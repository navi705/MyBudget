import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:my_budget_client/core/utils/performance_logger.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
// import 'package:my_budget_client/core/utils/device_utils.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/category_with_total.dart';
import 'package:my_budget_client/domain/entities/currency_designation.dart';
// import 'package:my_budget_client/domain/entities/settings.dart'; // unnecessary for basic save now, unless used elsewhere. Let's keep it if needed for reading but we are just saving text.
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';

import 'package:my_budget_client/core/enums/filter_enums.dart';

part 'categories_event.dart';
part 'categories_state.dart';

class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  final CategoryRepository _categoryRepository;
  final SettingsRepository _settingsRepository;
  final TransactionRepository _transactionRepository;
  final CurrencyRepository _currencyRepository;

  CategoriesBloc({
    required CategoryRepository categoryRepository,
    required SettingsRepository settingsRepository,
    required TransactionRepository transactionRepository,
    required CurrencyRepository currencyRepository,
  }) : _categoryRepository = categoryRepository,
       _settingsRepository = settingsRepository,
       _transactionRepository = transactionRepository,
       _currencyRepository = currencyRepository,
       super(CategoriesInitial()) {
    on<LoadCategories>(_onLoadCategories);
    on<LoadMoreCategories>(_onLoadMoreCategories);
    on<AddCategory>(_onAddCategory);
    on<UpdateCategory>(_onUpdateCategory);
    on<DeleteCategory>(_onDeleteCategory);
    on<DeleteCategoryConfirmed>(_onDeleteCategoryConfirmed);
    on<FilterCategoriesByType>(_onFilterCategoriesByType);
    on<DatePeriodNavigated>(_onDatePeriodNavigated);
    on<DateStepChanged>(_onDateStepChanged);
    on<ActiveDateChanged>(_onActiveDateChanged);
    on<ActiveDateRangeChanged>(_onActiveDateRangeChanged);
    on<FilterModeChanged>(_onFilterModeChanged);
    on<SortChanged>(_onSortChanged);
    on<FiltersChanged>(_onFiltersChanged);

    on<ToggleSelectionMode>(_onToggleSelectionMode);
    on<ToggleCategorySelection>(_onToggleCategorySelection);
    on<SelectAllCategories>(_onSelectAllCategories);
    on<ClearSelection>(_onClearSelection);
    on<DeleteMultipleCategories>(_onDeleteMultipleCategories);
    on<UpdateCategoryTypeForMultipleCategories>(
      _onUpdateCategoryTypeForMultipleCategories,
    );
  }

  void _onToggleSelectionMode(
    ToggleSelectionMode event,
    Emitter<CategoriesState> emit,
  ) {
    final currentState = state;
    if (currentState is CategoriesLoadSuccess) {
      emit(
        currentState.copyWith(
          isSelectionModeActive: event.isSelectionModeActive,
          selectedCategoryIds: event.isSelectionModeActive
              ? currentState.selectedCategoryIds
              : {},
        ),
      );
    }
  }

  void _onToggleCategorySelection(
    ToggleCategorySelection event,
    Emitter<CategoriesState> emit,
  ) {
    final currentState = state;
    if (currentState is CategoriesLoadSuccess) {
      final newSelectedIds = Set<String>.from(currentState.selectedCategoryIds);
      if (newSelectedIds.contains(event.categoryId)) {
        newSelectedIds.remove(event.categoryId);
      } else {
        newSelectedIds.add(event.categoryId);
      }
      emit(currentState.copyWith(selectedCategoryIds: newSelectedIds));
    }
  }

  void _onSelectAllCategories(
    SelectAllCategories event,
    Emitter<CategoriesState> emit,
  ) {
    final currentState = state;
    if (currentState is CategoriesLoadSuccess) {
      final allIds = currentState.categoriesWithTotals
          .map((c) => c.category.id!)
          .toSet();
      emit(currentState.copyWith(selectedCategoryIds: allIds));
    }
  }

  void _onClearSelection(ClearSelection event, Emitter<CategoriesState> emit) {
    final currentState = state;
    if (currentState is CategoriesLoadSuccess) {
      emit(currentState.copyWith(selectedCategoryIds: {}));
    }
  }

  Future<void> _onDeleteMultipleCategories(
    DeleteMultipleCategories event,
    Emitter<CategoriesState> emit,
  ) async {
    final currentState = state;
    if (currentState is CategoriesLoadSuccess) {
      try {
        for (final id in event.categoryIds) {
          await _categoryRepository.deleteCategory(id);
        }
        emit(
          currentState.copyWith(
            selectedCategoryIds: {},
            isSelectionModeActive: false,
          ),
        );
        add(LoadCategories());
      } catch (e) {
        // Handle error
      }
    }
  }

  Future<void> _onUpdateCategoryTypeForMultipleCategories(
    UpdateCategoryTypeForMultipleCategories event,
    Emitter<CategoriesState> emit,
  ) async {
    final currentState = state;
    if (currentState is CategoriesLoadSuccess) {
      try {
        final categoriesToUpdate = await _categoryRepository.getCategoriesByIds(
          event.categoryIds,
        );

        for (final category in categoriesToUpdate) {
          await _categoryRepository.updateCategory(
            category.copyWith(type: event.newType),
          );
        }
        emit(
          currentState.copyWith(
            selectedCategoryIds: {},
            isSelectionModeActive: false,
          ),
        );
        add(LoadCategories());
      } catch (e) {
        // Handle error
      }
    }
  }

  void _onDatePeriodNavigated(
    DatePeriodNavigated event,
    Emitter<CategoriesState> emit,
  ) {
    final currentState = state;
    if (currentState is! CategoriesLoadSuccess) return;

    DateTime newDate;
    switch (currentState.dateStep) {
      case DateStep.day:
        newDate = currentState.activeDate.add(Duration(days: event.direction));
        break;
      case DateStep.month:
        newDate = DateTime(
          currentState.activeDate.year,
          currentState.activeDate.month + event.direction,
          currentState.activeDate.day,
        );
        break;
      case DateStep.year:
        newDate = DateTime(
          currentState.activeDate.year + event.direction,
          currentState.activeDate.month,
          currentState.activeDate.day,
        );
        break;
    }
    emit(currentState.copyWith(activeDate: newDate));
    add(LoadCategories());
  }

  void _onDateStepChanged(
    DateStepChanged event,
    Emitter<CategoriesState> emit,
  ) {
    final currentState = state;
    if (currentState is CategoriesLoadSuccess) {
      emit(currentState.copyWith(dateStep: event.dateStep));
      add(LoadCategories());
    }
  }

  void _onActiveDateChanged(
    ActiveDateChanged event,
    Emitter<CategoriesState> emit,
  ) {
    final currentState = state;
    if (currentState is CategoriesLoadSuccess) {
      emit(currentState.copyWith(activeDate: event.date));
      add(LoadCategories());
    }
  }

  void _onActiveDateRangeChanged(
    ActiveDateRangeChanged event,
    Emitter<CategoriesState> emit,
  ) {
    final currentState = state;
    if (currentState is CategoriesLoadSuccess) {
      emit(currentState.copyWith(activeDateRange: event.dateRange));
      add(LoadCategories());
    }
  }

  void _onFilterModeChanged(
    FilterModeChanged event,
    Emitter<CategoriesState> emit,
  ) {
    final currentState = state;
    if (currentState is CategoriesLoadSuccess) {
      emit(currentState.copyWith(filterMode: event.filterMode));
      add(LoadCategories());
    }
  }

  void _onSortChanged(SortChanged event, Emitter<CategoriesState> emit) {
    final currentState = state;
    if (currentState is CategoriesLoadSuccess) {
      add(FiltersChanged(currentState.filters.copyWith(sort: event.sort)));
    }
  }

  Future<void> _onFiltersChanged(
    FiltersChanged event,
    Emitter<CategoriesState> emit,
  ) async {
    final currentState = state;
    if (currentState is CategoriesLoadSuccess) {
      await _settingsRepository.saveSetting(
        'category_filters',
        event.filters.toJsonString(),
      );
      emit(currentState.copyWith(filters: event.filters));
      add(LoadCategories());
    }
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<CategoriesState> emit,
  ) async {
    PerformanceLogger().start('Categories Screen Load');
    final currentState = state;
    if (currentState is! CategoriesLoadSuccess) {
      emit(CategoriesLoadInProgress());
    }

    try {
      var filters = currentState is CategoriesLoadSuccess
          ? currentState.filters
          : const CategoryFilters();
      final savedFilters = await _settingsRepository.getSetting(
        'category_filters',
      );
      if (savedFilters != null) {
        filters = CategoryFilters.fromJsonString(savedFilters.value);
      }

      DateTime? dateFrom;
      DateTime? dateTo;

      if (currentState is CategoriesLoadSuccess) {
        if (currentState.filterMode == FilterMode.date) {
          switch (currentState.dateStep) {
            case DateStep.day:
              dateFrom = currentState.activeDate;
              dateTo = currentState.activeDate;
              break;
            case DateStep.month:
              dateFrom = DateTime(
                currentState.activeDate.year,
                currentState.activeDate.month,
                1,
              );
              dateTo = DateTime(
                currentState.activeDate.year,
                currentState.activeDate.month + 1,
                0,
              );
              break;
            case DateStep.year:
              dateFrom = DateTime(currentState.activeDate.year, 1, 1);
              dateTo = DateTime(currentState.activeDate.year, 12, 31);
              break;
          }
        } else {
          dateFrom = currentState.activeDateRange?.start;
          dateTo = currentState.activeDateRange?.end;
        }
      }

      final mainCurrencyCode =
          (await _settingsRepository.getSetting('main_currency_code'))?.value ??
          'EUR';

      PerformanceLogger().start('Categories: Future.wait');
      final results = await Future.wait([
        _categoryRepository.getCategories(),
        _currencyRepository.getAllCurrencyDesignations(),
      ]);
      await PerformanceLogger().stop('Categories: Future.wait');

      final categories = results[0] as List<Category>;
      final currencyDesignations = results[1] as List<CurrencyDesignation>;

      // Legacy exchange rate logic removed - handled entirely by SQL aggregation now

      PerformanceLogger().start('Categories: compute totals');
      // OPTIMIZATION: Use SQL aggregation instead of Dart compute
      // This aggregates at DB level and only converts already-aggregated totals
      final categoryTotalsMap = await _transactionRepository
          .getCategoryTotalsInMainCurrency(
            dateFrom: dateFrom,
            dateTo: dateTo,
            mainCurrencyCode: mainCurrencyCode,
          );

      // Map categories to CategoryWithTotal
      final categoriesWithTotals = categories.map((category) {
        return CategoryWithTotal(
          category: category,
          total: categoryTotalsMap[category.id] ?? 0.0,
        );
      }).toList();
      await PerformanceLogger().stop('Categories: compute totals');

      await PerformanceLogger().stop('Categories Screen Load');

      final filteredItems = categoriesWithTotals.where((item) {
        if (filters.name != null &&
            !item.category.name.toLowerCase().contains(
              filters.name!.toLowerCase(),
            )) {
          return false;
        }
        if (filters.type != null && item.category.type != filters.type) {
          return false;
        }
        if (filters.amountFrom != null && item.total < filters.amountFrom!) {
          return false;
        }
        if (filters.amountTo != null && item.total > filters.amountTo!) {
          return false;
        }
        return true;
      }).toList();

      filteredItems.sort((a, b) {
        final comparison = a.total.compareTo(b.total);

        return filters.sort == Sort.ascending ? comparison : -comparison;
      });

      if (currentState is CategoriesLoadSuccess) {
        emit(
          currentState.copyWith(
            categoriesWithTotals: filteredItems,
            allCategories: categories,
            hasReachedMax: true,
            filters: filters,
            mainCurrencyCode: mainCurrencyCode,
            currencyDesignations: currencyDesignations,
          ),
        );
      } else {
        emit(
          CategoriesLoadSuccess(
            categoriesWithTotals: filteredItems,
            allCategories: categories,
            hasReachedMax: true,
            activeDate: DateTime.now(),
            filters: filters,
            mainCurrencyCode: mainCurrencyCode,
            currencyDesignations: currencyDesignations,
          ),
        );
      }
    } catch (e, s) {
      PerformanceLogger().stop('Categories Screen Load');
      debugPrint('Error loading categories: $e\n$s');
      emit(CategoriesLoadFailure());
    }
  }

  Future<void> _onLoadMoreCategories(
    LoadMoreCategories event,
    Emitter<CategoriesState> emit,
  ) async {
    // No-op since we load all categories at once now.
  }

  Future<void> _onAddCategory(
    AddCategory event,
    Emitter<CategoriesState> emit,
  ) async {
    await _categoryRepository.addCategory(event.category);
    add(LoadCategories());
  }

  Future<void> _onUpdateCategory(
    UpdateCategory event,
    Emitter<CategoriesState> emit,
  ) async {
    await _categoryRepository.updateCategory(event.category);
    add(LoadCategories());
  }

  Future<void> _onDeleteCategory(
    DeleteCategory event,
    Emitter<CategoriesState> emit,
  ) async {
    final currentState = state;
    if (currentState is CategoriesLoadSuccess) {
      final categoryToDelete = currentState.allCategories.firstWhere(
        (c) => c.id == event.id,
      );

      // Check if category has transactions (ignoring date filters)
      final transactions = await _transactionRepository
          .getTransactionsWithFilters(
            limit: 1,
            filters: TransactionFilters(categoryId: [event.id]),
          );

      if (transactions.isNotEmpty) {
        emit(
          CategoryDeletionConfirmationNeeded(
            categoryToDelete: categoryToDelete,
            allCategories: currentState.allCategories,
          ),
        );
      } else {
        await _categoryRepository.deleteCategory(event.id);
        add(LoadCategories());
      }
    }
  }

  Future<void> _onDeleteCategoryConfirmed(
    DeleteCategoryConfirmed event,
    Emitter<CategoriesState> emit,
  ) async {
    if (event.deleteTransactions) {
      await _categoryRepository.deleteCategoryWithTransactions(
        event.categoryToDelete.id!,
      );
    } else if (event.newCategoryId != null) {
      await _categoryRepository.deleteCategoryAndReassignTransactions(
        event.categoryToDelete.id!,
        event.newCategoryId!,
      );
    } else {
      await _categoryRepository.deleteCategory(event.categoryToDelete.id!);
    }
    add(LoadCategories());
  }

  Future<void> _onFilterCategoriesByType(
    FilterCategoriesByType event,
    Emitter<CategoriesState> emit,
  ) async {
    final currentState = state;
    if (currentState is CategoriesLoadSuccess) {
      emit(
        currentState.copyWith(getSelectedTypeFilter: () => event.categoryType),
      );
    }
  }
}
