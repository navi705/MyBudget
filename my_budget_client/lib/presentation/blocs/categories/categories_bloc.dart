import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:my_budget_client/core/utils/performance_logger.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
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

import '../bloc_lifecycle.dart';

part 'categories_event.dart';
part 'categories_state.dart';

class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState>
    with BlocShutdownGuard<CategoriesEvent, CategoriesState> {
  final CategoryRepository _categoryRepository;
  final SettingsRepository _settingsRepository;
  final TransactionRepository _transactionRepository;
  final CurrencyRepository _currencyRepository;

  StreamSubscription<void>? _transactionsSubscription;
  // The categories table itself. The screen only loads from a cold state now
  // (the shell route remounts it on every tab switch), so a write from outside
  // this bloc — a sync, a restore — has to reach the list through here.
  StreamSubscription<List<Category>>? _categoriesSubscription;

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
    on<ClearRecentlyDeletedCategory>(_onClearRecentlyDeletedCategory);
    on<UndoDeleteCategory>(_onUndoDeleteCategory);

    _transactionsSubscription = _transactionRepository
        .watchTransactionChanges()
        .debounceTime(const Duration(milliseconds: 500))
        .listen((_) => add(LoadCategories()));

    // skip(1): the stream opens with the current table, which the first
    // LoadCategories is already fetching.
    _categoriesSubscription = _categoryRepository
        .watchCategories()
        .skip(1)
        .debounceTime(const Duration(milliseconds: 500))
        .listen((_) => add(LoadCategories()));
  }

  @override
  Future<void> close() async {
    markClosing();
    // Awaited: the listener above calls add(), and adding after the event
    // controller is closed throws. Cancelling without awaiting leaves that
    // race open on every screen dismissal.
    await _transactionsSubscription?.cancel();
    await _categoriesSubscription?.cancel();
    return super.close();
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
      String? failure;
      try {
        debugPrint(
          '[CategoriesDebug] Deleting multiple categories: ${event.categoryIds}',
        );
        for (final id in event.categoryIds) {
          await _categoryRepository.deleteCategory(id);
        }
      } catch (e) {
        failure = e.toString();
      }
      if (isShuttingDown) return;
      emit(
        currentState.copyWith(
          selectedCategoryIds: {},
          isSelectionModeActive: false,
          error: failure,
          clearError: failure == null,
        ),
      );
      // The loop is not atomic: a throw halfway leaves the earlier ids deleted,
      // so the reload has to run on the failure path too or the list keeps
      // showing rows that are already gone.
      add(LoadCategories());
    }
  }

  Future<void> _onUpdateCategoryTypeForMultipleCategories(
    UpdateCategoryTypeForMultipleCategories event,
    Emitter<CategoriesState> emit,
  ) async {
    final currentState = state;
    if (currentState is CategoriesLoadSuccess) {
      String? failure;
      try {
        final categoriesToUpdate = await _categoryRepository.getCategoriesByIds(
          event.categoryIds,
        );

        for (final category in categoriesToUpdate) {
          await _categoryRepository.updateCategory(
            category.copyWith(type: event.newType),
          );
        }
      } catch (e) {
        failure = e.toString();
      }
      if (isShuttingDown) return;
      emit(
        currentState.copyWith(
          selectedCategoryIds: {},
          isSelectionModeActive: false,
          error: failure,
          clearError: failure == null,
        ),
      );
      // Same partial-write exposure as the bulk delete above.
      add(LoadCategories());
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
      if (isShuttingDown) return;
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
            clearError: true,
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
    if (isShuttingDown) return;
    add(LoadCategories());
  }

  Future<void> _onUpdateCategory(
    UpdateCategory event,
    Emitter<CategoriesState> emit,
  ) async {
    await _categoryRepository.updateCategory(event.category);
    if (isShuttingDown) return;
    add(LoadCategories());
  }

  Future<void> _onDeleteCategory(
    DeleteCategory event,
    Emitter<CategoriesState> emit,
  ) async {
    final currentState = state;
    if (currentState is CategoriesLoadSuccess) {
      // The loaded list is a snapshot: a sync pull can remove the row between
      // the screen offering it and this event arriving, so a miss is nothing
      // left to delete rather than a crash out of the handler.
      final categoryToDelete = currentState.allCategories.firstWhereOrNull(
        (c) => c.id == event.id,
      );
      if (categoryToDelete == null) {
        debugPrint(
          '[CategoriesDebug] Category ${event.id} is already gone; nothing to delete.',
        );
        return;
      }

      debugPrint(
        '[CategoriesDebug] Deleting category: ${categoryToDelete.name} (ID: ${event.id})',
      );

      // Check if category has transactions (ignoring date filters)
      final transactions = await _transactionRepository
          .getTransactionsWithFilters(
            limit: 1,
            filters: TransactionFilters(categoryId: [event.id]),
          );

      if (transactions.isNotEmpty) {
        debugPrint(
          '[CategoriesDebug] Transactions found for ${categoryToDelete.name}. Emitting ConfirmationNeeded.',
        );
        emit(
          CategoryDeletionConfirmationNeeded(
            categoryToDelete: categoryToDelete,
            allCategories: currentState.allCategories,
            lastSuccessState: currentState,
          ),
        );
      } else {
        // Soft delete for simple categories: Save to state first
        debugPrint(
          '[CategoriesDebug] No transactions. Performing Soft Delete for ${categoryToDelete.name}',
        );
        emit(currentState.copyWith(recentlyDeletedCategory: categoryToDelete));
        await _categoryRepository.deleteCategory(event.id);
        if (isShuttingDown) return;
        add(LoadCategories());
      }
    }
  }

  Future<void> _onDeleteCategoryConfirmed(
    DeleteCategoryConfirmed event,
    Emitter<CategoriesState> emit,
  ) async {
    debugPrint(
      '[CategoriesDebug] DeleteCategoryConfirmed: deleteTransactions=${event.deleteTransactions}, newCategoryId=${event.newCategoryId}',
    );
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
    if (isShuttingDown) return;
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

  void _onClearRecentlyDeletedCategory(
    ClearRecentlyDeletedCategory event,
    Emitter<CategoriesState> emit,
  ) {
    if (state is CategoriesLoadSuccess) {
      emit(
        (state as CategoriesLoadSuccess).copyWith(
          clearRecentlyDeletedCategory: true,
        ),
      );
    }
  }

  Future<void> _onUndoDeleteCategory(
    UndoDeleteCategory event,
    Emitter<CategoriesState> emit,
  ) async {
    final currentState = state;
    if (currentState is CategoriesLoadSuccess &&
        currentState.recentlyDeletedCategory != null) {
      final category = currentState.recentlyDeletedCategory!;
      // Clear flag immediately so UI hides snackbar
      emit(currentState.copyWith(clearRecentlyDeletedCategory: true));
      try {
        await _categoryRepository.addCategory(category);
        if (isShuttingDown) return;
        add(LoadCategories());
      } catch (e) {
        // If restore fails, maybe show error? For now just reload.
        if (isShuttingDown) return;
        add(LoadCategories());
      }
    }
  }
}
