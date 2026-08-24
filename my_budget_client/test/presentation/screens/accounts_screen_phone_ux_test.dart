// The accounts screen on a phone, with the data a real account list has.
//
// The rows carry a name, a balance, a per-period income and expense figure and
// a change against the previous period, and every one of those is user-typed
// or user-earned: names run long, balances run into the millions, and the
// window they have to fit in is 390dp wide. A row that overflows there paints
// the yellow-and-black stripe over the number the screen exists to show, and
// nothing in the layout says which of the two it will be until both are real.
//
// The reach checks are the other half: a control the thumb cannot land on is
// not on the screen in any sense that matters, and the FAB floats over the
// list, so the last account has to be scrollable out from under it.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/presentation/blocs/categories/categories_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency_converter/currency_converter_bloc.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';
import 'package:my_budget_client/presentation/screens/accounts_screen.dart';
import 'package:my_budget_client/presentation/widgets/account_list_item.dart';

import '../test_app.dart';

/// A phone in portrait: the narrowest surface the app ships on.
const Size _phone = Size(390, 844);

/// The smallest a control may be and still be reliably hit with a thumb.
/// Material states 48dp; anything under it is a control the user has to aim at.
const double _minTouchTarget = 48.0;

Account _account({
  required String id,
  required String name,
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

/// A name a person actually types when they have three accounts at one bank.
const _longName =
    'Совместный накопительный счёт в европейском банке для отпуска';

AccountsState _accountsLoaded(List<Account> accounts) => AccountsLoadSuccess(
  accounts: accounts,
  accountTypes: const [],
  hasReachedMax: true,
  totalCount: accounts.length,
  exchangeRates: const [],
  activeDate: DateTime(2024, 1, 1),
);

AccountsBloc _accountsBloc(AccountsState state) {
  final bloc = MockAccountsBloc();
  whenListen(bloc, const Stream<AccountsState>.empty(), initialState: state);
  return bloc;
}

CategoriesBloc _categoriesBloc() {
  final bloc = MockCategoriesBloc();
  whenListen(
    bloc,
    const Stream<CategoriesState>.empty(),
    initialState: CategoriesLoadSuccess(
      allCategories: [Category(id: 'c1', name: 'Groceries')],
      hasReachedMax: true,
      activeDate: DateTime(2024, 1, 1),
    ),
  );
  return bloc;
}

CurrencyConverterBloc _converterBloc() {
  final bloc = MockCurrencyConverterBloc();
  whenListen(
    bloc,
    const Stream<CurrencyConverterState>.empty(),
    initialState: CurrencyConverterInitial(),
  );
  return bloc;
}

Future<AppLocalizations> _pumpAccounts(
  WidgetTester tester, {
  required List<Account> accounts,
  Size surface = _phone,
  double textScale = 1.0,
}) async {
  setSurfaceSize(tester, surface);

  final router = GoRouter(
    initialLocation: AppRoutes.accounts,
    routes: [
      GoRoute(
        path: AppRoutes.accounts,
        builder: (_, _) => const AccountsScreen(),
      ),
      GoRoute(
        path: AppRoutes.addEditTransaction,
        builder: (_, _) => const Text('transaction form'),
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
        builder: (context, child) => MediaQuery.withClampedTextScaling(
          minScaleFactor: textScale,
          maxScaleFactor: textScale,
          child: child!,
        ),
      ),
      settingsBloc: createSettingsBloc(),
      currencyBloc: createCurrencyBloc(),
      stylesBloc: createStylesBloc(),
      accountsBloc: _accountsBloc(_accountsLoaded(accounts)),
      categoriesBloc: _categoriesBloc(),
      currencyConverterBloc: _converterBloc(),
    ),
  );
  await tester.pumpAndSettle();

  return loadL10n();
}

void main() {
  testWidgets('a long account name and a large balance fit the row', (
    tester,
  ) async {
    // An overflow here is a test failure on its own: the framework reports the
    // stripe as an exception. The expectations below are what the row still
    // has to show once it has fitted.
    await _pumpAccounts(
      tester,
      accounts: [
        _account(id: 'a1', name: _longName, balance: 1234567890.12),
        _account(id: 'a2', name: 'Кошелёк', balance: -4321.5),
      ],
    );

    expect(find.byType(AccountListItem), findsNWidgets(2));
    expect(find.textContaining('Кошелёк'), findsWidgets);
  });

  testWidgets('every row control is big enough to hit with a thumb', (
    tester,
  ) async {
    await _pumpAccounts(
      tester,
      accounts: [_account(id: 'a1', name: 'Кошелёк')],
    );

    for (final element in find.byType(IconButton).evaluate()) {
      final size = tester.getSize(find.byElementPredicate((e) => e == element));
      expect(
        size.shortestSide,
        greaterThanOrEqualTo(_minTouchTarget),
        reason:
            'a control smaller than $_minTouchTarget dp is one the user has '
            'to aim at rather than tap',
      );
    }
  });

  testWidgets('the last account can be read out from under the add button', (
    tester,
  ) async {
    // The FAB floats over the list, so without a bottom inset the last row is
    // scrolled to the bottom of the viewport and stays half covered by it.
    final accounts = [
      for (var i = 0; i < 12; i++) _account(id: 'a$i', name: 'Счёт $i'),
    ];
    await _pumpAccounts(tester, accounts: accounts);

    final last = find.text('Счёт 11');
    await tester.scrollUntilVisible(last, 300, maxScrolls: 30);
    await tester.pumpAndSettle();

    final fab = find.byType(FloatingActionButton);
    expect(fab, findsOneWidget);

    final rowBottom = tester.getBottomLeft(last).dy;
    final fabTop = tester.getTopLeft(fab).dy;
    expect(
      rowBottom,
      lessThanOrEqualTo(fabTop),
      reason: 'the last row must be readable, not parked under the FAB',
    );
  });

  testWidgets('the list keeps a reading width on a desktop window', (
    tester,
  ) async {
    // Unconstrained, a 1440px window stretches a row holding ~300px of content
    // across the whole screen and parks its menu a thousand pixels from the
    // name it belongs to.
    await _pumpAccounts(
      tester,
      accounts: [_account(id: 'a1', name: 'Кошелёк')],
      surface: const Size(1440, 900),
    );

    final row = tester.getSize(find.byType(AccountListItem).first);
    expect(row.width, lessThanOrEqualTo(kContentMaxWidth));
  });

  testWidgets('the rows still fit when the phone is set to large text', (
    tester,
  ) async {
    // Doubling the text size is a setting a person with poor eyesight turns on
    // once and never thinks about again; every screen after that is either
    // readable or striped.
    await _pumpAccounts(
      tester,
      accounts: [
        _account(id: 'a1', name: _longName, balance: 1234567890.12),
        _account(id: 'a2', name: 'Кошелёк', balance: -4321.5),
      ],
      textScale: 2.0,
    );

    // One row at a time is all a 390x844 phone holds at this text size, so the
    // second one is reached the way the user reaches it.
    expect(find.byType(AccountListItem), findsWidgets);
    await tester.scrollUntilVisible(find.text('Кошелёк'), 300, maxScrolls: 30);
    await tester.pumpAndSettle();
    expect(find.text('Кошелёк'), findsOneWidget);
  });
}
