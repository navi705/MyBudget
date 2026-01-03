import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/core/di/injection_container.dart';
import 'package:my_budget_client/core/utils/icon_utils.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/icon_type.dart';
import 'package:my_budget_client/domain/entities/style.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/presentation/blocs/add_edit_transaction/add_edit_transaction_bloc.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';
import 'package:my_budget_client/presentation/widgets/single_select_dialog.dart';

class AddEditTransactionScreen extends StatelessWidget {
  final Transaction? transaction;

  const AddEditTransactionScreen({super.key, this.transaction});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AddEditTransactionBloc(
        transactionRepository: sl<TransactionRepository>(),
        accountRepository: sl<AccountRepository>(),
        categoryRepository: sl<CategoryRepository>(),
      )..add(AddEditTransactionLoad(transaction: transaction)),
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

  @override
  void initState() {
    super.initState();
    final state = context.read<AddEditTransactionBloc>().state;
    _descriptionController = TextEditingController(text: state.description);
    _amountController = TextEditingController(text: state.amount);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddEditTransactionBloc, AddEditTransactionState>(
      listener: (context, state) {
        if (state.isSaveSuccess) {
          context.read<TransactionsBloc>().add(const InitialLoadTransactions());
          Navigator.of(context).pop();
        }

        if (state.description != _descriptionController.text) {
          _descriptionController.text = state.description;
        }
        if (state.amount != _amountController.text) {
          _amountController.text = state.amount;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: BlocBuilder<AddEditTransactionBloc, AddEditTransactionState>(
            builder: (context, state) {
              return Text(
                state.isEditing ? 'Edit Transaction' : 'Add Transaction',
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
                Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _DescriptionField(controller: _descriptionController),
                        const SizedBox(height: 16),
                        _AmountField(controller: _amountController),
                        const SizedBox(height: 16),
                        const _AccountField(),
                        const SizedBox(height: 16),
                        const _CategoryField(),
                        const SizedBox(height: 16),
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

  const _AmountField({required this.controller});
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Amount',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
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
  }
}

class _AccountField extends StatelessWidget {
  const _AccountField();

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
                labelText: 'Account',
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
              itemBuilder: (category) => Row(
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
                  Text(category.name),
                ],
              ),
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
