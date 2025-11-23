import 'package:get_it/get_it.dart';
import 'package:my_budget_client/data/repositories/db_repository.dart';
import 'package:my_budget_client/data/repositories/local_db/local_category_repository.dart';
import 'package:my_budget_client/data/repositories/local_db/local_db_repository.dart';
import 'package:my_budget_client/data/repositories/local_db/local_settings_repository.dart';
import 'package:my_budget_client/data/repositories/local_db/local_style_repository.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/domain/repositories/style_repository.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/presentation/blocs/categories/categories_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency/currency_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency_converter/currency_converter_bloc.dart';
import 'package:my_budget_client/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';

import '../../data/repositories/local_db/local_account_repository.dart';
import '../../data/repositories/local_db/local_currency_designation_repository.dart';
import '../../data/repositories/local_db/local_currency_repository.dart';
import '../../data/repositories/local_db/local_transaction_repository.dart';
import '../../domain/repositories/account_repository.dart';
import '../../domain/repositories/currency_designation_repository.dart';
import '../../domain/repositories/currency_repository.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../database/app_database.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Blocs
  sl.registerFactory(() => AccountsBloc(accountRepository: sl()));
  sl.registerFactory(() => SettingsBloc(settingsRepository: sl()));
  sl.registerFactory(() => CurrencyBloc(currencyRepository: sl()));
  sl.registerFactory(() => StylesBloc(styleRepository: sl()));
  sl.registerFactory(() => CategoriesBloc(
        categoryRepository: sl(),
        transactionRepository: sl(),
      ));
  sl.registerFactory(() => TransactionsBloc(transactionRepository: sl()));
  sl.registerFactory(() => CurrencyConverterBloc(
        currencyRepository: sl(),
        accountRepository: sl(),
        settingsRepository: sl(),
      ));
  sl.registerFactory(() => DashboardBloc(
        accountRepository: sl(),
        transactionRepository: sl(),
        categoryRepository: sl(),
      ));

  // Repositories
  sl.registerLazySingleton<AccountRepository>(() => LocalAccountRepository(sl()));
  sl.registerLazySingleton<CategoryRepository>(
      () => LocalCategoryRepository(sl()));
  sl.registerLazySingleton<CurrencyRepository>(
      () => LocalCurrencyRepository(sl()));
  sl.registerLazySingleton<CurrencyDesignationRepository>(
      () => LocalCurrencyDesignationRepository(sl()));
  sl.registerLazySingleton<SettingsRepository>(
      () => LocalSettingsRepository(sl()));
  sl.registerLazySingleton<StyleRepository>(
      () => LocalStyleRepository(sl()));
  sl.registerLazySingleton<TransactionRepository>(
      () => LocalTransactionRepository(sl()));
  sl.registerLazySingleton<DbRepository>(
      () => LocalDbRepository(sl()));    

  // Core
  sl.registerLazySingleton(() => AppDatabase());
}
