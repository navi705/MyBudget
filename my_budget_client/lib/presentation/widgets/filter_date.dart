import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
import 'package:my_budget_client/core/theme/app_spacing.dart';

import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';
import 'package:my_budget_client/presentation/widgets/advanced_filter_dialog.dart';
import 'package:my_budget_client/presentation/widgets/generic/generic_filter_app_bar.dart';
import 'package:my_budget_client/presentation/widgets/calendar_step_picker.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/presentation/widgets/multi_level_tooltip.dart';

class FilterDate extends StatelessWidget implements PreferredSizeWidget {
  const FilterDate({super.key});

  @override
  Size get preferredSize => Size.fromHeight(
    // We'll trust GenericFilterAppBar's internal logic for actual layout,
    // but we need to declare the correct PreferredSize for Scaffold.
    // Since we don't have context in preferredSize getter, we use a conservative standard.
    // However, GenericFilterAppBar will handle its own height internally.
    kToolbarHeight * 1.5,
  );

  String _formatDate(TransactionsState state, BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    if (state.filterMode == FilterMode.range) {
      if (state.activeDateRange == null) {
        return context.l10n.fltSelectRange;
      }
      final start = DateFormat(
        'dd.MM.yyyy',
        locale,
      ).format(state.activeDateRange!.start);
      final end = DateFormat(
        'dd.MM.yyyy',
        locale,
      ).format(state.activeDateRange!.end);
      return '$start - $end';
    }

    switch (state.dateStep) {
      case DateStep.day:
        return DateFormat('dd.MM.yyyy', locale).format(state.activeDate);
      case DateStep.month:
        return DateFormat('MMMM yyyy', locale).format(state.activeDate);
      case DateStep.year:
        return DateFormat('yyyy', locale).format(state.activeDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionsBloc, TransactionsState>(
      builder: (context, state) {
        final onSurface = Theme.of(context).colorScheme.onSurface;
        final isMobile = MediaQuery.of(context).size.width < kMobileBreakpoint;

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
                icon: Icon(Icons.chevron_left, color: onSurface),
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
                  quarterTurns: state.sort == Sort.ascending ? 0 : 2,
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
                  quarterTurns: state.sort == Sort.ascending ? 0 : 2,
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
                icon: Icon(Icons.chevron_right, color: onSurface),
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

void toggleTransactionsSort(TransactionsBloc bloc, TransactionsState state) {
  bloc.add(
    SortChanged(
      state.sort == Sort.ascending ? Sort.descending : Sort.ascending,
    ),
  );
}
