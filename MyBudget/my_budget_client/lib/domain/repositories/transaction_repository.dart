import 'package:my_budget_client/domain/entities/transaction.dart';

abstract class TransactionRepository {
  Stream<List<Transaction>> watchTransactions();
  Future<List<Transaction>> getTransactions();
  Future<List<Transaction>> getTransactionsPaginated({
    int limit = 10,
    int offset = 0,
  });
  Future<List<Transaction>> getTransactionsPaginatedSortFiltered({
    int limit = 10,
    int offset = 0,
    Sort sort,
    FilterFieldsTransaction fields
  });
  Future<List<Transaction>> getTransactionsByCategoryId(String categoryId);
  Future<Transaction?> getTransactionById(String id);
  Future<void> addTransaction(Transaction transaction);
  Future<void> addTransactions(List<Transaction> transactions);
  Future<void> updateTransaction(Transaction transaction);
  Future<void> deleteTransaction(String id);
  Future<int> getAllCount();
}

class FilterFieldsTransaction{
  
}

enum Sort{
  ascending,
  descending
}

