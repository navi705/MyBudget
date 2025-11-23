import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart' as db;
import 'package:my_budget_client/core/mappers/transaction_mapper.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';

class LocalTransactionRepository implements TransactionRepository {
  final db.AppDatabase database;

  LocalTransactionRepository(this.database);

  @override
  Stream<List<Transaction>> watchTransactions() {
    return database.transactionsDao.watchAllTransactions().map((transactions) {
      return transactions.map((t) => t.toDomain()).toList();
    });
  }

  @override
  Future<void> addTransaction(Transaction transaction) async {
    await database.transactionsDao.insertTransaction(transaction.toCompanion());
    await _updateAccountBalance(transaction.accountId, transaction.amount);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final transaction = await getTransactionById(id);
    if (transaction != null) {
      await database.transactionsDao
          .deleteTransaction(db.TransactionsCompanion(id: Value(id)));
      await _updateAccountBalance(transaction.accountId, -transaction.amount);
    }
  }

  @override
  Future<Transaction?> getTransactionById(String id) async {
    final transaction =
        await database.transactionsDao.getTransactionById(id);
    return transaction?.toDomain();
  }

  @override
  Future<List<Transaction>> getTransactions() async {
    final transactions = await database.transactionsDao.getAllTransactions();
    return transactions.map((t) => t.toDomain()).toList();
  }

  @override
  Future<List<Transaction>> getTransactionsByCategoryId(String categoryId) async {
    final transactions = await database.transactionsDao
        .getTransactionsByCategoryId(categoryId);
    return transactions.map((t) => t.toDomain()).toList();
  }

  @override
  Future<void> updateTransaction(Transaction transaction) async {
    // We need to use `transaction.id!` because we know for an update, the id must exist.
    final oldTransaction = await getTransactionById(transaction.id!);
    if (oldTransaction != null) {
      // Update the transaction in the database first
      await database.transactionsDao
          .updateTransaction(transaction.toCompanion());

      // Check if the account has changed
      if (oldTransaction.accountId != transaction.accountId) {
        // Revert the amount from the old account
        await _updateAccountBalance(
            oldTransaction.accountId, -oldTransaction.amount);
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
    final account = await database.accountsDao.getAccountById(accountId);
    if (account != null) {
      final newBalance = account.balance + amount;
      final companion =
          account.toCompanion(false).copyWith(balance: Value(newBalance));
      await database.accountsDao.updateAccount(companion);
    }
  }
}
