import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/presentation/blocs/api_settings/api_settings_bloc.dart';
import 'package:my_budget_client/presentation/blocs/api_settings/api_settings_event.dart';
import 'package:my_budget_client/presentation/blocs/api_settings/api_settings_state.dart';
import 'package:my_budget_client/core/di/injection_container.dart';

class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({super.key});

  @override
  State<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends State<ApiSettingsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ApiSettingsBloc>()..add(LoadApiSettings()),
      child: Scaffold(
        appBar: AppBar(title: const Text('API Management')),
        body: BlocConsumer<ApiSettingsBloc, ApiSettingsState>(
          listener: (context, state) {
            if (state is ApiSettingsLoadSuccess && state.lastError != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${state.lastError}')),
              );
            }
          },
          builder: (context, state) {
            if (state is ApiSettingsLoadInProgress) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ApiSettingsLoadSuccess) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SwitchListTile(
                    title: const Text('Enable API Fetching'),
                    subtitle: const Text(
                      'Automatic collection of exchange rates',
                    ),
                    value: state.isFetchingEnabled,
                    onChanged: (val) {
                      context.read<ApiSettingsBloc>().add(
                        ToggleApiFetching(val),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Fetch Mode'),
                    subtitle: Text(
                      state.fetchMode == 'debug'
                          ? 'Debug (JSON + API)'
                          : 'Production (API + Local DB)',
                    ),
                    trailing: DropdownButton<String>(
                      value: state.fetchMode,
                      items: const [
                        DropdownMenuItem(value: 'debug', child: Text('Debug')),
                        DropdownMenuItem(
                          value: 'production',
                          child: Text('Production'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          context.read<ApiSettingsBloc>().add(
                            SetApiFetchMode(val),
                          );
                        }
                      },
                    ),
                  ),
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 16.0,
                    ),
                    child: Text(
                      'Manual Data Fetch',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ListTile(
                    title: Text(
                      _startDate == null
                          ? 'Select Start Date'
                          : 'Start: ${DateFormat('yyyy-MM-dd').format(_startDate!)}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _startDate = picked);
                    },
                  ),
                  ListTile(
                    title: Text(
                      _endDate == null
                          ? 'Select End Date'
                          : 'End: ${DateFormat('yyyy-MM-dd').format(_endDate!)}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _endDate = picked);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: FilledButton.icon(
                      onPressed:
                          state.isOperationInProgress ||
                              _startDate == null ||
                              _endDate == null
                          ? null
                          : () {
                              context.read<ApiSettingsBloc>().add(
                                ManualFetchRange(_startDate!, _endDate!),
                              );
                            },
                      icon: state.isOperationInProgress
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download),
                      label: const Text('Fetch Data for Period'),
                    ),
                  ),
                ],
              );
            }

            if (state is ApiSettingsFailure) {
              return Center(
                child: Text('Failed to load settings: ${state.message}'),
              );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }
}
