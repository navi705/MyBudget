import 'package:flutter/material.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/style.dart';
import 'package:my_budget_client/presentation/widgets/dashboard/balance_line_chart.dart';
import 'package:my_budget_client/presentation/widgets/dashboard/category_pie_chart.dart';

enum AnalyticsViewType { totalBalance, byAccount, byCategory }

class AnalyticsChartSelector extends StatefulWidget {
  final DateTime dateRangeStart;
  final DateTime dateRangeEnd;
  final Map<DateTime, double> dailyNetWorth;
  final List<Account> accounts;
  final List<Category> categories;
  final List<Style> styles;
  final Map<String, double> categoryConvertedTotals;
  final String currencyCode;
  final bool isIncomeView;
  final VoidCallback onToggleChartType;

  const AnalyticsChartSelector({
    super.key,
    required this.dateRangeStart,
    required this.dateRangeEnd,
    required this.dailyNetWorth,
    required this.accounts,
    required this.categories,
    required this.styles,
    required this.categoryConvertedTotals,
    required this.currencyCode,
    required this.isIncomeView,
    required this.onToggleChartType,
  });

  @override
  State<AnalyticsChartSelector> createState() => _AnalyticsChartSelectorState();
}

class _AnalyticsChartSelectorState extends State<AnalyticsChartSelector> {
  AnalyticsViewType _selectedView = AnalyticsViewType.totalBalance;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // View Type Selector
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SegmentedButton<AnalyticsViewType>(
            segments: const [
              ButtonSegment(
                value: AnalyticsViewType.totalBalance,
                label: Text('Total Balance'),
                icon: Icon(Icons.trending_up),
              ),
              ButtonSegment(
                value: AnalyticsViewType.byAccount,
                label: Text('By Account'),
                icon: Icon(Icons.account_balance_wallet),
              ),
              ButtonSegment(
                value: AnalyticsViewType.byCategory,
                label: Text('By Category'),
                icon: Icon(Icons.category),
              ),
            ],
            selected: {_selectedView},
            onSelectionChanged: (Set<AnalyticsViewType> selection) {
              setState(() {
                _selectedView = selection.first;
              });
            },
          ),
        ),

        // Chart Display
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildSelectedChart(),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedChart() {
    switch (_selectedView) {
      case AnalyticsViewType.totalBalance:
        return _buildTotalBalanceChart();
      case AnalyticsViewType.byAccount:
        return _buildAccountChart();
      case AnalyticsViewType.byCategory:
        return _buildCategoryChart();
    }
  }

  Widget _buildTotalBalanceChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Net Worth Trend',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        BalanceLineChart(
          dailyNetWorth: widget.dailyNetWorth,
          dateRangeStart: widget.dateRangeStart,
          dateRangeEnd: widget.dateRangeEnd,
        ),
      ],
    );
  }

  Widget _buildAccountChart() {
    // Calculate account balances
    final accountBalances = <String, double>{};
    for (final account in widget.accounts) {
      if (account.balance > 0) {
        accountBalances[account.name] = account.balance;
      }
    }

    if (accountBalances.isEmpty) {
      return const Center(child: Text('No account data available'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Balance by Account',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 400,
          child: ListView.builder(
            itemCount: widget.accounts.length,
            itemBuilder: (context, index) {
              final account = widget.accounts[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(account.name),
                  subtitle: Text(account.currencyCode),
                  trailing: Text(
                    account.balance.toStringAsFixed(2),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: account.balance >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Spending by Category',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        // Income/Expense Toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ChoiceChip(
              label: const Text('Expenses'),
              selected: !widget.isIncomeView,
              onSelected: (val) {
                if (widget.isIncomeView) {
                  widget.onToggleChartType();
                }
              },
            ),
            const SizedBox(width: 16),
            ChoiceChip(
              label: const Text('Income'),
              selected: widget.isIncomeView,
              onSelected: (val) {
                if (!widget.isIncomeView) {
                  widget.onToggleChartType();
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        CategoryPieChart(
          categoryConvertedTotals: widget.categoryConvertedTotals,
          categories: widget.categories,
          styles: widget.styles,
          isIncome: widget.isIncomeView,
          currencyCode: widget.currencyCode,
        ),
      ],
    );
  }
}
