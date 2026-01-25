import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart' as db;
import 'package:my_budget_client/core/mappers/transaction_mapper.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';

class LocalTransactionRepository implements TransactionRepository {
  final db.AppDatabase database;

  LocalTransactionRepository(this.database);

  @override
  Stream<List<Transaction>> watchTransactions() {
    return database.transactionsDao.watchAllTransactions().map(
      (transactions) => transactions.toDomainList(),
    );
  }

  @override
  Future<void> addTransaction(Transaction transaction) async {
    print(
      'DEBUG: LocalTransactionRepository.addTransaction called for: ${transaction.description}, amount: ${transaction.amount}',
    );
    try {
      await database.transactionsDao.insertTransaction(
        transaction.toCompanion(),
      );
      await _updateAccountBalance(transaction.accountId, transaction.amount);
      print('DEBUG: LocalTransactionRepository.addTransaction success');
    } catch (e) {
      print('DEBUG: LocalTransactionRepository.addTransaction FAILED: $e');
      rethrow;
    }
  }

  @override
  Future<void> addTransactions(List<Transaction> transactions) async {
    print(
      'DEBUG: LocalTransactionRepository.addTransactions called for ${transactions.length} transactions',
    );
    try {
      await database.transaction(() async {
        // 1. Batch insert all transactions
        await database.transactionsDao.insertAllTransactions(
          transactions.toCompanionList(),
        );

        // 2. Aggregate amounts by account ID
        final amountChanges = <String, double>{};
        for (final transaction in transactions) {
          amountChanges.update(
            transaction.accountId,
            (value) => value + transaction.amount,
            ifAbsent: () => transaction.amount,
          );
        }

        // 3. Call the DAO to perform the batch update
        await database.accountsDao.batchUpdateBalances(amountChanges);
      });
      print('DEBUG: LocalTransactionRepository.addTransactions success');
    } catch (e) {
      print('DEBUG: LocalTransactionRepository.addTransactions FAILED: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await database.transaction(() async {
      await _deleteTransactionRecursive(id);
    });
  }

  Future<void> _deleteTransactionRecursive(String id) async {
    final transaction = await getTransactionById(id);
    if (transaction != null) {
      await database.transactionsDao.deleteTransaction(
        db.TransactionsCompanion(id: Value(id)),
      );
      await _updateAccountBalance(transaction.accountId, -transaction.amount);

      if (transaction.linkedTransactionId != null &&
          transaction.linkedTransactionId!.isNotEmpty) {
        await _deleteTransactionRecursive(transaction.linkedTransactionId!);
      }
    }
  }

  @override
  Future<void> deleteMultipleTransactions(List<String> ids) async {
    await database.transaction(() async {
      // 1. Recursively collect all IDs to delete, including linked transactions
      final allIdsToDelete = <String>{...ids};

      // implementation with batch fetch for performance
      var currentBatch = ids;
      final processedIds = <String>{...ids};

      while (true) {
        final transactions = await database.transactionsDao
            .getTransactionsByIds(currentBatch);
        final newIds = <String>[];
        for (final tx in transactions) {
          if (tx.linkedTransactionId != null &&
              tx.linkedTransactionId!.isNotEmpty &&
              !processedIds.contains(tx.linkedTransactionId!)) {
            newIds.add(tx.linkedTransactionId!);
            processedIds.add(tx.linkedTransactionId!);
          }
        }

        if (newIds.isEmpty) break;
        currentBatch = newIds;
        allIdsToDelete.addAll(newIds);
      }

      final finalIdsList = allIdsToDelete.toList();

      // 2. Adjust Balances
      final transactionsToDelete = await database.transactionsDao
          .getTransactionsByIds(finalIdsList);
      final amountChanges = <String, double>{};
      for (final transaction in transactionsToDelete) {
        amountChanges.update(
          transaction.accountId,
          (value) => value - transaction.amount,
          ifAbsent: () => -transaction.amount,
        );
      }
      await database.accountsDao.batchUpdateBalances(amountChanges);

      // 3. Delete
      await database.transactionsDao.deleteMultipleTransactions(finalIdsList);
    });
  }

  @override
  Future<void> updateDateForMultipleTransactions(
    List<String> ids,
    DateTime newDate,
  ) async {
    await database.transactionsDao.updateDateForMultipleTransactions(
      ids,
      newDate,
    );
  }

  @override
  Future<void> updateCategoryForMultipleTransactions(
    List<String> ids,
    String newCategoryId,
  ) async {
    await database.transactionsDao.updateCategoryForMultipleTransactions(
      ids,
      newCategoryId,
    );
  }

  @override
  Future<Transaction?> getTransactionById(String id) async {
    final transaction = await database.transactionsDao.getTransactionById(id);
    return transaction?.toDomain();
  }

  @override
  Future<List<Transaction>> getTransactions() async {
    final transactions = await database.transactionsDao.getAllTransactions();
    return transactions.toDomainList();
  }

  @override
  Future<List<Transaction>> getTransactionsPaginated({
    int limit = 10,
    int offset = 0,
  }) async {
    final transactions = await database.transactionsDao.getTransactions(
      limit: limit,
      offset: offset,
    );
    return transactions.toDomainList();
  }

  @override
  Future<List<Transaction>> getTransactionsByCategoryId(
    String categoryId,
  ) async {
    final transactions = await database.transactionsDao
        .getTransactionsByCategoryId(categoryId);
    return transactions.toDomainList();
  }

  @override
  Future<void> updateTransaction(Transaction transaction) async {
    // We need to use `transaction.id!` because we know for an update, the id must exist.
    final oldTransaction = await getTransactionById(transaction.id!);
    if (oldTransaction != null) {
      // Update the transaction in the database first
      await database.transactionsDao.updateTransaction(
        transaction.toCompanion(),
      );

      // Check if the account has changed
      if (oldTransaction.accountId != transaction.accountId) {
        // Revert the amount from the old account
        await _updateAccountBalance(
          oldTransaction.accountId,
          -oldTransaction.amount,
        );
        // Apply the new amount to the new account
        await _updateAccountBalance(transaction.accountId, transaction.amount);
      } else {
        // If the account is the same, just update with the difference
        final amountDifference = transaction.amount - oldTransaction.amount;
        await _updateAccountBalance(transaction.accountId, amountDifference);
      }
    }
  }

  Future<void> _updateAccountBalance(String accountId, double amount) async {
    await database.accountsDao.adjustBalance(accountId, amount);
  }

  @override
  Future<int> getAllCount() async {
    return await database.transactionsDao.getAllCount();
  }

  @override
  Future<List<Transaction>> getTransactionsWithFilters({
    int limit = 10,
    int offset = 0,
    Sort sort = Sort.descending,
    TransactionFilters? filters,
  }) async {
    final transactions = await database.transactionsDao
        .getTransactionsWithFilters(
          limit: limit,
          offset: offset,
          sort: sort == Sort.ascending ? OrderingMode.asc : OrderingMode.desc,
          description: filters?.description,
          amountFrom: filters?.amountFrom,
          amountTo: filters?.amountTo,
          dateFrom: filters?.dateFrom,
          dateTo: filters?.dateTo,
          accountId: filters?.accountId,
          categoryId: filters?.categoryId,
          currencyCode: filters?.currencyCode,
          transactionType: filters?.transactionType,
        );
    return transactions.toDomainList();
  }

  @override
  Future<int> getCountWithFilters({TransactionFilters? filters}) {
    return database.transactionsDao.getCountWithFilters(
      description: filters?.description,
      amountFrom: filters?.amountFrom,
      amountTo: filters?.amountTo,
      dateFrom: filters?.dateFrom,
      dateTo: filters?.dateTo,
      accountId: filters?.accountId,
      categoryId: filters?.categoryId,
      currencyCode: filters?.currencyCode,
      transactionType: filters?.transactionType,
    );
  }

  @override
  Future<List<GroupedTransactionTotal>> getTransactionTotalsGrouped({
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final totals = await database.transactionsDao.getTransactionTotalsGrouped(
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
    return totals
        .map(
          (t) => GroupedTransactionTotal(
            categoryId: t.categoryId,
            currencyCode: t.currencyCode,
            date: t.date,
            total: t.total,
          ),
        )
        .toList();
  }

  @override
  Future<Map<String, double>> getCategoryTotalsInMainCurrency({
    DateTime? dateFrom,
    DateTime? dateTo,
    required String mainCurrencyCode,
  }) async {
    // Delegate to DAO for SQL-level aggregation
    final result = await database.transactionsDao
        .getCategoryTotalsInMainCurrency(
          dateFrom: dateFrom,
          dateTo: dateTo,
          mainCurrencyCode: mainCurrencyCode,
        );
    return result;
  }

  @override
  Future<void> restoreTransactions(List<Transaction> transactions) async {
    await database.transaction(() async {
      final ids = transactions.map((t) => t.id!).toList();
      await database.transactionsDao.restoreTransactions(ids);

      final amountChanges = <String, double>{};
      for (final transaction in transactions) {
        amountChanges.update(
          transaction.accountId,
          (value) => value + transaction.amount,
          ifAbsent: () => transaction.amount,
        );
      }
      await database.accountsDao.batchUpdateBalances(amountChanges);
    });
  }
}
