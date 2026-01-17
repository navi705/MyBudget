import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  ) {
    final bloc = context.read<TransactionsBloc>();
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
        Offset.zero & overlay.size,
      ),
      items: <PopupMenuEntry<dynamic>>[
        PopupMenuItem(
          value: 'select',
          child: Text(isSelected ? 'Deselect' : 'Select'),
        ),
        const PopupMenuItem(value: 'select_all', child: Text('Select All')),
        if (bloc.state.selectedTransactionIds.isNotEmpty)
          const PopupMenuItem(
            value: 'deselect_all',
            child: Text('Deselect All'),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
        const PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    ).then((value) {
      if (!mounted) return;
      if (value == 'select') {
        if (!bloc.state.isSelectionModeActive) {
          bloc.add(const ToggleSelectionMode(true));
        }
        bloc.add(
          ToggleTransactionSelection(transactionCategory.transaction.id!),
        );
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
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete Transaction'),
            content: const Text(
              'Are you sure you want to delete this transaction?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  bloc.add(
                    DeleteTransaction(transactionCategory.transaction.id!),
                  );
                  Navigator.pop(dialogContext);
                },
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      }
    });
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
            return const Center(child: Text('Failed to load transactions'));
          }

          return Stack(
            children: [
              GroupedPaginatedList<TransactionCategory, DateTime>(
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
    final formattedDate = DateFormat('EEE, MMM d, yyyy').format(date);

    final designation = currencyDesignations.firstWhereOrNull(
      (d) => d.currencyCode == mainCurrencyCode,
    );
    final currencySymbol = designation?.value ?? mainCurrencyCode;

    final formattedSum = NumberFormat.currency(
      symbol: currencySymbol,
    ).format(dailySum);

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

class TransactionListItem extends StatefulWidget {
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

  @override
  State<TransactionListItem> createState() => _TransactionListItemState();
}

class _TransactionListItemState extends State<TransactionListItem> {
  bool _isHovering = false;

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    return Color(int.parse("0x$hexColor"));
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColorFromHex(widget.transactionCategory.style.colorHex);
    final iconWidget = IconUtils.getIconWidget(
      widget.transactionCategory.style,
    );

    final amount = widget.transactionCategory.transaction.amount;
    Color balanceColor;
    if (amount > 0) {
      balanceColor = Colors.green;
    } else if (amount < 0) {
      balanceColor = Colors.red;
    } else {
      balanceColor = Colors.grey[600]!; // Default or specific for zero
    }

    final designation = widget.currencyDesignations.firstWhereOrNull(
      (d) =>
          d.currencyCode == widget.transactionCategory.transaction.currencyCode,
    );
    final currencySymbol =
        designation?.value ??
        widget.transactionCategory.transaction.currencyCode;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onLongPress: widget.onLongPress,
        onTap: widget.onTap,
        onSecondaryTapUp: widget.onSecondaryTapUp,
        child: Card(
          elevation: 2.0,
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
            side: _isHovering
                ? BorderSide(color: Theme.of(context).primaryColor, width: 2.0)
                : BorderSide.none,
          ),
          color: widget.isSelected
              ? Theme.of(context).highlightColor
              : _isHovering
              ? Colors.grey.withValues(alpha: 0.1)
              : null,
          child: ListTile(
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
              widget.transactionCategory.transaction.description,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.transactionCategory.isAssetTransaction
                      ? 'Qty: ${widget.transactionCategory.transaction.amount.toStringAsFixed(2)}'
                      : '${widget.transactionCategory.transaction.amount.toStringAsFixed(2)} $currencySymbol',
                  style: TextStyle(color: balanceColor, fontSize: 14),
                ),
                if (widget.transactionCategory.linkedTransaction != null) ...[
                  const SizedBox(height: 2),
                  Builder(
                    builder: (context) {
                      final linkedTx =
                          widget.transactionCategory.linkedTransaction!;
                      final linkedDesignation = widget.currencyDesignations
                          .firstWhereOrNull(
                            (d) => d.currencyCode == linkedTx.currencyCode,
                          );
                      final linkedSymbol =
                          linkedDesignation?.value ?? linkedTx.currencyCode;

                      final isLinkedAsset =
                          !widget.transactionCategory.isAssetTransaction;
                      // If current is NOT asset, then linked IS asset (usually).
                      // If current IS asset, then linked is Cash.

                      return Text(
                        isLinkedAsset
                            ? 'Qty: ${linkedTx.amount > 0 ? '+' : ''}${linkedTx.amount.toStringAsFixed(2)}'
                            : '${linkedTx.amount > 0 ? '+' : ''}${linkedTx.amount.toStringAsFixed(2)} $linkedSymbol',
                        style: TextStyle(
                          color: Colors.grey[600],
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
      ),
    );
  }
}
