import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/core/utils/date_display.dart';
import 'package:my_budget_client/core/di/injection_container.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/asset_data.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/presentation/blocs/asset/asset_bloc.dart';
import 'package:my_budget_client/presentation/blocs/asset/asset_event.dart';
import 'package:my_budget_client/presentation/blocs/asset/asset_state.dart';
import 'package:my_budget_client/presentation/widgets/asset_tab_app_bar.dart';
import 'package:my_budget_client/presentation/widgets/asset_view.dart';
import 'package:my_budget_client/presentation/widgets/single_select_dialog.dart';
import 'package:my_budget_client/presentation/widgets/multi_level_tooltip.dart';
import 'package:my_budget_client/presentation/widgets/screen_shortcuts.dart';
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
    final l10n = context.l10n;
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

    String? nameError;
    String? assetIdError;
    String? valueError;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(asset == null ? l10n.assetAddTitle : l10n.assetEditTitle),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 250),
              child: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: l10n.assetNameLabel,
                        // Save used to be a bare `if (...)` with no else, so
                        // any of these three left blank or unparseable made
                        // the button do nothing at all and the dialog just
                        // sat there with nothing marked.
                        errorText: nameError,
                      ),
                    ),
                    TextField(
                      controller: assetIdController,
                      decoration: InputDecoration(
                        labelText: l10n.assetIdLabel,
                        errorText: assetIdError,
                      ),
                    ),
                    TextField(
                      controller: valueController,
                      decoration: InputDecoration(
                        labelText: l10n.assetValueLabel,
                        errorText: valueError,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    TextField(
                      controller: quantityController,
                      decoration: InputDecoration(
                        labelText: l10n.quantityFormLabel,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    TextField(
                      controller: assetTypeController,
                      decoration: InputDecoration(
                        labelText: l10n.assetTypeOptionalLabel,
                      ),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: l10n.descriptionOptionalLabel,
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final account = await showSingleSelectDialog<Account>(
                          context: context,
                          items: accounts,
                          title: l10n.selectLinkedAccountTitle,
                          selectedItem: selectedAccount,
                          itemBuilder: (account) => Text(account.name),
                          stringGetter: (account) => account.name,
                        );
                        setState(() => selectedAccount = account);
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: l10n.assetLinkedAccountOptionalLabel,
                          suffixIcon: const Icon(Icons.arrow_drop_down),
                          border: const OutlineInputBorder(),
                        ),
                        child: Text(selectedAccount?.name ?? l10n.noneLabel),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(
                        l10n.dateWithValueLabel(
                          DateDisplay.medium(context, selectedDate),
                        ),
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
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancelButton),
            ),
            FilledButton.tonal(
              onPressed: () {
                final value = double.tryParse(valueController.text);
                final quantity =
                    double.tryParse(quantityController.text) ?? 1.0;
                final name = nameController.text;
                final assetId = assetIdController.text;

                if (value == null || name.isEmpty || assetId.isEmpty) {
                  setState(() {
                    nameError = name.isEmpty
                        ? l10n.assetNameRequiredError
                        : null;
                    assetIdError = assetId.isEmpty
                        ? l10n.assetIdRequiredError
                        : null;
                    valueError = value == null
                        ? l10n.assetValueInvalidError
                        : null;
                  });
                } else {
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
              child: Text(asset == null ? l10n.addButton : l10n.updateButton),
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
        final bloc = context.read<AssetBloc>();
        return ScreenShortcuts(
          actions: {
            'add_action': () => _showAddEditAssetDialog(context),
            // Screen-agnostic ids, like add_action above: every list screen
            // carries the same date picker and sort toggle, and only the
            // focused screen's ScreenShortcuts sees the key event.
            'pick_date': () => showAssetCalendar(context, state),
            'sort_order': () => toggleAssetSort(bloc, state),
            // Selection actions only while the selection bar is on screen.
            // Off it, "close" would emit a state change nothing asked for and
            // "select all" would fill a selection the user cannot see.
            'asset_selection_close': () {
              if (state.isSelectionModeActive) bloc.add(DeselectAllAssets());
            },
            'asset_selection_all': () {
              if (state.isSelectionModeActive)
                toggleAssetSelectAll(bloc, state);
            },
            // The delete button is itself hidden at zero selection, so the
            // hotkey stays hidden with it rather than opening a dialog that
            // would delete nothing.
            'asset_selection_delete': () {
              if (state.isSelectionModeActive &&
                  state.selectedAssets.isNotEmpty) {
                showAssetDeleteConfirmation(context, bloc, state);
              }
            },
          },
          child: Scaffold(
            appBar: AssetTabAppBar(state: state),
            body: AssetView(
              onEdit: (asset) => _showAddEditAssetDialog(context, asset: asset),
            ),
            floatingActionButton: state.isSelectionModeActive
                ? null
                : MultiLevelTooltip(
                    message: context.l10n.assetAddTitle,
                    actionId: 'add_action',
                    description: context.l10n.assetAddDescription,
                    child: FloatingActionButton(
                      onPressed: () => _showAddEditAssetDialog(context),
                      child: const Icon(Icons.add),
                    ),
                  ),
          ),
        );
      },
    );
  }
}
