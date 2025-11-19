import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart' as drift;
import 'package:my_budget_client/domain/entities/category.dart';

extension CategoryMapper on drift.Category {
  Category toDomain() {
    return Category(
      id: id,
      name: name,
      parentId: parentId,
      styleId: styleId,
    );
  }
}

extension CategoryCompanionMapper on Category {
  drift.CategoriesCompanion toCompanion() {
    return drift.CategoriesCompanion(
      id: Value(id!),
      name: Value(name),
      parentId: Value(parentId),
      styleId: Value(styleId),
    );
  }
}
