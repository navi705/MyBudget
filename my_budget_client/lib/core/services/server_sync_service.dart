import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' hide Category;
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:drift/drift.dart' as drift_db;
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';

/// Why a connection test succeeded or failed.
///
/// A single bool made every failure look like a bad URL, so the one thing the
/// user could actually fix — a token that does not match the server's — sent
/// them editing the address instead.
enum SyncConnectionStatus {
  /// The server answered and accepted the token.
  ok,

  /// The server is running but rejected the token (HTTP 401).
  unauthorized,

  /// The server is running but has no `SYNC_TOKEN` configured, so it refuses
  /// everyone (HTTP 503). Nothing the user can do in the app fixes this.
  serverNotConfigured,

  /// Unreachable, timed out, or answered with something else entirely.
  failed,
}

/// Thrown when the server refuses the device's credentials.
///
/// Separate from a plain [Exception] because retrying changes nothing: the
/// same token will be rejected in thirty seconds and in five minutes, so the
/// callers back off instead of hammering, and the UI can say which of the two
/// fixable things is wrong instead of "sync failed".
class SyncAuthException implements Exception {
  SyncAuthException(this.status);

  /// Either [SyncConnectionStatus.unauthorized] or
  /// [SyncConnectionStatus.serverNotConfigured].
  final SyncConnectionStatus status;

  @override
  String toString() => 'SyncAuthException(${status.name})';
}

/// SharedPreferences key holding the pull cursor for the HTTP sync server.
///
/// Deliberately a different key from the `server_last_sync_timestamp` it
/// replaces. That one held a millisecond timestamp; the server now pages on a
/// sequence number it assigns itself, because a cursor made of client clocks
/// permanently skipped any row pushed with a clock below a value its peers had
/// already passed. Feeding the old epoch value (a number in the trillions) in
/// as a sequence would ask for everything after row 1.7 quadrillion and pull
/// nothing, ever. A fresh key starts at 0, which costs one full re-pull on the
/// first sync after the upgrade; every row applied on the way in is an
/// idempotent last-write-wins upsert.
const String serverPullCursorKey = 'server_pull_cursor';

/// The pre-sequence pull cursor, removed on first use of [serverPullCursorKey].
const String _legacyServerPullCursorKey = 'server_last_sync_timestamp';

class ServerSyncService {
  final AppDatabase _database;
  final SettingsRepository _settingsRepository;
  WebSocketChannel? _channel;
  StreamSubscription? _wsSubscription;
  Timer? _pingTimer;
  bool _reconnectScheduled = false;
  bool _isDisposed = false;
  bool _isConnecting = false;
  bool _isSyncingInternal = false;
  bool _autoSyncInitialized = false;

  /// Set when a sync is requested while one is already running. The running
  /// cycle re-runs instead of the request being dropped.
  bool _syncRequestedWhileBusy = false;

  /// True only while [_applyChanges] is writing rows pulled from the server.
  /// Those writes fire the same `tableUpdates` stream we listen to, so this is
  /// what distinguishes "our own echo" (ignore) from "the user edited something
  /// mid-sync" (must be synced).
  bool _isApplyingRemoteChanges = false;

  /// Upper bound on back-to-back passes inside one [sync] call.
  static const int _maxSyncPasses = 3;

  /// Consecutive failed WebSocket connection attempts, for exponential backoff.
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  Timer? _retryTimer;
  final math.Random _jitter = math.Random();

  /// Setting keys that describe THIS device and must never leave it.
  ///
  /// The settings table is keyed by `key` alone, so syncing these would make
  /// every device converge on one identity and one set of credentials:
  /// `local_device_id` is what both sync paths use to tell "my writes" from a
  /// peer's, and the `server_sync_*` / `sync_folder_path` values are per-device
  /// connection config — `server_sync_token` is a secret that has no business
  /// being uploaded to the very server it authenticates against.
  static const Set<String> _deviceLocalSettingKeys = {
    'local_device_id',
    'server_sync_enabled',
    'server_sync_url',
    'server_sync_token',
    'sync_enabled',
    'sync_folder_path',
  };

  ServerSyncService({
    required AppDatabase database,
    required SettingsRepository settingsRepository,
    http.Client? httpClient,
  }) : _database = database,
       _settingsRepository = settingsRepository,
       _http = httpClient ?? http.Client();

  /// The three calls this service makes went through the `http.get`/`http.post`
  /// top-level functions, which nothing can stand in for. Pull and push - the
  /// two paths that decide what a device keeps and what it sends - were
  /// therefore untestable without a live server on localhost. Injecting the
  /// client changes nothing in production (the default is a plain
  /// [http.Client]) and makes both paths reachable from a test.
  final http.Client _http;

  Future<String> _getBaseUrl() async {
    final setting = await _settingsRepository.getSetting('server_sync_url');
    return setting?.value ?? 'http://localhost:58080';
  }

  /// Empty when the user has not configured a token. Deliberately not a
  /// placeholder like `dev_token`: a placeholder that happens to match a
  /// server's real token would authenticate by accident, and an empty
  /// credential fails the same way a wrong one does — with a 401 the user can
  /// act on.
  Future<String> _getAuthToken() async {
    final setting = await _settingsRepository.getSetting('server_sync_token');
    return setting?.value ?? '';
  }

  /// This device's stable identity, as stored in the settings table and shared
  /// with the file-based sync path. Sent on push (`X-Device-Id`) and on the
  /// WebSocket handshake (`?device_id=`) so the server can skip ringing the
  /// doorbell back at the device that just pushed — without it the server
  /// broadcasts to everyone including the author, which triggers a pointless
  /// extra pull on every write.
  Future<String?> _getLocalDeviceId() async {
    final setting = await _settingsRepository.getSetting('local_device_id');
    final value = setting?.value;
    return (value == null || value.isEmpty) ? null : value;
  }

  Future<bool> _isEnabled() async {
    final setting = await _settingsRepository.getSetting('server_sync_enabled');
    return setting?.value == 'true';
  }

  /// Main entry point to sync data.
  /// 1. PULL changes from server
  /// 2. PUSH local changes to server
  Future<void> sync() async {
    if (!await _isEnabled()) {
      debugPrint('[ServerSync] Server sync is disabled. Skipping.');
      debugPrint(
        '[DIAG][ServerSync] server_sync_enabled=false — asset_entries will NOT sync between devices!',
      );
      return;
    }

    if (_isSyncingInternal) {
      // Do not just drop the request. A local write (or a `sync_available`
      // doorbell) that lands mid-cycle may already be past the point the
      // running cycle reads; without this flag it would sit unsynced until the
      // 5-minute fallback timer fired.
      _syncRequestedWhileBusy = true;
      debugPrint('[ServerSync] Sync in progress — queued a follow-up cycle.');
      return;
    }

    _isSyncingInternal = true;
    try {
      // Loop until nothing new arrived during the cycle. Bounded so a change
      // stream that fires on our own writes cannot spin forever.
      var passes = 0;
      do {
        _syncRequestedWhileBusy = false;
        passes++;
        debugPrint('[ServerSync] Starting sync cycle (pass $passes)...');
        await _pull();
        await _push();
        debugPrint('[ServerSync] Sync cycle completed (pass $passes).');
      } while (_syncRequestedWhileBusy && passes < _maxSyncPasses);

      if (_syncRequestedWhileBusy) {
        debugPrint(
          '[ServerSync] Still dirty after $_maxSyncPasses passes — '
          'leaving the rest to the next trigger.',
        );
      }
    } catch (e) {
      debugPrint('[ServerSync] Sync cycle error: $e');
      rethrow;
    } finally {
      _isSyncingInternal = false;
    }
  }

  /// Initialize real-time updates via WebSocket with auto-reconnect.
  /// Safe to call multiple times — skips if already connected or connecting.
  Future<void> initWebSocket() async {
    if (!await _isEnabled()) return;
    if (_channel != null || _isConnecting) {
      debugPrint(
        '[WS_CLIENT] Already connected/connecting — skipping initWebSocket()',
      );
      return;
    }
    _connectWebSocket();
  }

  Future<void> _connectWebSocket() async {
    if (_isDisposed || _isConnecting) return;
    _isConnecting = true;
    try {
      final baseUrl = await _getBaseUrl();
      // Ensure ws:// or wss:// scheme
      final wsParams = baseUrl.replaceFirst(RegExp(r'^http'), 'ws');
      final deviceId = await _getLocalDeviceId();
      // The token travels as a query parameter here, not as an Authorization
      // header: a browser's WebSocket API cannot set request headers, and the
      // web build has to reach the same endpoint as every other platform. The
      // HTTP routes still use the header — a token in an HTTP URL would be
      // written into access and proxy logs on every request.
      final authToken = await _getAuthToken();
      final query = <String>[
        if (deviceId != null) 'device_id=${Uri.encodeQueryComponent(deviceId)}',
        if (authToken.isNotEmpty)
          'token=${Uri.encodeQueryComponent(authToken)}',
      ];
      final wsUrl = query.isEmpty
          ? '$wsParams/ws/sync'
          : '$wsParams/ws/sync?${query.join('&')}';

      // Logs the endpoint, never the query string — it carries the token.
      debugPrint('[WS_CLIENT] Connecting to: $wsParams/ws/sync');

      // Cancel ping timer
      _pingTimer?.cancel();
      _pingTimer = null;

      // Cancel subscription BEFORE closing channel to prevent spurious onDone
      // (which would trigger _scheduleReconnect while we're already reconnecting)
      if (_wsSubscription != null) {
        debugPrint('[WS_CLIENT] Cancelling previous subscription...');
        await _wsSubscription?.cancel();
        _wsSubscription = null;
      }

      // Close existing channel if any
      if (_channel != null) {
        debugPrint('[WS_CLIENT] Closing previous channel...');
        await _channel?.sink.close();
        _channel = null;
        debugPrint('[WS_CLIENT] Previous channel closed');
      }

      if (_isDisposed) return;

      debugPrint('[WS_CLIENT] Creating WebSocketChannel...');
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      debugPrint('[WS_CLIENT] Channel object created (handshake pending)');

      // Ping every 30 s to keep the connection alive through idle-timeout proxies
      _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        try {
          _channel?.sink.add('ping');
        } catch (e) {
          debugPrint('[WS_CLIENT] Ping failed: $e');
        }
      });

      _wsSubscription = _channel!.stream.listen(
        (message) {
          debugPrint('[WS_CLIENT] Message received: $message');
          if (message == 'pong') return; // heartbeat reply — ignore
          if (message == 'sync_available') {
            // Fire-and-forget by design (the socket callback must not block),
            // but the error MUST be caught here: an unhandled Future error in a
            // stream callback escapes to the zone and can kill the isolate.
            unawaited(
              sync().catchError(
                (Object e) =>
                    debugPrint('[WS_CLIENT] Doorbell sync failed: $e'),
              ),
            );
          }
        },
        onDone: () {
          debugPrint('[WS_CLIENT] onDone called — connection closed');
          _wsSubscription = null;
          _pingTimer?.cancel();
          _pingTimer = null;
          _scheduleReconnect();
        },
        onError: (Object e) {
          debugPrint('[WS_CLIENT] onError: $e');
          _wsSubscription = null;
          _pingTimer?.cancel();
          _pingTimer = null;
          _scheduleReconnect();
        },
        cancelOnError: true,
      );

      // `WebSocketChannel.connect` returns a channel before the handshake has
      // happened, so registering a listener proves nothing about the server
      // being reachable. Awaiting `ready` is what makes the reset below mean
      // "we are connected" — resetting on the attempt instead pinned the
      // backoff at its first step, and an unreachable server was retried once a
      // second forever.
      await _channel!.ready;
      debugPrint('[WS_CLIENT] Stream listener registered, connection active');
      _reconnectAttempts = 0;

      // The socket was down for an unknown span, and the server only rings the
      // doorbell for changes made WHILE a client is listening. Without this
      // catch-up pull, anything that changed during the outage waited for the
      // 5-minute fallback timer.
      unawaited(
        sync().catchError(
          (Object e) => debugPrint('[WS_CLIENT] Reconnect sync failed: $e'),
        ),
      );
    } catch (e) {
      _pingTimer?.cancel();
      _pingTimer = null;
      debugPrint('[WS_CLIENT] Connection setup failed: $e. Retrying in 10s...');
      _scheduleReconnect();
    } finally {
      _isConnecting = false;
    }
  }

  /// Schedules a single reconnect attempt, ignoring duplicate calls.
  ///
  /// Backs off exponentially (1s, 2s, 4s … capped at 60s) with up to 30%
  /// jitter. The previous fixed 10s retry hammered an unreachable server
  /// forever at a constant rate, and every client reconnected in lockstep
  /// after a server restart. The delay runs on a cancellable [Timer] so
  /// [dispose] can actually stop it — `Future.delayed` could not be cancelled.
  void _scheduleReconnect() {
    if (_isDisposed || _reconnectScheduled) return;
    _reconnectScheduled = true;

    final exponent = _reconnectAttempts.clamp(0, 6); // 2^6 = 64 -> capped
    final baseSeconds = math.min(60, 1 << exponent);
    final delay = Duration(
      milliseconds:
          (baseSeconds * 1000) + _jitter.nextInt(baseSeconds * 300 + 1),
    );
    _reconnectAttempts++;

    debugPrint(
      '[WS_CLIENT] Reconnect attempt $_reconnectAttempts in '
      '${delay.inMilliseconds}ms',
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      _reconnectScheduled = false;
      _connectWebSocket();
    });
  }

  Timer? _debounceTimer;
  Timer? _periodicSyncTimer;
  StreamSubscription? _dbSubscription;

  /// Releases every background resource (socket, timers, DB listener) but
  /// leaves the instance usable.
  ///
  /// This is what callers want when server sync is switched off or the server
  /// URL changes: [dispose] used to latch `_isDisposed` permanently, which
  /// bricked the GetIt singleton — re-enabling sync afterwards could never
  /// re-establish the socket or the DB listener.
  void stop() {
    _autoSyncInitialized = false;
    _reconnectScheduled = false;
    _isConnecting = false;
    _reconnectAttempts = 0;

    _pingTimer?.cancel();
    _pingTimer = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _retryTimer?.cancel();
    _retryTimer = null;

    // Cancel subscription first to prevent onDone from firing during teardown
    _wsSubscription?.cancel();
    _wsSubscription = null;
    _channel?.sink.close();
    _channel = null;

    _dbSubscription?.cancel();
    _dbSubscription = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
  }

  /// Permanent teardown. After this the instance stays inert — use [stop] if
  /// the service must come back to life later.
  void dispose() {
    _isDisposed = true;
    stop();
  }

  /// Maps the two status codes the server uses to refuse a device, or null for
  /// anything else. 401: this device's token is wrong. 503: the server has no
  /// token configured and is refusing everyone.
  static SyncConnectionStatus? _authStatusFor(int statusCode) =>
      switch (statusCode) {
        401 => SyncConnectionStatus.unauthorized,
        503 => SyncConnectionStatus.serverNotConfigured,
        _ => null,
      };

  Future<SyncConnectionStatus> testConnection({
    String? url,
    String? token,
  }) async {
    try {
      final baseUrl = url ?? await _getBaseUrl();
      final authToken = token ?? await _getAuthToken();

      // Use the pull endpoint with limit=1 to test connectivity and authentication
      final uri = Uri.parse('$baseUrl/api/sync/pull?limit=1&last_sync=0');

      final response = await _http
          .get(uri, headers: {'Authorization': 'Bearer $authToken'})
          .timeout(const Duration(seconds: 10)); // Short timeout for testing

      switch (response.statusCode) {
        case 200:
          return SyncConnectionStatus.ok;
        case 401:
          return SyncConnectionStatus.unauthorized;
        case 503:
          return SyncConnectionStatus.serverNotConfigured;
        default:
          debugPrint(
            '[ServerSync] Test connection failed: ${response.statusCode}',
          );
          return SyncConnectionStatus.failed;
      }
    } catch (e) {
      debugPrint('[ServerSync] Test connection error: $e');
      return SyncConnectionStatus.failed;
    }
  }

  /// Initialize listeners for local database changes to trigger "Instant Push"
  /// and a periodic fallback timer.
  Future<void> initAutoSync() async {
    if (_autoSyncInitialized) {
      debugPrint('[ServerSync] Auto-sync already initialized. Skipping.');
      return;
    }
    if (!await _isEnabled()) return;
    _autoSyncInitialized = true;

    debugPrint('[ServerSync] Initializing DB Auto-Sync...');
    await _dbSubscription?.cancel();

    // Listen to all table updates
    _dbSubscription = _database.tableUpdates().listen((updates) {
      // 1. Loop protection: rows we just wrote during a pull echo back through
      // this same stream. Ignore only THOSE — the old check ignored everything
      // for the whole sync cycle, so a user edit made while a sync was running
      // was dropped and waited up to 5 minutes for the fallback timer.
      if (_isApplyingRemoteChanges) return;

      // 2. Filter: Only trigger for data tables (ignore logs/metadata if any)
      final relevantTables = {
        'transactions',
        'accounts',
        'categories',
        'settings',
        'styles',
        'currencies',
        'languages',
        'account_types',
        'asset_entries',
        'custom_data_sources',
        'sms_presets',
        'api_settings_table',
        'currency_designations',
        'exchange_rates',
        'inflation_rates',
      };

      final hasRelevantChanges = updates.any(
        (u) => relevantTables.contains(u.table),
      );

      if (hasRelevantChanges) {
        // 3. Debounce
        if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
          debugPrint(
            '[ServerSync] Auto-sync triggered by DB changes: ${updates.map((e) => e.table).join(', ')}',
          );
          try {
            await sync();
          } on SyncAuthException catch (e) {
            // No retry: the same token will be refused again in thirty
            // seconds, and again five minutes later. Retrying only buries the
            // one line that says what is actually wrong under a repeating
            // failure the user cannot distinguish from a flaky network.
            debugPrint(
              '[ServerSync] Auto-sync refused by the server (${e.status.name}). '
              'Not retrying — check the sync token in Settings.',
            );
          } catch (e) {
            debugPrint(
              '[ServerSync] Auto-sync failed: $e. Scheduling retry...',
            );
            // Simple retry mechanism: try again in 30 seconds if it failed
            // We check _isEnabled again just in case the user disabled it in the meantime
            if (await _isEnabled() && !_isDisposed) {
              // Held in a field so stop()/dispose() can cancel it — the bare
              // Timer here used to outlive teardown and fire a sync against a
              // service the app had already torn down.
              _retryTimer?.cancel();
              _retryTimer = Timer(
                const Duration(seconds: 30),
                () => unawaited(
                  sync().catchError(
                    (Object e) => debugPrint('[ServerSync] Retry failed: $e'),
                  ),
                ),
              );
            }
          }
        });
      }
    });

    // Periodic fallback timer: sync every 5 minutes regardless of DB changes or
    // WebSocket notifications, to catch any missed updates.
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      debugPrint('[ServerSync] Periodic sync triggered (5-min fallback).');
      try {
        await sync();
      } on SyncAuthException catch (e) {
        debugPrint(
          '[ServerSync] Periodic sync refused by the server '
          '(${e.status.name}). Check the sync token in Settings.',
        );
      } catch (e) {
        debugPrint('[ServerSync] Periodic sync failed: $e');
      }
    });
    debugPrint('[ServerSync] DB Auto-Sync and periodic timer initialized.');
  }

  /// How many rows this device still owes the server.
  ///
  /// Counts distinct rows in [SyncPushQueue] rather than
  /// `modified_at > server_last_push_timestamp`, which answered a different
  /// question — "how much changed since the clock last read X" — and so
  /// reported 0 for exactly the rows this class exists to stop losing: a row
  /// imported from a peer under that mark was unsent *and* uncounted, and the
  /// sync screen said everything was up to date while it was not.
  ///
  /// Distinct because a row edited five times is five queue entries but one
  /// upload; the user is being told how much work is outstanding, not how many
  /// keystrokes produced it.
  Future<int> getPendingChangesCount() async {
    final result = await _database
        .customSelect(
          'SELECT COUNT(*) AS c FROM '
          '(SELECT DISTINCT changed_table_name, record_key FROM sync_push_queue)',
        )
        .getSingle();
    return result.read<int>('c');
  }

  Future<void> _pull() async {
    final prefs = await SharedPreferences.getInstance();
    const lastSyncKey = serverPullCursorKey;
    if (prefs.containsKey(_legacyServerPullCursorKey)) {
      await prefs.remove(_legacyServerPullCursorKey);
      debugPrint(
        '[ServerSync] Dropped the pre-sequence pull cursor; this sync pulls '
        'the whole budget once and resumes incrementally afterwards.',
      );
    }

    final baseUrl = await _getBaseUrl();
    final authToken = await _getAuthToken();

    final totalPullStopwatch = Stopwatch()..start();
    int totalDownloaded = 0;

    // Hard cap on iterations — prevents infinite loop if server always returns hasMore=true
    // or if timestamp stops advancing due to data anomalies.
    const int maxIterations = 200;
    int iteration = 0;

    debugPrint('[ServerSync] Starting batched pull...');

    while (true) {
      if (iteration >= maxIterations) {
        debugPrint(
          '[ServerSync] WARNING: Max pull iterations ($maxIterations) reached. Stopping pull loop to prevent infinite loop.',
        );
        break;
      }
      iteration++;

      final batchStopwatch = Stopwatch()..start();
      final lastSync = prefs.getInt(lastSyncKey) ?? 0;
      final url = Uri.parse(
        '$baseUrl/api/sync/pull?last_sync=$lastSync&limit=20000',
      );

      debugPrint(
        '[ServerSync] Pulling batch since $lastSync (iteration $iteration)...',
      );

      final fetchStopwatch = Stopwatch()..start();
      final response = await _http
          .get(url, headers: {'Authorization': 'Bearer $authToken'})
          .timeout(const Duration(seconds: 180));
      fetchStopwatch.stop();

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final changesMap = body['changes'] as Map<String, dynamic>;
        final serverTimestamp = (body['server_timestamp'] as num).toInt();
        // has_more: server signals that at least one table hit the query limit
        final hasMore = body['has_more'] as bool? ?? false;

        // Check if we received any real changes
        bool hasChanges = false;
        changesMap.forEach((key, value) {
          if (value is List && value.isNotEmpty) {
            hasChanges = true;
            totalDownloaded += value.length;
          }
        });

        if (!hasChanges) {
          debugPrint('[ServerSync] No more changes from server.');
          break;
        }

        debugPrint(
          '[ServerSync] Applying batch with ${changesMap.length} tables (high mark: $serverTimestamp, hasMore: $hasMore)...',
        );

        final applyStopwatch = Stopwatch()..start();
        await _applyChanges(changesMap);
        applyStopwatch.stop();

        await prefs.setInt(lastSyncKey, serverTimestamp);

        debugPrint(
          '[PERF] Pull Batch: Fetch ${fetchStopwatch.elapsedMilliseconds}ms, DB Apply ${applyStopwatch.elapsedMilliseconds}ms, Total ${batchStopwatch.elapsedMilliseconds}ms',
        );

        // Primary infinite-loop guard: stop if the cursor did not advance.
        // With a server-assigned sequence it should always advance while rows
        // are coming back, so a stall here means the server sent a page it
        // will send again — looping on it would spin forever.
        if (serverTimestamp <= lastSync) {
          debugPrint(
            '[ServerSync] WARNING: Server cursor did not advance. Stopping pull loop.',
          );
          break;
        }

        // Secondary stop: server explicitly says no more data
        if (!hasMore) break;
      } else if (_authStatusFor(response.statusCode) != null) {
        // Body deliberately not logged: on 401 it is the server telling us the
        // credentials are wrong, and there is nothing in it worth printing next
        // to a token.
        throw SyncAuthException(_authStatusFor(response.statusCode)!);
      } else {
        debugPrint('[ServerSync] Pull failed body: ${response.body}');
        throw Exception('Pull failed: ${response.statusCode} ${response.body}');
      }
    }
    totalPullStopwatch.stop();
    debugPrint(
      '[PERF] Total Pull: ${totalPullStopwatch.elapsedMilliseconds}ms ($totalDownloaded items, $iteration iterations)',
    );
  }

  Future<void> _push() async {
    final totalPushStopwatch = Stopwatch()..start();

    // Freeze the queue this push is responsible for. A change made WHILE the
    // push runs is queued with a higher id than this ceiling, so it is neither
    // uploaded from a half-read page nor — and this is the one that used to
    // lose data — deleted by the acknowledgement of the version that preceded
    // it. It simply goes out with the next push.
    final ceiling = await _pushQueueCeiling();

    debugPrint('[ServerSync] Starting queued push up to entry $ceiling...');

    try {
      await _pushQueuedTable(
        'languages',
        'languages',
        _database.languages,
        (l) => {
          'languageCode': l.languageCode,
          'language': l.language,
          'modifiedAt': l.modifiedAt,
          'deviceId': l.deviceId,
        },
        ceiling,
      );

      await _pushQueuedTable(
        'currencies',
        'currencies',
        _database.currencies,
        (c) => {
          'code': c.code,
          'name': c.name,
          'languageCode': c.languageCode,
          'type': c.type.index,
          'modifiedAt': c.modifiedAt,
          'deviceId': c.deviceId,
        },
        ceiling,
      );

      await _pushQueuedTable(
        'settings',
        'settings',
        _database.settings,
        _settingToJson,
        ceiling,
        // The entries for these are still drained, only their rows are never
        // uploaded: a filter that skipped the entries too would leave them in
        // the queue forever, re-read on every push and counted as a backlog
        // that no amount of syncing could clear.
        rowFilter:
            'key NOT IN (${_deviceLocalSettingKeys.map((k) => "'$k'").join(', ')})',
      );

      await _pushQueuedTable(
        'api_settings_table',
        'api_settings',
        _database.apiSettingsTable,
        _apiSettingsToJson,
        ceiling,
      );

      await _pushQueuedTable(
        'styles',
        'styles',
        _database.styles,
        _styleToJson,
        ceiling,
      );

      await _pushQueuedTable(
        'custom_themes',
        'custom_themes',
        _database.customThemes,
        _customThemeToJson,
        ceiling,
      );

      await _pushQueuedTable(
        'account_types',
        'account_types',
        _database.accountTypes,
        _accountTypeToJson,
        ceiling,
      );

      await _pushQueuedTable(
        'currency_designations',
        'currency_designations',
        _database.currencyDesignations,
        _currencyDesignationToJson,
        ceiling,
      );

      await _pushQueuedTable(
        'categories',
        'categories',
        _database.categories,
        _categoryToJson,
        ceiling,
      );

      await _pushQueuedTable(
        'exchange_rates',
        'exchange_rates',
        _database.exchangeRates,
        _exchangeRateToJson,
        ceiling,
      );

      await _pushQueuedTable(
        'inflation_rates',
        'inflation_rates',
        _database.inflationRates,
        _inflationRateToJson,
        ceiling,
      );

      await _pushQueuedTable(
        'custom_data_sources',
        'custom_data_sources',
        _database.customDataSources,
        _customDataSourceToJson,
        ceiling,
      );

      await _pushQueuedTable(
        'sms_presets',
        'sms_presets',
        _database.smsPresets,
        _smsPresetToJson,
        ceiling,
      );

      // Dependent Tables
      await _pushQueuedTable(
        'accounts',
        'accounts',
        _database.accounts,
        _accountToJson,
        ceiling,
      );

      await _pushQueuedTable(
        'asset_entries',
        'asset_entries',
        _database.assetEntries,
        _assetEntryToJson,
        ceiling,
      );

      await _pushQueuedTable(
        'transactions',
        'transactions',
        _database.transactions,
        _transactionToJson,
        ceiling,
      );

      // No watermark is written. `server_last_push_timestamp` is gone from
      // every read path in this class: what has been sent is now recorded per
      // row, by the absence of a queue entry, which is the only record a clock
      // could never keep.
      totalPushStopwatch.stop();
      debugPrint(
        '[PERF] Total Push: ${totalPushStopwatch.elapsedMilliseconds}ms',
      );
    } catch (e) {
      // Nothing to roll back: entries are deleted one acknowledged batch at a
      // time, so everything the server never confirmed is still queued and the
      // tables after the failing one have not been touched at all.
      debugPrint('[ServerSync] Error during queued push: $e');
      rethrow;
    }
  }

  /// The highest queue entry that exists right now, or 0 for an empty queue.
  Future<int> _pushQueueCeiling() async {
    final row = await _database
        .customSelect('SELECT COALESCE(MAX(id), 0) AS c FROM sync_push_queue')
        .getSingle();
    return row.read<int>('c');
  }

  /// Uploads every row [tableName] has queued up to [ceiling] and drains those
  /// entries — and only those — once the server has answered 200.
  ///
  /// [payloadKey] is what the server calls the table, which is not always what
  /// SQLite calls it. [rowFilter] is extra SQL restricting which of the queued
  /// rows may leave the device.
  Future<void> _pushQueuedTable<D>(
    String tableName,
    String payloadKey,
    drift_db.ResultSetImplementation<dynamic, D> table,
    Map<String, dynamic> Function(D record) toJson,
    int ceiling, {
    String? rowFilter,
  }) async {
    if (ceiling <= 0) return;

    const int batchSize = 20000;
    // SQLite refuses a statement with more than 999 bound variables, and the
    // keys of one batch are bound one per placeholder.
    const int keyChunk = 500;

    final baseUrl = await _getBaseUrl();
    final url = Uri.parse('$baseUrl/api/sync/push');
    final authToken = await _getAuthToken();
    final deviceId = await _getLocalDeviceId();
    final keyExpression = syncPushQueueKeyExpression(tableName);

    while (true) {
      final batchStopwatch = Stopwatch()..start();

      final dbFetchStopwatch = Stopwatch()..start();
      final entries = await _database
          .customSelect(
            'SELECT id, record_key FROM sync_push_queue '
            'WHERE changed_table_name = ? AND id <= ? '
            'ORDER BY id LIMIT $batchSize',
            variables: [
              drift_db.Variable.withString(tableName),
              drift_db.Variable.withInt(ceiling),
            ],
          )
          .get();

      if (entries.isEmpty) break;

      final entryIds = entries.map((e) => e.read<int>('id')).toList();
      // One row can be queued several times over — every edit adds an entry, and
      // the file engine's imports add their own. The server only needs the row
      // as it stands now.
      final keys = <String>{
        for (final e in entries) e.read<String>('record_key'),
      }.toList();

      final records = <D>[];
      for (var i = 0; i < keys.length; i += keyChunk) {
        final chunk = keys.sublist(i, math.min(i + keyChunk, keys.length));
        final placeholders = List.filled(chunk.length, '?').join(', ');
        final rows = await _database
            .customSelect(
              'SELECT * FROM $tableName '
              'WHERE $keyExpression IN ($placeholders)'
              '${rowFilter == null ? '' : ' AND ($rowFilter)'}',
              variables: [
                for (final key in chunk) drift_db.Variable.withString(key),
              ],
            )
            .get();
        for (final row in rows) {
          records.add(await table.map(row.data));
        }
      }
      dbFetchStopwatch.stop();

      final jsonStopwatch = Stopwatch()..start();
      final payload = {payloadKey: records.map(toJson).toList()};
      jsonStopwatch.stop();

      // An entry whose row is gone (hard-deleted, or filtered out above) has
      // nothing to send but must still leave the queue, or the push re-reads
      // the same dead page on every sync and never reaches the live entries
      // behind it.
      if (records.isNotEmpty) {
        debugPrint(
          '[ServerSync] Table $tableName: sending ${records.length} rows '
          'for ${entries.length} queued changes...',
        );

        final uploadStopwatch = Stopwatch()..start();
        final response = await _http
            .post(
              url,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $authToken',
                if (deviceId != null) 'X-Device-Id': deviceId,
              },
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 180));
        uploadStopwatch.stop();

        if (response.statusCode != 200) {
          // Deliberately no drain: the entries stay exactly as they are, so a
          // push that never got an answer is retried in full rather than being
          // written off as sent.
          if (_authStatusFor(response.statusCode) != null) {
            throw SyncAuthException(_authStatusFor(response.statusCode)!);
          }
          throw Exception(
            'Push for $tableName failed: ${response.statusCode} ${response.body}',
          );
        }

        debugPrint(
          '[PERF] Push Batch ($tableName): DB ${dbFetchStopwatch.elapsedMilliseconds}ms, JSON ${jsonStopwatch.elapsedMilliseconds}ms, Network ${uploadStopwatch.elapsedMilliseconds}ms, Total ${batchStopwatch.elapsedMilliseconds}ms',
        );
      }

      await _drainPushQueue(entryIds);
    }
  }

  /// Removes exactly [entryIds] from the queue.
  ///
  /// By id, never by table or timestamp: an edit made to the same row while the
  /// batch was uploading has its own, higher id, and a broader delete would
  /// throw that edit away as if the server had been told about it.
  Future<void> _drainPushQueue(List<int> entryIds) async {
    const int chunk = 500;
    for (var i = 0; i < entryIds.length; i += chunk) {
      final ids = entryIds.sublist(i, math.min(i + chunk, entryIds.length));
      await _database.customStatement(
        'DELETE FROM sync_push_queue WHERE id IN (${ids.join(', ')})',
      );
    }
  }

  /// Tables applied on pull, PARENTS FIRST — accounts before asset_entries and
  /// transactions, currencies/styles/categories before accounts. Order matters
  /// even with FK checks off, because the last writer of a row wins and a child
  /// written before its parent would otherwise reference a stale parent row.
  late final List<
    ({String key, Future<void> Function(Map<String, dynamic>) upsert})
  >
  _pullTableOrder = [
    (key: 'languages', upsert: _upsertLanguage),
    (key: 'currencies', upsert: _upsertCurrency),
    (key: 'settings', upsert: _upsertSetting),
    (key: 'api_settings', upsert: _upsertApiSetting),
    (key: 'styles', upsert: _upsertStyle),
    (key: 'custom_themes', upsert: _upsertCustomTheme),
    (key: 'account_types', upsert: _upsertAccountType),
    (key: 'currency_designations', upsert: _upsertCurrencyDesignation),
    (key: 'categories', upsert: _upsertCategory),
    (key: 'exchange_rates', upsert: _upsertExchangeRate),
    (key: 'inflation_rates', upsert: _upsertInflationRate),
    (key: 'custom_data_sources', upsert: _upsertCustomDataSource),
    (key: 'sms_presets', upsert: _upsertSmsPreset),
    // Dependent tables
    (key: 'accounts', upsert: _upsertAccount),
    (key: 'asset_entries', upsert: _upsertAssetEntry),
    (key: 'transactions', upsert: _upsertTransaction),
  ];

  /// Applies one pulled batch as a SINGLE all-or-nothing transaction.
  ///
  /// This used to open one transaction per table. Because the caller advances
  /// the pull watermark right after this returns, a crash or a failed upsert
  /// between two tables left the earlier tables committed and the later ones
  /// lost — and the watermark either moved past them anyway or replayed rows
  /// that were already in. One transaction means a failed batch changes
  /// nothing and is simply re-pulled from the same watermark.
  Future<void> _applyChanges(Map<String, dynamic> changes) async {
    // FK enforcement is toggled OUTSIDE the transaction on purpose: SQLite
    // silently ignores `PRAGMA foreign_keys` while a transaction is open.
    // It has to be off because a batch can legitimately carry a child row
    // whose parent arrives in a later batch.
    await _database.customStatement('PRAGMA foreign_keys = OFF');
    _isApplyingRemoteChanges = true;
    try {
      debugPrint('[ServerSync] Entering database transaction for pull...');
      await _database.transaction(() async {
        // An incoming transaction can move to another account, and the account
        // it is leaving has to be rebuilt too — nothing in the batch mentions
        // it, so its id has to be read before the move overwrites it.
        final touchedAccounts = <String>{
          ...await _accountIdsOfTransactions(changes),
        };
        final anchorlessAccounts = <String>{};

        for (final table in _pullTableOrder) {
          final list = changes[table.key] as List?;
          if (list == null || list.isEmpty) continue;
          debugPrint('[ServerSync] Applying ${list.length} ${table.key}...');
          for (final row in list) {
            final json = row as Map<String, dynamic>;
            await table.upsert(json);
            if (table.key == 'accounts') {
              final id = json['id'] as String?;
              if (id != null && id.isNotEmpty) {
                touchedAccounts.add(id);
                if (json['openingBalance'] == null) {
                  anchorlessAccounts.add(id);
                }
              }
            } else if (table.key == 'transactions') {
              final accountId = json['accountId'] as String?;
              if (accountId != null && accountId.isNotEmpty) {
                touchedAccounts.add(accountId);
              }
            }
          }
        }

        await _database.accountsDao.anchorOpeningBalances(anchorlessAccounts);
        // The stored balance that came down the wire is deliberately thrown
        // away in favour of one rebuilt here. Balances merge as scalars while
        // transactions merge as a set, so accepting the pulled number leaves
        // whichever device pushed last dictating a balance that the merged set
        // of transactions does not add up to, for good. Rebuilding costs a
        // balance that can lag by one unconverted transaction; that resolves
        // itself, a balance nobody can reconcile does not.
        await _database.accountsDao.recomputeBalances(touchedAccounts);
      });
      debugPrint('[ServerSync] Pull committed successfully.');
    } finally {
      // Drift dispatches the table-update events on commit, so by the time the
      // transaction future resolves the echo has already been delivered and
      // classified. Safe to clear here.
      _isApplyingRemoteChanges = false;
      await _database.customStatement('PRAGMA foreign_keys = ON');
    }
  }

  /// The accounts the pulled transactions belong to *locally*, read before the
  /// batch is applied. Anything that changes account here would otherwise leave
  /// the account it left behind holding a balance that still counts it.
  Future<Set<String>> _accountIdsOfTransactions(
    Map<String, dynamic> changes,
  ) async {
    final list = changes['transactions'] as List?;
    if (list == null || list.isEmpty) return {};

    final ids = <String>[
      for (final row in list)
        if ((row as Map<String, dynamic>)['id'] case final String id
            when id.isNotEmpty)
          id,
    ];

    final accountIds = <String>{};
    for (var start = 0; start < ids.length; start += 500) {
      final chunk = ids.sublist(
        start,
        start + 500 > ids.length ? ids.length : start + 500,
      );
      final rows = await _database
          .customSelect(
            'SELECT DISTINCT account_id FROM transactions '
            'WHERE id IN (${List.filled(chunk.length, '?').join(', ')})',
            variables: [
              for (final id in chunk) drift_db.Variable.withString(id),
            ],
          )
          .get();
      for (final row in rows) {
        accountIds.add(row.read<String>('account_id'));
      }
    }
    return accountIds;
  }

  // Helpers to gather data (needs DB access)
  // REMOVED: _gatherLocalChanges is no longer used by the batched push process.
  // We now fetch per table directly in _push.

  // --- Serialization Helpers ---

  Map<String, dynamic> _styleToJson(Style e) => {
    'id': e.id,
    'name': e.name,
    'colorHex': e.colorHex,
    'iconName': e.iconName,
    'iconType': e.iconType.index,
    'modifiedAt': e.modifiedAt,
    'deviceId': e.deviceId,
    'isDeleted': e.isDeleted,
  };

  Map<String, dynamic> _accountTypeToJson(AccountType e) => {
    'id': e.id,
    'name': e.name,
    'languageCode': e.languageCode,
    'modifiedAt': e.modifiedAt,
    'deviceId': e.deviceId,
    'isDeleted': e.isDeleted,
  };

  Map<String, dynamic> _currencyDesignationToJson(CurrencyDesignation e) => {
    'id': e.id,
    'value': e.value,
    'currencyCode': e.currencyCode,
    'modifiedAt': e.modifiedAt,
    'deviceId': e.deviceId,
    'isDeleted': e.isDeleted,
  };

  Map<String, dynamic> _categoryToJson(Category entry) => {
    'id': entry.id,
    'name': entry.name,
    'parentId': entry.parentId,
    'styleId': entry.styleId,
    'type': entry.type.index,
    'modifiedAt': entry.modifiedAt,
    'deviceId': entry.deviceId,
    'isDeleted': entry.isDeleted,
  };

  Map<String, dynamic> _accountToJson(DbAccount e) => {
    'id': e.id,
    'name': e.name,
    'description': e.description,
    'balance': _round(e.balance),
    // Exact minor units for fiat accounts. NULL for crypto/commodity, where the
    // double above is the source of truth. Never _round()ed and never coerced
    // to 0 — a 0 here would mean "this account holds nothing".
    'balanceMinor': e.balanceMinor,
    // The anchor the receiver rebuilds the balance from. Unlike the balance it
    // only moves when the user edits the account, so the last writer of these
    // two really is the last person who changed them.
    'openingBalance': _round(e.openingBalance),
    'openingBalanceMinor': e.openingBalanceMinor,
    'currencyCode': e.currencyCode,
    'currencyDesignationId': e.currencyDesignationId,
    'styleId': e.styleId,
    'accountTypeId': e.accountTypeId,
    'creationDate': e.creationDate.toIso8601String(),
    'country': e.country,
    'assetId': e.assetId,
    'assetQuantity': _round(e.assetQuantity),
    'feeStructure': e.feeStructure,
    'modifiedAt': e.modifiedAt,
    'deviceId': e.deviceId,
    'isDeleted': e.isDeleted,
  };

  Map<String, dynamic> _transactionToJson(Transaction entry) => {
    'id': entry.id,
    'description': entry.description,
    'amount': _round(entry.amount),
    // See _accountToJson: exact minor units for fiat, NULL for crypto.
    'amountMinor': entry.amountMinor,
    'date': entry.date.toIso8601String(),
    'accountId': entry.accountId,
    'categoryId': entry.categoryId,
    'currencyCode': entry.currencyCode,
    'exchangeRate': entry.exchangeRate,
    'exchangeRatePreset': entry.exchangeRatePreset,
    'fee': _round(entry.fee),
    'feeMinor': entry.feeMinor,
    'linkedTransactionId': entry.linkedTransactionId,
    'modifiedAt': entry.modifiedAt,
    'deviceId': entry.deviceId,
    'isDeleted': entry.isDeleted,
  };

  Map<String, dynamic> _assetEntryToJson(AssetEntry e) => {
    'id': e.id,
    'assetId': e.assetId,
    'name': e.name,
    'date': e.date.toIso8601String(),
    'value': _round(e.value),
    'quantity': _round(e.quantity),
    'assetType': e.assetType,
    'description': e.description,
    'currencyCode': e.currencyCode,
    'accountId': e.accountId,
    'source': e.source,
    'preset': e.preset,
    'modifiedAt': e.modifiedAt,
    'deviceId': e.deviceId,
    'sourceId': e.sourceId,
    'isDeleted': e.isDeleted,
  };

  Map<String, dynamic> _customDataSourceToJson(CustomDataSource e) => {
    'id': e.id,
    'name': e.name,
    'url': e.url,
    'dataType': e.dataType,
    'enabled': e.enabled,
    'autoFetch': e.autoFetch,
    'lastFetchAt': e.lastFetchAt,
    'modifiedAt': e.modifiedAt,
    'deviceId': e.deviceId,
    'isDeleted': e.isDeleted,
  };

  Map<String, dynamic> _apiSettingsToJson(ApiSettingsTableData e) => {
    'id': e.id,
    'enabled': e.enabled,
    'autoFetch': e.autoFetch,
    'lastFetchAt': e.lastFetchAt,
    'modifiedAt': e.modifiedAt,
    'deviceId': e.deviceId,
    // Without this the delete never left the device: the row was pushed as a
    // live one, and the provider the user removed kept coming back from the
    // server on every other device.
    'isDeleted': e.isDeleted,
  };

  Map<String, dynamic> _smsPresetToJson(SmsPreset e) => {
    'id': e.id,
    'name': e.name,
    'senderFilter': e.senderFilter,
    'isBuiltIn': e.isBuiltIn,
    'isEnabled': e.isEnabled,
    'defaultAccountId': e.defaultAccountId,
    'defaultCategoryId': e.defaultCategoryId,
    'rulesJson': e.rulesJson,
    'modifiedAt': e.modifiedAt,
    'deviceId': e.deviceId,
    'isDeleted': e.isDeleted,
  };

  Map<String, dynamic> _settingToJson(Setting e) => {
    'key': e.key,
    'value': e.value,
    'device': e.device,
    'modifiedAt': e.modifiedAt,
    'deviceId': e.deviceId,
  };

  Map<String, dynamic> _exchangeRateToJson(ExchangeRate e) => {
    'fromCurrencyCode': e.fromCurrencyCode,
    'toCurrencyCode': e.toCurrencyCode,
    'rate': _round(e.rate),
    'preset': e.preset,
    'date': e.date.toIso8601String(),
    'modifiedAt': e.modifiedAt,
    'deviceId': e.deviceId,
    'sourceId': e.sourceId,
  };

  Map<String, dynamic> _inflationRateToJson(InflationRate e) => {
    'date': e.date.toIso8601String(),
    'percent': e.percent,
    'country': e.country,
    'preset': e.preset,
    'modifiedAt': e.modifiedAt,
    'deviceId': e.deviceId,
    'sourceId': e.sourceId,
  };

  Map<String, dynamic> _customThemeToJson(DbCustomTheme e) => {
    'id': e.id,
    'name': e.name,
    'primaryColorHex': e.primaryColorHex,
    'secondaryColorHex': e.secondaryColorHex,
    'surfaceColorHex': e.surfaceColorHex,
    'backgroundColorHex': e.backgroundColorHex,
    'backgroundImagePath': e.backgroundImagePath,
    'backgroundImageOpacity': e.backgroundImageOpacity,
    'backgroundImageBlur': e.backgroundImageBlur,
    'windowEffectType': e.windowEffectType,
    'effectOpacity': e.effectOpacity,
    'surfaceOpacity': e.surfaceOpacity,
    'themeMode': e.themeMode,
    'isPreset': e.isPreset,
    'isActive': e.isActive,
    'modifiedAt': e.modifiedAt,
    'deviceId': e.deviceId,
    'isDeleted': e.isDeleted,
  };

  // ---------------------------------------------------------------------------
  // _upsert* methods — optimised: no pre-SELECT, single SQL statement with
  // ON CONFLICT DO UPDATE SET ... WHERE EXCLUDED.modified_at > table.modified_at
  // This eliminates the N+1 SELECT+INSERT pattern (was 2×N DB ops, now N ops).
  // ---------------------------------------------------------------------------

  Future<void> _upsertLanguage(Map<String, dynamic> json) async {
    await _database.customInsert(
      '''INSERT INTO languages (language_code, language, modified_at, device_id)
      VALUES (?, ?, ?, ?)
      ON CONFLICT (language_code) DO UPDATE SET
        language = EXCLUDED.language,
        modified_at = EXCLUDED.modified_at,
        device_id = EXCLUDED.device_id
      WHERE EXCLUDED.modified_at > languages.modified_at''',
      variables: [
        drift_db.Variable.withString(json['languageCode'] as String? ?? 'en'),
        drift_db.Variable.withString(json['language'] as String? ?? 'English'),
        drift_db.Variable.withInt(json['modifiedAt'] as int? ?? 1),
        drift_db.Variable(json['deviceId'] as String?),
      ],
    );
  }

  Future<void> _upsertCurrency(Map<String, dynamic> json) async {
    await _database.customInsert(
      '''INSERT INTO currencies (code, name, language_code, type, modified_at, device_id)
      VALUES (?, ?, ?, ?, ?, ?)
      ON CONFLICT (code) DO UPDATE SET
        name = EXCLUDED.name,
        language_code = EXCLUDED.language_code,
        type = EXCLUDED.type,
        modified_at = EXCLUDED.modified_at,
        device_id = EXCLUDED.device_id
      WHERE EXCLUDED.modified_at > currencies.modified_at''',
      variables: [
        drift_db.Variable.withString(json['code'] as String? ?? 'USD'),
        drift_db.Variable.withString(json['name'] as String? ?? 'US Dollar'),
        drift_db.Variable.withString(json['languageCode'] as String? ?? 'en'),
        drift_db.Variable.withInt(json['type'] as int? ?? 0),
        drift_db.Variable.withInt(json['modifiedAt'] as int? ?? 1),
        drift_db.Variable(json['deviceId'] as String?),
      ],
    );
  }

  Future<void> _upsertStyle(Map<String, dynamic> json) async {
    await _database.customInsert(
      '''INSERT INTO styles (id, name, color_hex, icon_name, icon_type, modified_at, device_id, is_deleted)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        color_hex = EXCLUDED.color_hex,
        icon_name = EXCLUDED.icon_name,
        icon_type = EXCLUDED.icon_type,
        modified_at = EXCLUDED.modified_at,
        device_id = EXCLUDED.device_id,
        is_deleted = EXCLUDED.is_deleted
      WHERE EXCLUDED.modified_at > styles.modified_at''',
      variables: [
        drift_db.Variable.withString(json['id'] as String? ?? ''),
        drift_db.Variable.withString(json['name'] as String? ?? ''),
        drift_db.Variable.withString(json['colorHex'] as String? ?? ''),
        drift_db.Variable.withString(json['iconName'] as String? ?? ''),
        drift_db.Variable.withInt(json['iconType'] as int? ?? 0),
        drift_db.Variable.withInt(json['modifiedAt'] as int? ?? 1),
        drift_db.Variable(json['deviceId'] as String?),
        drift_db.Variable.withInt(_parseBool(json['isDeleted']) ? 1 : 0),
      ],
    );
  }

  Future<void> _upsertAccountType(Map<String, dynamic> json) async {
    await _database.customInsert(
      '''INSERT INTO account_types (id, name, language_code, modified_at, device_id, is_deleted)
      VALUES (?, ?, ?, ?, ?, ?)
      ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        language_code = EXCLUDED.language_code,
        modified_at = EXCLUDED.modified_at,
        device_id = EXCLUDED.device_id,
        is_deleted = EXCLUDED.is_deleted
      WHERE EXCLUDED.modified_at > account_types.modified_at''',
      variables: [
        drift_db.Variable.withString(json['id'] as String? ?? ''),
        drift_db.Variable.withString(json['name'] as String? ?? ''),
        drift_db.Variable.withString(json['languageCode'] as String? ?? 'en'),
        drift_db.Variable.withInt(json['modifiedAt'] as int? ?? 1),
        drift_db.Variable(json['deviceId'] as String?),
        drift_db.Variable.withInt(_parseBool(json['isDeleted']) ? 1 : 0),
      ],
    );
  }

  Future<void> _upsertCurrencyDesignation(Map<String, dynamic> json) async {
    await _database.customInsert(
      '''INSERT INTO currency_designations (id, value, currency_code, modified_at, device_id, is_deleted)
      VALUES (?, ?, ?, ?, ?, ?)
      ON CONFLICT (id) DO UPDATE SET
        value = EXCLUDED.value,
        currency_code = EXCLUDED.currency_code,
        modified_at = EXCLUDED.modified_at,
        device_id = EXCLUDED.device_id,
        is_deleted = EXCLUDED.is_deleted
      WHERE EXCLUDED.modified_at > currency_designations.modified_at''',
      variables: [
        drift_db.Variable.withString(json['id'] as String? ?? ''),
        drift_db.Variable.withString(json['value'] as String? ?? ''),
        drift_db.Variable.withString(json['currencyCode'] as String? ?? 'USD'),
        drift_db.Variable.withInt(json['modifiedAt'] as int? ?? 1),
        drift_db.Variable(json['deviceId'] as String?),
        drift_db.Variable.withInt(_parseBool(json['isDeleted']) ? 1 : 0),
      ],
    );
  }

  Future<void> _upsertCategory(Map<String, dynamic> json) async {
    await _database.customInsert(
      '''INSERT INTO categories (id, name, parent_id, style_id, type, modified_at, device_id, is_deleted)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        parent_id = EXCLUDED.parent_id,
        style_id = EXCLUDED.style_id,
        type = EXCLUDED.type,
        modified_at = EXCLUDED.modified_at,
        device_id = EXCLUDED.device_id,
        is_deleted = EXCLUDED.is_deleted
      WHERE EXCLUDED.modified_at > categories.modified_at''',
      variables: [
        drift_db.Variable.withString(json['id'] as String? ?? ''),
        drift_db.Variable.withString(json['name'] as String? ?? ''),
        drift_db.Variable(json['parentId'] as String?),
        drift_db.Variable(json['styleId'] as String?),
        drift_db.Variable.withInt(json['type'] as int? ?? 0),
        drift_db.Variable.withInt(json['modifiedAt'] as int? ?? 1),
        drift_db.Variable(json['deviceId'] as String?),
        drift_db.Variable.withInt(_parseBool(json['isDeleted']) ? 1 : 0),
      ],
    );
  }

  Future<void> _upsertAccount(Map<String, dynamic> json) async {
    final currencyCode = json['currencyCode'] as String?;
    final currencyDesignationId = json['currencyDesignationId'] as String?;
    // Fallback values are embedded in VALUES(...) so ON CONFLICT UPDATE can
    // safely use EXCLUDED.* — the correct value is already in EXCLUDED.
    final resolvedCurrencyCode =
        (currencyCode != null && currencyCode.isNotEmpty)
        ? currencyCode
        : 'USD';
    final resolvedCurrencyDesignationId =
        (currencyDesignationId != null && currencyDesignationId.isNotEmpty)
        ? currencyDesignationId
        : '';

    final balance = _round((json['balance'] as num?)?.toDouble() ?? 0.0);
    final balanceMinor = (json['balanceMinor'] as num?)?.toInt();
    // A sender that predates the anchor sends the balance and nothing else, so
    // the balance stands in for the anchor here and _applyChanges re-derives
    // the real anchor once the batch's transactions are in. Defaulting to zero
    // instead would hand such an account a balance made of its transactions
    // alone, with the money it opened with quietly gone.
    final openingBalance = (json['openingBalance'] as num?)?.toDouble();
    final openingBalanceMinor = (json['openingBalanceMinor'] as num?)?.toInt();

    await _database.customInsert(
      '''INSERT INTO accounts (id, name, description, balance, balance_minor, opening_balance, opening_balance_minor, currency_code, currency_designation_id, style_id, account_type_id, creation_date, country, asset_id, asset_quantity, fee_structure, modified_at, device_id, is_deleted)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        description = EXCLUDED.description,
        balance = EXCLUDED.balance,
        balance_minor = EXCLUDED.balance_minor,
        opening_balance = EXCLUDED.opening_balance,
        opening_balance_minor = EXCLUDED.opening_balance_minor,
        currency_code = EXCLUDED.currency_code,
        currency_designation_id = EXCLUDED.currency_designation_id,
        style_id = EXCLUDED.style_id,
        account_type_id = EXCLUDED.account_type_id,
        creation_date = EXCLUDED.creation_date,
        country = EXCLUDED.country,
        asset_id = EXCLUDED.asset_id,
        asset_quantity = EXCLUDED.asset_quantity,
        fee_structure = EXCLUDED.fee_structure,
        modified_at = EXCLUDED.modified_at,
        device_id = EXCLUDED.device_id,
        is_deleted = EXCLUDED.is_deleted
      WHERE EXCLUDED.modified_at > accounts.modified_at''',
      variables: [
        drift_db.Variable.withString(json['id'] as String? ?? ''),
        drift_db.Variable.withString(
          json['name'] as String? ?? 'Untitled Account',
        ),
        drift_db.Variable(json['description'] as String?),
        drift_db.Variable.withReal(balance),
        // Nullable on purpose: NULL means "not a fiat account, use the double".
        // A peer or server that predates this column simply sends nothing.
        drift_db.Variable(balanceMinor),
        drift_db.Variable.withReal(openingBalance ?? balance),
        drift_db.Variable(
          openingBalance == null ? balanceMinor : openingBalanceMinor,
        ),
        drift_db.Variable.withString(resolvedCurrencyCode),
        drift_db.Variable.withString(resolvedCurrencyDesignationId),
        drift_db.Variable(json['styleId'] as String?),
        drift_db.Variable.withString(
          json['accountTypeId'] as String? ?? 'account_type_checking',
        ),
        drift_db.Variable.withDateTime(
          DateTime.tryParse(json['creationDate'] as String? ?? '') ??
              DateTime.now(),
        ),
        drift_db.Variable(json['country'] as String?),
        drift_db.Variable(json['assetId'] as String?),
        drift_db.Variable.withReal(
          _round((json['assetQuantity'] as num?)?.toDouble() ?? 0.0),
        ),
        drift_db.Variable(json['feeStructure'] as String?),
        drift_db.Variable.withInt(json['modifiedAt'] as int? ?? 1),
        drift_db.Variable(json['deviceId'] as String?),
        drift_db.Variable.withInt(_parseBool(json['isDeleted']) ? 1 : 0),
      ],
    );
  }

  Future<void> _upsertTransaction(Map<String, dynamic> json) async {
    final currencyCode = json['currencyCode'] as String?;
    final resolvedCurrencyCode =
        (currencyCode != null && currencyCode.isNotEmpty)
        ? currencyCode
        : 'USD';

    await _database.customInsert(
      '''INSERT INTO transactions (id, description, amount, amount_minor, date, account_id, category_id, currency_code, exchange_rate, exchange_rate_preset, fee, fee_minor, linked_transaction_id, modified_at, device_id, is_deleted)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT (id) DO UPDATE SET
        description = EXCLUDED.description,
        amount = EXCLUDED.amount,
        amount_minor = EXCLUDED.amount_minor,
        date = EXCLUDED.date,
        account_id = EXCLUDED.account_id,
        category_id = EXCLUDED.category_id,
        currency_code = EXCLUDED.currency_code,
        exchange_rate = EXCLUDED.exchange_rate,
        exchange_rate_preset = EXCLUDED.exchange_rate_preset,
        fee = EXCLUDED.fee,
        fee_minor = EXCLUDED.fee_minor,
        linked_transaction_id = EXCLUDED.linked_transaction_id,
        modified_at = EXCLUDED.modified_at,
        device_id = EXCLUDED.device_id,
        is_deleted = EXCLUDED.is_deleted
      WHERE EXCLUDED.modified_at > transactions.modified_at''',
      variables: [
        drift_db.Variable.withString(json['id'] as String? ?? ''),
        drift_db.Variable.withString(json['description'] as String? ?? ''),
        drift_db.Variable.withReal(
          _round((json['amount'] as num?)?.toDouble() ?? 0.0),
        ),
        drift_db.Variable((json['amountMinor'] as num?)?.toInt()),
        drift_db.Variable.withDateTime(
          DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        ),
        drift_db.Variable.withString(json['accountId'] as String? ?? ''),
        drift_db.Variable.withString(json['categoryId'] as String? ?? ''),
        drift_db.Variable.withString(resolvedCurrencyCode),
        drift_db.Variable.withReal(
          (json['exchangeRate'] as num?)?.toDouble() ?? 1.0,
        ),
        drift_db.Variable(json['exchangeRatePreset'] as int?),
        drift_db.Variable.withReal(
          _round((json['fee'] as num?)?.toDouble() ?? 0.0),
        ),
        drift_db.Variable((json['feeMinor'] as num?)?.toInt()),
        drift_db.Variable(json['linkedTransactionId'] as String?),
        drift_db.Variable.withInt(json['modifiedAt'] as int? ?? 1),
        drift_db.Variable(json['deviceId'] as String?),
        drift_db.Variable.withInt(_parseBool(json['isDeleted']) ? 1 : 0),
      ],
    );
  }

  Future<void> _upsertAssetEntry(Map<String, dynamic> json) async {
    final source = json['source'] as String? ?? 'manual';
    final id = json['id'] as String? ?? '';
    final date =
        DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now();

    // For custom_api entries: remove any existing row with a different ID but
    // the same (asset_id, date) — these are pre-fix duplicates that would
    // violate the partial UNIQUE INDEX added in schema v7.
    if (source == 'custom_api' && id.isNotEmpty) {
      final assetId = json['assetId'] as String? ?? '';
      await _database.customUpdate(
        'DELETE FROM asset_entries '
        'WHERE source = ? AND asset_id = ? AND date = ? AND id != ?',
        variables: [
          drift_db.Variable.withString(source),
          drift_db.Variable.withString(assetId),
          drift_db.Variable.withDateTime(date),
          drift_db.Variable.withString(id),
        ],
        updates: {_database.assetEntries},
        updateKind: drift_db.UpdateKind.delete,
      );
    }

    await _database.customInsert(
      '''INSERT INTO asset_entries (id, asset_id, name, date, value, quantity, asset_type, description, currency_code, account_id, source, preset, modified_at, device_id, source_id, is_deleted)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT (id) DO UPDATE SET
        asset_id = EXCLUDED.asset_id,
        name = EXCLUDED.name,
        date = EXCLUDED.date,
        value = EXCLUDED.value,
        quantity = EXCLUDED.quantity,
        asset_type = EXCLUDED.asset_type,
        description = EXCLUDED.description,
        currency_code = EXCLUDED.currency_code,
        account_id = EXCLUDED.account_id,
        source = EXCLUDED.source,
        preset = EXCLUDED.preset,
        modified_at = EXCLUDED.modified_at,
        device_id = EXCLUDED.device_id,
        source_id = EXCLUDED.source_id,
        is_deleted = EXCLUDED.is_deleted
      WHERE EXCLUDED.modified_at > asset_entries.modified_at''',
      variables: [
        drift_db.Variable.withString(id),
        drift_db.Variable.withString(json['assetId'] as String? ?? ''),
        drift_db.Variable.withString(json['name'] as String? ?? ''),
        drift_db.Variable.withDateTime(date),
        drift_db.Variable.withReal(
          _round((json['value'] as num?)?.toDouble() ?? 0.0),
        ),
        drift_db.Variable.withReal(
          _round((json['quantity'] as num?)?.toDouble() ?? 1.0),
        ),
        drift_db.Variable(json['assetType'] as String?),
        drift_db.Variable(json['description'] as String?),
        drift_db.Variable.withString(json['currencyCode'] as String? ?? 'USD'),
        drift_db.Variable(json['accountId'] as String?),
        drift_db.Variable.withString(source),
        drift_db.Variable.withInt(json['preset'] as int? ?? 1),
        drift_db.Variable.withInt(json['modifiedAt'] as int? ?? 1),
        drift_db.Variable(json['deviceId'] as String?),
        drift_db.Variable(json['sourceId'] as String?),
        drift_db.Variable.withInt(_parseBool(json['isDeleted']) ? 1 : 0),
      ],
    );
  }

  Future<void> _upsertCustomDataSource(Map<String, dynamic> json) async {
    await _database.customInsert(
      '''INSERT INTO custom_data_sources (id, name, url, data_type, enabled, auto_fetch, last_fetch_at, modified_at, device_id, is_deleted)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        url = EXCLUDED.url,
        data_type = EXCLUDED.data_type,
        enabled = EXCLUDED.enabled,
        auto_fetch = EXCLUDED.auto_fetch,
        last_fetch_at = EXCLUDED.last_fetch_at,
        modified_at = EXCLUDED.modified_at,
        device_id = EXCLUDED.device_id,
        is_deleted = EXCLUDED.is_deleted
      WHERE EXCLUDED.modified_at > custom_data_sources.modified_at''',
      variables: [
        drift_db.Variable.withString(json['id'] as String? ?? ''),
        drift_db.Variable.withString(json['name'] as String? ?? ''),
        drift_db.Variable.withString(json['url'] as String? ?? ''),
        drift_db.Variable.withInt(json['dataType'] as int? ?? 0),
        drift_db.Variable.withInt(_parseBool(json['enabled']) ? 1 : 0),
        drift_db.Variable.withInt(_parseBool(json['autoFetch']) ? 1 : 0),
        drift_db.Variable(json['lastFetchAt'] as int?),
        drift_db.Variable.withInt(json['modifiedAt'] as int? ?? 1),
        drift_db.Variable(json['deviceId'] as String?),
        drift_db.Variable.withInt(_parseBool(json['isDeleted']) ? 1 : 0),
      ],
    );
  }

  Future<void> _upsertApiSetting(Map<String, dynamic> json) async {
    await _database.customInsert(
      '''INSERT INTO api_settings_table (id, enabled, auto_fetch, last_fetch_at, modified_at, device_id, is_deleted)
      VALUES (?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT (id) DO UPDATE SET
        enabled = EXCLUDED.enabled,
        auto_fetch = EXCLUDED.auto_fetch,
        last_fetch_at = EXCLUDED.last_fetch_at,
        modified_at = EXCLUDED.modified_at,
        device_id = EXCLUDED.device_id,
        is_deleted = EXCLUDED.is_deleted
      WHERE EXCLUDED.modified_at > api_settings_table.modified_at''',
      variables: [
        drift_db.Variable.withString(json['id'] as String? ?? ''),
        drift_db.Variable.withInt(_parseBool(json['enabled']) ? 1 : 0),
        drift_db.Variable.withInt(_parseBool(json['autoFetch']) ? 1 : 0),
        drift_db.Variable(json['lastFetchAt'] as int?),
        drift_db.Variable.withInt(json['modifiedAt'] as int? ?? 1),
        drift_db.Variable(json['deviceId'] as String?),
        // A peer on a pre-v12 build sends no flag; the only thing it can mean
        // is "live", since that build had no way to delete one.
        drift_db.Variable.withInt(_parseBool(json['isDeleted']) ? 1 : 0),
      ],
    );
  }

  Future<void> _upsertSmsPreset(Map<String, dynamic> json) async {
    await _database.customInsert(
      '''INSERT INTO sms_presets (id, name, sender_filter, is_built_in, is_enabled, default_account_id, default_category_id, rules_json, modified_at, device_id, is_deleted)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        sender_filter = EXCLUDED.sender_filter,
        is_built_in = EXCLUDED.is_built_in,
        is_enabled = EXCLUDED.is_enabled,
        default_account_id = EXCLUDED.default_account_id,
        default_category_id = EXCLUDED.default_category_id,
        rules_json = EXCLUDED.rules_json,
        modified_at = EXCLUDED.modified_at,
        device_id = EXCLUDED.device_id,
        is_deleted = EXCLUDED.is_deleted
      WHERE EXCLUDED.modified_at > sms_presets.modified_at''',
      variables: [
        drift_db.Variable.withString(json['id'] as String? ?? ''),
        drift_db.Variable.withString(
          json['name'] as String? ?? 'Untitled SMS Preset',
        ),
        drift_db.Variable.withString(json['senderFilter'] as String? ?? ''),
        drift_db.Variable.withInt(_parseBool(json['isBuiltIn']) ? 1 : 0),
        drift_db.Variable.withInt(_parseBool(json['isEnabled']) ? 1 : 0),
        drift_db.Variable(json['defaultAccountId'] as String?),
        drift_db.Variable(json['defaultCategoryId'] as String?),
        drift_db.Variable.withString(json['rulesJson'] as String? ?? '[]'),
        drift_db.Variable.withInt(json['modifiedAt'] as int? ?? 1),
        drift_db.Variable(json['deviceId'] as String?),
        drift_db.Variable.withInt(_parseBool(json['isDeleted']) ? 1 : 0),
      ],
    );
  }

  Future<void> _upsertSetting(Map<String, dynamic> json) async {
    final key = json['key'] as String? ?? '';
    // Defence in depth: even if a peer (or an older build) uploaded its own
    // device-local settings, never let them overwrite ours. Accepting
    // `local_device_id` here would give both devices the same identity and
    // break the "skip my own packets" check in the file-based sync.
    if (_deviceLocalSettingKeys.contains(key)) {
      debugPrint('[ServerSync] Ignoring device-local setting from peer: $key');
      return;
    }

    await _database.customInsert(
      '''INSERT INTO settings (key, value, device, modified_at, device_id)
      VALUES (?, ?, ?, ?, ?)
      ON CONFLICT (key) DO UPDATE SET
        value = EXCLUDED.value,
        device = EXCLUDED.device,
        modified_at = EXCLUDED.modified_at,
        device_id = EXCLUDED.device_id
      WHERE EXCLUDED.modified_at > settings.modified_at''',
      variables: [
        drift_db.Variable.withString(json['key'] as String? ?? ''),
        drift_db.Variable.withString(json['value'] as String? ?? ''),
        drift_db.Variable(json['device'] as String?),
        drift_db.Variable.withInt(json['modifiedAt'] as int? ?? 1),
        drift_db.Variable(json['deviceId'] as String?),
      ],
    );
  }

  Future<void> _upsertExchangeRate(Map<String, dynamic> json) async {
    final date =
        DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now();

    await _database.customInsert(
      '''INSERT INTO exchange_rates (from_currency_code, to_currency_code, rate, preset, date, modified_at, device_id, source_id)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT (from_currency_code, to_currency_code, date, preset) DO UPDATE SET
        rate = EXCLUDED.rate,
        modified_at = EXCLUDED.modified_at,
        device_id = EXCLUDED.device_id,
        source_id = EXCLUDED.source_id
      WHERE EXCLUDED.modified_at > exchange_rates.modified_at''',
      variables: [
        drift_db.Variable.withString(
          json['fromCurrencyCode'] as String? ?? 'USD',
        ),
        drift_db.Variable.withString(
          json['toCurrencyCode'] as String? ?? 'EUR',
        ),
        drift_db.Variable.withReal(
          _round((json['rate'] as num?)?.toDouble() ?? 1.0),
        ),
        drift_db.Variable.withInt(json['preset'] as int? ?? 1),
        drift_db.Variable.withDateTime(date),
        drift_db.Variable.withInt(json['modifiedAt'] as int? ?? 1),
        drift_db.Variable(json['deviceId'] as String?),
        drift_db.Variable(json['sourceId'] as String?),
      ],
    );
  }

  Future<void> _upsertInflationRate(Map<String, dynamic> json) async {
    final date =
        DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now();
    // `country` is part of the primary key and NOT NULL as of schema v10, where
    // the worldwide series is spelled with the `globalInflationCountry`
    // sentinel. A peer still on v9, or a server row written by one, sends null
    // for it - binding that straight in would fail the constraint and abort the
    // whole pull.
    final rawCountry = json['country'] as String?;
    final country = (rawCountry == null || rawCountry.isEmpty)
        ? globalInflationCountry
        : rawCountry;

    await _database.customInsert(
      '''INSERT INTO inflation_rates (date, percent, country, preset, modified_at, device_id, source_id)
      VALUES (?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT (date, country, preset) DO UPDATE SET
        percent = EXCLUDED.percent,
        modified_at = EXCLUDED.modified_at,
        device_id = EXCLUDED.device_id,
        source_id = EXCLUDED.source_id
      WHERE EXCLUDED.modified_at > inflation_rates.modified_at''',
      variables: [
        drift_db.Variable.withDateTime(date),
        drift_db.Variable.withReal(
          (json['percent'] as num?)?.toDouble() ?? 0.0,
        ),
        drift_db.Variable(country),
        drift_db.Variable.withInt(json['preset'] as int? ?? 1),
        drift_db.Variable.withInt(json['modifiedAt'] as int? ?? 1),
        drift_db.Variable(json['deviceId'] as String?),
        drift_db.Variable(json['sourceId'] as String?),
      ],
    );
  }

  Future<void> _upsertCustomTheme(Map<String, dynamic> json) async {
    await _database.customInsert(
      '''INSERT INTO custom_themes (id, name, primary_color_hex, secondary_color_hex, surface_color_hex, background_color_hex, background_image_path, background_image_opacity, background_image_blur, window_effect_type, effect_opacity, surface_opacity, theme_mode, is_preset, is_active, modified_at, device_id, is_deleted)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        primary_color_hex = EXCLUDED.primary_color_hex,
        secondary_color_hex = EXCLUDED.secondary_color_hex,
        surface_color_hex = EXCLUDED.surface_color_hex,
        background_color_hex = EXCLUDED.background_color_hex,
        background_image_path = EXCLUDED.background_image_path,
        background_image_opacity = EXCLUDED.background_image_opacity,
        background_image_blur = EXCLUDED.background_image_blur,
        window_effect_type = EXCLUDED.window_effect_type,
        effect_opacity = EXCLUDED.effect_opacity,
        surface_opacity = EXCLUDED.surface_opacity,
        theme_mode = EXCLUDED.theme_mode,
        is_preset = EXCLUDED.is_preset,
        is_active = EXCLUDED.is_active,
        modified_at = EXCLUDED.modified_at,
        device_id = EXCLUDED.device_id,
        is_deleted = EXCLUDED.is_deleted
      WHERE EXCLUDED.modified_at > custom_themes.modified_at''',
      variables: [
        drift_db.Variable.withString(json['id'] as String? ?? ''),
        drift_db.Variable.withString(json['name'] as String? ?? 'Custom Theme'),
        drift_db.Variable.withString(json['primaryColorHex'] as String? ?? ''),
        drift_db.Variable.withString(
          json['secondaryColorHex'] as String? ?? '',
        ),
        drift_db.Variable.withString(json['surfaceColorHex'] as String? ?? ''),
        drift_db.Variable.withString(
          json['backgroundColorHex'] as String? ?? '',
        ),
        drift_db.Variable(json['backgroundImagePath'] as String?),
        drift_db.Variable.withReal(
          (json['backgroundImageOpacity'] as num?)?.toDouble() ?? 1.0,
        ),
        drift_db.Variable.withReal(
          (json['backgroundImageBlur'] as num?)?.toDouble() ?? 0.0,
        ),
        drift_db.Variable.withInt(json['windowEffectType'] as int? ?? 0),
        drift_db.Variable.withReal(
          (json['effectOpacity'] as num?)?.toDouble() ?? 1.0,
        ),
        drift_db.Variable.withReal(
          (json['surfaceOpacity'] as num?)?.toDouble() ?? 1.0,
        ),
        drift_db.Variable.withInt(json['themeMode'] as int? ?? 0),
        drift_db.Variable.withInt(_parseBool(json['isPreset']) ? 1 : 0),
        drift_db.Variable.withInt(_parseBool(json['isActive']) ? 1 : 0),
        drift_db.Variable.withInt(json['modifiedAt'] as int? ?? 1),
        drift_db.Variable(json['deviceId'] as String?),
        drift_db.Variable.withInt(_parseBool(json['isDeleted']) ? 1 : 0),
      ],
    );
  }

  bool _parseBool(dynamic val) {
    if (val is bool) return val;
    if (val is int) return val == 1;
    return false;
  }

  /// Helper to round double values to 8 decimal places to avoid floating point errors
  double _round(double value) {
    return double.parse(value.toStringAsFixed(8));
  }
}
