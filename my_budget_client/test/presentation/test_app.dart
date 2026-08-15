// Shared scaffolding for the widget tests under test/presentation/.
//
// Every widget in this app expects two things from its ancestors: the
// generated `AppLocalizations` (reached through `context.l10n`, which throws on
// a null lookup) and whichever blocs it reads. Repeating that setup per file
// makes each test carry an opinion about the whole tree, so it lives here once.
//
// The blocs are `MockBloc`s from bloc_test: their `add` is a no-op and their
// state is whatever the test pins, which keeps a widget test about the widget
// rather than about repositories and drift.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/presentation/blocs/asset/asset_bloc.dart';
import 'package:my_budget_client/presentation/blocs/asset/asset_event.dart';
import 'package:my_budget_client/presentation/blocs/asset/asset_state.dart';
import 'package:my_budget_client/presentation/blocs/categories/categories_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency/currency_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency_converter/currency_converter_bloc.dart';
import 'package:my_budget_client/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:my_budget_client/presentation/blocs/exchange_rates/exchange_rates_bloc.dart';
import 'package:my_budget_client/presentation/blocs/inflation/inflation_bloc.dart';
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';
import 'package:my_budget_client/presentation/blocs/sms/sms_bloc.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';

// ---------------------------------------------------------------------------
// Mock blocs
// ---------------------------------------------------------------------------

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

class MockCurrencyBloc extends MockBloc<CurrencyEvent, CurrencyState>
    implements CurrencyBloc {}

class MockStylesBloc extends MockBloc<StylesEvent, StylesState>
    implements StylesBloc {}

class MockSmsBloc extends MockBloc<SmsEvent, SmsState> implements SmsBloc {}

class MockAccountsBloc extends MockBloc<AccountsEvent, AccountsState>
    implements AccountsBloc {}

class MockCategoriesBloc extends MockBloc<CategoriesEvent, CategoriesState>
    implements CategoriesBloc {}

class MockTransactionsBloc
    extends MockBloc<TransactionsEvent, TransactionsState>
    implements TransactionsBloc {}

class MockDashboardBloc extends MockBloc<DashboardEvent, DashboardState>
    implements DashboardBloc {}

// Not wired into `wrapWithBlocs`: the exchange rates screen builds its own bloc
// from the service locator rather than reading one from an ancestor, so a test
// hands this to `sl` instead of to a provider.
class MockExchangeRatesBloc
    extends MockBloc<ExchangeRatesEvent, ExchangeRatesState>
    implements ExchangeRatesBloc {}

// Also outside `wrapWithBlocs`, for the same reason as the exchange rates bloc
// above: the Data screen's two other tabs each build their bloc with
// `sl<AssetBloc>()` / `sl<InflationBloc>()`, so a provider wrapped around the
// tab would be ignored and the test has to reach the service locator.
class MockAssetBloc extends MockBloc<AssetEvent, AssetState>
    implements AssetBloc {}

class MockInflationBloc extends MockBloc<InflationEvent, InflationState>
    implements InflationBloc {}

class MockCurrencyConverterBloc
    extends MockBloc<CurrencyConverterEvent, CurrencyConverterState>
    implements CurrencyConverterBloc {}

/// A [SettingsBloc] pinned to [state] (default: the bloc's own initial state).
SettingsBloc createSettingsBloc({SettingsState state = const SettingsState()}) {
  final bloc = MockSettingsBloc();
  whenListen(bloc, const Stream<SettingsState>.empty(), initialState: state);
  return bloc;
}

/// A [CurrencyBloc] pinned to [state]; defaults to a loaded, empty catalogue so
/// widgets that only render on `CurrencyLoadSuccess` are exercised.
CurrencyBloc createCurrencyBloc({
  CurrencyState state = const CurrencyLoadSuccess(),
}) {
  final bloc = MockCurrencyBloc();
  whenListen(bloc, const Stream<CurrencyState>.empty(), initialState: state);
  return bloc;
}

/// A [StylesBloc] pinned to [state].
StylesBloc createStylesBloc({StylesState state = const StylesLoadSuccess()}) {
  final bloc = MockStylesBloc();
  whenListen(bloc, const Stream<StylesState>.empty(), initialState: state);
  return bloc;
}

/// An [SmsBloc] pinned to [state].
SmsBloc createSmsBloc({SmsState state = const SmsState()}) {
  final bloc = MockSmsBloc();
  whenListen(bloc, const Stream<SmsState>.empty(), initialState: state);
  return bloc;
}

// ---------------------------------------------------------------------------
// Tree assembly
// ---------------------------------------------------------------------------

/// Wraps [child] in `BlocProvider.value` for every bloc supplied.
///
/// Providers are nested one at a time rather than through `MultiBlocProvider`
/// so that callers can pass exactly the blocs the widget under test reads —
/// leaving one out is how a test proves a widget does *not* depend on it (the
/// Settings reset test relies on `SmsBloc` being absent, which is the shape of
/// the tree on every platform except Android).
Widget wrapWithBlocs(
  Widget child, {
  SettingsBloc? settingsBloc,
  CurrencyBloc? currencyBloc,
  StylesBloc? stylesBloc,
  SmsBloc? smsBloc,
  AccountsBloc? accountsBloc,
  CategoriesBloc? categoriesBloc,
  TransactionsBloc? transactionsBloc,
  DashboardBloc? dashboardBloc,
  CurrencyConverterBloc? currencyConverterBloc,
}) {
  var result = child;
  if (currencyConverterBloc != null) {
    result = BlocProvider<CurrencyConverterBloc>.value(
      value: currencyConverterBloc,
      child: result,
    );
  }
  if (dashboardBloc != null) {
    result = BlocProvider<DashboardBloc>.value(
      value: dashboardBloc,
      child: result,
    );
  }
  if (transactionsBloc != null) {
    result = BlocProvider<TransactionsBloc>.value(
      value: transactionsBloc,
      child: result,
    );
  }
  if (categoriesBloc != null) {
    result = BlocProvider<CategoriesBloc>.value(
      value: categoriesBloc,
      child: result,
    );
  }
  if (accountsBloc != null) {
    result = BlocProvider<AccountsBloc>.value(
      value: accountsBloc,
      child: result,
    );
  }
  if (smsBloc != null) {
    result = BlocProvider<SmsBloc>.value(value: smsBloc, child: result);
  }
  if (stylesBloc != null) {
    result = BlocProvider<StylesBloc>.value(value: stylesBloc, child: result);
  }
  if (currencyBloc != null) {
    result = BlocProvider<CurrencyBloc>.value(
      value: currencyBloc,
      child: result,
    );
  }
  if (settingsBloc != null) {
    result = BlocProvider<SettingsBloc>.value(
      value: settingsBloc,
      child: result,
    );
  }
  return result;
}

/// Sizes the test surface and restores it afterwards.
///
/// Layout in this app keys off width (`kMobileBreakpoint`), so the surface size
/// is the single most important input to most of these tests. The reset is
/// registered as a tear-down because a leaked size silently changes the
/// meaning of every later test in the same file.
void setSurfaceSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Pumps [child] inside a localized [MaterialApp].
///
/// [locale] drives both the strings and the text direction — `ar` and `ur`
/// render right-to-left through the localization delegates, which is closer to
/// production than wrapping in a bare [Directionality].
///
/// [aboveApp] wraps the [MaterialApp] itself. Anything a *dialog* or a pushed
/// route has to see must be provided there: those routes are siblings of
/// `home` under the app's Navigator, so providers placed around [child] are
/// invisible to them. In production `AppProviders` sits above the app for
/// exactly this reason, so `aboveApp: (app) => wrapWithBlocs(app, ...)` is the
/// faithful shape whenever the test opens a dialog.
Future<void> pumpAppWidget(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en'),
  Size? surfaceSize,
  TargetPlatform? platform,
  bool wrapInScaffold = true,
  Widget Function(Widget app)? aboveApp,
}) async {
  if (surfaceSize != null) setSurfaceSize(tester, surfaceSize);

  final Widget app = MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: platform == null ? null : ThemeData(platform: platform),
    home: wrapInScaffold ? Scaffold(body: child) : child,
  );

  await tester.pumpWidget(aboveApp == null ? app : aboveApp(app));
}

/// Pumps a localized [MaterialApp.router] driven by [router].
///
/// Shell widgets (`AdaptiveScaffold`, `MainScreen`) read `GoRouterState.of`, so
/// they can only be tested against a real router rather than a stand-in.
/// Providers are placed above [MaterialApp.router] so the routed pages — built
/// beneath it — still see them.
Future<void> pumpRouterApp(
  WidgetTester tester,
  GoRouter router, {
  Locale locale = const Locale('en'),
  Size? surfaceSize,
  SettingsBloc? settingsBloc,
  CurrencyBloc? currencyBloc,
  StylesBloc? stylesBloc,
}) async {
  if (surfaceSize != null) setSurfaceSize(tester, surfaceSize);

  await tester.pumpWidget(
    wrapWithBlocs(
      MaterialApp.router(
        routerConfig: router,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
      settingsBloc: settingsBloc ?? createSettingsBloc(),
      currencyBloc: currencyBloc,
      stylesBloc: stylesBloc,
    ),
  );
  addTearDown(router.dispose);
}

/// Localized strings for [locale], for asserting on text the widget renders.
///
/// Tests must not hard-code English: the label a destination shows is chosen by
/// the delegate, and asserting on a literal would pass in `en` and fail in the
/// other nine locales for reasons that have nothing to do with the widget.
Future<AppLocalizations> loadL10n([Locale locale = const Locale('en')]) =>
    AppLocalizations.delegate.load(locale);
