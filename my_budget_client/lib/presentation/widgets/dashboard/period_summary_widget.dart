import 'package:flutter/material.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
import 'package:my_budget_client/core/theme/app_spacing.dart';
import 'package:my_budget_client/core/theme/money_colors.dart';
import 'package:my_budget_client/core/utils/money_formatter.dart';
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
    final money = MoneyColors.of(context);
    // Use custom currency symbol from database, fallback to code if not found
    final designation = currencyDesignations.values
        .cast<CurrencyDesignation?>()
        .firstWhere((d) => d?.currencyCode == currencyCode, orElse: () => null);
    final currencySymbol = designation?.value ?? currencyCode;

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
                  money.inflow,
                  currencySymbol,
                ),
                _buildStat(
                  context,
                  context.l10n.expenseLabel,
                  totalExpense,
                  money.outflow,
                  currencySymbol,
                ),
                _buildStat(
                  context,
                  context.l10n.netLabel,
                  net,
                  money.forAmount(net),
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
    String currencySymbol, {
    bool showSign = false,
  }) {
    // Format: "123.45 €" (number, space, symbol)
    String text =
        '${MoneyFormatter.format(amount, currencyCode)} $currencySymbol';
    if (showSign && amount > 0) {
      text = '+$text';
    }

    final textWidget = Text(
      text,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: color,
        fontWeight: FontWeight.bold,
      ),
    );

    // Three of these share one Row with no horizontal padding around the card,
    // so a fixed 100dp cap on mobile still overflowed (3 x 100 > the ~280dp
    // usable) and the desktop branch was uncapped entirely - and neither
    // branch bounded the translated label above the amount. Taking an equal
    // third of whatever the Row has and scaling down inside it holds for every
    // width and locale; scaleDown never enlarges, so short values still render
    // at their natural size.
    return Expanded(
      child: Padding(
        // Without this the three columns butt straight against each other:
        // each takes an exact third and scaleDown then fills that third
        // edge to edge, so on a 411dp phone the row read as one run-on
        // string, "2 991.77 EUR 123 130.62 EUR-120 138.85 EUR". The gutter
        // comes out of the space the text is scaled into, so the values
        // shrink slightly rather than overflow.
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, style: Theme.of(context).textTheme.bodySmall),
            ),
            const SizedBox(height: 4),
            FittedBox(fit: BoxFit.scaleDown, child: textWidget),
          ],
        ),
      ),
    );
  }
}
