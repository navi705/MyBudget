import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';
import 'package:my_budget_client/presentation/widgets/calendar_step_picker.dart';
import 'package:my_budget_client/presentation/widgets/dashboard/balance_line_chart.dart';
import 'package:my_budget_client/presentation/widgets/dashboard/category_pie_chart.dart';
import 'package:my_budget_client/presentation/widgets/dashboard/dashboard_calendar.dart';
import 'package:my_budget_client/presentation/widgets/dashboard/day_balance_details.dart';

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
            appBar: AppBar(
              title: const Text('Dashboard'),
              actions: [
                if (state.activeTabIndex > 0)
                  IconButton(
                    icon: const Icon(Icons.date_range),
                    onPressed: () => _showDateRangePicker(context, state),
                  ),
              ],
            ),
            body: _buildBody(state),
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
                  icon: Icon(Icons.show_chart),
                  label: 'Trends',
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
        return _buildTrendsView(state);
      default:
        return const Center(child: Text('Selection Error'));
    }
  }

  Widget _buildCalendarView(DashboardLoadSuccess state) {
    return SingleChildScrollView(
      child: Column(
        children: [
          DashboardCalendar(
            dailyIncomes: state.dailyIncomes,
            dailyExpenses: state.dailyExpenses,
            selectedDay: state.selectedDay,
            onDaySelected: (day) =>
                context.read<DashboardBloc>().add(SelectDay(day)),
          ),
          const Divider(),
          DayBalanceDetails(
            accounts: state.accounts,
            dayBalances: state.dayBalances,
            date: state.selectedDay,
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

  Widget _buildTrendsView(DashboardLoadSuccess state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildDateRangeIndicator(state),
          const SizedBox(height: 24),
          Text(
            'Net Worth Trend',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          BalanceLineChart(
            dailyNetWorth: state.dailyNetWorth,
            dateRangeStart: state.dateRangeStart,
            dateRangeEnd: state.dateRangeEnd,
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeIndicator(DashboardLoadSuccess state) {
    final df = DateFormat('yyyy-MM-dd');
    return Card(
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
