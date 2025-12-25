import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/domain/entities/transaction_category.dart'; // Import TransactionCategory
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';
import 'package:my_budget_client/core/utils/icon_utils.dart'; // Import IconUtils
import 'package:my_budget_client/presentation/widgets/generic/grouped_paginated_list.dart';

class TransactionList extends StatefulWidget {
  const TransactionList({super.key});

  @override
  State<TransactionList> createState() => _TransactionListState();
}

class _TransactionListState extends State<TransactionList> {
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
        const PopupMenuItem(
          value: 'select_all',
          child: Text('Select All'),
        ),
        if (bloc.state.selectedTransactionIds.isNotEmpty)
          const PopupMenuItem(
            value: 'deselect_all',
            child: Text('Deselect All'),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'edit',
          child: Text('Edit'),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Text('Delete'),
        ),
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
                'Are you sure you want to delete this transaction?'),
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
    return BlocBuilder<TransactionsBloc, TransactionsState>(
      builder: (context, state) {
        if (state.status == TransactionStatus.initial &&
            state.transactions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == TransactionStatus.failure) {
          return const Center(child: Text('Failed to load transactions'));
        }

        return GroupedPaginatedList<TransactionCategory, DateTime>(
          items: state.transactions,
          hasMoreUp: state.hasMoreUp,
          hasMoreDown: state.hasMoreDown,
          onFetchMoreUp: () =>
              context.read<TransactionsBloc>().add(const LoadTransactionsUp()),
          onFetchMoreDown: () => context
              .read<TransactionsBloc>()
              .add(const LoadTransactionsDown()),
          groupKeyGetter: (item) => DateTime(
            item.transaction.date.year,
            item.transaction.date.month,
            item.transaction.date.day,
          ),
          groupHeaderBuilder: (context, date) {
            final dailySum = state.transactions
                .where((tc) =>
                    tc.transaction.date.year == date.year &&
                    tc.transaction.date.month == date.month &&
                    tc.transaction.date.day == date.day)
                .fold<double>(0, (sum, tc) => sum + tc.transaction.amount);
            return _DateHeader(date: date, dailySum: dailySum);
          },
          itemBuilder: (context, item) {
            final bloc = context.read<TransactionsBloc>();
            return TransactionListItem(
              transactionCategory: item,
              isSelected:
                  state.selectedTransactionIds.contains(item.transaction.id),
              onTap: () {
                if (state.isSelectionModeActive) {
                  bloc.add(ToggleTransactionSelection(item.transaction.id!));
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
                bloc.add(ToggleTransactionSelection(item.transaction.id!));
              },
              onSecondaryTapUp: (details) {
                if (kIsWeb ||
                    defaultTargetPlatform == TargetPlatform.macOS ||
                    defaultTargetPlatform == TargetPlatform.linux ||
                    defaultTargetPlatform == TargetPlatform.windows) {
                  _showContextMenu(
                    context,
                    details.globalPosition,
                    state.selectedTransactionIds.contains(item.transaction.id),
                    item,
                  );
                }
              },
            );
          },
          jumpToItemId: state.jumpToItemId,
          jumpToAlignment: state.jumpToAlignment,
        );
      },
    );
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.date, required this.dailySum});

  final DateTime date;
  final double dailySum;

  @override
  Widget build(BuildContext context) {
    final color = dailySum >= 0 ? Colors.green : Colors.red;
    final formattedDate = DateFormat('EEE, MMM d, yyyy').format(date);
    final formattedSum = NumberFormat.currency(symbol: '').format(dailySum);

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
    super.key,
  });

  final TransactionCategory transactionCategory;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Function(TapUpDetails) onSecondaryTapUp;

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    return Color(int.parse("0x$hexColor"));
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColorFromHex(transactionCategory.style.colorHex);
    final iconWidget = IconUtils.getIconWidget(transactionCategory.style);

    return GestureDetector(
      onLongPress: onLongPress,
      onTap: onTap,
      onSecondaryTapUp: onSecondaryTapUp,
      child: Container(
        color: isSelected ? Theme.of(context).highlightColor : null,
        child: ListTile(
          leading: CircleAvatar(backgroundColor: color, child: iconWidget),
          title: Text(transactionCategory.transaction.description),
          subtitle: Text(transactionCategory.transaction.amount.toString()),
        ),
      ),
    );
  }
}
