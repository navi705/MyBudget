import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart' as drift;
import 'package:my_budget_client/domain/entities/account_type.dart';

extension AccountTypeMapper on drift.AccountType {
  AccountType toDomain() {
    return AccountType(
      id: id,
      name: name,
      languageCode: languageCode,
    );
  }
}

extension AccountTypeCompanionMapper on AccountType {
  drift.AccountTypesCompanion toCompanion() {
    return drift.AccountTypesCompanion(
      id: Value(id),
      name: Value(name),
      languageCode: Value(languageCode)
    );
  }
}

extension AccountTypeListMapper on List<drift.AccountType> {
  List<AccountType> toDomainList() {
    return map((accountType) => accountType.toDomain()).toList();
  }
}

extension AccountTypeCompanionListMapper on List<AccountType> {
  List<drift.AccountTypesCompanion> toCompanionList() {
    return map((accountType) => accountType.toCompanion()).toList();
  }
}
