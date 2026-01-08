import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/core/di/injection_container.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/asset_data.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/presentation/blocs/asset/asset_bloc.dart';
import 'package:my_budget_client/presentation/blocs/asset/asset_event.dart';
import 'package:my_budget_client/presentation/blocs/asset/asset_state.dart';
import 'package:my_budget_client/presentation/widgets/asset_tab_app_bar.dart';
import 'package:my_budget_client/presentation/widgets/asset_view.dart';
import 'package:my_budget_client/presentation/widgets/single_select_dialog.dart';
import 'package:uuid/uuid.dart';

class AssetTab extends StatelessWidget {
  const AssetTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AssetBloc>()..add(const LoadAssetData()),
      child: const _AssetTabContent(),
    );
  }
}

class _AssetTabContent extends StatelessWidget {
  const _AssetTabContent();

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
                    source: asset?.source ?? 'manual',
                    accountId: selectedAccount?.id,
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
    return BlocBuilder<AssetBloc, AssetState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AssetTabAppBar(state: state),
          body: AssetView(
            onEdit: (asset) => _showAddEditAssetDialog(context, asset: asset),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddEditAssetDialog(context),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
