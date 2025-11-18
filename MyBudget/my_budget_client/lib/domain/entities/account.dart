import 'package:equatable/equatable.dart';

class Account extends Equatable {
  final int? id;
  final String name;
  final String? description;
  final double balance;
  final int currencyId;
  final int currencyDesignationId;
  final int? styleId;
  final int accountTypeId;

  const Account({
    this.id,
    required this.name,
    this.description,
    required this.balance,
    required this.currencyId,
    required this.currencyDesignationId,
    this.styleId,
    required this.accountTypeId,
  });

  Account copyWith({
    int? id,
    String? name,
    String? description,
    double? balance,
    int? currencyId,
    int? currencyDesignationId,
    int? styleId,
    int? accountTypeId,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      balance: balance ?? this.balance,
      currencyId: currencyId ?? this.currencyId,
      currencyDesignationId: currencyDesignationId ?? this.currencyDesignationId,
      styleId: styleId ?? this.styleId,
      accountTypeId: accountTypeId ?? this.accountTypeId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        balance,
        currencyId,
        currencyDesignationId,
        styleId,
        accountTypeId,
      ];
}
