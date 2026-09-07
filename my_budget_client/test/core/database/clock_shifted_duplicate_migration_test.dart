import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart'
    hide Transaction;
import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// The v25 -> v26 step: the same payment written twice by two importers whose
/// clocks disagree by a whole number of hours is collapsed to one row.
///
/// [AppDatabase.removeClockShiftedDuplicates] is the code under test - its doc
/// comment carries the rule and what makes a whole-hour gap safe to collapse
/// where an arbitrary one is not. Driven through a real `onUpgrade`, like the
/// v23 -> v24 dedupe test next door, because a bug in the `from < 26` guard
/// would skip the step and no test of the function itself would notice.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File file;

  /// Builds a device at the current schema, then winds `user_version` back to
  /// 25 so the next open runs only the step under test.
  Future<void> buildFixture(void Function(sqlite3.Database raw) seed) async {
    final db = AppDatabase.forTesting(NativeDatabase(file));
    await db.customSelect('SELECT 1').get();
    await db.close();

    final raw = sqlite3.sqlite3.open(file.path);
    seed(raw);
    raw.execute('PRAGMA user_version = 25;');
    raw.dispose();
  }

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

  Future<List<String>> liveTransactionIds(AppDatabase db) async {
    final rows = await db
        .customSelect('SELECT id FROM transactions WHERE is_deleted = 0')
        .get();
    return rows.map((r) => r.data['id'] as String).toList()..sort();
  }

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('mybudget_clock_shift_test');
    file = File('${tempDir.path}/v25.sqlite');
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

  void seedAccount(
    sqlite3.Database raw, {
    required String id,
    String name = 'Alta_Bank',
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
      [id, name, balance, balanceMinor, currencyCode],
    );
  }

  void seedTransaction(
    sqlite3.Database raw, {
    required String id,
    required String accountId,
    String? description,
    String currencyCode = 'USD',
    required double amount,
    int? amountMinor,
    required int date,
    bool needsReview = false,
    int modifiedAt = 1000,
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
        description ?? id,
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

  test('two copies two hours apart collapse to one and the balance gives back '
      'exactly one copy', () async {
    await buildFixture((raw) {
      // The balance counts both copies, as it does on a device that carried
      // this for months.
      seedAccount(raw, id: 'acc-a', balance: 800.0, balanceMinor: 80000);
      seedTransaction(
        raw,
        id: 'tx-early',
        accountId: 'acc-a',
        description: 'LIDL 128 BEOGRA',
        amount: -100.0,
        amountMinor: -10000,
        date: 1000000,
      );
      seedTransaction(
        raw,
        id: 'tx-late',
        accountId: 'acc-a',
        amount: -100.0,
        amountMinor: -10000,
        date: 1000000 + 7200,
      );
    });

    final db = await openUpgraded();
    addTearDown(db.close);

    expect(await liveTransactionIds(db), ['tx-early']);
    expect((await transactionRow(db, 'tx-late'))['is_deleted'], 1);
    // -100 was counted twice; the copy that goes takes its -100 with it.
    expect((await accountRow(db, 'acc-a'))['balance'], 900.0);
    expect((await accountRow(db, 'acc-a'))['balance_minor'], 90000);
  });

  test(
    'four hours apart is the same doubled offset after a clock change',
    () async {
      await buildFixture((raw) {
        seedAccount(raw, id: 'acc-a', balance: 0.0, balanceMinor: 0);
        seedTransaction(
          raw,
          id: 'tx-early',
          accountId: 'acc-a',
          description: '216 - C MARKET',
          amount: -50.0,
          amountMinor: -5000,
          date: 2000000,
        );
        seedTransaction(
          raw,
          id: 'tx-late',
          accountId: 'acc-a',
          amount: -50.0,
          amountMinor: -5000,
          date: 2000000 + 14400,
        );
      });

      final db = await openUpgraded();
      addTearDown(db.close);

      expect(await liveTransactionIds(db), ['tx-early']);
    },
  );

  test(
    'a copy rounded through a 32-bit float is still the same payment',
    () async {
      await buildFixture((raw) {
        seedAccount(raw, id: 'acc-a', balance: 0.0, balanceMinor: 0);
        // The salary that started this: one importer stores 165261.21, the other
        // the nearest 32-bit float to it, and their minor units differ by one.
        seedTransaction(
          raw,
          id: 'tx-exact',
          accountId: 'acc-a',
          description: 'Salary',
          amount: 165261.21,
          amountMinor: 16526121,
          date: 3000000,
        );
        seedTransaction(
          raw,
          id: 'tx-float',
          accountId: 'acc-a',
          amount: 165261.203125,
          amountMinor: 16526120,
          date: 3000000 + 14400,
        );
      });

      final db = await openUpgraded();
      addTearDown(db.close);

      expect(await liveTransactionIds(db), ['tx-exact']);
    },
  );

  test('a gap that is not a whole number of hours is two payments', () async {
    await buildFixture((raw) {
      seedAccount(raw, id: 'acc-a', balance: 0.0, balanceMinor: 0);
      seedTransaction(
        raw,
        id: 'tx-first',
        accountId: 'acc-a',
        amount: -20.0,
        amountMinor: -2000,
        date: 4000000,
      );
      // Ninety minutes: the same card, the same amount, twice in an afternoon.
      seedTransaction(
        raw,
        id: 'tx-second',
        accountId: 'acc-a',
        amount: -20.0,
        amountMinor: -2000,
        date: 4000000 + 5400,
      );
    });

    final db = await openUpgraded();
    addTearDown(db.close);

    expect(await liveTransactionIds(db), ['tx-first', 'tx-second']);
  });

  test('a gap past the window is two payments however round it is', () async {
    await buildFixture((raw) {
      seedAccount(raw, id: 'acc-a', balance: 0.0, balanceMinor: 0);
      seedTransaction(
        raw,
        id: 'tx-first',
        accountId: 'acc-a',
        amount: -20.0,
        amountMinor: -2000,
        date: 5000000,
      );
      // A day later to the second - a standing daily charge, not a clock.
      seedTransaction(
        raw,
        id: 'tx-second',
        accountId: 'acc-a',
        amount: -20.0,
        amountMinor: -2000,
        date: 5000000 + 86400,
      );
    });

    final db = await openUpgraded();
    addTearDown(db.close);

    expect(await liveTransactionIds(db), ['tx-first', 'tx-second']);
  });

  test('amounts a cent apart are two payments', () async {
    await buildFixture((raw) {
      seedAccount(raw, id: 'acc-a', balance: 0.0, balanceMinor: 0);
      seedTransaction(
        raw,
        id: 'tx-first',
        accountId: 'acc-a',
        amount: -20.0,
        amountMinor: -2000,
        date: 6000000,
      );
      seedTransaction(
        raw,
        id: 'tx-second',
        accountId: 'acc-a',
        amount: -20.01,
        amountMinor: -2001,
        date: 6000000 + 7200,
      );
    });

    final db = await openUpgraded();
    addTearDown(db.close);

    expect(await liveTransactionIds(db), ['tx-first', 'tx-second']);
  });

  test(
    'copies on two accounts, or in two currencies, are left alone',
    () async {
      await buildFixture((raw) {
        seedAccount(raw, id: 'acc-a', balance: 0.0, balanceMinor: 0);
        seedAccount(
          raw,
          id: 'acc-b',
          name: 'other',
          balance: 0.0,
          balanceMinor: 0,
        );
        seedTransaction(
          raw,
          id: 'tx-here',
          accountId: 'acc-a',
          amount: -75.0,
          amountMinor: -7500,
          date: 7000000,
        );
        seedTransaction(
          raw,
          id: 'tx-there',
          accountId: 'acc-b',
          amount: -75.0,
          amountMinor: -7500,
          date: 7000000 + 7200,
        );
        seedTransaction(
          raw,
          id: 'tx-eur',
          accountId: 'acc-a',
          currencyCode: 'EUR',
          amount: -75.0,
          amountMinor: -7500,
          date: 7000000 + 7200,
        );
      });

      final db = await openUpgraded();
      addTearDown(db.close);

      expect(await liveTransactionIds(db), ['tx-eur', 'tx-here', 'tx-there']);
    },
  );

  test(
    'a transfer leg is half of one movement, not a copy of a payment',
    () async {
      await buildFixture((raw) {
        seedAccount(raw, id: 'acc-a', balance: 0.0, balanceMinor: 0);
        seedTransaction(
          raw,
          id: 'tx-leg-a',
          accountId: 'acc-a',
          amount: -300.0,
          amountMinor: -30000,
          date: 8000000,
          linkedTransactionId: 'tx-leg-b',
        );
        seedTransaction(
          raw,
          id: 'tx-leg-b',
          accountId: 'acc-a',
          amount: -300.0,
          amountMinor: -30000,
          date: 8000000 + 7200,
          linkedTransactionId: 'tx-leg-a',
        );
      });

      final db = await openUpgraded();
      addTearDown(db.close);

      expect(await liveTransactionIds(db), ['tx-leg-a', 'tx-leg-b']);
    },
  );

  test('the copy that names the merchant is the one that stays', () async {
    await buildFixture((raw) {
      seedAccount(raw, id: 'acc-a', balance: 0.0, balanceMinor: 0);
      // The bank's own importer writes the account name into every row and is
      // the newer of the two, so the description is what has to decide.
      seedTransaction(
        raw,
        id: 'tx-generic',
        accountId: 'acc-a',
        description: 'Alta_Bank',
        amount: -12.5,
        amountMinor: -1250,
        date: 9000000,
        modifiedAt: 1000,
      );
      seedTransaction(
        raw,
        id: 'tx-merchant',
        accountId: 'acc-a',
        description: 'LIDL 128 BEOGRA',
        amount: -12.5,
        amountMinor: -1250,
        date: 9000000 + 7200,
        modifiedAt: 2000,
      );
    });

    final db = await openUpgraded();
    addTearDown(db.close);

    expect(await liveTransactionIds(db), ['tx-merchant']);
  });

  test(
    'a copy the user has already reviewed outranks a better description',
    () async {
      await buildFixture((raw) {
        seedAccount(raw, id: 'acc-a', balance: 0.0, balanceMinor: 0);
        seedTransaction(
          raw,
          id: 'tx-reviewed',
          accountId: 'acc-a',
          description: 'Alta_Bank',
          amount: -12.5,
          amountMinor: -1250,
          date: 9500000,
        );
        seedTransaction(
          raw,
          id: 'tx-unreviewed',
          accountId: 'acc-a',
          description: 'LIDL 128 BEOGRA',
          amount: -12.5,
          amountMinor: -1250,
          date: 9500000 + 7200,
          needsReview: true,
        );
      });

      final db = await openUpgraded();
      addTearDown(db.close);

      expect(await liveTransactionIds(db), ['tx-reviewed']);
    },
  );

  test('both halves of the collapse reach the sync log', () async {
    await buildFixture((raw) {
      seedAccount(raw, id: 'acc-a', balance: 0.0, balanceMinor: 0);
      seedTransaction(
        raw,
        id: 'tx-early',
        accountId: 'acc-a',
        description: 'LIDL 128 BEOGRA',
        amount: -100.0,
        amountMinor: -10000,
        date: 9900000,
      );
      seedTransaction(
        raw,
        id: 'tx-late',
        accountId: 'acc-a',
        amount: -100.0,
        amountMinor: -10000,
        date: 9900000 + 7200,
      );
    });

    final db = await openUpgraded();
    addTearDown(db.close);

    final logged = await db
        .customSelect(
          'SELECT changed_table_name, record_id, action FROM sync_log',
        )
        .get();
    expect(
      logged.any(
        (row) =>
            row.data['changed_table_name'] == 'transactions' &&
            row.data['record_id'] == 'tx-late' &&
            row.data['action'] == 'delete',
      ),
      isTrue,
    );
    expect(
      logged.any(
        (row) =>
            row.data['changed_table_name'] == 'accounts' &&
            row.data['record_id'] == 'acc-a' &&
            row.data['action'] == 'upsert',
      ),
      isTrue,
    );
  });
}
