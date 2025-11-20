import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:rxdart/rxdart.dart';

part 'categories_event.dart';
part 'categories_state.dart';

class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  final CategoryRepository _categoryRepository;
  StreamSubscription? _categoriesSubscription;

  CategoriesBloc({required CategoryRepository categoryRepository})
      : _categoryRepository = categoryRepository,
        super(CategoriesInitial()) {
    on<LoadCategories>(_onLoadCategories);
    on<AddCategory>(_onAddCategory);
    on<UpdateCategory>(_onUpdateCategory);
    on<DeleteCategory>(_onDeleteCategory);
    on<_CategoriesUpdated>(_onCategoriesUpdated);
  }

  void _onLoadCategories(
    LoadCategories event,
    Emitter<CategoriesState> emit,
  ) {
    emit(CategoriesLoadInProgress());
    _categoriesSubscription?.cancel();
    _categoriesSubscription = Rx.combineLatest2(
      _categoryRepository.watchCategories(),
      _categoryRepository.watchCategoryTotals(),
      (List<Category> categories, Map<int, double> totals) =>
          _CategoriesUpdated(categories, totals),
    ).listen(
      (update) => add(update),
      onError: (_) => emit(CategoriesLoadFailure()),
    );
  }

  Future<void> _onAddCategory(
    AddCategory event,
    Emitter<CategoriesState> emit,
  ) async {
    await _categoryRepository.addCategory(event.category);
  }

  Future<void> _onUpdateCategory(
    UpdateCategory event,
    Emitter<CategoriesState> emit,
  ) async {
    await _categoryRepository.updateCategory(event.category);
  }

  Future<void> _onDeleteCategory(
    DeleteCategory event,
    Emitter<CategoriesState> emit,
  ) async {
    await _categoryRepository.deleteCategory(event.id);
  }

  void _onCategoriesUpdated(
    _CategoriesUpdated event,
    Emitter<CategoriesState> emit,
  ) {
    emit(CategoriesLoadSuccess(
      categories: event.categories,
      categoryTotals: event.categoryTotals,
    ));
  }

  @override
  Future<void> close() {
    _categoriesSubscription?.cancel();
    return super.close();
  }
}
