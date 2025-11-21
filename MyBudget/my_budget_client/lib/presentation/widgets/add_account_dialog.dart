import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency/currency_bloc.dart';

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
  int? _selectedCurrencyId;
  int? _selectedCurrencyDesignationId;
  int? _selectedStyleId;
  int? _selectedAccountTypeId; // ADDED

  @override
  void initState() {
    super.initState();
    _descriptionController.text = ''; // Initialize
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _descriptionController.dispose(); // ADDED
    super.dispose();
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
                decoration:
                    const InputDecoration(labelText: 'Description'), // TODO: Localize
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
                    // Initialize selected currency and designation
                    if (_selectedCurrencyId == null &&
                        state.currencies.isNotEmpty) {
                      _selectedCurrencyId = state.currencies.first.id;
                      // Find first designation for the default currency
                      final firstDesignation = state.designations
                          .firstWhereOrNull(
                              (d) => d.currencyId == _selectedCurrencyId);
                      _selectedCurrencyDesignationId = firstDesignation?.id;
                    }

                    // Filter designations based on selected currency
                    final availableDesignations = state.designations
                        .where((d) => d.currencyId == _selectedCurrencyId)
                        .toList();

                    // Ensure a valid designation is selected if the current one is no longer available
                    if (_selectedCurrencyDesignationId != null &&
                        !availableDesignations
                            .any((d) => d.id == _selectedCurrencyDesignationId)) {
                      _selectedCurrencyDesignationId =
                          availableDesignations.first.id;
                    }

                    return Column(
                      // Wrap in Column to add designation dropdown
                      children: [
                        DropdownButtonFormField<int>(
                          initialValue: _selectedCurrencyId,
                          decoration:
                              InputDecoration(labelText: l10n.currencyLabel),
                          items: state.currencies
                              .map((c) => DropdownMenuItem<int>(
                                  value: c.id, child: Text(c.code)))
                              .toList(),
                          onChanged: (v) {
                            setState(() {
                              _selectedCurrencyId = v;
                              // Update selected designation when currency changes
                              _selectedCurrencyDesignationId = state
                                  .designations
                                  .firstWhereOrNull(
                                      (d) => d.currencyId == _selectedCurrencyId)
                                  ?.id;
                            });
                          },
                          validator: (v) => v == null
                              ? l10n.formValidationPleaseSelectCurrency
                              : null,
                        ),
                        const SizedBox(height: 16), // Spacing
                        DropdownButtonFormField<int>(
                          initialValue: _selectedCurrencyDesignationId,
                          decoration: const InputDecoration(
                              labelText: 'Currency Symbol'), // TODO: Localize
                          items: availableDesignations
                              .map((d) => DropdownMenuItem<int>(
                                  value: d.id, child: Text(d.value)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedCurrencyDesignationId = v),
                          validator: (v) =>
                              v == null ? 'Please select a symbol' : null, // TODO: Localize
                        ),
                      ],
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
              BlocBuilder<AccountsBloc, AccountsState>(
                // NEW BLOC BUILDER FOR AccountTypes
                builder: (context, state) {
                  if (state is AccountsLoadSuccess) {
                    if (_selectedAccountTypeId == null &&
                        state.accountTypes.isNotEmpty) {
                      _selectedAccountTypeId = state.accountTypes.first.id;
                    }
                    return DropdownButtonFormField<int>(
                      initialValue: _selectedAccountTypeId,
                      decoration: const InputDecoration(
                          labelText: 'Account Type'), // TODO: Localize
                      items: state.accountTypes
                          .map((type) => DropdownMenuItem<int>(
                              value: type.id, child: Text(type.name)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedAccountTypeId = v),
                      validator: (v) =>
                          v == null ? 'Please select an account type' : null, // TODO: Localize
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              BlocBuilder<StylesBloc, StylesState>(
                builder: (context, state) {
                  if (state is StylesLoadSuccess) {
                    _selectedStyleId ??= state.styles.first.id;
                    return DropdownButtonFormField<int>(
                      initialValue: _selectedStyleId,
                      decoration: const InputDecoration(
                          labelText: 'Style'), // TODO: Localize
                      items: state.styles
                          .map((s) => DropdownMenuItem<int>(
                              value: s.id, child: Text(s.name)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedStyleId = v),
                      validator: (v) =>
                          v == null ? 'Please select a style' : null, // TODO: Localize
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
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final newAccount = Account(
                name: _nameController.text,
                description: _descriptionController.text.isEmpty
                    ? null
                    : _descriptionController.text, // ADDED
                balance: double.parse(_balanceController.text),
                currencyId: _selectedCurrencyId!,
                currencyDesignationId: _selectedCurrencyDesignationId!,
                styleId: _selectedStyleId,
                accountTypeId: _selectedAccountTypeId!, // ADDED
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
