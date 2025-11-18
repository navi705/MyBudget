import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
import 'package:my_budget_client/presentation/blocs/account_styles/account_styles_bloc.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency/currency_bloc.dart';

class EditAccountScreen extends StatefulWidget {
  final String accountId;

  const EditAccountScreen({super.key, required this.accountId});

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _balanceController;
  int? _selectedCurrencyId;
  int? _selectedCurrencyDesignationId; // ADDED
  int? _selectedStyleId;

  Account? _initialAccount;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _balanceController = TextEditingController();

    final accountsState = context.read<AccountsBloc>().state;
    if (accountsState is AccountsLoadSuccess) {
      try {
        _initialAccount = accountsState.accounts.firstWhere(
          (acc) => acc.id.toString() == widget.accountId,
        );
        _nameController.text = _initialAccount!.name;
        _balanceController.text = _initialAccount!.balance.toString();
        _selectedCurrencyId = _initialAccount!.currencyId;
        _selectedCurrencyDesignationId = _initialAccount!.currencyDesignationId; // ADDED
        _selectedStyleId = _initialAccount!.styleId;
      } catch (e) {
        // Account not found, handle appropriately
        _initialAccount = null;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      final updatedAccount = Account(
        id: _initialAccount!.id,
        name: _nameController.text,
        balance: double.parse(_balanceController.text),
        currencyId: _selectedCurrencyId!,
        currencyDesignationId: _selectedCurrencyDesignationId!, // ADDED
        styleId: _selectedStyleId,
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

    if (_initialAccount == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Account not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit: ${_initialAccount!.name}'),
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
                validator: (value) => (value == null || value.isEmpty) ? l10n.formValidationPleaseEnterName : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _balanceController,
                decoration: InputDecoration(labelText: l10n.initialBalanceHint),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return l10n.formValidationPleaseEnterBalance;
                  if (double.tryParse(value) == null) return l10n.formValidationPleaseEnterValidNumber;
                  return null;
                },
              ),
              const SizedBox(height: 16),
              BlocBuilder<CurrencyBloc, CurrencyState>(
                builder: (context, state) {
                  if (state is CurrencyLoadSuccess) {
                    // Filter designations based on selected currency
                    final availableDesignations = state.designations
                        .where((d) => d.currencyId == _selectedCurrencyId)
                        .toList();

                    // Ensure a valid designation is selected if the current one is no longer available
                    if (_selectedCurrencyDesignationId != null &&
                        !availableDesignations.any((d) => d.id == _selectedCurrencyDesignationId)) {
                      _selectedCurrencyDesignationId = availableDesignations.first.id;
                    }


                    return Column( // Wrap in Column to add designation dropdown
                      children: [
                        DropdownButtonFormField<int>(
                          initialValue: _selectedCurrencyId,
                          decoration: InputDecoration(labelText: l10n.currencyLabel),
                          items: state.currencies.map((c) => DropdownMenuItem<int>(value: c.id, child: Text(c.code))).toList(),
                          onChanged: (v) {
                            setState(() {
                              _selectedCurrencyId = v;
                              // Update selected designation when currency changes
                              _selectedCurrencyDesignationId = state.designations
                                  .firstWhere((d) => d.currencyId == _selectedCurrencyId)
                                  .id;
                            });
                          },
                          validator: (v) => v == null ? l10n.formValidationPleaseSelectCurrency : null,
                        ),
                        const SizedBox(height: 16), // Spacing
                        DropdownButtonFormField<int>(
                          initialValue: _selectedCurrencyDesignationId,
                          decoration: const InputDecoration(labelText: 'Currency Symbol'), // TODO: Localize
                          items: availableDesignations.map((d) => DropdownMenuItem<int>(value: d.id, child: Text(d.value))).toList(),
                          onChanged: (v) => setState(() => _selectedCurrencyDesignationId = v),
                          validator: (v) => v == null ? 'Please select a symbol' : null, // TODO: Localize
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 16),
              BlocBuilder<AccountStylesBloc, AccountStylesState>(
                builder: (context, state) {
                  if (state is AccountStylesLoadSuccess) {
                    return DropdownButtonFormField<int>(
                      initialValue: _selectedStyleId,
                      decoration: const InputDecoration(labelText: 'Style'), // TODO: Localize
                      items: state.styles.map((s) => DropdownMenuItem<int>(value: s.id, child: Text(s.name))).toList(),
                      onChanged: (v) => setState(() => _selectedStyleId = v),
                      validator: (v) => v == null ? 'Please select a style' : null, // TODO: Localize
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _onSave,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: Text(l10n.saveButton),
              )
            ],
          ),
        ),
      ),
    );
  }
}
