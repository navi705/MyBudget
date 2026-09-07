import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart'
    hide Transaction;
import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// The v23 -> v24 step: transactions that recorded the same payment twice are
/// collapsed to one.
///
/// [AppDatabase.removeDuplicateTransactions] is the code under test - see its
/// doc comment for exactly what "the same payment" means and how the survivor
/// is chosen. These tests drive it through a real `onUpgrade`, the same way
/// rate_prune_migration_test drives the step next to it, because the
/// interesting failure mode is a fixture stuck below v24 that a bug in the
/// `from < 24` guard skips past without ever calling the function at all.
///
/// The fixture is a real file for the same reason as rate_prune_migration_test:
/// the migration has to be observed by a second connection opening a database
/// whose `user_version` is behind.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File file;

  /// Builds a device at the current schema, then winds `user_version` back to
  /// 23 so the next open runs only the step under test - not v22->v23 as
  /// well, which would make a failure here harder to tell apart from one there.
  Future<void> buildFixture(void Function(sqlite3.Database raw) seed) async {
    final db = AppDatabase.forTesting(NativeDatabase(file));
    await db.customSelect('SELECT 1').get();
    await db.close();

    final raw = sqlite3.sqlite3.open(file.path);
    seed(raw);
    raw.execute('PRAGMA user_version = 23;');
    raw.dispose();
  }

  /// Opens the fixture through drift, which runs the upgrade, and confirms it
  /// actually reached the current schema rather than stopping partway.
  Future<AppDatabase> openUpgraded() async {
    final db = AppDatabase.forTesting(NativeDatabase(file));
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data['user_version'], db.schemaVersion);
    return db;
  }

  Future<Map<String, dynamic>> transactionRow(AppDatabase db, String id) => db
      .customSelect("SELECT * FROM transactions WHERE id = '$id'")
      .getSingle()
      .then((row) => row.data);

  Future<Map<String, dynamic>> accountRow(AppDatabase db, String id) => db
      .customSelect("SELECT * FROM accounts WHERE id = '$id'")
      .getSingle()
      .then((row) => row.data);

  Future<List<String>> liveTransactionIds(
    AppDatabase db, {
    required String accountId,
  }) async {
    final rows = await db
        .customSelect(
          "SELECT id FROM transactions "
          "WHERE account_id = '$accountId' AND is_deleted = 0",
        )
        .get();
    return rows.map((r) => r.data['id'] as String).toList();
  }

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync(
      'mybudget_dup_transaction_test',
    );
    file = File('${tempDir.path}/v23.sqlite');
  });

  tearDown(() {
    // Windows keeps a handle on a database file a failed test left open; the
    // fixture is a temp directory either way and losing it is not a failure.
    try {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    } on FileSystemException {
      // Nothing to do about it here.
    }
  });

  /// Inserts one account through the raw connection - no clientDefault, no
  /// trigger, nothing drift would otherwise fill in for us.
  void seedAccount(
    sqlite3.Database raw, {
    required String id,
    String currencyCode = 'USD',
    required double balance,
    int? balanceMinor,
  }) {
    raw.execute(
      '''
      INSERT INTO accounts (id, name, balance, balance_minor, currency_code,
                             currency_designation_id, account_type_id,
                             creation_date)
        SELECT ?, ?, ?, ?, ?, (SELECT id FROM currency_designations LIMIT 1),
               (SELECT id FROM account_types LIMIT 1), 0
      ''',
      [id, id, balance, balanceMinor, currencyCode],
    );
  }

  /// Inserts one transaction through the raw connection. Every row shares the
  /// one seeded category, since the category-backfill rule is exercised by
  /// giving the survivor a null category instead.
  void seedTransaction(
    sqlite3.Database raw, {
    required String id,
    required String accountId,
    String currencyCode = 'USD',
    required double amount,
    int? amountMinor,
    int date = 1000,
    bool needsReview = false,
    required int modifiedAt,
    String? categoryId,
    String? linkedTransactionId,
  }) {
    raw.execute(
      '''
      INSERT INTO transactions (id, description, amount, amount_minor, date,
                                 account_id, category_id, currency_code,
                                 needs_review, modified_at, is_deleted,
                                 linked_transaction_id)
        SELECT ?, ?, ?, ?, ?, ?,
               COALESCE(?, (SELECT id FROM categories LIMIT 1)), ?, ?, ?, 0, ?
      ''',
      [
        id,
        id,
        amount,
        amountMinor,
        date,
        accountId,
        categoryId,
        currencyCode,
        needsReview ? 1 : 0,
        modifiedAt,
        linkedTransactionId,
      ],
    );
  }

  test('a duplicate pair collapses to one live row and the balance drops by '
      'exactly one copy\'s amount', () async {
    await buildFixture((raw) {
      // The balance already counts both copies, as it would on a device
      // that carried this bug for a while - collapsing the pair has to take
      // exactly one of them back out, not the whole balance or neither.
      seedAccount(raw, id: 'acc-a', balance: 300.0, balanceMinor: 30000);
      seedTransaction(
        raw,
        id: 'tx-a1',
        accountId: 'acc-a',
        amount: 100.0,
        amountMinor: 10000,
        modifiedAt: 1000,
      );
      seedTransaction(
        raw,
        id: 'tx-a2',
        accountId: 'acc-a',
        amount: 100.0,
        amountMinor: 10000,
        modifiedAt: 2000,
      );
    });

    final db = await openUpgraded();
    final live = await liveTransactionIds(db, accountId: 'acc-a');
    final account = await accountRow(db, 'acc-a');
    await db.close();

    expect(live, hasLength(1));
    expect(account['balance'], 200.0);
    expect(account['balance_minor'], 20000);
  });

  test(
    'the reviewed copy survives and the unreviewed one is tombstoned',
    () async {
      await buildFixture((raw) {
        seedAccount(raw, id: 'acc-b', balance: 240.0, balanceMinor: 24000);
        // The reviewed copy is the newer of the two, so a rule that picked on
        // age alone would keep the wrong row - reviewed has to win regardless.
        seedTransaction(
          raw,
          id: 'tx-b-reviewed',
          accountId: 'acc-b',
          amount: 120.0,
          amountMinor: 12000,
          needsReview: false,
          modifiedAt: 5000,
        );
        seedTransaction(
          raw,
          id: 'tx-b-unreviewed',
          accountId: 'acc-b',
          amount: 120.0,
          amountMinor: 12000,
          needsReview: true,
          modifiedAt: 1000,
        );
      });

      final db = await openUpgraded();
      final survivor = await transactionRow(db, 'tx-b-reviewed');
      final loser = await transactionRow(db, 'tx-b-unreviewed');
      final account = await accountRow(db, 'acc-b');
      await db.close();

      expect(survivor['is_deleted'], 0);
      expect(loser['is_deleted'], 1, reason: 'tombstoned, not hard-deleted');
      expect(account['balance'], 120.0);
      expect(account['balance_minor'], 12000);
    },
  );

  test('when both copies carry the same needs_review, the older modified_at '
      'survives', () async {
    await buildFixture((raw) {
      seedAccount(raw, id: 'acc-c', balance: 160.0, balanceMinor: 16000);
      // The older row's id sorts after the newer row's alphabetically, so a
      // fallback to id ordering would pick the wrong survivor here too.
      seedTransaction(
        raw,
        id: 'tx-c-zzz-older',
        accountId: 'acc-c',
        amount: 80.0,
        amountMinor: 8000,
        needsReview: false,
        modifiedAt: 1000,
      );
      seedTransaction(
        raw,
        id: 'tx-c-aaa-newer',
        accountId: 'acc-c',
        amount: 80.0,
        amountMinor: 8000,
        needsReview: false,
        modifiedAt: 5000,
      );
    });

    final db = await openUpgraded();
    final survivor = await transactionRow(db, 'tx-c-zzz-older');
    final loser = await transactionRow(db, 'tx-c-aaa-newer');
    final account = await accountRow(db, 'acc-c');
    await db.close();

    expect(survivor['is_deleted'], 0);
    expect(loser['is_deleted'], 1);
    expect(account['balance'], 80.0);
    expect(account['balance_minor'], 8000);
  });

  test('a duplicated transfer pair ends with exactly two live legs linked to '
      'each other and no live row pointing at a tombstone', () async {
    await buildFixture((raw) {
      seedAccount(raw, id: 'acc-d-from', balance: -400.0);
      seedAccount(raw, id: 'acc-d-to', balance: 400.0);

      // Both legs of one transfer were imported twice, and the two imports
      // linked their legs to the WRONG copy of the other leg - X to Y', and
      // X' to Y - so neither surviving leg already points at the other
      // survivor. That is the case the repoint step exists for.
      seedTransaction(
        raw,
        id: 'tx-d-x',
        accountId: 'acc-d-from',
        amount: -200.0,
        amountMinor: -20000,
        date: 2000,
        needsReview: false,
        modifiedAt: 1000,
        linkedTransactionId: 'tx-d-y2',
      );
      seedTransaction(
        raw,
        id: 'tx-d-x2',
        accountId: 'acc-d-from',
        amount: -200.0,
        amountMinor: -20000,
        date: 2000,
        needsReview: true,
        modifiedAt: 2000,
        linkedTransactionId: 'tx-d-y',
      );
      seedTransaction(
        raw,
        id: 'tx-d-y',
        accountId: 'acc-d-to',
        amount: 200.0,
        amountMinor: 20000,
        date: 2000,
        needsReview: false,
        modifiedAt: 1500,
        linkedTransactionId: 'tx-d-x2',
      );
      seedTransaction(
        raw,
        id: 'tx-d-y2',
        accountId: 'acc-d-to',
        amount: 200.0,
        amountMinor: 20000,
        date: 2000,
        needsReview: true,
        modifiedAt: 2500,
        linkedTransactionId: 'tx-d-x',
      );
    });

    final db = await openUpgraded();
    final x = await transactionRow(db, 'tx-d-x');
    final x2 = await transactionRow(db, 'tx-d-x2');
    final y = await transactionRow(db, 'tx-d-y');
    final y2 = await transactionRow(db, 'tx-d-y2');
    await db.close();

    expect(x['is_deleted'], 0);
    expect(y['is_deleted'], 0);
    expect(x2['is_deleted'], 1);
    expect(y2['is_deleted'], 1);

    // Each survivor now points at the other survivor, not at the tombstone
    // it originally linked to.
    expect(x['linked_transaction_id'], 'tx-d-y');
    expect(y['linked_transaction_id'], 'tx-d-x');
  });

  test(
    'rows that differ in amount, date, account or currency are left alone',
    () async {
      await buildFixture((raw) {
        seedAccount(raw, id: 'acc-e', balance: 0.0, balanceMinor: 0);
        seedAccount(raw, id: 'acc-e2', balance: 0.0, balanceMinor: 0);

        seedTransaction(
          raw,
          id: 'tx-e-base',
          accountId: 'acc-e',
          amount: 50.0,
          amountMinor: 5000,
          date: 3000,
          modifiedAt: 1000,
        );
        // Differs only in amount.
        seedTransaction(
          raw,
          id: 'tx-e-amount',
          accountId: 'acc-e',
          amount: 51.0,
          amountMinor: 5100,
          date: 3000,
          modifiedAt: 1000,
        );
        // Differs only in date. Five seconds rather than one: the v25 -> v26
        // step reads a gap of at most two seconds as one payment written twice
        // by two importers, and this row is here to be left alone.
        seedTransaction(
          raw,
          id: 'tx-e-date',
          accountId: 'acc-e',
          amount: 50.0,
          amountMinor: 5000,
          date: 3005,
          modifiedAt: 1000,
        );
        // Differs only in account.
        seedTransaction(
          raw,
          id: 'tx-e-account',
          accountId: 'acc-e2',
          amount: 50.0,
          amountMinor: 5000,
          date: 3000,
          modifiedAt: 1000,
        );
        // Differs only in currency.
        seedTransaction(
          raw,
          id: 'tx-e-currency',
          accountId: 'acc-e',
          currencyCode: 'EUR',
          amount: 50.0,
          amountMinor: 5000,
          date: 3000,
          modifiedAt: 1000,
        );
      });

      final db = await openUpgraded();
      final ids = [
        'tx-e-base',
        'tx-e-amount',
        'tx-e-date',
        'tx-e-account',
        'tx-e-currency',
      ];
      final rows = await Future.wait(ids.map((id) => transactionRow(db, id)));
      await db.close();

      for (var i = 0; i < ids.length; i++) {
        expect(
          rows[i]['is_deleted'],
          0,
          reason: '${ids[i]} should be untouched',
        );
      }
    },
  );

  test("sync_log gets a 'delete' entry for each removed transaction", () async {
    await buildFixture((raw) {
      seedAccount(raw, id: 'acc-f', balance: 30.0, balanceMinor: 3000);
      // Two independent duplicate pairs, so the assertion below can tell "one
      // entry" apart from "one entry regardless of how many rows were removed".
      seedTransaction(
        raw,
        id: 'tx-f1-survivor',
        accountId: 'acc-f',
        amount: 10.0,
        amountMinor: 1000,
        date: 100,
        modifiedAt: 1000,
      );
      seedTransaction(
        raw,
        id: 'tx-f1-loser',
        accountId: 'acc-f',
        amount: 10.0,
        amountMinor: 1000,
        date: 100,
        modifiedAt: 2000,
      );
      seedTransaction(
        raw,
        id: 'tx-f2-survivor',
        accountId: 'acc-f',
        amount: 20.0,
        amountMinor: 2000,
        date: 200,
        modifiedAt: 1000,
      );
      seedTransaction(
        raw,
        id: 'tx-f2-loser',
        accountId: 'acc-f',
        amount: 20.0,
        amountMinor: 2000,
        date: 200,
        modifiedAt: 2000,
      );
    });

    final db = await openUpgraded();
    final deletes = await db
        .customSelect(
          "SELECT record_id FROM sync_log "
          "WHERE changed_table_name = 'transactions' AND action = 'delete'",
        )
        .get();
    await db.close();

    final deletedIds = deletes
        .map((r) => r.data['record_id'] as String)
        .toSet();
    expect(deletedIds, {'tx-f1-loser', 'tx-f2-loser'});
  });
}
