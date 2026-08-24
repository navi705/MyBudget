import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart';

/// Who wrote this row.
///
/// `device_id` is the second half of the `(modified_at, device_id)` order that
/// both sync paths and the server resolve a conflict with, and no write path
/// ever filled it: every locally authored row carried NULL, every tie compared
/// `'' > ''`, and both ends kept their own version of a row that no later sync
/// would ever offer again. Against a live server that is a permanently and
/// silently divergent row, and it needs no clock coincidence to reach: the
/// seeded catalogue ships with `modified_at = 1` and names translated per
/// locale, so two devices in two languages disagree about all of it on their
/// first sync.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late String localId;
  late String designationId;
  late String accountTypeId;

  const insertRemoteAccount =
      'INSERT INTO accounts (id, name, balance, currency_code, '
      'currency_designation_id, account_type_id, creation_date, '
      'asset_quantity, modified_at, device_id, is_deleted) '
      "VALUES ('acc-remote', 'Remote', 5, 'USD', ?, ?, 0, 0, 900, "
      "'peer-1', 0)";

  setUp(() async {
    AppDatabase.seedExchangeRatesOnCreate = false;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.select(db.styles).get();
    localId = (await db.settingsDao.getSetting('local_device_id'))!.value;
    designationId = (await db
            .customSelect('SELECT id FROM currency_designations LIMIT 1')
            .getSingle())
        .read<String>('id');
    accountTypeId = (await db
            .customSelect('SELECT id FROM account_types LIMIT 1')
            .getSingle())
        .read<String>('id');
  });

  tearDown(() => db.close());

  Future<String?> authorOf(String table, String id) async {
    final rows = await db.customSelect(
      'SELECT device_id FROM $table WHERE id = ?',
      variables: [Variable.withString(id)],
    ).get();
    return rows.single.read<String?>('device_id');
  }

  Future<void> insertAccount(String id, {String name = 'Account'}) =>
      db.accountsDao.insertAccount(
        AccountsCompanion.insert(
          id: Value(id),
          name: name,
          balance: 10,
          currencyCode: 'USD',
          currencyDesignationId: designationId,
          accountTypeId: accountTypeId,
        ),
      );

  group('a row this device writes', () {
    test('is stamped with this device on the way in', () async {
      await insertAccount('acc-local');

      expect(await authorOf('accounts', 'acc-local'), localId);
    });

    test('is stamped whichever table it lands in', () async {
      await db.categoriesDao.insertCategory(
        CategoriesCompanion.insert(id: const Value('cat-local'), name: 'Local'),
      );
      await insertAccount('acc-for-tx');
      await db.transactionsDao.insertTransaction(
        TransactionsCompanion.insert(
          id: const Value('tx-local'),
          description: 'Local',
          amount: 5,
          date: DateTime(2026, 1, 1),
          accountId: 'acc-for-tx',
          categoryId: 'cat-local',
          currencyCode: 'USD',
        ),
      );

      expect(await authorOf('categories', 'cat-local'), localId);
      expect(await authorOf('transactions', 'tx-local'), localId);
    });

    test('the seeded catalogue is stamped too', () async {
      // The rows that ship with `modified_at = 1` and a locale-translated
      // name: without an author there is nothing left to break their tie
      // with, and two devices in two languages meet on exactly these.
      for (final table in const [
        'categories',
        'account_types',
        'currency_designations',
        'styles',
      ]) {
        final unstamped = (await db
                .customSelect(
                  'SELECT COUNT(*) AS c FROM $table WHERE device_id IS NULL',
                )
                .getSingle())
            .read<int>('c');

        expect(unstamped, 0, reason: '$table still has anonymous rows');
      }
    });
  });

  group('a row written on another device', () {
    test('keeps the author the writer gave it', () async {
      await db.customStatement(insertRemoteAccount, [
        designationId,
        accountTypeId,
      ]);

      expect(await authorOf('accounts', 'acc-remote'), 'peer-1');
    });

    test('a later write from a peer keeps naming that peer', () async {
      await db.customStatement(insertRemoteAccount, [
        designationId,
        accountTypeId,
      ]);
      await db.customStatement(
        "UPDATE accounts SET name = 'Renamed remotely', modified_at = 1500, "
        "device_id = 'peer-2' WHERE id = 'acc-remote'",
      );

      expect(await authorOf('accounts', 'acc-remote'), 'peer-2');
    });

    test('editing it here makes this device its author', () async {
      await db.customStatement(insertRemoteAccount, [
        designationId,
        accountTypeId,
      ]);

      await db.accountsDao.updateAccount(
        const AccountsCompanion(
          id: Value('acc-remote'),
          name: Value('Edited here'),
        ),
      );

      expect(
        await authorOf('accounts', 'acc-remote'),
        localId,
        reason: "the edit is this device's, so the tie it may lose is too",
      );
    });
  });

  group('the push queue', () {
    Future<int> queuedFor(String table, String key) async {
      final row = await db.customSelect(
        'SELECT COUNT(*) AS c FROM sync_push_queue '
        'WHERE changed_table_name = ? AND record_key = ?',
        variables: [Variable.withString(table), Variable.withString(key)],
      ).getSingle();
      return row.read<int>('c');
    }

    // The stamp is written by an UPDATE, and an UPDATE is exactly what the
    // push queue watches for. It must stay invisible to it: a row queued twice
    // for one edit is one wasted round trip per write, forever.
    test('counts an insert once, not twice for its stamp', () async {
      await db.categoriesDao.insertCategory(
        CategoriesCompanion.insert(id: const Value('cat-queue'), name: 'Queue'),
      );

      expect(await queuedFor('categories', 'cat-queue'), 1);
    });

    test('counts an edit once as well', () async {
      await db.categoriesDao.insertCategory(
        CategoriesCompanion.insert(
          id: const Value('cat-queue-2'),
          name: 'Queue',
        ),
      );
      await db.customStatement('DELETE FROM sync_push_queue');

      await db.categoriesDao.updateCategory(
        const CategoriesCompanion(
          id: Value('cat-queue-2'),
          name: Value('Edited'),
        ),
      );

      expect(await queuedFor('categories', 'cat-queue-2'), 1);
    });
  });
}
