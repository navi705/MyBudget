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
      type: type,
    );
  }
}

extension CategoryCompanionMapper on Category {
  drift.CategoriesCompanion toCompanion() {
    return drift.CategoriesCompanion(
      id: id == null ? const Value.absent() : Value(id!),
      name: Value(name),
      parentId: Value(parentId),
      styleId: Value(styleId),
      type: Value(type),
    );
  }
}

extension CategoryListMapper on List<drift.Category> {
  List<Category> toDomainList() {
    return map((category) => category.toDomain()).toList();
  }
}

extension CategoryCompanionListMapper on List<Category> {
  List<drift.CategoriesCompanion> toCompanionList() {
    return map((category) => category.toCompanion()).toList();
  }
}
