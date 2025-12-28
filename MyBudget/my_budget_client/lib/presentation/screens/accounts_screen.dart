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
import 'package:my_budget_client/presentation/widgets/account_list_item.dart';
import 'package:my_budget_client/presentation/widgets/add_account_dialog.dart';
import 'package:my_budget_client/presentation/widgets/generic/generic_filter_app_bar.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final _scrollController = ScrollController();
  final _dropdownFocusNode = FocusNode();

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
    _dropdownFocusNode.dispose();
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

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Currencies'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: currentState.allCurrencies.map((currency) {
                    final isSelected =
                        tempSelectedCurrencies.any((c) => c.code == currency.code);
                    return CheckboxListTile(
                      title: Text('${currency.name} (${currency.code})'),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            tempSelectedCurrencies.add(currency);
                          } else {
                            tempSelectedCurrencies
                                .removeWhere((c) => c.code == currency.code);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    // Clear current selections
                    for (final currency
                        in List<Currency>.from(currentState.selectedCurrencies)) {
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && context.mounted) {
      context.read<AccountsBloc>().add(LoadHistoricalBalances(picked));
    }
  }

  void _showDeleteConfirmationDialog(
      BuildContext context, AccountsBloc bloc, List<String> accountIds) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${accountIds.length} accounts?'),
        content:
            const Text('Are you sure you want to delete the selected accounts?'),
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

  void _showChangeAccountTypeDialog(BuildContext context, AccountsBloc bloc,
      List<String> accountIds, List<AccountType> accountTypes) {
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
                .map((type) => DropdownMenuItem(
                      value: type.id,
                      child: Text(type.name),
                    ))
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
                  bloc.add(UpdateAccountTypeForMultipleAccounts(
                      accountIds, selectedTypeId!));
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
        const PopupMenuItem(
          value: 'select_all',
          child: Text('Select All'),
        ),
        if (state.selectedAccountIds.isNotEmpty)
          const PopupMenuItem(
            value: 'deselect_all',
            child: Text('Deselect All'),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'edit',
          child: Text('Edit'),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Text('Delete'),
        ),
        const PopupMenuItem(
          value: 'change_type',
          child: Text('Change Type'),
        ),
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
        _showDeleteConfirmationDialog(
            context, bloc, isSelected ? selectedIds : [account.id!]);
      } else if (value == 'change_type') {
        _showChangeAccountTypeDialog(context, bloc,
            isSelected ? selectedIds : [account.id!], state.accountTypes);
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
                      context, bloc, state.selectedAccountIds.toList()),
                  onChangeType: () => _showChangeAccountTypeDialog(context,
                      bloc, state.selectedAccountIds.toList(), state.accountTypes),
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

                previous.recentlyDeletedAccount != current.recentlyDeletedAccount &&

                current.recentlyDeletedAccount != null;

          },

          child: Column(

            children: [

              BlocBuilder<CurrencyConverterBloc, CurrencyConverterState>(

                builder: (context, state) {

                  if (state is CurrencyConverterLoadSuccess) {

                    return TotalBalanceCard(state: state);

                  }

                  return const SizedBox.shrink();

                },

              ),

              Expanded(

                child: BlocBuilder<AccountsBloc, AccountsState>(

                  builder: (context, state) {

                    if (state is AccountsLoadInProgress) {

                      return const Center(

                        child: CircularProgressIndicator(),

                      );

                    }

                    if (state is AccountsLoadSuccess) {

                      // Filter accounts based on selected type

                      final filteredAccounts = state.selectedAccountTypeId == 'all'

                          ? state.accounts

                          : state.accounts

                              .where((acc) =>

                                  acc.accountTypeId == state.selectedAccountTypeId)

                              .toList();

  

                      if (filteredAccounts.isEmpty) {

                        return Center(

                          child: Text(l10n.accountsEmptyState),

                        );

                      }

  

                      // Apply sorting

                      filteredAccounts.sort((a, b) {

                        final balanceA = state.isHistorical

                            ? (state.historicalBalances[a.id] ?? a.balance)

                            : a.balance;

                        final balanceB = state.isHistorical

                            ? (state.historicalBalances[b.id] ?? b.balance)

                            : b.balance;

                        final comparison = balanceA.compareTo(balanceB);

                        return state.sortAscending ? comparison : -comparison;

                      });

  

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

                                context.push(AppRoutes.editAccount,

                                    extra: account);

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

                                  context, details.globalPosition, account, state);

                            },

                          );

                        },

                      );

                    }

                    return const SizedBox.shrink(); // Fallback for other states

                  },

                ),

              ),

            ],

          ),

        ),

        floatingActionButton: FloatingActionButton(

          onPressed: () {

            showDialog(

              context: context,

              builder: (dialogContext) => MultiBlocProvider(

                providers: [

                  BlocProvider.value(

                    value: context.read<AccountsBloc>(),

                  ),

                  BlocProvider.value(

                    value: context.read<CurrencyBloc>(),

                  ),

                  BlocProvider.value(

                    value: context.read<StylesBloc>(),

                  ),

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

  

  class _DateNavigationWidget extends StatelessWidget {
    final DateTime activeDate;
    final DateStep dateStep;
    final ValueChanged<DateStep?> onDateStepChanged;

    const _DateNavigationWidget({
      required this.activeDate,
      required this.dateStep,
      required this.onDateStepChanged,
    });

    String _formatDate(BuildContext context) {
      switch (dateStep) {
        case DateStep.day:
          return MaterialLocalizations.of(context).formatShortDate(activeDate);
        case DateStep.month:
          return MaterialLocalizations.of(context).formatMonthYear(activeDate);
        case DateStep.year:
          return activeDate.year.toString();
      }
    }

    @override
    Widget build(BuildContext context) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DropdownButton<DateStep>(
            value: dateStep,
            onChanged: onDateStepChanged,
            items: DateStep.values
                .map((step) => DropdownMenuItem(
                      value: step,
                      child: Text(step.name,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14)),
                    ))
                .toList(),
            dropdownColor: Theme.of(context).appBarTheme.backgroundColor,
            underline: Container(),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Text(
            _formatDate(context),
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      );
    }
  }

  

  class _SelectionAppBar extends StatelessWidget {

    final AccountsLoadSuccess state;

    final VoidCallback onDelete;

    final VoidCallback onChangeType;

  

    const _SelectionAppBar(

        {required this.state,

        required this.onDelete,

        required this.onChangeType});

  

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

            icon: Icon(isAllSelected

                ? Icons.deselect_outlined

                : Icons.select_all_outlined),

            onPressed: () {

              if (isAllSelected) {

                bloc.add(ClearSelection());

              } else {

                bloc.add(SelectAllAccounts());

              }

            },

          ),

          if (selectedCount > 0) ...[

            IconButton(

              icon: const Icon(Icons.delete),

              onPressed: onDelete,

            ),

            IconButton(

              icon: const Icon(Icons.drive_file_rename_outline),

              onPressed: onChangeType,

            ),

          ]

        ],

      );

    }

  }

  

  class TotalBalanceCard extends StatelessWidget {

    final CurrencyConverterLoadSuccess state;

    const TotalBalanceCard({required this.state, super.key});

  

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

              if (state.selectedCurrencies.isEmpty)

                const Text('No currencies selected.')

              else

                ...state.selectedCurrencies.map((currency) {

                  final total = state.totalBalanceFor(currency);

                  return Padding(

                    padding: const EdgeInsets.symmetric(vertical: 4.0),

                    child: Text(

                      '${currency.code}: ${total.toStringAsFixed(2)}',

                      style: const TextStyle(fontSize: 16),

                    ),

                  );

                })

            ],

          ),

        ),

      );

    }

  }

class _AccountsDateAppBar extends StatelessWidget implements PreferredSizeWidget {
  final AccountsLoadSuccess state;

  const _AccountsDateAppBar({required this.state});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  void _showDateStepPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return SimpleDialog(
          title: const Text('Select Step'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(dialogContext);
                context
                    .read<AccountsBloc>()
                    .add(const DateStepChanged(DateStep.day));
              },
              child: const Row(
                children: [
                  Icon(Icons.calendar_view_day),
                  SizedBox(width: 10),
                  Text('Day'),
                ],
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(dialogContext);
                context
                    .read<AccountsBloc>()
                    .add(const DateStepChanged(DateStep.month));
              },
              child: const Row(
                children: [
                  Icon(Icons.calendar_view_month),
                  SizedBox(width: 10),
                  Text('Month'),
                ],
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(dialogContext);
                context
                    .read<AccountsBloc>()
                    .add(const DateStepChanged(DateStep.year));
              },
              child: const Row(
                children: [
                  Icon(Icons.calendar_view_week),
                  SizedBox(width: 10),
                  Text('Year'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(BuildContext context, AccountsLoadSuccess state) {
    switch (state.dateStep) {
      case DateStep.day:
        return MaterialLocalizations.of(context).formatShortDate(state.activeDate);
      case DateStep.month:
        return MaterialLocalizations.of(context).formatMonthYear(state.activeDate);
      case DateStep.year:
        return state.activeDate.year.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AccountsBloc>();
    final accountTypeDropdown = DropdownButtonHideUnderline(
      child: Focus(
        canRequestFocus: false,
        child: DropdownButton<String>(
          value: state.selectedAccountTypeId,
          items: [
            AccountType(
                id: 'all',
                name: 'All',
                languageCode:
                    Localizations.localeOf(context).languageCode),
            ...state.accountTypes,
          ]
              .map((type) => DropdownMenuItem<String>(
                    value: type.id,
                    child: Text(type.name,
                        style: const TextStyle(color: Colors.white)),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              bloc.add(FilterAccounts(value));
            }
          },
          dropdownColor:
              Theme.of(context).appBarTheme.backgroundColor,
          icon:
              const Icon(Icons.arrow_drop_down, color: Colors.white),
        ),
      ),
    );

    final centerWidget = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () async {
             final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: state.activeDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
            );
            if (picked != null && context.mounted) {
              context
                  .read<AccountsBloc>()
                  .add(ActiveDateChanged(picked));
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            alignment: Alignment.center,
            child: Text(
              _formatDate(context, state),
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ),
        const SizedBox(width: 24),
        accountTypeDropdown,
      ],
    );

    return GenericFilterAppBar(
      onNavigatePrevious: () => bloc.add(const DatePeriodNavigated(-1)),
      onNavigateNext: () => bloc.add(const DatePeriodNavigated(1)),
      centerWidget: centerWidget,
      totalCountText: 'Total: ${state.totalCount}',
      actions: [
        if (state.isHistorical)
          IconButton(
            icon: const Icon(Icons.clear, color: Colors.white),
            tooltip: 'Clear Date Filter',
            onPressed: () {
              context
                  .read<AccountsBloc>()
                  .add(ClearHistoricalBalances());
            },
          ),
        IconButton(
          icon: const Icon(Icons.calculate, color: Colors.white),
          tooltip: 'Select Currencies for Total Balance',
          onPressed: () {
            (context as Element).findAncestorStateOfType<_AccountsScreenState>()!
                ._showCurrencySelectionDialog(context);
          }
        ),
        IconButton(
          icon: Icon(
            state.sortAscending
                ? Icons.arrow_upward
                : Icons.arrow_downward,
            color: Colors.white,
          ),
          tooltip: 'Sort by Balance',
          onPressed: () {
            context
                .read<AccountsBloc>()
                .add(SortAccounts(!state.sortAscending));
          },
        ),
      ],
    );
  }
}


  