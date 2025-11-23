import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/presentation/blocs/categories/categories_bloc.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';

class AddEditTransactionScreen extends StatefulWidget {
  final String? transactionId;
  final String? categoryId;

  const AddEditTransactionScreen(
      {super.key, this.transactionId, this.categoryId});

  @override
  State<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  String? _selectedAccountId;
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  Transaction? _existingTransaction;

  @override
  void initState() {
    super.initState();

    if (widget.transactionId != null) {
      final state = context.read<TransactionsBloc>().state;
      if (state is TransactionsLoadSuccess) {
        _existingTransaction = state.transactions
            .firstWhereOrNull((t) => t.id == widget.transactionId);
      }
    }

    _descriptionController =
        TextEditingController(text: _existingTransaction?.description);
    _amountController =
        TextEditingController(text: _existingTransaction?.amount.toString());
    _selectedAccountId = _existingTransaction?.accountId;
    _selectedCategoryId =
        _existingTransaction?.categoryId ?? widget.categoryId;
    _selectedDate = _existingTransaction?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      final description = _descriptionController.text;
      final amount = double.parse(_amountController.text);

      final accountsState = context.read<AccountsBloc>().state;
      if (accountsState is! AccountsLoadSuccess) return;

      final selectedAccount = accountsState.accounts
          .firstWhereOrNull((acc) => acc.id == _selectedAccountId);

      if (selectedAccount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not find selected account.')),
        );
        return;
      }

      if (_existingTransaction == null) {
        final newTransaction = Transaction(
          description: description,
          amount: amount,
          date: _selectedDate,
          accountId: _selectedAccountId!,
          categoryId: _selectedCategoryId!,
          currencyCode: selectedAccount.currencyCode,
        );
        context.read<TransactionsBloc>().add(AddTransaction(newTransaction));
      } else {
        final updatedTransaction = _existingTransaction!.copyWith(
          id: _existingTransaction!.id,
          description: description,
          amount: amount,
          date: _selectedDate,
          accountId: _selectedAccountId,
          categoryId: _selectedCategoryId,
          currencyCode: selectedAccount.currencyCode,
        );
        context
            .read<TransactionsBloc>()
            .add(UpdateTransaction(updatedTransaction));
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_existingTransaction == null
            ? 'Add Transaction'
            : 'Edit Transaction'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Please enter a description'
                    : null,
              ),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              BlocBuilder<AccountsBloc, AccountsState>(
                builder: (context, state) {
                  if (state is AccountsLoadSuccess) {
                    return DropdownButtonFormField<String>(
                      initialValue: _selectedAccountId,
                      decoration: const InputDecoration(labelText: 'Account'),
                      items: state.accounts
                          .map((acc) => DropdownMenuItem<String>(
                                value: acc.id,
                                child: Text(acc.name),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedAccountId = v),
                      validator: (v) =>
                          v == null ? 'Please select an account' : null,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              BlocBuilder<CategoriesBloc, CategoriesState>(
                builder: (context, state) {
                  if (state is CategoriesLoadSuccess) {
                    return DropdownButtonFormField<String>(
                      initialValue: _selectedCategoryId,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: state.categories
                          .map((cat) => DropdownMenuItem<String>(
                                value: cat.id,
                                child: Text(cat.name),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCategoryId = v),
                      validator: (v) =>
                          v == null ? 'Please select a category' : null,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              ListTile(
                title: Text("Date: ${_selectedDate.toLocal()}".split(' ')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _onSave,
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50)),
                child: const Text('Save'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
