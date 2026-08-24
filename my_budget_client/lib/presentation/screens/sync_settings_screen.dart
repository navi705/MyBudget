import 'package:my_budget_client/core/utils/platform/platform_utils.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:my_budget_client/core/di/injection_container.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/core/sync/sync_service.dart';
import 'package:my_budget_client/core/services/server_sync_service.dart';
import 'package:flutter/foundation.dart' as foundation;

import 'package:my_budget_client/core/extensions/context_extensions.dart';

/// Settings screen for P2P synchronization via Syncthing
class SyncSettingsScreen extends StatefulWidget {
  const SyncSettingsScreen({super.key});

  @override
  State<SyncSettingsScreen> createState() => _SyncSettingsScreenState();
}

class _SyncSettingsScreenState extends State<SyncSettingsScreen> {
  late final SyncService _syncService;
  late final ServerSyncService _serverSyncService;
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
    if (!mounted) return;

    setState(() {
      _syncFolderPath = folderSetting?.value;
      _isP2PEnabled = p2pEnabledSetting?.value == 'true';
      _isServerEnabled = serverEnabledSetting?.value == 'true';

      // Enforce mutual exclusivity if both were stored as true
      if (_isP2PEnabled && _isServerEnabled) {
        _isServerEnabled = false;
      }

      _serverUrlController.text = serverUrlSetting?.value ?? '';
      _serverTokenController.text = serverTokenSetting?.value ?? '';
      _incomingChanges = incoming;
    });

    // Calculate pending CHANGES AFTER we know which mode is enabled
    final pending = _isServerEnabled
        ? await _serverSyncService.getPendingChangesCount()
        : await _syncService.getPendingChangesCount();
    if (!mounted) return;

    setState(() {
      _pendingChanges = pending;
    });

    if (_isP2PEnabled && _syncFolderPath != null) {
      await _syncService.startSync(_syncFolderPath!);
    }
  }

  Future<void> _pickFolder() async {
    final l10n = context.l10n;
    if (AppPlatform.isAndroid) {
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
            _showSnackbar(l10n.syncPermissionRequired, isError: true);
          }
          return;
        }
      }
    }

    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: l10n.syncSelectFolderTitle,
    );

    if (result != null) {
      if (!mounted) return;
      setState(() => _syncFolderPath = result);
      await _settingsRepository.saveSetting('sync_folder_path', result);
    }
  }

  Future<void> _clearSyncFolder() async {
    if (_syncFolderPath == null) return;
    final l10n = context.l10n;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.syncClearFilesTitle),
        content: Text(l10n.syncClearFilesConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.clearButton),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final deletedCount = await _syncService.clearSyncFolder();
      if (mounted) {
        _showSnackbar(l10n.syncDeletedFilesCount(deletedCount));
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar(l10n.syncClearFilesError(e.toString()), isError: true);
      }
    }
  }

  /// Re-uploads everything to the server and re-reads it from the start.
  ///
  /// For a server whose database was wiped or replaced: an ordinary sync sends
  /// only what is owed, and after a wipe nothing is owed, so the server would
  /// stay empty. See [ServerSyncService.resendEverything].
  Future<void> _resendEverything() async {
    if (_isSyncing) return;
    final l10n = context.l10n;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.syncResendEverythingTitle),
        content: Text(l10n.syncResendEverythingConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.confirmButton),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    // Same guard as the ordinary sync button: resendEverything() ends in a
    // sync(), which declines without an address and would report success for a
    // transfer that never left the device.
    if (normalizeSyncBaseUrl(_serverUrlController.text) == null) {
      _showSnackbar(l10n.syncUrlNotConfigured, isError: true);
      return;
    }

    setState(() => _isSyncing = true);
    try {
      await _serverSyncService.resendEverything();
      final pending = await _serverSyncService.getPendingChangesCount();
      if (!mounted) return;
      setState(() => _pendingChanges = pending);
      _showSnackbar(l10n.syncCompleted);
    } on SyncAuthException catch (e) {
      if (mounted) {
        _showSnackbar(
          e.status == SyncConnectionStatus.serverNotConfigured
              ? l10n.syncServerNotConfigured
              : l10n.syncConnectionUnauthorized,
          isError: true,
        );
      }
    } catch (e) {
      debugPrint('Full resend error: $e');
      if (mounted) {
        _showSnackbar(l10n.syncFailed(e.toString()), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
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
      // Turning the switch on before typing an address is the ordinary order to
      // do it in. Starting the socket and the auto-sync listener here would
      // dial nowhere and retry for the rest of the session, so the machinery
      // waits until the address is saved.
      if (normalizeSyncBaseUrl(_serverUrlController.text) == null) {
        if (mounted) {
          _showSnackbar(context.l10n.syncUrlNotConfigured, isError: true);
        }
        return;
      }
      // Initialize WebSocket listener and DB auto-sync subscription so that
      // background sync starts immediately without requiring an app restart.
      await _serverSyncService.initWebSocket();
      await _serverSyncService.initAutoSync();
      // Trigger an initial sync to pull/push any pending changes right away.
      _syncNow();
    }
  }

  Future<void> _saveServerSettings() async {
    // Stored trimmed: a trailing space or newline pasted with the address made
    // every request URL invalid, and the failure surfaced as a connection error
    // pointing at the server rather than at the field.
    final url = _serverUrlController.text.trim();
    await _settingsRepository.saveSetting('server_sync_url', url);
    await _settingsRepository.saveSetting(
      'server_sync_token',
      _serverTokenController.text.trim(),
    );
    if (!mounted) return;
    // Saving an unusable address is allowed — half-typed settings are normal —
    // but it is said out loud, because sync will simply not run until it is
    // fixed and nothing else in the app would mention it.
    final unusable = normalizeSyncBaseUrl(url) == null;
    _showSnackbar(
      unusable
          ? context.l10n.syncUrlNotConfigured
          : context.l10n.syncSettingsSaved,
      isError: unusable,
    );
  }

  void _showSnackbar(String message, {bool isError = false}) {
    // Prevent stacking by clearing any existing SnackBars
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? Colors.red : Colors.green,
        // Wrap content in GestureDetector to allow tap-to-dismiss
        content: GestureDetector(
          onTap: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          behavior: HitTestBehavior.opaque, // Ensure tap is caught
          child: Text(message),
        ),
      ),
    );
  }

  bool _isTestingConnection = false;

  Future<void> _testConnection() async {
    setState(() => _isTestingConnection = true);
    final l10n = context.l10n;

    // Unfocus keyboard
    FocusScope.of(context).unfocus();

    try {
      final status = await _serverSyncService.testConnection(
        url: _serverUrlController.text,
        token: _serverTokenController.text,
      );

      if (mounted) {
        // Each failure points at the one thing that is actually wrong. A
        // single "connection failed" for all three sent the user editing the
        // URL when the server had simply rejected the token.
        switch (status) {
          case SyncConnectionStatus.ok:
            _showSnackbar(l10n.syncConnectionSuccessful);
          case SyncConnectionStatus.unauthorized:
            _showSnackbar(l10n.syncConnectionUnauthorized, isError: true);
          case SyncConnectionStatus.serverNotConfigured:
            _showSnackbar(l10n.syncServerNotConfigured, isError: true);
          case SyncConnectionStatus.failed:
            _showSnackbar(l10n.syncConnectionFailed, isError: true);
          case SyncConnectionStatus.notConfigured:
            _showSnackbar(l10n.syncUrlNotConfigured, isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar(e.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isTestingConnection = false);
      }
    }
  }

  Future<void> _syncNow() async {
    if (_isSyncing) return;
    final l10n = context.l10n;

    setState(() => _isSyncing = true);

    try {
      if (_isServerEnabled) {
        // sync() declines without an address, and reporting "sync completed"
        // for a cycle that never left the device is worse than saying nothing.
        if (normalizeSyncBaseUrl(_serverUrlController.text) == null) {
          _showSnackbar(l10n.syncUrlNotConfigured, isError: true);
          return;
        }
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
          : await _syncService.getPendingChangesCount();
      final incoming = await _syncService.getIncomingFileCount();

      if (!mounted) return;

      setState(() {
        _pendingChanges = pending;
        _incomingChanges = incoming;
      });

      _showSnackbar(l10n.syncCompleted);
    } on SyncAuthException catch (e) {
      // The raw exception would read "SyncAuthException(unauthorized)" inside
      // "Sync failed: ...", which tells the user nothing they can act on.
      if (mounted) {
        _showSnackbar(
          e.status == SyncConnectionStatus.serverNotConfigured
              ? l10n.syncServerNotConfigured
              : l10n.syncConnectionUnauthorized,
          isError: true,
        );
      }
    } catch (e) {
      debugPrint('Manual sync error: $e');
      if (mounted) {
        _showSnackbar(l10n.syncFailed(e.toString()), isError: true);
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
    final l10n = context.l10n;
    if (foundation.kIsWeb) {
      // /settings/sync is registered unconditionally and, on web, every route is
      // reachable by typing its URL. A bare Center() would land those visitors
      // on an unstyled page with no title and no way back, so this branch keeps
      // the same Scaffold + AppBar shell as the unsupported-platform notice in
      // SmsSettingsScreen.
      return Scaffold(
        appBar: AppBar(title: Text(l10n.syncScreenTitle)),
        body: Center(child: Text(l10n.syncWebNotAvailable)),
      );
    }
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: Text(l10n.syncScreenTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section Label: P2P
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              l10n.syncP2PSection,
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
                  title: Text(l10n.syncEnableP2P),
                  subtitle: Text(l10n.syncP2PSubtitle),
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
                        Text(
                          l10n.syncFolderLabel,
                          style: theme.textTheme.labelLarge,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _syncFolderPath ?? l10n.syncFolderNotSelected,
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
                              child: Text(l10n.syncBrowseButton),
                            ),
                          ],
                        ),
                        if (_syncFolderPath != null) ...[
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _clearSyncFolder,
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: Text(l10n.syncClearFilesButton),
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
              l10n.syncServerSection,
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
                        decoration: InputDecoration(
                          labelText: l10n.syncServerUrlLabel,
                          hintText: 'http://localhost:58080',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.link),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _serverTokenController,
                        decoration: InputDecoration(
                          labelText: l10n.syncApiTokenLabel,
                          hintText: l10n.syncApiTokenHint,
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
                        l10n.syncApiTokenHelp,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isTestingConnection
                              ? null
                              : _testConnection,
                          icon: _isTestingConnection
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.wifi_find_outlined),
                          label: Text(
                            _isTestingConnection
                                ? l10n.syncTestingLabel
                                : l10n.syncTestConnectionButton,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _saveServerSettings,
                          icon: const Icon(Icons.save_outlined),
                          label: Text(l10n.syncSaveServerSettingsButton),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  SwitchListTile(
                    title: Text(l10n.syncEnableServer),
                    subtitle: Text(l10n.syncServerSubtitle),
                    value: _isServerEnabled,
                    onChanged: _toggleServer,
                    contentPadding: EdgeInsets.zero,
                  ),
                  // Kept out of the shared action card below on purpose: it
                  // does nothing for peer-to-peer sync, and it is a full
                  // transfer rather than the usual few rows.
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isServerEnabled && !_isSyncing
                          ? _resendEverything
                          : null,
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: Text(l10n.syncResendEverythingButton),
                    ),
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
                      Text(l10n.syncPendingLocalChanges),
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
                    children: [],
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
                      label: Text(
                        _isSyncing
                            ? l10n.syncSyncingLabel
                            : l10n.syncSyncNowButton,
                      ),
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
