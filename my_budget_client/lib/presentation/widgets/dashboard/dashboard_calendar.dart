import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/core/theme/app_spacing.dart';
import 'package:my_budget_client/core/utils/date_display.dart';
import 'package:my_budget_client/core/theme/money_colors.dart';
import 'package:my_budget_client/core/utils/money_formatter.dart';
import 'package:my_budget_client/presentation/widgets/dashboard/dashboard_header.dart';
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
  final String currencyCode;
  final List<String> availableCurrencies;
  final Function(String) onCurrencySelected;
  final Function(DateStep) onDateStepChanged;

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
    required this.availableCurrencies,
    required this.onCurrencySelected,
    required this.onDateStepChanged,
  });

  @override
  Widget build(BuildContext context) {
    // RESPONSIVE: Use LayoutBuilder to adapt to screen size
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate appropriate maxWidth based on screen width
        final screenWidth = constraints.maxWidth;
        final isWideScreen = screenWidth > kMobileBreakpoint;
        // RESPONSIVE: 700px on desktop for better readability
        final maxCalendarWidth = isWideScreen
            ? kDashboardCalendarColumnWidth
            : screenWidth;

        return Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isWideScreen ? 0 : 12.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxCalendarWidth),
              child: Column(
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 16),
                  if (dateStep == DateStep.month) ...[
                    _buildWeekdayLabels(context),
                    const SizedBox(height: 8),
                    _buildMonthView(context, isWideScreen),
                  ] else if (dateStep == DateStep.year) ...[
                    _buildYearView(context),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return DashboardHeader(
      selectedDay: selectedDay,
      dateStep: dateStep,
      currencyCode: currencyCode,
      availableCurrencies: availableCurrencies,
      onPrevious: onPrevious,
      onNext: onNext,
      onTitleTap: onTitleTap,
      onCurrencySelected: onCurrencySelected,
      onDateStepChanged: onDateStepChanged,
    );
  }

  /// Key for the weekday label in column [column], so a test can prove the
  /// header row and the day grid agree rather than checking them separately.
  static ValueKey<String> weekdayLabelKey(int column) =>
      ValueKey<String>('dashboard-weekday-$column');

  /// Key for the cell showing [day] of the displayed month.
  static ValueKey<String> dayCellKey(int day) =>
      ValueKey<String>('dashboard-day-$day');

  /// Key for a cell that shows a day belonging to the month before or after
  /// the one on screen. Distinct from [dayCellKey] because both can show the
  /// same number — the 31st of the displayed month and the 31st spilling in
  /// from the previous one.
  static ValueKey<String> adjacentDayCellKey(DateTime date) =>
      ValueKey<String>('dashboard-adjacent-day-${date.toIso8601String()}');

  /// A month grid is always this many rows.
  ///
  /// A month needs four, five or six depending on its length and which weekday
  /// it starts on, so sizing the grid to the month made it change height as the
  /// user paged through the year — the whole dashboard below it jumped. Six is
  /// the worst case, so every month fits and none of them moves anything.
  static const int monthGridRows = 6;

  Widget _buildWeekdayLabels(BuildContext context) {
    // The week used to be hardcoded to start on Monday by formatting
    // 1-7 January 2024 in order. Arabic starts on Saturday and en_US on
    // Sunday, so the header was a column off from the dates underneath it for
    // at least three shipped locales - and the grid below shifts by the same
    // `firstDayOfWeek`, so the two cannot drift apart again.
    final weekdays = DateDisplay.weekdayLabels(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        for (var i = 0; i < weekdays.length; i++)
          Expanded(
            child: Center(
              key: weekdayLabelKey(i),
              child: Text(
                weekdays[i],
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMonthView(BuildContext context, bool isWideScreen) {
    final firstDayOfMonth = DateTime(selectedDay.year, selectedDay.month, 1);
    final lastDayOfMonth = DateTime(selectedDay.year, selectedDay.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startingWeekday = firstDayOfMonth.weekday; // 1=Mon .. 7=Sun
    // Same authority the header row reads, so the first cell always lands
    // under its own label whatever the locale's week start is.
    final firstDayOfWeek = DateDisplay.firstDayOfWeek(context);
    final leadingBlanks = (startingWeekday - firstDayOfWeek + 7) % 7;

    // RESPONSIVE: Use different aspect ratio for phone vs desktop
    final aspectRatio = isWideScreen ? 0.9 : 0.75;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: aspectRatio,
      ),
      itemCount: monthGridRows * 7,
      itemBuilder: (context, index) {
        final day = index - leadingBlanks + 1;
        // Days from the neighbouring months keep the grid the same height in
        // every month. They are shown faded and inert: they are not part of
        // this month, so they carry none of its figures and tapping one would
        // move the whole dashboard to another month by accident.
        if (day < 1 || day > daysInMonth) {
          return _buildAdjacentDayCell(
            context,
            DateTime(selectedDay.year, selectedDay.month, day),
          );
        }
        final date = DateTime(selectedDay.year, selectedDay.month, day);

        return _buildDayCell(context, date);
      },
    );
  }

  /// A day belonging to the previous or next month: same footprint, dimmed,
  /// no amounts, not tappable.
  Widget _buildAdjacentDayCell(BuildContext context, DateTime date) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Opacity(
      key: adjacentDayCellKey(date),
      // Dimmed enough to read as "not this month", but no dimmer: the themes
      // that blur the window behind the app already give the cards a partly
      // transparent fill, and a lower opacity on top of that left these cells
      // with neither a visible box nor a visible number.
      opacity: 0.6,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          padding: const EdgeInsetsDirectional.only(top: 4, end: 6),
          alignment: AlignmentDirectional.topEnd,
          child: Text(
            date.day.toString(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
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

    return Material(
      key: dayCellKey(date.day),
      // Transparent background; the color is applied inside Ink
      color: Colors.transparent,
      // Clip the paint area so the highlight stays within bounds
      clipBehavior: Clip.antiAlias,
      // Match the corner radius of the inner Ink
      borderRadius: BorderRadius.circular(8),
      child: Ink(
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : (isToday
                    ? colorScheme.primaryContainer.withValues(alpha: 0.8)
                    : theme.cardColor),
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: colorScheme.primary, width: 2)
              : null,
        ),
        child: InkWell(
          onTap: () => onDaySelected(date),
          // Radius for the tap ripple effect
          borderRadius: BorderRadius.circular(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Day number
              Container(
                width: double.infinity,
                padding: const EdgeInsetsDirectional.only(top: 4, end: 6),
                alignment: AlignmentDirectional.topEnd,
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
              // Stats (Income/Expense)
              //
              // One FittedBox around both lines rather than one around each:
              // scaled apart, a four-figure income and a two-figure expense in
              // the same cell came out at two visibly different font sizes,
              // which reads as a rendering fault. Sharing the box, they shrink
              // together and stay a matched pair.
              if (income > 0 || expense > 0)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (income > 0)
                        _miniStatText(
                          '+${MoneyFormatter.formatCompact(income, currencyCode)} ${NumberFormat.simpleCurrency(name: currencyCode).currencySymbol}',
                          MoneyColors.of(context).inflow,
                        ),
                      if (expense > 0)
                        _miniStatText(
                          '−${MoneyFormatter.formatCompact(expense, currencyCode)} ${NumberFormat.simpleCurrency(name: currencyCode).currencySymbol}',
                          MoneyColors.of(context).outflow,
                        ),
                    ],
                  ),
                ),
              const Spacer(),
            ],
          ),
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
            childAspectRatio: isWide ? 1.2 : 1.0, // Was 1.5, now more square
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

    return Ink(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.primaryContainer
            : (isCurrentMonth
                  ? colorScheme.primaryContainer.withValues(
                      alpha: 0.3,
                    ) // Consistent with day view today
                  : theme.cardColor),
        borderRadius: BorderRadius.circular(16),
        border: isSelected
            ? Border.all(color: colorScheme.primary, width: 2)
            : null,
      ),
      child: InkWell(
        onTap: () => onDaySelected(monthDate),
        borderRadius: BorderRadius.circular(16),
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
            // Show Net Delta
            Builder(
              builder: (context) {
                final net = totalIncome - totalExpense;
                final color = MoneyColors.of(context).forAmount(net);
                final currencySymbol = NumberFormat.simpleCurrency(
                  name: currencyCode,
                ).currencySymbol;
                return Text(
                  '${net >= 0 ? '+' : ''}${MoneyFormatter.format(net, currencyCode)}$currencySymbol',
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// One amount line of a day cell. Unscaled on its own — the caller's
  /// FittedBox scales it together with the other line.
  Widget _miniStatText(String text, Color color) {
    return Text(
      text,
      maxLines: 1,
      softWrap: false,
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
