import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/account_type.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
import 'package:my_budget_client/presentation/blocs/currency/currency_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency_converter/currency_converter_bloc.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';
import 'package:my_budget_client/presentation/widgets/account_filter_dialog.dart';
import 'package:my_budget_client/presentation/widgets/account_list_item.dart';
import 'package:my_budget_client/presentation/widgets/add_account_dialog.dart';
import 'package:my_budget_client/presentation/widgets/calendar_step_picker.dart';
import 'package:my_budget_client/presentation/widgets/generic/generic_filter_app_bar.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart'
    show FilterMode, DateStep;

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

  Future<void> _showCurrencySelectionDialog(BuildContext context) async {
    final converterBloc = context.read<CurrencyConverterBloc>();
    final currentState = converterBloc.state;
    if (currentState is! CurrencyConverterLoadSuccess) return;

    final tempSelectedCurrencies =
        List<Currency>.from(currentState.selectedCurrencies);
    String searchText = '';

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final screenHeight = MediaQuery.of(context).size.height;
            final filteredCurrencies = currentState.allCurrencies.where((c) {
              return c.name.toLowerCase().contains(searchText.toLowerCase()) ||
                  c.code.toLowerCase().contains(searchText.toLowerCase());
            }).toList();

            return AlertDialog(
              title: const Text('Select Currencies'),
              content: SizedBox(
                width: double.maxFinite,
                height: screenHeight * 0.7,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      onChanged: (value) {
                        setDialogState(() {
                          searchText = value;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Search',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredCurrencies.length,
                        itemBuilder: (context, index) {
                          final currency = filteredCurrencies[index];
                          final isSelected = tempSelectedCurrencies
                              .any((c) => c.code == currency.code);
                          return CheckboxListTile(
                            title: Text('${currency.name} (${currency.code})'),
                            value: isSelected,
                            onChanged: (bool? value) {
                              setDialogState(() {
                                if (value == true) {
                                  tempSelectedCurrencies.add(currency);
                                } else {
                                  tempSelectedCurrencies.removeWhere(
                                    (c) => c.code == currency.code,
                                  );
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Clear All'),
                  onPressed: () {
                    setDialogState(() {
                      tempSelectedCurrencies.clear();
                    });
                  },
                ),
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    // Clear current selections
                    for (final currency in List<Currency>.from(
                        currentState.selectedCurrencies)) {
                      converterBloc.add(RemoveSelectedCurrency(currency));
                    }
                    // Add new selections
                    for (final currency in tempSelectedCurrencies) {
                      converterBloc.add(AddSelectedCurrency(currency));
                    }
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(
    BuildContext context,
    AccountsBloc bloc,
    List<String> accountIds,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${accountIds.length} accounts?'),
        content: const Text(
          'Are you sure you want to delete the selected accounts?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              bloc.add(DeleteMultipleAccounts(accountIds));
              Navigator.pop(dialogContext);
            },
            child: const Text('Delete'),
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
    showDialog(
      context: context,
      builder: (dialogContext) {
        String? selectedTypeId = accountTypes.first.id;
        return AlertDialog(
          title: const Text('Change Account Type'),
          content: DropdownButton<String>(
            value: selectedTypeId,
            onChanged: (newValue) {
              // This needs to be in a stateful builder to update UI
              // For simplicity, we'll just handle it on submission
              selectedTypeId = newValue;
            },
            items: accountTypes
                .map(
                  (type) =>
                      DropdownMenuItem(value: type.id, child: Text(type.name)),
                )
                .toList(),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
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
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showContextMenu(
    BuildContext context,
    Offset position,
    Account account,
    AccountsLoadSuccess state,
  ) {
    final bloc = context.read<AccountsBloc>();
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final isSelected = state.selectedAccountIds.contains(account.id);

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
        Offset.zero & overlay.size,
      ),
      items: <PopupMenuEntry<dynamic>>[
        PopupMenuItem(
          value: 'select',
          child: Text(isSelected ? 'Deselect' : 'Select'),
        ),
        const PopupMenuItem(value: 'select_all', child: Text('Select All')),
        if (state.selectedAccountIds.isNotEmpty)
          const PopupMenuItem(
            value: 'deselect_all',
            child: Text('Deselect All'),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
        const PopupMenuItem(value: 'delete', child: Text('Delete')),
        const PopupMenuItem(value: 'change_type', child: Text('Change Type')),
      ],
    ).then((value) {
      if (!mounted) return;
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
      } else if (value == 'edit') {
        context.push(AppRoutes.editAccount, extra: account);
      } else if (value == 'delete') {
        if (!mounted) return;
        _showDeleteConfirmationDialog(
          context,
          bloc,
          isSelected ? selectedIds : [account.id!],
        );
      } else if (value == 'change_type') {
        if (!mounted) return;
        _showChangeAccountTypeDialog(
          context,
          bloc,
          isSelected ? selectedIds : [account.id!],
          state.accountTypes,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final bloc = context.read<AccountsBloc>();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
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
        listener: (context, state) {
          if (state is AccountsLoadSuccess &&
              state.recentlyDeletedAccount != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    '${state.recentlyDeletedAccount!.name} deleted', // TODO: Proper localization with variable
                  ),

                  action: SnackBarAction(
                    label: 'Undo', // TODO: Localize

                    onPressed: () {
                      context.read<AccountsBloc>().add(UndoDeleteAccount());
                    },
                  ),
                ),
              );
          }
        },

        listenWhen: (previous, current) {
          return previous is AccountsLoadSuccess &&
              current is AccountsLoadSuccess &&
              previous.recentlyDeletedAccount !=
                  current.recentlyDeletedAccount &&
              current.recentlyDeletedAccount != null;
        },

        child: BlocListener<AccountsBloc, AccountsState>(
          listenWhen: (previous, current) {
            return previous is AccountsLoadSuccess &&
                current is AccountsLoadSuccess &&
                previous.activeDate != current.activeDate;
          },
          listener: (context, state) {
            if (state is AccountsLoadSuccess) {
              context
                  .read<CurrencyConverterBloc>()
                  .add(DateChanged(state.activeDate));
            }
          },
          child: Column(
            children: [
              BlocBuilder<AccountsBloc, AccountsState>(
                builder: (context, accountsState) {
                  return BlocBuilder<CurrencyConverterBloc,
                      CurrencyConverterState>(
                    builder: (context, converterState) {
                      if (accountsState is AccountsLoadSuccess &&
                          converterState is CurrencyConverterLoadSuccess) {
                        return TotalBalanceCard(
                          accountsState: accountsState,
                          converterState: converterState,
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  );
                },
              ),
              Expanded(
                child: BlocBuilder<AccountsBloc, AccountsState>(
                  builder: (context, state) {
                    if (state is AccountsLoadInProgress) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is AccountsLoadSuccess) {
                      final filteredAccounts = state.accounts;

                      if (filteredAccounts.isEmpty) {
                        return Center(child: Text(l10n.accountsEmptyState));
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        itemCount: state.hasReachedMax
                            ? filteredAccounts.length
                            : filteredAccounts.length + 1,
                        itemBuilder: (context, index) {
                          if (index >= filteredAccounts.length) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final account = filteredAccounts[index];

                          final balance = state.isHistorical
                              ? (state.historicalBalances[account.id] ??
                                    account.balance)
                              : account.balance;

                          final isSelected =
                              state.selectedAccountIds.contains(account.id);

                          final bloc = context.read<AccountsBloc>();

                          return AccountListItem(
                            account: account.copyWith(balance: balance),
                            isSelected: isSelected,
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
                          );
                        },
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,

            builder: (dialogContext) => MultiBlocProvider(
              providers: [
                BlocProvider.value(value: context.read<AccountsBloc>()),

                BlocProvider.value(value: context.read<CurrencyBloc>()),

                BlocProvider.value(value: context.read<StylesBloc>()),
              ],

              child: const AddAccountDialog(),
            ),
          );
        },

        tooltip: l10n.accountsAddTooltip,

        child: const Icon(Icons.add),
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
    final bloc = context.read<AccountsBloc>();

    final selectedCount = state.selectedAccountIds.length;

    final allCount = state.accounts.length;

    final isAllSelected = selectedCount == allCount && allCount > 0;

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),

        onPressed: () => bloc.add(const ToggleSelectionMode(false)),
      ),

      title: Text('$selectedCount selected'),

      actions: [
        IconButton(
          icon: Icon(
            isAllSelected ? Icons.deselect_outlined : Icons.select_all_outlined,
          ),

          onPressed: () {
            if (isAllSelected) {
              bloc.add(ClearSelection());
            } else {
              bloc.add(SelectAllAccounts());
            }
          },
        ),

        if (selectedCount > 0) ...[
          IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),

          IconButton(
            icon: const Icon(Icons.drive_file_rename_outline),

            onPressed: onChangeType,
          ),
        ],
      ],
    );
  }
}

class TotalBalanceCard extends StatelessWidget {
  final CurrencyConverterLoadSuccess converterState;
  final AccountsLoadSuccess accountsState;

  const TotalBalanceCard({
    required this.converterState,
    required this.accountsState,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Total Balance', // TODO: Localize
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (converterState.selectedCurrencies.isEmpty)
              const Text('No currencies selected.')
            else
              Wrap(
                spacing: 16.0,
                runSpacing: 4.0,
                children: converterState.selectedCurrencies.map((currency) {
                  final total = totalBalanceFor(
                    currency: currency,
                    accounts: accountsState.accounts,
                    exchangeRates: converterState.exchangeRates,
                    baseCurrencyCode: converterState.baseCurrencyCode,
                    date: accountsState.activeDate,
                    groupedRates: converterState.groupedRates,
                  );
                  Color balanceColor;
                  if (total > 0) {
                    balanceColor = Colors.green;
                  } else if (total < 0) {
                    balanceColor = Colors.red;
                  } else {
                    balanceColor =
                        Theme.of(context).textTheme.bodyLarge?.color ??
                            Colors.black;
                  }

                  return Text(
                    '${currency.code}: ${total.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 16, color: balanceColor),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
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
              if (state.dateStep != step) {
                bloc.add(DateStepChanged(step));
              }
              bloc.add(ActiveDateChanged(date));
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
    final centerWidget = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(
            Icons.tune,
            color: Colors.white,
          ),
          tooltip: 'Filter',
          onPressed: () {
            showAccountFilterDialog(context, state.filters);
          },
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
              _formatDate(context, state),
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: Colors.white),
          onPressed: () => bloc.add(const DatePeriodNavigated(1)),
        ),
        const SizedBox(width: 24),
        RotatedBox(
          quarterTurns: state.sortAscending ? 0 : 2,
          child: IconButton(
            icon: const Icon(
              Icons.sort,
              color: Colors.white,
            ),
            tooltip: 'Sort by Balance',
            onPressed: () {
              context.read<AccountsBloc>().add(
                    SortAccounts(!state.sortAscending),
                  );
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.calculate, color: Colors.white),
          tooltip: 'Select Currencies for Total Balance',
          onPressed: () {
            (context as Element)
                .findAncestorStateOfType<_AccountsScreenState>()!
                ._showCurrencySelectionDialog(context);
          },
        ),
      ],
    );

    return GenericFilterAppBar(
      centerWidget: centerWidget,
      totalCountText: 'Total: ${state.totalCount}',
      actions: [],
    );
  }
}