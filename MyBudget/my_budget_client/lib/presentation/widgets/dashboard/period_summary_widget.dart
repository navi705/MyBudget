import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PeriodSummaryWidget extends StatelessWidget {
  final DateTime dateRangeStart;
  final DateTime dateRangeEnd;
  final Map<DateTime, double> dailyIncomes;
  final Map<DateTime, double> dailyExpenses;
  final String currencyCode;

  const PeriodSummaryWidget({
    super.key,
    required this.dateRangeStart,
    required this.dateRangeEnd,
    required this.dailyIncomes,
    required this.dailyExpenses,
    required this.currencyCode,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Calculate Totals
    double totalIncome = 0;
    double totalExpense = 0;

    // Iterate through days within the range
    // Efficiently: iterate the maps or the days.
    // Since maps contain all pre-calculated days for the loaded range, we can just sum values where key is within range.
    // However, DashboardBloc usually loads exactly the range needed + buffer.
    // Let's iterate the keys of dailyIncomes that fall within range.

    // Better: Iterate from start to end (inclusive)
    // Avoids checking keys outside range if map is huge (it shouldn't be too huge).

    final days = dateRangeEnd.difference(dateRangeStart).inDays + 1;
    for (int i = 0; i < days; i++) {
      final d = dateRangeStart.add(Duration(days: i));
      // Normalize date to remove time just in case, though maps keys should be normalized
      final key = DateTime(d.year, d.month, d.day);

      totalIncome += dailyIncomes[key] ?? 0;
      totalExpense += dailyExpenses[key] ?? 0;
    }

    final net = totalIncome - totalExpense;
    final theme = Theme.of(context);
    // CHANGE: Use compact format without currency prefix for cleaner display
    final formatter = NumberFormat.compact();

    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Period Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat(
                  context,
                  'Income',
                  totalIncome,
                  Colors.green,
                  formatter,
                ),
                _buildStat(
                  context,
                  'Expense',
                  totalExpense,
                  Colors.red,
                  formatter,
                ),
                _buildStat(
                  context,
                  'Net',
                  net,
                  net >= 0 ? Colors.green : Colors.red,
                  formatter,
                  showSign: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(
    BuildContext context,
    String label,
    double amount,
    Color color,
    NumberFormat formatter, {
    bool showSign = false,
  }) {
    final currencySymbol = NumberFormat.simpleCurrency(
      name: currencyCode,
    ).currencySymbol;
    String text = '${formatter.format(amount)}$currencySymbol';
    if (showSign && amount > 0) {
      text = '+${formatter.format(amount)}$currencySymbol';
    }

    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
