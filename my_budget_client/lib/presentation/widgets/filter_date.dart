import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
import 'package:my_budget_client/core/theme/pane_layout.dart';
import 'package:my_budget_client/core/utils/date_display.dart';
import 'package:my_budget_client/presentation/widgets/directional_icon.dart';

import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';
import 'package:my_budget_client/presentation/widgets/advanced_filter_dialog.dart';
import 'package:my_budget_client/presentation/widgets/generic/generic_filter_app_bar.dart';
import 'package:my_budget_client/presentation/widgets/calendar_step_picker.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/presentation/widgets/multi_level_tooltip.dart';

class FilterDate extends StatelessWidget implements PreferredSizeWidget {
  const FilterDate({super.key});

  // One height authority for the whole bar: this widget only ever renders a
  // GenericFilterAppBar, so it declares exactly what that bar draws. Declaring
  // 1.5x while the bar drew 1x left ~28dp of dead space under it.
  @override
  Size get preferredSize => GenericFilterAppBar.barSize;

  String _formatDate(TransactionsState state, BuildContext context) {
    // `dd.MM.yyyy` and `MMMM yyyy` were typed in here and handed to all ten
    // locales, so an en_US, ar or zh reader got a European date order. Both
    // patterns now come from the locale's own symbol data.
    if (state.filterMode == FilterMode.range) {
      if (state.activeDateRange == null) {
        return context.l10n.fltSelectRange;
      }
      final start = DateDisplay.short(context, state.activeDateRange!.start);
      final end = DateDisplay.short(context, state.activeDateRange!.end);
      return '$start - $end';
    }

    switch (state.dateStep) {
      case DateStep.day:
        return DateDisplay.short(context, state.activeDate);
      case DateStep.month:
        return DateDisplay.monthYear(context, state.activeDate);
      case DateStep.year:
        // A bare year has no locale-specific field order to get wrong, but it
        // still has locale-specific digits (Arabic-Indic in `ar`).
        return DateFormat.y(
          DateDisplay.localeOf(context),
        ).format(state.activeDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionsBloc, TransactionsState>(
      builder: (context, state) {
        final onSurface = Theme.of(context).colorScheme.onSurface;
        // The pane, not the window: the rail takes ~73dp off the left, so a
        // window over the breakpoint can hand this bar a pane under it.
        final isMobile = context.isCompactPane;
        final queueOnly = state.nonDateFilters.needsReview == true;

        final centerWidget = Row(
          mainAxisAlignment: isMobile
              ? MainAxisAlignment.spaceBetween
              : MainAxisAlignment.center,
          mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
          children: [
            MultiLevelTooltip(
              message: context.l10n.previousPeriodTooltip,
              actionId: 'prev_period',
              description: context.l10n.previousPeriodDescription,
              child: IconButton(
                icon: DirectionalIcon.previous(color: onSurface),
                onPressed: () => context.read<TransactionsBloc>().add(
                  const DatePeriodNavigated(-1),
                ),
              ),
            ),
            if (isMobile)
              MultiLevelTooltip(
                message: context.l10n.filterTooltip,
                actionId: 'filter_action',
                description: context.l10n.filterCategoriesDescription,
                child: IconButton(
                  icon: Icon(Icons.tune, color: onSurface),
                  onPressed: () =>
                      showAdvancedFilterDialog(context, state.nonDateFilters),
                ),
              )
            else if (!isMobile) ...[
              MultiLevelTooltip(
                message: context.l10n.fltAdvancedFilterTooltip,
                actionId: 'filter_action',
                description: context.l10n.fltAdvancedFilterDescription,
                child: IconButton(
                  icon: Icon(Icons.tune, color: onSurface),
                  onPressed: () =>
                      showAdvancedFilterDialog(context, state.nonDateFilters),
                ),
              ),
            ],
            // The review queue: rows the SMS import could not file with
            // confidence. It is a toggle rather than a control inside the
            // advanced dialog because working the queue down is a repeated
            // in-and-out, not a filter you set once.
            MultiLevelTooltip(
              message: context.l10n.reviewQueueTooltip,
              actionId: 'review_queue',
              description: context.l10n.reviewQueueDescription,
              child: IconButton(
                isSelected: queueOnly,
                icon: Icon(
                  queueOnly ? Icons.flag : Icons.flag_outlined,
                  color: queueOnly
                      ? Theme.of(context).colorScheme.primary
                      : onSurface,
                ),
                onPressed: () => toggleReviewQueue(
                  context.read<TransactionsBloc>(),
                  state,
                ),
              ),
            ),
            if (!isMobile) const SizedBox(width: 8),
            // Loose Flexible, not Expanded: with flex 0 the date was laid out
            // unbounded and could push the row past the app bar, and with the
            // tight fit of Expanded a long range string wrapped to two lines
            // inside a fixed-height bar. Loose lets it shrink to the space left
            // by the icon buttons and ellipsize instead.
            Flexible(
              fit: FlexFit.loose,
              child: MultiLevelTooltip(
                message: context.l10n.selectDateTooltip,
                actionId: 'pick_date',
                description: context.l10n.selectDateDescription,
                child: InkWell(
                  onTap: () => showTransactionsCalendar(context, state),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    alignment: Alignment.center,
                    child: Text(
                      _formatDate(state, context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: onSurface,
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: isMobile
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (isMobile)
              MultiLevelTooltip(
                message: context.l10n.sortOrderTooltip,
                actionId: 'sort_order',
                description: context.l10n.fltSortOrderDescription,
                child: RotatedBox(
                  // Ascending turns the icon over, as it does on accounts,
                  // categories, exchange rates, assets and inflation. This
                  // bar had the condition inverted, so the same sort order
                  // drew opposite arrows on two screens of one app.
                  quarterTurns: state.sort == Sort.ascending ? 2 : 0,
                  child: IconButton(
                    icon: Icon(Icons.sort, color: onSurface),
                    onPressed: () => toggleTransactionsSort(
                      context.read<TransactionsBloc>(),
                      state,
                    ),
                  ),
                ),
              )
            else if (!isMobile) ...[
              const SizedBox(width: 8),
            ],
            if (!isMobile) ...[
              const SizedBox(width: 8),
              MultiLevelTooltip(
                message: context.l10n.sortOrderTooltip,
                actionId: 'sort_order',
                description: context.l10n.fltSortOrderDescription,
                child: RotatedBox(
                  // Same rotation as the mobile branch above.
                  quarterTurns: state.sort == Sort.ascending ? 2 : 0,
                  child: IconButton(
                    icon: Icon(Icons.sort, color: onSurface),
                    onPressed: () => toggleTransactionsSort(
                      context.read<TransactionsBloc>(),
                      state,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            MultiLevelTooltip(
              message: context.l10n.nextPeriodTooltip,
              actionId: 'next_period',
              description: context.l10n.nextPeriodDescription,
              child: IconButton(
                icon: DirectionalIcon.next(color: onSurface),
                onPressed: () => context.read<TransactionsBloc>().add(
                  const DatePeriodNavigated(1),
                ),
              ),
            ),
          ],
        );

        return GenericFilterAppBar(
          totalCountText: context.l10n.totalCountLabel(
            state.totalCount.toString(),
          ),
          centerWidget: centerWidget,
        );
      },
    );
  }
}

// The date picker and the sort toggle are drawn by this app bar, but the Hot
// Keys screen offers both as bindable actions and the ScreenShortcuts that has
// to run them lives in transactions_screen.dart, above the Scaffold this bar is
// the appBar of. Top-level functions let the button and the hotkey call one
// implementation instead of two that can drift apart.
//
// The filter button needs none: its body is already the top-level
// `showAdvancedFilterDialog`.
void showTransactionsCalendar(BuildContext context, TransactionsState state) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    // The sheet is a route of its own, so its builder context is a sibling of
    // this bar rather than a descendant: the bloc is read from the context
    // passed in, which is provably below the provider the bar itself reads.
    builder: (_) {
      return CalendarStepPicker(
        initialDate: state.activeDate,
        initialRange: state.activeDateRange,
        initialStep: state.dateStep,
        initialFilterMode: state.filterMode,
        rangeOptionVisibility: PickerVisibility.visible,
        onApply: (date, range, step, mode) {
          final bloc = context.read<TransactionsBloc>();

          if (step != state.dateStep) {
            bloc.add(DateStepChanged(step));
          }

          if (mode != state.filterMode) {
            bloc.add(FilterModeChanged(mode));
          }

          if (mode == FilterMode.range && range != null) {
            bloc.add(ActiveDateRangeChanged(range));
          } else {
            bloc.add(ActiveDateChanged(date));
          }
        },
      );
    },
  );
}

/// Flips the transactions list between "only the review queue" and
/// "everything", leaving every other filter where the user put it.
///
/// Off is null, not false: false would show only the rows already reviewed,
/// hiding the queue from a list that is supposed to show both.
void toggleReviewQueue(TransactionsBloc bloc, TransactionsState state) {
  final on = state.nonDateFilters.needsReview == true;
  bloc.add(
    NonDateFiltersChanged(
      on
          ? state.nonDateFilters.copyWith(clearNeedsReview: true)
          : state.nonDateFilters.copyWith(needsReview: true),
    ),
  );
}

void toggleTransactionsSort(TransactionsBloc bloc, TransactionsState state) {
  bloc.add(
    SortChanged(
      state.sort == Sort.ascending ? Sort.descending : Sort.ascending,
    ),
  );
}
