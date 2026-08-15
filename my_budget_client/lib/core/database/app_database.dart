import 'package:my_budget_client/core/utils/device_utils.dart' as dev_utils;
import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:intl/intl.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:my_budget_client/core/database/connection/database_connection.dart';
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
  TextColumn get name => text().withLength(min: 1, max: 50).unique()();
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
  TextColumn get name => text().withLength(min: 1, max: 50).unique()();
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
  Future<bool> updateLanguage(LanguagesCompanion lang) =>
      update(languages).replace(lang);
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

  Future<bool> updateCurrency(CurrenciesCompanion currency) =>
      update(currencies).replace(currency);
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
    final result = await update(categories).replace(updatedCategory);
    await _logChange(category.id.value, 'upsert');
    return result;
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
    final result = await update(styles).replace(updatedStyle);
    // Only log what actually changed. `replace` returns false when no row
    // matched, and announcing that id anyway makes every peer ask for a style
    // this device does not have - a wasted round trip on the server engine, and
    // an entry the file engine can never resolve.
    if (result) {
      await _logChange(style.id.value, 'upsert');
    }
    return result;
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
    final result = await update(accountTypes).replace(updatedAccountType);
    if (result) {
      await _logChange(accountType.id.value, 'upsert');
    }
    return result;
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
  Future<List<DbAccount>> getAccounts({int limit = 10, int offset = 0}) =>
      (select(accounts)
            ..where((t) => t.isDeleted.equals(false))
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

  Future<void> restoreAccount(AccountsCompanion account) async {
    final toInsert = account.copyWith(
      modifiedAt: Value(DateTime.now().millisecondsSinceEpoch),
    );
    await into(accounts).insert(toInsert, mode: InsertMode.insertOrReplace);
    // The replace writes every column from a companion built out of the domain
    // entity, which carries the balance but not the anchor, so the anchor has
    // to be re-derived from the balance being restored.
    await anchorOpeningBalances([toInsert.id.value]);
  }

  Future<bool> updateAccount(AccountsCompanion account) async {
    final updatedAccount = account.copyWith(
      modifiedAt: Value(DateTime.now().millisecondsSinceEpoch),
    );
    final result = await update(accounts).replace(updatedAccount);
    // The user edits the balance, but the balance is derived; folding the edit
    // into the anchor is what keeps the edit and the transactions behind it
    // consistent, and puts the change on the column that survives a merge.
    await anchorOpeningBalances([account.id.value]);
    // Log change for sync
    await _logChange(account.id.value, 'upsert');
    return result;
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

    query.orderBy([(t) => OrderingTerm(expression: t.balance, mode: sort)]);
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

  Future<void> deleteAccountWithTransactions(String accountId) {
    debugPrint(
      '[AccountsDao] Deleting account $accountId with transactions...',
    ); // LOG
    return db.transaction(() async {
      final now = DateTime.now().millisecondsSinceEpoch;

      // 1. Find all transactions for this account to get their IDs and linked IDs
      final accountTxs = await (select(
        db.transactions,
      )..where((t) => t.accountId.equals(accountId))).get();

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
        final linkedTxs = await (select(
          db.transactions,
        )..where((t) => t.id.isIn(linkedTxIds))).get();
        linkedAccountIds.addAll(linkedTxs.map((t) => t.accountId));
      }

      // 2. Mark account transactions as deleted
      final txUpdate =
          await (update(
            db.transactions,
          )..where((t) => t.accountId.equals(accountId))).write(
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
    });
  }

  Future<void> deleteAccountAndReassignTransactions(
    String accountId,
    String newAccountId,
  ) {
    return db.transaction(() async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final movedTxIds =
          (await (select(
                db.transactions,
              )..where((t) => t.accountId.equals(accountId))).get())
              .map((t) => t.id)
              .toList();
      await (update(
        db.transactions,
      )..where((t) => t.accountId.equals(accountId))).write(
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
  Future<List<Transaction>> getTransactions({int limit = 10, int offset = 0}) =>
      (select(transactions)
            ..where((t) => t.isDeleted.equals(false))
            ..limit(limit, offset: offset))
          .get();
  Future<Transaction?> getTransactionById(String id) =>
      (select(transactions)
            ..where((tbl) => tbl.id.equals(id) & tbl.isDeleted.equals(false)))
          .getSingleOrNull();
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
    final result = await update(transactions).replace(updatedTransaction);
    await _logChange(transaction.id.value, 'upsert');
    return result;
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
    TransactionTypeFilter? transactionType,
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

    query.orderBy([
      (t) => OrderingTerm(expression: t.date, mode: sort),
      (t) => OrderingTerm(expression: t.amount, mode: sort),
    ]);
    query.limit(limit, offset: offset);

    return query.get();
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

    // Step 1: T.Curr -> Base (EUR)
    // Step 2: Base (EUR) -> Main
    // Using correlated subqueries is efficient here because exchange_rates has index on (date, from, to)

    final sql =
        '''
      SELECT 
        t.category_id as categoryId,
        SUM(
          t.amount * 
          -- STEP 1: Transaction Currency -> Base (EUR)
          CASE 
            WHEN t.currency_code = 'EUR' THEN 1.0
            ELSE COALESCE(
              (SELECT rate FROM exchange_rates WHERE date(date/1000, 'unixepoch') = date(t.date/1000, 'unixepoch') AND from_currency_code = t.currency_code AND to_currency_code = 'EUR'),
              CASE WHEN (SELECT rate FROM exchange_rates WHERE date(date/1000, 'unixepoch') = date(t.date/1000, 'unixepoch') AND from_currency_code = 'EUR' AND to_currency_code = t.currency_code) > 0 
                   THEN 1.0 / (SELECT rate FROM exchange_rates WHERE date(date/1000, 'unixepoch') = date(t.date/1000, 'unixepoch') AND from_currency_code = 'EUR' AND to_currency_code = t.currency_code)
                   ELSE 1.0 END,
              1.0
            )
          END *
          -- STEP 2: Base (EUR) -> Main Currency
          CASE 
            WHEN '$mainCurrencyCode' = 'EUR' THEN 1.0
            ELSE COALESCE(
              (SELECT rate FROM exchange_rates WHERE date(date/1000, 'unixepoch') = date(t.date/1000, 'unixepoch') AND from_currency_code = 'EUR' AND to_currency_code = '$mainCurrencyCode'),
              CASE WHEN (SELECT rate FROM exchange_rates WHERE date(date/1000, 'unixepoch') = date(t.date/1000, 'unixepoch') AND from_currency_code = '$mainCurrencyCode' AND to_currency_code = 'EUR') > 0
                   THEN 1.0 / (SELECT rate FROM exchange_rates WHERE date(date/1000, 'unixepoch') = date(t.date/1000, 'unixepoch') AND from_currency_code = '$mainCurrencyCode' AND to_currency_code = 'EUR')
                   ELSE 1.0 END,
              1.0
            )
          END
        ) as total
      FROM transactions t
      $whereClause
      GROUP BY t.category_id
    ''';

    final rows = await customSelect(sql, variables: variables).get();

    final categoryTotals = <String, double>{};
    for (final row in rows) {
      categoryTotals[row.read<String>('categoryId')] = row.read<double>(
        'total',
      );
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
  Future<void> setSetting(SettingsCompanion setting) {
    final toInsert =
        (setting.modifiedAt.present && setting.modifiedAt.value > 0)
        ? setting
        : setting.copyWith(
            modifiedAt: Value(DateTime.now().millisecondsSinceEpoch),
          );
    return into(settings).insert(toInsert, mode: InsertMode.insertOrReplace);
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

  /// Lightweight change signal for the exchange_rates table. Fires on every
  /// insert/update/delete WITHOUT materializing any rows — used to invalidate
  /// the in-memory rate cache in [CurrencyConverterService] so a freshly
  /// added/imported/refreshed rate takes effect without an app restart.
  Stream<void> watchExchangeRateChanges() =>
      tableUpdates(TableUpdateQuery.onTable(exchangeRates));

  Future<List<ExchangeRate>> getAllExchangesRates(List<DateTime> dates) async {
    const int chunkSize = 500;
    List<ExchangeRate> allResults = [];

    for (var i = 0; i < dates.length; i += chunkSize) {
      final end = (i + chunkSize < dates.length) ? i + chunkSize : dates.length;
      final chunk = dates.sublist(i, end);

      final chunkResults = await (select(
        exchangeRates,
      )..where((u) => u.date.isIn(chunk))).get();

      allResults.addAll(chunkResults);
    }

    return allResults;
  }

  Future<List<ExchangeRate>> getAllExchangesRatesAll() =>
      select(exchangeRates).get();

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

    query.orderBy([(t) => OrderingTerm(expression: t.date, mode: sort)]);
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
    final List<ExchangeRatesCompanion> ratesWithTimestamp = [];
    final now = DateTime.now().millisecondsSinceEpoch;

    await batch((batch) {
      for (final r in rates) {
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

  Future<DbCustomTheme?> getActiveTheme() =>
      (select(customThemes)..where(
            (tbl) => tbl.isActive.equals(true) & tbl.isDeleted.equals(false),
          ))
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
    final result = await update(customThemes).replace(updatedTheme);
    await _logChange(theme.id.value, 'upsert');
    return result;
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
    final query = select(inflationRates)
      ..limit(limit, offset: offset)
      ..orderBy([(t) => OrderingTerm(expression: t.date, mode: sort)]);

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
    final query = select(inflationRates)
      ..limit(limit, offset: offset)
      ..orderBy([(t) => OrderingTerm(expression: t.date, mode: sort)]);

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

    query.orderBy([(t) => OrderingTerm(expression: t.date, mode: sort)]);
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

    query.orderBy([(t) => OrderingTerm(expression: t.date, mode: sort)]);
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
    await update(assetEntries).replace(updatedData);
    await _logChange(data.id.value, 'upsert');
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
      // Only when `modified_at` actually moves. A balance rebuild rewrites
      // `balance` on purpose without stamping the row (every peer derives that
      // number for itself), and the server's upsert is strict last-write-wins,
      // so queueing those would upload rows the server is guaranteed to discard
      // — after every single pull, for every account it touched.
      await customStatement(
        'CREATE TRIGGER IF NOT EXISTS trg_push_queue_${table}_update '
        'AFTER UPDATE ON $table WHEN NEW.modified_at IS NOT OLD.modified_at '
        "BEGIN $target ('$table', $key); END",
      );
    }
  }

  @override
  int get schemaVersion => 13;

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
        // After the seed, not before: every install lays down the same bundled
        // rows under the same stable ids, so queueing them would upload ~283k
        // exchange rates the server either already has or would get, byte for
        // byte, from any other client's copy of the same bundle. Everything the
        // user or an API fetch does to them afterwards trips the triggers.
        debugPrint(
          '[DB_MIGRATION] onCreate: creating sync_push_queue triggers...',
        );
        await _createSyncPushQueueTriggers();
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

        // Repair corrupted modifiedAt columns (fix for previous batchUpdateBalances bug)
        // Reset to current time to ensure they are treated as valid updates
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

  Future<void> _seedStyles(AppDatabase db) async {
    await db.stylesDao.insertAllStyles(defaultStyles);
  }

  Future<void> _seedAccountTypes(AppDatabase db) async {
    await db.accountTypesDao.insertAllAccountTypes(defaultAccountTypes);
  }

  Future<void> _seedCategories(AppDatabase db) async {
    final languageCode = Intl.systemLocale.split('_').first;
    await db.categoriesDao.insertAllCategories(
      getDefaultCategories(languageCode),
    );
  }

  Future<void> _seedExchangeRates(AppDatabase db) async {
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
  Future<int> insertPreset(SmsPresetsCompanion preset) =>
      into(smsPresets).insert(preset);
  Future<bool> updatePreset(SmsPresetsCompanion preset) =>
      update(smsPresets).replace(preset);
  Future<int> deletePreset(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (update(smsPresets)..where((t) => t.id.equals(id))).write(
      SmsPresetsCompanion(isDeleted: const Value(true), modifiedAt: Value(now)),
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
  Future<void> clearOldConflicts(int maxKeep) async {
    final all = await (select(
      conflictHistory,
    )..orderBy([(t) => OrderingTerm.desc(t.rejectedAt)])).get();
    if (all.length > maxKeep) {
      final toDelete = all.skip(maxKeep).map((e) => e.id).toList();
      await (delete(conflictHistory)..where((t) => t.id.isIn(toDelete))).go();
    }
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
