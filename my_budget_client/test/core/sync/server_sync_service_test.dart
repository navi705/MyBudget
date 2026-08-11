import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/services/server_sync_service.dart';
import 'package:my_budget_client/data/repositories/local_db/local_settings_repository.dart';
import 'package:my_budget_client/domain/entities/settings.dart' as domain;

/// [ServerSyncService]'s wire-mapping logic (`_upsertTransaction`,
/// `_upsertAccount`, `_applyChanges`, `_pull`, `_push`) is private and
/// reachable only through [ServerSyncService.sync], which makes a real
/// `http.get`/`http.post` call at the top level of server_sync_service.dart
/// (not through an injectable `http.Client`). That combination makes it
/// impossible to exercise from a test without either hitting the network or
/// editing lib/ - see the REPORT for the finding and the smallest fix.
///
/// What remains testable from here: [ServerSyncService.getPendingChangesCount]
/// (a pure DB read gated by a SharedPreferences watermark, no network) and
/// [ServerSyncService.sync]'s early-return path when server sync is
/// disabled (proving it neither throws nor attempts a network call).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LocalSettingsRepository settingsRepository;
  late ServerSyncService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // Drift opens the connection lazily: onCreate/_seedData (which stamps
    // every seeded row, including all 283k exchange rates, with
    // DateTime.now() at seed time) does not actually run until the first
    // real query touches the DB. Force that here, before any test captures
    // a DateTime.now() watermark - otherwise seeding can run *after* the
    // watermark is captured, making seeded rows look newer than the
    // watermark and breaking every "pending changes" assertion below.
    await db.select(db.styles).get();
    settingsRepository = LocalSettingsRepository(db);
    service = ServerSyncService(
      database: db,
      settingsRepository: settingsRepository,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('sync() disabled path', () {
    test('returns immediately, without a network call, when no server_sync_enabled setting exists', () async {
      // _isEnabled() reads server_sync_enabled and treats anything other
      // than the literal string 'true' (including a missing setting) as
      // disabled - there is nothing here for sync() to reach the network
      // with, so a real http call would only happen if this test hangs or
      // throws a SocketException.
      await expectLater(service.sync(), completes);
    });

    test('stays disabled - and network-free - for any value other than the literal "true"', () async {
      await settingsRepository.setSetting(
        const domain.Settings(
          key: 'server_sync_enabled',
          value: 'false',
          device: 'test-device',
        ),
      );

      await expectLater(service.sync(), completes);
    });
  });

  group('getPendingChangesCount', () {
    Future<void> setWatermark(int value) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('server_last_push_timestamp', value);
    }

    test('is 0 once the watermark is at least as new as everything seeded', () async {
      // Drift opens its connection lazily: setUp()'s forcing query
      // (db.select(db.styles).get()) is what guarantees seeding has already
      // run by the time this watermark is captured. Without it, seeding
      // (which stamps every row with DateTime.now() at seed time) can run
      // *after* this watermark, making seeded rows look newer than it.
      final watermark = DateTime.now().millisecondsSinceEpoch;
      await setWatermark(watermark);

      expect(await service.getPendingChangesCount(), 0);
    });

    test('counts a row inserted after the watermark, summed across tables', () async {
      final watermark = DateTime.now().millisecondsSinceEpoch;
      await setWatermark(watermark);
      expect(await service.getPendingChangesCount(), 0);

      await db.stylesDao.insertStyle(
        StylesCompanion.insert(
          id: const Value('s1'),
          name: 'New Style',
          iconName: 'star',
          colorHex: '#123456',
        ),
      );
      expect(await service.getPendingChangesCount(), 1);

      await db.accountTypesDao.insertAccountType(
        AccountTypesCompanion.insert(
          id: const Value('at1'),
          name: 'New Account Type',
          languageCode: 'en',
        ),
      );
      expect(
        await service.getPendingChangesCount(),
        2,
        reason: 'the count sums matching rows across every synced table, not just one',
      );
    });

    test('a row modified exactly at the watermark is not counted (comparison is strict)', () async {
      await db.stylesDao.insertStyle(
        StylesCompanion.insert(
          id: const Value('s1'),
          name: 'New Style',
          iconName: 'star',
          colorHex: '#123456',
        ),
      );
      final style = await db.stylesDao.getStyleById('s1');
      await setWatermark(style!.modifiedAt);

      expect(await service.getPendingChangesCount(), 0);
    });
  });
}
