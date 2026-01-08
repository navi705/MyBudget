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
import 'package:my_budget_client/domain/repositories/account_repository.dart'; // Added
import 'package:uuid/uuid.dart';

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
          title: const Text('Data Management'),
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
      body: BlocBuilder<InflationBloc, InflationState>(
        builder: (context, state) {
          if (state is InflationLoadInProgress) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is InflationLoadSuccess) {
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
          if (state is InflationFailure) {
            return Center(child: Text('Error: ${state.message}'));
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
      body: BlocBuilder<AssetBloc, AssetState>(
        builder: (context, state) {
          if (state is AssetLoadInProgress) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AssetLoadSuccess) {
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
          if (state is AssetFailure) {
            return Center(child: Text('Error: ${state.message}'));
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
