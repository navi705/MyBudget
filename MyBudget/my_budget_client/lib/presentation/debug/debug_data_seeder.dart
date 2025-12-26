import 'package:collection/collection.dart';
import 'dart:developer' as developer;
import 'dart:math';

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
    await _seedData(accountCount: 100, categoryCount: 50, transactionCount: 5000);
  }

  static Future<void> seedMaximumData() async {
    await clearAllData();
    await _seedData(accountCount: 5000, categoryCount: 500, transactionCount: 500000);
  }

  static Future<void> _seedData({
    required int accountCount,
    required int categoryCount,
    required int transactionCount,
  }) async {
    final totalStopwatch = Stopwatch()..start();
    developer.log('--- Starting Data Seeding ---');

    final prerequisitesStopwatch = Stopwatch()..start();
    final prerequisites = await _getPrerequisites();
    developer.log('Fetched prerequisites in ${prerequisitesStopwatch.elapsed}');

    if (prerequisites.currencies.isEmpty ||
        prerequisites.accountTypes.isEmpty ||
        prerequisites.styles.isEmpty) {
      developer.log('Prerequisites missing, cannot seed data.');
      return;
    }

    final accountRepo = sl<AccountRepository>();
    final categoryRepo = sl<CategoryRepository>();
    final transactionRepo = sl<TransactionRepository>();

    // 1. Create Accounts
    final accountCreationStopwatch = Stopwatch()..start();
    final List<Account> insertedAccounts = [];
    List<Account> accountsForInsert = [];
    for (int i = 0; i < accountCount; i++) {
      final currency =
          prerequisites.currencies[_random.nextInt(prerequisites.currencies.length)];
      final accountType = prerequisites
          .accountTypes[_random.nextInt(prerequisites.accountTypes.length)];
      final style =
          prerequisites.styles[_random.nextInt(prerequisites.styles.length)];
      final designation = prerequisites.designations
          .firstWhereOrNull((d) => d.currencyCode == currency.code);

      if (designation == null) {
        developer.log('Could not find designation for currency ${currency.code}, skipping account creation.');
        continue;
      }

      final account = Account(
        name: 'Account $i',
        balance: _random.nextDouble() * 10000,
        currencyCode: currency.code,
        currencyDesignationId: designation.id,
        accountTypeId: accountType.id,
        styleId: style.id,
        creationDate: DateTime.now().subtract(Duration(days: _random.nextInt(1825))),
      );
      accountsForInsert.add(account);
    }
    developer.log('In-memory account creation took: ${accountCreationStopwatch.elapsed}');

    final accountDbStopwatch = Stopwatch()..start();
    await accountRepo.addAccounts(accountsForInsert);
    insertedAccounts.addAll(await accountRepo.getAccounts());
    developer.log('Account DB insertion took: ${accountDbStopwatch.elapsed}');

    // 2. Create Categories
    final categoryCreationStopwatch = Stopwatch()..start();
     List<Category> categoryForInsert = [];
    for (int i = 0; i < categoryCount; i++) {
      final style =
          prerequisites.styles[_random.nextInt(prerequisites.styles.length)];
      final type = CategoryType.values[_random.nextInt(CategoryType.values.length)];
      final category = Category(
        name: 'Category $i',
        styleId: style.id,
        type: type,
      );
      categoryForInsert.add(category);
    }
    await categoryRepo.addCategories(categoryForInsert);
    final allCategories = await categoryRepo.getCategories();
    
    // Make ~50% of categories into subcategories
    final int subCategoryCount = (allCategories.length * 0.5).round();
    final subCategoryCandidates = List.of(allCategories)..shuffle();
    final parentCategories = allCategories.where((c) => c.parentId == null).toList();

    for(int i = 0; i < subCategoryCount; i++) {
      final subCategory = subCategoryCandidates[i];

      // Ensure we have parents and the subcategory is not already a subcategory
      if (parentCategories.isEmpty || subCategory.parentId != null) continue;

      // Find a parent that is not the same category
      var potentialParents = parentCategories.where((p) => p.id != subCategory.id).toList();
      if (potentialParents.isEmpty) continue;
      
      final parent = potentialParents[_random.nextInt(potentialParents.length)];
      
      await categoryRepo.updateCategory(subCategory.copyWith(parentId: parent.id));
    }
    developer.log('Category creation and updates took: ${categoryCreationStopwatch.elapsed}');

    final insertedCategories = await categoryRepo.getCategories();

    // 3. Create Transactions
    final transactionCreationStopwatch = Stopwatch()..start();
    final List<Transaction> transactionsForInsert = [];
    for (int i = 0; i < transactionCount; i++) {
      final account =
          insertedAccounts[_random.nextInt(insertedAccounts.length)];
      final category =
          insertedCategories[_random.nextInt(insertedCategories.length)];
      final amount = category.type == CategoryType.expense
          ? -(_random.nextDouble() * 500).roundToDouble()
          : (_random.nextDouble() * 2000).roundToDouble();

      transactionsForInsert.add(Transaction(
        description: 'Transaction $i',
        amount: amount,
        date: DateTime.now().subtract(Duration(days: _random.nextInt(1825))),
        accountId: account.id!,
        categoryId: category.id!,
        currencyCode: account.currencyCode,
      ));
    }
    developer.log('In-memory transaction creation took: ${transactionCreationStopwatch.elapsed}');
    
    final transactionDbStopwatch = Stopwatch()..start();
    // Let the optimized repository method handle EVERYTHING
    await transactionRepo.addTransactions(transactionsForInsert);
    developer.log('Transaction DB insertion took: ${transactionDbStopwatch.elapsed}');

    developer.log('--- Total seeding time: ${totalStopwatch.elapsed} ---');
  }
}
