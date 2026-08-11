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
    print('[DB] Initializing database schema...');
    try {
      await _pool.execute('''
      CREATE TABLE IF NOT EXISTS languages (
        language_code TEXT PRIMARY KEY,
        language TEXT,
        modified_at BIGINT DEFAULT 0,
        device_id TEXT
      );
    ''');

      await _pool.execute('''
      CREATE TABLE IF NOT EXISTS currencies (
        code TEXT PRIMARY KEY,
        name TEXT,
        language_code TEXT,
        type INTEGER,
        modified_at BIGINT DEFAULT 0,
        device_id TEXT
      );
    ''');

      // Migration helpers for existing DBs
      try {
        await _pool.execute(
            'ALTER TABLE currencies ADD COLUMN IF NOT EXISTS modified_at BIGINT DEFAULT 0');
        await _pool.execute(
            'ALTER TABLE currencies ADD COLUMN IF NOT EXISTS device_id TEXT');
      } catch (_) {}

      await _pool.execute('''
      CREATE TABLE IF NOT EXISTS styles (
        id TEXT PRIMARY KEY,
        name TEXT,
        color_hex TEXT,
        icon_name TEXT,
        icon_type INTEGER,
        modified_at BIGINT DEFAULT 0,
        device_id TEXT,
        is_deleted BOOLEAN DEFAULT FALSE
      );
    ''');

      await _pool.execute('''
      CREATE TABLE IF NOT EXISTS account_types (
        id TEXT PRIMARY KEY,
        name TEXT,
        language_code TEXT,
        modified_at BIGINT DEFAULT 0,
        device_id TEXT,
        is_deleted BOOLEAN DEFAULT FALSE
      );
    ''');

      await _pool.execute('''
      CREATE TABLE IF NOT EXISTS currency_designations (
        id TEXT PRIMARY KEY,
        value TEXT,
        currency_code TEXT,
        modified_at BIGINT DEFAULT 0,
        device_id TEXT,
        is_deleted BOOLEAN DEFAULT FALSE
      );
    ''');

      await _pool.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id TEXT PRIMARY KEY,
        name TEXT,
        parent_id TEXT,
        style_id TEXT REFERENCES styles(id),
        type INTEGER,
        modified_at BIGINT DEFAULT 0,
        device_id TEXT,
        is_deleted BOOLEAN DEFAULT FALSE
      );
    ''');

      await _pool.execute('''
      CREATE TABLE IF NOT EXISTS accounts (
        id TEXT PRIMARY KEY,
        name TEXT,
        description TEXT,
        balance REAL,
        balance_minor BIGINT,
        currency_code TEXT,
        currency_designation_id TEXT REFERENCES currency_designations(id),
        style_id TEXT REFERENCES styles(id),
        account_type_id TEXT REFERENCES account_types(id),
        creation_date TIMESTAMP,
        country TEXT,
        asset_id TEXT,
        asset_quantity REAL DEFAULT 0.0,
        fee_structure TEXT,
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
        amount_minor BIGINT,
        date TIMESTAMP,
        account_id TEXT REFERENCES accounts(id),
        category_id TEXT REFERENCES categories(id),
        currency_code TEXT,
        exchange_rate REAL,
        exchange_rate_preset INTEGER,
        fee REAL,
        fee_minor BIGINT,
        linked_transaction_id TEXT,
        modified_at BIGINT DEFAULT 0,
        device_id TEXT,
        is_deleted BOOLEAN DEFAULT FALSE
      );
    ''');

      // Exact integer minor units for fiat money. Nullable on purpose: NULL
      // means the row is not fiat (crypto/commodity) and the REAL column is
      // authoritative, so these must never default to 0.
      await _pool.execute(
          'ALTER TABLE accounts ADD COLUMN IF NOT EXISTS balance_minor BIGINT');
      await _pool.execute(
          'ALTER TABLE transactions ADD COLUMN IF NOT EXISTS amount_minor BIGINT');
      await _pool.execute(
          'ALTER TABLE transactions ADD COLUMN IF NOT EXISTS fee_minor BIGINT');

      await _pool.execute('''
      CREATE TABLE IF NOT EXISTS asset_entries (
        id TEXT PRIMARY KEY,
        asset_id TEXT,
        name TEXT,
        date TIMESTAMP,
        value REAL,
        quantity REAL DEFAULT 1.0,
        asset_type TEXT,
        description TEXT,
        currency_code TEXT,
        account_id TEXT REFERENCES accounts(id),
        source TEXT,
        preset INTEGER DEFAULT 1,
        modified_at BIGINT DEFAULT 0,
        device_id TEXT,
        source_id TEXT,
        is_deleted BOOLEAN DEFAULT FALSE
      );
    ''');

      await _pool.execute('''
      CREATE TABLE IF NOT EXISTS sms_presets (
        id TEXT PRIMARY KEY,
        name TEXT,
        sender_filter TEXT,
        is_built_in BOOLEAN DEFAULT FALSE,
        is_enabled BOOLEAN DEFAULT TRUE,
        default_account_id TEXT,
        default_category_id TEXT,
        rules_json TEXT,
        modified_at BIGINT DEFAULT 0,
        device_id TEXT,
        is_deleted BOOLEAN DEFAULT FALSE
      );
    ''');

      await _pool.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT,
        device TEXT,
        modified_at BIGINT DEFAULT 0,
        device_id TEXT
      );
    ''');

      await _pool.execute('''
      CREATE TABLE IF NOT EXISTS exchange_rates (
        from_currency_code TEXT,
        to_currency_code TEXT,
        rate REAL,
        preset INTEGER,
        date TIMESTAMP,
        modified_at BIGINT DEFAULT 0,
        device_id TEXT,
        source_id TEXT,
        PRIMARY KEY (from_currency_code, to_currency_code, date, preset)
      );
    ''');

      await _pool.execute('''
      CREATE TABLE IF NOT EXISTS inflation_rates (
        date TIMESTAMP,
        percent REAL,
        country TEXT,
        preset INTEGER,
        modified_at BIGINT DEFAULT 0,
        device_id TEXT,
        source_id TEXT,
        PRIMARY KEY (date, country, preset)
      );
    ''');

      await _pool.execute('''
      CREATE TABLE IF NOT EXISTS custom_themes (
        id TEXT PRIMARY KEY,
        name TEXT,
        primary_color_hex TEXT,
        secondary_color_hex TEXT,
        surface_color_hex TEXT,
        background_color_hex TEXT,
        background_image_path TEXT,
        background_image_opacity REAL DEFAULT 1.0,
        background_image_blur REAL DEFAULT 0.0,
        window_effect_type INTEGER,
        effect_opacity REAL DEFAULT 1.0,
        surface_opacity REAL DEFAULT 1.0,
        theme_mode INTEGER,
        is_preset BOOLEAN DEFAULT FALSE,
        is_active BOOLEAN DEFAULT FALSE,
        modified_at BIGINT DEFAULT 0,
        device_id TEXT,
        is_deleted BOOLEAN DEFAULT FALSE
      );
    ''');

      await _pool.execute('''
      CREATE TABLE IF NOT EXISTS custom_data_sources (
        id TEXT PRIMARY KEY,
        name TEXT,
        url TEXT,
        data_type INTEGER,
        enabled BOOLEAN DEFAULT TRUE,
        auto_fetch BOOLEAN DEFAULT FALSE,
        last_fetch_at BIGINT,
        modified_at BIGINT DEFAULT 0,
        device_id TEXT,
        is_deleted BOOLEAN DEFAULT FALSE
      );
    ''');

      await _pool.execute('''
      CREATE TABLE IF NOT EXISTS api_settings (
        id TEXT PRIMARY KEY,
        enabled BOOLEAN DEFAULT TRUE,
        auto_fetch BOOLEAN DEFAULT FALSE,
        last_fetch_at BIGINT,
        modified_at BIGINT DEFAULT 0,
        device_id TEXT
      );
    ''');
      print('[DB] Schema initialization completed successfully.');
    } catch (e, stack) {
      print('[DB] CRITICAL ERROR during schema initialization: $e');
      print(stack);
      rethrow;
    }
  }
}
