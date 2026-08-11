// The screen half of AccountsBloc's failure reporting.
//
// Every mutation in the bloc used to swallow its exception into a `debugPrint`,
// so the screen had nothing to show and showed nothing: a failed save closed its
// dialog, and — worse — a failed *delete* still put the "deleted / Undo"
// SnackBar on screen. The account was never gone, so Undo restored a row that
// had never left, and the user's only evidence that anything went wrong was
// that the list looked unchanged.
//
// The bloc now reports `error` on the state, and the screen's listener has to
// route on it: an error is a SnackBar of its own and it *suppresses* the Undo
// offer. The two must never be on screen together, because "deleted, Undo?" is
// a claim that the delete happened.
//
// The listener is driven through a controlled stream rather than a real bloc so
// each state below is exactly the one under test; what the screen dispatched
// back is captured by overriding `add` (the project mocks with mockito, which
// has no `verify(() => ...)` for a bloc built this way).
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency_converter/currency_converter_bloc.dart';
import 'package:my_budget_client/presentation/screens/accounts_screen.dart';

import '../test_app.dart';

/// An [AccountsBloc] whose `add` records instead of dispatching.
///
/// `MockBloc.add` is a no-op that mocktail could verify, but this project's
/// mock is mockito, whose `verify` cannot see through a bloc built this way.
/// Recording the events is both simpler and stricter: a test can assert what
/// was *not* dispatched as easily as what was.
class _RecordingAccountsBloc extends MockBloc<AccountsEvent, AccountsState>
    implements AccountsBloc {
  final events = <AccountsEvent>[];

  @override
  void add(AccountsEvent event) => events.add(event);
}

final _wallet = Account(
  id: 'a1',
  name: 'Wallet',
  balance: 100,
  currencyCode: 'USD',
  currencyDesignationId: 'usd',
  accountTypeId: 'cash',
  creationDate: DateTime(2025, 1, 1),
);

const _failure = 'database is locked';

/// A loaded state that differs from its neighbours only in [error] and
/// [recentlyDeletedAccount] — the two fields the listener routes on.
///
/// The account list is empty and `activeDate` is fixed on purpose: an account
/// row would drag in the whole balance-formatting stack, and a changed
/// `activeDate` would wake the screen's *other* listener, which reaches for the
/// CurrencyConverterBloc. Neither has anything to do with failure reporting.
AccountsState _loaded({Account? recentlyDeletedAccount, String? error}) =>
    AccountsLoadSuccess(
      accounts: const [],
      accountTypes: const [],
      hasReachedMax: true,
      totalCount: 0,
      activeDate: DateTime(2025, 3, 15),
      exchangeRates: const [],
      recentlyDeletedAccount: recentlyDeletedAccount,
      error: error,
    );

typedef _Harness = ({
  _RecordingAccountsBloc bloc,
  StreamController<AccountsState> states,
  AppLocalizations l10n,
});

/// Pumps AccountsScreen over a stream the test drives by hand.
///
/// Only the three blocs the screen reads while building are provided —
/// SettingsBloc for `ScreenShortcuts`/`MultiLevelTooltip`, AccountsBloc, and
/// CurrencyConverterBloc for the balance summary. They sit above the app
/// because that is where `AppProviders` puts them in production.
Future<_Harness> _pumpAccounts(WidgetTester tester) async {
  final states = StreamController<AccountsState>();
  addTearDown(states.close);

  final bloc = _RecordingAccountsBloc();
  whenListen(bloc, states.stream, initialState: _loaded());

  final converter = MockCurrencyConverterBloc();
  whenListen(
    converter,
    const Stream<CurrencyConverterState>.empty(),
    // Not a success state, so the total-balance summary stays collapsed.
    initialState: CurrencyConverterInitial(),
  );

  await pumpAppWidget(
    tester,
    const AccountsScreen(),
    surfaceSize: const Size(900, 1200),
    // AccountsScreen brings its own Scaffold, which is what hosts the SnackBar.
    wrapInScaffold: false,
    aboveApp: (app) => wrapWithBlocs(
      app,
      settingsBloc: createSettingsBloc(),
      accountsBloc: bloc,
      currencyConverterBloc: converter,
    ),
  );
  await tester.pump();

  return (bloc: bloc, states: states, l10n: await loadL10n());
}

Future<void> _emit(
  WidgetTester tester,
  _Harness harness,
  AccountsState state,
) async {
  harness.states.add(state);
  await tester.pumpAndSettle();
}

/// Runs a showing SnackBar's display timer out and lets it animate away.
///
/// `pumpAndSettle` stops as soon as no frame is scheduled, which leaves the
/// four-second timer pending — and the test binding fails any test that ends
/// with a pending timer. A SnackBar carrying an action does not actually go
/// away when the timer fires (Flutter defaults `persist` to `action != null`),
/// but the timer is still drained, which is all this is for.
Future<void> _runOutSnackBar(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

Finder _snackBarCloseIcon() => find.descendant(
  of: find.byType(SnackBar),
  matching: find.byIcon(Icons.close),
);

void main() {
  group('AccountsScreen failure reporting', () {
    testWidgets('shows the message a failed mutation reported', (tester) async {
      final harness = await _pumpAccounts(tester);

      await _emit(tester, harness, _loaded(error: _failure));

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text(harness.l10n.importErrorLabel(_failure)),
        findsOneWidget,
      );

      await _runOutSnackBar(tester);
    });

    // The bug this whole change exists to kill. A delete that threw left
    // `recentlyDeletedAccount` null — there was nothing to undo — yet the
    // screen showed the Undo SnackBar anyway, because the listener had no
    // error branch to stop at.
    testWidgets('offers no Undo when the failure carries no deleted account', (
      tester,
    ) async {
      final harness = await _pumpAccounts(tester);

      await _emit(tester, harness, _loaded(error: _failure));

      expect(
        find.text(harness.l10n.importErrorLabel(_failure)),
        findsOneWidget,
      );
      expect(find.byType(SnackBarAction), findsNothing);
      expect(find.text(harness.l10n.undoButton), findsNothing);
      expect(
        find.text(harness.l10n.itemDeletedMessage(_wallet.name)),
        findsNothing,
      );

      await _runOutSnackBar(tester);
    });

    // A failed *undo* is the one failure that does keep the account pending, so
    // both fields are set at once. The error still wins: re-offering Undo would
    // be offering the button that just failed as if nothing had happened.
    testWidgets('reports a failed undo rather than offering Undo again', (
      tester,
    ) async {
      final harness = await _pumpAccounts(tester);

      await _emit(
        tester,
        harness,
        _loaded(recentlyDeletedAccount: _wallet, error: _failure),
      );

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text(harness.l10n.importErrorLabel(_failure)),
        findsOneWidget,
      );
      expect(
        find.text(harness.l10n.itemDeletedMessage(_wallet.name)),
        findsNothing,
      );
      expect(find.byType(SnackBarAction), findsNothing);

      await _runOutSnackBar(tester);
    });

    testWidgets('shows the deleted/Undo SnackBar when nothing failed', (
      tester,
    ) async {
      final harness = await _pumpAccounts(tester);

      await _emit(tester, harness, _loaded(recentlyDeletedAccount: _wallet));

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text(harness.l10n.itemDeletedMessage(_wallet.name)),
        findsOneWidget,
      );
      expect(find.byType(SnackBarAction), findsOneWidget);
      expect(find.text(harness.l10n.undoButton), findsOneWidget);
      expect(find.text(harness.l10n.importErrorLabel(_failure)), findsNothing);

      await _runOutSnackBar(tester);
    });

    // The same rule across two states rather than within one: once something
    // fails, the standing "deleted, Undo?" offer has to go, not sit beside the
    // error.
    testWidgets('replaces a showing deleted SnackBar with the error', (
      tester,
    ) async {
      final harness = await _pumpAccounts(tester);

      await _emit(tester, harness, _loaded(recentlyDeletedAccount: _wallet));
      expect(
        find.text(harness.l10n.itemDeletedMessage(_wallet.name)),
        findsOneWidget,
      );

      await _emit(tester, harness, _loaded(error: _failure));

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text(harness.l10n.importErrorLabel(_failure)),
        findsOneWidget,
      );
      expect(
        find.text(harness.l10n.itemDeletedMessage(_wallet.name)),
        findsNothing,
      );
      expect(find.byType(SnackBarAction), findsNothing);
      // Pulling the offer off screen has to retract it in the bloc too,
      // otherwise the next state still believes an undo is pending.
      expect(
        harness.bloc.events.whereType<ClearRecentlyDeletedAccount>(),
        hasLength(1),
      );
      expect(harness.bloc.events.whereType<UndoDeleteAccount>(), isEmpty);

      await _runOutSnackBar(tester);
    });
  });

  group('AccountsScreen undo SnackBar', () {
    testWidgets('asks the bloc to restore the account when Undo is tapped', (
      tester,
    ) async {
      final harness = await _pumpAccounts(tester);
      await _emit(tester, harness, _loaded(recentlyDeletedAccount: _wallet));

      await tester.tap(find.text(harness.l10n.undoButton));
      await tester.pumpAndSettle();

      expect(harness.bloc.events.whereType<UndoDeleteAccount>(), hasLength(1));
      // The bloc clears the pending account itself when the undo runs; sending
      // the clear as well would race the restore.
      expect(
        harness.bloc.events.whereType<ClearRecentlyDeletedAccount>(),
        isEmpty,
      );
    });

    testWidgets('clears the pending delete when the SnackBar is dismissed', (
      tester,
    ) async {
      final harness = await _pumpAccounts(tester);
      await _emit(tester, harness, _loaded(recentlyDeletedAccount: _wallet));

      await tester.tap(_snackBarCloseIcon());
      await tester.pumpAndSettle();

      expect(
        harness.bloc.events.whereType<ClearRecentlyDeletedAccount>(),
        hasLength(1),
      );
      expect(harness.bloc.events.whereType<UndoDeleteAccount>(), isEmpty);
    });

    // The other way out that costs the user the offer: a SnackBar carrying an
    // action never times out (Flutter defaults `persist` to `action != null`),
    // so swiping and the close icon are the only two exits besides Undo.
    testWidgets('clears the pending delete when the SnackBar is swiped away', (
      tester,
    ) async {
      final harness = await _pumpAccounts(tester);
      await _emit(tester, harness, _loaded(recentlyDeletedAccount: _wallet));

      await tester.drag(find.byType(SnackBar), const Offset(0, 200));
      await tester.pumpAndSettle();

      expect(
        harness.bloc.events.whereType<ClearRecentlyDeletedAccount>(),
        hasLength(1),
      );
      expect(harness.bloc.events.whereType<UndoDeleteAccount>(), isEmpty);
    });
  });
}
