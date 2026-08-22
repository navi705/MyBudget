import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/core/di/injection_container.dart';
import 'package:my_budget_client/core/theme/money_colors.dart';
import 'package:my_budget_client/core/utils/date_display.dart';
import 'package:my_budget_client/core/utils/dialog_utils.dart';
import 'package:my_budget_client/core/utils/money_formatter.dart';
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
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency/currency_bloc.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';
import 'package:my_budget_client/presentation/widgets/add_account_dialog.dart';
import 'package:my_budget_client/presentation/widgets/scaffold_with_escape_back.dart';
import 'package:my_budget_client/presentation/widgets/single_select_dialog.dart';
import 'package:my_budget_client/presentation/widgets/budget_icon.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';

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

  /// The message currently on screen, so one failure is reported once.
  String? _shownValidationError;

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
            context.pop();

            context.read<TransactionsBloc>().add(
              const InitialLoadTransactions(),
            );
            context.read<AccountsBloc>().add(LoadAccounts());
          }

          // The listener has to run on every state to keep the controllers in
          // step, so the SnackBar is gated here instead: without this, one
          // failed validation queued a fresh red SnackBar for every keystroke
          // that followed, because `validationError` stays set in state.
          final validationError = state.validationError;
          if (validationError != null &&
              validationError != _shownValidationError) {
            final l10n = context.l10n;
            final localized = <String, String>{
              'Please enter an amount': l10n.emptyAmountError,
              'Please select an account': l10n.selectAccountError,
              'Please select a date': l10n.selectDateError,
              'Please select a category': l10n.selectCategoryError,
              'Please enter a valid number': l10n.invalidAmountError,
              // Emitted by _onAccountsUpdated when a sync deletes an account
              // that this form still had selected. Without these two rows the
              // sentinels would reach the user as untranslated English through
              // the importErrorLabel fallback below.
              'The account you selected has been deleted':
                  l10n.accountDeletedError,
              'The linked account you selected has been deleted':
                  l10n.linkedAccountDeletedError,
              // Emitted by _onSubmitted when a cross-currency transfer has no
              // rate to convert the receiving leg at - the pair has none
              // stored and none was typed. Same reason as the two rows above:
              // without this row the sentinel reaches the user as untranslated
              // English through the importErrorLabel fallback below.
              'Please enter an exchange rate': l10n.enterExchangeRateError,
            };

            _shownValidationError = validationError;
            ScaffoldMessenger.of(context)
              ..removeCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  // Anything else is a repository exception, which no lookup
                  // can translate - the frame around it is localized so the
                  // user at least reads it as an error and not as a result.
                  content: Text(
                    localized[validationError] ??
                        l10n.importErrorLabel(validationError),
                  ),
                  backgroundColor: Colors.red,
                ),
              );
          } else if (validationError == null) {
            _shownValidationError = null;
          }

          if (state.description != _descriptionController.text) {
            _descriptionController.text = state.description;
          }
          // Nullable rather than a -1.0 sentinel. With the sentinel, a state
          // amount that really was -1.0 compared equal to an empty controller,
          // so reopening a transaction of exactly 1.00 left the Amount field
          // blank and saving was refused until the user retyped it.
          final amountDouble = double.tryParse(state.amount);
          final currentAmountDouble = double.tryParse(_amountController.text);
          if (amountDouble != currentAmountDouble &&
              (amountDouble == null ||
                  currentAmountDouble == null ||
                  (amountDouble - currentAmountDouble).abs() > 0.0000001)) {
            _amountController.text = state.amount;
          }
          if (state.fee != _feeController.text) {
            _feeController.text = state.fee;
          }

          // Same sentinel, same edge: a total value of exactly -1.0.
          final totalDouble = double.tryParse(state.totalValue);
          final currentTotalDouble = double.tryParse(
            _totalValueController.text,
          );
          if (totalDouble != currentTotalDouble &&
              (totalDouble == null ||
                  currentTotalDouble == null ||
                  (totalDouble - currentTotalDouble).abs() > 0.0000001)) {
            _totalValueController.text = state.totalValue;
          }
        },
        child: Scaffold(
          // The body is a plain SingleChildScrollView, so the viewport has to
          // shrink with the keyboard. With `false` the viewport kept the full
          // screen height, the max scroll extent ignored the inset and the last
          // ~300dp (Date field, Save button) stayed parked under the keyboard
          // with no way to scroll to it.
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            title: BlocBuilder<AddEditTransactionBloc, AddEditTransactionState>(
              builder: (context, state) {
                final l10n = context.l10n;
                return Text(
                  state.isTransferMode
                      ? (state.isEditing
                            ? l10n.editTransferTitle
                            : l10n.newTransferTitle)
                      : (state.isEditing
                            ? l10n.editTransactionTitle
                            : l10n.addTransactionTitle),
                );
              },
            ),
          ),
          body: BlocBuilder<AddEditTransactionBloc, AddEditTransactionState>(
            builder: (context, state) {
              if (state.status == AddEditTransactionStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state.status == AddEditTransactionStatus.failure) {
                return Center(child: Text(context.l10n.failedToLoadData));
              }

              // The scrim is the outer layer, the 600dp column the inner one.
              // Nested the other way round it dimmed only the form's own
              // width: on a 1440px window 800px of the screen stayed lit and
              // interactive while the save was in flight.
              return Stack(
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: RepaintBoundary(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16.0),
                          child: Form(
                            key: _formKey,
                            child: state.isAssetTransaction
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
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
                                              label: context
                                                  .l10n
                                                  .quantityFormLabel,
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
                                      if (state.isForeignCurrency) ...[
                                        const _ExchangeRateSection(),
                                        const SizedBox(height: 16),
                                      ],
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
                                      _AmountField(
                                        controller: _amountController,
                                      ),
                                      const SizedBox(height: 16),
                                      if (state.isForeignCurrency) ...[
                                        const _ExchangeRateSection(),
                                        const SizedBox(height: 16),
                                      ],

                                      const _ConvertedAmountDisplay(),
                                      const SizedBox(height: 16),
                                      if (state.isTransferMode) ...[
                                        _AccountField(
                                          label: context.l10n.fromAccountLabel,
                                        ),
                                        Align(
                                          alignment: Alignment.center,
                                          child: IconButton(
                                            icon: const Icon(Icons.swap_vert),
                                            onPressed: () {
                                              context
                                                  .read<
                                                    AddEditTransactionBloc
                                                  >()
                                                  .add(
                                                    const AddEditTransactionSwapAccounts(),
                                                  );
                                            },
                                            tooltip: context
                                                .l10n
                                                .swapAccountsTooltip,
                                          ),
                                        ),
                                        _LinkedAccountField(
                                          label: context.l10n.toAccountLabel,
                                        ),
                                      ] else ...[
                                        _AccountField(
                                          label: context.l10n.accountLabel,
                                        ),
                                        const SizedBox(height: 16),
                                        const _CategoryField(),
                                      ],
                                      const SizedBox(height: 16),
                                      const _CurrencyField(),
                                      const SizedBox(height: 16),
                                      const _DateField(),
                                      const SizedBox(height: 32),
                                      _SaveButton(formKey: _formKey),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (state.isSaving)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withAlpha(128),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
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

/// A form control whose value is chosen from a dialog rather than typed.
///
/// The pickers on this form used to be a `GestureDetector` wrapped around
/// `AbsorbPointer(TextFormField)`. A pointer was then the only way to open
/// them: the inner field could be tabbed onto but had no action behind it, so
/// on Windows desktop the keyboard path through the app's primary task stopped
/// dead at Account. `InkWell` is focusable, paints the theme's focus highlight
/// - the only focus affordance these fields have ever had - and maps
/// Enter/Space onto [onTap] through `ActivateIntent`. The decorated field below
/// it is taken out of traversal so a picker is one tab stop and not two, and
/// out of hit testing so the tap lands on the `InkWell` instead of the caret.
///
/// A null [onTap] means "not offered" (the currency field during a transfer):
/// the control then neither takes focus nor reacts, exactly as before.
class _PickerField extends StatelessWidget {
  const _PickerField({required this.onTap, required this.child, super.key});

  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      canRequestFocus: onTap != null,
      borderRadius: BorderRadius.circular(4),
      child: ExcludeFocus(child: IgnorePointer(child: child)),
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
      decoration: InputDecoration(
        labelText: context.l10n.descriptionOptionalLabel,
        border: const OutlineInputBorder(),
      ),
      onChanged: (value) => context.read<AddEditTransactionBloc>().add(
        AddEditTransactionDescriptionChanged(value),
      ),
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
        final category = state.selectedCategory;
        final isIncome = category?.type == CategoryType.income;

        // Direction is only a fact once a category has been chosen on a plain
        // income/expense. Quantities on an asset trade and both legs of a
        // transfer have none, and neither does a form nobody has filled in
        // yet - which used to paint the very first digit the user typed red.
        final hasDirection =
            category != null &&
            !state.isAssetTransaction &&
            !state.isTransferMode;

        final moneyColors = MoneyColors.of(context);
        final color = hasDirection
            ? moneyColors.forDirection(isIncome: isIncome)
            : moneyColors.neutral;

        // The control that decides this colour is three rows further down the
        // form, so the colour alone made the user scroll to find out why the
        // number went red. The glyph sits against the digits and says it
        // outright - and says it in greyscale, and to a red-green colourblind
        // reader, which the colour never did.
        final signGlyph = hasDirection
            ? MoneyColors.signGlyph(isIncome: isIncome)
            : null;

        final effectiveLabel = state.isAssetTransaction && label == null
            ? context.l10n.assetQuantityLabel
            : (label ?? context.l10n.amountLabel);

        return TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: effectiveLabel,
            border: const OutlineInputBorder(),
            prefixText: signGlyph,
            prefixStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            TextInputFormatter.withFunction((oldValue, newValue) {
              return newValue.copyWith(
                text: newValue.text.replaceAll(',', '.'),
              );
            }),
            FilteringTextInputFormatter.deny(RegExp(r'-')),
          ],
          onChanged: (value) => context.read<AddEditTransactionBloc>().add(
            AddEditTransactionAmountChanged(value),
          ),
          validator: (value) {
            final l10n = context.l10n;
            if (value == null || value.isEmpty) {
              return l10n.emptyAmountError;
            }
            if (double.tryParse(value) == null) {
              return l10n.invalidAmountError;
            }
            return null;
          },
        );
      },
    );
  }
}

class _AccountField extends StatelessWidget {
  final String? label;
  const _AccountField({this.label});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddEditTransactionBloc, AddEditTransactionState>(
      builder: (context, state) {
        final availableAccounts = state.isTransferMode
            ? state.accounts.where((a) => a.assetId == null).toList()
            : state.accounts;

        return _PickerField(
          key: const Key('accountPickerField'),
          onTap: () async {
            final selectedAccount = await showSingleSelectDialog<Account>(
              context: context,
              items: availableAccounts,
              title: context.l10n.selectAccountTitle,
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
          child: TextFormField(
            key: Key(state.selectedAccount?.id ?? 'no_account'),
            initialValue: state.selectedAccount?.name,
            decoration: InputDecoration(
              labelText: label ?? context.l10n.accountLabel,
              border: const OutlineInputBorder(),
              prefixIcon: state.selectedAccount != null
                  ? BlocBuilder<StylesBloc, StylesState>(
                      builder: (context, stylesState) {
                        if (stylesState is StylesLoadSuccess) {
                          final style = stylesState.styles.firstWhereOrNull(
                            (s) => s.id == state.selectedAccount!.styleId,
                          );
                          if (style != null) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: BudgetIcon(style: style, radius: 12),
                            );
                          }
                        }
                        return const Icon(Icons.account_balance);
                      },
                    )
                  : null,
            ),
            validator: (value) => state.selectedAccount == null
                ? context.l10n.selectAccountError
                : null,
          ),
        );
      },
    );
  }
}

class _AccountTile extends StatelessWidget {
  final Account account;

  const _AccountTile({required this.account});

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
            BudgetIcon(style: finalStyle, radius: 15),
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
        final moneyColors = MoneyColors.of(context);

        return _PickerField(
          key: const Key('categoryPickerField'),
          onTap: () async {
            final selectedCategory = await showSingleSelectDialog<Category>(
              context: context,
              items: state.categories,
              title: context.l10n.selectCategoryTitle,
              selectedItem: state.selectedCategory,
              itemBuilder: (category) {
                final isIncome = category.type == CategoryType.income;
                final color = moneyColors.forDirection(isIncome: isIncome);
                final typeLabel = isIncome
                    ? context.l10n.incomeType
                    : context.l10n.expenseType;

                return Row(
                  children: [
                    BlocBuilder<StylesBloc, StylesState>(
                      builder: (context, stylesState) {
                        if (stylesState is StylesLoadSuccess) {
                          final style = stylesState.styles.firstWhereOrNull(
                            (s) => s.id == category.styleId,
                          );
                          if (style != null) {
                            return BudgetIcon(style: style, radius: 15);
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
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: color),
                      ),
                      child: Text(
                        // The glyph repeats the badge's meaning without
                        // relying on the colour, for greyscale and for a
                        // red-green colourblind reader.
                        '${MoneyColors.signGlyph(isIncome: isIncome)} '
                        '$typeLabel',
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
          child: TextFormField(
            key: Key(state.selectedCategory?.id ?? 'no_category'),
            initialValue: state.selectedCategory?.name,
            decoration: InputDecoration(
              labelText: context.l10n.categoryLabel,
              border: const OutlineInputBorder(),
              prefixIcon: state.selectedCategory != null
                  ? BlocBuilder<StylesBloc, StylesState>(
                      builder: (context, stylesState) {
                        if (stylesState is StylesLoadSuccess) {
                          final style = stylesState.styles.firstWhereOrNull(
                            (s) => s.id == state.selectedCategory!.styleId,
                          );
                          if (style != null) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: BudgetIcon(style: style, radius: 12),
                            );
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
                      ? moneyColors.forDirection(
                          isIncome:
                              state.selectedCategory!.type ==
                              CategoryType.income,
                        )
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            validator: (value) => state.selectedCategory == null
                ? context.l10n.selectCategoryError
                : null,
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
        final l10n = context.l10n;
        final date = state.date;
        // `DateTime.toString().split(' ')[0]` printed a raw ISO date -
        // `2026-08-21` - in the app's highest-traffic form, to all ten
        // locales. `DateDisplay.short` is the locale's own numeric date.
        final formattedDate = date == null
            ? l10n.selectDateLabel
            : DateDisplay.short(context, date.toLocal());
        return ListTile(
          title: Text('${l10n.dateLabel}: $formattedDate'),
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
        final isValid = formKey.currentState?.validate() ?? false;
        if (isValid) {
          final bloc = context.read<AddEditTransactionBloc>();
          final state = bloc.state;
          final l10n = context.l10n;
          // A transfer's two rows are described for the user, not by them, so
          // the wording has to come from `l10n` - and the bloc cannot reach it.
          // The names are read here, at the moment of saving, so the strings
          // match the accounts actually chosen.
          final from = state.selectedAccount?.name;
          final to = state.linkedAccount?.name;
          // The asset rows are worded from the same place for the same
          // reason. `from` is the asset account here - the thing being bought
          // or sold - and the action word is the one the form's own toggle
          // shows, so the saved row reads the way the form did.
          final isBuy = state.assetAction == AssetAction.buy;
          final action = isBuy ? l10n.buyAction : l10n.sellAction;
          bloc.add(
            AddEditTransactionSubmitted(
              transferToDescription: to == null
                  ? null
                  : l10n.transferToDescription(to),
              transferFromDescription: from == null
                  ? null
                  : l10n.transferFromDescription(from),
              assetDescription: from == null
                  ? null
                  : (isBuy
                        ? l10n.buyDescription(from)
                        : l10n.sellDescription(from)),
              assetTransferDescription: from == null
                  ? null
                  : l10n.assetTransferDescription(action, from),
            ),
          );
        }
      },
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
      ),
      child: Text(context.l10n.saveButton),
    );
  }
}

class _CurrencyField extends StatelessWidget {
  const _CurrencyField();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddEditTransactionBloc, AddEditTransactionState>(
      builder: (context, state) {
        final isTransfer = state.isTransferMode;

        return _PickerField(
          key: const Key('currencyPickerField'),
          onTap: isTransfer
              ? null
              : () async {
                  final selectedCurrency =
                      await showSingleSelectDialog<Currency>(
                        context: context,
                        items: state.currencies,
                        title: context.l10n.selectCurrencyTitle,
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
          child: TextFormField(
            key: Key(state.selectedCurrency?.code ?? 'no_currency'),
            initialValue: state.selectedCurrency?.code,
            readOnly: true,
            enabled: !isTransfer,
            decoration: InputDecoration(
              labelText: context.l10n.currencyLabel,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.monetization_on),
              suffixIcon: isTransfer ? const Icon(Icons.lock, size: 16) : null,
              helperText: isTransfer
                  ? context.l10n.currencyLockedMessage
                  : null,
            ),
          ),
        );
      },
    );
  }
}

class _ExchangeRateSection extends StatefulWidget {
  const _ExchangeRateSection();

  @override
  State<_ExchangeRateSection> createState() => _ExchangeRateSectionState();
}

class _ExchangeRateSectionState extends State<_ExchangeRateSection> {
  late TextEditingController _rateController;

  String _getDisplayValue(AddEditTransactionState state) {
    return state.manualExchangeRate;
  }

  @override
  void initState() {
    super.initState();
    final state = context.read<AddEditTransactionBloc>().state;
    _rateController = TextEditingController(text: _getDisplayValue(state));
  }

  @override
  void didUpdateWidget(covariant _ExchangeRateSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final state = context.read<AddEditTransactionBloc>().state;

    final expectedText = _getDisplayValue(state);

    if (_rateController.text != expectedText) {
      final currentVal = double.tryParse(_rateController.text);
      final expectedVal = double.tryParse(expectedText);
      bool isClose = false;

      if (currentVal != null && expectedVal != null) {
        if ((currentVal - expectedVal).abs() < 0.000001) isClose = true;
      }

      if (!isClose) {
        _rateController.text = expectedText;

        _rateController.selection = TextSelection.fromPosition(
          TextPosition(offset: _rateController.text.length),
        );
      }
    }
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddEditTransactionBloc, AddEditTransactionState>(
      listener: (context, state) {
        final expectedText = _getDisplayValue(state);
        if (_rateController.text != expectedText) {
          final currentVal = double.tryParse(_rateController.text);
          final expectedVal = double.tryParse(expectedText);
          bool isClose = false;
          if (currentVal != null && expectedVal != null) {
            if ((currentVal - expectedVal).abs() < 0.000001) isClose = true;
          }

          if (!isClose) {
            _rateController.text = expectedText;
            _rateController.selection = TextSelection.fromPosition(
              TextPosition(offset: _rateController.text.length),
            );
          }
        }
      },
      child: BlocBuilder<AddEditTransactionBloc, AddEditTransactionState>(
        builder: (context, state) {
          String fromCurrency;
          String toCurrency;

          if (state.isTransferMode) {
            fromCurrency = state.selectedAccount?.currencyCode ?? '';
            toCurrency =
                state.linkedAccount?.currencyCode ?? state.mainCurrencyCode;
          } else if (state.isAssetTransaction) {
            fromCurrency = state.selectedAccount?.currencyCode ?? '';
            toCurrency =
                state.linkedAccount?.currencyCode ?? state.mainCurrencyCode;
          } else {
            fromCurrency = state.selectedCurrency?.code ?? '';
            if (fromCurrency != (state.selectedAccount?.currencyCode ?? '')) {
              toCurrency =
                  state.selectedAccount?.currencyCode ?? state.mainCurrencyCode;
            } else {
              toCurrency = state.mainCurrencyCode;
            }
          }

          final leftCurrency = state.isRateInputInverted
              ? toCurrency
              : fromCurrency;
          final rightCurrency = state.isRateInputInverted
              ? fromCurrency
              : toCurrency;

          return Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.exchangeRateLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            leftCurrency,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: IconButton(
                            icon: const Icon(Icons.swap_horiz),
                            onPressed: () {
                              context.read<AddEditTransactionBloc>().add(
                                const AddEditTransactionToggleRateDirection(),
                              );
                            },
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            rightCurrency,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (state.isLoadingRates)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else ...[
                    if (state.availableExchangeRates.isNotEmpty) ...[
                      Text(
                        context.l10n.availablePresetsLabel,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: state.availableExchangeRates.map((rate) {
                          final isSelected = state.selectedExchangeRate == rate;
                          return ChoiceChip(
                            label: Text(
                              'P${rate.preset}: ${rate.rate.toStringAsFixed(4)}',
                            ),
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
                            controller: _rateController,
                            decoration: InputDecoration(
                              labelText:
                                  '${context.l10n.exchangeRateLabel} ($rightCurrency)',
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.,]'),
                              ),
                              TextInputFormatter.withFunction((
                                oldValue,
                                newValue,
                              ) {
                                return newValue.copyWith(
                                  text: newValue.text.replaceAll(',', '.'),
                                );
                              }),
                            ],
                            onChanged: (value) =>
                                context.read<AddEditTransactionBloc>().add(
                                  AddEditTransactionManualRateChanged(value),
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Up to four labelled buttons live here. Side by side they
                    // need ~390dp, but a 360dp phone only offers ~296dp inside
                    // the form padding, so a Row overflowed in every locale.
                    // Wrap lets the row break onto a second line and supplies
                    // the gap the manual SizedBox spacers used to add.
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        // Gated on editingExchangeRate rather than
                        // selectedExchangeRate: the latter is cleared the
                        // moment the rate field is edited by hand (so the
                        // chip stops claiming a conversion it no longer
                        // describes), but typing a new rate over a preset is
                        // exactly when these two buttons are needed.
                        if (state.editingExchangeRate != null &&
                            state.editingExchangeRate!.preset != 1)
                          TextButton.icon(
                            icon: const Icon(Icons.delete, size: 16),
                            label: Text(context.l10n.deleteButton),
                            // The theme's own destructive colour: a raw red
                            // fails contrast on several of the dark surfaces
                            // the seed picker can generate.
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.error,
                            ),
                            onPressed: () {
                              context.read<AddEditTransactionBloc>().add(
                                AddEditTransactionDeletePreset(
                                  state.editingExchangeRate!,
                                ),
                              );
                            },
                          ),

                        if (state.editingExchangeRate != null &&
                            state.editingExchangeRate!.preset != 1)
                          TextButton.icon(
                            icon: const Icon(Icons.edit, size: 16),
                            label: Text(context.l10n.updateButton),
                            onPressed: () {
                              context.read<AddEditTransactionBloc>().add(
                                AddEditTransactionUpdatePreset(
                                  state.editingExchangeRate!,
                                ),
                              );
                            },
                          ),

                        TextButton.icon(
                          icon: const Icon(Icons.bookmark_border, size: 16),
                          label: Text(context.l10n.defaultLabel),
                          onPressed: () {
                            context.read<AddEditTransactionBloc>().add(
                              const AddEditTransactionSaveRateAsDefault(),
                            );
                          },
                        ),

                        TextButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: Text(context.l10n.newPresetButton),
                          onPressed: () {
                            context.read<AddEditTransactionBloc>().add(
                              const AddEditTransactionAddNewRate(),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
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
        // Read the same field the save reads, and read it the same way.
        // `manualExchangeRate` is what selecting a preset writes into and what
        // `_onSubmitted` converts with, so preferring `selectedExchangeRate`
        // here showed the preset's rate while the save used whatever the user
        // had since typed over it.
        var rate = double.tryParse(state.manualExchangeRate) ?? 0;
        // And apply the direction toggle the save applies. Without it the
        // preview multiplied by the rate while the save multiplied by its
        // reciprocal, so the number the user approved and the number written
        // to the account differed by a factor of rate squared.
        if (rate != 0 && state.isRateInputInverted) {
          rate = 1 / rate;
        }
        final converted = amount * rate;

        if (rate == 0) return const SizedBox.shrink();

        // In transfer mode the currency field is locked to the From account
        // and the bloc keeps `selectedCurrency` equal to it at every entry
        // point, so the test below is always false here - and the banner
        // announced the main currency over a figure that is the amount
        // arriving in the TO account, in the TO account's currency. The rate
        // card directly above it said From -> To, so the two panels
        // contradicted each other on the same screen: 100 EUR into an RSD
        // account read "Value in Global (EUR): EUR 11,700.00".
        final isTransferTarget = state.isTransferMode;
        final isToAccount =
            state.selectedCurrency?.code != state.selectedAccount?.currencyCode;
        final targetLabel = isTransferTarget || isToAccount
            ? context.l10n.amountToAddToAccountLabel
            : context.l10n.valueInGlobalLabel(state.mainCurrencyCode);
        final targetCurrency = isTransferTarget
            ? state.linkedAccount?.currencyCode
            : (isToAccount
                  ? state.selectedAccount?.currencyCode
                  : state.mainCurrencyCode);

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
                // Both sides are unbounded: a translated sentence on the left
                // and a currency code plus an arbitrarily long amount on the
                // right. Together they exceed the ~304dp inner width of this
                // banner on a 360dp phone (in English too, once the amount
                // reaches seven digits). Both are loose Flexibles so each only
                // takes the width it needs and spaceBetween still pushes them
                // apart; the 2:3 weighting means the amount - the point of the
                // banner - is the last thing to be ellipsised.
                Flexible(
                  flex: 2,
                  child: Text(
                    targetLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  flex: 3,
                  child: Text(
                    // Currency code and amount are one chunk of text: without
                    // the isolate an RTL paragraph reorders the two.
                    MoneyFormatter.isolate(
                      '$targetCurrency '
                      '${MoneyFormatter.format(converted, targetCurrency ?? '')}',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
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
      decoration: InputDecoration(
        labelText: context.l10n.feeCommissionLabel,
        border: const OutlineInputBorder(),
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
                segments: [
                  ButtonSegment(
                    value: AssetAction.buy,
                    label: Text(context.l10n.buyAction),
                    icon: const Icon(Icons.add_shopping_cart),
                  ),
                  ButtonSegment(
                    value: AssetAction.sell,
                    label: Text(context.l10n.sellAction),
                    icon: const Icon(Icons.sell),
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
            labelText: context.l10n.totalValueLabel,
            prefixText: state.linkedAccount?.currencyCode ?? '',
            border: const OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return context.l10n.requiredError;
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
            // The amount is embedded in a translated sentence, so it has to
            // be isolated from the words on either side of it.
            context.l10n.currentPriceLabel(
              MoneyFormatter.formatIsolated(price, currency),
              currency,
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        );
      },
    );
  }
}

/// Account creation, reached from a picker that has nothing to offer.
///
/// The blocs are re-provided the way the accounts screen does it: the dialog
/// goes onto the root navigator, so it is a sibling of this route rather than a
/// descendant of it.
void _showAddAccountDialog(BuildContext context) {
  DialogUtils.showAppDialog(
    context: context,
    resizeToAvoidBottomInset: false,
    child: MultiBlocProvider(
      providers: [
        BlocProvider.value(value: context.read<AccountsBloc>()),
        BlocProvider.value(value: context.read<CurrencyBloc>()),
        BlocProvider.value(value: context.read<StylesBloc>()),
      ],
      child: const AddAccountDialog(),
    ),
  );
}

class _LinkedAccountField extends StatelessWidget {
  final String? label;
  const _LinkedAccountField({this.label});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddEditTransactionBloc, AddEditTransactionState>(
      builder: (context, state) {
        final cashAccounts = state.accounts
            .where(
              (a) => a.id != state.selectedAccount?.id && a.assetId == null,
            )
            .toList();

        return FormField<Account>(
          initialValue: state.linkedAccount,
          validator: (value) {
            if (state.linkedAccount == null) {
              return context.l10n.requiredError;
            }
            return null;
          },
          builder: (FormFieldState<Account> field) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PickerField(
                  key: const Key('linkedAccountPickerField'),
                  onTap: () async {
                    final selectedAccount =
                        await showSingleSelectDialog<Account>(
                          context: context,
                          items: cashAccounts,
                          title: context.l10n.selectLinkedAccountTitle,
                          selectedItem: state.linkedAccount,
                          itemBuilder: (account) => ListTile(
                            title: Text(account.name),
                            leading: const Icon(Icons.account_balance_wallet),
                          ),
                          stringGetter: (account) => account.name,
                          // A transfer needs a second cash account. With only
                          // one there is nothing to pick, yet this field is
                          // required - so the form could never be saved and
                          // never said why. Creating the missing account from
                          // inside the picker is the only exit that does not
                          // throw away the half-filled form; the bloc watches
                          // the account stream, so it appears here at once.
                          createAction: cashAccounts.isEmpty
                              ? SingleSelectCreateAction(
                                  label: context.l10n.accountsAddTooltip,
                                  onPressed: () =>
                                      _showAddAccountDialog(context),
                                )
                              : null,
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
                      labelText: label ?? context.l10n.linkedAccountLabel,
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
                          state.linkedAccount?.name ??
                              context.l10n.selectAccountTitle,
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
