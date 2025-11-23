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
  StreamSubscription? _categoriesSubscription;

  CategoriesBloc({
    required CategoryRepository categoryRepository,
    required TransactionRepository transactionRepository,
  })  : _categoryRepository = categoryRepository,
        _transactionRepository = transactionRepository,
        super(CategoriesInitial()) {
    on<LoadCategories>(_onLoadCategories);
    on<AddCategory>(_onAddCategory);
    on<UpdateCategory>(_onUpdateCategory);
    on<DeleteCategory>(_onDeleteCategory);
    on<DeleteCategoryConfirmed>(_onDeleteCategoryConfirmed);
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
      _transactionRepository.watchTransactions(),
      (List<Category> categories, List<Transaction> transactions) {
        final categoryTotals = <String, double>{};
        for (var transaction in transactions) {
          categoryTotals.update(
            transaction.categoryId,
            (value) => value + transaction.amount,
            ifAbsent: () => transaction.amount,
          );
        }

        final recursiveTotals =
            _calculateRecursiveTotals(categories, categoryTotals);

        return _CategoriesUpdated(categories, recursiveTotals);
      },
    ).listen(
      (update) => add(update),
      onError: (_) => emit(CategoriesLoadFailure()),
    );
  }

  Map<String, double> _calculateRecursiveTotals(
      List<Category> categories, Map<String, double> totals) {
    final newTotals = Map<String, double>.from(totals);

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
          // This should not happen in a consistent database
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
    final transactions =
        await _transactionRepository.getTransactionsByCategoryId(event.id);

    if (transactions.isEmpty) {
      await _categoryRepository.deleteCategory(event.id);
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
