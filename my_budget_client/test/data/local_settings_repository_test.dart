import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/data/repositories/local_db/local_settings_repository.dart';
// `Settings` is both a drift table class and a domain entity.
import 'package:my_budget_client/domain/entities/settings.dart' as domain;

/// Settings are a key/value table read by nearly every screen. What is worth
/// pinning: the key really is the identity (a second write replaces, never
/// duplicates), the theme-mode stream always produces a usable value, and
/// `initializeDefaults` does not stamp over settings the user already changed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LocalSettingsRepository repo;

  setUpAll(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalSettingsRepository(db);
  });

  tearDownAll(() async => db.close());

  setUp(() async {
    await db.delete(db.settings).go();
    await db.delete(db.syncLog).go();
  });

  Future<Setting?> rowFor(String key) => (db.select(
    db.settings,
  )..where((s) => s.key.equals(key))).getSingleOrNull();

  group('reading and writing', () {
    test('a setting round-trips its key, value and device', () async {
      await repo.setSetting(
        const domain.Settings(key: 'k', value: 'v', device: 'laptop'),
      );

      final read = await repo.getSetting('k');

      expect(read!.key, 'k');
      expect(read.value, 'v');
      expect(read.device, 'laptop');
    });

    test('getSetting returns null for a key that was never set', () async {
      expect(await repo.getSetting('missing'), isNull);
    });

    test('a setting stored without a device reads back as "unknown" rather '
        'than crashing on a null', () async {
      await db
          .into(db.settings)
          .insert(SettingsCompanion.insert(key: 'k', value: 'v'));

      expect((await repo.getSetting('k'))!.device, 'unknown');
    });

    test('writing the same key twice replaces the value instead of '
        'duplicating the key', () async {
      await repo.setSetting(
        const domain.Settings(key: 'k', value: 'first', device: 'd'),
      );
      await repo.setSetting(
        const domain.Settings(key: 'k', value: 'second', device: 'd'),
      );

      expect((await repo.getSetting('k'))!.value, 'second');
      expect(await db.select(db.settings).get(), hasLength(1));
    });

    test('an empty string is stored as an empty string, not dropped', () async {
      // Several filter settings are seeded as '' and the screens rely on
      // reading back '' rather than null.
      await repo.setSetting(
        const domain.Settings(key: 'k', value: '', device: 'd'),
      );

      expect((await repo.getSetting('k'))!.value, '');
    });

    test('getAllSettings returns every key mapped to its value', () async {
      await repo.setSetting(
        const domain.Settings(key: 'a', value: '1', device: 'd'),
      );
      await repo.setSetting(
        const domain.Settings(key: 'b', value: '2', device: 'd'),
      );

      expect(await repo.getAllSettings(), {'a': '1', 'b': '2'});
    });

    test('getAllSettings is an empty map when nothing is stored', () async {
      expect(await repo.getAllSettings(), isEmpty);
    });

    test('saveSetting stores the value under the given key', () async {
      await repo.saveSetting('k', 'v');

      expect((await repo.getSetting('k'))!.value, 'v');
    });

    test('saveSetting stamps modifiedAt', () async {
      final before = DateTime.now().millisecondsSinceEpoch;

      await repo.saveSetting('k', 'v');

      expect((await rowFor('k'))!.modifiedAt, greaterThanOrEqualTo(before));
    });

    test('setSetting stamps modifiedAt, like saveSetting', () async {
      // Both write paths have to leave a real timestamp. A row stored as
      // "changed at epoch 0" is the oldest copy there is, so the value the user
      // just picked would lose last-write-wins against any peer's untouched
      // default the moment settings are carried by a sync engine.
      await repo.saveSetting('k', 'first');
      final before = DateTime.now().millisecondsSinceEpoch;

      await repo.setSetting(
        const domain.Settings(key: 'k', value: 'second', device: 'd'),
      );

      expect((await rowFor('k'))!.modifiedAt, greaterThanOrEqualTo(before));
    });

    test('setSetting keeps a modifiedAt the caller supplied', () async {
      // Rows applied from a peer keep the clock they arrived with, otherwise
      // every incoming row would look like a local edit made just now.
      await db.settingsDao.setSetting(
        SettingsCompanion.insert(
          key: 'k',
          value: 'v',
          modifiedAt: const Value(1234),
        ),
      );

      expect((await rowFor('k'))!.modifiedAt, 1234);
    });

    test('settings writes do not append to sync_log', () async {
      // Pinned as the current contract: `SettingsDao` has no sync bookkeeping
      // and `_tableNameToId` in lib/core/sync/sync_service_io.dart has no
      // 'settings' entry, so a row here would be dropped by the sender anyway.
      // If settings ever start syncing, this test is the reminder that both
      // sides have to change together.
      await repo.saveSetting('k', 'v');
      await repo.setSetting(
        const domain.Settings(key: 'k2', value: 'v', device: 'd'),
      );

      expect(await db.select(db.syncLog).get(), isEmpty);
    });
  });

  group('watching', () {
    test('watchSetting emits the stored value', () async {
      await repo.saveSetting('k', 'v');

      expect((await repo.watchSetting('k').first)!.value, 'v');
    });

    test('watchSetting emits null while the key is unset and the value once '
        'it is written', () async {
      final stream = repo.watchSetting('k');
      expect(await stream.first, isNull);

      final next = stream.skip(1).first;
      await repo.saveSetting('k', 'v');

      expect((await next)!.value, 'v');
    });

    test('watchAllSettings emits the whole table', () async {
      await repo.saveSetting('a', '1');
      await repo.saveSetting('b', '2');

      expect(await repo.watchAllSettings().first, hasLength(2));
    });
  });

  group('theme mode', () {
    test('themeMode starts at system before anything has been read', () async {
      // The stream is used to build MaterialApp, so it must produce a value
      // immediately - an app that waits for the database shows a blank frame.
      expect(await repo.themeMode.first, ThemeMode.system);
    });

    test('themeMode reports the stored mode', () async {
      await repo.setThemeMode(ThemeMode.dark, 'laptop');

      expect(await repo.themeMode.skip(1).first, ThemeMode.dark);
    });

    test('setThemeMode stores the mode as a lowercase string under the '
        'themeMode key', () async {
      // The stored spelling is the wire format read back by
      // `_stringToThemeMode` and by other devices - changing it silently
      // resets everyone to system.
      await repo.setThemeMode(ThemeMode.light, 'laptop');

      final row = await rowFor('themeMode');
      expect(row!.value, 'light');
      expect(row.device, 'laptop');
    });

    test('an unrecognised stored mode falls back to system instead of '
        'throwing', () async {
      await repo.saveSetting('themeMode', 'neon');

      expect(await repo.themeMode.skip(1).first, ThemeMode.system);
    });

    test('saveThemeMode writes the mode without the caller knowing the device '
        'name', () async {
      await repo.saveThemeMode(ThemeMode.dark);

      final row = await rowFor('themeMode');
      expect(row!.value, 'dark');
      expect(row.device, isNotNull);
    });
  });

  group('initializeDefaults', () {
    test('seeds the default settings into an empty table', () async {
      await repo.initializeDefaults();

      final all = await repo.getAllSettings();
      expect(all, isNotEmpty);
      expect(all['themeMode'], 'system');
      expect(all['sync_enabled'], 'false');
    });

    test('does nothing when any setting already exists, so a value the user '
        'changed is not reset on the next start', () async {
      await repo.saveSetting('themeMode', 'dark');

      await repo.initializeDefaults();

      final all = await repo.getAllSettings();
      expect(all['themeMode'], 'dark');
      expect(
        all.keys,
        hasLength(1),
        reason: 'the presence check is on the whole table, not per key',
      );
    });

    test('every seeded setting carries a device name', () async {
      await repo.initializeDefaults();

      final rows = await db.select(db.settings).get();
      expect(rows.every((r) => r.device != null), isTrue);
    });

    test('CHARACTERIZATION: seeded defaults have modifiedAt 0', () async {
      // Same root cause as the setSetting case above: the seed companions in
      // lib/data/seed_data/settings_data.dart do not set modifiedAt. Harmless
      // today because settings are not sent to peers, but it means a device
      // that has only ever seeded looks infinitely old.
      await repo.initializeDefaults();

      final rows = await db.select(db.settings).get();
      expect(rows.every((r) => r.modifiedAt == 0), isTrue);
    });
  });
}
