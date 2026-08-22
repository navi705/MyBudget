import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/sync/device_local_settings.dart';
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

  /// How long a packet that has been moved out of circulation, into the legacy
  /// `.processed` subfolder, is kept before it is deleted.
  ///
  /// It does NOT age out the `sync_processed_files` markers: a marker lives
  /// exactly as long as the packet it names is still in the sync folder. See
  /// [_cleanupProcessedFiles] for what tying the two to a clock instead used to
  /// cost.
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

  /// How long an already-exported `sync_log` row is kept after its export.
  ///
  /// Nothing reads those rows - [SyncLogDao.getPendingChanges] asks for
  /// `exported = false` - so the window exists only to leave a recent trail
  /// worth looking at when an export is being investigated.
  static const Duration _exportedLogRetention = Duration(days: 7);

  /// Retires the rows this export covered, and drops the ones that have been
  /// sitting retired since long before it.
  ///
  /// [SyncLogDao.clearExportedBefore] had no caller at all, so the log only
  /// ever grew: one row per write, kept for the life of the install. Settings
  /// are the writes that made it visible - a filter or a sort order is changed
  /// dozens of times in a session, and each change is a row - but every table
  /// was contributing to a table nothing ever emptied.
  Future<void> _markExportedAndPrune(List<SyncLogData> exported) async {
    await _db.syncLogDao.markExported(exported.map((e) => e.id).toList());
    try {
      final removed = await _db.syncLogDao.clearExportedBefore(
        DateTime.now().subtract(_exportedLogRetention),
      );
      if (removed > 0) {
        debugPrint('[SYNC_DEBUG] Pruned $removed exported sync_log rows.');
      }
    } catch (e) {
      // Housekeeping: a failure here costs disk, not correctness, and must
      // not turn a successful export into a failed one.
      debugPrint('[SYNC_DEBUG] Could not prune sync_log: $e');
    }
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
        await _markExportedAndPrune(pendingChanges);
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
      await _markExportedAndPrune(pendingChanges);
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
          unawaited(_importSerialized(File(event.path)));
        });
      } else {
        unawaited(_importSerialized(File(event.path)));
      }
    }
  }

  /// The tail of the import queue: every packet waits for the one before it.
  ///
  /// Imports used to be started and never awaited - the watcher fires one per
  /// event (Windows reports a single delivered file as a create AND a modify)
  /// and the initial scan starts more, so several ran interleaved. Two things
  /// broke. `PRAGMA foreign_keys` is connection-global and not reentrant, so
  /// the small packet that finished first turned enforcement back ON in the
  /// middle of the large one still running, and that one's next child row -
  /// whose parent travels in a later packet - was rejected. And the
  /// `isProcessed` check became check-then-act: two futures for the same file
  /// both read false and both applied it.
  Future<void> _importChain = Future<void>.value();

  /// Queues [file] behind every import already in flight and returns a future
  /// for this one alone.
  ///
  /// The chain is advanced with a swallowing `catchError` rather than the
  /// returned future so that one failed import cannot poison the queue for
  /// every packet behind it; the caller still sees the error on what it got
  /// back. (`_processFile` handles its own failures, so this is belt and
  /// braces.)
  Future<void> _importSerialized(File file) {
    final queued = _importChain.then((_) => _processFile(file));
    _importChain = queued.catchError((Object _) {});
    return queued;
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
        await _importSerialized(entity);
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

    // Both skips below are decided from the file NAME, before a single byte is
    // read. Imported packets are deliberately left in the folder for the other
    // peers to pick up, so the folder accumulates every packet the device was
    // ever handed and a rescan used to gunzip and JSON-decode all of them only
    // to discover it had already applied every one. The marker lookup is a
    // single indexed row read; the decode is proportional to the packet.
    if (_localDeviceId!.isNotEmpty &&
        fileName.startsWith('${_localDeviceId}_')) {
      // Exports are named '${deviceId}_$timestamp.sync' (see
      // _exportPendingChanges), so our own packets are recognisable without
      // opening them. A file that does not follow the convention still gets
      // the authoritative check against the decoded packet below.
      return;
    }

    if (await _db.syncProcessedFilesDao.isProcessed(fileName)) {
      debugPrint('[SYNC_DEBUG] Skipping already processed file: $fileName');
      return;
    }

    try {
      final bytes = await file.readAsBytes();
      final packet = SyncBinaryFormat.decode(bytes);

      // Skip our own files: a packet we wrote holds changes this database
      // already has, and applying them would only queue conflict history.
      if (packet.deviceId == _localDeviceId) {
        debugPrint('[SYNC_DEBUG] Ignoring local sync file: $fileName');
        return;
      }

      debugPrint(
        '[SYNC_DEBUG] Importing changes from device: ${packet.deviceId}',
      );

      // Disable FK checks during import to handle dependencies across packets.
      // This has to stay OUTSIDE the transaction below: SQLite ignores
      // `PRAGMA foreign_keys` while a transaction is open, so toggling it in
      // there would silently leave enforcement on and abort any child row
      // whose parent travels in a later packet.
      await _db.customStatement('PRAGMA foreign_keys = OFF;');

      var skipped = 0;
      try {
        // One transaction for the whole packet. Without it every change
        // auto-committed on its own, so a packet that threw halfway left the
        // prefix committed, re-applied that same prefix on each retry, and
        // lost the remaining changes for good once the file was quarantined.
        await _db.transaction(() async {
          final effects = _PacketEffects();
          // Read BEFORE the batch is applied: a transaction that moves to
          // another account overwrites the only record of where it used to
          // live, and the account it left has to be rebuilt too.
          await _collectPriorAccounts(packet.changes, effects);

          for (final change in packet.changes) {
            try {
              // The packet timestamp is only a fallback clock for a delete
              // sent by a peer that does not stamp its own; see _applyChange.
              await _applyChange(
                change,
                packet.deviceId,
                packet.timestamp,
                effects,
              );
            } catch (e) {
              // One unconvertible row must not cost the other 199 - a hostile
              // file, a corrupt field or a newer peer's enum value would
              // otherwise take the whole packet down with it. This mirrors the
              // decoder's policy for an unknown table id or action: skip the
              // one block, keep the packet.
              skipped++;
              debugPrint(
                '[SYNC_DEBUG] Skipping unapplicable change for '
                '${change.tableId.name}:${change.recordId}: $e',
              );
            }
          }

          await _settlePacket(effects);
        });
      } finally {
        // Re-enable FK checks
        await _db.customStatement('PRAGMA foreign_keys = ON;');
      }

      if (skipped > 0) {
        debugPrint(
          '[SYNC_DEBUG] Applied ${packet.changes.length - skipped} of '
          '${packet.changes.length} changes from $fileName '
          '($skipped skipped as unapplicable)',
        );
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

  /// Last-write-wins as a TOTAL order over `(modifiedAt, deviceId)`: the
  /// incoming change wins when it is newer, or when the clocks are equal and
  /// its authoring device id sorts higher.
  ///
  /// `modifiedAt` on its own is not an order. A tie used to answer "mine is not
  /// older, keep mine" on BOTH devices, so each kept its own version and no
  /// later packet could break the tie - the row stayed permanently divergent.
  /// That needs no clock coincidence: every seeded category and account type
  /// ships with `modifiedAt = 1` and a locale-dependent name, so a ru phone and
  /// an en laptop sharing a folder diverged on all of them on their first sync.
  ///
  /// The server resolves a tie with the identical rule
  /// (`SyncRepository._lastWriteWins`, "higher device id wins"), so all three
  /// parties pick the same winner.
  bool _incomingWins(
    int incomingModifiedAt,
    String incomingDeviceId,
    int localModifiedAt,
    String localDeviceId,
  ) {
    if (incomingModifiedAt != localModifiedAt) {
      return incomingModifiedAt > localModifiedAt;
    }
    return incomingDeviceId.compareTo(localDeviceId) > 0;
  }

  /// The device that authored an incoming change.
  ///
  /// A row carries its last writer in the payload, but nothing on this path
  /// fills that column yet, so the packet's sender is the fallback - and it is
  /// the right one: a change applied from a peer is written without a
  /// `sync_log` row, so a device only ever exports changes it made itself.
  String _incomingAuthor(SyncChange change, String fromDevice) =>
      (change.data?['deviceId'] as String?) ?? fromDevice;

  /// The device that authored a locally stored row, under the same fallback
  /// rule as [_incomingAuthor].
  ///
  /// The two fallbacks are what make the comparison symmetric: whichever way
  /// the packet travels, both peers name the same two devices for the same two
  /// versions and therefore reach the same verdict.
  String _localAuthor(String? storedDeviceId) =>
      storedDeviceId ?? _localDeviceId ?? '';

  /// Apply a single change with conflict resolution
  ///
  /// [packetTimestamp] is the clock of the batch the change arrived in, which a
  /// delete falls back to only when the sender did not stamp it with its own.
  ///
  /// [effects] accumulates the work that can only be done once the whole packet
  /// has been applied - see [_PacketEffects].
  Future<void> _applyChange(
    SyncChange change,
    String fromDevice,
    int packetTimestamp,
    _PacketEffects effects,
  ) async {
    // Get local record
    final localData = await _getRecordData(change.tableId, change.recordId);
    final localModifiedAt = localData?['modifiedAt'] as int? ?? 0;
    final incomingModifiedAt = change.data?['modifiedAt'] as int? ?? 0;
    final incomingDeviceId = _incomingAuthor(change, fromDevice);

    if (change.action == SyncAction.delete) {
      // The moment the delete happened, which is what every comparison below
      // has to weigh a local edit against. A peer on a build that stamps only
      // the batch leaves this to the packet clock, which is that delete's
      // closest available upper bound.
      final deleteTimestamp =
          (change.data?['modifiedAt'] as int?) ?? packetTimestamp;

      if (localData != null) {
        // Exactly the same total order the upsert path below uses, so a delete
        // and an edit that tie resolve identically on both peers - the strict
        // `>` here against the non-strict `>=` the tombstone branch used was
        // itself an asymmetry: one side kept the tombstone while the other
        // kept the live row, forever.
        if (_incomingWins(
          deleteTimestamp,
          incomingDeviceId,
          localModifiedAt,
          _localAuthor(localData['deviceId'] as String?),
        )) {
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
      final tombstone = await _getDeletedRecordStamp(
        change.tableId,
        change.recordId,
      );
      if (tombstone != null) {
        // Already deleted - keep the newest delete clock so that older upserts
        // arriving later keep losing the comparison.
        if (_incomingWins(
          deleteTimestamp,
          incomingDeviceId,
          tombstone.modifiedAt,
          _localAuthor(tombstone.deviceId),
        )) {
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
    final data = change.data;
    if (data == null) {
      // The binary format permits DATA_LEN = 0 on any action (the exporter
      // writes an empty block for a row that vanished between logging and
      // export), so an upsert with no payload is a well-formed packet with
      // nothing to apply - dereferencing it with `!` killed the rest of the
      // packet instead.
      debugPrint(
        '[SYNC_DEBUG] Upsert with no payload for '
        '${change.tableId.name}:${change.recordId} (skipping)',
      );
      return;
    }

    if (localData == null) {
      // "Missing" can also mean "soft deleted": every getById used by
      // _getRecordData filters on isDeleted = false, so check for a tombstone
      // before treating this as a brand new record.
      final tombstone = await _getDeletedRecordStamp(
        change.tableId,
        change.recordId,
      );
      if (tombstone != null &&
          !_incomingWins(
            incomingModifiedAt,
            incomingDeviceId,
            tombstone.modifiedAt,
            _localAuthor(tombstone.deviceId),
          )) {
        debugPrint(
          '[SYNC_DEBUG] Ignoring incoming update for: ${change.recordId} '
          '(Deleted locally: ${tombstone.modifiedAt} >= $incomingModifiedAt)',
        );
        await _db.conflictHistoryDao.saveConflict(
          tableName: change.tableId.name,
          recordId: change.recordId,
          rejectedDataJson: jsonEncode(change.data),
          rejectedDevice: fromDevice,
        );
        effects.wroteConflicts = true;
      } else {
        // New record (or a genuinely newer update to a deleted one) - insert
        debugPrint(
          '[SYNC_DEBUG] Inserting new record: ${change.recordId} into ${change.tableId.name}',
        );
        await _insertRecord(change.tableId, data);
        _noteApplied(change, data, effects);
      }
    } else if (_incomingWins(
      incomingModifiedAt,
      incomingDeviceId,
      localModifiedAt,
      _localAuthor(localData['deviceId'] as String?),
    )) {
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
      effects.wroteConflicts = true;
      await _updateRecord(change.tableId, data);
      _noteApplied(change, data, effects);
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
      effects.wroteConflicts = true;
    }
    // The conflict table is trimmed once per packet, in _settlePacket. Doing it
    // here ran an unbounded `SELECT *` - every rejected_data blob included -
    // and a DELETE for every single change in the packet, to remove at most one
    // row each time.
  }

  /// Records what an applied change makes stale, for [_settlePacket].
  ///
  /// Only called where a write actually happened. A change that lost
  /// last-write-wins changed nothing, and re-anchoring an account on the
  /// strength of a rejected row would fold whatever balance it happens to hold
  /// right now into its opening balance - freezing an error instead of
  /// rebuilding it away.
  void _noteApplied(
    SyncChange change,
    Map<String, dynamic> data,
    _PacketEffects effects,
  ) {
    switch (change.tableId) {
      case SyncTableId.accounts:
        effects.accounts.add(change.recordId);
        // A peer that predates the opening balance sends no such key. Absent
        // is not the same as null here: null would be a sender stating the
        // account has no anchor, and there is no such account.
        if (!data.containsKey('openingBalance')) {
          effects.anchorlessAccounts.add(change.recordId);
        }
      case SyncTableId.transactions:
        final accountId = data['accountId'] as String?;
        if (accountId != null && accountId.isNotEmpty) {
          effects.accounts.add(accountId);
        }
      default:
        break;
    }
  }

  /// The accounts the packet's transactions belong to RIGHT NOW, read before a
  /// single change is applied.
  ///
  /// A transaction that moves between accounts overwrites the only record of
  /// where it used to live, so the account it is leaving would otherwise keep a
  /// balance that still counts it, with nothing in the packet naming that
  /// account. Deletes are gathered too: a tombstone drops the row out of the
  /// rebuilt sum, which is a balance change on the account it was booked to.
  Future<void> _collectPriorAccounts(
    List<SyncChange> changes,
    _PacketEffects effects,
  ) async {
    final ids = [
      for (final change in changes)
        if (change.tableId == SyncTableId.transactions &&
            change.recordId.isNotEmpty)
          change.recordId,
    ];
    if (ids.isEmpty) return;

    // One bound variable per id, chunked under SQLite's 999-variable cap the
    // same way every other multi-key read on this path is.
    const chunkSize = 500;
    for (var start = 0; start < ids.length; start += chunkSize) {
      final chunk = ids.sublist(
        start,
        start + chunkSize > ids.length ? ids.length : start + chunkSize,
      );
      final rows = await _db
          .customSelect(
            'SELECT DISTINCT account_id FROM transactions '
            'WHERE id IN (${List.filled(chunk.length, '?').join(', ')})',
            variables: [for (final id in chunk) Variable<String>(id)],
          )
          .get();
      for (final row in rows) {
        effects.accounts.add(row.read<String>('account_id'));
      }
    }
  }

  /// The per-packet half of an import, run inside the packet's transaction once
  /// the last change has been applied.
  ///
  /// Rebuilding the balances here is what makes invariant 8 hold on this path:
  /// the importer used to write the peer's `balance` verbatim, so a device that
  /// merged a peer's transactions ended up holding both sets of rows and only
  /// one of the two balances - a number the merged set did not add up to, and
  /// which nothing ever recomputed. Transactions merge as a set; a balance
  /// merges as a scalar. Deriving the scalar from the set is the only reading
  /// two devices can both arrive at. This mirrors
  /// `ServerSyncService._applyChanges`, deliberately, so both sync paths leave
  /// the same number behind.
  ///
  /// Neither DAO stamps `modified_at` or writes a `sync_log` row, so the
  /// rebuild does not travel back out as a change the user never made.
  Future<void> _settlePacket(_PacketEffects effects) async {
    if (effects.accounts.isNotEmpty) {
      await _db.accountsDao.anchorOpeningBalances(effects.anchorlessAccounts);
      await _db.accountsDao.recomputeBalances(effects.accounts);
    }
    if (effects.wroteConflicts) {
      await _db.conflictHistoryDao.clearOldConflicts(maxConflictHistory);
    }
  }

  /// Drop the "already imported" markers whose packet is gone from the folder.
  ///
  /// A marker's only job is to stop a file that is still lying in the sync
  /// folder from being imported a second time, so its lifetime is the file's
  /// lifetime - not a clock. Ageing markers out after [keepProcessedFor] while
  /// the packets themselves are kept forever (imports are deliberately left in
  /// place so the other peers can still pick them up) meant every packet was
  /// re-imported on a ~7 day cycle, forever: an exchange rate the user deleted
  /// came back every week on every device, because `exchange_rates` has no
  /// `isDeleted` column and so leaves no tombstone for the replayed insert to
  /// lose against.
  ///
  /// [keepProcessedFor] now only governs the legacy `.processed` folder that
  /// older builds moved imported packets into: a file in there is out of
  /// circulation, so once it is deleted its marker goes with it.
  Future<void> _cleanupProcessedFiles() async {
    if (_syncFolderPath == null) return;

    final syncDir = Directory(_syncFolderPath!);
    if (!await syncDir.exists()) return;

    // Every packet still reachable by a scan. A marker for one of these has to
    // stay, whatever its age.
    final present = <String>{};
    for (final entity in await syncDir.list().toList()) {
      if (entity is File && entity.path.endsWith('.sync')) {
        present.add(p.basename(entity.path));
      }
    }

    final processedDir = Directory(p.join(_syncFolderPath!, '.processed'));
    if (await processedDir.exists()) {
      final cutoff = DateTime.now().subtract(keepProcessedFor);
      for (final entity in await processedDir.list().toList()) {
        if (entity is! File) continue;
        final stat = await entity.stat();
        if (stat.modified.isBefore(cutoff)) {
          await entity.delete();
        } else {
          present.add(p.basename(entity.path));
        }
      }
    }

    final markers = await _db.select(_db.syncProcessedFiles).get();
    final orphaned = [
      for (final marker in markers)
        if (!present.contains(marker.fileName)) marker.fileName,
    ];
    if (orphaned.isEmpty) return;

    // Chunked: the delete binds one SQL variable per name and a long-lived
    // folder can hold far more markers than SQLite's variable limit.
    const chunkSize = 500;
    for (var start = 0; start < orphaned.length; start += chunkSize) {
      final chunk = orphaned.sublist(
        start,
        start + chunkSize > orphaned.length
            ? orphaned.length
            : start + chunkSize,
      );
      await (_db.delete(
        _db.syncProcessedFiles,
      )..where((t) => t.fileName.isIn(chunk))).go();
    }
    debugPrint(
      '[SYNC_DEBUG] Dropped ${orphaned.length} processed-file markers whose '
      'packet is no longer in the sync folder',
    );
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
    if (name == 'settings') return SyncTableId.settings;
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
      case SyncTableId.smsPresets:
        final records = await _db.smsPresetsDao.getPresetsByIds(ids);
        for (final r in records) {
          result[r.id] = _smsPresetToJson(r);
        }
        break;
      case SyncTableId.settings:
        final records = await _db.settingsDao.getSettingsByKeys(ids);
        for (final r in records) {
          // The device-local keys never reach `sync_log` in the first place;
          // this is the second lock on the same door, because everything in
          // here is written to a folder other people can read.
          if (kDeviceLocalSettingKeys.contains(r.key)) continue;
          result[r.key] = _settingToJson(r);
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
      case SyncTableId.smsPresets:
        final record = await _db.smsPresetsDao.getPresetById(recordId);
        return record != null ? _smsPresetToJson(record) : null;
      case SyncTableId.settings:
        if (kDeviceLocalSettingKeys.contains(recordId)) return null;
        final record = await _db.settingsDao.getSetting(recordId);
        return record != null ? _settingToJson(record) : null;
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
      case SyncTableId.smsPresets:
        await _db.smsPresetsDao.insertSyncedPreset(_smsPresetFromJson(data));
        break;
      case SyncTableId.settings:
        final setting = _settingFromJson(data);
        // A peer has no business rewriting this device's identity or its
        // connection config, whatever build it is running.
        if (!kDeviceLocalSettingKeys.contains(setting.key.value)) {
          await _db.settingsDao.setSyncedSetting(setting);
        }
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
      case SyncTableId.smsPresets:
        await _db.smsPresetsDao.insertSyncedPreset(_smsPresetFromJson(data));
        break;
      case SyncTableId.settings:
        final setting = _settingFromJson(data);
        // A peer has no business rewriting this device's identity or its
        // connection config, whatever build it is running.
        if (!kDeviceLocalSettingKeys.contains(setting.key.value)) {
          await _db.settingsDao.setSyncedSetting(setting);
        }
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
        await (_db.update(
          _db.transactions,
        )..where((t) => t.id.equals(recordId))).write(
          TransactionsCompanion(
            isDeleted: const Value(true),
            modifiedAt: Value(modifiedAt),
          ),
        );
        break;
      case SyncTableId.accounts:
        await (_db.update(
          _db.accounts,
        )..where((t) => t.id.equals(recordId))).write(
          AccountsCompanion(
            isDeleted: const Value(true),
            modifiedAt: Value(modifiedAt),
          ),
        );
        break;
      case SyncTableId.categories:
        await (_db.update(
          _db.categories,
        )..where((t) => t.id.equals(recordId))).write(
          CategoriesCompanion(
            isDeleted: const Value(true),
            modifiedAt: Value(modifiedAt),
          ),
        );
        break;
      case SyncTableId.styles:
        await (_db.update(
          _db.styles,
        )..where((t) => t.id.equals(recordId))).write(
          StylesCompanion(
            isDeleted: const Value(true),
            modifiedAt: Value(modifiedAt),
          ),
        );
        break;
      case SyncTableId.assetEntries:
        await (_db.update(
          _db.assetEntries,
        )..where((t) => t.id.equals(recordId))).write(
          AssetEntriesCompanion(
            isDeleted: const Value(true),
            modifiedAt: Value(modifiedAt),
          ),
        );
        break;
      case SyncTableId.accountTypes:
        await (_db.update(
          _db.accountTypes,
        )..where((t) => t.id.equals(recordId))).write(
          AccountTypesCompanion(
            isDeleted: const Value(true),
            modifiedAt: Value(modifiedAt),
          ),
        );
        break;
      case SyncTableId.currencyDesignations:
        await (_db.update(
          _db.currencyDesignations,
        )..where((t) => t.id.equals(recordId))).write(
          CurrencyDesignationsCompanion(
            isDeleted: const Value(true),
            modifiedAt: Value(modifiedAt),
          ),
        );
        break;
      case SyncTableId.customDataSources:
        await (_db.update(
          _db.customDataSources,
        )..where((t) => t.id.equals(recordId))).write(
          CustomDataSourcesCompanion(
            isDeleted: const Value(true),
            modifiedAt: Value(modifiedAt),
          ),
        );
        break;
      case SyncTableId.customThemes:
        await (_db.update(
          _db.customThemes,
        )..where((t) => t.id.equals(recordId))).write(
          CustomThemesCompanion(
            isDeleted: const Value(true),
            modifiedAt: Value(modifiedAt),
          ),
        );
        break;
      case SyncTableId.smsPresets:
        await (_db.update(
          _db.smsPresets,
        )..where((t) => t.id.equals(recordId))).write(
          SmsPresetsCompanion(
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
        // order, not timestamp order) resurrects the row. Closing it needs an
        // isDeleted column, i.e. a schema migration - the one that
        // api_settings_table got in v12. A silent no-op would be worse - the
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
        await (_db.update(
          _db.apiSettingsTable,
        )..where((t) => t.id.equals(recordId))).write(
          ApiSettingsTableCompanion(
            isDeleted: const Value(true),
            modifiedAt: Value(modifiedAt),
          ),
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
  /// * `exchange_rates` and `inflation_rates` have no `isDeleted` column at all
  ///   (giving them one would need a schema migration), yet [_insertRecord] /
  ///   [_getRecordData] DO apply them. A delete for one of these is therefore
  ///   final only until an older upsert for the same record arrives, which
  ///   resurrects it - see [_softDeleteRecord]. `api_settings_table` used to be
  ///   in this list; it gained the column in schema v12.
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
      case SyncTableId.apiSettings:
        return 'api_settings_table';
      case SyncTableId.smsPresets:
        return 'sms_presets';
      default:
        return null;
    }
  }

  /// The `(modifiedAt, deviceId)` stamp of a locally soft-deleted row, or null
  /// when no deleted row exists.
  ///
  /// Needed because every getById used by [_getRecordData] filters on
  /// `isDeleted = false`, which makes a tombstoned record look exactly like one
  /// this device has never seen. Both halves of the stamp are read because a
  /// tombstone loses or wins a tie by the same total order a live row does; see
  /// [_incomingWins].
  Future<({int modifiedAt, String? deviceId})?> _getDeletedRecordStamp(
    SyncTableId tableId,
    String recordId,
  ) async {
    final tableName = _deletableTableName(tableId);
    if (tableName == null) return null;

    final row = await _db
        .customSelect(
          'SELECT modified_at, device_id FROM $tableName '
          'WHERE id = ? AND is_deleted = 1',
          variables: [Variable<String>(recordId)],
        )
        .getSingleOrNull();
    if (row == null) return null;
    return (
      modifiedAt: row.read<int>('modified_at'),
      deviceId: row.read<String?>('device_id'),
    );
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
      case SyncTableId.apiSettings:
        await _db
            .into(_db.apiSettingsTable)
            .insert(
              ApiSettingsTableCompanion(
                id: Value(recordId),
                // A tombstoned provider must not look like one to fetch from.
                enabled: const Value(false),
                autoFetch: const Value(false),
                modifiedAt: Value(modifiedAt),
                isDeleted: const Value(true),
              ),
              mode: InsertMode.insertOrIgnore,
            );
        break;
      case SyncTableId.smsPresets:
        await _db
            .into(_db.smsPresets)
            .insert(
              SmsPresetsCompanion(
                id: Value(recordId),
                name: const Value(placeholder),
                // A tombstone must not parse anything: `senderFilter` matches
                // no sender and the rule list is empty either way.
                senderFilter: const Value(''),
                rulesJson: const Value('[]'),
                isEnabled: const Value(false),
                modifiedAt: Value(modifiedAt),
                isDeleted: const Value(true),
              ),
              mode: InsertMode.insertOrIgnore,
            );
        break;
      default:
        // exchange_rates and inflation_rates have no isDeleted column, so a
        // delete for a record they have never seen stays a no-op and a later
        // upsert can still resurrect it - fixing that needs a schema
        // migration, the way api_settings_table got one in v12. The other ids
        // are not applied by _insertRecord either, so there is nothing to
        // resurrect for them.
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

  /// An enum value addressed by its wire index, bounded.
  ///
  /// Enums travel as `Enum.index`, and enum members are append-only, so a peer
  /// on a newer build WILL eventually send an index this build does not have -
  /// as will a corrupt or hostile packet. `values[raw]` threw a RangeError from
  /// inside the row converter, out of the change and into the packet loop; the
  /// out-of-range index falls back to [values].first instead, which is exactly
  /// what a payload with the key missing already resolved to. Same rule as
  /// [SyncTableId.fromValue]: never fail a whole packet over one field a newer
  /// peer knows more about.
  T _enumAt<T>(List<T> values, Object? raw) {
    if (raw is int && raw >= 0 && raw < values.length) return values[raw];
    return values.first;
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
      // The anchor the balance is rebuilt from. It only moves when the user
      // edits the account, so unlike `balance` it survives a merge, and sending
      // it is what lets the peer rebuild to the same number instead of falling
      // back on re-deriving an anchor from whatever balance this device
      // happened to compute. Additive: a peer that does not know the keys just
      // ignores them, and a packet that arrives without them is still read the
      // old way (see _accountFromJson).
      'openingBalance': a.openingBalance,
      'openingBalanceMinor': a.openingBalanceMinor,
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
    // Left ABSENT, not defaulted, when the sender said nothing about the
    // anchor: `insertSyncedAccount` re-derives it from the balance that sender
    // did compute, which is the only reading of an old packet that does not
    // invent a number. Writing a 0.0 default here instead would erase the money
    // the account opened with on the next rebuild.
    final openingBalance = (json['openingBalance'] as num?)?.toDouble();
    return AccountsCompanion(
      id: Value(json['id'] as String),
      name: Value(json['name'] as String? ?? 'Account'),
      description: Value(json['description'] as String?),
      balance: Value(balance),
      balanceMinor: Value(
        _minorUnits(json, 'balanceMinor', balance, currencyCode),
      ),
      openingBalance: openingBalance == null
          ? const Value.absent()
          : Value(openingBalance),
      openingBalanceMinor: openingBalance == null
          ? const Value.absent()
          : Value(
              _minorUnits(
                json,
                'openingBalanceMinor',
                openingBalance,
                currencyCode,
              ),
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
      type: Value(_enumAt(CategoryType.values, json['type'])),
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
      type: Value(_enumAt(TypeCurrency.values, json['type'])),
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
      iconType: Value(_enumAt(IconType.values, json['iconType'])),
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

  Map<String, dynamic> _smsPresetToJson(SmsPreset p) {
    return {
      'id': p.id,
      'name': p.name,
      'senderFilter': p.senderFilter,
      'isBuiltIn': p.isBuiltIn,
      'isEnabled': p.isEnabled,
      'defaultAccountId': p.defaultAccountId,
      'defaultCategoryId': p.defaultCategoryId,
      'rulesJson': p.rulesJson,
      'modifiedAt': p.modifiedAt,
      'deviceId': p.deviceId,
      'isDeleted': p.isDeleted,
    };
  }

  SmsPresetsCompanion _smsPresetFromJson(Map<String, dynamic> json) {
    return SmsPresetsCompanion(
      id: Value(json['id'] as String),
      name: Value(json['name'] as String? ?? 'SMS preset'),
      senderFilter: Value(json['senderFilter'] as String? ?? ''),
      isBuiltIn: Value(json['isBuiltIn'] as bool? ?? false),
      isEnabled: Value(json['isEnabled'] as bool? ?? true),
      defaultAccountId: Value(json['defaultAccountId'] as String?),
      defaultCategoryId: Value(json['defaultCategoryId'] as String?),
      // An empty rule list parses nothing, which is the only safe reading of a
      // preset that arrived without one.
      rulesJson: Value(json['rulesJson'] as String? ?? '[]'),
      modifiedAt: Value((json['modifiedAt'] as int?) ?? 0),
      deviceId: Value(json['deviceId'] as String?),
      isDeleted: Value(json['isDeleted'] as bool? ?? false),
    );
  }

  /// `device` is the human-readable name of the machine that last wrote the
  /// setting and is shown next to it, so it travels with the value; `deviceId`
  /// is the sync identity and is what last-write-wins breaks ties on.
  Map<String, dynamic> _settingToJson(Setting s) {
    return {
      'key': s.key,
      'value': s.value,
      'device': s.device,
      'modifiedAt': s.modifiedAt,
      'deviceId': s.deviceId,
    };
  }

  SettingsCompanion _settingFromJson(Map<String, dynamic> json) {
    return SettingsCompanion(
      key: Value(json['key'] as String),
      value: Value(json['value'] as String? ?? ''),
      device: Value(json['device'] as String?),
      modifiedAt: Value((json['modifiedAt'] as int?) ?? 0),
      deviceId: Value(json['deviceId'] as String?),
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
      'isDeleted': s.isDeleted,
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
      // A packet from a build older than schema v12 carries no flag, and the
      // only thing it can mean is "not deleted" - the sender had no way to
      // delete one.
      isDeleted: Value(json['isDeleted'] as bool? ?? false),
    );
  }
}

/// The work one packet leaves behind, gathered while its changes are applied
/// and settled once, after the last of them.
///
/// Both halves used to be done per change: the conflict table was trimmed on
/// every single row (a full unbounded SELECT each time), and the balances were
/// not settled at all - the importer simply wrote the peer's number. Per packet
/// is the right granularity for both, because both are functions of the whole
/// merged batch rather than of any one row in it.
class _PacketEffects {
  /// Accounts whose stored balance the packet has invalidated: every account it
  /// wrote, every account a transaction it wrote belongs to, and every account
  /// such a transaction belonged to BEFORE the packet moved it.
  final Set<String> accounts = {};

  /// The subset written by a peer that said nothing about the opening balance.
  /// Their anchor is re-derived from the balance that peer did compute, so a
  /// rebuild reproduces the sender's arithmetic instead of erasing it.
  final Set<String> anchorlessAccounts = {};

  /// Whether anything was written to `conflict_history`, so an import that
  /// resolved no conflict does not trim a table it did not grow.
  bool wroteConflicts = false;
}
