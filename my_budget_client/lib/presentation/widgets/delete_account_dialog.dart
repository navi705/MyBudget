import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';

enum DeleteAccountOption { reassign, delete }

class DeleteAccountDialog extends StatefulWidget {
  final Account accountToDelete;
  final List<Account> allAccounts;

  const DeleteAccountDialog({
    super.key,
    required this.accountToDelete,
    required this.allAccounts,
  });

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  DeleteAccountOption _selectedOption = DeleteAccountOption.reassign;
  String? _newAccountId;

  @override
  void initState() {
    super.initState();
    // Default to first available account if any
    final available = widget.allAccounts
        .where((a) => a.id != widget.accountToDelete.id)
        .toList();
    if (available.isNotEmpty) {
      _newAccountId = available.first.id;
    } else {
      // If no other accounts, force delete option
      _selectedOption = DeleteAccountOption.delete;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final availableAccounts = widget.allAccounts
        .where((a) => a.id != widget.accountToDelete.id)
        .toList();

    return AlertDialog(
      title: Text(l10n.deleteAccountConfirmTitle(widget.accountToDelete.name)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.deleteAccountMessage),
            const SizedBox(height: 16),
            RadioGroup<DeleteAccountOption>(
              groupValue: _selectedOption,
              onChanged: (value) {
                setState(() {
                  _selectedOption = value!;
                });
              },
              child: Column(
                children: [
                  if (availableAccounts.isNotEmpty) ...[
                    RadioListTile<DeleteAccountOption>(
                      title: Text(l10n.deleteAccountReassign),
                      value: DeleteAccountOption.reassign,
                    ),
                    if (_selectedOption == DeleteAccountOption.reassign)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: DropdownButtonFormField<String>(
                          initialValue: _newAccountId,
                          items: availableAccounts
                              .map(
                                (a) => DropdownMenuItem(
                                  value: a.id,
                                  child: Text(a.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _newAccountId = value;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: l10n.deleteAccountNewAccount,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                  ],
                  RadioListTile<DeleteAccountOption>(
                    title: Text(l10n.deleteAccountDeleteAll),
                    value: DeleteAccountOption.delete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        FilledButton.tonal(
          onPressed: () {
            if (_selectedOption == DeleteAccountOption.reassign &&
                _newAccountId == null) {
              return;
            }

            if (_selectedOption == DeleteAccountOption.reassign) {
              context.read<AccountsBloc>().add(
                DeleteAccountAndReassign(
                  widget.accountToDelete.id!,
                  _newAccountId!,
                ),
              );
            } else {
              context.read<AccountsBloc>().add(
                DeleteAccountWithTransactions(widget.accountToDelete.id!),
              );
            }
            Navigator.of(context).pop();
          },
          child: Text(
            l10n.deleteButton,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    );
  }
}
