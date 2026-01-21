import 'dart:io';
import 'package:postgres/postgres.dart';

class DatabaseClient {
  late final Pool _pool;

  DatabaseClient() {
    final dbUrl = Platform.environment['DATABASE_URL'] ??
        'postgres://postgres:postgres@localhost:5432/my_budget';

    final uri = Uri.parse(dbUrl);
    final userInfo = uri.userInfo.split(':');
    final username = userInfo.isNotEmpty ? userInfo[0] : 'postgres';
    final password = userInfo.length > 1 ? userInfo[1] : 'postgres';

    _pool = Pool.withEndpoints(
      [
        Endpoint(
          host: uri.host,
          port: uri.port,
          database:
              uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'my_budget',
          username: username,
          password: password,
        )
      ],
      settings: PoolSettings(
        sslMode: SslMode.disable, // internal docker net usually safe/plain
      ),
    );
  }

  Pool get pool => _pool;

  Future<void> close() => _pool.close();

  // Method to initialize schema to be called on startup
  Future<void> ensureSchema() async {
    await _pool.execute('''
      CREATE TABLE IF NOT EXISTS api_keys (
        key TEXT PRIMARY KEY,
        device_id TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    ''');

    await _pool.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id TEXT PRIMARY KEY,
        name TEXT,
        parent_id TEXT,
        style_id TEXT,
        type INTEGER,
        modified_at BIGINT DEFAULT 0,
        device_id TEXT,
        is_deleted BOOLEAN DEFAULT FALSE
      );
    ''');

    await _pool.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id TEXT PRIMARY KEY,
        description TEXT,
        amount REAL,
        date TIMESTAMP,
        account_id TEXT,
        category_id TEXT,
        currency_code TEXT,
        exchange_rate REAL,
        exchange_rate_preset INTEGER,
        fee REAL,
        linked_transaction_id TEXT,
        modified_at BIGINT DEFAULT 0,
        device_id TEXT,
        is_deleted BOOLEAN DEFAULT FALSE
      );
    ''');

    // Create other tables similarly as needed
    // For now, this proves connectivity and setup
  }
}
