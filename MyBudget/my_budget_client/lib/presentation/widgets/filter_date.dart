import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/domain/entities/transaction_type_filter.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';
import 'package:my_budget_client/presentation/widgets/advanced_filter_dialog.dart';
import 'package:my_budget_client/presentation/widgets/generic/generic_filter_app_bar.dart';
import 'package:my_budget_client/presentation/widgets/calendar_step_picker.dart';

class FilterDate extends StatelessWidget implements PreferredSizeWidget {
  const FilterDate({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  String _formatDate(TransactionsState state) {
    if (state.filterMode == FilterMode.range) {
      if (state.activeDateRange == null) return 'Select Range';
      final start =
          DateFormat('dd.MM.yyyy').format(state.activeDateRange!.start);
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

  void _showSortOptions(BuildContext context, Sort currentSort) {
    if(currentSort == Sort.ascending){
     context.read<TransactionsBloc>().add(SortChanged(Sort.descending)); 
    }
    else if(currentSort == Sort.descending){
      context.read<TransactionsBloc>().add(SortChanged(Sort.ascending));
    }
  }

  void _showDateStepPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return SimpleDialog(
          title: const Text('Выберите шаг'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(dialogContext);
                context
                    .read<TransactionsBloc>()
                    .add(const DateStepChanged(DateStep.day));
              },
              child: const Row(
                children: [
                  Icon(Icons.calendar_view_day),
                  SizedBox(width: 10),
                  Text('День'),
                ],
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(dialogContext);
                context
                    .read<TransactionsBloc>()
                    .add(const DateStepChanged(DateStep.month));
              },
              child: const Row(
                children: [
                  Icon(Icons.calendar_view_month),
                  SizedBox(width: 10),
                  Text('Месяц'),
                ],
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(dialogContext);
                context
                    .read<TransactionsBloc>()
                    .add(const DateStepChanged(DateStep.year));
              },
              child: const Row(
                children: [
                  Icon(Icons.calendar_view_week),
                  SizedBox(width: 10),
                  Text('Год'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectDateRange(
      BuildContext context, DateTimeRange? initialRange) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('ru', 'RU'),
    );
    if (picked != null && context.mounted) {
      context.read<TransactionsBloc>().add(ActiveDateRangeChanged(picked));
    }
  }

  void _showDateOptionsDialog(
      BuildContext context, TransactionsState currentState) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Выберите опцию даты'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _showDateStepPicker(context);
                },
                child: const Row(
                  children: [
                    Icon(Icons.filter_list),
                    SizedBox(width: 10),
                    Text('Выбрать шаг даты'),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _selectDateRange(context, currentState.activeDateRange);
                },
                child: const Row(
                  children: [
                    Icon(Icons.date_range),
                    SizedBox(width: 10),
                    Text('Выбрать диапазон'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionsBloc, TransactionsState>(
      builder: (context, state) {
        final bloc = context.read<TransactionsBloc>();
        final centerWidget = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.tune, color: Colors.white),
              tooltip: 'Фильтр',
              onPressed: () =>
                  showAdvancedFilterDialog(context, state.nonDateFilters),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white),
              onPressed: () => bloc.add(const DatePeriodNavigated(-1)),
            ),
            InkWell(
              onTap: () => _showCustomCalendar(context, state),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                alignment: Alignment.center,
                child: Text(
                  _formatDate(state),
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.white),
              onPressed: () => bloc.add(const DatePeriodNavigated(1)),
            ),
            RotatedBox(
              quarterTurns: state.sort == Sort.ascending ? 0 : 2,
              child: IconButton(
                icon: const Icon(Icons.sort, color: Colors.white),
                tooltip: 'Сортировка',
                onPressed: () {
                  final newSort = state.sort == Sort.ascending
                      ? Sort.descending
                      : Sort.ascending;
                  context.read<TransactionsBloc>().add(SortChanged(newSort));
                },
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
      isScrollControlled: true, // Allows the modal to be taller
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return CalendarStepPicker(
          initialDate: state.activeDate,
          initialRange: state.activeDateRange,
          initialStep: state.dateStep,
          initialFilterMode: state.filterMode,
          // Hide range option if current Step is NOT Day (optional logic)
          rangeOptionVisibility: PickerVisibility.visible, 
          onApply: (date, range, step, mode) {
            final bloc = context.read<TransactionsBloc>();
            
            // 1. Update Step if changed
            if (step != state.dateStep) {
              bloc.add(DateStepChanged(step));
            }
            
            // 2. Update Mode if changed
            if (mode != state.filterMode) {
              bloc.add(FilterModeChanged(mode));
            }

            // 3. Update Date/Range
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
