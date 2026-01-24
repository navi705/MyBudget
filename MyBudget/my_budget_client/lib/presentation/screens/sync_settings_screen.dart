import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/di/injection_container.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/core/sync/sync_service.dart';
import 'package:my_budget_client/core/services/server_sync_service.dart';

/// Settings screen for P2P synchronization via Syncthing
class SyncSettingsScreen extends StatefulWidget {
  const SyncSettingsScreen({super.key});

  @override
  State<SyncSettingsScreen> createState() => _SyncSettingsScreenState();
}

class _SyncSettingsScreenState extends State<SyncSettingsScreen> {
  late final SyncService _syncService;
  late final ServerSyncService _serverSyncService;
  late final AppDatabase _db;
  late final SettingsRepository _settingsRepository;

  final _serverUrlController = TextEditingController();
  final _serverTokenController = TextEditingController();

  String? _syncFolderPath;
  bool _isP2PEnabled = false;
  bool _isServerEnabled = false;
  bool _isSyncing = false;
  int _pendingChanges = 0;
  int _incomingChanges = 0;
  bool _obscureToken = true;

  @override
  void initState() {
    super.initState();
    _db = sl<AppDatabase>();
    _syncService = sl<SyncService>();
    _serverSyncService = sl<ServerSyncService>();
    _settingsRepository = sl<SettingsRepository>();
    _loadSyncSettings();
  }

  Future<void> _loadSyncSettings() async {
    final folderSetting = await _settingsRepository.getSetting(
      'sync_folder_path',
    );
    final p2pEnabledSetting = await _settingsRepository.getSetting(
      'sync_enabled',
    );
    final serverEnabledSetting = await _settingsRepository.getSetting(
      'server_sync_enabled',
    );
    final serverUrlSetting = await _settingsRepository.getSetting(
      'server_sync_url',
    );
    final serverTokenSetting = await _settingsRepository.getSetting(
      'server_sync_token',
    );

    final incoming = await _syncService.getIncomingFileCount();

    setState(() {
      _syncFolderPath = folderSetting?.value;
      _isP2PEnabled = p2pEnabledSetting?.value == 'true';
      _isServerEnabled = serverEnabledSetting?.value == 'true';

      // Enforce mutual exclusivity if both were stored as true
      if (_isP2PEnabled && _isServerEnabled) {
        _isServerEnabled = false;
      }

      _serverUrlController.text =
          serverUrlSetting?.value ?? 'http://localhost:58080';
      _serverTokenController.text = serverTokenSetting?.value ?? 'dev_token';
      _incomingChanges = incoming;
    });

    // Calculate pending CHANGES AFTER we know which mode is enabled
    final pending = _isServerEnabled
        ? await _serverSyncService.getPendingChangesCount()
        : (await _db.syncLogDao.getPendingChanges()).length;

    setState(() {
      _pendingChanges = pending;
    });

    if (_isP2PEnabled && _syncFolderPath != null) {
      await _syncService.startSync(_syncFolderPath!);
    }
  }

  Future<void> _pickFolder() async {
    if (Platform.isAndroid) {
      // Request Manage External Storage for Android 11+
      var status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        status = await Permission.manageExternalStorage.request();
      }

      // Fallback for older Android (though manageExternalStorage covers newer)
      if (!status.isGranted) {
        final storageStatus = await Permission.storage.request();
        if (!storageStatus.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Storage permission required for sync. Please enable "All files access" in settings.',
                ),
              ),
            );
          }
          return;
        }
      }
    }

    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Syncthing Folder',
    );

    if (result != null) {
      setState(() => _syncFolderPath = result);
      await _settingsRepository.saveSetting('sync_folder_path', result);
    }
  }

  Future<void> _clearSyncFolder() async {
    if (_syncFolderPath == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Sync Files'),
        content: const Text(
          'This will delete all .sync files from the selected folder. This action cannot be undone.',
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

  Future<void> _toggleP2P(bool enabled) async {
    setState(() {
      _isP2PEnabled = enabled;
      if (enabled) _isServerEnabled = false;
    });

    await _settingsRepository.saveSetting('sync_enabled', enabled.toString());
    if (enabled) {
      await _settingsRepository.saveSetting('server_sync_enabled', 'false');
      if (_syncFolderPath != null) {
        await _syncService.startSync(_syncFolderPath!);
      }
    } else {
      await _syncService.stopSync();
    }
  }

  Future<void> _toggleServer(bool enabled) async {
    setState(() {
      _isServerEnabled = enabled;
      if (enabled) _isP2PEnabled = false;
    });

    await _settingsRepository.saveSetting(
      'server_sync_enabled',
      enabled.toString(),
    );
    if (enabled) {
      await _settingsRepository.saveSetting('sync_enabled', 'false');
      await _syncService.stopSync();
      // Optionally trigger initial sync
      _syncNow();
    }
  }

  Future<void> _saveServerSettings() async {
    await _settingsRepository.saveSetting(
      'server_sync_url',
      _serverUrlController.text,
    );
    await _settingsRepository.saveSetting(
      'server_sync_token',
      _serverTokenController.text,
    );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Server settings saved')));
    }
  }

  Future<void> _syncNow() async {
    if (_isSyncing) return;

    setState(() => _isSyncing = true);

    try {
      if (_isServerEnabled) {
        await _serverSyncService.sync();
      } else if (_isP2PEnabled && _syncFolderPath != null) {
        if (!_syncService.isRunning) {
          await _syncService.startSync(_syncFolderPath!);
        }
        await _syncService.exportNow();
        await _syncService.importNow();
      }

      // Refresh counts after sync
      final pending = _isServerEnabled
          ? await _serverSyncService.getPendingChangesCount()
          : (await _db.syncLogDao.getPendingChanges()).length;
      final incoming = await _syncService.getIncomingFileCount();

      if (mounted) {
        setState(() {
          _pendingChanges = pending;
          _incomingChanges = incoming;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sync completed successfully')),
        );
      }
    } catch (e) {
      debugPrint('Manual sync error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sync failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('Synchronization Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section Label: P2P
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'P2P Synchronization (Syncthing)',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Enable P2P Sync'),
                  subtitle: const Text(
                    'Sync via .sync files in a shared folder',
                  ),
                  value: _isP2PEnabled,
                  onChanged: _syncFolderPath != null ? _toggleP2P : null,
                ),
                if (_isP2PEnabled || _syncFolderPath == null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        const SizedBox(height: 8),
                        Text('Sync Folder', style: theme.textTheme.labelLarge),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _syncFolderPath ?? 'Not selected',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: _syncFolderPath == null
                                      ? theme.colorScheme.error
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
                        if (_syncFolderPath != null) ...[
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _clearSyncFolder,
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Clear sync files'),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section Label: Server
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Cloud Synchronization (Server)',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _serverUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Server URL',
                          hintText: 'http://localhost:58080',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.link),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _serverTokenController,
                        decoration: InputDecoration(
                          labelText: 'API Token',
                          hintText: 'Enter your security token',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureToken
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureToken = !_obscureToken;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscureToken,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This token is your shared secret. Enter the same value on all your devices to authorize synchronization.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _saveServerSettings,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Save Server Settings'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Enable Server Sync'),
                    subtitle: const Text(
                      'Sync with a MyBudget Server instance',
                    ),
                    value: _isServerEnabled,
                    onChanged: _toggleServer,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Shared Status & Action
          Card(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.3,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Pending local changes:'),
                      Text(
                        '$_pendingChanges',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // const Text('Incoming changes pending:'),
                      // Text(
                      //   '$_incomingChanges',
                      //   style: theme.textTheme.titleMedium?.copyWith(
                      //     fontWeight: FontWeight.bold,
                      //     color: _incomingChanges > 0
                      //         ? theme.colorScheme.primary
                      //         : null,
                      //   ),
                      // ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed:
                          (_isP2PEnabled || _isServerEnabled) && !_isSyncing
                          ? _syncNow
                          : null,
                      icon: _isSyncing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.sync_alt),
                      label: Text(_isSyncing ? 'Syncing...' : 'Sync Now'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _serverTokenController.dispose();
    super.dispose();
  }
}
