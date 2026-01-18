import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/presentation/widgets/calendar_step_picker.dart';
import 'package:my_budget_client/presentation/widgets/dashboard/category_pie_chart.dart';
import 'package:my_budget_client/presentation/widgets/dashboard/dashboard_calendar.dart';
import 'package:my_budget_client/presentation/widgets/dashboard/day_balance_details.dart';
import 'package:my_budget_client/presentation/widgets/dashboard/period_summary_widget.dart';
import 'package:my_budget_client/presentation/widgets/dashboard/dashboard_header.dart';
import 'package:my_budget_client/presentation/widgets/dashboard/analytics_chart_selector.dart'; // Contains BalanceReportWidget

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(LoadDashboard());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoadInProgress) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is DashboardLoadSuccess) {
          return Scaffold(
            // AppBar removed to maximize space
            body: SafeArea(child: _buildBody(state)),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: state.activeTabIndex,
              type: BottomNavigationBarType.fixed, // Added to show all 4 items
              onTap: (index) =>
                  context.read<DashboardBloc>().add(ChangeTab(index)),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_month),
                  label: 'Calendar',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.pie_chart),
                  label: 'Categories',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.show_chart),
                  label: 'Balance',
                ),
              ],
            ),
          );
        }

        return const Scaffold(
          body: Center(child: Text('Failed to load dashboard')),
        );
      },
    );
  }

  Widget _buildBody(DashboardLoadSuccess state) {
    switch (state.activeTabIndex) {
      case 0:
        return _buildCalendarView(state);
      case 1:
        return _buildCategoryView(state);
      case 2:
        return _buildBalanceView(state);
      default:
        // Fallback for any deprecated index
        return _buildCalendarView(state);
    }
  }

  Widget _buildCalendarView(DashboardLoadSuccess state) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // View Selector & Currency
          // Calendar with integrated header
          DashboardCalendar(
            selectedDay: state.selectedDay,
            dateStep: state.dateStep,
            dailyIncomes: state.dailyIncomes,
            dailyExpenses: state.dailyExpenses,
            dailyNetWorth: state.dailyNetWorth,
            currencyCode: state.selectedCurrency,
            availableCurrencies: state.availableCurrencies
                .map((e) => e.code)
                .toList(),
            onCurrencySelected: (code) {
              context.read<DashboardBloc>().add(ChangeCurrency(code));
            },
            onDateStepChanged: (step) {
              context.read<DashboardBloc>().add(ChangeDateStep(step));
            },
            onDaySelected: (day) {
              context.read<DashboardBloc>().add(SelectDay(day));
              // If in Year view, switch to Month view explicitly on selection
              if (state.dateStep == DateStep.year) {
                context.read<DashboardBloc>().add(
                  const ChangeDateStep(DateStep.month),
                );
              }
            },
            onPrevious: () {
              final current = state.selectedDay;
              DateTime newDate;
              if (state.dateStep == DateStep.month) {
                newDate = DateTime(
                  current.year,
                  current.month - 1,
                  1,
                ); // Go to 1st
              } else {
                newDate = DateTime(current.year - 1, current.month, 1);
              }
              context.read<DashboardBloc>().add(SelectDay(newDate));
            },
            onNext: () {
              final current = state.selectedDay;
              DateTime newDate;
              if (state.dateStep == DateStep.month) {
                newDate = DateTime(current.year, current.month + 1, 1);
              } else {
                newDate = DateTime(current.year + 1, current.month, 1);
              }
              context.read<DashboardBloc>().add(SelectDay(newDate));
            },
            onTitleTap: () => _showPeriodPicker(context, state),
          ),
          const SizedBox(height: 16),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                children: [
                  PeriodSummaryWidget(
                    dateRangeStart: state.dateRangeStart,
                    dateRangeEnd: state.dateRangeEnd,
                    dailyIncomes: state.dailyIncomes,
                    dailyExpenses: state.dailyExpenses,
                    currencyCode: state.selectedCurrency,
                  ),
                  const Divider(),
                  DayBalanceDetails(
                    accounts: state.accounts,
                    dayBalances: state.dayBalances,
                    date: state.selectedDay,
                    currencyCode: state.selectedCurrency,
                    styles: state.styles,
                    currencyDesignations: state.currencyDesignations, // Added
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryView(DashboardLoadSuccess state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          DashboardHeader(
            selectedDay: state.selectedDay,
            dateStep: state.dateStep,
            currencyCode: state.selectedCurrency,
            availableCurrencies: state.availableCurrencies
                .map((e) => e.code)
                .toList(),
            onPrevious: () => context.read<DashboardBloc>().add(
              SelectDay(
                state.dateStep == DateStep.month
                    ? DateTime(
                        state.selectedDay.year,
                        state.selectedDay.month - 1,
                        1,
                      )
                    : DateTime(state.selectedDay.year - 1, 1, 1),
              ),
            ),
            onNext: () => context.read<DashboardBloc>().add(
              SelectDay(
                state.dateStep == DateStep.month
                    ? DateTime(
                        state.selectedDay.year,
                        state.selectedDay.month + 1,
                        1,
                      )
                    : DateTime(state.selectedDay.year + 1, 1, 1),
              ),
            ),
            onTitleTap: () => _showPeriodPicker(context, state), // Fixed
            onCurrencySelected: (currency) =>
                context.read<DashboardBloc>().add(ChangeCurrency(currency)),
            onDateStepChanged: (step) =>
                context.read<DashboardBloc>().add(ChangeDateStep(step)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: const Text('Expenses'),
                selected: !state.isIncomeView,
                onSelected: (val) =>
                    context.read<DashboardBloc>().add(ToggleChartType(false)),
              ),
              const SizedBox(width: 16),
              ChoiceChip(
                label: const Text('Income'),
                selected: state.isIncomeView,
                onSelected: (val) =>
                    context.read<DashboardBloc>().add(ToggleChartType(true)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          CategoryPieChart(
            categoryConvertedTotals: state.categoryConvertedTotals,
            categories: state.categories,
            styles: state.styles,
            isIncome: state.isIncomeView,
            currencyCode: state.selectedCurrency, // Added
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceView(DashboardLoadSuccess state) {
    return Column(
      children: [
        // Date Navigation Header
        DashboardHeader(
          selectedDay: state.selectedDay,
          dateStep: state.dateStep,
          currencyCode: state.selectedCurrency,
          availableCurrencies: state.availableCurrencies
              .map((e) => e.code)
              .toList(),
          onPrevious: () => context.read<DashboardBloc>().add(
            SelectDay(
              state.dateStep == DateStep.month
                  ? DateTime(
                      state.selectedDay.year,
                      state.selectedDay.month - 1,
                      1,
                    )
                  : DateTime(state.selectedDay.year - 1, 1, 1),
            ),
          ),
          onNext: () => context.read<DashboardBloc>().add(
            SelectDay(
              state.dateStep == DateStep.month
                  ? DateTime(
                      state.selectedDay.year,
                      state.selectedDay.month + 1,
                      1,
                    )
                  : DateTime(state.selectedDay.year + 1, 1, 1),
            ),
          ),
          onTitleTap: () => _showPeriodPicker(context, state),
          onCurrencySelected: (currency) =>
              context.read<DashboardBloc>().add(ChangeCurrency(currency)),
          onDateStepChanged: (step) =>
              context.read<DashboardBloc>().add(ChangeDateStep(step)),
        ),

        // Flexible Balance Report
        Expanded(
          child: BalanceReportWidget(
            dateRangeStart: state.dateRangeStart,
            dateRangeEnd: state.dateRangeEnd,
            dailyNetWorth: state.dailyNetWorth,
            dayBalances:
                state.dailyAccountBalances, // Pass historical account data
            currencyBreakdown: state.currencyBreakdown, // Added
            accountBreakdown: state.accountBreakdown, // Added
            accounts: state.accounts,
            currencyCode: state.selectedCurrency,
          ),
        ),
      ],
    );
  }

  void _showPeriodPicker(BuildContext context, DashboardLoadSuccess state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (modalContext) => CalendarStepPicker(
        initialDate: state.selectedDay,
        initialStep: state.dateStep == DateStep.year
            ? DateStep.year
            : DateStep.month,
        initialFilterMode: FilterMode.date,
        rangeOptionVisibility: PickerVisibility.hidden,
        onApply: (date, range, step, mode) {
          final bloc = context.read<DashboardBloc>();
          bloc.add(SelectDay(date));
          // FIX: Also update DateStep if user selected different step in picker
          if (step != state.dateStep && step != DateStep.day) {
            bloc.add(ChangeDateStep(step));
          }
        },
      ),
    );
  }
}
