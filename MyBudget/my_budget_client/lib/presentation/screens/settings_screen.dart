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

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocBuilder<SettingsBloc, SettingsState>(
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
                title: const Text('Manage Account Styles'),
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
                      trailing: DropdownButton<String>(
                        value: mainCurrencyCode,
                        items: currencyState.currencies
                            .map(
                              (currency) => DropdownMenuItem(
                                value: currency.code,
                                child: Text(currency.code),
                              ),
                            )
                            .toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            context.read<SettingsBloc>().add(
                              UpdateSetting('main_currency_code', newValue),
                            );
                          }
                        },
                      ),
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
                        UpdateSetting('default_inflation_country', newValue),
                      );
                    }
                  },
                ),
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
            ],
          );
        },
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
}
