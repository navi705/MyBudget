import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/presentation/blocs/inflation/inflation_bloc.dart';
import 'package:my_budget_client/presentation/widgets/calendar_step_picker.dart';
import 'package:my_budget_client/presentation/widgets/generic/generic_filter_app_bar.dart';
import 'package:my_budget_client/presentation/widgets/inflation_filter_dialog.dart';
import 'package:my_budget_client/presentation/widgets/multi_level_tooltip.dart';

class InflationTabAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final InflationState state;

  const InflationTabAppBar({super.key, required this.state});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight * 1.5);

  void _showCustomCalendar(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return BlocProvider.value(
          value: context.read<InflationBloc>(),
          child: CalendarStepPicker(
            initialDate: state.activeDate,
            initialRange: state.activeDateRange,
            initialStep: state.dateStep,
            initialFilterMode: state.filterMode,
            rangeOptionVisibility: PickerVisibility.visible,
            onApply: (date, range, step, mode) {
              final bloc = context.read<InflationBloc>();
              if (state.filterMode != mode) {
                bloc.add(ChangeInflationFilterMode(mode));
              }
              if (state.dateStep != step) {
                bloc.add(ChangeInflationDateStep(step));
              }
              if (mode == FilterMode.range && range != null) {
                bloc.add(ChangeInflationActiveDateRange(range));
              } else {
                bloc.add(ChangeInflationActiveDate(date));
              }
            },
          ),
        );
      },
    );
  }

  String _formatDate(BuildContext context) {
    if (state.filterMode == FilterMode.range) {
      if (state.activeDateRange == null) return 'Select Range';
      final start = MaterialLocalizations.of(
        context,
      ).formatShortDate(state.activeDateRange!.start);
      final end = MaterialLocalizations.of(
        context,
      ).formatShortDate(state.activeDateRange!.end);
      return '$start - $end';
    }

    switch (state.dateStep) {
      case DateStep.day:
        return MaterialLocalizations.of(
          context,
        ).formatShortDate(state.activeDate);
      case DateStep.month:
        return MaterialLocalizations.of(
          context,
        ).formatMonthYear(state.activeDate);
      case DateStep.year:
        return state.activeDate.year.toString();
    }
  }

  void _navigate(InflationBloc bloc, int i) {
    if (state.filterMode == FilterMode.range) return;

    DateTime newDate = state.activeDate;
    if (state.dateStep == DateStep.day) {
      newDate = newDate.add(Duration(days: i));
    } else if (state.dateStep == DateStep.month) {
      newDate = DateTime(newDate.year, newDate.month + i, newDate.day);
    } else if (state.dateStep == DateStep.year) {
      newDate = DateTime(newDate.year + i, newDate.month, newDate.day);
    }
    bloc.add(ChangeInflationActiveDate(newDate));
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<InflationBloc>();
    final onSurface = Theme.of(context).colorScheme.onSurface;

    if (state.isSelectionModeActive) {
      return _SelectionAppBar(
        selectionCount: state.selectedRates.length,
        totalCount: state
            .rates
            .length, // Should ideally use loaded count for "Select All" logic if we want to limit to loaded, but "Select All" usually means "Select All Loaded" or "All in DB"?
        // ExchangeRates implementation selects all in layout.
        // selectAll event in Bloc selects state.rates.
        onClearSelection: () => bloc.add(DeselectAllInflationRates()),
        onSelectAll: () {
          if (state.selectedRates.length == state.rates.length) {
            bloc.add(DeselectAllInflationRates());
          } else {
            bloc.add(SelectAllInflationRates());
          }
        },
        onDelete: () => _showDeleteConfirmation(context, bloc),
      );
    }

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
          description: 'Move back by one day, month, or year',
          child: IconButton(
            icon: Icon(Icons.chevron_left, color: onSurface),
            onPressed: () => _navigate(bloc, -1),
          ),
        ),
        if (isMobile)
          IconButton(
            icon: Icon(Icons.tune, color: onSurface),
            onPressed: () => showInflationFilterDialog(context),
          )
        else if (!isMobile) ...[
          IconButton(
            icon: Icon(Icons.tune, color: onSurface),
            onPressed: () => showInflationFilterDialog(context),
          ),
        ],
        if (!isMobile) const SizedBox(width: 8),
        Expanded(
          flex: isMobile ? 1 : 0,
          child: MultiLevelTooltip(
            message: 'Select Date',
            actionId: 'inflation_pick_date',
            description: 'Change the active period or date range',
            child: InkWell(
              onTap: () => _showCustomCalendar(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                alignment: Alignment.center,
                child: Text(
                  _formatDate(context),
                  style: TextStyle(
                    color: onSurface,
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: isMobile ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (isMobile)
          RotatedBox(
            quarterTurns: state.sort == Sort.ascending ? 2 : 0,
            child: MultiLevelTooltip(
              message: 'Sort Order',
              actionId: 'inflation_sort',
              description: 'Toggle between ascending and descending order',
              child: IconButton(
                icon: Icon(Icons.sort, color: onSurface),
                onPressed: () {
                  final newSort = state.sort == Sort.ascending
                      ? Sort.descending
                      : Sort.ascending;
                  bloc.add(ChangeInflationSort(newSort));
                },
              ),
            ),
          )
        else if (!isMobile) ...[
          const SizedBox(width: 8),
        ],
        if (!isMobile) ...[
          const SizedBox(width: 8),
          RotatedBox(
            quarterTurns: state.sort == Sort.ascending ? 2 : 0,
            child: MultiLevelTooltip(
              message: 'Sort Order',
              actionId: 'inflation_sort',
              description: 'Toggle between ascending and descending order',
              child: IconButton(
                icon: Icon(Icons.sort, color: onSurface),
                onPressed: () {
                  final newSort = state.sort == Sort.ascending
                      ? Sort.descending
                      : Sort.ascending;
                  bloc.add(ChangeInflationSort(newSort));
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        MultiLevelTooltip(
          message: 'Next Period',
          actionId: 'next_period',
          description: 'Move forward by one day, month, or year',
          child: IconButton(
            icon: Icon(Icons.chevron_right, color: onSurface),
            onPressed: () => _navigate(bloc, 1),
          ),
        ),
      ],
    );

    return GenericFilterAppBar(
      centerWidget: centerWidget,
      totalCountText: 'Total: ${state.totalCount}',
    );
  }

  void _showDeleteConfirmation(BuildContext context, InflationBloc bloc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Rates?'),
        content: Text(
          'Are you sure you want to delete ${state.selectedRates.length} rates?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              bloc.add(DeleteSelectedInflationRates());
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _SelectionAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int selectionCount;
  final int totalCount;
  final VoidCallback onClearSelection;
  final VoidCallback onSelectAll;
  final VoidCallback onDelete;

  const _SelectionAppBar({
    required this.selectionCount,
    required this.totalCount,
    required this.onClearSelection,
    required this.onSelectAll,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isAllSelected = selectionCount == totalCount && totalCount > 0;

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: onClearSelection,
      ),
      title: Text('$selectionCount selected'),
      actions: [
        MultiLevelTooltip(
          message: isAllSelected ? 'Deselect All' : 'Select All',
          actionId: 'inflation_selection_all',
          description: isAllSelected
              ? 'Clear all selections'
              : 'Select all visible inflation rates',
          child: IconButton(
            icon: Icon(
              isAllSelected
                  ? Icons.deselect_outlined
                  : Icons.select_all_outlined,
            ),
            onPressed: onSelectAll,
          ),
        ),
        if (selectionCount > 0)
          MultiLevelTooltip(
            message: 'Delete Selected',
            actionId: 'inflation_selection_delete',
            description:
                'Remove the selected inflation rates from the database',
            child: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: onDelete,
            ),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
