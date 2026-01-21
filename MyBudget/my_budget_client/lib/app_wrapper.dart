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
    try {
      // 1. Critical initialization - MUST be fast
      _updateProgress(0.1, 'Verifying settings...');
      await sl<SettingsRepository>().initializeDefaults();

      _updateProgress(0.3, 'Initializing Sync Service...');
      await sl<SyncService>().init();

      // 2. Non-critical initialization starts in background immediately
      // This will handle seeding, API fetches, etc. without blocking UI
      IntilizationData.fetchApiDataInBackground();

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
