import 'dart:async';

import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Web stub for SyncService
class SyncService {
  final AppDatabase _db;

  String? _localDeviceId;

  SyncService(this._db);

  bool get isRunning => false;
  Stream<String> get permissionErrors => const Stream.empty();

  Future<void> init() async {}

  /// Get the local device ID
  ///
  /// Every client needs its own identity: `local_device_id` is what both sync
  /// paths use to tell "my writes" from a peer's, so returning a shared
  /// constant made every browser look like the same device. Reads the same
  /// `local_device_id` settings key holding the same UUID shape as the native
  /// implementation, and generates the id once if the database never seeded it.
  Future<String> getLocalDeviceId() async {
    if (_localDeviceId != null) return _localDeviceId!;

    final setting = await _db.settingsDao.getSetting('local_device_id');
    if (setting != null && setting.value.isNotEmpty) {
      _localDeviceId = setting.value;
      return _localDeviceId!;
    }

    final generatedId = _uuid.v4();
    await _db.settingsDao.setSetting(
      SettingsCompanion(
        key: const Value('local_device_id'),
        value: Value(generatedId),
        modifiedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
    _localDeviceId = generatedId;
    return generatedId;
  }

  Future<bool> startSync(String syncFolderPath) async => false;
  Future<void> stopSync() async {}
  Future<void> exportNow() async {}
  Future<void> importNow() async {}
  Future<int> getIncomingFileCount() async => 0;

  /// The count is real even though file sync itself is not available on web:
  /// the rows are in the same local database, and returning 0 would tell a web
  /// user their unsynced work had already left the browser.
  ///
  /// It does not shrink, though, and it is not what the server path sends.
  /// Server sync drains `sync_push_queue`, a different table; nothing on web
  /// ever marks a `sync_log` row exported, because [exportNow] is the only
  /// thing that does and here it does nothing. The sync screen only reads this
  /// when server sync is switched off, so what it shows then is "none of this
  /// is going anywhere", which is true - but it is a running total of local
  /// writes, not a backlog that any action will clear.
  Future<int> getPendingChangesCount() async {
    final pending = await _db.syncLogDao.getPendingChanges();
    return pending.length;
  }

  Future<int> clearSyncFolder() async => 0;
}
