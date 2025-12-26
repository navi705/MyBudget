import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/category_with_total.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';

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
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<CategoriesState> emit,
  ) async {
    emit(CategoriesLoadInProgress());
    try {
      final items = await _categoryRepository.getCategoriesWithTotalsPaginated(
          limit: 50, offset: 0);
      emit(CategoriesLoadSuccess(
        categoriesWithTotals: items,
        hasReachedMax: items.length < 50,
      ));
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
      final items = await _categoryRepository.getCategoriesWithTotalsPaginated(
        offset: currentState.categoriesWithTotals.length,
        limit: 50,
      );

      if (items.isEmpty) {
        emit(currentState.copyWith(hasReachedMax: true));
      }
      else {
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
