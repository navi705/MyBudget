import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/sync/sync_service.dart';

/// Invariant 8 on the P2P path: an account balance is a DERIVED value, so it is
/// rebuilt from the merged transaction set after every packet instead of being
/// taken from the peer that happened to send last.
///
/// The server path has enforced this since `ServerSyncService._applyChanges`
/// started calling `recomputeBalances`; the file importer wrote `json['balance']`
/// straight into the row. Transactions merge as a set and a balance merges as a
/// scalar, so the two disagreed the moment both devices had touched the same
/// account - permanently, because nothing ever recomputed it again.
///
/// Both devices are set up with the SAME account rows (same ids, same seeded
/// designation/type ids - the seed lays every install down under stable ids),
/// which is what a real pair of synced devices looks like.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory syncFolder;
  late AppDatabase dbA;
  late AppDatabase dbB;
  late SyncService serviceA;
  late SyncService serviceB;

  Future<void> setDeviceId(AppDatabase db, String id) =>
      db.settingsDao.setSetting(
        SettingsCompanion(
          key: const Value('local_device_id'),
          value: Value(id),
        ),
      );

  Future<SyncService> configuredService(AppDatabase db, String deviceId) async {
    await setDeviceId(db, deviceId);
    final service = SyncService(db);
    await service.startSync(syncFolder.path);
    await service.stopSync();
    return service;
  }

  Future<void> createAccount(AppDatabase db, String id) async {
    final designationId =
        (await db.select(db.currencyDesignations).get()).first.id;
    final accountTypeId = (await db.select(db.accountTypes).get()).first.id;
    await db.accountsDao.insertAccount(
      AccountsCompanion.insert(
        id: Value(id),
        name: id,
        balance: 0.0,
        balanceMinor: const Value(0),
        currencyCode: 'EUR',
        currencyDesignationId: designationId,
        accountTypeId: accountTypeId,
      ),
    );
  }

  /// One transaction plus the incremental balance move the app makes for it -
  /// the same pair `LocalTransactionRepository.addTransaction` performs.
  Future<void> addTransaction(
    AppDatabase db,
    String id,
    double amount,
    String accountId,
  ) async {
    final categoryId = (await db.select(db.categories).get()).first.id;
    await db.transaction(() async {
      await db.transactionsDao.insertTransaction(
        TransactionsCompanion.insert(
          id: Value(id),
          description: id,
          amount: amount,
          amountMinor: Value((amount * 100).round()),
          date: DateTime(2024, 6, 1),
          accountId: accountId,
          categoryId: categoryId,
          currencyCode: 'EUR',
        ),
      );
      await db.accountsDao.adjustBalance(
        accountId,
        amount,
        currencyCode: 'EUR',
      );
    });
  }

  Future<DbAccount> accountOn(AppDatabase db, String id) =>
      (db.select(db.accounts)..where((a) => a.id.equals(id))).getSingle();

  /// Everything written so far is "already known to both peers": drop it from
  /// the export queues so each test only ships the writes it makes itself.
  Future<void> drainLogs() async {
    await dbA.customStatement('UPDATE sync_log SET exported = 1');
    await dbB.customStatement('UPDATE sync_log SET exported = 1');
  }

  Future<void> syncAToB() async {
    await serviceA.exportNow();
    await dbA.customStatement(
      'UPDATE sync_log SET exported = 1 WHERE exported = 0',
    );
    await serviceB.importNow();
  }

  setUp(() async {
    syncFolder = await Directory.systemTemp.createTemp('mybudget_sync_bal_');
    dbA = AppDatabase.forTesting(NativeDatabase.memory());
    dbB = AppDatabase.forTesting(NativeDatabase.memory());
    serviceA = await configuredService(dbA, 'device-a');
    serviceB = await configuredService(dbB, 'device-b');

    for (final db in [dbA, dbB]) {
      await createAccount(db, 'acc1');
      await createAccount(db, 'acc2');
    }
    await drainLogs();
  });

  tearDown(() async {
    await dbA.close();
    await dbB.close();
    if (await syncFolder.exists()) {
      await syncFolder.delete(recursive: true);
    }
  });

  test('an imported transaction is added to the balance, not replaced by the '
      "peer's", () async {
    // Both devices spend offline on the same account. B knows only about its
    // own 50, A only about its own 100.
    await addTransaction(dbB, 'tx-b', 50.0, 'acc1');
    await addTransaction(dbA, 'tx-a', 100.0, 'acc1');
    // A's account row is stamped into the future so it wins last-write-wins
    // outright: this test is about what happens AFTER the winner is picked,
    // not about which scalar won.
    await dbA.customStatement(
      "UPDATE accounts SET modified_at = ? WHERE id = 'acc1'",
      [DateTime.now().millisecondsSinceEpoch + 10000000],
    );

    await syncAToB();

    expect((await dbB.select(dbB.transactions).get()).length, 2);
    final acc1 = await accountOn(dbB, 'acc1');
    expect(
      acc1.balance,
      closeTo(150.0, 1e-9),
      reason: "100.0 would mean B took A's scalar and forgot its own 50",
    );
    expect(acc1.balanceMinor, 15000);
  });

  test('the account a moved transaction left is rebuilt too', () async {
    await addTransaction(dbA, 'tx-a', 100.0, 'acc1');
    await syncAToB();
    expect((await accountOn(dbB, 'acc1')).balance, closeTo(100.0, 1e-9));

    // A moves the transaction to acc2 and exports ONLY the transaction: acc1
    // is not mentioned in the packet at all, so B has to work out for itself
    // that acc1 no longer holds this money.
    await dbA.customStatement('UPDATE sync_log SET exported = 1');
    final categoryId = (await dbA.select(dbA.categories).get()).first.id;
    await dbA.transactionsDao.updateTransaction(
      TransactionsCompanion(
        id: const Value('tx-a'),
        description: const Value('tx-a'),
        amount: const Value(100.0),
        amountMinor: const Value(10000),
        date: Value(DateTime(2024, 6, 1)),
        accountId: const Value('acc2'),
        categoryId: Value(categoryId),
        currencyCode: const Value('EUR'),
      ),
    );
    await dbA.accountsDao.recomputeBalances({'acc1', 'acc2'});

    await syncAToB();

    expect(
      (await accountOn(dbB, 'acc1')).balance,
      closeTo(0.0, 1e-9),
      reason: 'acc1 no longer owns tx-a and nothing else was ever booked to it',
    );
    expect((await accountOn(dbB, 'acc2')).balance, closeTo(100.0, 1e-9));
    expect((await accountOn(dbB, 'acc1')).balanceMinor, 0);
    expect((await accountOn(dbB, 'acc2')).balanceMinor, 10000);
  });

  test('an imported delete takes its money back out of the balance', () async {
    await addTransaction(dbA, 'tx-a', 100.0, 'acc1');
    await syncAToB();
    expect((await accountOn(dbB, 'acc1')).balance, closeTo(100.0, 1e-9));

    await dbA.customStatement('UPDATE sync_log SET exported = 1');
    await dbA.transactionsDao.deleteTransaction(
      const TransactionsCompanion(id: Value('tx-a')),
    );

    await syncAToB();

    expect(
      (await accountOn(dbB, 'acc1')).balance,
      closeTo(0.0, 1e-9),
      reason: 'the tombstone is excluded from the rebuilt sum',
    );
  });

  test('the rebuilt balance is not queued back for export', () async {
    // recomputeBalances leaves modified_at alone on purpose: every peer can
    // derive this number from rows it already has, so exporting it would push
    // a change nobody made and start the cycle over on the other side.
    await addTransaction(dbA, 'tx-a', 100.0, 'acc1');
    await syncAToB();

    final pending = await dbB.syncLogDao.getPendingChanges();
    expect(
      pending.where((e) => e.changedTableName == 'accounts'),
      isEmpty,
      reason: 'a rebuild is not a local edit',
    );
  });
}
