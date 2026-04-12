import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:drift/drift.dart' as drift_db;
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';

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

  ServerSyncService({
    required AppDatabase database,
    required SettingsRepository settingsRepository,
  }) : _database = database,
       _settingsRepository = settingsRepository;

  Future<String> _getBaseUrl() async {
    final setting = await _settingsRepository.getSetting('server_sync_url');
    return setting?.value ?? 'http://localhost:58080';
  }

  Future<String> _getAuthToken() async {
    final setting = await _settingsRepository.getSetting('server_sync_token');
    return setting?.value ?? 'dev_token';
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
      debugPrint('[DIAG][ServerSync] server_sync_enabled=false — asset_entries will NOT sync between devices!');
      return;
    }

    if (_isSyncingInternal) {
      debugPrint('[ServerSync] Sync already in progress. Skipping.');
      return;
    }

    _isSyncingInternal = true;
    try {
      debugPrint('[ServerSync] Starting sync cycle...');
      await _pull();
      await _push();
      debugPrint('[ServerSync] Sync cycle completed.');
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
      debugPrint('[WS_CLIENT] Already connected/connecting — skipping initWebSocket()');
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
      final wsUrl = '$wsParams/ws/sync';

      debugPrint('[WS_CLIENT] Connecting to: $wsUrl');

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
            sync();
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

      debugPrint('[WS_CLIENT] Stream listener registered, connection active');
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
  void _scheduleReconnect() {
    if (_isDisposed || _reconnectScheduled) return;
    _reconnectScheduled = true;
    Future.delayed(const Duration(seconds: 10), () {
      _reconnectScheduled = false;
      _connectWebSocket();
    });
  }

  Timer? _debounceTimer;
  Timer? _periodicSyncTimer;
  StreamSubscription? _dbSubscription;

  void dispose() {
    _isDisposed = true;
    _autoSyncInitialized = false;
    _reconnectScheduled = false;
    _isConnecting = false;
    _pingTimer?.cancel();
    _pingTimer = null;
    // Cancel subscription first to prevent onDone from firing during dispose
    _wsSubscription?.cancel();
    _wsSubscription = null;
    _channel?.sink.close();
    _channel = null;
    _dbSubscription?.cancel();
    _debounceTimer?.cancel();
    _periodicSyncTimer?.cancel();
  }

  Future<bool> testConnection({String? url, String? token}) async {
    try {
      final baseUrl = url ?? await _getBaseUrl();
      final authToken = token ?? await _getAuthToken();

      // Use the pull endpoint with limit=1 to test connectivity and authentication
      final uri = Uri.parse('$baseUrl/api/sync/pull?limit=1&last_sync=0');

      final response = await http
          .get(uri, headers: {'Authorization': 'Bearer $authToken'})
          .timeout(const Duration(seconds: 10)); // Short timeout for testing

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint(
          '[ServerSync] Test connection failed: ${response.statusCode}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('[ServerSync] Test connection error: $e');
      return false;
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
      // 1. Loop Protection: If we are currently applying a Pull, ignore updates
      if (_isSyncingInternal) return;

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
          } catch (e) {
            debugPrint(
              '[ServerSync] Auto-sync failed: $e. Scheduling retry...',
            );
            // Simple retry mechanism: try again in 30 seconds if it failed
            // We check _isEnabled again just in case the user disabled it in the meantime
            if (await _isEnabled()) {
              Timer(
                const Duration(seconds: 30),
                () => sync().catchError(
                  (e) => debugPrint('[ServerSync] Retry failed: $e'),
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
    _periodicSyncTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) async {
        debugPrint('[ServerSync] Periodic sync triggered (5-min fallback).');
        try {
          await sync();
        } catch (e) {
          debugPrint('[ServerSync] Periodic sync failed: $e');
        }
      },
    );
    debugPrint('[ServerSync] DB Auto-Sync and periodic timer initialized.');
  }

  Future<int> getPendingChangesCount() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPushKey = 'server_last_push_timestamp';
    final lastPush = prefs.getInt(lastPushKey) ?? 0;

    int total = 0;

    // Helper to run count query
    Future<int> count(String table) async {
      final result = await _database
          .customSelect(
            'SELECT COUNT(*) as c FROM $table WHERE modified_at > ?',
            variables: [drift_db.Variable.withInt(lastPush)],
          )
          .getSingle();
      return result.read<int>('c');
    }

    final tables = [
      'settings',
      'api_settings_table',
      'languages',
      'currencies',
      'styles',
      'custom_themes',
      'account_types',
      'currency_designations',
      'categories',
      'exchange_rates',
      'inflation_rates',
      'custom_data_sources',
      'sms_presets',
      'accounts',
      'asset_entries',
      'transactions',
    ];

    for (var table in tables) {
      total += await count(table);
    }

    return total;
  }

  Future<void> _pull() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncKey = 'server_last_sync_timestamp';

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

      debugPrint('[ServerSync] Pulling batch since $lastSync (iteration $iteration)...');

      final fetchStopwatch = Stopwatch()..start();
      final response = await http
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

        // Primary infinite-loop guard: stop if timestamp did not advance.
        // This catches the case where all rows share the same modifiedAt and
        // the next query with modified_at > serverTimestamp returns nothing.
        if (serverTimestamp <= lastSync) {
          debugPrint(
            '[ServerSync] WARNING: Server timestamp did not advance. Stopping pull loop.',
          );
          break;
        }

        // Secondary stop: server explicitly says no more data
        if (!hasMore) break;
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
    final prefs = await SharedPreferences.getInstance();
    final lastPushKey = 'server_last_push_timestamp';
    final lastPush = prefs.getInt(lastPushKey) ?? 0;

    debugPrint('[ServerSync] Starting batched push from $lastPush...');

    // We keep track of the highest timestamp acknowledged by the server
    int maxAckTimestamp = lastPush;

    try {
      await _pushTableRecords(
        'languages',
        lastPush,
        (t, lp, lim, off) => _database.select(_database.languages)
          ..where((r) => r.modifiedAt.isBiggerThanValue(lp))
          ..limit(lim, offset: off),
        (l) => {
          'languageCode': l.languageCode,
          'language': l.language,
          'modifiedAt': l.modifiedAt,
          'deviceId': l.deviceId,
        },
        (ts) => maxAckTimestamp = ts > maxAckTimestamp ? ts : maxAckTimestamp,
      );

      await _pushTableRecords(
        'currencies',
        lastPush,
        (t, lp, lim, off) => _database.select(_database.currencies)
          ..where((r) => r.modifiedAt.isBiggerThanValue(lp))
          ..limit(lim, offset: off),
        (c) => {
          'code': c.code,
          'name': c.name,
          'languageCode': c.languageCode,
          'type': c.type.index,
          'modifiedAt': c.modifiedAt,
          'deviceId': c.deviceId,
        },
        (ts) => maxAckTimestamp = ts > maxAckTimestamp ? ts : maxAckTimestamp,
      );

      await _pushTableRecords(
        'settings',
        lastPush,
        (t, lp, lim, off) => _database.select(_database.settings)
          ..where((r) => r.modifiedAt.isBiggerThanValue(lp))
          ..limit(lim, offset: off),
        _settingToJson,
        (t) => maxAckTimestamp = t > maxAckTimestamp ? t : maxAckTimestamp,
      );

      await _pushTableRecords(
        'api_settings',
        lastPush,
        (t, lp, lim, off) => _database.select(_database.apiSettingsTable)
          ..where((r) => r.modifiedAt.isBiggerThanValue(lp))
          ..limit(lim, offset: off),
        _apiSettingsToJson,
        (t) => maxAckTimestamp = t > maxAckTimestamp ? t : maxAckTimestamp,
      );

      await _pushTableRecords(
        'styles',
        lastPush,
        (t, lp, lim, off) => _database.select(_database.styles)
          ..where((r) => r.modifiedAt.isBiggerThanValue(lp))
          ..limit(lim, offset: off),
        _styleToJson,
        (t) => maxAckTimestamp = t > maxAckTimestamp ? t : maxAckTimestamp,
      );

      await _pushTableRecords(
        'custom_themes',
        lastPush,
        (t, lp, lim, off) => _database.select(_database.customThemes)
          ..where((r) => r.modifiedAt.isBiggerThanValue(lp))
          ..limit(lim, offset: off),
        _customThemeToJson,
        (t) => maxAckTimestamp = t > maxAckTimestamp ? t : maxAckTimestamp,
      );

      await _pushTableRecords(
        'account_types',
        lastPush,
        (t, lp, lim, off) => _database.select(_database.accountTypes)
          ..where((r) => r.modifiedAt.isBiggerThanValue(lp))
          ..limit(lim, offset: off),
        _accountTypeToJson,
        (t) => maxAckTimestamp = t > maxAckTimestamp ? t : maxAckTimestamp,
      );

      await _pushTableRecords(
        'currency_designations',
        lastPush,
        (t, lp, lim, off) => _database.select(_database.currencyDesignations)
          ..where((r) => r.modifiedAt.isBiggerThanValue(lp))
          ..limit(lim, offset: off),
        _currencyDesignationToJson,
        (t) => maxAckTimestamp = t > maxAckTimestamp ? t : maxAckTimestamp,
      );

      await _pushTableRecords(
        'categories',
        lastPush,
        (t, lp, lim, off) => _database.select(_database.categories)
          ..where((r) => r.modifiedAt.isBiggerThanValue(lp))
          ..limit(lim, offset: off),
        _categoryToJson,
        (t) => maxAckTimestamp = t > maxAckTimestamp ? t : maxAckTimestamp,
      );

      await _pushTableRecords(
        'exchange_rates',
        lastPush,
        (t, lp, lim, off) => _database.select(_database.exchangeRates)
          ..where((r) => r.modifiedAt.isBiggerThanValue(lp))
          ..limit(lim, offset: off),
        _exchangeRateToJson,
        (t) => maxAckTimestamp = t > maxAckTimestamp ? t : maxAckTimestamp,
      );

      await _pushTableRecords(
        'inflation_rates',
        lastPush,
        (t, lp, lim, off) => _database.select(_database.inflationRates)
          ..where((r) => r.modifiedAt.isBiggerThanValue(lp))
          ..limit(lim, offset: off),
        _inflationRateToJson,
        (t) => maxAckTimestamp = t > maxAckTimestamp ? t : maxAckTimestamp,
      );

      await _pushTableRecords(
        'custom_data_sources',
        lastPush,
        (t, lp, lim, off) => _database.select(_database.customDataSources)
          ..where((r) => r.modifiedAt.isBiggerThanValue(lp))
          ..limit(lim, offset: off),
        _customDataSourceToJson,
        (t) => maxAckTimestamp = t > maxAckTimestamp ? t : maxAckTimestamp,
      );

      await _pushTableRecords(
        'sms_presets',
        lastPush,
        (t, lp, lim, off) => _database.select(_database.smsPresets)
          ..where((r) => r.modifiedAt.isBiggerThanValue(lp))
          ..limit(lim, offset: off),
        _smsPresetToJson,
        (t) => maxAckTimestamp = t > maxAckTimestamp ? t : maxAckTimestamp,
      );

      // Dependent Tables
      await _pushTableRecords(
        'accounts',
        lastPush,
        (t, lp, lim, off) => _database.select(_database.accounts)
          ..where((r) => r.modifiedAt.isBiggerThanValue(lp))
          ..limit(lim, offset: off),
        _accountToJson,
        (t) => maxAckTimestamp = t > maxAckTimestamp ? t : maxAckTimestamp,
      );

      await _pushTableRecords(
        'asset_entries',
        lastPush,
        (t, lp, lim, off) => _database.select(_database.assetEntries)
          ..where((r) => r.modifiedAt.isBiggerThanValue(lp))
          ..limit(lim, offset: off),
        _assetEntryToJson,
        (t) => maxAckTimestamp = t > maxAckTimestamp ? t : maxAckTimestamp,
      );

      await _pushTableRecords(
        'transactions',
        lastPush,
        (t, lp, lim, off) => _database.select(_database.transactions)
          ..where((r) => r.modifiedAt.isBiggerThanValue(lp))
          ..limit(lim, offset: off),
        _transactionToJson,
        (t) => maxAckTimestamp = t > maxAckTimestamp ? t : maxAckTimestamp,
      );

      debugPrint(
        '[ServerSync] Batched push complete. Final high-water timestamp: $maxAckTimestamp',
      );
      await prefs.setInt(lastPushKey, maxAckTimestamp);
      totalPushStopwatch.stop();
      debugPrint(
        '[PERF] Total Push: ${totalPushStopwatch.elapsedMilliseconds}ms',
      );
    } catch (e) {
      debugPrint('[ServerSync] Error during batched push: $e');
      if (maxAckTimestamp > lastPush) {
        await prefs.setInt(lastPushKey, maxAckTimestamp);
        debugPrint(
          '[ServerSync] Partial push success up to timestamp: $maxAckTimestamp',
        );
      }
      rethrow;
    }
  }

  Future<void> _pushTableRecords<T>(
    String tableName,
    int lastPush,
    drift_db.Selectable<T> Function(String name, int lp, int limit, int offset)
    queryBuilder,
    Map<String, dynamic> Function(T record) toJson,
    void Function(int serverTimestamp) onAck,
  ) async {
    const int batchSize = 20000;
    int offset = 0;

    final baseUrl = await _getBaseUrl();
    final url = Uri.parse('$baseUrl/api/sync/push');
    final authToken = await _getAuthToken();

    while (true) {
      final batchStopwatch = Stopwatch()..start();

      final dbFetchStopwatch = Stopwatch()..start();
      final records = await queryBuilder(
        tableName,
        lastPush,
        batchSize,
        offset,
      ).get();
      dbFetchStopwatch.stop();

      if (records.isEmpty) break;

      debugPrint(
        '[ServerSync] Table $tableName: sending chunk of ${records.length} (offset $offset)...',
      );

      final jsonStopwatch = Stopwatch()..start();
      final payload = {tableName: records.map((e) => toJson(e)).toList()};
      jsonStopwatch.stop();

      final uploadStopwatch = Stopwatch()..start();
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 180));
      uploadStopwatch.stop();

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final serverTimestamp = (body['timestamp'] as num).toInt();
        onAck(serverTimestamp);
        offset += records.length;

        debugPrint(
          '[PERF] Push Batch ($tableName): DB ${dbFetchStopwatch.elapsedMilliseconds}ms, JSON ${jsonStopwatch.elapsedMilliseconds}ms, Network ${uploadStopwatch.elapsedMilliseconds}ms, Total ${batchStopwatch.elapsedMilliseconds}ms',
        );

        // Safety break if we receive exactly 0 or something weird
        if (records.length < batchSize) break;
      } else {
        throw Exception(
          'Push for $tableName failed: ${response.statusCode} ${response.body}',
        );
      }
    }
  }

  Future<void> _applyChanges(Map<String, dynamic> changes) async {
    // Temporarily disable FK checks
    await _database.customStatement('PRAGMA foreign_keys = OFF');
    try {
      debugPrint('[ServerSync] Entering database transaction for pull...');
      if (changes.containsKey('languages')) {
        await _database.transaction(() async {
          final list = changes['languages'] as List;
          debugPrint('[ServerSync] Applying ${list.length} languages...');
          for (final row in list) {
            await _upsertLanguage(row as Map<String, dynamic>);
          }
        });
      }
      if (changes.containsKey('currencies')) {
        await _database.transaction(() async {
          final list = changes['currencies'] as List;
          debugPrint('[ServerSync] Applying ${list.length} currencies...');
          for (final row in list) {
            await _upsertCurrency(row as Map<String, dynamic>);
          }
        });
      }
      if (changes.containsKey('settings')) {
        await _database.transaction(() async {
          final list = changes['settings'] as List;
          debugPrint('[ServerSync] Applying ${list.length} settings...');
          for (final row in list) {
            await _upsertSetting(row as Map<String, dynamic>);
          }
        });
      }
      if (changes.containsKey('api_settings')) {
        await _database.transaction(() async {
          final list = changes['api_settings'] as List;
          debugPrint('[ServerSync] Applying ${list.length} api_settings...');
          for (final row in list) {
            await _upsertApiSetting(row as Map<String, dynamic>);
          }
        });
      }
      if (changes.containsKey('styles')) {
        await _database.transaction(() async {
          final list = changes['styles'] as List;
          debugPrint('[ServerSync] Applying ${list.length} styles...');
          for (final row in list) {
            await _upsertStyle(row as Map<String, dynamic>);
          }
        });
      }
      if (changes.containsKey('custom_themes')) {
        await _database.transaction(() async {
          final list = changes['custom_themes'] as List;
          debugPrint('[ServerSync] Applying ${list.length} custom_themes...');
          for (final row in list) {
            await _upsertCustomTheme(row as Map<String, dynamic>);
          }
        });
      }
      if (changes.containsKey('account_types')) {
        await _database.transaction(() async {
          final list = changes['account_types'] as List;
          debugPrint('[ServerSync] Applying ${list.length} account_types...');
          for (final row in list) {
            await _upsertAccountType(row as Map<String, dynamic>);
          }
        });
      }
      if (changes.containsKey('currency_designations')) {
        await _database.transaction(() async {
          final list = changes['currency_designations'] as List;
          debugPrint(
            '[ServerSync] Applying ${list.length} currency_designations...',
          );
          for (final row in list) {
            await _upsertCurrencyDesignation(row as Map<String, dynamic>);
          }
        });
      }
      if (changes.containsKey('categories')) {
        await _database.transaction(() async {
          final list = changes['categories'] as List;
          debugPrint('[ServerSync] Applying ${list.length} categories...');
          for (final row in list) {
            await _upsertCategory(row as Map<String, dynamic>);
          }
        });
      }
      if (changes.containsKey('exchange_rates')) {
        await _database.transaction(() async {
          final list = changes['exchange_rates'] as List;
          debugPrint('[ServerSync] Applying ${list.length} exchange_rates...');
          for (final row in list) {
            await _upsertExchangeRate(row as Map<String, dynamic>);
          }
        });
      }
      if (changes.containsKey('inflation_rates')) {
        await _database.transaction(() async {
          final list = changes['inflation_rates'] as List;
          debugPrint('[ServerSync] Applying ${list.length} inflation_rates...');
          for (final row in list) {
            await _upsertInflationRate(row as Map<String, dynamic>);
          }
        });
      }
      if (changes.containsKey('custom_data_sources')) {
        await _database.transaction(() async {
          final list = changes['custom_data_sources'] as List;
          debugPrint(
            '[ServerSync] Applying ${list.length} custom_data_sources...',
          );
          for (final row in list) {
            await _upsertCustomDataSource(row as Map<String, dynamic>);
          }
        });
      }
      if (changes.containsKey('sms_presets')) {
        await _database.transaction(() async {
          final list = changes['sms_presets'] as List;
          debugPrint('[ServerSync] Applying ${list.length} sms_presets...');
          for (final row in list) {
            await _upsertSmsPreset(row as Map<String, dynamic>);
          }
        });
      }
      // Dependent Tables
      if (changes.containsKey('accounts')) {
        await _database.transaction(() async {
          final list = changes['accounts'] as List;
          debugPrint('[ServerSync] Applying ${list.length} accounts...');
          for (final row in list) {
            await _upsertAccount(row as Map<String, dynamic>);
          }
        });
      }
      if (changes.containsKey('asset_entries')) {
        await _database.transaction(() async {
          final list = changes['asset_entries'] as List;
          debugPrint('[ServerSync] Applying ${list.length} asset_entries...');
          debugPrint('[DIAG][ServerSync] PULL: received ${list.length} asset_entries from server. IDs: ${list.take(5).map((r) => (r as Map)['id']).join(', ')}${list.length > 5 ? '...' : ''}');
          for (final row in list) {
            await _upsertAssetEntry(row as Map<String, dynamic>);
          }
        });
      } else {
        debugPrint('[DIAG][ServerSync] PULL: no asset_entries in server response — either no new data or server has nothing newer than lastSync');
      }
      if (changes.containsKey('transactions')) {
        await _database.transaction(() async {
          final list = changes['transactions'] as List;
          debugPrint('[ServerSync] Applying ${list.length} transactions...');
          for (final row in list) {
            await _upsertTransaction(row as Map<String, dynamic>);
          }
        });
      }
      debugPrint('[ServerSync] Pull committed successfully.');
    } finally {
      await _database.customStatement('PRAGMA foreign_keys = ON');
    }
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
    'date': entry.date.toIso8601String(),
    'accountId': entry.accountId,
    'categoryId': entry.categoryId,
    'currencyCode': entry.currencyCode,
    'exchangeRate': entry.exchangeRate,
    'exchangeRatePreset': entry.exchangeRatePreset,
    'fee': _round(entry.fee),
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
        (currencyCode != null && currencyCode.isNotEmpty) ? currencyCode : 'USD';
    final resolvedCurrencyDesignationId =
        (currencyDesignationId != null && currencyDesignationId.isNotEmpty)
            ? currencyDesignationId
            : '';

    await _database.customInsert(
      '''INSERT INTO accounts (id, name, description, balance, currency_code, currency_designation_id, style_id, account_type_id, creation_date, country, asset_id, asset_quantity, fee_structure, modified_at, device_id, is_deleted)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        description = EXCLUDED.description,
        balance = EXCLUDED.balance,
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
        drift_db.Variable.withString(json['name'] as String? ?? 'Untitled Account'),
        drift_db.Variable(json['description'] as String?),
        drift_db.Variable.withReal(_round((json['balance'] as num?)?.toDouble() ?? 0.0)),
        drift_db.Variable.withString(resolvedCurrencyCode),
        drift_db.Variable.withString(resolvedCurrencyDesignationId),
        drift_db.Variable(json['styleId'] as String?),
        drift_db.Variable.withString(json['accountTypeId'] as String? ?? 'account_type_checking'),
        drift_db.Variable.withDateTime(
          DateTime.tryParse(json['creationDate'] as String? ?? '') ?? DateTime.now(),
        ),
        drift_db.Variable(json['country'] as String?),
        drift_db.Variable(json['assetId'] as String?),
        drift_db.Variable.withReal(_round((json['assetQuantity'] as num?)?.toDouble() ?? 0.0)),
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
        (currencyCode != null && currencyCode.isNotEmpty) ? currencyCode : 'USD';

    await _database.customInsert(
      '''INSERT INTO transactions (id, description, amount, date, account_id, category_id, currency_code, exchange_rate, exchange_rate_preset, fee, linked_transaction_id, modified_at, device_id, is_deleted)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT (id) DO UPDATE SET
        description = EXCLUDED.description,
        amount = EXCLUDED.amount,
        date = EXCLUDED.date,
        account_id = EXCLUDED.account_id,
        category_id = EXCLUDED.category_id,
        currency_code = EXCLUDED.currency_code,
        exchange_rate = EXCLUDED.exchange_rate,
        exchange_rate_preset = EXCLUDED.exchange_rate_preset,
        fee = EXCLUDED.fee,
        linked_transaction_id = EXCLUDED.linked_transaction_id,
        modified_at = EXCLUDED.modified_at,
        device_id = EXCLUDED.device_id,
        is_deleted = EXCLUDED.is_deleted
      WHERE EXCLUDED.modified_at > transactions.modified_at''',
      variables: [
        drift_db.Variable.withString(json['id'] as String? ?? ''),
        drift_db.Variable.withString(json['description'] as String? ?? ''),
        drift_db.Variable.withReal(_round((json['amount'] as num?)?.toDouble() ?? 0.0)),
        drift_db.Variable.withDateTime(
          DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        ),
        drift_db.Variable.withString(json['accountId'] as String? ?? ''),
        drift_db.Variable.withString(json['categoryId'] as String? ?? ''),
        drift_db.Variable.withString(resolvedCurrencyCode),
        drift_db.Variable.withReal((json['exchangeRate'] as num?)?.toDouble() ?? 1.0),
        drift_db.Variable(json['exchangeRatePreset'] as int?),
        drift_db.Variable.withReal(_round((json['fee'] as num?)?.toDouble() ?? 0.0)),
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
    final date = DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now();

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
        drift_db.Variable.withReal(_round((json['value'] as num?)?.toDouble() ?? 0.0)),
        drift_db.Variable.withReal(_round((json['quantity'] as num?)?.toDouble() ?? 1.0)),
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
      '''INSERT INTO api_settings_table (id, enabled, auto_fetch, last_fetch_at, modified_at, device_id)
      VALUES (?, ?, ?, ?, ?, ?)
      ON CONFLICT (id) DO UPDATE SET
        enabled = EXCLUDED.enabled,
        auto_fetch = EXCLUDED.auto_fetch,
        last_fetch_at = EXCLUDED.last_fetch_at,
        modified_at = EXCLUDED.modified_at,
        device_id = EXCLUDED.device_id
      WHERE EXCLUDED.modified_at > api_settings_table.modified_at''',
      variables: [
        drift_db.Variable.withString(json['id'] as String? ?? ''),
        drift_db.Variable.withInt(_parseBool(json['enabled']) ? 1 : 0),
        drift_db.Variable.withInt(_parseBool(json['autoFetch']) ? 1 : 0),
        drift_db.Variable(json['lastFetchAt'] as int?),
        drift_db.Variable.withInt(json['modifiedAt'] as int? ?? 1),
        drift_db.Variable(json['deviceId'] as String?),
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
        drift_db.Variable.withString(json['name'] as String? ?? 'Untitled SMS Preset'),
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
    final date = DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now();

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
        drift_db.Variable.withString(json['fromCurrencyCode'] as String? ?? 'USD'),
        drift_db.Variable.withString(json['toCurrencyCode'] as String? ?? 'EUR'),
        drift_db.Variable.withReal(_round((json['rate'] as num?)?.toDouble() ?? 1.0)),
        drift_db.Variable.withInt(json['preset'] as int? ?? 1),
        drift_db.Variable.withDateTime(date),
        drift_db.Variable.withInt(json['modifiedAt'] as int? ?? 1),
        drift_db.Variable(json['deviceId'] as String?),
        drift_db.Variable(json['sourceId'] as String?),
      ],
    );
  }

  Future<void> _upsertInflationRate(Map<String, dynamic> json) async {
    final date = DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now();
    final country = json['country'] as String?;

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
        drift_db.Variable.withReal((json['percent'] as num?)?.toDouble() ?? 0.0),
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
        drift_db.Variable.withString(json['secondaryColorHex'] as String? ?? ''),
        drift_db.Variable.withString(json['surfaceColorHex'] as String? ?? ''),
        drift_db.Variable.withString(json['backgroundColorHex'] as String? ?? ''),
        drift_db.Variable(json['backgroundImagePath'] as String?),
        drift_db.Variable.withReal((json['backgroundImageOpacity'] as num?)?.toDouble() ?? 1.0),
        drift_db.Variable.withReal((json['backgroundImageBlur'] as num?)?.toDouble() ?? 0.0),
        drift_db.Variable.withInt(json['windowEffectType'] as int? ?? 0),
        drift_db.Variable.withReal((json['effectOpacity'] as num?)?.toDouble() ?? 1.0),
        drift_db.Variable.withReal((json['surfaceOpacity'] as num?)?.toDouble() ?? 1.0),
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
