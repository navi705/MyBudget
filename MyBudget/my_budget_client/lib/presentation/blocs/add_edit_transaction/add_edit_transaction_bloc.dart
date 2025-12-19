import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';

part 'add_edit_transaction_event.dart';
part 'add_edit_transaction_state.dart';

class AddEditTransactionBloc
    extends Bloc<AddEditTransactionEvent, AddEditTransactionState> {
  final TransactionRepository _transactionRepository;
  final AccountRepository _accountRepository;
  final CategoryRepository _categoryRepository;

  AddEditTransactionBloc({
    required TransactionRepository transactionRepository,
    required AccountRepository accountRepository,
    required CategoryRepository categoryRepository,
  })  : _transactionRepository = transactionRepository,
        _accountRepository = accountRepository,
        _categoryRepository = categoryRepository,
        super(const AddEditTransactionState()) {
    on<AddEditTransactionLoad>(_onLoad);
    on<AddEditTransactionDescriptionChanged>(_onDescriptionChanged);
    on<AddEditTransactionAmountChanged>(_onAmountChanged);
    on<AddEditTransactionAccountChanged>(_onAccountChanged);
    on<AddEditTransactionCategoryChanged>(_onCategoryChanged);
    on<AddEditTransactionDateChanged>(_onDateChanged);
    on<AddEditTransactionSubmitted>(_onSubmitted);
  }

  Future<void> _onLoad(
    AddEditTransactionLoad event,
    Emitter<AddEditTransactionState> emit,
  ) async {
    emit(state.copyWith(status: AddEditTransactionStatus.loading));

    try {
      final accounts = await _accountRepository.getAccounts();
      final categories = await _categoryRepository.getCategories();
      final initialTransaction = event.transaction;

      final selectedAccount = initialTransaction != null
          ? accounts.firstWhereOrNull((a) => a.id == initialTransaction.accountId)
          : (accounts.isNotEmpty ? accounts.first : null);

      final selectedCategory = initialTransaction != null
          ? categories.firstWhereOrNull((c) => c.id == initialTransaction.categoryId)
          : (categories.isNotEmpty ? categories.first : null);

      emit(state.copyWith(
        status: AddEditTransactionStatus.success,
        accounts: accounts,
        categories: categories,
        initialTransaction: initialTransaction,
        description: initialTransaction?.description ?? '',
        amount: initialTransaction?.amount.toString() ?? '',
        selectedAccount: selectedAccount,
        selectedCategory: selectedCategory,
        date: initialTransaction?.date ?? DateTime.now(),
      ));
    } catch (_) {
      emit(state.copyWith(status: AddEditTransactionStatus.failure));
    }
  }

  void _onDescriptionChanged(
    AddEditTransactionDescriptionChanged event,
    Emitter<AddEditTransactionState> emit,
  ) {
    emit(state.copyWith(description: event.description));
  }

  void _onAmountChanged(
    AddEditTransactionAmountChanged event,
    Emitter<AddEditTransactionState> emit,
  ) {
    emit(state.copyWith(amount: event.amount));
  }

  void _onAccountChanged(
    AddEditTransactionAccountChanged event,
    Emitter<AddEditTransactionState> emit,
  ) {
    emit(state.copyWith(selectedAccount: event.account));
  }

  void _onCategoryChanged(
    AddEditTransactionCategoryChanged event,
    Emitter<AddEditTransactionState> emit,
  ) {
    emit(state.copyWith(selectedCategory: event.category));
  }

  void _onDateChanged(
    AddEditTransactionDateChanged event,
    Emitter<AddEditTransactionState> emit,
  ) {
    emit(state.copyWith(date: event.date));
  }

  Future<void> _onSubmitted(
    AddEditTransactionSubmitted event,
    Emitter<AddEditTransactionState> emit,
  ) async {
    emit(state.copyWith(isSaving: true));

    try {
      final amount = double.tryParse(state.amount);
      final date = state.date;
      final accountId = state.selectedAccount?.id;
      final categoryId = state.selectedCategory?.id;

      if (amount == null ||
          accountId == null ||
          categoryId == null ||
          date == null) {
        // Handle validation failure
        emit(state.copyWith(isSaving: false));
        return;
      }

      if (state.isEditing) {
        final updatedTransaction = state.initialTransaction!.copyWith(
          description: state.description,
          amount: amount,
          date: date,
          accountId: accountId,
          categoryId: categoryId,
          currencyCode: state.selectedAccount!.currencyCode,
        );
        await _transactionRepository.updateTransaction(updatedTransaction);
      } else {
        final newTransaction = Transaction(
          description: state.description,
          amount: amount,
          date: date,
          accountId: accountId,
          categoryId: categoryId,
          currencyCode: state.selectedAccount!.currencyCode,
        );
        await _transactionRepository.addTransaction(newTransaction);
      }

      emit(state.copyWith(isSaving: false, isSaveSuccess: true));
    } catch (_) {
      emit(state.copyWith(isSaving: false));
    }
  }
}

