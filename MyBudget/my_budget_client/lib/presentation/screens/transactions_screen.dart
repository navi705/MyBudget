import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';
import 'package:my_budget_client/presentation/widgets/category_picker_dialog.dart';
import 'package:my_budget_client/presentation/widgets/filter_date.dart';
import 'package:my_budget_client/presentation/widgets/transaction_list.dart';
import 'package:my_budget_client/presentation/widgets/multi_level_tooltip.dart';
import 'package:my_budget_client/presentation/widgets/screen_shortcuts.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionsBloc, TransactionsState>(
      builder: (context, state) {
        final isSelectionMode = state.isSelectionModeActive;
        final selectedCount = state.selectedTransactionIds.length;

        final scaffold = Scaffold(
          appBar: isSelectionMode
              ? AppBar(
                  leading: MultiLevelTooltip(
                    message: 'Close Selection',
                    actionId: 'selection_close',
                    description: 'Exit transaction selection mode',
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        context.read<TransactionsBloc>().add(
                          const ToggleSelectionMode(false),
                        );
                      },
                    ),
                  ),
                  title: Text('$selectedCount selected'),
                  actions: [
                    MultiLevelTooltip(
                      message: 'Delete Selected',
                      actionId: 'selection_delete',
                      description:
                          'Permanently delete all selected transactions',
                      child: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Delete Transactions'),
                              content: Text(
                                'Are you sure you want to delete $selectedCount selected transactions?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    context.read<TransactionsBloc>().add(
                                      DeleteMultipleTransactions(
                                        state.selectedTransactionIds.toList(),
                                      ),
                                    );
                                    Navigator.pop(dialogContext);
                                  },
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    MultiLevelTooltip(
                      message: 'Change Date',
                      actionId: 'selection_change_date',
                      description:
                          'Update the date for all selected transactions',
                      child: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final newDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (newDate != null) {
                            context.read<TransactionsBloc>().add(
                              UpdateDateForMultipleTransactions(
                                state.selectedTransactionIds.toList(),
                                newDate,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    MultiLevelTooltip(
                      message: 'Change Category',
                      actionId: 'selection_change_category',
                      description:
                          'Update the category for all selected transactions',
                      child: IconButton(
                        icon: const Icon(Icons.category),
                        onPressed: () {
                          showCategoryPickerDialog(
                            context,
                            onCategorySelected: (categoryId) {
                              context.read<TransactionsBloc>().add(
                                UpdateCategoryForMultipleTransactions(
                                  state.selectedTransactionIds.toList(),
                                  categoryId,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                )
              : PreferredSize(
                  preferredSize: Size.fromHeight(
                    MediaQuery.of(context).size.width < 600
                        ? kToolbarHeight * 1.8
                        : kToolbarHeight,
                  ),
                  child: const FilterDate(),
                ),
          body: const TransactionList(),
          floatingActionButton: isSelectionMode
              ? null
              : MultiLevelTooltip(
                  message: 'Add Transaction',
                  actionId: 'add_action',
                  description: 'Create a new income or expense entry',
                  child: FloatingActionButton(
                    onPressed: () {
                      context.push(AppRoutes.addEditTransaction);
                    },
                    child: const Icon(Icons.add),
                  ),
                ),
        );

        return ScreenShortcuts(
          actions: {
            'add_action': () {
              if (!isSelectionMode) {
                context.push(AppRoutes.addEditTransaction);
              }
            },
            'prev_period': () => context.read<TransactionsBloc>().add(
              const DatePeriodNavigated(-1),
            ),
            'next_period': () => context.read<TransactionsBloc>().add(
              const DatePeriodNavigated(1),
            ),
          },
          child: scaffold,
        );
      },
    );
  }
}
