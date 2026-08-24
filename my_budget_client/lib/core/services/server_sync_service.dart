import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' hide Category;
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:drift/drift.dart' as drift_db;
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/sync/device_local_settings.dart';
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

  /// No server address is configured on this device, so there was nothing to
  /// contact. Distinct from [failed]: nothing is broken and nothing should be
  /// retried — the user simply has not filled the field in yet.
  notConfigured,
}

/// [url] as an absolute `http`/`https` origin with no trailing slash, or `null`
/// when it cannot be one.
///
/// Everything the sync service builds is `'$baseUrl/api/...'` string
/// concatenation, which means a base URL that is blank, scheme-less
/// (`my-server.example`) or host-less silently produces a relative URI instead
/// of an error. Rejecting it once, here, is what lets the callers tell "not
/// configured" apart from "the server is down".
String? normalizeSyncBaseUrl(String url) {
  var trimmed = url.trim();
  if (trimmed.isEmpty) return null;

  final uri = Uri.tryParse(trimmed);
  if (uri == null) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  if (uri.host.isEmpty) return null;

  // A trailing slash would make every path a double slash — `https://host//api`
  // is a different route on most proxies, including nginx.
  while (trimmed.endsWith('/')) {
    trimmed = trimmed.substring(0, trimmed.length - 1);
  }
  return trimmed;
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

/// Which server the value under [serverPullCursorKey] was counted by.
///
/// The cursor is a sequence number the server hands out, so it only means
/// anything to the server that issued it. Point a device at a different one -
/// a self-hosted instance, a restored backup, a development server, a moved
/// deployment - and the number carries over into a sequence that has never
/// reached it. The device then asks for everything after row N of a log that
/// is on row 3, is told there is nothing, and reports a successful sync
/// forever while pulling not one row. It keeps pushing, so the mismatch is
/// invisible from that device: it can see its own writes arrive.
const String serverPullCursorOriginKey = 'server_pull_cursor_origin';

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

  /// How many [_applyChanges] calls are in flight, not whether one is.
  ///
  /// A plain bool was cleared by whichever apply finished first, so a second,
  /// overlapping apply went on writing pulled rows with the flag already
  /// false: its own echo reached the `tableUpdates` listener below and was
  /// classified as a user edit, and the `PRAGMA foreign_keys = ON` that came
  /// with the early clear could land before the second apply had opened its
  /// transaction — which then rejected a legitimately parentless child row.
  int _remoteApplyDepth = 0;

  /// True only while [_applyChanges] is writing rows pulled from the server.
  /// Those writes fire the same `tableUpdates` stream we listen to, so this is
  /// what distinguishes "our own echo" (ignore) from "the user edited something
  /// mid-sync" (must be synced).
  bool get _isApplyingRemoteChanges => _remoteApplyDepth > 0;

  /// Upper bound on back-to-back passes inside one [sync] call.
  static const int _maxSyncPasses = 3;

  /// Consecutive failed WebSocket connection attempts, for exponential backoff.
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  Timer? _retryTimer;

  /// Runs [_connectionStabilityWindow] after a handshake completes and is what
  /// actually resets [_reconnectAttempts]. See [_connectionStabilityWindow].
  Timer? _connectionStabilityTimer;
  final math.Random _jitter = math.Random();

  /// Exposed so a test can watch the backoff grow — the delays are a pure
  /// function of this counter, and the bug it pins is the counter being reset
  /// by a handshake that did not last.
  @visibleForTesting
  int get reconnectAttempts => _reconnectAttempts;

  /// Setting keys that describe THIS device and must never leave it.
  ///
  /// Kept as an alias so this file reads the same as it did, while the list
  /// itself lives where both sync engines can share it.
  static const Set<String> _deviceLocalSettingKeys = kDeviceLocalSettingKeys;

  /// [channelFactory], [reconnectBaseDelay] and [connectionStabilityWindow]
  /// exist for tests only: the reconnect policy is otherwise reachable only
  /// through a real server that accepts an upgrade and then drops it, and
  /// waiting out the production 1s/2s/4s ladder in a test would cost seconds.
  /// The defaults are exactly the production values.
  ServerSyncService({
    required AppDatabase database,
    required SettingsRepository settingsRepository,
    http.Client? httpClient,
    WebSocketChannel Function(Uri url)? channelFactory,
    Duration reconnectBaseDelay = const Duration(seconds: 1),
    Duration connectionStabilityWindow = const Duration(seconds: 30),
  }) : _database = database,
       _settingsRepository = settingsRepository,
       _http = httpClient ?? http.Client(),
       _connectChannel = channelFactory ?? WebSocketChannel.connect,
       _reconnectBaseDelay = reconnectBaseDelay,
       _connectionStabilityWindow = connectionStabilityWindow;

  /// How the socket is dialled. Production hands in nothing and gets
  /// [WebSocketChannel.connect].
  final WebSocketChannel Function(Uri url) _connectChannel;

  /// First step of the reconnect ladder; every later step doubles it, capped
  /// at [_reconnectMaxDelay].
  final Duration _reconnectBaseDelay;

  /// How long a connection has to survive before it counts as "connected" for
  /// the purpose of resetting the backoff.
  ///
  /// The handshake completing proves only that the server accepted the
  /// upgrade. A server in a restart loop, or a proxy that drops the socket the
  /// moment it is established, satisfied `await ready` and reset the ladder to
  /// its first step every time — so it was redialled roughly once a second,
  /// forever, each redial dragging a full catch-up sync behind it. The ladder
  /// may only be reset by a connection that actually lasted.
  final Duration _connectionStabilityWindow;

  /// Ceiling on the reconnect ladder.
  static const Duration _reconnectMaxDelay = Duration(seconds: 60);

  /// The three calls this service makes went through the `http.get`/`http.post`
  /// top-level functions, which nothing can stand in for. Pull and push - the
  /// two paths that decide what a device keeps and what it sends - were
  /// therefore untestable without a live server on localhost. Injecting the
  /// client changes nothing in production (the default is a plain
  /// [http.Client]) and makes both paths reachable from a test.
  final http.Client _http;

  /// The server this device syncs with, or `null` when none is configured.
  ///
  /// A blank value is what the settings screen stores when the user leaves the
  /// field empty, and a blank base URL does not fail loudly — it builds
  /// *relative* URIs. `Uri.parse('/api/sync/pull?...')` has no host, so every
  /// HTTP request threw `No host specified in URI`, and every socket dial threw
  /// `only ws: and wss: schemes are supported`; the reconnect ladder treated
  /// both as a transient outage and retried them for the whole session. Not
  /// configured is a *state*, not a failure, so it is `null` here and every
  /// caller declines to sync instead of retrying.
  Future<String?> _getBaseUrl() async {
    final setting = await _settingsRepository.getSetting('server_sync_url');
    final raw = setting?.value;
    // No row at all means nothing was ever configured on this device: keep the
    // local dev default, which is what a fresh debug build has always used.
    if (raw == null) return 'http://localhost:58080';
    return normalizeSyncBaseUrl(raw);
  }

  /// [_getBaseUrl] for the transfer paths, which are only ever entered from
  /// [sync] and so run behind its "is a server configured?" check.
  ///
  /// If that check is ever removed this throws instead of quietly building a
  /// relative URI — the failure mode that made an unconfigured device retry
  /// forever in the first place.
  Future<String> _requireBaseUrl() async {
    final baseUrl = await _getBaseUrl();
    if (baseUrl == null) {
      throw StateError(
        'Server sync has no server URL configured. Set one in Settings › Sync.',
      );
    }
    return baseUrl;
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
    // Latched SYNCHRONOUSLY, before the first await, and that ordering is the
    // whole point: reading `server_sync_enabled` is a real database round trip,
    // and the guard used to sit behind it. Startup's `sync()` and the socket's
    // `sync()` both suspended on that read, both woke to find the guard clear,
    // and two complete cycles ran side by side — the same page pulled and
    // applied twice, the same queue read and uploaded twice, and one cycle's
    // `PRAGMA foreign_keys = ON` restored while the other was still writing.
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
      if (!await _isEnabled()) {
        debugPrint('[ServerSync] Server sync is disabled. Skipping.');
        debugPrint(
          '[DIAG][ServerSync] server_sync_enabled=false — asset_entries will NOT sync between devices!',
        );
        // Nothing in the app calls stop() when the user switches server sync
        // off, and nothing on the background paths re-reads the setting, so the
        // socket, the reconnect ladder, the 5-minute timer and the DB listener
        // all kept running for the rest of the session — against a server the
        // user had disconnected from. The service notices here, on the first
        // trigger after the switch, and shuts its own machinery down.
        stop();
        await _collapsePushQueue();
        return;
      }

      // Enabled but with no address to send anything to. Every request built
      // from a blank base URL is relative and throws, and the failure path
      // schedules a 30-second retry — so this used to fail forever, loudly, for
      // a user who had only forgotten to type the server in.
      if (await _getBaseUrl() == null) {
        debugPrint(
          '[ServerSync] Server sync is on but no server URL is configured. '
          'Skipping — set one in Settings › Sync.',
        );
        stop();
        return;
      }

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
    if (await _getBaseUrl() == null) {
      debugPrint(
        '[WS_CLIENT] Server sync is on but no server URL is configured — '
        'not starting the socket.',
      );
      return;
    }
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
      // Re-read on every dial, not just on the public entry point: a reconnect
      // scheduled before the user switched server sync off would otherwise
      // re-establish a token-authenticated socket to a server the app is no
      // longer supposed to be talking to, and keep re-establishing it.
      if (!await _isEnabled()) {
        debugPrint(
          '[WS_CLIENT] Server sync was switched off — tearing down instead '
          'of dialling.',
        );
        stop();
        return;
      }

      final baseUrl = await _getBaseUrl();
      if (baseUrl == null) {
        debugPrint(
          '[WS_CLIENT] No server URL configured — not dialling. '
          '(Set one in Settings › Sync.)',
        );
        // Deliberately NOT _scheduleReconnect(): there is nothing to reconnect
        // to. The old code fell through, built `ws:` from an empty string and
        // let WebSocketChannel throw, which the ladder read as an outage and
        // retried 33 times in a single session.
        stop();
        return;
      }
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
      _channel = _connectChannel(Uri.parse(wsUrl));
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
          _connectionStabilityTimer?.cancel();
          _connectionStabilityTimer = null;
          _scheduleReconnect();
        },
        onError: (Object e) {
          debugPrint('[WS_CLIENT] onError: $e');
          _wsSubscription = null;
          _pingTimer?.cancel();
          _pingTimer = null;
          _connectionStabilityTimer?.cancel();
          _connectionStabilityTimer = null;
          _scheduleReconnect();
        },
        cancelOnError: true,
      );

      // `WebSocketChannel.connect` returns a channel before the handshake has
      // happened, so registering a listener proves nothing about the server
      // being reachable — hence the await. But the handshake completing does
      // not prove the connection is usable either: a connection that lives
      // 20 ms satisfies `ready` just as well as one that lives an hour, and
      // resetting the ladder here pinned it at its first step forever. The
      // reset is armed instead, and only a connection that survives
      // [_connectionStabilityWindow] gets to fire it — onDone and onError
      // cancel it above.
      await _channel!.ready;
      debugPrint('[WS_CLIENT] Stream listener registered, connection active');

      // The socket can die between the listener registering and `ready`
      // completing, and by then onDone has already cancelled the subscription
      // and scheduled the reconnect. Arming the stability timer anyway would
      // hand a reset to a connection that never held, which is the exact bug
      // the timer exists to fix.
      if (_isDisposed || _wsSubscription == null) return;

      _connectionStabilityTimer?.cancel();
      _connectionStabilityTimer = Timer(_connectionStabilityWindow, () {
        debugPrint('[WS_CLIENT] Connection held — reconnect backoff reset.');
        _reconnectAttempts = 0;
      });

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
      _connectionStabilityTimer?.cancel();
      _connectionStabilityTimer = null;
      debugPrint('[WS_CLIENT] Connection setup failed: $e. Backing off...');
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
    final baseMs = math.min(
      _reconnectMaxDelay.inMilliseconds,
      _reconnectBaseDelay.inMilliseconds * (1 << exponent),
    );
    final delay = Duration(
      milliseconds: baseMs + _jitter.nextInt((baseMs * 3 ~/ 10) + 1),
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
  ///
  /// Nothing outside this class calls it, and it cannot be wired into the
  /// settings screen (presentation is out of scope), so [sync] and
  /// [_connectWebSocket] call it themselves the moment they read
  /// `server_sync_enabled` as false. Re-enabling works because [initWebSocket]
  /// and [initAutoSync] are idempotent and `_autoSyncInitialized` is cleared
  /// here.
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
    _connectionStabilityTimer?.cancel();
    _connectionStabilityTimer = null;

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
      // The screen passes the field's live text, which is exactly the value a
      // user is most likely to have left blank or typed without a scheme.
      final baseUrl = url != null
          ? normalizeSyncBaseUrl(url)
          : await _getBaseUrl();
      if (baseUrl == null) {
        debugPrint('[ServerSync] Test connection skipped: no server URL.');
        return SyncConnectionStatus.notConfigured;
      }
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
    if (await _getBaseUrl() == null) {
      debugPrint(
        '[ServerSync] No server URL configured — not starting auto-sync. '
        'Every write would queue a push to nowhere.',
      );
      return;
    }
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
            if (await _isEnabled() &&
                await _getBaseUrl() != null &&
                !_isDisposed) {
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

  /// Drops the pull cursor when it was not counted by the server about to be
  /// asked.
  ///
  /// See [serverPullCursorOriginKey] for what carrying it over does. The cost
  /// of dropping it wrongly is one full re-pull, and every row that arrives is
  /// an idempotent last-write-wins upsert, so a device that did not need the
  /// reset ends up exactly where it started. The cost of not dropping it is a
  /// device that silently never receives another change.
  ///
  /// A cursor with no recorded origin is treated as belonging to someone else
  /// for that reason: on the sync after this ships, every existing device pays
  /// the one re-pull once and is protected from then on. Assuming the cursor
  /// belongs to whatever server is configured now would leave exactly the
  /// devices this exists for - the ones that already moved - broken forever,
  /// which is the failure that cannot be recovered from.
  Future<void> _resetPullCursorIfServerChanged(
    SharedPreferences prefs,
    String baseUrl,
  ) async {
    if (prefs.getString(serverPullCursorOriginKey) == baseUrl) return;

    final carried = prefs.getInt(serverPullCursorKey) ?? 0;
    if (carried != 0) {
      debugPrint(
        '[ServerSync] Pull cursor $carried was not counted by $baseUrl. '
        'Starting from 0; this sync pulls the whole budget once.',
      );
    }
    await prefs.setInt(serverPullCursorKey, 0);
    await prefs.setString(serverPullCursorOriginKey, baseUrl);
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

    final baseUrl = await _requireBaseUrl();
    await _resetPullCursorIfServerChanged(prefs, baseUrl);
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

  /// Collapses `sync_push_queue` to one entry per row.
  ///
  /// The triggers fire on every write to the sixteen synced tables whether or
  /// not server sync is switched on, and [_drainPushQueue] — the only code
  /// that removes an entry — is reachable only through [_push]. With the
  /// feature off, an install therefore accumulated one row per write for its
  /// entire life: the daily rate fetch alone rewrites the same few hundred
  /// rates every day, and `getPendingChangesCount` scans the lot.
  ///
  /// Collapsing rather than deleting, because deleting is not correct: a row
  /// written while the feature was off still has to reach the server the day
  /// the user switches it on, and nothing else remembers that it is owed. The
  /// push already reduces a row's entries to a single upload of its current
  /// state ([_pushQueuedTable] de-duplicates by `record_key`), so keeping only
  /// the newest entry per row loses nothing at all and bounds the table by the
  /// number of rows that exist instead of by the number of edits ever made.
  Future<void> _collapsePushQueue() async {
    await _database.customStatement(
      'DELETE FROM sync_push_queue WHERE id NOT IN ('
      'SELECT MAX(id) FROM sync_push_queue '
      'GROUP BY changed_table_name, record_key)',
    );
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

    final baseUrl = await _requireBaseUrl();
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
  ///
  /// Each entry takes the table's WHOLE list of rows, not one row: the applier
  /// batches a page into a handful of multi-row statements rather than issuing
  /// one per row. See [_upsertBatch].
  late final List<
    ({String key, Future<void> Function(List<Map<String, dynamic>>) upsert})
  >
  _pullTableOrder = [
    (key: 'languages', upsert: _upsertLanguages),
    (key: 'currencies', upsert: _upsertCurrencies),
    (key: 'settings', upsert: _upsertSettings),
    (key: 'api_settings', upsert: _upsertApiSettings),
    (key: 'styles', upsert: _upsertStyles),
    (key: 'custom_themes', upsert: _upsertCustomThemes),
    (key: 'account_types', upsert: _upsertAccountTypes),
    (key: 'currency_designations', upsert: _upsertCurrencyDesignations),
    (key: 'categories', upsert: _upsertCategories),
    (key: 'exchange_rates', upsert: _upsertExchangeRates),
    (key: 'inflation_rates', upsert: _upsertInflationRates),
    (key: 'custom_data_sources', upsert: _upsertCustomDataSources),
    (key: 'sms_presets', upsert: _upsertSmsPresets),
    // Dependent tables
    (key: 'accounts', upsert: _upsertAccounts),
    (key: 'asset_entries', upsert: _upsertAssetEntries),
    (key: 'transactions', upsert: _upsertTransactions),
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
    // whose parent arrives in a later batch. Both the pragma and the flag are
    // balanced on the depth counter, so an outer apply that finishes first
    // cannot restore enforcement under an inner one that is still writing.
    if (_remoteApplyDepth == 0) {
      await _database.customStatement('PRAGMA foreign_keys = OFF');
    }
    _remoteApplyDepth++;
    try {
      debugPrint('[ServerSync] Entering database transaction for pull...');
      await _database.transaction(() async {
        // Everything the push-queue triggers add above this mark was made by
        // this transaction's own upserts. Drift serialises writes, so no other
        // writer can slip an entry in between — and an edit the user made
        // moments earlier is below the mark and survives untouched. See the
        // matching DELETE at the end of the transaction.
        final queueMark = await _pushQueueCeiling();

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
          // Cast up front rather than row by row inside the writer: a page
          // carrying something that is not an object fails here, before the
          // first statement of that table runs, and the transaction takes the
          // whole page down with it.
          final rows = <Map<String, dynamic>>[
            for (final row in list) row as Map<String, dynamic>,
          ];
          debugPrint('[ServerSync] Applying ${rows.length} ${table.key}...');
          await table.upsert(rows);
          if (table.key == 'accounts') {
            for (final json in rows) {
              final id = json['id'] as String?;
              if (id != null && id.isNotEmpty) {
                touchedAccounts.add(id);
                if (json['openingBalance'] == null) {
                  anchorlessAccounts.add(id);
                }
              }
            }
          } else if (table.key == 'transactions') {
            for (final json in rows) {
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

        // The last statement of the transaction, and the other half of the
        // mark read at the top. Every upsert above tripped the push-queue
        // triggers, so without this the device uploads the page it has just
        // downloaded straight back to the server it came from — 20 000 rows of
        // JSON that the server's own last-write-wins guard then discards row
        // for row, a doorbell rung at every other device for nothing, and a
        // phantom backlog in getPendingChangesCount if the echo push fails.
        // Scoped to the server-pull path deliberately: the peer-to-peer
        // importer writes through its own path and must keep queueing, because
        // what a peer sent us is exactly what the server has not heard about.
        await _database.customStatement(
          'DELETE FROM sync_push_queue WHERE id > ?',
          [queueMark],
        );
      });
      debugPrint('[ServerSync] Pull committed successfully.');
    } finally {
      // Drift dispatches the table-update events on commit, so by the time the
      // transaction future resolves the echo has already been delivered and
      // classified. Safe to unwind here.
      _remoteApplyDepth--;
      if (_remoteApplyDepth == 0) {
        await _database.customStatement('PRAGMA foreign_keys = ON');
      }
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
    // Optional on the wire: a server or peer that predates the review queue
    // neither sends nor stores it, and the reader below defaults it to false.
    'needsReview': entry.needsReview,
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
  // ON CONFLICT DO UPDATE SET ... WHERE <_lastWriteWins(table)>.
  // This eliminates the N+1 SELECT+INSERT pattern (was 2×N DB ops, now N ops).
  // ---------------------------------------------------------------------------

  /// The conflict guard, spelled exactly as the server spells it in
  /// `my_budget_server/lib/data/sync_repository.dart`.
  ///
  /// Both ends have to evaluate the same rule or the same pair of writes
  /// resolves differently on each side and the devices diverge in silence.
  /// Two parts to it beyond a bare `>`:
  ///
  /// * COALESCE, because a row whose `modified_at` is NULL (written by a build
  ///   that predates the column) made every later comparison evaluate to NULL
  ///   rather than TRUE — the row could never be updated again.
  /// * the device-id tiebreak, because two devices editing a row in the same
  ///   millisecond stamp the same `modified_at`; with a strict `>` each side
  ///   keeps its own version, neither push moves the server's sequence, and
  ///   nothing ever hands either device the other's row again.
  ///   `(modified_at, device_id)` is a total order every party can evaluate on
  ///   its own, so all three pick the same winner.
  static String _lastWriteWins(String table) =>
      'EXCLUDED.modified_at > COALESCE($table.modified_at, 0) '
      'OR (EXCLUDED.modified_at = COALESCE($table.modified_at, 0) '
      "AND COALESCE(EXCLUDED.device_id, '') > COALESCE($table.device_id, ''))";

  /// The `DO UPDATE SET` list for [table], restricted to the columns this
  /// payload actually carried.
  ///
  /// [columns] maps SQL column to the JSON key that fills it, primary key
  /// columns excluded — those are what matched. A key that is ABSENT from
  /// [json] is left out of the SET list entirely, so the stored value stands;
  /// a key present and explicitly null still clears the column. Assigning
  /// unconditionally is what let a sender that predates a column erase it for
  /// the whole fleet: no `amountMinor` key meant `amount_minor = NULL`, which
  /// by this codebase's own contract reclassifies a fiat transaction as
  /// crypto and demotes its exact minor units to an 8-decimal double, for
  /// good. `isDeleted` had the same shape one step worse — absent read as
  /// `false`, which resurrects a row the rest of the fleet has agreed is gone.
  ///
  /// The INSERT column list is deliberately NOT trimmed the same way: on the
  /// insert path there is no stored value to preserve, and several of these
  /// columns are NOT NULL without a default.
  ///
  /// `modified_at` and `device_id` are always assigned — they are the pair
  /// [_lastWriteWins] is built on, so the winner has to own both, and a
  /// missing stamp has to read as "oldest possible" rather than as NULL.
  static String _assignments(
    String table,
    Map<String, dynamic> json,
    Map<String, String> columns,
  ) => [
    for (final column in columns.entries)
      if (json.containsKey(column.value))
        '${column.key} = EXCLUDED.${column.key}',
    'modified_at = EXCLUDED.modified_at',
    'device_id = EXCLUDED.device_id',
  ].join(',\n        ');

  /// A multi-row `VALUES` binds every column of every row it carries, and
  /// SQLite refuses a statement with more bound variables than its
  /// compile-time `SQLITE_MAX_VARIABLE_NUMBER` — which is not a runtime
  /// property this code can read. The bundled `sqlite3_flutter_libs` build
  /// reports 32766; SQLite's own documented default, and what a host-provided
  /// library may well be built with, is 999. Chunks are sized against the
  /// lower number, because the failure mode on the other build is not a slow
  /// pull, it is `too many SQL variables` thrown out of the middle of one.
  ///
  /// That gives `999 ~/ columnsPerRow` rows per statement — 52 for `accounts`
  /// (19 columns), 124 for `exchange_rates` (8) — so a 5 000-row page is 41
  /// statements instead of 5 000.
  static const int _maxBoundVariables = 999;

  /// Applies a whole pulled table in as few statements as the variable cap
  /// allows, with exactly the per-row semantics the single-row upserts had.
  ///
  /// A page of 5 000 rows used to be 5 000 `customInsert` calls — 5 000 round
  /// trips through drift's background isolate inside one transaction, and a
  /// full pull of the bundled 283 000 exchange rates was 283 000 of them. The
  /// same rows now go out in chunked multi-row `INSERT … VALUES (…),(…) ON
  /// CONFLICT … DO UPDATE`, which SQLite applies row by row: each row meets
  /// the same [_lastWriteWins] guard, in the same order, and a row that loses
  /// the comparison is skipped rather than erroring — so two versions of one
  /// key inside a single statement resolve the way they would have as two
  /// statements.
  ///
  /// Rows are grouped by their `DO UPDATE SET` list before they are chunked.
  /// That list depends on WHICH keys the payload carried ([_assignments]): a
  /// column the sender omitted must keep its stored value, so rows of
  /// different shape cannot share a statement. A page from one server has one
  /// shape and collapses to a single group; a mixed page still gets exactly
  /// the assignments each row earns.
  ///
  /// [insertColumns] is the full INSERT column list — deliberately NOT trimmed
  /// per row, for the reason [_assignments] documents.
  Future<void> _upsertBatch({
    required String table,
    required String conflictTarget,
    required List<String> insertColumns,
    required Map<String, String> assignable,
    required List<drift_db.Variable> Function(Map<String, dynamic> json) bind,
    required List<Map<String, dynamic>> rows,
  }) async {
    if (rows.isEmpty) return;

    final byShape = <String, List<Map<String, dynamic>>>{};
    for (final json in rows) {
      byShape
          .putIfAbsent(_assignments(table, json, assignable), () => [])
          .add(json);
    }

    final columns = insertColumns.join(', ');
    final placeholder =
        '(${List.filled(insertColumns.length, '?').join(', ')})';
    final rowsPerStatement = math.max(
      1,
      _maxBoundVariables ~/ insertColumns.length,
    );
    final guard = _lastWriteWins(table);

    for (final shape in byShape.entries) {
      final shapeRows = shape.value;
      for (var start = 0; start < shapeRows.length; start += rowsPerStatement) {
        final chunk = shapeRows.sublist(
          start,
          math.min(start + rowsPerStatement, shapeRows.length),
        );
        await _database.customInsert(
          'INSERT INTO $table ($columns)\n'
          '      VALUES ${List.filled(chunk.length, placeholder).join(', ')}\n'
          '      ON CONFLICT ($conflictTarget) DO UPDATE SET\n'
          '        ${shape.key}\n'
          '      WHERE $guard',
          variables: [for (final json in chunk) ...bind(json)],
        );
      }
    }
  }

  Future<void> _upsertLanguages(List<Map<String, dynamic>> rows) =>
      _upsertBatch(
        table: 'languages',
        conflictTarget: 'language_code',
        insertColumns: const [
          'language_code',
          'language',
          'modified_at',
          'device_id',
        ],
        assignable: const {'language': 'language'},
        rows: rows,
        bind: (json) => [
          drift_db.Variable.withString(json['languageCode'] as String? ?? 'en'),
          drift_db.Variable.withString(
            json['language'] as String? ?? 'English',
          ),
          drift_db.Variable.withInt(json['modifiedAt'] as int? ?? 1),
          drift_db.Variable(json['deviceId'] as String?),
        ],
      );

  Future<void> _upsertCurrencies(List<Map<String, dynamic>> rows) =>
      _upsertBatch(
        table: 'currencies',
        conflictTarget: 'code',
        insertColumns: const [
          'code',
          'name',
          'language_code',
          'type',
          'modified_at',
          'device_id',
        ],
        assignable: const {
          'name': 'name',
          'language_code': 'languageCode',
          'type': 'type',
        },
        rows: rows,
        bind: (json) => [
          drift_db.Variable.withString(json['code'] as String? ?? 'USD'),
          drift_db.Variable.withString(json['name'] as String? ?? 'US Dollar'),
          drift_db.Variable.withString(json['languageCode'] as String? ?? 'en'),
          drift_db.Variable.withInt(json['type'] as int? ?? 0),
          drift_db.Variable.withInt(json['modifiedAt'] as int? ?? 1),
          drift_db.Variable(json['deviceId'] as String?),
        ],
      );

  Future<void> _upsertStyles(List<Map<String, dynamic>> rows) => _upsertBatch(
    table: 'styles',
    conflictTarget: 'id',
    insertColumns: const [
      'id',
      'name',
      'color_hex',
      'icon_name',
      'icon_type',
      'modified_at',
      'device_id',
      'is_deleted',
    ],
    assignable: const {
      'name': 'name',
      'color_hex': 'colorHex',
      'icon_name': 'iconName',
      'icon_type': 'iconType',
      'is_deleted': 'isDeleted',
    },
    rows: rows,
    bind: (json) => [
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

  Future<void> _upsertAccountTypes(List<Map<String, dynamic>> rows) =>
      _upsertBatch(
        table: 'account_types',
        conflictTarget: 'id',
        insertColumns: const [
          'id',
          'name',
          'language_code',
          'modified_at',
          'device_id',
          'is_deleted',
        ],
        assignable: const {
          'name': 'name',
          'language_code': 'languageCode',
          'is_deleted': 'isDeleted',
        },
        rows: rows,
        bind: (json) => [
          drift_db.Variable.withString(json['id'] as String? ?? ''),
          drift_db.Variable.withString(json['name'] as String? ?? ''),
          drift_db.Variable.withString(json['languageCode'] as String? ?? 'en'),
          drift_db.Variable.withInt(json['modifiedAt'] as int? ?? 1),
          drift_db.Variable(json['deviceId'] as String?),
          drift_db.Variable.withInt(_parseBool(json['isDeleted']) ? 1 : 0),
        ],
      );

  Future<void> _upsertCurrencyDesignations(List<Map<String, dynamic>> rows) =>
      _upsertBatch(
        table: 'currency_designations',
        conflictTarget: 'id',
        insertColumns: const [
          'id',
          'value',
          'currency_code',
          'modified_at',
          'device_id',
          'is_deleted',
        ],
        assignable: const {
          'value': 'value',
          'currency_code': 'currencyCode',
          'is_deleted': 'isDeleted',
        },
        rows: rows,
        bind: (json) => [
          drift_db.Variable.withString(json['id'] as String? ?? ''),
          drift_db.Variable.withString(json['value'] as String? ?? ''),
          drift_db.Variable.withString(
            json['currencyCode'] as String? ?? 'USD',
          ),
          drift_db.Variable.withInt(json['modifiedAt'] as int? ?? 1),
          drift_db.Variable(json['deviceId'] as String?),
          drift_db.Variable.withInt(_parseBool(json['isDeleted']) ? 1 : 0),
        ],
      );

  Future<void> _upsertCategories(List<Map<String, dynamic>> rows) =>
      _upsertBatch(
        table: 'categories',
        conflictTarget: 'id',
        insertColumns: const [
          'id',
          'name',
          'parent_id',
          'style_id',
          'type',
          'modified_at',
          'device_id',
          'is_deleted',
        ],
        assignable: const {
          'name': 'name',
          'parent_id': 'parentId',
          'style_id': 'styleId',
          'type': 'type',
          'is_deleted': 'isDeleted',
        },
        rows: rows,
        bind: (json) => [
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

  Future<void> _upsertAccounts(List<Map<String, dynamic>> rows) => _upsertBatch(
    table: 'accounts',
    conflictTarget: 'id',
    insertColumns: const [
      'id',
      'name',
      'description',
      'balance',
      'balance_minor',
      'opening_balance',
      'opening_balance_minor',
      'currency_code',
      'currency_designation_id',
      'style_id',
      'account_type_id',
      'creation_date',
      'country',
      'asset_id',
      'asset_quantity',
      'fee_structure',
      'modified_at',
      'device_id',
      'is_deleted',
    ],
    assignable: const {
      'name': 'name',
      'description': 'description',
      'balance': 'balance',
      'balance_minor': 'balanceMinor',
      'opening_balance': 'openingBalance',
      'opening_balance_minor': 'openingBalanceMinor',
      'currency_code': 'currencyCode',
      'currency_designation_id': 'currencyDesignationId',
      'style_id': 'styleId',
      'account_type_id': 'accountTypeId',
      'creation_date': 'creationDate',
      'country': 'country',
      'asset_id': 'assetId',
      'asset_quantity': 'assetQuantity',
      'fee_structure': 'feeStructure',
      'is_deleted': 'isDeleted',
    },
    rows: rows,
    bind: (json) {
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
      // A sender that predates the anchor sends the balance and nothing else,
      // so the balance stands in for the anchor here and _applyChanges
      // re-derives the real anchor once the batch's transactions are in.
      // Defaulting to zero instead would hand such an account a balance made
      // of its transactions alone, with the money it opened with quietly gone.
      final openingBalance = (json['openingBalance'] as num?)?.toDouble();
      final openingBalanceMinor = (json['openingBalanceMinor'] as num?)
          ?.toInt();

      return [
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
      ];
    },
  );

  Future<void> _upsertTransactions(List<Map<String, dynamic>> rows) =>
      _upsertBatch(
        table: 'transactions',
        conflictTarget: 'id',
        insertColumns: const [
          'id',
          'description',
          'amount',
          'amount_minor',
          'date',
          'account_id',
          'category_id',
          'currency_code',
          'exchange_rate',
          'exchange_rate_preset',
          'fee',
          'fee_minor',
          'linked_transaction_id',
          'needs_review',
          'modified_at',
          'device_id',
          'is_deleted',
        ],
        assignable: const {
          'description': 'description',
          'amount': 'amount',
          'amount_minor': 'amountMinor',
          'date': 'date',
          'account_id': 'accountId',
          'category_id': 'categoryId',
          'currency_code': 'currencyCode',
          'exchange_rate': 'exchangeRate',
          'exchange_rate_preset': 'exchangeRatePreset',
          'fee': 'fee',
          'fee_minor': 'feeMinor',
          'linked_transaction_id': 'linkedTransactionId',
          'needs_review': 'needsReview',
          'is_deleted': 'isDeleted',
        },
        rows: rows,
        bind: (json) {
          final currencyCode = json['currencyCode'] as String?;
          final resolvedCurrencyCode =
              (currencyCode != null && currencyCode.isNotEmpty)
              ? currencyCode
              : 'USD';

          return [
            drift_db.Variable.withString(json['id'] as String? ?? ''),
            drift_db.Variable.withString(json['description'] as String? ?? ''),
            drift_db.Variable.withReal(
              _round((json['amount'] as num?)?.toDouble() ?? 0.0),
            ),
            drift_db.Variable((json['amountMinor'] as num?)?.toInt()),
            drift_db.Variable.withDateTime(
              DateTime.tryParse(json['date'] as String? ?? '') ??
                  DateTime.now(),
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
            drift_db.Variable.withInt(
              _parseBool(json['needsReview']) ? 1 : 0,
            ),
            drift_db.Variable.withInt(json['modifiedAt'] as int? ?? 1),
            drift_db.Variable(json['deviceId'] as String?),
            drift_db.Variable.withInt(_parseBool(json['isDeleted']) ? 1 : 0),
          ];
        },
      );

  /// Collapses the `custom_api` duplicates a single page can carry.
  ///
  /// The dedup DELETE below only evicts rows that are ALREADY in the local
  /// database. A server that still holds two `custom_api` entries on the same
  /// `(asset_id, date)` under different ids — exactly the shape
  /// `idx_asset_entries_custom_api_dedup` was added in v7 to stop — sends both
  /// in one page, and the second row fails that partial UNIQUE index. Because
  /// a page applies all-or-nothing, that aborted the whole sync cycle, every
  /// cycle: observed live as
  /// `UNIQUE constraint failed: asset_entries.asset_id, asset_entries.date,
  /// asset_entries.source` on a device that could then never finish another
  /// pull.
  ///
  /// Resolved the way every other conflict in this engine is: the
  /// `(modifiedAt, deviceId)` total order of [_lastWriteWins], so the client,
  /// the server and any other device pick the same survivor. The loser is
  /// dropped from the page only — it stays on the server, and once the winner
  /// is pushed back the pair collapses there too.
  static List<Map<String, dynamic>> _dedupeCustomApiPage(
    List<Map<String, dynamic>> rows,
  ) {
    final seen = <String, int>{};
    final out = <Map<String, dynamic>>[];
    for (final json in rows) {
      if ((json['source'] as String? ?? 'manual') != 'custom_api') {
        out.add(json);
        continue;
      }
      final raw = json['date'] as String? ?? '';
      final parsed = DateTime.tryParse(raw);
      // Keyed on the parsed instant, because that is what reaches the column;
      // an unparsable date falls back to its own text so two of them are not
      // silently merged.
      final key =
          '${json['assetId'] ?? ''}\u0000'
          '${parsed?.toUtc().millisecondsSinceEpoch ?? raw}';
      final at = seen[key];
      if (at == null) {
        seen[key] = out.length;
        out.add(json);
        continue;
      }
      if (_winsLastWrite(json, out[at])) out[at] = json;
    }
    return out;
  }

  /// `(modifiedAt, deviceId)` compared the way [_lastWriteWins] compares it in
  /// SQL: a missing stamp reads as the oldest possible, a missing device id as
  /// the empty string.
  static bool _winsLastWrite(
    Map<String, dynamic> candidate,
    Map<String, dynamic> incumbent,
  ) {
    final candidateAt = candidate['modifiedAt'] as int? ?? 0;
    final incumbentAt = incumbent['modifiedAt'] as int? ?? 0;
    if (candidateAt != incumbentAt) return candidateAt > incumbentAt;
    final candidateDevice = candidate['deviceId'] as String? ?? '';
    final incumbentDevice = incumbent['deviceId'] as String? ?? '';
    return candidateDevice.compareTo(incumbentDevice) > 0;
  }

  /// The one table whose apply is not statements-per-chunk, and why.
  ///
  /// A `custom_api` entry has to evict any pre-fix duplicate holding the same
  /// `(asset_id, date)` under a DIFFERENT id, or the partial UNIQUE index added
  /// in schema v7 rejects the insert. The `id != ?` half of that is per-row:
  /// folding a chunk into one `DELETE … WHERE (asset_id, date) IN (…) AND id
  /// NOT IN (…)` changes which rows survive as soon as a page moves one id onto
  /// another id's slot, so the dedup stays one statement per custom_api row.
  /// It is cheap because `'custom_api'` is spelled as a literal rather than
  /// bound — see the comment on the DELETE — which keeps every one of them an
  /// index seek instead of a scan of the whole table.
  ///
  /// The upserts themselves are batched for the whole table, manual entries
  /// included.
  Future<void> _upsertAssetEntries(List<Map<String, dynamic>> rows) async {
    rows = _dedupeCustomApiPage(rows);
    for (final json in rows) {
      final source = json['source'] as String? ?? 'manual';
      final id = json['id'] as String? ?? '';
      if (source != 'custom_api' || id.isEmpty) continue;

      final date =
          DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now();
      await _database.customUpdate(
        // `source = 'custom_api'` is a literal, and has to stay one: SQLite may
        // only use a partial index when the query's WHERE provably implies the
        // index's own WHERE, and a bound parameter proves nothing at prepare
        // time. The branch above has already established the value, so the
        // literal is exactly as correct — and it is what keeps
        // idx_asset_entries_custom_api_dedup in the query plan.
        'DELETE FROM asset_entries '
        "WHERE source = 'custom_api' AND asset_id = ? AND date = ? AND id != ?",
        variables: [
          drift_db.Variable.withString(json['assetId'] as String? ?? ''),
          drift_db.Variable.withDateTime(date),
          drift_db.Variable.withString(id),
        ],
        updates: {_database.assetEntries},
        updateKind: drift_db.UpdateKind.delete,
      );
    }

    await _upsertBatch(
      table: 'asset_entries',
      conflictTarget: 'id',
      insertColumns: const [
        'id',
        'asset_id',
        'name',
        'date',
        'value',
        'quantity',
        'asset_type',
        'description',
        'currency_code',
        'account_id',
        'source',
        'preset',
        'modified_at',
        'device_id',
        'source_id',
        'is_deleted',
      ],
      assignable: const {
        'asset_id': 'assetId',
        'name': 'name',
        'date': 'date',
        'value': 'value',
        'quantity': 'quantity',
        'asset_type': 'assetType',
        'description': 'description',
        'currency_code': 'currencyCode',
        'account_id': 'accountId',
        'source': 'source',
        'preset': 'preset',
        'source_id': 'sourceId',
        'is_deleted': 'isDeleted',
      },
      rows: rows,
      bind: (json) => [
        drift_db.Variable.withString(json['id'] as String? ?? ''),
        drift_db.Variable.withString(json['assetId'] as String? ?? ''),
        drift_db.Variable.withString(json['name'] as String? ?? ''),
        drift_db.Variable.withDateTime(
          DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        ),
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
        drift_db.Variable.withString(json['source'] as String? ?? 'manual'),
        drift_db.Variable.withInt(json['preset'] as int? ?? 1),
        drift_db.Variable.withInt(json['modifiedAt'] as int? ?? 1),
        drift_db.Variable(json['deviceId'] as String?),
        drift_db.Variable(json['sourceId'] as String?),
        drift_db.Variable.withInt(_parseBool(json['isDeleted']) ? 1 : 0),
      ],
    );
  }

  Future<void> _upsertCustomDataSources(List<Map<String, dynamic>> rows) =>
      _upsertBatch(
        table: 'custom_data_sources',
        conflictTarget: 'id',
        insertColumns: const [
          'id',
          'name',
          'url',
          'data_type',
          'enabled',
          'auto_fetch',
          'last_fetch_at',
          'modified_at',
          'device_id',
          'is_deleted',
        ],
        assignable: const {
          'name': 'name',
          'url': 'url',
          'data_type': 'dataType',
          'enabled': 'enabled',
          'auto_fetch': 'autoFetch',
          'last_fetch_at': 'lastFetchAt',
          'is_deleted': 'isDeleted',
        },
        rows: rows,
        bind: (json) => [
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

  Future<void> _upsertApiSettings(List<Map<String, dynamic>> rows) =>
      _upsertBatch(
        table: 'api_settings_table',
        conflictTarget: 'id',
        insertColumns: const [
          'id',
          'enabled',
          'auto_fetch',
          'last_fetch_at',
          'modified_at',
          'device_id',
          'is_deleted',
        ],
        assignable: const {
          'enabled': 'enabled',
          'auto_fetch': 'autoFetch',
          'last_fetch_at': 'lastFetchAt',
          'is_deleted': 'isDeleted',
        },
        rows: rows,
        bind: (json) => [
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

  Future<void> _upsertSmsPresets(List<Map<String, dynamic>> rows) =>
      _upsertBatch(
        table: 'sms_presets',
        conflictTarget: 'id',
        insertColumns: const [
          'id',
          'name',
          'sender_filter',
          'is_built_in',
          'is_enabled',
          'default_account_id',
          'default_category_id',
          'rules_json',
          'modified_at',
          'device_id',
          'is_deleted',
        ],
        assignable: const {
          'name': 'name',
          'sender_filter': 'senderFilter',
          'is_built_in': 'isBuiltIn',
          'is_enabled': 'isEnabled',
          'default_account_id': 'defaultAccountId',
          'default_category_id': 'defaultCategoryId',
          'rules_json': 'rulesJson',
          'is_deleted': 'isDeleted',
        },
        rows: rows,
        bind: (json) => [
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

  Future<void> _upsertSettings(List<Map<String, dynamic>> rows) {
    // Defence in depth: even if a peer (or an older build) uploaded its own
    // device-local settings, never let them overwrite ours. Accepting
    // `local_device_id` here would give both devices the same identity and
    // break the "skip my own packets" check in the file-based sync. Filtered
    // BEFORE the batch, so a rejected key cannot ride into the database inside
    // another row's statement.
    final accepted = <Map<String, dynamic>>[];
    for (final json in rows) {
      final key = json['key'] as String? ?? '';
      if (_deviceLocalSettingKeys.contains(key)) {
        debugPrint(
          '[ServerSync] Ignoring device-local setting from peer: $key',
        );
        continue;
      }
      accepted.add(json);
    }

    return _upsertBatch(
      table: 'settings',
      conflictTarget: 'key',
      insertColumns: const [
        'key',
        'value',
        'device',
        'modified_at',
        'device_id',
      ],
      assignable: const {'value': 'value', 'device': 'device'},
      rows: accepted,
      bind: (json) => [
        drift_db.Variable.withString(json['key'] as String? ?? ''),
        drift_db.Variable.withString(json['value'] as String? ?? ''),
        drift_db.Variable(json['device'] as String?),
        drift_db.Variable.withInt(json['modifiedAt'] as int? ?? 1),
        drift_db.Variable(json['deviceId'] as String?),
      ],
    );
  }

  Future<void> _upsertExchangeRates(List<Map<String, dynamic>> rows) =>
      _upsertBatch(
        table: 'exchange_rates',
        conflictTarget: 'from_currency_code, to_currency_code, date, preset',
        insertColumns: const [
          'from_currency_code',
          'to_currency_code',
          'rate',
          'preset',
          'date',
          'modified_at',
          'device_id',
          'source_id',
        ],
        assignable: const {'rate': 'rate', 'source_id': 'sourceId'},
        rows: rows,
        bind: (json) => [
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
          drift_db.Variable.withDateTime(
            DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
          ),
          drift_db.Variable.withInt(json['modifiedAt'] as int? ?? 1),
          drift_db.Variable(json['deviceId'] as String?),
          drift_db.Variable(json['sourceId'] as String?),
        ],
      );

  Future<void> _upsertInflationRates(List<Map<String, dynamic>> rows) =>
      _upsertBatch(
        table: 'inflation_rates',
        conflictTarget: 'date, country, preset',
        insertColumns: const [
          'date',
          'percent',
          'country',
          'preset',
          'modified_at',
          'device_id',
          'source_id',
        ],
        assignable: const {'percent': 'percent', 'source_id': 'sourceId'},
        rows: rows,
        bind: (json) {
          // `country` is part of the primary key and NOT NULL as of schema v10,
          // where the worldwide series is spelled with the
          // `globalInflationCountry` sentinel. A peer still on v9, or a server
          // row written by one, sends null for it - binding that straight in
          // would fail the constraint and abort the whole pull.
          final rawCountry = json['country'] as String?;
          final country = (rawCountry == null || rawCountry.isEmpty)
              ? globalInflationCountry
              : rawCountry;

          return [
            drift_db.Variable.withDateTime(
              DateTime.tryParse(json['date'] as String? ?? '') ??
                  DateTime.now(),
            ),
            drift_db.Variable.withReal(
              (json['percent'] as num?)?.toDouble() ?? 0.0,
            ),
            drift_db.Variable(country),
            drift_db.Variable.withInt(json['preset'] as int? ?? 1),
            drift_db.Variable.withInt(json['modifiedAt'] as int? ?? 1),
            drift_db.Variable(json['deviceId'] as String?),
            drift_db.Variable(json['sourceId'] as String?),
          ];
        },
      );

  Future<void> _upsertCustomThemes(
    List<Map<String, dynamic>> rows,
  ) => _upsertBatch(
    table: 'custom_themes',
    conflictTarget: 'id',
    insertColumns: const [
      'id',
      'name',
      'primary_color_hex',
      'secondary_color_hex',
      'surface_color_hex',
      'background_color_hex',
      'background_image_path',
      'background_image_opacity',
      'background_image_blur',
      'window_effect_type',
      'effect_opacity',
      'surface_opacity',
      'theme_mode',
      'is_preset',
      'is_active',
      'modified_at',
      'device_id',
      'is_deleted',
    ],
    assignable: const {
      'name': 'name',
      'primary_color_hex': 'primaryColorHex',
      'secondary_color_hex': 'secondaryColorHex',
      'surface_color_hex': 'surfaceColorHex',
      'background_color_hex': 'backgroundColorHex',
      'background_image_path': 'backgroundImagePath',
      'background_image_opacity': 'backgroundImageOpacity',
      'background_image_blur': 'backgroundImageBlur',
      'window_effect_type': 'windowEffectType',
      'effect_opacity': 'effectOpacity',
      'surface_opacity': 'surfaceOpacity',
      'theme_mode': 'themeMode',
      'is_preset': 'isPreset',
      'is_active': 'isActive',
      'is_deleted': 'isDeleted',
    },
    rows: rows,
    bind: (json) => [
      drift_db.Variable.withString(json['id'] as String? ?? ''),
      drift_db.Variable.withString(json['name'] as String? ?? 'Custom Theme'),
      drift_db.Variable.withString(json['primaryColorHex'] as String? ?? ''),
      drift_db.Variable.withString(json['secondaryColorHex'] as String? ?? ''),
      drift_db.Variable.withString(json['surfaceColorHex'] as String? ?? ''),
      drift_db.Variable.withString(json['backgroundColorHex'] as String? ?? ''),
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

  bool _parseBool(dynamic val) {
    if (val is bool) return val;
    if (val is int) return val == 1;
    return false;
  }

  /// Drops the last few bits of floating-point noise from a double, so the
  /// same value computed on two devices does not travel as `0.1 + 0.2` on one
  /// and `0.30000000000000004` on the other and lose a last-write-wins
  /// comparison over the difference.
  ///
  /// Significant digits, not decimal places. This used to be
  /// `toStringAsFixed(8)` behind a `< 1e-8` guard, which measures precision
  /// from the decimal point instead of from the number: a value's own
  /// magnitude decided how much of it survived. An exchange rate of 3.7e-8
  /// left here as 4e-8 and a crypto `assetQuantity` of 1.5e-8 as 1e-8 — while
  /// 9e-9, being under the guard, came through untouched. The rule was
  /// backwards for exactly the values it was written to protect (IRR→BTC at
  /// 2.4e-10, fractional holdings), and it bit only on the server path: the
  /// peer-to-peer engine ships these verbatim, so a device on both paths
  /// flip-flopped between the two answers forever.
  ///
  /// Twelve digits is comfortably inside a double's 15-17, so this erases the
  /// noise two different computations of the same number disagree in and
  /// nothing else, at any magnitude. `toStringAsPrecision` switches to
  /// exponent form where it has to, which `double.parse` reads back exactly.
  double _round(double value) {
    if (value == 0 || !value.isFinite) return value;
    return double.parse(value.toStringAsPrecision(_significantDigits));
  }

  /// How much of a double is signal. The last three to five digits of a
  /// 64-bit float are where two routes to the same value differ.
  static const int _significantDigits = 12;
}
