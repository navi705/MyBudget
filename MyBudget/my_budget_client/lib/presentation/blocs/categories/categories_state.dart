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
  final CategoryFilters filters;
  final DateTime activeDate;
  final DateStep dateStep;
  final FilterMode filterMode;
  final DateTimeRange? activeDateRange;

  const CategoriesLoadSuccess({
    this.categoriesWithTotals = const [],
    this.hasReachedMax = false,
    this.selectedTypeFilter,
    this.filters = const CategoryFilters(),
    required this.activeDate,
    this.dateStep = DateStep.month,
    this.filterMode = FilterMode.date,
    this.activeDateRange,
  });

  CategoriesLoadSuccess copyWith({
    List<CategoryWithTotal>? categoriesWithTotals,
    bool? hasReachedMax,
    ValueGetter<CategoryType?>? getSelectedTypeFilter,
    CategoryFilters? filters,
    DateTime? activeDate,
    DateStep? dateStep,
    FilterMode? filterMode,
    DateTimeRange? activeDateRange,
  }) {
    return CategoriesLoadSuccess(
      categoriesWithTotals: categoriesWithTotals ?? this.categoriesWithTotals,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      selectedTypeFilter: getSelectedTypeFilter != null
          ? getSelectedTypeFilter()
          : selectedTypeFilter,
      filters: filters ?? this.filters,
      activeDate: activeDate ?? this.activeDate,
      dateStep: dateStep ?? this.dateStep,
      filterMode: filterMode ?? this.filterMode,
      activeDateRange: activeDateRange ?? this.activeDateRange,
    );
  }

  @override
  List<Object?> get props => [
        categoriesWithTotals,
        hasReachedMax,
        selectedTypeFilter,
        filters,
        activeDate,
        dateStep,
        filterMode,
        activeDateRange,
      ];
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
