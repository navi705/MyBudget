import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/presentation/blocs/currency/currency_bloc.dart';
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/services/data_export_service.dart';
import 'package:my_budget_client/core/services/data_import_service.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';
import 'package:my_budget_client/presentation/widgets/currency_picker_dialog.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/presentation/blocs/categories/categories_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency_converter/currency_converter_bloc.dart';
import 'package:my_budget_client/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, settingsState) {
              final persistFilters =
                  settingsState.settings['persist_advanced_filters'] == 'true';
              final mainCurrencyCode =
                  settingsState.settings['main_currency_code'] ?? 'EUR';
              final defaultInflationCountry =
                  settingsState.settings['default_inflation_country'] ?? 'SRB';

              return ListView(
                children: [
                  ListTile(
                    leading: const Icon(Icons.palette),
                    title: const Text('Manage Icons'),
                    onTap: () {
                      context.push(AppRoutes.manageAccountStyles);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.brightness_6),
                    title: const Text('Manage Theme'),
                    onTap: () {
                      context.push(AppRoutes.themeSettings);
                    },
                  ),
                  BlocBuilder<CurrencyBloc, CurrencyState>(
                    builder: (context, currencyState) {
                      if (currencyState is CurrencyLoadSuccess) {
                        return ListTile(
                          leading: const Icon(Icons.money),
                          title: const Text('Main Currency'),
                          subtitle: Text(mainCurrencyCode),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            final selectedCode = await showDialog<String>(
                              context: context,
                              builder: (context) => CurrencyPickerDialog(
                                allCurrencies: currencyState.currencies,
                                selectedCurrencyCode: mainCurrencyCode,
                              ),
                            );

                            if (selectedCode != null && context.mounted) {
                              context.read<SettingsBloc>().add(
                                UpdateSetting(
                                  'main_currency_code',
                                  selectedCode,
                                ),
                              );
                            }
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.public),
                    title: const Text('Default Inflation Country'),
                    trailing: DropdownButton<String>(
                      value: defaultInflationCountry,
                      items: settingsState.countries
                          .map(
                            (country) => DropdownMenuItem(
                              value: country,
                              child: Text(country),
                            ),
                          )
                          .toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          context.read<SettingsBloc>().add(
                            UpdateSetting(
                              'default_inflation_country',
                              newValue,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.keyboard),
                    title: const Text('Hot Keys'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      context.push(AppRoutes.hotKeys);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.save),
                    title: const Text('Persist Advanced Filters'),
                    trailing: Switch(
                      value: persistFilters,
                      onChanged: (bool value) {
                        context.read<SettingsBloc>().add(
                          UpdateSetting(
                            'persist_advanced_filters',
                            value.toString(),
                          ),
                        );
                      },
                    ),
                  ),
                  if (Platform.isAndroid || Platform.isIOS)
                    ListTile(
                      leading: const Icon(Icons.sms),
                      title: const Text('SMS Import'),
                      subtitle: const Text('Import transactions from bank SMS'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        context.push(AppRoutes.smsSettings);
                      },
                    ),

                  ListTile(
                    leading: const Icon(Icons.import_export),
                    title: const Text('Import Data'),
                    onTap: () {
                      context.push(AppRoutes.importScreen);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.currency_exchange),
                    title: const Text('Import Exchange Rates (CSV/JSON)'),
                    onTap: () => _importExchangeRates(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.file_download),
                    title: const Text('Export Data'),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Export Data'),
                          content: const Text(
                            'Choose format:\n\nJSON: Full backup of all data.\nCSV: Readable report of transactions.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _exportData(context, isCsv: false);
                              },
                              child: const Text('JSON'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _exportData(context, isCsv: true);
                              },
                              child: const Text('CSV'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.api),
                    title: const Text('API Management'),
                    onTap: () {
                      context.push(AppRoutes.apiSettings);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.restore_page, color: Colors.red),
                    title: const Text(
                      'Reset Data to Defaults',
                      style: TextStyle(color: Colors.red),
                    ),
                    subtitle: const Text(
                      'This will delete all data and restore default settings.',
                    ),
                    onTap: () => _confirmResetData(context),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _exportData(BuildContext context, {required bool isCsv}) async {
    try {
      final db = GetIt.I<AppDatabase>();
      final service = DataExportService(db);
      await service.exportData(isCsv);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export completed successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  void _importExchangeRates(BuildContext context) async {
    try {
      final db = GetIt.I<AppDatabase>();
      final service = DataImportService(db);
      await service.importExchangeRates();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Import completed successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    }
  }

  void _confirmResetData(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Data?'),
        content: const Text(
          'Warning! This will delete ALL your transactions, accounts, and settings.\n\n'
          'The app will be restored to its initial state with default data.\n'
          'This action CANNOT be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog
              await _performReset(context);
            },
            child: const Text('Reset Everything'),
          ),
        ],
      ),
    );
  }

  Future<void> _performReset(BuildContext context) async {
    try {
      final db = GetIt.I<AppDatabase>();
      await db.clearAllData();

      if (context.mounted) {
        _reloadAllBlocs(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data reset and defaults restored.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Reset failed: $e')));
      }
    }
  }

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
}
