import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:my_budget_client/data/seed_data/styles_data.dart';
import 'package:my_budget_client/data/seed_data/exchange_rates_data.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:my_budget_client/data/seed_data/currency_designations_data.dart';
import 'package:my_budget_client/data/seed_data/currencies_data.dart';
import 'package:my_budget_client/data/seed_data/settings_data.dart';
import 'package:my_budget_client/data/seed_data/account_types_data.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:uuid/uuid.dart';

part 'app_database.g.dart';

const _uuid = Uuid();

// --- Business Tables ---

class CurrencyDesignations extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get value => text().withLength(min: 1, max: 5)();
  TextColumn get currencyCode => text().references(Currencies, #code)();

  @override
  Set<Column> get primaryKey => {id};
}

class Currencies extends Table {
  TextColumn get name => text().withLength(min: 1, max: 50).unique()();
  TextColumn get code => text().withLength(min: 1, max: 5)();

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

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Style')
class Styles extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get iconName => text()();
  TextColumn get colorHex => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class AccountTypes extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get name => text().withLength(min: 1, max: 50).unique()();

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

  @override
  Set<Column> get primaryKey => {id};
}

class Transactions extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get description => text().withLength(min: 1, max: 100)();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get accountId => text().references(Accounts, #id)();
  TextColumn get categoryId => text().references(Categories, #id)();
  TextColumn get currencyCode => text().references(Currencies, #code)();

  @override
  Set<Column> get primaryKey => {id};
}

class ExchangeRates extends Table {
  TextColumn get fromCurrencyCode => text().references(Currencies, #code)();
  TextColumn get toCurrencyCode => text().references(Currencies, #code)();
  RealColumn get rate => real()();
  DateTimeColumn get date => dateTime()();

  @override
  Set<Column> get primaryKey => {fromCurrencyCode, toCurrencyCode, date};
}

// --- Technical Tables ---

@DataClassName('Setting')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}


// --- Data Access Objects (DAOs) ---

@DriftAccessor(tables: [CurrencyDesignations])
class CurrencyDesignationsDao extends DatabaseAccessor<AppDatabase>
    with _$CurrencyDesignationsDaoMixin {
  CurrencyDesignationsDao(super.db);

  Future<List<CurrencyDesignation>> getAllDesignations() =>
      select(currencyDesignations).get();
  Stream<List<CurrencyDesignation>> watchAllDesignations() =>
      select(currencyDesignations).watch();
  Future<CurrencyDesignation?> getDesignationById(String id) =>
      (select(currencyDesignations)..where((tbl) => tbl.id.equals(id)))
          .getSingleOrNull();
  Future<void> insertDesignation(CurrencyDesignationsCompanion designation) =>
      into(currencyDesignations).insert(designation);
  Future<bool> updateDesignation(CurrencyDesignationsCompanion designation) =>
      update(currencyDesignations).replace(designation);
  Future<int> deleteDesignation(CurrencyDesignationsCompanion designation) =>
      delete(currencyDesignations).delete(designation);
}

@DriftAccessor(tables: [Currencies])
class CurrenciesDao extends DatabaseAccessor<AppDatabase>
    with _$CurrenciesDaoMixin {
  CurrenciesDao(super.db);

  Future<List<Currency>> getAllCurrencies() => select(currencies).get();
  Stream<List<Currency>> watchAllCurrencies() => select(currencies).watch();
  Future<Currency?> getCurrencyByCode(String code) =>
      (select(currencies)..where((tbl) => tbl.code.equals(code)))
          .getSingleOrNull();
  Future<void> insertCurrency(CurrenciesCompanion currency) =>
      into(currencies).insert(currency);
  Future<bool> updateCurrency(CurrenciesCompanion currency) =>
      update(currencies).replace(currency);
  Future<int> deleteCurrency(CurrenciesCompanion currency) =>
      delete(currencies).delete(currency);
}

@DriftAccessor(tables: [Categories, Transactions])
class CategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  Future<List<Category>> getAllCategories() => select(categories).get();
  Future<Category?> getCategoryById(String id) =>
      (select(categories)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  Stream<List<Category>> watchAllCategories() => select(categories).watch();
  Future<void> insertCategory(CategoriesCompanion category) =>
      into(categories).insert(category);
  Future<bool> updateCategory(CategoriesCompanion category) =>
      update(categories).replace(category);
  Future<int> deleteCategory(CategoriesCompanion category) =>
      delete(categories).delete(category);

  Stream<Map<String, double>> watchCategoryTotals() {
    final amount = attachedDatabase.transactions.amount.total();
    final query = select(attachedDatabase.transactions).join([
      innerJoin(categories,
          categories.id.equalsExp(attachedDatabase.transactions.categoryId))
    ]);
    query.addColumns([amount]);
    query.groupBy([categories.id]);

    return query.watch().map((rows) {
      final a = <String, double>{
        for (final row in rows)
          row.read(categories.id)!: row.read(amount)!
      };
      return a;
    });
  }
}

@DriftAccessor(tables: [Styles])
class StylesDao extends DatabaseAccessor<AppDatabase> with _$StylesDaoMixin {
  StylesDao(super.db);

  Future<List<Style>> getAllStyles() => select(styles).get();
  Stream<List<Style>> watchAllStyles() => select(styles).watch();
  Future<void> insertStyle(StylesCompanion style) => into(styles).insert(style);
  Future<bool> updateStyle(StylesCompanion style) =>
      update(styles).replace(style);
  Future<int> deleteStyle(StylesCompanion style) =>
      delete(styles).delete(style);
}

@DriftAccessor(tables: [AccountTypes])
class AccountTypesDao extends DatabaseAccessor<AppDatabase>
    with _$AccountTypesDaoMixin {
  AccountTypesDao(super.db);

  Future<List<AccountType>> getAllAccountTypes() => select(accountTypes).get();
  Stream<List<AccountType>> watchAllAccountTypes() =>
      select(accountTypes).watch();
  Future<AccountType?> getAccountTypeById(String id) =>
      (select(accountTypes)..where((tbl) => tbl.id.equals(id)))
          .getSingleOrNull();
  Future<void> insertAccountType(AccountTypesCompanion accountType) =>
      into(accountTypes).insert(accountType);
  Future<bool> updateAccountType(AccountTypesCompanion accountType) =>
      update(accountTypes).replace(accountType);
  Future<int> deleteAccountType(AccountTypesCompanion accountType) =>
      delete(accountTypes).delete(accountType);
}

@DriftAccessor(tables: [Accounts])
class AccountsDao extends DatabaseAccessor<AppDatabase> with _$AccountsDaoMixin {
  AccountsDao(super.db);

  Future<List<DbAccount>> getAllAccounts() => select(accounts).get();
  Future<DbAccount?> getAccountById(String id) =>
      (select(accounts)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  Stream<List<DbAccount>> watchAllAccounts() => select(accounts).watch();
  Future<void> insertAccount(AccountsCompanion account) =>
      into(accounts).insert(account);
  Future<void> restoreAccount(AccountsCompanion account) =>
      into(accounts).insert(account, mode: InsertMode.insertOrReplace);
  Future<bool> updateAccount(AccountsCompanion account) =>
      update(accounts).replace(account);
  Future<int> deleteAccount(AccountsCompanion account) =>
      delete(accounts).delete(account);
}

@DriftAccessor(tables: [Transactions])
class TransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionsDaoMixin {
  TransactionsDao(super.db);

  Future<List<Transaction>> getAllTransactions() => select(transactions).get();
  Future<Transaction?> getTransactionById(String id) =>
      (select(transactions)..where((tbl) => tbl.id.equals(id)))
          .getSingleOrNull();
  Future<List<Transaction>> getTransactionsByCategoryId(String categoryId) =>
      (select(transactions)..where((tbl) => tbl.categoryId.equals(categoryId)))
          .get();
  Stream<List<Transaction>> watchAllTransactions() =>
      select(transactions).watch();
  Future<void> insertTransaction(TransactionsCompanion transaction) =>
      into(transactions).insert(transaction);
  Future<bool> updateTransaction(TransactionsCompanion transaction) =>
      update(transactions).replace(transaction);
  Future<int> deleteTransaction(TransactionsCompanion transaction) =>
      delete(transactions).delete(transaction);
}

@DriftAccessor(tables: [Settings])
class SettingsDao extends DatabaseAccessor<AppDatabase> with _$SettingsDaoMixin {
  SettingsDao(super.db);

  Stream<List<Setting>> watchAllSettings() => select(settings).watch();
  Stream<Setting?> watchSetting(String key) {
    return (select(settings)..where((tbl) => tbl.key.equals(key)))
        .watchSingleOrNull();
  }

  Future<Setting?> getSetting(String key) =>
      (select(settings)..where((tbl) => tbl.key.equals(key))).getSingleOrNull();
  Future<void> setSetting(Setting setting) =>
      into(settings).insert(setting, mode: InsertMode.insertOrReplace);
}

@DriftAccessor(tables: [ExchangeRates])
class ExchangeRatesDao extends DatabaseAccessor<AppDatabase>
    with _$ExchangeRatesDaoMixin {
  ExchangeRatesDao(super.db);

  Stream<List<ExchangeRate>> watchAllExchangeRates() =>
      select(exchangeRates).watch();
  Future<void> addExchangeRate(ExchangeRatesCompanion rate) =>
      into(exchangeRates).insert(rate);
}



@DriftDatabase(tables: [
  // Business Tables
  CurrencyDesignations,
  Currencies,
  Categories,
  Styles,
  Accounts,
  Transactions,
  AccountTypes,
  ExchangeRates,
  // Technical Tables
  Settings,
], daos: [
  CurrencyDesignationsDao,
  CurrenciesDao,
  CategoriesDao,
  StylesDao,
  AccountTypesDao,
  AccountsDao,
  TransactionsDao,
  SettingsDao,
  ExchangeRatesDao,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.connection);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _seedData(this);
      },
      onUpgrade: (Migrator m, int from, int to) async {
        for (final table in allTables) {
          await m.deleteTable(table.actualTableName);
          await m.createTable(table);
        }
        await _seedData(this);
      },
    );
  }

  Future<void> _seedData(AppDatabase db) async {
    await _seedCurrencyDesignations(db);
    await _seedCurrencies(db);
    await _seedSettings(db);
    await _seedStyles(db);
    await _seedAccountTypes(db);
    await _seedExchangeRates(db);
  }

  // --- Seeding Methods ---

  Future<void> _seedCurrencyDesignations(AppDatabase db) async {
    for (final designation in defaultCurrencyDesignations) {
      await db.into(db.currencyDesignations).insert(designation);
    }
  }

  Future<void> _seedCurrencies(AppDatabase db) async {
    for (final currency in defaultCurrencies) {
      await db.into(db.currencies).insert(currency);
    }
  }

  Future<void> _seedSettings(AppDatabase db) async {
    for (final setting in defaultSettings) {
      await db.settingsDao.setSetting(setting);
    }
  }

  Future<void> _seedStyles(AppDatabase db) async {
    for (final style in defaultStyles) {
      await db.into(db.styles).insert(style);
    }
  }

  Future<void> _seedAccountTypes(AppDatabase db) async {
    for (final accountType in defaultAccountTypes) {
      await db.into(db.accountTypes).insert(accountType);
    }
  }

  Future<void> _seedExchangeRates(AppDatabase db) async {
    for (final rate in defaultExchangeRates) {
      await db.into(db.exchangeRates).insert(rate);
    }
  }

  Future<void> clearAllData() async {
    // Delete all data from tables
    await batch((batch) {
      for (final table in allTables) {
        batch.deleteAll(table);
      }
    });
    // Re-seed the data after clearing
    await _seedData(this);
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}
