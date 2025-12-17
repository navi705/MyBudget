import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';
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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TransactionsBloc, TransactionsState>(
      // 1. LISTEN: Only jump when Bloc sends a specific index
      listenWhen: (previous, current) => current.jumpToIndex != null,
      listener: (context, state) {
        if (state.jumpToIndex != null && state.jumpToAlignment != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _listController.jumpToItem(
                index: state.jumpToIndex!,
                scrollController: _scrollController,
                alignment: state.jumpToAlignment!,
              );
            }
          });
        }
      },

      builder: (context, state) {
        if (state.status == TransactionStatus.initial && state.transactions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == TransactionStatus.failure) {
          return const Center(child: Text('Failed to load transactions'));
        }
        if (state.transactions.isEmpty &&
            state.status != TransactionStatus.loading) {
          return const Center(child: Text('No transactions found.'));
        }

        // 2. Use NotificationListener for triggers
        return NotificationListener<ScrollNotification>(
          onNotification: (scrollInfo) {
            // Check if we are near bottom (scrolling down)
            if (scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 200) {
              if (state.hasMoreDown && state.status != TransactionStatus.loading) {
                context.read<TransactionsBloc>().add(LoadTransactionsDown());
              }
            }

            // Check if we are near top (scrolling up)
            if (scrollInfo.metrics.pixels <= 200) {
              if (state.hasMoreUp && state.status != TransactionStatus.loading) {
                context.read<TransactionsBloc>().add(LoadTransactionsUp());
              }
            }
            return false;
          },
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SuperSliverList(
                listController: _listController,
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final transaction = state.transactions[index];
                    return TransactionListItem(
                      key: ValueKey(transaction.id), // Key is vital!
                      transaction: transaction,
                    );
                  },
                  childCount: state.transactions.length,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class TransactionListItem extends StatelessWidget {
  const TransactionListItem({required this.transaction, super.key});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(transaction.description),
      subtitle: Text(transaction.amount.toString()),
      onTap: () {
        context.push(
          AppRoutes.addEditTransaction,
          extra: {'transactionId': transaction.id},
        );
      },
    );
  }
}