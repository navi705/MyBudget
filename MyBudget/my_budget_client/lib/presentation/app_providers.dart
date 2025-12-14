import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/core/di/injection_container.dart' as di;
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/presentation/blocs/categories/categories_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency/currency_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency_converter/currency_converter_bloc.dart';
import 'package:my_budget_client/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';

class AppProviders extends StatelessWidget {
  final Widget child;
  const AppProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
            create: (context) => di.sl<SettingsBloc>()..add(LoadSettings())),
        BlocProvider(
            create: (context) => di.sl<AccountsBloc>()..add(LoadAccounts())),
        BlocProvider(
            create: (context) => di.sl<CurrencyBloc>()..add(LoadCurrencies())),
        BlocProvider(
            create: (context) => di.sl<StylesBloc>()..add(LoadStyles())),
        BlocProvider(
            create: (context) =>
                di.sl<CategoriesBloc>()..add(LoadCategories())),
        BlocProvider(create: (context) => di.sl<TransactionsBloc>()), //..add(InnitialLoadTransactions(
        BlocProvider(
            create: (context) =>
                di.sl<CurrencyConverterBloc>()..add(LoadCurrencyConverter())),
        BlocProvider(
            create: (context) => di.sl<DashboardBloc>()),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return child;
        },
      ),
    );
  }
}
