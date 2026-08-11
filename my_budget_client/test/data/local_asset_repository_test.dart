import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/data/repositories/local_db/local_asset_repository.dart';
import 'package:my_budget_client/domain/entities/asset_data.dart';

/// Asset entries are the price/holding history behind non-fiat accounts.
/// Pinned here: soft delete has to hide an entry from every read, filters have
/// to compose, and each write has to leave a `sync_log` row under
/// `asset_entries`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LocalAssetRepository repo;
  late String accountId;

  setUpAll(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalAssetRepository(db.assetEntriesDao);

    final designationId =
        (await db.select(db.currencyDesignations).get()).first.id;
    final accountTypeId = (await db.select(db.accountTypes).get()).first.id;
    accountId = 'acc-1';
    await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: Value(accountId),
            name: 'Holdings',
            balance: 0,
            balanceMinor: const Value(0),
            currencyCode: 'EUR',
            currencyDesignationId: designationId,
            accountTypeId: accountTypeId,
          ),
        );
  });

  tearDownAll(() async => db.close());

  setUp(() async {
    await db.delete(db.assetEntries).go();
    await db.delete(db.syncLog).go();
  });

  AssetDataDomain entry(
    String id, {
    String assetId = 'BTC',
    String name = 'Bitcoin',
    DateTime? date,
    double value = 100,
    double quantity = 1.0,
    String? assetType = 'crypto',
    String? description,
    String currency = 'EUR',
    String? account,
    String source = 'manual',
    int preset = 1,
  }) => AssetDataDomain(
    id: id,
    assetId: assetId,
    name: name,
    date: date ?? DateTime(2024, 1, 1),
    value: value,
    quantity: quantity,
    assetType: assetType,
    description: description,
    currency: currency,
    accountId: account,
    source: source,
    preset: preset,
  );

  Future<List<SyncLogData>> assetLogs() =>
      (db.select(db.syncLog)
            ..where((l) => l.changedTableName.equals('asset_entries')))
          .get();

  Future<AssetEntry> row(String id) =>
      (db.select(db.assetEntries)..where((e) => e.id.equals(id))).getSingle();

  group('addAssetData', () {
    test('round-trips every field it was given', () async {
      await repo.addAssetData(
        entry(
          'e1',
          assetId: 'ETH',
          name: 'Ether',
          date: DateTime(2024, 3, 4),
          value: 1234.56,
          quantity: 2.5,
          assetType: 'crypto',
          description: 'cold wallet',
          currency: 'USD',
          account: accountId,
          source: 'coingecko',
          preset: 7,
        ),
      );

      final read = (await repo.getAssetData()).single;
      expect(read.id, 'e1');
      expect(read.assetId, 'ETH');
      expect(read.name, 'Ether');
      expect(read.date, DateTime(2024, 3, 4));
      expect(read.value, 1234.56);
      expect(read.quantity, 2.5);
      expect(read.assetType, 'crypto');
      expect(read.description, 'cold wallet');
      expect(read.currency, 'USD');
      expect(read.accountId, accountId);
      expect(read.source, 'coingecko');
      expect(read.preset, 7);
    });

    test('round-trips the nullable fields as null', () async {
      await repo.addAssetData(
        entry('e1', assetType: null, description: null, account: null),
      );

      final read = (await repo.getAssetData()).single;
      expect(read.assetType, isNull);
      expect(read.description, isNull);
      expect(read.accountId, isNull);
    });

    test('keeps a fractional crypto quantity as a raw double', () async {
      // Asset holdings are deliberately NOT minor units: 0.00000001 BTC has to
      // survive the round-trip untouched.
      await repo.addAssetData(entry('e1', quantity: 0.00000001, value: 0.0007));

      final read = (await repo.getAssetData()).single;
      expect(read.quantity, 0.00000001);
      expect(read.value, 0.0007);
    });

    test('mints an id when none was supplied', () async {
      await repo.addAssetData(
        AssetDataDomain(
          assetId: 'BTC',
          name: 'Bitcoin',
          date: DateTime(2024, 1, 1),
          value: 1,
          source: 'manual',
        ),
      );

      final read = (await repo.getAssetData()).single;
      expect(read.id, isNotNull);
      // The generated id, not a null, is what has to reach sync_log.
      expect((await assetLogs()).single.recordId, read.id);
    });

    test('stamps modifiedAt and logs an upsert under asset_entries', () async {
      final before = DateTime.now().millisecondsSinceEpoch;

      await repo.addAssetData(entry('e1'));

      expect((await row('e1')).modifiedAt, greaterThanOrEqualTo(before));
      final logs = await assetLogs();
      expect(logs.map((l) => '${l.recordId}:${l.action}'), ['e1:upsert']);
      expect(logs.single.exported, isFalse);
    });
  });

  group('updateAssetData', () {
    test('persists the new values, bumps modifiedAt and logs an upsert',
        () async {
      await repo.addAssetData(entry('e1', value: 100));
      final oldModified = (await row('e1')).modifiedAt;
      await db.delete(db.syncLog).go();
      await Future<void>.delayed(const Duration(milliseconds: 5));

      await repo.updateAssetData(entry('e1', value: 250, name: 'Bitcoin XL'));

      final read = (await repo.getAssetData()).single;
      expect(read.value, 250);
      expect(read.name, 'Bitcoin XL');
      // A stale modifiedAt would lose to an older copy on another device.
      expect((await row('e1')).modifiedAt, greaterThan(oldModified));
      expect((await assetLogs()).map((l) => l.action), ['upsert']);
    });
  });

  group('soft delete', () {
    setUp(() async {
      await repo.addAssetData(entry('live'));
      await repo.addAssetData(entry('gone', assetId: 'DOGE', name: 'Doge'));
      await repo.deleteAssetData('gone');
      await db.delete(db.syncLog).go();
    });

    test('a deleted entry is not returned by getAssetData', () async {
      expect((await repo.getAssetData()).map((e) => e.id), ['live']);
      // The row is still physically present.
      expect((await row('gone')).isDeleted, isTrue);
    });

    test('a deleted entry is not counted by getAssetDataCount', () async {
      expect(await repo.getAssetDataCount(), 1);
    });

    test('a deleted entry is not emitted by watchAssetData', () async {
      expect((await repo.watchAssetData().first).map((e) => e.id), ['live']);
    });

    // BUG (characterisation): AssetEntriesDao.getAvailableAssetIds
    // (lib/core/database/app_database.dart:3176) builds its DISTINCT query
    // without `where(isDeleted.equals(false))`, unlike every other read in the
    // same DAO.
    // CORRECT behaviour: a deleted entry's asset id should disappear from the
    // filter options once it is the last entry for that asset. As written, the
    // asset filter dropdown keeps offering 'DOGE' forever, and picking it
    // returns an empty list — a dead option the user cannot get rid of.
    test(
      'a deleted entry still contributes its asset id to getAvailableAssetIds '
      '(WRONG - deleted rows should be excluded)',
      () async {
        expect(await repo.getAvailableAssetIds(), containsAll(['BTC', 'DOGE']));
      },
    );

    // BUG (characterisation): same omission in getAvailableAssetTypes
    // (app_database.dart:3186) — it filters `assetType.isNotNull()` but not
    // `isDeleted`. Same user-visible dead filter option.
    test(
      'a deleted entry still contributes its type to getAvailableAssetTypes '
      '(WRONG - deleted rows should be excluded)',
      () async {
        await repo.addAssetData(entry('other', assetType: 'stock'));
        await repo.deleteAssetData('other');

        expect(await repo.getAvailableAssetTypes(), contains('stock'));
      },
    );

    // BUG (characterisation): same omission in getAvailableSources
    // (app_database.dart:3197).
    test(
      'a deleted entry still contributes its source to getAvailableSources '
      '(WRONG - deleted rows should be excluded)',
      () async {
        await repo.addAssetData(entry('other', source: 'binance'));
        await repo.deleteAssetData('other');

        expect(await repo.getAvailableSources(), contains('binance'));
      },
    );

    // BUG (characterisation): same omission in getAvailablePresets
    // (app_database.dart:3208).
    test(
      'a deleted entry still contributes its preset to getAvailablePresets '
      '(WRONG - deleted rows should be excluded)',
      () async {
        await repo.addAssetData(entry('other', preset: 42));
        await repo.deleteAssetData('other');

        expect(await repo.getAvailablePresets(), contains(42));
      },
    );

    test('deleteAssetData logs a delete under asset_entries', () async {
      await repo.addAssetData(entry('e3'));
      await db.delete(db.syncLog).go();

      await repo.deleteAssetData('e3');

      expect(
        (await assetLogs()).map((l) => '${l.recordId}:${l.action}'),
        ['e3:delete'],
      );
    });

    test('deleteAssetData on an unknown id writes no sync_log row', () async {
      await repo.deleteAssetData('no-such-entry');

      // Announcing a delete for a record that never existed would let a peer
      // wipe whatever it happens to hold under that id.
      expect(await assetLogs(), isEmpty);
    });
  });

  group('deleteAssets', () {
    test('soft-deletes every listed id and logs each one', () async {
      await repo.addAssetData(entry('e1'));
      await repo.addAssetData(entry('e2'));
      await repo.addAssetData(entry('e3'));
      await db.delete(db.syncLog).go();

      await repo.deleteAssets(['e1', 'e2']);

      expect((await repo.getAssetData()).map((e) => e.id), ['e3']);
      expect(
        (await assetLogs()).map((l) => '${l.recordId}:${l.action}'),
        containsAll(['e1:delete', 'e2:delete']),
      );
    });

    // BUG (characterisation): AssetEntriesDao.deleteAssets
    // (lib/core/database/app_database.dart:3133-3142) calls `_logChanges(ids,
    // 'delete')` for the whole list without checking how many rows the update
    // actually touched, while the single-row deleteAssetEntry (line 3127) does
    // guard on `result > 0`.
    // CORRECT behaviour: only ids that really existed should be announced. As
    // written, a bulk delete containing a stale id tells every other device to
    // delete that id, so an entry that exists only on the peer is destroyed.
    test(
      'an id that does not exist is still announced as a delete '
      '(WRONG - only rows that were touched should be logged)',
      () async {
        await repo.deleteAssets(['ghost']);

        expect((await assetLogs()).map((l) => l.recordId), ['ghost']);
      },
    );
  });

  group('filtering', () {
    setUp(() async {
      await repo.addAssetData(
        entry(
          'btc',
          assetId: 'BTC',
          name: 'Bitcoin',
          date: DateTime(2024, 1, 10),
          value: 100,
          assetType: 'crypto',
          description: 'ledger',
          currency: 'EUR',
          account: accountId,
          source: 'manual',
          preset: 1,
        ),
      );
      await repo.addAssetData(
        entry(
          'eth',
          assetId: 'ETH',
          name: 'Ether',
          date: DateTime(2024, 2, 10),
          value: 200,
          assetType: 'crypto',
          currency: 'USD',
          source: 'coingecko',
          preset: 2,
        ),
      );
      await repo.addAssetData(
        entry(
          'gold',
          assetId: 'XAU',
          name: 'Gold',
          date: DateTime(2024, 3, 10),
          value: 300,
          assetType: 'commodity',
          currency: 'EUR',
          source: 'manual',
          preset: 2,
        ),
      );
    });

    test('results are newest first by default', () async {
      expect((await repo.getAssetData()).map((e) => e.id), [
        'gold',
        'eth',
        'btc',
      ]);
    });

    test('sortAscending flips the date ordering', () async {
      expect(
        (await repo.getAssetData(sortAscending: true)).map((e) => e.id),
        ['btc', 'eth', 'gold'],
      );
    });

    test('limit and offset page through the ordered results', () async {
      expect((await repo.getAssetData(limit: 2)).map((e) => e.id), [
        'gold',
        'eth',
      ]);
      expect(
        (await repo.getAssetData(limit: 2, offset: 2)).map((e) => e.id),
        ['btc'],
      );
    });

    test('assetId selects one asset exactly, not a substring', () async {
      expect((await repo.getAssetData(assetId: 'ETH')).map((e) => e.id), [
        'eth',
      ]);
    });

    test('accountId selects entries attached to that account', () async {
      expect(
        (await repo.getAssetData(accountId: accountId)).map((e) => e.id),
        ['btc'],
      );
    });

    test('the date range is inclusive on both ends', () async {
      final found = await repo.getAssetData(
        startDate: DateTime(2024, 1, 10),
        endDate: DateTime(2024, 2, 10),
        sortAscending: true,
      );

      expect(found.map((e) => e.id), ['btc', 'eth']);
    });

    test('name matches a substring', () async {
      expect((await repo.getAssetData(name: 'ther')).map((e) => e.id), ['eth']);
    });

    test('description matches a substring', () async {
      expect(
        (await repo.getAssetData(description: 'edge')).map((e) => e.id),
        ['btc'],
      );
    });

    test('assetTypes accepts several values at once', () async {
      expect(
        (await repo.getAssetData(assetTypes: ['commodity'])).map((e) => e.id),
        ['gold'],
      );
      expect(
        (await repo.getAssetData(
          assetTypes: ['crypto', 'commodity'],
        )).length,
        3,
      );
    });

    test('currencyCodes restricts to the listed currencies', () async {
      expect(
        (await repo.getAssetData(
          currencyCodes: ['USD'],
        )).map((e) => e.id),
        ['eth'],
      );
    });

    test('sources restricts to the listed sources', () async {
      expect(
        (await repo.getAssetData(sources: ['coingecko'])).map((e) => e.id),
        ['eth'],
      );
    });

    test('presets restricts to the listed presets', () async {
      expect(
        (await repo.getAssetData(presets: [2], sortAscending: true)).map(
          (e) => e.id,
        ),
        ['eth', 'gold'],
      );
    });

    test('minValue and maxValue are inclusive', () async {
      expect(
        (await repo.getAssetData(
          minValue: 200,
          maxValue: 300,
          sortAscending: true,
        )).map((e) => e.id),
        ['eth', 'gold'],
      );
    });

    test('an empty filter list is treated as no filter', () async {
      final found = await repo.getAssetData(
        assetTypes: [],
        sources: [],
        presets: [],
        currencyCodes: [],
        name: '',
        description: '',
      );

      expect(found.length, 3);
    });

    test('filters compose with AND, not OR', () async {
      final found = await repo.getAssetData(
        assetTypes: ['crypto'],
        currencyCodes: ['EUR'],
      );

      expect(found.map((e) => e.id), ['btc']);
    });

    test('getAssetDataCount counts the same rows the filtered read returns',
        () async {
      final filtered = await repo.getAssetData(
        assetTypes: ['crypto'],
        limit: 1,
      );
      final count = await repo.getAssetDataCount(assetTypes: ['crypto']);

      // The count must ignore the page size, or paging shows the wrong total.
      expect(filtered.length, 1);
      expect(count, 2);
    });

    test('watchAssetData re-emits after a write', () async {
      final emissions = repo
          .watchAssetData(assetTypes: ['commodity'])
          .take(2)
          .toList();

      await repo.addAssetData(
        entry('silver', assetId: 'XAG', name: 'Silver', assetType: 'commodity'),
      );

      final result = await emissions;
      expect(result.first.map((e) => e.id), ['gold']);
      expect(result.last.map((e) => e.id), containsAll(['gold', 'silver']));
    });
  });
}
