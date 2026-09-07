// The balance this form is allowed to write back.
//
// `AccountsBloc` never puts a stored balance in its state: `_onLoadAccounts`
// replaces every account's balance with one computed for the active date
// (stored minus everything dated after it), and the historical load replaces it
// with the full reverse-calculation of a past period. That object is what the
// accounts grid pushes into this screen, so the form used to open on a figure
// belonging to a *view* and hand it to `UpdateAccount` on Save. Renaming an
// account while last month was on screen moved its balance to last month's, and
// every balance derived afterwards was computed from the new, wrong base.
//
// The form reads the row back from the repository before it becomes
// interactive. These tests give the routed account and the stored row different
// balances on purpose - that gap is the only thing that separates the two
// behaviours.
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/asset_data.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/domain/repositories/asset_repository.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
import 'package:my_budget_client/core/utils/hotkey_utils.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';
import 'package:my_budget_client/presentation/screens/edit_account_screen.dart';

import '../test_app.dart';

/// Tall enough for Save to be on screen without scrolling.
const Size _surface = Size(600, 2000);

/// A phone in portrait: the narrowest surface this form is edited on.
const Size _phone = Size(390, 844);

/// What the database holds: a balance of 100.00 EUR, exact to the cent.
final Account _stored = Account(
  id: 'a1',
  name: 'Checking',
  balance: 100.0,
  balanceMinor: 10000,
  currencyCode: 'EUR',
  currencyDesignationId: 'd1',
  accountTypeId: 't1',
  creationDate: DateTime(2024, 1, 1),
);

/// What the accounts grid pushes: the same row with last month's balance.
final Account _asViewed = _stored.copyWith(balance: 42.0);

// ---------------------------------------------------------------------------
// Doubles
//
// Only the calls this screen makes are implemented; anything else should throw
// rather than answer with a default that quietly changes what a test proves.
// ---------------------------------------------------------------------------

class _FakeAccountRepository extends Fake implements AccountRepository {
  _FakeAccountRepository(this.stored, {this.gate, this.failure});

  final Account? stored;

  /// Completed by the test to release the read, when it wants to see the form
  /// mid-load.
  final Future<void>? gate;

  /// Thrown by the read, the way a locked database would.
  final Object? failure;

  final requestedIds = <String>[];

  @override
  Future<Account?> getAccountById(String id) async {
    requestedIds.add(id);
    if (gate != null) await gate;
    if (failure != null) throw failure!;
    return stored;
  }

  @override
  Stream<List<Account>> watchAccounts() => const Stream.empty();
}

class _FakeAssetRepository extends Fake implements AssetRepository {
  @override
  Stream<List<AssetDataDomain>> watchAssetData({
    int limit = 50,
    int offset = 0,
    String? assetId,
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
    String? name,
    List<String>? assetTypes,
    String? description,
    List<String>? currencyCodes,
    List<String>? sources,
    List<int>? presets,
    double? minValue,
    double? maxValue,
    bool sortAscending = false,
  }) => const Stream<List<AssetDataDomain>>.empty();
}

/// An [AccountsBloc] that records what the screen dispatched.
///
/// `MockBloc.add` is a no-op that keeps no history, and the whole point of
/// these tests is *which* account reached `UpdateAccount` - or whether one was
/// sent at all.
class _RecordingAccountsBloc extends MockAccountsBloc {
  final events = <AccountsEvent>[];

  @override
  void add(AccountsEvent event) => events.add(event);
}

/// The account carried by the single [UpdateAccount] the screen sent.
///
/// Fails loudly on none and on more than one: both mean the screen did
/// something other than what the test is asserting about.
Account _savedAccount(_RecordingAccountsBloc bloc) {
  final updates = bloc.events.whereType<UpdateAccount>().toList();
  expect(updates, hasLength(1), reason: 'expected exactly one UpdateAccount');
  return updates.single.account;
}

// ---------------------------------------------------------------------------
// Harness
// ---------------------------------------------------------------------------

/// Opens the screen on [routed], with [stored] as the row the database returns.
///
/// Returns the recording bloc so a test can read what Save dispatched.
Future<_RecordingAccountsBloc> _pumpEditAccount(
  WidgetTester tester, {
  required Account routed,
  Account? stored,
  Future<void>? gate,
  Object? failure,
  bool settle = true,
  Size surface = _surface,
  double textScale = 1.0,
  Locale locale = const Locale('en'),
  Map<String, String> hotkeys = const {},
}) async {
  setSurfaceSize(tester, surface);

  // The screen resolves both repositories out of `sl`, which is the only seam
  // a widget test has on it.
  GetIt.I.registerSingleton<AccountRepository>(
    _FakeAccountRepository(stored, gate: gate, failure: failure),
  );
  GetIt.I.registerSingleton<AssetRepository>(_FakeAssetRepository());

  final accountsBloc = _RecordingAccountsBloc();
  whenListen(
    accountsBloc,
    const Stream<AccountsState>.empty(),
    // The escape handler and the delete dialog both read the state; only the
    // account list in it matters to them.
    initialState: AccountsLoadSuccess(
      accounts: [routed],
      accountTypes: const [],
      hasReachedMax: true,
      totalCount: 1,
      exchangeRates: const [],
      activeDate: DateTime(2024, 1, 1),
    ),
  );

  // Started on the accounts route and pushed from there, the way the grid does
  // it: Save ends in `context.pop()`, which throws on a route with nothing
  // underneath it.
  final router = GoRouter(
    initialLocation: AppRoutes.accounts,
    routes: [
      GoRoute(path: AppRoutes.accounts, builder: (_, _) => const SizedBox()),
      GoRoute(
        path: AppRoutes.editAccount,
        builder: (_, _) => EditAccountScreen(account: routed),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    wrapWithBlocs(
      MaterialApp.router(
        routerConfig: router,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery.withClampedTextScaling(
          minScaleFactor: textScale,
          maxScaleFactor: textScale,
          child: child!,
        ),
      ),
      // EscapeBackHandler and the country field read Settings; the currency
      // field reads Currency; the style tile reads Styles.
      settingsBloc: createSettingsBloc(state: SettingsState(hotkeys: hotkeys)),
      currencyBloc: createCurrencyBloc(),
      stylesBloc: createStylesBloc(),
      accountsBloc: accountsBloc,
    ),
  );
  await tester.pumpAndSettle();

  router.push(AppRoutes.editAccount);
  await tester.pump();
  if (settle) await tester.pumpAndSettle();

  return accountsBloc;
}

Future<void> _tapSave(WidgetTester tester) async {
  final l10n = await loadL10n();
  await tester.ensureVisible(find.text(l10n.saveButton));
  await tester.tap(find.text(l10n.saveButton));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() async {
    await GetIt.I.reset();
  });

  group('EditAccountScreen balance', () {
    testWidgets('opens on the stored balance, not the one the grid showed', (
      tester,
    ) async {
      await _pumpEditAccount(tester, routed: _asViewed, stored: _stored);

      expect(find.text('100'), findsOneWidget);
      expect(find.text('42'), findsNothing);
    });

    testWidgets('offers the balance at the precision the currency has', (
      tester,
    ) async {
      // A balance an importer round-tripped through a 32-bit float. The field
      // used to show every digit the double holds, so editing it meant
      // deleting '158265.09375' by hand.
      await _pumpEditAccount(
        tester,
        routed: _asViewed,
        stored: _stored.copyWith(balance: 158265.09375, balanceMinor: 15826509),
      );

      expect(find.text('158265.09'), findsOneWidget);
    });

    testWidgets('reads the row back by the routed id', (tester) async {
      await _pumpEditAccount(tester, routed: _asViewed, stored: _stored);

      final repository = GetIt.I<AccountRepository>() as _FakeAccountRepository;
      expect(repository.requestedIds, [_stored.id]);
    });

    testWidgets('keeps the stored balance when only the name changed', (
      tester,
    ) async {
      final bloc = await _pumpEditAccount(
        tester,
        routed: _asViewed,
        stored: _stored,
      );
      final l10n = await loadL10n();

      await tester.enterText(
        find.widgetWithText(TextFormField, _stored.name),
        'Rent',
      );
      await tester.pumpAndSettle();
      await _tapSave(tester);

      final saved = _savedAccount(bloc);
      expect(saved.name, 'Rent');
      expect(saved.balance, _stored.balance);
      // The exact minor units go through untouched: a rename must not push the
      // account off its cent-exact anchor.
      expect(saved.balanceMinor, _stored.balanceMinor);
      expect(l10n.saveButton, isNotEmpty);
    });

    testWidgets('writes nothing at all when nothing was edited', (
      tester,
    ) async {
      final bloc = await _pumpEditAccount(
        tester,
        routed: _asViewed,
        stored: _stored,
      );

      await _tapSave(tester);

      expect(bloc.events.whereType<UpdateAccount>(), isEmpty);
    });

    testWidgets('still saves a balance the user typed', (tester) async {
      final bloc = await _pumpEditAccount(
        tester,
        routed: _asViewed,
        stored: _stored,
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, '100'),
        '250.5',
      );
      await tester.pumpAndSettle();
      await _tapSave(tester);

      final saved = _savedAccount(bloc);
      expect(saved.balance, 250.5);
      // Dropped rather than carried over: the mapper recomputes them from the
      // typed figure, and the old anchor would outvote it.
      expect(saved.balanceMinor, isNull);
    });
  });

  group('EditAccountScreen while the stored row is on its way', () {
    testWidgets('shows a spinner instead of the form', (tester) async {
      final gate = Completer<void>();
      addTearDown(() {
        if (!gate.isCompleted) gate.complete();
      });

      await _pumpEditAccount(
        tester,
        routed: _asViewed,
        stored: _stored,
        gate: gate.future,
        settle: false,
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Nothing to edit yet, so nothing of the routed figure is on screen.
      expect(find.text('42'), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('100'), findsOneWidget);
    });
  });

  // Save used to be the last row of a scrolling column that ends in the
  // account's linked assets, so on a phone the button that finishes the job sat
  // below the fold - and there was no key that ran it either.
  group('EditAccountScreen reaching Save', () {
    testWidgets('it is on screen on a phone without scrolling', (tester) async {
      final l10n = await loadL10n();
      await _pumpEditAccount(
        tester,
        routed: _asViewed,
        stored: _stored,
        // The smallest surface the app supports.
        surface: const Size(360, 640),
      );

      final save = find.widgetWithText(FilledButton, l10n.saveButton);
      expect(save, findsOneWidget);
      expect(tester.getBottomLeft(save).dy, lessThanOrEqualTo(640));
      expect(
        find.text(l10n.deleteButton),
        findsOneWidget,
        reason: 'Delete moved into the same footer and has to still be there',
      );
    });

    testWidgets('the save hotkey runs the same save the button does', (
      tester,
    ) async {
      final bloc = await _pumpEditAccount(
        tester,
        routed: _asViewed,
        stored: _stored,
        hotkeys: {
          'save_form': HotKeyUtils.serializeKeys({
            LogicalKeyboardKey.control,
            LogicalKeyboardKey.enter,
          }),
        },
      );
      final l10n = await loadL10n();

      await tester.enterText(
        find.widgetWithText(TextFormField, l10n.accountNameHint),
        'Renamed',
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      final saved = _savedAccount(bloc);
      expect(saved.name, 'Renamed');
      // And the same stored balance the button would have written, rather than
      // the date-scoped one the route carried.
      expect(saved.balance, _stored.balance);
    });

    testWidgets('with no key bound nothing is saved behind the user', (
      tester,
    ) async {
      final bloc = await _pumpEditAccount(
        tester,
        routed: _asViewed,
        stored: _stored,
      );
      final l10n = await loadL10n();

      await tester.enterText(
        find.widgetWithText(TextFormField, l10n.accountNameHint),
        'Renamed',
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(bloc.events.whereType<UpdateAccount>(), isEmpty);
    });
  });

  group('EditAccountScreen when the row cannot be read', () {
    testWidgets('falls back to the routed account after a failed read', (
      tester,
    ) async {
      await _pumpEditAccount(
        tester,
        routed: _asViewed,
        failure: Exception('database is locked'),
      );

      // Best effort: there is nothing better to edit, and the form has to open
      // on something rather than hang.
      expect(find.text('42'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('falls back when the account was deleted elsewhere', (
      tester,
    ) async {
      await _pumpEditAccount(tester, routed: _asViewed, stored: null);

      expect(find.text('42'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  // The bar at the bottom holds Delete and Save side by side, and only Save is
  // allowed to take the space that is left. Delete carries an icon and a word,
  // both of which grow with the text setting, so on a narrow phone at a large
  // scale the row is the first thing in this form to run out of width - and an
  // overflow there covers the two buttons the screen exists to offer.
  group('EditAccountScreen on a phone', () {
    testWidgets('both buttons fit the bar', (tester) async {
      await _pumpEditAccount(
        tester,
        routed: _asViewed,
        stored: _stored,
        surface: _phone,
      );

      final l10n = await loadL10n();
      final save = find.widgetWithText(FilledButton, l10n.saveButton);
      final delete = find.byIcon(Icons.delete_outline);
      expect(save, findsOneWidget);
      expect(delete, findsOneWidget);
      expect(find.text(l10n.deleteButton), findsOneWidget);

      for (final part in [save, delete, find.text(l10n.deleteButton)]) {
        final rect = tester.getRect(part);
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(_phone.width));
      }
      expect(
        tester.getSize(save).height,
        greaterThanOrEqualTo(48),
        reason: 'a button under 48dp is one the user has to aim at',
      );
    });

    testWidgets('they still fit with the phone set to large text', (
      tester,
    ) async {
      await _pumpEditAccount(
        tester,
        routed: _asViewed,
        stored: _stored,
        surface: _phone,
        textScale: 2.0,
      );

      final l10n = await loadL10n();
      for (final part in [
        find.widgetWithText(FilledButton, l10n.saveButton),
        find.text(l10n.deleteButton),
        find.byIcon(Icons.delete_outline),
      ]) {
        final rect = tester.getRect(part);
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(
          rect.right,
          lessThanOrEqualTo(_phone.width),
          reason: 'both buttons stay on a 390dp screen at any text setting',
        );
      }
    });

    testWidgets('a language with longer words stacks them instead', (
      tester,
    ) async {
      // Russian at twice the text size is where the two words stop fitting
      // side by side: the bar puts Save over Delete rather than clipping
      // either of them.
      await _pumpEditAccount(
        tester,
        routed: _asViewed,
        stored: _stored,
        surface: _phone,
        textScale: 2.0,
        locale: const Locale('ru'),
      );

      final l10n = await AppLocalizations.delegate.load(const Locale('ru'));
      final save = tester.getRect(
        find.widgetWithText(FilledButton, l10n.saveButton),
      );
      final delete = tester.getRect(find.byIcon(Icons.delete_outline));

      expect(save.right, lessThanOrEqualTo(_phone.width));
      expect(
        delete.top,
        greaterThanOrEqualTo(save.bottom),
        reason: 'stacked, so neither word has to be cut short',
      );
    });

    testWidgets('the form can still be edited and saved at large text', (
      tester,
    ) async {
      final bloc = await _pumpEditAccount(
        tester,
        routed: _asViewed,
        stored: _stored,
        surface: _phone,
        textScale: 2.0,
      );

      final l10n = await loadL10n();
      final name = find.widgetWithText(TextFormField, l10n.accountNameHint);
      await tester.ensureVisible(name);
      await tester.pumpAndSettle();
      await tester.enterText(name, 'Renamed');
      await tester.pumpAndSettle();

      await _tapSave(tester);

      final event = bloc.events.whereType<UpdateAccount>().single;
      expect(event.account.name, 'Renamed');
      expect(
        event.account.balance,
        _stored.balance,
        reason: 'the stored balance is what a rename must write back',
      );
    });
  });
}
