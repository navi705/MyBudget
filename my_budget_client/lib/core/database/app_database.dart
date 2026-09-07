import 'dart:async';

import 'package:my_budget_client/core/utils/calendar_day.dart';
import 'package:my_budget_client/core/utils/device_utils.dart' as dev_utils;
import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:intl/intl.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:my_budget_client/core/utils/region_utils.dart';
import 'package:my_budget_client/core/constants/app_constants.dart';
import 'package:my_budget_client/core/database/connection/database_connection.dart';
import 'package:my_budget_client/core/sync/device_local_settings.dart';
import 'package:my_budget_client/core/mappers/exchange_rate_mapper.dart';
import 'package:my_budget_client/core/utils/device_utils.dart';
import 'package:my_budget_client/core/utils/import_utils.dart';
import 'package:my_budget_client/data/seed_data/styles_data.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/value_objects/currency_precision.dart';
import 'package:my_budget_client/domain/entities/icon_type.dart';
import 'package:my_budget_client/domain/entities/transaction_type_filter.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';
import 'package:my_budget_client/data/seed_data/currency_designations_data.dart';
import 'package:my_budget_client/data/seed_data/currencies_data.dart';
import 'package:my_budget_client/data/seed_data/languages_data.dart';
import 'package:my_budget_client/data/seed_data/settings_data.dart';
import 'package:my_budget_client/data/seed_data/account_types_data.dart';
import 'package:my_budget_client/data/seed_data/categories_data.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/domain/entities/inflation_rate.dart';
import 'package:uuid/uuid.dart';

part 'app_database.g.dart';

const _uuid = Uuid();

/// Splits [values] into slices small enough to pass to `isIn`.
///
/// `isIn` binds one SQL variable per element and SQLite refuses a statement
/// with more than 999 of them (`SqliteException(1): too many SQL variables`).
/// The sync exporter hands these helpers every pending record id at once, so
/// the list is routinely far past that limit.
Iterable<List<T>> _sqlChunks<T>(List<T> values, {int size = 500}) sync* {
  for (var i = 0; i < values.length; i += size) {
    yield values.sublist(
      i,
      i + size < values.length ? i + size : values.length,
    );
  }
}

class CategoryWithTotal {
  final Category category;
  final double total;

  CategoryWithTotal({required this.category, required this.total});
}

// --- Business Tables ---

@DataClassName('Language')
class Languages extends Table {
  TextColumn get language => text().withLength(min: 1, max: 50)();
  TextColumn get languageCode => text().withLength(min: 1, max: 50)();

  // Sync fields
  IntColumn get modifiedAt => integer().withDefault(const Constant(0))();
  TextColumn get deviceId => text().nullable()();

  @override
  Set<Column> get primaryKey => {languageCode};
}

class CurrencyDesignations extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get value => text().withLength(min: 1, max: 5)();
  TextColumn get currencyCode => text().references(Currencies, #code)();

  // Sync fields
  IntColumn get modifiedAt => integer().withDefault(const Constant(0))();
  @ReferenceName('CurrencyDesignationDevice')
  TextColumn get deviceId => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Currencies extends Table {
  /// Deliberately not unique.
  ///
  /// The key is [code]; this is the label shown next to it, and two devices on
  /// different app versions do not agree on labels. The bundled seed renamed
  /// `BYR` to "Belarusian Ruble (2000-2016)" when `BYN` took over the plain
  /// name, and did the same for `SLL`/`SLE`. A device still on the older seed
  /// pushes `BYR = "Belarusian Ruble"`, which on the newer device is the name
  /// `BYN` already holds - and a UNIQUE here turned that into
  /// `SqliteException(2067)` inside the pull transaction. The pull applies all
  /// sixteen tables in one transaction and advances its cursor only after it
  /// commits, so the whole page rolled back and the next sync asked for the
  /// same page and failed the same way. Forever, including the WebSocket
  /// doorbell. Nothing reads a currency by name, so the constraint bought
  /// nothing and cost every pair of devices that were not on the same version.
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get code => text().withLength(min: 1, max: 5)();
  TextColumn get languageCode => text().references(Languages, #languageCode)();
  IntColumn get type => integer()
      .map(const EnumIndexConverter(TypeCurrency.values))
      .withDefault(const Constant(6))();

  // Sync fields
  IntColumn get modifiedAt => integer().withDefault(const Constant(0))();
  TextColumn get deviceId => text().nullable()();

  @override
  Set<Column> get primaryKey => {code};
}

class Categories extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get parentId => text().nullable().references(Categories, #id)();
  TextColumn get styleId => text().nullable().references(Styles, #id)();
  IntColumn get type => integer()
      .map(const EnumIndexConverter(CategoryType.values))
      .withDefault(const Constant(0))();

  // Sync fields
  IntColumn get modifiedAt => integer().withDefault(const Constant(0))();
  TextColumn get deviceId => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Style')
class Styles extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get iconName => text()();
  TextColumn get colorHex => text()();
  IntColumn get iconType => integer()
      .map(const EnumIndexConverter(IconType.values))
      .withDefault(const Constant(0))();

  // Sync fields
  IntColumn get modifiedAt => integer().withDefault(const Constant(0))();
  TextColumn get deviceId => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class AccountTypes extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();

  /// Deliberately not unique - see [Currencies.name] for what a UNIQUE on a
  /// synced label does.
  ///
  /// Same failure, one step further from the seed: the bundled types have
  /// stable ids, so a plain install cannot collide, but the name is the user's
  /// to edit. Rename "Savings" to "Cash" on the phone while the desktop still
  /// has the seeded "Cash", and the row that arrives carries a name another id
  /// holds. That threw inside the pull transaction, rolled the whole page back
  /// and left the cursor where it was, so every later sync retried the same
  /// page and failed the same way. Nothing looks an account type up by name.
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get languageCode => text().references(Languages, #languageCode)();

  // Sync fields
  IntColumn get modifiedAt => integer().withDefault(const Constant(0))();
  @ReferenceName('AccountTypeDevice')
  TextColumn get deviceId => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DbAccount') // Changed from Account to DbAccount
class Accounts extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get description => text().nullable()();
  RealColumn get balance => real()();
  // Exact integer minor units of [balance] for fiat currencies (see
  // CurrencyPrecision). NULL for crypto/commodity accounts, which stay on the
  // [balance] double. Kept in sync with [balance] by the balance-adjust DAO.
  IntColumn get balanceMinor => integer().nullable()();
  // What the account was worth before any of its transactions existed, and the
  // anchor [balance] is rebuilt from. [balance] is materialised, so two devices
  // that each add a transaction offline both send a whole balance and one of
  // them is simply overwritten, leaving a number that no set of transactions
  // explains. This one moves only when the user edits the account, so the
  // last writer really is the one who meant it.
  RealColumn get openingBalance => real().withDefault(const Constant(0.0))();
  // Exact integer minor units of [openingBalance], following [balanceMinor]:
  // NULL for crypto/commodity accounts, which stay on the double.
  IntColumn get openingBalanceMinor => integer().nullable()();
  TextColumn get currencyCode => text().references(Currencies, #code)();
  TextColumn get currencyDesignationId =>
      text().references(CurrencyDesignations, #id)();
  TextColumn get styleId => text().nullable().references(Styles, #id)();
  TextColumn get accountTypeId => text().references(AccountTypes, #id)();
  DateTimeColumn get creationDate =>
      dateTime().clientDefault(() => DateTime.now())();
  TextColumn get country => text().nullable()();
  TextColumn get assetId => text().nullable()(); // Added
  RealColumn get assetQuantity =>
      real().withDefault(const Constant(0.0))(); // Added
  TextColumn get feeStructure =>
      text().nullable()(); // Added: JSON string for Fee Constructor

  // Sync fields
  IntColumn get modifiedAt => integer().withDefault(const Constant(0))();
  TextColumn get deviceId => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_transactions_date', columns: {#date})
@TableIndex(name: 'idx_transactions_account', columns: {#accountId})
@TableIndex(name: 'idx_transactions_category', columns: {#categoryId})
// Composite indexes for dashboard queries:
// (date, category_id) — getTransactionTotalsGrouped groups by date+category
// (account_id, date)  — watchTransactionsFrom filters by account+date
@TableIndex(
  name: 'idx_transactions_date_category',
  columns: {#date, #categoryId},
)
@TableIndex(name: 'idx_transactions_account_date', columns: {#accountId, #date})
class Transactions extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get description => text().withLength(min: 1, max: 100)();
  RealColumn get amount => real()();
  // Exact integer minor units of [amount] for fiat currencies (see
  // CurrencyPrecision). NULL for crypto/commodity, which stay on the [amount]
  // double. Single-currency SQL aggregates (balances, per-currency subtotals)
  // sum this column so no floating-point drift accumulates.
  IntColumn get amountMinor => integer().nullable()();
  DateTimeColumn get date => dateTime()();
  TextColumn get accountId => text().references(Accounts, #id)();
  TextColumn get categoryId => text().references(Categories, #id)();
  TextColumn get currencyCode => text().references(Currencies, #code)();
  RealColumn get exchangeRate => real().nullable()(); // Added
  IntColumn get exchangeRatePreset => integer().nullable()(); // Added
  RealColumn get fee =>
      real().withDefault(const Constant(0.0))(); // Added: Fee/Commission
  // Exact integer minor units of [fee] for fiat currencies; NULL for non-fiat.
  IntColumn get feeMinor => integer().nullable()();
  TextColumn get linkedTransactionId =>
      text().nullable()(); // Added: ID of the linked transaction

  // Set on a transaction the app wrote without being sure where it belongs -
  // an SMS whose merchant matched no keyword, a cash withdrawal, a refund.
  // The row is real and counts towards every total; the flag only says a
  // person still has to look at it, and clearing it is what the review queue
  // on the transactions screen is for.
  BoolColumn get needsReview => boolean().withDefault(const Constant(false))();

  // Sync fields
  IntColumn get modifiedAt => integer().withDefault(const Constant(0))();
  TextColumn get deviceId => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_exchange_rates_date', columns: {#date})
@TableIndex(
  name: 'idx_exchange_rates_composite',
  columns: {#fromCurrencyCode, #toCurrencyCode, #date},
)
class ExchangeRates extends Table {
  TextColumn get fromCurrencyCode => text().references(Currencies, #code)();
  @ReferenceName('ToCurrencyRates')
  TextColumn get toCurrencyCode => text().references(Currencies, #code)();
  RealColumn get rate => real()();
  IntColumn get preset => integer()();
  DateTimeColumn get date => dateTime()();

  // Sync fields
  IntColumn get modifiedAt => integer().withDefault(const Constant(0))();
  TextColumn get deviceId => text().nullable()();
  TextColumn get sourceId => text().nullable()(); // Custom API source

  @override
  Set<Column> get primaryKey => {
    fromCurrencyCode,
    toCurrencyCode,
    date,
    preset,
  };
}

/// Marks a rate that applies worldwide rather than to a single country.
///
/// SQLite counts NULLs in a rowid table's PRIMARY KEY as distinct, so a
/// nullable [InflationRates.country] let the same worldwide month be inserted
/// over and over instead of replacing itself. The sentinel is what the sync
/// record id has always used for these rows.
const globalInflationCountry = 'global';

class InflationRates extends Table {
  DateTimeColumn get date => dateTime()();
  RealColumn get percent => real()();
  TextColumn get country =>
      text().withDefault(const Constant(globalInflationCountry))();
  IntColumn get preset => integer()();

  // Sync fields
  IntColumn get modifiedAt => integer().withDefault(const Constant(0))();
  TextColumn get deviceId => text().nullable()();
  TextColumn get sourceId => text().nullable()(); // Custom API source

  @override
  Set<Column> get primaryKey => {date, country, preset};
}

class AssetEntries extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get assetId => text()();
  TextColumn get name => text()(); // Added
  DateTimeColumn get date => dateTime()();
  RealColumn get value => real()();
  RealColumn get quantity => real().withDefault(const Constant(1.0))();
  TextColumn get assetType => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get currencyCode => text().references(Currencies, #code)();
  TextColumn get accountId =>
      text().nullable().references(Accounts, #id)(); // Added
  TextColumn get source => text()();
  IntColumn get preset => integer().withDefault(const Constant(1))();

  // Sync fields
  IntColumn get modifiedAt => integer().withDefault(const Constant(0))();
  TextColumn get deviceId => text().nullable()();
  TextColumn get sourceId => text().nullable()(); // Custom API source
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// --- Technical Tables ---

@DataClassName('Setting')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  TextColumn get device => text().nullable()();

  // Sync fields
  IntColumn get modifiedAt => integer().withDefault(const Constant(0))();
  TextColumn get deviceId => text().nullable()();

  @override
  Set<Column> get primaryKey => {key};
}

@DataClassName('DbCustomTheme')
class CustomThemes extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get primaryColorHex => text()();
  TextColumn get secondaryColorHex => text()();
  TextColumn get surfaceColorHex => text()();
  TextColumn get backgroundColorHex => text()();
  TextColumn get backgroundImagePath => text().nullable()();
  RealColumn get backgroundImageOpacity =>
      real().withDefault(const Constant(1.0))();
  RealColumn get backgroundImageBlur =>
      real().withDefault(const Constant(0.0))();
  IntColumn get windowEffectType => integer()();
  RealColumn get effectOpacity => real().withDefault(const Constant(1.0))();
  RealColumn get surfaceOpacity => real().withDefault(const Constant(1.0))();
  IntColumn get themeMode => integer()(); // 0: system, 1: light, 2: dark
  BoolColumn get isPreset => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();

  // Sync fields
  IntColumn get modifiedAt => integer().withDefault(const Constant(0))();
  TextColumn get deviceId => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// --- Sync Tables ---

/// Tracks local changes for sync export
class SyncLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get changedTableName => text()(); // Renamed from tableName
  TextColumn get recordId => text()();
  TextColumn get action => text()(); // upsert, delete
  IntColumn get timestamp => integer()();
  BoolColumn get exported => boolean().withDefault(const Constant(false))();
}

/// Rows this device still owes the HTTP sync server: one entry per change,
/// removed only once the server has answered 200 for the row that carries it.
///
/// It replaces the old `modified_at > last-push-timestamp` window, which could
/// only ever describe changes the local clock had made *since* that instant. A
/// row arriving from a peer through the file engine carries the timestamp of
/// the device that wrote it, and a device whose clock is set back writes rows
/// below its own watermark — both land under the mark and were never pushed at
/// all, with nothing anywhere reporting them as unsent.
///
/// Deliberately not [SyncLog]. That table's single `exported` flag belongs to
/// the peer-to-peer file engine: a second consumer clearing it would make each
/// engine's rows disappear from the other's queue. It is also written only by
/// the Dart DAO helpers, so the raw-SQL write paths — a server pull's upserts,
/// an import's `INSERT OR REPLACE` — never show up in it, which is exactly the
/// set of rows that used to go missing.
@TableIndex(
  name: 'idx_sync_push_queue_table',
  columns: {#changedTableName, #id},
)
class SyncPushQueue extends Table {
  /// AUTOINCREMENT (what drift emits for [autoIncrement]), so an id is never
  /// handed out twice. A push deletes the exact ids it read; with reused ids
  /// that delete could land on an entry queued for a later edit of the same row
  /// while the push was in flight, and that edit would never be sent again.
  IntColumn get id => integer().autoIncrement()();
  TextColumn get changedTableName => text()();

  /// The row's primary key, built by [syncPushQueueKeyExpression] so the push
  /// can find the row again — composite keys joined with `|`.
  TextColumn get recordKey => text()();
}

/// The tables whose rows the server sync pushes, and therefore the ones the
/// push queue has triggers on.
const List<String> syncPushQueueTables = [
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

/// The seeded tables whose rows the sync server holds a foreign key into.
///
/// The bundled seed is written before the push-queue triggers exist, on
/// purpose: every install lays down the same rows under the same ids, so
/// queueing all of it would upload ~283k exchange rates that any other client
/// would have supplied byte for byte. That reasoning is sound for bulk
/// reference data and wrong for these four, because the server's schema
/// declares real foreign keys against them —
/// `accounts.currency_designation_id`, `accounts.account_type_id`,
/// `accounts.style_id`, `categories.style_id` and `transactions.category_id`.
///
/// "some other client will have pushed them" is only true if some client ever
/// does. On a server whose clients are all fresh installs, none of them ever
/// did: the first account the user made referenced a seeded designation the
/// server had never heard of, the push came back `23503`, and because a failed
/// push deliberately does not drain its queue, that device retried the same
/// doomed batch forever. Uploads stopped dead while pulls kept working, which
/// reads as "this phone receives but never sends".
///
/// A few dozen rows, once per install. See [AppDatabase.seedPushQueueParents].
const List<String> syncPushQueueSeedTables = [
  'styles',
  'account_types',
  'currency_designations',
  'categories',
];

/// Columns every device computes for itself, per table.
///
/// A write that touches ONLY these is not a change any peer needs: the balance
/// of an account is derived from its transactions, so a rebuild rewrites it on
/// purpose without stamping the row, and every peer arrives at the same number
/// on its own. They are excluded from the update triggers' change test — see
/// [_pushQueueUpdateCondition] — because queueing them re-uploads every account
/// a rebuild touched after every single pull, for rows the server's
/// last-write-wins guard is guaranteed to discard.
const Map<String, Set<String>> syncPushQueueDerivedColumns = {
  'accounts': {'balance', 'balance_minor'},
};

/// SQL reading this device's sync identity out of the settings table.
///
/// A subquery rather than a value bound at trigger-creation time: the identity
/// is written during seeding, after the triggers of a fresh install exist, and
/// a trigger body is frozen the moment it is created.
const String _localDeviceIdSql =
    "(SELECT value FROM settings WHERE key = 'local_device_id')";

/// The device id written on rates this device pulled from its sync server.
///
/// The same string the server stamps on the rates it fetches, so a row says
/// where it came from on both sides. Rows carrying it are excluded from the
/// server's sync pull, and this device does not push them back up.
const String kServerRateDeviceId = 'server:rates';

/// The currency codes this database has any use for: the ones its accounts,
/// transactions and assets are denominated in, the main currency, and EUR.
///
/// EUR is unconditional because every published rate is quoted against it, so
/// a filter that drops it takes the whole table with it. Deliberately not
/// `currency_designations`: the seed ships a symbol for all 341 currencies, so
/// that table says nothing about which of them the user holds.
const String kUsedCurrenciesSql = '''
  SELECT currency_code AS code FROM accounts
   UNION SELECT currency_code FROM transactions
   UNION SELECT currency_code FROM asset_entries
   UNION SELECT value FROM settings WHERE key = 'main_currency_code'
   UNION SELECT 'EUR'
''';

/// SQL matching the bulk-seeded rate rows, and only those.
///
/// `preset = 1` on its own is not that set, which is the trap here: the daily
/// provider fetch (`ExchangeRateApiService._saveRatesToDb`) and a manually
/// entered default rate (`AddEditTransactionBloc`) both write preset 1 as
/// well, and no column records where a rate came from. What separates them is
/// batch size. [ExchangeRatesDao.insertAllExchangeRates] stamps one
/// `modified_at` across a whole call; the seed passes the entire bundled
/// history in a single call, a day's fetch is one row per known currency - a
/// few hundred at most - and a manual entry is one row. One stamp shared by a
/// thousand rows or more can only be the seed.
const String seededExchangeRatesFilter = """
preset = 1
      AND modified_at IN (
            SELECT modified_at
              FROM exchange_rates
             WHERE preset = 1
             GROUP BY modified_at
            HAVING COUNT(*) >= 1000
          )
""";

/// SQL rendering a row of [table] into the text held in
/// [SyncPushQueue.recordKey].
///
/// [prefix] is `NEW.` inside a trigger and empty in a plain SELECT. One
/// function serves both because a queued key that the push cannot rebuild is a
/// row that stays queued forever, re-read and re-skipped on every sync.
String syncPushQueueKeyExpression(String table, {String prefix = ''}) {
  switch (table) {
    case 'languages':
      return '${prefix}language_code';
    case 'currencies':
      return '${prefix}code';
    case 'settings':
      return '${prefix}key';
    case 'exchange_rates':
      return "${prefix}from_currency_code || '|' || ${prefix}to_currency_code "
          "|| '|' || ${prefix}date || '|' || ${prefix}preset";
    case 'inflation_rates':
      // COALESCE because `country` was nullable before v10 and NULL poisons the
      // whole concatenation — the trigger would then insert NULL into a NOT NULL
      // column and abort the user's write, not just the bookkeeping.
      return "${prefix}date || '|' || "
          "COALESCE(${prefix}country, '$globalInflationCountry') || '|' || "
          '${prefix}preset';
    default:
      return '${prefix}id';
  }
}

/// The index that lets the push resolve a queued key of [table] back to its
/// row, or null when the key needs no index of its own.
///
/// Every single-column key above (`id`, `code`, `key`, `language_code`) is that
/// table's primary key, so `key IN (?, ?, …)` already rides the primary key's
/// index. The two concatenated keys have nothing in the schema that can match
/// them — no index serves an expression unless it was built on that expression
/// — so those two get one built here.
String? syncPushQueueKeyIndexName(String table) {
  // Decided from the expression rather than a second hand-kept table list: a
  // key that changes shape must not keep an index that no longer serves it,
  // and a new concatenated key must not silently miss out on one.
  return syncPushQueueKeyExpression(table).contains('||')
      ? 'idx_${table}_push_key'
      : null;
}

/// Stores rejected versions during conflict resolution
class ConflictHistory extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get changedTableName => text()(); // Renamed from tableName
  TextColumn get recordId => text()();
  TextColumn get rejectedData => text()(); // JSON
  IntColumn get rejectedAt => integer()();
  TextColumn get rejectedDevice => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Custom API data sources
class CustomDataSources extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get name => text()();
  TextColumn get url => text()();
  IntColumn get dataType => integer()(); // 0=exchange, 1=inflation, 2=asset
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  BoolColumn get autoFetch => boolean().withDefault(const Constant(false))();
  IntColumn get lastFetchAt => integer().nullable()();

  // Sync fields
  IntColumn get modifiedAt => integer().withDefault(const Constant(0))();
  TextColumn get deviceId => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Built-in API settings
@DataClassName('ApiSettingsTableData')
class ApiSettingsTable extends Table {
  TextColumn get id => text()(); // "exchange_rates", "inflation", "assets"
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  BoolColumn get autoFetch => boolean().withDefault(const Constant(false))();
  IntColumn get lastFetchAt => integer().nullable()();

  // Sync fields
  IntColumn get modifiedAt => integer().withDefault(const Constant(0))();
  TextColumn get deviceId => text().nullable()();

  /// Tombstone flag, like every other synced table.
  ///
  /// Without it a delete for a provider row the peer had never seen was a
  /// no-op there, and the upsert that had been sitting in an earlier file
  /// simply recreated the row - a provider the user removed came back, and
  /// started fetching again.
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tracks which sync files have already been processed
class SyncProcessedFiles extends Table {
  TextColumn get fileName => text()();
  IntColumn get processedAt => integer()();
  TextColumn get deviceId => text()();

  @override
  Set<Column> get primaryKey => {fileName};
}

/// SMS parsing presets (migrated from SharedPreferences)
class SmsPresets extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get name => text()();
  TextColumn get senderFilter => text()();
  BoolColumn get isBuiltIn => boolean().withDefault(const Constant(false))();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  TextColumn get defaultAccountId => text().nullable()();
  TextColumn get defaultCategoryId => text().nullable()();
  TextColumn get rulesJson => text()(); // JSON array of parsing rules

  // Sync fields
  IntColumn get modifiedAt => integer().withDefault(const Constant(0))();
  TextColumn get deviceId => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftAccessor(tables: [Languages])
class LanguageDao extends DatabaseAccessor<AppDatabase>
    with _$LanguageDaoMixin {
  LanguageDao(super.db);

  Future<List<Language>> getAllLanguages() => select(languages).get();
  Future<List<Language>> getLanguages({int limit = 10, int offset = 0}) =>
      (select(languages)..limit(limit, offset: offset)).get();
  Stream<List<Language>> watchAllLanguages() => select(languages).watch();
  Future<void> insertLanguage(LanguagesCompanion lang) =>
      into(languages).insert(lang);
  Future<bool> updateLanguage(LanguagesCompanion lang) async {
    // `replace` writes the column default for every defaulted column the
    // companion left out, so an update carrying only the new display name also
    // reset `modifiedAt` to 0 - the row then sorts as never-modified and no
    // peer ever pulls the rename. `write` ignores absent fields.
    final count =
        await (update(languages)
              ..where((t) => t.languageCode.equals(lang.languageCode.value)))
            .write(lang);
    return count > 0;
  }

  Future<int> deleteLanguage(LanguagesCompanion lang) =>
      delete(languages).delete(lang);

  Future<void> insertAllLanguages(List<LanguagesCompanion> languages) {
    return batch((batch) {
      batch.insertAll(
        this.languages,
        languages,
        mode: InsertMode.insertOrReplace,
      );
    });
  }
}

@DriftAccessor(tables: [CurrencyDesignations])
class CurrencyDesignationsDao extends DatabaseAccessor<AppDatabase>
    with _$CurrencyDesignationsDaoMixin {
  CurrencyDesignationsDao(super.db);

  Future<List<CurrencyDesignation>> getAllDesignations() => (select(
    currencyDesignations,
  )..where((t) => t.isDeleted.equals(false))).get();
  Future<List<CurrencyDesignation>> getDesignations({
    int limit = 10,
    int offset = 0,
  }) =>
      (select(currencyDesignations)
            ..where((t) => t.isDeleted.equals(false))
            ..limit(limit, offset: offset))
          .get();
  Stream<List<CurrencyDesignation>> watchAllDesignations() => (select(
    currencyDesignations,
  )..where((t) => t.isDeleted.equals(false))).watch();
  Future<CurrencyDesignation?> getDesignationById(String id) =>
      (select(currencyDesignations)
            ..where((tbl) => tbl.id.equals(id) & tbl.isDeleted.equals(false)))
          .getSingleOrNull();

  Future<List<CurrencyDesignation>> getDesignationsByIds(
    List<String> ids,
  ) async {
    final results = <CurrencyDesignation>[];
    for (final chunk in _sqlChunks(ids)) {
      results.addAll(
        await (select(
          currencyDesignations,
        )..where((t) => t.id.isIn(chunk) & t.isDeleted.equals(false))).get(),
      );
    }
    return results;
  }

  Future<void> insertDesignation(
    CurrencyDesignationsCompanion designation,
  ) async {
    var toInsert = designation.id.present
        ? designation
        : designation.copyWith(id: Value(_uuid.v4()));

    toInsert = toInsert.copyWith(
      modifiedAt: Value(DateTime.now().millisecondsSinceEpoch),
    );

    await into(currencyDesignations).insert(toInsert);
    await _logChange(toInsert.id.value, 'upsert');
  }

  Future<void> insertSyncedDesignation(
    CurrencyDesignationsCompanion designation,
  ) => into(
    currencyDesignations,
  ).insert(designation, mode: InsertMode.insertOrReplace);

  Future<void> insertAllCurrencyDesignations(
    List<CurrencyDesignationsCompanion> designations,
  ) async {
    final List<CurrencyDesignationsCompanion> designationsWithIds = designations
        .map((d) {
          final now = DateTime.now().millisecondsSinceEpoch;
          var companion = d;
          if (!companion.id.present) {
            companion = companion.copyWith(id: Value(_uuid.v4()));
          }
          if (!companion.modifiedAt.present ||
              companion.modifiedAt.value == 0) {
            companion = companion.copyWith(modifiedAt: Value(now));
          }
          return companion;
        })
        .toList();

    await batch((batch) {
      batch.insertAll(
        currencyDesignations,
        designationsWithIds,
        mode: InsertMode.insertOrReplace,
      );
    });

    final ids = designationsWithIds.map((d) => d.id.value).toList();
    await _logChanges(ids, 'upsert');
  }

  Future<bool> updateDesignation(
    CurrencyDesignationsCompanion designation,
  ) async {
    final updatedDesignation = designation.copyWith(
      // The id addresses the row, it is never part of the new values.
      id: const Value.absent(),
      modifiedAt:
          (designation.modifiedAt.present && designation.modifiedAt.value > 0)
          ? designation.modifiedAt
          : Value(DateTime.now().millisecondsSinceEpoch),
    );
    // Deliberately NOT `replace`: replace writes every column of the table, and
    // the companion the UI builds carries no isDeleted, so a designation the
    // user deleted came back to life - on this device and, through the upsert
    // below, on every paired one - the moment anything re-saved that id.
    // Scoping the write to live rows also makes editing a deleted designation
    // the no-op the caller already expects, since it cannot even load one.
    final count =
        await (update(currencyDesignations)..where(
              (t) =>
                  t.id.equals(designation.id.value) & t.isDeleted.equals(false),
            ))
            .write(updatedDesignation);
    final result = count > 0;
    if (result) {
      await _logChange(designation.id.value, 'upsert');
    }
    return result;
  }

  Future<int> deleteDesignation(
    CurrencyDesignationsCompanion designation,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final updatedDesignation = CurrencyDesignationsCompanion(
      isDeleted: const Value(true),
      modifiedAt: Value(now),
    );

    final count =
        await (update(currencyDesignations)
              ..where((t) => t.id.equals(designation.id.value)))
            .write(updatedDesignation);

    if (count > 0) {
      await _logChange(designation.id.value, 'delete');
    }
    return count;
  }

  Future<void> _logChange(String recordId, String action) async {
    await into(db.syncLog).insert(
      SyncLogCompanion(
        changedTableName: const Value('currency_designations'),
        recordId: Value(recordId),
        action: Value(action),
        timestamp: Value(DateTime.now().millisecondsSinceEpoch),
        exported: const Value(false),
      ),
    );
  }

  Future<void> _logChanges(List<String> recordIds, String action) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await batch((batch) {
      batch.insertAll(
        db.syncLog,
        recordIds
            .map(
              (id) => SyncLogCompanion(
                changedTableName: const Value('currency_designations'),
                recordId: Value(id),
                action: Value(action),
                timestamp: Value(timestamp),
                exported: const Value(false),
              ),
            )
            .toList(),
      );
    });
  }
}

@DriftAccessor(tables: [Currencies])
class CurrenciesDao extends DatabaseAccessor<AppDatabase>
    with _$CurrenciesDaoMixin {
  CurrenciesDao(super.db);

  Future<List<Currency>> getAllCurrencies() => select(currencies).get();
  Future<List<Currency>> getCurrencies({int limit = 10, int offset = 0}) =>
      (select(currencies)..limit(limit, offset: offset)).get();
  Stream<List<Currency>> watchAllCurrencies() => select(currencies).watch();
  Future<Currency?> getCurrencyByCode(String code) => (select(
    currencies,
  )..where((tbl) => tbl.code.equals(code))).getSingleOrNull();

  /// How many rows the user already has in each currency: one point per
  /// account that keeps it, one per transaction written in it.
  ///
  /// The picker lists every currency the app knows - 341 of them - in
  /// alphabetical order, so the two or three a person actually works in are
  /// always behind a scroll or a search. This is what puts them at the top,
  /// and it needs no bookkeeping of its own: the counts come back out of the
  /// rows that were going to be written anyway, so there is nothing extra to
  /// keep in step, migrate or push to a peer.
  Future<Map<String, int>> getCurrencyUsageCounts() async {
    final rows = await customSelect(
      // Soft-deleted rows are left out: a currency the user threw away with
      // the account that held it is not one they are still working in.
      'SELECT code, COUNT(*) AS uses FROM ('
      'SELECT currency_code AS code FROM accounts WHERE is_deleted = 0 '
      'UNION ALL '
      'SELECT currency_code AS code FROM transactions WHERE is_deleted = 0'
      ') GROUP BY code',
      readsFrom: {db.accounts, db.transactions},
    ).get();
    return {
      for (final row in rows) row.read<String>('code'): row.read<int>('uses'),
    };
  }

  Future<void> insertCurrency(CurrenciesCompanion currency) async {
    // Import auto-creates currencies for unmapped CSV codes; without a fresh
    // modifiedAt the row sorts as never-modified and no peer ever pulls it.
    final toInsert = currency.copyWith(
      modifiedAt: Value(DateTime.now().millisecondsSinceEpoch),
    );
    await into(currencies).insert(toInsert);
    await _logChange(toInsert.code.value, 'upsert');
  }

  /// Bulk lookup for the sync exporter, which keys currencies by their code.
  Future<List<Currency>> getCurrenciesByCodes(List<String> codes) async {
    final results = <Currency>[];
    for (final chunk in _sqlChunks(codes)) {
      results.addAll(
        await (select(currencies)..where((t) => t.code.isIn(chunk))).get(),
      );
    }
    return results;
  }

  /// Apply a peer's currency without re-logging it as a local change.
  Future<void> insertSyncedCurrency(CurrenciesCompanion currency) =>
      into(currencies).insert(currency, mode: InsertMode.insertOrReplace);

  Future<void> insertAllCurrencies(List<CurrenciesCompanion> currencies) {
    return batch((batch) {
      batch.insertAll(
        this.currencies,
        currencies,
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  Future<bool> updateCurrency(CurrenciesCompanion currency) async {
    // CurrencyMapper.toCompanion carries no modifiedAt, and `replace` writes
    // the column default for every column the companion omits - so renaming a
    // currency stamped `modified_at = 0` and the rename then looked older than
    // every remote copy, which threw it away and brought the old name back on
    // the next sync. `write` leaves absent fields alone; the stamp is what
    // insertCurrency already does for the same reason.
    final updated = currency.copyWith(
      modifiedAt: Value(DateTime.now().millisecondsSinceEpoch),
    );
    final count = await (update(
      currencies,
    )..where((t) => t.code.equals(updated.code.value))).write(updated);
    return count > 0;
  }

  Future<int> deleteCurrency(CurrenciesCompanion currency) =>
      delete(currencies).delete(currency);

  Future<void> _logChange(String recordId, String action) async {
    await into(db.syncLog).insert(
      SyncLogCompanion(
        changedTableName: const Value('currencies'),
        recordId: Value(recordId),
        action: Value(action),
        timestamp: Value(DateTime.now().millisecondsSinceEpoch),
        exported: const Value(false),
      ),
    );
  }
}

@DriftAccessor(tables: [Categories, Transactions, SyncLog])
class CategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  Future<List<Category>> getAllCategories() =>
      (select(categories)..where((t) => t.isDeleted.equals(false))).get();
  Future<List<Category>> getCategories({int limit = 10, int offset = 0}) =>
      (select(categories)
            ..where((t) => t.isDeleted.equals(false))
            ..limit(limit, offset: offset))
          .get();
  Future<Category?> getCategoryById(String id) =>
      (select(categories)
            ..where((tbl) => tbl.id.equals(id) & tbl.isDeleted.equals(false)))
          .getSingleOrNull();

  Future<List<Category>> getCategoriesByIds(List<String> ids) async {
    const int chunkSize = 500;
    List<Category> allResults = [];

    for (var i = 0; i < ids.length; i += chunkSize) {
      final end = (i + chunkSize < ids.length) ? i + chunkSize : ids.length;
      final chunk = ids.sublist(i, end);

      final chunkResults = await (select(
        categories,
      )..where((u) => u.id.isIn(chunk) & u.isDeleted.equals(false))).get();

      allResults.addAll(chunkResults);
    }
    final resultMap = {for (var style in allResults) style.id: style};
    return ids.map((id) => resultMap[id]).whereType<Category>().toList();
  }

  Stream<List<Category>> watchAllCategories() =>
      (select(categories)..where((t) => t.isDeleted.equals(false))).watch();

  Future<void> insertCategory(CategoriesCompanion category) async {
    var toInsert = category.id.present
        ? category
        : category.copyWith(id: Value(_uuid.v4()));

    toInsert = toInsert.copyWith(
      modifiedAt: Value(DateTime.now().millisecondsSinceEpoch),
    );

    await into(categories).insert(toInsert);
    await _logChange(toInsert.id.value, 'upsert');
  }

  Future<void> insertSyncedCategory(CategoriesCompanion category) =>
      into(categories).insert(category, mode: InsertMode.insertOrReplace);

  Future<void> insertAllCategories(List<CategoriesCompanion> categories) async {
    final List<CategoriesCompanion> categoriesWithIds = categories.map((c) {
      final now = DateTime.now().millisecondsSinceEpoch;
      var companion = c;
      if (!companion.id.present) {
        companion = companion.copyWith(id: Value(_uuid.v4()));
      }
      if (!companion.modifiedAt.present || companion.modifiedAt.value == 0) {
        companion = companion.copyWith(modifiedAt: Value(now));
      }
      return companion;
    }).toList();

    await batch((batch) {
      batch.insertAll(
        this.categories,
        categoriesWithIds,
        mode: InsertMode.insertOrReplace,
      );
    });
    // Log changes for sync
    final ids = categoriesWithIds.map((c) => c.id.value).toList();
    await _logChanges(ids, 'upsert');
  }

  /// Log multiple changes for sync export
  Future<void> _logChanges(List<String> recordIds, String action) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await batch((batch) {
      batch.insertAll(
        syncLog,
        recordIds
            .map(
              (id) => SyncLogCompanion(
                changedTableName: const Value('categories'),
                recordId: Value(id),
                action: Value(action),
                timestamp: Value(timestamp),
                exported: const Value(false),
              ),
            )
            .toList(),
      );
    });
  }

  Future<bool> updateCategory(CategoriesCompanion category) async {
    final updatedCategory = category.copyWith(
      modifiedAt: (category.modifiedAt.present && category.modifiedAt.value > 0)
          ? category.modifiedAt
          : Value(DateTime.now().millisecondsSinceEpoch),
    );
    // `replace` writes the column default for every column the companion
    // omits, and CategoryMapper.toCompanion never sets `isDeleted`. Saving an
    // edit to a category a sync pull had already tombstoned therefore cleared
    // the tombstone, and because the update stamps a fresh `modifiedAt` the
    // resurrection won last-write-wins everywhere: a category the user deleted
    // on one device came back on all of them. `write` touches only the fields
    // the caller actually set.
    final count =
        await (update(categories)
              ..where((t) => t.id.equals(updatedCategory.id.value)))
            .write(updatedCategory);
    // Nothing changed means nothing for a peer to fetch; announcing the id
    // anyway made every peer ask for a category this device does not have.
    if (count > 0) {
      await _logChange(category.id.value, 'upsert');
    }
    return count > 0;
  }

  Future<int> deleteCategory(CategoriesCompanion category) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final updatedCategory = CategoriesCompanion(
      isDeleted: const Value(true),
      modifiedAt: Value(now),
    );

    final count = await (update(
      categories,
    )..where((t) => t.id.equals(category.id.value))).write(updatedCategory);

    if (count > 0) {
      await _logChange(category.id.value, 'delete');
    }
    return count;
  }

  /// Log a change for sync export
  Future<void> _logChange(String recordId, String action) async {
    await into(syncLog).insert(
      SyncLogCompanion(
        changedTableName: const Value('categories'),
        recordId: Value(recordId),
        action: Value(action),
        timestamp: Value(DateTime.now().millisecondsSinceEpoch),
        exported: const Value(false),
      ),
    );
  }

  Future<void> deleteCategoryWithTransactions(String categoryId) {
    return db.transaction(() async {
      final now = DateTime.now().millisecondsSinceEpoch;
      // Captured before the write: afterwards nothing links these rows to the
      // category any more, and a peer told only about the category would keep
      // showing every transaction that hung off it.
      final txIds = await _transactionIdsInCategory(categoryId);

      await (update(
        db.transactions,
      )..where((t) => t.categoryId.equals(categoryId))).write(
        TransactionsCompanion(
          isDeleted: const Value(true),
          modifiedAt: Value(now),
        ),
      );
      await (update(categories)..where((c) => c.id.equals(categoryId))).write(
        CategoriesCompanion(
          isDeleted: const Value(true),
          modifiedAt: Value(now),
        ),
      );
      await _logChange(categoryId, 'delete');
      if (txIds.isNotEmpty) await _logTransactionChanges(txIds, 'delete');
    });
  }

  Future<void> deleteCategoryAndReassignTransactions(
    String categoryId,
    String newCategoryId,
  ) {
    return db.transaction(() async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final txIds = await _transactionIdsInCategory(categoryId);

      await (update(
        db.transactions,
      )..where((t) => t.categoryId.equals(categoryId))).write(
        TransactionsCompanion(
          categoryId: Value(newCategoryId),
          modifiedAt: Value(now),
        ),
      );
      await (update(categories)..where((c) => c.id.equals(categoryId))).write(
        CategoriesCompanion(
          isDeleted: const Value(true),
          modifiedAt: Value(now),
        ),
      );
      await _logChange(categoryId, 'delete');
      // The rows survive, they only moved category: 'upsert', not 'delete'.
      if (txIds.isNotEmpty) await _logTransactionChanges(txIds, 'upsert');
    });
  }

  Future<List<String>> _transactionIdsInCategory(String categoryId) async {
    final rows = await (select(
      db.transactions,
    )..where((t) => t.categoryId.equals(categoryId))).get();
    return rows.map((t) => t.id).toList();
  }

  /// Log transaction-table changes made as a side effect of a category
  /// mutation ([_logChanges] is hard-coded to the `categories` table).
  Future<void> _logTransactionChanges(
    List<String> recordIds,
    String action,
  ) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await batch((batch) {
      batch.insertAll(
        syncLog,
        recordIds
            .map(
              (id) => SyncLogCompanion(
                changedTableName: const Value('transactions'),
                recordId: Value(id),
                action: Value(action),
                timestamp: Value(timestamp),
                exported: const Value(false),
              ),
            )
            .toList(),
      );
    });
  }

  Stream<Map<String, double>> watchCategoryTotals() {
    final amount = attachedDatabase.transactions.amount.total();
    final query = select(attachedDatabase.transactions).join([
      innerJoin(
        categories,
        categories.id.equalsExp(attachedDatabase.transactions.categoryId),
      ),
    ]);
    query.addColumns([amount]);
    query.groupBy([categories.id]);

    return query.watch().map((rows) {
      final a = <String, double>{
        for (final row in rows) row.read(categories.id)!: row.read(amount)!,
      };
      return a;
    });
  }

  Future<List<CategoryWithTotal>> getCategoriesWithTotals({
    int limit = 50,
    int offset = 0,
    OrderingMode sort = OrderingMode.desc,
    String? name,
    DateTime? dateFrom,
    DateTime? dateTo,
    CategoryType? type,
  }) {
    var sql = '''
      SELECT
        c.*,
        t.total
      FROM categories c
      LEFT JOIN (
        SELECT category_id, SUM(amount) AS total
        FROM transactions
    ''';

    List<Variable> variables = [];
    // Soft-deleted rows are hidden everywhere else; leaving them in here made
    // the Categories screen total money the user had already thrown away.
    List<String> whereClauses = ['is_deleted = 0'];

    if (dateFrom != null) {
      whereClauses.add('date >= ?');
      variables.add(Variable.withDateTime(dateFrom));
    }
    if (dateTo != null) {
      whereClauses.add('date <= ?');
      variables.add(Variable.withDateTime(dateTo));
    }

    sql += ' WHERE ${whereClauses.join(' AND ')}';

    sql += '''
        GROUP BY category_id
      ) t ON t.category_id = c.id
    ''';

    List<String> outerWhereClauses = ['c.is_deleted = 0'];
    if (name != null && name.isNotEmpty) {
      outerWhereClauses.add('c.name LIKE ?');
      variables.add(Variable('%$name%'));
    }
    if (type != null) {
      outerWhereClauses.add('c.type = ?');
      variables.add(Variable(type.index));
    }

    sql += ' WHERE ${outerWhereClauses.join(' AND ')}';

    sql += ' ORDER BY c.name ${sort == OrderingMode.asc ? 'ASC' : 'DESC'}';
    sql += ' LIMIT ? OFFSET ?';
    variables.add(Variable(limit));
    variables.add(Variable(offset));

    final query = customSelect(
      sql,
      variables: variables,
      readsFrom: {categories, transactions},
    );

    return query.map((row) {
      final category = categories.map(row.data);
      final total = row.read<double?>('total') ?? 0.0;
      return CategoryWithTotal(category: category, total: total);
    }).get();
  }
}

@DriftAccessor(tables: [Styles, SyncLog])
class StylesDao extends DatabaseAccessor<AppDatabase> with _$StylesDaoMixin {
  StylesDao(super.db);

  Future<List<Style>> getAllStyles() =>
      (select(styles)..where((t) => t.isDeleted.equals(false))).get();
  Future<List<Style>> getStyles({int limit = 10, int offset = 0}) =>
      (select(styles)
            ..where((t) => t.isDeleted.equals(false))
            ..limit(limit, offset: offset))
          .get();
  Stream<List<Style>> watchAllStyles() =>
      (select(styles)..where((t) => t.isDeleted.equals(false))).watch();
  Future<Style?> getStyleById(String id) =>
      (select(styles)
            ..where((tbl) => tbl.id.equals(id) & tbl.isDeleted.equals(false)))
          .getSingleOrNull();

  Future<List<Style>> getStylesByIds(List<String> ids) async {
    const int chunkSize = 500;
    List<Style> allResults = [];

    for (var i = 0; i < ids.length; i += chunkSize) {
      final end = (i + chunkSize < ids.length) ? i + chunkSize : ids.length;
      final chunk = ids.sublist(i, end);

      final chunkResults = await (select(
        styles,
      )..where((u) => u.id.isIn(chunk) & u.isDeleted.equals(false))).get();

      allResults.addAll(chunkResults);
    }

    final resultMap = {for (var style in allResults) style.id: style};

    return ids.map((id) => resultMap[id]).whereType<Style>().toList();
  }

  Future<void> insertStyle(StylesCompanion style) async {
    var toInsert = style.id.present
        ? style
        : style.copyWith(id: Value(_uuid.v4()));

    toInsert = toInsert.copyWith(
      modifiedAt: Value(DateTime.now().millisecondsSinceEpoch),
    );

    await into(styles).insert(toInsert);
    await _logChange(toInsert.id.value, 'upsert');
  }

  Future<void> insertSyncedStyle(StylesCompanion style) =>
      into(styles).insert(style, mode: InsertMode.insertOrReplace);

  Future<void> insertAllStyles(List<StylesCompanion> styles) async {
    final List<StylesCompanion> stylesWithIds = styles.map((s) {
      final now = DateTime.now().millisecondsSinceEpoch;
      var companion = s;
      if (!companion.id.present) {
        companion = companion.copyWith(id: Value(_uuid.v4()));
      }
      if (!companion.modifiedAt.present || companion.modifiedAt.value == 0) {
        companion = companion.copyWith(modifiedAt: Value(now));
      }
      return companion;
    }).toList();

    await batch((batch) {
      batch.insertAll(
        this.styles,
        stylesWithIds,
        mode: InsertMode.insertOrReplace,
      );
    });
    // Log changes for sync
    final ids = stylesWithIds.map((s) => s.id.value).toList();
    await _logChanges(ids, 'upsert');
  }

  Future<void> _logChanges(List<String> recordIds, String action) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await batch((batch) {
      batch.insertAll(
        syncLog,
        recordIds
            .map(
              (id) => SyncLogCompanion(
                changedTableName: const Value('styles'),
                recordId: Value(id),
                action: Value(action),
                timestamp: Value(timestamp),
                exported: const Value(false),
              ),
            )
            .toList(),
      );
    });
  }

  Future<bool> updateStyle(StylesCompanion style) async {
    final updatedStyle = style.copyWith(
      modifiedAt: (style.modifiedAt.present && style.modifiedAt.value > 0)
          ? style.modifiedAt
          : Value(DateTime.now().millisecondsSinceEpoch),
    );
    // `replace` writes the column default for every column the companion
    // omits, and StyleMapper.toCompanion never sets `isDeleted`. Re-saving a
    // style that a sync pull had already tombstoned therefore un-deleted it,
    // with a fresh `modifiedAt` that then won last-write-wins on every peer.
    // `write` touches only the fields the caller actually set.
    final count = await (update(
      styles,
    )..where((t) => t.id.equals(updatedStyle.id.value))).write(updatedStyle);
    // Only log what actually changed. No row matched means announcing that id
    // makes every peer ask for a style this device does not have - a wasted
    // round trip on the server engine, and an entry the file engine can never
    // resolve.
    if (count > 0) {
      await _logChange(style.id.value, 'upsert');
    }
    return count > 0;
  }

  Future<int> deleteStyle(StylesCompanion style) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final updatedStyle = StylesCompanion(
      isDeleted: const Value(true),
      modifiedAt: Value(now),
    );

    final count = await (update(
      styles,
    )..where((t) => t.id.equals(style.id.value))).write(updatedStyle);

    if (count > 0) {
      await _logChange(style.id.value, 'delete');
    }
    return count;
  }

  Future<void> _logChange(String recordId, String action) async {
    await into(syncLog).insert(
      SyncLogCompanion(
        changedTableName: const Value('styles'),
        recordId: Value(recordId),
        action: Value(action),
        timestamp: Value(DateTime.now().millisecondsSinceEpoch),
        exported: const Value(false),
      ),
    );
  }
}

@DriftAccessor(tables: [AccountTypes])
class AccountTypesDao extends DatabaseAccessor<AppDatabase>
    with _$AccountTypesDaoMixin {
  AccountTypesDao(super.db);

  Future<List<AccountType>> getAllAccountTypes() =>
      (select(accountTypes)..where((t) => t.isDeleted.equals(false))).get();
  Future<List<AccountType>> getAccountTypes({int limit = 10, int offset = 0}) =>
      (select(accountTypes)
            ..where((t) => t.isDeleted.equals(false))
            ..limit(limit, offset: offset))
          .get();
  Stream<List<AccountType>> watchAllAccountTypes() =>
      (select(accountTypes)..where((t) => t.isDeleted.equals(false))).watch();
  Future<AccountType?> getAccountTypeById(String id) =>
      (select(accountTypes)
            ..where((tbl) => tbl.id.equals(id) & tbl.isDeleted.equals(false)))
          .getSingleOrNull();

  Future<List<AccountType>> getAccountTypesByIds(List<String> ids) async {
    final results = <AccountType>[];
    for (final chunk in _sqlChunks(ids)) {
      results.addAll(
        await (select(
          accountTypes,
        )..where((t) => t.id.isIn(chunk) & t.isDeleted.equals(false))).get(),
      );
    }
    return results;
  }

  Future<void> insertAccountType(AccountTypesCompanion accountType) async {
    var toInsert = accountType.id.present
        ? accountType
        : accountType.copyWith(id: Value(_uuid.v4()));

    toInsert = toInsert.copyWith(
      modifiedAt: Value(DateTime.now().millisecondsSinceEpoch),
    );

    await into(accountTypes).insert(toInsert);
    await _logChange(toInsert.id.value, 'upsert');
  }

  Future<void> insertSyncedAccountType(AccountTypesCompanion accountType) =>
      into(accountTypes).insert(accountType, mode: InsertMode.insertOrReplace);

  Future<void> insertAllAccountTypes(
    List<AccountTypesCompanion> accountTypes,
  ) async {
    final List<AccountTypesCompanion> accountTypesWithIds = accountTypes.map((
      t,
    ) {
      final now = DateTime.now().millisecondsSinceEpoch;
      var companion = t;
      if (!companion.id.present) {
        companion = companion.copyWith(id: Value(_uuid.v4()));
      }
      return companion.copyWith(modifiedAt: Value(now));
    }).toList();

    await batch((batch) {
      batch.insertAll(
        this.accountTypes,
        accountTypesWithIds,
        mode: InsertMode.insertOrReplace,
      );
    });

    final ids = accountTypesWithIds.map((t) => t.id.value).toList();
    await _logChanges(ids, 'upsert');
  }

  Future<bool> updateAccountType(AccountTypesCompanion accountType) async {
    final updatedAccountType = accountType.copyWith(
      modifiedAt: Value(DateTime.now().millisecondsSinceEpoch),
    );
    // `replace` writes the column default for every column the companion
    // omits, and AccountTypeMapper.toCompanion never sets `isDeleted`, so
    // renaming an account type that had been deleted brought it back into every
    // picker - here and, via the fresh `modifiedAt`, on every peer.
    final count =
        await (update(accountTypes)
              ..where((t) => t.id.equals(updatedAccountType.id.value)))
            .write(updatedAccountType);
    if (count > 0) {
      await _logChange(accountType.id.value, 'upsert');
    }
    return count > 0;
  }

  Future<int> deleteAccountType(AccountTypesCompanion accountType) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final updatedAccountType = AccountTypesCompanion(
      isDeleted: const Value(true),
      modifiedAt: Value(now),
    );

    final count =
        await (update(accountTypes)
              ..where((t) => t.id.equals(accountType.id.value)))
            .write(updatedAccountType);

    if (count > 0) {
      await _logChange(accountType.id.value, 'delete');
    }
    return count;
  }

  Future<void> _logChange(String recordId, String action) async {
    await into(db.syncLog).insert(
      SyncLogCompanion(
        changedTableName: const Value('account_types'),
        recordId: Value(recordId),
        action: Value(action),
        timestamp: Value(DateTime.now().millisecondsSinceEpoch),
        exported: const Value(false),
      ),
    );
  }

  Future<void> _logChanges(List<String> recordIds, String action) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await batch((batch) {
      batch.insertAll(
        db.syncLog,
        recordIds
            .map(
              (id) => SyncLogCompanion(
                changedTableName: const Value('account_types'),
                recordId: Value(id),
                action: Value(action),
                timestamp: Value(timestamp),
                exported: const Value(false),
              ),
            )
            .toList(),
      );
    });
  }
}

/// SQL CASE yielding 10^decimals (the minor-unit scale) for the currency named
/// by [column], mirroring CurrencyPrecision: 0 for JPY/…, 3 for KWD/…, else 2.
/// Takes the column rather than assuming a bare `currency_code`, because a
/// statement that joins accounts to transactions has two of them and picking
/// the wrong one scales the money by a factor of ten or a hundred.
String minorScaleCaseFor(String column) =>
    '''
      CASE
        WHEN $column IN ('BIF','CLP','DJF','GNF','ISK','JPY','KMF','KRW','PYG','RWF','UGX','VND','VUV','XAF','XOF','XPF') THEN 1
        WHEN $column IN ('BHD','IQD','JOD','KWD','LYD','OMR','TND') THEN 1000
        ELSE 100
      END''';

/// The same CASE for a statement with only one `currency_code` in scope.
/// Shared by the v7->v8 backfill and the balance-adjust statements so exact
/// minor-unit balances are maintained without threading a delta through Dart.
final String kMinorScaleCase = minorScaleCaseFor('currency_code');

/// Correlated sum of the transactions that count toward an account's balance,
/// for use inside a statement whose target table is aliased `accounts`.
///
/// Only the account's own live rows in the account's own currency count. When
/// no exchange rate is on file the write paths deliberately keep a transaction
/// in the currency it was made in, and adding those digits to the balance as
/// if they were the account's own is wrong by the whole exchange rate — 100 USD
/// would move an RSD balance by 100 instead of about 11,700. Leaving such a row
/// out understates the balance by one transaction, which a rebuild puts right
/// the moment the rate arrives and the amount is restated in the account's
/// currency; a balance that has been scaled by a wrong factor is indistinguish-
/// able from money the user actually has, and nothing can put that right later.
String _ownTransactionsSum(String column) =>
    _ownTransactionsSumOf('COALESCE(t.$column, 0)');

/// The same sum in exact minor units, falling back to the double when a row
/// carries no integer amount.
///
/// A fiat row is supposed to arrive with its minor units filled in, but a peer
/// or an importer that predates them can send only the double, and dropping
/// such a row from the rebuild while [AccountsDao.adjustBalance] — which works
/// off the double — still counts it would leave the incremental and rebuilt
/// balances disagreeing by that transaction. The row is filtered to the
/// account's own currency, so scaling it by its own currency and by the
/// account's is the same thing.
String _ownTransactionsMinorSum(String minorColumn, String doubleColumn) =>
    _ownTransactionsSumOf(
      'COALESCE(t.$minorColumn, CAST(ROUND(COALESCE(t.$doubleColumn, 0) * '
      '(${minorScaleCaseFor('t.currency_code')})) AS INTEGER))',
    );

String _ownTransactionsSumOf(String valueExpression) =>
    '''COALESCE((SELECT SUM($valueExpression) FROM transactions t
          WHERE t.account_id = accounts.id
            AND t.is_deleted = 0
            AND t.currency_code = accounts.currency_code), 0)''';

/// Key of a batched balance delta. A delta is only ever applied to an account
/// whose currency matches the money it came from, so the currency travels with
/// the account id rather than being assumed.
typedef BalanceDeltaKey = ({String accountId, String currencyCode});

@DriftAccessor(tables: [Accounts, Transactions, SyncLog])
class AccountsDao extends DatabaseAccessor<AppDatabase>
    with _$AccountsDaoMixin {
  AccountsDao(super.db);

  Future<List<DbAccount>> getAllAccounts() =>
      (select(accounts)..where((t) => t.isDeleted.equals(false))).get();

  /// Ordered by id rather than left to the query plan: a paged read with no
  /// ORDER BY is free to return the pages in overlapping orders, so a row
  /// could arrive twice while another never arrives at all.
  Future<List<DbAccount>> getAccounts({int limit = 10, int offset = 0}) =>
      (select(accounts)
            ..where((t) => t.isDeleted.equals(false))
            ..orderBy([(t) => OrderingTerm.asc(t.id)])
            ..limit(limit, offset: offset))
          .get();
  Future<DbAccount?> getAccountById(String id) =>
      (select(accounts)
            ..where((tbl) => tbl.id.equals(id) & tbl.isDeleted.equals(false)))
          .getSingleOrNull();

  // OPTIMIZATION: Bulk fetch accounts by IDs (O(1) vs O(n) sequential calls)
  Future<List<DbAccount>> getAccountsByIds(List<String> ids) async {
    final results = <DbAccount>[];
    for (final chunk in _sqlChunks(ids)) {
      results.addAll(
        await (select(
          accounts,
        )..where((t) => t.id.isIn(chunk) & t.isDeleted.equals(false))).get(),
      );
    }
    return results;
  }

  Stream<List<DbAccount>> watchAllAccounts() =>
      (select(accounts)..where((t) => t.isDeleted.equals(false))).watch();

  Future<void> insertAccount(AccountsCompanion account) async {
    var toInsert = account.id.present
        ? account
        : account.copyWith(id: Value(_uuid.v4()));

    toInsert = toInsert.copyWith(
      modifiedAt: Value(DateTime.now().millisecondsSinceEpoch),
    );

    await into(accounts).insert(toInsert);
    // A new account's starting balance has no transaction behind it, so it is
    // the opening balance; anchoring here is what lets the balance be rebuilt
    // later instead of merely overwritten.
    await anchorOpeningBalances([toInsert.id.value]);
    // Log change for sync
    await _logChange(toInsert.id.value, 'upsert');
  }

  Future<void> insertSyncedAccount(AccountsCompanion account) async {
    await into(accounts).insert(account, mode: InsertMode.insertOrReplace);
    // The replace writes every column, so a sender that says nothing about the
    // anchor would leave a zero behind and the next rebuild would erase the
    // money the account opened with. Taking the balance the sender did compute
    // and working the anchor back out of it keeps that sender's arithmetic
    // intact while still leaving the row rebuildable.
    if (!account.openingBalance.present && account.id.present) {
      await anchorOpeningBalances([account.id.value]);
    }
  }

  Future<void> insertAllAccounts(List<AccountsCompanion> accounts) async {
    final List<AccountsCompanion> accountsWithIds = accounts.map((a) {
      final now = DateTime.now().millisecondsSinceEpoch;
      var companion = a;
      if (!companion.id.present) {
        companion = companion.copyWith(id: Value(_uuid.v4()));
      }
      return companion.copyWith(modifiedAt: Value(now));
    }).toList();

    await batch((batch) {
      batch.insertAll(
        this.accounts,
        accountsWithIds,
        mode: InsertMode.insertOrReplace,
      );
    });
    // Log changes for sync
    final ids = accountsWithIds.map((a) => a.id.value).toList();
    await anchorOpeningBalances(ids);
    await _logChanges(ids, 'upsert');
  }

  Future<void> _logChanges(List<String> recordIds, String action) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await batch((batch) {
      batch.insertAll(
        syncLog,
        recordIds
            .map(
              (id) => SyncLogCompanion(
                changedTableName: const Value('accounts'),
                recordId: Value(id),
                action: Value(action),
                timestamp: Value(timestamp),
                exported: const Value(false),
              ),
            )
            .toList(),
      );
    });
  }

  /// Puts a deleted account back together with the transactions the delete
  /// took with it.
  ///
  /// [tombstonedTransactionIds] are the rows
  /// [deleteAccountWithTransactions] soft deleted - the account's own and the
  /// transfer legs that sit on other accounts - and
  /// [movedTransactionIds] the rows
  /// [deleteAccountAndReassignTransactions] handed to another account. Undo
  /// used to restore the account row alone, so the user got the account back
  /// empty and the transactions stayed deleted or stayed on the account they
  /// had been moved to.
  Future<void> restoreAccount(
    AccountsCompanion account, {
    List<String> tombstonedTransactionIds = const [],
    List<String> movedTransactionIds = const [],
  }) {
    return db.transaction(() async {
      final accountId = account.id.value;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Accounts other than this one whose balance the restore changes: the
      // ones getting a transfer leg back, and the one that took the reassigned
      // rows. Read before anything moves, while the rows still name them.
      final touchedAccountIds = <String>{};

      if (tombstonedTransactionIds.isNotEmpty) {
        final rows = await (select(
          db.transactions,
        )..where((t) => t.id.isIn(tombstonedTransactionIds))).get();
        touchedAccountIds.addAll(rows.map((t) => t.accountId));
        await (update(
          db.transactions,
        )..where((t) => t.id.isIn(tombstonedTransactionIds))).write(
          TransactionsCompanion(
            isDeleted: const Value(false),
            modifiedAt: Value(now),
          ),
        );
      }

      if (movedTransactionIds.isNotEmpty) {
        final rows = await (select(
          db.transactions,
        )..where((t) => t.id.isIn(movedTransactionIds))).get();
        touchedAccountIds.addAll(rows.map((t) => t.accountId));
        await (update(
          db.transactions,
        )..where((t) => t.id.isIn(movedTransactionIds))).write(
          TransactionsCompanion(
            accountId: Value(accountId),
            modifiedAt: Value(now),
          ),
        );
      }

      final toInsert = account.copyWith(
        modifiedAt: Value(now),
        isDeleted: const Value(false),
      );
      await into(accounts).insert(toInsert, mode: InsertMode.insertOrReplace);
      // The replace writes every column from a companion built out of the
      // domain entity, which carries the balance but not the anchor, so the
      // anchor has to be re-derived from the balance being restored. The
      // transactions go back first for that reason: the anchor is the balance
      // minus the live transactions, and deriving it from an account that is
      // still empty would count every restored row twice.
      await anchorOpeningBalances([accountId]);

      // The accounts that gave a transfer leg back, or handed the reassigned
      // rows over, are still showing the balance they had without them.
      touchedAccountIds.remove(accountId);
      await recomputeBalances(touchedAccountIds);

      await _logChange(accountId, 'upsert');
      final restoredIds = [...tombstonedTransactionIds, ...movedTransactionIds];
      if (restoredIds.isNotEmpty) {
        await _logTransactionChanges(restoredIds, 'upsert');
      }
    });
  }

  Future<bool> updateAccount(AccountsCompanion account) async {
    final updatedAccount = account.copyWith(
      modifiedAt: Value(DateTime.now().millisecondsSinceEpoch),
    );
    // `replace` writes the column default for every column the companion
    // omits, and AccountMapper.toCompanion never sets `isDeleted`. Saving an
    // edit to an account a sync pull had already tombstoned therefore cleared
    // the tombstone, and the fresh `modifiedAt` made that resurrection win
    // last-write-wins on every peer - the deleted account, and every balance it
    // contributes to, came back. (`replace` also blanked `openingBalance` to
    // its 0.0 default, which only went unnoticed because
    // anchorOpeningBalances below re-derives it immediately.)
    final count =
        await (update(accounts)
              ..where((t) => t.id.equals(updatedAccount.id.value)))
            .write(updatedAccount);
    // The user edits the balance, but the balance is derived; folding the edit
    // into the anchor is what keeps the edit and the transactions behind it
    // consistent, and puts the change on the column that survives a merge.
    await anchorOpeningBalances([account.id.value]);
    // Log change for sync - but only when a row actually changed, or the peer
    // is told to fetch an account this device never wrote.
    if (count > 0) {
      await _logChange(account.id.value, 'upsert');
    }
    return count > 0;
  }

  Future<int> deleteAccount(AccountsCompanion account) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final updatedAccount = AccountsCompanion(
      isDeleted: const Value(true),
      modifiedAt: Value(now),
    );

    final count = await (update(
      accounts,
    )..where((t) => t.id.equals(account.id.value))).write(updatedAccount);

    if (count > 0) {
      await _logChange(account.id.value, 'delete');
    }
    return count;
  }

  /// Log a change for sync export
  Future<void> _logChange(String recordId, String action) async {
    await into(syncLog).insert(
      SyncLogCompanion(
        changedTableName: const Value('accounts'),
        recordId: Value(recordId),
        action: Value(action),
        timestamp: Value(DateTime.now().millisecondsSinceEpoch),
        exported: const Value(false),
      ),
    );
  }

  /// Moves [accountId]'s balance by [amount], which must be money denominated
  /// in [currencyCode].
  ///
  /// The currency is checked in SQL rather than trusted: a transaction the app
  /// could not convert for want of an exchange rate is stored in its own
  /// currency, and its raw digits added to an account in another currency are
  /// off by the exchange rate. A mismatch here matches no row and moves
  /// nothing, which leaves the balance one transaction short until a rebuild
  /// picks the row up in the account's currency. See [_ownTransactionsSum] for
  /// why understating is the recoverable failure.
  Future<void> adjustBalance(
    String accountId,
    double amount, {
    required String currencyCode,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    // Also maintain the exact integer balance_minor: scale the delta by the
    // account's own currency and round. Crypto rows have balance_minor NULL, so
    // NULL + x stays NULL and they remain on the double.
    await customUpdate(
      'UPDATE accounts SET balance = balance + ?, '
      'balance_minor = balance_minor + CAST(ROUND(? * ($kMinorScaleCase)) AS INTEGER), '
      'modified_at = ? WHERE id = ? AND currency_code = ?',
      variables: [
        Variable(amount),
        Variable(amount),
        Variable(now),
        Variable(accountId),
        Variable(currencyCode),
      ],
      updates: {accounts},
    );
    // The balance is a materialised value, not something a peer can recompute:
    // incoming transactions are applied with a bare insert that does NOT touch
    // balances. Without this log entry the peer got the transaction and never
    // got the new balance, so stored balances drifted apart permanently.
    await _logChange(accountId, 'upsert');
  }

  /// Applies many balance deltas at once. Each delta is keyed by the account it
  /// belongs to *and* the currency it is denominated in, and one statement is
  /// issued per currency so that the same guard [adjustBalance] applies can be
  /// expressed set-wise: a delta only lands on an account whose currency
  /// matches. A single account can appear under more than one currency when a
  /// batch mixes converted and unconverted transactions, which is why the map
  /// cannot be keyed on the account alone.
  Future<void> batchUpdateBalances(
    Map<BalanceDeltaKey, double> amountChanges,
  ) async {
    if (amountChanges.isEmpty) {
      return;
    }

    final byCurrency = <String, Map<String, double>>{};
    for (final entry in amountChanges.entries) {
      byCurrency.putIfAbsent(
        entry.key.currencyCode,
        () => <String, double>{},
      )[entry.key.accountId] = entry.value;
    }

    for (final group in byCurrency.entries) {
      final currencyCode = group.key;
      final accountIds = group.value.keys.toList();
      final caseClauses = <String>[];
      for (final _ in accountIds) {
        caseClauses.add('WHEN ? THEN ?');
      }
      final deltaCase = 'CASE id ${caseClauses.join(' ')} END';

      final variables = <Variable>[];
      // The delta CASE appears twice (balance + balance_minor), so its id/delta
      // variables are bound twice in the same order.
      for (var pass = 0; pass < 2; pass++) {
        for (final accountId in accountIds) {
          variables.add(Variable(accountId));
          variables.add(Variable(group.value[accountId]!));
        }
      }

      final idsInClause = List.filled(accountIds.length, '?').join(', ');
      final now = DateTime.now().millisecondsSinceEpoch;
      variables.add(Variable(now));

      for (final accountId in accountIds) {
        variables.add(Variable(accountId));
      }
      variables.add(Variable(currencyCode));

      // balance_minor scales the same delta by the account's currency and
      // rounds; crypto rows keep NULL (NULL + x == NULL) and stay on the double.
      final sql =
          '''
      UPDATE accounts
      SET balance = balance + ($deltaCase),
          balance_minor = balance_minor + CAST(ROUND(($deltaCase) * ($kMinorScaleCase)) AS INTEGER),
          modified_at = ?
      WHERE id IN ($idsInClause) AND currency_code = ?
    ''';

      await customUpdate(sql, variables: variables, updates: {accounts});
    }

    // Same reason as adjustBalance: peers cannot derive the new balance.
    for (final accountId
        in amountChanges.keys.map((k) => k.accountId).toSet()) {
      await _logChange(accountId, 'upsert');
    }
  }

  /// Rebuilds [accountIds]' balances from the opening-balance anchor plus the
  /// transactions that belong to them, discarding whatever the stored balance
  /// happened to be.
  ///
  /// This is what makes a balance survive two devices editing it at once.
  /// Transactions merge as a set, so once the balance is a function of the
  /// transactions plus an anchor that only the user moves, every device that
  /// has seen the same rows arrives at the same number instead of keeping
  /// whichever scalar was written last.
  ///
  /// Fiat is rebuilt in integer minor units and divided by the currency scale
  /// exactly once, so no floating-point error accumulates and the stored double
  /// stays a faithful rendering of the integer. Accounts with no minor units
  /// are crypto or commodity holdings whose double is the source of truth, and
  /// they are rebuilt on the double. An account carrying minor units but no
  /// integer anchor — one written by a peer that has never heard of the anchor —
  /// derives the anchor from its double so it still lands on the integer path.
  ///
  /// Neither `modified_at` nor the sync log is touched. Every peer can derive
  /// this number for itself from rows it already has, so stamping it would push
  /// a change nobody made and start the cycle again.
  Future<void> recomputeBalances(Iterable<String> accountIds) async {
    final ids = accountIds.toSet().toList();
    if (ids.isEmpty) {
      return;
    }

    final openingMinor =
        'COALESCE(opening_balance_minor, CAST(ROUND(opening_balance * ($kMinorScaleCase)) AS INTEGER))';
    final rebuiltMinor =
        '$openingMinor + ${_ownTransactionsMinorSum('amount_minor', 'amount')}';

    for (final chunk in _sqlChunks(ids)) {
      final idsInClause = List.filled(chunk.length, '?').join(', ');
      await customUpdate(
        '''
      UPDATE accounts
      SET balance_minor = CASE WHEN balance_minor IS NULL THEN NULL ELSE $rebuiltMinor END,
          balance = CASE
            WHEN balance_minor IS NULL THEN opening_balance + ${_ownTransactionsSum('amount')}
            ELSE CAST($rebuiltMinor AS REAL) / ($kMinorScaleCase)
          END
      WHERE id IN ($idsInClause)
    ''',
        variables: [for (final id in chunk) Variable(id)],
        updates: {accounts},
      );
    }
  }

  /// Re-derives the opening balance of [accountIds] from the balance they carry
  /// right now, so that a rebuild reproduces exactly that balance.
  ///
  /// The user only ever sees and edits the running balance; this turns such an
  /// edit into an edit of the anchor, which is the half of the pair that syncs
  /// safely. For a new account there are no transactions yet and it degenerates
  /// to "the opening balance is the balance", which is what the starting
  /// balance typed into the new-account form has always meant.
  ///
  /// It is also how a row from a peer that knows nothing about the anchor is
  /// taken in: whatever balance that peer computed is accepted as given, and
  /// the anchor is worked out from it, so a later rebuild returns that same
  /// balance rather than a number the peer never agreed to.
  Future<void> anchorOpeningBalances(Iterable<String> accountIds) async {
    final ids = accountIds.where((id) => id.isNotEmpty).toSet().toList();
    if (ids.isEmpty) {
      return;
    }

    final anchorMinor =
        'balance_minor - ${_ownTransactionsMinorSum('amount_minor', 'amount')}';
    for (final chunk in _sqlChunks(ids)) {
      final idsInClause = List.filled(chunk.length, '?').join(', ');
      await customUpdate(
        '''
      UPDATE accounts
      SET opening_balance_minor = CASE WHEN balance_minor IS NULL THEN NULL ELSE $anchorMinor END,
          opening_balance = CASE
            WHEN balance_minor IS NULL THEN balance - ${_ownTransactionsSum('amount')}
            ELSE CAST($anchorMinor AS REAL) / ($kMinorScaleCase)
          END
      WHERE id IN ($idsInClause)
    ''',
        variables: [for (final id in chunk) Variable(id)],
        updates: {accounts},
      );
    }
  }

  Future<Map<String, double>> getBalancesAtDate(DateTime date) async {
    final allAccounts = await getAllAccounts();
    final balances = <String, double>{};
    final startOfDate = DateTime(date.year, date.month, date.day);

    final futureSums = await attachedDatabase.transactionsDao
        .getFutureSumsGrouped(date);

    for (final account in allAccounts) {
      final startOfCreationDate = DateTime(
        account.creationDate.year,
        account.creationDate.month,
        account.creationDate.day,
      );
      if (startOfDate.isBefore(startOfCreationDate)) {
        balances[account.id] = 0.0;
      } else {
        final currentBalance = account.balance;
        final sumOfFutureTransactions = futureSums[account.id] ?? 0.0;
        balances[account.id] = currentBalance - sumOfFutureTransactions;
      }
    }
    return balances;
  }

  Future<List<DbAccount>> getAccountWithFilters({
    int limit = 10,
    int offset = 0,
    OrderingMode sort = OrderingMode.desc,
    String? description,
    String? name,
    double? amountFrom,
    double? amountTo,
    DateTime? date,
    List<String>? currenciesIds,
    List<String>? accountTypeIds,
  }) {
    final query = select(accounts)..where((t) => t.isDeleted.equals(false));

    if (name != null && name.isNotEmpty) {
      query.where((tbl) => tbl.name.like('%$name%'));
    }
    if (description != null && description.isNotEmpty) {
      query.where((tbl) => tbl.description.like('%$description%'));
    }
    if (amountFrom != null) {
      query.where((tbl) => tbl.balance.isBiggerOrEqualValue(amountFrom));
    }
    if (amountTo != null) {
      query.where((tbl) => tbl.balance.isSmallerOrEqualValue(amountTo));
    }
    if (date != null) {
      final startOfDay = DateTime(date.year, date.month, date.day);
      query.where((tbl) => tbl.creationDate.isBiggerOrEqualValue(startOfDay));
    }

    if (currenciesIds != null && currenciesIds.isNotEmpty) {
      query.where((tbl) => tbl.currencyCode.isIn(currenciesIds));
    }

    if (accountTypeIds != null && accountTypeIds.isNotEmpty) {
      query.where((tbl) => tbl.accountTypeId.isIn(accountTypeIds));
    }

    // The sort column is not unique, and `LIMIT`/`OFFSET` asks for the
    // pages in separate queries: rows that tie on it have no order to keep
    // between one page and the next, so a tie broken differently the second
    // time repeats a row the user already saw and drops one they never will.
    // The row's own key is the tiebreak that makes the order total.
    query.orderBy([
      (t) => OrderingTerm(expression: t.balance, mode: sort),
      (t) => OrderingTerm(expression: t.id, mode: sort),
    ]);
    query.limit(limit, offset: offset);

    return query.get();
  }

  Future<int> getCountWithFilters({List<String>? accountTypeIds}) async {
    final query = selectOnly(accounts)..where(accounts.isDeleted.equals(false));
    if (accountTypeIds != null && accountTypeIds.isNotEmpty) {
      query.where(accounts.accountTypeId.isIn(accountTypeIds));
    }
    final countExp = accounts.id.count();
    query.addColumns([countExp]);
    final count = await query
        .map((row) => row.read(countExp))
        .getSingleOrNull();
    return count ?? 0;
  }

  Future<void> deleteMultipleAccounts(List<String> ids) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (update(accounts)..where((tbl) => tbl.id.isIn(ids))).write(
      AccountsCompanion(isDeleted: const Value(true), modifiedAt: Value(now)),
    );
    await _logChanges(ids, 'delete');
  }

  Future<void> updateAccountTypeForMultipleAccounts(
    List<String> ids,
    String accountTypeId,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (update(accounts)..where((tbl) => tbl.id.isIn(ids))).write(
      AccountsCompanion(
        accountTypeId: Value(accountTypeId),
        modifiedAt: Value(now),
      ),
    );
    await _logChanges(ids, 'upsert');
  }

  /// Soft deletes [accountId] and everything booked on it, and returns the ids
  /// of the transactions it took with it so [restoreAccount] can put them back.
  Future<List<String>> deleteAccountWithTransactions(String accountId) {
    debugPrint(
      '[AccountsDao] Deleting account $accountId with transactions...',
    ); // LOG
    return db.transaction(() async {
      final now = DateTime.now().millisecondsSinceEpoch;

      // 1. Find all transactions for this account to get their IDs and linked
      // IDs. Rows the user had already deleted are skipped: this delete does
      // not touch them, so Undo must not resurrect them either.
      final accountTxs =
          await (select(db.transactions)..where(
                (t) =>
                    t.accountId.equals(accountId) & t.isDeleted.equals(false),
              ))
              .get();

      final txIds = accountTxs.map((t) => t.id).toList();
      final linkedTxIds = accountTxs
          .map((t) => t.linkedTransactionId)
          .whereType<String>()
          .toList();

      // The other half of a transfer sits on a DIFFERENT account, and that
      // account survives this delete. Its balance still counts the leg that is
      // about to disappear, so the accounts holding those legs are collected
      // here and rebuilt at the end - otherwise the user deletes one account
      // and another one is left showing money that no transaction backs.
      final linkedAccountIds = <String>{};
      if (linkedTxIds.isNotEmpty) {
        final linkedTxs =
            await (select(db.transactions)..where(
                  (t) => t.id.isIn(linkedTxIds) & t.isDeleted.equals(false),
                ))
                .get();
        linkedAccountIds.addAll(linkedTxs.map((t) => t.accountId));
        // Same reason as above: a leg already deleted stays deleted, and is
        // dropped here so it is neither re-stamped nor handed to Undo.
        final liveLinkedIds = linkedTxs.map((t) => t.id).toSet();
        linkedTxIds.retainWhere(liveLinkedIds.contains);
      }

      // 2. Mark account transactions as deleted
      final txUpdate =
          await (update(db.transactions)..where((t) => t.id.isIn(txIds))).write(
            TransactionsCompanion(
              isDeleted: const Value(true),
              modifiedAt: Value(now),
            ),
          );
      debugPrint('[AccountsDao] Marked $txUpdate transactions as deleted.');

      // 3. Mark linked transactions as deleted (Recursive Deletion of Transfers)
      if (linkedTxIds.isNotEmpty) {
        final linkedUpdate =
            await (update(
              db.transactions,
            )..where((t) => t.id.isIn(linkedTxIds))).write(
              TransactionsCompanion(
                isDeleted: const Value(true),
                modifiedAt: Value(now),
              ),
            );
        debugPrint(
          '[AccountsDao] Marked $linkedUpdate linked transactions as deleted.',
        );
      }

      // 4. Mark account as deleted
      final accUpdate =
          await (update(accounts)..where((a) => a.id.equals(accountId))).write(
            AccountsCompanion(
              isDeleted: const Value(true),
              modifiedAt: Value(now),
            ),
          );
      debugPrint(
        '[AccountsDao] Marked account as deleted (count: $accUpdate).',
      );

      // 5. Rebuild the accounts that kept a transfer leg (see above). The
      // deleted account itself is gone, so it is not worth rebuilding.
      linkedAccountIds.remove(accountId);
      await recomputeBalances(linkedAccountIds);

      await _logChange(accountId, 'delete');
      // Transaction ids have to be logged against the transactions table.
      // Logged as 'accounts' they named rows that do not exist in that table,
      // so every peer discarded them: the deleted transactions never reached
      // another device and came straight back on the next sync.
      if (txIds.isNotEmpty) await _logTransactionChanges(txIds, 'delete');
      if (linkedTxIds.isNotEmpty) {
        await _logTransactionChanges(linkedTxIds, 'delete');
      }
      return [...txIds, ...linkedTxIds];
    });
  }

  /// Soft deletes [accountId] after handing its transactions to
  /// [newAccountId], and returns the ids of the rows that moved so
  /// [restoreAccount] can bring them home.
  Future<List<String>> deleteAccountAndReassignTransactions(
    String accountId,
    String newAccountId,
  ) {
    return db.transaction(() async {
      final now = DateTime.now().millisecondsSinceEpoch;
      // Rows the user had already deleted stay where they are: moving them
      // would make Undo hand a tombstone back to an account it never sat on.
      final movedTxIds =
          (await (select(db.transactions)..where(
                    (t) =>
                        t.accountId.equals(accountId) &
                        t.isDeleted.equals(false),
                  ))
                  .get())
              .map((t) => t.id)
              .toList();
      await (update(
        db.transactions,
      )..where((t) => t.id.isIn(movedTxIds))).write(
        TransactionsCompanion(
          accountId: Value(newAccountId),
          modifiedAt: Value(now),
        ),
      );
      await (update(accounts)..where((a) => a.id.equals(accountId))).write(
        AccountsCompanion(isDeleted: const Value(true), modifiedAt: Value(now)),
      );
      // Moving transactions between accounts moves money between them, and
      // neither balance was touched: the account taking the transactions kept
      // showing its old total, so the transfers the user could now see on it
      // did not add up to it.
      await recomputeBalances([accountId, newAccountId]);
      await _logChange(accountId, 'delete');
      // The rows survive, they only moved account: 'upsert', not 'delete', and
      // against the table they actually live in.
      if (movedTxIds.isNotEmpty) {
        await _logTransactionChanges(movedTxIds, 'upsert');
      }
      return movedTxIds;
    });
  }

  /// Log transaction-table changes made as a side effect of an account
  /// mutation ([_logChanges] is hard-coded to the `accounts` table).
  Future<void> _logTransactionChanges(
    List<String> recordIds,
    String action,
  ) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await batch((batch) {
      batch.insertAll(
        syncLog,
        recordIds
            .map(
              (id) => SyncLogCompanion(
                changedTableName: const Value('transactions'),
                recordId: Value(id),
                action: Value(action),
                timestamp: Value(timestamp),
                exported: const Value(false),
              ),
            )
            .toList(),
      );
    });
  }
}

@DriftAccessor(tables: [Transactions, SyncLog])
class TransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionsDaoMixin {
  TransactionsDao(super.db);

  Future<List<Transaction>> getAllTransactions() =>
      (select(transactions)..where((t) => t.isDeleted.equals(false))).get();

  /// See [AccountsDao.getAccounts]: the order has to be given, not inherited
  /// from whatever plan the query happens to take.
  Future<List<Transaction>> getTransactions({int limit = 10, int offset = 0}) =>
      (select(transactions)
            ..where((t) => t.isDeleted.equals(false))
            ..orderBy([(t) => OrderingTerm.asc(t.id)])
            ..limit(limit, offset: offset))
          .get();
  Future<Transaction?> getTransactionById(String id) =>
      (select(transactions)
            ..where((tbl) => tbl.id.equals(id) & tbl.isDeleted.equals(false)))
          .getSingleOrNull();

  /// Rows on [accountId] stamped exactly [date], excluding any the SMS import
  /// wrote under its own derived id.
  ///
  /// The SMS import recognises its own work by that id, which only covers
  /// messages imported since the id became derived from the message. Rows
  /// written before that - and rows written by the file import from a bank
  /// statement covering the same payments - carry a random uuid, so the id
  /// check cannot see them and re-running an "All time" import writes a second
  /// copy of every one of them. The caller compares amounts itself; the
  /// timestamp is what makes the pair the same payment and it is exact,
  /// because both copies were derived from the same message.
  Future<List<Transaction>> getForeignTransactionsAt({
    required String accountId,
    required DateTime date,
  }) =>
      (select(transactions)..where(
            (t) =>
                t.accountId.equals(accountId) &
                t.date.equals(date) &
                t.isDeleted.equals(false) &
                t.id.like('sms%').not(),
          ))
          .get();
  Future<List<Transaction>> getTransactionsByCategoryId(String categoryId) =>
      (select(transactions)..where(
            (tbl) =>
                tbl.categoryId.equals(categoryId) & tbl.isDeleted.equals(false),
          ))
          .get();
  Stream<List<Transaction>> watchAllTransactions() =>
      (select(transactions)..where((t) => t.isDeleted.equals(false))).watch();

  /// Watch transactions on or after [from]. Used by the dashboard to avoid
  /// loading the entire transaction history on every stream update.
  Stream<List<Transaction>> watchTransactionsFrom(DateTime from) =>
      (select(transactions)..where(
            (t) =>
                t.isDeleted.equals(false) & t.date.isBiggerOrEqualValue(from),
          ))
          .watch();

  /// Lightweight change signal for the transactions table. Fires on every
  /// insert/update/delete WITHOUT materializing any rows. Use this to trigger
  /// a reload when only the fact-of-change matters (not the data itself) —
  /// avoids reading + mapping the entire history on each transaction create.
  Stream<void> watchTransactionChanges() =>
      tableUpdates(TableUpdateQuery.onTable(transactions));

  Future<void> insertTransaction(TransactionsCompanion transaction) async {
    var toInsert = transaction.id.present
        ? transaction
        : transaction.copyWith(id: Value(_uuid.v4()));

    toInsert = toInsert.copyWith(
      modifiedAt: Value(DateTime.now().millisecondsSinceEpoch),
    );

    await into(transactions).insert(toInsert);
    await _logChange(toInsert.id.value, 'upsert');
  }

  Future<void> insertSyncedTransaction(TransactionsCompanion transaction) =>
      into(transactions).insert(transaction, mode: InsertMode.insertOrReplace);

  Future<void> insertAllTransactions(
    List<TransactionsCompanion> transactions,
  ) async {
    final List<TransactionsCompanion> transactionsWithIds = transactions.map((
      t,
    ) {
      final now = DateTime.now().millisecondsSinceEpoch;
      var companion = t;
      if (!companion.id.present) {
        companion = companion.copyWith(id: Value(_uuid.v4()));
      }
      return companion.copyWith(modifiedAt: Value(now));
    }).toList();

    await batch((batch) {
      batch.insertAll(
        this.transactions,
        transactionsWithIds,
        mode: InsertMode.insertOrReplace,
      );
    });
    // Log changes for sync
    final ids = transactionsWithIds.map((t) => t.id.value).toList();
    await _logChanges(ids, 'upsert');
  }

  /// Log multiple changes for sync export
  Future<void> _logChanges(List<String> recordIds, String action) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await batch((batch) {
      batch.insertAll(
        db.syncLog,
        recordIds
            .map(
              (id) => SyncLogCompanion(
                changedTableName: const Value('transactions'),
                recordId: Value(id),
                action: Value(action),
                timestamp: Value(timestamp),
                exported: const Value(false),
              ),
            )
            .toList(),
      );
    });
  }

  Future<bool> updateTransaction(TransactionsCompanion transaction) async {
    final updatedTransaction = transaction.copyWith(
      modifiedAt: Value(DateTime.now().millisecondsSinceEpoch),
    );
    // `replace` writes the column default for every column the companion
    // omits, and TransactionMapper.toCompanion never sets `isDeleted`, so an
    // edit aimed at a tombstoned transaction un-deleted it and - via the fresh
    // `modifiedAt` - pushed it back onto every peer. LocalTransactionRepository
    // happens to guard this with a filtered read first, but the DAO is called
    // directly too and must not depend on that.
    final count =
        await (update(transactions)
              ..where((t) => t.id.equals(updatedTransaction.id.value)))
            .write(updatedTransaction);
    if (count > 0) {
      await _logChange(transaction.id.value, 'upsert');
    }
    return count > 0;
  }

  Future<int> deleteTransaction(TransactionsCompanion transaction) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final updatedTransaction = TransactionsCompanion(
      isDeleted: const Value(true),
      modifiedAt: Value(now),
    );

    final result =
        await (update(transactions)
              ..where((t) => t.id.equals(transaction.id.value)))
            .write(updatedTransaction);
    await _logChange(transaction.id.value, 'delete');
    return result;
  }

  Future<void> _logChange(String recordId, String action) async {
    await into(syncLog).insert(
      SyncLogCompanion(
        changedTableName: const Value('transactions'),
        recordId: Value(recordId),
        action: Value(action),
        timestamp: Value(DateTime.now().millisecondsSinceEpoch),
        exported: const Value(false),
      ),
    );
  }

  Future<List<Transaction>> getTransactionsWithFilters({
    int limit = 10,
    int offset = 0,
    OrderingMode sort = OrderingMode.desc,
    String? description,
    double? amountFrom,
    double? amountTo,
    DateTime? dateFrom,
    DateTime? dateTo,
    List<String>? accountId,
    List<String>? categoryId,
    List<String>? currencyCode,

    /// Rows on these accounts are left out of the result.
    ///
    /// The positive [accountId] filter cannot express this: a caller that
    /// wants everything except a handful of accounts would have to name every
    /// other account, and the list it would have to name grows as the person
    /// adds accounts.
    List<String>? excludeAccountId,

    /// Rows in these categories are left out of the result.
    List<String>? excludeCategoryId,
    TransactionTypeFilter? transactionType,
    bool? needsReview,
  }) {
    final query = select(transactions)..where((t) => t.isDeleted.equals(false));

    if (description != null) {
      query.where((tbl) => tbl.description.like('%$description%'));
    }
    if (amountFrom != null) {
      query.where((tbl) => tbl.amount.isBiggerOrEqualValue(amountFrom));
    }
    if (amountTo != null) {
      query.where((tbl) => tbl.amount.isSmallerOrEqualValue(amountTo));
    }
    if (dateFrom != null) {
      query.where((tbl) => tbl.date.isBiggerOrEqualValue(dateFrom));
    }
    if (dateTo != null) {
      query.where((tbl) => tbl.date.isSmallerOrEqualValue(dateTo));
    }
    if (accountId != null && accountId.isNotEmpty) {
      query.where((tbl) => tbl.accountId.isIn(accountId));
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      query.where((tbl) => tbl.categoryId.isIn(categoryId));
    }
    if (excludeAccountId != null && excludeAccountId.isNotEmpty) {
      query.where((tbl) => tbl.accountId.isNotIn(excludeAccountId));
    }
    if (excludeCategoryId != null && excludeCategoryId.isNotEmpty) {
      query.where((tbl) => tbl.categoryId.isNotIn(excludeCategoryId));
    }
    if (currencyCode != null && currencyCode.isNotEmpty) {
      query.where((tbl) => tbl.currencyCode.isIn(currencyCode));
    }
    if (transactionType != null) {
      if (transactionType == TransactionTypeFilter.income) {
        query.where((tbl) => tbl.amount.isBiggerThanValue(0));
      } else if (transactionType == TransactionTypeFilter.expense) {
        query.where((tbl) => tbl.amount.isSmallerThanValue(0));
      }
    }
    if (needsReview != null) {
      query.where((tbl) => tbl.needsReview.equals(needsReview));
    }

    // The sort column is not unique, and `LIMIT`/`OFFSET` asks for the
    // pages in separate queries: rows that tie on it have no order to keep
    // between one page and the next, so a tie broken differently the second
    // time repeats a row the user already saw and drops one they never will.
    // The row's own key is the tiebreak that makes the order total.
    query.orderBy([
      (t) => OrderingTerm(expression: t.date, mode: sort),
      (t) => OrderingTerm(expression: t.amount, mode: sort),
      (t) => OrderingTerm(expression: t.id, mode: sort),
    ]);
    query.limit(limit, offset: offset);

    return query.get();
  }

  /// The account [categoryId] was most often written against since [since].
  ///
  /// Null when the category has nothing in that window - the signal to leave
  /// whatever account the form already holds rather than guess.
  Future<String?> getMostUsedAccountForCategory(
    String categoryId, {
    required DateTime since,
  }) async {
    final uses = transactions.id.count();
    final query = selectOnly(transactions)
      ..addColumns([transactions.accountId, uses])
      ..where(
        transactions.isDeleted.equals(false) &
            transactions.categoryId.equals(categoryId) &
            transactions.date.isBiggerOrEqualValue(since),
      )
      ..groupBy([transactions.accountId])
      // The account id breaks a tie. Two accounts used the same number of
      // times have no order of their own, and a form that suggests a
      // different one every time it is opened is worse than one that never
      // suggests anything.
      ..orderBy([
        OrderingTerm(expression: uses, mode: OrderingMode.desc),
        OrderingTerm(expression: transactions.accountId),
      ])
      ..limit(1);

    final row = await query.getSingleOrNull();
    return row?.read(transactions.accountId);
  }

  /// The account the most recent transaction was written against.
  ///
  /// What a blank form should open on. The fallback it replaces was
  /// `accounts.first` - the first row SQLite happened to hand back, which is
  /// neither the account the person last used nor the one they use most, and
  /// which is why the account had to be corrected on almost every entry.
  ///
  /// [getMostUsedAccountForCategory] still wins once a category is picked:
  /// this only answers "which account, knowing nothing else".
  Future<String?> getLastUsedAccountId() async {
    final query = selectOnly(transactions)
      ..addColumns([transactions.accountId])
      ..where(transactions.isDeleted.equals(false))
      ..orderBy([
        OrderingTerm(expression: transactions.date, mode: OrderingMode.desc),
        // Same day, same person, two rows: the later write is the later
        // intent. Without this the pick flips between them at random.
        OrderingTerm(
          expression: transactions.modifiedAt,
          mode: OrderingMode.desc,
        ),
      ])
      ..limit(1);

    final row = await query.getSingleOrNull();
    return row?.read(transactions.accountId);
  }

  Future<int> getCountWithFilters({
    String? description,
    double? amountFrom,
    double? amountTo,
    DateTime? dateFrom,
    DateTime? dateTo,
    List<String>? accountId,
    List<String>? categoryId,
    List<String>? currencyCode,
    TransactionTypeFilter? transactionType,
    bool? needsReview,
  }) async {
    final query = selectOnly(transactions)
      ..where(transactions.isDeleted.equals(false));

    if (description != null) {
      query.where(transactions.description.like('%$description%'));
    }
    if (amountFrom != null) {
      query.where(transactions.amount.isBiggerOrEqualValue(amountFrom));
    }
    if (amountTo != null) {
      query.where(transactions.amount.isSmallerOrEqualValue(amountTo));
    }
    if (dateFrom != null) {
      query.where(transactions.date.isBiggerOrEqualValue(dateFrom));
    }
    if (dateTo != null) {
      query.where(transactions.date.isSmallerOrEqualValue(dateTo));
    }
    if (accountId != null && accountId.isNotEmpty) {
      query.where(transactions.accountId.isIn(accountId));
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      query.where(transactions.categoryId.isIn(categoryId));
    }
    if (currencyCode != null && currencyCode.isNotEmpty) {
      query.where(transactions.currencyCode.isIn(currencyCode));
    }
    if (transactionType != null) {
      if (transactionType == TransactionTypeFilter.income) {
        query.where(transactions.amount.isBiggerThanValue(0));
      } else if (transactionType == TransactionTypeFilter.expense) {
        query.where(transactions.amount.isSmallerThanValue(0));
      }
    }
    if (needsReview != null) {
      query.where(transactions.needsReview.equals(needsReview));
    }

    final countExp = transactions.id.count();
    query.addColumns([countExp]);
    final count = await query
        .map((row) => row.read(countExp))
        .getSingleOrNull();
    return count ?? 0;
  }

  Future<List<Transaction>> getTransactionsByIds(List<String> ids) async {
    final results = <Transaction>[];
    for (final chunk in _sqlChunks(ids)) {
      results.addAll(
        await (select(
          transactions,
        )..where((t) => t.id.isIn(chunk) & t.isDeleted.equals(false))).get(),
      );
    }
    return results;
  }

  Future<void> deleteMultipleTransactions(List<String> ids) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (update(transactions)..where((tbl) => tbl.id.isIn(ids))).write(
      TransactionsCompanion(
        isDeleted: const Value(true),
        modifiedAt: Value(now),
      ),
    );
    await _logChanges(ids, 'delete');
  }

  Future<void> restoreTransactions(List<String> ids) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (update(transactions)..where((tbl) => tbl.id.isIn(ids))).write(
      TransactionsCompanion(
        isDeleted: const Value(false),
        modifiedAt: Value(now),
      ),
    );
    await _logChanges(ids, 'upsert');
  }

  Future<void> updateDateForMultipleTransactions(
    List<String> ids,
    DateTime newDate,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (update(transactions)..where((tbl) => tbl.id.isIn(ids))).write(
      TransactionsCompanion(date: Value(newDate), modifiedAt: Value(now)),
    );
    await _logChanges(ids, 'upsert');
  }

  Future<void> updateCategoryForMultipleTransactions(
    List<String> ids,
    String newCategoryId,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (update(transactions)..where((tbl) => tbl.id.isIn(ids))).write(
      TransactionsCompanion(
        categoryId: Value(newCategoryId),
        modifiedAt: Value(now),
      ),
    );
    await _logChanges(ids, 'upsert');
  }

  Future<int> getAllCount() async {
    // 1. Pick any column to count (e.g., 'id').
    final expression = transactions.id.count();
    // 2. Create a query that only gets the count.
    final query = selectOnly(transactions)
      ..addColumns([expression])
      ..where(transactions.isDeleted.equals(false));
    // 3. Run the query and read the single integer value it returns.
    final count = await query
        .map((row) => row.read(expression))
        .getSingleOrNull();
    return count ?? 0;
  }

  Future<double> getSumOfTransactionsAfterDate(
    String accountId,
    DateTime date,
  ) async {
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    final amountExp = transactions.amount.total();
    final query = selectOnly(transactions)
      ..where(
        transactions.accountId.equals(accountId) &
            transactions.date.isBiggerThanValue(endOfDay) &
            transactions.isDeleted.equals(false),
      )
      ..addColumns([amountExp]);

    final result = await query
        .map((row) => row.read(amountExp))
        .getSingleOrNull();
    return result ?? 0.0;
  }

  Future<Map<String, double>> getFutureSumsGrouped(DateTime date) async {
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    final amountExp = transactions.amount.sum();
    final query = selectOnly(transactions)
      ..addColumns([transactions.accountId, amountExp])
      ..where(
        transactions.date.isBiggerThanValue(endOfDay) &
            transactions.isDeleted.equals(false),
      )
      ..groupBy([transactions.accountId]);

    final rows = await query.get();
    return {
      for (var row in rows)
        row.read(transactions.accountId)!: row.read(amountExp) ?? 0.0,
    };
  }

  /// Sum of transaction amounts strictly AFTER [cutoff], grouped by account.
  ///
  /// Unlike [getFutureSumsGrouped], this uses the exact [cutoff] instant rather
  /// than snapping to end-of-day, so it exactly mirrors the reverse-balance
  /// rule in FinanceCalculator (`tx.date.isAfter(date)`): for a standard
  /// account, balanceAt(cutoff) == storedBalance - result[accountId].
  Future<Map<String, double>> getFutureSumsExact(DateTime cutoff) async {
    final amountExp = transactions.amount.sum();
    final query = selectOnly(transactions)
      ..addColumns([transactions.accountId, amountExp])
      ..where(
        transactions.date.isBiggerThanValue(cutoff) &
            transactions.isDeleted.equals(false),
      )
      ..groupBy([transactions.accountId]);

    final rows = await query.get();
    return {
      for (var row in rows)
        row.read(transactions.accountId)!: row.read(amountExp) ?? 0.0,
    };
  }

  /// Exact integer minor-unit counterpart of [getFutureSumsExact] for fiat
  /// accounts: sums the amountMinor column (NULL for crypto rows, so they are
  /// simply excluded here and handled via the double [getFutureSumsExact]).
  /// balanceAt(cutoff)_minor == balanceMinor - result[accountId].
  Future<Map<String, int>> getFutureSumsExactMinor(DateTime cutoff) async {
    final amountExp = transactions.amountMinor.sum();
    final query = selectOnly(transactions)
      ..addColumns([transactions.accountId, amountExp])
      ..where(
        transactions.date.isBiggerThanValue(cutoff) &
            transactions.isDeleted.equals(false) &
            transactions.amountMinor.isNotNull(),
      )
      ..groupBy([transactions.accountId]);

    final rows = await query.get();
    return {
      for (var row in rows)
        row.read(transactions.accountId)!: row.read(amountExp) ?? 0,
    };
  }

  Future<List<GroupedTransactionTotal>> getTransactionTotalsGrouped({
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final amountExp = transactions.amount.sum();
    final amountMinorExp = transactions.amountMinor.sum();
    final query = selectOnly(transactions)
      ..addColumns([
        transactions.categoryId,
        transactions.currencyCode,
        transactions.date,
        amountExp,
        amountMinorExp,
      ])
      ..where(transactions.isDeleted.equals(false));

    if (dateFrom != null) {
      query.where(transactions.date.isBiggerOrEqualValue(dateFrom));
    }
    if (dateTo != null) {
      query.where(transactions.date.isSmallerOrEqualValue(dateTo));
    }

    query.groupBy([
      transactions.categoryId,
      transactions.currencyCode,
      transactions.date,
    ]);

    final rows = await query.get();
    return rows.map((row) {
      final code = row.read(transactions.currencyCode)!;
      // Each group is a single currency, so prefer the exact integer sum for
      // fiat (drift-free), dividing by the currency scale once. Crypto groups
      // have a NULL minor sum and fall back to the double.
      final minorSum = row.read(amountMinorExp);
      final total = minorSum != null && CurrencyPrecision.isMinorUnitCode(code)
          ? minorSum /
                CurrencyPrecision.scaleFor(CurrencyPrecision.decimalsFor(code))
          : (row.read(amountExp) ?? 0.0);
      return GroupedTransactionTotal(
        categoryId: row.read(transactions.categoryId)!,
        currencyCode: code,
        date: row.read(transactions.date)!,
        total: total,
      );
    }).toList();
  }

  /// OPTIMIZATION: Get category totals in main currency via SQL aggregation
  /// Uses SQL to convert currencies via exchange rates instead of Dart compute
  Future<Map<String, double>> getCategoryTotalsInMainCurrency({
    DateTime? dateFrom,
    DateTime? dateTo,
    required String mainCurrencyCode,
  }) async {
    // OPTIMIZATION: Pure SQL execution.
    // 0ms overhead for data transfer, exact usage of daily rates.
    final sw = Stopwatch()..start();

    final variables = <Variable>[];
    final whereConditions = <String>[];

    if (dateFrom != null) {
      whereConditions.add('t.date >= ?');
      variables.add(Variable(dateFrom));
    }
    if (dateTo != null) {
      whereConditions.add('t.date <= ?');
      variables.add(Variable(dateTo));
    }

    // EXCLUDE SOFT DELETED TRANSACTIONS
    whereConditions.add('t.is_deleted = 0');

    final whereClause = whereConditions.isNotEmpty
        ? 'WHERE ${whereConditions.join(' AND ')}'
        : '';

    // Every DateTime in this schema is stored the way drift stores one by
    // default: unix SECONDS. This block used to write `date(date/1000,
    // 'unixepoch')` on both sides, dividing an already-divided value: 2024-01-15
    // came out as 1970-01-20, and roughly every date inside a 2.7-year span
    // collapsed onto the same bucket. The equality then matched a rate from an
    // arbitrary point in that span, and the totals moved whenever a bucket
    // boundary was crossed.
    //
    // Matching the exact day is not the repair on its own: rates exist for the
    // days a provider was asked, and a transaction on any other day would find
    // nothing and fall through to the 1.0 below - reading a foreign amount as
    // if it were already in the main currency. So the lookup takes the latest
    // rate quoted on or before the transaction, which is the rate that was in
    // effect, and only reaches forward for a transaction older than any rate
    // this database holds. That is also what
    // [CurrencyConverter.resolveRate] does, so the two screens stop
    // disagreeing about the same category.
    //
    // Both subqueries seek on idx_exchange_rates_composite
    // (from_currency_code, to_currency_code, date) and stop at the first row.
    String rateFactor(String fromExpr, String toExpr) =>
        '''
            COALESCE(
              (SELECT r.rate FROM exchange_rates r
                WHERE r.from_currency_code = $fromExpr
                  AND r.to_currency_code = $toExpr
                  AND r.date <= t.date
                ORDER BY r.date DESC LIMIT 1),
              (SELECT r.rate FROM exchange_rates r
                WHERE r.from_currency_code = $fromExpr
                  AND r.to_currency_code = $toExpr
                ORDER BY r.date ASC LIMIT 1),
              (SELECT 1.0 / r.rate FROM exchange_rates r
                WHERE r.from_currency_code = $toExpr
                  AND r.to_currency_code = $fromExpr
                  AND r.rate > 0
                  AND r.date <= t.date
                ORDER BY r.date DESC LIMIT 1),
              (SELECT 1.0 / r.rate FROM exchange_rates r
                WHERE r.from_currency_code = $toExpr
                  AND r.to_currency_code = $fromExpr
                  AND r.rate > 0
                ORDER BY r.date ASC LIMIT 1),
              1.0
            )''';

    // A parent category answers for what was spent inside it, so a transaction
    // filed under a child counts towards the child and every category above
    // it. `GROUP BY t.category_id` rolled nothing up: a parent used to show
    // only the transactions pinned directly to it, which for a parent that
    // exists purely to group its children was 0.00 next to children holding
    // real money.
    //
    // The base row is the category paired with itself, so a category with no
    // parent still reports its own total and the query stays a superset of
    // what it returned before.
    //
    // Ancestors are walked without checking `is_deleted`: a soft-deleted
    // category in the middle of a chain would otherwise cut the branch off
    // from a live grandparent, and the money would vanish from the screen
    // rather than move up. The screen only draws live categories, so a
    // deleted ancestor's row is simply never looked up.
    //
    // `depth < 16` is a cycle guard. A parent chain that loops - which nothing
    // here writes, but nothing here forbids either, since `parent_id` is a
    // plain self-reference - would otherwise recurse until the query is killed.
    //
    // Interpolated, like the rest of this statement, so the bound variables
    // stay in the order the WHERE clause added them. A code carrying a quote
    // is not a currency, but escaping costs nothing and the value comes out of
    // a settings row rather than a fixed list.
    final mainLiteral = "'${mainCurrencyCode.replaceAll("'", "''")}'";

    // The fee is money that left with the transaction, in the transaction's own
    // currency, and it was never counted here - a category's total disagreed
    // with what the account actually moved by the sum of its commissions.
    //
    // Subtracted as a magnitude rather than added with its own sign: a fee is
    // an outflow whichever way the amount points. On an expense (negative) it
    // deepens the total, on an income (positive) it shaves it, and both are
    // what the bank did.
    const netAmount = 't.amount - ABS(t.fee)';

    // The same net amount in the currency's own minor units, where the row
    // carries them. `amount_minor` is NULL for crypto and commodities, and
    // `fee_minor` is NULL both there and on rows written before the column
    // existed, so this expression is only ever read under [exactBranch].
    const netAmountMinor = 't.amount_minor - ABS(COALESCE(t.fee_minor, 0))';

    // When a row can be added up exactly, in integers, with no conversion.
    //
    // Three conditions, all of them necessary: the row is already in the main
    // currency (so no rate multiplies it back into floating point), it has
    // minor units at all, and its fee either is zero or has minor units too -
    // a row with a fee of 0.07 and no `fee_minor` would otherwise silently
    // drop the commission the double branch does subtract.
    final exactBranch =
        't.currency_code = $mainLiteral '
        'AND t.amount_minor IS NOT NULL '
        'AND (t.fee = 0 OR t.fee_minor IS NOT NULL)';

    final sql =
        '''
      WITH RECURSIVE category_ancestry(category_id, ancestor_id, depth) AS (
        SELECT c.id, c.id, 0 FROM categories c
        UNION ALL
        SELECT a.category_id, p.parent_id, a.depth + 1
          FROM category_ancestry a
          JOIN categories p ON p.id = a.ancestor_id
         WHERE p.parent_id IS NOT NULL
           AND a.depth < 16
      )
      SELECT 
        a.ancestor_id as categoryId,
        -- The exact half: whole cents, summed as integers. This is the
        -- single-currency case, which is most rows on most screens, and it
        -- used to run through the same REAL accumulator as everything else -
        -- so a category holding a few thousand ordinary purchases drifted off
        -- the sum of its own transactions by the accumulated slack of binary rounding, and the
        -- number under a parent disagreed with the numbers under its children.
        COALESCE(
          SUM(CASE WHEN $exactBranch THEN $netAmountMinor END),
          0
        ) as exactMinor,
        -- The inexact remainder: foreign-currency rows, which have to be
        -- multiplied by a rate and cannot be integers, and non-fiat rows,
        -- which have no minor unit to be exact in.
        COALESCE(
          SUM(
            CASE
              WHEN $exactBranch THEN 0.0
              -- Still the no-conversion case, just without exact units: same
              -- currency, so no pivot, no rate lookup, no round through EUR.
              WHEN t.currency_code = $mainLiteral THEN $netAmount
              ELSE ($netAmount)
                -- STEP 1: Transaction Currency -> Base (EUR)
                * CASE WHEN t.currency_code = 'EUR' THEN 1.0
                       ELSE ${rateFactor('t.currency_code', "'EUR'")} END
                -- STEP 2: Base (EUR) -> Main Currency
                * CASE WHEN $mainLiteral = 'EUR' THEN 1.0
                       ELSE ${rateFactor("'EUR'", mainLiteral)} END
            END
          ),
          0.0
        ) as approxTotal
      FROM transactions t
      JOIN category_ancestry a ON a.category_id = t.category_id
      $whereClause
      GROUP BY a.ancestor_id
    ''';

    final rows = await customSelect(sql, variables: variables).get();

    // One scale for the whole result: every exact row is by definition in the
    // main currency, so they all divide by the same power of ten. Zero-decimal
    // currencies (JPY, KRW) scale by 1 and three-decimal ones (BHD, KWD) by
    // 1000 - dividing those by a hardwired 100 would be off by two orders of
    // magnitude, which is the whole reason [CurrencyPrecision] exists.
    final scale = CurrencyPrecision.scaleFor(
      CurrencyPrecision.decimalsFor(mainCurrencyCode),
    ).toDouble();

    final categoryTotals = <String, double>{};
    for (final row in rows) {
      // The division happens once per category rather than once per row, so
      // the integer sum stays exact all the way to the last step and only the
      // converted remainder was ever floating point.
      categoryTotals[row.read<String>('categoryId')] =
          row.read<int>('exactMinor') / scale + row.read<double>('approxTotal');
    }

    debugPrint('[PERF] SQL Optimized Aggregation: ${sw.elapsedMilliseconds}ms');
    return categoryTotals;
  }
}

class GroupedTransactionTotal {
  final String categoryId;
  final String currencyCode;
  final DateTime date;
  final double total;

  GroupedTransactionTotal({
    required this.categoryId,
    required this.currencyCode,
    required this.date,
    required this.total,
  });
}

@DriftAccessor(tables: [Settings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  Stream<List<Setting>> watchAllSettings() => select(settings).watch();
  Stream<Setting?> watchSetting(String key) {
    return (select(
      settings,
    )..where((tbl) => tbl.key.equals(key))).watchSingleOrNull();
  }

  Future<Setting?> getSetting(String key) =>
      (select(settings)..where((tbl) => tbl.key.equals(key))).getSingleOrNull();

  /// Writes a setting, stamping [Settings.modifiedAt] when the caller left it
  /// out.
  ///
  /// Without the stamp every setting the user changed sat at modifiedAt 0,
  /// which is the losing side of last-write-wins: the moment settings are
  /// carried by a sync engine, a peer's untouched default beats the choice the
  /// user actually made. An explicit value is left alone, so a row applied from
  /// a peer keeps the timestamp it arrived with.
  Future<void> setSetting(SettingsCompanion setting) async {
    final toInsert =
        (setting.modifiedAt.present && setting.modifiedAt.value > 0)
        ? setting
        : setting.copyWith(
            modifiedAt: Value(DateTime.now().millisecondsSinceEpoch),
          );
    await into(settings).insert(toInsert, mode: InsertMode.insertOrReplace);
    await _logChange(toInsert.key.value);
  }

  /// Writes a setting that arrived from a peer.
  ///
  /// No `sync_log` row and no clock of its own: the timestamp is the one the
  /// sender stamped, and re-logging it would send the change straight back to
  /// the device it came from. Every other synced table has the same pair.
  Future<void> setSyncedSetting(SettingsCompanion setting) =>
      into(settings).insert(setting, mode: InsertMode.insertOrReplace);

  Future<List<Setting>> getSettingsByKeys(List<String> keys) =>
      (select(settings)..where((t) => t.key.isIn(keys))).get();

  /// Queues a setting for the folder-sync exporter.
  ///
  /// Device-local keys are dropped here rather than at export time because
  /// this is the only place that knows a write happened at all - a key that
  /// never enters the log can never leave the device, whatever a later change
  /// to the exporter does. The server path filters the same list in SQL.
  Future<void> _logChange(String key) async {
    if (kDeviceLocalSettingKeys.contains(key)) return;
    await into(db.syncLog).insert(
      SyncLogCompanion(
        changedTableName: const Value('settings'),
        recordId: Value(key),
        action: const Value('upsert'),
        timestamp: Value(DateTime.now().millisecondsSinceEpoch),
        exported: const Value(false),
      ),
    );
  }

  Future<void> insertAllSettings(List<SettingsCompanion> settings) {
    return batch((batch) {
      batch.insertAll(
        this.settings,
        settings,
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  Future<List<Setting>> getAllSettings() => select(settings).get();
  Future<List<Setting>> getSettings({int limit = 10, int offset = 0}) =>
      (select(settings)..limit(limit, offset: offset)).get();
  Future<List<Setting>> getRecentSettings(int limit) {
    return (select(settings)
          ..orderBy([
            (t) => OrderingTerm(expression: t.key, mode: OrderingMode.desc),
          ])
          ..limit(limit))
        .get();
  }

  Future<String> getDeviceName() => dev_utils.getDeviceName();
}

@DriftAccessor(tables: [ExchangeRates, SyncLog])
class ExchangeRatesDao extends DatabaseAccessor<AppDatabase>
    with _$ExchangeRatesDaoMixin {
  ExchangeRatesDao(super.db);

  Future<List<ExchangeRate>> getAllExchangeRates() =>
      select(exchangeRates).get();

  /// Every rate row whose two endpoints are both currencies this database uses
  /// ([kUsedCurrenciesSql]).
  ///
  /// This is what a backup carries. The table holds a row per currency pair per
  /// day — 432 000 of them on the database this was written against, a 105 MB
  /// backup file that took two minutes to restore — while a budget prices
  /// everything in two or three currencies. The rest is reference data: it is
  /// identical on every install, the server serves it on demand, and a restore
  /// that leaves it out reproduces the user's money exactly.
  Future<List<ExchangeRate>> getExchangeRatesForUsedCurrencies() async {
    final rows = await customSelect(
      '''
      SELECT * FROM exchange_rates
       WHERE from_currency_code IN ($kUsedCurrenciesSql)
         AND to_currency_code IN ($kUsedCurrenciesSql)
      ''',
      readsFrom: {
        exchangeRates,
        attachedDatabase.accounts,
        attachedDatabase.transactions,
        attachedDatabase.assetEntries,
        attachedDatabase.settings,
      },
    ).get();
    return rows.map((row) => exchangeRates.map(row.data)).toList();
  }

  /// Lightweight change signal for the exchange_rates table. Fires on every
  /// insert/update/delete WITHOUT materializing any rows — used to invalidate
  /// the in-memory rate cache in [CurrencyConverterService] so a freshly
  /// added/imported/refreshed rate takes effect without an app restart.
  Stream<void> watchExchangeRateChanges() =>
      tableUpdates(TableUpdateQuery.onTable(exchangeRates));

  /// Every rate stored on any of the calendar days in [dates].
  ///
  /// Matches on the DAY, not on the exact instant. Callers pass midnight
  /// (`DateTime(y, m, d)`) because that is how a transaction's day is
  /// normalised, but a rate pulled from an API is stamped with the wall clock
  /// of the moment it was fetched. An equality test between the two matched
  /// nothing at all, so every pair whose only rows came from an API refresh
  /// was invisible to the caller and every amount in that currency silently
  /// dropped out of the totals.
  ///
  /// [currencyCodes], when given, keeps only the rows BOTH of whose sides are
  /// one of those codes — or one of the currencies the table quotes from, which
  /// are added to the set here. The table holds a row per currency pair per day
  /// — 326 of them per day, 853 days, 432k rows on the database this was
  /// written against — and a screen prices amounts in a handful of them.
  ///
  /// Both sides, not either side. Either side is what a pivot needs — a pair
  /// with no direct row is converted through one, and the two rows making that
  /// hop touch the pivot on one side only — but every row in the table is
  /// quoted from the same pivot, so "touches one of these codes" matched the
  /// whole day once the pivot was on screen: 326 rows fetched where 5 were
  /// wanted. Adding the quote currencies to the set keeps both halves of every
  /// hop and drops the rest.
  Future<List<ExchangeRate>> getAllExchangesRates(
    List<DateTime> dates, {
    Set<String>? currencyCodes,
  }) async {
    if (dates.isEmpty) return [];

    // Consecutive days collapse into one range. A year of daily transactions is
    // 365 separate day tests otherwise, and the days a budget touches come in
    // runs, so this is usually an order-of-magnitude fewer terms.
    final days =
        dates.map((d) => DateTime(d.year, d.month, d.day)).toSet().toList()
          ..sort();
    final ranges = <({DateTime start, DateTime end})>[];
    var rangeStart = days.first;
    var rangeEnd = nextDay(rangeStart);
    for (final day in days.skip(1)) {
      // `nextDay`, not `add(Duration(days: 1))`: across a clock change a day is
      // 23 or 25 hours, so a nominal day lands beside local midnight rather
      // than on it, and the end of a 25-hour day would fall an hour short of
      // the day it is meant to bound.
      if (day.isAfter(rangeEnd)) {
        ranges.add((start: rangeStart, end: rangeEnd));
        rangeStart = day;
      }
      rangeEnd = nextDay(day);
    }
    ranges.add((start: rangeStart, end: rangeEnd));

    // Each range contributes two bound variables. SQLite's default ceiling on a
    // single statement is 999, so keep a chunk well under half of that.
    const int chunkSize = 300;
    List<ExchangeRate> allResults = [];

    for (var i = 0; i < ranges.length; i += chunkSize) {
      final end = (i + chunkSize < ranges.length)
          ? i + chunkSize
          : ranges.length;
      final chunk = ranges.sublist(i, end);

      final dayRanges = _anyOf([
        for (final range in chunk)
          exchangeRates.date.isBiggerOrEqualValue(range.start) &
              exchangeRates.date.isSmallerThanValue(range.end),
      ]);

      final codeFilter = await _withCodeFilter(dayRanges, currencyCodes);
      final chunkResults = await (select(
        exchangeRates,
      )..where((_) => codeFilter)).get();

      allResults.addAll(chunkResults);
    }

    allResults.addAll(
      await _ratesForUncoveredDays(days, allResults, currencyCodes),
    );

    return allResults;
  }

  /// [rows] restricted to the pairs whose two sides are both in [currencyCodes]
  /// or are a currency the table quotes from. See [getAllExchangesRates] for
  /// why the quote currencies belong in the set.
  Future<Expression<bool>> _withCodeFilter(
    Expression<bool> rows,
    Set<String>? currencyCodes,
  ) async {
    if (currencyCodes == null || currencyCodes.isEmpty) return rows;
    final codes = {...currencyCodes, ...await _quoteCurrencies()}.toList();
    return rows &
        exchangeRates.fromCurrencyCode.isIn(codes) &
        exchangeRates.toCurrencyCode.isIn(codes);
  }

  /// The currencies the table quotes rates FROM — one of them on this data set,
  /// the euro every published rate is stated against.
  ///
  /// Held between calls, and dropped by the same change stream that drops
  /// [_storedRateDays]: it is asked for on every rate read, and a fresh
  /// `SELECT DISTINCT` walks the whole composite index each time.
  Future<Set<String>> _quoteCurrencies() async {
    final cached = _quoteCurrenciesCache;
    if (cached != null) return cached;

    _quoteCurrenciesWatch ??= watchExchangeRateChanges().listen((_) {
      _quoteCurrenciesCache = null;
    });

    final query = selectOnly(exchangeRates, distinct: true)
      ..addColumns([exchangeRates.fromCurrencyCode]);
    final rows = await query.get();
    final codes = {
      for (final row in rows) row.read(exchangeRates.fromCurrencyCode)!,
    };
    _quoteCurrenciesCache = codes;
    return codes;
  }

  Set<String>? _quoteCurrenciesCache;
  StreamSubscription<void>? _quoteCurrenciesWatch;

  /// Rows to stand in for the days in [days] that [found] has nothing for.
  ///
  /// The provider stops somewhere - the bundled history ends in January and the
  /// free API answers 404 for anything past its own last publication - so a
  /// budget being read today asks for days no row exists on. Returning only
  /// exact matches handed [CurrencyConverter] an empty set for those days, and
  /// the dashboard then reported *every* foreign currency as unconvertible even
  /// though a rate from a fortnight earlier was sitting in the table. The
  /// converter already prefers whichever stored row is nearest the date it was
  /// asked about; this makes sure such a row is in front of it.
  ///
  /// Two statements at most, whatever the shape of the gap. The first version
  /// asked SQLite which day was nearest, one query on each side per uncovered
  /// day: thirteen round trips on the transactions page and about forty on the
  /// dashboard, repeated on every navigation. The days that exist are a list of
  /// a few hundred that changes only when a rate is written, so it is cheaper
  /// to hold it and binary-search it here.
  Future<List<ExchangeRate>> _ratesForUncoveredDays(
    List<DateTime> days,
    List<ExchangeRate> found,
    Set<String>? currencyCodes,
  ) async {
    final covered = found.map((r) => _dayOf(r.date)).toSet();
    final missing = days.where((d) => !covered.contains(d)).toList();
    if (missing.isEmpty) return const [];

    final stored = await _storedRateDays();
    if (stored.isEmpty) return const [];

    final substitutes = <DateTime>{};
    for (final day in missing) {
      final nearest = _nearestStoredDay(stored, day);
      if (nearest != null) substitutes.add(nearest);
    }

    final wanted = substitutes.difference(covered);
    if (wanted.isEmpty) return const [];

    final codeFilter = await _withCodeFilter(
      _anyOf([
        for (final day in wanted)
          exchangeRates.date.isBiggerOrEqualValue(day) &
              exchangeRates.date.isSmallerThanValue(nextDay(day)),
      ]),
      currencyCodes,
    );
    return (select(exchangeRates)..where((_) => codeFilter)).get();
  }

  /// Whichever day in [sorted] is closest to [day], preferring the earlier one
  /// when a day falls exactly between two.
  ///
  /// A rate from before the date being converted is the safer of two equals: it
  /// was quoted by the time the transaction happened. Shared with the pickers
  /// in the transactions bloc, which resolved the same tie the other way.
  DateTime? _nearestStoredDay(List<DateTime> sorted, DateTime day) =>
      nearestDay(sorted, day);

  /// Every calendar day the rate table holds a row on, ascending.
  ///
  /// Held between calls. Recomputing it means a `GROUP BY date` over every rate
  /// in the table - a few hundred thousand of them once the bundled history is
  /// seeded - and it is asked for on every screen that converts anything. The
  /// table's own change stream drops the list, so a fetched or imported rate
  /// still shows up.
  Future<List<DateTime>> _storedRateDays() async {
    final cached = _storedRateDaysCache;
    if (cached != null) return cached;

    _storedRateDaysWatch ??= watchExchangeRateChanges().listen((_) {
      _storedRateDaysCache = null;
    });

    final query = selectOnly(exchangeRates)
      ..addColumns([exchangeRates.date])
      ..groupBy([exchangeRates.date])
      ..orderBy([OrderingTerm.asc(exchangeRates.date)]);
    final rows = await query.get();

    // A rate pulled from an API is stamped with the wall clock of the moment it
    // was fetched, so two rows on the same day are two rows here until they are
    // normalised.
    final days = <DateTime>[];
    for (final row in rows) {
      final date = row.read(exchangeRates.date);
      if (date == null) continue;
      final normalised = _dayOf(date);
      if (days.isEmpty || days.last != normalised) days.add(normalised);
    }
    _storedRateDaysCache = days;
    return days;
  }

  List<DateTime>? _storedRateDaysCache;
  StreamSubscription<void>? _storedRateDaysWatch;

  static DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  /// [terms] OR-ed together as a BALANCED tree.
  ///
  /// `terms.reduce((a, b) => a | b)` builds a left-deep chain, and SQLite parses
  /// `((((a OR b) OR c) OR d) ...)` recursively: past a couple of hundred terms
  /// it aborts the whole statement with "parser stack overflow", which surfaced
  /// as an empty rate set and a dashboard reporting every foreign currency as
  /// unconvertible. Halving instead of chaining makes the nesting logarithmic —
  /// a thousand terms nest ten deep.
  Expression<bool> _anyOf(List<Expression<bool>> terms) {
    if (terms.length == 1) return terms.first;
    final mid = terms.length ~/ 2;
    return _anyOf(terms.sublist(0, mid)) | _anyOf(terms.sublist(mid));
  }

  Future<List<ExchangeRate>> getAllExchangesRatesAll() =>
      select(exchangeRates).get();

  /// The distinct days the seeded history already covers.
  ///
  /// The startup gap check used to answer this out of
  /// [getAllExchangesRatesAll]: every rate row - 367k of them on a real
  /// database - marshalled across the drift isolate port, rebuilt as domain
  /// objects and date-formatted one by one on the UI isolate, while the first
  /// frames were being laid out. It only ever wanted the days, and there are a
  /// few hundred of those.
  Future<List<DateTime>> getPresetRateDates() {
    final query = selectOnly(exchangeRates, distinct: true)
      ..addColumns([exchangeRates.date])
      ..where(exchangeRates.preset.equals(1));
    return query.map((row) => row.read(exchangeRates.date)!).get();
  }

  Future<List<ExchangeRate>> getExchangeRatesFiltered({
    int limit = 100,
    int offset = 0,
    DateTime? startDate,
    DateTime? endDate,
    String? fromCurrency,
    String? toCurrency,
    List<int>? presets,
    OrderingMode sort = OrderingMode.desc,
  }) {
    final query = select(exchangeRates);

    if (startDate != null) {
      query.where((t) => t.date.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      query.where((t) => t.date.isSmallerOrEqualValue(endDate));
    }
    if (fromCurrency != null) {
      query.where((t) => t.fromCurrencyCode.equals(fromCurrency));
    }
    if (toCurrency != null) {
      query.where((t) => t.toCurrencyCode.equals(toCurrency));
    }
    if (presets != null && presets.isNotEmpty) {
      query.where((t) => t.preset.isIn(presets));
    }

    // The sort column is not unique, and `LIMIT`/`OFFSET` asks for the
    // pages in separate queries: rows that tie on it have no order to keep
    // between one page and the next, so a tie broken differently the second
    // time repeats a row the user already saw and drops one they never will.
    // The row's own key is the tiebreak that makes the order total.
    query.orderBy([
      (t) => OrderingTerm(expression: t.date, mode: sort),
      (t) => OrderingTerm(expression: t.fromCurrencyCode, mode: sort),
      (t) => OrderingTerm(expression: t.toCurrencyCode, mode: sort),
      (t) => OrderingTerm(expression: t.preset, mode: sort),
    ]);
    query.limit(limit, offset: offset);

    return query.get();
  }

  Future<int> getExchangeRatesCount({
    DateTime? startDate,
    DateTime? endDate,
    String? fromCurrency,
    String? toCurrency,
    List<int>? presets,
  }) async {
    final query = selectOnly(exchangeRates);

    if (startDate != null) {
      query.where(exchangeRates.date.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      query.where(exchangeRates.date.isSmallerOrEqualValue(endDate));
    }
    if (fromCurrency != null) {
      query.where(exchangeRates.fromCurrencyCode.equals(fromCurrency));
    }
    if (toCurrency != null) {
      query.where(exchangeRates.toCurrencyCode.equals(toCurrency));
    }
    if (presets != null && presets.isNotEmpty) {
      query.where(exchangeRates.preset.isIn(presets));
    }

    final countExp = exchangeRates.date.count();
    query.addColumns([countExp]);
    final count = await query
        .map((row) => row.read(countExp))
        .getSingleOrNull();
    return count ?? 0;
  }

  Future<List<int>> getAvailablePresets() async {
    final result = await customSelect(
      'SELECT DISTINCT preset FROM exchange_rates ORDER BY preset ASC',
      readsFrom: {exchangeRates},
    ).get();
    return result.map((row) => row.read<int>('preset')).toList();
  }

  Future<List<ExchangeRate>> getLatestExchangeRates(DateTime date) {
    return customSelect(
      'SELECT r.* FROM exchange_rates r INNER JOIN (SELECT from_currency_code, to_currency_code, MAX(date) AS max_date FROM exchange_rates WHERE date <= ? GROUP BY from_currency_code, to_currency_code) max_dates ON r.from_currency_code = max_dates.from_currency_code AND r.to_currency_code = max_dates.to_currency_code AND r.date = max_dates.max_date',
      variables: [Variable.withDateTime(date)],
      readsFrom: {exchangeRates},
    ).get().then(
      (rows) => rows.map((row) => exchangeRates.map(row.data)).toList(),
    );
  }

  Future<void> addExchangeRate(ExchangeRatesCompanion rate) async {
    debugPrint('DAO: Adding exchange rate with preset: ${rate.preset.value}');
    final toInsert = rate.copyWith(
      modifiedAt: Value(DateTime.now().millisecondsSinceEpoch),
    );
    await into(
      exchangeRates,
    ).insert(toInsert, mode: InsertMode.insertOrReplace);

    final from = toInsert.fromCurrencyCode.value;
    final to = toInsert.toCurrencyCode.value;
    final date = DateFormat('yyyy-MM-dd', 'en').format(toInsert.date.value);
    final preset = toInsert.preset.value;
    final recordId = '${from}_${to}_${date}_$preset';
    await _logChange(recordId, 'upsert');
  }

  Future<void> insertSyncedExchangeRate(ExchangeRatesCompanion rate) =>
      into(exchangeRates).insert(rate, mode: InsertMode.insertOrReplace);

  Future<void> updateExchangeRate(ExchangeRatesCompanion rate) async {
    final updatedRate = rate.copyWith(
      modifiedAt: Value(DateTime.now().millisecondsSinceEpoch),
    );
    await update(exchangeRates).replace(updatedRate);

    final from = updatedRate.fromCurrencyCode.value;
    final to = updatedRate.toCurrencyCode.value;
    final date = DateFormat('yyyy-MM-dd', 'en').format(updatedRate.date.value);
    final preset = updatedRate.preset.value;
    final recordId = '${from}_${to}_${date}_$preset';
    await _logChange(recordId, 'upsert');
  }

  /// Replaces an existing exchange rate by deleting the ORIGINAL row (matched
  /// on its composite primary key from/to/date/preset) and inserting the
  /// updated row, atomically. This prevents orphaned duplicates when the user
  /// edits key fields (from/to/date/preset) of an existing rate.
  Future<void> replaceExchangeRate(
    ExchangeRateDomain original,
    ExchangeRatesCompanion updated,
  ) async {
    final toInsert = updated.copyWith(
      modifiedAt: Value(DateTime.now().millisecondsSinceEpoch),
    );

    await transaction(() async {
      // Delete the ORIGINAL row by its composite primary key.
      await (delete(exchangeRates)..where(
            (t) =>
                t.fromCurrencyCode.equals(original.fromCurrencyCode) &
                t.toCurrencyCode.equals(original.toCurrencyCode) &
                t.date.equals(original.date) &
                t.preset.equals(original.preset),
          ))
          .go();

      // Insert the updated row.
      await into(
        exchangeRates,
      ).insert(toInsert, mode: InsertMode.insertOrReplace);
    });

    // Sync bookkeeping.
    final originalDate = DateFormat('yyyy-MM-dd', 'en').format(original.date);
    final originalId =
        '${original.fromCurrencyCode}_${original.toCurrencyCode}_${originalDate}_${original.preset}';
    final newDate = DateFormat('yyyy-MM-dd', 'en').format(toInsert.date.value);
    final newId =
        '${toInsert.fromCurrencyCode.value}_${toInsert.toCurrencyCode.value}_${newDate}_${toInsert.preset.value}';

    if (originalId != newId) {
      await _logChange(originalId, 'delete');
    }
    await _logChange(newId, 'upsert');
  }

  Future<void> insertAllExchangeRates(
    List<ExchangeRatesCompanion> rates,
  ) async {
    if (rates.isEmpty) return;

    // Both currency columns are foreign keys into `currencies`, and every
    // source feeding this method quotes far more codes than the app seeds: the
    // bundled history alone carries 812, of which 341 are known. A single
    // unknown code used to abort the whole batch with
    // `SqliteException(787): FOREIGN KEY constraint failed`, which on Android
    // left the database with no rates at all and every foreign-currency total
    // unconvertible. Drop what cannot be referenced and keep the rest.
    final knownCodes =
        (await attachedDatabase.select(attachedDatabase.currencies).get())
            .map((c) => c.code)
            .toSet();

    final insertable = rates
        .where(
          (r) =>
              knownCodes.contains(r.fromCurrencyCode.value) &&
              knownCodes.contains(r.toCurrencyCode.value),
        )
        .toList();

    if (insertable.length != rates.length) {
      debugPrint(
        '[DB] Skipped ${rates.length - insertable.length} of ${rates.length} '
        'exchange rates naming a currency the app does not know.',
      );
    }
    if (insertable.isEmpty) return;

    final List<ExchangeRatesCompanion> ratesWithTimestamp = [];
    final now = DateTime.now().millisecondsSinceEpoch;

    await batch((batch) {
      for (final r in insertable) {
        final withTs = r.copyWith(modifiedAt: Value(now));
        ratesWithTimestamp.add(withTs);
        batch.insert(exchangeRates, withTs, mode: InsertMode.insertOrReplace);
      }
    });

    // Deliberately not written to sync_log. This is the bulk path used by the
    // seed data and by every rate-provider refresh, so one launch would enqueue
    // hundreds of thousands of rows. Both engines could ship them now - the
    // file engine gained an exchangeRates case in 585b48d - which is exactly
    // why the omission has to stay deliberate: every device fetches the same
    // rates from the same provider, so shipping them buys the peer nothing and
    // costs every export a re-walk of the whole backlog. Manually entered rates
    // still log through addExchangeRate/updateExchangeRate/replaceExchangeRate.
  }

  /// Stores rates that came from this device's own sync server.
  ///
  /// Same rows as [insertAllExchangeRates], with two differences that both
  /// exist to stop the device sending the server back its own data.
  ///
  /// The rows are stamped [kServerRateDeviceId] rather than left for the
  /// device-id trigger to claim, so what wrote them stays visible; and the
  /// push-queue entries the insert trigger creates are deleted inside the same
  /// transaction, the way the server pull already does it. Without that, a
  /// range fetch would upload every row it just downloaded, the server would
  /// rewrite each one under this device's id, and the rows would then be handed
  /// to every other device through the ordinary sync - the exact traffic that
  /// moving the fetch to the server was meant to remove.
  Future<void> insertFetchedExchangeRates(
    List<ExchangeRatesCompanion> rates,
  ) async {
    if (rates.isEmpty) return;

    await transaction(() async {
      final mark = await _pushQueueCeiling();
      await insertAllExchangeRates([
        for (final rate in rates)
          rate.copyWith(deviceId: const Value(kServerRateDeviceId)),
      ]);
      await customStatement('DELETE FROM sync_push_queue WHERE id > ?', [mark]);
    });
  }

  /// The highest queue entry that existed before a write, so the entries that
  /// write adds can be told apart from a real local edit waiting to go up.
  Future<int> _pushQueueCeiling() async {
    final row = await customSelect(
      'SELECT COALESCE(MAX(id), 0) AS c FROM sync_push_queue',
    ).getSingle();
    return row.read<int>('c');
  }

  Future<void> deleteExchangeRates(List<ExchangeRateDomain> rates) {
    return batch((batch) {
      for (final rate in rates) {
        batch.delete(
          exchangeRates,
          ExchangeRatesCompanion(
            fromCurrencyCode: Value(rate.fromCurrencyCode),
            toCurrencyCode: Value(rate.toCurrencyCode),
            date: Value(rate.date),
            preset: Value(rate.preset),
          ),
        );
      }
    });
  }

  Future<void> updateExchangeRatePresets(
    List<ExchangeRateDomain> rates,
    int newPreset,
  ) {
    return transaction(() async {
      for (final rate in rates) {
        // Delete old entry
        await (delete(exchangeRates)..where(
              (t) =>
                  t.fromCurrencyCode.equals(rate.fromCurrencyCode) &
                  t.toCurrencyCode.equals(rate.toCurrencyCode) &
                  t.date.equals(rate.date) &
                  t.preset.equals(rate.preset),
            ))
            .go();

        // Insert new entry with updated preset
        await into(exchangeRates).insert(
          ExchangeRatesCompanion(
            fromCurrencyCode: Value(rate.fromCurrencyCode),
            toCurrencyCode: Value(rate.toCurrencyCode),
            date: Value(rate.date),
            preset: Value(newPreset),
            rate: Value(rate.rate),
            modifiedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
          mode: InsertMode.replace,
        );
      }
    });
  }

  Future<void> _logChange(String recordId, String action) async {
    await into(db.syncLog).insert(
      SyncLogCompanion(
        changedTableName: const Value('exchange_rates'),
        recordId: Value(recordId),
        action: Value(action),
        timestamp: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }
}

@DriftAccessor(tables: [CustomThemes])
class CustomThemesDao extends DatabaseAccessor<AppDatabase>
    with _$CustomThemesDaoMixin {
  CustomThemesDao(super.db);

  Future<List<DbCustomTheme>> getAllThemes() =>
      (select(customThemes)..where((t) => t.isDeleted.equals(false))).get();
  Future<DbCustomTheme?> getThemeById(String id) =>
      (select(customThemes)
            ..where((tbl) => tbl.id.equals(id) & tbl.isDeleted.equals(false)))
          .getSingleOrNull();

  /// The theme the app renders from, chosen deterministically when more than
  /// one row claims to be active.
  ///
  /// "Exactly one theme is active" is a rule across rows, and sync merges one
  /// row at a time, so it is not a rule sync can keep: a device that activates
  /// a theme while another device has its own ends up, after the two meet,
  /// with the flag on both. This read used to be `getSingleOrNull`, which
  /// throws on the second row - and it throws out of the single
  /// LoadThemeSettings the app dispatches at startup, so the user got a
  /// fallback preset and an error bar that no restart cleared, on a database
  /// that was merely ambiguous rather than broken.
  ///
  /// Newest wins, id breaks the tie. The rule is the same on every device, so
  /// a fleet whose rows disagree still renders the same theme, and the next
  /// time the user picks one [setActiveTheme] clears the rest for good.
  Future<DbCustomTheme?> getActiveTheme() =>
      (select(customThemes)
            ..where(
              (tbl) => tbl.isActive.equals(true) & tbl.isDeleted.equals(false),
            )
            ..orderBy([
              (t) => OrderingTerm.desc(t.modifiedAt),
              (t) => OrderingTerm.asc(t.id),
            ])
            ..limit(1))
          .getSingleOrNull();

  Future<void> insertTheme(CustomThemesCompanion theme) async {
    var toInsert = theme.id.present
        ? theme
        : theme.copyWith(id: Value(_uuid.v4()));

    toInsert = toInsert.copyWith(
      modifiedAt: Value(DateTime.now().millisecondsSinceEpoch),
    );
    await into(customThemes).insert(toInsert, mode: InsertMode.insertOrReplace);
    await _logChange(toInsert.id.value, 'upsert');
  }

  Future<void> insertSyncedTheme(CustomThemesCompanion theme) =>
      into(customThemes).insert(theme, mode: InsertMode.insertOrReplace);

  Future<void> insertAllThemes(List<CustomThemesCompanion> themes) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final themesWithIds = themes.map((t) {
      var companion = t;
      if (!companion.id.present) {
        companion = companion.copyWith(id: Value(_uuid.v4()));
      }
      return companion.copyWith(modifiedAt: Value(now));
    }).toList();

    await batch((batch) {
      batch.insertAll(
        customThemes,
        themesWithIds,
        mode: InsertMode.insertOrReplace,
      );
    });
    await _logChanges(themesWithIds.map((t) => t.id.value).toList(), 'upsert');
  }

  Future<bool> updateTheme(CustomThemesCompanion theme) async {
    final updatedTheme = theme.copyWith(
      modifiedAt: Value(DateTime.now().millisecondsSinceEpoch),
    );
    // `replace` writes the column default for every column the companion
    // omits, so a theme companion without `isDeleted` un-deleted the row, and
    // one without `effectOpacity`/`surfaceOpacity`/`backgroundImageOpacity`
    // silently reset those to 1.0/1.0/1.0 - the user's tuned look snapping back
    // to the defaults on an unrelated edit. `write` touches only what was set.
    final count = await (update(
      customThemes,
    )..where((t) => t.id.equals(updatedTheme.id.value))).write(updatedTheme);
    if (count > 0) {
      await _logChange(theme.id.value, 'upsert');
    }
    return count > 0;
  }

  Future<int> deleteTheme(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final count = await (update(customThemes)..where((t) => t.id.equals(id)))
        .write(
          CustomThemesCompanion(
            isDeleted: const Value(true),
            modifiedAt: Value(now),
          ),
        );

    if (count > 0) {
      await _logChange(id, 'delete');
    }
    return count;
  }

  Future<void> setActiveTheme(String id) {
    return transaction(() async {
      final now = DateTime.now().millisecondsSinceEpoch;

      // Check the target first. Deactivating everything and then updating an id
      // that is not there - or one the user deleted - left the app with NO
      // active theme at all, which is worse than the theme not changing: the
      // user loses the look they had and there is nothing in the picker marked
      // as current. A deleted theme must not become active either, or the
      // interface renders from a row that is a tombstone everywhere else.
      final target =
          await (select(customThemes)..where(
                (tbl) => tbl.id.equals(id) & tbl.isDeleted.equals(false),
              ))
              .getSingleOrNull();
      if (target == null) return;

      // The rows losing `is_active` change too, so a peer that only heard
      // about [id] would end up with two active themes.
      final deactivated = await (select(
        customThemes,
      )..where((tbl) => tbl.isActive.equals(true))).get();

      await (update(
        customThemes,
      )..where((tbl) => tbl.isActive.equals(true))).write(
        CustomThemesCompanion(
          isActive: const Value(false),
          modifiedAt: Value(now),
        ),
      );
      await (update(customThemes)..where((tbl) => tbl.id.equals(id))).write(
        CustomThemesCompanion(
          isActive: const Value(true),
          modifiedAt: Value(now),
        ),
      );

      final ids = {...deactivated.map((t) => t.id), id}.toList();
      await _logChanges(ids, 'upsert');
    });
  }

  Future<void> _logChange(String recordId, String action) async {
    await into(db.syncLog).insert(
      SyncLogCompanion(
        changedTableName: const Value('custom_themes'),
        recordId: Value(recordId),
        action: Value(action),
        timestamp: Value(DateTime.now().millisecondsSinceEpoch),
        exported: const Value(false),
      ),
    );
  }

  Future<void> _logChanges(List<String> recordIds, String action) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await batch((batch) {
      batch.insertAll(
        db.syncLog,
        recordIds
            .map(
              (id) => SyncLogCompanion(
                changedTableName: const Value('custom_themes'),
                recordId: Value(id),
                action: Value(action),
                timestamp: Value(timestamp),
                exported: const Value(false),
              ),
            )
            .toList(),
      );
    });
  }
}

@DriftAccessor(tables: [InflationRates, SyncLog])
class InflationRatesDao extends DatabaseAccessor<AppDatabase>
    with _$InflationRatesDaoMixin {
  InflationRatesDao(super.db);

  Future<List<InflationRate>> getAllInflationRates() =>
      select(inflationRates).get();

  Future<List<InflationRate>> getInflationRatesFiltered({
    required int limit,
    required int offset,
    DateTime? dateFrom,
    DateTime? dateTo,
    List<String>? countries,
    List<int>? presets,
    OrderingMode sort = OrderingMode.desc,
  }) {
    // See the note on the transactions query: ordering by date alone leaves
    // the rows that share a date free to swap places between pages.
    final query = select(inflationRates)
      ..limit(limit, offset: offset)
      ..orderBy([
        (t) => OrderingTerm(expression: t.date, mode: sort),
        (t) => OrderingTerm(expression: t.country, mode: sort),
        (t) => OrderingTerm(expression: t.preset, mode: sort),
      ]);

    if (dateFrom != null) {
      query.where((t) => t.date.isBiggerOrEqualValue(dateFrom));
    }
    if (dateTo != null) {
      query.where((t) => t.date.isSmallerOrEqualValue(dateTo));
    }

    if (countries != null && countries.isNotEmpty) {
      query.where((t) => t.country.isIn(countries));
    }
    if (presets != null && presets.isNotEmpty) {
      query.where((t) => t.preset.isIn(presets));
    }

    return query.get();
  }

  Stream<List<InflationRate>> watchInflationRatesFiltered({
    required int limit,
    required int offset,
    DateTime? dateFrom,
    DateTime? dateTo,
    List<String>? countries,
    List<int>? presets,
    OrderingMode sort = OrderingMode.desc,
  }) {
    // See the note on the transactions query: ordering by date alone leaves
    // the rows that share a date free to swap places between pages.
    final query = select(inflationRates)
      ..limit(limit, offset: offset)
      ..orderBy([
        (t) => OrderingTerm(expression: t.date, mode: sort),
        (t) => OrderingTerm(expression: t.country, mode: sort),
        (t) => OrderingTerm(expression: t.preset, mode: sort),
      ]);

    if (dateFrom != null) {
      query.where((t) => t.date.isBiggerOrEqualValue(dateFrom));
    }
    if (dateTo != null) {
      query.where((t) => t.date.isSmallerOrEqualValue(dateTo));
    }

    if (countries != null && countries.isNotEmpty) {
      query.where((t) => t.country.isIn(countries));
    }
    if (presets != null && presets.isNotEmpty) {
      query.where((t) => t.preset.isIn(presets));
    }

    return query.watch();
  }

  Future<void> insertInflationRate(InflationRatesCompanion rate) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final toInsert = _withResolvedCountry(
      rate,
    ).copyWith(modifiedAt: Value(now));
    await into(
      inflationRates,
    ).insert(toInsert, mode: InsertMode.insertOrReplace);

    // Log change for sync
    await _logChange(
      _recordId(
        toInsert.date.value,
        toInsert.country.value,
        toInsert.preset.value,
      ),
      'upsert',
    );
  }

  Future<void> insertAllInflationRates(
    List<InflationRatesCompanion> rates,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await batch((batch) {
      for (final r in rates) {
        batch.insert(
          inflationRates,
          _withResolvedCountry(r).copyWith(modifiedAt: Value(now)),
          mode: InsertMode.insertOrReplace,
        );
      }
    });

    // Not written to sync_log, for the same reason as insertAllExchangeRates:
    // provider data every device fetches for itself, so shipping it only makes
    // every export longer. Both engines can carry inflation rates - the file
    // engine since 585b48d - so this is a choice, not a gap. This loop also ran
    // one INSERT round trip per rate.
  }

  Future<void> insertSyncedInflationRate(InflationRatesCompanion rate) => into(
    inflationRates,
  ).insert(_withResolvedCountry(rate), mode: InsertMode.insertOrReplace);

  Future<void> deleteInflationRate(
    DateTime date,
    String? country,
    int preset,
  ) async {
    final resolved = _resolveCountry(country);
    final count =
        await (delete(inflationRates)..where(
              (tbl) =>
                  tbl.date.equals(date) &
                  tbl.country.equals(resolved) &
                  tbl.preset.equals(preset),
            ))
            .go();

    if (count > 0) {
      await _logChange(_recordId(date, resolved, preset), 'delete');
    }
  }

  Future<bool> updateInflationRate(InflationRatesCompanion rate) async {
    final updatedRate = _withResolvedCountry(
      rate,
    ).copyWith(modifiedAt: Value(DateTime.now().millisecondsSinceEpoch));
    final result = await update(inflationRates).replace(updatedRate);
    await _logChange(
      _recordId(
        updatedRate.date.value,
        updatedRate.country.value,
        updatedRate.preset.value,
      ),
      'upsert',
    );
    return result;
  }

  Future<void> deleteInflationRates(List<InflationRateDomain> rates) async {
    final countries = [for (final rate in rates) _resolveCountry(rate.country)];

    await batch((batch) {
      for (var i = 0; i < rates.length; i++) {
        batch.delete(
          inflationRates,
          InflationRatesCompanion(
            date: Value(rates[i].date),
            country: Value(countries[i]),
            preset: Value(rates[i].preset),
          ),
        );
      }
    });

    await _logChanges([
      for (var i = 0; i < rates.length; i++)
        _recordId(rates[i].date, countries[i], rates[i].preset),
    ], 'delete');
  }

  Future<List<String>> getAvailableCountries() async {
    // The worldwide series is not a country, so it must not reach the country
    // filter or the default-country picker.
    final query = selectOnly(inflationRates, distinct: true)
      ..addColumns([inflationRates.country])
      ..where(inflationRates.country.isNotValue(globalInflationCountry));

    final results = await query
        .map((row) => row.read(inflationRates.country))
        .get();
    return results.whereType<String>().toList();
  }

  Future<int> getInflationRatesCount({
    DateTime? dateFrom,
    DateTime? dateTo,
    List<String>? countries,
    List<int>? presets,
  }) async {
    final query = selectOnly(inflationRates);

    if (dateFrom != null) {
      query.where(inflationRates.date.isBiggerOrEqualValue(dateFrom));
    }
    if (dateTo != null) {
      query.where(inflationRates.date.isSmallerOrEqualValue(dateTo));
    }

    if (countries != null && countries.isNotEmpty) {
      query.where(inflationRates.country.isIn(countries));
    }
    if (presets != null && presets.isNotEmpty) {
      query.where(inflationRates.preset.isIn(presets));
    }

    final countExp = inflationRates.preset
        .count(); // Using preset or date or any non-null col
    query.addColumns([countExp]);
    final count = await query
        .map((row) => row.read(countExp))
        .getSingleOrNull();
    return count ?? 0;
  }

  Future<List<int>> getAvailablePresets() async {
    final query = selectOnly(inflationRates, distinct: true)
      ..addColumns([inflationRates.preset])
      ..where(inflationRates.preset.isNotNull());

    final results = await query
        .map((row) => row.read(inflationRates.preset))
        .get();
    return results.whereType<int>().toList();
  }

  /// The UI models a worldwide rate as an absent country; the column stores
  /// [globalInflationCountry] so the primary key can actually catch a repeat.
  static String _resolveCountry(String? country) =>
      country == null || country.isEmpty ? globalInflationCountry : country;

  static InflationRatesCompanion _withResolvedCountry(
    InflationRatesCompanion rate,
  ) => rate.copyWith(
    country: Value(
      _resolveCountry(rate.country.present ? rate.country.value : null),
    ),
  );

  static String _recordId(DateTime date, String country, int preset) =>
      '${DateFormat('yyyy-MM-dd', 'en').format(date)}_${country}_$preset';

  Future<void> _logChange(String recordId, String action) async {
    await into(db.syncLog).insert(
      SyncLogCompanion(
        changedTableName: const Value('inflation_rates'),
        recordId: Value(recordId),
        action: Value(action),
        timestamp: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> _logChanges(List<String> recordIds, String action) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await batch((batch) {
      batch.insertAll(
        db.syncLog,
        recordIds
            .map(
              (id) => SyncLogCompanion(
                changedTableName: const Value('inflation_rates'),
                recordId: Value(id),
                action: Value(action),
                timestamp: Value(timestamp),
              ),
            )
            .toList(),
      );
    });
  }
}

@DriftAccessor(tables: [AssetEntries, SyncLog])
class AssetEntriesDao extends DatabaseAccessor<AppDatabase>
    with _$AssetEntriesDaoMixin {
  AssetEntriesDao(super.db);

  Future<List<AssetEntry>> getAllAssetEntries() =>
      (select(assetEntries)..where((t) => t.isDeleted.equals(false))).get();
  Stream<List<AssetEntry>> watchAllAssetEntries() =>
      (select(assetEntries)..where((t) => t.isDeleted.equals(false))).watch();

  Future<AssetEntry?> getAssetEntryById(String id) =>
      (select(assetEntries)
            ..where((t) => t.id.equals(id) & t.isDeleted.equals(false)))
          .getSingleOrNull();

  Future<List<AssetEntry>> getAssetEntriesByIds(List<String> ids) async {
    final results = <AssetEntry>[];
    for (final chunk in _sqlChunks(ids)) {
      results.addAll(
        await (select(
          assetEntries,
        )..where((t) => t.id.isIn(chunk) & t.isDeleted.equals(false))).get(),
      );
    }
    return results;
  }

  Future<List<AssetEntry>> getAssetData({
    int limit = 50,
    int offset = 0,
    String? assetId,
    String? accountId, // Added
    DateTime? startDate,
    DateTime? endDate,
    String? name,
    List<String>? assetTypes,
    String? description,
    List<String>? currencyCodes,
    List<String>? sources,
    List<int>? presets,
    double? minValue,
    double? maxValue,
    OrderingMode sort = OrderingMode.desc,
  }) {
    final query = select(assetEntries)..where((t) => t.isDeleted.equals(false));
    if (assetId != null) {
      query.where((t) => t.assetId.equals(assetId));
    }
    if (accountId != null) {
      query.where((t) => t.accountId.equals(accountId));
    }
    if (startDate != null) {
      query.where((t) => t.date.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      query.where((t) => t.date.isSmallerOrEqualValue(endDate));
    }

    if (name != null && name.isNotEmpty) {
      query.where((t) => t.name.like('%$name%'));
    }
    if (assetTypes != null && assetTypes.isNotEmpty) {
      query.where((t) => t.assetType.isIn(assetTypes));
    }
    if (description != null && description.isNotEmpty) {
      query.where((t) => t.description.like('%$description%'));
    }
    if (currencyCodes != null && currencyCodes.isNotEmpty) {
      query.where((t) => t.currencyCode.isIn(currencyCodes));
    }
    if (sources != null && sources.isNotEmpty) {
      query.where((t) => t.source.isIn(sources));
    }
    if (presets != null && presets.isNotEmpty) {
      query.where((t) => t.preset.isIn(presets));
    }
    if (minValue != null) {
      query.where((t) => t.value.isBiggerOrEqualValue(minValue));
    }
    if (maxValue != null) {
      query.where((t) => t.value.isSmallerOrEqualValue(maxValue));
    }

    // The sort column is not unique, and `LIMIT`/`OFFSET` asks for the
    // pages in separate queries: rows that tie on it have no order to keep
    // between one page and the next, so a tie broken differently the second
    // time repeats a row the user already saw and drops one they never will.
    // The row's own key is the tiebreak that makes the order total.
    query.orderBy([
      (t) => OrderingTerm(expression: t.date, mode: sort),
      (t) => OrderingTerm(expression: t.id, mode: sort),
    ]);
    query.limit(limit, offset: offset);

    return query.get();
  }

  Stream<List<AssetEntry>> watchAssetData({
    int limit = 50,
    int offset = 0,
    String? assetId,
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
    String? name,
    List<String>? assetTypes,
    String? description,
    List<String>? currencyCodes,
    List<String>? sources,
    List<int>? presets,
    double? minValue,
    double? maxValue,
    OrderingMode sort = OrderingMode.desc,
  }) {
    final query = select(assetEntries)..where((t) => t.isDeleted.equals(false));
    if (assetId != null) {
      query.where((t) => t.assetId.equals(assetId));
    }
    if (accountId != null) {
      query.where((t) => t.accountId.equals(accountId));
    }
    if (startDate != null) {
      query.where((t) => t.date.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      query.where((t) => t.date.isSmallerOrEqualValue(endDate));
    }

    if (name != null && name.isNotEmpty) {
      query.where((t) => t.name.like('%$name%'));
    }
    if (assetTypes != null && assetTypes.isNotEmpty) {
      query.where((t) => t.assetType.isIn(assetTypes));
    }
    if (description != null && description.isNotEmpty) {
      query.where((t) => t.description.like('%$description%'));
    }
    if (currencyCodes != null && currencyCodes.isNotEmpty) {
      query.where((t) => t.currencyCode.isIn(currencyCodes));
    }
    if (sources != null && sources.isNotEmpty) {
      query.where((t) => t.source.isIn(sources));
    }
    if (presets != null && presets.isNotEmpty) {
      query.where((t) => t.preset.isIn(presets));
    }
    if (minValue != null) {
      query.where((t) => t.value.isBiggerOrEqualValue(minValue));
    }
    if (maxValue != null) {
      query.where((t) => t.value.isSmallerOrEqualValue(maxValue));
    }

    // The sort column is not unique, and `LIMIT`/`OFFSET` asks for the
    // pages in separate queries: rows that tie on it have no order to keep
    // between one page and the next, so a tie broken differently the second
    // time repeats a row the user already saw and drops one they never will.
    // The row's own key is the tiebreak that makes the order total.
    query.orderBy([
      (t) => OrderingTerm(expression: t.date, mode: sort),
      (t) => OrderingTerm(expression: t.id, mode: sort),
    ]);
    query.limit(limit, offset: offset);

    return query.watch();
  }

  Future<int> getAssetDataCount({
    String? assetId,
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
    String? name,
    List<String>? assetTypes,
    String? description,
    List<String>? currencyCodes,
    List<String>? sources,
    List<int>? presets,
    double? minValue,
    double? maxValue,
  }) async {
    final query = selectOnly(assetEntries)
      ..where(assetEntries.isDeleted.equals(false));
    if (assetId != null) {
      query.where(assetEntries.assetId.equals(assetId));
    }
    if (accountId != null) {
      query.where(assetEntries.accountId.equals(accountId));
    }
    if (startDate != null) {
      query.where(assetEntries.date.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      query.where(assetEntries.date.isSmallerOrEqualValue(endDate));
    }

    if (name != null && name.isNotEmpty) {
      query.where(assetEntries.name.like('%$name%'));
    }
    if (assetTypes != null && assetTypes.isNotEmpty) {
      query.where(assetEntries.assetType.isIn(assetTypes));
    }
    if (description != null && description.isNotEmpty) {
      query.where(assetEntries.description.like('%$description%'));
    }
    if (currencyCodes != null && currencyCodes.isNotEmpty) {
      query.where(assetEntries.currencyCode.isIn(currencyCodes));
    }
    if (sources != null && sources.isNotEmpty) {
      query.where(assetEntries.source.isIn(sources));
    }
    if (presets != null && presets.isNotEmpty) {
      query.where(assetEntries.preset.isIn(presets));
    }
    if (minValue != null) {
      query.where(assetEntries.value.isBiggerOrEqualValue(minValue));
    }
    if (maxValue != null) {
      query.where(assetEntries.value.isSmallerOrEqualValue(maxValue));
    }

    final countExp = assetEntries.id.count();
    query.addColumns([countExp]);
    final count = await query
        .map((row) => row.read(countExp))
        .getSingleOrNull();
    return count ?? 0;
  }

  Future<void> addAssetData(AssetEntriesCompanion data) async {
    var toInsert = data.id.present
        ? data
        : data.copyWith(id: Value(_uuid.v4()));

    toInsert = toInsert.copyWith(
      modifiedAt: Value(DateTime.now().millisecondsSinceEpoch),
    );

    await into(assetEntries).insert(toInsert);
    await _logChange(toInsert.id.value, 'upsert');
  }

  /// Upsert (insert or replace) an asset entry by its ID.
  /// Used by custom_api imports with a deterministic ID to prevent duplicates.
  Future<void> upsertAssetData(AssetEntriesCompanion data) async {
    var toInsert = data.id.present
        ? data
        : data.copyWith(id: Value(_uuid.v4()));

    toInsert = toInsert.copyWith(
      modifiedAt: Value(DateTime.now().millisecondsSinceEpoch),
    );

    await into(assetEntries).insert(toInsert, mode: InsertMode.insertOrReplace);
    await _logChange(toInsert.id.value, 'upsert');
  }

  Future<void> insertSyncedAssetEntry(AssetEntriesCompanion entry) =>
      into(assetEntries).insert(entry, mode: InsertMode.insertOrReplace);

  Future<void> updateAssetData(AssetEntriesCompanion data) async {
    final updatedData = data.copyWith(
      modifiedAt: Value(DateTime.now().millisecondsSinceEpoch),
    );
    // `replace` writes the column default for every column the companion
    // omits, and AssetDataMapper.toCompanion never sets `isDeleted`. The
    // custom-API refresh at intilization_data.dart updates entries in a loop,
    // so a single stale entry was enough to bring a deleted holding back into
    // the portfolio - and the fresh `modifiedAt` carried it to every peer.
    final count = await (update(
      assetEntries,
    )..where((t) => t.id.equals(updatedData.id.value))).write(updatedData);
    if (count > 0) {
      await _logChange(data.id.value, 'upsert');
    }
  }

  Future<int> deleteAssetEntry(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final result = await (update(assetEntries)..where((t) => t.id.equals(id)))
        .write(
          AssetEntriesCompanion(
            isDeleted: const Value(true),
            modifiedAt: Value(now),
          ),
        );
    if (result > 0) {
      await _logChange(id, 'delete');
    }
    return result;
  }

  Future<void> deleteAssets(List<String> ids) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (update(assetEntries)..where((tbl) => tbl.id.isIn(ids))).write(
      AssetEntriesCompanion(
        isDeleted: const Value(true),
        modifiedAt: Value(now),
      ),
    );
    await _logChanges(ids, 'delete');
  }

  Future<void> _logChange(String recordId, String action) async {
    await into(db.syncLog).insert(
      SyncLogCompanion(
        changedTableName: const Value('asset_entries'),
        recordId: Value(recordId),
        action: Value(action),
        timestamp: Value(DateTime.now().millisecondsSinceEpoch),
        exported: const Value(false),
      ),
    );
  }

  Future<void> _logChanges(List<String> recordIds, String action) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await batch((batch) {
      batch.insertAll(
        db.syncLog,
        recordIds
            .map(
              (id) => SyncLogCompanion(
                changedTableName: const Value('asset_entries'),
                recordId: Value(id),
                action: Value(action),
                timestamp: Value(timestamp),
                exported: const Value(false),
              ),
            )
            .toList(),
      );
    });
  }

  Future<List<String>> getAvailableAssetIds() async {
    final query = selectOnly(assetEntries, distinct: true)
      ..addColumns([assetEntries.assetId]);

    final results = await query
        .map((row) => row.read(assetEntries.assetId))
        .get();
    return results.whereType<String>().toList();
  }

  Future<List<String>> getAvailableAssetTypes() async {
    final query = selectOnly(assetEntries, distinct: true)
      ..addColumns([assetEntries.assetType])
      ..where(assetEntries.assetType.isNotNull());

    final results = await query
        .map((row) => row.read(assetEntries.assetType))
        .get();
    return results.whereType<String>().toList();
  }

  Future<List<String>> getAvailableSources() async {
    final query = selectOnly(assetEntries, distinct: true)
      ..addColumns([assetEntries.source])
      ..where(assetEntries.source.isNotNull());

    final results = await query
        .map((row) => row.read(assetEntries.source))
        .get();
    return results.whereType<String>().toList();
  }

  Future<List<int>> getAvailablePresets() async {
    final query = selectOnly(assetEntries, distinct: true)
      ..addColumns([assetEntries.preset])
      ..where(assetEntries.preset.isNotNull());

    final results = await query
        .map((row) => row.read(assetEntries.preset))
        .get();
    return results.whereType<int>().toList();
  }
}

@DriftDatabase(
  tables: [
    Languages,
    CurrencyDesignations,
    Currencies,
    Categories,
    Styles,
    AccountTypes,
    Accounts,
    Transactions,
    ExchangeRates,
    InflationRates,
    AssetEntries,
    Settings,
    CustomThemes,
    ApiFetchStatuses,
    ApiSettingsTable,
    SmsPresets,
    SyncProcessedFiles,
    SyncLog,
    SyncPushQueue,
    ConflictHistory,
    CustomDataSources,
  ],
  daos: [
    LanguageDao,
    CurrencyDesignationsDao,
    CurrenciesDao,
    CategoriesDao,
    StylesDao,
    AccountTypesDao,
    AccountsDao,
    TransactionsDao,
    ExchangeRatesDao,
    InflationRatesDao,
    AssetEntriesDao,
    SettingsDao,
    CustomThemesDao,
    ApiFetchStatusesDao,
    SmsPresetsDao,
    SyncLogDao,
    ConflictHistoryDao,
    CustomDataSourcesDao,
    ApiSettingsDao,
    SyncProcessedFilesDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  AppDatabase.forTesting(super.connection);

  /// Whether creating a database seeds the shipped exchange-rate history.
  ///
  /// Always true in the app: without the seed a new install has no rate for
  /// any pair and every foreign-currency screen is empty. It is a switch only
  /// because of what the seed costs. Each seeded database reads a 6.8 MB JSON
  /// file, parses it in a spawned isolate and inserts roughly 283,000 rows -
  /// tolerable once at install, ruinous in a test suite that builds a fresh
  /// database 146 times, several of those per test rather than per file.
  ///
  /// `test/flutter_test_config.dart` turns it off for every test file, and the
  /// handful of suites that actually read seeded rates turn it back on for
  /// themselves. Those suites are the ones that pin this behaviour: a test
  /// asserting on seeded data fails loudly with the seed off, it does not
  /// quietly pass on an empty table.
  @visibleForTesting
  static bool seedExchangeRatesOnCreate = true;

  /// Whether [table] already has [column], so a migration step that adds it can
  /// be re-run after an upgrade that was interrupted halfway.
  Future<bool> _hasColumn(String table, String column) async {
    final rows = await customSelect('PRAGMA table_info($table)').get();
    return rows.any((r) => r.read<String>('name') == column);
  }

  /// The tables this database actually has right now.
  ///
  /// The push-queue triggers are created from a fixed list, but a database
  /// halfway through the upgrade chain (or a fixture that only carries the
  /// tables its test needs) may not have all of them yet, and
  /// `CREATE TRIGGER ... ON <missing table>` fails the whole migration.
  Future<Set<String>> _existingTables() async {
    final rows = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    ).get();
    return rows.map((r) => r.read<String>('name')).toSet();
  }

  /// Puts a row in [SyncPushQueue] on every insert and every real edit of a
  /// synced table.
  ///
  /// Triggers rather than call sites — mirroring the `server_seq` trigger the
  /// server stamps its own rows with — because the rows that went missing were
  /// precisely the ones written by paths that never called the sync bookkeeping:
  /// the pull's raw upserts, the file engine's `INSERT OR REPLACE` imports, the
  /// importer's bulk writes. A trigger cannot be forgotten by a write path that
  /// has not been written yet.
  Future<void> _createSyncPushQueueTriggers() async {
    final existing = await _existingTables();
    for (final table in syncPushQueueTables) {
      if (!existing.contains(table)) continue;
      final key = syncPushQueueKeyExpression(table, prefix: 'NEW.');
      const target =
          'INSERT INTO sync_push_queue (changed_table_name, record_key) VALUES';
      await customStatement(
        'CREATE TRIGGER IF NOT EXISTS trg_push_queue_${table}_insert '
        'AFTER INSERT ON $table BEGIN '
        "$target ('$table', $key); END",
      );
      // Recreated rather than left alone: this trigger's WHEN clause changed
      // in v15, and `CREATE TRIGGER IF NOT EXISTS` would keep the old body
      // forever on every database that already had one.
      await customStatement(
        'DROP TRIGGER IF EXISTS trg_push_queue_${table}_update',
      );
      await customStatement(
        'CREATE TRIGGER trg_push_queue_${table}_update '
        'AFTER UPDATE ON $table '
        'WHEN ${await _pushQueueUpdateCondition(table)} '
        "BEGIN $target ('$table', $key); END",
      );
    }
  }

  /// Stamps every row this device writes with its own sync identity.
  ///
  /// `device_id` is the second half of the `(modified_at, device_id)` total
  /// order that decides a conflict, and no write path ever filled it: every
  /// locally authored row carried NULL. Both tie-breaks read a NULL author as
  /// the empty string, so two devices that edited the same row within the same
  /// millisecond compared `'' > ''` - false on both sides and on the server.
  /// Each end kept its own version, the push was answered 200 without an
  /// UPDATE, `server_seq` never moved, and no later sync ever offered either
  /// version again: a permanently and silently divergent row. It needs no
  /// clock coincidence to happen, because the whole seeded catalogue ships
  /// with `modified_at = 1` and locale-dependent names.
  ///
  /// Triggers rather than call sites, for the same reason
  /// [_createSyncPushQueueTriggers] gives: there are ~67 places that write a
  /// synced row and a new one is added every week, while a trigger cannot be
  /// forgotten by a path nobody has written yet.
  ///
  /// A write that names an author keeps it - that is how a row applied from a
  /// peer or pulled from the server stays attributed to the device that really
  /// made the edit, which is what makes both ends of a comparison name the
  /// same two devices. The update trigger fires only when the writer left
  /// `device_id` exactly as it found it while moving `modified_at`, which is
  /// the signature of a local edit.
  Future<void> _createDeviceIdTriggers() async {
    final existing = await _existingTables();
    for (final table in syncPushQueueTables) {
      if (!existing.contains(table)) continue;
      if (!await _hasColumn(table, 'device_id')) continue;
      // Addressed by rowid, so one body serves the tables keyed by a single
      // column and the ones keyed by four.
      final stamp =
          'UPDATE $table SET device_id = $_localDeviceIdSql '
          'WHERE rowid = NEW.rowid;';
      await customStatement(
        'DROP TRIGGER IF EXISTS trg_device_id_${table}_insert',
      );
      await customStatement(
        'CREATE TRIGGER trg_device_id_${table}_insert '
        'AFTER INSERT ON $table '
        'WHEN NEW.device_id IS NULL AND $_localDeviceIdSql IS NOT NULL '
        'BEGIN $stamp END',
      );
      await customStatement(
        'DROP TRIGGER IF EXISTS trg_device_id_${table}_update',
      );
      if (!await _hasColumn(table, 'modified_at')) continue;
      await customStatement(
        'CREATE TRIGGER trg_device_id_${table}_update '
        'AFTER UPDATE ON $table '
        'WHEN NEW.device_id IS OLD.device_id '
        'AND NEW.modified_at IS NOT OLD.modified_at '
        'AND $_localDeviceIdSql IS NOT NULL '
        'AND NEW.device_id IS NOT $_localDeviceIdSql '
        'BEGIN $stamp END',
      );
    }
  }

  /// Puts this device's identity on the seeded rows that predate the triggers.
  ///
  /// Only [syncPushQueueSeedTables]: those are the rows that ship with
  /// `modified_at = 1` and a name translated per locale, so they are exactly
  /// the ones two devices disagree about with no clock to separate them. The
  /// bulk reference tables are left alone deliberately - ~283k exchange rates
  /// carry the same numbers on every install, so a tie there resolves to two
  /// copies of the same value, and stamping them would queue the lot for
  /// upload.
  ///
  /// The push-queue triggers see this as the content edit it is and queue the
  /// rows, which is what carries the new stamp to the server; without that the
  /// device would keep winning ties locally against a server copy it never
  /// corrected.
  @visibleForTesting
  Future<void> stampSeededRowsWithLocalDeviceId() async {
    final existing = await _existingTables();
    for (final table in syncPushQueueSeedTables) {
      if (!existing.contains(table)) continue;
      if (!await _hasColumn(table, 'device_id')) continue;
      await customStatement(
        'UPDATE $table SET device_id = $_localDeviceIdSql '
        'WHERE device_id IS NULL AND $_localDeviceIdSql IS NOT NULL',
      );
    }
  }

  /// Queues every existing row of [syncPushQueueSeedTables] for upload.
  ///
  /// Runs on a fresh install and once more on the upgrade to v16, so a device
  /// created before the fix is repaired rather than left stuck. Skips a table
  /// this database does not have yet - a migration test builds partial
  /// schemas - and is safe to run twice: a duplicate queue entry costs one
  /// deduped record key in the next push.
  @visibleForTesting
  Future<void> seedPushQueueParents() =>
      _queueRowsForPush(syncPushQueueSeedTables);

  /// Queues every existing row of every synced table for upload.
  ///
  /// The queue records what the server has NOT been told, so it is empty on a
  /// device that has synced everything it has - which is exactly the state a
  /// device is in when the server's own copy is thrown away. Nothing else can
  /// repopulate that server: the rows are not owed, so they are never offered
  /// again, and the server stays empty for good.
  ///
  /// Costs one full upload, the same one-off price the v12 to v13 upgrade paid
  /// when it seeded the queue from the same list. Safe to run twice - the push
  /// de-duplicates by record key - and safe to run with rows already queued,
  /// which then simply go out in the same pass.
  Future<void> queueEverythingForPush() =>
      _queueRowsForPush(syncPushQueueTables);

  /// Inserts one queue entry per existing row of each of [tables].
  ///
  /// Skips a table this database does not have yet - a migration test builds
  /// partial schemas.
  Future<void> _queueRowsForPush(List<String> tables) async {
    final existing = await _existingTables();
    for (final table in tables) {
      if (!existing.contains(table)) continue;
      // Resending everything must not put back what the v20 to v21 upgrade
      // took out. The bundled rate history is identical on every install, so
      // uploading it tells the server nothing another client would not have
      // supplied byte for byte - and it is ~283k of the ~284k rows this loop
      // would otherwise queue, which is the backlog itself, rebuilt.
      final filter = table == 'exchange_rates'
          ? ' WHERE NOT ($seededExchangeRatesFilter)'
          : '';
      await customStatement(
        'INSERT INTO sync_push_queue (changed_table_name, record_key) '
        "SELECT '$table', ${syncPushQueueKeyExpression(table)} "
        'FROM $table$filter',
      );
    }
  }

  /// The `WHEN` clause of [table]'s update trigger: did this UPDATE change
  /// anything a peer has to be told about?
  ///
  /// v13 asked only `NEW.modified_at IS NOT OLD.modified_at`, which is not the
  /// same question. Two writes to one row inside the same millisecond carry the
  /// same stamp, so the second one queued nothing and never left the device —
  /// and the case that matters is not exotic: seeding a row and deleting it in
  /// the same millisecond is a tombstone that no peer and no server ever hears
  /// about, because the row they are missing is one they have never been
  /// offered. It is what makes
  /// `test/core/sync/sync_service_api_settings_test.dart` "a locally deleted
  /// provider is pushed with its tombstone flag" fail perhaps one run in three.
  ///
  /// So the test is on the CONTENT: any column other than `modified_at`,
  /// `device_id` and the [syncPushQueueDerivedColumns] each device computes for
  /// itself.
  ///
  /// `device_id` is out because [_createDeviceIdTriggers] writes it in a second
  /// statement, right after the one that queued the row: counting it queued
  /// every insert twice. Nothing is lost - the push reads the row as it stands
  /// when it runs, so it carries the stamp, and an edit that re-stamps a row
  /// moved `modified_at` to get there. A stamp written on its own, by
  /// [stampSeededRowsWithLocalDeviceId], is queued by that method's caller
  /// instead. `IS NOT`
  /// rather than `<>`, because `<>` is NULL — never true — the moment either
  /// side is NULL, which is precisely the insert-a-value-into-an-empty-column
  /// edit that most needs to travel.
  ///
  /// Read from `PRAGMA table_info` rather than a hand-kept list: a column added
  /// by a later migration is a column whose edits must queue, and nobody will
  /// remember to add it here.
  Future<String> _pushQueueUpdateCondition(String table) async {
    final derived = syncPushQueueDerivedColumns[table] ?? const <String>{};
    final info = await customSelect("PRAGMA table_info('$table')").get();
    final columns = [
      for (final row in info)
        if (row.read<String>('name') != 'modified_at' &&
            row.read<String>('name') != 'device_id' &&
            !derived.contains(row.read<String>('name')))
          row.read<String>('name'),
    ];
    return [
      'NEW.modified_at IS NOT OLD.modified_at',
      for (final column in columns) 'NEW.$column IS NOT OLD.$column',
    ].join(' OR ');
  }

  /// Indexes the push key of the tables whose [syncPushQueueKeyExpression] is a
  /// concatenation, so the push can find a queued row again without reading the
  /// whole table.
  ///
  /// `_pushQueuedTable` resolves a batch with that same expression on the left
  /// of an `IN (?, …)` list, 500 keys at a time. On a bare column that rides
  /// the primary key's index; on a concatenation SQLite has nothing to match
  /// and scans the table — once per chunk, and `exchange_rates` ships with
  /// ~283 000 rows that the v12→v13 step queues in one go, so a first push
  /// after the upgrade scanned it 600 times before uploading a byte.
  ///
  /// The index expression is rendered by the same function the query uses, and
  /// deliberately so: SQLite only matches an expression index when the query's
  /// expression parses to the same thing, so a second, hand-copied spelling of
  /// the key would be an index that exists and is never used.
  Future<void> _createSyncPushQueueKeyIndexes() async {
    final existing = await _existingTables();
    for (final table in syncPushQueueTables) {
      final indexName = syncPushQueueKeyIndexName(table);
      if (indexName == null || !existing.contains(table)) continue;
      await customStatement(
        'CREATE INDEX IF NOT EXISTS $indexName '
        'ON $table (${syncPushQueueKeyExpression(table)})',
      );
    }
  }

  /// The two lookups every asset account costs, given an index to seek on.
  ///
  /// `asset_entries` shipped with no index at all beyond its primary key, and
  /// its only declared index is the partial `custom_api` dedup one, which no
  /// read uses. Every `getAssetData` call therefore scanned the whole table -
  /// and the accounts screen makes one such call per asset account, on every
  /// balance switch, so the scan count grows with the number of asset accounts
  /// while the scan itself grows with the entry history behind all of them.
  ///
  /// Both are `(owner, date)` rather than plain `(owner)`: the filter is always
  /// an owner plus a date window or a `date DESC` ordering, so the trailing
  /// column turns the sort into a range read off the same index.
  ///
  /// Written out here rather than as `@TableIndex` for the reason v8->v9 and
  /// v13 both record: drift only builds the annotated indexes in `createAll()`,
  /// which never runs on a database that arrived by upgrade.
  Future<void> _createAssetEntryIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_asset_entries_account_date '
      'ON asset_entries (account_id, date)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_asset_entries_asset_date '
      'ON asset_entries (asset_id, date)',
    );
  }

  /// Collapses transactions that record the same payment twice, keeping one
  /// row of each pair. Returns how many rows were removed.
  ///
  /// "The same payment" is the same account, the same instant, the same
  /// currency and the same amount down to the minor unit. Deliberately not the
  /// description: the whole reason these pairs exist is that the two copies
  /// were written by different importers and disagree about what to call the
  /// merchant. Crypto rows, which carry no exact minor amount, are keyed on
  /// the stored double instead — two copies of one payment hold bit-identical
  /// doubles, so nothing is lost by comparing them exactly.
  ///
  /// The survivor is the copy the user has already worked on: reviewed before
  /// unreviewed, then the older of the two, because the older row is the one
  /// that has been sitting in their history collecting a hand-picked category.
  /// A category the survivor is missing is taken from the copy being removed.
  ///
  /// Removal is the same soft delete the transaction screen performs — the row
  /// is tombstoned, the account balance is adjusted by the amount that is no
  /// longer counted, and both changes are logged for sync — so a pair collapsed
  /// here converges on every device instead of coming back on the next pull.
  ///
  /// Two rows linked to each other are never a pair. That is a transfer whose
  /// two legs landed on one account, and it matches on every field this keys
  /// on — same account, same instant, same amount — while being two halves of
  /// one movement rather than one payment written twice. A transfer that was
  /// itself imported twice is still collapsed: those four rows are two pairs,
  /// and neither copy is linked to the other.
  @visibleForTesting
  Future<int> removeDuplicateTransactions() async {
    // The four fields that define one payment, packed into a single text key so
    // the group-by and the membership test can both be expressed on it.
    const dupKey =
        '''account_id || '|' || date || '|' || currency_code || '|' ||
             CASE WHEN amount_minor IS NOT NULL THEN 'm' || amount_minor
                  ELSE 'r' || amount END''';

    final rows = await customSelect(
      '''
      WITH keyed AS (
        SELECT id, account_id, amount, amount_minor, currency_code,
               category_id, needs_review, modified_at, linked_transaction_id,
               $dupKey AS dup_key
          FROM transactions
         WHERE is_deleted = 0
      )
      SELECT * FROM keyed
       WHERE dup_key IN (
               SELECT dup_key FROM keyed GROUP BY dup_key HAVING COUNT(*) > 1
             )
      ''',
      readsFrom: {transactions},
    ).get();

    if (rows.isEmpty) return 0;

    final groups = <String, List<QueryRow>>{};
    for (final row in rows) {
      groups.putIfAbsent(row.read<String>('dup_key'), () => []).add(row);
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    var removed = 0;

    for (final group in groups.values) {
      group.sort((a, b) {
        // needs_review is an INTEGER here: customSelect has no column type to
        // read it back through.
        final reviewed = a
            .read<int>('needs_review')
            .compareTo(b.read<int>('needs_review'));
        if (reviewed != 0) return reviewed;
        final age = a
            .read<int>('modified_at')
            .compareTo(b.read<int>('modified_at'));
        if (age != 0) return age;
        return a.read<String>('id').compareTo(b.read<String>('id'));
      });

      // Legs of one transfer, sorted into the group because they agree on
      // every field the key is built from. The first row stays; a later one
      // linked to something already kept is a leg and stays with it, and what
      // is left over is the copies.
      final kept = <QueryRow>[group.first];
      final losers = <QueryRow>[];
      for (final row in group.skip(1)) {
        final linked = row.read<String?>('linked_transaction_id');
        final id = row.read<String>('id');
        final isLeg = kept.any(
          (k) =>
              linked == k.read<String>('id') ||
              k.read<String?>('linked_transaction_id') == id,
        );
        (isLeg ? kept : losers).add(row);
      }
      if (losers.isEmpty) continue;

      final survivorId = kept.first.read<String>('id');
      for (final loser in losers) {
        await _removeDuplicateRow(loser, survivorId, now);
        removed++;
      }
    }

    return removed;
  }

  /// Tombstones [loser] as a copy of [survivorId].
  ///
  /// The row is soft-deleted, the account balance gives back the amount the
  /// row was counted for, anything still pointing at the removed row is
  /// re-pointed at the copy that stays, and every change is logged for sync -
  /// so a pair collapsed here converges on every device instead of coming back
  /// on the next pull. Shared by the two dedupe passes.
  Future<void> _removeDuplicateRow(
    QueryRow loser,
    String survivorId,
    int now,
  ) async {
    final loserId = loser.read<String>('id');
    final amount = loser.read<double>('amount');
    final accountId = loser.read<String>('account_id');
    final currencyCode = loser.read<String>('currency_code');

    await customUpdate(
      'UPDATE transactions SET is_deleted = 1, modified_at = ? WHERE id = ?',
      variables: [Variable(now), Variable(loserId)],
      updates: {transactions},
    );
    await _logMigrationChange('transactions', loserId, 'delete', now);

    // Same statement adjustBalance issues, with the sign flipped: the stored
    // balance counted this row, and after the tombstone it must not.
    await customUpdate(
      'UPDATE accounts SET balance = balance - ?, '
      'balance_minor = balance_minor - '
      'CAST(ROUND(? * ($kMinorScaleCase)) AS INTEGER), '
      'modified_at = ? WHERE id = ? AND currency_code = ?',
      variables: [
        Variable(amount),
        Variable(amount),
        Variable(now),
        Variable(accountId),
        Variable(currencyCode),
      ],
      updates: {accounts},
    );
    await _logMigrationChange('accounts', accountId, 'upsert', now);

    // Whatever still points at the removed row is pointed at the copy that
    // stays: a transfer whose two legs were both duplicated would otherwise
    // keep one leg linked to a tombstone.
    await customUpdate(
      'UPDATE transactions SET linked_transaction_id = ?, modified_at = ? '
      'WHERE linked_transaction_id = ? AND is_deleted = 0 AND id != ?',
      variables: [
        Variable(survivorId),
        Variable(now),
        Variable(loserId),
        Variable(survivorId),
      ],
      updates: {transactions},
    );
  }

  /// The widest clock disagreement two importers are collapsed across.
  ///
  /// The offsets actually observed are whole hours - a time zone applied twice
  /// - and the largest of them is four, from a summer offset of +2 doubled.
  /// Twelve leaves room for the zones this app is used from without reaching
  /// the far side of a day.
  static const _clockShiftWindow = Duration(hours: 12);

  /// Collapses transactions that record the same payment twice with the two
  /// copies timestamped by clocks that disagree, keeping one row of each pair.
  /// Returns how many rows were removed.
  ///
  /// [removeDuplicateTransactions] keys on the instant exactly, which is what
  /// two copies of one message agree on when both importers read the same
  /// timestamp the same way. They do not always: 55 pairs on the database this
  /// was written against are the same account, the same currency and the same
  /// amount to the minor unit, sitting exactly two hours apart before the
  /// spring clock change and exactly four hours apart after it - one importer
  /// applying the zone offset that the other had already applied. Every one of
  /// them is counted twice in every total, including three months of salary.
  ///
  /// A pair is the same account, the same currency, the same amount, and a gap
  /// that is either at most two seconds - two messages about one payment
  /// arriving back to back - or an exact whole number of hours up to
  /// [_clockShiftWindow]. Whole seconds are what makes this safe: two genuine
  /// payments of the same size on one card land 7200 seconds apart to the
  /// second essentially never, while a re-applied zone offset lands there every
  /// time.
  ///
  /// "The same amount" allows the two copies to disagree in the last bits of
  /// the double. One of the two importers rounds through a 32-bit float, so a
  /// salary stored as 165261.21 by one is 165261.203125 by the other; the
  /// minor units are compared with a slack of one for the same reason. The
  /// doubles still have to agree to within a millionth, which is far tighter
  /// than the smallest gap between two real amounts.
  ///
  /// Rows already linked to another transaction are left alone: a leg of a
  /// transfer is half of one movement rather than a copy of a payment, and
  /// removing one would leave the other pointing at a tombstone and the
  /// balance short by the amount removed.
  ///
  /// The survivor is the copy the user has already worked on - reviewed before
  /// unreviewed - and then the copy that says something: one importer writes
  /// the bank's own name into every description while the other writes the
  /// merchant's, and keeping "Alta_Bank" over "LIDL 128 BEOGRA" would lose the
  /// only thing that tells two payments apart in a list. Removal is the same
  /// soft delete [removeDuplicateTransactions] performs.
  @visibleForTesting
  Future<int> removeClockShiftedDuplicates() async {
    final rows = await customSelect(
      '''
      SELECT id, account_id, date, amount, amount_minor, currency_code,
             description, needs_review, modified_at
        FROM transactions
       WHERE is_deleted = 0
         AND (linked_transaction_id IS NULL OR linked_transaction_id = '')
       ORDER BY account_id, date, id
      ''',
      readsFrom: {transactions},
    ).get();
    if (rows.length < 2) return 0;

    final accountNames = await _accountNamesById();
    final windowSeconds = _clockShiftWindow.inSeconds;

    // Keyed on the row every copy is a copy of, so a payment written three
    // times still collapses onto one survivor.
    final groups = <String, List<QueryRow>>{};
    final taken = <String>{};

    for (var i = 0; i < rows.length; i++) {
      final left = rows[i];
      final leftId = left.read<String>('id');
      if (taken.contains(leftId)) continue;
      final accountId = left.read<String>('account_id');
      final date = left.read<int>('date');

      for (var j = i + 1; j < rows.length; j++) {
        final right = rows[j];
        // Ordered by account then date, so once either runs past the row being
        // matched there is nothing further along that can match it.
        if (right.read<String>('account_id') != accountId) break;
        final gap = right.read<int>('date') - date;
        if (gap > windowSeconds) break;
        if (!_isClockShift(gap)) continue;

        final rightId = right.read<String>('id');
        if (taken.contains(rightId)) continue;
        if (right.read<String>('currency_code') !=
            left.read<String>('currency_code')) {
          continue;
        }
        if (!_sameAmount(left, right)) continue;

        groups.putIfAbsent(leftId, () => [left]).add(right);
        taken.add(leftId);
        taken.add(rightId);
      }
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    var removed = 0;

    for (final group in groups.values) {
      group.sort((a, b) => _duplicateSurvivorOrder(a, b, accountNames));

      final survivorId = group.first.read<String>('id');
      for (final loser in group.skip(1)) {
        await _removeDuplicateRow(loser, survivorId, now);
        removed++;
      }
    }

    return removed;
  }

  /// Whether a gap of [seconds] between two otherwise identical rows is two
  /// clocks disagreeing rather than two payments. See
  /// [removeClockShiftedDuplicates].
  bool _isClockShift(int seconds) {
    if (seconds <= 0) return false;
    if (seconds <= 2) return true;
    return seconds % Duration.secondsPerHour == 0;
  }

  /// Whether two rows carry the same amount, allowing for one of them having
  /// been rounded through a 32-bit float. See [removeClockShiftedDuplicates].
  bool _sameAmount(QueryRow left, QueryRow right) {
    final leftMinor = left.read<int?>('amount_minor');
    final rightMinor = right.read<int?>('amount_minor');
    if (leftMinor != null &&
        rightMinor != null &&
        (leftMinor - rightMinor).abs() > 1) {
      return false;
    }

    final leftAmount = left.read<double>('amount');
    final rightAmount = right.read<double>('amount');
    if (leftAmount == rightAmount) return true;
    final size = leftAmount.abs() >= rightAmount.abs()
        ? leftAmount.abs()
        : rightAmount.abs();
    if (size == 0) return false;
    return (leftAmount - rightAmount).abs() <= size * 1e-6;
  }

  /// Orders two copies of one payment so the first is the one worth keeping:
  /// reviewed before unreviewed, a description the user can read before the
  /// bank's own name, then the older row and finally the id so the order is
  /// total. See [removeClockShiftedDuplicates].
  int _duplicateSurvivorOrder(
    QueryRow a,
    QueryRow b,
    Map<String, String> accountNames,
  ) {
    // needs_review is an INTEGER here: customSelect has no column type to read
    // it back through.
    final reviewed = a
        .read<int>('needs_review')
        .compareTo(b.read<int>('needs_review'));
    if (reviewed != 0) return reviewed;

    final aNames = _describesPayee(a, accountNames) ? 1 : 0;
    final bNames = _describesPayee(b, accountNames) ? 1 : 0;
    if (aNames != bNames) return bNames - aNames;

    final age = a
        .read<int>('modified_at')
        .compareTo(b.read<int>('modified_at'));
    if (age != 0) return age;
    return a.read<String>('id').compareTo(b.read<String>('id'));
  }

  /// Whether [row]'s description says something beyond which account the money
  /// moved on. See [removeClockShiftedDuplicates].
  bool _describesPayee(QueryRow row, Map<String, String> accountNames) {
    final description = row.read<String?>('description')?.trim() ?? '';
    if (description.isEmpty || description == '-') return false;
    return description != accountNames[row.read<String>('account_id')];
  }

  /// Every account's name, keyed by id.
  Future<Map<String, String>> _accountNamesById() async {
    final rows = await customSelect(
      'SELECT id, name FROM accounts',
      readsFrom: {accounts},
    ).get();
    return {
      for (final row in rows) row.read<String>('id'): row.read<String>('name'),
    };
  }

  /// How far apart the two halves of one movement of money can sit and still be
  /// recognised as a pair. A bank sends one message per leg and the import
  /// timestamps each row from its own message; the gaps observed on real data
  /// are one to three seconds, and the widest sane reading of "the same moment"
  /// is what this wants to be.
  static const _transferPairWindow = Duration(seconds: 120);

  /// Links pairs of rows that are the two halves of one movement of money, so
  /// that neither half is counted as income or as expense. Returns the number
  /// of pairs linked.
  ///
  /// One movement looks like this in the table: an amount leaves an account and
  /// the same amount arrives back on it a second or two later, with nothing
  /// tying the two rows together. A bank sends a message per leg of a currency
  /// exchange or a cash operation, the import wrote a row per message, and the
  /// pair nets to zero in the account balance while adding its whole size to
  /// both totals on the dashboard - 47 pairs and 982513 RSD of inflation on the
  /// database this was written against, 727442 of it inside one month, against
  /// months that otherwise run to 150k.
  ///
  /// The v23->v24 dedupe cannot reach these: its key carries the sign, so -7000
  /// and +7000 are two different payments to it. That is the right answer.
  /// These rows are not two copies of one payment - both are real, and removing
  /// either would leave the account balance wrong by the amount removed. They
  /// only need to be recognised as one movement, which is what a mutual link
  /// and the transfer category say, and what the dashboard already excludes on.
  ///
  /// A pair is: the same account, the same currency, opposite signs, at most
  /// [_transferPairWindow] apart, and amounts equal to within 2%. The tolerance
  /// is there because the two legs of an exchange are one foreign amount
  /// converted at two slightly different rates - 6000 EUR arriving as 704267.64
  /// RSD against 707515.20 RSD leaving, 0.46% apart. Rows that already carry a
  /// link are left alone, each row is used at most once, and the nearest
  /// candidate in time wins.
  ///
  /// Nothing is deleted and no balance moves.
  @visibleForTesting
  Future<int> linkOffsettingTransfers() async {
    final rows = await customSelect(
      '''
      SELECT id, account_id, date, amount, currency_code
        FROM transactions
       WHERE is_deleted = 0
         AND amount != 0
         AND (linked_transaction_id IS NULL OR linked_transaction_id = '')
       ORDER BY account_id, date, id
      ''',
      readsFrom: {transactions},
    ).get();
    if (rows.length < 2) return 0;

    final transferCategoryId = await _transferCategoryId();

    final windowSeconds = _transferPairWindow.inSeconds;
    final paired = <String>{};
    final now = DateTime.now().millisecondsSinceEpoch;
    var pairs = 0;

    for (var i = 0; i < rows.length; i++) {
      final left = rows[i];
      final leftId = left.read<String>('id');
      if (paired.contains(leftId)) continue;
      final accountId = left.read<String>('account_id');
      final date = left.read<int>('date');
      final amount = left.read<double>('amount');
      final currencyCode = left.read<String>('currency_code');

      for (var j = i + 1; j < rows.length; j++) {
        final right = rows[j];
        // Ordered by account then date, so once either runs past the row being
        // matched there is nothing further along that can match it.
        if (right.read<String>('account_id') != accountId) break;
        if (right.read<int>('date') - date > windowSeconds) break;

        final rightId = right.read<String>('id');
        if (paired.contains(rightId)) continue;
        if (right.read<String>('currency_code') != currencyCode) continue;

        if (!_offsets(amount, right.read<double>('amount'))) continue;

        await _markTransferLeg(leftId, rightId, transferCategoryId, now);
        await _markTransferLeg(rightId, leftId, transferCategoryId, now);
        paired.add(leftId);
        paired.add(rightId);
        pairs++;
        break;
      }
    }

    return pairs;
  }

  /// Whether [amount] and [other] are the two sides of one movement of money:
  /// opposite signs, equal to within 2%. See [linkOffsettingTransfers] for what
  /// the tolerance is for.
  bool _offsets(double amount, double other) {
    if (amount * other >= 0) return false;
    final size = amount.abs() >= other.abs() ? amount.abs() : other.abs();
    return (amount + other).abs() <= size * 0.02;
  }

  /// Links [transactionId] to the row holding the other half of the same
  /// movement of money and returns that row's id, or null when there is none.
  ///
  /// The live counterpart of the v24->v25 migration: the same rule, applied to
  /// one row as it is written, so the pairs that migration had to go back and
  /// find are never created again. See [linkOffsettingTransfers].
  ///
  /// The nearest candidate in time wins, and a row that already carries a link
  /// is neither matched nor rematched.
  Future<String?> linkOffsettingTransferFor(String transactionId) async {
    final row = await customSelect(
      'SELECT account_id, date, amount, currency_code FROM transactions '
      "WHERE id = ? AND is_deleted = 0 AND amount != 0 "
      "AND (linked_transaction_id IS NULL OR linked_transaction_id = '')",
      variables: [Variable(transactionId)],
      readsFrom: {transactions},
    ).getSingleOrNull();
    if (row == null) return null;

    final date = row.read<int>('date');
    final amount = row.read<double>('amount');
    final windowSeconds = _transferPairWindow.inSeconds;

    final candidates = await customSelect(
      'SELECT id, amount FROM transactions '
      'WHERE is_deleted = 0 AND id != ? AND account_id = ? '
      'AND currency_code = ? AND date BETWEEN ? AND ? '
      "AND (linked_transaction_id IS NULL OR linked_transaction_id = '') "
      'ORDER BY ABS(date - ?)',
      variables: [
        Variable(transactionId),
        Variable(row.read<String>('account_id')),
        Variable(row.read<String>('currency_code')),
        Variable(date - windowSeconds),
        Variable(date + windowSeconds),
        Variable(date),
      ],
      readsFrom: {transactions},
    ).get();

    for (final candidate in candidates) {
      if (!_offsets(amount, candidate.read<double>('amount'))) continue;

      final otherId = candidate.read<String>('id');
      final transferCategoryId = await _transferCategoryId();
      final now = DateTime.now().millisecondsSinceEpoch;
      await _markTransferLeg(transactionId, otherId, transferCategoryId, now);
      await _markTransferLeg(otherId, transactionId, transferCategoryId, now);
      return otherId;
    }

    return null;
  }

  /// The id of the category transfers are filed under, or null when the seeded
  /// row is missing - in which case the link alone is left to speak for the
  /// pair, which is already enough for the dashboard to drop it.
  Future<String?> _transferCategoryId() async {
    final row = await customSelect(
      'SELECT id FROM categories WHERE name = ? LIMIT 1',
      variables: [Variable(AppConstants.systemTransferCategoryName)],
      readsFrom: {categories},
    ).getSingleOrNull();
    return row?.read<String>('id');
  }

  /// Points [id] at [otherId] and files it under the transfer category, leaving
  /// the amount and the account alone. See [linkOffsettingTransfers].
  Future<void> _markTransferLeg(
    String id,
    String otherId,
    String? transferCategoryId,
    int now,
  ) async {
    await customUpdate(
      'UPDATE transactions SET linked_transaction_id = ?, '
      'category_id = COALESCE(?, category_id), modified_at = ? WHERE id = ?',
      variables: [
        Variable(otherId),
        Variable(transferCategoryId),
        Variable(now),
        Variable(id),
      ],
      updates: {transactions},
    );
    await _logMigrationChange('transactions', id, 'upsert', now);
  }

  Future<void> _logMigrationChange(
    String table,
    String recordId,
    String action,
    int timestamp,
  ) async {
    await into(syncLog).insert(
      SyncLogCompanion(
        changedTableName: Value(table),
        recordId: Value(recordId),
        action: Value(action),
        timestamp: Value(timestamp),
        exported: const Value(false),
      ),
    );
  }

  @override
  int get schemaVersion => 26;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        debugPrint('[DB_MIGRATION] onCreate START');
        debugPrint(
          '[DB_MIGRATION] onCreate: calling m.createAll() (tables + @TableIndex indexes)...',
        );
        await m.createAll();
        debugPrint('[DB_MIGRATION] onCreate: m.createAll() done');
        debugPrint('[DB_MIGRATION] onCreate: calling _seedData...');
        await _seedData(this);
        debugPrint('[DB_MIGRATION] onCreate: _seedData done');
        debugPrint(
          '[DB_MIGRATION] onCreate: creating partial UNIQUE INDEX idx_asset_entries_custom_api_dedup...',
        );
        await customStatement(
          'CREATE UNIQUE INDEX IF NOT EXISTS idx_asset_entries_custom_api_dedup '
          'ON asset_entries (asset_id, date, source) '
          "WHERE source = 'custom_api'",
        );
        debugPrint(
          '[DB_MIGRATION] onCreate: creating asset_entries read indexes...',
        );
        await _createAssetEntryIndexes();
        // After the seed, not before: every install lays down the same bundled
        // rows under the same stable ids, so queueing them would upload ~283k
        // exchange rates the server either already has or would get, byte for
        // byte, from any other client's copy of the same bundle. Everything the
        // user or an API fetch does to them afterwards trips the triggers.
        debugPrint(
          '[DB_MIGRATION] onCreate: creating sync_push_queue triggers...',
        );
        await _createSyncPushQueueTriggers();
        // After the seed as well, for the same reason the dedup index above is:
        // building the index once over the finished table is one sort, while
        // creating it first makes every one of the ~283k seeded rate inserts
        // maintain it.
        debugPrint(
          '[DB_MIGRATION] onCreate: creating push-queue key indexes...',
        );
        await _createSyncPushQueueKeyIndexes();
        // The four seeded tables the server keeps foreign keys into have to go
        // up even though nothing has edited them yet - see
        // [syncPushQueueSeedTables].
        debugPrint('[DB_MIGRATION] onCreate: queueing the seeded parents...');
        await seedPushQueueParents();
        // After the seed, because the identity these stamp with is written by
        // it - see [_createDeviceIdTriggers].
        debugPrint('[DB_MIGRATION] onCreate: creating device-id triggers...');
        await _createDeviceIdTriggers();
        debugPrint('[DB_MIGRATION] onCreate: stamping the seeded rows...');
        await stampSeededRowsWithLocalDeviceId();
        debugPrint('[DB_MIGRATION] onCreate END');
      },
      onUpgrade: (Migrator m, int from, int to) async {
        debugPrint('[DB_MIGRATION] onUpgrade: from=$from to=$to');

        if (from < 2) {
          debugPrint(
            '[DB_MIGRATION] v1→v2: adding sync columns to styles/accountTypes/currencyDesignations...',
          );
          await m.addColumn(styles, styles.modifiedAt);
          await m.addColumn(styles, styles.deviceId);
          await m.addColumn(styles, styles.isDeleted);
          await m.addColumn(accountTypes, accountTypes.modifiedAt);
          await m.addColumn(accountTypes, accountTypes.deviceId);
          await m.addColumn(accountTypes, accountTypes.isDeleted);
          await m.addColumn(
            currencyDesignations,
            currencyDesignations.modifiedAt,
          );
          await m.addColumn(
            currencyDesignations,
            currencyDesignations.deviceId,
          );
          await m.addColumn(
            currencyDesignations,
            currencyDesignations.isDeleted,
          );
          debugPrint('[DB_MIGRATION] v1→v2: migrating to stable IDs...');
          await _migrateToStableIds(this);
          debugPrint('[DB_MIGRATION] v1→v2: complete');
        }

        if (from < 3) {
          debugPrint(
            '[DB_MIGRATION] v2→v3: adding sync columns to all tables...',
          );
          await m.addColumn(categories, categories.modifiedAt);
          await m.addColumn(categories, categories.deviceId);
          await m.addColumn(categories, categories.isDeleted);

          await m.addColumn(accounts, accounts.modifiedAt);
          await m.addColumn(accounts, accounts.deviceId);
          await m.addColumn(accounts, accounts.isDeleted);

          await m.addColumn(transactions, transactions.modifiedAt);
          await m.addColumn(transactions, transactions.deviceId);
          await m.addColumn(transactions, transactions.isDeleted);

          await m.addColumn(exchangeRates, exchangeRates.modifiedAt);
          await m.addColumn(exchangeRates, exchangeRates.deviceId);

          await m.addColumn(inflationRates, inflationRates.modifiedAt);
          await m.addColumn(inflationRates, inflationRates.deviceId);

          await m.addColumn(assetEntries, assetEntries.modifiedAt);
          await m.addColumn(assetEntries, assetEntries.deviceId);
          await m.addColumn(assetEntries, assetEntries.isDeleted);

          await m.addColumn(settings, settings.modifiedAt);
          await m.addColumn(settings, settings.deviceId);

          await m.addColumn(customThemes, customThemes.modifiedAt);
          await m.addColumn(customThemes, customThemes.deviceId);
          await m.addColumn(customThemes, customThemes.isDeleted);

          await m.addColumn(customDataSources, customDataSources.modifiedAt);
          await m.addColumn(customDataSources, customDataSources.deviceId);
          await m.addColumn(customDataSources, customDataSources.isDeleted);

          await m.addColumn(apiSettingsTable, apiSettingsTable.modifiedAt);
          await m.addColumn(apiSettingsTable, apiSettingsTable.deviceId);

          debugPrint('[DB_MIGRATION] v2→v3: creating smsPresets table...');
          await m.createTable(smsPresets);
          debugPrint('[DB_MIGRATION] v2→v3: complete');
        }

        if (from < 4) {
          debugPrint(
            '[DB_MIGRATION] v3→v4: creating syncProcessedFiles table...',
          );
          await m.createTable(syncProcessedFiles);
          debugPrint('[DB_MIGRATION] v3→v4: complete');
        }

        if (from < 5) {
          debugPrint('[DB_MIGRATION] v4→v5: re-seeding data...');
          await _seedData(this);
          debugPrint('[DB_MIGRATION] v4→v5: complete');
        }

        if (from < 6) {
          debugPrint(
            '[DB_MIGRATION] v5→v6: creating composite indexes on transactions...',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_transactions_date_category '
            'ON transactions (date, category_id)',
          );
          debugPrint(
            '[DB_MIGRATION] v5→v6: idx_transactions_date_category created',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_transactions_account_date '
            'ON transactions (account_id, date)',
          );
          debugPrint(
            '[DB_MIGRATION] v5→v6: idx_transactions_account_date created',
          );
          debugPrint('[DB_MIGRATION] v5→v6: complete');
        }

        if (from < 7) {
          debugPrint(
            '[DB_MIGRATION] v6→v7: deduplicating asset_entries for custom_api...',
          );
          try {
            await customStatement('''DELETE FROM asset_entries
                 WHERE source = 'custom_api'
                 AND rowid NOT IN (
                   SELECT MAX(rowid)
                   FROM asset_entries
                   WHERE source = 'custom_api'
                   GROUP BY asset_id, date(date / 1000, 'unixepoch')
                 )''');
            debugPrint('[DB_MIGRATION] v6→v7: dedup DELETE complete');
          } catch (e) {
            debugPrint(
              '[DB_MIGRATION] v6→v7: dedup DELETE error (non-fatal, continuing): $e',
            );
          }

          debugPrint(
            '[DB_MIGRATION] v6→v7: creating partial UNIQUE INDEX idx_asset_entries_custom_api_dedup...',
          );
          try {
            await customStatement(
              'CREATE UNIQUE INDEX IF NOT EXISTS idx_asset_entries_custom_api_dedup '
              'ON asset_entries (asset_id, date, source) '
              "WHERE source = 'custom_api'",
            );
            debugPrint('[DB_MIGRATION] v6→v7: UNIQUE INDEX created');
          } catch (e) {
            debugPrint('[DB_MIGRATION] v6→v7: UNIQUE INDEX creation error: $e');
            // If index creation fails due to remaining duplicates, force-delete them
            // by keeping only the row with the MAX id (alphabetically) per (asset_id, date)
            debugPrint(
              '[DB_MIGRATION] v6→v7: retrying dedup with stricter DELETE...',
            );
            await customStatement('''DELETE FROM asset_entries
                 WHERE source = 'custom_api'
                 AND id NOT IN (
                   SELECT MAX(id)
                   FROM asset_entries
                   WHERE source = 'custom_api'
                   GROUP BY asset_id, date
                 )''');
            debugPrint(
              '[DB_MIGRATION] v6→v7: strict dedup complete, retrying index...',
            );
            await customStatement(
              'CREATE UNIQUE INDEX IF NOT EXISTS idx_asset_entries_custom_api_dedup '
              'ON asset_entries (asset_id, date, source) '
              "WHERE source = 'custom_api'",
            );
            debugPrint('[DB_MIGRATION] v6→v7: UNIQUE INDEX created on retry');
          }
          debugPrint('[DB_MIGRATION] v6→v7: complete');
        }

        if (from < 8) {
          debugPrint('[DB_MIGRATION] v7→v8: adding minor-unit columns...');
          await m.addColumn(transactions, transactions.amountMinor);
          await m.addColumn(transactions, transactions.feeMinor);
          await m.addColumn(accounts, accounts.balanceMinor);
          debugPrint(
            '[DB_MIGRATION] v7→v8: backfilling minor units for fiat...',
          );
          await backfillMinorUnits();
          debugPrint('[DB_MIGRATION] v7→v8: complete');
        }

        if (from < 9) {
          // These five are declared with @TableIndex, so m.createAll() only
          // ever built them on fresh installs — every device that arrived
          // here by upgrade has been querying without them since v1.
          debugPrint(
            '[DB_MIGRATION] v8→v9: creating the @TableIndex indexes missing on upgraded databases...',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_transactions_date '
            'ON transactions (date)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_transactions_account '
            'ON transactions (account_id)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_transactions_category '
            'ON transactions (category_id)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_exchange_rates_date '
            'ON exchange_rates (date)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_exchange_rates_composite '
            'ON exchange_rates (from_currency_code, to_currency_code, date)',
          );
          debugPrint('[DB_MIGRATION] v8→v9: complete');
        }

        if (from < 10) {
          // `country` was nullable and sits in the primary key, and SQLite
          // counts NULLs there as distinct, so every refresh of the worldwide
          // series appended a row instead of replacing one. Those pile-ups
          // become genuine key collisions once they all read 'global', so they
          // have to be collapsed first — newest `modified_at` wins, which is
          // the row last-write-wins sync would have kept anyway.
          debugPrint(
            '[DB_MIGRATION] v9→v10: collapsing duplicate worldwide inflation rates...',
          );
          await customStatement('''DELETE FROM inflation_rates
               WHERE (country IS NULL OR country = 'global')
               AND rowid NOT IN (
                 SELECT rowid FROM (
                   SELECT rowid, MAX(modified_at)
                   FROM inflation_rates
                   WHERE country IS NULL OR country = 'global'
                   GROUP BY date, preset
                 )
               )''');
          debugPrint('[DB_MIGRATION] v9→v10: dedup DELETE complete');

          debugPrint(
            '[DB_MIGRATION] v9→v10: pointing NULL countries at the global sentinel...',
          );
          await customStatement(
            "UPDATE inflation_rates SET country = 'global' WHERE country IS NULL",
          );
          debugPrint(
            '[DB_MIGRATION] v9→v10: rebuilding inflation_rates with a NOT NULL country...',
          );
          await m.alterTable(TableMigration(inflationRates));
          debugPrint('[DB_MIGRATION] v9→v10: complete');
        }

        if (from < 11) {
          debugPrint(
            '[DB_MIGRATION] v10→v11: adding the opening-balance anchor...',
          );
          await m.addColumn(accounts, accounts.openingBalance);
          await m.addColumn(accounts, accounts.openingBalanceMinor);
          debugPrint(
            '[DB_MIGRATION] v10→v11: deriving opening balances from stored balances...',
          );
          await backfillOpeningBalances();
          debugPrint('[DB_MIGRATION] v10→v11: complete');
        }

        if (from < 12) {
          // api_settings_table was the only synced table with no tombstone, so
          // deleting a provider on one device left the others untouched and the
          // row came back on the next sync. Guarded like the index steps above:
          // a database that already carries the column (an upgrade that died
          // after the ALTER) must not fail the whole migration on
          // "duplicate column name".
          debugPrint(
            '[DB_MIGRATION] v11→v12: adding is_deleted to api_settings_table...',
          );
          if (!await _hasColumn('api_settings_table', 'is_deleted')) {
            await m.addColumn(apiSettingsTable, apiSettingsTable.isDeleted);
          }
          debugPrint('[DB_MIGRATION] v11→v12: complete');
        }

        if (from < 13) {
          // The server push used to select rows by `modified_at > <the clock
          // reading of the last push>`. Anything that entered this database
          // carrying an older stamp — every row imported from a peer's sync
          // file, everything written while the clock was skewed or set back —
          // was born below the mark and was never offered to the server once.
          // Guarded like the steps above so an upgrade that died halfway can be
          // re-run.
          debugPrint(
            '[DB_MIGRATION] v12→v13: creating the server push queue...',
          );
          if (!(await _existingTables()).contains('sync_push_queue')) {
            await m.createTable(syncPushQueue);
          }
          // @TableIndex indexes are only created by createAll(), so an upgraded
          // database needs the index spelled out (same lesson as v8→v9).
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_sync_push_queue_table '
            'ON sync_push_queue (changed_table_name, id)',
          );
          await _createSyncPushQueueTriggers();

          // Seed the queue from every synced table. The old watermark lives in
          // SharedPreferences and is unreachable from here, so there is no way
          // to tell which rows the server already has; this costs one full push
          // after the upgrade — the same one-off price the pull cursor paid —
          // and it is what finally sends the rows the watermark had stranded.
          debugPrint('[DB_MIGRATION] v12→v13: seeding the push queue...');
          final queued = await customSelect(
            'SELECT COUNT(*) AS c FROM sync_push_queue',
          ).getSingle();
          if (queued.read<int>('c') == 0) {
            final existing = await _existingTables();
            for (final table in syncPushQueueTables) {
              if (!existing.contains(table)) continue;
              await customStatement(
                'INSERT INTO sync_push_queue (changed_table_name, record_key) '
                "SELECT '$table', ${syncPushQueueKeyExpression(table)} "
                'FROM $table',
              );
            }
          }
          debugPrint('[DB_MIGRATION] v12→v13: complete');
        }

        if (from < 14) {
          // v13 shipped the queue but nothing that can resolve a queued key of
          // exchange_rates or inflation_rates back to its row: the lookup is
          // `WHERE <concatenated key> IN (?, …)`, and no index in the schema
          // matched an expression. Every 500-key chunk of the full push that
          // v12→v13 seeds therefore scanned the whole rate table. Purely
          // additive — two indexes, no column, no row touched — and
          // `IF NOT EXISTS` inside the helper makes it re-runnable like the
          // steps above.
          debugPrint(
            '[DB_MIGRATION] v13→v14: indexing the push-queue record keys...',
          );
          await _createSyncPushQueueKeyIndexes();
          debugPrint('[DB_MIGRATION] v13→v14: complete');
        }

        if (from < 15) {
          // v13's update triggers only fired when `modified_at` moved, so a row
          // written and changed again inside the same millisecond queued
          // nothing and stayed on this device for good — a delete made right
          // after a seed being the case that actually bites. The new WHEN asks
          // whether the row's CONTENT changed. No column, no row and no data
          // touched: the triggers are dropped and recreated, which the helper
          // does on every call, so this step is re-runnable like the rest.
          debugPrint(
            '[DB_MIGRATION] v14→v15: content-aware push-queue triggers...',
          );
          await _createSyncPushQueueTriggers();
          debugPrint('[DB_MIGRATION] v14→v15: complete');
        }

        if (from < 16) {
          // The repair half of the same fix. A database created by v13, v14 or
          // v15 got the triggers but never queued the seeded rows the server
          // holds foreign keys into, so its very first account push failed
          // with a 23503 and every push after it retried the same batch. This
          // step puts those rows in the queue so the next sync can clear it.
          //
          // Databases upgraded from v12 are unaffected and re-queueing costs
          // them nothing: v12→v13 seeded the queue from every table, the push
          // dedupes record keys within a batch, and the server resolves a row
          // it already holds by last-write-wins. No column, no row and no data
          // touched.
          debugPrint(
            '[DB_MIGRATION] v15→v16: queueing the seeded foreign-key parents...',
          );
          await seedPushQueueParents();
          debugPrint('[DB_MIGRATION] v15→v16: complete');
        }

        if (from < 17) {
          // Drops the UNIQUE on currencies.name and account_types.name - see
          // those columns for what the constraint did to a pair of devices.
          // Both are written inline in CREATE TABLE, so removing them means
          // rebuilding the tables; drift copies the rows across.
          //
          // Dropping a table drops its triggers with it, so the push-queue
          // triggers for both have to be put back. The helper recreates all of
          // them and is re-runnable, which is also what makes this step safe
          // to re-enter.
          debugPrint(
            '[DB_MIGRATION] v16→v17: dropping the UNIQUE on synced names...',
          );
          await m.alterTable(TableMigration(currencies));
          await m.alterTable(TableMigration(accountTypes));
          await _createSyncPushQueueTriggers();
          debugPrint('[DB_MIGRATION] v16→v17: complete');
        }

        if (from < 18) {
          // Every row this device ever wrote carries a NULL author, which is
          // half of the order that decides a conflict missing - see
          // [_createDeviceIdTriggers] for what that costs. The triggers fix
          // everything written from here on; the stamp fixes the seeded
          // catalogue, which is where equal clocks are the rule rather than a
          // coincidence. Both are re-runnable.
          debugPrint('[DB_MIGRATION] v17→v18: device-id triggers...');
          // Recreated, not left alone: the update trigger's WHEN clause stopped
          // counting `device_id` in this version - see
          // [_pushQueueUpdateCondition].
          await _createSyncPushQueueTriggers();
          await _createDeviceIdTriggers();
          debugPrint('[DB_MIGRATION] v17→v18: stamping the seeded rows...');
          await stampSeededRowsWithLocalDeviceId();
          // The stamp alone no longer queues anything, and the server has to
          // hear about it or it keeps resolving these ties against a copy that
          // has no author at all.
          await seedPushQueueParents();
          debugPrint('[DB_MIGRATION] v17→v18: complete');
        }

        if (from < 19) {
          // The review queue's flag. Additive and defaulted to false, so every
          // row already in the database reads as reviewed - which is what a row
          // a person entered by hand actually is.
          //
          // The push-queue triggers enumerate the columns of the table they
          // watch (see [_pushQueueUpdateCondition]) and were compiled before
          // this one existed, so clearing the flag would never have been
          // uploaded. Recreating them is re-runnable, like every other step
          // here.
          debugPrint('[DB_MIGRATION] v18->v19: transactions.needs_review...');
          // Guarded like the other re-runnable steps: an upgrade interrupted
          // after the ALTER and before the version bump would otherwise fail
          // on the retry and leave the device stuck one version back forever.
          if (!await _hasColumn('transactions', 'needs_review')) {
            await m.addColumn(transactions, transactions.needsReview);
          }
          await _createSyncPushQueueTriggers();

          // The category the SMS import files recurring payments into.
          // Seeding only runs on a fresh install, so a database that already
          // exists - which is every device this user has - would never get
          // it, and every subscription would land in "other expense".
          //
          // Insert-or-ignore on both rows: a device that has already synced
          // the row down from a peer that migrated first keeps what it has,
          // and re-running the step changes nothing. The names come from the
          // seed lists so they read in the same language as the categories
          // seeded beside them.
          debugPrint('[DB_MIGRATION] v18->v19: cat_subscriptions...');
          final seedLang = _seedLanguageCode;
          await into(styles).insert(
            getDefaultStyles(
              seedLang,
            ).firstWhere((s) => s.id.value == 'style_subscriptions'),
            mode: InsertMode.insertOrIgnore,
          );
          await into(categories).insert(
            getDefaultCategories(
              seedLang,
            ).firstWhere((c) => c.id.value == 'cat_subscriptions'),
            mode: InsertMode.insertOrIgnore,
          );
          debugPrint('[DB_MIGRATION] v18->v19: complete');
        }

        if (from < 20) {
          // Repair for the SMS re-import that wrote the whole inbox a second
          // time. Until this version nothing tied a transaction back to the
          // message that produced it - every import minted a fresh UUID - so
          // re-running "All time" to pick up the new per-merchant categories
          // inserted a duplicate of every row, and each duplicate moved the
          // account balance again. The import now derives the id from the
          // message, so this can only ever have to run once.
          //
          // Soft-delete, not delete: the rows stay in the table with
          // is_deleted = 1, which is also what carries the removal to the
          // other devices instead of letting them push their copies back on
          // the next pull. It is also the undo - flipping the flag back
          // restores anything this took that it should not have.
          //
          // What it can get wrong: two rows that a person really did enter
          // twice, on the same account, the same currency, the same
          // description and the same timestamp to the millisecond, are
          // indistinguishable from an import duplicate and one of them will
          // be flagged. Transfers are excluded outright - they come in linked
          // pairs and collapsing one half would strand the other.
          debugPrint(
            '[DB_MIGRATION] v19->v20: collapsing import duplicates...',
          );
          final tombstonedAt = DateTime.now().millisecondsSinceEpoch;
          final collapsed = await customUpdate(
            '''
            UPDATE transactions
               SET is_deleted = 1,
                   modified_at = ?
             WHERE is_deleted = 0
               AND linked_transaction_id IS NULL
               AND rowid NOT IN (
                     SELECT MIN(rowid)
                       FROM transactions
                      WHERE is_deleted = 0
                        AND linked_transaction_id IS NULL
                      GROUP BY account_id, date, amount, currency_code,
                               description
                   )
            ''',
            variables: [Variable<int>(tombstonedAt)],
            updates: {transactions},
          );
          debugPrint(
            '[DB_MIGRATION] v19->v20: $collapsed duplicate rows tombstoned',
          );

          if (collapsed > 0) {
            // Every balance the duplicates touched is now overstated by
            // exactly them. Rebuilding from the opening-balance anchor is the
            // only way to put it right: the running balance is materialised,
            // so there is no delta to subtract that is not itself derived
            // from the rows that just went away. Every account is rebuilt
            // rather than only the ones that lost a row - it is a handful of
            // accounts, and a rebuild is idempotent for the untouched ones.
            final accountIds = await select(accounts).map((a) => a.id).get();
            await accountsDao.recomputeBalances(accountIds);
            debugPrint(
              '[DB_MIGRATION] v19->v20: rebuilt ${accountIds.length} balances',
            );
          }
          debugPrint('[DB_MIGRATION] v19->v20: complete');
        }

        if (from < 21) {
          // The v12 to v13 upgrade seeded the push queue from every synced
          // table, which handed the server ~367k queue entries for the bundled
          // rate history - reference data that every install already lays down
          // under the same keys, so no client has ever needed another client
          // to send it. The queue drains oldest-first, so those entries sit in
          // front of everything a person actually did.
          //
          // Deleted, not tombstoned: a queue entry is a note saying "the
          // server has not been told about this row", and dropping the note
          // leaves the row itself untouched. Nothing is lost that a later edit
          // to that rate would not re-queue.
          debugPrint(
            '[DB_MIGRATION] v20->v21: dropping seeded rates from the push queue...',
          );
          final trimmed = await customUpdate(
            '''
            DELETE FROM sync_push_queue
             WHERE changed_table_name = 'exchange_rates'
               AND record_key IN (
                     SELECT ${syncPushQueueKeyExpression('exchange_rates')}
                       FROM exchange_rates
                      WHERE $seededExchangeRatesFilter
                   )
            ''',
            updates: {syncPushQueue},
          );
          debugPrint(
            '[DB_MIGRATION] v20->v21: $trimmed seeded rate entries dropped',
          );
          debugPrint('[DB_MIGRATION] v20->v21: complete');
        }

        if (from < 22) {
          debugPrint(
            '[DB_MIGRATION] v21->v22: creating asset_entries read indexes...',
          );
          await _createAssetEntryIndexes();
          debugPrint('[DB_MIGRATION] v21->v22: complete');
        }

        if (from < 23) {
          // The bundled history used to be every currency the data set
          // publishes - roughly 700 of them - for every day since 2024-04-01,
          // which is ~283 000 rows a device carried to convert between the two
          // or three currencies its owner actually holds. The asset now ships
          // the last 30 days and the rest comes from the server on demand, so
          // the rows for currencies nothing references are dead weight in
          // every query that scans this table.
          //
          // Only rows nobody typed: a hand-entered or hand-corrected rate is
          // the one thing here that cannot be fetched again, so the delete is
          // restricted to rows written by the seed (a bulk write of a whole
          // day) or by the server fetch (stamped with its device id). A rate
          // the user edited has neither mark and stays.
          //
          // Deleted outright rather than tombstoned: these rows are reference
          // data, identical on every install, and re-fetchable. There is no
          // sync_log entry either, so this stays local - a peer that still
          // wants JPY keeps its own copy instead of being told to drop it.
          debugPrint(
            '[DB_MIGRATION] v22->v23: pruning rates for unused currencies...',
          );

          // A row is kept only if both of its endpoints are in use. EUR is in
          // the set unconditionally: every published rate is quoted against
          // it, so dropping the base would take the entire table with it.
          //
          // Deliberately not `currency_designations`: the seed ships a symbol
          // for all 341 currencies, so that table says nothing about which of
          // them the user holds - joining it in would keep every row and make
          // this step a no-op.
          const usedCurrencies = kUsedCurrenciesSql;

          const prunable =
              '''
            (from_currency_code NOT IN ($usedCurrencies)
              OR to_currency_code NOT IN ($usedCurrencies))
            AND (device_id = '$kServerRateDeviceId'
                 OR ($seededExchangeRatesFilter))
          ''';

          // The queue entries first, while the rows they name still exist:
          // the key is built from the row, so after the delete there is
          // nothing left to match them against.
          await customUpdate(
            '''
            DELETE FROM sync_push_queue
             WHERE changed_table_name = 'exchange_rates'
               AND record_key IN (
                     SELECT ${syncPushQueueKeyExpression('exchange_rates')}
                       FROM exchange_rates
                      WHERE $prunable
                   )
            ''',
            updates: {syncPushQueue},
          );

          final pruned = await customUpdate(
            'DELETE FROM exchange_rates WHERE $prunable',
            updates: {exchangeRates},
          );
          debugPrint('[DB_MIGRATION] v22->v23: $pruned rate rows removed');
          debugPrint('[DB_MIGRATION] v22->v23: complete');
        }

        if (from < 24) {
          // The SMS import derives a transaction's id from the message it came
          // from, so a message imported twice now lands on the same row. Every
          // copy written before that - and everything a bank statement put in
          // for the same payments - carries a random uuid instead, and those
          // pairs are still sitting in the table: 116 of them on the database
          // this was written against, each one counted twice in every total.
          //
          // Nothing running at read time can collapse them: the two copies
          // disagree on the description (one carries the bank's name, the
          // other the merchant's), so they are the same payment only by
          // account, instant and amount.
          debugPrint(
            '[DB_MIGRATION] v23->v24: removing duplicate transactions...',
          );
          final removed = await removeDuplicateTransactions();
          debugPrint('[DB_MIGRATION] v23->v24: $removed duplicates removed');
          debugPrint('[DB_MIGRATION] v23->v24: complete');
        }

        if (from < 25) {
          // Rows that record one movement of money as an unrelated expense and
          // an unrelated income, seconds apart on one account. They net out in
          // the balance and double-count in every total on the dashboard, and
          // the v23->v24 dedupe leaves them alone by design - see
          // linkOffsettingTransfers for why the sign in its key is right.
          debugPrint(
            '[DB_MIGRATION] v24->v25: linking offsetting transfers...',
          );
          final pairs = await linkOffsettingTransfers();
          debugPrint('[DB_MIGRATION] v24->v25: $pairs transfer pairs linked');
          debugPrint('[DB_MIGRATION] v24->v25: complete');
        }

        if (from < 26) {
          // The same payment written twice by two importers whose clocks
          // disagree by a whole number of hours - a time zone applied twice.
          // The v23->v24 dedupe keys on the instant exactly and cannot see
          // them; see removeClockShiftedDuplicates for what makes a whole-hour
          // gap safe to collapse.
          debugPrint(
            '[DB_MIGRATION] v25->v26: removing clock-shifted duplicates...',
          );
          final shifted = await removeClockShiftedDuplicates();
          debugPrint('[DB_MIGRATION] v25->v26: $shifted duplicates removed');
          debugPrint('[DB_MIGRATION] v25->v26: complete');
        }

        debugPrint('[DB_MIGRATION] onUpgrade complete: from=$from to=$to');
      },
      beforeOpen: (details) async {
        debugPrint(
          '[DB_MIGRATION] beforeOpen START: wasCreated=${details.wasCreated} versionBefore=${details.versionBefore} versionNow=${details.versionNow}',
        );
        debugPrint(
          '[DB_MIGRATION] beforeOpen: executing PRAGMA foreign_keys = ON...',
        );
        await customStatement('PRAGMA foreign_keys = ON');
        debugPrint('[DB_MIGRATION] beforeOpen: PRAGMA foreign_keys = ON done');

        // Repair corrupted modifiedAt columns (fix for previous
        // batchUpdateBalances bug). Reset to current time to ensure they are
        // treated as valid updates.
        //
        // Only on an upgrade. The bug that wrote text into the column is long
        // gone, so nothing can reintroduce the corruption between two opens of
        // the same version - but `typeof()` is unindexable, so leaving the
        // repair unconditional meant a full scan of `accounts` plus a write
        // transaction opened ahead of the first query, on every single launch,
        // forever.
        if (!details.wasCreated && details.hadUpgrade) {
          final now = DateTime.now().millisecondsSinceEpoch;
          debugPrint(
            '[DB_MIGRATION] beforeOpen: executing corrupted modified_at repair...',
          );
          await customStatement(
            "UPDATE accounts SET modified_at = $now WHERE typeof(modified_at) = 'text'",
          );
          debugPrint(
            '[DB_MIGRATION] beforeOpen END: corrupted modified_at repaired',
          );
        } else {
          debugPrint(
            '[DB_MIGRATION] beforeOpen END: no upgrade, modified_at repair skipped',
          );
        }
      },
    );
  }

  /// Backfill the integer minor-unit columns from the legacy [amount]/[fee]/
  /// [balance] doubles, for fiat rows only (currencies.type = 0 == currency).
  /// Non-fiat rows keep NULL minor columns and stay on the double. The per-
  /// currency scale mirrors CurrencyPrecision (0 for JPY/…, 3 for KWD/…, else 2).
  @visibleForTesting
  Future<void> backfillMinorUnits() async {
    // SQL CASE yielding 10^decimals for a `currency_code` column.
    const scaleCase = '''
      CASE
        WHEN currency_code IN ('BIF','CLP','DJF','GNF','ISK','JPY','KMF','KRW','PYG','RWF','UGX','VND','VUV','XAF','XOF','XPF') THEN 1
        WHEN currency_code IN ('BHD','IQD','JOD','KWD','LYD','OMR','TND') THEN 1000
        ELSE 100
      END''';
    const fiatFilter =
        "currency_code IN (SELECT code FROM currencies WHERE type = 0)";

    await customStatement(
      'UPDATE transactions SET amount_minor = '
      'CAST(ROUND(amount * ($scaleCase)) AS INTEGER) WHERE $fiatFilter',
    );
    await customStatement(
      'UPDATE transactions SET fee_minor = '
      'CAST(ROUND(fee * ($scaleCase)) AS INTEGER) WHERE $fiatFilter',
    );
    await customStatement(
      'UPDATE accounts SET balance_minor = '
      'CAST(ROUND(balance * ($scaleCase)) AS INTEGER) WHERE $fiatFilter',
    );
  }

  /// Derive every account's opening balance from the balance it carries right
  /// now, by subtracting exactly what a rebuild would add back.
  ///
  /// The point is that nobody's money moves: whatever balance the user is
  /// looking at today is what the first rebuild produces. That only holds if
  /// this subtracts the same set of transactions the rebuild sums, which is why
  /// it goes through the same helpers, with the same currency filter, rather
  /// than summing every row on the account. A balance built before this existed did
  /// add unconverted foreign amounts as if they were the account's own, and the
  /// difference lands in the anchor instead of changing the balance. That is
  /// deliberate: there is no way to tell from the row which historic amounts
  /// were converted, and a migration is the wrong place to guess at money.
  @visibleForTesting
  Future<void> backfillOpeningBalances() async {
    final anchorMinor =
        'balance_minor - ${_ownTransactionsMinorSum('amount_minor', 'amount')}';
    await customStatement('''
      UPDATE accounts
      SET opening_balance_minor = CASE WHEN balance_minor IS NULL THEN NULL ELSE $anchorMinor END,
          opening_balance = CASE
            WHEN balance_minor IS NULL THEN balance - ${_ownTransactionsSum('amount')}
            ELSE CAST($anchorMinor AS REAL) / ($kMinorScaleCase)
          END
    ''');
  }

  Future<void> _seedData(AppDatabase db, {bool skipStaticData = false}) async {
    debugPrint('[DB_SEED] _seedData START (skipStaticData=$skipStaticData)');
    if (!skipStaticData) {
      debugPrint('[DB_SEED] _seedData: seeding languages...');
      await _seedLanguages(db);
      debugPrint('[DB_SEED] _seedData: languages done');
      debugPrint('[DB_SEED] _seedData: seeding currencies...');
      await _seedCurrencies(db);
      debugPrint('[DB_SEED] _seedData: currencies done');
      debugPrint('[DB_SEED] _seedData: seeding currencyDesignations...');
      await _seedCurrencyDesignations(db);
      debugPrint('[DB_SEED] _seedData: currencyDesignations done');
      debugPrint('[DB_SEED] _seedData: seeding accountTypes...');
      await _seedAccountTypes(db);
      debugPrint('[DB_SEED] _seedData: accountTypes done');
    }
    debugPrint('[DB_SEED] _seedData: seeding styles...');
    await _seedStyles(db);
    debugPrint('[DB_SEED] _seedData: styles done');
    debugPrint('[DB_SEED] _seedData: seeding categories...');
    await _seedCategories(db);
    debugPrint('[DB_SEED] _seedData: categories done');
    debugPrint('[DB_SEED] _seedData: seeding exchangeRates (may be slow)...');
    await _seedExchangeRates(db);
    debugPrint('[DB_SEED] _seedData: exchangeRates done');
    debugPrint('[DB_SEED] _seedData: seeding settings...');
    await _seedSettings(db);
    debugPrint('[DB_SEED] _seedData: settings done');
    debugPrint('[DB_SEED] _seedData: seeding apiSettings...');
    await _seedApiSettings(db);
    debugPrint('[DB_SEED] _seedData: apiSettings done');
    debugPrint('[DB_SEED] _seedData END');
  }

  // --- Seeding Methods ---

  Future<void> _seedLanguages(AppDatabase db) async {
    await db.languageDao.insertAllLanguages(defaultLanguages);
  }

  Future<void> _seedCurrencyDesignations(AppDatabase db) async {
    await db.currencyDesignationsDao.insertAllCurrencyDesignations(
      defaultCurrencyDesignations,
    );
  }

  Future<void> _seedCurrencies(AppDatabase db) async {
    await db.currenciesDao.insertAllCurrencies(defaultCurrencies);
  }

  Future<void> _seedSettings(AppDatabase db) async {
    final deviceName = await getDeviceName();
    final settingsToSeed = getDefaultSettings(deviceName);
    await db.settingsDao.insertAllSettings(settingsToSeed);

    // Generate and store unique device ID for sync if not exists
    final deviceId = await db.settingsDao.getSetting('local_device_id');
    if (deviceId == null) {
      await db.settingsDao.setSetting(
        SettingsCompanion(
          key: const Value('local_device_id'),
          value: Value(_uuid.v4()),
          device: Value(deviceName),
          modifiedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );
    }
  }

  /// Creates the built-in provider rows that are missing.
  ///
  /// Only the missing ones: this also runs after "clear my data", and an
  /// unconditional upsert switched every provider back to enabled with
  /// auto-fetch on. A user who had deliberately turned the exchange-rate
  /// provider off found their device talking to the network again after a
  /// clear, without being asked.
  Future<void> _seedApiSettings(AppDatabase db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    const providerIds = ['exchange_rates', 'inflation', 'assets'];

    // Tombstones count as existing, or a provider the user deleted would be
    // recreated - and re-enabled - by the next reseed.
    final existing = await db.apiSettingsDao.existingIds(providerIds);

    for (final id in providerIds) {
      if (existing.contains(id)) continue;
      await db.apiSettingsDao.upsertSetting(
        ApiSettingsTableCompanion(
          id: Value(id),
          enabled: const Value(true),
          autoFetch: const Value(true),
          modifiedAt: Value(now),
        ),
      );
    }
  }

  /// The language the seeded rows should be named in.
  ///
  /// This ran off `Intl.systemLocale`, which is empty unless something has
  /// called `findSystemLocale()` - nothing here ever does - so `''.split('_')`
  /// handed the seeder an empty code, it fell back to English, and the
  /// translations sitting next to the seed data had never once been used. The
  /// platform locale is the same answer that question wanted, and it is
  /// available before the first frame, which is when this runs.
  ///
  /// Only the first launch reads this. Switching language later renames
  /// nothing: by then the rows are the user's, and they may have edited them.
  String get _seedLanguageCode => RegionUtils.detectDeviceLanguage() ?? 'en';

  Future<void> _seedStyles(AppDatabase db) async {
    await db.stylesDao.insertAllStyles(getDefaultStyles(_seedLanguageCode));
  }

  Future<void> _seedAccountTypes(AppDatabase db) async {
    await db.accountTypesDao.insertAllAccountTypes(
      getDefaultAccountTypes(_seedLanguageCode),
    );
  }

  Future<void> _seedCategories(AppDatabase db) async {
    await db.categoriesDao.insertAllCategories(
      getDefaultCategories(_seedLanguageCode),
    );
  }

  Future<void> _seedExchangeRates(AppDatabase db) async {
    if (!seedExchangeRatesOnCreate) {
      debugPrint('[DB_SEED] _seedExchangeRates: skipped, seeding is off');
      return;
    }
    debugPrint(
      '[DB_SEED] _seedExchangeRates: calling getCurrenciesRateToSeeder...',
    );
    final List<ExchangeRateDomain> rates =
        await ImportDataUtils.getCurrenciesRateToSeeder();
    debugPrint(
      '[DB_SEED] _seedExchangeRates: got ${rates.length} rates, inserting...',
    );
    await db.exchangeRatesDao.insertAllExchangeRates(rates.toCompanionList());
    debugPrint('[DB_SEED] _seedExchangeRates: insert done');
  }

  /// Migration helper to convert old UUID-based IDs to new stable IDs
  Future<void> _migrateToStableIds(AppDatabase db) async {
    // Disable FK checks during migration
    await customStatement('PRAGMA foreign_keys = OFF');

    try {
      await db.transaction(() async {
        // 1. Migrate Account Types
        for (final type in defaultAccountTypes) {
          final stableId = type.id.value;
          final name = type.name.value;

          // Find old record by name
          final oldRecord = await (select(
            accountTypes,
          )..where((t) => t.name.equals(name))).getSingleOrNull();

          if (oldRecord != null && oldRecord.id != stableId) {
            final oldId = oldRecord.id;

            // Update references in Accounts
            await (update(accounts)
                  ..where((a) => a.accountTypeId.equals(oldId)))
                .write(AccountsCompanion(accountTypeId: Value(stableId)));

            // Update the record itself (Delete old, insert new with stable ID)
            await (delete(accountTypes)..where((t) => t.id.equals(oldId))).go();
            await into(accountTypes).insert(type, mode: InsertMode.replace);
          } else if (oldRecord == null) {
            // Record missing? Insert it.
            await into(accountTypes).insert(type, mode: InsertMode.replace);
          }
        }

        // 2. Migrate Currency Designations
        for (final des in defaultCurrencyDesignations) {
          final stableId = des.id.value;
          final value = des.value.value;
          final currencyCode = des.currencyCode.value;

          // Find old record by value and currencyCode
          final oldRecord =
              await (select(currencyDesignations)
                    ..where((t) => t.value.equals(value))
                    ..where((t) => t.currencyCode.equals(currencyCode)))
                  .getSingleOrNull();

          if (oldRecord != null && oldRecord.id != stableId) {
            final oldId = oldRecord.id;

            // Update references in Accounts
            await (update(
              accounts,
            )..where((a) => a.currencyDesignationId.equals(oldId))).write(
              AccountsCompanion(currencyDesignationId: Value(stableId)),
            );

            // Update the record itself
            await (delete(
              currencyDesignations,
            )..where((t) => t.id.equals(oldId))).go();
            await into(
              currencyDesignations,
            ).insert(des, mode: InsertMode.replace);
          } else if (oldRecord == null) {
            await into(
              currencyDesignations,
            ).insert(des, mode: InsertMode.replace);
          }
        }

        // 3. Migrate Styles
        for (final style in defaultStyles) {
          final stableId = style.id.value;
          final name = style.name.value;

          // Find old record by name
          final oldRecord = await (select(
            styles,
          )..where((t) => t.name.equals(name))).getSingleOrNull();

          if (oldRecord != null && oldRecord.id != stableId) {
            final oldId = oldRecord.id;

            // Update references in Accounts
            await (update(accounts)..where((a) => a.styleId.equals(oldId)))
                .write(AccountsCompanion(styleId: Value(stableId)));

            // Update references in Categories
            await (update(categories)..where((c) => c.styleId.equals(oldId)))
                .write(CategoriesCompanion(styleId: Value(stableId)));

            // Update the record itself
            await (delete(styles)..where((t) => t.id.equals(oldId))).go();
            await into(styles).insert(style, mode: InsertMode.replace);
          } else if (oldRecord == null) {
            await into(styles).insert(style, mode: InsertMode.replace);
          }
        }
      });
    } finally {
      // Re-enable FK checks
      await customStatement('PRAGMA foreign_keys = ON');
    }
  }

  /// The tables [clearAllData] empties, mapped to the ids they held.
  ///
  /// Read before the wipe, because after it there is nothing left to name.
  /// Keyed by the `sync_log` table name, which is what the sync engines match
  /// on - not the drift class name.
  Future<Map<String, List<String>>> _clearableRecordIds({
    required bool preserveStaticData,
  }) async {
    Future<List<String>> ids(String table, [String column = 'id']) async {
      final rows = await customSelect('SELECT $column AS id FROM $table').get();
      return rows.map((r) => r.read<String>('id')).toList();
    }

    return {
      'transactions': await ids('transactions'),
      'accounts': await ids('accounts'),
      'categories': await ids('categories'),
      'asset_entries': await ids('asset_entries'),
      'styles': await ids('styles'),
      'sms_presets': await ids('sms_presets'),
      if (!preserveStaticData) ...{
        'currency_designations': await ids('currency_designations'),
        'account_types': await ids('account_types'),
        'currencies': await ids('currencies', 'code'),
      },
    };
  }

  Future<void> clearAllData({bool preserveStaticData = true}) async {
    // Disable FK checks during clear and reseed
    await customStatement('PRAGMA foreign_keys = OFF');

    final clearedIds = await _clearableRecordIds(
      preserveStaticData: preserveStaticData,
    );

    // Delete all data from tables
    await batch((batch) {
      // Always delete user data
      batch.deleteAll(transactions);
      batch.deleteAll(accounts);
      batch.deleteAll(categories);
      batch.deleteAll(apiFetchStatuses);
      batch.deleteAll(assetEntries);
      batch.deleteAll(settings);
      batch.deleteAll(smsPresets);

      // Clear inflation rates as they are fetched data
      batch.deleteAll(inflationRates);
      batch.deleteAll(exchangeRates);
      batch.deleteAll(styles);
      if (!preserveStaticData) {
        // Only delete static data if strictly requested (Factory Reset)
        batch.deleteAll(currencyDesignations);
        batch.deleteAll(accountTypes);
        batch.deleteAll(currencies);
        batch.deleteAll(languages);
      }
    });

    // Everything still queued for export against a wiped table names a row that
    // no longer exists, so it can only be sent as "nothing" or re-sent from the
    // reseed. Dropping those entries first also keeps a pre-clear upsert from
    // arriving after the tombstone written below and undoing it. Entries for
    // tables the clear does not touch - custom themes, custom data sources, API
    // settings - are deliberately left pending.
    final clearedTables = [
      ...clearedIds.keys,
      'exchange_rates',
      'inflation_rates',
    ];
    await (delete(
      syncLog,
    )..where((l) => l.changedTableName.isIn(clearedTables))).go();

    // Re-seed the data after clearing
    await _seedData(this, skipStaticData: preserveStaticData);

    // Tombstones for everything the wipe removed and the reseed did not bring
    // back. Without them the clear was invisible to the other devices: they
    // still held the accounts, transactions and asset entries the user had just
    // erased, and pushed every one of them back on the next sync, so the data
    // reappeared by itself. Ids the reseed restored (the default styles and
    // categories) are excluded - they exist again, and their reseed upsert has
    // already been logged.
    final now = DateTime.now().millisecondsSinceEpoch;
    final tombstones = <SyncLogCompanion>[];
    for (final entry in clearedIds.entries) {
      final table = _tableForSyncName(entry.key);
      final survivors = table == null
          ? const <String>{}
          : (await customSelect(
              'SELECT ${_idColumnForSyncName(entry.key)} AS id FROM $table',
            ).get()).map((r) => r.read<String>('id')).toSet();
      for (final id in entry.value) {
        if (survivors.contains(id)) continue;
        tombstones.add(
          SyncLogCompanion(
            changedTableName: Value(entry.key),
            recordId: Value(id),
            action: const Value('delete'),
            timestamp: Value(now),
            exported: const Value(false),
          ),
        );
      }
    }
    if (tombstones.isNotEmpty) {
      await batch((batch) => batch.insertAll(syncLog, tombstones));
    }

    // Re-enable FK checks
    await customStatement('PRAGMA foreign_keys = ON');
  }

  /// SQL table behind a `sync_log` table name, for the few tables [clearAllData]
  /// wipes. Returns null when the name is not one of them.
  String? _tableForSyncName(String syncName) => const {
    'transactions': 'transactions',
    'accounts': 'accounts',
    'categories': 'categories',
    'asset_entries': 'asset_entries',
    'styles': 'styles',
    'sms_presets': 'sms_presets',
    'currency_designations': 'currency_designations',
    'account_types': 'account_types',
    'currencies': 'currencies',
  }[syncName];

  /// Currencies are keyed by `code`, everything else by `id`.
  String _idColumnForSyncName(String syncName) =>
      syncName == 'currencies' ? 'code' : 'id';
}

@DriftAccessor(tables: [CustomDataSources, SyncLog])
class CustomDataSourcesDao extends DatabaseAccessor<AppDatabase>
    with _$CustomDataSourcesDaoMixin {
  CustomDataSourcesDao(super.db);

  Future<List<CustomDataSource>> getAllDataSources() => (select(
    customDataSources,
  )..where((t) => t.isDeleted.equals(false))).get();

  Future<CustomDataSource?> getDataSourceById(String id) =>
      (select(customDataSources)
            ..where((tbl) => tbl.id.equals(id) & tbl.isDeleted.equals(false)))
          .getSingleOrNull();

  /// Same lookup, but tombstones included. Callers deciding whether an id is
  /// free must use this one: an id whose row is soft-deleted is still taken,
  /// and treating it as free means inserting over the tombstone, which brings
  /// a deleted endpoint back and starts it fetching again.
  Future<CustomDataSource?> getDataSourceByIdIncludingDeleted(String id) =>
      (select(
        customDataSources,
      )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

  Future<List<CustomDataSource>> getDataSourcesByIds(List<String> ids) async {
    final query = select(customDataSources)
      ..where((t) => t.id.isIn(ids) & t.isDeleted.equals(false));
    return query.get();
  }

  Future<void> insertDataSource(CustomDataSourcesCompanion dataSource) async {
    var toInsert = dataSource.id.present
        ? dataSource
        : dataSource.copyWith(id: Value(_uuid.v4()));

    toInsert = toInsert.copyWith(
      modifiedAt: Value(DateTime.now().millisecondsSinceEpoch),
    );

    await into(
      customDataSources,
    ).insert(toInsert, mode: InsertMode.insertOrReplace);
    await _logChange(toInsert.id.value, 'upsert');
  }

  Future<void> insertSyncedCustomDataSource(
    CustomDataSourcesCompanion dataSource,
  ) => into(
    customDataSources,
  ).insert(dataSource, mode: InsertMode.insertOrReplace);

  Future<void> insertAllDataSources(
    List<CustomDataSourcesCompanion> dataSources,
  ) async {
    final List<CustomDataSourcesCompanion> dataSourcesWithIds = dataSources.map(
      (d) {
        if (d.id.present) return d;
        return d.copyWith(id: Value(_uuid.v4()));
      },
    ).toList();

    await batch((batch) {
      batch.insertAll(
        customDataSources,
        dataSourcesWithIds,
        mode: InsertMode.insertOrReplace,
      );
    });

    final ids = dataSourcesWithIds.map((d) => d.id.value).toList();
    await _logChanges(ids, 'upsert');
  }

  Future<bool> updateCustomDataSource(
    CustomDataSourcesCompanion dataSource,
  ) async {
    final updatedDataSource = dataSource.copyWith(
      // The id addresses the row, it is never part of the new values.
      id: const Value.absent(),
      modifiedAt: Value(DateTime.now().millisecondsSinceEpoch),
    );
    // Deliberately NOT `replace`: replace fills in the table default for every
    // column the caller left out, so an edit built without isDeleted cleared
    // the tombstone and the deleted endpoint started being fetched again, here
    // and on every paired device. Restricting the write to live rows makes
    // editing a deleted source do nothing, which is what the caller expects -
    // it cannot even load one.
    final count =
        await (update(customDataSources)..where(
              (t) =>
                  t.id.equals(dataSource.id.value) & t.isDeleted.equals(false),
            ))
            .write(updatedDataSource);
    final result = count > 0;
    if (result) {
      await _logChange(dataSource.id.value, 'upsert');
    }
    return result;
  }

  Future<int> deleteDataSource(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final count =
        await (update(customDataSources)..where((t) => t.id.equals(id))).write(
          CustomDataSourcesCompanion(
            isDeleted: const Value(true),
            modifiedAt: Value(now),
          ),
        );

    if (count > 0) {
      await _logChange(id, 'delete');
    }
    return count;
  }

  Future<void> _logChange(String recordId, String action) async {
    await into(db.syncLog).insert(
      SyncLogCompanion(
        changedTableName: const Value('custom_data_sources'),
        recordId: Value(recordId),
        action: Value(action),
        timestamp: Value(DateTime.now().millisecondsSinceEpoch),
        exported: const Value(false),
      ),
    );
  }

  Future<void> _logChanges(List<String> recordIds, String action) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await batch((batch) {
      batch.insertAll(
        db.syncLog,
        recordIds
            .map(
              (id) => SyncLogCompanion(
                changedTableName: const Value('custom_data_sources'),
                recordId: Value(id),
                action: Value(action),
                timestamp: Value(timestamp),
                exported: const Value(false),
              ),
            )
            .toList(),
      );
    });
  }
}

@DriftAccessor(tables: [ApiSettingsTable, SyncLog])
class ApiSettingsDao extends DatabaseAccessor<AppDatabase>
    with _$ApiSettingsDaoMixin {
  ApiSettingsDao(super.db);

  Future<List<ApiSettingsTableData>> getAllSettings() => (select(
    apiSettingsTable,
  )..where((tbl) => tbl.isDeleted.equals(false))).get();

  Future<ApiSettingsTableData?> getSettingById(String id) =>
      (select(apiSettingsTable)
            ..where((tbl) => tbl.id.equals(id) & tbl.isDeleted.equals(false)))
          .getSingleOrNull();

  Future<void> upsertSetting(ApiSettingsTableCompanion setting) async {
    final toInsert = setting.copyWith(
      modifiedAt: Value(DateTime.now().millisecondsSinceEpoch),
    );
    await into(apiSettingsTable).insert(toInsert, mode: InsertMode.replace);
    await _logChange(toInsert.id.value, 'upsert');
  }

  Future<List<ApiSettingsTableData>> getSettingsByIds(List<String> ids) async {
    final query = select(apiSettingsTable)
      ..where((t) => t.id.isIn(ids) & t.isDeleted.equals(false));
    return query.get();
  }

  /// Which of [ids] already have a row, tombstones included.
  ///
  /// Anything deciding whether an id is free has to count tombstones as taken:
  /// treating a deleted provider as missing means seeding it again, which is
  /// how a provider the user removed starts fetching by itself.
  Future<Set<String>> existingIds(List<String> ids) async {
    final rows = await (select(
      apiSettingsTable,
    )..where((t) => t.id.isIn(ids))).get();
    return rows.map((r) => r.id).toSet();
  }

  /// Soft-deletes a provider row so the removal can reach the other devices.
  Future<int> deleteSetting(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final count =
        await (update(apiSettingsTable)..where((t) => t.id.equals(id))).write(
          ApiSettingsTableCompanion(
            isDeleted: const Value(true),
            modifiedAt: Value(now),
          ),
        );
    if (count > 0) {
      await _logChange(id, 'delete');
    }
    return count;
  }

  Future<void> insertSyncedApiSetting(ApiSettingsTableCompanion setting) =>
      into(apiSettingsTable).insert(setting, mode: InsertMode.replace);

  Future<void> _logChange(String recordId, String action) async {
    await into(db.syncLog).insert(
      SyncLogCompanion(
        changedTableName: const Value('api_settings_table'),
        recordId: Value(recordId),
        action: Value(action),
        timestamp: Value(DateTime.now().millisecondsSinceEpoch),
        exported: const Value(false),
      ),
    );
  }
}

@DataClassName('ApiFetchStatus')
class ApiFetchStatuses extends Table {
  TextColumn get id => text()(); // Date string yyyy-MM-dd
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastAttempt => dateTime().nullable()();
  TextColumn get status => text().withDefault(
    const Constant('pending'),
  )(); // pending, success, failed, permanent_fail

  @override
  Set<Column> get primaryKey => {id};
}

@DriftAccessor(tables: [ApiFetchStatuses])
class ApiFetchStatusesDao extends DatabaseAccessor<AppDatabase>
    with _$ApiFetchStatusesDaoMixin {
  ApiFetchStatusesDao(super.db);

  Future<ApiFetchStatus?> getStatus(String date) => (select(
    apiFetchStatuses,
  )..where((t) => t.id.equals(date))).getSingleOrNull();

  Future<void> upsertStatus(ApiFetchStatusesCompanion companion) =>
      into(apiFetchStatuses).insertOnConflictUpdate(companion);

  Future<List<ApiFetchStatus>> getAllFailedStatuses() =>
      (select(apiFetchStatuses)..where((t) => t.status.equals('failed'))).get();
}

@DriftAccessor(tables: [SmsPresets])
class SmsPresetsDao extends DatabaseAccessor<AppDatabase>
    with _$SmsPresetsDaoMixin {
  SmsPresetsDao(super.db);

  Future<List<SmsPreset>> getAllPresets() =>
      (select(smsPresets)..where((t) => t.isDeleted.equals(false))).get();
  Stream<List<SmsPreset>> watchAllPresets() =>
      (select(smsPresets)..where((t) => t.isDeleted.equals(false))).watch();
  Future<SmsPreset?> getPresetById(String id) =>
      (select(smsPresets)
            ..where((t) => t.id.equals(id) & t.isDeleted.equals(false)))
          .getSingleOrNull();

  Future<List<SmsPreset>> getPresetsByIds(List<String> ids) => (select(
    smsPresets,
  )..where((t) => t.id.isIn(ids) & t.isDeleted.equals(false))).get();

  /// Writes a preset and queues it for sync.
  ///
  /// The id is settled here rather than left to the column's `clientDefault`,
  /// because the `sync_log` row has to name the record that was just written
  /// and `insert` hands back a rowid, not the uuid.
  Future<int> insertPreset(SmsPresetsCompanion preset) async {
    final withId = preset.id.present
        ? preset
        : preset.copyWith(id: Value(_uuid.v4()));
    // A preset left at modifiedAt 0 is the losing side of every last-write-wins
    // comparison, so a peer's untouched copy would beat the one just typed.
    final toInsert = (withId.modifiedAt.present && withId.modifiedAt.value > 0)
        ? withId
        : withId.copyWith(
            modifiedAt: Value(DateTime.now().millisecondsSinceEpoch),
          );
    final rowId = await into(smsPresets).insert(toInsert);
    await _logChange(toInsert.id.value, 'upsert');
    return rowId;
  }

  Future<bool> updatePreset(SmsPresetsCompanion preset) async {
    // `replace` writes the column default for every column the companion
    // omits, so a partial preset edit un-deleted the row (`isDeleted`), turned
    // it back on (`isEnabled` defaults to true) and reset `modifiedAt` to 0.
    // `write` touches only the fields the caller actually set.
    final stamped = (preset.modifiedAt.present && preset.modifiedAt.value > 0)
        ? preset
        : preset.copyWith(
            modifiedAt: Value(DateTime.now().millisecondsSinceEpoch),
          );
    final count = await (update(
      smsPresets,
    )..where((t) => t.id.equals(stamped.id.value))).write(stamped);
    if (count > 0) {
      await _logChange(stamped.id.value, 'upsert');
    }
    return count > 0;
  }

  Future<int> deletePreset(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final count = await (update(smsPresets)..where((t) => t.id.equals(id)))
        .write(
          SmsPresetsCompanion(
            isDeleted: const Value(true),
            modifiedAt: Value(now),
          ),
        );
    if (count > 0) {
      await _logChange(id, 'delete');
    }
    return count;
  }

  /// Writes a preset that arrived from a peer: no clock of its own and no
  /// `sync_log` row, so it does not travel back where it came from.
  Future<void> insertSyncedPreset(SmsPresetsCompanion preset) =>
      into(smsPresets).insert(preset, mode: InsertMode.replace);

  Future<void> _logChange(String recordId, String action) async {
    await into(db.syncLog).insert(
      SyncLogCompanion(
        changedTableName: const Value('sms_presets'),
        recordId: Value(recordId),
        action: Value(action),
        timestamp: Value(DateTime.now().millisecondsSinceEpoch),
        exported: const Value(false),
      ),
    );
  }
}

@DriftAccessor(tables: [SyncLog])
class SyncLogDao extends DatabaseAccessor<AppDatabase> with _$SyncLogDaoMixin {
  SyncLogDao(super.db);

  /// Log a change for sync export
  Future<int> logChange({
    required String tableName,
    required String recordId,
    required String action, // 'upsert' or 'delete'
  }) => into(syncLog).insert(
    SyncLogCompanion(
      changedTableName: Value(tableName),
      recordId: Value(recordId),
      action: Value(action),
      timestamp: Value(DateTime.now().millisecondsSinceEpoch),
      exported: const Value(false),
    ),
  );

  /// Get all unexported changes
  Future<List<SyncLogData>> getPendingChanges() =>
      (select(syncLog)..where((t) => t.exported.equals(false))).get();

  /// Mark changes as exported.
  ///
  /// Written in chunks because `isIn` binds one SQL variable per id and SQLite
  /// caps a statement at 999 of them. A single statement over a large backlog
  /// threw `SqliteException(1): too many SQL variables`, which the export path
  /// swallowed - so no row was ever marked exported, the log grew without
  /// bound, and every later export re-walked the whole backlog.
  Future<void> markExported(List<int> ids) async {
    if (ids.isEmpty) return;
    const chunkSize = 500;
    await transaction(() async {
      for (var i = 0; i < ids.length; i += chunkSize) {
        final end = (i + chunkSize < ids.length) ? i + chunkSize : ids.length;
        await (update(syncLog)..where((t) => t.id.isIn(ids.sublist(i, end))))
            .write(const SyncLogCompanion(exported: Value(true)));
      }
    });
  }

  /// Clear old exported entries
  Future<int> clearExportedBefore(DateTime cutoff) =>
      (delete(syncLog)
            ..where((t) => t.exported.equals(true))
            ..where(
              (t) => t.timestamp.isSmallerOrEqualValue(
                cutoff.millisecondsSinceEpoch,
              ),
            ))
          .go();
}

@DriftAccessor(tables: [ConflictHistory])
class ConflictHistoryDao extends DatabaseAccessor<AppDatabase>
    with _$ConflictHistoryDaoMixin {
  ConflictHistoryDao(super.db);

  /// Save a rejected version during conflict resolution
  Future<int> saveConflict({
    required String tableName,
    required String recordId,
    required String rejectedDataJson,
    String? rejectedDevice,
  }) => into(conflictHistory).insert(
    ConflictHistoryCompanion(
      changedTableName: Value(tableName),
      recordId: Value(recordId),
      rejectedData: Value(rejectedDataJson),
      rejectedAt: Value(DateTime.now().millisecondsSinceEpoch),
      rejectedDevice: Value(rejectedDevice),
    ),
  );

  /// Get all conflicts for a specific record
  Future<List<ConflictHistoryData>> getConflictsForRecord(String recordId) =>
      (select(
        conflictHistory,
      )..where((t) => t.recordId.equals(recordId))).get();

  /// Get all conflicts
  Future<List<ConflictHistoryData>> getAllConflicts() =>
      select(conflictHistory).get();

  /// Clear old conflicts (keep only last N)
  ///
  /// One statement rather than read-everything-then-delete-by-id: this runs
  /// once per imported packet (`sync_service_io.dart:915`), and the old shape
  /// pulled every conflict row — `rejected_data` is a whole serialised record —
  /// into memory, then built an `IN (...)` list of every id past the keep
  /// window. On a device that has been rejecting writes for a while that is the
  /// table twice, per packet, to delete rows the database can find by itself.
  ///
  /// `id` breaks ties in the ORDER BY so the keep window is deterministic when
  /// several conflicts share a millisecond; without it SQLite may keep a
  /// different N each run and the delete becomes a coin toss.
  Future<void> clearOldConflicts(int maxKeep) async {
    await customStatement(
      'DELETE FROM conflict_history WHERE id NOT IN ('
      'SELECT id FROM conflict_history '
      'ORDER BY rejected_at DESC, id DESC LIMIT ?)',
      [maxKeep < 0 ? 0 : maxKeep],
    );
  }
}

@DriftAccessor(tables: [SyncProcessedFiles])
class SyncProcessedFilesDao extends DatabaseAccessor<AppDatabase>
    with _$SyncProcessedFilesDaoMixin {
  SyncProcessedFilesDao(super.db);

  Future<bool> isProcessed(String fileName) async {
    final query = select(syncProcessedFiles)
      ..where((t) => t.fileName.equals(fileName));
    final result = await query.getSingleOrNull();
    return result != null;
  }

  Future<void> markProcessed(String fileName, String deviceId) async {
    await into(syncProcessedFiles).insert(
      SyncProcessedFilesCompanion(
        fileName: Value(fileName),
        deviceId: Value(deviceId),
        processedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> clearOldProcessed(DateTime cutoff) =>
      (delete(syncProcessedFiles)..where(
            (t) => t.processedAt.isSmallerOrEqualValue(
              cutoff.millisecondsSinceEpoch,
            ),
          ))
          .go();
}
