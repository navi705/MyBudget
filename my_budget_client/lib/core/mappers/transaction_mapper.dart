import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart' as drift;
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/value_objects/amount.dart';
import 'package:uuid/uuid.dart';

/// Exact minor units for a fiat [major] value in [code], or null for non-fiat
/// (crypto/commodity), whose minor column stays NULL.
int? _minorOrNull(double major, String code) {
  final a = Amount.fromMajorCode(major, code);
  return a is FiatAmount ? a.minorUnits : null;
}

extension TransactionMapper on drift.Transaction {
  Transaction toDomain() {
    return Transaction(
      id: id,
      description: description,
      amount: amount,
      date: date,
      accountId: accountId,
      categoryId: categoryId,
      currencyCode: currencyCode,
      exchangeRate: exchangeRate,
      exchangeRatePreset: exchangeRatePreset,
      fee: fee,
      linkedTransactionId: linkedTransactionId,
      needsReview: needsReview,
    );
  }
}

extension TransactionCompanionMapper on Transaction {
  drift.TransactionsCompanion toCompanion() {
    return drift.TransactionsCompanion(
      id: Value(id ?? const Uuid().v4()),
      description: Value(description),
      amount: Value(amount),
      amountMinor: Value(_minorOrNull(amount, currencyCode)),
      date: Value(date),
      accountId: Value(accountId),
      categoryId: Value(categoryId),
      currencyCode: Value(currencyCode),
      exchangeRate: Value(exchangeRate),
      exchangeRatePreset: Value(exchangeRatePreset),
      fee: Value(fee),
      feeMinor: Value(_minorOrNull(fee, currencyCode)),
      linkedTransactionId: Value(linkedTransactionId),
      needsReview: Value(needsReview),
    );
  }
}

extension TransactionListMapper on List<drift.Transaction> {
  List<Transaction> toDomainList() {
    return map((transaction) => transaction.toDomain()).toList();
  }
}

extension TransactionCompanionListMapper on List<Transaction> {
  List<drift.TransactionsCompanion> toCompanionList() {
    return map((transaction) => transaction.toCompanion()).toList();
  }
}
