import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/account_type.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
import 'package:my_budget_client/presentation/blocs/currency/currency_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency_converter/currency_converter_bloc.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';
import 'package:my_budget_client/presentation/widgets/account_filter_dialog.dart';
import 'package:my_budget_client/presentation/widgets/account_list_item.dart';
import 'package:my_budget_client/presentation/widgets/add_account_dialog.dart';
import 'package:my_budget_client/presentation/widgets/delete_account_dialog.dart';
import 'package:my_budget_client/presentation/widgets/calendar_step_picker.dart';
import 'package:my_budget_client/presentation/widgets/generic/generic_filter_app_bar.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/presentation/widgets/total_balance_summary_widget.dart';
import 'package:my_budget_client/presentation/widgets/multi_level_tooltip.dart';
import 'package:my_budget_client/presentation/widgets/screen_shortcuts.dart';
import 'package:my_budget_client/presentation/widgets/generic/app_state_view.dart';
import 'package:my_budget_client/core/theme/app_spacing.dart';
import 'package:my_budget_client/core/utils/dialog_utils.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<AccountsBloc>().add(LoadAccounts());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<AccountsBloc>().add(LoadMoreAccounts());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    // Load more when we are at 90% of the screen
    return currentScroll >= (maxScroll * 0.9);
  }

  void _showDeleteConfirmationDialog(
    BuildContext context,
    AccountsBloc bloc,
    List<String> accountIds,
  ) {
    if (accountIds.length == 1) {
      final accountId = accountIds.first;
      final state = bloc.state;
      if (state is AccountsLoadSuccess) {
        final account = state.accounts.firstWhere((a) => a.id == accountId);
        DialogUtils.showAppDialog(
          context: context,
          resizeToAvoidBottomInset: false,
          child: DeleteAccountDialog(
            accountToDelete: account,
            allAccounts: state.accounts,
          ),
        );
      }
      return;
    }

    DialogUtils.showAppDialog(
      context: context,
      resizeToAvoidBottomInset: false,
      child: AlertDialog(
        title: Text('Delete ${accountIds.length} accounts?'),
        content: const Text(
          'Are you sure you want to delete the selected accounts? All associated transactions will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // For multiple accounts, default to cascading delete (delete w/ transactions)
              bloc.add(DeleteMultipleAccounts(accountIds));
              Navigator.of(context, rootNavigator: true).pop();
            },
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  void _showChangeAccountTypeDialog(
    BuildContext context,
    AccountsBloc bloc,
    List<String> accountIds,
    List<AccountType> accountTypes,
  ) {
    String? selectedTypeId = accountTypes.first.id;
    DialogUtils.showAppDialog(
      context: context,
      resizeToAvoidBottomInset: false,
      child: StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Change Account Type'),
            content: DropdownButton<String>(
              value: selectedTypeId,
              onChanged: (newValue) {
                setState(() {
                  selectedTypeId = newValue;
                });
              },
              items: accountTypes
                  .map(
                    (type) => DropdownMenuItem(
                      value: type.id,
                      child: Text(type.name),
                    ),
                  )
                  .toList(),
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text('Change'),
                onPressed: () {
                  if (selectedTypeId != null) {
                    bloc.add(
                      UpdateAccountTypeForMultipleAccounts(
                        accountIds,
                        selectedTypeId!,
                      ),
                    );
                  }
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showContextMenu(
    BuildContext context,
    Offset position,
    Account account,
    AccountsLoadSuccess state,
  ) async {
    final bloc = context.read<AccountsBloc>();
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final l10n = context.l10n;
    final isSelected = state.selectedAccountIds.contains(account.id);

    final value = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
        Offset.zero & overlay.size,
      ),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem(
          value: 'select',
          child: Text(
            isSelected ? l10n.contextMenuDeselect : l10n.contextMenuSelect,
          ),
        ),
        PopupMenuItem(
          value: 'select_all',
          child: Text(l10n.contextMenuSelectAll),
        ),
        if (state.selectedAccountIds.isNotEmpty)
          PopupMenuItem(
            value: 'deselect_all',
            child: Text(l10n.contextMenuDeselectAll),
          ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'add_transaction',
          child: Text(l10n.contextMenuAddTransaction),
        ),
        PopupMenuItem(value: 'transfer', child: Text(l10n.contextMenuTransfer)),
        PopupMenuItem(value: 'edit', child: Text(l10n.contextMenuEdit)),
        PopupMenuItem(
          value: 'change_type',
          child: Text(l10n.contextMenuChangeType),
        ),
        PopupMenuItem(value: 'delete', child: Text(l10n.contextMenuDelete)),
      ],
    );

    if (!context.mounted || value == null) return;
    final selectedIds = state.selectedAccountIds.toList();

    if (value == 'select') {
      if (!bloc.state.isSelectionModeActive) {
        bloc.add(const ToggleSelectionMode(true));
      }
      bloc.add(ToggleAccountSelection(account.id!));
    } else if (value == 'select_all') {
      if (!bloc.state.isSelectionModeActive) {
        bloc.add(const ToggleSelectionMode(true));
      }
      bloc.add(SelectAllAccounts());
    } else if (value == 'deselect_all') {
      bloc.add(ClearSelection());
    } else if (value == 'add_transaction') {
      context.push(
        AppRoutes.addEditTransaction,
        extra: {'accountId': account.id},
      );
    } else if (value == 'transfer') {
      context.push(
        AppRoutes.addEditTransaction,
        extra: {'accountId': account.id, 'isTransfer': true},
      );
    } else if (value == 'edit') {
      context.push(AppRoutes.editAccount, extra: account);
    } else if (value == 'delete') {
      _showDeleteConfirmationDialog(
        context,
        bloc,
        isSelected ? selectedIds : [account.id!],
      );
    } else if (value == 'change_type') {
      _showChangeAccountTypeDialog(
        context,
        bloc,
        isSelected ? selectedIds : [account.id!],
        state.accountTypes,
      );
    }
  }

  void _showEmptyAreaContextMenu(BuildContext context, Offset position) async {
    final l10n = context.l10n;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final value = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
        Offset.zero & overlay.size,
      ),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem(
          value: 'add_account',
          child: Row(
            children: [
              const Icon(Icons.add),
              const SizedBox(width: 8),
              Flexible(child: Text(l10n.addAccountDescription)),
            ],
          ),
        ),
      ],
    );

    if (!context.mounted || value == null) return;

    if (value == 'add_account') {
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
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final bloc = context.read<AccountsBloc>();

    return ScreenShortcuts(
      actions: {
        'add_action': () {
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
        },
        'prev_period': () =>
            context.read<AccountsBloc>().add(const DatePeriodNavigated(-1)),
        'next_period': () =>
            context.read<AccountsBloc>().add(const DatePeriodNavigated(1)),
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(
            MediaQuery.of(context).size.width < kMobileBreakpoint
                ? kToolbarHeight * 1.8
                : kToolbarHeight,
          ),
          child: BlocBuilder<AccountsBloc, AccountsState>(
            builder: (context, state) {
              if (state is! AccountsLoadSuccess) {
                return AppBar(title: Text(l10n.accountsAppBarTitle));
              }

              if (state.isSelectionModeActive) {
                return _SelectionAppBar(
                  state: state,
                  onDelete: () => _showDeleteConfirmationDialog(
                    context,
                    bloc,
                    state.selectedAccountIds.toList(),
                  ),
                  onChangeType: () => _showChangeAccountTypeDialog(
                    context,
                    bloc,
                    state.selectedAccountIds.toList(),
                    state.accountTypes,
                  ),
                );
              }

              return _AccountsDateAppBar(state: state);
            },
          ),
        ),

        body: BlocListener<AccountsBloc, AccountsState>(
          listenWhen: (previous, current) {
            final changed =
                previous.recentlyDeletedAccount !=
                current.recentlyDeletedAccount;
            final isNowNotNull = current.recentlyDeletedAccount != null;
            return changed && isNowNotNull;
          },
          listener: (context, state) {
            final recentlyDeleted = state.recentlyDeletedAccount;
            if (recentlyDeleted != null) {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              scaffoldMessenger.removeCurrentSnackBar();

              scaffoldMessenger
                  .showSnackBar(
                    SnackBar(
                      showCloseIcon: true,
                      closeIconColor: Colors.white,
                      duration: const Duration(seconds: 4),
                      content: Text(
                        l10n.itemDeletedMessage(recentlyDeleted.name),
                      ),
                      action: SnackBarAction(
                        label: l10n.undoButton,
                        onPressed: () {
                          context.read<AccountsBloc>().add(UndoDeleteAccount());
                        },
                      ),
                    ),
                  )
                  .closed
                  .then((reason) {
                    // Clear state on ANY reason except action (action clears it in Bloc itself)
                    if (context.mounted &&
                        reason != SnackBarClosedReason.action) {
                      context.read<AccountsBloc>().add(
                        const ClearRecentlyDeletedAccount(),
                      );
                    }
                  });
            }
          },

          child: BlocListener<AccountsBloc, AccountsState>(
            listenWhen: (previous, current) {
              return previous is AccountsLoadSuccess &&
                  current is AccountsLoadSuccess &&
                  previous.activeDate != current.activeDate;
            },
            listener: (context, state) {
              if (state is AccountsLoadSuccess) {
                context.read<CurrencyConverterBloc>().add(
                  DateChanged(state.activeDate),
                );
              }
            },
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: BlocBuilder<AccountsBloc, AccountsState>(
                    builder: (context, accountsState) {
                      return BlocBuilder<
                        CurrencyConverterBloc,
                        CurrencyConverterState
                      >(
                        builder: (context, converterState) {
                          if (accountsState is AccountsLoadSuccess &&
                              converterState is CurrencyConverterLoadSuccess) {
                            return TotalBalanceSummaryWidget(
                              accountsState: accountsState,
                              converterState: converterState,
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      );
                    },
                  ),
                ),
                BlocBuilder<AccountsBloc, AccountsState>(
                  builder: (context, state) {
                    if (state is AccountsLoadInProgress) {
                      return const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (state is AccountsLoadSuccess) {
                      final filteredAccounts = state.accounts;

                      if (filteredAccounts.isEmpty) {
                        return SliverFillRemaining(
                          child: Center(child: Text(l10n.accountsEmptyState)),
                        );
                      }

                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index >= filteredAccounts.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final account = filteredAccounts[index];

                            final balance = state.isHistorical
                                ? (state.historicalBalances[account.id] ??
                                      account.balance)
                                : account.balance;

                            final isSelected = state.selectedAccountIds
                                .contains(account.id);

                            final bloc = context.read<AccountsBloc>();

                            return AccountListItem(
                              account: account.copyWith(balance: balance),
                              assetStats: state.assetStats[account.id],
                              isSelected: isSelected,
                              realBalance: state.realBalances[account.id],
                              inflationLoss: state.inflationLosses[account.id],
                              income: state.accountIncomes[account.id],
                              expense: state.accountExpenses[account.id],
                              realIncome: state.accountRealIncomes[account.id],
                              realExpense:
                                  state.accountRealExpenses[account.id],
                              prevBalance:
                                  state.previousPeriodBalances[account.id],
                              prevIncome:
                                  state.previousAccountIncomes[account.id],
                              prevExpense:
                                  state.previousAccountExpenses[account.id],
                              prevRealBalance:
                                  state.previousPeriodRealBalances[account.id],
                              prevRealIncome:
                                  state.previousAccountRealIncomes[account.id],
                              prevRealExpense:
                                  state.previousAccountRealExpenses[account.id],
                              onTap: () {
                                if (state.isSelectionModeActive) {
                                  bloc.add(ToggleAccountSelection(account.id!));
                                } else {
                                  context.push(
                                    AppRoutes.editAccount,
                                    extra: account,
                                  );
                                }
                              },
                              onLongPress: () {
                                if (!state.isSelectionModeActive) {
                                  bloc.add(const ToggleSelectionMode(true));
                                }
                                bloc.add(ToggleAccountSelection(account.id!));
                              },
                              onSecondaryTapUp: (details) {
                                _showContextMenu(
                                  context,
                                  details.globalPosition,
                                  account,
                                  state,
                                );
                              },
                              onMenuPressed: (details) {
                                _showContextMenu(
                                  context,
                                  details.globalPosition,
                                  account,
                                  state,
                                );
                              },
                            );
                          },
                          childCount: state.hasReachedMax
                              ? filteredAccounts.length
                              : filteredAccounts.length + 1,
                        ),
                      );
                    }

                    if (state is AccountsLoadFailure) {
                      return SliverFillRemaining(
                        child: AppStateView.error(
                          message: l10n.failedToLoadData,
                          onRetry: () =>
                              context.read<AccountsBloc>().add(LoadAccounts()),
                        ),
                      );
                    }

                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  },
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onSecondaryTapUp: (details) => _showEmptyAreaContextMenu(
                      context,
                      details.globalPosition,
                    ),
                    onLongPressStart: (details) => _showEmptyAreaContextMenu(
                      context,
                      details.globalPosition,
                    ),
                    child: const SizedBox(height: 200),
                  ),
                ),
              ],
            ),
          ),
        ),

        floatingActionButton: MultiLevelTooltip(
          message: l10n.accountsAddTooltip,
          actionId: 'add_action',
          description: l10n.addAccountDescription,
          child: FloatingActionButton(
            onPressed: () {
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
            },
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}

class _SelectionAppBar extends StatelessWidget {
  final AccountsLoadSuccess state;

  final VoidCallback onDelete;

  final VoidCallback onChangeType;

  const _SelectionAppBar({
    required this.state,

    required this.onDelete,

    required this.onChangeType,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<AccountsBloc>();

    final selectedCount = state.selectedAccountIds.length;

    final allCount = state.accounts.length;

    final isAllSelected = selectedCount == allCount && allCount > 0;

    return AppBar(
      leading: MultiLevelTooltip(
        message: l10n.closeSelectionTooltip,
        actionId: 'accounts_selection_close',
        description: l10n.exitSelectionDescription,
        child: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => bloc.add(const ToggleSelectionMode(false)),
        ),
      ),
      title: Text(l10n.selectedCountLabel(selectedCount)),
      actions: [
        MultiLevelTooltip(
          message: isAllSelected
              ? l10n.contextMenuDeselectAll
              : l10n.contextMenuSelectAll,
          actionId: 'accounts_selection_all',
          description: isAllSelected
              ? l10n.contextMenuDeselectAll
              : l10n.contextMenuSelectAll,
          child: IconButton(
            icon: Icon(
              isAllSelected
                  ? Icons.deselect_outlined
                  : Icons.select_all_outlined,
            ),
            onPressed: () {
              if (isAllSelected) {
                bloc.add(ClearSelection());
              } else {
                bloc.add(SelectAllAccounts());
              }
            },
          ),
        ),
        if (selectedCount > 0) ...[
          MultiLevelTooltip(
            message: l10n.contextMenuDelete,
            actionId: 'accounts_selection_delete',
            description: l10n.deleteTransactionsDescription,
            child: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: onDelete,
            ),
          ),
          MultiLevelTooltip(
            message: l10n.contextMenuChangeType,
            actionId: 'accounts_selection_change_type',
            description: l10n.contextMenuChangeType,
            child: IconButton(
              icon: const Icon(Icons.drive_file_rename_outline),
              onPressed: onChangeType,
            ),
          ),
        ],
      ],
    );
  }
}

class _AccountsDateAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final AccountsLoadSuccess state;

  const _AccountsDateAppBar({required this.state});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  void _showCustomCalendar(BuildContext context, AccountsLoadSuccess state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the modal to be taller
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return BlocProvider.value(
          value: context.read<AccountsBloc>(),
          child: CalendarStepPicker(
            initialDate: state.activeDate,
            initialRange: null,
            initialStep: state.dateStep,
            initialFilterMode: FilterMode.date,
            rangeOptionVisibility: PickerVisibility.hidden,
            onApply: (date, range, step, mode) {
              final bloc = context.read<AccountsBloc>();

              // Adjust date to end of period if switching to Month or Year
              DateTime adjustedDate = date;
              if (step == DateStep.month) {
                adjustedDate = DateTime(
                  date.year,
                  date.month + 1,
                  0,
                  23,
                  59,
                  59,
                );
              } else if (step == DateStep.year) {
                adjustedDate = DateTime(date.year, 12, 31, 23, 59, 59);
              }

              // Single atomic event - updates both date and step
              if (state.dateStep != step) {
                bloc.add(ActiveDateChanged(adjustedDate, dateStep: step));
              } else {
                bloc.add(ActiveDateChanged(adjustedDate));
              }
            },
          ),
        );
      },
    );
  }

  String _formatDate(BuildContext context, AccountsLoadSuccess state) {
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

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AccountsBloc>();
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isMobile = MediaQuery.of(context).size.width < kMobileBreakpoint;

    final centerWidget = Row(
      mainAxisAlignment: isMobile
          ? MainAxisAlignment.spaceBetween
          : MainAxisAlignment.center,
      mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
      children: [
        MultiLevelTooltip(
          message: 'Previous Period',
          actionId: 'prev_period',
          description: 'Go to the previous month or year',
          child: IconButton(
            icon: Icon(Icons.chevron_left, color: onSurface),
            onPressed: () => bloc.add(const DatePeriodNavigated(-1)),
          ),
        ),
        if (isMobile)
          MultiLevelTooltip(
            message: 'Filter',
            actionId: 'filter_accounts',
            description: 'Filter accounts by type or hidden status',
            child: IconButton(
              icon: Icon(Icons.tune, color: onSurface),
              onPressed: () {
                showAccountFilterDialog(context, state.filters);
              },
            ),
          )
        else if (!isMobile) ...[
          MultiLevelTooltip(
            message: 'Filter',
            actionId: 'filter_accounts',
            description: 'Filter accounts by type or hidden status',
            child: IconButton(
              icon: Icon(Icons.tune, color: onSurface),
              onPressed: () {
                showAccountFilterDialog(context, state.filters);
              },
            ),
          ),
        ],
        if (!isMobile) const SizedBox(width: 8),
        Expanded(
          flex: isMobile ? 1 : 0,
          child: MultiLevelTooltip(
            message: 'Select Date',
            actionId: 'accounts_pick_date',
            description: 'Choose a specific date to view historical balances',
            child: InkWell(
              onTap: () => _showCustomCalendar(context, state),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                alignment: Alignment.center,
                child: Text(
                  _formatDate(context, state),
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
          MultiLevelTooltip(
            message: 'Sort Order',
            actionId: 'accounts_sort',
            description:
                'Switch between ascending and descending balance order',
            child: RotatedBox(
              quarterTurns: state.sortAscending ? 2 : 0,
              child: IconButton(
                icon: Icon(Icons.sort, color: onSurface),
                onPressed: () {
                  context.read<AccountsBloc>().add(
                    SortAccounts(!state.sortAscending),
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
            actionId: 'accounts_sort',
            description:
                'Switch between ascending and descending balance order',
            child: RotatedBox(
              quarterTurns: state.sortAscending ? 2 : 0,
              child: IconButton(
                icon: Icon(Icons.sort, color: onSurface),
                onPressed: () {
                  context.read<AccountsBloc>().add(
                    SortAccounts(!state.sortAscending),
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
          description: 'Go to the next month or year',
          child: IconButton(
            icon: Icon(Icons.chevron_right, color: onSurface),
            onPressed: () => bloc.add(const DatePeriodNavigated(1)),
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
