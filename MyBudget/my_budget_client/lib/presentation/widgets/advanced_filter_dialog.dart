import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/category_with_total.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/presentation/blocs/categories/categories_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency/currency_bloc.dart';
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';

void showAdvancedFilterDialog(
    BuildContext context, TransactionFilters currentFilters) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      // Use MultiBlocProvider.value to pass down the existing BLoCs.
      // This is the correct way to provide existing BLoC instances to a new route/dialog.
      return MultiBlocProvider(
        providers: [
          BlocProvider.value(
            value: BlocProvider.of<TransactionsBloc>(context),
          ),
          BlocProvider.value(
            value: BlocProvider.of<AccountsBloc>(context),
          ),
          BlocProvider.value(
            value: BlocProvider.of<CategoriesBloc>(context),
          ),
          BlocProvider.value(
            value: BlocProvider.of<CurrencyBloc>(context),
          ),
          BlocProvider.value(value: BlocProvider.of<SettingsBloc>(context)),
          
        ],
        child: AdvancedFilterDialog(currentFilters: currentFilters),
      );
    },
  );
}

class AdvancedFilterDialog extends StatefulWidget {
  final TransactionFilters currentFilters;

  const AdvancedFilterDialog({super.key, required this.currentFilters});

  @override
  State<AdvancedFilterDialog> createState() => _AdvancedFilterDialogState();
}

class _AdvancedFilterDialogState extends State<AdvancedFilterDialog> {
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;
  String? _selectedAccountId;
  String? _selectedCategoryId;
  String? _selectedCurrencyCode;

  @override
  void initState() {
    super.initState();
    final filters = widget.currentFilters;
    _descriptionController = TextEditingController(text: filters.description);
    _amountController = TextEditingController(text: filters.amount?.toString());
    _selectedAccountId = filters.accountId;
    _selectedCategoryId = filters.categoryId;
    _selectedCurrencyCode = filters.currencyCode;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Advanced Filters'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Search description...',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            BlocBuilder<AccountsBloc, AccountsState>(
              builder: (context, state) {
                return DropdownButtonFormField<String>(
                  value: _selectedAccountId,
                  decoration: const InputDecoration(labelText: 'Account'),
                  items: state.accounts
                      .map((Account account) => DropdownMenuItem(
                            value: account.id,
                            child: Text(account.name),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedAccountId = value;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),
             BlocBuilder<CategoriesBloc, CategoriesState>(
              builder: (context, state) {
                if (state is CategoriesLoadSuccess) {
                  return DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: state.categoriesWithTotals
                        .map((CategoryWithTotal categoryWithTotal) =>
                            DropdownMenuItem<String>(
                              value: categoryWithTotal.category.id,
                              child: Text(categoryWithTotal.category.name),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoryId = value;
                      });
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 16),
            BlocBuilder<CurrencyBloc, CurrencyState>(
              builder: (context, state) {
                return DropdownButtonFormField<String>(
                  value: _selectedCurrencyCode,
                  decoration: const InputDecoration(labelText: 'Currency'),
                  items: state.currencies
                      .map((Currency currency) => DropdownMenuItem(
                            value: currency.code,
                            child: Text(currency.code),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCurrencyCode = value;
                    });
                  },
                );
              },
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Clear'),
          onPressed: () {
            context
                .read<TransactionsBloc>()
                .add(const NonDateFiltersChanged(TransactionFilters()));
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('Apply'),
          onPressed: () {
            final newFilters = TransactionFilters(
              description: _descriptionController.text.isNotEmpty
                  ? _descriptionController.text
                  : null,
              amount: _amountController.text.isNotEmpty
                  ? double.tryParse(_amountController.text)
                  : null,
              accountId: _selectedAccountId,
              categoryId: _selectedCategoryId,
              currencyCode: _selectedCurrencyCode,
            );

            context
                .read<TransactionsBloc>()
                .add(NonDateFiltersChanged(newFilters));
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
