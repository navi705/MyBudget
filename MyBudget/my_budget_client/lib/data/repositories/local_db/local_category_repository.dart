import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart' as drift;
import 'package:my_budget_client/core/mappers/category_mapper.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';

class LocalCategoryRepository implements CategoryRepository {
  final drift.AppDatabase _appDatabase;

  LocalCategoryRepository(this._appDatabase);

  @override
  Stream<List<Category>> watchCategories() {
    return _appDatabase.categoriesDao.watchAllCategories().map((categories) {
      return categories.map((c) => c.toDomain()).toList();
    });
  }

  @override
  Future<void> addCategory(Category category) async {
    final companion = drift.CategoriesCompanion.insert(
      name: category.name,
      parentId: Value(category.parentId),
      styleId: Value(category.styleId),
    );
    await _appDatabase.categoriesDao.insertCategory(companion);
  }

  @override
  Future<void> deleteCategory(int id) async {
    await _appDatabase.categoriesDao.deleteCategory(
      drift.CategoriesCompanion(id: Value(id)),
    );
  }

  @override
  Future<List<Category>> getCategories() async {
    final driftCategories = await _appDatabase.categoriesDao.getAllCategories();
    return driftCategories.map((c) => c.toDomain()).toList();
  }

  @override
  Future<Category?> getCategoryById(int id) async {
    final driftCategory = await _appDatabase.categoriesDao.getCategoryById(id);
    return driftCategory?.toDomain();
  }

  @override
  Future<void> updateCategory(Category category) async {
    await _appDatabase.categoriesDao.updateCategory(category.toCompanion());
  }

  @override
  Stream<Map<int, double>> watchCategoryTotals() {
    return _appDatabase.categoriesDao.watchCategoryTotals();
  }
}
