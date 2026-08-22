import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/domain/entities/currency_designation.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/entities/transaction_category.dart'; // Import TransactionCategory
// Both bloc libraries export ToggleSelectionMode and ClearSelection, and every
// use of those names in this file belongs to the transactions bloc.
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart'
    show AccountsBloc, AccountsLoadSuccess, AccountsState;
import 'package:my_budget_client/presentation/blocs/currency/currency_bloc.dart'
    show CurrencyBloc;
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart'
    show StylesBloc;
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';
import 'package:my_budget_client/presentation/widgets/add_account_dialog.dart';
import 'package:my_budget_client/core/utils/icon_utils.dart'; // Import IconUtils
import 'package:my_budget_client/core/theme/money_colors.dart';
import 'package:my_budget_client/core/utils/date_display.dart';
import 'package:my_budget_client/core/utils/money_formatter.dart';
import 'package:my_budget_client/presentation/widgets/generic/grouped_paginated_list.dart';
import 'package:my_budget_client/presentation/widgets/generic/app_state_view.dart';
import 'package:my_budget_client/core/utils/dialog_utils.dart';
import 'package:my_budget_client/core/constants/app_constants.dart';
import 'package:collection/collection.dart';

class TransactionList extends StatefulWidget {
  const TransactionList({super.key});

  @override
  State<TransactionList> createState() => _TransactionListState();
}

class _TransactionListState extends State<TransactionList> {
  @override
  void initState() {
    // Only from a cold state. The bloc is provided app-wide and outlives this
    // widget, but the shell route rebuilds the screen on every tab switch, and
    // a reload there redid the whole pipeline — the page query, the counts, the
    // category/style/account lookups and the currency conversion of every row.
    // The bloc watches the transactions table, so a list it already holds is
    // current.
    final bloc = context.read<TransactionsBloc>();
    if (bloc.state.status == TransactionStatus.initial ||
        bloc.state.status == TransactionStatus.failure) {
      bloc.add(const InitialLoadTransactions());
    }
    super.initState();
  }

  /// True once the accounts have actually loaded and there are none.
  ///
  /// Every other [AccountsState] reports no accounts while the load is still
  /// running, so treating that as "no accounts" everywhere would refuse taps on
  /// the first frame of a normal launch.
  ///
  /// The unfiltered count, not `state.accounts`: that list is the accounts
  /// screen's page after its type/currency/name filter, and the form's account
  /// picker is fed from the whole table. Reading it refused the form whenever a
  /// filter left the accounts grid empty.
  static bool _hasNoAccounts(AccountsState state) =>
      state is AccountsLoadSuccess && state.unfilteredAccountCount == 0;

  /// The single door to the transaction form for this list.
  ///
  /// Account is required on that form and its picker is fed from the same
  /// account list, so with none the form opens and can never be saved - Back is
  /// the only exit. Refuse instead, and say what is missing.
  void _openTransactionForm(BuildContext context, {Transaction? transaction}) {
    if (_hasNoAccounts(context.read<AccountsBloc>().state)) {
      _refuseWithoutAccount(context);
      return;
    }

    context.push(
      AppRoutes.addEditTransaction,
      extra: transaction == null ? null : {'transaction': transaction},
    );
  }

  /// Names the missing prerequisite and offers to create it.
  void _refuseWithoutAccount(BuildContext context) {
    final l10n = context.l10n;

    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.addAccountBeforeTransactionDescription),
          action: SnackBarAction(
            label: l10n.accountsAddTooltip,
            // The SnackBar outlives the row that was tapped, so this widget's
            // own context is what opens the dialog.
            onPressed: () {
              if (!mounted) return;
              _showAddAccountDialog(this.context);
            },
          ),
        ),
      );
  }

  /// Account creation, on the root navigator: the dialog is a sibling of this
  /// list rather than a descendant, so it has to be handed the blocs itself.
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

  void _showContextMenu(
    BuildContext context,
    Offset position,
    bool isSelected,
    TransactionCategory transactionCategory,
  ) async {
    final bloc = context.read<TransactionsBloc>();
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final l10n = context.l10n;
    final value = await showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
        Offset.zero & overlay.size,
      ),
      items: <PopupMenuEntry<dynamic>>[
        PopupMenuItem(
          value: 'select',
          child: Text(
            isSelected ? l10n.contextMenuDeselect : l10n.contextMenuSelect,
          ),
        ),
        PopupMenuItem(
          value: 'select_all',
          child: Text(l10n.contextMenuSelectAll),
        ),
        if (bloc.state.selectedTransactionIds.isNotEmpty)
          PopupMenuItem(
            value: 'deselect_all',
            child: Text(l10n.contextMenuDeselectAll),
          ),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'edit', child: Text(l10n.contextMenuEdit)),
        PopupMenuItem(value: 'delete', child: Text(l10n.contextMenuDelete)),
      ],
    );

    if (!context.mounted || value == null) return;

    if (value == 'select') {
      if (!bloc.state.isSelectionModeActive) {
        bloc.add(const ToggleSelectionMode(true));
      }
      bloc.add(ToggleTransactionSelection(transactionCategory.transaction.id!));
    } else if (value == 'select_all') {
      if (!bloc.state.isSelectionModeActive) {
        bloc.add(const ToggleSelectionMode(true));
      }
      bloc.add(const SelectAllTransactions());
    } else if (value == 'deselect_all') {
      bloc.add(const ClearSelection());
    } else if (value == 'edit') {
      _openTransactionForm(
        context,
        transaction: transactionCategory.transaction,
      );
    } else if (value == 'delete') {
      DialogUtils.showAppDialog(
        context: context,
        resizeToAvoidBottomInset: false,
        child: AlertDialog(
          title: Text(l10n.deleteTransactionsConfirmationTitle),
          content: Text(l10n.deleteTransactionsConfirmationMessage('1')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
              child: Text(l10n.cancelButton),
            ),
            TextButton(
              onPressed: () {
                bloc.add(
                  DeleteTransaction(transactionCategory.transaction.id!),
                );
                Navigator.of(context, rootNavigator: true).pop();
              },
              child: Text(l10n.deleteButton),
            ),
          ],
        ),
      );
    }
  }

  void _showEmptyAreaContextMenu(BuildContext context, Offset position) async {
    final l10n = context.l10n;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final value = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
        Offset.zero & overlay.size,
      ),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem(
          value: 'add_transaction',
          child: Row(
            children: [
              const Icon(Icons.add),
              const SizedBox(width: 8),
              Flexible(child: Text(l10n.addTransactionDescription)),
            ],
          ),
        ),
      ],
    );

    if (!context.mounted || value == null) return;

    if (value == 'add_transaction') {
      _openTransactionForm(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsBloc, SettingsState>(
      listener: (context, settingsState) {
        final newCurrency = settingsState.settings['main_currency_code'];
        final transactionsBloc = context.read<TransactionsBloc>();

        if (transactionsBloc.state.status == TransactionStatus.success &&
            newCurrency != null &&
            newCurrency != transactionsBloc.state.mainCurrencyCode) {
          transactionsBloc.add(const InitialLoadTransactions());
        }
      },
      child: BlocBuilder<TransactionsBloc, TransactionsState>(
        builder: (context, state) {
          if (state.status == TransactionStatus.initial &&
              state.transactions.isEmpty) {
            return const AppStateView.loading();
          }
          if (state.status == TransactionStatus.failure) {
            return AppStateView.error(
              message: context.l10n.accountsLoadFailure,
            );
          }
          if (state.status == TransactionStatus.success &&
              state.transactions.isEmpty) {
            return AppStateView.empty(message: context.l10n.noDataForPeriod);
          }

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onSecondaryTapUp: (details) =>
                _showEmptyAreaContextMenu(context, details.globalPosition),
            onLongPressStart: (details) =>
                _showEmptyAreaContextMenu(context, details.globalPosition),
            child: Stack(
              children: [
                RepaintBoundary(
                  child: GroupedPaginatedList<TransactionCategory, DateTime>(
                    items: state.transactions,
                    hasMoreUp: state.hasMoreUp,
                    hasMoreDown: state.hasMoreDown,
                    onFetchMoreUp: () => context.read<TransactionsBloc>().add(
                      const LoadTransactionsUp(),
                    ),
                    onFetchMoreDown: () => context.read<TransactionsBloc>().add(
                      const LoadTransactionsDown(),
                    ),
                    groupKeyGetter: (item) => DateTime(
                      item.transaction.date.year,
                      item.transaction.date.month,
                      item.transaction.date.day,
                    ),
                    groupHeaderBuilder: (context, date) {
                      final dailyTotal = state.dailyTotals[date] ?? 0.0;
                      return _DateHeader(
                        date: date,
                        dailySum: dailyTotal,
                        mainCurrencyCode: state.mainCurrencyCode,
                        currencyDesignations: state.currencyDesignations,
                      );
                    },
                    itemBuilder: (context, item) {
                      final bloc = context.read<TransactionsBloc>();
                      return TransactionListItem(
                        transactionCategory: item,
                        isSelected: state.selectedTransactionIds.contains(
                          item.transaction.id,
                        ),
                        onTap: () {
                          if (state.isSelectionModeActive) {
                            bloc.add(
                              ToggleTransactionSelection(item.transaction.id!),
                            );
                          } else {
                            _openTransactionForm(
                              context,
                              transaction: item.transaction,
                            );
                          }
                        },
                        onLongPress: () {
                          if (!state.isSelectionModeActive) {
                            bloc.add(const ToggleSelectionMode(true));
                          }
                          bloc.add(
                            ToggleTransactionSelection(item.transaction.id!),
                          );
                        },
                        onSecondaryTapUp: (details) {
                          if (kIsWeb ||
                              defaultTargetPlatform == TargetPlatform.macOS ||
                              defaultTargetPlatform == TargetPlatform.linux ||
                              defaultTargetPlatform == TargetPlatform.windows) {
                            _showContextMenu(
                              context,
                              details.globalPosition,
                              state.selectedTransactionIds.contains(
                                item.transaction.id,
                              ),
                              item,
                            );
                          }
                        },
                        mainCurrencyCode: state.mainCurrencyCode,
                        currencyDesignations: state.currencyDesignations,
                      );
                    },
                    jumpToItemId: state.jumpToItemId,
                    jumpToAlignment: state.jumpToAlignment,
                    keyComparator: (a, b) {
                      // Assuming Sort is available and has ascending/descending
                      // If Sort is definitely OrderingMode from drift:
                      // if (state.sort == OrderingMode.asc) return a.compareTo(b);
                      // return b.compareTo(a);
                      // But checking for 'Sort' enum.
                      if (state.sort.toString().contains('ascending') ||
                          state.sort.index == 0) {
                        // Safety fallback if Enum name unkown
                        return a.compareTo(b);
                      }
                      return b.compareTo(a);
                    },
                  ),
                ),
                if (state.status == TransactionStatus.loading)
                  const Positioned(
                    top: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Card(
                        shape: CircleBorder(),
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({
    required this.date,
    required this.dailySum,
    required this.mainCurrencyCode,
    required this.currencyDesignations,
  });

  final DateTime date;
  final double dailySum;
  final String mainCurrencyCode;
  final List<CurrencyDesignation> currencyDesignations;

  @override
  Widget build(BuildContext context) {
    // Money direction is a theme token, not a literal: the user picks the seed
    // colour, so a hardcoded green can land on top of the primary. The glyph
    // beside the figure carries the same information without colour, for
    // greyscale and for red-green colour blindness.
    final moneyColors = MoneyColors.of(context);
    final color = moneyColors.forAmount(dailySum);
    final signGlyph = dailySum == 0 || !dailySum.isFinite
        ? ''
        : MoneyColors.signGlyph(isIncome: dailySum > 0);
    // Locale-aware: the old 'EEE, MMM d, yyyy' was an English pattern printed
    // to all ten locales.
    final formattedDate = DateDisplay.listHeader(context, date);

    final designation = currencyDesignations.firstWhereOrNull(
      (d) => d.currencyCode == mainCurrencyCode,
    );
    final currencySymbol = designation?.value ?? mainCurrencyCode;

    // Sign lives in the glyph, so the number itself is the magnitude.
    final formattedSum = MoneyFormatter.formatWithSymbol(
      dailySum.abs(),
      mainCurrencyCode,
      currencySymbol,
      prefix: signGlyph,
    );

    return ListTile(
      title: Text(
        formattedDate,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      trailing: Text(
        formattedSum,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class TransactionListItem extends StatelessWidget {
  const TransactionListItem({
    required this.transactionCategory,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onSecondaryTapUp,
    required this.mainCurrencyCode,
    required this.currencyDesignations,
    super.key,
  });

  final TransactionCategory transactionCategory;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Function(TapUpDetails) onSecondaryTapUp;
  final String mainCurrencyCode;
  final List<CurrencyDesignation> currencyDesignations;

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    return Color(int.parse("0x$hexColor"));
  }

  @override
  Widget build(BuildContext context) {
    final isRegularTransfer =
        transactionCategory.linkedTransaction != null &&
        !transactionCategory.isAssetTransaction &&
        !transactionCategory.isLinkedAssetTransaction;

    final color = isRegularTransfer
        ? Theme.of(context).colorScheme.outline
        : _getColorFromHex(transactionCategory.style.colorHex);

    final iconWidget = isRegularTransfer
        // White on the 15%-alpha `outline` chip below is white on surface in
        // the light theme, i.e. invisible. The chip's own hue reads on both.
        ? Icon(Icons.compare_arrows, color: color)
        : IconUtils.getIconWidget(transactionCategory.style);

    final amount = transactionCategory.transaction.amount;
    final moneyColors = MoneyColors.of(context);
    final balanceColor = moneyColors.forAmount(amount);
    final signGlyph = amount == 0 || !amount.isFinite
        ? ''
        : MoneyColors.signGlyph(isIncome: amount > 0);

    final designation = currencyDesignations.firstWhereOrNull(
      (d) => d.currencyCode == transactionCategory.transaction.currencyCode,
    );
    final currencySymbol =
        designation?.value ?? transactionCategory.transaction.currencyCode;

    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      color: isSelected ? Theme.of(context).highlightColor : null,
      child: GestureDetector(
        onSecondaryTapUp: onSecondaryTapUp,
        child: ListTile(
          onTap: onTap,
          onLongPress: onLongPress,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20.0,
            vertical: 10.0,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: color.withAlpha((255 * 0.15).round()),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: iconWidget,
          ),
          title: Text(
            transactionCategory.category?.name ==
                    AppConstants.systemTransferCategoryName
                ? context.l10n.transferLabel
                : (transactionCategory.category?.name ??
                      context.l10n.uncategorizedLabel),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (transactionCategory.transaction.description.isNotEmpty) ...[
                Text(
                  transactionCategory.transaction.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 2),
              ],
              Text(
                transactionCategory.isAssetTransaction
                    // The quantity is dropped into a translated sentence, so
                    // it has to be isolated or an RTL paragraph reorders it.
                    ? context.l10n.quantityLabel(
                        MoneyFormatter.isolate(
                          transactionCategory.transaction.amount
                              .toStringAsFixed(2),
                        ),
                      )
                    : MoneyFormatter.formatWithSymbol(
                        transactionCategory.transaction.amount.abs(),
                        transactionCategory.transaction.currencyCode,
                        currencySymbol,
                        prefix: signGlyph,
                      ),
                style: TextStyle(color: balanceColor, fontSize: 14),
              ),
              if (transactionCategory.linkedTransaction != null &&
                  (transactionCategory.isAssetTransaction ||
                      transactionCategory.isLinkedAssetTransaction)) ...[
                const SizedBox(height: 2),
                Builder(
                  builder: (context) {
                    final linkedTx = transactionCategory.linkedTransaction!;
                    final linkedDesignation = currencyDesignations
                        .firstWhereOrNull(
                          (d) => d.currencyCode == linkedTx.currencyCode,
                        );
                    final linkedSymbol =
                        linkedDesignation?.value ?? linkedTx.currencyCode;

                    final isLinkedAsset =
                        !transactionCategory.isAssetTransaction;
                    // If current is NOT asset, then linked IS asset (usually).
                    // If current IS asset, then linked is Cash.

                    return Text(
                      isLinkedAsset
                          ? context.l10n.quantityLabel(
                              MoneyFormatter.isolate(
                                '${linkedTx.amount > 0 ? '+' : ''}'
                                '${linkedTx.amount.toStringAsFixed(2)}',
                              ),
                            )
                          : MoneyFormatter.formatWithSymbol(
                              linkedTx.amount,
                              linkedTx.currencyCode,
                              linkedSymbol,
                              signed: true,
                            ),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                        height: 1.2,
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
