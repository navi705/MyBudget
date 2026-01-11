import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/core/utils/icon_utils.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency/currency_bloc.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/presentation/widgets/single_select_dialog.dart';
import 'package:my_budget_client/domain/entities/account_type.dart';
import 'package:my_budget_client/presentation/widgets/icon_selection_dialog.dart';

class AddAccountDialog extends StatefulWidget {
  const AddAccountDialog({super.key});

  @override
  State<AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<AddAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController(); // ADDED
  final _balanceController = TextEditingController();
  String? _selectedCurrencyCode;
  String? _selectedCurrencyDesignationId;
  String? _selectedStyleId;
  String? _selectedAccountTypeId; // ADDED
  String? _selectedCountry;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _descriptionController.dispose(); // ADDED
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.addAccountDialogTitle),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: l10n.accountNameHint),
                validator: (value) => (value == null || value.isEmpty)
                    ? l10n.formValidationPleaseEnterName
                    : null,
              ),
              TextFormField(
                controller: _descriptionController, // ADDED
                decoration: const InputDecoration(
                  labelText: 'Description',
                ), // TODO: Localize
                maxLines: 3,
                keyboardType: TextInputType.multiline,
              ),
              TextFormField(
                controller: _balanceController,
                decoration: InputDecoration(labelText: l10n.initialBalanceHint),
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
                            _selectedCurrencyDesignationId = state.designations
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
                  return const Center(child: CircularProgressIndicator());
                },
              ),
              BlocBuilder<AccountsBloc, AccountsState>(
                // NEW BLOC BUILDER FOR AccountTypes
                builder: (context, state) {
                  if (state is AccountsLoadSuccess) {
                    return GestureDetector(
                      onTap: () async {
                        final selectedAccountType =
                            await showSingleSelectDialog<AccountType>(
                              context: context,
                              items: state.accountTypes,
                              title: 'Select Account Type',
                              selectedItem: state.accountTypes.firstWhereOrNull(
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
              BlocBuilder<SettingsBloc, SettingsState>(
                builder: (context, state) {
                  return DropdownButtonFormField<String>(
                    value: _selectedCountry,
                    hint: const Text('Select Country'),
                    items: state.countries
                        .map(
                          (country) => DropdownMenuItem(
                            value: country,
                            child: Text(country),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCountry = value;
                      });
                    },
                  );
                },
              ),
              BlocBuilder<StylesBloc, StylesState>(
                builder: (context, state) {
                  if (state is StylesLoadSuccess) {
                    if (_selectedStyleId == null && state.styles.isNotEmpty) {
                      _selectedStyleId = state.styles.first.id;
                    }

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
                      title: const Text('Icon'),
                      subtitle: Text(selectedStyle?.name ?? 'Select an icon'),
                      onTap: () async {
                        final newStyleId = await showIconSelectionDialog(
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
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        FilledButton.tonal(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final newAccount = Account(
                name: _nameController.text,
                description: _descriptionController.text.isEmpty
                    ? null
                    : _descriptionController.text,
                balance: double.parse(_balanceController.text),
                currencyCode: _selectedCurrencyCode!,
                currencyDesignationId: _selectedCurrencyDesignationId!,
                styleId: _selectedStyleId,
                accountTypeId: _selectedAccountTypeId!,
                creationDate: DateTime.now(),
                country: _selectedCountry,
              );
              context.read<AccountsBloc>().add(AddAccount(newAccount));
              Navigator.of(context).pop();
            }
          },
          child: Text(l10n.saveButton),
        ),
      ],
    );
  }
}
