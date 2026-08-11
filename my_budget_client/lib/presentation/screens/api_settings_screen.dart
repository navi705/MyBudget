import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
import 'package:my_budget_client/data/api/external_data.dart';
import 'package:my_budget_client/domain/entities/api_setting.dart';
import 'package:my_budget_client/domain/entities/custom_data_source.dart';
import 'package:my_budget_client/presentation/blocs/api_settings/api_settings_bloc.dart';
import 'package:my_budget_client/presentation/blocs/api_settings/api_settings_event.dart';
import 'package:my_budget_client/presentation/blocs/api_settings/api_settings_state.dart';
import 'package:my_budget_client/core/di/injection_container.dart';
import 'package:my_budget_client/presentation/widgets/scaffold_with_escape_back.dart';
import 'package:my_budget_client/presentation/widgets/generic/app_state_view.dart';

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
            appBar: AppBar(title: Text(context.l10n.apiManagementTitle)),
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

                    if (state is ApiSettingsFailure) {
                      return AppStateView.error(
                        message: context.l10n.failedToLoadData,
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
      padding: const EdgeInsetsDirectional.only(start: 4.0, bottom: 4.0),
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
          context.l10n.startupDataSyncLabel,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        subtitle: Text(context.l10n.startupDataSyncDescription),
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
    final title = _getApiTitle(context, setting.id);
    final lastFetch = setting.lastFetchAt != null
        ? DateFormat('yyyy-MM-dd HH:mm').format(setting.lastFetchAt!)
        : context.l10n.noneLabel;

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
        subtitle: Text('${context.l10n.dateLabel}: $lastFetch'),
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
                  title: context.l10n.standardApiLabel,
                  subtitle: context.l10n.syncOnStartupDescription,
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
                    title: context.l10n.customSourcesLabel,
                    subtitle: context.l10n.syncCustomSourcesDescription(
                      customSourcesOfType.length,
                    ),
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
                        tooltip: context.l10n.addCustomSourceTitle,
                        onPressed: () => _showSourceDialog(
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
            label: Text(context.l10n.fetchTodaysRatesButton),
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
        _buildSmallHeader(context, context.l10n.inflationConfigTitle),
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey('field_val_inflation_country'),
          controller: _countryCodeController,
          decoration: InputDecoration(
            labelText: context.l10n.countryCodeHint,
            border: const OutlineInputBorder(),
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
            label: Text(
              context.l10n.fetchDataForCountryButton(
                _countryCodeController.text,
              ),
            ),
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
          _buildSmallHeader(context, context.l10n.steamSettingsTitle),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('field_val_steam_id'),
            controller: _steamIdController,
            decoration: InputDecoration(
              labelText: context.l10n.steamIdLabel,
              hintText: 'e.g. 76561198085715972',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) =>
                context.read<ApiSettingsBloc>().add(SaveSteamId(v)),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<GameApiSteam>(
            key: const ValueKey('steam_game_dropdown'),
            value: state.steamGame ?? GameApiSteam.cs2,
            decoration: InputDecoration(
              labelText: context.l10n.preferredGameLabel,
              border: const OutlineInputBorder(),
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
              label: Text(context.l10n.fetchInventoryNowButton),
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

  Widget _buildExchangeRatesUtil(
    BuildContext context,
    ApiSettingsLoadSuccess state,
  ) {
    return Card(
      key: const ValueKey('util_rates'),
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        key: const ValueKey('exp_state_manual_rates'),
        title: Text(context.l10n.manualExchangeRatesTitle),
        leading: const Icon(Icons.currency_exchange),
        children: [
          ListTile(
            title: Text(
              _startDate == null
                  ? context.l10n.selectStartDate
                  : context.l10n.startDateFrom(
                      DateFormat('yyyy-MM-dd').format(_startDate!),
                    ),
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
                  ? context.l10n.selectEndDate
                  : context.l10n.endDateTo(
                      DateFormat('yyyy-MM-dd').format(_endDate!),
                    ),
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
                label: Text(context.l10n.fetchRangeButton),
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
        title: Text(context.l10n.manualSteamInventoryTitle),
        leading: const Icon(Icons.games_outlined),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _steamIdController,
                  decoration: InputDecoration(
                    labelText: context.l10n.steamIdLabel,
                    border: const OutlineInputBorder(),
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
        title: Text(context.l10n.manualInflationDataTitle),
        leading: const Icon(Icons.trending_up),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _countryCodeController,
                  decoration: InputDecoration(
                    labelText: context.l10n.countryCodeHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _startDate == null
                        ? context.l10n.selectStartYear
                        : context.l10n.startYearFrom(
                            _startDate!.year.toString(),
                          ),
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
                        ? context.l10n.selectEndYear
                        : context.l10n.endYearTo(_endDate!.year.toString()),
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
                    label: Text(context.l10n.fetchDataButton),
                  ),
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
      key: ValueKey('custom_source_${source.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        key: ValueKey('exp_state_custom_${source.id}'),
        title: Text(source.name),
        subtitle: Text(source.url),
        leading: Icon(_getApiIcon(source.dataType.name)),
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
                if (state.testResults.containsKey(source.url)) ...[
                  Icon(
                    state.testResults[source.url]!
                        ? Icons.check_circle
                        : Icons.error,
                    color: state.testResults[source.url]!
                        ? Colors.green
                        : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    state.testResults[source.url]!
                        ? 'Connection OK'
                        : 'Connection Failed',
                    style: TextStyle(
                      color: state.testResults[source.url]!
                          ? Colors.green
                          : Colors.red,
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
                            TestCustomDataSource(
                              id: source.id,
                              url: source.url,
                            ),
                          );
                        },
                  icon: state.isOperationInProgress
                      ? const _MiniLoading()
                      : const Icon(Icons.network_check, size: 18),
                  label: const Text('Test Connection'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blueAccent),
                  tooltip: context.l10n.editCustomSourceTitle,
                  onPressed: () => _showSourceDialog(
                    context,
                    preselectedType: source.dataType,
                    existingSource: source,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  tooltip: context.l10n.deleteButton,
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

  void _showSourceDialog(
    BuildContext context, {
    ApiDataType? preselectedType,
    CustomDataSourceDomain? existingSource,
  }) {
    final isEditing = existingSource != null;
    final nameCtrl = TextEditingController(text: existingSource?.name ?? '');
    final urlCtrl = TextEditingController(text: existingSource?.url ?? '');
    int type = existingSource != null
        ? ApiDataType.values.indexOf(existingSource.dataType)
        : (preselectedType != null
              ? ApiDataType.values.indexOf(preselectedType)
              : 0);
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            isEditing
                ? context.l10n.editCustomSourceTitle
                : context.l10n.addCustomSourceTitle,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.addressFormatsHelp,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: context.l10n.categoryNameLabel,
                    hintText: 'My Home Server',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: urlCtrl,
                  decoration: InputDecoration(
                    labelText: context.l10n.urlIpLabel,
                    hintText: context.l10n.urlIpHint,
                    errorText: errorText,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: type,
                  items: [
                    DropdownMenuItem(
                      value: 0,
                      child: Text(context.l10n.apiTitleExchangeRates),
                    ),
                    DropdownMenuItem(
                      value: 1,
                      child: Text(context.l10n.apiTitleInflation),
                    ),
                    DropdownMenuItem(
                      value: 2,
                      child: Text(context.l10n.apiTitleAssetPrices),
                    ),
                  ],
                  onChanged: (v) => setDialogState(() => type = v ?? 0),
                  decoration: InputDecoration(
                    labelText: context.l10n.dataTypeLabel,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.l10n.cancelButton),
            ),
            FilledButton(
              onPressed: () {
                final url = urlCtrl.text.trim();
                final name = nameCtrl.text.trim();
                if (name.isEmpty || url.isEmpty) {
                  setDialogState(() => errorText = context.l10n.requiredError);
                  return;
                }
                if (isEditing) {
                  context.read<ApiSettingsBloc>().add(
                    EditCustomDataSource(
                      id: existingSource.id,
                      name: name,
                      url: url,
                      dataType: type,
                    ),
                  );
                } else {
                  context.read<ApiSettingsBloc>().add(
                    AddCustomDataSource(name: name, url: url, dataType: type),
                  );
                }
                Navigator.pop(ctx);
              },
              child: Text(
                isEditing
                    ? context.l10n.saveButton
                    : context.l10n.addCustomSourceTitle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getApiTitle(BuildContext context, String id) {
    switch (id) {
      case 'exchange_rates':
        return context.l10n.apiTitleExchangeRates;
      case 'inflation':
        return context.l10n.apiTitleInflation;
      case 'assets':
        return context.l10n.apiTitleAssetPrices;
      case 'steam_inventory':
        return context.l10n.apiTitleSteamInventory;
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
