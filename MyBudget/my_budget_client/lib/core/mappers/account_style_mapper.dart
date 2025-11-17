import 'package:my_budget_client/core/database/app_database.dart' as drift;
import 'package:my_budget_client/domain/entities/account_style.dart';
import 'package:drift/drift.dart';

extension AccountStyleMapper on drift.AccountStyle {
  AccountStyle toDomain() {
    return AccountStyle(
      id: id,
      name: name,
      iconName: iconName,
      colorHex: colorHex,
    );
  }
}

extension AccountStyleCompanionMapper on AccountStyle {
  drift.AccountStylesCompanion toCompanion() {
    return drift.AccountStylesCompanion(
      id: id == null ? const Value.absent() : Value(id!),
      name: Value(name),
      iconName: Value(iconName),
      colorHex: Value(colorHex),
    );
  }
}
