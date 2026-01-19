import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/core/di/injection_container.dart';
import 'package:my_budget_client/domain/entities/inflation_rate.dart';
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
    final percentController = TextEditingController(
      text: rate?.percent.toString() ?? '',
    );
    final countryController = TextEditingController(text: rate?.country ?? '');
    final presetController = TextEditingController(
      text: rate?.preset.toString() ?? '1',
    );
    DateTime selectedDate = rate?.date ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            rate == null ? 'Add Inflation Rate' : 'Edit Inflation Rate',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: percentController,
                  decoration: const InputDecoration(
                    labelText: 'Inflation Percent (%)',
                    hintText: 'e.g. 2.5',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                TextField(
                  controller: countryController,
                  decoration: const InputDecoration(
                    labelText: 'Country (Optional)',
                    hintText: 'Leave empty for Global',
                  ),
                ),
                TextField(
                  controller: presetController,
                  decoration: const InputDecoration(labelText: 'Preset ID'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(
                    'Date: ${DateFormat('MMMM yyyy').format(selectedDate)}',
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton.tonal(
              onPressed: () {
                final percent = double.tryParse(percentController.text);
                final preset = int.tryParse(presetController.text) ?? 1;
                if (percent != null) {
                  final newRate = InflationRateDomain(
                    percent: percent,
                    country: countryController.text.isEmpty
                        ? null
                        : countryController.text,
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
              child: Text(rate == null ? 'Add' : 'Update'),
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
              message: 'Add Inflation Rate',
              actionId: 'add_action',
              description:
                  'Enter a new inflation percentage for a specific date and country',
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
