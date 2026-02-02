import 'dart:async';

/// Web stub for SyncService
class SyncService {
  final dynamic _db;

  SyncService(this._db);

  bool get isRunning => false;
  Stream<String> get permissionErrors => const Stream.empty();

  Future<void> init() async {}
  Future<String> getLocalDeviceId() async => 'web_device';
  Future<bool> startSync(String syncFolderPath) async => false;
  Future<void> stopSync() async {}
  Future<void> exportNow() async {}
  Future<void> importNow() async {}
  Future<int> getIncomingFileCount() async => 0;
  Future<int> clearSyncFolder() async => 0;
}
