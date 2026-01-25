import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:my_budget_client/presentation/widgets/dashboard/accounts_overview_widget.dart';

class AccountsDistributionScreen extends StatelessWidget {
  const AccountsDistributionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoadSuccess) {
          return AccountsOverviewWidget(
            accounts: state.accounts,
            dailyNetWorth: state.dailyNetWorth,
            dateRangeStart: state.dateRangeStart,
            dateRangeEnd: state.dateRangeEnd,
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
