import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/domain/entities/currency_designation.dart';
import 'package:my_budget_client/domain/entities/transaction_category.dart'; // Import TransactionCategory
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';
import 'package:my_budget_client/core/utils/icon_utils.dart'; // Import IconUtils
import 'package:my_budget_client/presentation/widgets/generic/grouped_paginated_list.dart';
import 'package:my_budget_client/core/utils/dialog_utils.dart';
import 'package:collection/collection.dart';

class TransactionList extends StatefulWidget {
  const TransactionList({super.key});

  @override
  State<TransactionList> createState() => _TransactionListState();
}

class _TransactionListState extends State<TransactionList> {
  @override
  void initState() {
    context.read<TransactionsBloc>().add(const InitialLoadTransactions());
    super.initState();
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
      context.push(
        AppRoutes.addEditTransaction,
        extra: {'transaction': transactionCategory.transaction},
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
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancelButton),
            ),
            TextButton(
              onPressed: () {
                bloc.add(
                  DeleteTransaction(transactionCategory.transaction.id!),
                );
                Navigator.pop(context);
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
      context.push(AppRoutes.addEditTransaction);
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
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == TransactionStatus.failure) {
            return Center(child: Text(context.l10n.accountsLoadFailure));
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
                            context.push(
                              AppRoutes.addEditTransaction,
                              extra: {'transaction': item.transaction},
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
    final color = dailySum >= 0 ? Colors.green : Colors.red;
    final formattedDate = DateFormat(
      'EEE, MMM d, yyyy',
      Localizations.localeOf(context).toString(),
    ).format(date);

    final designation = currencyDesignations.firstWhereOrNull(
      (d) => d.currencyCode == mainCurrencyCode,
    );
    final currencySymbol = designation?.value ?? mainCurrencyCode;

    final formattedSum =
        '${NumberFormat.decimalPattern().format(dailySum).replaceAll(',', ' ')} $currencySymbol';

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
        ? const Icon(Icons.compare_arrows, color: Colors.white)
        : IconUtils.getIconWidget(transactionCategory.style);

    final amount = transactionCategory.transaction.amount;
    Color balanceColor;
    if (amount > 0) {
      balanceColor = Colors.green;
    } else if (amount < 0) {
      balanceColor = Colors.red;
    } else {
      balanceColor = Theme.of(context).colorScheme.onSurfaceVariant;
    }

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
            transactionCategory.category?.name ?? 'Uncategorized',
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
                    ? context.l10n.quantityLabel(
                        transactionCategory.transaction.amount.toStringAsFixed(
                          2,
                        ),
                      )
                    : '${transactionCategory.transaction.amount.toStringAsFixed(2).replaceAll('.', ',').replaceAll(',', ' ')} $currencySymbol',
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
                              '${linkedTx.amount > 0 ? '+' : ''}${linkedTx.amount.toStringAsFixed(2)}',
                            )
                          : '${linkedTx.amount > 0 ? '+' : ''}${linkedTx.amount.toStringAsFixed(2).replaceAll('.', ',').replaceAll(',', ' ')} $linkedSymbol',
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
