import '../../core/utils/country_codes.dart';
import '../widgets/country_picker_dialog.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/core/utils/icon_utils.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency/currency_bloc.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/presentation/widgets/single_select_dialog.dart';
import 'package:my_budget_client/presentation/widgets/icon_selection_dialog.dart';
import 'package:my_budget_client/presentation/widgets/delete_account_dialog.dart';
import 'package:my_budget_client/presentation/blocs/asset/asset_bloc.dart';
import 'package:my_budget_client/presentation/blocs/asset/asset_state.dart';

import 'package:my_budget_client/presentation/widgets/scaffold_with_escape_back.dart';
import 'package:my_budget_client/domain/repositories/asset_repository.dart'; // Added
import 'package:my_budget_client/domain/entities/asset_data.dart'; // Added
import 'package:my_budget_client/core/di/injection_container.dart'; // Added for sl
import 'package:my_budget_client/presentation/widgets/fee_structure_editor.dart'; // Added

class EditAccountScreen extends StatefulWidget {
  final Account account;

  const EditAccountScreen({super.key, required this.account});

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController; // ADDED
  late TextEditingController _balanceController;
  String? _selectedCurrencyCode;
  String? _selectedCurrencyDesignationId;

  String? _selectedStyleId;
  String? _selectedAccountTypeId;
  String? _selectedAssetId; // ADDED
  late TextEditingController _assetQuantityController; // ADDED
  double? _currentAssetPrice; // To display price
  String? _assetCurrency; // To display currency
  String? _feeStructureJson; // Added

  late Account _initialAccount;

  @override
  void initState() {
    super.initState();
    _initialAccount = widget.account;

    _nameController = TextEditingController(text: _initialAccount.name);
    _descriptionController = TextEditingController(
      text: _initialAccount.description ?? '',
    );
    _balanceController = TextEditingController(
      text: _initialAccount.balance.toString(),
    );
    _selectedCurrencyCode = _initialAccount.currencyCode;
    _selectedCurrencyDesignationId = _initialAccount.currencyDesignationId;
    _selectedStyleId = _initialAccount.styleId;

    _selectedAccountTypeId = _initialAccount.accountTypeId;
    _selectedAssetId = _initialAccount.assetId;
    _assetQuantityController = TextEditingController(
      text: _initialAccount.assetQuantity.toString(),
    );
    // Trigger initial balance calculation/update if asset is selected?
    // For now, just load state.
    _feeStructureJson = _initialAccount.feeStructure;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _balanceController.dispose();
    _assetQuantityController.dispose(); // ADDED
    super.dispose();
  }

  Color _getColorFromHex(String? hexColor) {
    hexColor = (hexColor ?? '#FF5733').replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    if (hexColor.length == 8) {
      return Color(int.parse("0x$hexColor"));
    }
    return Colors.orange;
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      final updatedAccount = _initialAccount.copyWith(
        name: _nameController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        balance: double.parse(_balanceController.text),
        currencyCode: _selectedCurrencyCode,
        currencyDesignationId: _selectedCurrencyDesignationId,
        styleId: _selectedStyleId,
        accountTypeId: _selectedAccountTypeId,
        assetId: _selectedAssetId,
        assetQuantity: _selectedAssetId != null
            ? double.tryParse(_assetQuantityController.text) ?? 0.0
            : 0.0,
        feeStructure: _feeStructureJson, // Added
      );

      // Only dispatch an update if the account has actually changed.
      if (updatedAccount != widget.account) {
        context.read<AccountsBloc>().add(UpdateAccount(updatedAccount));
      }
      FocusScope.of(context).unfocus();
      context.pop();
    }
  }

  void _onDelete() {
    final state = context.read<AccountsBloc>().state;
    if (state is AccountsLoadSuccess) {
      showDialog(
        context: context,
        builder: (context) => DeleteAccountDialog(
          accountToDelete: _initialAccount,
          allAccounts: state.accounts,
        ),
      ).then((_) {
        // Dialog handles the bloc event.
        // If deleted, we should pop.
        // But better to listen to Bloc state change (RecentlyDeleted) in Screen?
        // Actually typical flow: Dialog adds event -> Bloc updates state -> Listener Pops.
        // But here we are in Edit Screen. If deleted, we should manually pop?
        // The dialog confirms and closes itself.
        // We need to close *this* screen if delete happened.
        // But we don't know if user cancelled or deleted from the dialog result unless we return it.
        // Let's assume user might manually navigate back or we rely on some listener.
        // Simple fix: Check if account exists in list?
        // Actually, `DeleteAccountDialog` returns void.
        // I will just pop `EditAccountScreen` if the dialog *was confirmed*.
        // But `DeleteAccountDialog` creates the event.
        // I'll make `DeleteAccountScreen` close automatically.
        // Wait, `EditAccountScreen` is pushed on stack.
        // If I delete account, `AccountsScreen` (underneath) updates.
        // `EditAccountScreen` remains open?
        // I should stick to: Dialog handles deletion. logic.
        // Ideally, `EditAccountScreen` should listen to Bloc and pop if current account is deleted.
        // Or I can pass a callback?
        // Let's just pop `EditAccountScreen` here assuming success if we want, OR just let user go back.
        // BETTER: `DeleteAccountDialog` handles deletion.
        // If I want to close `EditAccountScreen` on success, I should listen to `AccountsBloc`.
        // But `AccountsBloc` listener is in `AccountsScreen`.
        // Let's add a `BlocListener` in `EditAccountScreen`.
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return EscapeBackHandler(
      child: BlocListener<AccountsBloc, AccountsState>(
        listener: (context, state) {
          if (state is AccountsLoadSuccess &&
              state.recentlyDeletedAccount?.id == widget.account.id) {
            context.pop();
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(l10n.editAccountTitle(_initialAccount.name)),
            actions: const [],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: l10n.accountNameHint,
                          isDense: true,
                        ),
                        validator: (value) => (value == null || value.isEmpty)
                            ? l10n.formValidationPleaseEnterName
                            : null,
                      ),
                      // Hide Description as requested
                      /*
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: l10n.descriptionLabel,
                    ),
                    maxLines: 3,
                    keyboardType: TextInputType.multiline,
                  ),
                  */
                      const SizedBox(height: 8),
                      // Added spacing for new field
                      TextFormField(
                        controller: _balanceController,
                        readOnly:
                            _selectedAssetId !=
                            null, // Make read-only if asset bound
                        decoration: InputDecoration(
                          labelText: l10n.initialBalanceHint,
                          filled: _selectedAssetId != null, // Visual cue
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.formValidationPleaseEnterBalance;
                          }
                          if (double.tryParse(value) == null) {
                            return l10n.formValidationPleaseEnterValidNumber;
                          }
                          return null;
                        },
                      ),
                      if (_selectedAssetId != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            l10n.balanceCalculatedFromAsset,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      BlocBuilder<CurrencyBloc, CurrencyState>(
                        builder: (context, state) {
                          if (state is CurrencyLoadSuccess) {
                            return GestureDetector(
                              onTap: () async {
                                final selectedCurrency =
                                    await showSingleSelectDialog<Currency>(
                                      context: context,
                                      items: state.currencies,
                                      title: l10n.selectCurrencyTitle,
                                      selectedItem: state.currencies
                                          .firstWhereOrNull(
                                            (c) =>
                                                c.code == _selectedCurrencyCode,
                                          ),
                                      itemBuilder: (currency) =>
                                          Text(currency.name),
                                      stringGetter: (currency) =>
                                          '${currency.name} ${currency.code}',
                                    );
                                if (mounted && selectedCurrency != null) {
                                  setState(() {
                                    _selectedCurrencyCode =
                                        selectedCurrency.code;
                                    _selectedCurrencyDesignationId = state
                                        .designations
                                        .firstWhereOrNull(
                                          (d) =>
                                              d.currencyCode ==
                                              _selectedCurrencyCode,
                                        )
                                        ?.id;
                                  });
                                }
                              },
                              child: AbsorbPointer(
                                child: TextFormField(
                                  key: Key(
                                    _selectedCurrencyCode ?? 'no_currency',
                                  ),
                                  initialValue: state.currencies
                                      .firstWhereOrNull(
                                        (c) => c.code == _selectedCurrencyCode,
                                      )
                                      ?.name,
                                  decoration: InputDecoration(
                                    labelText: l10n.currencyLabel,
                                    isDense: true,
                                  ),
                                  validator: (value) =>
                                      _selectedCurrencyCode == null
                                      ? l10n.formValidationPleaseSelectCurrency
                                      : null,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(height: 8),
                      // Hide Account Type as requested
                      /*
                  BlocBuilder<AccountsBloc, AccountsState>(
                    builder: (context, state) {
                      if (state is AccountsLoadSuccess) {
                        return GestureDetector(
                          onTap: () async {
                            final selectedAccountType =
                                await showSingleSelectDialog<AccountType>(
                                  context: context,
                                  items: state.accountTypes,
                                  title: l10n.selectAccountTypeTitle,
                                  selectedItem: state.accountTypes
                                      .firstWhereOrNull(
                                        (t) => t.id == _selectedAccountTypeId,
                                      ),
                                  itemBuilder: (type) => Text(type.name),
                                  stringGetter: (type) => type.name,
                                );
                            if (mounted && selectedAccountType != null) {
                              setState(() {
                                _selectedAccountTypeId = selectedAccountType.id;
                              });
                            }
                          },
                          child: AbsorbPointer(
                            child: TextFormField(
                              key: Key(_selectedAccountTypeId ?? 'no_type'),
                              initialValue: state.accountTypes
                                  .firstWhereOrNull(
                                    (t) => t.id == _selectedAccountTypeId,
                                  )
                                  ?.name,
                              decoration: InputDecoration(
                                labelText: l10n.typeLabel,
                              ),
                              validator: (value) =>
                                  _selectedAccountTypeId == null
                                  ? l10n.selectAccountError
                                  : null,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  */
                      const SizedBox(height: 8),
                      BlocBuilder<SettingsBloc, SettingsState>(
                        builder: (context, state) {
                          final localizedCountryName =
                              _initialAccount.country != null
                              ? getLocalizedCountryName(
                                  _initialAccount.country!,
                                  state.settings['language_code'] ?? 'en',
                                )
                              : null;

                          return GestureDetector(
                            onTap: () async {
                              final selectedCode = await showDialog<String>(
                                context: context,
                                builder: (context) => CountryPickerDialog(
                                  allCountries: state.countries,
                                  selectedCountryCode: _initialAccount.country,
                                ),
                              );

                              if (mounted && selectedCode != null) {
                                setState(() {
                                  _initialAccount = _initialAccount.copyWith(
                                    country: selectedCode,
                                  );
                                });
                              }
                            },
                            child: AbsorbPointer(
                              child: TextFormField(
                                key: Key(
                                  _initialAccount.country ?? 'no_country',
                                ),
                                initialValue:
                                    localizedCountryName ??
                                    _initialAccount.country,
                                decoration: InputDecoration(
                                  labelText: l10n.defaultInflationCountryLabel,
                                  isDense: true,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      BlocBuilder<StylesBloc, StylesState>(
                        builder: (context, state) {
                          if (state is StylesLoadSuccess) {
                            final selectedStyle = state.styles.firstWhereOrNull(
                              (s) => s.id == _selectedStyleId,
                            );

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: selectedStyle != null
                                  ? CircleAvatar(
                                      backgroundColor: _getColorFromHex(
                                        selectedStyle.colorHex,
                                      ),
                                      child: IconUtils.getIconWidget(
                                        selectedStyle,
                                      ),
                                    )
                                  : const CircleAvatar(
                                      child: Icon(Icons.account_balance),
                                    ),
                              title: Text(l10n.styleLabel),
                              subtitle: Text(
                                selectedStyle?.name ?? l10n.selectIconSubtitle,
                              ),
                              onTap: () async {
                                final newStyleId =
                                    await showIconSelectionDialog(
                                      context,
                                      _selectedStyleId ?? '',
                                    );
                                if (newStyleId != null) {
                                  setState(() {
                                    _selectedStyleId = newStyleId;
                                  });
                                }
                              },
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(height: 8),

                      // --- ASSET BINDING SECTION ---
                      BlocBuilder<AssetBloc, AssetState>(
                        builder: (context, state) {
                          // Get latest versions of unique assets by ID
                          final uniqueAssets = <String, AssetDataDomain>{};
                          for (var asset in state.assetData) {
                            if (!uniqueAssets.containsKey(asset.assetId) ||
                                asset.date.isAfter(
                                  uniqueAssets[asset.assetId]!.date,
                                )) {
                              uniqueAssets[asset.assetId] = asset;
                            }
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(),
                              Text(
                                l10n.bindToAssetLabel,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  final selectedId =
                                      await showSingleSelectDialog<String>(
                                        context: context,
                                        items: uniqueAssets.keys.toList(),
                                        title: l10n.selectAssetTitle,
                                        selectedItem: _selectedAssetId,
                                        itemBuilder: (id) {
                                          final asset = uniqueAssets[id]!;
                                          return Text(
                                            '${asset.name} (${asset.assetId})',
                                          );
                                        },
                                        stringGetter: (id) =>
                                            uniqueAssets[id]!.name,
                                      );

                                  if (mounted) {
                                    setState(() {
                                      if (selectedId != null) {
                                        _selectedAssetId = selectedId;
                                        final asset = uniqueAssets[selectedId]!;
                                        _currentAssetPrice = asset.value;
                                        _assetCurrency = asset.currency;

                                        // Recalculate Balance
                                        final qty =
                                            double.tryParse(
                                              _assetQuantityController.text,
                                            ) ??
                                            0.0;
                                        _balanceController.text =
                                            (qty * asset.value).toStringAsFixed(
                                              2,
                                            );
                                      }
                                    });
                                  }
                                },
                                child: AbsorbPointer(
                                  child: TextFormField(
                                    key: Key(_selectedAssetId ?? 'no_asset'),
                                    initialValue: _selectedAssetId != null
                                        ? uniqueAssets[_selectedAssetId]?.name
                                        : null,
                                    decoration: InputDecoration(
                                      labelText: l10n.selectedAssetLabel,
                                      helperText: _selectedAssetId != null
                                          ? l10n.balanceAutoCalculatedLabel
                                          : l10n.tapToBindAssetLabel,
                                      suffixIcon: _selectedAssetId != null
                                          ? IconButton(
                                              icon: const Icon(Icons.clear),
                                              onPressed: () {
                                                setState(() {
                                                  _selectedAssetId = null;
                                                  _currentAssetPrice = null;
                                                  _assetCurrency = null;
                                                });
                                              },
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      if (_selectedAssetId != null) ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _assetQuantityController,
                          decoration: InputDecoration(
                            labelText: l10n.assetQuantityLabel,
                            isDense: true,
                            helperText:
                                _currentAssetPrice != null &&
                                    _assetCurrency != null
                                ? l10n.currentPriceLabel(
                                    _currentAssetPrice!.toString(),
                                    _assetCurrency!,
                                  )
                                : null,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (val) {
                            final qty = double.tryParse(val) ?? 0.0;
                            if (_currentAssetPrice != null) {
                              setState(() {
                                _balanceController.text =
                                    (qty * _currentAssetPrice!).toStringAsFixed(
                                      2,
                                    );
                              });
                            }
                          },
                        ),
                      ],

                      const SizedBox(height: 8),

                      // --- END ASSET BINDING SECTION ---
                      const Divider(),
                      FeeStructureEditor(
                        initialFeeStructureJson: _feeStructureJson,
                        onChanged: (json) {
                          setState(() {
                            _feeStructureJson = json;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      const Divider(),

                      // ASSET LIST Section
                      FutureBuilder<List<AssetDataDomain>>(
                        future: sl<AssetRepository>().getAssetData(
                          accountId: widget.account.id,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final assets = snapshot.data ?? [];
                          if (assets.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.linkedAssetsTitle,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...assets.map((asset) {
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: const Icon(Icons.show_chart),
                                    title: Text(asset.name),
                                    subtitle: Text(
                                      '${asset.quantity} @ ${asset.value} ${asset.currency}',
                                    ),
                                    trailing: Text(
                                      '${(asset.quantity * asset.value).toStringAsFixed(2)} ${asset.currency}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(height: 16),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      FilledButton.tonal(
                        onPressed: _onSave,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: Text(l10n.saveButton),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _onDelete,
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        label: Text(
                          l10n.deleteButton,
                          style: const TextStyle(color: Colors.red),
                        ),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(double.infinity, 40),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ), // Scaffold
      ), // BlocListener
    ); // EscapeBackHandler
  }
}
