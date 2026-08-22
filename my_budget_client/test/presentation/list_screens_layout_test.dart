// Layout pins for the four list screens on a desktop window.
//
// Every assertion here is about a number the renders caught being wrong at
// 1440x900 or in the 600-742dp band, and every one of them is invisible to a
// normal test: nothing throws when a card stretches to 1408px, when a filter
// bar sizes itself for the layout it is not building, or when the last row of
// a list sits under the FAB. They only show up as a measurement, so they are
// measured here.
//
// Each test pins its own window with `tester.view.physicalSize` through
// `setSurfaceSize`, which registers the reset as a tear-down — a leaked size
// silently changes the meaning of every later test in the file.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/core/theme/money_colors.dart';
import 'package:my_budget_client/core/theme/pane_layout.dart';
import 'package:my_budget_client/core/utils/money_formatter.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/icon_type.dart';
import 'package:my_budget_client/domain/entities/style.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency_converter/currency_converter_bloc.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';
import 'package:my_budget_client/presentation/screens/accounts_screen.dart';
import 'package:my_budget_client/presentation/screens/manage_styles_screen.dart';
import 'package:my_budget_client/presentation/widgets/account_list_item.dart';

import 'test_app.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

const Size _desktop = Size(1440, 900);

/// The Android reference window the renders used.
const Size _phone = Size(360, 780);

/// A window inside the band where the shell and the screens used to disagree:
/// wide enough that `MediaQuery` calls it a desktop, narrow enough that the
/// pane left after the rail is not.
const Size _bandWindow = Size(660, 900);

/// What the shell hands the screen at [_bandWindow] once the rail and its
/// divider have taken their ~73dp — plus the pane's own padding.
const Size _compactPane = Size(518, 900);

Account _account(String id, String name) => Account(
  id: id,
  name: name,
  balance: 1500,
  currencyCode: 'EUR',
  currencyDesignationId: 'd1',
  accountTypeId: 't1',
  creationDate: DateTime(2024, 1, 1),
);

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

/// Not a success state, so the total-balance summary stays collapsed and the
/// account cards are the only thing being measured.
CurrencyConverterBloc _converterBloc() {
  final bloc = MockCurrencyConverterBloc();
  whenListen(
    bloc,
    const Stream<CurrencyConverterState>.empty(),
    initialState: CurrencyConverterInitial(),
  );
  return bloc;
}

/// Pumps [AccountsScreen] under a router, optionally inside a [PaneLayout]
/// standing in for the shell's content pane.
///
/// Without [pane] the screen falls back to `MediaQuery`, which is the shape it
/// has on a full-screen route.
Future<void> _pumpAccounts(
  WidgetTester tester, {
  required Size window,
  Size? pane,
  List<Account> accounts = const [],
}) async {
  setSurfaceSize(tester, window);

  final router = GoRouter(
    initialLocation: AppRoutes.accounts,
    routes: [
      GoRoute(
        path: AppRoutes.accounts,
        builder: (_, _) => pane == null
            ? const AccountsScreen()
            : PaneLayout(size: pane, child: const AccountsScreen()),
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
      accountsBloc: _accountsBloc(_accountsLoaded(accounts)),
      currencyConverterBloc: _converterBloc(),
    ),
  );
  await tester.pumpAndSettle();
}

Style _style(int i) => Style(
  id: 's$i',
  name: 'Style $i',
  iconName: 'account_balance',
  colorHex: '#808080',
  iconType: IconType.material,
);

Future<void> _pumpManageStyles(
  WidgetTester tester, {
  required Size window,
  required int styleCount,
}) async {
  setSurfaceSize(tester, window);

  final bloc = MockStylesBloc();
  whenListen(
    bloc,
    const Stream<StylesState>.empty(),
    initialState: StylesLoadSuccess([
      for (var i = 0; i < styleCount; i++) _style(i),
    ]),
  );

  final router = GoRouter(
    initialLocation: AppRoutes.manageAccountStyles,
    routes: [
      GoRoute(
        path: AppRoutes.manageAccountStyles,
        builder: (_, _) => const ManageStylesScreen(),
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
      stylesBloc: bloc,
    ),
  );
  await tester.pumpAndSettle();
}

/// The balance row's span. It hung off a `SelectableText` until that was
/// found to be eating the row's own tap and long press.
TextSpan _balanceSpan(WidgetTester tester) =>
    tester
            .widgetList<Text>(find.byType(Text))
            .firstWhere((text) => text.textSpan != null)
            .textSpan!
        as TextSpan;

/// The colour the balance amount is actually painted in.
///
/// The amount is the first child span of the balance row; the plain text of
/// the whole span is asserted elsewhere, what matters here is where the colour
/// came from.
Color? _amountColor(WidgetTester tester) =>
    (_balanceSpan(tester).children!.first as TextSpan).style?.color;

/// The literal text of the balance amount — the first child span of the
/// balance row, before the "change" figure is appended.
String _amountText(WidgetTester tester) =>
    (_balanceSpan(tester).children!.first as TextSpan).text!;

/// Flattened text of the whole balance row, separators included.
String _balanceRowText(WidgetTester tester) =>
    _balanceSpan(tester).toPlainText();

/// Pumps a single [AccountListItem] at [surface] on [platform].
Future<void> _pumpItem(
  WidgetTester tester,
  Account account, {
  required Size surface,
  TargetPlatform? platform,
  double? prevBalance,
  Locale locale = const Locale('en'),
}) async {
  await pumpAppWidget(
    tester,
    AccountListItem(account: account, prevBalance: prevBalance),
    surfaceSize: surface,
    platform: platform,
    locale: locale,
    aboveApp: (app) => wrapWithBlocs(
      app,
      currencyBloc: createCurrencyBloc(),
      stylesBloc: createStylesBloc(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('content width on a desktop window', () {
    testWidgets('caps the account card well inside a 1440px window', (
      tester,
    ) async {
      await _pumpAccounts(
        tester,
        window: _desktop,
        accounts: [_account('a1', 'Checking')],
      );

      final card = tester.getSize(find.byType(AccountListItem));

      // The render caught this card at 1408px around ~300px of content, with
      // the row's own menu ~1300px from the account name.
      expect(card.width, lessThanOrEqualTo(kContentMaxWidth));
      // Materially narrower than the viewport, not merely narrower: the card
      // keeps its own 16dp margins inside the capped column, so this is the
      // 1440px window with over 600px of it given back as gutter.
      expect(_desktop.width - card.width, greaterThan(600));
    });

    testWidgets('centres the column rather than leaving it against one edge', (
      tester,
    ) async {
      await _pumpAccounts(
        tester,
        window: _desktop,
        accounts: [_account('a1', 'Checking')],
      );

      final card = tester.getRect(find.byType(AccountListItem));
      final leftGutter = card.left;
      final rightGutter = _desktop.width - card.right;

      expect(leftGutter, greaterThan(0));
      expect((leftGutter - rightGutter).abs(), lessThan(1.0));
    });
  });

  group('the filter bar reads the pane, not the window', () {
    testWidgets('builds the compact bar when the pane is compact but the '
        'window is not', (tester) async {
      await _pumpAccounts(
        tester,
        window: _bandWindow,
        pane: _compactPane,
        accounts: [_account('a1', 'Checking')],
      );

      final bar = tester.widget<PreferredSize>(find.byType(PreferredSize));

      // Read from MediaQuery this was kToolbarHeight — the desktop height —
      // reserved for a bar laying itself out in its mobile form.
      expect(bar.preferredSize.height, kToolbarHeight * 1.8);
      expect(tester.takeException(), isNull);
    });

    testWidgets('builds the desktop bar without overflowing a 660dp pane', (
      tester,
    ) async {
      await _pumpAccounts(
        tester,
        window: _bandWindow,
        pane: const Size(660, 900),
        accounts: [_account('a1', 'Checking')],
      );

      final bar = tester.widget<PreferredSize>(find.byType(PreferredSize));

      expect(bar.preferredSize.height, kToolbarHeight);
      // A RenderFlex overflow is reported as an exception during paint; the
      // desktop branch of this bar is an unbounded Row of actions and this is
      // the width it used to be handed while believing it had 660 + the rail.
      expect(tester.takeException(), isNull);
    });
  });

  group('the FAB does not cover the last row', () {
    testWidgets('leaves the last style tile fully above the button', (
      tester,
    ) async {
      await _pumpManageStyles(tester, window: _desktop, styleCount: 30);

      // Past the end: a ListView clamps at maxScrollExtent, so this lands on
      // the last row whatever the row height turns out to be.
      await tester.drag(find.byType(ListView), const Offset(0, -4000));
      await tester.pumpAndSettle();

      final lastTile = find.ancestor(
        of: find.text('Style 29'),
        matching: find.byType(ListTile),
      );
      expect(lastTile, findsOneWidget);

      final tileBottom = tester.getRect(lastTile).bottom;
      final fabTop = tester.getRect(find.byType(FloatingActionButton)).top;

      expect(tileBottom, lessThanOrEqualTo(fabTop));
    });

    testWidgets('reserves the FAB inset at the foot of the list', (
      tester,
    ) async {
      await _pumpManageStyles(tester, window: _desktop, styleCount: 30);

      await tester.drag(find.byType(ListView), const Offset(0, -4000));
      await tester.pumpAndSettle();

      final listBottom = tester.getRect(find.byType(ListView)).bottom;
      final tileBottom = tester
          .getRect(
            find.ancestor(
              of: find.text('Style 29'),
              matching: find.byType(ListTile),
            ),
          )
          .bottom;

      // Scrolled to the end, the gap under the last row is exactly the
      // reserved inset; the half-pixel is float slack, not a tolerance on the
      // rule.
      expect(
        listBottom - tileBottom,
        greaterThanOrEqualTo(kFabScrollBottomInset - 0.5),
      );
    });
  });

  group('balance colour', () {
    testWidgets('comes from the money palette, not Colors.green', (
      tester,
    ) async {
      await pumpAppWidget(
        tester,
        AccountListItem(account: _account('a1', 'Checking')),
        surfaceSize: const Size(500, 900),
        aboveApp: (app) => wrapWithBlocs(
          app,
          currencyBloc: createCurrencyBloc(),
          stylesBloc: createStylesBloc(),
        ),
      );
      await tester.pumpAndSettle();

      final light = MoneyColors.forBrightness(Brightness.light);

      expect(_amountColor(tester), light.inflow);
      expect(_amountColor(tester), isNot(Colors.green));
    });

    testWidgets('uses the outflow hue for a negative balance', (tester) async {
      final overdrawn = _account('a1', 'Checking').copyWith(balance: -42.0);

      await pumpAppWidget(
        tester,
        AccountListItem(account: overdrawn),
        surfaceSize: const Size(500, 900),
        aboveApp: (app) => wrapWithBlocs(
          app,
          currencyBloc: createCurrencyBloc(),
          stylesBloc: createStylesBloc(),
        ),
      );
      await tester.pumpAndSettle();

      final light = MoneyColors.forBrightness(Brightness.light);

      expect(_amountColor(tester), light.outflow);
      expect(_amountColor(tester), isNot(Colors.red));
    });
  });

  // -------------------------------------------------------------------------
  // The accounts list was the only one of the four whose FAB floated over its
  // own last row: transactions, categories and manage-styles each pad their
  // scroll view by `kFabScrollBottomInset` and it did not. Scrolled to the
  // end, the last account card sat under the add button, so the card's `⋮`
  // menu — the only way to reach that account's actions with a mouse — was
  // unhittable. Nothing throws when a FAB covers a row, so it is measured.
  // -------------------------------------------------------------------------
  group('the accounts FAB does not cover the last account', () {
    /// Enough cards to overflow a 900dp-tall window several times over.
    List<Account> manyAccounts() => [
      for (var i = 0; i < 12; i++) _account('a$i', 'Account $i'),
    ];

    testWidgets('leaves the last account card fully above the button', (
      tester,
    ) async {
      // A phone window on purpose. At 1440px the column is capped at 800 and
      // centred, so the FAB sits in the right-hand gutter and clears the card
      // horizontally whatever the inset does — the assertion would pass on the
      // broken build. At 360dp the card is full-bleed and the button is
      // genuinely on top of it, which is the Android case the renders caught.
      await _pumpAccounts(tester, window: _phone, accounts: manyAccounts());

      // Past the end: the scroll position clamps at maxScrollExtent, so this
      // lands on the last row whatever the card height turns out to be.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -20000));
      await tester.pumpAndSettle();

      final lastCard = find.ancestor(
        of: find.text('Account 11'),
        matching: find.byType(AccountListItem),
      );
      expect(lastCard, findsOneWidget);

      final card = tester.getRect(lastCard);
      final fab = tester.getRect(find.byType(FloatingActionButton));

      // Guard against the assertion going vacuous: it only means anything
      // while the two actually share horizontal space.
      expect(
        card.left < fab.right && fab.left < card.right,
        isTrue,
        reason: 'FAB and card do not overlap horizontally; test proves nothing',
      );
      expect(card.bottom, lessThanOrEqualTo(fab.top));
    });

    testWidgets('reserves the FAB inset at the foot of the list', (
      tester,
    ) async {
      await _pumpAccounts(tester, window: _desktop, accounts: manyAccounts());

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -20000));
      await tester.pumpAndSettle();

      final listBottom = tester.getRect(find.byType(CustomScrollView)).bottom;
      final cardBottom = tester
          .getRect(
            find.ancestor(
              of: find.text('Account 11'),
              matching: find.byType(AccountListItem),
            ),
          )
          .bottom;

      // Scrolled to the end, the gap under the last card is the reserved
      // inset; the half-pixel is float slack, not a tolerance on the rule.
      expect(
        listBottom - cardBottom,
        greaterThanOrEqualTo(kFabScrollBottomInset - 0.5),
      );
    });

    testWidgets('adds no FAB inset to the empty state', (tester) async {
      // The inset belongs to the list, not to the whole scroll view: the empty
      // state is a `SliverFillRemaining` and must not gain 88dp of scroll
      // under a centred message.
      //
      // Zero is *not* the expected extent. Below every state the screen has
      // always parked a `kAccountsEmptyAreaTargetHeight` box carrying the
      // "add account" right-click menu, and with the empty state already
      // filling the viewport that box is the whole scrollable range. So the
      // measurement that separates "no FAB inset" from "FAB inset" is this
      // extent staying at exactly the target height rather than growing to
      // 288.
      await _pumpAccounts(tester, window: _desktop);

      expect(tester.takeException(), isNull);
      final scrollable = tester.widget<Scrollable>(
        find.descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(Scrollable),
        ),
      );
      expect(
        scrollable.controller!.position.maxScrollExtent,
        moreOrLessEquals(kAccountsEmptyAreaTargetHeight, epsilon: 0.5),
      );
    });
  });

  // -------------------------------------------------------------------------
  // Every other money line in the app goes through `MoneyFormatter`'s isolated
  // helpers. The account balance was built by hand as `format(...) + ' ' +
  // symbol`, which leaves a bare number and a bidi-neutral U+0020 next to
  // Arabic letters: the paragraph's RTL run swallowed them and an overdrawn
  // account read `250.00-` while the transaction list beside it read
  // `-250.00`. Same figure, two different strings, in a finance app.
  // -------------------------------------------------------------------------
  group('the balance amount is bidi-isolated', () {
    testWidgets('wraps a negative balance so the sign stays with the digits', (
      tester,
    ) async {
      final overdrawn = _account('a1', 'Checking').copyWith(balance: -250.0);

      await _pumpItem(
        tester,
        overdrawn,
        surface: const Size(500, 900),
        locale: const Locale('ar'),
      );

      // U+2066 LEFT-TO-RIGHT ISOLATE … U+2069 POP DIRECTIONAL ISOLATE, with a
      // U+00A0 joining the amount to its (here empty) symbol. Written out
      // rather than rebuilt from MoneyFormatter so the test states the bytes
      // the renderer receives instead of restating the implementation.
      expect(_amountText(tester), '\u2066-250.00\u00A0\u2069');
    });

    testWidgets('never joins the amount to its symbol with a plain space', (
      tester,
    ) async {
      // U+0020 is bidi class WS, which terminates a number run; U+00A0 is CS,
      // which does not. This is the whole bug in one character.
      await _pumpItem(
        tester,
        _account('a1', 'Checking'),
        surface: const Size(500, 900),
        locale: const Locale('ar'),
      );

      expect(_amountText(tester), isNot(contains(' ')));
      expect(_amountText(tester), startsWith('\u2066'));
      expect(_amountText(tester), endsWith('\u2069'));
    });

    testWidgets('leaves the English rendering byte-identical to before', (
      tester,
    ) async {
      // The isolate marks are zero-width: `en` must read exactly as it did.
      await _pumpItem(
        tester,
        _account('a1', 'Checking'),
        surface: const Size(500, 900),
      );

      expect(
        _amountText(tester).replaceAll(RegExp('[\u2066\u2069]'), ''),
        '1\u00A0500.00\u00A0',
      );
    });

    testWidgets('isolates the change figure too', (tester) async {
      await _pumpItem(
        tester,
        _account('a1', 'Checking'),
        prevBalance: 1000,
        surface: const Size(500, 900),
        locale: const Locale('ar'),
      );

      final row = _balanceRowText(tester);

      // The signed diff, its parentheses and its percent sign are all
      // bidi-neutral, so the group reorders around them unless isolated.
      expect(
        row,
        contains(
          MoneyFormatter.isolate(
            '${MoneyColors.signGlyph(isIncome: true)}500.00 (+50.00%)',
          ),
        ),
      );
    });
  });

  // -------------------------------------------------------------------------
  // The "change" figure used to stack onto a second line based on
  // `Theme.of(context).platform`, so a 360dp desktop window and a 360dp
  // Android phone laid the identical row out differently for a reason no user
  // could see — and a 360dp *pane* on a wide Windows window got the desktop
  // layout it had no room for. The decision is about width, so width is what
  // is pinned.
  // -------------------------------------------------------------------------
  group('the change figure stacks on width, not on platform', () {
    testWidgets('stacks on a narrow surface whatever the platform', (
      tester,
    ) async {
      for (final platform in [TargetPlatform.android, TargetPlatform.windows]) {
        await _pumpItem(
          tester,
          _account('a1', 'Checking'),
          prevBalance: 1000,
          surface: const Size(360, 800),
          platform: platform,
        );

        expect(
          _balanceRowText(tester),
          contains('\n'),
          reason: 'did not stack at 360dp on $platform',
        );
      }
    });

    testWidgets('stays inline on a wide surface whatever the platform', (
      tester,
    ) async {
      for (final platform in [TargetPlatform.android, TargetPlatform.windows]) {
        await _pumpItem(
          tester,
          _account('a1', 'Checking'),
          prevBalance: 1000,
          surface: const Size(600, 800),
          platform: platform,
        );

        expect(
          _balanceRowText(tester),
          isNot(contains('\n')),
          reason: 'stacked at 600dp on $platform',
        );
      }
    });

    testWidgets('carries the same figures either way', (tester) async {
      final l10n = await loadL10n();

      await _pumpItem(
        tester,
        _account('a1', 'Checking'),
        prevBalance: 1000,
        surface: const Size(360, 800),
      );
      final stacked = _balanceRowText(tester);

      await _pumpItem(
        tester,
        _account('a1', 'Checking'),
        prevBalance: 1000,
        surface: const Size(600, 800),
      );
      final inline = _balanceRowText(tester);

      // Only the separator differs; the information does not.
      expect(stacked.replaceAll('\n', ' '), inline);
      for (final text in [stacked, inline]) {
        expect(text, contains(l10n.metricChange));
        expect(text, contains('+50.00%'));
      }
    });
  });
}
