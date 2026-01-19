import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:my_budget_client/app.dart';
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

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Step 1: Load local data (fast, from files)
      _updateProgress(0.3, 'Loading exchange rates...');
      await IntilizationData.loadLocalData();

      _updateProgress(0.9, 'Ready!');

      // Small delay to show "Ready!" message
      await Future.delayed(const Duration(milliseconds: 200));

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
