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
  final int limit = 50;
  @override
  void initState() {
    super.initState();
    _listController = ListController();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionsBloc, TransactionsState>(
      builder: (context, state) {
        if (state.status == TransactionStatus.initial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == TransactionStatus.failure) {
          return const Center(child: Text('Failed to load transactions'));
        }
        if (state.transactions.isEmpty &&
            state.status != TransactionStatus.loading) {
          return const Center(child: Text('No transactions found.'));
        }

        return CustomScrollView(
          controller: _scrollController,
          cacheExtent: 0,
          slivers: [
            SuperSliverList(
              listController: _listController,
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  print("Index element $index name element: ${state.transactions[index].description} >= ${state.transactions.length - 1}");
                  // --- TRIGGER UP ---
                  if (index == 0 && state.hasMoreUp && state.status != TransactionStatus.loading) {
                     WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (context.mounted) {
                        context.read<TransactionsBloc>().add(LoadTransactionsUp());
                      }
                    });
                  }

                  // --- TRIGGER DOWN (SKELETONS) ---
                  if (index >= state.transactions.length - 1) {
                     if (state.hasMoreDown && state.status != TransactionStatus.loading) {
                        // WidgetsBinding.instance.addPostFrameCallback((_) {
                        //   if (context.mounted) {
                        //     context.read<TransactionsBloc>().add(LoadTransactionsDown());
                        //     if(index == state.windowSize){
                        //     _listController.jumpToItem(index: index -50 , scrollController: _scrollController , alignment: 0.9);
                        //     }
                        //     print("Jump to element ${index-50} name element: ${state.transactions[index-50].description}");
                        //   }
                        // });
                      
                          context.read<TransactionsBloc>().add(LoadTransactionsDown());
                        if(index == state.windowSize - 1){
                            _listController.jumpToItem(index: index - limit , scrollController: _scrollController , alignment: 1);
                            //index = index - 50;
                            print("Jump to element ${index - limit} name element: ${state.transactions[index-50].description}");
                          } 
                       
                     }
                     //return const TransactionSkeletonItem();
                  }

                  final transaction = state.transactions[index];
                  
                  return TransactionListItem(
                    key: ValueKey(transaction.id), 
                    transaction: transaction,
                  );
                },
                //childCount: state.transactions.length + (state.hasMoreDown ? 5 : 0),
                childCount: state.transactions.length,
              ),
            ),
          ],
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

class TransactionSkeletonItem extends StatelessWidget {
  const TransactionSkeletonItem({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleMedium;
    final subtitleStyle = theme.textTheme.bodyMedium;

    return ListTile(
      title: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: 0.7,
          child: Container(
            height: titleStyle?.fontSize,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
      subtitle: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: 0.4,
          child: Container(
            height: subtitleStyle?.fontSize,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.08),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}
