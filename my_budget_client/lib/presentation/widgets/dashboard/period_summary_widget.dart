import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
import 'package:my_budget_client/domain/entities/currency_designation.dart';

class PeriodSummaryWidget extends StatelessWidget {
  final DateTime dateRangeStart;
  final DateTime dateRangeEnd;
  final Map<DateTime, double> dailyIncomes;
  final Map<DateTime, double> dailyExpenses;
  final String currencyCode;
  final Map<String, CurrencyDesignation> currencyDesignations; // Added

  const PeriodSummaryWidget({
    super.key,
    required this.dateRangeStart,
    required this.dateRangeEnd,
    required this.dailyIncomes,
    required this.dailyExpenses,
    required this.currencyCode,
    required this.currencyDesignations, // Added
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
    // Use custom currency symbol from database, fallback to code if not found
    final designation = currencyDesignations.values
        .cast<CurrencyDesignation?>()
        .firstWhere((d) => d?.currencyCode == currencyCode, orElse: () => null);
    final currencySymbol = designation?.value ?? currencyCode;
    final numberFormatter = NumberFormat.decimalPatternDigits(decimalDigits: 2);

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
              context.l10n.periodSummaryTitle,
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
                  context.l10n.incomeLabel,
                  totalIncome,
                  Colors.green,
                  numberFormatter,
                  currencySymbol,
                ),
                _buildStat(
                  context,
                  context.l10n.expenseLabel,
                  totalExpense,
                  Colors.red,
                  numberFormatter,
                  currencySymbol,
                ),
                _buildStat(
                  context,
                  context.l10n.netLabel,
                  net,
                  net >= 0 ? Colors.green : Colors.red,
                  numberFormatter,
                  currencySymbol,
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
    NumberFormat numberFormatter,
    String currencySymbol, {
    bool showSign = false,
  }) {
    // Format: "123.45 €" (number, space, symbol)
    String text = '${numberFormatter.format(amount)} $currencySymbol';
    if (showSign && amount > 0) {
      text = '+$text';
    }

    final isMobile = MediaQuery.of(context).size.width < 600;

    final textWidget = Text(
      text,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: color,
        fontWeight: FontWeight.bold,
      ),
    );

    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        if (isMobile)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 100),
            child: FittedBox(fit: BoxFit.scaleDown, child: textWidget),
          )
        else
          textWidget,
      ],
    );
  }
}
