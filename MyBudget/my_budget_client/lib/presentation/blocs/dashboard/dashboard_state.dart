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
  final List<Currency> availableCurrencies;

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
  final Map<String, double> categoryConvertedTotals; // Added
  final Map<DateTime, double> dailyIncomes;
  final Map<DateTime, double> dailyExpenses;
  final Map<DateTime, double> dailyNetWorth;

  final Map<String, CurrencyDesignation> currencyDesignations; // Added

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
    this.categoryConvertedTotals = const {}, // Added
    this.dailyIncomes = const {},
    this.dailyExpenses = const {},
    this.dailyNetWorth = const {},
    this.availableCurrencies = const [],
    this.currencyDesignations = const {}, // Added
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
    Map<String, double>? categoryConvertedTotals, // Added
    Map<DateTime, double>? dailyIncomes,
    Map<DateTime, double>? dailyExpenses,
    Map<DateTime, double>? dailyNetWorth,
    List<Currency>? availableCurrencies,
    Map<String, CurrencyDesignation>? currencyDesignations, // Added
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
      categoryConvertedTotals:
          categoryConvertedTotals ?? this.categoryConvertedTotals, // Added
      dailyIncomes: dailyIncomes ?? this.dailyIncomes,
      dailyExpenses: dailyExpenses ?? this.dailyExpenses,
      dailyNetWorth: dailyNetWorth ?? this.dailyNetWorth,
      availableCurrencies: availableCurrencies ?? this.availableCurrencies,
      currencyDesignations:
          currencyDesignations ?? this.currencyDesignations, // Added
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
    categoryConvertedTotals, // Added
    dailyIncomes,
    dailyExpenses,
    dailyNetWorth,
    availableCurrencies,
    currencyDesignations, // Added
  ];
}

class DashboardLoadFailure extends DashboardState {}
