import 'dart:async';
import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/category_with_total.dart';
import 'package:my_budget_client/domain/entities/currency_designation.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart'
    show DateStep, FilterMode;
import 'package:my_budget_client/domain/entities/settings.dart';
import 'package:collection/collection.dart';
import 'package:my_budget_client/core/database/app_database.dart' as drift;
import 'package:my_budget_client/core/mappers/currency_designation_mapper.dart';

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
  })  : _categoryRepository = categoryRepository,
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

  void _onSortChanged(
    SortChanged event,
    Emitter<CategoriesState> emit,
  ) {
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
      final deviceName =
          (await _settingsRepository.getSetting('device_name'))?.value ??
              'default';
      await _settingsRepository.setSetting(Settings(
        key: 'category_filters',
        value: event.filters.toJsonString(),
        device: deviceName,
      ));
      emit(currentState.copyWith(filters: event.filters));
      add(LoadCategories());
    }
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<CategoriesState> emit,
  ) async {
    final currentState = state;
    emit(CategoriesLoadInProgress());
    try {
      var filters = currentState is CategoriesLoadSuccess
          ? currentState.filters
          : const CategoryFilters();
      final savedFilters =
          await _settingsRepository.getSetting('category_filters');
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
                  currentState.activeDate.year, currentState.activeDate.month, 1);
              dateTo = DateTime(
                  currentState.activeDate.year, currentState.activeDate.month + 1, 0);
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

      final mainCurrencyCode = (await _settingsRepository.getSetting('main_currency_code'))?.value ?? 'EUR';

      final results = await Future.wait([
        _categoryRepository.getCategories(),
        _transactionRepository.getTransactionsWithFilters(
            filters: TransactionFilters(dateFrom: dateFrom, dateTo: dateTo)),
        _currencyRepository.getLatestExchangeRates(DateTime.now()),
        _currencyRepository.getAllCurrencyDesignations(),
      ]);

      final categories = results[0] as List<Category>;
      final transactions = results[1] as List<Transaction>;
      final exchangeRates = results[2] as List<drift.ExchangeRate>;
      final currencyDesignations = (results[3] as List<drift.CurrencyDesignation>).toDomainList();

      final mainCurrencyRate = exchangeRates
              .firstWhereOrNull((r) => r.toCurrencyCode == mainCurrencyCode)
              ?.rate ??
          1.0;

      final categoriesWithTotals = categories.map((category) {
        final categoryTransactions = transactions
            .where((t) => t.categoryId == category.id);
        double total = 0;
        for (final transaction in categoryTransactions) {
           final rate = exchangeRates
                  .firstWhereOrNull(
                      (r) => r.toCurrencyCode == transaction.currencyCode)
                  ?.rate ??
              1.0;

          // Convert amount to EUR first, then to main currency
          final amountInEur = transaction.amount / rate;
          total += amountInEur * mainCurrencyRate;
        }
        return CategoryWithTotal(category: category, total: total);
      }).toList();
      
      // Apply filters and sorting
      final filteredItems = categoriesWithTotals.where((item) {
        if (filters.name != null &&
            !item.category.name.toLowerCase().contains(filters.name!.toLowerCase())) {
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
        final comparison = a.category.name.compareTo(b.category.name);
        return filters.sort == Sort.ascending ? comparison : -comparison;
      });

      if (currentState is CategoriesLoadSuccess) {
        emit(currentState.copyWith(
          categoriesWithTotals: filteredItems,
          hasReachedMax: true, // Since we fetch all transactions
          filters: filters,
          mainCurrencyCode: mainCurrencyCode,
          currencyDesignations: currencyDesignations,
        ));
      } else {
        emit(CategoriesLoadSuccess(
          categoriesWithTotals: filteredItems,
          hasReachedMax: true,
          activeDate: DateTime.now(),
          filters: filters,
          mainCurrencyCode: mainCurrencyCode,
          currencyDesignations: currencyDesignations,
        ));
      }
    } catch (e) {
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
    await _categoryRepository.deleteCategory(event.id);
    add(LoadCategories());
  }

  Future<void> _onDeleteCategoryConfirmed(
    DeleteCategoryConfirmed event,
    Emitter<CategoriesState> emit,
  ) async {
    await _categoryRepository.deleteCategory(event.categoryToDelete.id!);
    add(LoadCategories());
  }

  Future<void> _onFilterCategoriesByType(
    FilterCategoriesByType event,
    Emitter<CategoriesState> emit,
  ) async {
    final currentState = state;
    if (currentState is CategoriesLoadSuccess) {
      emit(currentState.copyWith(
        getSelectedTypeFilter: () => event.categoryType,
      ));
    }
  }
}