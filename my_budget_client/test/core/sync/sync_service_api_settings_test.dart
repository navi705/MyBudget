import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/services/server_sync_service.dart';
import 'package:my_budget_client/core/sync/sync_service.dart';
import 'package:my_budget_client/data/repositories/local_db/local_settings_repository.dart';
import 'package:my_budget_client/domain/entities/settings.dart' as domain;
import 'package:intl/date_symbol_data_local.dart';

/// `api_settings_table` is the row behind each "fetch exchange rates / inflation
/// / asset prices" toggle. It only gained an `isDeleted` column in schema v12;
/// before that a provider the user removed had no tombstone to carry, so the
/// removal could not survive a round trip through either sync engine. Both
/// engines are exercised here because both had to learn the column.
void main() {
  // `sync_record_keys.dart` pins its DateFormat to 'en' so a record id spells
  // the same day on every device, and a pinned locale needs its CLDR data
  // loaded. `app.dart` does this at startup; a bare `flutter test` does not, so
  // every id this suite formats or parses would throw LocaleDataException.
  setUpAll(() async {
    await initializeDateFormatting();
  });

  TestWidgetsFlutterBinding.ensureInitialized();

  group('file sync (SyncService)', () {
    late Directory syncFolder;
    late AppDatabase dbA;
    late AppDatabase dbB;
    late SyncService serviceA;
    late SyncService serviceB;

    Future<SyncService> configuredService(
      AppDatabase db,
      String deviceId,
    ) async {
      await db.settingsDao.setSetting(
        SettingsCompanion(
          key: const Value('local_device_id'),
          value: Value(deviceId),
        ),
      );
      final service = SyncService(db);
      // startSync() does one import pass and arms a periodic export timer;
      // stopSync() kills the timer and the directory watcher so the test drives
      // exportNow()/importNow() itself.
      await service.startSync(syncFolder.path);
      await service.stopSync();
      return service;
    }

    setUp(() async {
      syncFolder = await Directory.systemTemp.createTemp('mybudget_sync_api_');
      dbA = AppDatabase.forTesting(NativeDatabase.memory());
      dbB = AppDatabase.forTesting(NativeDatabase.memory());
      serviceA = await configuredService(dbA, 'device-a');
      serviceB = await configuredService(dbB, 'device-b');
    });

    tearDown(() async {
      await dbA.close();
      await dbB.close();
      if (await syncFolder.exists()) {
        await syncFolder.delete(recursive: true);
      }
    });

    Future<void> syncAToB() async {
      await serviceA.exportNow();
      // markExported() binds one SQL variable per pending row and blows past
      // SQLITE_MAX_VARIABLE_NUMBER on the seeded backlog, so it silently fails
      // after the file has been written. Draining by hand keeps each sync in
      // this test limited to the changes made since the previous one.
      await dbA.customStatement(
        'UPDATE sync_log SET exported = 1 WHERE exported = 0',
      );
      await serviceB.importNow();
    }

    /// Ages B's copy of [id] so the comparison under test is the tombstone
    /// rule, not a race between two seeds that can land in the same
    /// millisecond.
    Future<void> outdateOnB(String id) => dbB.customStatement(
      'UPDATE api_settings_table SET modified_at = 1 WHERE id = ?',
      [id],
    );

    Future<ApiSettingsTableData?> rawOnB(String id) => (dbB.select(
      dbB.apiSettingsTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    test('an edited provider reaches the peer', () async {
      await dbA.apiSettingsDao.upsertSetting(
        const ApiSettingsTableCompanion(
          id: Value('exchange_rates'),
          enabled: Value(false),
          autoFetch: Value(false),
        ),
      );
      await outdateOnB('exchange_rates');

      await syncAToB();

      final applied = await dbB.apiSettingsDao.getSettingById('exchange_rates');
      expect(applied!.enabled, isFalse);
      expect(applied.autoFetch, isFalse);
      expect(applied.isDeleted, isFalse);
    });

    test('a deleted provider is deleted on the peer too', () async {
      await dbA.apiSettingsDao.deleteSetting('exchange_rates');
      await outdateOnB('exchange_rates');

      await syncAToB();

      expect(await dbB.apiSettingsDao.getSettingById('exchange_rates'), isNull);
      expect((await rawOnB('exchange_rates'))!.isDeleted, isTrue);
    });

    test('a delete for a provider the peer never had leaves a tombstone that '
        'an older upsert cannot beat', () async {
      // This is the case the missing column made impossible: with nothing to
      // write the flag on, the delete was a no-op on the peer, and the upsert
      // that had been sitting in an earlier file recreated the provider - so it
      // came back and started fetching again.
      await dbA.apiSettingsDao.upsertSetting(
        const ApiSettingsTableCompanion(
          id: Value('custom-provider'),
          enabled: Value(true),
        ),
      );
      // The upsert never reached B.
      await dbA.customStatement('DELETE FROM sync_log');

      await dbA.apiSettingsDao.deleteSetting('custom-provider');
      await syncAToB();

      final tombstone = await rawOnB('custom-provider');
      expect(tombstone, isNotNull, reason: 'the delete has to leave a mark');
      expect(tombstone!.isDeleted, isTrue);
      expect(tombstone.enabled, isFalse, reason: 'nothing left to fetch from');

      // Now the older upsert finally arrives.
      final deletedAt = (await (dbA.select(
        dbA.apiSettingsTable,
      )..where((t) => t.id.equals('custom-provider'))).getSingle()).modifiedAt;
      await dbA.customStatement(
        'UPDATE api_settings_table SET is_deleted = 0, enabled = 1, '
        'modified_at = ? WHERE id = ?',
        [deletedAt - 1000, 'custom-provider'],
      );
      await dbA
          .into(dbA.syncLog)
          .insert(
            SyncLogCompanion.insert(
              changedTableName: 'api_settings_table',
              recordId: 'custom-provider',
              action: 'upsert',
              timestamp: deletedAt - 1000,
            ),
          );
      await syncAToB();

      expect((await rawOnB('custom-provider'))!.isDeleted, isTrue);
      expect(
        await dbB.apiSettingsDao.getSettingById('custom-provider'),
        isNull,
      );
    });
  });

  group('server sync (ServerSyncService)', () {
    late AppDatabase db;
    late LocalSettingsRepository settingsRepository;
    late ServerSyncService service;
    late List<Map<String, dynamic>> pushBodies;
    late List<Map<String, dynamic>> pages;

    Map<String, dynamic> page(List<Map<String, dynamic>> apiSettings) => {
      'changes': {'api_settings': apiSettings},
      'server_timestamp': 1,
      'has_more': false,
    };

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      db = AppDatabase.forTesting(NativeDatabase.memory());
      // Drift opens lazily; force the seed to run before any watermark is
      // captured, otherwise the seeded rows look newer than it.
      await db.select(db.styles).get();
      settingsRepository = LocalSettingsRepository(db);
      pushBodies = [];
      pages = [];

      final prefs = await SharedPreferences.getInstance();
      // Everything seeded (283k exchange rates included) is older than this, so
      // the push carries only what a test changes afterwards.
      await prefs.setInt(
        'server_last_push_timestamp',
        DateTime.now().millisecondsSinceEpoch,
      );

      await settingsRepository.setSetting(
        const domain.Settings(
          key: 'server_sync_enabled',
          value: 'true',
          device: 'test-device',
        ),
      );

      service = ServerSyncService(
        database: db,
        settingsRepository: settingsRepository,
        httpClient: MockClient((request) async {
          if (request.method == 'POST') {
            pushBodies.add(jsonDecode(request.body) as Map<String, dynamic>);
            return http.Response('{"status":"ok"}', 200);
          }
          return http.Response(
            jsonEncode(pages.isEmpty ? page(const []) : pages.removeAt(0)),
            200,
          );
        }),
      );
    });

    tearDown(() async => db.close());

    Future<ApiSettingsTableData?> raw(String id) => (db.select(
      db.apiSettingsTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    test('a pulled provider marked deleted is removed locally', () async {
      pages = [
        page([
          {
            'id': 'exchange_rates',
            'enabled': true,
            'autoFetch': true,
            'modifiedAt': DateTime.now().millisecondsSinceEpoch + 60000,
            'isDeleted': true,
          },
        ]),
      ];

      await service.sync();

      expect(await db.apiSettingsDao.getSettingById('exchange_rates'), isNull);
      expect((await raw('exchange_rates'))!.isDeleted, isTrue);
    });

    test('a pulled provider from a pre-v12 peer, which sends no flag, is '
        'treated as live', () async {
      pages = [
        page([
          {
            'id': 'exchange_rates',
            'enabled': false,
            'autoFetch': false,
            'modifiedAt': DateTime.now().millisecondsSinceEpoch + 60000,
          },
        ]),
      ];

      await service.sync();

      final applied = await db.apiSettingsDao.getSettingById('exchange_rates');
      expect(applied, isNotNull);
      expect(applied!.enabled, isFalse);
    });

    test(
      'a locally deleted provider is pushed with its tombstone flag',
      () async {
        await db.apiSettingsDao.deleteSetting('exchange_rates');
        // The push window is `modifiedAt > watermark`, and the whole setUp can
        // land in the same millisecond as the delete. Park the watermark just
        // below the tombstone so the row is unambiguously inside the window.
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(
          'server_last_push_timestamp',
          (await raw('exchange_rates'))!.modifiedAt - 1,
        );

        await service.sync();

        final pushed = pushBodies
            .expand(
              (b) => (b['api_settings'] as List? ?? const [])
                  .cast<Map<String, dynamic>>(),
            )
            .where((r) => r['id'] == 'exchange_rates');
        expect(pushed, hasLength(1));
        expect(
          pushed.single['isDeleted'],
          isTrue,
          reason:
              'a push without the flag looks like a live provider to the '
              'server, which hands it straight back to every other device',
        );
      },
    );
  });
}
