import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';

class DashboardCalendar extends StatelessWidget {
  final DateTime selectedDay;
  final DateStep dateStep;
  final Map<DateTime, double> dailyIncomes;
  final Map<DateTime, double> dailyExpenses;
  final Map<DateTime, double> dailyNetWorth;
  final Function(DateTime) onDaySelected;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onTitleTap;
  final String currencyCode; // Added

  const DashboardCalendar({
    super.key,
    required this.selectedDay,
    required this.dateStep,
    required this.dailyIncomes,
    required this.dailyExpenses,
    required this.dailyNetWorth,
    required this.onDaySelected,
    required this.onNext,
    required this.onPrevious,
    required this.onTitleTap,
    required this.currencyCode,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900), // Constraint for PC
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            if (dateStep == DateStep.month) ...[
              _buildWeekdayLabels(context),
              const SizedBox(height: 8),
              _buildMonthView(context),
            ] else if (dateStep == DateStep.year) ...[
              _buildYearView(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    String title;

    if (dateStep == DateStep.month) {
      title = DateFormat.yMMMM().format(selectedDay);
    } else {
      title = selectedDay.year.toString();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(onPressed: onPrevious, icon: const Icon(Icons.chevron_left)),
        InkWell(
          onTap: onTitleTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
      ],
    );
  }

  Widget _buildWeekdayLabels(BuildContext context) {
    // Determine start of week (Monday)
    // We can use a localized list or hardcode [Mon, Tue...]
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekdays
          .map(
            (d) => Expanded(
              child: Center(
                child: Text(
                  d,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildMonthView(BuildContext context) {
    final firstDayOfMonth = DateTime(selectedDay.year, selectedDay.month, 1);
    final lastDayOfMonth = DateTime(selectedDay.year, selectedDay.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startingWeekday = firstDayOfMonth.weekday; // 1=Mon

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.75, // Taller cells for stats
      ),
      itemCount: daysInMonth + (startingWeekday - 1),
      itemBuilder: (context, index) {
        if (index < startingWeekday - 1) {
          return const SizedBox.shrink();
        }
        final day = index - (startingWeekday - 2);
        final date = DateTime(selectedDay.year, selectedDay.month, day);

        return _buildDayCell(context, date);
      },
    );
  }

  Widget _buildDayCell(BuildContext context, DateTime date) {
    final isSelected =
        date.year == selectedDay.year &&
        date.month == selectedDay.month &&
        date.day == selectedDay.day;
    final isToday =
        DateTime.now().year == date.year &&
        DateTime.now().month == date.month &&
        DateTime.now().day == date.day;

    final income = dailyIncomes[date] ?? 0;
    final expense = dailyExpenses[date] ?? 0;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () => onDaySelected(date),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : (isToday
                    ? colorScheme.surfaceContainerHighest
                    : colorScheme.surfaceContainerLow),
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: colorScheme.primary, width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Date Number
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 4, right: 6),
              alignment: Alignment.topRight,
              child: Text(
                date.day.toString(),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: isSelected || isToday
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: isSelected ? colorScheme.onPrimaryContainer : null,
                ),
              ),
            ),
            const Spacer(),
            // Stats
            if (income > 0 || expense > 0) ...[
              if (income > 0)
                _buildMiniStat(
                  context,
                  '+${NumberFormat.compactSimpleCurrency(name: currencyCode).format(income)}',
                  Colors.green,
                ),
              if (expense > 0)
                _buildMiniStat(
                  context,
                  '-${NumberFormat.compactSimpleCurrency(name: currencyCode).format(expense)}',
                  Colors.red,
                ),
            ],
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildYearView(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Constraints here are determined by the parent ConstrainedBox (maxWidth 900).
        // If screen < 900, it shrinks.
        final isWide = constraints.maxWidth > 500;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWide ? 4 : 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: isWide ? 1.5 : 1.0,
          ),
          itemCount: 12,
          itemBuilder: (context, index) {
            final monthIndex = index + 1;
            final monthDate = DateTime(selectedDay.year, monthIndex, 1);
            return _buildMonthCell(context, monthDate);
          },
        );
      },
    );
  }

  Widget _buildMonthCell(BuildContext context, DateTime monthDate) {
    final isSelected =
        monthDate.year == selectedDay.year &&
        monthDate.month == selectedDay.month;
    final isCurrentMonth =
        DateTime.now().year == monthDate.year &&
        DateTime.now().month == monthDate.month;

    // Aggregate stats for this month
    double totalIncome = 0;
    double totalExpense = 0;

    // We iterate dailyIncomes/Expenses keys to find those in this month
    // Optimization: Since maps are by DateTime, checking every entry is okay for small sets,
    // but better to iterate days of month if efficient. Map lookup is O(1).
    // Let's iterate days of month (max 31).
    final lastDay = DateTime(monthDate.year, monthDate.month + 1, 0).day;
    for (int i = 1; i <= lastDay; i++) {
      final d = DateTime(monthDate.year, monthDate.month, i);
      totalIncome += dailyIncomes[d] ?? 0;
      totalExpense += dailyExpenses[d] ?? 0;
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () => onDaySelected(monthDate),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : (isCurrentMonth
                    ? colorScheme.surfaceContainerHighest
                    : colorScheme.surfaceContainerLow),
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: colorScheme.primary, width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat.MMM().format(monthDate),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? colorScheme.onPrimaryContainer : null,
              ),
            ),
            const SizedBox(height: 8),
            if (totalIncome > 0)
              Text(
                '+${NumberFormat.compactSimpleCurrency(name: currencyCode).format(totalIncome)}',
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (totalExpense > 0)
              Text(
                '-${NumberFormat.compactSimpleCurrency(name: currencyCode).format(totalExpense)}',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(BuildContext context, String text, Color color) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
