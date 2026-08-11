import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart'
    hide Transaction;

/// The sync log has to drain. It is the file-sync engine's only queue: rows
/// go in on every local mutation and only leave when `markExported` flips
/// `exported`. Both ends of that used to break on a large backlog, because
/// `isIn` binds one SQL variable per id and SQLite refuses a statement with
/// more than 999 of them.
///
/// The failure was silent. `_exportPendingChanges` wraps everything in a
/// blanket `catch`, so `SqliteException(1): too many SQL variables` was logged
/// and swallowed *after* the .sync file had been written - the peer got the
/// data, but the local log kept every row, and the next export re-read,
/// re-fetched and re-shipped the entire backlog. Forever.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // Opening the database seeds designations, account types, categories and
    // styles, and each of those DAOs logs its inserts - ~390 rows before the
    // test has done anything. Start from an empty queue so every count below
    // is about the call under test.
    await db.delete(db.syncLog).go();
  });
  tearDown(() => db.close());

  Future<int> pendingCount() async =>
      (await db.syncLogDao.getPendingChanges()).length;

  Future<List<int>> seedLog(int count) async {
    final ids = <int>[];
    await db.batch((batch) {
      batch.insertAll(
        db.syncLog,
        List.generate(
          count,
          (i) => SyncLogCompanion.insert(
            changedTableName: 'styles',
            recordId: 'record-$i',
            action: 'upsert',
            timestamp: 1000 + i,
          ),
        ),
      );
    });
    for (final row in await db.select(db.syncLog).get()) {
      ids.add(row.id);
    }
    return ids;
  }

  group('SyncLogDao.markExported', () {
    test('drains a backlog far past the 999-variable statement limit',
        () async {
      final ids = await seedLog(2500);
      expect(await pendingCount(), 2500);

      await db.syncLogDao.markExported(ids);

      expect(
        await pendingCount(),
        0,
        reason: 'an unchunked isIn() threw here and left every row pending',
      );
    });

    test('marks exactly the ids it is given', () async {
      final ids = await seedLog(1200);
      final half = ids.sublist(0, 600);

      await db.syncLogDao.markExported(half);

      final stillPending = await db.syncLogDao.getPendingChanges();
      expect(stillPending, hasLength(600));
      expect(
        stillPending.map((e) => e.id).toSet().intersection(half.toSet()),
        isEmpty,
      );
    });

    test('an empty list is a no-op, not a statement with no arguments',
        () async {
      await seedLog(3);

      await db.syncLogDao.markExported([]);

      expect(await pendingCount(), 3);
    });
  });

  group('bulk provider data stays out of the log', () {
    test('a rate refresh enqueues nothing to sync', () async {
      // One refresh of the seeded currency matrix is six figures of rows. The
      // file-sync engine has no exchangeRates case in _getBulkRecordData, so
      // every one of them was fetched, found payload-less and dropped - after
      // being walked on every single export.
      // preset 9999 is not a provider the seed uses, so these rows are
      // distinguishable from the ~283k seeded ones sharing this table.
      await db.exchangeRatesDao.insertAllExchangeRates([
        for (var i = 0; i < 50; i++)
          ExchangeRatesCompanion.insert(
            fromCurrencyCode: 'EUR',
            toCurrencyCode: 'USD',
            date: DateTime(2024, 1, 1).add(Duration(days: i)),
            rate: 1.1,
            preset: 9999,
          ),
      ]);

      expect(await pendingCount(), 0);
      expect(
        await (db.select(db.exchangeRates)
              ..where((t) => t.preset.equals(9999)))
            .get(),
        hasLength(50),
      );
    });

    test('a manually entered rate still enqueues one change', () async {
      // The distinction that matters: provider data is reproducible on every
      // device, a hand-entered rate is not.
      await db.exchangeRatesDao.addExchangeRate(
        ExchangeRatesCompanion.insert(
          fromCurrencyCode: 'EUR',
          toCurrencyCode: 'USD',
          date: DateTime(2024, 6, 1),
          rate: 1.07,
          preset: 1,
        ),
      );

      final pending = await db.syncLogDao.getPendingChanges();
      expect(pending, hasLength(1));
      expect(pending.single.changedTableName, 'exchange_rates');
      expect(pending.single.recordId, 'EUR_USD_2024-06-01_1');
    });

    test('an inflation refresh enqueues nothing to sync', () async {
      await db.inflationRatesDao.insertAllInflationRates([
        for (var i = 0; i < 20; i++)
          InflationRatesCompanion.insert(
            date: DateTime(2024, 1, 1).add(Duration(days: i)),
            percent: 3.2,
            country: const Value('DE'),
            preset: 1,
          ),
      ]);

      expect(await pendingCount(), 0);
      expect(await db.select(db.inflationRates).get(), hasLength(20));
    });
  });

  group('bulk fetch by ids survives a large id list', () {
    // _exportPendingChanges hands these every pending record id for a table at
    // once, so they hit the same 999-variable ceiling markExported did.
    test('getTransactionsByIds', () async {
      final ids = List.generate(2000, (i) => 'missing-$i');
      expect(await db.transactionsDao.getTransactionsByIds(ids), isEmpty);
    });

    test('getAccountsByIds', () async {
      final ids = List.generate(2000, (i) => 'missing-$i');
      expect(await db.accountsDao.getAccountsByIds(ids), isEmpty);
    });

    test('getAssetEntriesByIds', () async {
      final ids = List.generate(2000, (i) => 'missing-$i');
      expect(await db.assetEntriesDao.getAssetEntriesByIds(ids), isEmpty);
    });

    test('getAccountTypesByIds returns the rows that do exist', () async {
      final seeded = await db.select(db.accountTypes).get();
      expect(seeded, isNotEmpty);
      final ids = [
        seeded.first.id,
        ...List.generate(2000, (i) => 'missing-$i'),
      ];

      final found = await db.accountTypesDao.getAccountTypesByIds(ids);

      expect(found.map((e) => e.id), [seeded.first.id]);
    });

    test('getDesignationsByIds returns the rows that do exist', () async {
      final seeded = await db.select(db.currencyDesignations).get();
      expect(seeded, isNotEmpty);
      final ids = [
        seeded.first.id,
        ...List.generate(2000, (i) => 'missing-$i'),
      ];

      final found = await db.currencyDesignationsDao.getDesignationsByIds(ids);

      expect(found.map((e) => e.id), [seeded.first.id]);
    });
  });
}
