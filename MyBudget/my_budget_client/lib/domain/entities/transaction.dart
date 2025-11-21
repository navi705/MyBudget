import 'package:equatable/equatable.dart';

class Transaction extends Equatable {
  final int? id;
  final String description;
  final double amount;
  final DateTime date;
  final int accountId;
  final int categoryId;
  final int currencyId;

  const Transaction({
    this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.accountId,
    required this.categoryId,
    required this.currencyId,
  });

  Transaction copyWith({
    int? id,
    String? description,
    double? amount,
    DateTime? date,
    int? accountId,
    int? categoryId,
    int? currencyId,
  }) {
    return Transaction(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      currencyId: currencyId ?? this.currencyId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        description,
        amount,
        date,
        accountId,
        categoryId,
        currencyId,
      ];
}
