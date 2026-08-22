import 'package:flutter/material.dart';
import 'package:my_budget_client/app.dart';
import 'package:my_budget_client/core/sync/sync_service.dart';
import 'package:my_budget_client/core/services/server_sync_service.dart';
import 'package:my_budget_client/core/di/injection_container.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/intilization_data.dart';
import 'package:my_budget_client/presentation/screens/splash_screen.dart';
import 'dart:async';

/// Wrapper that shows splash screen during initialization, then shows the main app.
class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  bool _isInitialized = false;
  String _loadingMessage = 'Initializing...';
  double? _progress;

  late final AppLifecycleListener _lifecycleListener;
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    _initialize();
    _lifecycleListener = AppLifecycleListener(
      onPause: _onAppPaused,
      onDetach: _onAppPaused,
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _syncTimer?.cancel();
    super.dispose();
  }

  void _onAppPaused() {
    // Attempt to sync changes when app is closed or backgrounded
    debugPrint('[SYNC_DEBUG] App paused/detached, triggering sync...');

    // P2P Sync
    if (sl.isRegistered<SyncService>()) {
      sl<SyncService>().exportNow();
    }

    // Server Sync
    if (sl.isRegistered<ServerSyncService>()) {
      sl<ServerSyncService>().sync().catchError((e) {
        debugPrint('[SYNC_DEBUG] Server sync on pause failed: $e');
      });
    }
  }

  Future<void> _initialize() async {
    debugPrint('[APP_WRAPPER_DEBUG] ========== INIT START ==========');
    try {
      // 1. Critical initialization - MUST be fast
      debugPrint('[APP_WRAPPER_DEBUG] Step 1: Calling initializeDefaults...');
      _updateProgress(0.1, 'Verifying settings...');
      try {
        await sl<SettingsRepository>().initializeDefaults();
        debugPrint(
          '[APP_WRAPPER_DEBUG] Step 1 OK: initializeDefaults complete',
        );
      } catch (e, st) {
        debugPrint('[APP_WRAPPER_DEBUG] Step 1 FAILED: $e');
        debugPrint('[APP_WRAPPER_DEBUG] Step 1 stack: $st');
        rethrow;
      }

      // 1b. Initialize server sync listeners EARLY — before the app is shown
      // so auto-sync is ready before the user can make any changes.
      // initAutoSync() sets up DB table-update listeners (fast, local).
      // initWebSocket() fires the WS connection attempt in the background.
      debugPrint(
        '[APP_WRAPPER_DEBUG] Step 1b: Checking ServerSyncService registration...',
      );
      if (sl.isRegistered<ServerSyncService>()) {
        debugPrint(
          '[APP_WRAPPER_DEBUG] Step 1b: ServerSyncService registered, calling initAutoSync...',
        );
        final serverSync = sl<ServerSyncService>();
        try {
          await serverSync.initAutoSync();
          debugPrint('[APP_WRAPPER_DEBUG] Step 1b: initAutoSync OK');
          await serverSync.initWebSocket();
          debugPrint('[APP_WRAPPER_DEBUG] Step 1b: initWebSocket OK');
        } catch (e, st) {
          debugPrint('[APP_WRAPPER_DEBUG] Step 1b FAILED (non-fatal): $e');
          debugPrint('[APP_WRAPPER_DEBUG] Step 1b stack: $st');
        }
      } else {
        debugPrint(
          '[APP_WRAPPER_DEBUG] Step 1b: ServerSyncService NOT registered, skipping',
        );
      }

      // 2. Start Services
      // We start non-critical services in the background without awaiting them
      // to let the user enter the app as soon as possible.
      debugPrint('[APP_WRAPPER_DEBUG] Step 2: Starting SyncService...');
      _updateProgress(0.6, 'Starting background services...');
      sl<SyncService>().init().catchError((e) {
        debugPrint('[APP_WRAPPER_DEBUG] SyncService init error: $e');
      });
      debugPrint(
        '[APP_WRAPPER_DEBUG] Step 2: SyncService.init() fired (background)',
      );

      // Non-critical background tasks (asynchronous launch)
      // Note: On Windows, compute() can crash, so we run in the main isolate
      // but without 'await' to achieve background effect.
      debugPrint(
        '[APP_WRAPPER_DEBUG] Step 2b: Firing fetchApiDataInBackground...',
      );
      IntilizationData.fetchApiDataInBackground();

      // Setup 24h periodic sync timer
      _syncTimer?.cancel();
      _syncTimer = Timer.periodic(const Duration(hours: 24), (timer) {
        debugPrint('[SYNC_DEBUG] 24h timer triggered, starting sync...');
        IntilizationData.fetchApiDataInBackground();
      });
      debugPrint('[APP_WRAPPER_DEBUG] Step 2c: 24h sync timer set up');

      // 3. Mark as initialized so the main App can be shown
      debugPrint('[APP_WRAPPER_DEBUG] Step 3: Marking as initialized...');
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
      debugPrint('[APP_WRAPPER_DEBUG] ========== INIT COMPLETE ==========');
    } catch (e, st) {
      debugPrint('[APP_WRAPPER_DEBUG] ========== INIT FAILED ==========');
      debugPrint('[APP_WRAPPER_DEBUG] Error: $e');
      debugPrint('[APP_WRAPPER_DEBUG] Stack trace: $st');
      // Still proceed to app even if init fails to not block the user
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  void _updateProgress(double progress, String message) {
    if (mounted) {
      setState(() {
        _progress = progress;
        _loadingMessage = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialized) {
      return const App();
    }

    return SplashScreen(message: _loadingMessage, progress: _progress);
  }
}
