import 'package:my_budget_client/domain/entities/style.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';

import 'package:my_budget_client/domain/entities/category.dart';

class TransactionCategory {
  final Transaction transaction;
  final Style style;
  final Category? category; // Added
  final Transaction? linkedTransaction;
  final bool isAssetTransaction;
  final bool isLinkedAssetTransaction;

  TransactionCategory({
    required this.transaction,
    required this.style,
    this.category, // Added
    this.linkedTransaction,
    this.isAssetTransaction = false,
    this.isLinkedAssetTransaction = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'transaction': transaction.toJson(),
      'style': style.toJson(),
      'linkedTransaction': linkedTransaction?.toJson(),
      'isAssetTransaction': isAssetTransaction,
      'isLinkedAssetTransaction': isLinkedAssetTransaction,
    };
  }
}
