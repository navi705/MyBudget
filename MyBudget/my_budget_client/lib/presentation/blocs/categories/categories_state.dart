part of 'categories_bloc.dart';

abstract class CategoriesState extends Equatable {
  const CategoriesState();

  @override
  List<Object?> get props => [];
}

class CategoryDeletionConfirmationNeeded extends CategoriesState {
  final Category categoryToDelete;
  final List<Category> allCategories;
  final CategoriesLoadSuccess lastSuccessState;

  const CategoryDeletionConfirmationNeeded({
    required this.categoryToDelete,
    required this.allCategories,
    required this.lastSuccessState,
  });

  @override
  List<Object> get props => [categoryToDelete, allCategories, lastSuccessState];
}

class CategoriesInitial extends CategoriesState {}

class CategoriesLoadInProgress extends CategoriesState {}

class CategoriesLoadSuccess extends CategoriesState {
  final List<CategoryWithTotal> categoriesWithTotals;
  final List<Category> allCategories;
  final bool hasReachedMax;
  final CategoryType? selectedTypeFilter;
  final CategoryFilters filters;
  final DateTime activeDate;
  final DateStep dateStep;
  final FilterMode filterMode;
  final DateTimeRange? activeDateRange;
  final String mainCurrencyCode;
  final List<CurrencyDesignation> currencyDesignations;
  final bool isSelectionModeActive;
  final Set<String> selectedCategoryIds;
  final Category? recentlyDeletedCategory;

  const CategoriesLoadSuccess({
    this.categoriesWithTotals = const [],
    this.allCategories = const [],
    this.hasReachedMax = false,
    this.selectedTypeFilter,
    this.filters = const CategoryFilters(),
    required this.activeDate,
    this.dateStep = DateStep.month,
    this.filterMode = FilterMode.date,
    this.activeDateRange,
    this.mainCurrencyCode = 'EUR',
    this.currencyDesignations = const [],
    this.isSelectionModeActive = false,
    this.selectedCategoryIds = const {},
    this.recentlyDeletedCategory,
  });

  CategoriesLoadSuccess copyWith({
    List<CategoryWithTotal>? categoriesWithTotals,
    List<Category>? allCategories,
    bool? hasReachedMax,
    ValueGetter<CategoryType?>? getSelectedTypeFilter,
    CategoryFilters? filters,
    DateTime? activeDate,
    DateStep? dateStep,
    FilterMode? filterMode,
    DateTimeRange? activeDateRange,
    String? mainCurrencyCode,
    List<CurrencyDesignation>? currencyDesignations,
    bool? isSelectionModeActive,
    Set<String>? selectedCategoryIds,
    Category? recentlyDeletedCategory,
    bool clearRecentlyDeletedCategory = false,
  }) {
    return CategoriesLoadSuccess(
      categoriesWithTotals: categoriesWithTotals ?? this.categoriesWithTotals,
      allCategories: allCategories ?? this.allCategories,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      selectedTypeFilter: getSelectedTypeFilter != null
          ? getSelectedTypeFilter()
          : selectedTypeFilter,
      filters: filters ?? this.filters,
      activeDate: activeDate ?? this.activeDate,
      dateStep: dateStep ?? this.dateStep,
      filterMode: filterMode ?? this.filterMode,
      activeDateRange: activeDateRange ?? this.activeDateRange,
      mainCurrencyCode: mainCurrencyCode ?? this.mainCurrencyCode,
      currencyDesignations: currencyDesignations ?? this.currencyDesignations,
      isSelectionModeActive:
          isSelectionModeActive ?? this.isSelectionModeActive,
      selectedCategoryIds: selectedCategoryIds ?? this.selectedCategoryIds,
      recentlyDeletedCategory: clearRecentlyDeletedCategory
          ? null
          : (recentlyDeletedCategory ?? this.recentlyDeletedCategory),
    );
  }

  @override
  List<Object?> get props => [
    categoriesWithTotals,
    allCategories,
    hasReachedMax,
    selectedTypeFilter,
    filters,
    activeDate,
    dateStep,
    filterMode,
    activeDateRange,
    mainCurrencyCode,
    currencyDesignations,
    isSelectionModeActive,
    selectedCategoryIds,
    recentlyDeletedCategory,
  ];
}

class CategoriesLoadFailure extends CategoriesState {}
