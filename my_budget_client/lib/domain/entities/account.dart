import 'package:equatable/equatable.dart';

class Account extends Equatable {
  final String? id;
  final String name;
  final String? description;
  final double balance;

  /// Exact integer minor units of [balance] for fiat accounts; null for crypto/
  /// commodity (which stay on [balance]). Used to derive drift-free balances.
  final int? balanceMinor;
  final String currencyCode;
  final String currencyDesignationId;
  final String? styleId;
  final String accountTypeId;
  final DateTime creationDate;
  final String? country;
  final String? assetId; // Added
  final double assetQuantity; // Added
  final String? feeStructure; // Added: JSON string for Fee Constructor

  const Account({
    this.id,
    required this.name,
    this.description,
    required this.balance,
    this.balanceMinor,
    required this.currencyCode,
    required this.currencyDesignationId,
    this.styleId,
    required this.accountTypeId,
    required this.creationDate,
    this.country,
    this.assetId,
    this.assetQuantity = 0.0,
    this.feeStructure,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    balance,
    balanceMinor,
    currencyCode,
    currencyDesignationId,
    styleId,
    accountTypeId,
    creationDate,
    country,
    assetId,
    assetQuantity,
    feeStructure,
  ];

  Account copyWith({
    String? id,
    String? name,
    String? description,
    double? balance,
    int? balanceMinor,
    String? currencyCode,
    String? currencyDesignationId,
    String? styleId,
    String? accountTypeId,
    DateTime? creationDate,
    String? country,
    String? assetId,
    double? assetQuantity,
    String? feeStructure,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      balance: balance ?? this.balance,
      balanceMinor: balanceMinor ?? this.balanceMinor,
      currencyCode: currencyCode ?? this.currencyCode,
      currencyDesignationId:
          currencyDesignationId ?? this.currencyDesignationId,
      styleId: styleId ?? this.styleId,
      accountTypeId: accountTypeId ?? this.accountTypeId,
      creationDate: creationDate ?? this.creationDate,
      country: country ?? this.country,
      assetId: assetId ?? this.assetId,
      assetQuantity: assetQuantity ?? this.assetQuantity,
      feeStructure: feeStructure ?? this.feeStructure,
    );
  }
}
