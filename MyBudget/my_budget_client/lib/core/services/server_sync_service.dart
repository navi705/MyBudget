import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:drift/drift.dart' as drift_db;
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/icon_type.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';

class ServerSyncService {
  final AppDatabase _database;
  final SettingsRepository _settingsRepository;
  WebSocketChannel? _channel;
  bool _isSyncingInternal = false;

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

  /// Initialize real-time updates via WebSocket with auto-reconnect
  Future<void> initWebSocket() async {
    if (!await _isEnabled()) return;
    _connectWebSocket();
  }

  Future<void> _connectWebSocket() async {
    try {
      final baseUrl = await _getBaseUrl();
      // Ensure ws:// or wss:// scheme
      final wsParams = baseUrl.replaceFirst(RegExp(r'^http'), 'ws');
      final wsUrl = '$wsParams/ws/sync';

      debugPrint('[ServerSync] Connecting to WebSocket: $wsUrl');

      // Close existing channel if any
      await _channel?.sink.close();

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
        (message) {
          debugPrint('[ServerSync] WS Message: $message');
          if (message == 'sync_available') {
            sync();
          }
        },
        onDone: () {
          debugPrint(
            '[ServerSync] WebSocket disconnected. Reconnecting in 10s...',
          );
          Future.delayed(const Duration(seconds: 10), _connectWebSocket);
        },
        onError: (e) {
          debugPrint(
            '[ServerSync] WebSocket error: $e. Reconnecting in 10s...',
          );
          Future.delayed(const Duration(seconds: 10), _connectWebSocket);
        },
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint(
        '[ServerSync] WebSocket connection setup failed: $e. Retrying in 10s...',
      );
      Future.delayed(const Duration(seconds: 10), _connectWebSocket);
    }
  }

  Timer? _debounceTimer;
  StreamSubscription? _dbSubscription;

  void dispose() {
    _channel?.sink.close();
    _dbSubscription?.cancel();
    _debounceTimer?.cancel();
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
  Future<void> initAutoSync() async {
    if (!await _isEnabled()) return;

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

    debugPrint('[ServerSync] Starting batched pull...');

    while (true) {
      final batchStopwatch = Stopwatch()..start();
      final lastSync = prefs.getInt(lastSyncKey) ?? 0;
      final url = Uri.parse(
        '$baseUrl/api/sync/pull?last_sync=$lastSync&limit=20000',
      );

      debugPrint('[ServerSync] Pulling batch since $lastSync...');

      final fetchStopwatch = Stopwatch()..start();
      final response = await http
          .get(url, headers: {'Authorization': 'Bearer $authToken'})
          .timeout(const Duration(seconds: 180));
      fetchStopwatch.stop();

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final changesMap = body['changes'] as Map<String, dynamic>;
        final serverTimestamp = (body['server_timestamp'] as num).toInt();

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
          '[ServerSync] Applying batch with ${changesMap.length} tables (high mark: $serverTimestamp)...',
        );

        final applyStopwatch = Stopwatch()..start();
        await _applyChanges(changesMap);
        applyStopwatch.stop();

        await prefs.setInt(lastSyncKey, serverTimestamp);

        debugPrint(
          '[PERF] Pull Batch: Fetch ${fetchStopwatch.elapsedMilliseconds}ms, DB Apply ${applyStopwatch.elapsedMilliseconds}ms, Total ${batchStopwatch.elapsedMilliseconds}ms',
        );

        // Infinite loop protection
        if (serverTimestamp <= lastSync) {
          debugPrint(
            '[ServerSync] WARNING: Server timestamp did not advance. Stopping pull loop.',
          );
          break;
        }
      } else {
        debugPrint('[ServerSync] Pull failed body: ${response.body}');
        throw Exception('Pull failed: ${response.statusCode} ${response.body}');
      }
    }
    totalPullStopwatch.stop();
    debugPrint(
      '[PERF] Total Pull: ${totalPullStopwatch.elapsedMilliseconds}ms ($totalDownloaded items)',
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
      await _database.transaction(() async {
        if (changes.containsKey('languages')) {
          final list = changes['languages'] as List;
          debugPrint('[ServerSync] Applying ${list.length} languages...');
          for (final row in list) {
            await _upsertLanguage(row as Map<String, dynamic>);
          }
        }
        if (changes.containsKey('currencies')) {
          final list = changes['currencies'] as List;
          debugPrint('[ServerSync] Applying ${list.length} currencies...');
          for (final row in list) {
            await _upsertCurrency(row as Map<String, dynamic>);
          }
        }
        if (changes.containsKey('settings')) {
          final list = changes['settings'] as List;
          debugPrint('[ServerSync] Applying ${list.length} settings...');
          for (final row in list) {
            await _upsertSetting(row as Map<String, dynamic>);
          }
        }
        if (changes.containsKey('api_settings')) {
          final list = changes['api_settings'] as List;
          debugPrint('[ServerSync] Applying ${list.length} api_settings...');
          for (final row in list) {
            await _upsertApiSetting(row as Map<String, dynamic>);
          }
        }
        if (changes.containsKey('styles')) {
          final list = changes['styles'] as List;
          debugPrint('[ServerSync] Applying ${list.length} styles...');
          for (final row in list) {
            await _upsertStyle(row as Map<String, dynamic>);
          }
        }
        if (changes.containsKey('custom_themes')) {
          final list = changes['custom_themes'] as List;
          debugPrint('[ServerSync] Applying ${list.length} custom_themes...');
          for (final row in list) {
            await _upsertCustomTheme(row as Map<String, dynamic>);
          }
        }
        if (changes.containsKey('account_types')) {
          final list = changes['account_types'] as List;
          debugPrint('[ServerSync] Applying ${list.length} account_types...');
          for (final row in list) {
            await _upsertAccountType(row as Map<String, dynamic>);
          }
        }
        if (changes.containsKey('currency_designations')) {
          final list = changes['currency_designations'] as List;
          debugPrint(
            '[ServerSync] Applying ${list.length} currency_designations...',
          );
          for (final row in list) {
            await _upsertCurrencyDesignation(row as Map<String, dynamic>);
          }
        }
        if (changes.containsKey('categories')) {
          final list = changes['categories'] as List;
          debugPrint('[ServerSync] Applying ${list.length} categories...');
          for (final row in list) {
            await _upsertCategory(row as Map<String, dynamic>);
          }
        }
        if (changes.containsKey('exchange_rates')) {
          final list = changes['exchange_rates'] as List;
          debugPrint('[ServerSync] Applying ${list.length} exchange_rates...');
          for (final row in list) {
            await _upsertExchangeRate(row as Map<String, dynamic>);
          }
        }
        if (changes.containsKey('inflation_rates')) {
          final list = changes['inflation_rates'] as List;
          debugPrint('[ServerSync] Applying ${list.length} inflation_rates...');
          for (final row in list) {
            await _upsertInflationRate(row as Map<String, dynamic>);
          }
        }
        if (changes.containsKey('custom_data_sources')) {
          final list = changes['custom_data_sources'] as List;
          debugPrint(
            '[ServerSync] Applying ${list.length} custom_data_sources...',
          );
          for (final row in list) {
            await _upsertCustomDataSource(row as Map<String, dynamic>);
          }
        }
        if (changes.containsKey('sms_presets')) {
          final list = changes['sms_presets'] as List;
          debugPrint('[ServerSync] Applying ${list.length} sms_presets...');
          for (final row in list) {
            await _upsertSmsPreset(row as Map<String, dynamic>);
          }
        }

        // Dependent Tables (Accounts rely on Styles, Types, Currencies)
        if (changes.containsKey('accounts')) {
          final list = changes['accounts'] as List;
          debugPrint('[ServerSync] Applying ${list.length} accounts...');
          for (final row in list) {
            await _upsertAccount(row as Map<String, dynamic>);
          }
        }

        // Highly Dependent Tables (Transactions/Assets rely on Accounts)
        if (changes.containsKey('asset_entries')) {
          final list = changes['asset_entries'] as List;
          debugPrint('[ServerSync] Applying ${list.length} asset_entries...');
          for (final row in list) {
            await _upsertAssetEntry(row as Map<String, dynamic>);
          }
        }
        if (changes.containsKey('transactions')) {
          final list = changes['transactions'] as List;
          debugPrint('[ServerSync] Applying ${list.length} transactions...');
          for (final row in list) {
            await _upsertTransaction(row as Map<String, dynamic>);
          }
        }
      });
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
    'balance': e.balance,
    'currencyCode': e.currencyCode,
    'currencyDesignationId': e.currencyDesignationId,
    'styleId': e.styleId,
    'accountTypeId': e.accountTypeId,
    'creationDate': e.creationDate.toIso8601String(),
    'country': e.country,
    'assetId': e.assetId,
    'assetQuantity': e.assetQuantity,
    'feeStructure': e.feeStructure,
    'modifiedAt': e.modifiedAt,
    'deviceId': e.deviceId,
    'isDeleted': e.isDeleted,
  };

  Map<String, dynamic> _transactionToJson(Transaction entry) => {
    'id': entry.id,
    'description': entry.description,
    'amount': entry.amount,
    'date': entry.date.toIso8601String(),
    'accountId': entry.accountId,
    'categoryId': entry.categoryId,
    'currencyCode': entry.currencyCode,
    'exchangeRate': entry.exchangeRate,
    'exchangeRatePreset': entry.exchangeRatePreset,
    'fee': entry.fee,
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
    'value': e.value,
    'quantity': e.quantity,
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
    'rate': e.rate,
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

  Future<void> _upsertLanguage(Map<String, dynamic> json) async {
    final companion = LanguagesCompanion(
      languageCode: drift_db.Value(json['languageCode'] as String? ?? 'en'),
      language: drift_db.Value(json['language'] as String? ?? 'English'),
      modifiedAt: drift_db.Value(json['modifiedAt'] as int? ?? 1),
      deviceId: drift_db.Value(json['deviceId'] as String?),
    );
    await _database.into(_database.languages).insertOnConflictUpdate(companion);
  }

  Future<void> _upsertCurrency(Map<String, dynamic> json) async {
    final companion = CurrenciesCompanion(
      code: drift_db.Value(json['code'] as String? ?? 'USD'),
      name: drift_db.Value(json['name'] as String? ?? 'US Dollar'),
      languageCode: drift_db.Value(json['languageCode'] as String? ?? 'en'),
      type: drift_db.Value(TypeCurrency.values[json['type'] as int? ?? 0]),
      modifiedAt: drift_db.Value(json['modifiedAt'] as int? ?? 1),
      deviceId: drift_db.Value(json['deviceId'] as String?),
    );
    await _database
        .into(_database.currencies)
        .insertOnConflictUpdate(companion);
  }

  Future<void> _upsertStyle(Map<String, dynamic> json) async {
    final companion = StylesCompanion(
      id: drift_db.Value(json['id'] as String? ?? ''),
      name: drift_db.Value(json['name'] as String? ?? ''),
      colorHex: drift_db.Value(json['colorHex'] as String? ?? ''),
      iconName: drift_db.Value(json['iconName'] as String? ?? ''),
      iconType: drift_db.Value(IconType.values[json['iconType'] as int? ?? 0]),
      modifiedAt: drift_db.Value(json['modifiedAt'] as int? ?? 1),
      deviceId: drift_db.Value(json['deviceId'] as String?),
      isDeleted: drift_db.Value(_parseBool(json['isDeleted'])),
    );
    await _database.into(_database.styles).insertOnConflictUpdate(companion);
  }

  Future<void> _upsertAccountType(Map<String, dynamic> json) async {
    final companion = AccountTypesCompanion(
      id: drift_db.Value(json['id'] as String? ?? ''),
      name: drift_db.Value(json['name'] as String? ?? ''),
      languageCode: drift_db.Value(json['languageCode'] as String? ?? 'en'),
      modifiedAt: drift_db.Value(json['modifiedAt'] as int? ?? 1),
      deviceId: drift_db.Value(json['deviceId'] as String?),
      isDeleted: drift_db.Value(_parseBool(json['isDeleted'])),
    );
    await _database
        .into(_database.accountTypes)
        .insertOnConflictUpdate(companion);
  }

  Future<void> _upsertCurrencyDesignation(Map<String, dynamic> json) async {
    final companion = CurrencyDesignationsCompanion(
      id: drift_db.Value(json['id'] as String? ?? ''),
      value: drift_db.Value(json['value'] as String? ?? ''),
      currencyCode: drift_db.Value(json['currencyCode'] as String? ?? 'USD'),
      modifiedAt: drift_db.Value(json['modifiedAt'] as int? ?? 1),
      deviceId: drift_db.Value(json['deviceId'] as String?),
      isDeleted: drift_db.Value(_parseBool(json['isDeleted'])),
    );
    await _database
        .into(_database.currencyDesignations)
        .insertOnConflictUpdate(companion);
  }

  Future<void> _upsertCategory(Map<String, dynamic> json) async {
    final companion = CategoriesCompanion(
      id: drift_db.Value(json['id'] as String? ?? ''),
      name: drift_db.Value(json['name'] as String? ?? ''),
      parentId: drift_db.Value(json['parentId'] as String?),
      styleId: drift_db.Value(json['styleId'] as String?),
      type: drift_db.Value(CategoryType.values[json['type'] as int? ?? 0]),
      modifiedAt: drift_db.Value(json['modifiedAt'] as int? ?? 1),
      deviceId: drift_db.Value(json['deviceId'] as String?),
      isDeleted: drift_db.Value(_parseBool(json['isDeleted'])),
    );
    await _database
        .into(_database.categories)
        .insertOnConflictUpdate(companion);
  }

  Future<void> _upsertAccount(Map<String, dynamic> json) async {
    final companion = AccountsCompanion(
      id: drift_db.Value(json['id'] as String? ?? ''),
      name: drift_db.Value(json['name'] as String? ?? 'Untitled Account'),
      description: drift_db.Value(json['description'] as String?),
      balance: drift_db.Value((json['balance'] as num?)?.toDouble() ?? 0.0),
      currencyCode: drift_db.Value(json['currencyCode'] as String? ?? 'USD'),
      currencyDesignationId: drift_db.Value(
        json['currencyDesignationId'] as String? ?? '',
      ),
      styleId: drift_db.Value(json['styleId'] as String?),
      accountTypeId: drift_db.Value(
        json['accountTypeId'] as String? ?? 'account_type_checking',
      ),
      creationDate: drift_db.Value(
        DateTime.tryParse(json['creationDate'] as String? ?? '') ??
            DateTime.now(),
      ),
      country: drift_db.Value(json['country'] as String?),
      assetId: drift_db.Value(json['assetId'] as String?),
      assetQuantity: drift_db.Value(
        (json['assetQuantity'] as num?)?.toDouble() ?? 0.0,
      ),
      feeStructure: drift_db.Value(json['feeStructure'] as String?),
      modifiedAt: drift_db.Value(json['modifiedAt'] as int? ?? 1),
      deviceId: drift_db.Value(json['deviceId'] as String?),
      isDeleted: drift_db.Value(_parseBool(json['isDeleted'])),
    );
    await _database.into(_database.accounts).insertOnConflictUpdate(companion);
  }

  Future<void> _upsertTransaction(Map<String, dynamic> json) async {
    final companion = TransactionsCompanion(
      id: drift_db.Value(json['id'] as String? ?? ''),
      description: drift_db.Value(json['description'] as String? ?? ''),
      amount: drift_db.Value((json['amount'] as num?)?.toDouble() ?? 0.0),
      date: drift_db.Value(
        DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      ),
      accountId: drift_db.Value(json['accountId'] as String? ?? ''),
      categoryId: drift_db.Value(json['categoryId'] as String? ?? ''),
      currencyCode: drift_db.Value(json['currencyCode'] as String? ?? 'USD'),
      exchangeRate: drift_db.Value(
        (json['exchangeRate'] as num?)?.toDouble() ?? 1.0,
      ),
      exchangeRatePreset: drift_db.Value(json['exchangeRatePreset'] as int?),
      fee: drift_db.Value((json['fee'] as num?)?.toDouble() ?? 0.0),
      linkedTransactionId: drift_db.Value(
        json['linkedTransactionId'] as String?,
      ),
      modifiedAt: drift_db.Value(json['modifiedAt'] as int? ?? 1),
      deviceId: drift_db.Value(json['deviceId'] as String?),
      isDeleted: drift_db.Value(_parseBool(json['isDeleted'])),
    );
    await _database
        .into(_database.transactions)
        .insertOnConflictUpdate(companion);
  }

  Future<void> _upsertAssetEntry(Map<String, dynamic> json) async {
    final companion = AssetEntriesCompanion(
      id: drift_db.Value(json['id'] as String? ?? ''),
      assetId: drift_db.Value(json['assetId'] as String? ?? ''),
      name: drift_db.Value(json['name'] as String? ?? ''),
      date: drift_db.Value(
        DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      ),
      value: drift_db.Value((json['value'] as num?)?.toDouble() ?? 0.0),
      quantity: drift_db.Value((json['quantity'] as num?)?.toDouble() ?? 1.0),
      assetType: drift_db.Value(json['assetType'] as String?),
      description: drift_db.Value(json['description'] as String?),
      currencyCode: drift_db.Value(json['currencyCode'] as String? ?? 'USD'),
      accountId: drift_db.Value(json['accountId'] as String?),
      source: drift_db.Value(json['source'] as String? ?? 'manual'),
      preset: drift_db.Value(json['preset'] as int? ?? 1),
      modifiedAt: drift_db.Value(json['modifiedAt'] as int? ?? 1),
      deviceId: drift_db.Value(json['deviceId'] as String?),
      sourceId: drift_db.Value(json['sourceId'] as String?),
      isDeleted: drift_db.Value(_parseBool(json['isDeleted'])),
    );
    await _database
        .into(_database.assetEntries)
        .insertOnConflictUpdate(companion);
  }

  Future<void> _upsertCustomDataSource(Map<String, dynamic> json) async {
    final companion = CustomDataSourcesCompanion(
      id: drift_db.Value(json['id'] as String? ?? ''),
      name: drift_db.Value(json['name'] as String? ?? ''),
      url: drift_db.Value(json['url'] as String? ?? ''),
      dataType: drift_db.Value(json['dataType'] as int? ?? 0),
      enabled: drift_db.Value(_parseBool(json['enabled'])),
      autoFetch: drift_db.Value(_parseBool(json['autoFetch'])),
      lastFetchAt: drift_db.Value(json['lastFetchAt'] as int?),
      modifiedAt: drift_db.Value(json['modifiedAt'] as int? ?? 1),
      deviceId: drift_db.Value(json['deviceId'] as String?),
      isDeleted: drift_db.Value(_parseBool(json['isDeleted'])),
    );
    await _database
        .into(_database.customDataSources)
        .insertOnConflictUpdate(companion);
  }

  Future<void> _upsertApiSetting(Map<String, dynamic> json) async {
    final companion = ApiSettingsTableCompanion(
      id: drift_db.Value(json['id'] as String? ?? ''),
      enabled: drift_db.Value(_parseBool(json['enabled'])),
      autoFetch: drift_db.Value(_parseBool(json['autoFetch'])),
      lastFetchAt: drift_db.Value(json['lastFetchAt'] as int?),
      modifiedAt: drift_db.Value(json['modifiedAt'] as int? ?? 1),
      deviceId: drift_db.Value(json['deviceId'] as String?),
    );
    await _database
        .into(_database.apiSettingsTable)
        .insertOnConflictUpdate(companion);
  }

  Future<void> _upsertSmsPreset(Map<String, dynamic> json) async {
    final companion = SmsPresetsCompanion(
      id: drift_db.Value(json['id'] as String? ?? ''),
      name: drift_db.Value(json['name'] as String? ?? 'Untitled SMS Preset'),
      senderFilter: drift_db.Value(json['senderFilter'] as String? ?? ''),
      isBuiltIn: drift_db.Value(_parseBool(json['isBuiltIn'])),
      isEnabled: drift_db.Value(_parseBool(json['isEnabled'])),
      defaultAccountId: drift_db.Value(json['defaultAccountId'] as String?),
      defaultCategoryId: drift_db.Value(json['defaultCategoryId'] as String?),
      rulesJson: drift_db.Value(json['rulesJson'] as String? ?? '[]'),
      modifiedAt: drift_db.Value(json['modifiedAt'] as int? ?? 1),
      deviceId: drift_db.Value(json['deviceId'] as String?),
      isDeleted: drift_db.Value(_parseBool(json['isDeleted'])),
    );
    await _database
        .into(_database.smsPresets)
        .insertOnConflictUpdate(companion);
  }

  Future<void> _upsertSetting(Map<String, dynamic> json) async {
    final companion = SettingsCompanion(
      key: drift_db.Value(json['key'] as String? ?? ''),
      value: drift_db.Value(json['value'] as String? ?? ''),
      device: drift_db.Value(json['device'] as String?),
      modifiedAt: drift_db.Value(json['modifiedAt'] as int? ?? 1),
      deviceId: drift_db.Value(json['deviceId'] as String?),
    );
    await _database.into(_database.settings).insertOnConflictUpdate(companion);
  }

  Future<void> _upsertExchangeRate(Map<String, dynamic> json) async {
    final companion = ExchangeRatesCompanion(
      fromCurrencyCode: drift_db.Value(
        json['fromCurrencyCode'] as String? ?? 'USD',
      ),
      toCurrencyCode: drift_db.Value(
        json['toCurrencyCode'] as String? ?? 'EUR',
      ),
      rate: drift_db.Value((json['rate'] as num?)?.toDouble() ?? 1.0),
      preset: drift_db.Value(json['preset'] as int? ?? 1),
      date: drift_db.Value(
        DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      ),
      modifiedAt: drift_db.Value(json['modifiedAt'] as int? ?? 1),
      deviceId: drift_db.Value(json['deviceId'] as String?),
      sourceId: drift_db.Value(json['sourceId'] as String?),
    );
    await _database
        .into(_database.exchangeRates)
        .insertOnConflictUpdate(companion);
  }

  Future<void> _upsertInflationRate(Map<String, dynamic> json) async {
    final companion = InflationRatesCompanion(
      date: drift_db.Value(
        DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      ),
      percent: drift_db.Value((json['percent'] as num?)?.toDouble() ?? 0.0),
      country: drift_db.Value(json['country']),
      preset: drift_db.Value(json['preset']),
      modifiedAt: drift_db.Value(json['modifiedAt']),
      deviceId: drift_db.Value(json['deviceId']),
      sourceId: drift_db.Value(json['sourceId']),
    );
    await _database
        .into(_database.inflationRates)
        .insertOnConflictUpdate(companion);
  }

  Future<void> _upsertCustomTheme(Map<String, dynamic> json) async {
    final companion = CustomThemesCompanion(
      id: drift_db.Value(json['id'] as String? ?? ''),
      name: drift_db.Value(json['name'] as String? ?? 'Custom Theme'),
      primaryColorHex: drift_db.Value(json['primaryColorHex'] as String? ?? ''),
      secondaryColorHex: drift_db.Value(
        json['secondaryColorHex'] as String? ?? '',
      ),
      surfaceColorHex: drift_db.Value(json['surfaceColorHex'] as String? ?? ''),
      backgroundColorHex: drift_db.Value(
        json['backgroundColorHex'] as String? ?? '',
      ),
      backgroundImagePath: drift_db.Value(
        json['backgroundImagePath'] as String?,
      ),
      backgroundImageOpacity: drift_db.Value(
        (json['backgroundImageOpacity'] as num?)?.toDouble() ?? 1.0,
      ),
      backgroundImageBlur: drift_db.Value(
        (json['backgroundImageBlur'] as num?)?.toDouble() ?? 0.0,
      ),
      windowEffectType: drift_db.Value(json['windowEffectType'] as int? ?? 0),
      effectOpacity: drift_db.Value(
        (json['effectOpacity'] as num?)?.toDouble() ?? 1.0,
      ),
      surfaceOpacity: drift_db.Value(
        (json['surfaceOpacity'] as num?)?.toDouble() ?? 1.0,
      ),
      themeMode: drift_db.Value(json['themeMode'] as int? ?? 0),
      isPreset: drift_db.Value(_parseBool(json['isPreset'])),
      isActive: drift_db.Value(_parseBool(json['isActive'])),
      modifiedAt: drift_db.Value(json['modifiedAt'] as int? ?? 1),
      deviceId: drift_db.Value(json['deviceId'] as String?),
      isDeleted: drift_db.Value(_parseBool(json['isDeleted'])),
    );
    await _database
        .into(_database.customThemes)
        .insertOnConflictUpdate(companion);
  }

  bool _parseBool(dynamic val) {
    if (val is bool) return val;
    if (val is int) return val == 1;
    return false;
  }
}
