import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/presentation/blocs/inflation/inflation_bloc.dart';
import 'package:my_budget_client/presentation/widgets/calendar_step_picker.dart';
import 'package:my_budget_client/presentation/widgets/generic/generic_filter_app_bar.dart';
import 'package:my_budget_client/presentation/widgets/inflation_filter_dialog.dart';

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

    final centerWidget = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.tune, color: onSurface),
          tooltip: 'Filter',
          onPressed: () => showInflationFilterDialog(context),
        ),
        IconButton(
          icon: Icon(Icons.chevron_left, color: onSurface),
          onPressed: () => _navigate(bloc, -1),
        ),
        InkWell(
          onTap: () => _showCustomCalendar(context),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            alignment: Alignment.center,
            child: Text(
              _formatDate(context),
              style: TextStyle(color: onSurface, fontSize: 18),
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.chevron_right, color: onSurface),
          onPressed: () => _navigate(bloc, 1),
        ),
        const SizedBox(width: 24),
        RotatedBox(
          quarterTurns: state.sort == Sort.ascending ? 2 : 0,
          child: IconButton(
            icon: Icon(Icons.sort, color: onSurface),
            tooltip: 'Sort',
            onPressed: () {
              final newSort = state.sort == Sort.ascending
                  ? Sort.descending
                  : Sort.ascending;
              bloc.add(ChangeInflationSort(newSort));
            },
          ),
        ),
      ],
    );

    return GenericFilterAppBar(
      centerWidget: centerWidget,
      totalCountText: 'Total: ${state.totalCount}',
    );
  }
}
