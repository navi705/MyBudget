import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:my_budget_client/app.dart';
import 'package:my_budget_client/core/sync/sync_service.dart';
import 'package:my_budget_client/core/di/injection_container.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/intilization_data.dart';
import 'package:my_budget_client/presentation/screens/splash_screen.dart';

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
    super.dispose();
  }

  void _onAppPaused() {
    // Attempt to sync changes when app is closed or backgrounded
    debugPrint('[SYNC_DEBUG] App paused/detached, triggering exportNow()');
    sl<SyncService>().exportNow();
  }

  Future<void> _initialize() async {
    debugPrint('[SYNC_DEBUG] AppWrapper._initialize() started');
    try {
      // Step 0: Ensure local DB defaults are seeded (fixes crash on old DBs)
      _updateProgress(0.1, 'Verifying settings...');
      await sl<SettingsRepository>().initializeDefaults();

      // Step 0.5: Initialize Sync Service
      await sl<SyncService>().init();
      // Step 1: Load local data (fast, from files)
      _updateProgress(0.3, 'Loading exchange rates...');
      await IntilizationData.loadLocalData();

      _updateProgress(0.9, 'Ready!');

      // Small delay to show "Ready!" message
      await Future.delayed(const Duration(milliseconds: 1000));

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }

      // Step 2: Fetch fresh API data in background (non-blocking)
      // This runs AFTER the app is shown
      IntilizationData.fetchApiDataInBackground();
    } catch (e) {
      debugPrint('Initialization error: $e');
      // Still proceed to app even if init fails
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
