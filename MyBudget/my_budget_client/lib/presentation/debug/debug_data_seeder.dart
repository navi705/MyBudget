import 'dart:math';

import 'package:my_budget_client/core/database/app_database.dart' as db;
import 'package:my_budget_client/core/di/injection_container.dart';
import 'package:my_budget_client/data/repositories/db_repository.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/account_type.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/currency_designation.dart';
import 'package:my_budget_client/domain/entities/style.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/domain/repositories/style_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';

typedef _Prerequisites = ({
  List<Currency> currencies,
  List<CurrencyDesignation> designations,
  List<AccountType> accountTypes,
  List<Style> styles,
});

class DebugDataSeeder {
  static final Random _random = Random();

  static Future<void> clearAllData() async {
    final dbRepository = sl<DbRepository>();
    await dbRepository.clearAllDatabase();
  }

  static Future<_Prerequisites> _getPrerequisites() async {
    final currencyRepo = sl<CurrencyRepository>();
    final accountRepo = sl<AccountRepository>();
    final styleRepo = sl<StyleRepository>();

    final currencies = await currencyRepo.getCurrencies();
    final designations = await currencyRepo.getAllCurrencyDesignations();
    final accountTypes = await accountRepo.getAccountTypes();
    final styles = await styleRepo.watchAllStyles().first;

    return (
      currencies: currencies,
      designations: designations,
      accountTypes: accountTypes,
      styles: styles,
    );
  }

  static Future<void> seedMinimumData() async {
    await clearAllData();
    await _seedData(accountCount: 10, categoryCount: 5, transactionCount: 50);
  }

  static Future<void> seedMediumData() async {
    await clearAllData();
    await _seedData(accountCount: 50, categoryCount: 20, transactionCount: 1000);
  }

  static Future<void> seedMaximumData() async {
    await clearAllData();
    await _seedData(accountCount: 5000, categoryCount: 100, transactionCount: 1000000);
  }

  static Future<void> _seedData({
    required int accountCount,
    required int categoryCount,
    required int transactionCount,
  }) async {
    final prerequisites = await _getPrerequisites();
    if (prerequisites.currencies.isEmpty ||
        prerequisites.accountTypes.isEmpty ||
        prerequisites.styles.isEmpty) {
      // Cannot proceed if default data is missing
      return;
    }

    final accountRepo = sl<AccountRepository>();
    final categoryRepo = sl<CategoryRepository>();

    // 1. Create Accounts
    final List<Account> insertedAccounts = [];
    for (int i = 0; i < accountCount; i++) {
      final currency =
          prerequisites.currencies[_random.nextInt(prerequisites.currencies.length)];
      final accountType = prerequisites
          .accountTypes[_random.nextInt(prerequisites.accountTypes.length)];
      final style =
          prerequisites.styles[_random.nextInt(prerequisites.styles.length)];
      final designation = prerequisites.designations
          .firstWhere((d) => d.currencyCode == currency.code);

      final account = Account(
        name: 'Account $i',
        balance: _random.nextDouble() * 10000,
        currencyCode: currency.code,
        currencyDesignationId: designation.id,
        accountTypeId: accountType.id,
        styleId: style.id,
      );
      await accountRepo.addAccount(account);
    }
    insertedAccounts.addAll(await accountRepo.getAccounts());

    // 2. Create Categories
    final List<Category> insertedCategories = [];
    for (int i = 0; i < categoryCount; i++) {
      final style =
          prerequisites.styles[_random.nextInt(prerequisites.styles.length)];
      final type = CategoryType.values[_random.nextInt(CategoryType.values.length)];
      final category = Category(
        name: 'Category $i',
        styleId: style.id,
        type: type,
      );
      await categoryRepo.addCategory(category);
    }
    insertedCategories.addAll(await categoryRepo.getCategories());

    // 3. Create Transactions
    if (transactionCount > 10000) {
      // Use batch insert for large amounts
      await _batchInsertTransactions(
          transactionCount, insertedAccounts, insertedCategories);
    } else {
      // Use repository for smaller amounts
      final transactionRepo = sl<TransactionRepository>();
      for (int i = 0; i < transactionCount; i++) {
        final account =
            insertedAccounts[_random.nextInt(insertedAccounts.length)];
        final category =
            insertedCategories[_random.nextInt(insertedCategories.length)];
        final amount = category.type == CategoryType.expense
            ? -(_random.nextDouble() * 500).roundToDouble()
            : (_random.nextDouble() * 2000).roundToDouble();

        await transactionRepo.addTransaction(Transaction(
          description: 'Transaction $i',
          amount: amount,
          date: DateTime.now().subtract(Duration(days: _random.nextInt(1825))),
          accountId: account.id!,
          categoryId: category.id!,
          currencyCode: account.currencyCode,
        ));
      }
    }
  }

  static Future<void> _batchInsertTransactions(
    int count,
    List<Account> accounts,
    List<Category> categories,
  ) async {
    final dbRepository = sl<DbRepository>();
    final List<db.TransactionsCompanion> companions = [];
    final Map<String, double> accountBalanceDelta = {};

    for (int i = 0; i < count; i++) {
      final account = accounts[_random.nextInt(accounts.length)];
      final category = categories[_random.nextInt(categories.length)];

      final amount = category.type == CategoryType.expense
          ? -(_random.nextDouble() * 500).roundToDouble()
          : (_random.nextDouble() * 2000).roundToDouble();
      final date = DateTime.now().subtract(Duration(days: _random.nextInt(1825)));

      companions.add(db.TransactionsCompanion.insert(
        description: 'Transaction $i',
        amount: amount,
        date: date,
        accountId: account.id!,
        categoryId: category.id!,
        currencyCode: account.currencyCode,
      ));

      // Track balance changes to update later
      accountBalanceDelta.update(
        account.id!,
        (value) => value + amount,
        ifAbsent: () => amount,
      );
    }

    // Insert all transactions in a single batch
    await dbRepository.batch((batch) {
      batch.insertAll(
        // A bit of a hack to get the table reference, could be improved in DbRepo
        (dbRepository as dynamic).database.transactions,
        companions,
      );
    });

    // Update account balances
    final accountRepo = sl<AccountRepository>();
    for (final entry in accountBalanceDelta.entries) {
      final account = await accountRepo.getAccountById(entry.key);
      if (account != null) {
        await accountRepo.updateAccount(
          account.copyWith(balance: account.balance + entry.value),
        );
      }
    }
  }
}
