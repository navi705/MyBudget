import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/sync/sync_binary_format.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/domain/entities/icon_type.dart';
import 'package:path/path.dart' as p;

/// Service for P2P synchronization via Syncthing
class SyncService {
  final AppDatabase _db;

  String? _syncFolderPath;
  String? _localDeviceId;
  Timer? _exportTimer;
  StreamSubscription<FileSystemEvent>? _watcherSubscription;

  bool _isRunning = false;

  /// Batch interval for exporting changes (default 30 seconds)
  Duration batchInterval = const Duration(seconds: 30);

  /// How long to keep processed sync files
  Duration keepProcessedFor = const Duration(days: 7);

  /// Maximum conflict history entries to keep
  int maxConflictHistory = 100;

  SyncService(this._db);

  /// Check if sync is currently running
  bool get isRunning => _isRunning;

  /// Get the local device ID
  Future<String> getLocalDeviceId() async {
    if (_localDeviceId != null) return _localDeviceId!;

    final setting = await _db.settingsDao.getSetting('local_device_id');
    _localDeviceId = setting?.value;
    return _localDeviceId ?? '';
  }

  /// Start synchronization
  Future<void> startSync(String syncFolderPath) async {
    if (_isRunning) return;

    _syncFolderPath = syncFolderPath;
    _localDeviceId = await getLocalDeviceId();

    // Ensure sync folder exists
    final syncDir = Directory(syncFolderPath);
    if (!await syncDir.exists()) {
      await syncDir.create(recursive: true);
    }

    // Ensure .processed subfolder exists
    final processedDir = Directory(p.join(syncFolderPath, '.processed'));
    if (!await processedDir.exists()) {
      await processedDir.create();
    }

    // Start export timer
    _exportTimer = Timer.periodic(
      batchInterval,
      (_) => _exportPendingChanges(),
    );

    // Start file watcher
    _watcherSubscription = syncDir.watch().listen(_onFileSystemEvent);

    // Process any existing files from other devices
    await _processExistingFiles();

    _isRunning = true;
  }

  /// Stop synchronization
  Future<void> stopSync() async {
    _exportTimer?.cancel();
    _exportTimer = null;

    await _watcherSubscription?.cancel();
    _watcherSubscription = null;

    _isRunning = false;
  }

  /// Force export pending changes now
  Future<void> exportNow() async {
    await _exportPendingChanges();
  }

  /// Force import all files now
  Future<void> importNow() async {
    await _processExistingFiles();
  }

  /// Export pending changes to a .sync file
  Future<void> _exportPendingChanges() async {
    if (_syncFolderPath == null || _localDeviceId == null) return;

    final pendingChanges = await _db.syncLogDao.getPendingChanges();
    if (pendingChanges.isEmpty) return;

    // Convert to SyncChange objects
    final changes = <SyncChange>[];
    for (final log in pendingChanges) {
      final tableId = _tableNameToId(log.changedTableName);
      if (tableId == null) continue;

      // Get current data for upsert actions
      Map<String, dynamic>? data;
      if (log.action == 'upsert') {
        data = await _getRecordData(tableId, log.recordId);
      }

      changes.add(
        SyncChange(
          tableId: tableId,
          recordId: log.recordId,
          action: log.action == 'delete'
              ? SyncAction.delete
              : SyncAction.upsert,
          data: data,
        ),
      );
    }

    if (changes.isEmpty) return;

    // Encode to binary
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final bytes = SyncBinaryFormat.encode(
      deviceId: _localDeviceId!,
      timestamp: timestamp,
      changes: changes,
    );

    // Write file
    final fileName =
        'device_${_localDeviceId!.substring(0, 8)}_$timestamp.sync';
    final file = File(p.join(_syncFolderPath!, fileName));
    await file.writeAsBytes(bytes);

    // Mark as exported
    await _db.syncLogDao.markExported(pendingChanges.map((e) => e.id).toList());
  }

  /// Handle file system events
  void _onFileSystemEvent(FileSystemEvent event) {
    if (event is FileSystemCreateEvent && event.path.endsWith('.sync')) {
      // New sync file detected
      _processFile(File(event.path));
    }
  }

  /// Process existing sync files
  Future<void> _processExistingFiles() async {
    if (_syncFolderPath == null) return;

    final syncDir = Directory(_syncFolderPath!);
    final files = await syncDir
        .list()
        .where((e) => e.path.endsWith('.sync'))
        .toList();

    for (final entity in files) {
      if (entity is File) {
        await _processFile(entity);
      }
    }

    // Cleanup old processed files
    await _cleanupProcessedFiles();
  }

  /// Process a single sync file
  Future<void> _processFile(File file) async {
    if (_localDeviceId == null) return;

    try {
      final bytes = await file.readAsBytes();
      final packet = SyncBinaryFormat.decode(bytes);

      // Skip our own files
      if (packet.deviceId == _localDeviceId) {
        // Move to processed
        await _moveToProcessed(file);
        return;
      }

      // Process each change
      for (final change in packet.changes) {
        await _applyChange(change, packet.deviceId);
      }

      // Move to processed
      await _moveToProcessed(file);
    } catch (e) {
      // Log error but don't crash
      print('Error processing sync file ${file.path}: $e');
    }
  }

  /// Apply a single change with conflict resolution
  Future<void> _applyChange(SyncChange change, String fromDevice) async {
    // Get local record
    final localData = await _getRecordData(change.tableId, change.recordId);
    final localModifiedAt = localData?['modifiedAt'] as int? ?? 0;
    final incomingModifiedAt = change.data?['modifiedAt'] as int? ?? 0;

    if (change.action == SyncAction.delete) {
      if (localData != null) {
        // Soft delete - set is_deleted = true
        await _softDeleteRecord(change.tableId, change.recordId);
      }
      return;
    }

    // Upsert
    if (localData == null) {
      // New record - insert
      await _insertRecord(change.tableId, change.data!);
    } else if (incomingModifiedAt > localModifiedAt) {
      // Incoming is newer - update, save local to conflict history
      await _db.conflictHistoryDao.saveConflict(
        tableName: change.tableId.name,
        recordId: change.recordId,
        rejectedDataJson: jsonEncode(localData),
        rejectedDevice: _localDeviceId,
      );
      await _updateRecord(change.tableId, change.data!);
    } else {
      // Local is newer - save incoming to conflict history
      await _db.conflictHistoryDao.saveConflict(
        tableName: change.tableId.name,
        recordId: change.recordId,
        rejectedDataJson: jsonEncode(change.data),
        rejectedDevice: fromDevice,
      );
    }

    // Cleanup old conflicts
    await _db.conflictHistoryDao.clearOldConflicts(maxConflictHistory);
  }

  /// Move processed file to .processed folder
  Future<void> _moveToProcessed(File file) async {
    if (_syncFolderPath == null) return;

    final processedDir = Directory(p.join(_syncFolderPath!, '.processed'));
    final newPath = p.join(processedDir.path, p.basename(file.path));
    await file.rename(newPath);
  }

  /// Cleanup old processed files
  Future<void> _cleanupProcessedFiles() async {
    if (_syncFolderPath == null) return;

    final processedDir = Directory(p.join(_syncFolderPath!, '.processed'));
    if (!await processedDir.exists()) return;

    final cutoff = DateTime.now().subtract(keepProcessedFor);
    final files = await processedDir.list().toList();

    for (final entity in files) {
      if (entity is File) {
        final stat = await entity.stat();
        if (stat.modified.isBefore(cutoff)) {
          await entity.delete();
        }
      }
    }
  }

  // --- Helper methods for data access ---

  SyncTableId? _tableNameToId(String name) {
    return SyncTableId.values.cast<SyncTableId?>().firstWhere(
      (e) => e?.name == name,
      orElse: () => null,
    );
  }

  Future<Map<String, dynamic>?> _getRecordData(
    SyncTableId tableId,
    String recordId,
  ) async {
    switch (tableId) {
      case SyncTableId.transactions:
        final record = await _db.transactionsDao.getTransactionById(recordId);
        return record != null ? _transactionToJson(record) : null;
      case SyncTableId.accounts:
        final record = await _db.accountsDao.getAccountById(recordId);
        return record != null ? _accountToJson(record) : null;
      case SyncTableId.categories:
        final record = await _db.categoriesDao.getCategoryById(recordId);
        return record != null ? _categoryToJson(record) : null;
      case SyncTableId.styles:
        final record = await _db.stylesDao.getStyleById(recordId);
        return record != null ? _styleToJson(record) : null;
      case SyncTableId.exchangeRates:
      case SyncTableId.inflationRates:
      case SyncTableId.assetEntries:
      case SyncTableId.customThemes:
      case SyncTableId.settings:
      case SyncTableId.smsPresets:
      case SyncTableId.customDataSources:
      case SyncTableId.apiSettings:
        // These tables need specific get methods
        return null;
    }
  }

  Future<void> _insertRecord(
    SyncTableId tableId,
    Map<String, dynamic> data,
  ) async {
    switch (tableId) {
      case SyncTableId.transactions:
        await _db.transactionsDao.insertTransaction(_transactionFromJson(data));
        break;
      case SyncTableId.accounts:
        await _db.accountsDao.insertAccount(_accountFromJson(data));
        break;
      case SyncTableId.categories:
        await _db.categoriesDao.insertCategory(_categoryFromJson(data));
        break;
      case SyncTableId.styles:
        await _db.stylesDao.insertStyle(_styleFromJson(data));
        break;
      default:
        break;
    }
  }

  Future<void> _updateRecord(
    SyncTableId tableId,
    Map<String, dynamic> data,
  ) async {
    switch (tableId) {
      case SyncTableId.transactions:
        await _db.transactionsDao.updateTransaction(_transactionFromJson(data));
        break;
      case SyncTableId.accounts:
        await _db.accountsDao.updateAccount(_accountFromJson(data));
        break;
      case SyncTableId.categories:
        await _db.categoriesDao.updateCategory(_categoryFromJson(data));
        break;
      case SyncTableId.styles:
        await _db.stylesDao.updateStyle(_styleFromJson(data));
        break;
      default:
        break;
    }
  }

  Future<void> _softDeleteRecord(SyncTableId tableId, String recordId) async {
    // Soft delete by setting is_deleted = true
    // For now, we'll do a hard delete as soft delete requires schema changes
    switch (tableId) {
      case SyncTableId.transactions:
        await _db.transactionsDao.deleteTransaction(
          TransactionsCompanion(id: Value(recordId)),
        );
        break;
      case SyncTableId.accounts:
        await _db.accountsDao.deleteAccount(
          AccountsCompanion(id: Value(recordId)),
        );
        break;
      case SyncTableId.categories:
        await _db.categoriesDao.deleteCategory(
          CategoriesCompanion(id: Value(recordId)),
        );
        break;
      case SyncTableId.styles:
        await _db.stylesDao.deleteStyle(StylesCompanion(id: Value(recordId)));
        break;
      default:
        break;
    }
  }

  // --- JSON serialization helpers ---

  Map<String, dynamic> _transactionToJson(Transaction t) {
    return {
      'id': t.id,
      'description': t.description,
      'amount': t.amount,
      'date': t.date.toIso8601String(),
      'accountId': t.accountId,
      'categoryId': t.categoryId,
      'currencyCode': t.currencyCode,
      'modifiedAt': t.modifiedAt,
      'deviceId': t.deviceId,
      'isDeleted': t.isDeleted,
    };
  }

  TransactionsCompanion _transactionFromJson(Map<String, dynamic> json) {
    return TransactionsCompanion(
      id: Value(json['id'] as String),
      description: Value(json['description'] as String? ?? ''),
      amount: Value((json['amount'] as num).toDouble()),
      date: Value(DateTime.parse(json['date'] as String)),
      accountId: Value(json['accountId'] as String? ?? ''),
      categoryId: Value(json['categoryId'] as String? ?? ''),
      currencyCode: Value(json['currencyCode'] as String? ?? 'USD'),
      modifiedAt: Value((json['modifiedAt'] as int?) ?? 0),
      deviceId: Value(json['deviceId'] as String?),
      isDeleted: Value(json['isDeleted'] as bool? ?? false),
    );
  }

  Map<String, dynamic> _accountToJson(DbAccount a) {
    return {
      'id': a.id,
      'name': a.name,
      'description': a.description,
      'balance': a.balance,
      'currencyCode': a.currencyCode,
      'accountTypeId': a.accountTypeId,
      'styleId': a.styleId,
      'modifiedAt': a.modifiedAt,
      'deviceId': a.deviceId,
      'isDeleted': a.isDeleted,
    };
  }

  AccountsCompanion _accountFromJson(Map<String, dynamic> json) {
    return AccountsCompanion(
      id: Value(json['id'] as String),
      name: Value(json['name'] as String? ?? 'Account'),
      description: Value(json['description'] as String?),
      balance: Value((json['balance'] as num).toDouble()),
      currencyCode: Value(json['currencyCode'] as String? ?? 'USD'),
      accountTypeId: Value(json['accountTypeId'] as String? ?? ''),
      styleId: Value(json['styleId'] as String?),
      modifiedAt: Value((json['modifiedAt'] as int?) ?? 0),
      deviceId: Value(json['deviceId'] as String?),
      isDeleted: Value(json['isDeleted'] as bool? ?? false),
    );
  }

  Map<String, dynamic> _categoryToJson(Category c) {
    return {
      'id': c.id,
      'name': c.name,
      'parentId': c.parentId,
      'styleId': c.styleId,
      'type': c.type.index,
      'modifiedAt': c.modifiedAt,
      'deviceId': c.deviceId,
      'isDeleted': c.isDeleted,
    };
  }

  CategoriesCompanion _categoryFromJson(Map<String, dynamic> json) {
    return CategoriesCompanion(
      id: Value(json['id'] as String),
      name: Value(json['name'] as String? ?? 'Category'),
      parentId: Value(json['parentId'] as String?),
      styleId: Value(json['styleId'] as String?),
      type: Value(CategoryType.values[(json['type'] as int?) ?? 0]),
      modifiedAt: Value((json['modifiedAt'] as int?) ?? 0),
      deviceId: Value(json['deviceId'] as String?),
      isDeleted: Value(json['isDeleted'] as bool? ?? false),
    );
  }

  Map<String, dynamic> _styleToJson(Style s) {
    return {
      'id': s.id,
      'name': s.name,
      'colorHex': s.colorHex,
      'iconName': s.iconName,
      'iconType': s.iconType,
      'modifiedAt': s.modifiedAt,
      'deviceId': s.deviceId,
      'isDeleted': s.isDeleted,
    };
  }

  StylesCompanion _styleFromJson(Map<String, dynamic> json) {
    return StylesCompanion(
      id: Value(json['id'] as String),
      name: Value(json['name'] as String? ?? 'Style'),
      colorHex: Value(json['colorHex'] as String? ?? '#000000'),
      iconName: Value(json['iconName'] as String? ?? 'star'),
      iconType: Value(IconType.values[(json['iconType'] as int?) ?? 0]),
      modifiedAt: Value((json['modifiedAt'] as int?) ?? 0),
      deviceId: Value(json['deviceId'] as String?),
      isDeleted: Value(json['isDeleted'] as bool? ?? false),
    );
  }
}
