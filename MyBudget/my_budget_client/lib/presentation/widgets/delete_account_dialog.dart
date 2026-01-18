import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    final availableAccounts = widget.allAccounts
        .where((a) => a.id != widget.accountToDelete.id)
        .toList();

    return AlertDialog(
      title: Text('Delete ${widget.accountToDelete.name}?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This account may have associated transactions. What would you like to do?',
            ),
            const SizedBox(height: 16),
            if (availableAccounts.isNotEmpty) ...[
              RadioListTile<DeleteAccountOption>(
                title: const Text('Reassign transactions to another account'),
                value: DeleteAccountOption.reassign,
                groupValue: _selectedOption,
                onChanged: (value) {
                  setState(() {
                    _selectedOption = value!;
                  });
                },
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
                    decoration: const InputDecoration(
                      labelText: 'New Account',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
            ],
            RadioListTile<DeleteAccountOption>(
              title: const Text('Delete all associated transactions'),
              value: DeleteAccountOption.delete,
              groupValue: _selectedOption,
              onChanged: (value) {
                setState(() {
                  _selectedOption = value!;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
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
            'Delete',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    );
  }
}
