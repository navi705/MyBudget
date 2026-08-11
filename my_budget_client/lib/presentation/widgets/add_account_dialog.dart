import '../../core/utils/country_codes.dart';
import 'country_picker_dialog.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/core/utils/icon_utils.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency/currency_bloc.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/presentation/widgets/single_select_dialog.dart';
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
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(l10n.addAccountDialogTitle),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 250),
            child: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: l10n.accountNameHint,
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? l10n.formValidationPleaseEnterName
                        : null,
                  ),
                  // Hide Description
                  /*
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(labelText: l10n.descriptionLabel),
                  maxLines: 3,
                  keyboardType: TextInputType.multiline,
                ),
                */
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
                                        (c) => c.code == _selectedCurrencyCode,
                                      ),
                                  itemBuilder: (currency) =>
                                      Text(currency.name),
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
                                          d.currencyCode ==
                                          _selectedCurrencyCode,
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
                              validator: (value) =>
                                  _selectedCurrencyCode == null
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
                    // Automatic selection of first account type if none selected
                    builder: (context, state) {
                      if (state is AccountsLoadSuccess) {
                        if (_selectedAccountTypeId == null &&
                            state.accountTypes.isNotEmpty) {
                          _selectedAccountTypeId = state.accountTypes.first.id;
                        }
                        return const SizedBox.shrink(); // Hide Account Type
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  BlocBuilder<SettingsBloc, SettingsState>(
                    builder: (context, state) {
                      final localizedCountryName = _selectedCountry != null
                          ? getLocalizedCountryName(
                              _selectedCountry!,
                              state.settings['language_code'] ?? 'en',
                            )
                          : null;

                      return GestureDetector(
                        onTap: () async {
                          final selectedCode = await showDialog<String>(
                            context: context,
                            builder: (context) => CountryPickerDialog(
                              allCountries: state.countries,
                              selectedCountryCode: _selectedCountry,
                            ),
                          );

                          if (mounted && selectedCode != null) {
                            setState(() {
                              _selectedCountry = selectedCode;
                            });
                          }
                        },
                        child: AbsorbPointer(
                          child: TextFormField(
                            key: Key(_selectedCountry ?? 'no_country'),
                            initialValue: localizedCountryName,
                            decoration: InputDecoration(
                              labelText: l10n.defaultInflationCountryLabel,
                              hintText: l10n.selectCountryTitle,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
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
                              : const CircleAvatar(
                                  child: Icon(Icons.account_balance),
                                ),
                          title: Text(l10n.iconLabel),
                          subtitle: Text(
                            selectedStyle?.name ?? l10n.selectIconSubtitle,
                          ),
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
              // Guard against force-unwrap crash if currency/designation unresolved.
              if (_selectedCurrencyCode == null ||
                  _selectedCurrencyDesignationId == null ||
                  _selectedAccountTypeId == null) {
                return;
              }
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
