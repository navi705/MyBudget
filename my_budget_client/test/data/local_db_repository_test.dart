// Clearing re-seeds the database, including a few hundred thousand exchange
// rates, so the shared setUpAll needs more than the default 30 s budget.
@Timeout(Duration(minutes: 5))
library;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/data/repositories/local_db/local_db_repository.dart';

/// `clearAllDatabase` is the "erase my data" button. It is destructive and
/// irreversible, so what it does and does not touch is pinned here in one
/// place: the clear plus its reseed is expensive, so this file runs it once in
/// setUpAll and the tests assert on the resulting state.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LocalDbRepository repo;
  late int syncLogRowsBeforeClear;

  setUpAll(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalDbRepository(db);

    final designationId =
        (await db.select(db.currencyDesignations).get()).first.id;
    final accountTypeId = (await db.select(db.accountTypes).get()).first.id;

    // A slice of user data across the tables the clear is expected to wipe.
    await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: const Value('acc-1'),
            name: 'Wallet',
            balance: 10,
            balanceMinor: const Value(1000),
            currencyCode: 'EUR',
            currencyDesignationId: designationId,
            accountTypeId: accountTypeId,
          ),
        );
    await db
        .into(db.assetEntries)
        .insert(
          AssetEntriesCompanion.insert(
            id: const Value('asset-1'),
            assetId: 'BTC',
            name: 'Bitcoin',
            date: DateTime(2024, 1, 1),
            value: 100,
            currencyCode: 'EUR',
            source: 'manual',
          ),
        );
    await db
        .into(db.inflationRates)
        .insert(
          InflationRatesCompanion.insert(
            date: DateTime(2024, 1, 1),
            percent: 3,
            preset: 1,
            country: const Value('US'),
          ),
        );
    await db.settingsDao.setSetting(
      SettingsCompanion.insert(key: 'user_key', value: 'user_value'),
    );
    await db.customThemesDao.insertTheme(
      CustomThemesCompanion.insert(
        id: const Value('theme-1'),
        name: 'Mine',
        primaryColorHex: '#FF000000',
        secondaryColorHex: '#FF000000',
        surfaceColorHex: '#FF000000',
        backgroundColorHex: '#FF000000',
        windowEffectType: 0,
        themeMode: 0,
      ),
    );
    await db.customDataSourcesDao.insertDataSource(
      CustomDataSourcesCompanion.insert(
        id: const Value('src-1'),
        name: 'Mine',
        url: 'https://example.test',
        dataType: 0,
      ),
    );
    await db.apiSettingsDao.upsertSetting(
      const ApiSettingsTableCompanion(
        id: Value('exchange_rates'),
        enabled: Value(false),
        autoFetch: Value(false),
      ),
    );

    syncLogRowsBeforeClear = (await db.select(db.syncLog).get()).length;

    await repo.clearAllDatabase();
  });

  tearDownAll(() async => db.close());

  group('clearAllDatabase wipes user data', () {
    test('accounts are gone', () async {
      expect(await db.select(db.accounts).get(), isEmpty);
    });

    test('transactions are gone', () async {
      expect(await db.select(db.transactions).get(), isEmpty);
    });

    test('asset entries are gone', () async {
      expect(await db.select(db.assetEntries).get(), isEmpty);
    });

    test('inflation rates are gone, because they are refetched from the '
        'provider', () async {
      expect(await db.select(db.inflationRates).get(), isEmpty);
    });

    test('a setting the user added is gone, replaced by the seeded '
        'defaults', () async {
      final settings = await db.settingsDao.getAllSettings();
      expect(settings.map((s) => s.key), isNot(contains('user_key')));
      expect(settings.map((s) => s.key), contains('themeMode'));
    });
  });

  group('clearAllDatabase keeps the app usable', () {
    test('the static currency list survives, so accounts can be recreated '
        'straight away', () async {
      expect(await db.select(db.currencies).get(), isNotEmpty);
    });

    test('account types survive', () async {
      expect(await db.select(db.accountTypes).get(), isNotEmpty);
    });

    test('currency designations survive', () async {
      expect(await db.select(db.currencyDesignations).get(), isNotEmpty);
    });

    test('default categories are seeded back', () async {
      expect(await db.select(db.categories).get(), isNotEmpty);
    });

    test('default styles are seeded back', () async {
      expect(await db.select(db.styles).get(), isNotEmpty);
    });

    test('exchange rates are seeded back, so conversion still works '
        'offline', () async {
      expect(await db.select(db.exchangeRates).get(), isNotEmpty);
    });
  });

  group('clearAllDatabase leaves some tables untouched', () {
    test('custom themes survive, so the user keeps the look they '
        'built', () async {
      expect(await db.customThemesDao.getAllThemes(), hasLength(1));
    });

    test('custom data sources survive', () async {
      expect(await db.customDataSourcesDao.getAllDataSources(), hasLength(1));
    });

    test('CHARACTERIZATION: the user\'s API provider toggles are reset to '
        'enabled + auto-fetch', () async {
      // BUG. `clearAllData` does not delete api_settings_table, but its reseed
      // calls `_seedApiSettings`, which upserts every provider back to
      // enabled: true / autoFetch: true. A user who deliberately turned the
      // exchange-rate provider off and then clears their data starts fetching
      // from the network again without being asked. Correct behaviour: seed
      // API settings only for ids that are missing.
      final setting = await db.apiSettingsDao.getSettingById('exchange_rates');
      expect(setting!.enabled, isTrue);
      expect(setting.autoFetch, isTrue);
    });

    test('CHARACTERIZATION: the clear writes no delete rows to sync_log, so '
        'every wiped record comes back from the next sync', () async {
      // BUG. `AppDatabase.clearAllData` deletes with a raw batch and never
      // records tombstones, while the reseed that follows it *does* log
      // upserts for the freshly seeded styles, categories and API settings. On
      // the next sync the peer sends back the accounts, transactions and asset
      // entries this device just erased, and the user watches their data
      // reappear. Correct behaviour: write `delete` rows for every cleared
      // record id (or explicitly reset the sync state and re-pair).
      final logged = await db.select(db.syncLog).get();

      expect(logged.where((l) => l.action == 'delete'), isEmpty);
      expect(
        logged.length,
        greaterThan(syncLogRowsBeforeClear),
        reason: 'the reseed logs upserts even though the wipe logs nothing',
      );
    });
  });

  group('batch', () {
    test('runs every statement handed to it', () async {
      await repo.batch((batch) {
        batch.insertAll(db.settings, [
          SettingsCompanion.insert(key: 'batch_a', value: '1'),
          SettingsCompanion.insert(key: 'batch_b', value: '2'),
        ]);
      });

      final settings = await db.settingsDao.getAllSettings();
      expect(settings.map((s) => s.key), containsAll(['batch_a', 'batch_b']));
    });

    test('a batch that throws leaves none of its statements applied', () async {
      // Callers use this for imports; a half-applied import would be worse
      // than a failed one. Note the builder runs synchronously inside `batch`,
      // so the error surfaces before `batch` returns a future at all - hence
      // the closure.
      await expectLater(
        () => repo.batch((batch) {
          batch.insert(
            db.settings,
            SettingsCompanion.insert(key: 'batch_c', value: '1'),
          );
          throw StateError('import failed halfway');
        }),
        throwsA(isA<StateError>()),
      );

      expect(await db.settingsDao.getSetting('batch_c'), isNull);
    });
  });
}
