import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/sync/sync_service.dart';

/// Folder sync for the two tables the binary format reserves ids for but the
/// engine never carried: `settings` (id 8) and `sms_presets` (id 9).
///
/// Server sync carries both - settings minus a short list of per-device keys -
/// so a user with two devices on a shared folder was quietly getting a
/// different result from a user with the same two devices on a server: their
/// SMS parsing rules and their preferences stayed on whichever device they
/// were typed on, forever, with the sync screen reporting success.
///
/// The per-device keys are the point of the last test: `local_device_id` is
/// what both sync paths use to tell "my writes" from a peer's, so carrying it
/// would give two devices one identity, and `server_sync_token` is a secret
/// that has no business travelling through a shared folder at all.
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

  Future<String?> settingOn(AppDatabase db, String key) async {
    final row = await (db.select(
      db.settings,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<SmsPreset?> presetOn(AppDatabase db, String id) async =>
      (db.select(db.smsPresets)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  setUp(() async {
    syncFolder = await Directory.systemTemp.createTemp(
      'mybudget_sync_settings_',
    );
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

  group('sms presets', () {
    test('a preset written on A arrives on B', () async {
      await dbA.smsPresetsDao.insertPreset(
        SmsPresetsCompanion.insert(
          id: const Value('preset1'),
          name: 'Bank of A',
          senderFilter: 'BANKA',
          rulesJson: '[{"field":"amount"}]',
        ),
      );

      await serviceA.exportNow();
      await serviceB.importNow();

      final onB = await presetOn(dbB, 'preset1');
      expect(onB, isNotNull);
      expect(onB!.name, 'Bank of A');
      expect(onB.senderFilter, 'BANKA');
      expect(onB.rulesJson, '[{"field":"amount"}]');
      expect(onB.isEnabled, isTrue);
    });

    test('an edit on A reaches the copy on B', () async {
      await dbA.smsPresetsDao.insertPreset(
        SmsPresetsCompanion.insert(
          id: const Value('preset1'),
          name: 'Bank of A',
          senderFilter: 'BANKA',
          rulesJson: '[]',
        ),
      );
      await serviceA.exportNow();
      await serviceB.importNow();

      await dbA.smsPresetsDao.updatePreset(
        const SmsPresetsCompanion(
          id: Value('preset1'),
          name: Value('Bank of A (renamed)'),
          isEnabled: Value(false),
        ),
      );
      await serviceA.exportNow();
      await serviceB.importNow();

      final onB = await presetOn(dbB, 'preset1');
      expect(onB!.name, 'Bank of A (renamed)');
      expect(onB.isEnabled, isFalse);
      expect(
        onB.senderFilter,
        'BANKA',
        reason: 'a partial edit may not blank the columns it left out',
      );
    });

    test('a delete on A removes the copy on B', () async {
      await dbA.smsPresetsDao.insertPreset(
        SmsPresetsCompanion.insert(
          id: const Value('preset1'),
          name: 'Bank of A',
          senderFilter: 'BANKA',
          rulesJson: '[]',
        ),
      );
      await serviceA.exportNow();
      await serviceB.importNow();

      await dbA.smsPresetsDao.deletePreset('preset1');
      await serviceA.exportNow();
      await serviceB.importNow();

      final onB = await presetOn(dbB, 'preset1');
      expect(
        onB?.isDeleted ?? true,
        isTrue,
        reason: 'the row is either gone or tombstoned, never live',
      );
      final visible = await dbB.smsPresetsDao.getAllPresets();
      expect(visible.where((p) => p.id == 'preset1'), isEmpty);
    });
  });

  group('settings', () {
    test('an ordinary setting written on A arrives on B', () async {
      await dbA.settingsDao.setSetting(
        const SettingsCompanion(
          key: Value('main_currency'),
          value: Value('EUR'),
        ),
      );

      await serviceA.exportNow();
      await serviceB.importNow();

      expect(await settingOn(dbB, 'main_currency'), 'EUR');
    });

    test('a changed setting overwrites the copy on B', () async {
      await dbA.settingsDao.setSetting(
        const SettingsCompanion(
          key: Value('main_currency'),
          value: Value('EUR'),
        ),
      );
      await serviceA.exportNow();
      await serviceB.importNow();

      await dbA.settingsDao.setSetting(
        const SettingsCompanion(
          key: Value('main_currency'),
          value: Value('USD'),
        ),
      );
      await serviceA.exportNow();
      await serviceB.importNow();

      expect(await settingOn(dbB, 'main_currency'), 'USD');
    });

    test('an older value from a peer does not revert a newer local one', () async {
      // Two devices both change the same preference. Nothing about the file
      // format orders those writes - a packet is read whenever the folder is
      // next scanned - so without the clock comparison whichever import ran
      // last would win, and a setting edited on the phone this morning would
      // be silently put back by a laptop that touched it last week.
      await dbB.settingsDao.setSetting(
        SettingsCompanion(
          key: const Value('main_currency'),
          value: const Value('USD'),
          modifiedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );
      await dbA.settingsDao.setSetting(
        SettingsCompanion(
          key: const Value('main_currency'),
          value: const Value('EUR'),
          modifiedAt: Value(
            DateTime.now()
                .subtract(const Duration(days: 7))
                .millisecondsSinceEpoch,
          ),
        ),
      );

      await serviceA.exportNow();
      await serviceB.importNow();

      expect(await settingOn(dbB, 'main_currency'), 'USD');
    });

    test('a newer value from a peer does replace an older local one', () async {
      // The other half of the same rule: the clock has to be read, not the
      // arrival order, in both directions.
      await dbB.settingsDao.setSetting(
        SettingsCompanion(
          key: const Value('main_currency'),
          value: const Value('USD'),
          modifiedAt: Value(
            DateTime.now()
                .subtract(const Duration(days: 7))
                .millisecondsSinceEpoch,
          ),
        ),
      );
      await dbA.settingsDao.setSetting(
        SettingsCompanion(
          key: const Value('main_currency'),
          value: const Value('EUR'),
          modifiedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );

      await serviceA.exportNow();
      await serviceB.importNow();

      expect(await settingOn(dbB, 'main_currency'), 'EUR');
    });

    test('the per-device settings stay on the device that wrote them', () async {
      const deviceLocal = {
        'local_device_id': 'device-a',
        'server_sync_enabled': 'true',
        'server_sync_url': 'wss://a.example',
        'server_sync_token': 'secret-of-a',
        'sync_enabled': 'true',
        'sync_folder_path': 'C:/a/folder',
      };
      for (final entry in deviceLocal.entries) {
        await dbA.settingsDao.setSetting(
          SettingsCompanion(
            key: Value(entry.key),
            value: Value(entry.value),
          ),
        );
      }

      await serviceA.exportNow();
      await serviceB.importNow();

      expect(
        await settingOn(dbB, 'local_device_id'),
        'device-b',
        reason: 'two devices sharing one identity break every LWW tie-break',
      );
      for (final entry in deviceLocal.entries) {
        expect(
          await settingOn(dbB, entry.key),
          isNot(entry.value),
          reason:
              '${entry.key} is this device\'s own configuration - B either '
              'has no value for it or its own, never A\'s',
        );
      }
    });
  });
}
