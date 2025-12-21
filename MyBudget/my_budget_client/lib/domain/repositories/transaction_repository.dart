import 'package:equatable/equatable.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';

abstract class TransactionRepository {
  Stream<List<Transaction>> watchTransactions();
  Future<List<Transaction>> getTransactions();
  Future<List<Transaction>> getTransactionsPaginated({
    int limit = 10,
    int offset = 0,
  });
  Future<List<Transaction>> getTransactionsWithFilters({
    int limit = 10,
    int offset = 0,
    Sort sort = Sort.descending,
    TransactionFilters? filters,
  });
  Future<List<Transaction>> getTransactionsByCategoryId(String categoryId);
  Future<Transaction?> getTransactionById(String id);
  Future<void> addTransaction(Transaction transaction);
  Future<void> addTransactions(List<Transaction> transactions);
  Future<void> updateTransaction(Transaction transaction);
  Future<void> deleteTransaction(String id);
  Future<int> getAllCount();
}

class TransactionFilters extends Equatable {
  final String? description;
  final double? amount;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? accountId;
  final String? categoryId;
  final String? currencyCode;

  const TransactionFilters({
    this.description,
    this.amount,
    this.dateFrom,
    this.dateTo,
    this.accountId,
    this.categoryId,
    this.currencyCode,
  });

  TransactionFilters copyWith({
    String? description,
    double? amount,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? accountId,
    String? categoryId,
    String? currencyCode,
  }) {
    return TransactionFilters(
      description: description ?? this.description,
      amount: amount ?? this.amount,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      currencyCode: currencyCode ?? this.currencyCode,
    );
  }

  @override
  List<Object?> get props => [
        description,
        amount,
        dateFrom,
        dateTo,
        accountId,
        categoryId,
        currencyCode,
      ];
}

enum Sort { ascending, descending }
