import 'package:my_budget_client/data/repositories/local_db/local_transaction_repository.dart';
import 'package:my_budget_client/data/repositories/remote_api/remote_transaction_repository.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final LocalTransactionRepository localRepository;
  final RemoteTransactionRepository remoteRepository;

  TransactionRepositoryImpl({
    required this.localRepository,
    required this.remoteRepository,
  });

  @override
  Future<void> addTransaction(Transaction transaction) {
    // For now, we'll just add to the local repository.
    // In a real app, you'd have logic here to decide whether to
    // add to remote, then sync, or add to local and sync later.
    return localRepository.addTransaction(transaction);
  }

  @override
  Future<void> deleteTransaction(int id) {
    // For now, we'll just delete from the local repository.
    return localRepository.deleteTransaction(id);
  }

  @override
  Future<Transaction?> getTransactionById(int id) {
    // For now, we'll just get from the local repository.
    return localRepository.getTransactionById(id);
  }

  @override
  Future<List<Transaction>> getTransactions() {
    // For now, we'll just get from the local repository.
    // Here you could implement logic to:
    // 1. Try remote first, if successful, update local cache.
    // 2. If remote fails, fall back to local.
    // 3. Or, always return local and sync in background.
    return localRepository.getTransactions();
  }

  @override
  Future<void> updateTransaction(Transaction transaction) {
    // For now, we'll just update the local repository.
    return localRepository.updateTransaction(transaction);
  }
}
