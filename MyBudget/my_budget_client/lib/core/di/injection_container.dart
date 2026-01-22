import 'package:get_it/get_it.dart';
import 'package:my_budget_client/data/repositories/db_repository.dart';
import 'package:my_budget_client/data/repositories/local_db/local_category_repository.dart';
import 'package:my_budget_client/data/repositories/local_db/local_db_repository.dart';
import 'package:my_budget_client/data/repositories/local_db/local_settings_repository.dart';
import 'package:my_budget_client/data/repositories/local_db/local_style_repository.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/domain/repositories/style_repository.dart';
import 'package:my_budget_client/domain/repositories/theme_repository.dart';
import 'package:my_budget_client/data/repositories/local_db/local_theme_repository.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/presentation/blocs/categories/categories_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency/currency_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency_converter/currency_converter_bloc.dart';
import 'package:my_budget_client/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';
import 'package:my_budget_client/presentation/blocs/theme/theme_bloc.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';
import 'package:my_budget_client/presentation/blocs/exchange_rates/exchange_rates_bloc.dart';
import 'package:my_budget_client/presentation/blocs/inflation/inflation_bloc.dart';
import 'package:my_budget_client/domain/repositories/inflation_repository.dart';
import 'package:my_budget_client/data/repositories/local_db/local_inflation_repository.dart';
import 'package:my_budget_client/presentation/blocs/asset/asset_bloc.dart';
import 'package:my_budget_client/presentation/blocs/api_settings/api_settings_bloc.dart';
import 'package:my_budget_client/core/services/exchange_rate_api_service.dart';
import 'package:my_budget_client/core/services/inflation_api_service.dart';
import 'package:my_budget_client/core/services/steam_inventory_api_service.dart';
import 'package:my_budget_client/domain/repositories/asset_repository.dart';
import 'package:my_budget_client/data/repositories/local_db/local_asset_repository.dart';
import 'package:my_budget_client/domain/services/finance_calculator.dart';
import 'package:my_budget_client/presentation/blocs/sms/sms_bloc.dart';
import 'package:my_budget_client/domain/repositories/sms_repository.dart';
import 'package:my_budget_client/data/repositories/local_sms_repository.dart';
import 'package:my_budget_client/domain/repositories/api_settings_repository.dart';
import 'package:my_budget_client/data/repositories/local_db/local_api_settings_repository.dart';
import 'package:my_budget_client/domain/repositories/custom_data_source_repository.dart';
import 'package:my_budget_client/data/repositories/local_db/local_custom_data_source_repository.dart';
import 'package:my_budget_client/core/services/android_file_picker_service.dart';
import 'package:my_budget_client/core/sync/sync_service.dart';

import 'package:my_budget_client/core/services/startup_sync_service.dart';
import 'package:my_budget_client/core/services/custom_api_service.dart';
import 'package:my_budget_client/core/services/server_sync_service.dart';

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
  sl.registerFactory(
    () => AccountsBloc(
      accountRepository: sl(),
      settingsRepository: sl(),
      currencyRepository: sl(),
      inflationRepository: sl(),
      transactionRepository: sl(),
      assetRepository: sl(),
      categoryRepository: sl(), // Added
      financeCalculator: sl(),
    ),
  );
  sl.registerFactory(
    () => SettingsBloc(
      settingsRepository: sl(),
      inflationRepository: sl(),
      inflationApiService: sl(),
    ),
  );
  sl.registerFactory(() => CurrencyBloc(currencyRepository: sl()));
  sl.registerFactory(() => StylesBloc(styleRepository: sl()));
  sl.registerFactory(
    () => CategoriesBloc(
      categoryRepository: sl(),
      settingsRepository: sl(),
      transactionRepository: sl(),
      currencyRepository: sl(),
    ),
  );
  sl.registerFactory(
    () => TransactionsBloc(
      transactionRepository: sl(),
      styleRepository: sl(),
      categoryRepository: sl(),
      settingsRepository: sl(),
      currencyRepository: sl(),
      accountRepository: sl(), // Added
    ),
  );
  sl.registerFactory(
    () => CurrencyConverterBloc(
      currencyRepository: sl(),
      //accountRepository: sl(),
      settingsRepository: sl(),
    ),
  );
  sl.registerFactory(
    () => DashboardBloc(
      accountRepository: sl(),
      transactionRepository: sl(),
      categoryRepository: sl(),
      styleRepository: sl(),
      currencyRepository: sl(),
      settingsRepository: sl(),
      assetRepository: sl(), // Added
    ),
  );
  sl.registerFactory(
    () => ThemeBloc(settingsRepository: sl(), themeRepository: sl()),
  );
  sl.registerFactory(() => ExchangeRatesBloc(currencyRepository: sl()));
  sl.registerFactory(
    () => InflationBloc(inflationRepository: sl(), settingsRepository: sl()),
  );
  sl.registerFactory(() => AssetBloc(sl(), sl()));
  sl.registerFactory(
    () => ApiSettingsBloc(
      sl(),
      sl(),
      sl(),
      sl(),
      apiSettingsRepository: sl(),
      customDataSourceRepository: sl(),
      customApiService: sl(),
    ),
  );
  sl.registerFactory(
    () => SmsBloc(
      smsRepository: sl(),
      transactionRepository: sl(),
      currencyRepository: sl(),
    ),
  );

  // Services
  sl.registerLazySingleton(
    () => CustomApiService(
      sl<AppDatabase>().exchangeRatesDao,
      sl<AppDatabase>().inflationRatesDao,
      sl<AppDatabase>().assetEntriesDao,
    ),
  );

  sl.registerLazySingleton(
    () => StartupSyncService(sl(), sl(), sl(), sl(), sl(), sl(), sl(), sl()),
  );
  sl.registerLazySingleton(() => ServerSyncService(database: sl()));
  sl.registerLazySingleton(() => FinanceCalculator());
  sl.registerLazySingleton(
    () => ExchangeRateApiService(
      sl<AppDatabase>().exchangeRatesDao,
      sl<AppDatabase>().apiFetchStatusesDao,
      sl<AppDatabase>().currenciesDao,
    ),
  );
  sl.registerLazySingleton(
    () => SteamInventoryApiService(
      sl<AppDatabase>().assetEntriesDao,
      sl<AppDatabase>().apiFetchStatusesDao,
    ),
  );
  sl.registerLazySingleton(
    () => InflationApiService(sl<AppDatabase>().inflationRatesDao),
  );
  sl.registerLazySingleton(() => AndroidFilePickerService());
  sl.registerLazySingleton(() => SyncService(sl()));

  // Repositories
  sl.registerLazySingleton<AccountRepository>(
    () => LocalAccountRepository(sl()),
  );
  sl.registerLazySingleton<CategoryRepository>(
    () => LocalCategoryRepository(sl()),
  );
  sl.registerLazySingleton<CurrencyRepository>(
    () => LocalCurrencyRepository(sl()),
  );
  sl.registerLazySingleton<CurrencyDesignationRepository>(
    () => LocalCurrencyDesignationRepository(sl()),
  );
  sl.registerLazySingleton<SettingsRepository>(
    () => LocalSettingsRepository(sl()),
  );
  sl.registerLazySingleton<StyleRepository>(() => LocalStyleRepository(sl()));
  sl.registerLazySingleton<TransactionRepository>(
    () => LocalTransactionRepository(sl()),
  );
  sl.registerLazySingleton<ThemeRepository>(() => LocalThemeRepository(sl()));
  sl.registerLazySingleton<InflationRepository>(
    () => LocalInflationRepository(sl<AppDatabase>().inflationRatesDao),
  );
  sl.registerLazySingleton<AssetRepository>(
    () => LocalAssetRepository(sl<AppDatabase>().assetEntriesDao),
  );
  sl.registerLazySingleton<DbRepository>(() => LocalDbRepository(sl()));
  sl.registerLazySingleton<SmsRepository>(() => LocalSmsRepository());
  sl.registerLazySingleton<ApiSettingsRepository>(
    () => LocalApiSettingsRepository(sl<AppDatabase>().apiSettingsDao),
  );
  sl.registerLazySingleton<CustomDataSourceRepository>(
    () =>
        LocalCustomDataSourceRepository(sl<AppDatabase>().customDataSourcesDao),
  );

  // Core
  sl.registerLazySingleton(() => AppDatabase());
}
