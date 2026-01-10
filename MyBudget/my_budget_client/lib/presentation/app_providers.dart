import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
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
    if (!Platform.isWindows) return;

    final brightness = Theme.of(context).brightness;
    final tintOpacity = 1.0 - theme.effectOpacity;

    WindowEffect windowEffect;
    switch (theme.windowEffectType) {
      case WindowEffectType.none:
        windowEffect = WindowEffect.disabled;
        break;
      case WindowEffectType.acrylic:
        windowEffect = WindowEffect.acrylic;
        break;
      case WindowEffectType.mica:
        windowEffect = WindowEffect.mica;
        break;
      case WindowEffectType.aero:
        windowEffect = WindowEffect.aero;
        break;
      case WindowEffectType.vibrancy:
        windowEffect = WindowEffect.disabled; // Not on Windows
        break;
      case WindowEffectType.transparent:
        windowEffect = WindowEffect.transparent;
        break;
    }

    Window.setEffect(
      effect: windowEffect,
      color: AppTheme.getWindowTintColor(
        theme.backgroundColor,
        brightness,
        tintOpacity,
        theme.windowEffectType,
      ),
    );
  }
}
