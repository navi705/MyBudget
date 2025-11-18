import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/domain/entities/account_type.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';
import 'package:my_budget_client/presentation/widgets/account_list_item.dart';
import 'package:my_budget_client/presentation/widgets/add_account_dialog.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  int? _selectedAccountTypeId; // State variable for selected account type filter
  bool _sortAscending = true; // NEW: Sorting order (ascending by default)

  @override
  void initState() {
    super.initState();
    _selectedAccountTypeId = 0; // 0 for 'All' accounts
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocListener<AccountsBloc, AccountsState>(
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
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.accountsAppBarTitle),
          actions: [
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
                    const AccountType(id: 0, name: 'All'), // "All" option
                    ...state.accountTypes,
                  ];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: DropdownButtonFormField<int>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      initialValue: _selectedAccountTypeId,
                      items: allAccountTypes.map((type) => DropdownMenuItem<int>(
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
        body: BlocBuilder<AccountsBloc, AccountsState>(
          builder: (context, state) {
            if (state is AccountsLoadInProgress) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (state is AccountsLoadSuccess) {
              // Filter accounts based on selected type
              final filteredAccounts = _selectedAccountTypeId == 0
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
                itemCount: filteredAccounts.length,
                itemBuilder: (context, index) {
                  final account = filteredAccounts[index];
                  return Dismissible(
                    key: ValueKey(account.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) {
                      context.read<AccountsBloc>().add(DeleteAccount(account.id!));
                    },
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: AccountListItem(account: account),
                  );
                },
              );
            }
            return const SizedBox.shrink(); // Fallback for other states
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (dialogContext) => BlocProvider.value(
                value: BlocProvider.of<AccountsBloc>(context),
                child: const AddAccountDialog(),
              ),
            );
          },
          tooltip: l10n.accountsAddTooltip,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
