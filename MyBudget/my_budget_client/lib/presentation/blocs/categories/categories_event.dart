part of 'categories_bloc.dart';

abstract class CategoriesEvent extends Equatable {
  const CategoriesEvent();

  @override
  List<Object> get props => [];
}

class LoadCategories extends CategoriesEvent {}

class LoadMoreCategories extends CategoriesEvent {}

class AddCategory extends CategoriesEvent {
  final Category category;

  const AddCategory(this.category);

  @override
  List<Object> get props => [category];
}

class UpdateCategory extends CategoriesEvent {
  final Category category;

  const UpdateCategory(this.category);

  @override
  List<Object> get props => [category];
}

class DeleteCategory extends CategoriesEvent {
  final String id;

  const DeleteCategory(this.id);

  @override
  List<Object> get props => [id];
}

class DeleteCategoryConfirmed extends CategoriesEvent {
  final Category categoryToDelete;
  final bool deleteTransactions;
  final String? newCategoryId;

  const DeleteCategoryConfirmed({
    required this.categoryToDelete,
    required this.deleteTransactions,
    this.newCategoryId,
  });

  @override
  List<Object> get props => [categoryToDelete, deleteTransactions];
}

class _CategoriesUpdated extends CategoriesEvent {
  final List<Category> categories;
  final Map<String, double> categoryTotals;

  const _CategoriesUpdated(this.categories, this.categoryTotals);

  @override
  List<Object> get props => [categories, categoryTotals];
}
