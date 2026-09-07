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

/// Moves a bloc's opening fetch off the first frame.
///
/// Nine blocs used to fire their load event the moment their provider was
/// built, and `app.dart` plus the dashboard route read most of them at once -
/// so the exact frames in which the app has to paint for the first time were
/// also the frames in which eight or nine database round-trips landed and their
/// rows were mapped into entities. drift runs the SQL on a background isolate,
/// but every row still crosses the port and is materialised here on the UI
/// isolate, so that mapping is time the first frame does not have.
///
/// The bloc is still constructed eagerly, so `context.read` works from the very
/// first build; only the fetch moves. Nothing regresses by waiting one frame:
/// a bloc event is processed asynchronously regardless, so every consumer of
/// these blocs already had to render an initial/loading state before the data
/// arrived. The two blocs the first frame genuinely reads - theme (paints the
/// shell) and settings (supplies the locale to MaterialApp.router) - are
/// deliberately left eager.
extension _DeferredLoad<E, S> on Bloc<E, S> {
  void loadAfterFirstFrame(E event) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // The provider can be disposed before the callback runs - a restart, or
      // a hot reload that rebuilds the tree - and adding to a closed bloc
      // throws.
      if (isClosed) return;
      add(event);
    });
  }
}

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
          // Eager: MaterialApp.router below is keyed on the locale this bloc
          // holds, so the first frame reads it.
          BlocProvider(
            create: (context) => di.sl<SettingsBloc>()..add(LoadSettings()),
          ),
          // Deferred to the first post-frame callback - see [_DeferredLoad].
          BlocProvider(
            create: (context) =>
                di.sl<AccountsBloc>()..loadAfterFirstFrame(LoadAccounts()),
          ),
          BlocProvider(
            create: (context) =>
                di.sl<CurrencyBloc>()..loadAfterFirstFrame(LoadCurrencies()),
          ),
          BlocProvider(
            create: (context) =>
                di.sl<StylesBloc>()..loadAfterFirstFrame(LoadStyles()),
          ),
          BlocProvider(
            create: (context) =>
                di.sl<CategoriesBloc>()..loadAfterFirstFrame(LoadCategories()),
          ),
          BlocProvider(
            create: (context) =>
                di.sl<TransactionsBloc>()
                  ..loadAfterFirstFrame(const InitialLoadTransactions()),
          ),
          BlocProvider(
            create: (context) =>
                di.sl<CurrencyConverterBloc>()
                  ..loadAfterFirstFrame(LoadCurrencyConverter()),
          ),
          BlocProvider(create: (context) => di.sl<DashboardBloc>()),
          // Eager: the app shell is painted from this bloc's theme, and its
          // seeded fallback is what lets frame one exist at all.
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
