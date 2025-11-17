import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';
import 'package:my_budget_client/presentation/widgets/account_list_item.dart';
import 'package:my_budget_client/presentation/widgets/add_account_dialog.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accountsAppBarTitle),
        actions: [
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
      ),
      body: BlocBuilder<AccountsBloc, AccountsState>(
        builder: (context, state) {
          if (state is AccountsLoadInProgress) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (state is AccountsLoadSuccess) {
            if (state.accounts.isEmpty) {
              return Center(
                child: Text(l10n.accountsEmptyState),
              );
            }
            return ListView.builder(
              itemCount: state.accounts.length,
              itemBuilder: (context, index) {
                final account = state.accounts[index];
                return Dismissible(
                  key: ValueKey(account.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    // Dispatch the delete event immediately
                    context.read<AccountsBloc>().add(DeleteAccount(account.id!));

                    // Then, show a SnackBar with an Undo action
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text('${account.name} deleted'), // TODO: Localize
                          action: SnackBarAction(
                            label: 'Undo', // TODO: Localize
                            onPressed: () {
                              // If undo is pressed, dispatch an event to re-add the account
                              context.read<AccountsBloc>().add(AddAccount(account));
                            },
                          ),
                        ),
                      );
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
          if (state is AccountsLoadFailure) {
            return Center(
              child: Text(l10n.accountsLoadFailure),
            );
          }
          return Center(
            child: Text(l10n.accountsEmptyState),
          );
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
    );
  }
}
