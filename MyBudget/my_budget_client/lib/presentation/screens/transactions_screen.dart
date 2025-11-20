import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

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
              itemCount: state.transactions.length,
              itemBuilder: (context, index) {
                final transaction = state.transactions[index];
                return ListTile(
                  title: Text(transaction.description),
                  subtitle: Text(
                      '${transaction.amount} on ${DateFormat.yMd().add_Hms().format(transaction.date.toLocal())}'),
                  onTap: () {
                    context.push(AppRoutes.addEditTransaction, extra: transaction);
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () {
                      context
                          .read<TransactionsBloc>()
                          .add(DeleteTransaction(transaction.id));
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