import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';
import 'package:my_budget_client/presentation/widgets/advanced_filter_dialog.dart';
import 'package:my_budget_client/presentation/widgets/generic/generic_filter_app_bar.dart';

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
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return SimpleDialog(
          title: const Text('Сортировка по дате'),
          children: <Widget>[
            RadioListTile<Sort>(
              title: const Text('По убыванию (новые сверху)'),
              value: Sort.descending,
              groupValue: currentSort,
              onChanged: (Sort? value) {
                if (value != null) {
                  context.read<TransactionsBloc>().add(SortChanged(value));
                  Navigator.pop(dialogContext);
                }
              },
            ),
            RadioListTile<Sort>(
              title: const Text('По возрастанию (старые сверху)'),
              value: Sort.ascending,
              groupValue: currentSort,
              onChanged: (Sort? value) {
                if (value != null) {
                  context.read<TransactionsBloc>().add(SortChanged(value));
                  Navigator.pop(dialogContext);
                }
              },
            ),
          ],
        );
      },
    );
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

  Future<void> _selectDate(BuildContext context, DateTime initialDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('ru', 'RU'),
    );
    if (picked != null && context.mounted) {
      context.read<TransactionsBloc>().add(ActiveDateChanged(picked));
    }
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
                  _selectDate(context, currentState.activeDate);
                },
                child: const Row(
                  children: [
                    Icon(Icons.calendar_today),
                    SizedBox(width: 10),
                    Text('Выбрать день'),
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
        return GenericFilterAppBar(
          title: _formatDate(state),
          totalCountText: 'Всего: ${state.transactions.length}',
          dateStepText: state.dateStep.name[0].toUpperCase(),
          onNavigatePrevious: () =>
              context.read<TransactionsBloc>().add(const DatePeriodNavigated(-1)),
          onNavigateNext: () =>
              context.read<TransactionsBloc>().add(const DatePeriodNavigated(1)),
          onOpenAdvancedFilter: () {
            showAdvancedFilterDialog(context, state.nonDateFilters);
          },
          onShowSortOptions: () => _showSortOptions(context, state.sort),
          onShowDateStepPicker: () => _showDateStepPicker(context),
          onShowDateOptionsDialog: () => _showDateOptionsDialog(context, state),
          onSelectDate: () => _selectDate(context, state.activeDate),
        );
      },
    );
  }
}
