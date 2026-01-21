import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/presentation/widgets/dashboard/balance_line_chart.dart';

class AccountsOverviewWidget extends StatelessWidget {
  final List<Account> accounts;
  final Map<DateTime, double> dailyNetWorth;
  final DateTime dateRangeStart;
  final DateTime dateRangeEnd;

  const AccountsOverviewWidget({
    super.key,
    required this.accounts,
    required this.dailyNetWorth,
    required this.dateRangeStart,
    required this.dateRangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return const Center(child: Text('No accounts found'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Balance History (Trends)
          Text(
            'Net Worth Trend',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          BalanceLineChart(
            dailyNetWorth: dailyNetWorth,
            dateRangeStart: dateRangeStart,
            dateRangeEnd: dateRangeEnd,
          ),
          const SizedBox(height: 32),

          // 2. Charts Row (Responsive)
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildAccountDistribution(context)),
                    const SizedBox(width: 24),
                    Expanded(child: _buildCurrencyDistribution(context)),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildAccountDistribution(context),
                    const SizedBox(height: 24),
                    _buildCurrencyDistribution(context),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountDistribution(BuildContext context) {
    final data = _getAccountDistribution();
    return _buildPieSection(context, 'Wealth Distribution (by Account)', data);
  }

  Widget _buildCurrencyDistribution(BuildContext context) {
    final data = _getCurrencyDistribution();
    return _buildPieSection(context, 'Currency Exposure', data);
  }

  Widget _buildPieSection(
    BuildContext context,
    String title,
    List<MapEntry<String, double>> data,
  ) {
    final total = data.fold(0.0, (sum, e) => sum + e.value);

    return Column(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: data.map((e) {
                final percentage = total > 0 ? (e.value / total) * 100 : 0.0;
                final isLarge = percentage > 5;
                return PieChartSectionData(
                  color: _getRandomColor(e.key.hashCode),
                  value: e.value,
                  title: isLarge ? '${percentage.toStringAsFixed(1)}%' : '',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: data.map((e) {
            final percentage = total > 0 ? (e.value / total) * 100 : 0.0;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _getRandomColor(e.key.hashCode),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${e.key} (${percentage.toStringAsFixed(1)}%)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  List<MapEntry<String, double>> _getAccountDistribution() {
    // Only positive balances for pie chart
    final map = <String, double>{};
    for (final acc in accounts) {
      if (acc.balance > 0) {
        map[acc.name] = acc.balance;
      }
    }
    return map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  List<MapEntry<String, double>> _getCurrencyDistribution() {
    final map = <String, double>{};
    for (final acc in accounts) {
      if (acc.balance > 0) {
        map.update(
          acc.currencyCode,
          (v) => v + acc.balance,
          ifAbsent: () => acc.balance,
        );
      }
    }
    return map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  Color _getRandomColor(int seed) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.cyan,
      Colors.indigo,
    ];
    return colors[seed % colors.length];
  }
}
