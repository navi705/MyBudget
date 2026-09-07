import 'package:flutter/material.dart';
import 'package:my_budget_client/app.dart';
import 'package:my_budget_client/core/sync/sync_service.dart';
import 'package:my_budget_client/core/services/server_sync_service.dart';
import 'package:my_budget_client/core/database/app_database.dart';
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

  /// How long the detach path will wait for the local export before giving up.
  ///
  /// Short on purpose: the platform is already shutting the app down and will
  /// kill the process regardless. Two seconds is enough for a normal export
  /// (it is local file writes, and the encode itself now runs off the UI
  /// isolate) without leaving a visible hang if the disk is busy.
  static const Duration _detachFlushBudget = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _initialize();
    // Pause and detach are deliberately NOT the same handler any more.
    //
    // Pause means "the user switched away" — the process is still alive, the
    // services keep running, and there is time for a real sync. Detach means
    // the engine is already tearing the app down: whatever is not finished by
    // the time this returns is killed mid-flight. Firing a full sync cycle
    // there (a pull, then sixteen table pushes over the network) could never
    // finish, and it held the shutdown open while it tried.
    _lifecycleListener = AppLifecycleListener(
      onPause: _onAppPaused,
      onDetach: _onAppDetached,
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _syncTimer?.cancel();

    // Nothing else in the app ever called these, so the reconnect ladder, the
    // ping timer, the 5-minute periodic sync, the 30s retry and the drift
    // table-update listener all outlived the widget that started them — on a
    // hot restart or any rebuild of the wrapper they simply accumulated.
    // Stopping (not disposing) leaves both services able to come back if the
    // wrapper is mounted again.
    _stopSyncServices();

    super.dispose();
  }

  /// Cancels every background timer and listener the two sync services own.
  ///
  /// Both are idempotent and both leave the service re-startable, which is why
  /// [stop] is used rather than [ServerSyncService.dispose]: the GetIt
  /// singletons outlive this widget and a disposed one would stay inert.
  void _stopSyncServices() {
    if (sl.isRegistered<ServerSyncService>()) {
      sl<ServerSyncService>().stop();
    }
    if (sl.isRegistered<SyncService>()) {
      unawaited(
        sl<SyncService>().stopSync().catchError((Object e) {
          debugPrint('[SYNC_DEBUG] stopSync during teardown failed: $e');
        }),
      );
    }
  }

  void _onAppPaused() {
    // Backgrounded, not closing: the process survives, so a full cycle is both
    // affordable and the right thing to do — this is the app's main
    // opportunity to push what the user just did.
    debugPrint('[SYNC_DEBUG] App paused, triggering sync...');

    // P2P Sync
    if (sl.isRegistered<SyncService>()) {
      unawaited(
        sl<SyncService>().exportNow().catchError((Object e) {
          debugPrint('[SYNC_DEBUG] Export on pause failed: $e');
        }),
      );
    }

    // Server Sync
    if (sl.isRegistered<ServerSyncService>()) {
      unawaited(
        sl<ServerSyncService>().sync().catchError((Object e) {
          debugPrint('[SYNC_DEBUG] Server sync on pause failed: $e');
        }),
      );
    }
  }

  /// The app is going away. Flush what can be flushed inside a fixed budget,
  /// then let go of the database.
  ///
  /// The order matters and is the whole point of the split:
  ///
  ///  1. Stop the services first, so no timer, socket callback or drift
  ///     table-update listener can start new work behind the flush — or touch
  ///     the database after step 3 has closed it.
  ///  2. Export the local backlog under a hard timeout. The export is disk
  ///     work with a known end, unlike the network round-trips a full server
  ///     sync needs, so it is the only job with any chance of completing here.
  ///     If the budget runs out the changes stay pending and go out on the
  ///     next launch — exactly what happened anyway when the platform killed
  ///     the old unawaited sync mid-request.
  ///  3. Close the database, which flushes SQLite's WAL and shuts the
  ///     background isolate down cleanly instead of leaving the OS to reclaim
  ///     it.
  ///
  /// This handler cannot block the framework (onDetach is not awaited), so the
  /// budget is what keeps the tail short rather than a guarantee that it runs
  /// to completion.
  void _onAppDetached() {
    debugPrint('[SYNC_DEBUG] App detached, running bounded flush...');
    unawaited(_flushAndClose());
  }

  Future<void> _flushAndClose() async {
    _stopSyncServices();

    if (sl.isRegistered<SyncService>()) {
      try {
        await sl<SyncService>().exportNow().timeout(_detachFlushBudget);
      } catch (e) {
        debugPrint('[SYNC_DEBUG] Bounded export on detach failed: $e');
      }
    }

    if (sl.isRegistered<AppDatabase>()) {
      try {
        await sl<AppDatabase>().close();
      } catch (e) {
        debugPrint('[SYNC_DEBUG] Database close on detach failed: $e');
      }
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
          // Together, not one after the other. Neither reads anything the
          // other writes, and each one opens with the same two awaited
          // settings reads (`server_sync_enabled`, then the base URL) before it
          // does any work of its own. Run in sequence that was four round trips
          // to the settings store on the startup path with the splash screen
          // up, and the WebSocket's connection attempt could not even begin
          // until the DB listener had finished registering.
          await Future.wait([
            serverSync.initAutoSync(),
            serverSync.initWebSocket(),
          ]);
          debugPrint(
            '[APP_WRAPPER_DEBUG] Step 1b: initAutoSync + initWebSocket OK',
          );
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
      //
      // This used to read: "On Windows, compute() can crash, so we run in the
      // main isolate but without 'await' to achieve background effect." That is
      // corrected, on both halves. Not awaiting achieves no background effect
      // whatsoever - it takes the work off the *critical path*, not off the *UI
      // isolate*, and the multi-megabyte currency-history decode underneath
      // still ran here and still dropped every frame it landed in. And
      // compute() does not crash on Windows: `getCurrenciesRateToSeeder` and
      // `sync_binary_format.dart` have both been calling it on debug Windows
      // all along. The heavy decodes now go to a real worker isolate inside
      // `ImportDataUtils.getCurrenciesInitial`; the un-awaited call here is
      // still correct, but it is no longer what makes this cheap.
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
