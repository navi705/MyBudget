import 'package:equatable/equatable.dart';

class Transaction extends Equatable {
  final String? id;
  final String description;
  final double amount;
  final DateTime date;
  final String accountId;
  final String categoryId;
  final String currencyCode;
  final double? exchangeRate;
  final int? exchangeRatePreset;

  const Transaction({
    this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.accountId,
    required this.categoryId,
    required this.currencyCode,
    this.exchangeRate,
    this.exchangeRatePreset,
  });

  Transaction copyWith({
    String? id,
    String? description,
    double? amount,
    DateTime? date,
    String? accountId,
    String? categoryId,
    String? currencyCode,
    double? exchangeRate,
    int? exchangeRatePreset,
  }) {
    return Transaction(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      currencyCode: currencyCode ?? this.currencyCode,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      exchangeRatePreset: exchangeRatePreset ?? this.exchangeRatePreset,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'accountId': accountId,
      'categoryId': categoryId,
      'currencyCode': currencyCode,
      'exchangeRate': exchangeRate,
      'exchangeRatePreset': exchangeRatePreset,
    };
  }

  @override
  List<Object?> get props => [
    id,
    description,
    amount,
    date,
    accountId,
    categoryId,
    currencyCode,
    exchangeRate,
    exchangeRatePreset,
  ];
}
