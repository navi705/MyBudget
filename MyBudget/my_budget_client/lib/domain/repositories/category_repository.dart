import 'package:my_budget_client/domain/entities/category.dart';

abstract class CategoryRepository {
  Stream<List<Category>> watchCategories();
  Future<List<Category>> getCategories();
  Future<Category?> getCategoryById(String id);
  Future<void> addCategory(Category category);
  Future<void> addCategories(List<Category> categories);
  Future<void> updateCategory(Category category);
  Future<void> deleteCategory(String id);
  Stream<Map<String, double>> watchCategoryTotals();
}