import 'package:my_budget_client/core/database/app_database.dart' as drift;
import 'package:my_budget_client/domain/entities/style.dart';
import 'package:drift/drift.dart';

extension StyleMapper on drift.Style {
  Style toDomain() {
    return Style(
      id: id,
      name: name,
      iconName: iconName,
      colorHex: colorHex,
    );
  }
}

extension StyleCompanionMapper on Style {
  drift.StylesCompanion toCompanion() {
    return drift.StylesCompanion(
      id: id == null ? const Value.absent() : Value(id!),
      name: Value(name),
      iconName: Value(iconName),
      colorHex: Value(colorHex),
    );
  }
}
