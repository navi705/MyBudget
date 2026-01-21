import 'package:postgres/postgres.dart';
import 'package:my_budget_server/data/database_client.dart';

class SyncRepository {
  final DatabaseClient _dbClient;

  SyncRepository(this._dbClient);

  Future<void> upsertBatch(Map<String, dynamic> data) async {
    // data structure: { 'categories': [ {id: '...', ...}, ... ], 'transactions': ... }

    // We can use a transaction for atomicity?
    // Note: Pool.runTx is deprecated in v3, use run(txn => ...)
    // Wait, v3 uses .runTx or similar depending on minor version.
    // Checking docs: connection.runTx((Session session) async { ... })
    // Actually, usually `pool.runTx` wrapper exists or we use `pool.withConnection`.
    // Let's assume loose operations for now or simple batching.

    // For 'categories'
    if (data.containsKey('categories')) {
      final rows = data['categories'] as List;
      for (final row in rows) {
        // row is Map<String, dynamic>
        // We need to construct INSERT ON CONFLICT
        // This is tedious to do manually for every field.
        // Let's implement a simple helper for 'Categories' specifically first.
        await _upsertCategory(row as Map<String, dynamic>);
      }
    }

    if (data.containsKey('transactions')) {
      final rows = data['transactions'] as List;
      for (final row in rows) {
        await _upsertTransaction(row as Map<String, dynamic>);
      }
    }
  }

  Future<void> _upsertCategory(Map<String, dynamic> row) async {
    // Extract fields
    // We assume field names match DB columns for simplicity, or map them.
    // Client JSON likely matches Drift columns: id, name, parentId, etc. (camelCase)
    // DB columns are snake_case in standard SQL, but I defined them as snake_case in EnsureSchema?
    // Wait, in `ensureSchema` I used snake_case for DB columns: `parent_id`, `style_id`.
    // Drift usually uses camelCase for Dart headers but snake_case for SQL columns.
    // I need to map JSON camelCase to DB snake_case.

    final sql = '''
      INSERT INTO categories (id, name, parent_id, style_id, type, modified_at, device_id, is_deleted)
      VALUES (@id, @name, @parentId, @styleId, @type, @modifiedAt, @deviceId, @isDeleted)
      ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        parent_id = EXCLUDED.parent_id,
        style_id = EXCLUDED.style_id,
        type = EXCLUDED.type,
        modified_at = EXCLUDED.modified_at,
        device_id = EXCLUDED.device_id,
        is_deleted = EXCLUDED.is_deleted
      WHERE EXCLUDED.modified_at > categories.modified_at
    ''';

    await _dbClient.pool.execute(Sql.named(sql), parameters: {
      'id': row['id'],
      'name': row['name'],
      'parentId': row['parentId'], // JSON key
      'styleId': row['styleId'],
      'type': row['type'],
      'modifiedAt': row['modifiedAt'],
      'deviceId': row['deviceId'],
      'isDeleted':
          row['isDeleted'] is bool ? row['isDeleted'] : (row['isDeleted'] == 1),
    });
  }

  Future<void> _upsertTransaction(Map<String, dynamic> row) async {
    final sql = '''
      INSERT INTO transactions (id, description, amount, date, account_id, category_id, currency_code, exchange_rate, exchange_rate_preset, fee, linked_transaction_id, modified_at, device_id, is_deleted)
      VALUES (@id, @description, @amount, @date, @accountId, @categoryId, @currencyCode, @exchangeRate, @exchangeRatePreset, @fee, @linkedTransactionId, @modifiedAt, @deviceId, @isDeleted)
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
      WHERE EXCLUDED.modified_at > transactions.modified_at
    ''';

    // Date handling: Client sends ISO string? or int? Drift DateTimeColumn.
    // Drift usually serializes as int (millis) or ISO string depending on config.
    // I'll assume ISO string if JSON, or int. Postgres wants DateTime object or specialized string.
    dynamic dateVal = row['date'];
    if (dateVal is int) {
      dateVal = DateTime.fromMillisecondsSinceEpoch(dateVal);
    } else if (dateVal is String) {
      dateVal = DateTime.parse(dateVal);
    }

    await _dbClient.pool.execute(Sql.named(sql), parameters: {
      'id': row['id'],
      'description': row['description'],
      'amount': row['amount'],
      'date': dateVal,
      'accountId': row['accountId'],
      'categoryId': row['categoryId'],
      'currencyCode': row['currencyCode'],
      'exchangeRate': row['exchangeRate'],
      'exchangeRatePreset': row['exchangeRatePreset'],
      'fee': row['fee'],
      'linkedTransactionId': row['linkedTransactionId'],
      'modifiedAt': row['modifiedAt'],
      'deviceId': row['deviceId'],
      'isDeleted':
          row['isDeleted'] is bool ? row['isDeleted'] : (row['isDeleted'] == 1),
    });
  }

  Future<Map<String, List<Map<String, dynamic>>>> getChanges(
      int lastSync) async {
    final changes = <String, List<Map<String, dynamic>>>{};

    // Fetch Categories
    final catResult = await _dbClient.pool.execute(
      Sql.named('SELECT * FROM categories WHERE modified_at > @lastSync'),
      parameters: {'lastSync': lastSync},
    );
    changes['categories'] = _mapResult(catResult, {
      'parent_id': 'parentId',
      'style_id': 'styleId',
      'modified_at': 'modifiedAt',
      'device_id': 'deviceId',
      'is_deleted': 'isDeleted'
    });

    // Fetch Transactions
    final txResult = await _dbClient.pool.execute(
      Sql.named('SELECT * FROM transactions WHERE modified_at > @lastSync'),
      parameters: {'lastSync': lastSync},
    );
    changes['transactions'] = _mapResult(txResult, {
      'account_id': 'accountId',
      'category_id': 'categoryId',
      'currency_code': 'currencyCode',
      'exchange_rate': 'exchangeRate',
      'exchange_rate_preset': 'exchangeRatePreset',
      'linked_transaction_id': 'linkedTransactionId',
      'modified_at': 'modifiedAt',
      'device_id': 'deviceId',
      'is_deleted': 'isDeleted'
    });

    return changes;
  }

  // Helper to map DB row (snake_case) to JSON (camelCase or whatever client expects)
  List<Map<String, dynamic>> _mapResult(
      Result result, Map<String, String> columnMap) {
    return result.map((row) {
      final map = <String, dynamic>{};
      // row.toColumnMap() returns { 'id': val, 'parent_id': val }
      // We want to transform keys.
      final colMap = row.toColumnMap();
      colMap.forEach((key, value) {
        final newKey = columnMap[key] ?? key;
        // Handle types if needed (DateTime to int/String)
        if (value is DateTime) {
          map[newKey] =
              value.millisecondsSinceEpoch; // Client likely expects int or ISO
        } else {
          map[newKey] = value;
        }
      });
      return map;
    }).toList();
  }
}
