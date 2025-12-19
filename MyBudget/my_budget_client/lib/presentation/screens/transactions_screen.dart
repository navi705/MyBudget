import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';
import 'package:my_budget_client/presentation/widgets/filter_date.dart';
import 'package:my_budget_client/presentation/widgets/transaction_list.dart';

class TransactionsScreen extends StatelessWidget  {
  const TransactionsScreen({super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FilterDate(),
      body: BlocBuilder<TransactionsBloc,TransactionsState>(
        builder: (context, state){
          return TransactionList();
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
