import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart'
    hide Transaction;
import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// Migration characterization tests.
///
/// This repo has no `test/drift_schemas/` fixtures and no `drift_dev schema
/// dump` setup (checked: no `build.yaml`, no schema JSON files). So instead
/// of driving drift's official schema-testing helpers, these tests hand-build
/// older-version SQLite databases with plain `package:sqlite3` (the same
/// engine `NativeDatabase` uses), matching exactly the columns/tables that
/// `AppDatabase.migration`'s `onUpgrade` callback (lib/core/database/
/// app_database.dart) proves are pre-v-N by *adding* them at step N. Any
/// column never added by an explicit `m.addColumn`/`m.createTable` call is
/// left in the fixture as a "since v1" baseline column (confirmed against
/// git history for e.g. `source_id`, which predates this repo's recorded
/// commits despite having no matching addColumn step).
///
/// The fixture is written to a real temp file (not `:memory:`) because the
/// two-phase approach needs two connections to see the same database: one
/// raw `sqlite3` connection to build the "old" schema + seed "existing user"
/// rows, and a second `AppDatabase.forTesting(NativeDatabase(file))` that
/// observes `PRAGMA user_version` < `schemaVersion` and runs the real
/// `onUpgrade` migration path against it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('mybudget_migration_test');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('v7 -> v8 migration (adds minor-unit columns)', () {
    // v7 == current schema minus the three minor-unit columns. Everything
    // else (indexes included) is identical to the live v8 DDL, dumped from a
    // fresh onCreate database via `sqlite_master`, so this fixture is exact
    // rather than guessed.
    const createV7Sql = '''
      CREATE TABLE "languages" ("language" TEXT NOT NULL, "language_code" TEXT NOT NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, PRIMARY KEY ("language_code"));
      CREATE TABLE "currencies" ("name" TEXT NOT NULL UNIQUE, "code" TEXT NOT NULL, "language_code" TEXT NOT NULL REFERENCES languages (language_code), "type" INTEGER NOT NULL DEFAULT 6, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, PRIMARY KEY ("code"));
      CREATE TABLE "currency_designations" ("id" TEXT NOT NULL, "value" TEXT NOT NULL, "currency_code" TEXT NOT NULL REFERENCES currencies (code), "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "account_types" ("id" TEXT NOT NULL, "name" TEXT NOT NULL UNIQUE, "language_code" TEXT NOT NULL REFERENCES languages (language_code), "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "styles" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "icon_name" TEXT NOT NULL, "color_hex" TEXT NOT NULL, "icon_type" INTEGER NOT NULL DEFAULT 0, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "categories" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "parent_id" TEXT NULL REFERENCES categories (id), "style_id" TEXT NULL REFERENCES styles (id), "type" INTEGER NOT NULL DEFAULT 0, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "accounts" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "description" TEXT NULL, "balance" REAL NOT NULL, "currency_code" TEXT NOT NULL REFERENCES currencies (code), "currency_designation_id" TEXT NOT NULL REFERENCES currency_designations (id), "style_id" TEXT NULL REFERENCES styles (id), "account_type_id" TEXT NOT NULL REFERENCES account_types (id), "creation_date" INTEGER NOT NULL, "country" TEXT NULL, "asset_id" TEXT NULL, "asset_quantity" REAL NOT NULL DEFAULT 0.0, "fee_structure" TEXT NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "transactions" ("id" TEXT NOT NULL, "description" TEXT NOT NULL, "amount" REAL NOT NULL, "date" INTEGER NOT NULL, "account_id" TEXT NOT NULL REFERENCES accounts (id), "category_id" TEXT NOT NULL REFERENCES categories (id), "currency_code" TEXT NOT NULL REFERENCES currencies (code), "exchange_rate" REAL NULL, "exchange_rate_preset" INTEGER NULL, "fee" REAL NOT NULL DEFAULT 0.0, "linked_transaction_id" TEXT NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "exchange_rates" ("from_currency_code" TEXT NOT NULL REFERENCES currencies (code), "to_currency_code" TEXT NOT NULL REFERENCES currencies (code), "rate" REAL NOT NULL, "preset" INTEGER NOT NULL, "date" INTEGER NOT NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "source_id" TEXT NULL, PRIMARY KEY ("from_currency_code", "to_currency_code", "date", "preset"));
      CREATE TABLE "inflation_rates" ("date" INTEGER NOT NULL, "percent" REAL NOT NULL, "country" TEXT NULL, "preset" INTEGER NOT NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "source_id" TEXT NULL, PRIMARY KEY ("date", "country", "preset"));
      CREATE TABLE "asset_entries" ("id" TEXT NOT NULL, "asset_id" TEXT NOT NULL, "name" TEXT NOT NULL, "date" INTEGER NOT NULL, "value" REAL NOT NULL, "quantity" REAL NOT NULL DEFAULT 1.0, "asset_type" TEXT NULL, "description" TEXT NULL, "currency_code" TEXT NOT NULL REFERENCES currencies (code), "account_id" TEXT NULL REFERENCES accounts (id), "source" TEXT NOT NULL, "preset" INTEGER NOT NULL DEFAULT 1, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "source_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "settings" ("key" TEXT NOT NULL, "value" TEXT NOT NULL, "device" TEXT NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, PRIMARY KEY ("key"));
      CREATE TABLE "custom_themes" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "primary_color_hex" TEXT NOT NULL, "secondary_color_hex" TEXT NOT NULL, "surface_color_hex" TEXT NOT NULL, "background_color_hex" TEXT NOT NULL, "background_image_path" TEXT NULL, "background_image_opacity" REAL NOT NULL DEFAULT 1.0, "background_image_blur" REAL NOT NULL DEFAULT 0.0, "window_effect_type" INTEGER NOT NULL, "effect_opacity" REAL NOT NULL DEFAULT 1.0, "surface_opacity" REAL NOT NULL DEFAULT 1.0, "theme_mode" INTEGER NOT NULL, "is_preset" INTEGER NOT NULL DEFAULT 0, "is_active" INTEGER NOT NULL DEFAULT 0, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "sync_log" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "changed_table_name" TEXT NOT NULL, "record_id" TEXT NOT NULL, "action" TEXT NOT NULL, "timestamp" INTEGER NOT NULL, "exported" INTEGER NOT NULL DEFAULT 0);
      CREATE TABLE "conflict_history" ("id" TEXT NOT NULL, "changed_table_name" TEXT NOT NULL, "record_id" TEXT NOT NULL, "rejected_data" TEXT NOT NULL, "rejected_at" INTEGER NOT NULL, "rejected_device" TEXT NULL, PRIMARY KEY ("id"));
      CREATE TABLE "custom_data_sources" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "url" TEXT NOT NULL, "data_type" INTEGER NOT NULL, "enabled" INTEGER NOT NULL DEFAULT 1, "auto_fetch" INTEGER NOT NULL DEFAULT 0, "last_fetch_at" INTEGER NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "api_settings_table" ("id" TEXT NOT NULL, "enabled" INTEGER NOT NULL DEFAULT 1, "auto_fetch" INTEGER NOT NULL DEFAULT 0, "last_fetch_at" INTEGER NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, PRIMARY KEY ("id"));
      CREATE TABLE "api_fetch_statuses" ("id" TEXT NOT NULL, "attempts" INTEGER NOT NULL DEFAULT 0, "last_attempt" INTEGER NULL, "status" TEXT NOT NULL DEFAULT 'pending', PRIMARY KEY ("id"));
      CREATE TABLE "sms_presets" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "sender_filter" TEXT NOT NULL, "is_built_in" INTEGER NOT NULL DEFAULT 0, "is_enabled" INTEGER NOT NULL DEFAULT 1, "default_account_id" TEXT NULL, "default_category_id" TEXT NULL, "rules_json" TEXT NOT NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "sync_processed_files" ("file_name" TEXT NOT NULL, "processed_at" INTEGER NOT NULL, "device_id" TEXT NOT NULL, PRIMARY KEY ("file_name"));
      CREATE INDEX idx_transactions_date ON transactions (date);
      CREATE INDEX idx_transactions_account ON transactions (account_id);
      CREATE INDEX idx_transactions_category ON transactions (category_id);
      CREATE INDEX idx_transactions_date_category ON transactions (date, category_id);
      CREATE INDEX idx_transactions_account_date ON transactions (account_id, date);
      CREATE INDEX idx_exchange_rates_date ON exchange_rates (date);
      CREATE INDEX idx_exchange_rates_composite ON exchange_rates (from_currency_code, to_currency_code, date);
      CREATE UNIQUE INDEX idx_asset_entries_custom_api_dedup ON asset_entries (asset_id, date, source) WHERE source = 'custom_api';
    ''';

    Future<AppDatabase> buildAndOpen({
      required void Function(sqlite3.Database) seed,
    }) async {
      final file = File('${tempDir.path}/v7.sqlite');
      final raw = sqlite3.sqlite3.open(file.path);
      raw.execute(createV7Sql);
      seed(raw);
      raw.execute('PRAGMA user_version = 7;');
      raw.dispose();

      final db = AppDatabase.forTesting(NativeDatabase(file));
      // Force the migration to run by touching the db.
      await db.customSelect('SELECT 1').get();
      return db;
    }

    test('fiat account balance and transaction amount/fee survive exactly; '
        'minor columns get the right integer scale', () async {
      final db = await buildAndOpen(
        seed: (raw) {
          raw.execute('''
              INSERT INTO languages (language, language_code) VALUES ('English','en');
              INSERT INTO currencies (name, code, language_code, type) VALUES ('Euro','EUR','en',0);
              INSERT INTO currencies (name, code, language_code, type) VALUES ('Bitcoin','BTC','en',1);
              INSERT INTO currency_designations (id, value, currency_code) VALUES ('d1','€','EUR');
              INSERT INTO account_types (id, name, language_code) VALUES ('at1','Checking','en');
              INSERT INTO categories (id, name) VALUES ('c1','Groceries');
              INSERT INTO accounts (id, name, balance, currency_code, currency_designation_id, account_type_id, creation_date)
                VALUES ('accEur', 'Eur Wallet', 1234.56, 'EUR', 'd1', 'at1', 0);
              INSERT INTO accounts (id, name, balance, currency_code, currency_designation_id, account_type_id, creation_date)
                VALUES ('accBtc', 'Btc Wallet', 0.5, 'BTC', 'd1', 'at1', 0);
              INSERT INTO transactions (id, description, amount, date, account_id, category_id, currency_code, fee)
                VALUES ('t1', 'Weekly shop', 10.10, 0, 'accEur', 'c1', 'EUR', 0.05);
              INSERT INTO transactions (id, description, amount, date, account_id, category_id, currency_code, fee)
                VALUES ('t2', 'Sats', 0.25, 0, 'accBtc', 'c1', 'BTC', 0.0);
            ''');
        },
      );

      final eurAccount = await (db.select(
        db.accounts,
      )..where((a) => a.id.equals('accEur'))).getSingle();
      final btcAccount = await (db.select(
        db.accounts,
      )..where((a) => a.id.equals('accBtc'))).getSingle();

      // The legacy double must be untouched by the migration.
      expect(eurAccount.balance, 1234.56);
      expect(btcAccount.balance, 0.5);
      // The new integer column is exact and correctly scaled (2 decimals).
      expect(eurAccount.balanceMinor, 123456);
      // Crypto never gets a minor value: NULL, not 0.
      expect(btcAccount.balanceMinor, isNull);

      final eurTx = await (db.select(
        db.transactions,
      )..where((t) => t.id.equals('t1'))).getSingle();
      final btcTx = await (db.select(
        db.transactions,
      )..where((t) => t.id.equals('t2'))).getSingle();

      expect(eurTx.amount, 10.10);
      expect(eurTx.fee, 0.05);
      expect(eurTx.amountMinor, 1010);
      expect(eurTx.feeMinor, 5);
      expect(btcTx.amount, 0.25);
      expect(btcTx.amountMinor, isNull);

      await db.close();
    });

    test(
      'adds the minor-unit columns without dropping any other column',
      () async {
        final db = await buildAndOpen(seed: (_) {});

        final accountCols = await db
            .customSelect("PRAGMA table_info('accounts')")
            .get();
        final accountColNames = accountCols
            .map((r) => r.data['name'] as String)
            .toSet();
        expect(accountColNames, contains('balance_minor'));
        expect(accountColNames, contains('balance')); // old column intact
        expect(accountColNames, contains('is_deleted')); // v3 column intact

        final txCols = await db
            .customSelect("PRAGMA table_info('transactions')")
            .get();
        final txColNames = txCols.map((r) => r.data['name'] as String).toSet();
        expect(txColNames, containsAll(['amount_minor', 'fee_minor']));
        expect(txColNames, contains('amount')); // old column intact

        await db.close();
      },
    );
  });

  group('v2 -> current migration (chain covering every v3+ upgrade step)', () {
    // Starts from v2, not v1: the v1->v2 `_migrateToStableIds` step is the
    // only one this chain skips, and it needs a whole extra pre-stable-id
    // fixture to model. Every other upgrade step is exercised (v3 sync
    // columns, v3/v4 new tables, v5 full reseed, v6 composite indexes, v7
    // dedup index + backfill precursor, v8 minor units, v9 backfilled
    // @TableIndex indexes).
    //
    // v2 baseline: v1 schema + the three sync columns v1->v2 adds to
    // styles/account_types/currency_designations (id churn from
    // `_migrateToStableIds` is NOT modeled here - by v2 a real device's rows
    // already carry whatever ids that rename settled on, so plain
    // self-consistent ids are used instead of the literal seed-data ids).
    // `source_id` on exchange_rates/inflation_rates/asset_entries is kept
    // in the baseline even though it's never addColumn'd: `git blame` on
    // the earliest commit in this repo's history shows it already present
    // before any recorded schema-version bump, i.e. it predates the
    // migration chain rather than being a missed migration.
    const createV2Sql = '''
      CREATE TABLE "languages" ("language" TEXT NOT NULL, "language_code" TEXT NOT NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, PRIMARY KEY ("language_code"));
      CREATE TABLE "currencies" ("name" TEXT NOT NULL UNIQUE, "code" TEXT NOT NULL, "language_code" TEXT NOT NULL REFERENCES languages (language_code), "type" INTEGER NOT NULL DEFAULT 6, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, PRIMARY KEY ("code"));
      CREATE TABLE "currency_designations" ("id" TEXT NOT NULL, "value" TEXT NOT NULL, "currency_code" TEXT NOT NULL REFERENCES currencies (code), "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "account_types" ("id" TEXT NOT NULL, "name" TEXT NOT NULL UNIQUE, "language_code" TEXT NOT NULL REFERENCES languages (language_code), "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "styles" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "icon_name" TEXT NOT NULL, "color_hex" TEXT NOT NULL, "icon_type" INTEGER NOT NULL DEFAULT 0, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "categories" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "parent_id" TEXT NULL REFERENCES categories (id), "style_id" TEXT NULL REFERENCES styles (id), "type" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "accounts" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "description" TEXT NULL, "balance" REAL NOT NULL, "currency_code" TEXT NOT NULL REFERENCES currencies (code), "currency_designation_id" TEXT NOT NULL REFERENCES currency_designations (id), "style_id" TEXT NULL REFERENCES styles (id), "account_type_id" TEXT NOT NULL REFERENCES account_types (id), "creation_date" INTEGER NOT NULL, "country" TEXT NULL, "asset_id" TEXT NULL, "asset_quantity" REAL NOT NULL DEFAULT 0.0, "fee_structure" TEXT NULL, PRIMARY KEY ("id"));
      CREATE TABLE "transactions" ("id" TEXT NOT NULL, "description" TEXT NOT NULL, "amount" REAL NOT NULL, "date" INTEGER NOT NULL, "account_id" TEXT NOT NULL REFERENCES accounts (id), "category_id" TEXT NOT NULL REFERENCES categories (id), "currency_code" TEXT NOT NULL REFERENCES currencies (code), "exchange_rate" REAL NULL, "exchange_rate_preset" INTEGER NULL, "fee" REAL NOT NULL DEFAULT 0.0, "linked_transaction_id" TEXT NULL, PRIMARY KEY ("id"));
      CREATE TABLE "exchange_rates" ("from_currency_code" TEXT NOT NULL REFERENCES currencies (code), "to_currency_code" TEXT NOT NULL REFERENCES currencies (code), "rate" REAL NOT NULL, "preset" INTEGER NOT NULL, "date" INTEGER NOT NULL, "source_id" TEXT NULL, PRIMARY KEY ("from_currency_code", "to_currency_code", "date", "preset"));
      CREATE TABLE "inflation_rates" ("date" INTEGER NOT NULL, "percent" REAL NOT NULL, "country" TEXT NULL, "preset" INTEGER NOT NULL, "source_id" TEXT NULL, PRIMARY KEY ("date", "country", "preset"));
      CREATE TABLE "asset_entries" ("id" TEXT NOT NULL, "asset_id" TEXT NOT NULL, "name" TEXT NOT NULL, "date" INTEGER NOT NULL, "value" REAL NOT NULL, "quantity" REAL NOT NULL DEFAULT 1.0, "asset_type" TEXT NULL, "description" TEXT NULL, "currency_code" TEXT NOT NULL REFERENCES currencies (code), "account_id" TEXT NULL REFERENCES accounts (id), "source" TEXT NOT NULL, "preset" INTEGER NOT NULL DEFAULT 1, "source_id" TEXT NULL, PRIMARY KEY ("id"));
      CREATE TABLE "settings" ("key" TEXT NOT NULL, "value" TEXT NOT NULL, "device" TEXT NULL, PRIMARY KEY ("key"));
      CREATE TABLE "custom_themes" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "primary_color_hex" TEXT NOT NULL, "secondary_color_hex" TEXT NOT NULL, "surface_color_hex" TEXT NOT NULL, "background_color_hex" TEXT NOT NULL, "background_image_path" TEXT NULL, "background_image_opacity" REAL NOT NULL DEFAULT 1.0, "background_image_blur" REAL NOT NULL DEFAULT 0.0, "window_effect_type" INTEGER NOT NULL, "effect_opacity" REAL NOT NULL DEFAULT 1.0, "surface_opacity" REAL NOT NULL DEFAULT 1.0, "theme_mode" INTEGER NOT NULL, "is_preset" INTEGER NOT NULL DEFAULT 0, "is_active" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "sync_log" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "changed_table_name" TEXT NOT NULL, "record_id" TEXT NOT NULL, "action" TEXT NOT NULL, "timestamp" INTEGER NOT NULL, "exported" INTEGER NOT NULL DEFAULT 0);
      CREATE TABLE "conflict_history" ("id" TEXT NOT NULL, "changed_table_name" TEXT NOT NULL, "record_id" TEXT NOT NULL, "rejected_data" TEXT NOT NULL, "rejected_at" INTEGER NOT NULL, "rejected_device" TEXT NULL, PRIMARY KEY ("id"));
      CREATE TABLE "custom_data_sources" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "url" TEXT NOT NULL, "data_type" INTEGER NOT NULL, "enabled" INTEGER NOT NULL DEFAULT 1, "auto_fetch" INTEGER NOT NULL DEFAULT 0, "last_fetch_at" INTEGER NULL, PRIMARY KEY ("id"));
      CREATE TABLE "api_settings_table" ("id" TEXT NOT NULL, "enabled" INTEGER NOT NULL DEFAULT 1, "auto_fetch" INTEGER NOT NULL DEFAULT 0, "last_fetch_at" INTEGER NULL, PRIMARY KEY ("id"));
      CREATE TABLE "api_fetch_statuses" ("id" TEXT NOT NULL, "attempts" INTEGER NOT NULL DEFAULT 0, "last_attempt" INTEGER NULL, "status" TEXT NOT NULL DEFAULT 'pending', PRIMARY KEY ("id"));
    ''';

    // Pre-existing "real user" rows, using already-stable ids (a real v2
    // device has already been through `_migrateToStableIds`; which literal
    // ids it landed on doesn't matter here, only that they're self-consistent
    // FKs pointing at rows this fixture also creates).
    const seedSql = '''
      INSERT INTO languages (language, language_code) VALUES ('English','en');
      INSERT INTO currencies (name, code, language_code, type) VALUES ('Euro','EUR','en',0);
      INSERT INTO currencies (name, code, language_code, type) VALUES ('Bitcoin','BTC','en',1);
      INSERT INTO currency_designations (id, value, currency_code) VALUES ('desig_eur','€','EUR');
      INSERT INTO account_types (id, name, language_code) VALUES ('at_checking','Checking','en');
      INSERT INTO styles (id, name, icon_name, color_hex) VALUES ('style_wallet','Default Wallet','wallet','#000000');
      INSERT INTO categories (id, name) VALUES ('user_cat_custom_v1','My Custom Category');
      INSERT INTO accounts (id, name, balance, currency_code, currency_designation_id, style_id, account_type_id, creation_date)
        VALUES ('accEur', 'Eur Wallet', 1234.56, 'EUR', 'desig_eur', 'style_wallet', 'at_checking', 0);
      INSERT INTO accounts (id, name, balance, currency_code, currency_designation_id, account_type_id, creation_date)
        VALUES ('accBtc', 'Btc Wallet', 0.5, 'BTC', 'desig_eur', 'at_checking', 0);
      INSERT INTO transactions (id, description, amount, date, account_id, category_id, currency_code, fee)
        VALUES ('t1', 'Weekly shop', 10.10, 0, 'accEur', 'user_cat_custom_v1', 'EUR', 0.05);
      INSERT INTO transactions (id, description, amount, date, account_id, category_id, currency_code, fee)
        VALUES ('t2', 'Sats', 0.25, 0, 'accBtc', 'user_cat_custom_v1', 'BTC', 0.0);
    ''';

    late AppDatabase db;

    setUpAll(() async {
      // One shared migration for the whole group: the chain re-runs
      // the ~283k-row exchange-rate reseed (the v4->v5 step calls
      // `_seedData` again), so it is materially slower than the other
      // migration tests here; running it once and asserting many things
      // against the result keeps this suite's runtime reasonable.
      final tempDir = Directory.systemTemp.createTempSync(
        'mybudget_migration_v2_test',
      );
      final file = File('${tempDir.path}/v2.sqlite');
      final raw = sqlite3.sqlite3.open(file.path);
      raw.execute(createV2Sql);
      raw.execute(seedSql);
      raw.execute('PRAGMA user_version = 2;');
      raw.dispose();

      db = AppDatabase.forTesting(NativeDatabase(file));
      await db.customSelect('SELECT 1').get();
    });

    tearDownAll(() async {
      await db.close();
    });

    // Asserted against `db.schemaVersion` rather than a literal: the point is
    // that the chain arrives at whatever the current schema is, and a literal
    // here only ever means "someone added a migration" - it went stale the
    // first time one was added.
    test(
      'completes the chain without throwing and lands on schemaVersion',
      () async {
        final versionRow = await db
            .customSelect('PRAGMA user_version')
            .getSingle();
        expect(versionRow.data['user_version'], db.schemaVersion);
      },
    );

    test('final schema has the columns the v8 Dart tables expect', () async {
      Future<Set<String>> columnsOf(String table) async {
        final rows = await db.customSelect("PRAGMA table_info('$table')").get();
        return rows.map((r) => r.data['name'] as String).toSet();
      }

      expect(
        await columnsOf('accounts'),
        containsAll([
          'balance_minor',
          'modified_at',
          'device_id',
          'is_deleted',
        ]),
      );
      expect(
        await columnsOf('transactions'),
        containsAll([
          'amount_minor',
          'fee_minor',
          'modified_at',
          'device_id',
          'is_deleted',
        ]),
      );
      expect(
        await columnsOf('styles'),
        containsAll(['modified_at', 'device_id', 'is_deleted']),
      );
      expect(
        await columnsOf('account_types'),
        containsAll(['modified_at', 'device_id', 'is_deleted']),
      );
      expect(
        await columnsOf('currency_designations'),
        containsAll(['modified_at', 'device_id', 'is_deleted']),
      );
      expect(
        await columnsOf('api_settings_table'),
        containsAll(['modified_at', 'device_id']),
      );
    });

    test('creates the tables introduced after v1 (sms_presets v3, '
        'sync_processed_files v4)', () async {
      final tables = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
          .get();
      final names = tables.map((r) => r.data['name'] as String).toSet();
      expect(names, containsAll(['sms_presets', 'sync_processed_files']));
    });

    test('creates the composite indexes added in v6 and the dedup unique '
        'index added in v7', () async {
      final indexes = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'index'")
          .get();
      final names = indexes.map((r) => r.data['name'] as String).toSet();
      expect(
        names,
        containsAll([
          'idx_transactions_date_category',
          'idx_transactions_account_date',
          'idx_asset_entries_custom_api_dedup',
        ]),
      );
    });

    test('backfills the five @TableIndex indexes, which only ever existed on '
        'fresh installs: m.createAll() builds them in onCreate and no upgrade '
        'step did, so every upgraded device ran without them', () async {
      final indexes = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'index'")
          .get();
      final names = indexes.map((r) => r.data['name'] as String).toSet();
      expect(
        names,
        containsAll([
          'idx_transactions_date',
          'idx_transactions_account',
          'idx_transactions_category',
          'idx_exchange_rates_date',
          'idx_exchange_rates_composite',
        ]),
      );
    });

    test(
      'MONEY: fiat account balance and transaction amount/fee are byte-exact '
      'after the v2->v8 chain; crypto stays on the double with NULL '
      'minor columns',
      () async {
        final eurAccount = await (db.select(
          db.accounts,
        )..where((a) => a.id.equals('accEur'))).getSingle();
        final btcAccount = await (db.select(
          db.accounts,
        )..where((a) => a.id.equals('accBtc'))).getSingle();

        expect(eurAccount.balance, 1234.56, reason: 'legacy double untouched');
        expect(
          eurAccount.balanceMinor,
          123456,
          reason: 'exact 2-decimal scale',
        );
        expect(btcAccount.balance, 0.5);
        expect(btcAccount.balanceMinor, isNull);

        final eurTx = await (db.select(
          db.transactions,
        )..where((t) => t.id.equals('t1'))).getSingle();
        final btcTx = await (db.select(
          db.transactions,
        )..where((t) => t.id.equals('t2'))).getSingle();

        expect(eurTx.amount, 10.10);
        expect(eurTx.fee, 0.05);
        expect(eurTx.amountMinor, 1010);
        expect(eurTx.feeMinor, 5);
        expect(btcTx.amount, 0.25);
        expect(btcTx.amountMinor, isNull);
      },
    );

    test(
      'custom (non-seed) category survives the v4->v5 reseed untouched',
      () async {
        final cat = await (db.select(
          db.categories,
        )..where((c) => c.id.equals('user_cat_custom_v1'))).getSingleOrNull();
        expect(cat, isNotNull);
        expect(cat!.name, 'My Custom Category');
      },
    );
  });

  group('v10 -> v11 migration (adds the opening-balance anchor)', () {
    // v10 == the current schema minus the two opening-balance columns: the v9
    // fixture above with `inflation_rates.country` already NOT NULL, which is
    // all the v9->v10 step changes.
    const createV10Sql = '''
      CREATE TABLE "languages" ("language" TEXT NOT NULL, "language_code" TEXT NOT NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, PRIMARY KEY ("language_code"));
      CREATE TABLE "currencies" ("name" TEXT NOT NULL UNIQUE, "code" TEXT NOT NULL, "language_code" TEXT NOT NULL REFERENCES languages (language_code), "type" INTEGER NOT NULL DEFAULT 6, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, PRIMARY KEY ("code"));
      CREATE TABLE "currency_designations" ("id" TEXT NOT NULL, "value" TEXT NOT NULL, "currency_code" TEXT NOT NULL REFERENCES currencies (code), "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "account_types" ("id" TEXT NOT NULL, "name" TEXT NOT NULL UNIQUE, "language_code" TEXT NOT NULL REFERENCES languages (language_code), "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "styles" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "icon_name" TEXT NOT NULL, "color_hex" TEXT NOT NULL, "icon_type" INTEGER NOT NULL DEFAULT 0, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "categories" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "parent_id" TEXT NULL REFERENCES categories (id), "style_id" TEXT NULL REFERENCES styles (id), "type" INTEGER NOT NULL DEFAULT 0, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "accounts" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "description" TEXT NULL, "balance" REAL NOT NULL, "balance_minor" INTEGER NULL, "currency_code" TEXT NOT NULL REFERENCES currencies (code), "currency_designation_id" TEXT NOT NULL REFERENCES currency_designations (id), "style_id" TEXT NULL REFERENCES styles (id), "account_type_id" TEXT NOT NULL REFERENCES account_types (id), "creation_date" INTEGER NOT NULL, "country" TEXT NULL, "asset_id" TEXT NULL, "asset_quantity" REAL NOT NULL DEFAULT 0.0, "fee_structure" TEXT NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "transactions" ("id" TEXT NOT NULL, "description" TEXT NOT NULL, "amount" REAL NOT NULL, "amount_minor" INTEGER NULL, "date" INTEGER NOT NULL, "account_id" TEXT NOT NULL REFERENCES accounts (id), "category_id" TEXT NOT NULL REFERENCES categories (id), "currency_code" TEXT NOT NULL REFERENCES currencies (code), "exchange_rate" REAL NULL, "exchange_rate_preset" INTEGER NULL, "fee" REAL NOT NULL DEFAULT 0.0, "fee_minor" INTEGER NULL, "linked_transaction_id" TEXT NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "exchange_rates" ("from_currency_code" TEXT NOT NULL REFERENCES currencies (code), "to_currency_code" TEXT NOT NULL REFERENCES currencies (code), "rate" REAL NOT NULL, "preset" INTEGER NOT NULL, "date" INTEGER NOT NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "source_id" TEXT NULL, PRIMARY KEY ("from_currency_code", "to_currency_code", "date", "preset"));
      CREATE TABLE "inflation_rates" ("date" INTEGER NOT NULL, "percent" REAL NOT NULL, "country" TEXT NOT NULL DEFAULT 'global', "preset" INTEGER NOT NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "source_id" TEXT NULL, PRIMARY KEY ("date", "country", "preset"));
      CREATE TABLE "asset_entries" ("id" TEXT NOT NULL, "asset_id" TEXT NOT NULL, "name" TEXT NOT NULL, "date" INTEGER NOT NULL, "value" REAL NOT NULL, "quantity" REAL NOT NULL DEFAULT 1.0, "asset_type" TEXT NULL, "description" TEXT NULL, "currency_code" TEXT NOT NULL REFERENCES currencies (code), "account_id" TEXT NULL REFERENCES accounts (id), "source" TEXT NOT NULL, "preset" INTEGER NOT NULL DEFAULT 1, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "source_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "settings" ("key" TEXT NOT NULL, "value" TEXT NOT NULL, "device" TEXT NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, PRIMARY KEY ("key"));
      CREATE TABLE "custom_themes" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "primary_color_hex" TEXT NOT NULL, "secondary_color_hex" TEXT NOT NULL, "surface_color_hex" TEXT NOT NULL, "background_color_hex" TEXT NOT NULL, "background_image_path" TEXT NULL, "background_image_opacity" REAL NOT NULL DEFAULT 1.0, "background_image_blur" REAL NOT NULL DEFAULT 0.0, "window_effect_type" INTEGER NOT NULL, "effect_opacity" REAL NOT NULL DEFAULT 1.0, "surface_opacity" REAL NOT NULL DEFAULT 1.0, "theme_mode" INTEGER NOT NULL, "is_preset" INTEGER NOT NULL DEFAULT 0, "is_active" INTEGER NOT NULL DEFAULT 0, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "sync_log" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "changed_table_name" TEXT NOT NULL, "record_id" TEXT NOT NULL, "action" TEXT NOT NULL, "timestamp" INTEGER NOT NULL, "exported" INTEGER NOT NULL DEFAULT 0);
      CREATE TABLE "conflict_history" ("id" TEXT NOT NULL, "changed_table_name" TEXT NOT NULL, "record_id" TEXT NOT NULL, "rejected_data" TEXT NOT NULL, "rejected_at" INTEGER NOT NULL, "rejected_device" TEXT NULL, PRIMARY KEY ("id"));
      CREATE TABLE "custom_data_sources" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "url" TEXT NOT NULL, "data_type" INTEGER NOT NULL, "enabled" INTEGER NOT NULL DEFAULT 1, "auto_fetch" INTEGER NOT NULL DEFAULT 0, "last_fetch_at" INTEGER NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "api_settings_table" ("id" TEXT NOT NULL, "enabled" INTEGER NOT NULL DEFAULT 1, "auto_fetch" INTEGER NOT NULL DEFAULT 0, "last_fetch_at" INTEGER NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, PRIMARY KEY ("id"));
      CREATE TABLE "api_fetch_statuses" ("id" TEXT NOT NULL, "attempts" INTEGER NOT NULL DEFAULT 0, "last_attempt" INTEGER NULL, "status" TEXT NOT NULL DEFAULT 'pending', PRIMARY KEY ("id"));
      CREATE TABLE "sms_presets" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "sender_filter" TEXT NOT NULL, "is_built_in" INTEGER NOT NULL DEFAULT 0, "is_enabled" INTEGER NOT NULL DEFAULT 1, "default_account_id" TEXT NULL, "default_category_id" TEXT NULL, "rules_json" TEXT NOT NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "sync_processed_files" ("file_name" TEXT NOT NULL, "processed_at" INTEGER NOT NULL, "device_id" TEXT NOT NULL, PRIMARY KEY ("file_name"));
    ''';

    // A user's database on the day of the upgrade. The euro account's stored
    // balance is what the running total had reached: the opening 1200.00, plus
    // 34.56 of euro transactions, plus a soft-deleted euro transaction that was
    // already reverted when it was deleted, and NOT the 100 USD row, which the
    // account was never converted into.
    const seedSql = '''
      INSERT INTO languages (language, language_code) VALUES ('English','en');
      INSERT INTO currencies (name, code, language_code, type) VALUES ('Euro','EUR','en',0);
      INSERT INTO currencies (name, code, language_code, type) VALUES ('Dollar','USD','en',0);
      INSERT INTO currencies (name, code, language_code, type) VALUES ('Yen','JPY','en',0);
      INSERT INTO currencies (name, code, language_code, type) VALUES ('Bitcoin','BTC','en',1);
      INSERT INTO currency_designations (id, value, currency_code) VALUES ('d1','€','EUR');
      INSERT INTO account_types (id, name, language_code) VALUES ('at1','Checking','en');
      INSERT INTO categories (id, name) VALUES ('c1','Groceries');
      INSERT INTO accounts (id, name, balance, balance_minor, currency_code, currency_designation_id, account_type_id, creation_date)
        VALUES ('accEur', 'Eur Wallet', 1234.56, 123456, 'EUR', 'd1', 'at1', 0);
      INSERT INTO accounts (id, name, balance, balance_minor, currency_code, currency_designation_id, account_type_id, creation_date)
        VALUES ('accJpy', 'Yen Wallet', 15000.0, 15000, 'JPY', 'd1', 'at1', 0);
      INSERT INTO accounts (id, name, balance, balance_minor, currency_code, currency_designation_id, account_type_id, creation_date)
        VALUES ('accBtc', 'Btc Wallet', 0.5, NULL, 'BTC', 'd1', 'at1', 0);
      INSERT INTO transactions (id, description, amount, amount_minor, date, account_id, category_id, currency_code)
        VALUES ('t1', 'Weekly shop', 10.10, 1010, 0, 'accEur', 'c1', 'EUR');
      INSERT INTO transactions (id, description, amount, amount_minor, date, account_id, category_id, currency_code)
        VALUES ('t2', 'Refund', 24.46, 2446, 0, 'accEur', 'c1', 'EUR');
      INSERT INTO transactions (id, description, amount, amount_minor, date, account_id, category_id, currency_code, is_deleted)
        VALUES ('t3', 'Cancelled', 500.00, 50000, 0, 'accEur', 'c1', 'EUR', 1);
      INSERT INTO transactions (id, description, amount, amount_minor, date, account_id, category_id, currency_code)
        VALUES ('t4', 'Hotel in dollars', 100.0, 10000, 0, 'accEur', 'c1', 'USD');
      INSERT INTO transactions (id, description, amount, amount_minor, date, account_id, category_id, currency_code)
        VALUES ('t5', 'Lunch', 500.0, 500, 0, 'accJpy', 'c1', 'JPY');
      INSERT INTO transactions (id, description, amount, amount_minor, date, account_id, category_id, currency_code)
        VALUES ('t6', 'Sats', 0.25, NULL, 0, 'accBtc', 'c1', 'BTC');
    ''';

    late AppDatabase db;

    setUp(() async {
      final file = File('${tempDir.path}/v10.sqlite');
      final raw = sqlite3.sqlite3.open(file.path);
      raw.execute(createV10Sql);
      raw.execute(seedSql);
      raw.execute('PRAGMA user_version = 10;');
      raw.dispose();

      db = AppDatabase.forTesting(NativeDatabase(file));
      await db.customSelect('SELECT 1').get();
    });

    tearDown(() async => db.close());

    Future<DbAccount> account(String id) =>
        (db.select(db.accounts)..where((a) => a.id.equals(id))).getSingle();

    test('nobody\'s balance moves', () async {
      expect((await account('accEur')).balance, 1234.56);
      expect((await account('accEur')).balanceMinor, 123456);
      expect((await account('accJpy')).balanceMinor, 15000);
      expect((await account('accBtc')).balance, 0.5);
    });

    test(
      'the first rebuild reproduces the balance the user had, exactly',
      () async {
        // The whole point of the anchor: it is only worth having if rebuilding
        // from it is a no-op on the day it is introduced. If this drifts, every
        // upgraded device silently restates its owner's money.
        await db.accountsDao.recomputeBalances(['accEur', 'accJpy', 'accBtc']);

        expect((await account('accEur')).balanceMinor, 123456);
        expect((await account('accEur')).balance, 1234.56);
        expect((await account('accJpy')).balanceMinor, 15000);
        expect((await account('accBtc')).balance, closeTo(0.5, 1e-12));
      },
    );

    test(
      'the anchor is the balance minus the transactions that built it',
      () async {
        final eur = await account('accEur');
        // 123456 minus t1 and t2; the soft-deleted t3 was already taken out of
        // the balance when it was deleted, and the dollar row never went in.
        expect(eur.openingBalanceMinor, 120000);
        expect(eur.openingBalance, 1200.0);
      },
    );

    test('a zero-decimal currency is not assumed to have cents', () async {
      final jpy = await account('accJpy');
      expect(jpy.openingBalanceMinor, 14500);
      expect(jpy.openingBalance, 14500.0);
    });

    test(
      'a crypto account keeps NULL minor units and anchors on the double',
      () async {
        final btc = await account('accBtc');
        expect(btc.openingBalanceMinor, isNull);
        expect(btc.openingBalance, closeTo(0.25, 1e-12));
      },
    );

    test('adds the anchor without dropping any other column', () async {
      final cols = await db.customSelect("PRAGMA table_info('accounts')").get();
      final names = cols.map((r) => r.data['name'] as String).toSet();
      expect(names, containsAll(['opening_balance', 'opening_balance_minor']));
      expect(names, containsAll(['balance', 'balance_minor', 'is_deleted']));
    });
  });

  group('v11 -> v12 migration (adds is_deleted to api_settings_table)', () {
    // v11 == the v10 fixture plus the two opening-balance columns the v10->v11
    // step adds to accounts, which is all that separates the two versions.
    const createV11Sql = '''
      CREATE TABLE "languages" ("language" TEXT NOT NULL, "language_code" TEXT NOT NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, PRIMARY KEY ("language_code"));
      CREATE TABLE "currencies" ("name" TEXT NOT NULL UNIQUE, "code" TEXT NOT NULL, "language_code" TEXT NOT NULL REFERENCES languages (language_code), "type" INTEGER NOT NULL DEFAULT 6, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, PRIMARY KEY ("code"));
      CREATE TABLE "currency_designations" ("id" TEXT NOT NULL, "value" TEXT NOT NULL, "currency_code" TEXT NOT NULL REFERENCES currencies (code), "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "account_types" ("id" TEXT NOT NULL, "name" TEXT NOT NULL UNIQUE, "language_code" TEXT NOT NULL REFERENCES languages (language_code), "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "styles" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "icon_name" TEXT NOT NULL, "color_hex" TEXT NOT NULL, "icon_type" INTEGER NOT NULL DEFAULT 0, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "categories" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "parent_id" TEXT NULL REFERENCES categories (id), "style_id" TEXT NULL REFERENCES styles (id), "type" INTEGER NOT NULL DEFAULT 0, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "accounts" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "description" TEXT NULL, "balance" REAL NOT NULL, "balance_minor" INTEGER NULL, "opening_balance" REAL NOT NULL DEFAULT 0.0, "opening_balance_minor" INTEGER NULL, "currency_code" TEXT NOT NULL REFERENCES currencies (code), "currency_designation_id" TEXT NOT NULL REFERENCES currency_designations (id), "style_id" TEXT NULL REFERENCES styles (id), "account_type_id" TEXT NOT NULL REFERENCES account_types (id), "creation_date" INTEGER NOT NULL, "country" TEXT NULL, "asset_id" TEXT NULL, "asset_quantity" REAL NOT NULL DEFAULT 0.0, "fee_structure" TEXT NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "transactions" ("id" TEXT NOT NULL, "description" TEXT NOT NULL, "amount" REAL NOT NULL, "amount_minor" INTEGER NULL, "date" INTEGER NOT NULL, "account_id" TEXT NOT NULL REFERENCES accounts (id), "category_id" TEXT NOT NULL REFERENCES categories (id), "currency_code" TEXT NOT NULL REFERENCES currencies (code), "exchange_rate" REAL NULL, "exchange_rate_preset" INTEGER NULL, "fee" REAL NOT NULL DEFAULT 0.0, "fee_minor" INTEGER NULL, "linked_transaction_id" TEXT NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "exchange_rates" ("from_currency_code" TEXT NOT NULL REFERENCES currencies (code), "to_currency_code" TEXT NOT NULL REFERENCES currencies (code), "rate" REAL NOT NULL, "preset" INTEGER NOT NULL, "date" INTEGER NOT NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "source_id" TEXT NULL, PRIMARY KEY ("from_currency_code", "to_currency_code", "date", "preset"));
      CREATE TABLE "inflation_rates" ("date" INTEGER NOT NULL, "percent" REAL NOT NULL, "country" TEXT NOT NULL DEFAULT 'global', "preset" INTEGER NOT NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "source_id" TEXT NULL, PRIMARY KEY ("date", "country", "preset"));
      CREATE TABLE "asset_entries" ("id" TEXT NOT NULL, "asset_id" TEXT NOT NULL, "name" TEXT NOT NULL, "date" INTEGER NOT NULL, "value" REAL NOT NULL, "quantity" REAL NOT NULL DEFAULT 1.0, "asset_type" TEXT NULL, "description" TEXT NULL, "currency_code" TEXT NOT NULL REFERENCES currencies (code), "account_id" TEXT NULL REFERENCES accounts (id), "source" TEXT NOT NULL, "preset" INTEGER NOT NULL DEFAULT 1, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "source_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "settings" ("key" TEXT NOT NULL, "value" TEXT NOT NULL, "device" TEXT NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, PRIMARY KEY ("key"));
      CREATE TABLE "custom_themes" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "primary_color_hex" TEXT NOT NULL, "secondary_color_hex" TEXT NOT NULL, "surface_color_hex" TEXT NOT NULL, "background_color_hex" TEXT NOT NULL, "background_image_path" TEXT NULL, "background_image_opacity" REAL NOT NULL DEFAULT 1.0, "background_image_blur" REAL NOT NULL DEFAULT 0.0, "window_effect_type" INTEGER NOT NULL, "effect_opacity" REAL NOT NULL DEFAULT 1.0, "surface_opacity" REAL NOT NULL DEFAULT 1.0, "theme_mode" INTEGER NOT NULL, "is_preset" INTEGER NOT NULL DEFAULT 0, "is_active" INTEGER NOT NULL DEFAULT 0, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "sync_log" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "changed_table_name" TEXT NOT NULL, "record_id" TEXT NOT NULL, "action" TEXT NOT NULL, "timestamp" INTEGER NOT NULL, "exported" INTEGER NOT NULL DEFAULT 0);
      CREATE TABLE "conflict_history" ("id" TEXT NOT NULL, "changed_table_name" TEXT NOT NULL, "record_id" TEXT NOT NULL, "rejected_data" TEXT NOT NULL, "rejected_at" INTEGER NOT NULL, "rejected_device" TEXT NULL, PRIMARY KEY ("id"));
      CREATE TABLE "custom_data_sources" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "url" TEXT NOT NULL, "data_type" INTEGER NOT NULL, "enabled" INTEGER NOT NULL DEFAULT 1, "auto_fetch" INTEGER NOT NULL DEFAULT 0, "last_fetch_at" INTEGER NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "api_settings_table" ("id" TEXT NOT NULL, "enabled" INTEGER NOT NULL DEFAULT 1, "auto_fetch" INTEGER NOT NULL DEFAULT 0, "last_fetch_at" INTEGER NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, PRIMARY KEY ("id"));
      CREATE TABLE "api_fetch_statuses" ("id" TEXT NOT NULL, "attempts" INTEGER NOT NULL DEFAULT 0, "last_attempt" INTEGER NULL, "status" TEXT NOT NULL DEFAULT 'pending', PRIMARY KEY ("id"));
      CREATE TABLE "sms_presets" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "sender_filter" TEXT NOT NULL, "is_built_in" INTEGER NOT NULL DEFAULT 0, "is_enabled" INTEGER NOT NULL DEFAULT 1, "default_account_id" TEXT NULL, "default_category_id" TEXT NULL, "rules_json" TEXT NOT NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "sync_processed_files" ("file_name" TEXT NOT NULL, "processed_at" INTEGER NOT NULL, "device_id" TEXT NOT NULL, PRIMARY KEY ("file_name"));
    ''';

    // A device mid-life: providers the user has configured by hand, an account
    // with money on it, and a custom data source - none of which the new column
    // has any business touching.
    const seedSql = '''
      INSERT INTO languages (language, language_code) VALUES ('English','en');
      INSERT INTO currencies (name, code, language_code, type) VALUES ('Euro','EUR','en',0);
      INSERT INTO currency_designations (id, value, currency_code) VALUES ('d1','€','EUR');
      INSERT INTO account_types (id, name, language_code) VALUES ('at1','Checking','en');
      INSERT INTO categories (id, name) VALUES ('c1','Groceries');
      INSERT INTO accounts (id, name, balance, balance_minor, opening_balance, opening_balance_minor, currency_code, currency_designation_id, account_type_id, creation_date)
        VALUES ('accEur', 'Eur Wallet', 1234.56, 123456, 1200.0, 120000, 'EUR', 'd1', 'at1', 0);
      INSERT INTO transactions (id, description, amount, amount_minor, date, account_id, category_id, currency_code)
        VALUES ('t1', 'Weekly shop', 34.56, 3456, 0, 'accEur', 'c1', 'EUR');
      INSERT INTO api_settings_table (id, enabled, auto_fetch, last_fetch_at, modified_at, device_id)
        VALUES ('exchange_rates', 0, 0, 1700000000000, 1700000000001, 'old-device');
      INSERT INTO api_settings_table (id, enabled, auto_fetch, modified_at)
        VALUES ('inflation', 1, 1, 1700000000002);
      INSERT INTO custom_data_sources (id, name, url, data_type, enabled, auto_fetch)
        VALUES ('src1', 'My rates', 'https://example.test', 0, 1, 0);
    ''';

    late AppDatabase db;

    setUp(() async {
      final file = File('${tempDir.path}/v11.sqlite');
      final raw = sqlite3.sqlite3.open(file.path);
      raw.execute(createV11Sql);
      raw.execute(seedSql);
      raw.execute('PRAGMA user_version = 11;');
      raw.dispose();

      db = AppDatabase.forTesting(NativeDatabase(file));
      await db.customSelect('SELECT 1').get();
    });

    tearDown(() async => db.close());

    test('adds is_deleted to api_settings_table', () async {
      final cols = await db
          .customSelect("PRAGMA table_info('api_settings_table')")
          .get();
      final names = cols.map((r) => r.data['name'] as String).toSet();
      expect(names, contains('is_deleted'));
    });

    test('every existing provider row survives, live and unchanged', () async {
      // The column is what a delete is recorded in, so an upgrade that defaulted
      // rows to deleted would silently switch every provider off.
      final rates = await db.apiSettingsDao.getSettingById('exchange_rates');
      expect(rates, isNotNull);
      expect(rates!.enabled, isFalse, reason: 'the user turned this one off');
      expect(rates.autoFetch, isFalse);
      expect(rates.lastFetchAt, 1700000000000);
      expect(rates.modifiedAt, 1700000000001);
      expect(rates.deviceId, 'old-device');
      expect(rates.isDeleted, isFalse);

      final inflation = await db.apiSettingsDao.getSettingById('inflation');
      expect(inflation!.enabled, isTrue);
      expect(inflation.autoFetch, isTrue);
      expect(inflation.isDeleted, isFalse);
    });

    test('the rest of the database is untouched', () async {
      final account = await (db.select(
        db.accounts,
      )..where((a) => a.id.equals('accEur'))).getSingle();
      expect(account.balanceMinor, 123456);
      expect(account.openingBalanceMinor, 120000);

      final tx = await (db.select(
        db.transactions,
      )..where((t) => t.id.equals('t1'))).getSingle();
      expect(tx.amountMinor, 3456);

      expect(
        await db.customDataSourcesDao.getDataSourceById('src1'),
        isNotNull,
      );
    });

    test('lands on the current schema version', () async {
      final row = await db.customSelect('PRAGMA user_version').getSingle();
      expect(row.data['user_version'], db.schemaVersion);
    });

    test(
      'a database that already has the column upgrades without error',
      () async {
        // The step is re-runnable: a device that took an interim build carrying
        // the column must not hit "duplicate column name" and be stuck on every
        // launch.
        final file = File('${tempDir.path}/v11_with_column.sqlite');
        final raw = sqlite3.sqlite3.open(file.path);
        raw.execute(createV11Sql);
        raw.execute(
          'ALTER TABLE api_settings_table ADD COLUMN "is_deleted" INTEGER NOT '
          'NULL DEFAULT 0;',
        );
        raw.execute(seedSql);
        raw.execute('PRAGMA user_version = 11;');
        raw.dispose();

        final upgraded = AppDatabase.forTesting(NativeDatabase(file));
        await expectLater(upgraded.customSelect('SELECT 1').get(), completes);
        expect(
          await upgraded.apiSettingsDao.getSettingById('exchange_rates'),
          isNotNull,
        );
        await upgraded.close();
      },
    );
  });

  group('v12 -> v13 migration (adds the server push queue)', () {
    // v12 == the v11 fixture plus the tombstone the v11->v12 step adds to
    // api_settings_table, which is all that separates the two versions.
    const createV12Sql = '''
      CREATE TABLE "languages" ("language" TEXT NOT NULL, "language_code" TEXT NOT NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, PRIMARY KEY ("language_code"));
      CREATE TABLE "currencies" ("name" TEXT NOT NULL UNIQUE, "code" TEXT NOT NULL, "language_code" TEXT NOT NULL REFERENCES languages (language_code), "type" INTEGER NOT NULL DEFAULT 6, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, PRIMARY KEY ("code"));
      CREATE TABLE "currency_designations" ("id" TEXT NOT NULL, "value" TEXT NOT NULL, "currency_code" TEXT NOT NULL REFERENCES currencies (code), "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "account_types" ("id" TEXT NOT NULL, "name" TEXT NOT NULL UNIQUE, "language_code" TEXT NOT NULL REFERENCES languages (language_code), "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "styles" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "icon_name" TEXT NOT NULL, "color_hex" TEXT NOT NULL, "icon_type" INTEGER NOT NULL DEFAULT 0, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "categories" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "parent_id" TEXT NULL REFERENCES categories (id), "style_id" TEXT NULL REFERENCES styles (id), "type" INTEGER NOT NULL DEFAULT 0, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "accounts" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "description" TEXT NULL, "balance" REAL NOT NULL, "balance_minor" INTEGER NULL, "opening_balance" REAL NOT NULL DEFAULT 0.0, "opening_balance_minor" INTEGER NULL, "currency_code" TEXT NOT NULL REFERENCES currencies (code), "currency_designation_id" TEXT NOT NULL REFERENCES currency_designations (id), "style_id" TEXT NULL REFERENCES styles (id), "account_type_id" TEXT NOT NULL REFERENCES account_types (id), "creation_date" INTEGER NOT NULL, "country" TEXT NULL, "asset_id" TEXT NULL, "asset_quantity" REAL NOT NULL DEFAULT 0.0, "fee_structure" TEXT NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "transactions" ("id" TEXT NOT NULL, "description" TEXT NOT NULL, "amount" REAL NOT NULL, "amount_minor" INTEGER NULL, "date" INTEGER NOT NULL, "account_id" TEXT NOT NULL REFERENCES accounts (id), "category_id" TEXT NOT NULL REFERENCES categories (id), "currency_code" TEXT NOT NULL REFERENCES currencies (code), "exchange_rate" REAL NULL, "exchange_rate_preset" INTEGER NULL, "fee" REAL NOT NULL DEFAULT 0.0, "fee_minor" INTEGER NULL, "linked_transaction_id" TEXT NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "exchange_rates" ("from_currency_code" TEXT NOT NULL REFERENCES currencies (code), "to_currency_code" TEXT NOT NULL REFERENCES currencies (code), "rate" REAL NOT NULL, "preset" INTEGER NOT NULL, "date" INTEGER NOT NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "source_id" TEXT NULL, PRIMARY KEY ("from_currency_code", "to_currency_code", "date", "preset"));
      CREATE TABLE "inflation_rates" ("date" INTEGER NOT NULL, "percent" REAL NOT NULL, "country" TEXT NOT NULL DEFAULT 'global', "preset" INTEGER NOT NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "source_id" TEXT NULL, PRIMARY KEY ("date", "country", "preset"));
      CREATE TABLE "asset_entries" ("id" TEXT NOT NULL, "asset_id" TEXT NOT NULL, "name" TEXT NOT NULL, "date" INTEGER NOT NULL, "value" REAL NOT NULL, "quantity" REAL NOT NULL DEFAULT 1.0, "asset_type" TEXT NULL, "description" TEXT NULL, "currency_code" TEXT NOT NULL REFERENCES currencies (code), "account_id" TEXT NULL REFERENCES accounts (id), "source" TEXT NOT NULL, "preset" INTEGER NOT NULL DEFAULT 1, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "source_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "settings" ("key" TEXT NOT NULL, "value" TEXT NOT NULL, "device" TEXT NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, PRIMARY KEY ("key"));
      CREATE TABLE "custom_themes" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "primary_color_hex" TEXT NOT NULL, "secondary_color_hex" TEXT NOT NULL, "surface_color_hex" TEXT NOT NULL, "background_color_hex" TEXT NOT NULL, "background_image_path" TEXT NULL, "background_image_opacity" REAL NOT NULL DEFAULT 1.0, "background_image_blur" REAL NOT NULL DEFAULT 0.0, "window_effect_type" INTEGER NOT NULL, "effect_opacity" REAL NOT NULL DEFAULT 1.0, "surface_opacity" REAL NOT NULL DEFAULT 1.0, "theme_mode" INTEGER NOT NULL, "is_preset" INTEGER NOT NULL DEFAULT 0, "is_active" INTEGER NOT NULL DEFAULT 0, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "sync_log" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "changed_table_name" TEXT NOT NULL, "record_id" TEXT NOT NULL, "action" TEXT NOT NULL, "timestamp" INTEGER NOT NULL, "exported" INTEGER NOT NULL DEFAULT 0);
      CREATE TABLE "conflict_history" ("id" TEXT NOT NULL, "changed_table_name" TEXT NOT NULL, "record_id" TEXT NOT NULL, "rejected_data" TEXT NOT NULL, "rejected_at" INTEGER NOT NULL, "rejected_device" TEXT NULL, PRIMARY KEY ("id"));
      CREATE TABLE "custom_data_sources" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "url" TEXT NOT NULL, "data_type" INTEGER NOT NULL, "enabled" INTEGER NOT NULL DEFAULT 1, "auto_fetch" INTEGER NOT NULL DEFAULT 0, "last_fetch_at" INTEGER NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "api_settings_table" ("id" TEXT NOT NULL, "enabled" INTEGER NOT NULL DEFAULT 1, "auto_fetch" INTEGER NOT NULL DEFAULT 0, "last_fetch_at" INTEGER NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "api_fetch_statuses" ("id" TEXT NOT NULL, "attempts" INTEGER NOT NULL DEFAULT 0, "last_attempt" INTEGER NULL, "status" TEXT NOT NULL DEFAULT 'pending', PRIMARY KEY ("id"));
      CREATE TABLE "sms_presets" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "sender_filter" TEXT NOT NULL, "is_built_in" INTEGER NOT NULL DEFAULT 0, "is_enabled" INTEGER NOT NULL DEFAULT 1, "default_account_id" TEXT NULL, "default_category_id" TEXT NULL, "rules_json" TEXT NOT NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "sync_processed_files" ("file_name" TEXT NOT NULL, "processed_at" INTEGER NOT NULL, "device_id" TEXT NOT NULL, PRIMARY KEY ("file_name"));
    ''';

    // A device that has been running for a while. `modified_at` values are
    // deliberately tiny: under the old scheme every one of these rows sat far
    // below `server_last_push_timestamp`, which is exactly why the upgrade has
    // to assume none of them ever reached the server.
    const seedSql = '''
      INSERT INTO languages (language, language_code) VALUES ('English','en');
      INSERT INTO currencies (name, code, language_code, type) VALUES ('Euro','EUR','en',0);
      INSERT INTO currency_designations (id, value, currency_code) VALUES ('d1','€','EUR');
      INSERT INTO account_types (id, name, language_code) VALUES ('at1','Checking','en');
      INSERT INTO categories (id, name, modified_at) VALUES ('c1','Groceries',1);
      INSERT INTO accounts (id, name, balance, currency_code, currency_designation_id, account_type_id, creation_date, modified_at)
        VALUES ('accEur', 'Eur Wallet', 1234.56, 'EUR', 'd1', 'at1', 0, 1);
      INSERT INTO transactions (id, description, amount, date, account_id, category_id, currency_code, modified_at)
        VALUES ('t1', 'Weekly shop', 34.56, 0, 'accEur', 'c1', 'EUR', 1);
      INSERT INTO exchange_rates (from_currency_code, to_currency_code, rate, preset, date, modified_at)
        VALUES ('EUR','EUR',1.0,7,1700000000,1);
      INSERT INTO api_settings_table (id, enabled, auto_fetch, modified_at) VALUES ('exchange_rates', 1, 1, 1);
    ''';

    late AppDatabase db;

    Future<Set<String>> queuedKeysFor(AppDatabase target, String table) async {
      final rows = await target
          .customSelect(
            'SELECT record_key FROM sync_push_queue '
            'WHERE changed_table_name = ?',
            variables: [Variable.withString(table)],
          )
          .get();
      return rows.map((r) => r.read<String>('record_key')).toSet();
    }

    setUp(() async {
      final file = File('${tempDir.path}/v12.sqlite');
      final raw = sqlite3.sqlite3.open(file.path);
      raw.execute(createV12Sql);
      raw.execute(seedSql);
      raw.execute('PRAGMA user_version = 12;');
      raw.dispose();

      db = AppDatabase.forTesting(NativeDatabase(file));
      await db.customSelect('SELECT 1').get();
    });

    tearDown(() async => db.close());

    test(
      'creates sync_push_queue and lands on the current schema version',
      () async {
        final tables = await db
            .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
            .get();
        expect(
          tables.map((r) => r.read<String>('name')),
          contains('sync_push_queue'),
        );

        final version = await db
            .customSelect('PRAGMA user_version')
            .getSingle();
        expect(version.data['user_version'], db.schemaVersion);
      },
    );

    test('seeds the queue from every row the device already had', () async {
      // The old watermark lived in SharedPreferences and is unreachable from a
      // migration, so there is no way to tell which of these the server has.
      // Assuming "none" costs one full push; assuming "all" would keep exactly
      // the stranded rows stranded, forever.
      expect(await queuedKeysFor(db, 'accounts'), {'accEur'});
      expect(await queuedKeysFor(db, 'transactions'), {'t1'});
      // cat_subscriptions is not one of the device's own rows: the v19 step
      // inserts it on the way past, and the trigger queues it like any
      // other write. The other device has to hear about it too.
      expect(await queuedKeysFor(db, 'categories'), {
        'c1',
        'cat_subscriptions',
      });
      expect(await queuedKeysFor(db, 'api_settings_table'), {'exchange_rates'});
      expect(await queuedKeysFor(db, 'exchange_rates'), {
        'EUR|EUR|1700000000|7',
      });
    });

    test('the triggers are live afterwards', () async {
      await db.customStatement(
        "INSERT INTO styles (id, name, color_hex, icon_name, icon_type, "
        "modified_at, is_deleted) "
        "VALUES ('after', 'Made later', '#000000', 'star', 0, 5, 0)",
      );
      // style_subscriptions arrives the same way cat_subscriptions does,
      // in the v19 step this fixture's upgrade runs through.
      expect(await queuedKeysFor(db, 'styles'), {
        'style_subscriptions',
        'after',
      });

      await db.customStatement(
        "UPDATE styles SET name = 'Renamed', modified_at = 6 "
        "WHERE id = 'after'",
      );
      final rows = await db
          .customSelect(
            "SELECT COUNT(*) AS c FROM sync_push_queue "
            "WHERE changed_table_name = 'styles'",
          )
          .getSingle();
      // Three: the row the v19 step seeded, this insert, and its edit.
      expect(rows.read<int>('c'), 3, reason: 'an edit is a change to send too');
    });

    test('a write that does not move modified_at is not queued', () async {
      // A balance rebuild rewrites `balance` on purpose without stamping the
      // row - every peer derives that number for itself, and the server's
      // upsert is strict last-write-wins, so queueing it would upload a row the
      // server is guaranteed to discard after every single pull.
      await db.customStatement('DELETE FROM sync_push_queue');
      await db.customStatement(
        "UPDATE accounts SET balance = 999.0 WHERE id = 'accEur'",
      );

      expect(await queuedKeysFor(db, 'accounts'), isEmpty);
    });

    test('an upgrade that already ran does not seed the queue twice', () async {
      // The step is re-runnable like the ones before it: a device whose
      // upgrade died after the seed must not come back to a doubled backlog.
      final file = File('${tempDir.path}/v12_already_seeded.sqlite');
      final raw = sqlite3.sqlite3.open(file.path);
      raw.execute(createV12Sql);
      raw.execute(seedSql);
      raw.execute(
        'CREATE TABLE "sync_push_queue" ("id" INTEGER NOT NULL PRIMARY KEY '
        'AUTOINCREMENT, "changed_table_name" TEXT NOT NULL, "record_key" TEXT '
        'NOT NULL);',
      );
      raw.execute(
        "INSERT INTO sync_push_queue (changed_table_name, record_key) "
        "VALUES ('accounts', 'accEur');",
      );
      raw.execute('PRAGMA user_version = 12;');
      raw.dispose();

      final upgraded = AppDatabase.forTesting(NativeDatabase(file));
      await expectLater(upgraded.customSelect('SELECT 1').get(), completes);
      expect(await queuedKeysFor(upgraded, 'accounts'), {'accEur'});
      final accountEntries = await upgraded
          .customSelect(
            "SELECT COUNT(*) AS c FROM sync_push_queue "
            "WHERE changed_table_name = 'accounts'",
          )
          .getSingle();
      expect(accountEntries.read<int>('c'), 1);
      await upgraded.close();
    });
  });

  group('v13 -> v14 migration (indexes the push-queue record keys)', () {
    // Unlike the fixtures above, this one is not a hand-copied DDL dump: v13
    // and v14 differ by exactly two indexes and nothing else — no table, no
    // column, no row — so a v13 device is a current-schema database with those
    // two indexes dropped and `user_version` wound back. Building it that way
    // keeps the fixture exact for free; a future step that changes more than
    // indexes would need a spelled-out fixture like the ones above.
    late File file;

    // A device that has been running on v13: rows in both concatenated-key
    // tables, and a push queue that the v12->v13 seed already filled from them.
    const seedSql = '''
      INSERT INTO exchange_rates (from_currency_code, to_currency_code, rate, preset, date, modified_at)
        VALUES ('USD','EUR',0.91,0,1700000000,5);
      INSERT INTO exchange_rates (from_currency_code, to_currency_code, rate, preset, date, modified_at)
        VALUES ('USD','EUR',0.92,7,1700086400,6);
      INSERT INTO inflation_rates (date, percent, country, preset, modified_at)
        VALUES (1700000000, 2.5, 'global', 0, 7);
      INSERT INTO sync_push_queue (changed_table_name, record_key) VALUES ('exchange_rates', 'USD|EUR|1700000000|0');
      INSERT INTO sync_push_queue (changed_table_name, record_key) VALUES ('exchange_rates', 'USD|EUR|1700086400|7');
      INSERT INTO sync_push_queue (changed_table_name, record_key) VALUES ('inflation_rates', '1700000000|global|0');
    ''';

    setUp(() async {
      file = File('${tempDir.path}/v13.sqlite');
      // onCreate lays down the current schema...
      final fresh = AppDatabase.forTesting(NativeDatabase(file));
      await fresh.customSelect('SELECT 1').get();
      await fresh.close();

      // ...and this winds it back to what v13 shipped. The raw connection has
      // foreign_keys off by default, which is what lets the seed insert rates
      // without dragging the whole currency graph in with them.
      final raw = sqlite3.sqlite3.open(file.path);
      raw.execute('DROP INDEX IF EXISTS idx_exchange_rates_push_key;');
      raw.execute('DROP INDEX IF EXISTS idx_inflation_rates_push_key;');
      raw.execute('DELETE FROM sync_push_queue;');
      raw.execute(seedSql);
      raw.execute('PRAGMA user_version = 13;');
      raw.dispose();
    });

    test('creates both key indexes and lands on the current schema '
        'version', () async {
      final db = AppDatabase.forTesting(NativeDatabase(file));
      final indexes = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'index'")
          .get();
      expect(
        indexes.map((r) => r.read<String>('name')).toSet(),
        containsAll([
          'idx_exchange_rates_push_key',
          'idx_inflation_rates_push_key',
        ]),
      );

      final version = await db.customSelect('PRAGMA user_version').getSingle();
      expect(version.data['user_version'], db.schemaVersion);
      await db.close();
    });

    test('the push lookup stops scanning the rate tables', () async {
      // The point of the step: the backlog v12->v13 seeds is resolved 500 keys
      // at a time, and until this index existed every one of those chunks read
      // every row of the table.
      final db = AppDatabase.forTesting(NativeDatabase(file));
      for (final table in ['exchange_rates', 'inflation_rates']) {
        final plan = await db
            .customSelect(
              'EXPLAIN QUERY PLAN SELECT * FROM $table '
              'WHERE ${syncPushQueueKeyExpression(table)} IN (?, ?)',
              variables: [Variable.withString('a'), Variable.withString('b')],
            )
            .get();
        final detail = plan.map((r) => r.read<String>('detail')).join(' | ');
        expect(detail, isNot(contains('SCAN $table')));
        expect(
          detail,
          contains('USING INDEX ${syncPushQueueKeyIndexName(table)}'),
        );
      }
      await db.close();
    });

    test('no row and no queued entry is lost', () async {
      // An index-only step has to be invisible to the data. Asserted rather
      // than assumed because the queue is the list of edits that have not
      // reached the server yet: dropping an entry here drops an edit silently.
      final db = AppDatabase.forTesting(NativeDatabase(file));
      final rates = await db
          .customSelect('SELECT rate FROM exchange_rates ORDER BY date')
          .get();
      expect(rates.map((r) => r.read<double>('rate')), [0.91, 0.92]);

      final inflation = await db
          .customSelect('SELECT percent FROM inflation_rates')
          .get();
      expect(inflation.single.read<double>('percent'), 2.5);

      // Read per table rather than whole: opening this fixture runs every
      // step after v13 too, and v15->v16 adds the seeded foreign-key parents
      // to the same queue. What this test is about is that the entries the
      // fixture already had come out the other side.
      final queued = await db
          .customSelect(
            'SELECT record_key FROM sync_push_queue '
            "WHERE changed_table_name IN ('exchange_rates', 'inflation_rates')",
          )
          .get();
      expect(queued.map((r) => r.read<String>('record_key')).toSet(), {
        'USD|EUR|1700000000|0',
        'USD|EUR|1700086400|7',
        '1700000000|global|0',
      });
      await db.close();
    });

    test('a device that already has an index upgrades without error', () async {
      // Re-runnable like every step before it: an upgrade that died between the
      // two CREATEs must not come back to "index already exists" on every
      // launch and never reach the second one.
      final raw = sqlite3.sqlite3.open(file.path);
      raw.execute(
        'CREATE INDEX idx_exchange_rates_push_key ON exchange_rates '
        "(${syncPushQueueKeyExpression('exchange_rates')});",
      );
      raw.dispose();

      final db = AppDatabase.forTesting(NativeDatabase(file));
      await expectLater(db.customSelect('SELECT 1').get(), completes);
      final indexes = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'index'")
          .get();
      expect(
        indexes.map((r) => r.read<String>('name')).toSet(),
        containsAll([
          'idx_exchange_rates_push_key',
          'idx_inflation_rates_push_key',
        ]),
      );
      await db.close();
    });
  });

  group('v14 -> v15 migration (content-aware push-queue triggers)', () {
    // Same fixture trick as the group above, for the same reason: v14 and v15
    // differ by the body of one trigger per table and nothing else. So a v14
    // device is a current-schema database whose update triggers have been put
    // back the way v13 wrote them, with `user_version` wound back.
    late File file;

    void writeV14UpdateTriggers(sqlite3.Database raw) {
      for (final table in syncPushQueueTables) {
        final key = syncPushQueueKeyExpression(table, prefix: 'NEW.');
        raw.execute('DROP TRIGGER IF EXISTS trg_push_queue_${table}_update;');
        raw.execute(
          'CREATE TRIGGER trg_push_queue_${table}_update '
          'AFTER UPDATE ON $table '
          'WHEN NEW.modified_at IS NOT OLD.modified_at BEGIN '
          'INSERT INTO sync_push_queue (changed_table_name, record_key) '
          "VALUES ('$table', $key); END;",
        );
      }
    }

    Future<Set<String>> queuedKeysFor(AppDatabase target, String table) async {
      final rows = await target
          .customSelect(
            'SELECT record_key FROM sync_push_queue '
            'WHERE changed_table_name = ?',
            variables: [Variable.withString(table)],
          )
          .get();
      return rows.map((r) => r.read<String>('record_key')).toSet();
    }

    setUp(() async {
      file = File('${tempDir.path}/v14.sqlite');
      if (file.existsSync()) file.deleteSync();
      final fresh = AppDatabase.forTesting(NativeDatabase(file));
      await fresh.customSelect('SELECT 1').get();
      await fresh.close();

      final raw = sqlite3.sqlite3.open(file.path);
      writeV14UpdateTriggers(raw);
      // OR REPLACE because onCreate seeds this provider itself: what the
      // fixture needs is a known starting state, not a second row.
      raw.execute(
        "INSERT OR REPLACE INTO api_settings_table (id, enabled, auto_fetch, "
        "last_fetch_at, modified_at, is_deleted) "
        "VALUES ('exchange_rates', 1, 1, NULL, 1, 0);",
      );
      raw.execute('DELETE FROM sync_push_queue;');
      raw.execute('PRAGMA user_version = 14;');
      raw.dispose();
    });

    test('the v14 trigger is what was dropping the tombstone', () async {
      // Not a test of the fix - a test that the fixture reproduces the defect,
      // so the assertions below cannot pass for some unrelated reason. Seeding
      // a provider and deleting it inside one millisecond leaves `modified_at`
      // untouched, and v14 asked about nothing else.
      final raw = sqlite3.sqlite3.open(file.path);
      raw.execute(
        "UPDATE api_settings_table SET is_deleted = 1 "
        "WHERE id = 'exchange_rates';",
      );
      final queued = raw.select('SELECT record_key FROM sync_push_queue');
      raw.dispose();
      expect(queued, isEmpty);
    });

    test('a delete that does not move modified_at is queued now', () async {
      final db = AppDatabase.forTesting(NativeDatabase(file));
      await db.customStatement('DELETE FROM sync_push_queue');
      await db.customStatement(
        "UPDATE api_settings_table SET is_deleted = 1 "
        "WHERE id = 'exchange_rates'",
      );
      expect(await queuedKeysFor(db, 'api_settings_table'), {'exchange_rates'});
      await db.close();
    });

    test('a value arriving in a NULL column is queued too', () async {
      // `<>` would read this as NULL and skip it, which is why the clause is
      // built out of `IS NOT`.
      final db = AppDatabase.forTesting(NativeDatabase(file));
      await db.customStatement('DELETE FROM sync_push_queue');
      await db.customStatement(
        "UPDATE api_settings_table SET last_fetch_at = 42 "
        "WHERE id = 'exchange_rates'",
      );
      expect(await queuedKeysFor(db, 'api_settings_table'), {'exchange_rates'});
      await db.close();
    });

    test('a balance rebuild is still not queued', () async {
      // The one thing the content test must NOT pick up: every peer derives
      // `balance` for itself, and the server discards what it is sent, so
      // queueing a rebuild uploads a row that is guaranteed to be thrown away.
      final db = AppDatabase.forTesting(NativeDatabase(file));
      await db.customStatement(
        "INSERT INTO languages (language, language_code) "
        "VALUES ('Testish','xx')",
      );
      await db.customStatement(
        "INSERT INTO currencies (name, code, language_code, type) "
        "VALUES ('Testo','TS1','xx',0)",
      );
      await db.customStatement(
        "INSERT INTO currency_designations (id, value, currency_code) "
        "VALUES ('dTs','T','TS1')",
      );
      await db.customStatement(
        "INSERT INTO account_types (id, name, language_code) "
        "VALUES ('atTs','ZZ Test Type','xx')",
      );
      await db.customStatement(
        "INSERT INTO accounts (id, name, balance, currency_code, "
        "currency_designation_id, account_type_id, creation_date, modified_at) "
        "VALUES ('accTs','Test Wallet',1234.56,'TS1','dTs','atTs',0,1)",
      );
      await db.customStatement('DELETE FROM sync_push_queue');

      await db.customStatement(
        "UPDATE accounts SET balance = 999.0, balance_minor = 99900 "
        "WHERE id = 'accTs'",
      );
      expect(await queuedKeysFor(db, 'accounts'), isEmpty);

      // ...but a rename of the same row still is.
      await db.customStatement(
        "UPDATE accounts SET name = 'Renamed' WHERE id = 'accTs'",
      );
      expect(await queuedKeysFor(db, 'accounts'), {'accTs'});
      await db.close();
    });

    test('every update trigger is rewritten, not just one', () async {
      final db = AppDatabase.forTesting(NativeDatabase(file));
      final triggers = await db
          .customSelect(
            "SELECT name, sql FROM sqlite_master WHERE type = 'trigger' "
            "AND name LIKE 'trg_push_queue_%_update'",
          )
          .get();
      expect(triggers.length, syncPushQueueTables.length);
      for (final trigger in triggers) {
        final when = trigger.read<String>('sql').split('BEGIN').first;
        expect(
          when,
          isNot(endsWith('WHEN NEW.modified_at IS NOT OLD.modified_at ')),
          reason: '${trigger.read<String>('name')} kept its v14 body',
        );
      }

      final accounts = triggers.firstWhere(
        (t) => t.read<String>('name') == 'trg_push_queue_accounts_update',
      );
      final when = accounts.read<String>('sql').split('BEGIN').first;
      expect(when, contains('NEW.name IS NOT OLD.name'));
      expect(when, isNot(contains('NEW.balance IS NOT OLD.balance')));
      expect(when, isNot(contains('NEW.balance_minor')));

      final version = await db.customSelect('PRAGMA user_version').getSingle();
      expect(version.data['user_version'], db.schemaVersion);
      await db.close();
    });

    test('a device already on v15 upgrades again without error', () async {
      // Re-runnable like every step before it: DROP ... IF EXISTS followed by a
      // plain CREATE must not come back to "trigger already exists".
      final db = AppDatabase.forTesting(NativeDatabase(file));
      await db.close();

      final raw = sqlite3.sqlite3.open(file.path);
      raw.execute('PRAGMA user_version = 14;');
      raw.dispose();

      final again = AppDatabase.forTesting(NativeDatabase(file));
      await expectLater(again.customSelect('SELECT 1').get(), completes);
      await again.close();
    });
  });

  group('v15 -> v16 migration (queues the seeded foreign-key parents)', () {
    // Same fixture trick as the two groups above: v15 and v16 differ by no
    // table, no column and no trigger at all - only by which rows sit in
    // sync_push_queue after a fresh install. So a v15 device is a
    // current-schema database with those queue entries taken back out and
    // `user_version` wound back.
    late File file;

    Future<Set<String>> queuedKeysFor(AppDatabase target, String table) async {
      final rows = await target
          .customSelect(
            'SELECT record_key FROM sync_push_queue '
            'WHERE changed_table_name = ?',
            variables: [Variable.withString(table)],
          )
          .get();
      return rows.map((r) => r.read<String>('record_key')).toSet();
    }

    Future<Set<String>> idsIn(AppDatabase target, String table) async {
      final rows = await target.customSelect('SELECT id FROM $table').get();
      return rows.map((r) => r.read<String>('id')).toSet();
    }

    setUp(() async {
      file = File('${tempDir.path}/v15.sqlite');
      if (file.existsSync()) file.deleteSync();
      final fresh = AppDatabase.forTesting(NativeDatabase(file));
      await fresh.customSelect('SELECT 1').get();
      await fresh.close();

      final raw = sqlite3.sqlite3.open(file.path);
      // What v15's onCreate left behind: the triggers are created after the
      // bundled seed is written, on purpose, so none of the seeded rows was
      // ever queued.
      raw.execute('DELETE FROM sync_push_queue;');
      raw.execute('PRAGMA user_version = 15;');
      raw.dispose();
    });

    test('the v15 fixture is the stuck device this step exists for', () async {
      // Not a test of the fix - a test that the fixture reproduces the defect,
      // so the assertions below cannot pass for some unrelated reason. The
      // server's schema declares real foreign keys into these four tables
      // (accounts.currency_designation_id, accounts.account_type_id,
      // accounts.style_id, categories.style_id, transactions.category_id), so
      // a device that never uploads them gets a 23503 on the first account it
      // pushes - and a failed push deliberately keeps its queue, so that
      // device retries the same doomed batch forever.
      final raw = sqlite3.sqlite3.open(file.path);
      final queued = raw.select('SELECT record_key FROM sync_push_queue');
      final designations = raw.select('SELECT id FROM currency_designations');
      raw.dispose();
      expect(queued, isEmpty);
      expect(
        designations,
        isNotEmpty,
        reason: 'the rows exist locally; they just never went up',
      );
    });

    test('the upgrade queues every seeded parent', () async {
      final db = AppDatabase.forTesting(NativeDatabase(file));
      for (final table in syncPushQueueSeedTables) {
        final ids = await idsIn(db, table);
        expect(ids, isNotEmpty, reason: '$table is seeded on install');
        expect(
          await queuedKeysFor(db, table),
          ids,
          reason: 'every $table row the server may point at has to go up',
        );
      }

      final version = await db.customSelect('PRAGMA user_version').getSingle();
      expect(version.data['user_version'], db.schemaVersion);
      await db.close();
    });

    test('and queues nothing else', () async {
      // The reason the triggers are created after the seed in the first place:
      // the bundled exchange rates are ~283k rows that every install lays down
      // identically, so uploading them buys nothing and costs a full sync. The
      // step is a few dozen rows wide by design.
      final db = AppDatabase.forTesting(NativeDatabase(file));
      final queued = await db
          .customSelect(
            'SELECT DISTINCT changed_table_name AS t FROM sync_push_queue',
          )
          .get();
      expect(
        queued.map((r) => r.read<String>('t')).toSet(),
        syncPushQueueSeedTables.toSet(),
      );
      await db.close();
    });

    test('a row the device wrote itself is not re-queued', () async {
      // The queue is "what has not reached the server yet". An upgrade that
      // swept in rows the device already pushed would re-upload them on every
      // install, and the step has no way to tell which those are - so it only
      // ever touches the four seeded tables.
      final raw = sqlite3.sqlite3.open(file.path);
      raw.execute(
        "INSERT INTO accounts (id, name, balance, currency_code, "
        "currency_designation_id, account_type_id, creation_date, modified_at) "
        "SELECT 'accOld', 'Already pushed', 0.0, c.currency_code, c.id, "
        "(SELECT id FROM account_types LIMIT 1), 0, 1 "
        "FROM currency_designations c LIMIT 1;",
      );
      raw.execute('DELETE FROM sync_push_queue;');
      raw.dispose();

      final db = AppDatabase.forTesting(NativeDatabase(file));
      expect(await queuedKeysFor(db, 'accounts'), isEmpty);
      expect(await queuedKeysFor(db, 'transactions'), isEmpty);
      await db.close();
    });

    test('no seeded row is edited, moved or stamped', () async {
      // Queueing is a statement about what to send, not a write to the data:
      // touching `modified_at` here would make these rows win a
      // last-write-wins race against a peer that had customised them.
      final before = <String, List<Map<String, Object?>>>{};
      final raw = sqlite3.sqlite3.open(file.path);
      for (final table in syncPushQueueSeedTables) {
        before[table] = raw
            .select('SELECT * FROM $table ORDER BY id')
            .map((r) => Map<String, Object?>.from(r))
            .toList();
      }
      raw.dispose();

      final db = AppDatabase.forTesting(NativeDatabase(file));
      await db.customSelect('SELECT 1').get();
      await db.close();

      final after = sqlite3.sqlite3.open(file.path);
      for (final table in syncPushQueueSeedTables) {
        final rows = after
            .select('SELECT * FROM $table ORDER BY id')
            .map((r) => Map<String, Object?>.from(r))
            .toList();
        expect(rows, before[table], reason: '$table changed');
      }
      after.dispose();
    });

    test('an upgrade that already ran does not widen the backlog', () async {
      // Re-runnable like every step before it. A duplicate entry costs one
      // deduped record key in the next push and nothing else, so what has to
      // hold is the set of keys - not the row count of the queue.
      final db = AppDatabase.forTesting(NativeDatabase(file));
      await db.close();

      final raw = sqlite3.sqlite3.open(file.path);
      raw.execute('PRAGMA user_version = 15;');
      raw.dispose();

      final again = AppDatabase.forTesting(NativeDatabase(file));
      await expectLater(again.customSelect('SELECT 1').get(), completes);
      for (final table in syncPushQueueSeedTables) {
        expect(await queuedKeysFor(again, table), await idsIn(again, table));
      }
      await again.close();
    });

    test('a fresh install starts with the same parents queued', () async {
      // The other half of the fix: the repair step above is for devices that
      // already exist, and this is what stops the next install from arriving
      // in the same state.
      final freshFile = File('${tempDir.path}/fresh_v16.sqlite');
      final db = AppDatabase.forTesting(NativeDatabase(freshFile));
      await db.customSelect('SELECT 1').get();

      for (final table in syncPushQueueSeedTables) {
        expect(await queuedKeysFor(db, table), await idsIn(db, table));
      }
      final queued = await db
          .customSelect(
            'SELECT DISTINCT changed_table_name AS t FROM sync_push_queue',
          )
          .get();
      expect(
        queued.map((r) => r.read<String>('t')).toSet(),
        syncPushQueueSeedTables.toSet(),
      );
      await db.close();
    });
  });

  group('v16 -> v17 migration (drops the UNIQUE on synced names)', () {
    // v16 and v17 differ by two constraints, both written inline in CREATE
    // TABLE, so the fixture is a current-schema database whose `currencies`
    // and `account_types` tables have been rebuilt with the UNIQUE put back
    // and `user_version` wound back.
    late File file;

    /// Rebuilds [table] the way v16 declared it.
    ///
    /// The trigger SQL is copied out of `sqlite_master` rather than retyped:
    /// dropping the table drops its triggers, and a fixture whose triggers
    /// differ from the ones a real v16 device has would let the migration pass
    /// here and lose queue entries in the field.
    void rebuildWithUnique(sqlite3.Database raw, String table) {
      final triggers = raw
          .select(
            "SELECT sql FROM sqlite_master WHERE type = 'trigger' "
            'AND tbl_name = ?',
            [table],
          )
          .map((r) => r['sql'] as String)
          .toList();
      final ddl =
          raw.select(
                "SELECT sql FROM sqlite_master WHERE type = 'table' "
                'AND name = ?',
                [table],
              ).single['sql']
              as String;
      expect(
        ddl.contains('"name" TEXT NOT NULL,'),
        isTrue,
        reason: 'the shipped $table moved; this fixture no longer builds v16',
      );
      final v16Ddl = ddl
          .replaceFirst('"$table"', '"${table}_v16"')
          .replaceFirst(
            '"name" TEXT NOT NULL,',
            '"name" TEXT NOT NULL UNIQUE,',
          );

      raw.execute('PRAGMA foreign_keys = OFF;');
      // Without this, renaming into the name the other tables reference makes
      // SQLite rewrite their REFERENCES clauses instead of leaving them alone.
      raw.execute('PRAGMA legacy_alter_table = ON;');
      raw.execute(v16Ddl);
      raw.execute('INSERT INTO ${table}_v16 SELECT * FROM $table;');
      raw.execute('DROP TABLE $table;');
      raw.execute('ALTER TABLE ${table}_v16 RENAME TO $table;');
      for (final sql in triggers) {
        raw.execute(sql);
      }
      raw.execute('PRAGMA legacy_alter_table = OFF;');
    }

    /// The rename that actually broke a pair of devices: `BYR` used to be
    /// "Belarusian Ruble" and a later seed moved that name to `BYN`.
    void applyIncomingCurrency(sqlite3.Database raw) {
      raw.execute(
        "UPDATE currencies SET name = 'Belarusian Ruble' WHERE code = 'BYR'",
      );
    }

    /// The account-type version: a row arrives carrying a name that another id
    /// already holds, because the user renamed it on the other device.
    void applyIncomingAccountType(sqlite3.Database raw) {
      final cash =
          raw
                  .select(
                    "SELECT name FROM account_types WHERE id = "
                    "'account_type_cash'",
                  )
                  .single['name']
              as String;
      raw.execute('UPDATE account_types SET name = ? WHERE id = ?', [
        cash,
        'account_type_savings',
      ]);
    }

    setUp(() async {
      file = File('${tempDir.path}/v16.sqlite');
      if (file.existsSync()) file.deleteSync();
      final fresh = AppDatabase.forTesting(NativeDatabase(file));
      await fresh.customSelect('SELECT 1').get();
      await fresh.close();

      final raw = sqlite3.sqlite3.open(file.path);
      rebuildWithUnique(raw, 'currencies');
      rebuildWithUnique(raw, 'account_types');
      raw.execute('PRAGMA user_version = 16;');
      raw.dispose();
    });

    test('the v16 fixture is the wedged device this step exists for', () async {
      // Not a test of the fix - a test that the fixture reproduces the defect.
      // A device on an older bundled seed pushes BYR under the plain name; the
      // pull applies every table in one transaction, so this exception rolled
      // the whole page back and left the cursor where it was. The next sync
      // asked for the same page. Forever.
      final raw = sqlite3.sqlite3.open(file.path);
      final byn = raw.select("SELECT name FROM currencies WHERE code = 'BYN'");
      expect(
        byn.single['name'],
        'Belarusian Ruble',
        reason: 'the seed this test is about',
      );
      final unique = isA<sqlite3.SqliteException>().having(
        (e) => e.extendedResultCode,
        'extendedResultCode',
        2067,
      );
      expect(() => applyIncomingCurrency(raw), throwsA(unique));
      expect(() => applyIncomingAccountType(raw), throwsA(unique));
      raw.dispose();
    });

    test('after the upgrade the same rows apply', () async {
      final db = AppDatabase.forTesting(NativeDatabase(file));
      await db.customSelect('SELECT 1').get();
      await db.close();

      final raw = sqlite3.sqlite3.open(file.path);
      // The upgrade runs the whole chain, so this is the version the app
      // ships, not the one this group is named after.
      expect(
        raw.select('PRAGMA user_version').single['user_version'],
        db.schemaVersion,
      );
      expect(() => applyIncomingCurrency(raw), returnsNormally);
      expect(() => applyIncomingAccountType(raw), returnsNormally);
      final codes = raw
          .select(
            "SELECT code FROM currencies WHERE name = 'Belarusian Ruble' "
            'ORDER BY code',
          )
          .map((r) => r['code'])
          .toList();
      expect(codes, [
        'BYN',
        'BYR',
      ], reason: 'two codes may carry one label; the key is the code');
      raw.dispose();
    });

    test('every row survives the rebuild unchanged', () async {
      // The tables are dropped and recreated, so this is the step where a
      // mistake silently empties the currency list - and every account,
      // transaction and rate points at it.
      final raw = sqlite3.sqlite3.open(file.path);
      Map<String, List<Map<String, Object?>>> snapshot(sqlite3.Database db) => {
        for (final entry in const {
          'currencies': 'code',
          'account_types': 'id',
        }.entries)
          entry.key: db
              .select('SELECT * FROM ${entry.key} ORDER BY ${entry.value}')
              .map((r) => Map<String, Object?>.from(r))
              .toList(),
      };
      final before = snapshot(raw);
      final childCounts = <String, int>{
        for (final table in const [
          'currency_designations',
          'accounts',
          'transactions',
          'exchange_rates',
          'asset_entries',
        ])
          table:
              raw.select('SELECT COUNT(*) AS c FROM $table').single['c'] as int,
      };
      raw.dispose();
      for (final entry in before.entries) {
        expect(entry.value, isNotEmpty, reason: '${entry.key} is seeded');
      }

      final db = AppDatabase.forTesting(NativeDatabase(file));
      await db.customSelect('SELECT 1').get();
      await db.close();

      final after = sqlite3.sqlite3.open(file.path);
      expect(snapshot(after), before);
      for (final entry in childCounts.entries) {
        expect(
          after.select('SELECT COUNT(*) AS c FROM ${entry.key}').single['c'],
          entry.value,
          reason: '${entry.key} lost rows to the rebuild',
        );
      }
      // A dangling reference would mean the copy renamed or dropped a key.
      expect(after.select('PRAGMA foreign_key_check'), isEmpty);
      after.dispose();
    });

    test('the push-queue triggers survive the rebuild', () async {
      // Dropping a table drops its triggers. Without recreating them the app
      // keeps working and simply stops uploading edits to these tables - which
      // is invisible until another device is missing them.
      final db = AppDatabase.forTesting(NativeDatabase(file));
      await db.customSelect('SELECT 1').get();
      await db.close();

      final raw = sqlite3.sqlite3.open(file.path);
      for (final table in const ['currencies', 'account_types']) {
        expect(
          raw
              .select(
                "SELECT name FROM sqlite_master WHERE type = 'trigger' "
                'AND tbl_name = ? ORDER BY name',
                [table],
              )
              .map((r) => r['name'])
              .toList(),
          [
            // v18 puts this device's identity on every row it writes; the
            // rebuild has to leave those behind as well.
            'trg_device_id_${table}_insert',
            'trg_device_id_${table}_update',
            'trg_push_queue_${table}_insert',
            'trg_push_queue_${table}_update',
          ],
        );
      }

      raw.execute('DELETE FROM sync_push_queue;');
      applyIncomingCurrency(raw);
      applyIncomingAccountType(raw);
      expect(
        raw
            .select(
              'SELECT changed_table_name, record_key FROM sync_push_queue '
              'ORDER BY changed_table_name',
            )
            .map((r) => '${r['changed_table_name']}:${r['record_key']}')
            .toList(),
        ['account_types:account_type_savings', 'currencies:BYR'],
        reason: 'an edit made after the upgrade still has to go up',
      );
      raw.dispose();
    });

    test('an upgrade that already ran is a no-op', () async {
      final db = AppDatabase.forTesting(NativeDatabase(file));
      await db.customSelect('SELECT 1').get();
      await db.close();

      final raw = sqlite3.sqlite3.open(file.path);
      raw.execute('PRAGMA user_version = 16;');
      raw.dispose();

      final again = AppDatabase.forTesting(NativeDatabase(file));
      await expectLater(again.customSelect('SELECT 1').get(), completes);
      await again.close();

      final check = sqlite3.sqlite3.open(file.path);
      expect(() => applyIncomingCurrency(check), returnsNormally);
      expect(() => applyIncomingAccountType(check), returnsNormally);
      expect(check.select('PRAGMA foreign_key_check'), isEmpty);
      check.dispose();
    });

    test('a fresh install has no unique on the names either', () async {
      // The other half: the step above repairs devices that exist, this is
      // what stops the next install from arriving in the same state.
      final freshFile = File('${tempDir.path}/fresh_v17.sqlite');
      final db = AppDatabase.forTesting(NativeDatabase(freshFile));
      await db.customSelect('SELECT 1').get();
      await db.close();

      final raw = sqlite3.sqlite3.open(freshFile.path);
      expect(() => applyIncomingCurrency(raw), returnsNormally);
      expect(() => applyIncomingAccountType(raw), returnsNormally);
      raw.dispose();
    });
  });

  group('v18 -> v19 migration (the review queue and its category)', () {
    // v18 and v19 differ by one column on `transactions` and by two seeded
    // rows, so the fixture is a current-schema database with the column
    // rebuilt away, those rows deleted and `user_version` wound back.
    late File file;

    /// Rebuilds `transactions` the way v18 declared it - without
    /// `needs_review`.
    ///
    /// DROP COLUMN is refused here: the push-queue triggers name every column
    /// of the table they watch, so SQLite will not leave one referring to a
    /// column that is gone. The triggers are copied out of `sqlite_master`
    /// and put back with the same column removed from them, the way the v16
    /// fixture does it: a fixture whose triggers differ from a real v18
    /// device's would let the migration pass here and lose queue entries in
    /// the field.
    void stripNeedsReview(sqlite3.Database raw) {
      final triggers = raw
          .select(
            "SELECT sql FROM sqlite_master WHERE type = 'trigger' "
            "AND tbl_name = 'transactions'",
          )
          .map((r) => r['sql'] as String)
          .toList();
      expect(
        triggers.any((t) => t.contains('needs_review')),
        isTrue,
        reason: 'the v19 triggers must watch the new column',
      );
      final ddl =
          raw.select(
                "SELECT sql FROM sqlite_master WHERE type = 'table' "
                "AND name = 'transactions'",
              ).single['sql']
              as String;
      expect(
        ddl.contains('"needs_review"'),
        isTrue,
        reason: 'the shipped column moved; this fixture no longer builds v18',
      );
      final columns = raw
          .select("PRAGMA table_info('transactions')")
          .map((r) => r['name'] as String)
          .where((c) => c != 'needs_review')
          .map((c) => '"$c"')
          .join(', ');
      final v18Ddl = _dropColumnDeclaration(
        ddl.replaceFirst('"transactions"', '"transactions_v18"'),
        'needs_review',
      );
      expect(
        v18Ddl.contains('needs_review'),
        isFalse,
        reason: 'the column declaration is not shaped as this fixture assumes',
      );

      raw.execute('PRAGMA foreign_keys = OFF;');
      // Without this, renaming into the name other tables reference makes
      // SQLite rewrite their REFERENCES clauses instead of leaving them be.
      raw.execute('PRAGMA legacy_alter_table = ON;');
      raw.execute(v18Ddl);
      raw.execute(
        'INSERT INTO transactions_v18 ($columns) SELECT $columns '
        'FROM transactions;',
      );
      raw.execute('DROP TABLE transactions;');
      raw.execute('ALTER TABLE transactions_v18 RENAME TO transactions;');
      for (final sql in triggers) {
        // The v18 device's triggers: the same SQL with the comparison of the
        // column that did not exist for it to watch taken back out.
        raw.execute(sql.replaceAll(RegExp(r'[^ (]*needs_review[^ )]*'), "''"));
      }
      raw.execute('PRAGMA legacy_alter_table = OFF;');
    }

    setUp(() async {
      file = File('${tempDir.path}/v18.sqlite');
      if (file.existsSync()) file.deleteSync();
      final fresh = AppDatabase.forTesting(NativeDatabase(file));
      await fresh.customSelect('SELECT 1').get();
      await fresh.close();

      final raw = sqlite3.sqlite3.open(file.path);
      stripNeedsReview(raw);
      // What a device installed before v19 has: no subscriptions category,
      // and no style behind it.
      raw.execute("DELETE FROM categories WHERE id = 'cat_subscriptions';");
      raw.execute("DELETE FROM styles WHERE id = 'style_subscriptions';");
      raw.execute('DELETE FROM sync_push_queue;');
      raw.execute('PRAGMA user_version = 18;');
      raw.dispose();
    });

    test('the fixture is a v18 device', () async {
      // Not a test of the fix - a test that the fixture is the state the step
      // has to upgrade from.
      final raw = sqlite3.sqlite3.open(file.path);
      final columns = raw
          .select("PRAGMA table_info('transactions')")
          .map((r) => r['name'])
          .toList();
      expect(columns, isNot(contains('needs_review')));
      expect(
        raw.select("SELECT id FROM categories WHERE id = 'cat_subscriptions'"),
        isEmpty,
      );
      raw.dispose();
    });

    test('adds the column and keeps the rows already written', () async {
      final seeded = sqlite3.sqlite3.open(file.path);
      // Accounts are the user's, not the seed's, so the fixture writes the one
      // this row hangs off - out of the seeded catalogue, so the foreign keys
      // are real ones.
      final designation = seeded
          .select('SELECT id, currency_code FROM currency_designations LIMIT 1')
          .single;
      final accountTypeId =
          seeded.select('SELECT id FROM account_types LIMIT 1').single['id']
              as String;
      final categoryId =
          seeded.select('SELECT id FROM categories LIMIT 1').single['id']
              as String;
      seeded.execute(
        'INSERT INTO accounts (id, name, balance, currency_code, '
        'currency_designation_id, account_type_id, creation_date) '
        'VALUES (?, ?, ?, ?, ?, ?, ?)',
        [
          'acc-v18',
          'Account from before',
          0.0,
          designation['currency_code'],
          designation['id'],
          accountTypeId,
          1700000000000,
        ],
      );
      seeded.execute(
        'INSERT INTO transactions (id, description, amount, date, account_id, '
        'category_id, currency_code) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [
          'tx-v18',
          'written before the upgrade',
          -12.5,
          1700000000000,
          'acc-v18',
          categoryId,
          designation['currency_code'],
        ],
      );
      seeded.dispose();

      final db = AppDatabase.forTesting(NativeDatabase(file));
      await db.customSelect('SELECT 1').get();
      await db.close();

      final raw = sqlite3.sqlite3.open(file.path);
      expect(
        raw.select('PRAGMA user_version').single['user_version'],
        db.schemaVersion,
      );
      final row = raw
          .select(
            'SELECT description, needs_review FROM transactions '
            "WHERE id = 'tx-v18'",
          )
          .single;
      expect(row['description'], 'written before the upgrade');
      // Nothing has reviewed the rows that were already there, and nothing
      // flagged them either: the queue starts empty rather than holding the
      // user's whole history.
      expect(row['needs_review'], 0);
      expect(raw.select('PRAGMA foreign_key_check'), isEmpty);
      raw.dispose();
    });

    test('seeds the subscriptions category and its style', () async {
      // Seeding only runs on a fresh install, so without this step the
      // category the SMS import files subscriptions into would exist on no
      // device that already had the app.
      final db = AppDatabase.forTesting(NativeDatabase(file));
      await db.customSelect('SELECT 1').get();
      await db.close();

      final raw = sqlite3.sqlite3.open(file.path);
      final category = raw
          .select(
            'SELECT style_id, is_deleted FROM categories '
            "WHERE id = 'cat_subscriptions'",
          )
          .single;
      expect(category['style_id'], 'style_subscriptions');
      expect(category['is_deleted'], 0);
      expect(
        raw.select("SELECT id FROM styles WHERE id = 'style_subscriptions'"),
        hasLength(1),
      );
      raw.dispose();
    });

    test('recreates the push-queue triggers around the new column', () async {
      // The triggers enumerate the columns they compare and were compiled
      // before this one existed: without recreating them, clearing the flag on
      // a reviewed row would never be uploaded.
      final db = AppDatabase.forTesting(NativeDatabase(file));
      await db.customSelect('SELECT 1').get();
      await db.close();

      final raw = sqlite3.sqlite3.open(file.path);
      final triggers = raw
          .select(
            "SELECT sql FROM sqlite_master WHERE type = 'trigger' "
            "AND tbl_name = 'transactions'",
          )
          .map((r) => r['sql'] as String)
          .toList();
      expect(triggers.any((t) => t.contains('needs_review')), isTrue);
      raw.dispose();
    });

    test('a device already on v19 upgrades again without error', () async {
      final db = AppDatabase.forTesting(NativeDatabase(file));
      await db.customSelect('SELECT 1').get();
      await db.close();

      final again = AppDatabase.forTesting(NativeDatabase(file));
      await expectLater(again.customSelect('SELECT 1').get(), completes);
      await again.close();

      final raw = sqlite3.sqlite3.open(file.path);
      expect(
        raw.select("SELECT id FROM categories WHERE id = 'cat_subscriptions'"),
        hasLength(1),
        reason: 'the insert is insert-or-ignore, not a second row',
      );
      raw.dispose();
    });
  });

  group('v19 -> v20 migration (collapses the re-imported duplicates)', () {
    // v20 adds no columns, so the fixture is a current-schema database with
    // `user_version` wound back and the rows a re-imported inbox would have
    // left behind written into it.
    late File file;
    late String currencyCode;

    /// The seeded catalogue row the fixture's accounts hang off, so every
    /// foreign key in here is a real one.
    late String designationId;
    late String accountTypeId;
    late String categoryId;

    setUp(() async {
      file = File('${tempDir.path}/v19.sqlite');
      if (file.existsSync()) file.deleteSync();
      final fresh = AppDatabase.forTesting(NativeDatabase(file));
      await fresh.customSelect('SELECT 1').get();
      await fresh.close();

      final raw = sqlite3.sqlite3.open(file.path);
      final designation = raw
          .select('SELECT id, currency_code FROM currency_designations LIMIT 1')
          .single;
      designationId = designation['id'] as String;
      currencyCode = designation['currency_code'] as String;
      accountTypeId =
          raw.select('SELECT id FROM account_types LIMIT 1').single['id']
              as String;
      categoryId =
          raw.select('SELECT id FROM categories LIMIT 1').single['id']
              as String;

      void insertAccount(String id, double opening, double balance) {
        raw.execute(
          'INSERT INTO accounts (id, name, balance, opening_balance, '
          'currency_code, currency_designation_id, account_type_id, '
          'creation_date) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
          [
            id,
            id,
            balance,
            opening,
            currencyCode,
            designationId,
            accountTypeId,
            1700000000000,
          ],
        );
      }

      void insertTx(
        String id,
        String accountId,
        String description,
        double amount,
        int date, {
        String? linkedTransactionId,
      }) {
        raw.execute(
          'INSERT INTO transactions (id, description, amount, date, '
          'account_id, category_id, currency_code, linked_transaction_id) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
          [
            id,
            description,
            amount,
            date,
            accountId,
            categoryId,
            currencyCode,
            linkedTransactionId,
          ],
        );
      }

      // The account the duplicated import landed on. Its balance is what the
      // duplicates left: the anchor plus all three rows, one of which is the
      // second copy of another. Minor columns stay NULL so the rebuild takes
      // the double path and the arithmetic in the assertions is the plain
      // one.
      insertAccount('acc-dup', 100.0, 70.0);
      insertTx('tx-a', 'acc-dup', 'ATM BPS- MAXI V', -10.0, 1700000000000);
      // Same account, same description, same amount, same millisecond: what
      // re-running the import produced, distinguishable only by its id.
      insertTx('tx-a-copy', 'acc-dup', 'ATM BPS- MAXI V', -10.0, 1700000000000);
      // Same money, one second apart. A different message, and it has to
      // survive.
      insertTx('tx-b', 'acc-dup', 'ATM BPS- MAXI V', -10.0, 1700000001000);

      // A transfer's two halves are identical in everything this groups on.
      // Collapsing one would strand the other, so they are excluded outright.
      insertAccount('acc-tr', 0.0, 0.0);
      insertTx(
        'tx-tr-1',
        'acc-tr',
        'moved',
        -5.0,
        1700000000000,
        linkedTransactionId: 'tx-tr-2',
      );
      insertTx(
        'tx-tr-2',
        'acc-tr',
        'moved',
        -5.0,
        1700000000000,
        linkedTransactionId: 'tx-tr-1',
      );

      raw.execute('DELETE FROM sync_push_queue;');
      raw.execute('PRAGMA user_version = 19;');
      raw.dispose();
    });

    Future<sqlite3.Database> migrate() async {
      final db = AppDatabase.forTesting(NativeDatabase(file));
      await db.customSelect('SELECT 1').get();
      await db.close();
      return sqlite3.sqlite3.open(file.path);
    }

    test('tombstones the copy and keeps the original', () async {
      final raw = await migrate();
      int deletedOf(String id) =>
          raw.select('SELECT is_deleted FROM transactions WHERE id = ?', [
                id,
              ]).single['is_deleted']
              as int;

      // The survivor is the lower rowid, which is the row that was there
      // first - the copy is the one that goes.
      expect(deletedOf('tx-a'), 0);
      expect(deletedOf('tx-a-copy'), 1);
      expect(
        deletedOf('tx-b'),
        0,
        reason: 'one second apart is a different message',
      );
      raw.dispose();
    });

    test('leaves the two halves of a transfer alone', () async {
      final raw = await migrate();
      final rows = raw.select(
        "SELECT is_deleted FROM transactions WHERE account_id = 'acc-tr'",
      );
      expect(rows.map((r) => r['is_deleted']), everyElement(0));
      raw.dispose();
    });

    test('rebuilds the balance the duplicate had moved', () async {
      final raw = await migrate();
      final balance =
          raw.select(
                "SELECT balance FROM accounts WHERE id = 'acc-dup'",
              ).single['balance']
              as double;
      // 100 anchor, two surviving rows of -10. The third -10 went with the
      // copy, and the balance has to stop counting it.
      expect(balance, closeTo(80.0, 0.0001));
      raw.dispose();
    });

    test('queues the tombstone so the peers hear about it', () async {
      final raw = await migrate();
      final queued = raw.select(
        "SELECT record_key FROM sync_push_queue WHERE changed_table_name = "
        "'transactions'",
      );
      expect(
        queued.map((r) => r['record_key']),
        contains('tx-a-copy'),
        reason: 'a removal the peers never hear about comes back on the '
            'next pull',
      );
      raw.dispose();
    });
  });

  group('v20 -> v21 migration (drops the seeded rates from the push queue)', () {
    // v21 adds no columns either. The fixture is a current-schema database
    // wound back to 20 with three preset-1 batches in it, told apart only by
    // how many rows share a `modified_at`: that is the whole discriminator
    // the migration has, so it is the whole point of the fixture.
    late File file;
    late String fromCode;
    late String toCode;

    /// One `modified_at` across a batch far larger than any provider fetch:
    /// the bundled history, and the only thing the trim is allowed to take.
    const seedStamp = 1000;
    const seedRows = 1200;

    /// A day's fetch. Preset 1 as well, one row per known currency, so a few
    /// hundred at most - under the threshold, and it has to survive.
    const fetchStamp = 2000;
    const fetchRows = 300;

    /// A rate the person typed in as their default. Preset 1, one row.
    const manualStamp = 3000;

    setUp(() async {
      AppDatabase.seedExchangeRatesOnCreate = false;
      file = File('${tempDir.path}/v20.sqlite');
      if (file.existsSync()) file.deleteSync();
      final fresh = AppDatabase.forTesting(NativeDatabase(file));
      await fresh.customSelect('SELECT 1').get();
      await fresh.close();

      final raw = sqlite3.sqlite3.open(file.path);
      final codes = raw.select('SELECT code FROM currencies LIMIT 2');
      fromCode = codes.first['code'] as String;
      toCode = codes.last['code'] as String;

      void insertRate(int date, int preset, int modifiedAt) {
        raw.execute(
          'INSERT INTO exchange_rates (from_currency_code, to_currency_code, '
          'rate, preset, date, modified_at) VALUES (?, ?, ?, ?, ?, ?)',
          [fromCode, toCode, 1.5, preset, date, modifiedAt],
        );
      }

      for (var i = 0; i < seedRows; i++) {
        insertRate(i, 1, seedStamp);
      }
      for (var i = 0; i < fetchRows; i++) {
        insertRate(100000 + i, 1, fetchStamp);
      }
      insertRate(200000, 1, manualStamp);
      // A custom source writes preset 2, in bulk. Sharing the seed's stamp
      // and its size, so the only thing keeping it is the preset.
      for (var i = 0; i < 5; i++) {
        insertRate(300000 + i, 2, seedStamp);
      }

      // The triggers queued all of that on the way in and may have restamped
      // it. Set the stamps last, then rebuild the queue by hand, so what the
      // migration reads is exactly what this fixture says it is.
      raw.execute(
        'UPDATE exchange_rates SET modified_at = ? WHERE date < 100000',
        [seedStamp],
      );
      raw.execute(
        'UPDATE exchange_rates SET modified_at = ? '
        'WHERE date >= 100000 AND date < 200000',
        [fetchStamp],
      );
      raw.execute('UPDATE exchange_rates SET modified_at = ? WHERE date = ?', [
        manualStamp,
        200000,
      ]);
      raw.execute(
        'UPDATE exchange_rates SET modified_at = ? WHERE preset = 2',
        [seedStamp],
      );

      raw.execute('DELETE FROM sync_push_queue;');
      raw.execute(
        "INSERT INTO sync_push_queue (changed_table_name, record_key) "
        "SELECT 'exchange_rates', from_currency_code || '|' || "
        "to_currency_code || '|' || date || '|' || preset FROM exchange_rates",
      );
      // Two entries that are not rates at all. The trim names one table; if it
      // ever stops doing so, these are what says it.
      raw.execute(
        "INSERT INTO sync_push_queue (changed_table_name, record_key) "
        "VALUES ('transactions', 'tx-1'), ('accounts', 'acc-1')",
      );

      raw.execute('PRAGMA user_version = 20;');
      raw.dispose();
    });

    tearDown(() {
      AppDatabase.seedExchangeRatesOnCreate = true;
    });

    Future<sqlite3.Database> migrate() async {
      final db = AppDatabase.forTesting(NativeDatabase(file));
      await db.customSelect('SELECT 1').get();
      await db.close();
      return sqlite3.sqlite3.open(file.path);
    }

    /// How many distinct rate rows carrying [stamp] are still owed to the
    /// server. DISTINCT because the resend path inserts unconditionally - a
    /// row already queued ends up with two entries and one record key, which
    /// is what the push itself collapses.
    int queuedRatesWithStamp(sqlite3.Database raw, int stamp) =>
        raw.select(
              'SELECT COUNT(DISTINCT q.record_key) AS c FROM sync_push_queue q '
              'JOIN exchange_rates r ON q.record_key = '
              "r.from_currency_code || '|' || r.to_currency_code || '|' || "
              "r.date || '|' || r.preset "
              "WHERE q.changed_table_name = 'exchange_rates' "
              'AND r.modified_at = ?',
              [stamp],
            ).single['c']
            as int;

    test('drops the seeded batch', () async {
      final raw = await migrate();
      expect(queuedRatesWithStamp(raw, seedStamp), 5,
          reason: 'only the five preset-2 rows sharing that stamp survive');
      raw.dispose();
    });

    test("keeps a day's fetch and a hand-entered rate", () async {
      final raw = await migrate();
      expect(
        queuedRatesWithStamp(raw, fetchStamp),
        fetchRows,
        reason: 'preset 1 is not the same question as "came from the seed"',
      );
      expect(queuedRatesWithStamp(raw, manualStamp), 1);
      raw.dispose();
    });

    test('leaves the other tables queued', () async {
      final raw = await migrate();
      final rows = raw.select(
        "SELECT record_key FROM sync_push_queue WHERE changed_table_name "
        "IN ('transactions', 'accounts')",
      );
      expect(rows.map((r) => r['record_key']), containsAll(['tx-1', 'acc-1']));
      raw.dispose();
    });

    test('resending everything does not put the seed back', () async {
      (await migrate()).dispose();

      final db = AppDatabase.forTesting(NativeDatabase(file));
      await db.customSelect('SELECT 1').get();
      await db.queueEverythingForPush();
      await db.close();

      final raw = sqlite3.sqlite3.open(file.path);
      expect(
        queuedRatesWithStamp(raw, seedStamp),
        5,
        reason: 'the resend path rebuilt the backlog the upgrade just cleared',
      );
      expect(queuedRatesWithStamp(raw, fetchStamp), fetchRows);
      expect(queuedRatesWithStamp(raw, manualStamp), 1);
      raw.dispose();
    });
  });

  group('v21 -> v22 migration (indexes the asset_entries reads)', () {
    // No columns again. What v22 adds is two indexes, and the thing worth
    // pinning is not that the CREATE ran - it is that the planner picks them
    // up, because an index the query never matches costs writes and buys
    // nothing.
    late File file;

    setUp(() async {
      AppDatabase.seedExchangeRatesOnCreate = false;
      file = File('${tempDir.path}/v21.sqlite');
      if (file.existsSync()) file.deleteSync();
      final fresh = AppDatabase.forTesting(NativeDatabase(file));
      await fresh.customSelect('SELECT 1').get();
      await fresh.close();

      // Wind back to what a v21 database looked like: the indexes did not
      // exist there, so drop the ones onCreate just built.
      final raw = sqlite3.sqlite3.open(file.path);
      raw.execute('DROP INDEX IF EXISTS idx_asset_entries_account_date');
      raw.execute('DROP INDEX IF EXISTS idx_asset_entries_asset_date');
      raw.execute('PRAGMA user_version = 21');
      raw.dispose();
    });

    tearDown(() {
      AppDatabase.seedExchangeRatesOnCreate = true;
    });

    Set<String> indexNames(sqlite3.Database raw) => raw
        .select(
          "SELECT name FROM sqlite_master WHERE type = 'index' "
          "AND tbl_name = 'asset_entries'",
        )
        .map((row) => row['name'] as String)
        .toSet();

    test('creates both indexes on an upgraded database', () async {
      final before = sqlite3.sqlite3.open(file.path);
      expect(
        indexNames(before),
        isNot(contains('idx_asset_entries_account_date')),
        reason: 'fixture was not actually wound back',
      );
      before.dispose();

      final db = AppDatabase.forTesting(NativeDatabase(file));
      await db.customSelect('SELECT 1').get();
      await db.close();

      final raw = sqlite3.sqlite3.open(file.path);
      expect(
        indexNames(raw),
        containsAll([
          'idx_asset_entries_account_date',
          'idx_asset_entries_asset_date',
        ]),
      );
      raw.dispose();
    });

    test('the planner seeks on them instead of scanning', () async {
      final db = AppDatabase.forTesting(NativeDatabase(file));
      await db.customSelect('SELECT 1').get();
      await db.close();

      final raw = sqlite3.sqlite3.open(file.path);
      String planFor(String sql) => raw
          .select('EXPLAIN QUERY PLAN $sql')
          .map((row) => row['detail'] as String)
          .join(' | ');

      // The shape getAssetData builds for one asset account: an owner plus a
      // date window, ordered by date.
      final accountPlan = planFor(
        'SELECT * FROM asset_entries '
        "WHERE is_deleted = 0 AND account_id = 'a' "
        'AND date >= 0 AND date <= 99 ORDER BY date DESC',
      );
      expect(
        accountPlan,
        contains('idx_asset_entries_account_date'),
        reason: 'account lookups still scan the table: $accountPlan',
      );

      final assetPlan = planFor(
        'SELECT * FROM asset_entries '
        "WHERE is_deleted = 0 AND asset_id = 'x' ORDER BY date DESC",
      );
      expect(
        assetPlan,
        contains('idx_asset_entries_asset_date'),
        reason: 'asset lookups still scan the table: $assetPlan',
      );
      raw.dispose();
    });

    test('is idempotent - a second open does not fail on the indexes', () async {
      final first = AppDatabase.forTesting(NativeDatabase(file));
      await first.customSelect('SELECT 1').get();
      await first.close();

      final second = AppDatabase.forTesting(NativeDatabase(file));
      await second.customSelect('SELECT 1').get();
      await second.close();

      final raw = sqlite3.sqlite3.open(file.path);
      expect(indexNames(raw), contains('idx_asset_entries_account_date'));
      raw.dispose();
    });
  });
}

/// [ddl] with the declaration of [column] taken out of it.
///
/// Not a regex: a declaration carries its own commas - `CHECK ("x" IN (0,
/// 1))` - so cutting at the first comma leaves half a CHECK behind and the
/// CREATE TABLE no longer parses. This walks to the first comma that is not
/// inside brackets instead.
String _dropColumnDeclaration(String ddl, String column) {
  final start = ddl.indexOf('"$column"');
  if (start < 0) return ddl;
  var depth = 0;
  for (var i = start; i < ddl.length; i++) {
    final c = ddl[i];
    if (c == '(') depth++;
    if (c == ')') depth--;
    if (c == ',' && depth == 0) {
      var end = i + 1;
      while (end < ddl.length && ddl[end] == ' ') {
        end++;
      }
      return ddl.substring(0, start) + ddl.substring(end);
    }
  }
  return ddl;
}
