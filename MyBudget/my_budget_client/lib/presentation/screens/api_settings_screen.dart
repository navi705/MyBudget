import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EscapeBackHandler(
      child: BlocProvider(
        create: (context) => sl<ApiSettingsBloc>()..add(LoadApiSettings()),
        child: Scaffold(
          appBar: AppBar(title: const Text('API Management')),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: BlocConsumer<ApiSettingsBloc, ApiSettingsState>(
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
                    if (state.steamId != null &&
                        _steamIdController.text.isEmpty) {
                      _steamIdController.text = state.steamId!;
                    }
                    return ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        _buildMasterSyncSwitch(state),
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
                          (source) =>
                              _buildCustomSourceCard(context, source, state),
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
    ApiSettingsLoadSuccess state,
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
      child: ExpansionTile(
        title: Text(source.name),
        subtitle: Text(source.url),
        trailing: SizedBox(
          width: 96,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Switch(
                value: source.enabled,
                onChanged: (val) {
                  context.read<ApiSettingsBloc>().add(
                    UpdateCustomDataSource(id: source.id, enabled: val),
                  );
                },
              ),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('Auto-fetch daily'),
                    const Spacer(),
                    Switch(
                      value: source.autoFetch,
                      onChanged: (val) {
                        context.read<ApiSettingsBloc>().add(
                          UpdateCustomDataSource(id: source.id, autoFetch: val),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (state.testResult != null) ...[
                      Icon(
                        state.testResult! ? Icons.check_circle : Icons.error,
                        color: state.testResult! ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        state.testResult!
                            ? 'Connection OK'
                            : 'Connection Failed',
                        style: TextStyle(
                          color: state.testResult! ? Colors.green : Colors.red,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                    ],
                    OutlinedButton.icon(
                      onPressed: state.isOperationInProgress
                          ? null
                          : () {
                              context.read<ApiSettingsBloc>().add(
                                TestCustomDataSource(source.url),
                              );
                            },
                      icon: state.isOperationInProgress
                          ? const _MiniLoading()
                          : const Icon(Icons.network_check, size: 18),
                      label: const Text('Test Connection'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.redAccent),
            title: const Text(
              'Remove Source',
              style: TextStyle(color: Colors.redAccent),
            ),
            onTap: () {
              context.read<ApiSettingsBloc>().add(
                DeleteCustomDataSource(source.id),
              );
            },
          ),
        ],
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
                  initialValue: _selectedGame,
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
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _startDate == null
                        ? 'Select Start Year'
                        : 'From: ${_startDate!.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                      initialDatePickerMode: DatePickerMode.year,
                    );
                    if (picked != null) setState(() => _startDate = picked);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _endDate == null
                        ? 'Select End Year'
                        : 'To: ${_endDate!.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                      initialDatePickerMode: DatePickerMode.year,
                    );
                    if (picked != null) setState(() => _endDate = picked);
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed:
                        state.isOperationInProgress ||
                            _countryCodeController.text.isEmpty ||
                            _startDate == null ||
                            _endDate == null
                        ? null
                        : () {
                            final range =
                                '${_startDate!.year}:${_endDate!.year}';
                            context.read<ApiSettingsBloc>().add(
                              FetchInflationData(
                                _countryCodeController.text,
                                range,
                              ),
                            );
                          },
                    icon: state.isOperationInProgress
                        ? const _MiniLoading()
                        : const Icon(Icons.cloud_download),
                    label: const Text('Fetch Data'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSourceDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final portCtrl = TextEditingController();
    int type = 0;
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Custom Source'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Address Formats:\n'
                  '• 192.168.1.10 (IP)\n'
                  '• localhost or api.my.com\n'
                  '• http://myserver.com',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'My Home Server',
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: urlCtrl,
                        decoration: InputDecoration(
                          labelText: 'URL / IP',
                          hintText: '192.168.1.10',
                          errorText: errorText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: portCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Port',
                          hintText: '8080',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: type,
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Exchange Rates')),
                    DropdownMenuItem(value: 1, child: Text('Inflation')),
                    DropdownMenuItem(value: 2, child: Text('Assets')),
                  ],
                  onChanged: (v) => setDialogState(() => type = v!),
                  decoration: const InputDecoration(labelText: 'Data Type'),
                ),
                const SizedBox(height: 16),
                Text(
                  'Required JSON Format:',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                _buildJsonFormatHint(type, context),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final url = urlCtrl.text.trim();
                final name = nameCtrl.text.trim();
                final port = portCtrl.text.trim();

                if (name.isEmpty || url.isEmpty) {
                  setDialogState(() => errorText = 'Required');
                  return;
                }

                String finalUrl = url;
                if (port.isNotEmpty) {
                  finalUrl = '$url:$port';
                }

                context.read<ApiSettingsBloc>().add(
                  AddCustomDataSource(
                    name: name,
                    url: finalUrl,
                    dataType: type,
                  ),
                );
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJsonFormatHint(int type, BuildContext context) {
    String json;
    switch (type) {
      case 0:
        json =
            '{\n  "type": "exchange_rates",\n  "data": [\n    { "date": "2023-01-01", "from": "EUR", "to": "USD", "rate": 1.08 }\n  ]\n}';
        break;
      case 1:
        json =
            '{\n  "type": "inflation",\n  "data": [\n    { "date": "2023-01-01", "country": "USA", "rate": 6.5 }\n  ]\n}';
        break;
      default:
        json =
            '{\n  "type": "assets",\n  "data": [\n    { "date": "2023-01-01", "code": "BTC", "value": 20000 }\n  ]\n}';
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withAlpha(100),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(50),
        ),
      ),
      child: Text(
        json,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildMasterSyncSwitch(ApiSettingsLoadSuccess state) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer.withAlpha(76),
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        title: Text(
          'Global Startup Sync',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        subtitle: const Text(
          'Master switch to control all data fetching on application startup.',
        ),
        value: state.startupSyncEnabled,
        onChanged: (val) {
          context.read<ApiSettingsBloc>().add(ToggleStartupSync(val));
        },
        secondary: Icon(
          Icons.sync_lock,
          color: Theme.of(context).colorScheme.primary,
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
