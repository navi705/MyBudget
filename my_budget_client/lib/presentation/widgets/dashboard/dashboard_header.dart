import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
import 'package:my_budget_client/core/theme/app_spacing.dart';
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
      title = DateFormat.yMMMM(
        Localizations.localeOf(context).toString(),
      ).format(selectedDay);
    } else {
      title = selectedDay.year.toString();
    }

    final onSurface = Theme.of(context).colorScheme.onSurface;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < kMobileBreakpoint;

        // Shared Components
        final leftArrow = MultiLevelTooltip(
          message: context.l10n.previousPeriodTooltip,
          actionId: 'prev_period',
          description: context.l10n.previousPeriodDescription,
          child: IconButton(
            icon: Icon(Icons.chevron_left, color: onSurface),
            onPressed: onPrevious,
          ),
        );

        final rightArrow = MultiLevelTooltip(
          message: context.l10n.nextPeriodTooltip,
          actionId: 'next_period',
          description: context.l10n.nextPeriodDescription,
          child: IconButton(
            icon: Icon(Icons.chevron_right, color: onSurface),
            onPressed: onNext,
          ),
        );

        final titleWidget = MultiLevelTooltip(
          message: context.l10n.selectDateTooltip,
          // Screen-agnostic, like `prev_period` and `next_period` above: every
          // screen that shows a period carries the same date button, one
          // binding serves all of them, and only the focused screen answers.
          // The old `dashboard_pick_date` was a fourth id nothing could bind.
          actionId: 'pick_date',
          description: context.l10n.dshSelectDateDescription,
          child: _PeriodSelector(title: title, onTap: onTitleTap),
        );

        final currencySelector = MultiLevelTooltip(
          message: context.l10n.currencyLabel,
          actionId: 'dashboard_currency',
          description: context.l10n.dshCurrencyDescription,
          child: DashboardCurrencySelector(
            selectedCurrency: currencyCode,
            availableCurrencies: availableCurrencies,
            onCurrencyChanged: onCurrencySelected,
          ),
        );

        final viewSwitcher = MultiLevelTooltip(
          message: context.l10n.dshChangeViewTooltip,
          actionId: 'dashboard_switch_view',
          description: context.l10n.dshChangeViewDescription,
          child: SegmentedButton<DateStep>(
            segments: [
              ButtonSegment(
                value: DateStep.month,
                label: Text(context.l10n.dshMonthlyAbbreviation),
              ),
              ButtonSegment(
                value: DateStep.year,
                label: Text(context.l10n.dshYearlyAbbreviation),
              ),
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
              backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.selected)) {
                  return Theme.of(context).colorScheme.primary;
                }
                return Theme.of(context).colorScheme.surfaceContainerHighest;
              }),
              foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.selected)) {
                  return Theme.of(context).colorScheme.onPrimary;
                }
                return Theme.of(context).colorScheme.onSurface;
              }),
            ),
          ),
        );

        // --- MOBILE LAYOUT (2 Rows) ---
        if (isMobile) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Row 1: Arrows and Title
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  leftArrow,
                  Expanded(child: titleWidget),
                  rightArrow,
                ],
              ),
              const SizedBox(height: 4),
              // Row 2: Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  currencySelector,
                  const SizedBox(width: 8),
                  viewSwitcher,
                ],
              ),
            ],
          );
        }

        // --- DESKTOP/WIDE LAYOUT (1 Row) ---
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                leftArrow,
                const SizedBox(width: 8),
                currencySelector,
                const SizedBox(width: 16),
                titleWidget,
                const SizedBox(width: 16),
                viewSwitcher,
                const SizedBox(width: 8),
                rightArrow,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PeriodSelector extends StatefulWidget {
  final String title;
  final VoidCallback onTap;

  const _PeriodSelector({required this.title, required this.onTap});

  @override
  State<_PeriodSelector> createState() => _PeriodSelectorState();
}

class _PeriodSelectorState extends State<_PeriodSelector> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered
                ? colorScheme.surfaceContainerHighest
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isHovered
                  ? colorScheme.onSurface.withValues(alpha: 0.1)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Text(
            widget.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
