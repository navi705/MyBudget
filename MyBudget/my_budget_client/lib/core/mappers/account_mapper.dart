import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart' as drift;
import 'package:my_budget_client/domain/entities/account.dart' as domain_account;

extension AccountMapper on drift.DbAccount {
  domain_account.Account toDomain() {
    return domain_account.Account(
      id: id,
      name: name,
      description: description,
      balance: balance,
      currencyCode: currencyCode,
      currencyDesignationId: currencyDesignationId,
      styleId: styleId,
      accountTypeId: accountTypeId,
      creationDate: creationDate,
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
      currencyCode: Value(currencyCode),
      currencyDesignationId: Value(currencyDesignationId),
      styleId: styleId == null && nullToAbsent
          ? const Value.absent()
          : Value(styleId),
      accountTypeId: Value(accountTypeId),
      creationDate: Value(creationDate),
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
    return map((account) => account.toCompanion(nullToAbsent: nullToAbsent))
        .toList();
  }
}
