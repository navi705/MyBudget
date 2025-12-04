import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/domain/entities/account_type.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
import 'package:my_budget_client/presentation/blocs/currency/currency_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency_converter/currency_converter_bloc.dart';
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';
import 'package:my_budget_client/presentation/widgets/account_list_item.dart';
import 'package:my_budget_client/presentation/widgets/add_account_dialog.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final _scrollController = ScrollController();
  String? _selectedAccountTypeId; // State variable for selected account type filter
  bool _sortAscending = true; // NEW: Sorting order (ascending by default)

  @override
  void initState() {
    super.initState();
    _selectedAccountTypeId = 'all'; // 0 for 'All' accounts
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accountsAppBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate),
            tooltip: 'Select Currencies for Total Balance',
            onPressed: () => _showCurrencySelectionDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.sort), // NEW: Sorting icon
            tooltip: 'Sort by Balance', // TODO: Localize
            onPressed: () {
              setState(() {
                _sortAscending = !_sortAscending; // Toggle sorting order
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.brightness_6),
            tooltip: 'Toggle Theme', // TODO: Localize
            onPressed: () {
              final currentMode = context.read<SettingsBloc>().state.themeMode;
              final nextMode = switch (currentMode) {
                ThemeMode.system => ThemeMode.light,
                ThemeMode.light => ThemeMode.dark,
                ThemeMode.dark => ThemeMode.system,
              };
              context.read<SettingsBloc>().add(UpdateThemeMode(nextMode));
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.accountsRefreshTooltip,
            onPressed: () {
              context.read<AccountsBloc>().add(LoadAccounts());
            },
          ),
        ],
        bottom: PreferredSize( // NEW: Account type selector below AppBar
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: BlocBuilder<AccountsBloc, AccountsState>(
            builder: (context, state) {
              if (state is AccountsLoadSuccess) {
                // Create a list of all account types, including an "All" option
                final allAccountTypes = [
                   AccountType(id: 'all', name: 'All', languageCode: Localizations.localeOf(context).languageCode), // "All" option
                  ...state.accountTypes,
                ];

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    initialValue: _selectedAccountTypeId,
                    items: allAccountTypes.map((type) => DropdownMenuItem<String>(
                      value: type.id,
                      child: Text(type.name),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedAccountTypeId = value;
                      });
                    },
                  ),
                );
              }
              return const SizedBox.shrink(); // Hide dropdown if not loaded
            },
          ),
        ),
      ),
      body: BlocListener<AccountsBloc, AccountsState>(
        listener: (context, state) {
          if (state.recentlyDeletedAccount != null) {
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
          return previous.recentlyDeletedAccount != current.recentlyDeletedAccount &&
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
                    final filteredAccounts = _selectedAccountTypeId == 'all'
                        ? state.accounts
                        : state.accounts.where((acc) => acc.accountTypeId == _selectedAccountTypeId).toList();

                    if (filteredAccounts.isEmpty) {
                      return Center(
                        child: Text(l10n.accountsEmptyState),
                      );
                    }

                    // Apply sorting
                    filteredAccounts.sort((a, b) {
                      final comparison = a.balance.compareTo(b.balance);
                      return _sortAscending ? comparison : -comparison;
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
                        return AccountListItem(account: account);
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
