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
          // AssetBloc/InflationBloc are deliberately NOT provided here.
          // AssetTab/InflationTab each create their own instance via
          // sl<...Bloc>() in a local BlocProvider, and every consumer
          // (asset_view, asset_tab_app_bar, asset_filter_dialog, and the
          // Inflation equivalents) reads that nearer provider. A root entry
          // would sit unread most of the time — BlocProvider is lazy by
          // default, so it wouldn't even build — until something above the
          // tab happened to call context.read<AssetBloc>(), at which point
          // it would spin up a second live bloc watching the same drift
          // stream as the tab's own instance: every write processed twice,
          // and this app-lifetime instance never closed.
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
    // Reapplying on launch has to cover every desktop platform the effect can
    // be saved on, not just Windows - otherwise a macOS or Linux user picks an
    // effect, it applies once, and comes back missing after every restart.
    if (kIsWeb ||
        (!AppPlatform.isWindows &&
            !AppPlatform.isMacOS &&
            !AppPlatform.isLinux)) {
      return;
    }

    // The tint used to be built here from `1.0 - effectOpacity`, the inverse of
    // what the picker applies, and the transparent case was missing entirely -
    // so an effect looked one way when chosen and another way after every
    // restart. Both are now decided in one place.
    WindowEffectUtils.applyTheme(
      type: theme.windowEffectType,
      backgroundColor: theme.backgroundColor,
      surfaceColor: theme.surfaceColor,
      effectOpacity: theme.effectOpacity,
      brightness: Theme.of(context).brightness,
    );
  }
}
