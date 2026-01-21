import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
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
  bool _hasLoggedPermissionError = false;

  /// Stream controller for permission errors (to notify UI)
  final _permissionErrorController = StreamController<String>.broadcast();

  /// Batch interval for exporting changes (default 30 seconds)
  Duration batchInterval = const Duration(seconds: 30);

  /// How long to keep processed sync files
  Duration keepProcessedFor = const Duration(days: 7);

  /// Maximum conflict history entries to keep
  int maxConflictHistory = 100;

  SyncService(this._db);

  /// Check if sync is currently running
  bool get isRunning => _isRunning;

  /// Stream of permission errors (for UI to display)
  Stream<String> get permissionErrors => _permissionErrorController.stream;

  /// Initialize sync settings from database and start sync if enabled
  Future<void> init() async {
    try {
      debugPrint('[SYNC_DEBUG] SyncService.init() started');
      debugPrint('[SYNC_DEBUG] Loading sync_enabled setting...');
      final enabledSetting = await _db.settingsDao.getSetting('sync_enabled');

      debugPrint('[SYNC_DEBUG] Loading sync_folder_path setting...');
      final folderSetting = await _db.settingsDao.getSetting(
        'sync_folder_path',
      );

      debugPrint(
        '[SYNC_DEBUG] Settings loaded - Enabled: ${enabledSetting?.value}, Folder: ${folderSetting?.value}',
      );

      if (enabledSetting?.value == 'true' &&
          folderSetting != null &&
          folderSetting.value.isNotEmpty) {
        debugPrint('[SYNC_DEBUG] Auto-starting sync from settings...');
        await startSync(folderSetting.value);
      } else {
        debugPrint('[SYNC_DEBUG] Sync is disabled or folder not set.');
      }
    } catch (e, stack) {
      debugPrint('[SYNC_DEBUG] Initialization CRITICAL ERROR: $e');
      debugPrint('[SYNC_DEBUG] Stack trace: $stack');
    }
  }

  /// Get the local device ID
  Future<String> getLocalDeviceId() async {
    if (_localDeviceId != null) return _localDeviceId!;

    final setting = await _db.settingsDao.getSetting('local_device_id');
    _localDeviceId = setting?.value;
    return _localDeviceId ?? '';
  }

  /// Start synchronization
  /// Returns true if sync started successfully, false if there was a permission error.
  Future<bool> startSync(String syncFolderPath) async {
    debugPrint('[SYNC_DEBUG] startSync called with path: $syncFolderPath');
    if (Platform.isAndroid && syncFolderPath.contains(':\\')) {
      debugPrint(
        '[SYNC_DEBUG] WARNING: You are using a Windows-style path (C:\\...) on Android. This will likely fail or create files in an unexpected location.',
      );
    }
    if (_isRunning) {
      debugPrint('[SYNC_DEBUG] Sync already running, skipping.');
      return true;
    }

    _syncFolderPath = syncFolderPath;
    _localDeviceId = await getLocalDeviceId();

    // Ensure sync folder exists - with error handling for Android Scoped Storage
    try {
      debugPrint('[SYNC_DEBUG] Checking sync directory...');
      final syncDir = Directory(syncFolderPath);
      if (!await syncDir.exists()) {
        await syncDir.create(recursive: true);
      }

      // Ensure .processed subfolder exists
      final processedDir = Directory(p.join(syncFolderPath, '.processed'));
      if (!await processedDir.exists()) {
        await processedDir.create();
      }
    } on PathAccessException catch (e) {
      debugPrint(
        'SyncService: Cannot access sync folder. Permission denied: ${e.path}',
      );
      debugPrint(
        'SyncService: On Android 11+, select a folder within Documents or Downloads.',
      );
      _syncFolderPath = null;
      return false;
    } on FileSystemException catch (e) {
      debugPrint(
        'SyncService: File system error creating sync folder: ${e.message}',
      );
      _syncFolderPath = null;
      return false;
    }

    // Start export timer
    debugPrint('[SYNC_DEBUG] Starting export timer (interval: $batchInterval)');
    _exportTimer = Timer.periodic(
      batchInterval,
      (_) => _exportPendingChanges(),
    );

    // Start file watcher
    final syncDir = Directory(syncFolderPath);
    _watcherSubscription = syncDir.watch().listen(_onFileSystemEvent);

    // Process any existing files from other devices
    await _processExistingFiles();

    _isRunning = true;
    return true;
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
    try {
      if (_syncFolderPath == null || _localDeviceId == null) {
        debugPrint('[SYNC_DEBUG] Export skipped: Folder or Device ID missing.');
        return;
      }

      final pendingChanges = await _db.syncLogDao.getPendingChanges();
      debugPrint(
        '[SYNC_DEBUG] Found ${pendingChanges.length} pending changes.',
      );
      if (pendingChanges.isEmpty) {
        debugPrint('[SYNC_DEBUG] No pending changes, skipping export.');
        return;
      }

      debugPrint(
        '[SYNC_DEBUG] Exporting ${pendingChanges.length} pending changes...',
      );

      // Group record IDs by table for bulk fetching
      debugPrint('[SYNC_DEBUG] Grouping record IDs by table...');
      final tableRecordIds = <SyncTableId, Set<String>>{};
      for (final log in pendingChanges) {
        if (log.action != 'upsert') continue;
        final tableId = _tableNameToId(log.changedTableName);
        if (tableId == null) {
          debugPrint('[SYNC_DEBUG] Unknown table: ${log.changedTableName}');
          continue;
        }
        tableRecordIds.putIfAbsent(tableId, () => {}).add(log.recordId);
      }

      // Bulk fetch data for each table
      debugPrint(
        '[SYNC_DEBUG] Fetching bulk data for ${tableRecordIds.length} tables...',
      );
      final tableDataMaps = <SyncTableId, Map<String, Map<String, dynamic>>>{};
      for (final entry in tableRecordIds.entries) {
        final tableId = entry.key;
        final ids = entry.value.toList();
        debugPrint(
          '[SYNC_DEBUG] Fetching ${ids.length} records from ${tableId.name}...',
        );
        final dataMap = await _getBulkRecordData(tableId, ids);
        debugPrint(
          '[SYNC_DEBUG] Received ${dataMap.length} records for ${tableId.name}.',
        );
        tableDataMaps[tableId] = dataMap;
      }

      // Convert to SyncChange objects
      debugPrint('[SYNC_DEBUG] Converting logs to SyncChange objects...');
      final changes = <SyncChange>[];
      for (final log in pendingChanges) {
        final tableId = _tableNameToId(log.changedTableName);
        if (tableId == null) continue;

        Map<String, dynamic>? data;
        if (log.action == 'upsert') {
          data = tableDataMaps[tableId]?[log.recordId];
          // If data is null for an upsert, the record might have been deleted later
          if (data == null) {
            debugPrint(
              '[SYNC_DEBUG] Data null for ${tableId.name}:${log.recordId} (skipping)',
            );
            continue;
          }
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

      if (changes.isEmpty) {
        debugPrint(
          '[SYNC_DEBUG] All changes were skipped (deleted or invalid). Clearing log.',
        );
        // Mark as exported anyway to clear the log
        await _db.syncLogDao.markExported(
          pendingChanges.map((e) => e.id).toList(),
        );
        return;
      }

      // Encode to binary
      debugPrint(
        '[SYNC_DEBUG] Encoding ${changes.length} changes to binary (GZIP)...',
      );
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final bytes = SyncBinaryFormat.encode(
        deviceId: _localDeviceId!,
        timestamp: timestamp,
        changes: changes,
      );
      debugPrint(
        '[SYNC_DEBUG] Binary encoding complete. Data size: ${bytes.length} bytes.',
      );

      // Write file
      final fileName = '${_localDeviceId}_$timestamp.sync';
      final file = File(p.join(_syncFolderPath!, fileName));

      debugPrint(
        '[SYNC_DEBUG] Writing ${bytes.length} bytes to ${file.absolute.path}',
      );
      await file.writeAsBytes(bytes);
      debugPrint('[SYNC_DEBUG] Export successful: $fileName');

      // Mark as exported only if write succeeded
      await _db.syncLogDao.markExported(
        pendingChanges.map((e) => e.id).toList(),
      );
    } on PathAccessException catch (e) {
      // Android 11+ Scoped Storage blocks direct file access to external paths.
      // Only log once to avoid spamming the console
      if (!_hasLoggedPermissionError) {
        _hasLoggedPermissionError = true;
        debugPrint(
          '[SYNC_DEBUG] SyncService: Cannot write to sync folder. Permission denied: ${e.path}',
        );
      }
      // Broadcast to UI so it can show a snackbar
      _permissionErrorController.add(
        'Cannot write to sync folder. Please select a folder within Documents or Downloads.',
      );
    } on FileSystemException catch (e) {
      debugPrint(
        '[SYNC_DEBUG] File system error during sync export: ${e.message}',
      );
    } catch (e, stack) {
      debugPrint('[SYNC_DEBUG] CRITICAL ERROR in _exportPendingChanges: $e');
      debugPrint('[SYNC_DEBUG] Stack trace: $stack');
    }
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

      // Skip our own files - don't even move them to .processed
      // They should stay in the folder so other devices can sync them.
      if (packet.deviceId == _localDeviceId) {
        debugPrint(
          '[SYNC_DEBUG] Ignoring local sync file: ${p.basename(file.path)}',
        );
        return;
      }

      debugPrint(
        '[SYNC_DEBUG] Importing changes from device: ${packet.deviceId}',
      );

      // Disable FK checks during import to handle dependencies across packets
      await _db.customStatement('PRAGMA foreign_keys = OFF;');

      try {
        // Process each change
        for (final change in packet.changes) {
          await _applyChange(change, packet.deviceId);
        }
      } finally {
        // Re-enable FK checks
        await _db.customStatement('PRAGMA foreign_keys = ON;');
      }

      // Move to processed
      await _moveToProcessed(file);
    } catch (e) {
      // Log error but don't crash
      debugPrint('Error processing sync file ${file.path}: $e');
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
    if (name == 'transactions') return SyncTableId.transactions;
    if (name == 'accounts') return SyncTableId.accounts;
    if (name == 'categories') return SyncTableId.categories;
    if (name == 'styles') return SyncTableId.styles;
    if (name == 'asset_entries') return SyncTableId.assetEntries;
    if (name == 'exchange_rates') return SyncTableId.exchangeRates;
    if (name == 'inflation_rates') return SyncTableId.inflationRates;
    if (name == 'custom_themes') return SyncTableId.customThemes;
    if (name == 'api_settings') return SyncTableId.apiSettings;
    if (name == 'sms_presets') return SyncTableId.smsPresets;
    if (name == 'account_types') return SyncTableId.accountTypes;
    if (name == 'currency_designations')
      return SyncTableId.currencyDesignations;
    if (name == 'custom_data_sources') return SyncTableId.customDataSources;

    return null;
  }

  Future<Map<String, Map<String, dynamic>>> _getBulkRecordData(
    SyncTableId tableId,
    List<String> ids,
  ) async {
    final Map<String, Map<String, dynamic>> result = {};
    switch (tableId) {
      case SyncTableId.transactions:
        final records = await _db.transactionsDao.getTransactionsByIds(ids);
        for (final r in records) {
          result[r.id] = _transactionToJson(r);
        }
        break;
      case SyncTableId.accounts:
        final records = await _db.accountsDao.getAccountsByIds(ids);
        for (final r in records) {
          result[r.id] = _accountToJson(r);
        }
        break;
      case SyncTableId.categories:
        final records = await _db.categoriesDao.getCategoriesByIds(ids);
        for (final r in records) {
          result[r.id] = _categoryToJson(r);
        }
        break;
      case SyncTableId.styles:
        final records = await _db.stylesDao.getStylesByIds(ids);
        for (final r in records) {
          result[r.id] = _styleToJson(r);
        }
        break;
      case SyncTableId.assetEntries:
        final records = await _db.assetEntriesDao.getAssetEntriesByIds(ids);
        for (final r in records) {
          result[r.id] = _assetEntryToJson(r);
        }
        break;
      case SyncTableId.accountTypes:
        final records = await _db.accountTypesDao.getAccountTypesByIds(ids);
        for (final r in records) {
          result[r.id] = _accountTypeToJson(r);
        }
        break;
      case SyncTableId.currencyDesignations:
        final records = await _db.currencyDesignationsDao.getDesignationsByIds(
          ids,
        );
        for (final r in records) {
          result[r.id] = _currencyDesignationToJson(r);
        }
        break;
      case SyncTableId.customDataSources:
        final records = await _db.customDataSourcesDao.getDataSourcesByIds(ids);
        for (final r in records) {
          result[r.id] = _customDataSourceToJson(r);
        }
        break;
      default:
        break;
    }
    return result;
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
      case SyncTableId.assetEntries:
        final record = await _db.assetEntriesDao.getAssetEntryById(recordId);
        return record != null ? _assetEntryToJson(record) : null;
      case SyncTableId.accountTypes:
        final record = await _db.accountTypesDao.getAccountTypeById(recordId);
        return record != null ? _accountTypeToJson(record) : null;
      case SyncTableId.currencyDesignations:
        final record = await _db.currencyDesignationsDao.getDesignationById(
          recordId,
        );
        return record != null ? _currencyDesignationToJson(record) : null;
      case SyncTableId.customDataSources:
        final record = await _db.customDataSourcesDao.getDataSourceById(
          recordId,
        );
        return record != null ? _customDataSourceToJson(record) : null;
      default:
        return null;
    }
  }

  Future<void> _insertRecord(
    SyncTableId tableId,
    Map<String, dynamic> data,
  ) async {
    switch (tableId) {
      case SyncTableId.transactions:
        await _db.transactionsDao.insertSyncedTransaction(
          _transactionFromJson(data),
        );
        break;
      case SyncTableId.accounts:
        await _db.accountsDao.insertSyncedAccount(_accountFromJson(data));
        break;
      case SyncTableId.categories:
        await _db.categoriesDao.insertSyncedCategory(_categoryFromJson(data));
        break;
      case SyncTableId.styles:
        await _db.stylesDao.insertSyncedStyle(_styleFromJson(data));
        break;
      case SyncTableId.assetEntries:
        await _db.assetEntriesDao.insertSyncedAssetEntry(
          _assetEntryFromJson(data),
        );
        break;
      case SyncTableId.accountTypes:
        await _db.accountTypesDao.insertSyncedAccountType(
          _accountTypeFromJson(data),
        );
        break;
      case SyncTableId.currencyDesignations:
        await _db.currencyDesignationsDao.insertSyncedDesignation(
          _currencyDesignationFromJson(data),
        );
        break;
      case SyncTableId.customDataSources:
        await _db.customDataSourcesDao.insertSyncedCustomDataSource(
          _customDataSourceFromJson(data),
        );
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
        await _db.transactionsDao.insertSyncedTransaction(
          _transactionFromJson(data),
        );
        break;
      case SyncTableId.accounts:
        await _db.accountsDao.insertSyncedAccount(_accountFromJson(data));
        break;
      case SyncTableId.categories:
        await _db.categoriesDao.insertSyncedCategory(_categoryFromJson(data));
        break;
      case SyncTableId.styles:
        await _db.stylesDao.insertSyncedStyle(_styleFromJson(data));
        break;
      case SyncTableId.assetEntries:
        await _db.assetEntriesDao.insertSyncedAssetEntry(
          _assetEntryFromJson(data),
        );
        break;
      case SyncTableId.accountTypes:
        await _db.accountTypesDao.insertSyncedAccountType(
          _accountTypeFromJson(data),
        );
        break;
      case SyncTableId.currencyDesignations:
        await _db.currencyDesignationsDao.insertSyncedDesignation(
          _currencyDesignationFromJson(data),
        );
        break;
      case SyncTableId.customDataSources:
        await _db.customDataSourcesDao.insertSyncedCustomDataSource(
          _customDataSourceFromJson(data),
        );
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
      case SyncTableId.assetEntries:
        await _db.assetEntriesDao.deleteAssetEntry(recordId);
        break;
      case SyncTableId.accountTypes:
        await _db.accountTypesDao.deleteAccountType(
          AccountTypesCompanion(id: Value(recordId)),
        );
        break;
      case SyncTableId.currencyDesignations:
        await _db.currencyDesignationsDao.deleteDesignation(
          CurrencyDesignationsCompanion(id: Value(recordId)),
        );
        break;
      case SyncTableId.customDataSources:
        await _db.customDataSourcesDao.deleteDataSource(
          CustomDataSourcesCompanion(id: Value(recordId)),
        );
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
      'exchangeRate': t.exchangeRate,
      'exchangeRatePreset': t.exchangeRatePreset,
      'fee': t.fee,
      'linkedTransactionId': t.linkedTransactionId,
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
      exchangeRate: Value(json['exchangeRate'] as double?),
      exchangeRatePreset: Value(json['exchangeRatePreset'] as int?),
      fee: Value((json['fee'] as num?)?.toDouble() ?? 0.0),
      linkedTransactionId: Value(json['linkedTransactionId'] as String?),
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
      'currencyDesignationId': a.currencyDesignationId,
      'accountTypeId': a.accountTypeId,
      'styleId': a.styleId,
      'creationDate': a.creationDate.toIso8601String(),
      'country': a.country,
      'assetId': a.assetId,
      'assetQuantity': a.assetQuantity,
      'feeStructure': a.feeStructure,
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
      currencyDesignationId: Value(
        json['currencyDesignationId'] as String? ?? '',
      ),
      accountTypeId: Value(json['accountTypeId'] as String? ?? ''),
      styleId: Value(json['styleId'] as String?),
      creationDate: Value(
        json['creationDate'] != null
            ? DateTime.parse(json['creationDate'] as String)
            : DateTime.now(),
      ),
      country: Value(json['country'] as String?),
      assetId: Value(json['assetId'] as String?),
      assetQuantity: Value((json['assetQuantity'] as num?)?.toDouble() ?? 0.0),
      feeStructure: Value(json['feeStructure'] as String?),
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
      'iconType': s.iconType.index,
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

  Map<String, dynamic> _assetEntryToJson(AssetEntry e) {
    return {
      'id': e.id,
      'assetId': e.assetId,
      'name': e.name,
      'date': e.date.toIso8601String(),
      'value': e.value,
      'quantity': e.quantity,
      'assetType': e.assetType,
      'description': e.description,
      'currencyCode': e.currencyCode,
      'accountId': e.accountId,
      'source': e.source,
      'preset': e.preset,
      'modifiedAt': e.modifiedAt,
      'deviceId': e.deviceId,
      'sourceId': e.sourceId,
      'isDeleted': e.isDeleted,
    };
  }

  AssetEntriesCompanion _assetEntryFromJson(Map<String, dynamic> json) {
    return AssetEntriesCompanion(
      id: Value(json['id'] as String),
      assetId: Value(json['assetId'] as String),
      name: Value(json['name'] as String? ?? 'Asset'),
      date: Value(DateTime.parse(json['date'] as String)),
      value: Value((json['value'] as num).toDouble()),
      quantity: Value((json['quantity'] as num).toDouble()),
      assetType: Value(json['assetType'] as String?),
      description: Value(json['description'] as String?),
      currencyCode: Value(json['currencyCode'] as String? ?? 'USD'),
      accountId: Value(json['accountId'] as String?),
      source: Value(json['source'] as String? ?? 'Manual'),
      preset: Value((json['preset'] as int?) ?? 1),
      modifiedAt: Value((json['modifiedAt'] as int?) ?? 0),
      deviceId: Value(json['deviceId'] as String?),
      sourceId: Value(json['sourceId'] as String?),
      isDeleted: Value(json['isDeleted'] as bool? ?? false),
    );
  }

  Map<String, dynamic> _accountTypeToJson(AccountType at) {
    return {
      'id': at.id,
      'name': at.name,
      'languageCode': at.languageCode,
      'modifiedAt': at.modifiedAt,
      'deviceId': at.deviceId,
      'isDeleted': at.isDeleted,
    };
  }

  AccountTypesCompanion _accountTypeFromJson(Map<String, dynamic> json) {
    return AccountTypesCompanion(
      id: Value(json['id'] as String),
      name: Value(json['name'] as String? ?? 'Account Type'),
      languageCode: Value(json['languageCode'] as String? ?? 'en'),
      modifiedAt: Value((json['modifiedAt'] as int?) ?? 0),
      deviceId: Value(json['deviceId'] as String?),
      isDeleted: Value(json['isDeleted'] as bool? ?? false),
    );
  }

  Map<String, dynamic> _currencyDesignationToJson(CurrencyDesignation cd) {
    return {
      'id': cd.id,
      'value': cd.value,
      'currencyCode': cd.currencyCode,
      'modifiedAt': cd.modifiedAt,
      'deviceId': cd.deviceId,
      'isDeleted': cd.isDeleted,
    };
  }

  CurrencyDesignationsCompanion _currencyDesignationFromJson(
    Map<String, dynamic> json,
  ) {
    return CurrencyDesignationsCompanion(
      id: Value(json['id'] as String),
      value: Value(json['value'] as String? ?? ''),
      currencyCode: Value(json['currencyCode'] as String? ?? 'USD'),
      modifiedAt: Value((json['modifiedAt'] as int?) ?? 0),
      deviceId: Value(json['deviceId'] as String?),
      isDeleted: Value(json['isDeleted'] as bool? ?? false),
    );
  }

  Map<String, dynamic> _customDataSourceToJson(CustomDataSource cds) {
    return {
      'id': cds.id,
      'name': cds.name,
      'url': cds.url,
      'dataType': cds.dataType,
      'enabled': cds.enabled,
      'autoFetch': cds.autoFetch,
      'lastFetchAt': cds.lastFetchAt,
      'modifiedAt': cds.modifiedAt,
      'deviceId': cds.deviceId,
      'isDeleted': cds.isDeleted,
    };
  }

  CustomDataSourcesCompanion _customDataSourceFromJson(
    Map<String, dynamic> json,
  ) {
    return CustomDataSourcesCompanion(
      id: Value(json['id'] as String),
      name: Value(json['name'] as String? ?? 'Custom Data Source'),
      url: Value(json['url'] as String? ?? ''),
      dataType: Value((json['dataType'] as int?) ?? 0),
      enabled: Value(json['enabled'] as bool? ?? true),
      autoFetch: Value(json['autoFetch'] as bool? ?? false),
      lastFetchAt: Value(json['lastFetchAt'] as int?),
      modifiedAt: Value((json['modifiedAt'] as int?) ?? 0),
      deviceId: Value(json['deviceId'] as String?),
      isDeleted: Value(json['isDeleted'] as bool? ?? false),
    );
  }
}
