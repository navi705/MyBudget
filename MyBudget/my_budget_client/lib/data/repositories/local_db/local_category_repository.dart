import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart' as drift;
import 'package:my_budget_client/core/mappers/category_mapper.dart';
import 'package:my_budget_client/core/mappers/category_with_total_mapper.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/category_with_total.dart' as domain;
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';

class LocalCategoryRepository implements CategoryRepository {
  final drift.AppDatabase _appDatabase;

  LocalCategoryRepository(this._appDatabase);

  @override
  Stream<List<Category>> watchCategories() {
    return _appDatabase.categoriesDao.watchAllCategories().map((categories) {
      return categories.toDomainList();
    });
  }

  @override
  Future<void> addCategory(Category category) async {
    await _appDatabase.categoriesDao.insertCategory(category.toCompanion());
  }

  @override
  Future<void> addCategories(List<Category> categories) async {
    await _appDatabase.categoriesDao
        .insertAllCategories(categories.toCompanionList());
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _appDatabase.categoriesDao.deleteCategory(
      drift.CategoriesCompanion(id: Value(id)),
    );
  }

  @override
  Future<List<Category>> getCategories() async {
    final driftCategories = await _appDatabase.categoriesDao.getAllCategories();
    return driftCategories.toDomainList();
  }

  @override
  Future<List<Category>> getCategoriesPaginated(
      {int limit = 10, int offset = 0}) async {
    final driftCategories = await _appDatabase.categoriesDao
        .getCategories(limit: limit, offset: offset);
    return driftCategories.toDomainList();
  }

  @override
  Future<List<domain.CategoryWithTotal>> getCategoriesWithTotalsPaginated({
    int limit = 50,
    int offset = 0,
    CategoryFilters filters = const CategoryFilters(),
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final results = await _appDatabase.categoriesDao.getCategoriesWithTotals(
      limit: limit,
      offset: offset,
      name: filters.name,
      sort: filters.sort == Sort.ascending
          ? OrderingMode.asc
          : OrderingMode.desc,
      dateFrom: dateFrom,
      dateTo: dateTo,
      type: filters.type,
    );
    return results.toDomainList();
  }

  @override
  Future<Category?> getCategoryById(String id) async {
    final driftCategory = await _appDatabase.categoriesDao.getCategoryById(id);
    return driftCategory?.toDomain();
  }

  @override
  Future<void> updateCategory(Category category) async {
    await _appDatabase.categoriesDao.updateCategory(category.toCompanion());
  }
}
