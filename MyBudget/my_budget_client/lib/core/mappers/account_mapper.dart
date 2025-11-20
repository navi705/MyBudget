import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart' as drift;
import 'package:my_budget_client/domain/entities/account.dart';

extension AccountMapper on drift.Account {
  Account toDomain() {
    return Account(
      id: id,
      name: name,
      description: description,
      balance: balance,
      currencyId: currencyId,
      currencyDesignationId: currencyDesignationId,
      styleId: styleId,
      accountTypeId: accountTypeId,
    );
  }
}

extension AccountCompanionMapper on Account {
  drift.AccountsCompanion toCompanion({bool nullToAbsent = false}) {
    return drift.AccountsCompanion(
      id: id == null ? const Value.absent() : Value(id!),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      balance: Value(balance),
      currencyId: Value(currencyId),
      currencyDesignationId: Value(currencyDesignationId),
      styleId: styleId == null && nullToAbsent
          ? const Value.absent()
          : Value(styleId),
      accountTypeId: Value(accountTypeId),
    );
  }
}
