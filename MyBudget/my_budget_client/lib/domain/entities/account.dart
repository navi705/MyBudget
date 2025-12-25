import 'package:equatable/equatable.dart';

class Account extends Equatable {
  final String? id;
  final String name;
  final String? description;
  final double balance;
  final String currencyCode;
  final String currencyDesignationId;
  final String? styleId;
  final String accountTypeId;
  final DateTime creationDate;

  const Account({
    this.id,
    required this.name,
    this.description,
    required this.balance,
    required this.currencyCode,
    required this.currencyDesignationId,
    this.styleId,
    required this.accountTypeId,
    required this.creationDate,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        balance,
        currencyCode,
        currencyDesignationId,
        styleId,
        accountTypeId,
        creationDate,
      ];

  Account copyWith({
    String? id,
    String? name,
    String? description,
    double? balance,
    String? currencyCode,
    String? currencyDesignationId,
    String? styleId,
    String? accountTypeId,
    DateTime? creationDate,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      balance: balance ?? this.balance,
      currencyCode: currencyCode ?? this.currencyCode,
      currencyDesignationId:
          currencyDesignationId ?? this.currencyDesignationId,
      styleId: styleId ?? this.styleId,
      accountTypeId: accountTypeId ?? this.accountTypeId,
      creationDate: creationDate ?? this.creationDate,
    );
  }
}
