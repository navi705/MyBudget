import 'dart:io';

// import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/di/injection_container.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
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
  late final SettingsRepository _settingsRepository;

  String? _syncFolderPath;
  bool _isEnabled = false;
  bool _isSyncing = false;
  int _pendingChanges = 0;

  @override
  void initState() {
    super.initState();
    _db = sl<AppDatabase>();
    _syncService = sl<SyncService>();
    _settingsRepository = sl<SettingsRepository>();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final folderSetting = await _settingsRepository.getSetting(
      'sync_folder_path',
    );
    final enabledSetting = await _settingsRepository.getSetting('sync_enabled');
    final pending = await _db.syncLogDao.getPendingChanges();

    setState(() {
      _syncFolderPath = folderSetting?.value;
      _isEnabled = enabledSetting?.value == 'true';
      _pendingChanges = pending.length;
    });

    if (_isEnabled && _syncFolderPath != null) {
      final success = await _syncService.startSync(_syncFolderPath!);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cannot access sync folder. On Android 11+, please select a folder within Documents or Downloads.',
            ),
            duration: Duration(seconds: 5),
          ),
        );
        setState(() => _isEnabled = false);
      }
    }
  }

  Future<void> _pickFolder() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Syncthing Folder',
    );

    if (result != null) {
      setState(() => _syncFolderPath = result);

      // Save setting
      await _settingsRepository.saveSetting('sync_folder_path', result);
    }
  }

  Future<void> _clearSyncFolder() async {
    if (_syncFolderPath == null) return;

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Sync Files'),
        content: const Text(
          'This will delete all .sync files from the selected folder. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final dir = Directory(_syncFolderPath!);
      if (await dir.exists()) {
        int deletedCount = 0;
        await for (final entity in dir.list()) {
          if (entity is File && entity.path.endsWith('.sync')) {
            await entity.delete();
            deletedCount++;
          }
        }

        // Also clear .processed subfolder
        final processedDir = Directory('${_syncFolderPath!}/.processed');
        if (await processedDir.exists()) {
          await for (final entity in processedDir.list()) {
            if (entity is File && entity.path.endsWith('.sync')) {
              await entity.delete();
              deletedCount++;
            }
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deleted $deletedCount sync files')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error clearing files: $e')));
      }
    }
  }

  Future<void> _toggleSync(bool enabled) async {
    setState(() => _isEnabled = enabled);

    await _settingsRepository.saveSetting('sync_enabled', enabled.toString());

    if (enabled && _syncFolderPath != null) {
      final success = await _syncService.startSync(_syncFolderPath!);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cannot access sync folder. On Android 11+, please select a folder within Documents or Downloads.',
            ),
            duration: Duration(seconds: 5),
          ),
        );
        setState(() => _isEnabled = false);
        return;
      }
    } else {
      await _syncService.stopSync();
    }
  }

  Future<void> _syncNow() async {
    if (_syncFolderPath == null) return;

    setState(() => _isSyncing = true);

    try {
      if (!_syncService.isRunning) {
        final success = await _syncService.startSync(_syncFolderPath!);
        if (!success) {
          throw Exception('Cannot access sync folder');
        }
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
                  // Android 11+ warning - only show on Android
                  if (Platform.isAndroid) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiaryContainer.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: theme.colorScheme.onTertiaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Android 11+: Select a folder within Documents or Downloads',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onTertiaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_syncFolderPath != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _clearSyncFolder,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Clear sync files'),
                    ),
                  ],
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
