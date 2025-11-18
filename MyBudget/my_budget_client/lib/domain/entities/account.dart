import 'package:equatable/equatable.dart';

class Account extends Equatable {
  final int? id;
  final String name;
  final double balance;
  final int currencyId;
  final int? styleId;

  Account({
    this.id,
    required this.name,
    required this.balance,
    required this.currencyId,
    this.styleId,
  });

  Account copyWith({
    int? id,
    String? name,
    double? balance,
    int? currencyId,
    int? styleId,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      currencyId: currencyId ?? this.currencyId,
      styleId: styleId ?? this.styleId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        balance,
        currencyId,
        styleId,
      ];
}
