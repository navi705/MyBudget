import 'package:my_budget_client/domain/entities/transaction.dart';

abstract class TransactionRepository {
  Stream<List<Transaction>> watchTransactions();
  Future<List<Transaction>> getTransactions();
  Future<Transaction?> getTransactionById(int id);
  Future<void> addTransaction(Transaction transaction);
  Future<void> updateTransaction(Transaction transaction);
  Future<void> deleteTransaction(int id);
}
