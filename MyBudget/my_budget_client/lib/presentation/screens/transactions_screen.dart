import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<TransactionsBloc>().add(LoadMoreTransactions());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    // Load more when we are at 90% of the screen
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
      ),
      body: BlocBuilder<TransactionsBloc, TransactionsState>(
        builder: (context, state) {
          if (state is TransactionsLoadInProgress) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TransactionsLoadSuccess) {
            if (state.transactions.isEmpty) {
              return const Center(child: Text('No transactions yet.'));
            }
            return ListView.builder(
              controller: _scrollController,
              itemCount: state.hasReachedMax
                  ? state.transactions.length
                  : state.transactions.length + 1,
              itemBuilder: (context, index) {
                if (index >= state.transactions.length) {
                  return const Center(child: CircularProgressIndicator());
                }
                final transaction = state.transactions[index];
                return ListTile(
                  title: Text(transaction.description),
                  subtitle: Text(
                      '${transaction.amount} on ${DateFormat.yMd().add_Hms().format(transaction.date.toLocal())}'),
                  onTap: () {
                    context.push(AppRoutes.addEditTransaction,
                        extra: {'transactionId': transaction.id});
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () {
                      context
                          .read<TransactionsBloc>()
                          .add(DeleteTransaction(transaction.id!));
                    },
                  ),
                );
              },
            );
          }
          return const Center(child: Text('Failed to load transactions.'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push(AppRoutes.addEditTransaction);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}