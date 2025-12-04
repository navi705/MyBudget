import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart' as drift;
import 'package:my_budget_client/domain/entities/transaction.dart';

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
    );
  }
}

extension TransactionCompanionMapper on Transaction {
  drift.TransactionsCompanion toCompanion() {
    return drift.TransactionsCompanion(
      id: id == null ? const Value.absent() : Value(id!),
      description: Value(description),
      amount: Value(amount),
      date: Value(date),
      accountId: Value(accountId),
      categoryId: Value(categoryId),
      currencyCode: Value(currencyCode),
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
