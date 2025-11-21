import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:rxdart/rxdart.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final AccountRepository _accountRepository;
  final TransactionRepository _transactionRepository;
  final CategoryRepository _categoryRepository;

  DashboardBloc({
    required AccountRepository accountRepository,
    required TransactionRepository transactionRepository,
    required CategoryRepository categoryRepository,
  })  : _accountRepository = accountRepository,
        _transactionRepository = transactionRepository,
        _categoryRepository = categoryRepository,
        super(DashboardInitial()) {
    on<LoadDashboard>(_onLoadDashboard);
  }

  Future<void> _onLoadDashboard(
    LoadDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoadInProgress());
    final stream = Rx.combineLatest3(
      _accountRepository.watchAccounts(),
      _transactionRepository.watchTransactions(),
      _categoryRepository.watchCategories(),
      (
        List<Account> accounts,
        List<Transaction> transactions,
        List<Category> categories,
      ) {
        return DashboardLoadSuccess(
          accounts: accounts,
          transactions: transactions,
          categories: categories,
        );
      },
    );

    await emit.forEach<DashboardState>(
      stream,
      onData: (state) => state,
      onError: (_, __) => DashboardLoadFailure(),
    );
  }
}
