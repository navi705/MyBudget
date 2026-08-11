import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:my_budget_client/presentation/widgets/dashboard/accounts_overview_widget.dart';
import 'package:my_budget_client/presentation/widgets/generic/app_state_view.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';

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
            currencyCode: state.selectedCurrency,
          );
        }

        if (state is DashboardLoadFailure) {
          return AppStateView.error(
            message: context.l10n.failedToLoadDashboard,
            onRetry: () => context.read<DashboardBloc>().add(LoadDashboard()),
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
