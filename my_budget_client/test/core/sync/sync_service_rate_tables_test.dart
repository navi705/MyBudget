import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/sync/sync_binary_format.dart';
import 'package:my_budget_client/core/sync/sync_service.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';

/// `exchange_rates`, `inflation_rates` and `custom_themes` travelling end to
/// end over the folder-based P2P engine.
///
/// The regression these tests exist for: all three tables have DAOs that write
/// `sync_log` rows, but `SyncService` had no case for them in
/// `_getBulkRecordData`, so every one of those pending upserts came back with a
/// null payload, hit the `continue` in `_exportPendingChanges` - and was then
/// marked exported along with the rest of the batch. A hand-entered exchange
/// rate, inflation rate or custom theme was silently dropped and never retried,
/// so it reached no peer, ever. Deletes did travel (a delete change carries
/// only its clock) but the receiving peer's `_softDeleteRecord` fell through to
/// `default: break` and did nothing with them.
///
/// Two devices share one folder, mirroring how Syncthing hands a `.sync` file
/// to every peer watching the same directory: A always exports, B always
/// imports.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory syncFolder;
  late AppDatabase dbA;
  late AppDatabase dbB;
  late SyncService serviceA;
  late SyncService serviceB;

  Future<SyncService> configuredService(AppDatabase db, String deviceId) async {
    await db.settingsDao.setSetting(
      SettingsCompanion(
        key: const Value('local_device_id'),
        value: Value(deviceId),
      ),
    );
    final service = SyncService(db);
    // startSync() sets the folder + device id and does one initial import
    // pass; stopSync() immediately kills the periodic export Timer and the
    // Directory.watch() subscription so the test controls timing exactly via
    // exportNow()/importNow(), neither of which checks _isRunning.
    await service.startSync(syncFolder.path);
    await service.stopSync();
    return service;
  }

  // setUpAll, not setUp: AppDatabase.forTesting() seeds hundreds of thousands
  // of exchange rate rows on every call. Every test below works on its own
  // record ids (distinct dates, presets and theme ids), so one shared pair of
  // devices is enough and keeps this suite's runtime sane.
  setUpAll(() async {
    syncFolder = await Directory.systemTemp.createTemp(
      'mybudget_sync_rate_tables_',
    );
    dbA = AppDatabase.forTesting(NativeDatabase.memory());
    dbB = AppDatabase.forTesting(NativeDatabase.memory());
    serviceA = await configuredService(dbA, 'device-a');
    serviceB = await configuredService(dbB, 'device-b');

    // Currency codes are compared byte for byte by SQLite and are a foreign
    // key, so a lowercase-coded currency has to exist before a rate can point
    // at it. CSV import really does auto-create currencies like this.
    // insertSyncedCurrency is the non-logging variant, so this setup adds no
    // pending changes of its own.
    final languageCode = (await dbA.select(dbA.currencies).get())
        .first
        .languageCode;
    await dbA.currenciesDao.insertSyncedCurrency(
      CurrenciesCompanion.insert(
        name: 'Lowercase Test Dollar',
        code: 'usd',
        languageCode: languageCode,
      ),
    );
    await dbA.currenciesDao.insertSyncedCurrency(
      CurrenciesCompanion.insert(
        name: 'Lowercase Test Euro',
        code: 'eur',
        languageCode: languageCode,
      ),
    );
  });

  tearDownAll(() async {
    await dbA.close();
    await dbB.close();
    if (await syncFolder.exists()) {
      await syncFolder.delete(recursive: true);
    }
  });

  Future<Set<String>> syncFileNames() async {
    final entities = await syncFolder.list().toList();
    return {
      for (final e in entities)
        if (e is File && e.path.endsWith('.sync')) e.uri.pathSegments.last,
    };
  }

  /// Exports A's pending changes and returns the packet that was written, so a
  /// test can assert on what actually left the device rather than only on what
  /// arrived.
  Future<SyncPacket> exportFromA() async {
    // Files are named '${deviceId}_$timestamp.sync'. Two exports inside one
    // millisecond would reuse a name, and B skips a file name it has already
    // processed - so give the clock room to move.
    await Future<void>.delayed(const Duration(milliseconds: 5));

    final before = await syncFileNames();
    await serviceA.exportNow();
    final written = (await syncFileNames()).difference(before);
    expect(
      written,
      hasLength(1),
      reason: 'exportNow() must have written exactly one packet',
    );

    // _exportPendingChanges already marks the batch exported; this is belt and
    // braces so one test's changes can never be re-bundled into a later test's
    // packet with a fresh clock.
    await dbA.customStatement(
      'UPDATE sync_log SET exported = 1 WHERE exported = 0',
    );

    final bytes = await File(
      '${syncFolder.path}/${written.single}',
    ).readAsBytes();
    return SyncBinaryFormat.decode(bytes);
  }

  Future<SyncPacket> syncAToB() async {
    final packet = await exportFromA();
    await serviceB.importNow();
    return packet;
  }

  SyncChange? changeFor(
    SyncPacket packet,
    SyncTableId tableId,
    String recordId,
  ) {
    for (final change in packet.changes) {
      if (change.tableId == tableId && change.recordId == recordId) {
        return change;
      }
    }
    return null;
  }

  /// The clock a delete travels with: the `sync_log` row's own timestamp, not
  /// the batch clock. Read back rather than hand-picked so the assertions match
  /// what the peer really compared against.
  Future<int> deleteLogTimestamp(String tableName, String recordId) async {
    final log =
        await (dbA.select(dbA.syncLog)..where(
              (t) =>
                  t.changedTableName.equals(tableName) &
                  t.recordId.equals(recordId) &
                  t.action.equals('delete'),
            ))
            .getSingle();
    return log.timestamp;
  }

  Future<ExchangeRate?> rateOnB(
    String from,
    String to,
    DateTime date,
    int preset,
  ) => (dbB.select(dbB.exchangeRates)..where(
        (t) =>
            t.fromCurrencyCode.equals(from) &
            t.toCurrencyCode.equals(to) &
            t.date.equals(date) &
            t.preset.equals(preset),
      ))
      .getSingleOrNull();

  Future<InflationRate?> inflationOnB(
    DateTime date,
    String country,
    int preset,
  ) => (dbB.select(dbB.inflationRates)..where(
        (t) =>
            t.date.equals(date) &
            t.country.equals(country) &
            t.preset.equals(preset),
      ))
      .getSingleOrNull();

  /// Raw row, bypassing `getThemeById`'s `isDeleted = false` filter, so a
  /// tombstone is visible to the assertions.
  Future<DbCustomTheme?> themeRowOnB(String id) =>
      (dbB.select(dbB.customThemes)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  ExchangeRatesCompanion rate({
    required String from,
    required String to,
    required double value,
    required int preset,
    required DateTime date,
  }) => ExchangeRatesCompanion.insert(
    fromCurrencyCode: from,
    toCurrencyCode: to,
    rate: value,
    preset: preset,
    date: date,
  );

  CustomThemesCompanion theme(String id, String name) =>
      CustomThemesCompanion.insert(
        id: Value(id),
        name: name,
        primaryColorHex: '#112233',
        secondaryColorHex: '#445566',
        surfaceColorHex: '#778899',
        backgroundColorHex: '#AABBCC',
        windowEffectType: 2,
        themeMode: 1,
      );

  /// The same theme as [theme] under a new name, as a full companion.
  ///
  /// `CustomThemesDao.updateTheme` runs `UpdateStatement.replace`, which
  /// rewrites the entire row, so a partial companion fails verification rather
  /// than patching a single column.
  CustomThemesCompanion editedTheme(String id, String name) =>
      CustomThemesCompanion(
        id: Value(id),
        name: Value(name),
        primaryColorHex: const Value('#112233'),
        secondaryColorHex: const Value('#445566'),
        surfaceColorHex: const Value('#778899'),
        backgroundColorHex: const Value('#AABBCC'),
        windowEffectType: const Value(2),
        themeMode: const Value(1),
        isDeleted: const Value(false),
      );

  group('export: the change actually reaches the packet', () {
    test('a manually added exchange rate survives export', () async {
      final date = DateTime(2099, 1, 15);
      await dbA.exchangeRatesDao.addExchangeRate(
        rate(from: 'USD', to: 'EUR', value: 1.25, preset: 1, date: date),
      );

      final packet = await exportFromA();
      final change = changeFor(
        packet,
        SyncTableId.exchangeRates,
        'USD_EUR_2099-01-15_1',
      );

      expect(
        change,
        isNotNull,
        reason:
            'the rate was logged for sync but dropped at export time, which is '
            'exactly the data loss this suite guards',
      );
      expect(change!.action, SyncAction.upsert);
      expect(change.data, isNotNull);
      expect(change.data!['fromCurrencyCode'], 'USD');
      expect(change.data!['toCurrencyCode'], 'EUR');
      expect(change.data!['rate'], 1.25);
      expect(change.data!['preset'], 1);
      // _applyChange reads modifiedAt as an int and collapses a missing one to
      // 0, which would lose every last-write-wins comparison on the peer.
      expect(change.data!['modifiedAt'], isA<int>());
      expect(change.data!['modifiedAt'], greaterThan(0));
    });

    test('a manually added inflation rate survives export', () async {
      final date = DateTime(2099, 2, 1);
      await dbA.inflationRatesDao.insertInflationRate(
        InflationRatesCompanion.insert(
          date: date,
          percent: 3.5,
          preset: 1,
          country: const Value('Japan'),
        ),
      );

      final packet = await exportFromA();
      final change = changeFor(
        packet,
        SyncTableId.inflationRates,
        '2099-02-01_Japan_1',
      );

      expect(change, isNotNull);
      expect(change!.action, SyncAction.upsert);
      expect(change.data!['percent'], 3.5);
      expect(change.data!['country'], 'Japan');
      expect(change.data!['preset'], 1);
      expect(change.data!['modifiedAt'], isA<int>());
      expect(change.data!['modifiedAt'], greaterThan(0));
    });

    test('a newly created custom theme survives export', () async {
      await dbA.customThemesDao.insertTheme(theme('theme-export', 'Exported'));

      final packet = await exportFromA();
      final change = changeFor(
        packet,
        SyncTableId.customThemes,
        'theme-export',
      );

      expect(change, isNotNull);
      expect(change!.action, SyncAction.upsert);
      expect(change.data!['name'], 'Exported');
      expect(change.data!['primaryColorHex'], '#112233');
      expect(change.data!['modifiedAt'], isA<int>());
      expect(change.data!['modifiedAt'], greaterThan(0));
    });
  });

  group('round trip: the row lands on the peer', () {
    test('an exchange rate with a lowercase currency pair', () async {
      // Codes are stored and matched byte for byte, so a pair the record id
      // spells in lowercase must not be normalised anywhere along the way.
      final date = DateTime(2099, 3, 1);
      await dbA.exchangeRatesDao.addExchangeRate(
        rate(from: 'usd', to: 'eur', value: 1.5, preset: 4, date: date),
      );

      final packet = await syncAToB();
      expect(
        changeFor(packet, SyncTableId.exchangeRates, 'usd_eur_2099-03-01_4'),
        isNotNull,
      );

      final row = await rateOnB('usd', 'eur', date, 4);
      expect(row, isNotNull);
      expect(row!.rate, 1.5);
      expect(row.date, date);
      expect(row.preset, 4);
      expect(row.modifiedAt, greaterThan(0));
    });

    test('an exchange rate whose date carries a time of day', () async {
      // The record id spells the date only to the day, while the column stores
      // a full DateTime and not every caller normalises to midnight. Matching
      // the id against an exact midnight instant would find nothing and the row
      // would be dropped at export all over again.
      final date = DateTime(2099, 3, 5, 14, 30);
      await dbA.exchangeRatesDao.addExchangeRate(
        rate(from: 'USD', to: 'EUR', value: 1.75, preset: 5, date: date),
      );

      final packet = await syncAToB();
      expect(
        changeFor(packet, SyncTableId.exchangeRates, 'USD_EUR_2099-03-05_5'),
        isNotNull,
        reason: 'a non-midnight rate must still match its day-granular id',
      );

      final row = await rateOnB('USD', 'EUR', date, 5);
      expect(row, isNotNull);
      expect(row!.rate, 1.75);
      expect(
        row.date,
        date,
        reason: 'the exact instant travels in the payload, not just the day',
      );
    });

    test('a worldwide inflation rate keeps the global sentinel', () async {
      // The UI models "worldwide" as an absent country; the column and the
      // record id both spell it as the globalInflationCountry sentinel.
      final date = DateTime(2099, 4, 1);
      await dbA.inflationRatesDao.insertInflationRate(
        InflationRatesCompanion.insert(date: date, percent: 2.75, preset: 1),
      );

      final packet = await syncAToB();
      expect(
        changeFor(
          packet,
          SyncTableId.inflationRates,
          '2099-04-01_${globalInflationCountry}_1',
        ),
        isNotNull,
      );

      final row = await inflationOnB(date, globalInflationCountry, 1);
      expect(row, isNotNull);
      expect(row!.percent, 2.75);
      expect(row.country, globalInflationCountry);
      expect(row.date, date);
    });

    test('an inflation rate with a non-ASCII country', () async {
      final date = DateTime(2099, 4, 2);
      await dbA.inflationRatesDao.insertInflationRate(
        InflationRatesCompanion.insert(
          date: date,
          percent: 8.25,
          preset: 1,
          country: const Value('Россия'),
        ),
      );

      final packet = await syncAToB();
      expect(
        changeFor(packet, SyncTableId.inflationRates, '2099-04-02_Россия_1'),
        isNotNull,
      );

      final row = await inflationOnB(date, 'Россия', 1);
      expect(row, isNotNull);
      expect(row!.percent, 8.25);
    });

    test('a custom theme lands with every column intact', () async {
      await dbA.customThemesDao.insertTheme(
        CustomThemesCompanion.insert(
          id: const Value('theme-roundtrip'),
          name: 'Round Trip',
          primaryColorHex: '#010203',
          secondaryColorHex: '#040506',
          surfaceColorHex: '#070809',
          backgroundColorHex: '#0A0B0C',
          backgroundImagePath: const Value('/tmp/bg.png'),
          backgroundImageOpacity: const Value(0.42),
          backgroundImageBlur: const Value(3.5),
          windowEffectType: 2,
          effectOpacity: const Value(0.8),
          surfaceOpacity: const Value(0.9),
          themeMode: 2,
          isPreset: const Value(true),
          isActive: const Value(true),
        ),
      );

      await syncAToB();

      final row = await themeRowOnB('theme-roundtrip');
      expect(row, isNotNull);
      expect(row!.name, 'Round Trip');
      expect(row.primaryColorHex, '#010203');
      expect(row.secondaryColorHex, '#040506');
      expect(row.surfaceColorHex, '#070809');
      expect(row.backgroundColorHex, '#0A0B0C');
      expect(row.backgroundImagePath, '/tmp/bg.png');
      expect(row.backgroundImageOpacity, 0.42);
      expect(row.backgroundImageBlur, 3.5);
      expect(row.windowEffectType, 2);
      expect(row.effectOpacity, 0.8);
      expect(row.surfaceOpacity, 0.9);
      expect(row.themeMode, 2);
      expect(row.isPreset, isTrue);
      // setActiveTheme logs every row whose flag changed, so a peer that did
      // not receive isActive would end up with two active themes.
      expect(row.isActive, isTrue);
      expect(row.isDeleted, isFalse);
      expect(row.modifiedAt, greaterThan(0));
    });
  });

  group('delete: exchange_rates and inflation_rates have no tombstone', () {
    test('an incoming delete removes the local exchange rate', () async {
      final date = DateTime(2099, 5, 1);
      await dbA.exchangeRatesDao.addExchangeRate(
        rate(from: 'USD', to: 'GBP', value: 1.1, preset: 1, date: date),
      );
      await syncAToB();
      expect(await rateOnB('USD', 'GBP', date, 1), isNotNull);

      // replaceExchangeRate is the DAO path that logs a delete for this table:
      // it drops the original row and logs delete(originalId) + upsert(newId)
      // whenever the composite key changes.
      await dbA.exchangeRatesDao.replaceExchangeRate(
        ExchangeRateDomain(
          fromCurrencyCode: 'USD',
          toCurrencyCode: 'GBP',
          preset: 1,
          rate: 1.1,
          date: date,
        ),
        rate(from: 'USD', to: 'GBP', value: 1.2, preset: 2, date: date),
      );

      final packet = await syncAToB();
      expect(
        changeFor(
          packet,
          SyncTableId.exchangeRates,
          'USD_GBP_2099-05-01_1',
        )?.action,
        SyncAction.delete,
      );

      expect(
        await rateOnB('USD', 'GBP', date, 1),
        isNull,
        reason:
            'exchange_rates has no isDeleted column, so the delete has to be a '
            'real DELETE - a silent no-op would leave the peer showing a rate '
            'the user removed',
      );
      expect((await rateOnB('USD', 'GBP', date, 2))!.rate, 1.2);
    });

    test('a stale delete leaves a newer local exchange rate alone', () async {
      final date = DateTime(2099, 6, 1);
      await dbA.exchangeRatesDao.addExchangeRate(
        rate(from: 'USD', to: 'EUR', value: 2.0, preset: 6, date: date),
      );
      await syncAToB();

      // A delete travels with real wall-clock time (its sync_log timestamp),
      // so "the local row is newer" has to be staged by stamping B's row into
      // the future.
      final future = DateTime.now().millisecondsSinceEpoch + 10000000;
      await (dbB.update(dbB.exchangeRates)..where(
            (t) =>
                t.fromCurrencyCode.equals('USD') &
                t.toCurrencyCode.equals('EUR') &
                t.date.equals(date) &
                t.preset.equals(6),
          ))
          .write(ExchangeRatesCompanion(modifiedAt: Value(future)));

      await dbA.exchangeRatesDao.replaceExchangeRate(
        ExchangeRateDomain(
          fromCurrencyCode: 'USD',
          toCurrencyCode: 'EUR',
          preset: 6,
          rate: 2.0,
          date: date,
        ),
        rate(from: 'USD', to: 'EUR', value: 2.1, preset: 7, date: date),
      );

      final packet = await syncAToB();
      expect(
        changeFor(
          packet,
          SyncTableId.exchangeRates,
          'USD_EUR_2099-06-01_6',
        )?.action,
        SyncAction.delete,
        reason: 'the delete must actually be in the packet for this to mean '
            'anything',
      );

      final survivor = await rateOnB('USD', 'EUR', date, 6);
      expect(
        survivor,
        isNotNull,
        reason: 'a delete older than the local row must lose last-write-wins',
      );
      expect(survivor!.rate, 2.0);
      expect(survivor.modifiedAt, future);
    });

    test('an incoming delete removes the local inflation rate', () async {
      final date = DateTime(2099, 7, 1);
      await dbA.inflationRatesDao.insertInflationRate(
        InflationRatesCompanion.insert(
          date: date,
          percent: 4.2,
          preset: 1,
          country: const Value('Japan'),
        ),
      );
      await syncAToB();
      expect(await inflationOnB(date, 'Japan', 1), isNotNull);

      await dbA.inflationRatesDao.deleteInflationRate(date, 'Japan', 1);

      final packet = await syncAToB();
      expect(
        changeFor(
          packet,
          SyncTableId.inflationRates,
          '2099-07-01_Japan_1',
        )?.action,
        SyncAction.delete,
      );

      expect(
        await inflationOnB(date, 'Japan', 1),
        isNull,
        reason: 'inflation_rates cannot hold a tombstone either, so the row '
            'itself has to go',
      );
    });

    test('a stale delete leaves a newer local inflation rate alone', () async {
      final date = DateTime(2099, 8, 1);
      await dbA.inflationRatesDao.insertInflationRate(
        InflationRatesCompanion.insert(
          date: date,
          percent: 5.5,
          preset: 1,
          country: const Value('Brazil'),
        ),
      );
      await syncAToB();

      final future = DateTime.now().millisecondsSinceEpoch + 10000000;
      await (dbB.update(dbB.inflationRates)..where(
            (t) =>
                t.date.equals(date) &
                t.country.equals('Brazil') &
                t.preset.equals(1),
          ))
          .write(InflationRatesCompanion(modifiedAt: Value(future)));

      await dbA.inflationRatesDao.deleteInflationRate(date, 'Brazil', 1);

      final packet = await syncAToB();
      expect(
        changeFor(
          packet,
          SyncTableId.inflationRates,
          '2099-08-01_Brazil_1',
        )?.action,
        SyncAction.delete,
      );

      final survivor = await inflationOnB(date, 'Brazil', 1);
      expect(
        survivor,
        isNotNull,
        reason: 'a delete older than the local row must lose last-write-wins',
      );
      expect(survivor!.percent, 5.5);
      expect(survivor.modifiedAt, future);
    });
  });

  group('delete: custom_themes does have a tombstone', () {
    test(
      'an incoming delete soft-deletes the theme and a later older upsert does '
      'not resurrect it',
      () async {
        await dbA.customThemesDao.insertTheme(theme('theme-del', 'Doomed'));
        await syncAToB();
        expect((await themeRowOnB('theme-del'))!.isDeleted, isFalse);

        await dbA.customThemesDao.deleteTheme('theme-del');
        final deletedAt = await deleteLogTimestamp('custom_themes', 'theme-del');
        await syncAToB();

        final tombstone = await themeRowOnB('theme-del');
        expect(
          tombstone!.isDeleted,
          isTrue,
          reason: 'custom_themes HAS an isDeleted column, so the delete is a '
              'soft delete like every other synced table',
        );
        expect(
          tombstone.modifiedAt,
          deletedAt,
          reason: 'the tombstone carries the clock the delete happened at, not '
              'the peer\'s own now()',
        );

        // A stale upsert for the same theme - a third device's older edit
        // propagating late. updateTheme() always stamps modifiedAt = now(), so
        // the row is pushed back behind the delete directly afterwards; the
        // export re-reads the row, so that is what the peer is told.
        await dbA.customThemesDao.updateTheme(
          // updateTheme() goes through UpdateStatement.replace, which rewrites
          // the whole row, so every non-defaulted column has to be present.
          editedTheme('theme-del', 'Resurrection Attempt'),
        );
        await (dbA.update(dbA.customThemes)
              ..where((t) => t.id.equals('theme-del')))
            .write(CustomThemesCompanion(modifiedAt: Value(deletedAt - 1000)));

        await syncAToB();

        final after = await themeRowOnB('theme-del');
        expect(
          after!.isDeleted,
          isTrue,
          reason: 'a stale upsert must not resurrect a tombstoned theme',
        );
        expect(after.name, 'Doomed');
      },
    );

    test('a genuinely newer upsert does resurrect a tombstoned theme', () async {
      await dbA.customThemesDao.insertTheme(theme('theme-back', 'Original'));
      await syncAToB();

      await dbA.customThemesDao.deleteTheme('theme-back');
      final deletedAt = await deleteLogTimestamp('custom_themes', 'theme-back');
      await syncAToB();
      expect((await themeRowOnB('theme-back'))!.isDeleted, isTrue);

      await dbA.customThemesDao.updateTheme(
        editedTheme('theme-back', 'Genuinely Newer'),
      );
      await (dbA.update(dbA.customThemes)
            ..where((t) => t.id.equals('theme-back')))
          .write(CustomThemesCompanion(modifiedAt: Value(deletedAt + 1000)));

      await syncAToB();

      final after = await themeRowOnB('theme-back');
      expect(after!.isDeleted, isFalse);
      expect(after.name, 'Genuinely Newer');
      expect(after.modifiedAt, deletedAt + 1000);
    });
  });
}
