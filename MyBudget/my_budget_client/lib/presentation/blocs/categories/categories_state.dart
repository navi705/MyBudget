part of 'categories_bloc.dart';

abstract class CategoriesState extends Equatable {
  const CategoriesState();

  @override
  List<Object> get props => [];
}

class CategoriesInitial extends CategoriesState {}

class CategoriesLoadInProgress extends CategoriesState {}

class CategoriesLoadSuccess extends CategoriesState {
  final List<Category> categories;
  final Map<String, double> categoryTotals;
  final bool hasReachedMax;

  const CategoriesLoadSuccess({
    this.categories = const [],
    this.categoryTotals = const {},
    this.hasReachedMax = false,
  });

  CategoriesLoadSuccess copyWith({
    List<Category>? categories,
    Map<String, double>? categoryTotals,
    bool? hasReachedMax,
  }) {
    return CategoriesLoadSuccess(
      categories: categories ?? this.categories,
      categoryTotals: categoryTotals ?? this.categoryTotals,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object> get props => [categories, categoryTotals, hasReachedMax];
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
