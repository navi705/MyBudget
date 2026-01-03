import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class PerformanceLogger {
  static final PerformanceLogger _instance = PerformanceLogger._internal();

  factory PerformanceLogger() {
    return _instance;
  }

  PerformanceLogger._internal();

  final Map<String, Stopwatch> _stopwatches = {};

  void start(String label) {
    if (kDebugMode) {
      final stopwatch = Stopwatch()..start();
      _stopwatches[label] = stopwatch;
    }
  }

  Future<void> stop(String label) async {
    if (kDebugMode) {
      final stopwatch = _stopwatches.remove(label);
      if (stopwatch != null) {
        stopwatch.stop();
        final duration = stopwatch.elapsedMilliseconds;
        await _logResult(label, duration);
      }
    }
  }

  Future<void> _logResult(String label, int duration) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/performance_logs.txt');

      final timestamp = DateTime.now().toLocal().toString().split('.')[0];
      final logEntry = '[$timestamp] $label: ${duration}ms\n';

      await file.writeAsString(logEntry, mode: FileMode.append);
      debugPrint('PERFORMANCE LOG: $logEntry');
    } catch (e) {
      debugPrint('Error logging performance: $e');
    }
  }
}
