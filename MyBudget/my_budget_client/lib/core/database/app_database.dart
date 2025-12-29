import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:my_budget_client/core/utils/device_utils.dart';
import 'package:my_budget_client/core/utils/import_utils.dart';
import 'package:my_budget_client/data/seed_data/styles_data.dart';
import 'package:my_budget_client/data/seed_data/exchange_rates_data.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/icon_type.dart';
import 'package:my_budget_client/domain/entities/transaction_type_filter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:my_budget_client/data/seed_data/currency_designations_data.dart';
import 'package:my_budget_client/data/seed_data/currencies_data.dart';
import 'package:my_budget_client/data/seed_data/languages_data.dart';
import 'package:my_budget_client/data/seed_data/settings_data.dart';
import 'package:my_budget_client/data/seed_data/account_types_data.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
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
  IntColumn get type => integer().map(const EnumIndexConverter(TypeCurrency.values)).withDefault(const Constant(6))();

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
  DateTimeColumn get creationDate => dateTime().clientDefault(() => DateTime.now())();

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
  @ReferenceName('ToCurrencyRates')
  TextColumn get toCurrencyCode => text().references(Currencies, #code)();
  RealColumn get rate => real()();
  IntColumn get preset => integer()();
  DateTimeColumn get date => dateTime()();

  @override
  Set<Column> get primaryKey => {fromCurrencyCode, toCurrencyCode, date};
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
  }) {
    final query = customSelect(
      '''
      SELECT
        c.*,
        t.total
      FROM categories c
      LEFT JOIN (
        SELECT category_id, SUM(amount) AS total
        FROM transactions
        GROUP BY category_id
      ) t ON t.category_id = c.id
      LIMIT ? OFFSET ?
      ''',
      variables: [Variable(limit), Variable(offset)],
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
  Future<Style?> getStyleById(String id) => // Added this method
      (select(styles)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
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

    for (final account in allAccounts) {
      final startOfCreationDate = DateTime(account.creationDate.year, account.creationDate.month, account.creationDate.day);
      if (startOfDate.isBefore(startOfCreationDate)) {
        balances[account.id] = 0.0;
      } else {
        final currentBalance = account.balance;
        final sumOfFutureTransactions = await attachedDatabase.transactionsDao
            .getSumOfTransactionsAfterDate(account.id, date);
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
    List<String>? categoriesIds,
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

    if (categoriesIds != null && categoriesIds.isNotEmpty) {
      final subquery = selectOnly(transactions)
        ..where(transactions.categoryId.isIn(categoriesIds))
        ..addColumns([transactions.accountId]);
      query.where((tbl) => tbl.id.isInQuery(subquery));
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
    final count = await query.map((row) => row.read(countExp)).getSingleOrNull();
    return count ?? 0;
  }

  Future<void> deleteMultipleAccounts(List<String> ids) {
    return (delete(accounts)..where((tbl) => tbl.id.isIn(ids))).go();
  }

  Future<void> updateAccountTypeForMultipleAccounts(
      List<String> ids, String accountTypeId) {
    return (update(accounts)..where((tbl) => tbl.id.isIn(ids)))
        .write(AccountsCompanion(accountTypeId: Value(accountTypeId)));
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
    String? accountId,
    String? categoryId,
    String? currencyCode,
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
    if (accountId != null) {
      query.where((tbl) => tbl.accountId.equals(accountId));
    }
    if (categoryId != null) {
      query.where((tbl) => tbl.categoryId.equals(categoryId));
    }
    if (currencyCode != null) {
      query.where((tbl) => tbl.currencyCode.equals(currencyCode));
    }
    if (transactionType != null) {
      if (transactionType == TransactionTypeFilter.income) {
        query.where((tbl) => tbl.amount.isBiggerThanValue(0));
      } else if (transactionType == TransactionTypeFilter.expense) {
        query.where((tbl) => tbl.amount.isSmallerThanValue(0));
      }
    }

    query.orderBy([(t) => OrderingTerm(expression: t.date, mode: sort)]);
    query.limit(limit, offset: offset);

    return query.get();
  }

  Future<int> getCountWithFilters({
    String? description,
    double? amountFrom,
    double? amountTo,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? accountId,
    String? categoryId,
    String? currencyCode,
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
    if (accountId != null) {
      query.where(transactions.accountId.equals(accountId));
    }
    if (categoryId != null) {
      query.where(transactions.categoryId.equals(categoryId));
    }
    if (currencyCode != null) {
      query.where(transactions.currencyCode.equals(currencyCode));
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
    final count = await query.map((row) => row.read(countExp)).getSingleOrNull();
    return count ?? 0;
  }

  Future<List<Transaction>> getTransactionsByIds(List<String> ids) {
    return (select(transactions)..where((tbl) => tbl.id.isIn(ids))).get();
  }

  Future<void> deleteMultipleTransactions(List<String> ids) {
    return (delete(transactions)..where((tbl) => tbl.id.isIn(ids))).go();
  }

  Future<void> updateDateForMultipleTransactions(
      List<String> ids, DateTime newDate) {
    return (update(transactions)..where((tbl) => tbl.id.isIn(ids)))
        .write(TransactionsCompanion(date: Value(newDate)));
  }

  Future<void> updateCategoryForMultipleTransactions(
      List<String> ids, String newCategoryId) {
    return (update(transactions)..where((tbl) => tbl.id.isIn(ids)))
        .write(TransactionsCompanion(categoryId: Value(newCategoryId)));
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
      String accountId, DateTime date) async {
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    final amountExp = transactions.amount.total();
    final query = selectOnly(transactions)
      ..where(transactions.accountId.equals(accountId) &
          transactions.date.isBiggerThanValue(endOfDay))
      ..addColumns([amountExp]);

    final result =
        await query.map((row) => row.read(amountExp)).getSingleOrNull();
    return result ?? 0.0;
  }
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
}

@DriftAccessor(tables: [ExchangeRates])
class ExchangeRatesDao extends DatabaseAccessor<AppDatabase>
    with _$ExchangeRatesDaoMixin {
  ExchangeRatesDao(super.db);

  Future<List<ExchangeRate>> getAllExchangeRates() =>
      select(exchangeRates).get();
  Future<List<ExchangeRate>> getExchangeRates({
    int limit = 10,
    int offset = 0,
  }) => (select(exchangeRates)..limit(limit, offset: offset)).get();
  
  Future<List<ExchangeRate>> getLatestExchangeRates(DateTime date) {
    return customSelect(
      'SELECT r.* FROM exchange_rates r INNER JOIN (SELECT from_currency_code, to_currency_code, MAX(date) AS max_date FROM exchange_rates WHERE date <= ? GROUP BY from_currency_code, to_currency_code) max_dates ON r.from_currency_code = max_dates.from_currency_code AND r.to_currency_code = max_dates.to_currency_code AND r.date = max_dates.max_date',
      variables: [Variable.withDateTime(date)],
      readsFrom: {exchangeRates},
    ).get().then((rows) => rows.map((row) => exchangeRates.map(row.data)).toList());
  }

  Future<void> addExchangeRate(ExchangeRatesCompanion rate) =>
      into(exchangeRates).insert(rate);

  Future<void> insertAllExchangeRates(List<ExchangeRatesCompanion> rates) {
    return batch((batch) {
      batch.insertAll(exchangeRates, rates, mode: InsertMode.insertOrReplace);
    });
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
    // Technical Tables
    Settings,
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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.connection);

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _seedData(this);
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from == 6) {
          await m.addColumn(accounts, accounts.creationDate);
        }
      },
    );
  }

  Future<void> _seedData(AppDatabase db) async {
    await _seedLanguages(db);
    await _seedCurrencyDesignations(db);
    await _seedCurrencies(db);
    await _seedSettings(db);
    await _seedStyles(db);
    await _seedAccountTypes(db);
    await _seedExchangeRates(db);
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
    await db.exchangeRatesDao.insertAllExchangeRates( await ImportDataUtils.getCurrenciesRateToSeeder());
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
