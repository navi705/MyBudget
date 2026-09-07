// The `buildWhen` regression test.
//
// The accounts screen carried four unguarded `BlocBuilder<AccountsBloc, ...>`,
// and one tap on a date chevron emits about three states - the date moves, the
// balances land, the previous-period figures land - so every gesture re-ran
// twelve builders, each redoing linear scans and currency arithmetic. They are
// guarded now, and a `buildWhen` that misses a field its builder displays is a
// stale-UI bug: the screen would keep showing last period's numbers with no
// error anywhere.
//
// So this file does not test that the guards suppress anything. It tests the
// half that can break silently: for each guarded builder, an emit that touches
// ONLY the fields that builder reads must still reach the screen. Every state
// below is a `copyWith` off the same instance, which is what the bloc really
// emits - so every untouched field is the identical object, and a predicate
// that watched the wrong one would drop the emit.
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/core/utils/money_formatter.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency_converter/currency_converter_bloc.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';
import 'package:my_budget_client/presentation/screens/accounts_screen.dart';
import 'package:my_budget_client/presentation/widgets/account_list_item.dart';

import '../test_app.dart';

final _january = DateTime(2024, 1, 15);
final _february = DateTime(2024, 2, 15);

Currency _currency(String code) => Currency(
  name: code,
  code: code,
  languageCode: 'en',
  type: TypeCurrency.currency,
);

Account _account({
  String id = 'a1',
  String name = 'Checking',
  double balance = 100,
}) => Account(
  id: id,
  name: name,
  balance: balance,
  currencyCode: 'EUR',
  currencyDesignationId: 'd1',
  accountTypeId: 't1',
  creationDate: DateTime(2024, 1, 1),
);

final _initialState = AccountsLoadSuccess(
  accounts: [_account()],
  accountTypes: const [],
  hasReachedMax: true,
  totalCount: 1,
  exchangeRates: const [],
  activeDate: _january,
);

CurrencyConverterState _converterState() => CurrencyConverterLoadSuccess(
  allCurrencies: [_currency('EUR')],
  exchangeRates: [
    ExchangeRateDomain(
      fromCurrencyCode: 'EUR',
      toCurrencyCode: 'RSD',
      preset: 1,
      rate: 117.0,
      date: _january,
    ),
  ],
  selectedCurrencies: [_currency('EUR')],
  baseCurrencyCode: 'EUR',
);

/// Pumps the screen against a bloc whose states the test pushes by hand.
///
/// A real stream rather than a re-pump with a new pinned state: `buildWhen` is
/// only ever consulted on a state arriving through `bloc.stream`, so a test
/// that swapped the mock's state would exercise nothing.
Future<StreamController<AccountsState>> _pumpScreen(WidgetTester tester) async {
  setSurfaceSize(tester, const Size(1000, 1400));

  final controller = StreamController<AccountsState>.broadcast();
  addTearDown(controller.close);

  final accountsBloc = MockAccountsBloc();
  whenListen(accountsBloc, controller.stream, initialState: _initialState);

  final converterBloc = MockCurrencyConverterBloc();
  whenListen(
    converterBloc,
    const Stream<CurrencyConverterState>.empty(),
    initialState: _converterState(),
  );

  final router = GoRouter(
    initialLocation: AppRoutes.accounts,
    routes: [
      GoRoute(
        path: AppRoutes.accounts,
        builder: (_, _) => const AccountsScreen(),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    wrapWithBlocs(
      MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
      settingsBloc: createSettingsBloc(),
      currencyBloc: createCurrencyBloc(),
      stylesBloc: createStylesBloc(),
      accountsBloc: accountsBloc,
      currencyConverterBloc: converterBloc,
    ),
  );
  await tester.pumpAndSettle();

  return controller;
}

/// Pushes [state] and lets the frame it causes finish.
Future<void> _emit(
  WidgetTester tester,
  StreamController<AccountsState> controller,
  AccountsState state,
) async {
  controller.add(state);
  await tester.pumpAndSettle();
}

/// The month/year label the date bar is expected to draw for [date].
///
/// Read back out of the tree's own [MaterialLocalizations] rather than typed
/// out: 'January 2024' is right in `en` and wrong in the nine other locales
/// this app ships.
String _monthLabel(WidgetTester tester, DateTime date) =>
    MaterialLocalizations.of(
      tester.element(find.byType(AccountsScreen)),
    ).formatMonthYear(date);

/// The amount an account row draws for [value].
///
/// The symbol is left off: it comes from the currency designation, and these
/// tests run against an empty designation catalogue, so the row joins the
/// amount to an empty string.
String _rowAmount(double value) => MoneyFormatter.format(value, 'EUR');

/// The amount a summary card draws for [value].
String _cardAmount(double value) =>
    '${MoneyFormatter.format(value, 'EUR')} EUR';

void main() {
  group('AccountsScreen app bar guard', () {
    // The date is what the chevrons move, and the bar is the only thing on
    // screen that shows it. `_appBarInputsChanged` is deliberately blind to
    // every balance map, so this is the emit it must not be blind to.
    testWidgets('follows the active date when nothing else changed', (
      tester,
    ) async {
      final controller = await _pumpScreen(tester);
      expect(find.text(_monthLabel(tester, _january)), findsOneWidget);

      await _emit(
        tester,
        controller,
        _initialState.copyWith(activeDate: _february),
      );

      expect(find.text(_monthLabel(tester, _february)), findsOneWidget);
      expect(find.text(_monthLabel(tester, _january)), findsNothing);
    });

    testWidgets('follows the row counter', (tester) async {
      final controller = await _pumpScreen(tester);
      final l10n = await loadL10n();
      expect(find.text(l10n.totalCountLabel(1)), findsOneWidget);

      await _emit(tester, controller, _initialState.copyWith(totalCount: 7));

      expect(find.text(l10n.totalCountLabel(7)), findsOneWidget);
    });

    // The selection bar and the date bar are two different widgets returned by
    // the same builder, so a guard that missed this flag would leave the date
    // bar on screen with no way out of selection mode.
    testWidgets('swaps in the selection bar', (tester) async {
      final controller = await _pumpScreen(tester);
      expect(find.text(_monthLabel(tester, _january)), findsOneWidget);

      await _emit(
        tester,
        controller,
        _initialState.copyWith(
          isSelectionModeActive: true,
          selectedAccountIds: const {'a1'},
        ),
      );

      expect(find.text(_monthLabel(tester, _january)), findsNothing);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });

  group('AccountsScreen account rows guard', () {
    testWidgets('follows the accounts themselves', (tester) async {
      final controller = await _pumpScreen(tester);
      expect(find.text('Checking'), findsOneWidget);

      await _emit(
        tester,
        controller,
        _initialState.copyWith(accounts: [_account(name: 'Savings')]),
      );

      expect(find.text('Savings'), findsOneWidget);
      expect(find.text('Checking'), findsNothing);
    });

    // A historical date replaces the balance a row prints without touching the
    // account list at all - the map is the only field that moves. It is also
    // the field the row's `account.copyWith(balance: ...)` now depends on, and
    // that copy is made conditionally.
    testWidgets('follows a historical balance', (tester) async {
      final controller = await _pumpScreen(tester);
      expect(find.textContaining(_rowAmount(100)), findsOneWidget);

      await _emit(
        tester,
        controller,
        _initialState.copyWith(
          isHistorical: true,
          historicalBalances: const {'a1': 999.0},
        ),
      );

      expect(find.textContaining(_rowAmount(999)), findsOneWidget);
      expect(find.textContaining(_rowAmount(100)), findsNothing);
    });

    // The row draws its "Real" line straight off this map, and nothing else on
    // the state moves when the real-balance pass lands.
    testWidgets('follows the real balances', (tester) async {
      final controller = await _pumpScreen(tester);

      await _emit(
        tester,
        controller,
        _initialState.copyWith(realBalances: const {'a1': 42.0}),
      );

      expect(find.textContaining(_rowAmount(42)), findsOneWidget);
    });

    // Selection is drawn on the rows, not only in the app bar: a selected row
    // is the highlight colour rather than the card colour, and that is the
    // only thing that marks it.
    testWidgets('follows the selection', (tester) async {
      final controller = await _pumpScreen(tester);
      final theme = Theme.of(tester.element(find.byType(AccountsScreen)));

      Color? rowColour() => tester
          .widget<Card>(
            find.descendant(
              of: find.byType(AccountListItem),
              matching: find.byType(Card),
            ),
          )
          .color;

      expect(rowColour(), theme.cardColor);

      await _emit(
        tester,
        controller,
        _initialState.copyWith(
          isSelectionModeActive: true,
          selectedAccountIds: const {'a1'},
        ),
      );

      expect(rowColour(), theme.highlightColor);
    });
  });

  group('AccountsScreen summary guard', () {
    // The summary is behind two guards - the accounts one and the converter
    // one - and its figures are cached on the identity of the state pair. An
    // emit that changes a balance has to get through both and past the cache.
    testWidgets('follows the balances once the card is open', (tester) async {
      final controller = await _pumpScreen(tester);
      final l10n = await loadL10n();

      await tester.tap(find.text(l10n.totalNetWorth));
      await tester.pumpAndSettle();
      expect(find.textContaining(_cardAmount(100)), findsOneWidget);

      await _emit(
        tester,
        controller,
        _initialState.copyWith(accounts: [_account(balance: 250)]),
      );

      expect(find.textContaining(_cardAmount(250)), findsOneWidget);
    });
  });
}
