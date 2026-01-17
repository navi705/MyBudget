import 'package:my_budget_client/domain/entities/style.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';

class TransactionCategory {
  final Transaction transaction;
  final Style style;
  final Transaction? linkedTransaction;
  final bool isAssetTransaction; // Added

  TransactionCategory({
    required this.transaction,
    required this.style,
    this.linkedTransaction,
    this.isAssetTransaction = false, // Added default false
  });

  Map<String, dynamic> toJson() {
    return {
      'transaction': transaction.toJson(),
      'style': style.toJson(),
      'linkedTransaction': linkedTransaction?.toJson(),
      'isAssetTransaction': isAssetTransaction,
    };
  }
}
