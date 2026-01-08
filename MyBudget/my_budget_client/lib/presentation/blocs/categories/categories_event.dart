part of 'categories_bloc.dart';

abstract class CategoriesEvent extends Equatable {
  const CategoriesEvent();

  @override
  List<Object?> get props => [];
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

class FilterCategoriesByType extends CategoriesEvent {
  final CategoryType? categoryType;

  const FilterCategoriesByType(this.categoryType);

  @override
  List<Object?> get props => [categoryType];
}

class DatePeriodNavigated extends CategoriesEvent {
  final int direction;

  const DatePeriodNavigated(this.direction);

  @override
  List<Object> get props => [direction];
}

class DateStepChanged extends CategoriesEvent {
  final DateStep dateStep;

  const DateStepChanged(this.dateStep);

  @override
  List<Object> get props => [dateStep];
}

class ActiveDateChanged extends CategoriesEvent {
  final DateTime date;

  const ActiveDateChanged(this.date);

  @override
  List<Object> get props => [date];
}

class ActiveDateRangeChanged extends CategoriesEvent {
  final DateTimeRange dateRange;

  const ActiveDateRangeChanged(this.dateRange);

  @override
  List<Object> get props => [dateRange];
}

class FilterModeChanged extends CategoriesEvent {
  final FilterMode filterMode;

  const FilterModeChanged(this.filterMode);

  @override
  List<Object> get props => [filterMode];
}

class SortChanged extends CategoriesEvent {
  final Sort sort;

  const SortChanged(this.sort);

  @override
  List<Object> get props => [sort];
}

class FiltersChanged extends CategoriesEvent {
  final CategoryFilters filters;

  const FiltersChanged(this.filters);

  @override
  List<Object> get props => [filters];
}

class ToggleSelectionMode extends CategoriesEvent {
  final bool isSelectionModeActive;

  const ToggleSelectionMode(this.isSelectionModeActive);

  @override
  List<Object> get props => [isSelectionModeActive];
}

class ToggleCategorySelection extends CategoriesEvent {
  final String categoryId;

  const ToggleCategorySelection(this.categoryId);

  @override
  List<Object> get props => [categoryId];
}

class SelectAllCategories extends CategoriesEvent {}

class ClearSelection extends CategoriesEvent {}

class DeleteMultipleCategories extends CategoriesEvent {
  final List<String> categoryIds;

  const DeleteMultipleCategories(this.categoryIds);

  @override
  List<Object> get props => [categoryIds];
}

class UpdateCategoryTypeForMultipleCategories extends CategoriesEvent {
  final List<String> categoryIds;
  final CategoryType newType;

  const UpdateCategoryTypeForMultipleCategories(this.categoryIds, this.newType);

  @override
  List<Object> get props => [categoryIds, newType];
}
