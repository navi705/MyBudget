import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart' as drift;
import 'package:my_budget_client/domain/entities/account.dart';

extension AccountMapper on drift.Account {
  Account toDomain() {
    return Account(
      id: id,
      name: name,
      balance: balance,
      currencyId: currencyId,
      styleId: styleId,
    );
  }
}

extension AccountCompanionMapper on Account {
  drift.AccountsCompanion toCompanion() {
    return drift.AccountsCompanion(
      id: id == null ? const Value.absent() : Value(id!),
      name: Value(name),
      balance: Value(balance),
      currencyId: Value(currencyId),
      styleId: Value(styleId),
    );
  }
}
