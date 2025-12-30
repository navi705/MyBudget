import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/category_with_total.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart'
    show DateStep, FilterMode;

part 'categories_event.dart';
part 'categories_state.dart';

class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  final CategoryRepository _categoryRepository;

  CategoriesBloc({
    required CategoryRepository categoryRepository,
  })  : _categoryRepository = categoryRepository,
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
      emit(currentState.copyWith(filters: currentState.filters.copyWith(sort: event.sort)));
      add(LoadCategories());
    }
  }

  void _onFiltersChanged(
    FiltersChanged event,
    Emitter<CategoriesState> emit,
  ) {
    final currentState = state;
    if (currentState is CategoriesLoadSuccess) {
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
      final filters = currentState is CategoriesLoadSuccess
          ? currentState.filters
          : const CategoryFilters();
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

      final items = await _categoryRepository.getCategoriesWithTotalsPaginated(
          limit: 50,
          offset: 0,
          filters: filters,
          dateFrom: dateFrom,
          dateTo: dateTo);
      if (currentState is CategoriesLoadSuccess) {
        emit(currentState.copyWith(
          categoriesWithTotals: items,
          hasReachedMax: items.length < 50,
        ));
      } else {
        emit(CategoriesLoadSuccess(
          categoriesWithTotals: items,
          hasReachedMax: items.length < 50,
          activeDate: DateTime.now(),
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
    final currentState = state;
    if (currentState is! CategoriesLoadSuccess || currentState.hasReachedMax) {
      return;
    }

    try {
      DateTime? dateFrom;
      DateTime? dateTo;
      if (currentState.filterMode == FilterMode.date) {
        dateFrom = currentState.activeDate;
        dateTo = currentState.activeDate;
      } else {
        dateFrom = currentState.activeDateRange?.start;
        dateTo = currentState.activeDateRange?.end;
      }

      final items = await _categoryRepository.getCategoriesWithTotalsPaginated(
        offset: currentState.categoriesWithTotals.length,
        limit: 50,
        filters: currentState.filters,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );

      if (items.isEmpty) {
        emit(currentState.copyWith(hasReachedMax: true));
      } else {
        emit(
          currentState.copyWith(
            categoriesWithTotals: List.of(currentState.categoriesWithTotals)
              ..addAll(items),
            hasReachedMax: items.length < 50,
          ),
        );
      }
    } catch (_) {
      // Keep current state on error
    }
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
