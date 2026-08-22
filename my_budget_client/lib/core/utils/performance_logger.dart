import 'dart:async';

import 'package:my_budget_client/core/utils/platform/platform_utils.dart';
import 'package:my_budget_client/core/utils/platform/io_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

/// Debug-only timing log.
///
/// [stop] returns a future so the call sites can `await` it, but it no longer
/// waits for anything: it takes the reading and hands the line to a writer that
/// drains in the background. Awaiting the write put a document-directory lookup
/// and a file append on the critical path of whatever was being measured — some
/// 16ms per call, thirteen calls in one transactions load — so the logger was
/// costing more than most of the steps it reported, and every number it printed
/// included the write of the line before it.
class PerformanceLogger {
  static final PerformanceLogger _instance = PerformanceLogger._internal();

  factory PerformanceLogger() {
    return _instance;
  }

  PerformanceLogger._internal();

  final Map<String, Stopwatch> _stopwatches = {};

  /// Lines taken but not yet written.
  final List<String> _pending = [];

  /// The drain in flight, if any. One at a time, so the lines keep their order
  /// and two appends never overlap on the same file.
  bool _draining = false;
  Future<void>? _drainDone;

  /// Resolved once — [getApplicationDocumentsDirectory] is a platform channel
  /// round trip, and it answered the same thing every time.
  Future<String>? _logPath;

  void start(String label) {
    if (kDebugMode) {
      final stopwatch = Stopwatch()..start();
      _stopwatches[label] = stopwatch;
    }
  }

  Future<void> stop(String label) async {
    if (!kDebugMode) return;
    final stopwatch = _stopwatches.remove(label);
    if (stopwatch == null) return;
    stopwatch.stop();
    _record(label, stopwatch.elapsedMilliseconds);
  }

  /// Waits for everything taken so far to be written.
  ///
  /// Nothing in the app needs this — it is here so a test can assert on the
  /// file instead of racing the drain.
  Future<void> flush() async {
    while (_draining) {
      await _drainDone;
    }
  }

  void _record(String label, int duration) {
    final timestamp = DateTime.now().toLocal().toString().split('.')[0];
    final logEntry = '[$timestamp] $label: ${duration}ms\n';
    debugPrint('PERFORMANCE LOG: $logEntry');
    if (kIsWeb) return; // No file to append to; debugPrint above is the log.
    _pending.add(logEntry);
    if (!_draining) {
      _draining = true;
      _drainDone = _drain();
    }
  }

  Future<void> _drain() async {
    try {
      while (_pending.isNotEmpty) {
        // Everything taken up to now goes out in one append, so a burst of
        // measurements costs one write rather than one per line.
        final batch = _pending.join();
        _pending.clear();
        final path = await (_logPath ??= _resolveLogPath());
        await IoHelper.appendAsString(path, batch);
      }
    } catch (e) {
      // A logger must not take the app down with it, and the path lookup fails
      // outright in tests (no path_provider plugin behind the channel).
      _pending.clear();
      _logPath = null;
      debugPrint('Error logging performance: $e');
    } finally {
      _draining = false;
    }
  }

  Future<String> _resolveLogPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/performance_logs.txt';
  }
}
