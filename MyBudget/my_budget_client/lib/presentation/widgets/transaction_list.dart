import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';
import 'package:my_budget_client/presentation/widgets/bottom_loader.dart';


class TransactionList extends StatefulWidget {
  const TransactionList({super.key});

  @override
  State<TransactionList> createState() => _TransactionListState();
}

class _TransactionListState extends State<TransactionList> {
  final Key centerKey = const ValueKey('center-anchor');

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionsBloc, TransactionsState>(
      builder: (context, state) {
        switch (state.status) {
          case TransactionStatus.failure:
            return const Center(
              child: Text(
                'failed to fetch transcation list',
                style: TextStyle(color: Color.fromARGB(255, 255, 0, 0)),
              ),
            );
          case TransactionStatus.success:
            if (state.upList.isEmpty && state.downList.isEmpty) {
              return const Center(child: Text('no transactions'));
            }
            return CustomScrollView(
              center: centerKey,
              slivers: [
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= state.upList.length - 5 && state.hasMoreUp) {
                        context.read<TransactionsBloc>().add(LoadTransactionsUp());
                      }
                      final transaction = state.upList[index];
                      return TransactionListItem(transaction: transaction);
                    },
                    childCount: state.upList.length,
                  ),
                ),
                SliverList(
                  key: centerKey,
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= state.downList.length - 5 && state.hasMoreDown) {
                        context.read<TransactionsBloc>().add(LoadTransactionsDown());
                      }
                      final transaction = state.downList[index];
                      return TransactionListItem(transaction: transaction);
                    },
                    childCount: state.downList.length,
                  ),
                ),
              ],
            );
          case TransactionStatus.initial:
          case TransactionStatus.loading:
            return const BottomLoader();
        }
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
