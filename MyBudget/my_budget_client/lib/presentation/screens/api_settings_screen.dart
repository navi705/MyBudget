import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/data/api/external_data.dart';
import 'package:my_budget_client/core/utils/country_codes.dart';
import 'package:my_budget_client/presentation/blocs/api_settings/api_settings_bloc.dart';
import 'package:my_budget_client/presentation/blocs/api_settings/api_settings_event.dart';
import 'package:my_budget_client/presentation/blocs/api_settings/api_settings_state.dart';
import 'package:my_budget_client/core/di/injection_container.dart';
import 'package:my_budget_client/presentation/widgets/scaffold_with_escape_back.dart';

class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({super.key});

  @override
  State<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends State<ApiSettingsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  GameApiSteam? _selectedGame;
  final _steamIdController = TextEditingController();
  final _countryCodeController = TextEditingController(text: 'SRB');
  final _dateRangeController = TextEditingController(text: '2000:2024');

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      _steamIdController.text = '76561198085715972';
    }
  }

  @override
  void dispose() {
    _steamIdController.dispose();
    _countryCodeController.dispose();
    _dateRangeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EscapeBackHandler(
      child: BlocProvider(
        create: (context) => sl<ApiSettingsBloc>()..add(LoadApiSettings()),
        child: Scaffold(
          appBar: AppBar(title: const Text('API Management')),
          body: BlocConsumer<ApiSettingsBloc, ApiSettingsState>(
            listener: (context, state) {
              if (state is ApiSettingsLoadSuccess) {
                if (state.lastError != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${state.lastError}')),
                  );
                }
              }
            },
            builder: (context, state) {
              if (state is ApiSettingsLoadInProgress) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is ApiSettingsLoadSuccess) {
                if (state.steamId != null && _steamIdController.text.isEmpty) {
                  _steamIdController.text = state.steamId!;
                }
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 16.0,
                      ),
                      child: Text(
                        'Currency Exchange Rates',
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.download),
                        label: const Text('Fetch Exchange Rates'),
                      ),
                    ),
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 16.0,
                      ),
                      child: Text(
                        'Steam Inventory',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextFormField(
                        controller: _steamIdController,
                        decoration: const InputDecoration(
                          labelText: 'Steam Account ID',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          context.read<ApiSettingsBloc>().add(
                            SaveSteamId(value),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: DropdownButtonFormField<GameApiSteam>(
                        initialValue: _selectedGame,
                        hint: const Text('Select Game'),
                        items: GameApiSteam.values
                            .map(
                              (game) => DropdownMenuItem(
                                value: game,
                                child: Text(game.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedGame = value;
                          });
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: FilledButton.icon(
                        onPressed:
                            state.isOperationInProgress ||
                                _steamIdController.text.isEmpty ||
                                _selectedGame == null
                            ? null
                            : () {
                                final accountId = int.tryParse(
                                  _steamIdController.text,
                                );
                                if (accountId != null) {
                                  context.read<ApiSettingsBloc>().add(
                                    SaveSteamId(_steamIdController.text),
                                  );
                                  context.read<ApiSettingsBloc>().add(
                                    FetchSteamInventory(
                                      accountId,
                                      _selectedGame!,
                                    ),
                                  );
                                }
                              },
                        icon: state.isOperationInProgress
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.download),
                        label: const Text('Fetch Steam Inventory Value'),
                      ),
                    ),
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 16.0,
                      ),
                      child: Text(
                        'World Bank Inflation Data',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: SearchAnchor(
                        builder:
                            (
                              BuildContext context,
                              SearchController controller,
                            ) {
                              return TextField(
                                controller: controller,
                                decoration: const InputDecoration(
                                  labelText: 'Country Code (e.g. SRB)',
                                  suffixIcon: Icon(Icons.search),
                                ),
                                onTap: () {
                                  controller.openView();
                                },
                                onChanged: (_) {
                                  controller.openView();
                                },
                              );
                            },
                        suggestionsBuilder:
                            (
                              BuildContext context,
                              SearchController controller,
                            ) {
                              final keyword = controller.text.toLowerCase();
                              return worldBankCountryCodes.entries
                                  .where(
                                    (entry) =>
                                        entry.key.toLowerCase().contains(
                                          keyword,
                                        ) ||
                                        entry.value.toLowerCase().contains(
                                          keyword,
                                        ),
                                  )
                                  .map((entry) {
                                    return ListTile(
                                      title: Text(entry.key),
                                      subtitle: Text(entry.value),
                                      onTap: () {
                                        setState(() {
                                          controller.closeView(entry.value);
                                          _countryCodeController.text =
                                              entry.value;
                                        });
                                      },
                                    );
                                  });
                            },
                        viewOnChanged: (value) {
                          _countryCodeController.text =
                              value; // Keep controller synced if user types manually
                        },
                        viewOnSubmitted: (value) {
                          _countryCodeController.text = value;
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: TextFormField(
                        controller: _dateRangeController,
                        decoration: const InputDecoration(
                          labelText: 'Date Range (e.g. 2000:2024)',
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: FilledButton.icon(
                        onPressed:
                            state.isOperationInProgress ||
                                _countryCodeController.text.isEmpty ||
                                _dateRangeController.text.isEmpty
                            ? null
                            : () {
                                context.read<ApiSettingsBloc>().add(
                                  FetchInflationData(
                                    _countryCodeController.text,
                                    _dateRangeController.text,
                                  ),
                                );
                              },
                        icon: state.isOperationInProgress
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.download),
                        label: const Text('Fetch Inflation Data'),
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
      ),
    );
  }
}
