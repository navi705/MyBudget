import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/presentation/widgets/dashboard/dashboard_currency_selector.dart';

import 'package:my_budget_client/presentation/widgets/multi_level_tooltip.dart';

class DashboardHeader extends StatelessWidget {
  // ... (keep fields)
  final DateTime selectedDay;
  final DateStep dateStep;
  final String currencyCode;
  final List<String> availableCurrencies;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onTitleTap;
  final Function(String) onCurrencySelected;
  final Function(DateStep) onDateStepChanged;

  const DashboardHeader({
    super.key,
    required this.selectedDay,
    required this.dateStep,
    required this.currencyCode,
    required this.availableCurrencies,
    required this.onPrevious,
    required this.onNext,
    required this.onTitleTap,
    required this.onCurrencySelected,
    required this.onDateStepChanged,
  });

  @override
  Widget build(BuildContext context) {
    String title;
    if (dateStep == DateStep.month) {
      title = DateFormat.yMMMM().format(selectedDay);
    } else {
      title = selectedDay.year.toString();
    }

    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Left Arrow
            MultiLevelTooltip(
              message: 'Previous Period',
              actionId: 'prev_period',
              description: 'Go to the previous month or year',
              child: IconButton(
                icon: Icon(Icons.chevron_left, color: onSurface),
                onPressed: onPrevious,
              ),
            ),
            // Currency Selector
            MultiLevelTooltip(
              message: 'Currency',
              actionId: 'dashboard_currency',
              description: 'Select the primary currency for display',
              child: DashboardCurrencySelector(
                selectedCurrency: currencyCode,
                availableCurrencies: availableCurrencies,
                onCurrencyChanged: onCurrencySelected,
              ),
            ),
            const SizedBox(width: 16),
            // Center: Title
            MultiLevelTooltip(
              message: 'Select Date',
              actionId: 'dashboard_pick_date',
              description: 'Open calendar to pick a specific date or range',
              child: InkWell(
                onTap: onTitleTap,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    title,
                    style: TextStyle(color: onSurface, fontSize: 18),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // DateStep Selector (Month/Year)
            MultiLevelTooltip(
              message: 'Change View',
              actionId: 'dashboard_switch_view',
              description: 'Switch between Monthly and Yearly views',
              child: SegmentedButton<DateStep>(
                segments: const [
                  ButtonSegment(value: DateStep.month, label: Text('M')),
                  ButtonSegment(value: DateStep.year, label: Text('Y')),
                ],
                selected: {dateStep},
                onSelectionChanged: (Set<DateStep> newSelection) {
                  onDateStepChanged(newSelection.first);
                },
                showSelectedIcon: false,
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  backgroundColor: WidgetStateProperty.resolveWith<Color>((
                    states,
                  ) {
                    if (states.contains(WidgetState.selected)) {
                      return Theme.of(context).colorScheme.primary;
                    }
                    return Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith<Color>((
                    states,
                  ) {
                    if (states.contains(WidgetState.selected)) {
                      return Theme.of(context).colorScheme.onPrimary;
                    }
                    return Theme.of(context).colorScheme.onSurface;
                  }),
                ),
              ),
            ),
            // Right Arrow
            MultiLevelTooltip(
              message: 'Next Period',
              actionId: 'next_period',
              description: 'Go to the next month or year',
              child: IconButton(
                icon: Icon(Icons.chevron_right, color: onSurface),
                onPressed: onNext,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
