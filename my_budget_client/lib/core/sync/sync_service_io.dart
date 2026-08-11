import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/sync/sync_binary_format.dart';
import 'package:my_budget_client/core/sync/sync_record_keys.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
// `show` because the entity library also declares a `Currency` class, which
// would collide with the drift row class of the same name.
import 'package:my_budget_client/domain/entities/currency.dart'
    show TypeCurrency;
import 'package:my_budget_client/domain/entities/icon_type.dart';
import 'package:my_budget_client/domain/value_objects/amount.dart';
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

  /// How many times a file may fail to import before it is quarantined.
  static const int _maxImportAttempts = 3;

  /// Failed import attempts per file name.
  ///
  /// Kept in memory only: `sync_processed_files` has no column to carry a
  /// failure count and adding one would need a schema migration. A permanently
  /// corrupt file is therefore skipped for the rest of the process lifetime
  /// instead of being retried on every single scan.
  final Map<String, int> _failedImportAttempts = {};

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

  /// Clear all .sync files in the sync folder
  Future<int> clearSyncFolder() async {
    if (_syncFolderPath == null) return 0;
    final dir = Directory(_syncFolderPath!);
    if (!await dir.exists()) return 0;

    int deletedCount = 0;
    final entities = await dir.list().toList();
    for (final entity in entities) {
      if (entity is File && entity.path.endsWith('.sync')) {
        await entity.delete();
        deletedCount++;
      }
    }
    return deletedCount;
  }

  /// Get count of incoming files waiting to be imported
  Future<int> getIncomingFileCount() async {
    if (_syncFolderPath == null) return 0;
    final syncDir = Directory(_syncFolderPath!);
    if (!await syncDir.exists()) return 0;

    // Get local device ID to exclude own files
    final localId = await getLocalDeviceId();

    try {
      final files = await syncDir.list().where((entity) {
        if (entity is! File) return false;
        final name = p.basename(entity.path);
        // Match .sync files that adhere to naming convention: timestamp_deviceid.sync
        if (!name.endsWith('.sync')) return false;

        // Exclude own files
        if (name.contains(localId)) {
          // debugPrint('[SYNC_DEBUG] Ignoring own file in count: $name');
          return false;
        }

        debugPrint('[SYNC_DEBUG] Found incoming file in Incoming Count: $name');
        return true;
      }).length;
      return files;
    } catch (e) {
      debugPrint('[SYNC_DEBUG] Error counting incoming files: $e');
      return 0;
    }
  }

  /// How many local writes are still waiting to be exported.
  ///
  /// Exists so the settings screen can show the number without reaching into
  /// `AppDatabase.syncLogDao` itself — the server-sync path already exposes the
  /// same figure through [ServerSyncService.getPendingChangesCount], and a UI
  /// that queries one of them through a service and the other through a DAO
  /// will drift the moment either definition of "pending" changes.
  Future<int> getPendingChangesCount() async {
    final pending = await _db.syncLogDao.getPendingChanges();
    return pending.length;
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

        final isDelete = log.action == 'delete';

        Map<String, dynamic>? data;
        if (isDelete) {
          // The delete leaves no row for a peer to read a clock from, and the
          // batch below is written up to one export interval after the fact.
          // Leaving the peer to compare against that batch clock let a delete
          // beat an undo the user made after it, so the moment the delete
          // actually happened travels with the change.
          data = {'modifiedAt': log.timestamp};
        } else {
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
            action: isDelete ? SyncAction.delete : SyncAction.upsert,
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
  /// Handle file system events
  void _onFileSystemEvent(FileSystemEvent event) {
    if (event.path.endsWith('.sync')) {
      // Process on Create, Move, or Modify (after write completes)
      // Syncthing often writes to a temp file then renames (Move)
      // Or might modify an existing file.
      // We add a small delay to ensure write is complete if it's a modify event

      if (event is FileSystemModifyEvent) {
        // Delay processing for modify events to avoid reading during write
        Future.delayed(const Duration(milliseconds: 500), () {
          _processFile(File(event.path));
        });
      } else {
        _processFile(File(event.path));
      }
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

    final fileName = p.basename(file.path);

    // A file that already failed too often is quarantined: retrying a corrupt
    // packet on every scan only burns I/O and floods the log.
    final previousFailures = _failedImportAttempts[fileName] ?? 0;
    if (previousFailures >= _maxImportAttempts) return;

    try {
      final bytes = await file.readAsBytes();
      final packet = SyncBinaryFormat.decode(bytes);

      // Process any existing files from other devices
      // Skip our own files and files we've already processed
      if (packet.deviceId == _localDeviceId) {
        debugPrint('[SYNC_DEBUG] Ignoring local sync file: $fileName');
        return;
      }

      final alreadyProcessed = await _db.syncProcessedFilesDao.isProcessed(
        fileName,
      );
      if (alreadyProcessed) {
        debugPrint('[SYNC_DEBUG] Skipping already processed file: $fileName');
        return;
      }

      debugPrint(
        '[SYNC_DEBUG] Importing changes from device: ${packet.deviceId}',
      );

      // Disable FK checks during import to handle dependencies across packets
      await _db.customStatement('PRAGMA foreign_keys = OFF;');

      try {
        // The packet timestamp is only a fallback clock for a delete sent by a
        // peer that does not stamp its own; see _applyChange.
        for (final change in packet.changes) {
          await _applyChange(change, packet.deviceId, packet.timestamp);
        }
      } finally {
        // Re-enable FK checks
        await _db.customStatement('PRAGMA foreign_keys = ON;');
      }

      // Mark as processed in database
      await _db.syncProcessedFilesDao.markProcessed(fileName, packet.deviceId);
      _failedImportAttempts.remove(fileName);

      // We no longer move to .processed immediately to allow other devices to pick it up.
      // Rename to .sync.processed to hide it from watcher but keep it in the folder?
      // Or just leave it as is, and rely on isProcessed() check.
      // Let's leave it as is for propagation, but implementation of cleanup will handle it.
      // To avoid infinite loops in watcher, we might want to move it to a subfolder
      // AFTER a delay. For now, markProcessed is enough to skip it.
    } catch (e) {
      // Log error but don't crash. The file stays unmarked so a transient
      // failure can still be retried, but count the attempts so a permanently
      // corrupt file is not re-read on every scan forever.
      final attempts = previousFailures + 1;
      _failedImportAttempts[fileName] = attempts;
      debugPrint(
        '[SYNC_DEBUG] Error processing sync file ${file.path} '
        '(attempt $attempts of $_maxImportAttempts): $e',
      );
      if (attempts >= _maxImportAttempts) {
        debugPrint(
          '[SYNC_DEBUG] Quarantining sync file $fileName after $attempts '
          'failed attempts. It will be skipped until the app restarts.',
        );
      }
    }
  }

  /// Apply a single change with conflict resolution
  ///
  /// [packetTimestamp] is the clock of the batch the change arrived in, which a
  /// delete falls back to only when the sender did not stamp it with its own.
  Future<void> _applyChange(
    SyncChange change,
    String fromDevice,
    int packetTimestamp,
  ) async {
    // Get local record
    final localData = await _getRecordData(change.tableId, change.recordId);
    final localModifiedAt = localData?['modifiedAt'] as int? ?? 0;
    final incomingModifiedAt = change.data?['modifiedAt'] as int? ?? 0;

    if (change.action == SyncAction.delete) {
      // The moment the delete happened, which is what every comparison below
      // has to weigh a local edit against. A peer on a build that stamps only
      // the batch leaves this to the packet clock, which is that delete's
      // closest available upper bound.
      final deleteTimestamp =
          (change.data?['modifiedAt'] as int?) ?? packetTimestamp;

      if (localData != null) {
        // Same last-write-wins rule the upsert path below uses: the incoming
        // change only wins when it is strictly newer, so a stale delete can no
        // longer wipe out a newer local edit.
        if (deleteTimestamp > localModifiedAt) {
          await _softDeleteRecord(
            change.tableId,
            change.recordId,
            deleteTimestamp,
          );
        } else {
          debugPrint(
            '[SYNC_DEBUG] Ignoring incoming delete for: ${change.recordId} '
            '(Local newer: $localModifiedAt >= $deleteTimestamp)',
          );
        }
        return;
      }

      // No visible row. Either it is already tombstoned, or this device has
      // never seen the record at all.
      final deletedAt = await _getDeletedRecordModifiedAt(
        change.tableId,
        change.recordId,
      );
      if (deletedAt != null) {
        // Already deleted - keep the newest delete clock so that older upserts
        // arriving later keep losing the comparison.
        if (deleteTimestamp > deletedAt) {
          await _softDeleteRecord(
            change.tableId,
            change.recordId,
            deleteTimestamp,
          );
        }
        return;
      }

      // Unknown record: record a tombstone so an older upsert for it that is
      // processed later (files are imported in directory order, not timestamp
      // order) loses last-write-wins instead of resurrecting the row.
      await _insertTombstone(change.tableId, change.recordId, deleteTimestamp);
      return;
    }

    // Upsert
    if (localData == null) {
      // "Missing" can also mean "soft deleted": every getById used by
      // _getRecordData filters on isDeleted = false, so check for a tombstone
      // before treating this as a brand new record.
      final deletedAt = await _getDeletedRecordModifiedAt(
        change.tableId,
        change.recordId,
      );
      if (deletedAt != null && deletedAt >= incomingModifiedAt) {
        debugPrint(
          '[SYNC_DEBUG] Ignoring incoming update for: ${change.recordId} '
          '(Deleted locally: $deletedAt >= $incomingModifiedAt)',
        );
        await _db.conflictHistoryDao.saveConflict(
          tableName: change.tableId.name,
          recordId: change.recordId,
          rejectedDataJson: jsonEncode(change.data),
          rejectedDevice: fromDevice,
        );
      } else {
        // New record (or a genuinely newer update to a deleted one) - insert
        debugPrint(
          '[SYNC_DEBUG] Inserting new record: ${change.recordId} into ${change.tableId.name}',
        );
        await _insertRecord(change.tableId, change.data!);
      }
    } else if (incomingModifiedAt > localModifiedAt) {
      // Incoming is newer - update, save local to conflict history
      debugPrint(
        '[SYNC_DEBUG] Updating record: ${change.recordId} in ${change.tableId.name} (Incoming newer)',
      );
      await _db.conflictHistoryDao.saveConflict(
        tableName: change.tableId.name,
        recordId: change.recordId,
        rejectedDataJson: jsonEncode(localData),
        rejectedDevice: _localDeviceId,
      );
      await _updateRecord(change.tableId, change.data!);
    } else {
      // Local is newer - save incoming to conflict history
      debugPrint(
        '[SYNC_DEBUG] Ignoring incoming update for: ${change.recordId} (Local newer: $localModifiedAt >= $incomingModifiedAt)',
      );
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

    // Also cleanup DB records
    await _db.syncProcessedFilesDao.clearOldProcessed(cutoff);
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
    if (name == 'api_settings_table') return SyncTableId.apiSettings;
    if (name == 'sms_presets') return SyncTableId.smsPresets;
    if (name == 'account_types') return SyncTableId.accountTypes;
    if (name == 'currency_designations') {
      return SyncTableId.currencyDesignations;
    }
    if (name == 'custom_data_sources') return SyncTableId.customDataSources;
    // Import auto-creates a currency for any code the CSV uses that the seed
    // does not have. Without this entry its sync_log row was dropped here and
    // the peer received transactions referencing a currency it does not know.
    if (name == 'currencies') return SyncTableId.currencies;

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
      case SyncTableId.apiSettings:
        final records = await _db.apiSettingsDao.getSettingsByIds(ids);
        for (final r in records) {
          result[r.id] = _apiSettingsToJson(r);
        }
        break;
      case SyncTableId.currencies:
        final records = await _db.currenciesDao.getCurrenciesByCodes(ids);
        for (final r in records) {
          result[r.code] = _currencyToJson(r);
        }
        break;
      case SyncTableId.exchangeRates:
        result.addAll(await _bulkExchangeRateData(ids));
        break;
      case SyncTableId.inflationRates:
        result.addAll(await _bulkInflationRateData(ids));
        break;
      case SyncTableId.customThemes:
        // One query per id rather than a chunked `isIn`: custom themes are
        // hand-made by the user, so a pending batch holds a handful of them at
        // most, and the DAO getter already applies the `isDeleted = false`
        // filter every other table's getById does.
        for (final id in ids) {
          final record = await _db.customThemesDao.getThemeById(id);
          if (record != null) {
            result[id] = _customThemeToJson(record);
          }
        }
        break;
      default:
        break;
    }
    return result;
  }

  /// Keys per statement when fetching exchange rates by parsed record id.
  ///
  /// Each key contributes five bound variables (from, to, preset and the two
  /// ends of the day range) to an OR-ed `WHERE`, and SQLite caps a statement at
  /// 999 of them - the same limit that made [SyncLogDao.markExported] chunk its
  /// writes. 150 keys is 750 variables, comfortably under it.
  static const int _exchangeRateKeyChunkSize = 150;

  /// Keys per statement when fetching inflation rates by parsed record id.
  ///
  /// Four bound variables each (country, preset and the two ends of the day
  /// range); 200 keys is 800 variables. See [_exchangeRateKeyChunkSize].
  static const int _inflationRateKeyChunkSize = 200;

  /// Exchange rates for a batch of `sync_log` record ids, keyed by the id each
  /// row was found for.
  ///
  /// The map has to be keyed by the exact string `sync_log` carries, because
  /// that is what [_exportPendingChanges] looks the payload up by. The row
  /// itself only yields the canonical spelling of its key, so the canonical
  /// form is used to find the original id again - a record id written with,
  /// say, a zero-padded preset still resolves to its row.
  ///
  /// A record id that does not parse is skipped rather than fetched: it cannot
  /// name a row in this table, and letting it through would only turn into a
  /// `null` payload downstream.
  Future<Map<String, Map<String, dynamic>>> _bulkExchangeRateData(
    List<String> ids,
  ) async {
    final result = <String, Map<String, dynamic>>{};
    final idByCanonicalKey = <String, String>{};
    final keys = <ExchangeRateKey>[];

    for (final id in ids) {
      final key = ExchangeRateKey.tryParse(id);
      if (key == null) {
        debugPrint('[SYNC_DEBUG] Unparsable exchange_rates record id: $id');
        continue;
      }
      idByCanonicalKey[key.format()] = id;
      keys.add(key);
    }

    for (var i = 0; i < keys.length; i += _exchangeRateKeyChunkSize) {
      final end = (i + _exchangeRateKeyChunkSize < keys.length)
          ? i + _exchangeRateKeyChunkSize
          : keys.length;
      final chunk = keys.sublist(i, end);

      final rows =
          await (_db.select(_db.exchangeRates)..where(
                (t) => _anyOf([
                  for (final key in chunk)
                    t.fromCurrencyCode.equals(key.fromCurrencyCode) &
                        t.toCurrencyCode.equals(key.toCurrencyCode) &
                        t.preset.equals(key.preset) &
                        t.date.isBiggerOrEqualValue(key.dayStart) &
                        t.date.isSmallerThanValue(key.dayAfter),
                ]),
              ))
              .get();

      for (final row in rows) {
        final id = idByCanonicalKey[_exchangeRateKeyOf(row).format()];
        if (id != null) {
          result[id] = _exchangeRateToJson(row);
        }
      }
    }

    return result;
  }

  /// Inflation rates for a batch of `sync_log` record ids. See
  /// [_bulkExchangeRateData] for how the result is keyed.
  Future<Map<String, Map<String, dynamic>>> _bulkInflationRateData(
    List<String> ids,
  ) async {
    final result = <String, Map<String, dynamic>>{};
    final idByCanonicalKey = <String, String>{};
    final keys = <InflationRateKey>[];

    for (final id in ids) {
      final key = InflationRateKey.tryParse(id);
      if (key == null) {
        debugPrint('[SYNC_DEBUG] Unparsable inflation_rates record id: $id');
        continue;
      }
      idByCanonicalKey[key.format()] = id;
      keys.add(key);
    }

    for (var i = 0; i < keys.length; i += _inflationRateKeyChunkSize) {
      final end = (i + _inflationRateKeyChunkSize < keys.length)
          ? i + _inflationRateKeyChunkSize
          : keys.length;
      final chunk = keys.sublist(i, end);

      final rows =
          await (_db.select(_db.inflationRates)..where(
                (t) => _anyOf([
                  for (final key in chunk)
                    t.country.equals(key.country) &
                        t.preset.equals(key.preset) &
                        t.date.isBiggerOrEqualValue(key.dayStart) &
                        t.date.isSmallerThanValue(key.dayAfter),
                ]),
              ))
              .get();

      for (final row in rows) {
        final id = idByCanonicalKey[_inflationRateKeyOf(row).format()];
        if (id != null) {
          result[id] = _inflationRateToJson(row);
        }
      }
    }

    return result;
  }

  /// OR of [terms], or a predicate matching nothing when [terms] is empty.
  ///
  /// An empty list must not degrade into "no WHERE clause at all", which would
  /// select the entire table.
  Expression<bool> _anyOf(List<Expression<bool>> terms) {
    if (terms.isEmpty) return const Constant(false);
    return terms.reduce((a, b) => a | b);
  }

  /// The record id key of a stored exchange rate row.
  ///
  /// Lives here rather than in `sync_record_keys.dart` so that file stays free
  /// of any database import.
  ExchangeRateKey _exchangeRateKeyOf(ExchangeRate r) => ExchangeRateKey(
    fromCurrencyCode: r.fromCurrencyCode,
    toCurrencyCode: r.toCurrencyCode,
    date: r.date,
    preset: r.preset,
  );

  /// The record id key of a stored inflation rate row. See
  /// [_exchangeRateKeyOf].
  InflationRateKey _inflationRateKeyOf(InflationRate r) =>
      InflationRateKey(date: r.date, country: r.country, preset: r.preset);

  /// The single exchange rate a record id names, or null.
  ///
  /// The id carries only the calendar day, while the column may hold a time of
  /// day (not every caller normalises to midnight), so the day is matched as a
  /// range. `getSingleOrNull` is deliberately not used: two rows on the same
  /// day differing only in time of day are distinct rows sharing one record id,
  /// and the newest is the one a peer should be told about.
  Future<ExchangeRate?> _exchangeRateForId(String recordId) async {
    final key = ExchangeRateKey.tryParse(recordId);
    if (key == null) return null;

    final rows =
        await (_db.select(_db.exchangeRates)
              ..where(
                (t) =>
                    t.fromCurrencyCode.equals(key.fromCurrencyCode) &
                    t.toCurrencyCode.equals(key.toCurrencyCode) &
                    t.preset.equals(key.preset) &
                    t.date.isBiggerOrEqualValue(key.dayStart) &
                    t.date.isSmallerThanValue(key.dayAfter),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)])
              ..limit(1))
            .get();
    return rows.isEmpty ? null : rows.first;
  }

  /// The single inflation rate a record id names, or null. See
  /// [_exchangeRateForId].
  Future<InflationRate?> _inflationRateForId(String recordId) async {
    final key = InflationRateKey.tryParse(recordId);
    if (key == null) return null;

    final rows =
        await (_db.select(_db.inflationRates)
              ..where(
                (t) =>
                    t.country.equals(key.country) &
                    t.preset.equals(key.preset) &
                    t.date.isBiggerOrEqualValue(key.dayStart) &
                    t.date.isSmallerThanValue(key.dayAfter),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)])
              ..limit(1))
            .get();
    return rows.isEmpty ? null : rows.first;
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
      case SyncTableId.apiSettings:
        final record = await _db.apiSettingsDao.getSettingById(recordId);
        return record != null ? _apiSettingsToJson(record) : null;
      case SyncTableId.currencies:
        final record = await _db.currenciesDao.getCurrencyByCode(recordId);
        return record != null ? _currencyToJson(record) : null;
      case SyncTableId.exchangeRates:
        final record = await _exchangeRateForId(recordId);
        return record != null ? _exchangeRateToJson(record) : null;
      case SyncTableId.inflationRates:
        final record = await _inflationRateForId(recordId);
        return record != null ? _inflationRateToJson(record) : null;
      case SyncTableId.customThemes:
        final record = await _db.customThemesDao.getThemeById(recordId);
        return record != null ? _customThemeToJson(record) : null;
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
      case SyncTableId.apiSettings:
        await _db.apiSettingsDao.insertSyncedApiSetting(
          _apiSettingsFromJson(data),
        );
        break;
      case SyncTableId.currencies:
        await _db.currenciesDao.insertSyncedCurrency(_currencyFromJson(data));
        break;
      case SyncTableId.exchangeRates:
        await _db.exchangeRatesDao.insertSyncedExchangeRate(
          _exchangeRateFromJson(data),
        );
        break;
      case SyncTableId.inflationRates:
        await _db.inflationRatesDao.insertSyncedInflationRate(
          _inflationRateFromJson(data),
        );
        break;
      case SyncTableId.customThemes:
        await _db.customThemesDao.insertSyncedTheme(_customThemeFromJson(data));
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
      case SyncTableId.apiSettings:
        await _db.apiSettingsDao.insertSyncedApiSetting(
          _apiSettingsFromJson(data),
        );
        break;
      case SyncTableId.currencies:
        await _db.currenciesDao.insertSyncedCurrency(_currencyFromJson(data));
        break;
      case SyncTableId.exchangeRates:
        await _db.exchangeRatesDao.insertSyncedExchangeRate(
          _exchangeRateFromJson(data),
        );
        break;
      case SyncTableId.inflationRates:
        await _db.inflationRatesDao.insertSyncedInflationRate(
          _inflationRateFromJson(data),
        );
        break;
      case SyncTableId.customThemes:
        await _db.customThemesDao.insertSyncedTheme(_customThemeFromJson(data));
        break;
      default:
        break;
    }
  }

  /// Apply a peer's delete as a soft delete, stamped with the clock the delete
  /// arrived with.
  ///
  /// `exchange_rates` and `inflation_rates` are the exception: they have no
  /// `isDeleted` column, so the delete is applied as a real DELETE and
  /// [modifiedAt] has nowhere to be recorded. See the cases themselves for what
  /// that costs.
  ///
  /// [modifiedAt] must come from the incoming change, never from
  /// `DateTime.now()`: re-stamping with the local clock made a stale delete look
  /// like the newest change to every other peer, so it kept winning and
  /// ping-ponging around the network.
  ///
  /// The DAO `update*` helpers are deliberately bypassed here. They overwrite
  /// `modifiedAt` with `DateTime.now()`, re-log the delete as a local `upsert`,
  /// and validate the companion as a full insert (which throws for a partial
  /// one), so the two sync columns are written directly instead.
  Future<void> _softDeleteRecord(
    SyncTableId tableId,
    String recordId,
    int modifiedAt,
  ) async {
    switch (tableId) {
      case SyncTableId.transactions:
        await (_db.update(_db.transactions)
              ..where((t) => t.id.equals(recordId)))
            .write(
              TransactionsCompanion(
                isDeleted: const Value(true),
                modifiedAt: Value(modifiedAt),
              ),
            );
        break;
      case SyncTableId.accounts:
        await (_db.update(_db.accounts)..where((t) => t.id.equals(recordId)))
            .write(
              AccountsCompanion(
                isDeleted: const Value(true),
                modifiedAt: Value(modifiedAt),
              ),
            );
        break;
      case SyncTableId.categories:
        await (_db.update(_db.categories)..where((t) => t.id.equals(recordId)))
            .write(
              CategoriesCompanion(
                isDeleted: const Value(true),
                modifiedAt: Value(modifiedAt),
              ),
            );
        break;
      case SyncTableId.styles:
        await (_db.update(_db.styles)..where((t) => t.id.equals(recordId)))
            .write(
              StylesCompanion(
                isDeleted: const Value(true),
                modifiedAt: Value(modifiedAt),
              ),
            );
        break;
      case SyncTableId.assetEntries:
        await (_db.update(_db.assetEntries)
              ..where((t) => t.id.equals(recordId)))
            .write(
              AssetEntriesCompanion(
                isDeleted: const Value(true),
                modifiedAt: Value(modifiedAt),
              ),
            );
        break;
      case SyncTableId.accountTypes:
        await (_db.update(_db.accountTypes)
              ..where((t) => t.id.equals(recordId)))
            .write(
              AccountTypesCompanion(
                isDeleted: const Value(true),
                modifiedAt: Value(modifiedAt),
              ),
            );
        break;
      case SyncTableId.currencyDesignations:
        await (_db.update(_db.currencyDesignations)
              ..where((t) => t.id.equals(recordId)))
            .write(
              CurrencyDesignationsCompanion(
                isDeleted: const Value(true),
                modifiedAt: Value(modifiedAt),
              ),
            );
        break;
      case SyncTableId.customDataSources:
        await (_db.update(_db.customDataSources)
              ..where((t) => t.id.equals(recordId)))
            .write(
              CustomDataSourcesCompanion(
                isDeleted: const Value(true),
                modifiedAt: Value(modifiedAt),
              ),
            );
        break;
      case SyncTableId.customThemes:
        await (_db.update(_db.customThemes)
              ..where((t) => t.id.equals(recordId)))
            .write(
              CustomThemesCompanion(
                isDeleted: const Value(true),
                modifiedAt: Value(modifiedAt),
              ),
            );
        break;
      case SyncTableId.exchangeRates:
        // exchange_rates has no isDeleted column, so the delete cannot be held
        // as a tombstone and the row is removed outright instead, matched on
        // its composite primary key.
        //
        // Plainly: with no tombstone there is nothing left for a later change
        // to lose a comparison against, so an OLDER upsert for the same rate
        // that is imported after this delete (files are read in directory
        // order, not timestamp order) resurrects the row. That mirrors the
        // api_settings_table caveat below; closing it needs an isDeleted
        // column, i.e. a schema migration. A silent no-op would be worse - the
        // row the user deleted would simply never go away on the peer.
        final exchangeRateKey = ExchangeRateKey.tryParse(recordId);
        if (exchangeRateKey == null) {
          debugPrint(
            '[SYNC_DEBUG] Cannot apply delete for exchange_rates:$recordId '
            '(unparsable record id)',
          );
          break;
        }
        await (_db.delete(_db.exchangeRates)..where(
              (t) =>
                  t.fromCurrencyCode.equals(exchangeRateKey.fromCurrencyCode) &
                  t.toCurrencyCode.equals(exchangeRateKey.toCurrencyCode) &
                  t.preset.equals(exchangeRateKey.preset) &
                  t.date.isBiggerOrEqualValue(exchangeRateKey.dayStart) &
                  t.date.isSmallerThanValue(exchangeRateKey.dayAfter),
            ))
            .go();
        break;
      case SyncTableId.inflationRates:
        // inflation_rates has no isDeleted column either: same real DELETE,
        // same caveat as exchange_rates above - an older upsert arriving after
        // this delete can bring the row back.
        final inflationRateKey = InflationRateKey.tryParse(recordId);
        if (inflationRateKey == null) {
          debugPrint(
            '[SYNC_DEBUG] Cannot apply delete for inflation_rates:$recordId '
            '(unparsable record id)',
          );
          break;
        }
        await (_db.delete(_db.inflationRates)..where(
              (t) =>
                  t.country.equals(inflationRateKey.country) &
                  t.preset.equals(inflationRateKey.preset) &
                  t.date.isBiggerOrEqualValue(inflationRateKey.dayStart) &
                  t.date.isSmallerThanValue(inflationRateKey.dayAfter),
            ))
            .go();
        break;
      case SyncTableId.apiSettings:
        // api_settings_table has no isDeleted column, so a peer's delete
        // cannot be represented without a schema migration. Log it rather than
        // dropping it silently.
        debugPrint(
          '[SYNC_DEBUG] Cannot apply delete for api_settings_table:$recordId '
          '(table has no isDeleted column)',
        );
        break;
      default:
        break;
    }
  }

  /// SQL table name of the imported tables that carry an `isDeleted` column.
  ///
  /// Returns null for tables that cannot hold a tombstone, which now splits
  /// into two very different cases:
  ///
  /// * `api_settings_table`, `exchange_rates` and `inflation_rates` have no
  ///   `isDeleted` column at all (giving them one would need a schema
  ///   migration), yet [_insertRecord] / [_getRecordData] DO apply them. A
  ///   delete for one of these is therefore final only until an older upsert
  ///   for the same record arrives, which resurrects it - see
  ///   [_softDeleteRecord].
  /// * The remaining ids are not applied by [_insertRecord] / [_getRecordData]
  ///   in the first place, so nothing can resurrect them either.
  String? _deletableTableName(SyncTableId tableId) {
    switch (tableId) {
      case SyncTableId.transactions:
        return 'transactions';
      case SyncTableId.accounts:
        return 'accounts';
      case SyncTableId.categories:
        return 'categories';
      case SyncTableId.styles:
        return 'styles';
      case SyncTableId.assetEntries:
        return 'asset_entries';
      case SyncTableId.accountTypes:
        return 'account_types';
      case SyncTableId.currencyDesignations:
        return 'currency_designations';
      case SyncTableId.customDataSources:
        return 'custom_data_sources';
      case SyncTableId.customThemes:
        return 'custom_themes';
      default:
        return null;
    }
  }

  /// `modifiedAt` of a locally soft-deleted row, or null when no deleted row
  /// exists.
  ///
  /// Needed because every getById used by [_getRecordData] filters on
  /// `isDeleted = false`, which makes a tombstoned record look exactly like one
  /// this device has never seen.
  Future<int?> _getDeletedRecordModifiedAt(
    SyncTableId tableId,
    String recordId,
  ) async {
    final tableName = _deletableTableName(tableId);
    if (tableName == null) return null;

    final row = await _db
        .customSelect(
          'SELECT modified_at FROM $tableName WHERE id = ? AND is_deleted = 1',
          variables: [Variable<String>(recordId)],
        )
        .getSingleOrNull();
    return row?.read<int>('modified_at');
  }

  /// Record a delete for a record this device has never seen.
  ///
  /// Files are imported in directory order rather than timestamp order, so an
  /// older upsert packet for the same record can still be processed after this
  /// delete. Writing a tombstone stamped with the delete's own clock makes that
  /// late upsert lose the last-write-wins comparison instead of resurrecting
  /// the row.
  ///
  /// Only the columns the schema requires are filled with placeholders: the row
  /// is invisible to every query because they all filter on
  /// `isDeleted = false`, and a genuinely newer upsert replaces the whole row.
  Future<void> _insertTombstone(
    SyncTableId tableId,
    String recordId,
    int modifiedAt,
  ) async {
    const placeholder = 'Deleted';
    final placeholderDate = DateTime.fromMillisecondsSinceEpoch(0);

    switch (tableId) {
      case SyncTableId.transactions:
        await _db
            .into(_db.transactions)
            .insert(
              TransactionsCompanion(
                id: Value(recordId),
                description: const Value(placeholder),
                amount: const Value(0.0),
                date: Value(placeholderDate),
                accountId: const Value(''),
                categoryId: const Value(''),
                currencyCode: const Value(''),
                modifiedAt: Value(modifiedAt),
                isDeleted: const Value(true),
              ),
              mode: InsertMode.insertOrIgnore,
            );
        break;
      case SyncTableId.accounts:
        await _db
            .into(_db.accounts)
            .insert(
              AccountsCompanion(
                id: Value(recordId),
                name: const Value(placeholder),
                balance: const Value(0.0),
                currencyCode: const Value(''),
                currencyDesignationId: const Value(''),
                accountTypeId: const Value(''),
                modifiedAt: Value(modifiedAt),
                isDeleted: const Value(true),
              ),
              mode: InsertMode.insertOrIgnore,
            );
        break;
      case SyncTableId.categories:
        await _db
            .into(_db.categories)
            .insert(
              CategoriesCompanion(
                id: Value(recordId),
                name: const Value(placeholder),
                modifiedAt: Value(modifiedAt),
                isDeleted: const Value(true),
              ),
              mode: InsertMode.insertOrIgnore,
            );
        break;
      case SyncTableId.styles:
        await _db
            .into(_db.styles)
            .insert(
              StylesCompanion(
                id: Value(recordId),
                name: const Value(placeholder),
                iconName: const Value('star'),
                colorHex: const Value('#000000'),
                modifiedAt: Value(modifiedAt),
                isDeleted: const Value(true),
              ),
              mode: InsertMode.insertOrIgnore,
            );
        break;
      case SyncTableId.assetEntries:
        await _db
            .into(_db.assetEntries)
            .insert(
              AssetEntriesCompanion(
                id: Value(recordId),
                assetId: const Value(''),
                name: const Value(placeholder),
                date: Value(placeholderDate),
                value: const Value(0.0),
                currencyCode: const Value(''),
                source: const Value('Manual'),
                modifiedAt: Value(modifiedAt),
                isDeleted: const Value(true),
              ),
              mode: InsertMode.insertOrIgnore,
            );
        break;
      case SyncTableId.accountTypes:
        // account_types.name is UNIQUE, so the record id doubles as the
        // placeholder name to keep concurrent tombstones from colliding.
        await _db
            .into(_db.accountTypes)
            .insert(
              AccountTypesCompanion(
                id: Value(recordId),
                name: Value(
                  recordId.length > 50 ? recordId.substring(0, 50) : recordId,
                ),
                languageCode: const Value(''),
                modifiedAt: Value(modifiedAt),
                isDeleted: const Value(true),
              ),
              mode: InsertMode.insertOrIgnore,
            );
        break;
      case SyncTableId.currencyDesignations:
        await _db
            .into(_db.currencyDesignations)
            .insert(
              CurrencyDesignationsCompanion(
                id: Value(recordId),
                // Column is capped at 5 characters.
                value: const Value('X'),
                currencyCode: const Value(''),
                modifiedAt: Value(modifiedAt),
                isDeleted: const Value(true),
              ),
              mode: InsertMode.insertOrIgnore,
            );
        break;
      case SyncTableId.customDataSources:
        await _db
            .into(_db.customDataSources)
            .insert(
              CustomDataSourcesCompanion(
                id: Value(recordId),
                name: const Value(placeholder),
                url: const Value(''),
                dataType: const Value(0),
                modifiedAt: Value(modifiedAt),
                isDeleted: const Value(true),
              ),
              mode: InsertMode.insertOrIgnore,
            );
        break;
      case SyncTableId.customThemes:
        await _db
            .into(_db.customThemes)
            .insert(
              CustomThemesCompanion(
                id: Value(recordId),
                name: const Value(placeholder),
                primaryColorHex: const Value('#000000'),
                secondaryColorHex: const Value('#000000'),
                surfaceColorHex: const Value('#000000'),
                backgroundColorHex: const Value('#000000'),
                windowEffectType: const Value(0),
                themeMode: const Value(0),
                modifiedAt: Value(modifiedAt),
                isDeleted: const Value(true),
              ),
              mode: InsertMode.insertOrIgnore,
            );
        break;
      default:
        // api_settings_table, exchange_rates and inflation_rates have no
        // isDeleted column, so a delete for a record they have never seen
        // stays a no-op and a later upsert can still resurrect it - fixing
        // that needs a schema migration. The other ids are not applied by
        // _insertRecord either, so there is nothing to resurrect for them.
        debugPrint(
          '[SYNC_DEBUG] No tombstone support for ${tableId.name}:$recordId',
        );
        break;
    }
  }

  // --- JSON serialization helpers ---

  /// Exact minor units to store for the money column carried under [key], whose
  /// major-unit value is [major] in currency [code].
  ///
  /// A packet written before these keys existed carries the double alone, and
  /// the peer applies it with `InsertMode.insertOrReplace`, so a column not
  /// supplied here is written as NULL. Re-deriving from the double is the only
  /// reading of such a packet that cannot invent a number: [Amount.fromMajorCode]
  /// yields minor units for fiat and nothing for crypto/commodity, whose double
  /// is the source of truth and whose column must stay NULL. A key that is
  /// present is taken exactly as sent, null included - that is the sender
  /// stating the row has no minor units, not an absence of information.
  int? _minorUnits(
    Map<String, dynamic> json,
    String key,
    double major,
    String code,
  ) {
    if (json.containsKey(key)) return (json[key] as num?)?.toInt();
    final amount = Amount.fromMajorCode(major, code);
    return amount is FiatAmount ? amount.minorUnits : null;
  }

  Map<String, dynamic> _transactionToJson(Transaction t) {
    return {
      'id': t.id,
      'description': t.description,
      'amount': t.amount,
      // Exact minor units for fiat, NULL for crypto/commodity, where the double
      // above is the source of truth. Never coerced to 0 - a 0 here would claim
      // the row is worth nothing.
      'amountMinor': t.amountMinor,
      'date': t.date.toIso8601String(),
      'accountId': t.accountId,
      'categoryId': t.categoryId,
      'currencyCode': t.currencyCode,
      'exchangeRate': t.exchangeRate,
      'exchangeRatePreset': t.exchangeRatePreset,
      'fee': t.fee,
      'feeMinor': t.feeMinor,
      'linkedTransactionId': t.linkedTransactionId,
      'modifiedAt': t.modifiedAt,
      'deviceId': t.deviceId,
      'isDeleted': t.isDeleted,
    };
  }

  TransactionsCompanion _transactionFromJson(Map<String, dynamic> json) {
    final amount = (json['amount'] as num).toDouble();
    final fee = (json['fee'] as num?)?.toDouble() ?? 0.0;
    final currencyCode = json['currencyCode'] as String? ?? 'USD';
    return TransactionsCompanion(
      id: Value(json['id'] as String),
      description: Value(json['description'] as String? ?? ''),
      amount: Value(amount),
      amountMinor: Value(
        _minorUnits(json, 'amountMinor', amount, currencyCode),
      ),
      date: Value(DateTime.parse(json['date'] as String)),
      accountId: Value(json['accountId'] as String? ?? ''),
      categoryId: Value(json['categoryId'] as String? ?? ''),
      currencyCode: Value(currencyCode),
      exchangeRate: Value(json['exchangeRate'] as double?),
      exchangeRatePreset: Value(json['exchangeRatePreset'] as int?),
      fee: Value(fee),
      feeMinor: Value(_minorUnits(json, 'feeMinor', fee, currencyCode)),
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
      // See _transactionToJson: exact minor units for fiat, NULL for
      // crypto/commodity accounts.
      'balanceMinor': a.balanceMinor,
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
    final balance = (json['balance'] as num).toDouble();
    final currencyCode = json['currencyCode'] as String? ?? 'USD';
    return AccountsCompanion(
      id: Value(json['id'] as String),
      name: Value(json['name'] as String? ?? 'Account'),
      description: Value(json['description'] as String?),
      balance: Value(balance),
      balanceMinor: Value(
        _minorUnits(json, 'balanceMinor', balance, currencyCode),
      ),
      currencyCode: Value(currencyCode),
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

  /// Keyed by `code`, which is the table's primary key and the value every
  /// account and transaction stores, so the record id on the wire is the code.
  Map<String, dynamic> _currencyToJson(Currency c) {
    return {
      'code': c.code,
      'name': c.name,
      'languageCode': c.languageCode,
      'type': c.type.index,
      'modifiedAt': c.modifiedAt,
      'deviceId': c.deviceId,
    };
  }

  CurrenciesCompanion _currencyFromJson(Map<String, dynamic> json) {
    final code = json['code'] as String;
    return CurrenciesCompanion(
      code: Value(code),
      // The table has a unique index on `name`, so falling back to the code
      // keeps a payload with a missing name from colliding with every other
      // name-less currency.
      name: Value(json['name'] as String? ?? code),
      languageCode: Value(json['languageCode'] as String? ?? 'en'),
      type: Value(TypeCurrency.values[(json['type'] as int?) ?? 0]),
      modifiedAt: Value((json['modifiedAt'] as int?) ?? 0),
      deviceId: Value(json['deviceId'] as String?),
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

  /// The composite primary key columns travel with the payload, not just in the
  /// record id: the id spells the date only to the day, while the column stores
  /// a full [DateTime], so the peer needs the real value to rebuild the row it
  /// is being told about.
  Map<String, dynamic> _exchangeRateToJson(ExchangeRate r) {
    return {
      'fromCurrencyCode': r.fromCurrencyCode,
      'toCurrencyCode': r.toCurrencyCode,
      'rate': r.rate,
      'preset': r.preset,
      'date': r.date.toIso8601String(),
      'modifiedAt': r.modifiedAt,
      'deviceId': r.deviceId,
      'sourceId': r.sourceId,
    };
  }

  ExchangeRatesCompanion _exchangeRateFromJson(Map<String, dynamic> json) {
    return ExchangeRatesCompanion(
      fromCurrencyCode: Value(json['fromCurrencyCode'] as String),
      toCurrencyCode: Value(json['toCurrencyCode'] as String),
      rate: Value((json['rate'] as num).toDouble()),
      preset: Value((json['preset'] as int?) ?? 1),
      date: Value(DateTime.parse(json['date'] as String)),
      modifiedAt: Value((json['modifiedAt'] as int?) ?? 0),
      deviceId: Value(json['deviceId'] as String?),
      sourceId: Value(json['sourceId'] as String?),
    );
  }

  /// See [_exchangeRateToJson] for why the key columns are carried.
  Map<String, dynamic> _inflationRateToJson(InflationRate r) {
    return {
      'date': r.date.toIso8601String(),
      'percent': r.percent,
      // Never null in the database: the worldwide series is stored under the
      // globalInflationCountry sentinel, which is also what the record id
      // spells.
      'country': r.country,
      'preset': r.preset,
      'modifiedAt': r.modifiedAt,
      'deviceId': r.deviceId,
      'sourceId': r.sourceId,
    };
  }

  InflationRatesCompanion _inflationRateFromJson(Map<String, dynamic> json) {
    return InflationRatesCompanion(
      date: Value(DateTime.parse(json['date'] as String)),
      percent: Value((json['percent'] as num).toDouble()),
      country: Value(json['country'] as String? ?? globalInflationCountry),
      preset: Value((json['preset'] as int?) ?? 1),
      modifiedAt: Value((json['modifiedAt'] as int?) ?? 0),
      deviceId: Value(json['deviceId'] as String?),
      sourceId: Value(json['sourceId'] as String?),
    );
  }

  /// `isActive` is carried deliberately: `CustomThemesDao.setActiveTheme` logs
  /// every row whose flag changed, so a peer that received only the newly
  /// active theme would end up with two active ones.
  Map<String, dynamic> _customThemeToJson(DbCustomTheme t) {
    return {
      'id': t.id,
      'name': t.name,
      'primaryColorHex': t.primaryColorHex,
      'secondaryColorHex': t.secondaryColorHex,
      'surfaceColorHex': t.surfaceColorHex,
      'backgroundColorHex': t.backgroundColorHex,
      'backgroundImagePath': t.backgroundImagePath,
      'backgroundImageOpacity': t.backgroundImageOpacity,
      'backgroundImageBlur': t.backgroundImageBlur,
      'windowEffectType': t.windowEffectType,
      'effectOpacity': t.effectOpacity,
      'surfaceOpacity': t.surfaceOpacity,
      'themeMode': t.themeMode,
      'isPreset': t.isPreset,
      'isActive': t.isActive,
      'modifiedAt': t.modifiedAt,
      'deviceId': t.deviceId,
      'isDeleted': t.isDeleted,
    };
  }

  CustomThemesCompanion _customThemeFromJson(Map<String, dynamic> json) {
    return CustomThemesCompanion(
      id: Value(json['id'] as String),
      // The column is constrained to 1..50 characters, so an empty or absent
      // name would be rejected by drift's own validation on insert.
      name: Value(json['name'] as String? ?? 'Theme'),
      primaryColorHex: Value(json['primaryColorHex'] as String? ?? '#000000'),
      secondaryColorHex: Value(
        json['secondaryColorHex'] as String? ?? '#000000',
      ),
      surfaceColorHex: Value(json['surfaceColorHex'] as String? ?? '#000000'),
      backgroundColorHex: Value(
        json['backgroundColorHex'] as String? ?? '#000000',
      ),
      backgroundImagePath: Value(json['backgroundImagePath'] as String?),
      backgroundImageOpacity: Value(
        (json['backgroundImageOpacity'] as num?)?.toDouble() ?? 1.0,
      ),
      backgroundImageBlur: Value(
        (json['backgroundImageBlur'] as num?)?.toDouble() ?? 0.0,
      ),
      windowEffectType: Value((json['windowEffectType'] as int?) ?? 0),
      effectOpacity: Value((json['effectOpacity'] as num?)?.toDouble() ?? 1.0),
      surfaceOpacity: Value(
        (json['surfaceOpacity'] as num?)?.toDouble() ?? 1.0,
      ),
      themeMode: Value((json['themeMode'] as int?) ?? 0),
      isPreset: Value(json['isPreset'] as bool? ?? false),
      isActive: Value(json['isActive'] as bool? ?? false),
      modifiedAt: Value((json['modifiedAt'] as int?) ?? 0),
      deviceId: Value(json['deviceId'] as String?),
      isDeleted: Value(json['isDeleted'] as bool? ?? false),
    );
  }

  Map<String, dynamic> _apiSettingsToJson(ApiSettingsTableData s) {
    return {
      'id': s.id,
      'enabled': s.enabled,
      'autoFetch': s.autoFetch,
      'lastFetchAt': s.lastFetchAt,
      'modifiedAt': s.modifiedAt,
      'deviceId': s.deviceId,
    };
  }

  ApiSettingsTableCompanion _apiSettingsFromJson(Map<String, dynamic> json) {
    return ApiSettingsTableCompanion(
      id: Value(json['id'] as String),
      enabled: Value(json['enabled'] as bool? ?? true),
      autoFetch: Value(json['autoFetch'] as bool? ?? false),
      lastFetchAt: Value(json['lastFetchAt'] as int?),
      modifiedAt: Value((json['modifiedAt'] as int?) ?? 0),
      deviceId: Value(json['deviceId'] as String?),
    );
  }
}
