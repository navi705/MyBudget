import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/core/utils/icon_utils.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/style.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency/currency_bloc.dart';
import 'package:my_budget_client/presentation/widgets/style_picker_dialog.dart';

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
      if (updatedAccount != _initialAccount) {
        context.read<AccountsBloc>().add(UpdateAccount(updatedAccount));
      }
      context.pop();
    }
  }

  void _onDelete() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text(
            'Are you sure you want to delete "${_initialAccount.name}"? This will also delete all associated transactions.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context
                  .read<AccountsBloc>()
                  .add(DeleteAccount(_initialAccount.id!));
              Navigator.of(dialogContext).pop();
              context.pop();
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
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
                builder: (context, state) {
                  if (state is AccountsLoadSuccess) {
                    // This is a workaround for a bug where duplicate account types are present in the state.
                    // The root cause should be investigated in the AccountsBloc.
                    final seenIds = <String>{};
                    final uniqueAccountTypes = state.accountTypes.where((type) => seenIds.add(type.id)).toList();

                    // Check if the current value is still valid after de-duplication.
                    final selectedValue = uniqueAccountTypes
                            .any((type) => type.id == _selectedAccountTypeId)
                        ? _selectedAccountTypeId
                        : null;

                    return DropdownButtonFormField<String>(
                      value: selectedValue,
                      decoration:
                          const InputDecoration(labelText: 'Account Type'),
                      items: uniqueAccountTypes
                          .map((type) => DropdownMenuItem<String>(
                              value: type.id, child: Text(type.name)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedAccountTypeId = v),
                      validator: (v) => v == null
                          ? 'Please select an account type'
                          : null,
                    );
                  }
                  return const SizedBox.shrink();
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
                              backgroundColor: _getColorFromHex(selectedStyle.colorHex),
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

