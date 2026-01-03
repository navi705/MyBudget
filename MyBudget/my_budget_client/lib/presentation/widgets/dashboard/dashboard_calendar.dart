import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardCalendar extends StatelessWidget {
  final DateTime selectedDay;
  final Map<DateTime, double> dailyIncomes;
  final Map<DateTime, double> dailyExpenses;
  final Function(DateTime) onDaySelected;

  const DashboardCalendar({
    super.key,
    required this.selectedDay,
    required this.dailyIncomes,
    required this.dailyExpenses,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(selectedDay.year, selectedDay.month, 1);
    final lastDayOfMonth = DateTime(selectedDay.year, selectedDay.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startingWeekday = firstDayOfMonth.weekday; // 1 (Mon) to 7 (Sun)

    // Adjust for starting day of the week (if needed, here assumes Monday start)
    // Flutter's weekday is 1=Mon, 7=Sun.

    return Column(
      children: [
        _buildHeader(context),
        const SizedBox(height: 16),
        _buildWeekdayLabels(context),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: daysInMonth + (startingWeekday - 1),
          itemBuilder: (context, index) {
            if (index < startingWeekday - 1) {
              return const SizedBox.shrink();
            }

            final dayNumber = index - (startingWeekday - 2);
            final currentDay = DateTime(
              selectedDay.year,
              selectedDay.month,
              dayNumber,
            );
            final isSelected =
                dayNumber == selectedDay.day &&
                selectedDay.month == currentDay.month &&
                selectedDay.year == currentDay.year;

            final isToday =
                dayNumber == now.day &&
                now.month == currentDay.month &&
                now.year == currentDay.year;

            final hasIncome = dailyIncomes.containsKey(currentDay);
            final hasExpense = dailyExpenses.containsKey(currentDay);

            return _buildDayCell(
              context,
              dayNumber,
              isSelected,
              isToday,
              hasIncome,
              hasExpense,
              () => onDaySelected(currentDay),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          DateFormat.MMMM().format(selectedDay),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          selectedDay.year.toString(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary.withAlpha(200),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayLabels(BuildContext context) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekdays
          .map(
            (d) => Expanded(
              child: Center(
                child: Text(
                  d,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).hintColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildDayCell(
    BuildContext context,
    int day,
    bool isSelected,
    bool isToday,
    bool hasIncome,
    bool hasExpense,
    VoidCallback onTap,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary
              : (isToday ? colorScheme.primary.withAlpha(30) : null),
          borderRadius: BorderRadius.circular(12),
          border: isToday && !isSelected
              ? Border.all(color: colorScheme.primary, width: 2)
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              day.toString(),
              style: TextStyle(
                fontWeight: isSelected || isToday
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: isSelected ? colorScheme.onPrimary : null,
              ),
            ),
            Positioned(
              bottom: 4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasIncome)
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (hasIncome && hasExpense) const SizedBox(width: 2),
                  if (hasExpense)
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
