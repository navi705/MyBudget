import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart' as drift;
import 'package:my_budget_client/domain/entities/account_type.dart';

extension AccountTypeMapper on drift.AccountType {
  AccountType toDomain() {
    return AccountType(
      id: id,
      name: name,
    );
  }
}

extension AccountTypeCompanionMapper on AccountType {
  drift.AccountTypesCompanion toCompanion() {
    return drift.AccountTypesCompanion(
      id: Value(id),
      name: Value(name),
    );
  }
}
