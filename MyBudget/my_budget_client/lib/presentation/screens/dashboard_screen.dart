import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';

enum DateFilter { last30Days, thisMonth, thisYear }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateFilter _selectedDateFilter = DateFilter.last30Days;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Transaction> _filterTransactions(List<Transaction> transactions) {
    final now = DateTime.now();
    switch (_selectedDateFilter) {
      case DateFilter.last30Days:
        return transactions
            .where((t) => t.date.isAfter(now.subtract(const Duration(days: 30))))
            .toList();
      case DateFilter.thisMonth:
        return transactions
            .where((t) => t.date.year == now.year && t.date.month == now.month)
            .toList();
      case DateFilter.thisYear:
        return transactions.where((t) => t.date.year == now.year).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: DropdownButton<DateFilter>(
            value: _selectedDateFilter,
            isExpanded: true,
            onChanged: (DateFilter? newValue) {
              setState(() {
                _selectedDateFilter = newValue!;
              });
            },
            items: DateFilter.values.map((DateFilter filter) {
              return DropdownMenuItem<DateFilter>(
                value: filter,
                child: Text(filter.toString().split('.').last),
              );
            }).toList(),
          ),
        ),
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Income/Expense'),
            Tab(text: 'Category Analysis'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildIncomeExpenseTab(),
              _buildCategoryAnalysisTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab() {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoadInProgress) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is DashboardLoadSuccess) {
          final filteredTransactions = _filterTransactions(state.transactions);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Dashboard',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: <Widget>[
                    _buildInfoCard(
                      context,
                      title: 'Total Accounts',
                      value: state.accounts.length.toString(),
                      icon: Icons.account_balance_wallet,
                      color: Colors.blue,
                    ),
                    _buildInfoCard(
                      context,
                      title: 'Total Transactions',
                      value: filteredTransactions.length.toString(),
                      icon: Icons.swap_horiz,
                      color: Colors.green,
                    ),
                    _buildInfoCard(
                      context,
                      title: 'Total Categories',
                      value: state.categories.length.toString(),
                      icon: Icons.category,
                      color: Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          );
        }
        if (state is DashboardLoadFailure) {
          return const Center(child: Text('Failed to load dashboard data.'));
        }
        return const Center(child: Text('Dashboard'));
      },
    );
  }

  Widget _buildIncomeExpenseTab() {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoadSuccess) {
          final filteredTransactions = _filterTransactions(state.transactions);
          double totalIncome = 0;
          double totalExpense = 0;

          for (var transaction in filteredTransactions) {
            final category = state.categories.firstWhere((cat) => cat.id == transaction.categoryId);
            if (category.type == CategoryType.income) {
              totalIncome += transaction.amount;
            } else {
              totalExpense += transaction.amount;
            }
          }

          if (totalIncome == 0 && totalExpense == 0) {
            return const Center(child: Text('No income or expense data.'));
          }

          return PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  color: Colors.green,
                  value: totalIncome,
                  title: '${(totalIncome / (totalIncome + totalExpense) * 100).toStringAsFixed(1)}%',
                  radius: 100,
                  titleStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  color: Colors.red,
                  value: totalExpense,
                  title: '${(totalExpense / (totalIncome + totalExpense) * 100).toStringAsFixed(1)}%',
                  radius: 100,
                  titleStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCategoryAnalysisTab() {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoadSuccess) {
          final filteredTransactions = _filterTransactions(state.transactions);
          final Map<String, double> categoryTotals = {};
          double totalExpense = 0;
          for (var transaction in filteredTransactions) {
            final category = state.categories.firstWhere((cat) => cat.id == transaction.categoryId);
            if (category.type == CategoryType.expense) {
              totalExpense += transaction.amount;
              categoryTotals.update(
                category.name,
                (value) => value + transaction.amount,
                ifAbsent: () => transaction.amount,
              );
            }
          }

          if (categoryTotals.isEmpty) {
            return const Center(child: Text('No expense data to analyze.'));
          }

          return PieChart(
            PieChartData(
              sections: categoryTotals.entries.map((entry) {
                final percentage = (entry.value / totalExpense * 100).toStringAsFixed(1);
                return PieChartSectionData(
                  color: Colors.primaries[categoryTotals.keys.toList().indexOf(entry.key) % Colors.primaries.length],
                  value: entry.value,
                  title: '${entry.key}\n$percentage%',
                  radius: 100,
                  titleStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return SizedBox(
      width: 200,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              CircleAvatar(
                radius: 30,
                backgroundColor: color,
                child: Icon(icon, size: 30, color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
