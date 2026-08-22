import 'package:my_budget_client/core/utils/decimal_input.dart';
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
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';
import 'package:my_budget_client/presentation/widgets/multi_select_dialog.dart';
import 'package:my_budget_client/core/utils/dialog_utils.dart';
import 'package:my_budget_client/core/utils/icon_utils.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
import 'package:collection/collection.dart';

void showAdvancedFilterDialog(
  BuildContext context,
  TransactionFilters currentFilters,
) {
  DialogUtils.showAppDialog(
    context: context,
    resizeToAvoidBottomInset: false,
    child: AdvancedFilterDialog(currentFilters: currentFilters),
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
  List<String> _selectedAccountId = [];
  List<String> _selectedCategoryId = [];
  List<String> _selectedCurrencyCode = [];
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
      final accountId = settings['advanced_filter_account_id']?.split(',');
      final categoryId = settings['advanced_filter_category_id']?.split(',');
      final currencyCode = settings['advanced_filter_currency_code']?.split(
        ',',
      );
      final transactionType = TransactionTypeFilter.values.firstWhere(
        (e) => e.toString() == settings['advanced_filter_transaction_type'],
        orElse: () => TransactionTypeFilter.all,
      );
      filters = TransactionFilters(
        description: settings['advanced_filter_description'],
        amountFrom: double.tryParse(
          settings['advanced_filter_amount_from'] ?? '',
        ),
        amountTo: double.tryParse(settings['advanced_filter_amount_to'] ?? ''),
        accountId: accountId,
        categoryId: categoryId,
        currencyCode: currencyCode,
        transactionType: transactionType,
      );
    } else {
      filters = widget.currentFilters;
    }

    _descriptionController = TextEditingController(text: filters.description);
    _amountFromController = TextEditingController(
      text: filters.amountFrom?.toString(),
    );
    _amountToController = TextEditingController(
      text: filters.amountTo?.toString(),
    );
    _selectedAccountId = filters.accountId ?? [];
    _selectedCategoryId = filters.categoryId ?? [];
    _selectedCurrencyCode = filters.currencyCode ?? [];
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
    settingsBloc.add(
      UpdateSetting('persist_advanced_filters', _persistFilters.toString()),
    );

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
      settingsBloc.add(
        UpdateSetting(
          'advanced_filter_description',
          newFilters.description ?? '',
        ),
      );
      settingsBloc.add(
        UpdateSetting(
          'advanced_filter_amount_from',
          newFilters.amountFrom?.toString() ?? '',
        ),
      );
      settingsBloc.add(
        UpdateSetting(
          'advanced_filter_amount_to',
          newFilters.amountTo?.toString() ?? '',
        ),
      );
      settingsBloc.add(
        UpdateSetting(
          'advanced_filter_account_id',
          newFilters.accountId?.join(',') ?? '',
        ),
      );
      settingsBloc.add(
        UpdateSetting(
          'advanced_filter_category_id',
          newFilters.categoryId?.join(',') ?? '',
        ),
      );
      settingsBloc.add(
        UpdateSetting(
          'advanced_filter_currency_code',
          newFilters.currencyCode?.join(',') ?? '',
        ),
      );
      settingsBloc.add(
        UpdateSetting(
          'advanced_filter_transaction_type',
          newFilters.transactionType.toString(),
        ),
      );
    } else {
      // Clear settings if persistence is disabled
      _clearFilterSettings();
    }

    context.read<TransactionsBloc>().add(NonDateFiltersChanged(newFilters));
    Navigator.of(context).pop();
  }

  void _clearFilters() {
    _clearFilterSettings();
    context.read<TransactionsBloc>().add(
      const NonDateFiltersChanged(TransactionFilters()),
    );
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
      const UpdateSetting('advanced_filter_transaction_type', ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.advancedFiltersTitle),
      content: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(context.l10n.persistFiltersLabel),
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
                decoration: InputDecoration(
                  labelText: context.l10n.transactionTypeLabel,
                ),
                items: TransactionTypeFilter.values.map((
                  TransactionTypeFilter type,
                ) {
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
                decoration: InputDecoration(
                  labelText: context.l10n.descriptionLabel,
                  hintText: context.l10n.searchDescriptionHint,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountFromController,
                decoration: InputDecoration(
                  labelText: context.l10n.fltAmountFrom,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: signedDecimalInputFormatters,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountToController,
                decoration: InputDecoration(
                  labelText: context.l10n.fltAmountTo,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: signedDecimalInputFormatters,
              ),
              const SizedBox(height: 16),
              BlocBuilder<AccountsBloc, AccountsState>(
                builder: (context, state) {
                  return ListTile(
                    title: Text(context.l10n.accountLabel),
                    subtitle: Wrap(
                      spacing: 4.0,
                      runSpacing: 4.0,
                      children: _selectedAccountId.map((accountId) {
                        final account = state.accounts.firstWhereOrNull(
                          (acc) => acc.id == accountId,
                        );
                        if (account == null) {
                          return const SizedBox.shrink();
                        }
                        return Chip(
                          label: Text(account.name),
                          avatar: BlocBuilder<StylesBloc, StylesState>(
                            builder: (context, stylesState) {
                              if (stylesState is StylesLoadSuccess) {
                                final style = stylesState.styles
                                    .firstWhereOrNull(
                                      (s) => s.id == account.styleId,
                                    );
                                if (style != null) {
                                  return IconUtils.getIconWidget(style);
                                }
                              }
                              return const Icon(Icons.account_balance);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    onTap: () async {
                      final selectedIds = await showDialog<List<String>>(
                        context: context,
                        builder: (_) => BlocProvider.value(
                          value: context.read<StylesBloc>(),
                          child: MultiSelectDialog<Account, String>(
                            items: state.accounts,
                            selectedIds: _selectedAccountId,
                            itemBuilder: (item) => Row(
                              children: [
                                BlocBuilder<StylesBloc, StylesState>(
                                  builder: (context, stylesState) {
                                    if (stylesState is StylesLoadSuccess) {
                                      final style = stylesState.styles
                                          .firstWhereOrNull(
                                            (s) => s.id == item.styleId,
                                          );
                                      if (style != null) {
                                        return IconUtils.getIconWidget(style);
                                      }
                                    }
                                    return const Icon(Icons.account_balance);
                                  },
                                ),
                                const SizedBox(width: 8),
                                Text(item.name),
                              ],
                            ),
                            idGetter: (item) => item.id!,
                            stringGetter: (item) => item.name,
                          ),
                        ),
                      );

                      if (selectedIds != null) {
                        setState(() {
                          _selectedAccountId = selectedIds;
                        });
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              BlocBuilder<CategoriesBloc, CategoriesState>(
                builder: (context, state) {
                  if (state is CategoriesLoadSuccess) {
                    return ListTile(
                      title: Text(context.l10n.categoryLabel),
                      subtitle: Wrap(
                        spacing: 4.0,
                        runSpacing: 4.0,
                        children: _selectedCategoryId.map((categoryId) {
                          final categoryWithTotal = state.categoriesWithTotals
                              .firstWhereOrNull(
                                (cat) => cat.category.id == categoryId,
                              );
                          if (categoryWithTotal == null) {
                            return const SizedBox.shrink();
                          }
                          return Chip(
                            label: Text(categoryWithTotal.category.name),
                            avatar: BlocBuilder<StylesBloc, StylesState>(
                              builder: (context, stylesState) {
                                if (stylesState is StylesLoadSuccess) {
                                  final style = stylesState.styles
                                      .firstWhereOrNull(
                                        (s) =>
                                            s.id ==
                                            categoryWithTotal.category.styleId,
                                      );
                                  if (style != null) {
                                    return IconUtils.getIconWidget(style);
                                  }
                                }
                                return const Icon(Icons.category);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                      onTap: () async {
                        final selectedIds = await showDialog<List<String>>(
                          context: context,
                          builder: (_) => BlocProvider.value(
                            value: context.read<StylesBloc>(),
                            child: MultiSelectDialog<CategoryWithTotal, String>(
                              items: state.categoriesWithTotals,
                              selectedIds: _selectedCategoryId,
                              itemBuilder: (item) => Row(
                                children: [
                                  BlocBuilder<StylesBloc, StylesState>(
                                    builder: (context, stylesState) {
                                      if (stylesState is StylesLoadSuccess) {
                                        final style = stylesState.styles
                                            .firstWhereOrNull(
                                              (s) =>
                                                  s.id == item.category.styleId,
                                            );
                                        if (style != null) {
                                          return IconUtils.getIconWidget(style);
                                        }
                                      }
                                      return const Icon(Icons.category);
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  Text(item.category.name),
                                ],
                              ),
                              idGetter: (item) => item.category.id!,
                              stringGetter: (item) => item.category.name,
                            ),
                          ),
                        );

                        if (selectedIds != null) {
                          setState(() {
                            _selectedCategoryId = selectedIds;
                          });
                        }
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 16),
              BlocBuilder<CurrencyBloc, CurrencyState>(
                builder: (context, state) {
                  if (state is CurrencyLoadSuccess) {
                    return ListTile(
                      title: Text(context.l10n.currencyLabel),
                      subtitle: Wrap(
                        spacing: 4.0,
                        runSpacing: 4.0,
                        children: _selectedCurrencyCode.map((code) {
                          final currency = state.currencies.firstWhereOrNull(
                            (curr) => curr.code == code,
                          );
                          if (currency == null) {
                            return const SizedBox.shrink();
                          }
                          return Chip(label: Text(currency.name));
                        }).toList(),
                      ),
                      onTap: () async {
                        final selectedIds = await showDialog<List<String>>(
                          context: context,
                          builder: (_) => MultiSelectDialog<Currency, String>(
                            items: state.currencies,
                            selectedIds: _selectedCurrencyCode,
                            itemBuilder: (item) => Text(item.name),
                            idGetter: (item) => item.code,
                            stringGetter: (item) => '${item.name} ${item.code}',
                          ),
                        );

                        if (selectedIds != null) {
                          setState(() {
                            _selectedCurrencyCode = selectedIds;
                          });
                        }
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _clearFilters,
          child: Text(context.l10n.clearButton),
        ),
        TextButton(
          onPressed: _applyFilters,
          child: Text(context.l10n.applyButton),
        ),
      ],
    );
  }
}
