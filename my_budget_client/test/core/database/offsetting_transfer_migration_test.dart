import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart'
    hide Transaction;
import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// The v24 -> v25 step: the two halves of one movement of money, written as an
/// unrelated expense and an unrelated income seconds apart on one account, are
/// linked so that neither is counted as income or as expense.
///
/// [AppDatabase.linkOffsettingTransfers] is the code under test - its doc
/// comment carries the rule and the reason the v23 -> v24 dedupe is right to
/// leave these rows alone. Driven through a real `onUpgrade`, like the dedupe
/// test next door, because a bug in the `from < 25` guard would skip the step
/// entirely and no test of the function itself would notice.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File file;

  /// Builds a device at the current schema, then winds `user_version` back to
  /// 24 so the next open runs only the step under test.
  Future<void> buildFixture(void Function(sqlite3.Database raw) seed) async {
    final db = AppDatabase.forTesting(NativeDatabase(file));
    await db.customSelect('SELECT 1').get();
    await db.close();

    final raw = sqlite3.sqlite3.open(file.path);
    seed(raw);
    raw.execute('PRAGMA user_version = 24;');
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

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('mybudget_offsetting_test');
    file = File('${tempDir.path}/v24.sqlite');
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

  /// One transaction, written the way an import writes it: an ordinary
  /// category, no link, and a date in whole seconds - which is the unit the
  /// column stores and the unit the pairing window is measured in.
  void seedTransaction(
    sqlite3.Database raw, {
    required String id,
    required String accountId,
    String currencyCode = 'USD',
    required double amount,
    int? amountMinor,
    int date = 1000,
    String categoryId = 'cat_groceries',
    String? linkedTransactionId,
  }) {
    raw.execute(
      '''
      INSERT INTO transactions (id, description, amount, amount_minor, date,
                                 account_id, category_id, currency_code,
                                 needs_review, modified_at, is_deleted,
                                 linked_transaction_id)
        SELECT ?, ?, ?, ?, ?, ?, ?, ?, 0, 1000, 0, ?
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
        linkedTransactionId,
      ],
    );
  }

  test('the two halves of one movement are linked to each other and filed as '
      'a transfer, and no balance moves', () async {
    await buildFixture((raw) {
      seedAccount(raw, id: 'acc-a', balance: 300.0, balanceMinor: 30000);
      seedTransaction(
        raw,
        id: 'tx-out',
        accountId: 'acc-a',
        amount: -70.0,
        amountMinor: -7000,
        date: 1000,
      );
      seedTransaction(
        raw,
        id: 'tx-in',
        accountId: 'acc-a',
        amount: 70.0,
        amountMinor: 7000,
        date: 1002,
        categoryId: 'cat_salary',
      );
    });

    final db = await openUpgraded();
    addTearDown(db.close);

    final out = await transactionRow(db, 'tx-out');
    final into = await transactionRow(db, 'tx-in');
    expect(out['linked_transaction_id'], 'tx-in');
    expect(into['linked_transaction_id'], 'tx-out');
    expect(out['category_id'], 'cat_system_transfer');
    expect(into['category_id'], 'cat_system_transfer');

    // Both rows are real and both still count against the account: this step
    // only says they are one movement, it does not remove anything.
    expect(out['is_deleted'], 0);
    expect(into['is_deleted'], 0);
    expect(out['amount'], -70.0);
    expect(into['amount'], 70.0);

    final account = await accountRow(db, 'acc-a');
    expect(account['balance'], 300.0);
    expect(account['balance_minor'], 30000);
  });

  test('legs converted at two slightly different rates still pair', () async {
    // The pair this was written for: 6000 EUR leaving as 707515.20 RSD and
    // arriving as 704267.64, two seconds and 0.46% apart.
    await buildFixture((raw) {
      seedAccount(raw, id: 'acc-a', balance: 0.0, balanceMinor: 0);
      seedTransaction(
        raw,
        id: 'tx-out',
        accountId: 'acc-a',
        amount: -707515.20,
        amountMinor: -70751520,
        date: 1000,
      );
      seedTransaction(
        raw,
        id: 'tx-in',
        accountId: 'acc-a',
        amount: 704267.64,
        amountMinor: 70426764,
        date: 1002,
        categoryId: 'cat_salary',
      );
    });

    final db = await openUpgraded();
    addTearDown(db.close);

    expect(
      (await transactionRow(db, 'tx-out'))['linked_transaction_id'],
      'tx-in',
    );
  });

  test('amounts too far apart to be one movement are left alone', () async {
    await buildFixture((raw) {
      seedAccount(raw, id: 'acc-a', balance: 0.0, balanceMinor: 0);
      seedTransaction(
        raw,
        id: 'tx-out',
        accountId: 'acc-a',
        amount: -100.0,
        amountMinor: -10000,
        date: 1000,
      );
      // 5% off. A real exchange spread is under one.
      seedTransaction(
        raw,
        id: 'tx-in',
        accountId: 'acc-a',
        amount: 95.0,
        amountMinor: 9500,
        date: 1002,
        categoryId: 'cat_salary',
      );
    });

    final db = await openUpgraded();
    addTearDown(db.close);

    expect((await transactionRow(db, 'tx-out'))['linked_transaction_id'], null);
    expect((await transactionRow(db, 'tx-in'))['linked_transaction_id'], null);
    expect((await transactionRow(db, 'tx-in'))['category_id'], 'cat_salary');
  });

  test('a salary and a rent of the same size in the same month are left '
      'alone', () async {
    // The failure mode worth guarding: an income and an expense that really
    // are two separate movements, which only the window tells apart.
    await buildFixture((raw) {
      seedAccount(raw, id: 'acc-a', balance: 0.0, balanceMinor: 0);
      seedTransaction(
        raw,
        id: 'tx-salary',
        accountId: 'acc-a',
        amount: 1000.0,
        amountMinor: 100000,
        date: 1000,
        categoryId: 'cat_salary',
      );
      seedTransaction(
        raw,
        id: 'tx-rent',
        accountId: 'acc-a',
        amount: -1000.0,
        amountMinor: -100000,
        date: 1000 + 3600,
        categoryId: 'cat_housing',
      );
    });

    final db = await openUpgraded();
    addTearDown(db.close);

    expect(
      (await transactionRow(db, 'tx-salary'))['linked_transaction_id'],
      null,
    );
    expect((await transactionRow(db, 'tx-rent'))['category_id'], 'cat_housing');
  });

  test('two halves on different accounts are left alone', () async {
    await buildFixture((raw) {
      seedAccount(raw, id: 'acc-a', balance: 0.0, balanceMinor: 0);
      seedAccount(raw, id: 'acc-b', balance: 0.0, balanceMinor: 0);
      seedTransaction(
        raw,
        id: 'tx-out',
        accountId: 'acc-a',
        amount: -70.0,
        amountMinor: -7000,
        date: 1000,
      );
      seedTransaction(
        raw,
        id: 'tx-in',
        accountId: 'acc-b',
        amount: 70.0,
        amountMinor: 7000,
        date: 1001,
        categoryId: 'cat_salary',
      );
    });

    final db = await openUpgraded();
    addTearDown(db.close);

    // Two accounts is what a transfer the app itself wrote looks like, and
    // those already carry their link. An unlinked pair across accounts is a
    // guess this step is not entitled to make.
    expect((await transactionRow(db, 'tx-out'))['linked_transaction_id'], null);
    expect((await transactionRow(db, 'tx-in'))['linked_transaction_id'], null);
  });

  test('a row that already carries a link keeps it', () async {
    await buildFixture((raw) {
      seedAccount(raw, id: 'acc-a', balance: 0.0, balanceMinor: 0);
      seedAccount(raw, id: 'acc-b', balance: 0.0, balanceMinor: 0);
      // A transfer the app wrote: two legs, mutually linked, on two accounts.
      seedTransaction(
        raw,
        id: 'tx-leg-a',
        accountId: 'acc-a',
        amount: -70.0,
        amountMinor: -7000,
        date: 1000,
        categoryId: 'cat_system_transfer',
        linkedTransactionId: 'tx-leg-b',
      );
      seedTransaction(
        raw,
        id: 'tx-leg-b',
        accountId: 'acc-b',
        amount: 70.0,
        amountMinor: 7000,
        date: 1000,
        categoryId: 'cat_system_transfer',
        linkedTransactionId: 'tx-leg-a',
      );
      // An unrelated row on acc-a that offsets the leg sitting there.
      seedTransaction(
        raw,
        id: 'tx-other',
        accountId: 'acc-a',
        amount: 70.0,
        amountMinor: 7000,
        date: 1001,
        categoryId: 'cat_salary',
      );
    });

    final db = await openUpgraded();
    addTearDown(db.close);

    expect(
      (await transactionRow(db, 'tx-leg-a'))['linked_transaction_id'],
      'tx-leg-b',
    );
    expect(
      (await transactionRow(db, 'tx-other'))['linked_transaction_id'],
      null,
    );
  });

  test('each row is used once when three could pair', () async {
    await buildFixture((raw) {
      seedAccount(raw, id: 'acc-a', balance: 0.0, balanceMinor: 0);
      for (final (id, amount, date) in [
        ('tx-1', -70.0, 1000),
        ('tx-2', 70.0, 1001),
        ('tx-3', 70.0, 1002),
      ]) {
        seedTransaction(
          raw,
          id: id,
          accountId: 'acc-a',
          amount: amount,
          amountMinor: (amount * 100).round(),
          date: date,
        );
      }
    });

    final db = await openUpgraded();
    addTearDown(db.close);

    expect((await transactionRow(db, 'tx-1'))['linked_transaction_id'], 'tx-2');
    expect((await transactionRow(db, 'tx-2'))['linked_transaction_id'], 'tx-1');
    expect((await transactionRow(db, 'tx-3'))['linked_transaction_id'], null);
  });

  test('both linked rows are logged for sync', () async {
    await buildFixture((raw) {
      seedAccount(raw, id: 'acc-a', balance: 0.0, balanceMinor: 0);
      seedTransaction(
        raw,
        id: 'tx-out',
        accountId: 'acc-a',
        amount: -70.0,
        amountMinor: -7000,
        date: 1000,
      );
      seedTransaction(
        raw,
        id: 'tx-in',
        accountId: 'acc-a',
        amount: 70.0,
        amountMinor: 7000,
        date: 1001,
      );
    });

    final db = await openUpgraded();
    addTearDown(db.close);

    final logged = await db
        .customSelect(
          "SELECT record_id FROM sync_log WHERE changed_table_name = "
          "'transactions' AND action = 'upsert'",
        )
        .get();
    expect(
      logged.map((r) => r.data['record_id']).toSet(),
      containsAll(<String>{'tx-out', 'tx-in'}),
    );
  });
}
