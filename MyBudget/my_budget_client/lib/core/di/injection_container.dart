import 'package:get_it/get_it.dart';
import 'package:my_budget_client/data/repositories/local_db/local_account_style_repository.dart';
import 'package:my_budget_client/data/repositories/local_db/local_category_repository.dart';
import 'package:my_budget_client/data/repositories/local_db/local_settings_repository.dart';
import 'package:my_budget_client/domain/repositories/account_style_repository.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/presentation/blocs/account_styles/account_styles_bloc.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency/currency_bloc.dart';
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';

import '../../data/repositories/local_db/local_account_repository.dart';
import '../../data/repositories/local_db/local_currency_designation_repository.dart';
import '../../data/repositories/local_db/local_currency_repository.dart';
import '../../data/repositories/local_db/local_transaction_repository.dart';
import '../../data/repositories/remote_api/remote_transaction_repository.dart';
import '../../data/repositories/transaction_repository_impl.dart';
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
  sl.registerFactory(() => AccountStylesBloc(accountStyleRepository: sl()));

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
  sl.registerLazySingleton<AccountStyleRepository>(
      () => LocalAccountStyleRepository(sl()));
  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(
      localRepository: sl(),
      remoteRepository: sl(),
    ),
  );

  // Local and Remote Data Sources
  sl.registerLazySingleton(() => LocalTransactionRepository(sl()));
  sl.registerLazySingleton(() => RemoteTransactionRepository());

  // Core
  sl.registerLazySingleton(() => AppDatabase());
}
