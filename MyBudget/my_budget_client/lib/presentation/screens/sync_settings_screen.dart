import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/di/injection_container.dart';
import 'package:my_budget_client/core/sync/sync_service.dart';

/// Settings screen for P2P synchronization via Syncthing
class SyncSettingsScreen extends StatefulWidget {
  const SyncSettingsScreen({super.key});

  @override
  State<SyncSettingsScreen> createState() => _SyncSettingsScreenState();
}

class _SyncSettingsScreenState extends State<SyncSettingsScreen> {
  late final SyncService _syncService;
  late final AppDatabase _db;

  String? _syncFolderPath;
  bool _isEnabled = false;
  bool _isSyncing = false;
  String _localDeviceId = '';
  int _pendingChanges = 0;

  @override
  void initState() {
    super.initState();
    _db = sl<AppDatabase>();
    _syncService = SyncService(_db);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final folderSetting = await _db.settingsDao.getSetting('sync_folder_path');
    final enabledSetting = await _db.settingsDao.getSetting('sync_enabled');
    final deviceId = await _syncService.getLocalDeviceId();
    final pending = await _db.syncLogDao.getPendingChanges();

    setState(() {
      _syncFolderPath = folderSetting?.value;
      _isEnabled = enabledSetting?.value == 'true';
      _localDeviceId = deviceId;
      _pendingChanges = pending.length;
    });

    if (_isEnabled && _syncFolderPath != null) {
      await _syncService.startSync(_syncFolderPath!);
    }
  }

  Future<void> _pickFolder() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Syncthing Folder',
    );

    if (result != null) {
      setState(() => _syncFolderPath = result);

      // Save setting
      final deviceName = await _db.settingsDao.getSetting('device_name');
      await _db.settingsDao.setSetting(
        SettingsCompanion(
          key: const Value('sync_folder_path'),
          value: Value(result),
          device: Value(deviceName?.value ?? 'default'),
          modifiedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );
    }
  }

  Future<void> _toggleSync(bool enabled) async {
    setState(() => _isEnabled = enabled);

    final deviceName = await _db.settingsDao.getSetting('device_name');
    await _db.settingsDao.setSetting(
      SettingsCompanion(
        key: const Value('sync_enabled'),
        value: Value(enabled.toString()),
        device: Value(deviceName?.value ?? 'default'),
        modifiedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );

    if (enabled && _syncFolderPath != null) {
      await _syncService.startSync(_syncFolderPath!);
    } else {
      await _syncService.stopSync();
    }
  }

  Future<void> _syncNow() async {
    if (_syncFolderPath == null) return;

    setState(() => _isSyncing = true);

    try {
      // Start sync if not running
      if (!_syncService.isRunning) {
        await _syncService.startSync(_syncFolderPath!);
      }

      // Export pending changes
      await _syncService.exportNow();

      // Import new files
      await _syncService.importNow();

      // Refresh pending count
      final pending = await _db.syncLogDao.getPendingChanges();
      setState(() => _pendingChanges = pending.length);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Sync completed')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sync failed: $e')));
      }
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Sync Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Device ID card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Device ID', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SelectableText(
                    _localDeviceId.isEmpty ? 'Loading...' : _localDeviceId,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Sync folder selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Syncthing Folder', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _syncFolderPath ?? 'Not selected',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: _syncFolderPath == null
                                ? theme.colorScheme.outline
                                : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonal(
                        onPressed: _pickFolder,
                        child: const Text('Browse'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select a folder that is synced via Syncthing',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Enable sync toggle
          Card(
            child: SwitchListTile(
              title: const Text('Enable Sync'),
              subtitle: Text(
                _syncService.isRunning ? 'Sync is active' : 'Sync is disabled',
              ),
              value: _isEnabled,
              onChanged: _syncFolderPath != null ? _toggleSync : null,
            ),
          ),

          const SizedBox(height: 16),

          // Status card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Pending changes:'),
                      Text('$_pendingChanges'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Sync interval:'),
                      Text('${_syncService.batchInterval.inSeconds}s'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Sync now button
          FilledButton.icon(
            onPressed: _syncFolderPath != null && !_isSyncing ? _syncNow : null,
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            label: Text(_isSyncing ? 'Syncing...' : 'Sync Now'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Don't stop sync on dispose - let it run in background
    super.dispose();
  }
}
