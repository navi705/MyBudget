import 'package:my_budget_client/domain/entities/style.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';

class TransactionCategory {
  final Transaction transaction;
  final Style style;

  TransactionCategory({required this.transaction, required this.style});

  Map<String, dynamic> toJson() {
    return {
      'transaction': transaction.toJson(),
      'style': style.toJson(),
    };
  }
}
