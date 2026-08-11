import 'dart:io';

import 'package:drift/drift.dart' show Value;
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

    Future<AppDatabase> buildAndOpen({required void Function(sqlite3.Database) seed}) async {
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

    test(
      'fiat account balance and transaction amount/fee survive exactly; '
      'minor columns get the right integer scale',
      () async {
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

        final eurAccount =
            await (db.select(db.accounts)..where((a) => a.id.equals('accEur')))
                .getSingle();
        final btcAccount =
            await (db.select(db.accounts)..where((a) => a.id.equals('accBtc')))
                .getSingle();

        // The legacy double must be untouched by the migration.
        expect(eurAccount.balance, 1234.56);
        expect(btcAccount.balance, 0.5);
        // The new integer column is exact and correctly scaled (2 decimals).
        expect(eurAccount.balanceMinor, 123456);
        // Crypto never gets a minor value: NULL, not 0.
        expect(btcAccount.balanceMinor, isNull);

        final eurTx =
            await (db.select(db.transactions)..where((t) => t.id.equals('t1')))
                .getSingle();
        final btcTx =
            await (db.select(db.transactions)..where((t) => t.id.equals('t2')))
                .getSingle();

        expect(eurTx.amount, 10.10);
        expect(eurTx.fee, 0.05);
        expect(eurTx.amountMinor, 1010);
        expect(eurTx.feeMinor, 5);
        expect(btcTx.amount, 0.25);
        expect(btcTx.amountMinor, isNull);

        await db.close();
      },
    );

    test('adds the minor-unit columns without dropping any other column',
        () async {
      final db = await buildAndOpen(seed: (_) {});

      final accountCols = await db
          .customSelect("PRAGMA table_info('accounts')")
          .get();
      final accountColNames =
          accountCols.map((r) => r.data['name'] as String).toSet();
      expect(accountColNames, contains('balance_minor'));
      expect(accountColNames, contains('balance')); // old column intact
      expect(accountColNames, contains('is_deleted')); // v3 column intact

      final txCols =
          await db.customSelect("PRAGMA table_info('transactions')").get();
      final txColNames = txCols.map((r) => r.data['name'] as String).toSet();
      expect(txColNames, containsAll(['amount_minor', 'fee_minor']));
      expect(txColNames, contains('amount')); // old column intact

      await db.close();
    });
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
      final tempDir =
          Directory.systemTemp.createTempSync('mybudget_migration_v2_test');
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
    test('completes the chain without throwing and lands on schemaVersion',
        () async {
      final versionRow =
          await db.customSelect('PRAGMA user_version').getSingle();
      expect(versionRow.data['user_version'], db.schemaVersion);
    });

    test('final schema has the columns the v8 Dart tables expect', () async {
      Future<Set<String>> columnsOf(String table) async {
        final rows =
            await db.customSelect("PRAGMA table_info('$table')").get();
        return rows.map((r) => r.data['name'] as String).toSet();
      }

      expect(
        await columnsOf('accounts'),
        containsAll(['balance_minor', 'modified_at', 'device_id', 'is_deleted']),
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
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table'",
          )
          .get();
      final names = tables.map((r) => r.data['name'] as String).toSet();
      expect(names, containsAll(['sms_presets', 'sync_processed_files']));
    });

    test('creates the composite indexes added in v6 and the dedup unique '
        'index added in v7', () async {
      final indexes = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index'",
          )
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

    test(
      'backfills the five @TableIndex indexes, which only ever existed on '
      'fresh installs: m.createAll() builds them in onCreate and no upgrade '
      'step did, so every upgraded device ran without them',
      () async {
        final indexes = await db
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type = 'index'",
            )
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
      },
    );

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
        expect(eurAccount.balanceMinor, 123456, reason: 'exact 2-decimal scale');
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

    test('custom (non-seed) category survives the v4->v5 reseed untouched',
        () async {
      final cat = await (db.select(
        db.categories,
      )..where((c) => c.id.equals('user_cat_custom_v1'))).getSingleOrNull();
      expect(cat, isNotNull);
      expect(cat!.name, 'My Custom Category');
    });
  });
}
