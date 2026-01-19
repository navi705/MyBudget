import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode;

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:my_budget_client/core/mappers/exchange_rate_mapper.dart';
import 'package:my_budget_client/core/utils/device_utils.dart';
import 'package:my_budget_client/core/utils/import_utils.dart';
import 'package:my_budget_client/data/seed_data/styles_data.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/icon_type.dart';
import 'package:my_budget_client/domain/entities/transaction_type_filter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:my_budget_client/domain/entities/exchange_rate.dart';
import 'package:my_budget_client/data/seed_data/currency_designations_data.dart';
import 'package:my_budget_client/data/seed_data/currencies_data.dart';
import 'package:my_budget_client/data/seed_data/languages_data.dart';
import 'package:my_budget_client/data/seed_data/settings_data.dart';
import 'package:my_budget_client/data/seed_data/account_types_data.dart';
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

  @override
  Set<Column> get primaryKey => {languageCode};
}

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
  TextColumn get languageCode => text().references(Languages, #languageCode)();
  IntColumn get type => integer()
      .map(const EnumIndexConverter(TypeCurrency.values))
      .withDefault(const Constant(6))();

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
  IntColumn get iconType => integer()
      .map(const EnumIndexConverter(IconType.values))
      .withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class AccountTypes extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get name => text().withLength(min: 1, max: 50).unique()();
  TextColumn get languageCode => text().references(Languages, #languageCode)();

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

  @override
  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_transactions_date', columns: {#date})
@TableIndex(name: 'idx_transactions_account', columns: {#accountId})
@TableIndex(name: 'idx_transactions_category', columns: {#categoryId})
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

  @override
  Set<Column> get primaryKey => {id};
}

// --- Technical Tables ---

@DataClassName('Setting')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  TextColumn get device => text()();

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

  @override
  Set<Column> get primaryKey => {id};
}

// --- Data Access Objects (DAOs) ---

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

  Future<void> insertAllinsertLanguages(List<LanguagesCompanion> languages) {
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

  Future<List<CurrencyDesignation>> getAllDesignations() =>
      select(currencyDesignations).get();
  Future<List<CurrencyDesignation>> getDesignations({
    int limit = 10,
    int offset = 0,
  }) => (select(currencyDesignations)..limit(limit, offset: offset)).get();
  Stream<List<CurrencyDesignation>> watchAllDesignations() =>
      select(currencyDesignations).watch();
  Future<CurrencyDesignation?> getDesignationById(String id) => (select(
    currencyDesignations,
  )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  Future<void> insertDesignation(CurrencyDesignationsCompanion designation) =>
      into(currencyDesignations).insert(designation);
  Future<void> insertAllCurrencyDesignations(
    List<CurrencyDesignationsCompanion> designations,
  ) {
    return batch((batch) {
      batch.insertAll(
        currencyDesignations,
        designations,
        mode: InsertMode.insertOrReplace,
      );
    });
  }

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

@DriftAccessor(tables: [Categories, Transactions])
class CategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  Future<List<Category>> getAllCategories() => select(categories).get();
  Future<List<Category>> getCategories({int limit = 10, int offset = 0}) =>
      (select(categories)..limit(limit, offset: offset)).get();
  Future<Category?> getCategoryById(String id) =>
      (select(categories)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

  Future<List<Category>> getCategoriesByIds(List<String> ids) async {
    const int chunkSize = 500;
    List<Category> allResults = [];

    for (var i = 0; i < ids.length; i += chunkSize) {
      final end = (i + chunkSize < ids.length) ? i + chunkSize : ids.length;
      final chunk = ids.sublist(i, end);

      final chunkResults = await (select(
        categories,
      )..where((u) => u.id.isIn(chunk))).get();

      allResults.addAll(chunkResults);
    }
    final resultMap = {for (var style in allResults) style.id: style};
    return ids.map((id) => resultMap[id]).whereType<Category>().toList();
  }

  Stream<List<Category>> watchAllCategories() => select(categories).watch();
  Future<void> insertCategory(CategoriesCompanion category) =>
      into(categories).insert(category);
  Future<void> insertAllCategories(List<CategoriesCompanion> categories) {
    return batch((batch) {
      batch.insertAll(
        this.categories,
        categories,
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  Future<bool> updateCategory(CategoriesCompanion category) =>
      update(categories).replace(category);
  Future<int> deleteCategory(CategoriesCompanion category) =>
      delete(categories).delete(category);

  Future<void> deleteCategoryWithTransactions(String categoryId) {
    return db.transaction(() async {
      await (delete(
        db.transactions,
      )..where((t) => t.categoryId.equals(categoryId))).go();
      await (delete(categories)..where((c) => c.id.equals(categoryId))).go();
    });
  }

  Future<void> deleteCategoryAndReassignTransactions(
    String categoryId,
    String newCategoryId,
  ) {
    return db.transaction(() async {
      await (update(db.transactions)
            ..where((t) => t.categoryId.equals(categoryId)))
          .write(TransactionsCompanion(categoryId: Value(newCategoryId)));
      await (delete(categories)..where((c) => c.id.equals(categoryId))).go();
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

@DriftAccessor(tables: [Styles])
class StylesDao extends DatabaseAccessor<AppDatabase> with _$StylesDaoMixin {
  StylesDao(super.db);

  Future<List<Style>> getAllStyles() => select(styles).get();
  Future<List<Style>> getStyles({int limit = 10, int offset = 0}) =>
      (select(styles)..limit(limit, offset: offset)).get();
  Stream<List<Style>> watchAllStyles() => select(styles).watch();
  Future<Style?> getStyleById(String id) =>
      (select(styles)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

  Future<List<Style>> getStylesByIds(List<String> ids) async {
    const int chunkSize = 500;
    List<Style> allResults = [];

    for (var i = 0; i < ids.length; i += chunkSize) {
      final end = (i + chunkSize < ids.length) ? i + chunkSize : ids.length;
      final chunk = ids.sublist(i, end);

      final chunkResults = await (select(
        styles,
      )..where((u) => u.id.isIn(chunk))).get();

      allResults.addAll(chunkResults);
    }

    final resultMap = {for (var style in allResults) style.id: style};

    return ids
        .map((id) => resultMap[id]) // Get style by ID
        .whereType<Style>() // Remove nulls (in case an ID wasn't found in DB)
        .toList();
  }

  Future<void> insertStyle(StylesCompanion style) => into(styles).insert(style);
  Future<void> insertAllStyles(List<StylesCompanion> styles) {
    return batch((batch) {
      batch.insertAll(this.styles, styles, mode: InsertMode.insertOrReplace);
    });
  }

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
  Future<List<AccountType>> getAccountTypes({int limit = 10, int offset = 0}) =>
      (select(accountTypes)..limit(limit, offset: offset)).get();
  Stream<List<AccountType>> watchAllAccountTypes() =>
      select(accountTypes).watch();
  Future<AccountType?> getAccountTypeById(String id) => (select(
    accountTypes,
  )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  Future<void> insertAccountType(AccountTypesCompanion accountType) =>
      into(accountTypes).insert(accountType);
  Future<void> insertAllAccountTypes(List<AccountTypesCompanion> accountTypes) {
    return batch((batch) {
      batch.insertAll(
        this.accountTypes,
        accountTypes,
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  Future<bool> updateAccountType(AccountTypesCompanion accountType) =>
      update(accountTypes).replace(accountType);
  Future<int> deleteAccountType(AccountTypesCompanion accountType) =>
      delete(accountTypes).delete(accountType);
}

@DriftAccessor(tables: [Accounts, Transactions])
class AccountsDao extends DatabaseAccessor<AppDatabase>
    with _$AccountsDaoMixin {
  AccountsDao(super.db);

  Future<List<DbAccount>> getAllAccounts() => select(accounts).get();
  Future<List<DbAccount>> getAccounts({int limit = 10, int offset = 0}) =>
      (select(accounts)..limit(limit, offset: offset)).get();
  Future<DbAccount?> getAccountById(String id) =>
      (select(accounts)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

  // OPTIMIZATION: Bulk fetch accounts by IDs (O(1) vs O(n) sequential calls)
  Future<List<DbAccount>> getAccountsByIds(List<String> ids) =>
      (select(accounts)..where((tbl) => tbl.id.isIn(ids))).get();

  Stream<List<DbAccount>> watchAllAccounts() => select(accounts).watch();
  Future<void> insertAccount(AccountsCompanion account) =>
      into(accounts).insert(account);
  Future<void> insertAllAccounts(List<AccountsCompanion> accounts) {
    return batch((batch) {
      batch.insertAll(
        this.accounts,
        accounts,
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  Future<void> restoreAccount(AccountsCompanion account) =>
      into(accounts).insert(account, mode: InsertMode.insertOrReplace);
  Future<bool> updateAccount(AccountsCompanion account) =>
      update(accounts).replace(account);
  Future<int> deleteAccount(AccountsCompanion account) =>
      delete(accounts).delete(account);

  Future<void> adjustBalance(String accountId, double amount) {
    return customUpdate(
      'UPDATE accounts SET balance = balance + ? WHERE id = ?',
      variables: [Variable(amount), Variable(accountId)],
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
    for (final accountId in accountIds) {
      variables.add(Variable(accountId));
    }

    final sql =
        '''
      UPDATE accounts
      SET balance = balance + (CASE id ${caseClauses.join(' ')} END)
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
    final query = select(accounts);

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
    final query = selectOnly(accounts);
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

  Future<void> deleteMultipleAccounts(List<String> ids) {
    return (delete(accounts)..where((tbl) => tbl.id.isIn(ids))).go();
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
    return db.transaction(() async {
      await (delete(
        db.transactions,
      )..where((t) => t.accountId.equals(accountId))).go();
      await (delete(accounts)..where((a) => a.id.equals(accountId))).go();
    });
  }

  Future<void> deleteAccountAndReassignTransactions(
    String accountId,
    String newAccountId,
  ) {
    return db.transaction(() async {
      await (update(db.transactions)
            ..where((t) => t.accountId.equals(accountId)))
          .write(TransactionsCompanion(accountId: Value(newAccountId)));
      await (delete(accounts)..where((a) => a.id.equals(accountId))).go();
    });
  }
}

@DriftAccessor(tables: [Transactions])
class TransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionsDaoMixin {
  TransactionsDao(super.db);

  Future<List<Transaction>> getAllTransactions() => select(transactions).get();
  Future<List<Transaction>> getTransactions({int limit = 10, int offset = 0}) =>
      (select(transactions)..limit(limit, offset: offset)).get();
  Future<Transaction?> getTransactionById(String id) => (select(
    transactions,
  )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  Future<List<Transaction>> getTransactionsByCategoryId(String categoryId) =>
      (select(
        transactions,
      )..where((tbl) => tbl.categoryId.equals(categoryId))).get();
  Stream<List<Transaction>> watchAllTransactions() =>
      select(transactions).watch();
  Future<void> insertTransaction(TransactionsCompanion transaction) =>
      into(transactions).insert(transaction);
  Future<void> insertAllTransactions(List<TransactionsCompanion> transactions) {
    return batch((batch) {
      batch.insertAll(
        this.transactions,
        transactions,
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  Future<bool> updateTransaction(TransactionsCompanion transaction) =>
      update(transactions).replace(transaction);
  Future<int> deleteTransaction(TransactionsCompanion transaction) =>
      delete(transactions).delete(transaction);
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
    final query = select(transactions);

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
    final query = selectOnly(transactions);

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
    return (select(transactions)..where((tbl) => tbl.id.isIn(ids))).get();
  }

  Future<void> deleteMultipleTransactions(List<String> ids) {
    return (delete(transactions)..where((tbl) => tbl.id.isIn(ids))).go();
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
    final query = selectOnly(transactions)..addColumns([expression]);
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
            transactions.date.isBiggerThanValue(endOfDay),
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
      ..where(transactions.date.isBiggerThanValue(endOfDay))
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
      ]);

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
              (SELECT rate FROM exchange_rates WHERE date = t.date AND from_currency_code = t.currency_code AND to_currency_code = 'EUR'),
              CASE WHEN (SELECT rate FROM exchange_rates WHERE date = t.date AND from_currency_code = 'EUR' AND to_currency_code = t.currency_code) > 0 
                   THEN 1.0 / (SELECT rate FROM exchange_rates WHERE date = t.date AND from_currency_code = 'EUR' AND to_currency_code = t.currency_code)
                   ELSE 1.0 END,
              1.0
            )
          END *
          -- STEP 2: Base (EUR) -> Main Currency
          CASE 
            WHEN '$mainCurrencyCode' = 'EUR' THEN 1.0
            ELSE COALESCE(
              (SELECT rate FROM exchange_rates WHERE date = t.date AND from_currency_code = 'EUR' AND to_currency_code = '$mainCurrencyCode'),
              CASE WHEN (SELECT rate FROM exchange_rates WHERE date = t.date AND from_currency_code = '$mainCurrencyCode' AND to_currency_code = 'EUR') > 0
                   THEN 1.0 / (SELECT rate FROM exchange_rates WHERE date = t.date AND from_currency_code = '$mainCurrencyCode' AND to_currency_code = 'EUR')
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

    print('[PERF] SQL Optimized Aggregation: ${sw.elapsedMilliseconds}ms');
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

  Future<String> getDeviceName() async {
    final firstSetting = await (select(
      db.settings,
    )..limit(1)).getSingleOrNull();
    return firstSetting?.device ?? 'default';
  }
}

@DriftAccessor(tables: [ExchangeRates])
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

  Future<void> addExchangeRate(ExchangeRatesCompanion rate) {
    print('DAO: Adding exchange rate with preset: ${rate.preset.value}');
    return into(exchangeRates).insert(rate);
  }

  Future<void> updateExchangeRate(ExchangeRatesCompanion rate) =>
      update(exchangeRates).replace(rate);

  Future<void> insertAllExchangeRates(List<ExchangeRatesCompanion> rates) {
    return batch((batch) {
      batch.insertAll(exchangeRates, rates, mode: InsertMode.insertOrReplace);
    });
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
          ),
          mode: InsertMode.replace,
        );
      }
    });
  }
}

@DriftAccessor(tables: [CustomThemes])
class CustomThemesDao extends DatabaseAccessor<AppDatabase>
    with _$CustomThemesDaoMixin {
  CustomThemesDao(super.db);

  Future<List<DbCustomTheme>> getAllThemes() => select(customThemes).get();
  Future<DbCustomTheme?> getThemeById(String id) => (select(
    customThemes,
  )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

  Future<DbCustomTheme?> getActiveTheme() => (select(
    customThemes,
  )..where((tbl) => tbl.isActive.equals(true))).getSingleOrNull();

  Future<void> insertTheme(CustomThemesCompanion theme) =>
      into(customThemes).insert(theme, mode: InsertMode.insertOrReplace);

  Future<void> insertAllThemes(List<CustomThemesCompanion> themes) {
    return batch((batch) {
      batch.insertAll(customThemes, themes, mode: InsertMode.insertOrReplace);
    });
  }

  Future<bool> updateTheme(CustomThemesCompanion theme) =>
      update(customThemes).replace(theme);

  Future<int> deleteTheme(String id) =>
      (delete(customThemes)..where((tbl) => tbl.id.equals(id))).go();

  Future<void> setActiveTheme(String id) {
    return transaction(() async {
      await (update(customThemes)..where((tbl) => tbl.isActive.equals(true)))
          .write(const CustomThemesCompanion(isActive: Value(false)));
      await (update(customThemes)..where((tbl) => tbl.id.equals(id))).write(
        const CustomThemesCompanion(isActive: Value(true)),
      );
    });
  }
}

@DriftAccessor(tables: [InflationRates])
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

  Future<void> insertInflationRate(InflationRatesCompanion rate) =>
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

  Future<bool> updateInflationRate(InflationRatesCompanion rate) =>
      update(inflationRates).replace(rate);

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
}

@DriftAccessor(tables: [AssetEntries])
class AssetEntriesDao extends DatabaseAccessor<AppDatabase>
    with _$AssetEntriesDaoMixin {
  AssetEntriesDao(super.db);

  Future<List<AssetEntry>> getAllAssetEntries() => select(assetEntries).get();
  Stream<List<AssetEntry>> watchAllAssetEntries() =>
      select(assetEntries).watch();

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
    final query = select(assetEntries);
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
    final query = select(assetEntries);
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
    final query = selectOnly(assetEntries);
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

  Future<void> addAssetData(AssetEntriesCompanion data) =>
      into(assetEntries).insert(data);

  Future<void> updateAssetData(AssetEntriesCompanion data) =>
      update(assetEntries).replace(data);

  Future<void> deleteAssetEntry(String id) {
    return (delete(assetEntries)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> deleteAssets(List<String> ids) async {
    await (delete(assetEntries)..where((tbl) => tbl.id.isIn(ids))).go();
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
    // Business Tables
    CurrencyDesignations,
    Currencies,
    Categories,
    Styles,
    Accounts,
    Transactions,
    AccountTypes,
    ExchangeRates,
    Languages,
    InflationRates,
    AssetEntries,
    // Technical Tables
    Settings,
    CustomThemes,
    ApiFetchStatuses,
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
    SettingsDao,
    ExchangeRatesDao,
    CustomThemesDao,
    InflationRatesDao,
    AssetEntriesDao,
    ApiFetchStatusesDao, // Added
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.connection);

  @override
  int get schemaVersion => 18;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _seedData(this);
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 7) {
          await m.addColumn(accounts, accounts.creationDate);
        }
        if (from < 8) {
          // idx_transactions_date is now handled by @TableIndex,
          // but for existing migrations we still run it if needed.
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions (date)',
          );
        }
        if (from < 10) {
          if (from < 9) {
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_transactions_account ON transactions (account_id)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_transactions_category ON transactions (category_id)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_exchange_rates_date ON exchange_rates (date)',
            );
          }
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_exchange_rates_composite ON exchange_rates (from_currency_code, to_currency_code, date)',
          );
        }
        if (from < 11) {
          await m.createTable(customThemes);
        }
        if (from < 12) {
          // Recreate ExchangeRates table to update Primary Key
          await m.deleteTable('exchange_rates');
          await m.createTable(exchangeRates);
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_exchange_rates_date ON exchange_rates (date)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_exchange_rates_composite ON exchange_rates (from_currency_code, to_currency_code, date)',
          );
        }
        if (from < 13) {
          // Explicitly drop the problematic index if it exists
          await customStatement(
            'DROP INDEX IF EXISTS idx_exchange_rates_composite',
          );
          // Re-recreate the table to be absolutely certain the PK is correct
          await m.deleteTable('exchange_rates');
          await m.createTable(exchangeRates);

          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_exchange_rates_date ON exchange_rates (date)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_exchange_rates_composite ON exchange_rates (from_currency_code, to_currency_code, date)',
          );
        }
        if (from < 15) {
          await m.createTable(assetEntries);
        }
        if (from < 16) {
          await m.createTable(apiFetchStatuses);
        }
        if (from < 17) {
          // Ensure all new/existing indices are created for existing users using custom statements
          // as they are more robust during migration when generated objects might differ.
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions (date)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_transactions_account ON transactions (account_id)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_transactions_category ON transactions (category_id)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_exchange_rates_date ON exchange_rates (date)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_exchange_rates_composite ON exchange_rates (from_currency_code, to_currency_code, date)',
          );
        }
        if (from < 18) {
          await customStatement(
            "ALTER TABLE asset_entries ADD COLUMN currency_code TEXT NOT NULL DEFAULT 'EUR' REFERENCES currencies(code)",
          );
          await customStatement(
            "ALTER TABLE asset_entries ADD COLUMN source TEXT NOT NULL DEFAULT 'manual'",
          );
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _seedData(AppDatabase db, {bool skipStaticData = false}) async {
    if (!skipStaticData) {
      await _seedLanguages(db);
      await _seedCurrencies(db);
      await _seedCurrencyDesignations(db);
      await _seedStyles(db);
      await _seedAccountTypes(db);
      await _seedExchangeRates(db);
    }
    // Settings are always re-seeded to defaults
    await _seedSettings(db);
  }

  // --- Seeding Methods ---

  Future<void> _seedLanguages(AppDatabase db) async {
    await db.languageDao.insertAllinsertLanguages(defaultLanguages);
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
    for (final setting in settingsToSeed) {
      await db.settingsDao.setSetting(setting);
    }
  }

  Future<void> _seedStyles(AppDatabase db) async {
    await db.stylesDao.insertAllStyles(defaultStyles);
  }

  Future<void> _seedAccountTypes(AppDatabase db) async {
    await db.accountTypesDao.insertAllAccountTypes(defaultAccountTypes);
  }

  Future<void> _seedExchangeRates(AppDatabase db) async {
    final List<ExchangeRateDomain> rates =
        await ImportDataUtils.getCurrenciesRateToSeeder();
    await db.exchangeRatesDao.insertAllExchangeRates(rates.toCompanionList());
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

      // Clear inflation rates as they are fetched data
      batch.deleteAll(inflationRates);

      if (!preserveStaticData) {
        // Only delete static data if strictly requested (Factory Reset)
        batch.deleteAll(exchangeRates);
        batch.deleteAll(currencyDesignations);
        batch.deleteAll(accountTypes);
        batch.deleteAll(styles);
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

QueryExecutor _openConnection() {
  // driftDatabase from drift_flutter automatically handles:
  // - Native (Android/iOS/Desktop): SQLite via sqlite3_flutter_libs
  // - Web: sqlite3.wasm (WASM) with IndexedDB persistence
  return driftDatabase(
    name: 'my_budget_db',
    // In debug mode: store in documents for easy access (native only)
    // In release mode: use default application support directory
    native: DriftNativeOptions(
      databasePath: () async {
        final Directory dbFolder;
        if (kDebugMode) {
          dbFolder = await getApplicationDocumentsDirectory();
        } else {
          dbFolder = await getApplicationSupportDirectory();
        }
        return p.join(dbFolder.path, 'db.sqlite');
      },
    ),
  );
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
