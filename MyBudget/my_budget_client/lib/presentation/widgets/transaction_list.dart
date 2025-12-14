import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';
import 'package:my_budget_client/presentation/widgets/bottom_loader.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';


class TransactionList extends StatefulWidget {
  const TransactionList({super.key});

  @override
  State<TransactionList> createState() => _TransactionListState();
}

class _TransactionListState extends State<TransactionList> {
  final itemScrollController = ItemScrollController();
  final itemPositionsListener = ItemPositionsListener.create();

  @override
  void initState() {
    super.initState();
     itemPositionsListener.itemPositions.addListener(_onScrollPositionChanged);
  }

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
            if (state.transactions.isEmpty) {
              return const Center(child: Text('no posts'));
            }
            return ScrollablePositionedList.builder(itemCount: state.transactions.length,
            itemScrollController: itemScrollController,
            itemPositionsListener: itemPositionsListener,
             itemBuilder: (context, index){
              return TransactionListItem(
                        transaction: state.transactions[index],
                      );
             });
          case TransactionStatus.initial:
            return const BottomLoader();
          case TransactionStatus.loading:
            return const BottomLoader();
        }
      },
    );
  }

  @override
  void dispose() {
    
    super.dispose();
  }

  void _onScrollPositionChanged() {
  final positions = itemPositionsListener.itemPositions.value;
  if (positions.isEmpty) return;

  final state = context.read<TransactionsBloc>().state;

  // ---- ВЕРХ ----
  final minIndex = positions
      .where((p) => p.itemTrailingEdge > 0)
      .map((p) => p.index)
      .reduce((a, b) => a < b ? a : b);

  if (minIndex <= 1 && state.hasMoreUp) {
    context.read<TransactionsBloc>().add(
      LoadTransactionsUp(),
    );
  }

  // ---- НИЗ ----
  final maxIndex = positions
      .where((p) => p.itemLeadingEdge < 1)
      .map((p) => p.index)
      .reduce((a, b) => a > b ? a : b);

  if (maxIndex >= state.transactions.length - 2 &&
      state.hasMoreDown) {
    context.read<TransactionsBloc>().add(
      LoadTransactionsDown(),
    );
  }
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
