import 'dart:io';
import 'package:postgres/postgres.dart';

class DatabaseClient {
  late final Pool<dynamic> _pool;

  /// [pool] is a seam, and the only reason it exists: production always builds
  /// its own pool from `DATABASE_URL`, but the schema migrations below have no
  /// other observable surface, so a test cannot pin them without one.
  DatabaseClient({Pool<dynamic>? pool}) {
    if (pool != null) {
      _pool = pool;
      return;
    }

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
        // The pool defaults to a single connection. A pull holds one for the
        // whole of its sixteen-table transaction, so with the default a second
        // device syncing at the same time waits out the first one and can hit
        // the acquire timeout instead of syncing.
        maxConnectionCount: int.tryParse(
              Platform.environment['DB_MAX_CONNECTIONS'] ?? '',
            ) ??
            8,
      ),
    );
  }

  Pool<dynamic> get pool => _pool;

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
        balance DOUBLE PRECISION,
        balance_minor BIGINT,
        opening_balance DOUBLE PRECISION,
        opening_balance_minor BIGINT,
        currency_code TEXT,
        currency_designation_id TEXT REFERENCES currency_designations(id),
        style_id TEXT REFERENCES styles(id),
        account_type_id TEXT REFERENCES account_types(id),
        creation_date TIMESTAMP,
        country TEXT,
        asset_id TEXT,
        asset_quantity DOUBLE PRECISION DEFAULT 0.0,
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
        amount DOUBLE PRECISION,
        amount_minor BIGINT,
        date TIMESTAMP,
        account_id TEXT REFERENCES accounts(id),
        category_id TEXT REFERENCES categories(id),
        currency_code TEXT,
        exchange_rate DOUBLE PRECISION,
        exchange_rate_preset INTEGER,
        fee DOUBLE PRECISION,
        fee_minor BIGINT,
        linked_transaction_id TEXT,
        needs_review BOOLEAN DEFAULT FALSE,
        modified_at BIGINT DEFAULT 0,
        device_id TEXT,
        is_deleted BOOLEAN DEFAULT FALSE
      );
    ''');

      // Exact integer minor units for fiat money. Nullable on purpose: NULL
      // means the row is not fiat (crypto/commodity) and the floating-point
      // column is authoritative, so these must never default to 0.
      await _pool.execute(
          'ALTER TABLE accounts ADD COLUMN IF NOT EXISTS balance_minor BIGINT');
      await _pool.execute(
          'ALTER TABLE transactions ADD COLUMN IF NOT EXISTS amount_minor BIGINT');
      await _pool.execute(
          'ALTER TABLE transactions ADD COLUMN IF NOT EXISTS fee_minor BIGINT');

      // Whether a client still wants a person to look at the row. Added after
      // the first release, so it has to be an ALTER as well as a column in the
      // CREATE above: a server that has been running keeps its table. Defaults
      // to FALSE, which is what every row written before the review queue
      // existed is.
      await _pool.execute(
          'ALTER TABLE transactions ADD COLUMN IF NOT EXISTS needs_review BOOLEAN DEFAULT FALSE');

      // The balance an account held before its first transaction, and the one
      // number on an account row that is not derivable from anything else.
      //
      // Every client rebuilds `balance` from this anchor plus the transactions
      // it holds, deliberately throwing away the balance it was sent: balances
      // merge as scalars while transactions merge as a set, so an accepted
      // balance leaves whichever device pushed last dictating a number the
      // merged set does not add up to. That rebuild is only as good as the
      // anchor, and the anchor never crossed this server - the columns did not
      // exist, so the two values the client pushed were dropped on the floor.
      //
      // A receiver with no anchor works one out from the balance it happens to
      // hold at that moment. Two devices spending from the same account before
      // either syncs both hold a balance carrying one spend and not the other,
      // so both derived an anchor inflated by the spend they were missing, and
      // then rebuilt a balance that agreed with it. Nothing about the result
      // is inconsistent, which is why nothing later repaired it: the account
      // was simply wrong, on every device, permanently. The peer-to-peer sync
      // path has carried both values from the start.
      //
      // Left NULL for rows already stored rather than backfilled from
      // `balance`: the stored balance is the sum of an unknown set of
      // transactions, so writing it here would invent an anchor instead of
      // waiting for the device that owns the account to push the real one.
      // NULL is already the wire's word for "sender has no anchor", and every
      // client handles it.
      await _pool.execute('ALTER TABLE accounts '
          'ADD COLUMN IF NOT EXISTS opening_balance DOUBLE PRECISION');
      await _pool.execute('ALTER TABLE accounts '
          'ADD COLUMN IF NOT EXISTS opening_balance_minor BIGINT');

      await _pool.execute('''
      CREATE TABLE IF NOT EXISTS asset_entries (
        id TEXT PRIMARY KEY,
        asset_id TEXT,
        name TEXT,
        date TIMESTAMP,
        value DOUBLE PRECISION,
        quantity DOUBLE PRECISION DEFAULT 1.0,
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
        rate DOUBLE PRECISION,
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
        percent DOUBLE PRECISION,
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
        background_image_opacity DOUBLE PRECISION DEFAULT 1.0,
        background_image_blur DOUBLE PRECISION DEFAULT 0.0,
        window_effect_type INTEGER,
        effect_opacity DOUBLE PRECISION DEFAULT 1.0,
        surface_opacity DOUBLE PRECISION DEFAULT 1.0,
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
        device_id TEXT,
        is_deleted BOOLEAN DEFAULT FALSE
      );
    ''');

      // The only synced table that was created without a tombstone column.
      // The client has always pushed `isDeleted` for it and has always read it
      // back, so the delete travelled to the server and died there: the row
      // was stored as live, and every other device pulled the provider the
      // user had removed straight back into its list, on every sync, forever.
      // DEFAULT FALSE is the right backfill - a row that exists today is one
      // no device has claimed to have deleted.
      await _pool.execute(
          'ALTER TABLE api_settings ADD COLUMN IF NOT EXISTS is_deleted '
          'BOOLEAN DEFAULT FALSE');

      await _ensureWideFloats();

      await _ensureServerSeq();

      print('[DB] Schema initialization completed successfully.');
    } catch (e, stack) {
      print('[DB] CRITICAL ERROR during schema initialization: $e');
      print(stack);
      rethrow;
    }
  }

  /// Every table a client can pull from, in no particular order.
  static const List<String> syncedTables = [
    'languages',
    'currencies',
    'styles',
    'account_types',
    'currency_designations',
    'categories',
    'accounts',
    'transactions',
    'asset_entries',
    'sms_presets',
    'settings',
    'exchange_rates',
    'inflation_rates',
    'custom_themes',
    'custom_data_sources',
    'api_settings',
  ];


  /// Widens every 32-bit float column on a synced table to 64 bits.
  ///
  /// Postgres `REAL` is float4: about seven significant digits. Both clients
  /// hold these values as Dart doubles and SQLite stores them as 8-byte
  /// floats, so the server was the one narrow link in the chain, and it
  /// narrowed silently. A balance of -1234567.89 pushed by one device came
  /// back to the other as -1234567.875, and since neither row is newer than
  /// the other under last-write-wins, the two devices then disagreed about
  /// that account forever with nothing left to re-sync. Values outside the
  /// float4 range were worse: Postgres raised 22003, the whole push failed,
  /// and a failed push deliberately keeps its queue - so that device retried
  /// the same doomed batch every five minutes.
  ///
  /// Widening is lossless for what is already stored; it cannot recover the
  /// digits an earlier write threw away. Those rows heal the next time the
  /// device that owns them edits them.
  ///
  /// Guarded on the catalogue rather than run unconditionally: `ALTER COLUMN
  /// TYPE` rewrites the whole table, and this runs on every boot.
  Future<void> _ensureWideFloats() async {
    final tables = syncedTables.map((t) => "'$t'").join(', ');
    await _pool.execute('''
      DO \$\$
      DECLARE
        target RECORD;
      BEGIN
        FOR target IN
          SELECT table_name, column_name
          FROM information_schema.columns
          WHERE table_schema = current_schema()
            AND data_type = 'real'
            AND table_name IN ($tables)
        LOOP
          EXECUTE format(
            'ALTER TABLE %I ALTER COLUMN %I TYPE DOUBLE PRECISION',
            target.table_name, target.column_name);
        END LOOP;
      END
      \$\$;
    ''');
  }

  /// Gives every synced row a server-assigned position in one global order.
  ///
  /// Pull used to page on `modified_at`, which is written by the client that
  /// made the change. A device whose clock is behind — or one that was offline
  /// for a week and pushes a change stamped last Tuesday — writes a row *below*
  /// a cursor other devices have already moved past, and that row is then never
  /// handed out again: it is invisible to every peer forever, with nothing
  /// anywhere reporting a loss.
  ///
  /// `server_seq` is drawn from a single sequence at write time, so it orders
  /// rows by when this server accepted them, which is the only clock a cursor
  /// can safely be built on. A trigger sets it rather than each of the ~20
  /// upsert statements, so no future write path can forget to.
  Future<void> _ensureServerSeq() async {
    await _pool.execute('CREATE SEQUENCE IF NOT EXISTS sync_seq');

    // Assigned on UPDATE as well as INSERT: an edit to an existing row is a
    // change peers still have to receive, so it has to move to the end of the
    // queue.
    await _pool.execute('''
      CREATE OR REPLACE FUNCTION sync_stamp_server_seq() RETURNS trigger AS \$\$
      BEGIN
        NEW.server_seq := nextval('sync_seq');
        RETURN NEW;
      END;
      \$\$ LANGUAGE plpgsql;
    ''');

    for (final table in syncedTables) {
      await _pool.execute(
        'ALTER TABLE $table ADD COLUMN IF NOT EXISTS server_seq BIGINT',
      );
      await _pool.execute(
        'CREATE INDEX IF NOT EXISTS ${table}_server_seq_idx '
        'ON $table (server_seq)',
      );
      // Rows written before this column existed. Ordering among them is
      // arbitrary, which is harmless: a client either has them already or is
      // pulling from 0 and gets all of them regardless.
      await _pool.execute(
        "UPDATE $table SET server_seq = nextval('sync_seq') "
        'WHERE server_seq IS NULL',
      );
      await _pool.execute('DROP TRIGGER IF EXISTS ${table}_server_seq ON $table');
      await _pool.execute('''
        CREATE TRIGGER ${table}_server_seq
        BEFORE INSERT OR UPDATE ON $table
        FOR EACH ROW EXECUTE FUNCTION sync_stamp_server_seq();
      ''');
    }
  }
}
