import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/core/utils/icon_utils.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency/currency_bloc.dart';
import 'package:my_budget_client/domain/entities/account_type.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/presentation/widgets/single_select_dialog.dart';
import 'package:my_budget_client/presentation/widgets/style_picker_dialog.dart';

import 'package:my_budget_client/presentation/widgets/scaffold_with_escape_back.dart';
import 'package:my_budget_client/domain/repositories/asset_repository.dart'; // Added
import 'package:my_budget_client/domain/entities/asset_data.dart'; // Added
import 'package:my_budget_client/core/di/injection_container.dart'; // Added for sl

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
  String? _selectedAccountTypeId; // ADDED

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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose(); // ADDED
    _balanceController.dispose();
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
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text(
          'Are you sure you want to delete "${_initialAccount.name}"? This will also delete all associated transactions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AccountsBloc>().add(
                DeleteAccount(_initialAccount.id!),
              );
              Navigator.of(dialogContext).pop();
              FocusScope.of(context).unfocus();
              context.pop();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return EscapeBackHandler(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Edit: ${_initialAccount.name}'),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _onDelete();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: l10n.accountNameHint),
                  validator: (value) => (value == null || value.isEmpty)
                      ? l10n.formValidationPleaseEnterName
                      : null,
                ),
                TextFormField(
                  // ADDED
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  // TODO: Localize
                  maxLines: 3,
                  keyboardType: TextInputType.multiline,
                ),
                const SizedBox(height: 16),
                // Added spacing for new field
                TextFormField(
                  controller: _balanceController,
                  decoration: InputDecoration(
                    labelText: l10n.initialBalanceHint,
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
                const SizedBox(height: 16),
                BlocBuilder<CurrencyBloc, CurrencyState>(
                  builder: (context, state) {
                    if (state is CurrencyLoadSuccess) {
                      return GestureDetector(
                        onTap: () async {
                          final selectedCurrency =
                              await showSingleSelectDialog<Currency>(
                                context: context,
                                items: state.currencies,
                                title: 'Select Currency',
                                selectedItem: state.currencies.firstWhereOrNull(
                                  (c) => c.code == _selectedCurrencyCode,
                                ),
                                itemBuilder: (currency) => Text(currency.name),
                                stringGetter: (currency) =>
                                    '${currency.name} ${currency.code}',
                              );
                          if (mounted && selectedCurrency != null) {
                            setState(() {
                              _selectedCurrencyCode = selectedCurrency.code;
                              _selectedCurrencyDesignationId = state
                                  .designations
                                  .firstWhereOrNull(
                                    (d) =>
                                        d.currencyCode == _selectedCurrencyCode,
                                  )
                                  ?.id;
                            });
                          }
                        },
                        child: AbsorbPointer(
                          child: TextFormField(
                            key: Key(_selectedCurrencyCode ?? 'no_currency'),
                            initialValue: state.currencies
                                .firstWhereOrNull(
                                  (c) => c.code == _selectedCurrencyCode,
                                )
                                ?.name,
                            decoration: InputDecoration(
                              labelText: l10n.currencyLabel,
                            ),
                            validator: (value) => _selectedCurrencyCode == null
                                ? l10n.formValidationPleaseSelectCurrency
                                : null,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 16),
                BlocBuilder<AccountsBloc, AccountsState>(
                  builder: (context, state) {
                    if (state is AccountsLoadSuccess) {
                      return GestureDetector(
                        onTap: () async {
                          final selectedAccountType =
                              await showSingleSelectDialog<AccountType>(
                                context: context,
                                items: state.accountTypes,
                                title: 'Select Account Type',
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
                            decoration: const InputDecoration(
                              labelText: 'Account Type',
                            ),
                            validator: (value) => _selectedAccountTypeId == null
                                ? 'Please select an account type'
                                : null,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 16),
                BlocBuilder<SettingsBloc, SettingsState>(
                  builder: (context, state) {
                    return GestureDetector(
                      onTap: () async {
                        final selectedCountry =
                            await showSingleSelectDialog<String>(
                              context: context,
                              items: state.countries,
                              title: 'Select Country',
                              selectedItem: _initialAccount.country,
                              itemBuilder: (country) => Text(country),
                              stringGetter: (country) => country,
                            );
                        if (mounted && selectedCountry != null) {
                          // We need to update the _initialAccount directly or a controller for it
                          // Since there is no controller for country, let's store it in a local variable
                          // But wait, the UpdateAccount event uses _initialAccount.copyWith...
                          // We should probably introduce a state variable for selectedCountry
                          setState(() {
                            _initialAccount = _initialAccount.copyWith(
                              country: selectedCountry,
                            );
                          });
                        }
                      },
                      child: AbsorbPointer(
                        child: TextFormField(
                          key: Key(_initialAccount.country ?? 'no_country'),
                          initialValue: _initialAccount.country,
                          decoration: const InputDecoration(
                            labelText: 'Country (Inflation)',
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
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
                                child: IconUtils.getIconWidget(selectedStyle),
                              )
                            : const CircleAvatar(child: Icon(Icons.style)),
                        title: const Text('Style'),
                        subtitle: Text(selectedStyle?.name ?? 'Select a style'),
                        onTap: () async {
                          final newStyleId = await showStylePickerDialog(
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
                const SizedBox(height: 16),
                // ASSET LIST Section
                FutureBuilder<List<AssetDataDomain>>(
                  future: sl<AssetRepository>().getAssetData(
                    accountId: widget.account.id,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final assets = snapshot.data ?? [];
                    if (assets.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Linked Assets",
                          style: TextStyle(
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
                const SizedBox(height: 32),
                FilledButton.tonal(
                  onPressed: _onSave,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: Text(l10n.saveButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
