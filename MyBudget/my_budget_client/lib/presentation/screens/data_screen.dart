import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/presentation/blocs/inflation/inflation_bloc.dart';
import 'package:my_budget_client/presentation/blocs/asset/asset_bloc.dart';
import 'package:my_budget_client/presentation/blocs/asset/asset_event.dart';
import 'package:my_budget_client/presentation/blocs/asset/asset_state.dart';
import 'package:my_budget_client/presentation/screens/exchange_rates_screen.dart';
import 'package:my_budget_client/presentation/widgets/single_select_dialog.dart'; // Added
import 'package:my_budget_client/core/di/injection_container.dart';
import 'package:my_budget_client/domain/entities/inflation_rate.dart';
import 'package:my_budget_client/domain/entities/asset_data.dart';
import 'package:my_budget_client/domain/entities/account.dart'; // Added
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/domain/repositories/inflation_repository.dart';
import 'package:my_budget_client/domain/repositories/asset_repository.dart'; // Added
import 'package:uuid/uuid.dart';
import 'package:my_budget_client/presentation/widgets/calendar_step_picker.dart';
import 'package:my_budget_client/presentation/widgets/multi_select_dialog.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';

class DataScreen extends StatefulWidget {
  final int initialTabIndex;
  const DataScreen({super.key, this.initialTabIndex = 0});

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: widget.initialTabIndex,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Exchange Rates', icon: Icon(Icons.currency_exchange)),
              Tab(text: 'Inflation', icon: Icon(Icons.trending_up)),
              Tab(text: 'Assets', icon: Icon(Icons.inventory_2)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const ExchangeRatesScreen(isStandalone: false),
            const InflationManager(),
            const AssetManager(),
          ],
        ),
      ),
    );
  }
}

class InflationManager extends StatelessWidget {
  const InflationManager({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<InflationBloc>()..add(LoadInflationRates()),
      child: const _InflationView(),
    );
  }
}

class _InflationView extends StatelessWidget {
  const _InflationView();

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
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: BlocBuilder<InflationBloc, InflationState>(
          builder: (context, state) {
            if (state.status == InflationStatus.success ||
                state.status == InflationStatus.loading) {
              return _InflationDateAppBar(state: state);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
      body: BlocBuilder<InflationBloc, InflationState>(
        builder: (context, state) {
          if (state.status == InflationStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == InflationStatus.success) {
            if (state.rates.isEmpty) {
              return const Center(child: Text('No inflation rates added.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: state.rates.length,
              itemBuilder: (context, index) {
                final rate = state.rates[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.trending_up),
                    ),
                    title: Text(
                      '${rate.percent}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(
                      '${DateFormat('MMMM yyyy').format(rate.date)} • ${rate.country ?? "Global"}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () =>
                              _showAddEditInflationDialog(context, rate: rate),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            context.read<InflationBloc>().add(
                              DeleteInflationRate(
                                date: rate.date,
                                country: rate.country,
                                preset: rate.preset,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
          if (state.status == InflationStatus.failure) {
            return Center(child: Text('Error: ${state.errorMessage}'));
          }
          return const Center(child: Text('Start adding inflation records.'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditInflationDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AssetManager extends StatelessWidget {
  const AssetManager({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AssetBloc>()..add(const LoadAssetData()),
      child: const _AssetView(),
    );
  }
}

class _AssetView extends StatelessWidget {
  const _AssetView();

  Future<void> _showAddEditAssetDialog(
    BuildContext context, {
    AssetDataDomain? asset,
  }) async {
    final bloc = context.read<AssetBloc>();
    final nameController = TextEditingController(text: asset?.name ?? '');
    final assetIdController = TextEditingController(text: asset?.assetId ?? '');
    final valueController = TextEditingController(
      text: asset?.value.toString() ?? '',
    );
    final quantityController = TextEditingController(
      text: asset?.quantity.toString() ?? '1.0',
    );
    final assetTypeController = TextEditingController(
      text: asset?.assetType ?? '',
    );
    final descriptionController = TextEditingController(
      text: asset?.description ?? '',
    );
    DateTime selectedDate = asset?.date ?? DateTime.now();

    final accountRepository = sl<AccountRepository>();
    final accounts = await accountRepository.getAccounts();
    Account? selectedAccount;
    if (asset?.accountId != null) {
      try {
        selectedAccount = accounts.firstWhere((a) => a.id == asset!.accountId);
      } catch (_) {}
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(asset == null ? 'Add Asset Data' : 'Edit Asset Data'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Asset Name (e.g. Apple Stock)',
                  ),
                ),
                TextField(
                  controller: assetIdController,
                  decoration: const InputDecoration(
                    labelText: 'Asset ID (e.g. AAPL)',
                  ),
                ),
                TextField(
                  controller: valueController,
                  decoration: const InputDecoration(
                    labelText: 'Value (Price per unit)',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                TextField(
                  controller: quantityController,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                TextField(
                  controller: assetTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Asset Type (Optional)',
                  ),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final account = await showSingleSelectDialog<Account>(
                      context: context,
                      items: accounts,
                      title: 'Select Linked Account',
                      selectedItem: selectedAccount,
                      itemBuilder: (account) => Text(account.name),
                      stringGetter: (account) => account.name,
                    );
                    setState(() => selectedAccount = account);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Linked Account (Optional)',
                      suffixIcon: Icon(Icons.arrow_drop_down),
                      border: OutlineInputBorder(),
                    ),
                    child: Text(selectedAccount?.name ?? 'None'),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(
                    'Date: ${DateFormat('dd MMM yyyy').format(selectedDate)}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
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
                final value = double.tryParse(valueController.text);
                final quantity =
                    double.tryParse(quantityController.text) ?? 1.0;
                final name = nameController.text;
                final assetId = assetIdController.text;

                if (value != null && name.isNotEmpty && assetId.isNotEmpty) {
                  final newAsset = AssetDataDomain(
                    id: asset?.id ?? const Uuid().v4(),
                    assetId: assetId,
                    name: name,
                    date: selectedDate,
                    value: value,
                    quantity: quantity,
                    assetType: assetTypeController.text.isEmpty
                        ? null
                        : assetTypeController.text,
                    description: descriptionController.text.isEmpty
                        ? null
                        : descriptionController.text,
                    source: 'manual',
                    accountId: selectedAccount?.id, // Added
                  );

                  if (asset == null) {
                    bloc.add(AddAssetData(newAsset));
                  } else {
                    bloc.add(UpdateAssetData(newAsset));
                  }
                  Navigator.pop(context);
                }
              },
              child: Text(asset == null ? 'Add' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: BlocBuilder<AssetBloc, AssetState>(
          builder: (context, state) {
            if (state.status == AssetStatus.success ||
                state.status == AssetStatus.loading) {
              return _AssetDateAppBar(state: state);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
      body: BlocBuilder<AssetBloc, AssetState>(
        builder: (context, state) {
          if (state.status == AssetStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == AssetStatus.success) {
            if (state.assetData.isEmpty) {
              return const Center(child: Text('No asset data added.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: state.assetData.length,
              itemBuilder: (context, index) {
                final asset = state.assetData[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.inventory_2),
                    ),
                    title: Text(
                      asset.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${asset.assetId} • ${DateFormat('dd MMM yyyy').format(asset.date)}',
                        ),
                        Text(
                          'Val: ${NumberFormat.decimalPattern().format(asset.value)} • Qty: ${asset.quantity}',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () =>
                              _showAddEditAssetDialog(context, asset: asset),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => context.read<AssetBloc>().add(
                            DeleteAssetData(asset.id!),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
          if (state.status == AssetStatus.failure) {
            return Center(child: Text('Error: ${state.errorMessage}'));
          }
          return const Center(child: Text('Start adding asset records.'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditAssetDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _InflationDateAppBar extends StatelessWidget {
  final InflationState state;

  const _InflationDateAppBar({required this.state});

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<InflationBloc>(),
        child: const _InflationFilterDialog(),
      ),
    );
  }

  void _showCustomCalendar(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return BlocProvider.value(
          value: context.read<InflationBloc>(),
          child: CalendarStepPicker(
            initialDate: state.activeDate,
            initialRange: state.activeDateRange,
            initialStep: state.dateStep,
            initialFilterMode: state.filterMode,
            rangeOptionVisibility: PickerVisibility.visible,
            onApply: (date, range, step, mode) {
              final bloc = context.read<InflationBloc>();
              if (state.filterMode != mode) {
                bloc.add(ChangeInflationFilterMode(mode));
              }
              if (state.dateStep != step) {
                bloc.add(ChangeInflationDateStep(step));
              }
              if (mode == FilterMode.range && range != null) {
                bloc.add(ChangeInflationActiveDateRange(range));
              } else {
                bloc.add(ChangeInflationActiveDate(date));
              }
            },
          ),
        );
      },
    );
  }

  String _formatDate(BuildContext context) {
    if (state.filterMode == FilterMode.range) {
      if (state.activeDateRange == null) return 'Select Range';
      final start = MaterialLocalizations.of(
        context,
      ).formatShortDate(state.activeDateRange!.start);
      final end = MaterialLocalizations.of(
        context,
      ).formatShortDate(state.activeDateRange!.end);
      return '$start - $end';
    }

    switch (state.dateStep) {
      case DateStep.day:
        return MaterialLocalizations.of(
          context,
        ).formatShortDate(state.activeDate);
      case DateStep.month:
        return MaterialLocalizations.of(
          context,
        ).formatMonthYear(state.activeDate);
      case DateStep.year:
        return state.activeDate.year.toString();
    }
  }

  void _navigate(InflationBloc bloc, int i) {
    if (state.filterMode == FilterMode.range) return;

    DateTime newDate = state.activeDate;
    if (state.dateStep == DateStep.day) {
      newDate = newDate.add(Duration(days: i));
    } else if (state.dateStep == DateStep.month) {
      newDate = DateTime(newDate.year, newDate.month + i, newDate.day);
    } else if (state.dateStep == DateStep.year) {
      newDate = DateTime(newDate.year + i, newDate.month, newDate.day);
    }
    bloc.add(ChangeInflationActiveDate(newDate));
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<InflationBloc>();
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).cardColor,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => _showFilterDialog(context),
            tooltip: 'Filter',
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, color: onSurface),
                  onPressed: () => _navigate(bloc, -1),
                ),
                InkWell(
                  onTap: () => _showCustomCalendar(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    alignment: Alignment.center,
                    child: Text(
                      _formatDate(context),
                      style: TextStyle(color: onSurface, fontSize: 18),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right, color: onSurface),
                  onPressed: () => _navigate(bloc, 1),
                ),
              ],
            ),
          ),
          Text(
            'Total: ${state.totalCount}',
            style: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          RotatedBox(
            quarterTurns: state.sort == Sort.ascending ? 2 : 0,
            child: IconButton(
              icon: Icon(Icons.sort, color: onSurface),
              tooltip: 'Sort',
              onPressed: () {
                final newSort = state.sort == Sort.ascending
                    ? Sort.descending
                    : Sort.ascending;
                bloc.add(ChangeInflationSort(newSort));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetDateAppBar extends StatelessWidget {
  final AssetState state;

  const _AssetDateAppBar({required this.state});

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<AssetBloc>(),
        child: const _AssetFilterDialog(),
      ),
    );
  }

  void _showCustomCalendar(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return BlocProvider.value(
          value: context.read<AssetBloc>(),
          child: CalendarStepPicker(
            initialDate: state.activeDate,
            initialRange: state.activeDateRange,
            initialStep: state.dateStep,
            initialFilterMode: state.filterMode,
            rangeOptionVisibility: PickerVisibility.visible,
            onApply: (date, range, step, mode) {
              final bloc = context.read<AssetBloc>();
              if (state.filterMode != mode) {
                bloc.add(ChangeAssetFilterMode(mode));
              }
              if (state.dateStep != step) {
                bloc.add(ChangeAssetDateStep(step));
              }
              if (mode == FilterMode.range && range != null) {
                bloc.add(ChangeAssetActiveDateRange(range));
              } else {
                bloc.add(ChangeAssetActiveDate(date));
              }
            },
          ),
        );
      },
    );
  }

  String _formatDate(BuildContext context) {
    if (state.filterMode == FilterMode.range) {
      if (state.activeDateRange == null) return 'Select Range';
      final start = MaterialLocalizations.of(
        context,
      ).formatShortDate(state.activeDateRange!.start);
      final end = MaterialLocalizations.of(
        context,
      ).formatShortDate(state.activeDateRange!.end);
      return '$start - $end';
    }

    switch (state.dateStep) {
      case DateStep.day:
        return MaterialLocalizations.of(
          context,
        ).formatShortDate(state.activeDate);
      case DateStep.month:
        return MaterialLocalizations.of(
          context,
        ).formatMonthYear(state.activeDate);
      case DateStep.year:
        return state.activeDate.year.toString();
    }
  }

  void _navigate(AssetBloc bloc, int i) {
    if (state.filterMode == FilterMode.range) return;

    DateTime newDate = state.activeDate;
    if (state.dateStep == DateStep.day) {
      newDate = newDate.add(Duration(days: i));
    } else if (state.dateStep == DateStep.month) {
      newDate = DateTime(newDate.year, newDate.month + i, newDate.day);
    } else if (state.dateStep == DateStep.year) {
      newDate = DateTime(newDate.year + i, newDate.month, newDate.day);
    }
    bloc.add(ChangeAssetActiveDate(newDate));
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AssetBloc>();
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).cardColor,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => _showFilterDialog(context),
            tooltip: 'Filter',
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, color: onSurface),
                  onPressed: () => _navigate(bloc, -1),
                ),
                InkWell(
                  onTap: () => _showCustomCalendar(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    alignment: Alignment.center,
                    child: Text(
                      _formatDate(context),
                      style: TextStyle(color: onSurface, fontSize: 18),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right, color: onSurface),
                  onPressed: () => _navigate(bloc, 1),
                ),
              ],
            ),
          ),
          Text(
            'Total: ${state.totalCount}',
            style: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          RotatedBox(
            quarterTurns: state.sort == Sort.ascending ? 2 : 0,
            child: IconButton(
              icon: Icon(Icons.sort, color: onSurface),
              tooltip: 'Sort',
              onPressed: () {
                final newSort = state.sort == Sort.ascending
                    ? Sort.descending
                    : Sort.ascending;
                bloc.add(ChangeAssetSort(newSort));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InflationFilterDialog extends StatefulWidget {
  const _InflationFilterDialog();

  @override
  State<_InflationFilterDialog> createState() => _InflationFilterDialogState();
}

class _InflationFilterDialogState extends State<_InflationFilterDialog> {
  late Future<List<String>> _countriesFuture;
  late TextEditingController _presetController;
  // Temporary state for the dialog before applying
  String? _selectedCountry;

  @override
  void initState() {
    super.initState();
    _countriesFuture = sl<InflationRepository>().getAvailableCountries();
    final state = context.read<InflationBloc>().state;
    _selectedCountry = state.countryFilter;
    _presetController = TextEditingController(
      text: state.presetFilter?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _presetController.dispose();
    super.dispose();
  }

  Future<void> _selectCountry(List<String> availableCountries) async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => MultiSelectDialog<String>(
        items: availableCountries,
        selectedIds: _selectedCountry != null ? [_selectedCountry!] : [],
        itemBuilder: (item) => Text(item),
        idGetter: (item) => item,
        stringGetter: (item) => item,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedCountry = result.isNotEmpty ? result.first : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Inflation Rates'),
      content: FutureBuilder<List<String>>(
        future: _countriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          final countries = snapshot.data ?? [];

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Country'),
                subtitle: Text(_selectedCountry ?? 'All Countries'),
                trailing: const Icon(Icons.arrow_drop_down),
                onTap: () => _selectCountry(countries),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _presetController,
                decoration: const InputDecoration(
                  labelText: 'Preset',
                  hintText: 'Filter by preset value',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Clear filters
            setState(() {
              _selectedCountry = null;
              _presetController.clear();
            });
            final bloc = context.read<InflationBloc>();
            bloc.add(const ChangeInflationFilters(country: null));
            Navigator.pop(context);
          },
          child: const Text('Clear'),
        ),
        TextButton(
          onPressed: () {
            final bloc = context.read<InflationBloc>();
            bloc.add(
              ChangeInflationFilters(
                country: _selectedCountry,
                preset: int.tryParse(_presetController.text),
              ),
            );
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class _AssetFilterDialog extends StatefulWidget {
  const _AssetFilterDialog();

  @override
  State<_AssetFilterDialog> createState() => _AssetFilterDialogState();
}

class _AssetFilterDialogState extends State<_AssetFilterDialog> {
  late Future<List<String>> _assetIdsFuture;
  String? _selectedAssetId;

  @override
  void initState() {
    super.initState();
    _assetIdsFuture = sl<AssetRepository>().getAvailableAssetIds();
    _selectedAssetId = context.read<AssetBloc>().state.selectedAssetId;
  }

  Future<void> _selectAsset(List<String> assets) async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => MultiSelectDialog<String>(
        items: assets,
        selectedIds: _selectedAssetId != null ? [_selectedAssetId!] : [],
        itemBuilder: (item) => Text(item),
        idGetter: (item) => item,
        stringGetter: (item) => item,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedAssetId = result.isNotEmpty ? result.first : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Assets'),
      content: FutureBuilder<List<String>>(
        future: _assetIdsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          final assets = snapshot.data ?? [];

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Asset'),
                subtitle: Text(_selectedAssetId ?? 'All Assets'),
                trailing: const Icon(Icons.arrow_drop_down),
                onTap: () => _selectAsset(assets),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _selectedAssetId = null;
            });
            context.read<AssetBloc>().add(
              const ChangeAssetFilters(assetId: null),
            );
            Navigator.pop(context);
          },
          child: const Text('Clear'),
        ),
        TextButton(
          onPressed: () {
            context.read<AssetBloc>().add(
              ChangeAssetFilters(assetId: _selectedAssetId),
            );
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
