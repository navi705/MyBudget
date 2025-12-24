import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency/currency_bloc.dart';

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
    _descriptionController =
        TextEditingController(text: _initialAccount.description ?? '');
    _balanceController =
        TextEditingController(text: _initialAccount.balance.toString());
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

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      final updatedAccount = Account(
        id: _initialAccount.id,
        name: _nameController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text, // ADDED
        balance: double.parse(_balanceController.text),
        currencyCode: _selectedCurrencyCode!,
        currencyDesignationId: _selectedCurrencyDesignationId!,
        styleId: _selectedStyleId,
        accountTypeId: _selectedAccountTypeId!, // ADDED
      );

      // Only dispatch an update if the account has actually changed.
      // This now works correctly due to Equatable.
      if (updatedAccount != _initialAccount) {
        context.read<AccountsBloc>().add(UpdateAccount(updatedAccount));
      }
      // Always pop the screen after the save attempt (or no-op save).
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit: ${_initialAccount.name}'),
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
              const SizedBox(height: 16),
              BlocBuilder<CurrencyBloc, CurrencyState>(
                builder: (context, state) {
                  if (state is CurrencyLoadSuccess) {
                    // Filter designations based on selected currency
                    final availableDesignations = state.designations
                        .where((d) => d.currencyCode == _selectedCurrencyCode)
                        .toList();

                    // Ensure a valid designation is selected if the current one is no longer available
                    if (_selectedCurrencyDesignationId != null &&
                        !availableDesignations.any(
                            (d) => d.id == _selectedCurrencyDesignationId)) {
                      _selectedCurrencyDesignationId =
                          availableDesignations.first.id;
                    }

                    return Column(
                      // Wrap in Column to add designation dropdown
                      children: [
                        DropdownButtonFormField<String>(
                          value: _selectedCurrencyCode,
                          decoration:
                              InputDecoration(labelText: l10n.currencyLabel),
                          items: state.currencies
                              .map((c) => DropdownMenuItem<String>(
                                  value: c.code, child: Text(c.code)))
                              .toList(),
                          onChanged: (v) {
                            setState(() {
                              _selectedCurrencyCode = v;
                              // Update selected designation when currency changes
                              _selectedCurrencyDesignationId = state
                                  .designations
                                  .firstWhereOrNull((d) =>
                                      d.currencyCode == _selectedCurrencyCode)
                                  ?.id;
                            });
                          },
                          validator: (v) => v == null
                              ? l10n.formValidationPleaseSelectCurrency
                              : null,
                        ),
                        const SizedBox(height: 16),
                        // Spacing
                        DropdownButtonFormField<String>(
                          value: _selectedCurrencyDesignationId,
                          decoration: const InputDecoration(
                              labelText: 'Currency Symbol'),
                          // TODO: Localize
                          items: availableDesignations
                              .map((d) => DropdownMenuItem<String>(
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
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 16),
              BlocBuilder<AccountsBloc, AccountsState>(
                // NEW BLOC BUILDER FOR AccountTypes
                builder: (context, state) {
                  if (state is AccountsLoadSuccess) {
                    return DropdownButtonFormField<String>(
                      value: _selectedAccountTypeId,
                      decoration:
                          const InputDecoration(labelText: 'Account Type'),
                      // TODO: Localize
                      items: state.accountTypes
                          .map((type) => DropdownMenuItem<String>(
                              value: type.id, child: Text(type.name)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedAccountTypeId = v),
                      validator: (v) => v == null
                          ? 'Please select an account type'
                          : null, // TODO: Localize
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 16),
              // Added spacing for new field
              BlocBuilder<StylesBloc, StylesState>(
                builder: (context, state) {
                  if (state is StylesLoadSuccess) {
                    return DropdownButtonFormField<String>(
                      value: _selectedStyleId,
                      decoration: const InputDecoration(labelText: 'Style'),
                      // TODO: Localize
                      items: state.styles
                          .map((s) => DropdownMenuItem<String>(
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
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _onSave,
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50)),
                child: Text(l10n.saveButton),
              )
            ],
          ),
        ),
      ),
    );
  }
}

