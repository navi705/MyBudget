import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';

class RemoteTransactionRepository implements TransactionRepository {
  @override
  Future<void> addTransaction(Transaction transaction) {
    // TODO: Implement actual remote API call
    throw UnimplementedError('addTransaction not implemented for RemoteTransactionRepository');
  }

  @override
  Future<void> deleteTransaction(int id) {
    // TODO: Implement actual remote API call
    throw UnimplementedError('deleteTransaction not implemented for RemoteTransactionRepository');
  }

  @override
  Future<Transaction?> getTransactionById(int id) {
    // TODO: Implement actual remote API call
    throw UnimplementedError('getTransactionById not implemented for RemoteTransactionRepository');
  }

  @override
  Future<List<Transaction>> getTransactions() {
    // TODO: Implement actual remote API call
    throw UnimplementedError('getTransactions not implemented for RemoteTransactionRepository');
  }

  @override
  Future<void> updateTransaction(Transaction transaction) {
    // TODO: Implement actual remote API call
    throw UnimplementedError('updateTransaction not implemented for RemoteTransactionRepository');
  }
}
