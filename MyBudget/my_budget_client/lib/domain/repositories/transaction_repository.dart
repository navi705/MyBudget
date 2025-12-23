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
  Future<void> deleteMultipleTransactions(List<String> ids);
  Future<void> updateDateForMultipleTransactions(
      List<String> ids, DateTime newDate);
  Future<int> getAllCount();
}

class TransactionFilters extends Equatable {
  final String? description;
  final double? amountFrom;
  final double? amountTo;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? accountId;
  final String? categoryId;
  final String? currencyCode;

  const TransactionFilters({
    this.description,
    this.amountFrom,
    this.amountTo,
    this.dateFrom,
    this.dateTo,
    this.accountId,
    this.categoryId,
    this.currencyCode,
  });

  TransactionFilters copyWith({
    String? description,
    double? amountFrom,
    double? amountTo,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? accountId,
    String? categoryId,
    String? currencyCode,
  }) {
    return TransactionFilters(
      description: description ?? this.description,
      amountFrom: amountFrom ?? this.amountFrom,
      amountTo: amountTo ?? this.amountTo,
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
        amountFrom,
        amountTo,
        dateFrom,
        dateTo,
        accountId,
        categoryId,
        currencyCode,
      ];
}

enum Sort { ascending, descending }
