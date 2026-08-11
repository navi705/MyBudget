import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart' as db;
import 'package:my_budget_client/domain/entities/category.dart';

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
      // Minting a uuid here made two calls on the same unsaved Category
      // produce two different row ids. Leaving it absent (as
      // AccountMapper/StyleMapper do) hands id assignment to the single
      // authority that already does it: CategoriesDao / the column's
      // clientDefault.
      id: id == null ? const Value.absent() : Value(id!),
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
