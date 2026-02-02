import 'package:my_budget_client/core/utils/platform/platform_utils.dart';
import 'package:flutter/material.dart';
import 'package:my_budget_client/core/utils/window/window_effect_utils.dart';
import 'package:my_budget_client/core/theme/app_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/core/di/injection_container.dart' as di;
import 'package:my_budget_client/domain/entities/custom_theme.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/presentation/blocs/categories/categories_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency/currency_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency_converter/currency_converter_bloc.dart';
import 'package:my_budget_client/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';
import 'package:my_budget_client/presentation/blocs/theme/theme_bloc.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';
import 'package:my_budget_client/domain/repositories/asset_repository.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/domain/repositories/inflation_repository.dart';
import 'package:my_budget_client/presentation/blocs/asset/asset_bloc.dart';
import 'package:my_budget_client/presentation/blocs/asset/asset_event.dart';
import 'package:my_budget_client/presentation/blocs/inflation/inflation_bloc.dart';
import 'package:my_budget_client/presentation/blocs/sms/sms_bloc.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AppProviders extends StatelessWidget {
  final Widget child;
  const AppProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => di.sl<CurrencyRepository>()),
        RepositoryProvider(create: (context) => di.sl<AssetRepository>()),
        RepositoryProvider(create: (context) => di.sl<InflationRepository>()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => di.sl<SettingsBloc>()..add(LoadSettings()),
          ),
          BlocProvider(
            create: (context) => di.sl<AccountsBloc>()..add(LoadAccounts()),
          ),
          BlocProvider(
            create: (context) => di.sl<CurrencyBloc>()..add(LoadCurrencies()),
          ),
          BlocProvider(
            create: (context) => di.sl<StylesBloc>()..add(LoadStyles()),
          ),
          BlocProvider(
            create: (context) => di.sl<CategoriesBloc>()..add(LoadCategories()),
          ),
          BlocProvider(
            create: (context) =>
                di.sl<TransactionsBloc>()..add(const InitialLoadTransactions()),
          ),
          BlocProvider(
            create: (context) =>
                di.sl<CurrencyConverterBloc>()..add(LoadCurrencyConverter()),
          ),
          BlocProvider(create: (context) => di.sl<DashboardBloc>()),
          BlocProvider(
            create: (context) =>
                di.sl<ThemeBloc>()..add(const LoadThemeSettings()),
          ),
          BlocProvider(
            create: (context) => di.sl<AssetBloc>()..add(const LoadAssetData()),
          ),
          BlocProvider(
            create: (context) =>
                di.sl<InflationBloc>()..add(LoadInflationRates()),
          ),
          if (!kIsWeb && AppPlatform.isAndroid)
            BlocProvider(
              create: (context) => di.sl<SmsBloc>()..add(LoadSmsPresets()),
              lazy: false,
            ),
        ],
        child: BlocListener<ThemeBloc, ThemeState>(
          listener: (context, state) {
            if (state.isLoaded && state.activeTheme != null) {
              _applyWindowEffect(context, state.activeTheme!);
            }
          },
          child: BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, state) {
              return child;
            },
          ),
        ),
      ),
    );
  }

  void _applyWindowEffect(BuildContext context, CustomTheme theme) {
    if (kIsWeb || !AppPlatform.isWindows) return;

    final brightness = Theme.of(context).brightness;
    final tintOpacity = 1.0 - theme.effectOpacity;

    WindowEffectUtils.applyEffect(
      context: context,
      color: AppTheme.getWindowTintColor(
        theme.backgroundColor,
        brightness,
        tintOpacity,
        theme.windowEffectType,
      ),
      opacity: theme.effectOpacity,
      type: theme.windowEffectType,
    );
  }
}
