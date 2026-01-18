part of 'dashboard_bloc.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoadInProgress extends DashboardState {}

class DashboardLoadSuccess extends DashboardState {
  final List<Account> accounts;
  final List<Transaction> transactions;
  final List<Category> categories;
  final List<Style> styles;

  // Dashboard parameters
  final int activeTabIndex;
  final DateTime selectedDay;
  final DateTime dateRangeStart;
  final DateTime dateRangeEnd;
  final DateStep dateStep;
  final String selectedCurrency;
  final bool isIncomeView;

  // Aggregated data
  final Map<String, double> dayBalances; // accountId -> balance for selectedDay
  final List<GroupedTransactionTotal> categoryTotals;
  final Map<DateTime, double> dailyIncomes;
  final Map<DateTime, double> dailyExpenses;
  final Map<DateTime, double> dailyNetWorth;

  DashboardLoadSuccess({
    this.accounts = const [],
    this.transactions = const [],
    this.categories = const [],
    this.styles = const [],
    this.activeTabIndex = 0,
    DateTime? selectedDay,
    DateTime? dateRangeStart,
    DateTime? dateRangeEnd,
    this.dateStep = DateStep.month,
    this.selectedCurrency = 'USD',
    this.isIncomeView = false,
    this.dayBalances = const {},
    this.categoryTotals = const [],
    this.dailyIncomes = const {},
    this.dailyExpenses = const {},
    this.dailyNetWorth = const {},
  }) : selectedDay = selectedDay ?? DateTime.now(),
       dateRangeStart =
           dateRangeStart ?? DateTime.now().subtract(const Duration(days: 30)),
       dateRangeEnd = dateRangeEnd ?? DateTime.now();

  DashboardLoadSuccess copyWith({
    List<Account>? accounts,
    List<Transaction>? transactions,
    List<Category>? categories,
    List<Style>? styles,
    int? activeTabIndex,
    DateTime? selectedDay,
    DateTime? dateRangeStart,
    DateTime? dateRangeEnd,
    DateStep? dateStep,
    String? selectedCurrency,
    bool? isIncomeView,
    Map<String, double>? dayBalances,
    List<GroupedTransactionTotal>? categoryTotals,
    Map<DateTime, double>? dailyIncomes,
    Map<DateTime, double>? dailyExpenses,
    Map<DateTime, double>? dailyNetWorth,
  }) {
    return DashboardLoadSuccess(
      accounts: accounts ?? this.accounts,
      transactions: transactions ?? this.transactions,
      categories: categories ?? this.categories,
      styles: styles ?? this.styles,
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
      selectedDay: selectedDay ?? this.selectedDay,
      dateRangeStart: dateRangeStart ?? this.dateRangeStart,
      dateRangeEnd: dateRangeEnd ?? this.dateRangeEnd,
      dateStep: dateStep ?? this.dateStep,
      selectedCurrency: selectedCurrency ?? this.selectedCurrency,
      isIncomeView: isIncomeView ?? this.isIncomeView,
      dayBalances: dayBalances ?? this.dayBalances,
      categoryTotals: categoryTotals ?? this.categoryTotals,
      dailyIncomes: dailyIncomes ?? this.dailyIncomes,
      dailyExpenses: dailyExpenses ?? this.dailyExpenses,
      dailyNetWorth: dailyNetWorth ?? this.dailyNetWorth,
    );
  }

  @override
  List<Object?> get props => [
    accounts,
    transactions,
    categories,
    styles,
    activeTabIndex,
    selectedDay,
    dateRangeStart,
    dateRangeEnd,
    dateStep,
    selectedCurrency,
    isIncomeView,
    dayBalances,
    categoryTotals,
    dailyIncomes,
    dailyExpenses,
    dailyNetWorth,
  ];
}

class DashboardLoadFailure extends DashboardState {}
