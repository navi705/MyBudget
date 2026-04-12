import 'package:my_budget_client/core/utils/device_utils.dart' as dev_utils;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:intl/intl.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:my_budget_client/core/database/connection/database_connection.dart';
import 'package:my_budget_client/core/mappers/exchange_rate_mapper.dart';
import 'package:my_budget_client/core/utils/device_utils.dart';
import 'package:my_budget_client/core/utils/import_utils.dart';
import 'package:my_budget_client/data/seed_data/styles_data.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
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
@TableIndex(name: 'idx_transactions_date_category', columns: {#date, #categoryId})
@TableIndex(name: 'idx_transactions_account_date', columns: {#accountId, #date})
class Transactions extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get description => text().withLength(min: 1, max: 100)();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get accountId => text().references(Accounts, #id)();
  TextColumn get categoryId => text().references(Categories, #id)();
  TextColumn get currencyCode => text().references(Currencies, #code)();
  RealColumn get exchangeRate => real().nullable()(); // Added
  IntColumn get exchangeRatePreset => integer().nullable()(); // Added
  RealColumn get fee =>
      real().withDefault(const Constant(0.0))(); // Added: Fee/Commission
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

class InflationRates extends Table {
  DateTimeColumn get date => dateTime()();
  RealColumn get percent => real()();
  TextColumn get country => text().nullable()();
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
    final query = select(currencyDesignations)
      ..where((t) => t.id.isIn(ids) & t.isDeleted.equals(false));
    return query.get();
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
      modifiedAt:
          (designation.modifiedAt.present && designation.modifiedAt.value > 0)
          ? designation.modifiedAt
          : Value(DateTime.now().millisecondsSinceEpoch),
    );
    final result = await update(
      currencyDesignations,
    ).replace(updatedDesignation);
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
  Future<void> insertCurrency(CurrenciesCompanion currency) =>
      into(currencies).insert(currency);
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
    });
  }

  Future<void> deleteCategoryAndReassignTransactions(
    String categoryId,
    String newCategoryId,
  ) {
    return db.transaction(() async {
      final now = DateTime.now().millisecondsSinceEpoch;
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
    List<String> whereClauses = [];

    if (dateFrom != null) {
      whereClauses.add('date >= ?');
      variables.add(Variable.withDateTime(dateFrom));
    }
    if (dateTo != null) {
      whereClauses.add('date <= ?');
      variables.add(Variable.withDateTime(dateTo));
    }

    if (whereClauses.isNotEmpty) {
      sql += ' WHERE ${whereClauses.join(' AND ')}';
    }

    sql += '''
        GROUP BY category_id
      ) t ON t.category_id = c.id
    ''';

    List<String> outerWhereClauses = [];
    if (name != null && name.isNotEmpty) {
      outerWhereClauses.add('c.name LIKE ?');
      variables.add(Variable('%$name%'));
    }
    if (type != null) {
      outerWhereClauses.add('c.type = ?');
      variables.add(Variable(type.index));
    }

    if (outerWhereClauses.isNotEmpty) {
      sql += ' WHERE ${outerWhereClauses.join(' AND ')}';
    }

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
    await _logChange(style.id.value, 'upsert');
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
    final query = select(accountTypes)
      ..where((t) => t.id.isIn(ids) & t.isDeleted.equals(false));
    return query.get();
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
  Future<List<DbAccount>> getAccountsByIds(List<String> ids) => (select(
    accounts,
  )..where((tbl) => tbl.id.isIn(ids) & tbl.isDeleted.equals(false))).get();

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
    // Log change for sync
    await _logChange(toInsert.id.value, 'upsert');
  }

  Future<void> insertSyncedAccount(AccountsCompanion account) =>
      into(accounts).insert(account, mode: InsertMode.insertOrReplace);

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

  Future<void> restoreAccount(AccountsCompanion account) {
    final toInsert = account.copyWith(
      modifiedAt: Value(DateTime.now().millisecondsSinceEpoch),
    );
    return into(accounts).insert(toInsert, mode: InsertMode.insertOrReplace);
  }

  Future<bool> updateAccount(AccountsCompanion account) async {
    final updatedAccount = account.copyWith(
      modifiedAt: Value(DateTime.now().millisecondsSinceEpoch),
    );
    final result = await update(accounts).replace(updatedAccount);
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

  Future<void> adjustBalance(String accountId, double amount) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return customUpdate(
      'UPDATE accounts SET balance = balance + ?, modified_at = ? WHERE id = ?',
      variables: [Variable(amount), Variable(now), Variable(accountId)],
      updates: {accounts},
    );
  }

  Future<void> batchUpdateBalances(Map<String, double> amountChanges) {
    if (amountChanges.isEmpty) {
      return Future.value();
    }

    final accountIds = amountChanges.keys.toList();
    final caseClauses = <String>[];
    final variables = <Variable>[];

    // Build CASE clauses and their variables
    for (final accountId in accountIds) {
      caseClauses.add('WHEN ? THEN ?');
      variables.add(Variable(accountId));
      variables.add(Variable(amountChanges[accountId]!));
    }

    // Build IN clause variables
    final idsInClause = List.filled(accountIds.length, '?').join(', ');
    final now = DateTime.now().millisecondsSinceEpoch;
    variables.add(Variable(now));

    for (final accountId in accountIds) {
      variables.add(Variable(accountId));
    }

    final sql =
        '''
      UPDATE accounts
      SET balance = balance + (CASE id ${caseClauses.join(' ')} END),
          modified_at = ?
      WHERE id IN ($idsInClause)
    ''';

    return customUpdate(sql, variables: variables, updates: {accounts});
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
  ) {
    return (update(accounts)..where((tbl) => tbl.id.isIn(ids))).write(
      AccountsCompanion(accountTypeId: Value(accountTypeId)),
    );
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

      await _logChange(accountId, 'delete');
      if (txIds.isNotEmpty) await _logChanges(txIds, 'delete');
      if (linkedTxIds.isNotEmpty) await _logChanges(linkedTxIds, 'delete');
    });
  }

  Future<void> deleteAccountAndReassignTransactions(
    String accountId,
    String newAccountId,
  ) {
    return db.transaction(() async {
      final now = DateTime.now().millisecondsSinceEpoch;
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
      await _logChange(accountId, 'delete');
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

    return (update(transactions)
          ..where((t) => t.id.equals(transaction.id.value)))
        .write(updatedTransaction);
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

  Future<List<Transaction>> getTransactionsByIds(List<String> ids) {
    return (select(
      transactions,
    )..where((tbl) => tbl.id.isIn(ids) & tbl.isDeleted.equals(false))).get();
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
  ) {
    return (update(transactions)..where((tbl) => tbl.id.isIn(ids))).write(
      TransactionsCompanion(date: Value(newDate)),
    );
  }

  Future<void> updateCategoryForMultipleTransactions(
    List<String> ids,
    String newCategoryId,
  ) {
    return (update(transactions)..where((tbl) => tbl.id.isIn(ids))).write(
      TransactionsCompanion(categoryId: Value(newCategoryId)),
    );
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

  Future<List<GroupedTransactionTotal>> getTransactionTotalsGrouped({
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final amountExp = transactions.amount.sum();
    final query = selectOnly(transactions)
      ..addColumns([
        transactions.categoryId,
        transactions.currencyCode,
        transactions.date,
        amountExp,
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
      return GroupedTransactionTotal(
        categoryId: row.read(transactions.categoryId)!,
        currencyCode: row.read(transactions.currencyCode)!,
        date: row.read(transactions.date)!,
        total: row.read(amountExp) ?? 0.0,
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
  Future<void> setSetting(SettingsCompanion setting) =>
      into(settings).insert(setting, mode: InsertMode.insertOrReplace);

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
    final date = DateFormat('yyyy-MM-dd').format(toInsert.date.value);
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
    final date = DateFormat('yyyy-MM-dd').format(updatedRate.date.value);
    final preset = updatedRate.preset.value;
    final recordId = '${from}_${to}_${date}_$preset';
    await _logChange(recordId, 'upsert');
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

    // Log changes for sync (especially useful if fetched from custom API)
    final List<String> recordIds = ratesWithTimestamp.map((r) {
      // For exchange rates, the unique ID for sync log is a composite string
      // but since record_id is a single text column, we use a stable format:
      // from_to_date_preset
      final from = r.fromCurrencyCode.value;
      final to = r.toCurrencyCode.value;
      final date = DateFormat('yyyy-MM-dd').format(r.date.value);
      final preset = r.preset.value;
      return '${from}_${to}_${date}_$preset';
    }).toList();

    await _logChanges(recordIds, 'upsert');
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

  Future<void> _logChanges(List<String> recordIds, String action) async {
    final now = DateTime.now();
    await batch((batch) {
      for (final id in recordIds) {
        batch.insert(
          db.syncLog,
          SyncLogCompanion(
            changedTableName: const Value('exchange_rates'),
            recordId: Value(id),
            action: Value(action),
            timestamp: Value(now.millisecondsSinceEpoch),
          ),
        );
      }
    });
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

  Future<void> insertTheme(CustomThemesCompanion theme) {
    var toInsert = theme.id.present
        ? theme
        : theme.copyWith(id: Value(_uuid.v4()));

    toInsert = toInsert.copyWith(
      modifiedAt: Value(DateTime.now().millisecondsSinceEpoch),
    );
    return into(
      customThemes,
    ).insert(toInsert, mode: InsertMode.insertOrReplace);
  }

  Future<void> insertSyncedTheme(CustomThemesCompanion theme) =>
      into(customThemes).insert(theme, mode: InsertMode.insertOrReplace);

  Future<void> insertAllThemes(List<CustomThemesCompanion> themes) {
    return batch((batch) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final themesWithIds = themes.map((t) {
        var companion = t;
        if (!companion.id.present) {
          companion = companion.copyWith(id: Value(_uuid.v4()));
        }
        return companion.copyWith(modifiedAt: Value(now));
      }).toList();
      batch.insertAll(
        customThemes,
        themesWithIds,
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  Future<bool> updateTheme(CustomThemesCompanion theme) {
    final updatedTheme = theme.copyWith(
      modifiedAt: Value(DateTime.now().millisecondsSinceEpoch),
    );
    return update(customThemes).replace(updatedTheme);
  }

  Future<int> deleteTheme(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (update(customThemes)..where((t) => t.id.equals(id))).write(
      CustomThemesCompanion(
        isDeleted: const Value(true),
        modifiedAt: Value(now),
      ),
    );
  }

  Future<void> setActiveTheme(String id) {
    return transaction(() async {
      final now = DateTime.now().millisecondsSinceEpoch;
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
    final toInsert = rate.copyWith(modifiedAt: Value(now));
    await into(
      inflationRates,
    ).insert(toInsert, mode: InsertMode.insertOrReplace);

    // Log change for sync
    final date = DateFormat('yyyy-MM-dd').format(toInsert.date.value);
    final country = toInsert.country.value ?? 'global';
    final preset = toInsert.preset.value;
    final recordId = '${date}_${country}_$preset';
    await _logChange(recordId, 'upsert');
  }

  Future<void> insertAllInflationRates(
    List<InflationRatesCompanion> rates,
  ) async {
    final List<String> recordIds = [];
    final now = DateTime.now().millisecondsSinceEpoch;

    await batch((batch) {
      for (final r in rates) {
        final withTs = r.copyWith(modifiedAt: Value(now));
        batch.insert(inflationRates, withTs, mode: InsertMode.insertOrReplace);

        final date = DateFormat('yyyy-MM-dd').format(withTs.date.value);
        final country = withTs.country.value ?? 'global';
        final preset = withTs.preset.value;
        recordIds.add('${date}_${country}_$preset');
      }
    });

    for (final id in recordIds) {
      await _logChange(id, 'upsert');
    }
  }

  Future<void> insertSyncedInflationRate(InflationRatesCompanion rate) =>
      into(inflationRates).insert(rate, mode: InsertMode.insertOrReplace);

  Future<void> deleteInflationRate(DateTime date, String? country, int preset) {
    return (delete(inflationRates)..where(
          (tbl) =>
              tbl.date.equals(date) &
              (country == null
                  ? tbl.country.isNull()
                  : tbl.country.equals(country)) &
              tbl.preset.equals(preset),
        ))
        .go();
  }

  Future<bool> updateInflationRate(InflationRatesCompanion rate) {
    final updatedRate = rate.copyWith(
      modifiedAt: Value(DateTime.now().millisecondsSinceEpoch),
    );
    return update(inflationRates).replace(updatedRate);
  }

  Future<void> deleteInflationRates(List<InflationRateDomain> rates) async {
    await batch((batch) {
      for (final rate in rates) {
        batch.delete(
          inflationRates,
          InflationRatesCompanion(
            date: Value(rate.date),
            country: Value(rate.country),
            preset: Value(rate.preset),
          ),
        );
      }
    });
  }

  Future<List<String>> getAvailableCountries() async {
    final query = selectOnly(inflationRates, distinct: true)
      ..addColumns([inflationRates.country])
      ..where(inflationRates.country.isNotNull());

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

  Future<void> _logChange(String recordId, String action) async {
    await into(db.syncLog).insert(
      SyncLogCompanion(
        changedTableName: const Value('inflation_rates'),
        recordId: Value(recordId),
        action: Value(action),
      ),
    );
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

  Future<List<AssetEntry>> getAssetEntriesByIds(List<String> ids) => (select(
    assetEntries,
  )..where((t) => t.id.isIn(ids) & t.isDeleted.equals(false))).get();

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

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        debugPrint('[DB_MIGRATION] onCreate START');
        debugPrint('[DB_MIGRATION] onCreate: calling m.createAll() (tables + @TableIndex indexes)...');
        await m.createAll();
        debugPrint('[DB_MIGRATION] onCreate: m.createAll() done');
        debugPrint('[DB_MIGRATION] onCreate: calling _seedData...');
        await _seedData(this);
        debugPrint('[DB_MIGRATION] onCreate: _seedData done');
        debugPrint('[DB_MIGRATION] onCreate: creating partial UNIQUE INDEX idx_asset_entries_custom_api_dedup...');
        await customStatement(
          'CREATE UNIQUE INDEX IF NOT EXISTS idx_asset_entries_custom_api_dedup '
          'ON asset_entries (asset_id, date, source) '
          "WHERE source = 'custom_api'",
        );
        debugPrint('[DB_MIGRATION] onCreate END');
      },
      onUpgrade: (Migrator m, int from, int to) async {
        debugPrint('[DB_MIGRATION] onUpgrade: from=$from to=$to');

        if (from < 2) {
          debugPrint('[DB_MIGRATION] v1→v2: adding sync columns to styles/accountTypes/currencyDesignations...');
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
          debugPrint('[DB_MIGRATION] v2→v3: adding sync columns to all tables...');
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
          debugPrint('[DB_MIGRATION] v3→v4: creating syncProcessedFiles table...');
          await m.createTable(syncProcessedFiles);
          debugPrint('[DB_MIGRATION] v3→v4: complete');
        }

        if (from < 5) {
          debugPrint('[DB_MIGRATION] v4→v5: re-seeding data...');
          await _seedData(this);
          debugPrint('[DB_MIGRATION] v4→v5: complete');
        }

        if (from < 6) {
          debugPrint('[DB_MIGRATION] v5→v6: creating composite indexes on transactions...');
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_transactions_date_category '
            'ON transactions (date, category_id)',
          );
          debugPrint('[DB_MIGRATION] v5→v6: idx_transactions_date_category created');
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_transactions_account_date '
            'ON transactions (account_id, date)',
          );
          debugPrint('[DB_MIGRATION] v5→v6: idx_transactions_account_date created');
          debugPrint('[DB_MIGRATION] v5→v6: complete');
        }

        if (from < 7) {
          debugPrint('[DB_MIGRATION] v6→v7: deduplicating asset_entries for custom_api...');
          try {
            await customStatement(
              '''DELETE FROM asset_entries
                 WHERE source = 'custom_api'
                 AND rowid NOT IN (
                   SELECT MAX(rowid)
                   FROM asset_entries
                   WHERE source = 'custom_api'
                   GROUP BY asset_id, date(date / 1000, 'unixepoch')
                 )''',
            );
            debugPrint('[DB_MIGRATION] v6→v7: dedup DELETE complete');
          } catch (e) {
            debugPrint('[DB_MIGRATION] v6→v7: dedup DELETE error (non-fatal, continuing): $e');
          }

          debugPrint('[DB_MIGRATION] v6→v7: creating partial UNIQUE INDEX idx_asset_entries_custom_api_dedup...');
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
            debugPrint('[DB_MIGRATION] v6→v7: retrying dedup with stricter DELETE...');
            await customStatement(
              '''DELETE FROM asset_entries
                 WHERE source = 'custom_api'
                 AND id NOT IN (
                   SELECT MAX(id)
                   FROM asset_entries
                   WHERE source = 'custom_api'
                   GROUP BY asset_id, date
                 )''',
            );
            debugPrint('[DB_MIGRATION] v6→v7: strict dedup complete, retrying index...');
            await customStatement(
              'CREATE UNIQUE INDEX IF NOT EXISTS idx_asset_entries_custom_api_dedup '
              'ON asset_entries (asset_id, date, source) '
              "WHERE source = 'custom_api'",
            );
            debugPrint('[DB_MIGRATION] v6→v7: UNIQUE INDEX created on retry');
          }
          debugPrint('[DB_MIGRATION] v6→v7: complete');
        }

        debugPrint('[DB_MIGRATION] onUpgrade complete: from=$from to=$to');
      },
      beforeOpen: (details) async {
        debugPrint('[DB_MIGRATION] beforeOpen START: wasCreated=${details.wasCreated} versionBefore=${details.versionBefore} versionNow=${details.versionNow}');
        debugPrint('[DB_MIGRATION] beforeOpen: executing PRAGMA foreign_keys = ON...');
        await customStatement('PRAGMA foreign_keys = ON');
        debugPrint('[DB_MIGRATION] beforeOpen: PRAGMA foreign_keys = ON done');

        // Repair corrupted modifiedAt columns (fix for previous batchUpdateBalances bug)
        // Reset to current time to ensure they are treated as valid updates
        final now = DateTime.now().millisecondsSinceEpoch;
        debugPrint('[DB_MIGRATION] beforeOpen: executing corrupted modified_at repair...');
        await customStatement(
          "UPDATE accounts SET modified_at = $now WHERE typeof(modified_at) = 'text'",
        );
        debugPrint('[DB_MIGRATION] beforeOpen END: corrupted modified_at repaired');
      },
    );
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

  Future<void> _seedApiSettings(AppDatabase db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.apiSettingsDao.upsertSetting(
      ApiSettingsTableCompanion(
        id: const Value('exchange_rates'),
        enabled: const Value(true),
        autoFetch: const Value(true),
        modifiedAt: Value(now),
      ),
    );
    await db.apiSettingsDao.upsertSetting(
      ApiSettingsTableCompanion(
        id: const Value('inflation'),
        enabled: const Value(true),
        autoFetch: const Value(true),
        modifiedAt: Value(now),
      ),
    );
    await db.apiSettingsDao.upsertSetting(
      ApiSettingsTableCompanion(
        id: const Value('assets'),
        enabled: const Value(true),
        autoFetch: const Value(true),
        modifiedAt: Value(now),
      ),
    );
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
    debugPrint('[DB_SEED] _seedExchangeRates: calling getCurrenciesRateToSeeder...');
    final List<ExchangeRateDomain> rates =
        await ImportDataUtils.getCurrenciesRateToSeeder();
    debugPrint('[DB_SEED] _seedExchangeRates: got ${rates.length} rates, inserting...');
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

  Future<void> clearAllData({bool preserveStaticData = true}) async {
    // Disable FK checks during clear and reseed
    await customStatement('PRAGMA foreign_keys = OFF');

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

    // Re-seed the data after clearing
    await _seedData(this, skipStaticData: preserveStaticData);

    // Re-enable FK checks
    await customStatement('PRAGMA foreign_keys = ON');
  }
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

    await into(customDataSources).insert(
      toInsert,
      mode: InsertMode.insertOrReplace,
    );
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
      modifiedAt: Value(DateTime.now().millisecondsSinceEpoch),
    );
    final result = await update(customDataSources).replace(updatedDataSource);
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

  Future<List<ApiSettingsTableData>> getAllSettings() =>
      select(apiSettingsTable).get();

  Future<ApiSettingsTableData?> getSettingById(String id) => (select(
    apiSettingsTable,
  )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

  Future<void> upsertSetting(ApiSettingsTableCompanion setting) async {
    final toInsert = setting.copyWith(
      modifiedAt: Value(DateTime.now().millisecondsSinceEpoch),
    );
    await into(apiSettingsTable).insert(toInsert, mode: InsertMode.replace);
    await _logChange(toInsert.id.value, 'upsert');
  }

  Future<List<ApiSettingsTableData>> getSettingsByIds(List<String> ids) async {
    final query = select(apiSettingsTable)..where((t) => t.id.isIn(ids));
    return query.get();
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

  /// Mark changes as exported
  Future<void> markExported(List<int> ids) async {
    await (update(syncLog)..where((t) => t.id.isIn(ids))).write(
      const SyncLogCompanion(exported: Value(true)),
    );
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
