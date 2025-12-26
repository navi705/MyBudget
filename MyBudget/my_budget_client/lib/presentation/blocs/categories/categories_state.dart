part of 'categories_bloc.dart';

abstract class CategoriesState extends Equatable {
  const CategoriesState();

  @override
  List<Object?> get props => [];
}

class CategoriesInitial extends CategoriesState {}

class CategoriesLoadInProgress extends CategoriesState {}

class CategoriesLoadSuccess extends CategoriesState {
  final List<CategoryWithTotal> categoriesWithTotals;
  final bool hasReachedMax;
  final CategoryType? selectedTypeFilter;

  const CategoriesLoadSuccess({
    this.categoriesWithTotals = const [],
    this.hasReachedMax = false,
    this.selectedTypeFilter,
  });

  CategoriesLoadSuccess copyWith({
    List<CategoryWithTotal>? categoriesWithTotals,
    bool? hasReachedMax,
    ValueGetter<CategoryType?>? getSelectedTypeFilter,
  }) {
    return CategoriesLoadSuccess(
      categoriesWithTotals: categoriesWithTotals ?? this.categoriesWithTotals,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      selectedTypeFilter: getSelectedTypeFilter != null
          ? getSelectedTypeFilter()
          : selectedTypeFilter,
    );
  }

  @override
  List<Object?> get props =>
      [categoriesWithTotals, hasReachedMax, selectedTypeFilter];
}

class CategoryDeletionConfirmationNeeded extends CategoriesState {
  final Category categoryToDelete;
  final List<Category> allCategories;

  const CategoryDeletionConfirmationNeeded({
    required this.categoryToDelete,
    required this.allCategories,
  });

  @override
  List<Object> get props => [categoryToDelete, allCategories];
}

class CategoriesLoadFailure extends CategoriesState {}
