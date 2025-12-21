import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';
import 'package:my_budget_client/presentation/widgets/advanced_filter_dialog.dart';

class FilterDate extends StatelessWidget implements PreferredSizeWidget {
  const FilterDate({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  String _formatDate(TransactionsState state) {
    if (state.filterMode == FilterMode.range) {
      if (state.activeDateRange == null) return 'Select Range';
      final start = DateFormat('dd.MM.yyyy').format(state.activeDateRange!.start);
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
                context.read<TransactionsBloc>().add(const DateStepChanged(DateStep.day));
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
                context.read<TransactionsBloc>().add(const DateStepChanged(DateStep.month));
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
                context.read<TransactionsBloc>().add(const DateStepChanged(DateStep.year));
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

  Future<void> _selectDateRange(BuildContext context, DateTimeRange? initialRange) async {
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

  void _showDateOptionsDialog(BuildContext context, TransactionsState currentState) {
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
    return Container(
      height: preferredSize.height,
      color: Theme.of(context).appBarTheme.backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: BlocBuilder<TransactionsBloc, TransactionsState>(
        builder: (context, state) {
          return Stack(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                    onPressed: () => context.read<TransactionsBloc>().add(const DatePeriodNavigated(-1)),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.tune, color: Colors.white),
                        tooltip: 'Фильтр',
                        onPressed: () {
                          showAdvancedFilterDialog(context, state.nonDateFilters);
                        },
                      ),
                      SizedBox(
                        width: 40,
                        child: TextButton(
                          onPressed: () => _showDateStepPicker(context),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: const CircleBorder(),
                          ),
                          child: Text(
                            state.dateStep.name[0].toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      IntrinsicWidth(
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _showDateOptionsDialog(context, state),
                                hoverColor: Colors.white.withAlpha(25),
                                borderRadius: BorderRadius.circular(4.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                                  alignment: Alignment.center,
                                  child: Text(
                                    _formatDate(state),
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 18),
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.calendar_today, color: Colors.white),
                              onPressed: () => _selectDate(context, state.activeDate),
                              tooltip: 'Выбрать дату',
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.sort, color: Colors.white),
                        tooltip: 'Сортировка',
                        onPressed: () => _showSortOptions(context, state.sort),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
                    onPressed: () => context.read<TransactionsBloc>().add(const DatePeriodNavigated(1)),
                  ),
                ],
              ),
              Positioned(
                left: 50,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Text(
                    'Всего: ${state.totalCount}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
