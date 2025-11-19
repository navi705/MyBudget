import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:my_budget_client/app.dart';
import 'package:my_budget_client/core/di/injection_container.dart' as sl;
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/presentation/blocs/categories/categories_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency/currency_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency_converter/currency_converter_bloc.dart';
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await sl.init();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => sl.sl<AccountsBloc>()..add(LoadAccounts()),
        ),
        BlocProvider(
          create: (context) => sl.sl<SettingsBloc>()..add(LoadSettings()),
        ),
        BlocProvider(
          create: (context) => sl.sl<CurrencyBloc>()..add(LoadCurrencies()),
        ),
        BlocProvider(
          create: (context) => sl.sl<StylesBloc>()..add(LoadStyles()),
        ),
        BlocProvider(
          create: (context) => sl.sl<CategoriesBloc>()..add(LoadCategories()),
        ),
        BlocProvider(
          create: (context) => sl.sl<TransactionsBloc>()..add(LoadTransactions()),
        ),
        BlocProvider(
          create: (context) => sl.sl<CurrencyConverterBloc>()..add(LoadCurrencyConverter()),
        ),
      ],
      child: const App(),
    );
  }
}
