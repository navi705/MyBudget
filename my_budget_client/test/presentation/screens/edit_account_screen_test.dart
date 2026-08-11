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
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/asset_data.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/domain/repositories/asset_repository.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';
import 'package:my_budget_client/presentation/screens/edit_account_screen.dart';

import '../test_app.dart';

/// Tall enough for Save to be on screen without scrolling.
const Size _surface = Size(600, 2000);

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
}) async {
  setSurfaceSize(tester, _surface);

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
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
      // EscapeBackHandler and the country field read Settings; the currency
      // field reads Currency; the style tile reads Styles.
      settingsBloc: createSettingsBloc(),
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

      expect(find.text('100.0'), findsOneWidget);
      expect(find.text('42.0'), findsNothing);
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
        find.widgetWithText(TextFormField, '100.0'),
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
      expect(find.text('42.0'), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('100.0'), findsOneWidget);
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
      expect(find.text('42.0'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('falls back when the account was deleted elsewhere', (
      tester,
    ) async {
      await _pumpEditAccount(tester, routed: _asViewed, stored: null);

      expect(find.text('42.0'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
