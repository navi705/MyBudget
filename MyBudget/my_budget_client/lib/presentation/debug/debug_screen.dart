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
    context.read<TransactionsBloc>().add(const InnitialLoadTransactions()); //TODO remove direction scroll
  }

  @override
  Widget build(BuildContext context) {
    //final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Menu'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () async {
                  await DebugDataSeeder.clearAllData();
                  if (!context.mounted) return;
                  _reloadAllBlocs(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'All data cleared and re-seeded with defaults.')),
                  );
                },
                child: const Text('Clear All Data (and re-seed defaults)'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await DebugDataSeeder.seedMinimumData();
                  if (!context.mounted) return;
                  _reloadAllBlocs(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Minimum data seeded.')),
                  );
                },
                child: const Text('Seed Minimum Data'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await DebugDataSeeder.seedMediumData();
                  if (!context.mounted) return;
                  _reloadAllBlocs(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Medium data seeded.')),
                  );
                },
                child: const Text('Seed Medium Data'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await DebugDataSeeder.seedMaximumData();
                  if (!context.mounted) return;
                  _reloadAllBlocs(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Maximum data seeded.')),
                  );
                },
                child: const Text('Seed Maximum Data (for performance test)'),
              ),
              const SizedBox(height: 16),
              if (kDebugMode) // Example of debug mode check
                Text(
                  'Running in DEBUG mode',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
