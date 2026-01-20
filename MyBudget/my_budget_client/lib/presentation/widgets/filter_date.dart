import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

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

  String _formatDate(TransactionsState state) {
    if (state.filterMode == FilterMode.range) {
      if (state.activeDateRange == null) return 'Select Range';
      final start = DateFormat(
        'dd.MM.yyyy',
      ).format(state.activeDateRange!.start);
      final end = DateFormat('dd.MM.yyyy').format(state.activeDateRange!.end);
      return '$start - $end';
    }

    switch (state.dateStep) {
      case DateStep.day:
        return DateFormat('dd.MM.yyyy').format(state.activeDate);
      case DateStep.month:
        return DateFormat('MMMM yyyy', 'ru_RU').format(state.activeDate);
      case DateStep.year:
        return DateFormat('yyyy').format(state.activeDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionsBloc, TransactionsState>(
      builder: (context, state) {
        final onSurface = Theme.of(context).colorScheme.onSurface;
        final isMobile = MediaQuery.of(context).size.width < 600;

        final centerWidget = Row(
          mainAxisAlignment: isMobile
              ? MainAxisAlignment.spaceBetween
              : MainAxisAlignment.center,
          mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
          children: [
            MultiLevelTooltip(
              message: 'Previous Period',
              actionId: 'prev_period',
              description: 'Go to the previous day, month, or year',
              child: IconButton(
                icon: Icon(Icons.chevron_left, color: onSurface),
                onPressed: () => context.read<TransactionsBloc>().add(
                  const DatePeriodNavigated(-1),
                ),
              ),
            ),
            if (isMobile)
              MultiLevelTooltip(
                message: 'Advanced Filter',
                actionId: 'filter_advanced',
                description:
                    'Filter transactions by account, category, or amount',
                child: IconButton(
                  icon: Icon(Icons.tune, color: onSurface),
                  onPressed: () =>
                      showAdvancedFilterDialog(context, state.nonDateFilters),
                ),
              )
            else if (!isMobile) ...[
              MultiLevelTooltip(
                message: 'Advanced Filter',
                actionId: 'filter_advanced',
                description:
                    'Filter transactions by account, category, or amount',
                child: IconButton(
                  icon: Icon(Icons.tune, color: onSurface),
                  onPressed: () =>
                      showAdvancedFilterDialog(context, state.nonDateFilters),
                ),
              ),
            ],
            if (!isMobile) const SizedBox(width: 8),
            Expanded(
              flex: isMobile ? 1 : 0,
              child: MultiLevelTooltip(
                message: 'Select Date',
                actionId: 'filter_pick_date',
                description: 'Choose a specific date or date range',
                child: InkWell(
                  onTap: () => _showCustomCalendar(context, state),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    alignment: Alignment.center,
                    child: Text(
                      _formatDate(state),
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
                message: 'Sort Order',
                actionId: 'filter_sort',
                description: 'Toggle between ascending and descending order',
                child: RotatedBox(
                  quarterTurns: state.sort == Sort.ascending ? 0 : 2,
                  child: IconButton(
                    icon: Icon(Icons.sort, color: onSurface),
                    onPressed: () {
                      final newSort = state.sort == Sort.ascending
                          ? Sort.descending
                          : Sort.ascending;
                      context.read<TransactionsBloc>().add(
                        SortChanged(newSort),
                      );
                    },
                  ),
                ),
              )
            else if (!isMobile) ...[
              const SizedBox(width: 8),
            ],
            if (!isMobile) ...[
              const SizedBox(width: 8),
              MultiLevelTooltip(
                message: 'Sort Order',
                actionId: 'filter_sort',
                description: 'Toggle between ascending and descending order',
                child: RotatedBox(
                  quarterTurns: state.sort == Sort.ascending ? 0 : 2,
                  child: IconButton(
                    icon: Icon(Icons.sort, color: onSurface),
                    onPressed: () {
                      final newSort = state.sort == Sort.ascending
                          ? Sort.descending
                          : Sort.ascending;
                      context.read<TransactionsBloc>().add(
                        SortChanged(newSort),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            MultiLevelTooltip(
              message: 'Next Period',
              actionId: 'next_period',
              description: 'Go to the next day, month, or year',
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
          totalCountText: 'Всего: ${state.totalCount}',
          centerWidget: centerWidget,
        );
      },
    );
  }

  void _showCustomCalendar(BuildContext context, TransactionsState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
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
}
