import 'package:my_budget_client/domain/entities/category.dart';

abstract class CategoryRepository {
  Stream<List<Category>> watchCategories();
  Future<List<Category>> getCategories();
  Future<Category?> getCategoryById(int id);
  Future<void> addCategory(Category category);
  Future<void> updateCategory(Category category);
  Future<void> deleteCategory(int id);
  Stream<Map<int, double>> watchCategoryTotals();
}