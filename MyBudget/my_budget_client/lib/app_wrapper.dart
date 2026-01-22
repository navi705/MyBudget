import 'package:flutter/material.dart';
import 'package:my_budget_client/app.dart';
import 'package:my_budget_client/core/sync/sync_service.dart';
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
    debugPrint('[SYNC_DEBUG] App paused/detached, triggering exportNow()');
    sl<SyncService>().exportNow();
  }

  Future<void> _initialize() async {
    try {
      // 1. Critical initialization - MUST be fast
      _updateProgress(0.1, 'Verifying settings...');
      await sl<SettingsRepository>().initializeDefaults();

      // 2. Start Services
      // We start non-critical services in the background without awaiting them
      // to let the user enter the app as soon as possible.
      _updateProgress(0.6, 'Starting background services...');
      sl<SyncService>().init().catchError((e) {
        debugPrint('SyncService init error: $e');
      });

      // Non-critical background tasks (asynchronous launch)
      // Note: On Windows, compute() can crash, so we run in the main isolate
      // but without 'await' to achieve background effect.
      IntilizationData.fetchApiDataInBackground();

      // Setup 24h periodic sync timer
      _syncTimer?.cancel();
      _syncTimer = Timer.periodic(const Duration(hours: 24), (timer) {
        debugPrint('[SYNC_DEBUG] 24h timer triggered, starting sync...');
        IntilizationData.fetchApiDataInBackground();
      });

      // 3. Mark as initialized so the main App can be shown
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Initialization error: $e');
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
