import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/core/di/injection_container.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
import 'package:my_budget_client/core/utils/country_codes.dart';
import 'package:my_budget_client/domain/entities/inflation_rate.dart';
import 'package:my_budget_client/presentation/widgets/country_picker_dialog.dart';
import 'package:my_budget_client/presentation/blocs/inflation/inflation_bloc.dart';
import 'package:my_budget_client/presentation/widgets/screen_shortcuts.dart';
import 'package:my_budget_client/presentation/widgets/inflation_tab_app_bar.dart';
import 'package:my_budget_client/presentation/widgets/inflation_view.dart';
import 'package:my_budget_client/presentation/widgets/multi_level_tooltip.dart';

class InflationTab extends StatelessWidget {
  const InflationTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<InflationBloc>()..add(LoadInflationRates()),
      child: const _InflationTabContent(),
    );
  }
}

class _InflationTabContent extends StatelessWidget {
  const _InflationTabContent();

  void _showAddEditInflationDialog(
    BuildContext context, {
    InflationRateDomain? rate,
  }) {
    final bloc = context.read<InflationBloc>();
    final l10n = context.l10n;
    final percentController = TextEditingController(
      text: rate?.percent.toString() ?? '',
    );
    String? selectedCountry = rate?.country;
    String? percentError;
    final presetController = TextEditingController(
      text: rate?.preset.toString() ?? '1',
    );
    DateTime selectedDate = rate?.date ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            rate == null ? l10n.inflationAddRate : l10n.inflationEditRate,
          ),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 250),
              child: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: percentController,
                      decoration: InputDecoration(
                        labelText: l10n.inflationPercentLabel,
                        hintText: l10n.inflationPercentHint,
                        // Save used to be a bare `if (percent != null)` with
                        // no else, so a blank or unparseable percent made the
                        // button do nothing at all and the dialog just sat
                        // there.
                        errorText: percentError,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    // Free text used to be accepted here, but
                    // FinanceCalculator looks a rate up by exact World Bank
                    // code - so "Serbia" or "RS" was stored, listed, and then
                    // silently never applied to any balance. The only way to
                    // name a country the calculator can find is to pick one.
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        selectedCountry == null
                            ? l10n.inflationCountryGlobal
                            : l10n.inflationCountryNamed(
                                getLocalizedCountryName(
                                  selectedCountry!,
                                  Localizations.localeOf(context).toString(),
                                ),
                              ),
                      ),
                      trailing: selectedCountry == null
                          ? const Icon(Icons.public)
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              tooltip: l10n.inflationUseWorldwideRate,
                              onPressed: () =>
                                  setState(() => selectedCountry = null),
                            ),
                      onTap: () async {
                        final code = await showDialog<String>(
                          context: context,
                          builder: (context) => CountryPickerDialog(
                            allCountries: worldBankCountryCodes,
                            selectedCountryCode: selectedCountry,
                          ),
                        );
                        if (code != null) {
                          setState(() => selectedCountry = code);
                        }
                      },
                    ),
                    TextField(
                      controller: presetController,
                      decoration: InputDecoration(
                        labelText: l10n.exchPresetIdLabel,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(
                        l10n.dateWithValueLabel(
                          DateFormat('MMMM yyyy').format(selectedDate),
                        ),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          initialDatePickerMode: DatePickerMode.year,
                        );
                        if (date != null) {
                          setState(() {
                            selectedDate = DateTime(date.year, date.month);
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancelButton),
            ),
            FilledButton.tonal(
              onPressed: () {
                final percent = double.tryParse(percentController.text);
                final preset = int.tryParse(presetController.text) ?? 1;
                if (percent == null) {
                  setState(
                    () => percentError = l10n.inflationPercentInvalidError,
                  );
                } else {
                  final newRate = InflationRateDomain(
                    percent: percent,
                    country: selectedCountry,
                    date: DateTime(selectedDate.year, selectedDate.month),
                    preset: preset,
                  );

                  if (rate == null) {
                    bloc.add(AddInflationRate(newRate));
                  } else {
                    bloc.add(UpdateInflationRate(newRate));
                  }
                  Navigator.pop(context);
                }
              },
              child: Text(rate == null ? l10n.addButton : l10n.updateButton),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InflationBloc, InflationState>(
      builder: (context, state) {
        return ScreenShortcuts(
          actions: {'add_action': () => _showAddEditInflationDialog(context)},
          child: Scaffold(
            appBar: InflationTabAppBar(state: state),
            body: InflationView(
              onEdit: (rate) =>
                  _showAddEditInflationDialog(context, rate: rate),
            ),
            floatingActionButton: MultiLevelTooltip(
              message: context.l10n.inflationAddRate,
              actionId: 'add_action',
              description: context.l10n.inflationAddDescription,
              child: FloatingActionButton(
                onPressed: () => _showAddEditInflationDialog(context),
                child: const Icon(Icons.add),
              ),
            ),
          ),
        );
      },
    );
  }
}
