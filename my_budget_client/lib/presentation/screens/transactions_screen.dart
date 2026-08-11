import 'package:flutter/material.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
// Both bloc libraries export ToggleSelectionMode and DatePeriodNavigated, and
// every use of those names on this screen belongs to the transactions bloc.
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart'
    show AccountsBloc, AccountsLoadSuccess, AccountsState;
import 'package:my_budget_client/presentation/blocs/currency/currency_bloc.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';
import 'package:my_budget_client/presentation/widgets/add_account_dialog.dart';
import 'package:my_budget_client/presentation/widgets/category_picker_dialog.dart';
import 'package:my_budget_client/presentation/widgets/filter_date.dart';
import 'package:my_budget_client/presentation/widgets/transaction_list.dart';
import 'package:my_budget_client/presentation/widgets/multi_level_tooltip.dart';
import 'package:my_budget_client/presentation/widgets/screen_shortcuts.dart';
import 'package:my_budget_client/core/utils/dialog_utils.dart';
import 'package:my_budget_client/core/theme/app_spacing.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  /// True once the accounts have actually loaded and there are none.
  ///
  /// Every other [AccountsState] reports an empty list while the load is still
  /// running, so treating "empty" as "no accounts" everywhere would flip the
  /// button under the user on the first frame of a normal launch.
  static bool _hasNoAccounts(AccountsState state) =>
      state is AccountsLoadSuccess && state.accounts.isEmpty;

  /// The "+" entry point, shared by the button and the hotkey.
  ///
  /// Nothing seeds an account, Account is required on the transaction form and
  /// its picker is fed from the same empty list, so on a fresh install the form
  /// could be opened but never saved - Back was the only way out. Those users
  /// get account creation instead, which is what the form was waiting for.
  void _startAddFlow(BuildContext context) {
    if (_hasNoAccounts(context.read<AccountsBloc>().state)) {
      _showAddAccountDialog(context);
      return;
    }
    context.push(AppRoutes.addEditTransaction);
  }

  void _showAddAccountDialog(BuildContext context) {
    DialogUtils.showAppDialog(
      context: context,
      resizeToAvoidBottomInset: false,
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<AccountsBloc>()),
          BlocProvider.value(value: context.read<CurrencyBloc>()),
          BlocProvider.value(value: context.read<StylesBloc>()),
        ],
        child: const AddAccountDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionsBloc, TransactionsState>(
      builder: (context, state) {
        final isSelectionMode = state.isSelectionModeActive;
        final selectedCount = state.selectedTransactionIds.length;

        final l10n = context.l10n;
        final scaffold = Scaffold(
          appBar: isSelectionMode
              ? AppBar(
                  leading: MultiLevelTooltip(
                    message: l10n.closeSelectionTooltip,
                    actionId: 'selection_close',
                    description: l10n.exitTransactionsSelectionDescription,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        context.read<TransactionsBloc>().add(
                          const ToggleSelectionMode(false),
                        );
                      },
                    ),
                  ),
                  title: Text(
                    l10n.selectedCountLabel(selectedCount.toString()),
                  ),
                  actions: [
                    MultiLevelTooltip(
                      message: l10n.contextMenuDelete,
                      actionId: 'selection_delete',
                      description: l10n.deleteTransactionsDescription,
                      child: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          DialogUtils.showAppDialog(
                            context: context,
                            resizeToAvoidBottomInset: false,
                            child: AlertDialog(
                              title: Text(
                                l10n.deleteTransactionsConfirmationTitle,
                              ),
                              content: Text(
                                l10n.deleteTransactionsConfirmationMessage(
                                  selectedCount.toString(),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).pop(),
                                  child: Text(l10n.cancelButton),
                                ),
                                TextButton(
                                  onPressed: () {
                                    context.read<TransactionsBloc>().add(
                                      DeleteMultipleTransactions(
                                        state.selectedTransactionIds.toList(),
                                      ),
                                    );
                                    Navigator.of(
                                      context,
                                      rootNavigator: true,
                                    ).pop();
                                  },
                                  child: Text(l10n.deleteButton),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    MultiLevelTooltip(
                      message: l10n.changeDateTooltip,
                      actionId: 'selection_change_date',
                      description: l10n.changeDateDescription,
                      child: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final newDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (newDate != null && context.mounted) {
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
                      message: l10n.changeCategoryTooltip,
                      actionId: 'selection_change_category',
                      description: l10n.changeCategoryDescription,
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
                    MediaQuery.of(context).size.width < kMobileBreakpoint
                        ? kToolbarHeight * 1.8
                        : kToolbarHeight,
                  ),
                  child: const FilterDate(),
                ),
          body: BlocListener<TransactionsBloc, TransactionsState>(
            listenWhen: (previous, current) {
              final changed =
                  previous.recentlyDeletedTransactions !=
                  current.recentlyDeletedTransactions;
              final isNowNotEmpty =
                  current.recentlyDeletedTransactions != null &&
                  current.recentlyDeletedTransactions!.isNotEmpty;
              return changed && isNowNotEmpty;
            },
            listener: (context, state) {
              final txs = state.recentlyDeletedTransactions!;
              final name = txs.length == 1
                  ? (txs.first.description.isNotEmpty
                        ? txs.first.description
                        : 'Transaction')
                  : l10n.selectedCountLabel(txs.length.toString());

              final scaffoldMessenger = ScaffoldMessenger.of(context);
              scaffoldMessenger.removeCurrentSnackBar();

              scaffoldMessenger
                  .showSnackBar(
                    SnackBar(
                      showCloseIcon: true,
                      closeIconColor: Colors.white,
                      duration: const Duration(seconds: 4),
                      content: Text(l10n.itemDeletedMessage(name)),
                      action: SnackBarAction(
                        label: l10n.undoButton,
                        onPressed: () {
                          context.read<TransactionsBloc>().add(
                            const UndoDeleteTransactions(),
                          );
                        },
                      ),
                    ),
                  )
                  .closed
                  .then((reason) {
                    if (context.mounted &&
                        reason != SnackBarClosedReason.action) {
                      context.read<TransactionsBloc>().add(
                        const ClearRecentlyDeletedTransactions(),
                      );
                    }
                  });
            },
            child: const TransactionList(),
          ),
          floatingActionButton: isSelectionMode
              ? null
              : BlocBuilder<AccountsBloc, AccountsState>(
                  builder: (context, accountsState) {
                    final needsAccount = _hasNoAccounts(accountsState);
                    return MultiLevelTooltip(
                      message: needsAccount
                          ? l10n.accountsAddTooltip
                          : l10n.contextMenuAddTransaction,
                      actionId: 'add_action',
                      description: needsAccount
                          ? l10n.addAccountBeforeTransactionDescription
                          : l10n.addTransactionDescription,
                      child: FloatingActionButton(
                        onPressed: () => _startAddFlow(context),
                        child: const Icon(Icons.add),
                      ),
                    );
                  },
                ),
        );

        return ScreenShortcuts(
          actions: {
            'add_action': () {
              if (!isSelectionMode) {
                _startAddFlow(context);
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
