import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';
import 'package:my_budget_client/presentation/widgets/category_picker_dialog.dart';
import 'package:my_budget_client/presentation/widgets/filter_date.dart';
import 'package:my_budget_client/presentation/widgets/transaction_list.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionsBloc, TransactionsState>(
      builder: (context, state) {
        final isSelectionMode = state.isSelectionModeActive;
        final selectedCount = state.selectedTransactionIds.length;

        return Scaffold(
          appBar: isSelectionMode
              ? AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      context
                          .read<TransactionsBloc>()
                          .add(const ToggleSelectionMode(false));
                    },
                  ),
                  title: Text('$selectedCount selected'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('Delete Transactions'),
                            content: Text(
                                'Are you sure you want to delete $selectedCount selected transactions?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  context.read<TransactionsBloc>().add(
                                      DeleteMultipleTransactions(state
                                          .selectedTransactionIds
                                          .toList()));
                                  Navigator.pop(dialogContext);
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    IconButton(
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
                                  newDate));
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.category),
                      onPressed: () {
                        showCategoryPickerDialog(
                          context,
                          onCategorySelected: (categoryId) {
                            context.read<TransactionsBloc>().add(
                                UpdateCategoryForMultipleTransactions(
                                    state.selectedTransactionIds.toList(),
                                    categoryId));
                          },
                        );
                      },
                    ),
                  ],
                )
              : FilterDate(),
          body: TransactionList(),
          floatingActionButton: isSelectionMode
              ? null
              : FloatingActionButton(
                  onPressed: () {
                    context.push(AppRoutes.addEditTransaction);
                  },
                  child: const Icon(Icons.add),
                ),
        );
      },
    );
  }
}
