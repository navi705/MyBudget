import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
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
  final _balanceController = TextEditingController();
  int? _selectedCurrencyId;

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.addAccountDialogTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.accountNameHint,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.formValidationPleaseEnterName;
                }
                return null;
              },
            ),
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
                if (state is CurrencyLoadInProgress) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is CurrencyLoadFailure) {
                  return Text(l10n.currencyLoadError);
                }
                if (state is CurrencyLoadSuccess) {
                  if (state.currencies.isEmpty) {
                    return Text(l10n.noCurrenciesAvailable);
                  }
                  _selectedCurrencyId ??= state.currencies.first.id;
                  return DropdownButtonFormField<int>(
                    value: _selectedCurrencyId,
                    decoration: InputDecoration(
                      labelText: l10n.currencyLabel,
                    ),
                    items: state.currencies.map((currency) {
                      return DropdownMenuItem<int>(
                        value: currency.id,
                        child: Text(currency.code),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedCurrencyId = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return l10n.formValidationPleaseSelectCurrency;
                      }
                      return null;
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
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
                balance: double.parse(_balanceController.text),
                currencyId: _selectedCurrencyId!,
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
