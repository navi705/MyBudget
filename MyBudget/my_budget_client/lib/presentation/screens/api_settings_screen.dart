import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/data/api/external_data.dart';
import 'package:my_budget_client/data/api/external_data.dart';
import 'package:my_budget_client/domain/entities/api_setting.dart';
import 'package:my_budget_client/domain/entities/custom_data_source.dart';
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
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildSectionTitle(context, 'Built-in APIs'),
                    const SizedBox(height: 8),
                    ...state.apiSettings.map(
                      (setting) =>
                          _buildApiSettingCard(context, setting, state),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionTitle(context, 'Custom Data Sources'),
                    const SizedBox(height: 8),
                    ...state.customDataSources.map(
                      (source) => _buildCustomSourceCard(context, source),
                    ),
                    ListTile(
                      leading: const Icon(Icons.add),
                      title: const Text('Add Source'),
                      onTap: () => _showAddSourceDialog(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withAlpha(50),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionTitle(context, 'Manual Utilities'),
                    const SizedBox(height: 8),
                    _buildExchangeRatesUtil(context, state),
                    _buildSteamUtil(context, state),
                    _buildInflationUtil(context, state),
                    const SizedBox(height: 48),
                  ],
                );
              }

              return const SizedBox();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildApiSettingCard(
    BuildContext context,
    ApiSettingDomain setting,
    ApiSettingsLoadSuccess state,
  ) {
    final title = _getApiTitle(setting.id);
    final lastFetch = setting.lastFetchAt != null
        ? DateFormat('yyyy-MM-dd HH:mm').format(setting.lastFetchAt!)
        : 'Never';

    return Card(
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withAlpha(100),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(_getApiIcon(setting.id)),
        title: Text(title),
        subtitle: Text('Last: $lastFetch'),
        trailing: Switch(
          value: setting.enabled,
          onChanged: (val) {
            context.read<ApiSettingsBloc>().add(
              UpdateApiSetting(id: setting.id, enabled: val),
            );
          },
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                const Text('Auto-fetch daily'),
                const Spacer(),
                Switch(
                  value: setting.autoFetch,
                  onChanged: (val) {
                    context.read<ApiSettingsBloc>().add(
                      UpdateApiSetting(id: setting.id, autoFetch: val),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomSourceCard(
    BuildContext context,
    CustomDataSourceDomain source,
  ) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withAlpha(50),
        ),
      ),
      child: ListTile(
        title: Text(source.name),
        subtitle: Text(source.url),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            context.read<ApiSettingsBloc>().add(
              DeleteCustomDataSource(source.id),
            );
          },
        ),
      ),
    );
  }

  Widget _buildExchangeRatesUtil(
    BuildContext context,
    ApiSettingsLoadSuccess state,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: const Text('Manual Exchange Rates Fetch'),
        leading: const Icon(Icons.currency_exchange),
        children: [
          ListTile(
            title: Text(
              _startDate == null
                  ? 'Select Start Date'
                  : 'From: ${DateFormat('yyyy-MM-dd').format(_startDate!)}',
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
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
                  : 'To: ${DateFormat('yyyy-MM-dd').format(_endDate!)}',
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
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
                  ? const _MiniLoading()
                  : const Icon(Icons.download),
              label: const Text('Fetch Range'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSteamUtil(BuildContext context, ApiSettingsLoadSuccess state) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: const Text('Manual Steam Inventory'),
        leading: const Icon(Icons.games_outlined),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _steamIdController,
                  decoration: const InputDecoration(
                    labelText: 'Steam ID',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) =>
                      context.read<ApiSettingsBloc>().add(SaveSteamId(v)),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<GameApiSteam>(
                  value: _selectedGame,
                  hint: const Text('Select Game'),
                  items: GameApiSteam.values
                      .map(
                        (g) => DropdownMenuItem(value: g, child: Text(g.name)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedGame = v),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed:
                      state.isOperationInProgress ||
                          _steamIdController.text.isEmpty ||
                          _selectedGame == null
                      ? null
                      : () {
                          final id = int.tryParse(_steamIdController.text);
                          if (id != null) {
                            context.read<ApiSettingsBloc>().add(
                              FetchSteamInventory(id, _selectedGame!),
                            );
                          }
                        },
                  icon: state.isOperationInProgress
                      ? const _MiniLoading()
                      : const Icon(Icons.sync),
                  label: const Text('Fetch Value'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInflationUtil(
    BuildContext context,
    ApiSettingsLoadSuccess state,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: const Text('Manual Inflation Data'),
        leading: const Icon(Icons.trending_up),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _countryCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Country Code (e.g. SRB)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _date_range_controller,
                  decoration: const InputDecoration(
                    labelText: 'Years (e.g. 2000:2024)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed:
                      state.isOperationInProgress ||
                          _countryCodeController.text.isEmpty
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
                      ? const _MiniLoading()
                      : const Icon(Icons.cloud_download),
                  label: const Text('Fetch Data'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  get _date_range_controller => _dateRangeController;

  void _showAddSourceDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    int type = 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Custom Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: urlCtrl,
                decoration: const InputDecoration(labelText: 'URL'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: type,
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Exchange Rates')),
                  DropdownMenuItem(value: 1, child: Text('Inflation')),
                  DropdownMenuItem(value: 2, child: Text('Assets')),
                ],
                onChanged: (v) => setDialogState(() => type = v!),
                decoration: const InputDecoration(labelText: 'Data Type'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty && urlCtrl.text.isNotEmpty) {
                  context.read<ApiSettingsBloc>().add(
                    AddCustomDataSource(
                      name: nameCtrl.text,
                      url: urlCtrl.text,
                      dataType: type,
                    ),
                  );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  String _getApiTitle(String id) {
    switch (id) {
      case 'exchange_rates':
        return 'Exchange Rates';
      case 'inflation':
        return 'Inflation Data';
      case 'assets':
        return 'Asset Prices';
      default:
        return id;
    }
  }

  IconData _getApiIcon(String id) {
    switch (id) {
      case 'exchange_rates':
        return Icons.currency_exchange;
      case 'inflation':
        return Icons.trending_up;
      case 'assets':
        return Icons.inventory_2_outlined;
      default:
        return Icons.api;
    }
  }
}

class _MiniLoading extends StatelessWidget {
  const _MiniLoading();
  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 14,
    height: 14,
    child: CircularProgressIndicator(strokeWidth: 2),
  );
}
