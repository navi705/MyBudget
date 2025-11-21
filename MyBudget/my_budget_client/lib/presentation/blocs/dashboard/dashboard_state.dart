part of 'dashboard_bloc.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoadInProgress extends DashboardState {}

class DashboardLoadSuccess extends DashboardState {
  final List<Account> accounts;
  final List<Transaction> transactions;
  final List<Category> categories;

  const DashboardLoadSuccess({
    this.accounts = const [],
    this.transactions = const [],
    this.categories = const [],
  });

  @override
  List<Object> get props => [accounts, transactions, categories];
}

class DashboardLoadFailure extends DashboardState {}
