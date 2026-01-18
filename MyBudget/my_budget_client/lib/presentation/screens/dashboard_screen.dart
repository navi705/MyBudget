import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/presentation/widgets/calendar_step_picker.dart';
import 'package:my_budget_client/presentation/widgets/dashboard/accounts_overview_widget.dart';
import 'package:my_budget_client/presentation/widgets/dashboard/category_pie_chart.dart';
import 'package:my_budget_client/presentation/widgets/dashboard/dashboard_calendar.dart';
import 'package:my_budget_client/presentation/widgets/dashboard/day_balance_details.dart';

import 'package:my_budget_client/presentation/widgets/dashboard/period_summary_widget.dart'; // Added

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
                  icon: Icon(Icons.analytics_outlined),
                  label: 'Analytics',
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
        return _buildAnalyticsView(state);
      default:
        return const Center(child: Text('Selection Error'));
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
          _buildDateRangeIndicator(state),
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
            categoryTotals: state.categoryTotals,
            categories: state.categories,
            styles: state.styles,
            isIncome: state.isIncomeView,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsView(DashboardLoadSuccess state) {
    return Column(
      children: [
        const SizedBox(height: 16),
        _buildDateRangeIndicator(state),
        Expanded(
          child: AccountsOverviewWidget(
            accounts: state.accounts,
            dailyNetWorth: state.dailyNetWorth,
            dateRangeStart: state.dateRangeStart,
            dateRangeEnd: state.dateRangeEnd,
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangeIndicator(DashboardLoadSuccess state) {
    final df = DateFormat('yyyy-MM-dd');
    return GestureDetector(
      onTap: () => _showDateRangePicker(context, state),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.date_range, size: 16),
              const SizedBox(width: 8),
              Text(
                '${df.format(state.dateRangeStart)} - ${df.format(state.dateRangeEnd)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
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

  void _showDateRangePicker(BuildContext context, DashboardLoadSuccess state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CalendarStepPicker(
        initialDate: state.dateRangeEnd,
        initialRange: DateTimeRange(
          start: state.dateRangeStart,
          end: state.dateRangeEnd,
        ),
        initialStep: DateStep.day,
        initialFilterMode: FilterMode.range,
        onApply: (date, range, step, mode) {
          if (range != null) {
            context.read<DashboardBloc>().add(
              ChangeDateRange(range.start, range.end),
            );
          }
        },
      ),
    );
  }
}
