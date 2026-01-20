import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart' as db;
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:uuid/uuid.dart';

extension CategoryMapper on db.Category {
  Category toDomain() {
    return Category(
      id: id,
      name: name,
      parentId: parentId,
      styleId: styleId,
      type: type,
    );
  }
}

extension CategoriesMapper on Category {
  db.CategoriesCompanion toCompanion() {
    return db.CategoriesCompanion(
      id: Value(id ?? const Uuid().v4()),
      name: Value(name),
      parentId: Value(parentId),
      styleId: Value(styleId),
      type: Value(type),
    );
  }
}

extension CategoriesListMapper on List<db.Category> {
  List<Category> toDomainList() {
    return map((e) => e.toDomain()).toList();
  }
}

extension CategoryListMapper on List<Category> {
  List<db.CategoriesCompanion> toCompanionList() {
    return map((e) => e.toCompanion()).toList();
  }
}
