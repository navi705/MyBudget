import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/domain/entities/transaction_category.dart'; // Import TransactionCategory
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';
import 'package:my_budget_client/core/utils/icon_utils.dart'; // Import IconUtils
import 'package:super_sliver_list/super_sliver_list.dart';

class TransactionList extends StatefulWidget {
  const TransactionList({super.key});

  @override
  State<TransactionList> createState() => _TransactionListState();
}

class _TransactionListState extends State<TransactionList> {
  late ListController _listController;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _listController = ListController();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _listController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Map<DateTime, List<TransactionCategory>> _groupTransactionsByDay(
    List<TransactionCategory> transactions,
  ) {
    final Map<DateTime, List<TransactionCategory>> grouped = {};
    for (final transactionCategory in transactions) {
      final date = DateTime(
        transactionCategory.transaction.date.year,
        transactionCategory.transaction.date.month,
        transactionCategory.transaction.date.day,
      );
      if (grouped[date] == null) {
        grouped[date] = [];
      }
      grouped[date]!.add(transactionCategory);
    }
    return grouped;
  }

  List<Widget> _buildListItems(
    List<TransactionCategory> transactionCategories,
  ) {
    final groupedTransactions = _groupTransactionsByDay(transactionCategories);
    final sortedDates = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final List<Widget> listItems = [];
    for (final date in sortedDates) {
      final transactionsForDay = groupedTransactions[date]!;
      final dailySum = transactionsForDay.fold<double>(
        0,
        (sum, tc) => sum + tc.transaction.amount,
      );

      listItems.add(
        _DateHeader(key: ValueKey(date), date: date, dailySum: dailySum),
      );

      for (final transactionCategory in transactionsForDay) {
        listItems.add(
          TransactionListItem(
            key: ValueKey(transactionCategory.transaction.id),
            transactionCategory: transactionCategory,
          ),
        );
      }

      listItems.add(Divider(key: ValueKey('divider_$date')));
    }
    return listItems;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TransactionsBloc, TransactionsState>(
      listenWhen: (previous, current) => current.jumpToItemId != null,
      listener: (context, state) {
        if (state.jumpToItemId != null && state.jumpToAlignment != null) {
          final listItems = _buildListItems(state.transactions);
          final index = listItems.indexWhere((item) {
            if (item is TransactionListItem) {
              return item.transactionCategory.transaction.id ==
                  state.jumpToItemId;
            }
            return false;
          });

          if (index != -1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _listController.jumpToItem(
                  index: index,
                  scrollController: _scrollController,
                  alignment: state.jumpToAlignment!,
                );
              }
            });
          }
        }
      },
      builder: (context, state) {
        if (state.status == TransactionStatus.initial &&
            state.transactions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == TransactionStatus.failure) {
          return const Center(child: Text('Failed to load transactions'));
        }
        if (state.transactions.isEmpty &&
            state.status != TransactionStatus.loading) {
          return const Center(child: Text('No transactions found.'));
        }

        final listItems = _buildListItems(state.transactions);

        return NotificationListener<ScrollNotification>(
          onNotification: (scrollInfo) {
            if (scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 200) {
              if (state.hasMoreDown &&
                  state.status != TransactionStatus.loading) {
                context.read<TransactionsBloc>().add(
                  const LoadTransactionsDown(),
                );
              }
            }

            if (scrollInfo.metrics.pixels <= 200) {
              if (state.hasMoreUp &&
                  state.status != TransactionStatus.loading) {
                context.read<TransactionsBloc>().add(
                  const LoadTransactionsUp(),
                );
              }
            }
            return false;
          },
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SuperSliverList(
                listController: _listController,
                delegate: SliverChildBuilderDelegate((context, index) {
                  return listItems[index];
                }, childCount: listItems.length),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.date, required this.dailySum, super.key});

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
  const TransactionListItem({required this.transactionCategory, super.key});

  final TransactionCategory transactionCategory;

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    return Color(int.parse("0x$hexColor"));
  }

  void _showContextMenu(BuildContext context, Offset position) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
        Offset.zero & overlay.size,
      ),
      items: [
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
      if (value == 'edit') {
        context.push(
          AppRoutes.addEditTransaction,
          extra: {'transaction': transactionCategory.transaction},
        );
      } else if (value == 'delete') {
        // TODO: Show confirmation dialog before deleting
        context
            .read<TransactionsBloc>()
            .add(DeleteTransaction(transactionCategory.transaction.id!));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.watch<TransactionsBloc>();
    final isSelected = bloc.state.selectedTransactionIds
        .contains(transactionCategory.transaction.id);

    final color = _getColorFromHex(transactionCategory.style.colorHex);
    final iconWidget = IconUtils.getIconWidget(transactionCategory.style);

    return GestureDetector(
      onLongPress: () {
        bloc.add(const ToggleSelectionMode(true));
        bloc.add(ToggleTransactionSelection(transactionCategory.transaction.id!));
      },
      onTap: () {
        if (bloc.state.isSelectionModeActive) {
          bloc.add(ToggleTransactionSelection(transactionCategory.transaction.id!));
        } else {
          context.push(
            AppRoutes.addEditTransaction,
            extra: {'transaction': transactionCategory.transaction},
          );
        }
      },
      onSecondaryTapUp: (details) {
        if (kIsWeb ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.windows) {
          _showContextMenu(context, details.globalPosition);
        }
      },
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
