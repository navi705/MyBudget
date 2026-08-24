import 'package:equatable/equatable.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/entities/transaction_type_filter.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';

abstract class TransactionRepository {
  /// Watch transactions. If [from] is provided, only transactions on or after
  /// that date are included — use this for date-bounded views (e.g. dashboard)
  /// to avoid loading the full history.
  Stream<List<Transaction>> watchTransactions({DateTime? from});

  /// Lightweight change signal — emits (void) on any transaction insert/update/
  /// delete without loading rows. Use to trigger reloads driven by SQL/aggregate
  /// queries instead of the full-history [watchTransactions] list.
  Stream<void> watchTransactionChanges();
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
  Future<List<Transaction>> getTransactionsByIds(List<String> ids);
  Future<void> addTransaction(Transaction transaction);
  Future<void> addTransactions(List<Transaction> transactions);
  Future<void> updateTransaction(Transaction transaction);
  Future<void> deleteTransaction(String id);
  Future<void> deleteMultipleTransactions(List<String> ids);
  Future<void> updateDateForMultipleTransactions(
    List<String> ids,
    DateTime newDate,
  );
  Future<void> updateCategoryForMultipleTransactions(
    List<String> ids,
    String newCategoryId,
  );
  Future<int> getCountWithFilters({TransactionFilters? filters});
  Future<int> getAllCount();
  Future<List<GroupedTransactionTotal>> getTransactionTotalsGrouped({
    DateTime? dateFrom,
    DateTime? dateTo,
  });

  /// Sum of transaction amounts strictly after [cutoff], grouped by account id.
  /// For a standard account: balanceAt(cutoff) == storedBalance - result[id].
  /// Used to derive balances via SQL instead of a full-history Dart pass.
  Future<Map<String, double>> getFutureSumsExact(DateTime cutoff);

  /// Exact integer minor-unit sums after [cutoff], grouped by account, for fiat
  /// rows only (crypto has null amountMinor and is excluded). Lets callers
  /// derive drift-free fiat balances: balanceMinorAt = balanceMinor - result.
  Future<Map<String, int>> getFutureSumsExactMinor(DateTime cutoff);

  /// OPTIMIZATION: Get category totals already converted to main currency
  /// Uses SQL aggregation with exchange rates to avoid expensive Dart computation
  Future<Map<String, double>> getCategoryTotalsInMainCurrency({
    DateTime? dateFrom,
    DateTime? dateTo,
    required String mainCurrencyCode,
  });
  /// The account [categoryId] was most often used with since [since], or null
  /// when it has no transactions in that window.
  ///
  /// Feeds the entry form's account suggestion: a category is nearly always
  /// paid from the same place, and re-picking it by hand on every entry is the
  /// single most repeated action in the app.
  Future<String?> getMostUsedAccountForCategory(
    String categoryId, {
    required DateTime since,
  });

  Future<void> restoreTransactions(List<Transaction> transactions);
}

class GroupedTransactionTotal extends Equatable {
  final String categoryId;
  final String currencyCode;
  final DateTime date;
  final double total;

  const GroupedTransactionTotal({
    required this.categoryId,
    required this.currencyCode,
    required this.date,
    required this.total,
  });

  @override
  List<Object?> get props => [categoryId, currencyCode, date, total];
}

class TransactionFilters extends Equatable {
  final String? description;
  final double? amountFrom;
  final double? amountTo;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final List<String>? accountId;
  final List<String>? categoryId;
  final List<String>? currencyCode;
  final TransactionTypeFilter transactionType;

  /// Narrows to the review queue when true, to everything already reviewed
  /// when false. Null - the default - leaves the queue mixed in with the rest,
  /// which is what every screen but the queue itself wants.
  final bool? needsReview;

  const TransactionFilters({
    this.description,
    this.amountFrom,
    this.amountTo,
    this.dateFrom,
    this.dateTo,
    this.accountId,
    this.categoryId,
    this.currencyCode,
    this.transactionType = TransactionTypeFilter.all,
    this.needsReview,
  });

  TransactionFilters copyWith({
    String? description,
    double? amountFrom,
    double? amountTo,
    DateTime? dateFrom,
    DateTime? dateTo,
    List<String>? accountId,
    List<String>? categoryId,
    List<String>? currencyCode,
    TransactionTypeFilter? transactionType,
    bool? needsReview,
    // Every other field is cleared by building a fresh TransactionFilters,
    // but the queue toggle flips one field of the filters already on screen
    // and null is what "off" means, which `??` cannot express.
    bool clearNeedsReview = false,
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
      transactionType: transactionType ?? this.transactionType,
      needsReview: clearNeedsReview ? null : (needsReview ?? this.needsReview),
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
    transactionType,
    needsReview,
  ];
}
