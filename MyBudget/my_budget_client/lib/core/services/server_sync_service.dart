import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:drift/drift.dart' as drift_db;
import 'package:my_budget_client/core/database/app_database.dart'; // contains Category
import 'package:shared_preferences/shared_preferences.dart';

class ServerSyncService {
  final AppDatabase _database;
  final String _baseUrl;
  WebSocketChannel? _channel;

  // TODO: Move to secure storage or settings
  static const String _authToken = 'dev_token';

  ServerSyncService({
    required AppDatabase database,
    // Default to localhost for Windows dev, strictly for now.
    // In production, this should be configurable.
    String baseUrl = 'http://localhost:8080',
  }) : _database = database,
       _baseUrl = baseUrl;

  /// Main entry point to sync data.
  /// 1. PULL changes from server
  /// 2. PUSH local changes to server
  Future<void> sync() async {
    try {
      debugPrint('[ServerSync] Starting sync...');
      await _pull();
      await _push();
      debugPrint('[ServerSync] Sync completed.');
    } catch (e) {
      debugPrint('[ServerSync] Error: $e');
      rethrow;
    }
  }

  /// Initialize real-time updates via WebSocket
  void initWebSocket() {
    try {
      final wsUrl = _baseUrl.replaceFirst('http', 'ws') + '/ws/sync';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel?.stream.listen((message) {
        debugPrint('[ServerSync] WS Message: $message');
        // TODO: Handle "sync_available" message to trigger sync()
        if (message == 'sync_available') {
          sync();
        }
      });
      debugPrint('[ServerSync] WebSocket connected to $wsUrl');
    } catch (e) {
      debugPrint('[ServerSync] WebSocket Error: $e');
    }
  }

  void dispose() {
    _channel?.sink.close();
  }

  Future<void> _pull() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncKey = 'server_last_sync_timestamp';
    final lastSync = prefs.getInt(lastSyncKey) ?? 0;

    final url = Uri.parse('$_baseUrl/api/sync/pull?last_sync=$lastSync');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $_authToken'},
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final changes = body['changes'] as Map<String, dynamic>;
      final serverTimestamp = body['server_timestamp'] as int;

      await _applyChanges(changes);

      await prefs.setInt(lastSyncKey, serverTimestamp);
      debugPrint(
        '[ServerSync] Pull successful. New timestamp: $serverTimestamp',
      );
    } else {
      throw Exception('Pull failed: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> _push() async {
    // 1. Gather local changes (modified_at > last_push or marked as dirty)
    // For this MVP, we might need a way to track what has been pushed.
    // Or we scan all records where modified_at > last_push_timestamp.

    // Simplification: We pushed everything modified "recently" or we just rely on the server
    // handling idempotency if we push redundant data.
    // Better approach: locally track `last_push_timestamp`.

    final prefs = await SharedPreferences.getInstance();
    final lastPushKey = 'server_last_push_timestamp';
    final lastPush = prefs.getInt(lastPushKey) ?? 0;

    // Fetch local data modified since lastPush
    // We need DAOs for this. Assuming we can query the DB.
    // This part requires accessing table DAOs directly or writing a helper in AppDatabase.

    // For now, let's assume we have a helper explicitly for getting sync data.
    // Placeholder logic:
    final payload = await _gatherLocalChanges(lastPush);

    if (payload.isEmpty) {
      debugPrint('[ServerSync] Nothing to push.');
      return;
    }

    final url = Uri.parse('$_baseUrl/api/sync/push');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_authToken',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final serverTimestamp = body['timestamp'] as int; // or just use response
      await prefs.setInt(lastPushKey, serverTimestamp);
      debugPrint('[ServerSync] Push successful. Timestamp: $serverTimestamp');
    } else {
      throw Exception('Push failed: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> _applyChanges(Map<String, dynamic> changes) async {
    // Apply changes transactionally
    await _database.transaction(() async {
      if (changes.containsKey('categories')) {
        final rows = changes['categories'] as List;
        for (final row in rows) {
          // Upsert category
          // Mapping required from JSON to Drift types
          await _upsertCategory(row as Map<String, dynamic>);
        }
      }
      if (changes.containsKey('transactions')) {
        final rows = changes['transactions'] as List;
        for (final row in rows) {
          await _upsertTransaction(row as Map<String, dynamic>);
        }
      }
    });
  }

  // Helpers to gather data (needs DB access)
  Future<Map<String, dynamic>> _gatherLocalChanges(int lastPush) async {
    // Access DB tables.
    // Drift tables: _database.categories, _database.transactions

    final categories = await (_database.select(
      _database.categories,
    )..where((t) => t.modifiedAt.isBiggerThanValue(lastPush))).get();

    final transactions = await (_database.select(
      _database.transactions,
    )..where((t) => t.modifiedAt.isBiggerThanValue(lastPush))).get();

    if (categories.isEmpty && transactions.isEmpty) return {};

    return {
      'categories': categories.map((e) => _categoryToJson(e)).toList(),
      'transactions': transactions.map((e) => _transactionToJson(e)).toList(),
    };
  }

  Map<String, dynamic> _categoryToJson(Category entry) {
    return {
      'id': entry.id,
      'name': entry.name,
      'parentId': entry.parentId,
      'styleId': entry.styleId,
      'type': entry.type,
      'modifiedAt': entry.modifiedAt,
      'deviceId': entry.deviceId,
      'isDeleted': entry.isDeleted,
    };
  }

  Map<String, dynamic> _transactionToJson(Transaction entry) {
    return {
      'id': entry.id,
      'description': entry.description,
      'amount': entry.amount,
      'date': entry.date.toIso8601String(), // Send as ISO string
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
  }

  Future<void> _upsertCategory(Map<String, dynamic> json) async {
    // Drift generated classes: Category
    // We need to create a Companion for insert/update
    // Note: JSON keys must match what we expect. Server sends what we defined in SyncRepository (camelCase mapped).

    final companion = CategoriesCompanion.insert(
      id: json['id'],
      name: json['name'],
      parentId: drift_db.Value(json['parentId']),
      styleId: drift_db.Value(json['styleId']),
      type: drift_db.Value(json['type']),
      modifiedAt: drift_db.Value(json['modifiedAt']),
      deviceId: drift_db.Value(json['deviceId']),
      isDeleted: drift_db.Value(
        json['isDeleted'] is bool ? json['isDeleted'] : json['isDeleted'] == 1,
      ),
    );

    await _database
        .into(_database.categories)
        .insertOnConflictUpdate(companion);
  }

  Future<void> _upsertTransaction(Map<String, dynamic> json) async {
    final companion = TransactionsCompanion.insert(
      id: json['id'],
      description: json['description'],
      amount: json['amount'],
      date: DateTime.parse(json['date']),
      accountId: json['accountId'],
      categoryId: json['categoryId'],
      currencyCode: json['currencyCode'],
      exchangeRate: drift_db.Value(json['exchangeRate']),
      exchangeRatePreset: drift_db.Value(json['exchangeRatePreset']),
      fee: drift_db.Value(json['fee']),
      linkedTransactionId: drift_db.Value(json['linkedTransactionId']),
      modifiedAt: drift_db.Value(json['modifiedAt']),
      deviceId: drift_db.Value(json['deviceId']),
      isDeleted: drift_db.Value(
        json['isDeleted'] is bool ? json['isDeleted'] : json['isDeleted'] == 1,
      ),
    );

    await _database
        .into(_database.transactions)
        .insertOnConflictUpdate(companion);
  }
}
