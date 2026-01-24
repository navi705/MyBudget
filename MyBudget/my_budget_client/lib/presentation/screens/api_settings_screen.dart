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
        create: (context) =>
            sl<ApiSettingsBloc>()..add(const LoadApiSettings()),
        child: Builder(
          builder: (context) => Scaffold(
            resizeToAvoidBottomInset: false,
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
                      // Initialize local controllers/state when data loads
                      if (state.steamId != null &&
                          _steamIdController.text.isEmpty) {
                        _steamIdController.text = state.steamId!;
                      }
                      if (state.steamGame != null && _selectedGame == null) {
                        _selectedGame = state.steamGame;
                      }
                    }
                  },
                  builder: (context, state) {
                    if (state is ApiSettingsLoadInProgress) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is ApiSettingsLoadSuccess) {
                      return ListView(
                        padding: const EdgeInsets.all(16.0),
                        children: [
                          _buildMasterSyncSwitch(context, state),
                          _buildSectionTitle(context, 'API Categories'),
                          const SizedBox(height: 8),
                          ...state.apiSettings.map(
                            (setting) =>
                                _buildApiSettingCard(context, setting, state),
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

  Widget _buildMasterSyncSwitch(
    BuildContext context,
    ApiSettingsLoadSuccess state,
  ) {
    return Card(
      key: const ValueKey('master_sync_card'),
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer.withAlpha(76),
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        title: Text(
          'Startup Data Sync',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        subtitle: const Text(
          'Controls both external data fetching and server synchronization on application launch.',
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

  Widget _buildApiSettingCard(
    BuildContext context,
    ApiSettingDomain setting,
    ApiSettingsLoadSuccess state,
  ) {
    final title = _getApiTitle(setting.id);
    final lastFetch = setting.lastFetchAt != null
        ? DateFormat('yyyy-MM-dd HH:mm').format(setting.lastFetchAt!)
        : 'Never';

    final dataType = _getApiDataType(setting.id);
    final customSourcesOfType = dataType != null
        ? state.customDataSources.where((s) => s.dataType == dataType).toList()
        : <CustomDataSourceDomain>[];
    final anyCustomEnabled = customSourcesOfType.any((s) => s.enabled);

    return Card(
      key: ValueKey('api_card_${setting.id}'),
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withAlpha(100),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        key: ValueKey('exp_state_tile_${setting.id}'),
        leading: Icon(_getApiIcon(setting.id)),
        title: Text(title),
        subtitle: Text('Last: $lastFetch'),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSwitchRow(
                  context: context,
                  title: 'Standard API',
                  subtitle: 'Sync on startup',
                  value: setting.enabled,
                  enabled: state.startupSyncEnabled,
                  key: ValueKey('api_switch_std_${setting.id}'),
                  onChanged: (val) {
                    context.read<ApiSettingsBloc>().add(
                      UpdateApiSetting(id: setting.id, enabled: val),
                    );
                  },
                ),
                if (dataType != null)
                  _buildSwitchRow(
                    context: context,
                    title: 'Custom Sources',
                    subtitle:
                        'Sync all ${customSourcesOfType.length} on startup',
                    value: anyCustomEnabled,
                    enabled: state.startupSyncEnabled,
                    key: ValueKey('api_switch_custom_${setting.id}'),
                    onChanged: (val) {
                      context.read<ApiSettingsBloc>().add(
                        ToggleAllCustomSources(
                          dataType: dataType,
                          enabled: val,
                        ),
                      );
                    },
                  ),
                const Divider(height: 24),
                if (setting.id == 'exchange_rates')
                  _buildExchangeRatesCardUtil(context, state),
                if (setting.id == 'steam_inventory')
                  _buildSteamConfig(context, state),
                if (setting.id == 'assets' &&
                    !state.apiSettings.any((s) => s.id == 'steam_inventory'))
                  _buildSteamConfig(context, state),
                if (setting.id == 'inflation')
                  _buildInflationCardUtil(context, state),
                if (dataType != null) ...[
                  const Divider(height: 24),
                  Row(
                    children: [
                      Text(
                        'Individual Custom Sources',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add, size: 20),
                        tooltip: 'Add Source',
                        onPressed: () => _showAddSourceDialog(
                          context,
                          preselectedType: dataType,
                        ),
                      ),
                    ],
                  ),
                  if (customSourcesOfType.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'No custom sources added.',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                        ),
                      ),
                    )
                  else
                    ...customSourcesOfType.map(
                      (source) =>
                          _buildCustomSourceCard(context, source, state),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool value,
    required bool enabled,
    required ValueKey key,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      key: key,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(
        enabled ? subtitle : 'Disabled by Global Sync',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      value: value,
      onChanged: enabled ? onChanged : null,
      dense: true,
    );
  }

  Widget _buildExchangeRatesCardUtil(
    BuildContext context,
    ApiSettingsLoadSuccess state,
  ) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: state.isOperationInProgress
                ? null
                : () {
                    final today = DateTime.now();
                    context.read<ApiSettingsBloc>().add(
                      ManualFetchRange(today, today),
                    );
                  },
            icon: state.isOperationInProgress
                ? const _MiniLoading()
                : const Icon(Icons.currency_exchange, size: 18),
            label: const Text('Fetch Today\'s Rates'),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildInflationCardUtil(
    BuildContext context,
    ApiSettingsLoadSuccess state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSmallHeader(context, 'Inflation Config'),
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey('field_val_inflation_country'),
          controller: _countryCodeController,
          decoration: const InputDecoration(
            labelText: 'Country Code (e.g. SRB)',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed:
                state.isOperationInProgress ||
                    _countryCodeController.text.isEmpty
                ? null
                : () {
                    final currentYear = DateTime.now().year;
                    final range = '${currentYear - 25}:$currentYear';
                    context.read<ApiSettingsBloc>().add(
                      FetchInflationData(_countryCodeController.text, range),
                    );
                  },
            icon: state.isOperationInProgress
                ? const _MiniLoading()
                : const Icon(Icons.cloud_download, size: 18),
            label: Text('Fetch Data for ${_countryCodeController.text}'),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSteamConfig(BuildContext context, ApiSettingsLoadSuccess state) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withAlpha(50),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withAlpha(100),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSmallHeader(context, 'Steam Settings'),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('field_val_steam_id'),
            controller: _steamIdController,
            decoration: const InputDecoration(
              labelText: 'Steam ID (64-bit)',
              hintText: 'e.g. 76561198085715972',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) =>
                context.read<ApiSettingsBloc>().add(SaveSteamId(v)),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<GameApiSteam>(
            key: const ValueKey('steam_game_dropdown'),
            value: state.steamGame ?? GameApiSteam.cs2,
            decoration: const InputDecoration(
              labelText: 'Preferred Game',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: GameApiSteam.values
                .map(
                  (g) => DropdownMenuItem(
                    value: g,
                    child: Text(g.name.toUpperCase()),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) {
                context.read<ApiSettingsBloc>().add(SaveSteamGame(v));
                setState(() => _selectedGame = v);
              }
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
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
                  : const Icon(Icons.sync, size: 18),
              label: const Text('Fetch Inventory Now'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallHeader(BuildContext context, String title) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.primary.withAlpha(200),
      ),
    );
  }

  Widget _buildCustomSourceCard(
    BuildContext context,
    CustomDataSourceDomain source,
    ApiSettingsLoadSuccess state,
  ) {
    return Card(
      key: ValueKey('custom_source_${source.id}'),
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withAlpha(50),
        ),
      ),
      child: ExpansionTile(
        key: ValueKey('exp_state_custom_${source.id}'),
        title: Text(source.name),
        subtitle: Text(source.url),
        trailing: Switch(
          value: source.enabled,
          onChanged: state.startupSyncEnabled
              ? (val) {
                  context.read<ApiSettingsBloc>().add(
                    UpdateCustomDataSource(id: source.id, enabled: val),
                  );
                }
              : null,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                if (state.testResult != null) ...[
                  Icon(
                    state.testResult! ? Icons.check_circle : Icons.error,
                    color: state.testResult! ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    state.testResult! ? 'Connection OK' : 'Connection Failed',
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
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => context.read<ApiSettingsBloc>().add(
                    DeleteCustomDataSource(source.id),
                  ),
                ),
              ],
            ),
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
      key: const ValueKey('util_rates'),
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        key: const ValueKey('exp_state_manual_rates'),
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
            child: SizedBox(
              width: double.infinity,
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
          ),
        ],
      ),
    );
  }

  Widget _buildSteamUtil(BuildContext context, ApiSettingsLoadSuccess state) {
    return Card(
      key: const ValueKey('util_steam'),
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        key: const ValueKey('exp_state_manual_steam'),
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
                        (g) => DropdownMenuItem(
                          value: g,
                          child: Text(g.name.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedGame = v),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
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
      key: const ValueKey('util_inflation'),
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        key: const ValueKey('exp_state_manual_inflation'),
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

  void _showAddSourceDialog(
    BuildContext context, {
    ApiDataType? preselectedType,
  }) {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    int type = preselectedType != null
        ? ApiDataType.values.indexOf(preselectedType)
        : 0;
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
                  'Address Formats:\n• 192.168.1.10 (IP)\n• localhost or api.my.com\n• http://myserver.com',
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
                const SizedBox(height: 16),
                TextField(
                  controller: urlCtrl,
                  decoration: InputDecoration(
                    labelText: 'URL / IP',
                    hintText: '192.168.1.10:8080',
                    errorText: errorText,
                  ),
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
                if (name.isEmpty || url.isEmpty) {
                  setDialogState(() => errorText = 'Required');
                  return;
                }
                context.read<ApiSettingsBloc>().add(
                  AddCustomDataSource(name: name, url: url, dataType: type),
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

  String _getApiTitle(String id) {
    switch (id) {
      case 'exchange_rates':
        return 'Exchange Rates';
      case 'inflation':
        return 'Inflation';
      case 'assets':
        return 'Asset Prices';
      case 'steam_inventory':
        return 'Steam Inventory';
      default:
        return id.toUpperCase();
    }
  }

  IconData _getApiIcon(String id) {
    switch (id) {
      case 'exchange_rates':
        return Icons.currency_exchange;
      case 'inflation':
        return Icons.trending_up;
      case 'assets':
      case 'steam_inventory':
        return Icons.inventory_2;
      default:
        return Icons.api;
    }
  }

  ApiDataType? _getApiDataType(String id) {
    switch (id) {
      case 'exchange_rates':
        return ApiDataType.exchange;
      case 'inflation':
        return ApiDataType.inflation;
      case 'assets':
      case 'steam_inventory':
        return ApiDataType.asset;
      default:
        return null;
    }
  }
}

class _MiniLoading extends StatelessWidget {
  const _MiniLoading();
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}
