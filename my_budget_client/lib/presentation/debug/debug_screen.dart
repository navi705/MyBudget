import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
//import 'package:my_budget_client/l10n/app_localizations.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/presentation/blocs/categories/categories_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency/currency_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency_converter/currency_converter_bloc.dart';
import 'package:my_budget_client/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';
import 'package:my_budget_client/presentation/debug/debug_data_seeder.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';

class DebugScreen extends StatelessWidget {
  const DebugScreen({super.key});

  void _reloadAllBlocs(BuildContext context) {
    context.read<AccountsBloc>().add(LoadAccounts());
    context.read<CategoriesBloc>().add(LoadCategories());
    context.read<CurrencyBloc>().add(LoadCurrencies());
    context.read<CurrencyConverterBloc>().add(LoadCurrencyConverter());
    context.read<DashboardBloc>().add(LoadDashboard());
    context.read<SettingsBloc>().add(LoadSettings());
    context.read<StylesBloc>().add(LoadStyles());
    context.read<TransactionsBloc>().add(const InitialLoadTransactions());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.debugMenuLabel)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.tonal(
                onPressed: () async {
                  await DebugDataSeeder.clearAllData();
                  if (!context.mounted) return;
                  _reloadAllBlocs(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.debugAllDataClearedMessage),
                    ),
                  );
                },
                child: Text(context.l10n.debugClearAllDataLabel),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () async {
                  await DebugDataSeeder.seedMinimumData();
                  if (!context.mounted) return;
                  _reloadAllBlocs(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.debugMinimumDataSeededMessage),
                    ),
                  );
                },
                child: Text(context.l10n.debugSeedMinimumDataLabel),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () async {
                  await DebugDataSeeder.seedMediumData();
                  if (!context.mounted) return;
                  _reloadAllBlocs(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.debugMediumDataSeededMessage),
                    ),
                  );
                },
                child: Text(context.l10n.debugSeedMediumDataLabel),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () async {
                  await DebugDataSeeder.seedMaximumData();
                  if (!context.mounted) return;
                  _reloadAllBlocs(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.debugMaximumDataSeededMessage),
                    ),
                  );
                },
                child: Text(context.l10n.debugSeedMaximumDataLabel),
              ),
              const SizedBox(height: 16),
              if (kDebugMode) // Example of debug mode check
                Text(
                  context.l10n.debugRunningInDebugModeLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
