
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:my_budget_client/data/seed_data/account_styles_data.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:my_budget_client/data/seed_data/currency_designations_data.dart';
import 'package:my_budget_client/data/seed_data/currencies_data.dart';
import 'package:my_budget_client/data/seed_data/settings_data.dart';

part 'app_database.g.dart';

// --- Business Tables ---

class CurrencyDesignations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get value => text().withLength(min: 1, max: 5)();
}

class Currencies extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50).unique()();
  TextColumn get code => text().withLength(min: 1, max: 5).unique()();
  IntColumn get designationId => integer().references(CurrencyDesignations, #id)();
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  IntColumn get parentId => integer().nullable().references(Categories, #id)();
}

@DataClassName('AccountStyle')
class AccountStyles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get iconName => text()();
  TextColumn get colorHex => text()();
}

class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  RealColumn get balance => real()();
  IntColumn get currencyId => integer().references(Currencies, #id)();
  IntColumn get styleId => integer().nullable().references(AccountStyles, #id)();
}

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get description => text().withLength(min: 1, max: 100)();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  IntColumn get accountId => integer().references(Accounts, #id)();
  IntColumn get categoryId => integer().references(Categories, #id)();
  IntColumn get currencyId => integer().references(Currencies, #id)();
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
class CurrencyDesignationsDao extends DatabaseAccessor<AppDatabase> with _$CurrencyDesignationsDaoMixin {
  CurrencyDesignationsDao(super.db);

  Future<List<CurrencyDesignation>> getAllDesignations() => select(currencyDesignations).get();
  Stream<List<CurrencyDesignation>> watchAllDesignations() => select(currencyDesignations).watch();
  Future<CurrencyDesignation?> getDesignationById(int id) => (select(currencyDesignations)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  Future<int> insertDesignation(CurrencyDesignationsCompanion designation) => into(currencyDesignations).insert(designation);
  Future<bool> updateDesignation(CurrencyDesignationsCompanion designation) => update(currencyDesignations).replace(designation);
  Future<int> deleteDesignation(CurrencyDesignationsCompanion designation) => delete(currencyDesignations).delete(designation);
}

@DriftAccessor(tables: [Currencies])
class CurrenciesDao extends DatabaseAccessor<AppDatabase> with _$CurrenciesDaoMixin {
  CurrenciesDao(super.db);

  Future<List<Currency>> getAllCurrencies() => select(currencies).get();
  Stream<List<Currency>> watchAllCurrencies() => select(currencies).watch();
  Future<Currency?> getCurrencyById(int id) => (select(currencies)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  Future<int> insertCurrency(CurrenciesCompanion currency) => into(currencies).insert(currency);
  Future<bool> updateCurrency(CurrenciesCompanion currency) => update(currencies).replace(currency);
  Future<int> deleteCurrency(CurrenciesCompanion currency) => delete(currencies).delete(currency);
}

@DriftAccessor(tables: [Categories])
class CategoriesDao extends DatabaseAccessor<AppDatabase> with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  Future<List<Category>> getAllCategories() => select(categories).get();
  Future<Category?> getCategoryById(int id) => (select(categories)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  Stream<List<Category>> watchAllCategories() => select(categories).watch();
  Future<int> insertCategory(CategoriesCompanion category) => into(categories).insert(category);
  Future<bool> updateCategory(CategoriesCompanion category) => update(categories).replace(category);
  Future<int> deleteCategory(CategoriesCompanion category) => delete(categories).delete(category);
}

@DriftAccessor(tables: [AccountStyles])
class AccountStylesDao extends DatabaseAccessor<AppDatabase> with _$AccountStylesDaoMixin {
  AccountStylesDao(super.db);

  Future<List<AccountStyle>> getAllStyles() => select(accountStyles).get();
  Stream<List<AccountStyle>> watchAllStyles() => select(accountStyles).watch();
  Future<int> insertStyle(AccountStylesCompanion style) => into(accountStyles).insert(style);
  Future<bool> updateStyle(AccountStylesCompanion style) => update(accountStyles).replace(style);
  Future<int> deleteStyle(AccountStylesCompanion style) => delete(accountStyles).delete(style);
}

@DriftAccessor(tables: [Accounts])
class AccountsDao extends DatabaseAccessor<AppDatabase> with _$AccountsDaoMixin {
  AccountsDao(super.db);

  Future<List<Account>> getAllAccounts() => select(accounts).get();
  Future<Account?> getAccountById(int id) => (select(accounts)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  Stream<List<Account>> watchAllAccounts() => select(accounts).watch();
  Future<int> insertAccount(AccountsCompanion account) => into(accounts).insert(account);
  Future<bool> updateAccount(AccountsCompanion account) => update(accounts).replace(account);
  Future<int> deleteAccount(AccountsCompanion account) => delete(accounts).delete(account);
}

@DriftAccessor(tables: [Transactions])
class TransactionsDao extends DatabaseAccessor<AppDatabase> with _$TransactionsDaoMixin {
  TransactionsDao(super.db);

  Future<List<Transaction>> getAllTransactions() => select(transactions).get();
  Future<Transaction?> getTransactionById(int id) => (select(transactions)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  Stream<List<Transaction>> watchAllTransactions() => select(transactions).watch();
  Future<int> insertTransaction(TransactionsCompanion transaction) => into(transactions).insert(transaction);
  Future<bool> updateTransaction(TransactionsCompanion transaction) => update(transactions).replace(transaction);
  Future<int> deleteTransaction(TransactionsCompanion transaction) => delete(transactions).delete(transaction);
}

@DriftAccessor(tables: [Settings])
class SettingsDao extends DatabaseAccessor<AppDatabase> with _$SettingsDaoMixin {
  SettingsDao(super.db);

  Stream<List<Setting>> watchAllSettings() => select(settings).watch();
  Future<Setting?> getSetting(String key) => (select(settings)..where((tbl) => tbl.key.equals(key))).getSingleOrNull();
  Future<void> setSetting(Setting setting) => into(settings).insert(setting, mode: InsertMode.insertOrReplace);
}


@DriftDatabase(tables: [
  // Business Tables
  CurrencyDesignations,
  Currencies,
  Categories,
  AccountStyles,
  Accounts,
  Transactions,
  // Technical Tables
  Settings,
], daos: [
  CurrencyDesignationsDao,
  CurrenciesDao,
  CategoriesDao,
  AccountStylesDao,
  AccountsDao,
  TransactionsDao,
  SettingsDao,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.connection);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // Seed initial data
        await _seedCurrencyDesignations(this);
        await _seedCurrencies(this);
        await _seedSettings(this);
        await _seedAccountStyles(this);
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // No-op for development, we re-create the DB
      },
    );
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

  Future<void> _seedAccountStyles(AppDatabase db) async {
    for (final style in defaultAccountStyles) {
      await db.into(db.accountStyles).insert(style);
    }
  }
}

LazyDatabase _openConnection() {
  // the LazyDatabase util lets us find the right location for the file async.
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}

