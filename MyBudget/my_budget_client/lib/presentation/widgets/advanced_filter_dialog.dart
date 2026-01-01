import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/category_with_total.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/transaction_type_filter.dart';
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
      return AdvancedFilterDialog(currentFilters: currentFilters);
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
  late final TextEditingController _amountFromController;
  late final TextEditingController _amountToController;
  String? _selectedAccountId;
  String? _selectedCategoryId;
  String? _selectedCurrencyCode;
  late TransactionTypeFilter _selectedTransactionType;
  late bool _persistFilters;

  @override
  void initState() {
    super.initState();
    final settingsBloc = context.read<SettingsBloc>();
    _persistFilters =
        settingsBloc.state.settings['persist_advanced_filters'] == 'true';

    TransactionFilters filters;
    if (_persistFilters) {
      final settings = settingsBloc.state.settings;
      final accountId = settings['advanced_filter_account_id'];
      final categoryId = settings['advanced_filter_category_id'];
      final currencyCode = settings['advanced_filter_currency_code'];
      final transactionType = TransactionTypeFilter.values.firstWhere(
        (e) => e.toString() == settings['advanced_filter_transaction_type'],
        orElse: () => TransactionTypeFilter.all,
      );
      filters = TransactionFilters(
        description: settings['advanced_filter_description'],
        amountFrom:
            double.tryParse(settings['advanced_filter_amount_from'] ?? ''),
        amountTo: double.tryParse(settings['advanced_filter_amount_to'] ?? ''),
        accountId: accountId != null && accountId.isNotEmpty ? accountId : null,
        categoryId:
            categoryId != null && categoryId.isNotEmpty ? categoryId : null,
        currencyCode: currencyCode != null && currencyCode.isNotEmpty
            ? currencyCode
            : null,
        transactionType: transactionType,
      );
    } else {
      filters = widget.currentFilters;
    }

    _descriptionController = TextEditingController(text: filters.description);
    _amountFromController =
        TextEditingController(text: filters.amountFrom?.toString());
    _amountToController =
        TextEditingController(text: filters.amountTo?.toString());
    _selectedAccountId = filters.accountId;
    _selectedCategoryId = filters.categoryId;
    _selectedCurrencyCode = filters.currencyCode;
    _selectedTransactionType = filters.transactionType;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountFromController.dispose();
    _amountToController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final settingsBloc = context.read<SettingsBloc>();
    settingsBloc.add(UpdateSetting(
        'persist_advanced_filters', _persistFilters.toString()));

    final newFilters = TransactionFilters(
      description: _descriptionController.text.isNotEmpty
          ? _descriptionController.text
          : null,
      amountFrom: _amountFromController.text.isNotEmpty
          ? double.tryParse(_amountFromController.text)
          : null,
      amountTo: _amountToController.text.isNotEmpty
          ? double.tryParse(_amountToController.text)
          : null,
      accountId: _selectedAccountId,
      categoryId: _selectedCategoryId,
      currencyCode: _selectedCurrencyCode,
      transactionType: _selectedTransactionType,
    );

    if (_persistFilters) {
      settingsBloc.add(UpdateSetting(
          'advanced_filter_description', newFilters.description ?? ''));
      settingsBloc.add(UpdateSetting('advanced_filter_amount_from',
          newFilters.amountFrom?.toString() ?? ''));
      settingsBloc.add(UpdateSetting(
          'advanced_filter_amount_to', newFilters.amountTo?.toString() ?? ''));
      settingsBloc.add(UpdateSetting(
          'advanced_filter_account_id', newFilters.accountId ?? ''));
      settingsBloc.add(UpdateSetting(
          'advanced_filter_category_id', newFilters.categoryId ?? ''));
      settingsBloc.add(UpdateSetting(
          'advanced_filter_currency_code', newFilters.currencyCode ?? ''));
      settingsBloc.add(UpdateSetting('advanced_filter_transaction_type',
          newFilters.transactionType.toString()));
    } else {
      // Clear settings if persistence is disabled
      _clearFilterSettings();
    }

    context.read<TransactionsBloc>().add(NonDateFiltersChanged(newFilters));
    Navigator.of(context).pop();
  }

  void _clearFilters() {
    _clearFilterSettings();
    context
        .read<TransactionsBloc>()
        .add(const NonDateFiltersChanged(TransactionFilters()));
    Navigator.of(context).pop();
  }

  void _clearFilterSettings() {
    final settingsBloc = context.read<SettingsBloc>();
    settingsBloc.add(const UpdateSetting('advanced_filter_description', ''));
    settingsBloc.add(const UpdateSetting('advanced_filter_amount_from', ''));
    settingsBloc.add(const UpdateSetting('advanced_filter_amount_to', ''));
    settingsBloc.add(const UpdateSetting('advanced_filter_account_id', ''));
    settingsBloc.add(const UpdateSetting('advanced_filter_category_id', ''));
    settingsBloc.add(const UpdateSetting('advanced_filter_currency_code', ''));
    settingsBloc.add(
        const UpdateSetting('advanced_filter_transaction_type', ''));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Advanced Filters'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Persist Filters'),
                Switch(
                  value: _persistFilters,
                  onChanged: (value) {
                    setState(() {
                      _persistFilters = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TransactionTypeFilter>(
              initialValue: _selectedTransactionType,
              decoration: const InputDecoration(labelText: 'Transaction Type'),
              items: TransactionTypeFilter.values
                  .map((TransactionTypeFilter type) {
                return DropdownMenuItem<TransactionTypeFilter>(
                  value: type,
                  child: Text(type.name),
                );
              }).toList(),
              onChanged: (TransactionTypeFilter? newValue) {
                setState(() {
                  _selectedTransactionType = newValue!;
                });
              },
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Search description...',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountFromController,
              decoration: const InputDecoration(labelText: 'Amount From'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountToController,
              decoration: const InputDecoration(labelText: 'Amount To'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            BlocBuilder<AccountsBloc, AccountsState>(
              builder: (context, state) {
                return DropdownButtonFormField<String>(
                  initialValue: _selectedAccountId,
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
                    initialValue: _selectedCategoryId,
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
                  initialValue: _selectedCurrencyCode,
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
          onPressed: _clearFilters,
          child: const Text('Clear'),
        ),
        TextButton(
          onPressed: _applyFilters,
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
