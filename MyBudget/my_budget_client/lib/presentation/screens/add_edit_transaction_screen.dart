import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/core/di/injection_container.dart';
import 'package:my_budget_client/core/utils/icon_utils.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/icon_type.dart';
import 'package:my_budget_client/domain/entities/style.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/domain/repositories/asset_repository.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/presentation/blocs/add_edit_transaction/add_edit_transaction_bloc.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';
import 'package:my_budget_client/presentation/widgets/scaffold_with_escape_back.dart';
import 'package:my_budget_client/presentation/widgets/single_select_dialog.dart';

class AddEditTransactionScreen extends StatelessWidget {
  final Transaction? transaction;
  final String? accountId;
  final bool isTransfer;

  const AddEditTransactionScreen({
    super.key,
    this.transaction,
    this.accountId,
    this.isTransfer = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          AddEditTransactionBloc(
            transactionRepository: sl<TransactionRepository>(),
            accountRepository: sl<AccountRepository>(),
            categoryRepository: sl<CategoryRepository>(),
            currencyRepository: sl<CurrencyRepository>(),
            settingsRepository: sl<SettingsRepository>(),
            assetRepository: sl<AssetRepository>(),
          )..add(
            AddEditTransactionLoad(
              transaction: transaction,
              accountId: accountId,
              isTransfer: isTransfer,
            ),
          ),
      child: _AddEditTransactionView(),
    );
  }
}

class _AddEditTransactionView extends StatefulWidget {
  @override
  __AddEditTransactionViewState createState() =>
      __AddEditTransactionViewState();
}

class __AddEditTransactionViewState extends State<_AddEditTransactionView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;
  late final TextEditingController _feeController;
  late final TextEditingController _totalValueController;

  @override
  void initState() {
    super.initState();
    final state = context.read<AddEditTransactionBloc>().state;
    _descriptionController = TextEditingController(text: state.description);
    _amountController = TextEditingController(text: state.amount);
    _feeController = TextEditingController(text: state.fee);
    _totalValueController = TextEditingController(text: state.totalValue);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _feeController.dispose();
    _totalValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EscapeBackHandler(
      child: BlocListener<AddEditTransactionBloc, AddEditTransactionState>(
        listener: (context, state) {
          if (state.isSaveSuccess) {
            context.read<TransactionsBloc>().add(
              const InitialLoadTransactions(),
            );
            Navigator.of(context).pop();
          }

          if (state.description != _descriptionController.text) {
            _descriptionController.text = state.description;
          }
          if (state.amount != _amountController.text) {
            _amountController.text = state.amount;
          }
          if (state.fee != _feeController.text) {
            _feeController.text = state.fee;
          }
          // Sync Total Value
          if (state.totalValue != _totalValueController.text) {
            // Avoid cursor jumps if user is typing?
            // Simple equality check might fail if formatting differs.
            // But here state.totalValue comes from Bloc which parses input.
            // Best to only update if significantly different or if not focused?
            // For bidirectional sync (Qty changes -> Total changes), we need to update.
            // But if User changes Total -> Bloc updates Total -> Listener updates Total... loop?
            // We can check if widget is focused?
            // Simpler: Check if double values match?
            // Or just equality check on string.
            _totalValueController.text = state.totalValue;
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: BlocBuilder<AddEditTransactionBloc, AddEditTransactionState>(
              builder: (context, state) {
                return Text(
                  state.isTransferMode
                      ? (state.isEditing ? 'Edit Transfer' : 'New Transfer')
                      : (state.isEditing
                            ? 'Edit Transaction'
                            : 'Add Transaction'),
                );
              },
            ),
          ),
          body: BlocBuilder<AddEditTransactionBloc, AddEditTransactionState>(
            builder: (context, state) {
              if (state.status == AddEditTransactionStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state.status == AddEditTransactionStatus.failure) {
                return const Center(child: Text('Failed to load data'));
              }

              return Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: state.isAssetTransaction
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const _AccountField(),
                                const SizedBox(height: 16),
                                const _AssetActionToggle(),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _AmountField(
                                        controller: _amountController,
                                        label: 'Quantity',
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _TotalValueField(
                                        controller: _totalValueController,
                                      ),
                                    ),
                                  ],
                                ),
                                const _AssetPriceDisplay(),
                                const SizedBox(height: 16),
                                const _LinkedAccountField(),
                                const SizedBox(height: 16),
                                const _DateField(),
                                const SizedBox(height: 16),
                                _DescriptionField(
                                  controller: _descriptionController,
                                ),
                                const SizedBox(height: 16),
                                _FeeField(controller: _feeController),
                                const Divider(),
                                const _ExchangeLossSection(),
                                const SizedBox(height: 32),
                                _SaveButton(formKey: _formKey),
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _DescriptionField(
                                  controller: _descriptionController,
                                ),
                                const SizedBox(height: 16),
                                _AmountField(controller: _amountController),
                                const SizedBox(height: 16),
                                const SizedBox(height: 16),
                                // Fee field hidden for standard transactions
                                const _ConvertedAmountDisplay(),
                                const SizedBox(height: 16),
                                _AccountField(
                                  label: state.isTransferMode
                                      ? 'From Account'
                                      : 'Account',
                                ),
                                const SizedBox(height: 16),
                                if (state.isTransferMode)
                                  const _LinkedAccountField(label: 'To Account')
                                else
                                  const _CategoryField(),
                                const SizedBox(height: 16),
                                const _CurrencyField(),
                                const SizedBox(height: 16),
                                if (state.isForeignCurrency) ...[
                                  const _ExchangeRateSection(),
                                  const SizedBox(height: 16),
                                ],
                                const _DateField(),
                                const SizedBox(height: 32),
                                _SaveButton(formKey: _formKey),
                              ],
                            ),
                    ),
                  ),
                  if (state.isSaving)
                    Container(
                      color: Colors.black.withAlpha(128),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DescriptionField extends StatelessWidget {
  final TextEditingController controller;

  const _DescriptionField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Description',
        border: OutlineInputBorder(),
      ),
      onChanged: (value) => context.read<AddEditTransactionBloc>().add(
        AddEditTransactionDescriptionChanged(value),
      ),
      validator: (value) => (value == null || value.isEmpty)
          ? 'Please enter a description'
          : null,
    );
  }
}

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;

  const _AmountField({required this.controller, this.label});
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddEditTransactionBloc, AddEditTransactionState>(
      builder: (context, state) {
        final isIncome = state.selectedCategory?.type == CategoryType.income;
        // Default to red for expense or if no category selected (assume expense)
        final color = isIncome ? Colors.green : Colors.red;

        return TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label ?? 'Amount',
            border: const OutlineInputBorder(),
          ),
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp(r'[0-9.,]'),
            ), // Allow numbers, dot, and comma
            TextInputFormatter.withFunction((oldValue, newValue) {
              return newValue.copyWith(
                text: newValue.text.replaceAll(',', '.'),
              );
            }),
            FilteringTextInputFormatter.deny(
              RegExp(r'-'),
            ), // Deny negative sign
          ],
          onChanged: (value) => context.read<AddEditTransactionBloc>().add(
            AddEditTransactionAmountChanged(value),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter an amount';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        );
      },
    );
  }
}

class _AccountField extends StatelessWidget {
  final String label;
  const _AccountField({this.label = 'Account'});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddEditTransactionBloc, AddEditTransactionState>(
      builder: (context, state) {
        return GestureDetector(
          onTap: () async {
            final selectedAccount = await showSingleSelectDialog<Account>(
              context: context,
              items: state.accounts,
              title: 'Select Account',
              selectedItem: state.selectedAccount,
              itemBuilder: (account) => _AccountTile(account: account),
              stringGetter: (account) => account.name,
            );
            if (context.mounted && selectedAccount != null) {
              context.read<AddEditTransactionBloc>().add(
                AddEditTransactionAccountChanged(selectedAccount),
              );
            }
          },
          child: AbsorbPointer(
            child: TextFormField(
              key: Key(state.selectedAccount?.id ?? 'no_account'),
              initialValue: state.selectedAccount?.name,
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
                prefixIcon: state.selectedAccount != null
                    ? BlocBuilder<StylesBloc, StylesState>(
                        builder: (context, stylesState) {
                          if (stylesState is StylesLoadSuccess) {
                            final style = stylesState.styles.firstWhereOrNull(
                              (s) => s.id == state.selectedAccount!.styleId,
                            );
                            if (style != null) {
                              return IconUtils.getIconWidget(style);
                            }
                          }
                          return const Icon(Icons.account_balance);
                        },
                      )
                    : null,
              ),
              validator: (value) => state.selectedAccount == null
                  ? 'Please select an account'
                  : null,
            ),
          ),
        );
      },
    );
  }
}

class _AccountTile extends StatelessWidget {
  final Account account;

  const _AccountTile({required this.account});

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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StylesBloc, StylesState>(
      builder: (context, stylesState) {
        Style? style;
        if (stylesState is StylesLoadSuccess) {
          style = stylesState.styles.firstWhereOrNull(
            (s) => s.id == account.styleId,
          );
        }
        final finalStyle =
            style ??
            Style(
              id: 'default',
              name: 'Default',
              iconName: 'account_balance',
              colorHex: '#808080',
              iconType: IconType.material,
            );

        return Row(
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: _getColorFromHex(finalStyle.colorHex),
              child: IconUtils.getIconWidget(finalStyle),
            ),
            const SizedBox(width: 10),
            Text(account.name),
          ],
        );
      },
    );
  }
}

class _CategoryField extends StatelessWidget {
  const _CategoryField();
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddEditTransactionBloc, AddEditTransactionState>(
      builder: (context, state) {
        return GestureDetector(
          onTap: () async {
            final selectedCategory = await showSingleSelectDialog<Category>(
              context: context,
              items: state.categories,
              title: 'Select Category',
              selectedItem: state.selectedCategory,
              itemBuilder: (category) {
                final isIncome = category.type == CategoryType.income;
                final color = isIncome ? Colors.green : Colors.red;
                final typeLabel = isIncome ? 'Income' : 'Expense';

                return Row(
                  children: [
                    BlocBuilder<StylesBloc, StylesState>(
                      builder: (context, stylesState) {
                        if (stylesState is StylesLoadSuccess) {
                          final style = stylesState.styles.firstWhereOrNull(
                            (s) => s.id == category.styleId,
                          );
                          if (style != null) {
                            return IconUtils.getIconWidget(style);
                          }
                        }
                        return const Icon(Icons.category);
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(category.name)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: color),
                      ),
                      child: Text(
                        typeLabel,
                        style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              },
              stringGetter: (category) => category.name,
            );
            if (context.mounted && selectedCategory != null) {
              context.read<AddEditTransactionBloc>().add(
                AddEditTransactionCategoryChanged(selectedCategory),
              );
            }
          },
          child: AbsorbPointer(
            child: TextFormField(
              key: Key(state.selectedCategory?.id ?? 'no_category'),
              initialValue: state.selectedCategory?.name,
              decoration: InputDecoration(
                labelText: 'Category',
                border: const OutlineInputBorder(),
                prefixIcon: state.selectedCategory != null
                    ? BlocBuilder<StylesBloc, StylesState>(
                        builder: (context, stylesState) {
                          if (stylesState is StylesLoadSuccess) {
                            final style = stylesState.styles.firstWhereOrNull(
                              (s) => s.id == state.selectedCategory!.styleId,
                            );
                            if (style != null) {
                              return IconUtils.getIconWidget(style);
                            }
                          }
                          return const Icon(Icons.category);
                        },
                      )
                    : null,
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Icon(
                    state.selectedCategory != null
                        ? (state.selectedCategory!.type == CategoryType.income
                              ? Icons.arrow_upward
                              : Icons.arrow_downward)
                        : Icons.arrow_drop_down,
                    color: state.selectedCategory != null
                        ? (state.selectedCategory!.type == CategoryType.income
                              ? Colors.green
                              : Colors.red)
                        : Colors.grey,
                  ),
                ),
              ),
              validator: (value) => state.selectedCategory == null
                  ? 'Please select a category'
                  : null,
            ),
          ),
        );
      },
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField();
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddEditTransactionBloc, AddEditTransactionState>(
      builder: (context, state) {
        return ListTile(
          title: Text(
            "Date: ${state.date?.toLocal().toString().split(' ')[0] ?? 'Select Date'}",
          ),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: state.date ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
            );

            if (picked != null && context.mounted) {
              context.read<AddEditTransactionBloc>().add(
                AddEditTransactionDateChanged(picked),
              );
            }
          },
        );
      },
    );
  }
}

class _SaveButton extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  const _SaveButton({required this.formKey});
  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: () {
        if (formKey.currentState?.validate() ?? false) {
          context.read<AddEditTransactionBloc>().add(
            const AddEditTransactionSubmitted(),
          );
        }
      },
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
      ),
      child: const Text('Save'),
    );
  }
}

class _CurrencyField extends StatelessWidget {
  const _CurrencyField();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddEditTransactionBloc, AddEditTransactionState>(
      builder: (context, state) {
        return GestureDetector(
          onTap: () async {
            final selectedCurrency = await showSingleSelectDialog<Currency>(
              context: context,
              items: state.currencies,
              title: 'Select Currency',
              selectedItem: state.selectedCurrency,
              itemBuilder: (currency) => ListTile(
                title: Text('${currency.code} - ${currency.name}'),
                leading: Text(currency.code),
              ),
              stringGetter: (currency) => currency.code,
            );
            if (context.mounted && selectedCurrency != null) {
              context.read<AddEditTransactionBloc>().add(
                AddEditTransactionCurrencyChanged(selectedCurrency),
              );
            }
          },
          child: AbsorbPointer(
            child: TextFormField(
              key: Key(state.selectedCurrency?.code ?? 'no_currency'),
              initialValue: state.selectedCurrency?.code,
              decoration: const InputDecoration(
                labelText: 'Currency',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monetization_on),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ExchangeRateSection extends StatelessWidget {
  const _ExchangeRateSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddEditTransactionBloc, AddEditTransactionState>(
      builder: (context, state) {
        if (!state.isForeignCurrency) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Exchange Rate',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '1 ${state.selectedCurrency?.code} = ${state.selectedExchangeRate?.rate ?? state.manualExchangeRate} ${state.selectedCurrency?.code == state.selectedAccount?.currencyCode ? state.mainCurrencyCode : state.selectedAccount?.currencyCode}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (state.isLoadingRates)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else ...[
                  if (state.availableExchangeRates.isNotEmpty) ...[
                    const Text(
                      'Available Presets:',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: state.availableExchangeRates.map((rate) {
                        final isSelected = state.selectedExchangeRate == rate;
                        return ChoiceChip(
                          label: Text('P${rate.preset}: ${rate.rate}'),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              context.read<AddEditTransactionBloc>().add(
                                AddEditTransactionRatePresetChanged(rate),
                              );
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: ValueKey(state.selectedExchangeRate?.rate),
                          initialValue: state.manualExchangeRate,
                          decoration: const InputDecoration(
                            labelText: 'Rate Value',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (value) => context
                              .read<AddEditTransactionBloc>()
                              .add(AddEditTransactionManualRateChanged(value)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ConvertedAmountDisplay extends StatelessWidget {
  const _ConvertedAmountDisplay();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddEditTransactionBloc, AddEditTransactionState>(
      builder: (context, state) {
        if (!state.isForeignCurrency || state.amount.isEmpty) {
          return const SizedBox.shrink();
        }

        final amount = double.tryParse(state.amount) ?? 0;
        final rate =
            state.selectedExchangeRate?.rate ??
            double.tryParse(state.manualExchangeRate) ??
            0;
        final converted = amount * rate;

        if (rate == 0) return const SizedBox.shrink();

        final isToAccount =
            state.selectedCurrency?.code != state.selectedAccount?.currencyCode;
        final targetLabel = isToAccount
            ? 'Amount to Add to Account:'
            : 'Value in Global (${state.mainCurrencyCode}):';
        final targetCurrency = isToAccount
            ? state.selectedAccount?.currencyCode
            : state.mainCurrencyCode;

        return Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  targetLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '$targetCurrency ${converted.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FeeField extends StatelessWidget {
  final TextEditingController controller;

  const _FeeField({required this.controller});
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Fee (Commission)',
        border: OutlineInputBorder(),
        hintText: '0.00',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        TextInputFormatter.withFunction((oldValue, newValue) {
          return newValue.copyWith(text: newValue.text.replaceAll(',', '.'));
        }),
      ],
      onChanged: (value) => context.read<AddEditTransactionBloc>().add(
        AddEditTransactionFeeChanged(value),
      ),
    );
  }
}

class _AssetActionToggle extends StatelessWidget {
  const _AssetActionToggle();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddEditTransactionBloc, AddEditTransactionState>(
      builder: (context, state) {
        return Row(
          children: [
            Expanded(
              child: SegmentedButton<AssetAction>(
                segments: const [
                  ButtonSegment(
                    value: AssetAction.buy,
                    label: Text('Buy'),
                    icon: Icon(Icons.add_shopping_cart),
                  ),
                  ButtonSegment(
                    value: AssetAction.sell,
                    label: Text('Sell'),
                    icon: Icon(Icons.sell),
                  ),
                ],
                selected: {state.assetAction},
                onSelectionChanged: (Set<AssetAction> newSelection) {
                  context.read<AddEditTransactionBloc>().add(
                    AddEditTransactionAssetActionChanged(newSelection.first),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TotalValueField extends StatelessWidget {
  final TextEditingController controller;

  const _TotalValueField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddEditTransactionBloc, AddEditTransactionState>(
      builder: (context, state) {
        return TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Total Value',
            prefixText: state.linkedAccount?.currencyCode ?? '',
            border: const OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Required';
            }
            return null;
          },
          onChanged: (value) {
            context.read<AddEditTransactionBloc>().add(
              AddEditTransactionTotalValueChanged(value),
            );
          },
        );
      },
    );
  }
}

class _AssetPriceDisplay extends StatelessWidget {
  const _AssetPriceDisplay();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddEditTransactionBloc, AddEditTransactionState>(
      builder: (context, state) {
        if (state.assetPrice == null) return const SizedBox.shrink();

        final price = state.assetPrice!;
        final currency = state.selectedAccount?.currencyCode ?? '';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Current Price: $price $currency',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        );
      },
    );
  }
}

class _LinkedAccountField extends StatelessWidget {
  final String label;
  const _LinkedAccountField({this.label = 'Linked Account'});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddEditTransactionBloc, AddEditTransactionState>(
      builder: (context, state) {
        final cashAccounts = state.accounts
            .where((a) => a.id != state.selectedAccount?.id)
            .toList();

        return FormField<Account>(
          initialValue: state.linkedAccount,
          validator: (value) {
            if (state.linkedAccount == null) {
              return 'Required';
            }
            return null;
          },
          builder: (FormFieldState<Account> field) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () async {
                    final selectedAccount =
                        await showSingleSelectDialog<Account>(
                          context: context,
                          items: cashAccounts,
                          title: 'Select Linked Account',
                          selectedItem: state.linkedAccount,
                          itemBuilder: (account) => ListTile(
                            title: Text(account.name),
                            leading: const Icon(Icons.account_balance_wallet),
                          ),
                          stringGetter: (account) => account.name,
                        );

                    if (context.mounted && selectedAccount != null) {
                      context.read<AddEditTransactionBloc>().add(
                        AddEditTransactionLinkedAccountChanged(selectedAccount),
                      );
                      field.didChange(selectedAccount);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: label,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      errorText: field.errorText,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          state.linkedAccount?.name ?? 'Select Account',
                          style: state.linkedAccount == null
                              ? Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).hintColor,
                                )
                              : Theme.of(context).textTheme.bodyLarge,
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ExchangeLossSection extends StatelessWidget {
  const _ExchangeLossSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddEditTransactionBloc, AddEditTransactionState>(
      builder: (context, state) {
        if (!state.isAssetTransaction) return const SizedBox.shrink();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SwitchListTile(
                title: const Text('Record Exchange Loss?'),
                subtitle: Text(
                  state.recordExchangeLoss
                      ? 'Loss: ${state.projectedLoss.toStringAsFixed(2)} ${state.linkedAccount?.currencyCode ?? ''}'
                      : 'Track realized loss on currency/asset conversion',
                ),
                value: state.recordExchangeLoss,
                onChanged: (value) {
                  context.read<AddEditTransactionBloc>().add(
                    AddEditTransactionRecordExchangeLossChanged(value),
                  );
                },
              ),
            ),
            if (state.recordExchangeLoss)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Market Rate Used: ${state.marketRate!.toStringAsFixed(4)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
