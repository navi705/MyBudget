import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart' as drift;
import 'package:my_budget_client/domain/entities/account.dart'
    as domain_account;
import 'package:my_budget_client/domain/value_objects/amount.dart';

/// Exact minor units for a fiat [major] value in [code], or null for non-fiat.
int? _minorOrNull(double major, String code) {
  final a = Amount.fromMajorCode(major, code);
  return a is FiatAmount ? a.minorUnits : null;
}

extension AccountMapper on drift.DbAccount {
  domain_account.Account toDomain() {
    return domain_account.Account(
      id: id,
      name: name,
      description: description,
      balance: balance,
      balanceMinor: balanceMinor,
      currencyCode: currencyCode,
      currencyDesignationId: currencyDesignationId,
      styleId: styleId,
      accountTypeId: accountTypeId,
      creationDate: creationDate,
      country: country,
      assetId: assetId,
      assetQuantity: assetQuantity,
      feeStructure: feeStructure, // Added
    );
  }
}

extension AccountCompanionMapper on domain_account.Account {
  drift.AccountsCompanion toCompanion({bool nullToAbsent = false}) {
    return drift.AccountsCompanion(
      id: id == null ? const Value.absent() : Value(id!),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      balance: Value(balance),
      balanceMinor: Value(_minorOrNull(balance, currencyCode)),
      currencyCode: Value(currencyCode),
      currencyDesignationId: Value(currencyDesignationId),
      styleId: styleId == null && nullToAbsent
          ? const Value.absent()
          : Value(styleId),
      accountTypeId: Value(accountTypeId),
      creationDate: Value(creationDate),
      country: country == null && nullToAbsent
          ? const Value.absent()
          : Value(country),
      assetId: assetId == null && nullToAbsent
          ? const Value.absent()
          : Value(assetId),
      assetQuantity: Value(assetQuantity),
      feeStructure: feeStructure == null && nullToAbsent
          ? const Value.absent()
          : Value(feeStructure), // Added
    );
  }
}

extension AccountListMapper on List<drift.DbAccount> {
  List<domain_account.Account> toDomainList() {
    return map((account) => account.toDomain()).toList();
  }
}

extension AccountCompanionListMapper on List<domain_account.Account> {
  List<drift.AccountsCompanion> toCompanionList({bool nullToAbsent = false}) {
    return map(
      (account) => account.toCompanion(nullToAbsent: nullToAbsent),
    ).toList();
  }
}
