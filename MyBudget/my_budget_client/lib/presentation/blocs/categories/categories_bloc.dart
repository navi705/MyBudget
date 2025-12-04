import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:rxdart/rxdart.dart';

part 'categories_event.dart';
part 'categories_state.dart';

class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  final CategoryRepository _categoryRepository;
  final TransactionRepository _transactionRepository;

  CategoriesBloc({
    required CategoryRepository categoryRepository,
    required TransactionRepository transactionRepository,
  })  : _categoryRepository = categoryRepository,
        _transactionRepository = transactionRepository,
        super(CategoriesInitial()) {
    on<LoadCategories>(_onLoadCategories);
    on<LoadMoreCategories>(_onLoadMoreCategories);
    on<AddCategory>(_onAddCategory);
    on<UpdateCategory>(_onUpdateCategory);
    on<DeleteCategory>(_onDeleteCategory);
    on<DeleteCategoryConfirmed>(_onDeleteCategoryConfirmed);
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<CategoriesState> emit,
  ) async {
    emit(CategoriesLoadInProgress());
    try {
      // Fetch all transactions to calculate totals, but only the first page of categories.
      // This is a trade-off: for accurate totals, we need all transactions.
      final results = await Future.wait([
        _transactionRepository.getTransactions(),
        _categoryRepository.getCategoriesPaginated(limit: 50, offset: 0),
      ]);

      final transactions = results[0] as List<Transaction>;
      final categories = results[1] as List<Category>;

      final categoryTotals = _calculateTotals(transactions);
      final recursiveTotals =
          _calculateRecursiveTotals(categories, categoryTotals);

      emit(CategoriesLoadSuccess(
        categories: categories,
        categoryTotals: recursiveTotals,
        hasReachedMax: categories.length < 50,
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
      final categories = await _categoryRepository.getCategoriesPaginated(
        offset: currentState.categories.length,
        limit: 50,
      );

      if (categories.isEmpty) {
        emit(currentState.copyWith(hasReachedMax: true));
      } else {
        final allCategories = List.of(currentState.categories)
          ..addAll(categories);
        // Recalculate recursive totals with the full list of categories
        final recursiveTotals = _calculateRecursiveTotals(
            allCategories, currentState.categoryTotals);

        emit(currentState.copyWith(
          categories: allCategories,
          categoryTotals: recursiveTotals,
          hasReachedMax: categories.length < 50,
        ));
      }
    } catch (_) {
      // Keep current state on error
    }
  }

  Map<String, double> _calculateTotals(List<Transaction> transactions) {
    final categoryTotals = <String, double>{};
    for (var transaction in transactions) {
      categoryTotals.update(
        transaction.categoryId,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }
    return categoryTotals;
  }

  Map<String, double> _calculateRecursiveTotals(
      List<Category> categories, Map<String, double> totals) {
    final newTotals = Map<String, double>.from(totals);

    // This logic might need adjustment if not all categories are present
    // For now, it works on the currently loaded set.
    for (final category in categories.where((c) => c.parentId != null)) {
      var parentId = category.parentId;
      while (parentId != null) {
        newTotals.update(
          parentId,
          (value) => value + (totals[category.id] ?? 0.0),
          ifAbsent: () => totals[category.id] ?? 0.0,
        );
        final parent =
            categories.firstWhere((c) => c.id == parentId, orElse: () {
          return Category(id: "not_found", name: "Not Found", type: category.type);
        });

        parentId = parent.parentId;
      }
    }
    return newTotals;
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
    final transactions =
        await _transactionRepository.getTransactionsByCategoryId(event.id);

    // This logic remains complex and may need a rethink in a fully paginated world.
    // For now, it fetches ALL categories for the dialog.
    if (transactions.isEmpty) {
      await _categoryRepository.deleteCategory(event.id);
      add(LoadCategories());
    } else {
      final category = await _categoryRepository.getCategoryById(event.id);
      final allCategories = await _categoryRepository.getCategories();
      if (category != null) {
        emit(CategoryDeletionConfirmationNeeded(
          categoryToDelete: category,
          allCategories: allCategories,
        ));
      }
    }
  }

  Future<void> _onDeleteCategoryConfirmed(
    DeleteCategoryConfirmed event,
    Emitter<CategoriesState> emit,
  ) async {
    final transactions = await _transactionRepository
        .getTransactionsByCategoryId(event.categoryToDelete.id!);

    if (event.deleteTransactions) {
      for (final transaction in transactions) {
        await _transactionRepository.deleteTransaction(transaction.id!);
      }
    } else {
      for (final transaction in transactions) {
        final updatedTransaction =
            transaction.copyWith(categoryId: event.newCategoryId);
        await _transactionRepository.updateTransaction(updatedTransaction);
      }
    }

    await _categoryRepository.deleteCategory(event.categoryToDelete.id!);
    add(LoadCategories());
  }
}
