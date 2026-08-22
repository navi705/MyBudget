// Destructive protection in Settings was inverted against the rest of the app:
// deleting one transaction offers an Undo, while "Reset Data" wiped every
// account and every transaction behind a single red button - no typed
// confirmation, no statement of what was about to go, no backup offered. And
// the export chooser had exactly one action ("JSON") and no Cancel, so opening
// it by a mistap left no way out but guessing that a tap outside dismisses.
//
// Both dialogs are pushed onto the app's Navigator, so the blocs they read are
// provided above the MaterialApp rather than around the screen - a provider
// wrapped around `home` is invisible to a route that is `home`'s sibling.
import 'package:bloc_test/bloc_test.dart';
import 'package:drift/drift.dart' show Batch;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:my_budget_client/core/utils/platform/platform_utils.dart';
import 'package:my_budget_client/data/repositories/db_repository.dart';
import 'package:my_budget_client/domain/entities/sms_preset.dart';
import 'package:my_budget_client/domain/repositories/sms_repository.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';
import 'package:my_budget_client/presentation/screens/settings_screen.dart';

import 'test_app.dart';

// Tall on purpose: the settings list is longer than a phone viewport and a
// sliver list only builds what is near the viewport, so a short surface would
// make "row is absent" and "row is merely below the fold" look identical.
// `setSurfaceSize` inside `pumpAppWidget` registers the reset as a tear-down.
const Size _phone = Size(400, 2400);

// An arbitrary count that cannot collide with anything else the screen prints.
const int _transactionCount = 4213;

TransactionsBloc _transactionsBlocWithCount(int count) {
  final bloc = MockTransactionsBloc();
  whenListen(
    bloc,
    const Stream<TransactionsState>.empty(),
    initialState: TransactionsState(totalCount: count),
  );
  return bloc;
}

Future<AppLocalizations> _pumpSettings(WidgetTester tester) async {
  await pumpAppWidget(
    tester,
    const SettingsScreen(),
    surfaceSize: _phone,
    wrapInScaffold: false,
    aboveApp: (app) => wrapWithBlocs(
      app,
      settingsBloc: createSettingsBloc(),
      currencyBloc: createCurrencyBloc(),
      transactionsBloc: _transactionsBlocWithCount(_transactionCount),
    ),
  );
  await tester.pump();
  return loadL10n();
}

Finder _row(String title) => find.widgetWithText(ListTile, title);

/// Scoped to the dialog: several of these strings are also row labels on the
/// screen behind it, and an unscoped `find.text` would match either one.
Finder _inDialog(Finder matching) =>
    find.descendant(of: find.byType(AlertDialog), matching: matching);

Finder _resetButton(AppLocalizations l10n) =>
    _inDialog(find.widgetWithText(TextButton, l10n.resetEverythingButton));

Future<AppLocalizations> _openResetDialog(WidgetTester tester) async {
  final l10n = await _pumpSettings(tester);
  await tester.tap(_row(l10n.resetDataLabel));
  await tester.pumpAndSettle();
  expect(find.text(l10n.resetDataConfirmationTitle), findsOneWidget);
  return l10n;
}

void main() {
  group('Reset Data confirmation', () {
    testWidgets('is inert until the confirmation word is typed', (
      tester,
    ) async {
      final l10n = await _openResetDialog(tester);

      expect(
        tester.widget<TextButton>(_resetButton(l10n)).onPressed,
        isNull,
        reason: 'an armed reset button is the bug this dialog exists to fix',
      );

      // A near miss must not arm it either.
      await tester.enterText(
        find.byKey(const Key('reset-confirmation-field')),
        '${l10n.confirmButton}x',
      );
      await tester.pump();
      expect(tester.widget<TextButton>(_resetButton(l10n)).onPressed, isNull);

      await tester.enterText(
        find.byKey(const Key('reset-confirmation-field')),
        l10n.confirmButton,
      );
      await tester.pump();
      expect(
        tester.widget<TextButton>(_resetButton(l10n)).onPressed,
        isNotNull,
      );
    });

    testWidgets('states how much data is about to be deleted', (tester) async {
      final l10n = await _openResetDialog(tester);

      // "All your data" is an adjective; the count is the fact.
      expect(
        _inDialog(find.text(l10n.transactionsAppBarTitle)),
        findsOneWidget,
      );
      expect(_inDialog(find.text('$_transactionCount')), findsOneWidget);
    });

    testWidgets('offers a backup as the primary action', (tester) async {
      final l10n = await _openResetDialog(tester);

      // Export is the FilledButton (primary); reset is a plain TextButton, so
      // the cheap way out is the one the eye and the default focus land on.
      expect(
        _inDialog(find.widgetWithText(FilledButton, l10n.exportDataLabel)),
        findsOneWidget,
      );
      expect(_resetButton(l10n), findsOneWidget);
      expect(
        _inDialog(
          find.widgetWithText(FilledButton, l10n.resetEverythingButton),
        ),
        findsNothing,
      );
    });

    testWidgets('can still be cancelled', (tester) async {
      final l10n = await _openResetDialog(tester);

      await tester.tap(
        _inDialog(find.widgetWithText(TextButton, l10n.cancelButton)),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.resetDataConfirmationTitle), findsNothing);
    });
  });

  // The other half of the same dialog: once the word *is* typed, the wipe has
  // to run to the end. It reaches for a bloc that only exists on Android, and
  // the reload used to be unconditional, so on Windows the read threw after the
  // database was already empty and the user was told the reset had failed.
  group('Reset Data, once armed', () {
    late _FakeDbRepository db;
    late _FakeSmsRepository sms;

    setUp(() {
      db = _FakeDbRepository();
      sms = _FakeSmsRepository();
      GetIt.I.registerSingleton<DbRepository>(db);
      GetIt.I.registerSingleton<SmsRepository>(sms);
    });

    tearDown(() {
      debugAppPlatformOverride = null;
      return GetIt.I.reset();
    });

    testWidgets('wipes and reports success with no SmsBloc in the tree', (
      tester,
    ) async {
      debugAppPlatformOverride = AppPlatformKind.windows;

      // Note the absence of an SmsBloc: this is the provider set the app
      // builds on every platform except Android.
      await pumpAppWidget(
        tester,
        const SettingsScreen(),
        surfaceSize: _phone,
        wrapInScaffold: false,
        aboveApp: (app) => wrapWithBlocs(
          app,
          settingsBloc: createSettingsBloc(),
          currencyBloc: createCurrencyBloc(),
          stylesBloc: createStylesBloc(),
          accountsBloc: MockAccountsBloc(),
          categoriesBloc: MockCategoriesBloc(),
          transactionsBloc: _transactionsBlocWithCount(_transactionCount),
          dashboardBloc: MockDashboardBloc(),
          currencyConverterBloc: MockCurrencyConverterBloc(),
        ),
      );
      await tester.pump();
      final l10n = await loadL10n();

      await tester.tap(_row(l10n.resetDataLabel));
      await tester.pumpAndSettle();

      // Arming the button is the user's part of the contract, and it is what
      // the old one-tap version of this test skipped.
      await tester.enterText(
        find.byKey(const Key('reset-confirmation-field')),
        l10n.confirmButton,
      );
      await tester.pump();

      await tester.tap(_resetButton(l10n));
      await tester.pumpAndSettle();

      expect(db.cleared, isTrue, reason: 'the wipe never reached the database');
      expect(sms.cleared, isTrue);
      expect(
        find.text(l10n.resetSuccessMessage),
        findsOneWidget,
        reason: 'a missing SmsBloc must not be reported as a failed reset',
      );
    });
  });

  group('Export dialog', () {
    testWidgets('has a Cancel that closes it', (tester) async {
      final l10n = await _pumpSettings(tester);

      await tester.tap(_row(l10n.exportDataLabel));
      await tester.pumpAndSettle();

      // The dialog is open: the one format it offers is on screen.
      final json = _inDialog(
        find.widgetWithText(FilledButton, l10n.jsonFormat),
      );
      expect(json, findsOneWidget);

      final cancel = _inDialog(
        find.widgetWithText(TextButton, l10n.cancelButton),
      );
      expect(
        cancel,
        findsOneWidget,
        reason: 'one action and no Cancel traps a mistap inside the dialog',
      );

      await tester.tap(cancel);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, l10n.jsonFormat), findsNothing);
    });
  });
}

class _FakeDbRepository implements DbRepository {
  bool cleared = false;

  @override
  Future<void> clearAllDatabase() async => cleared = true;

  @override
  Future<void> batch(Function(Batch) action) async {}
}

/// Only [clearData] matters here; the rest of the interface is device SMS
/// access, which a widget test never reaches.
class _FakeSmsRepository implements SmsRepository {
  bool cleared = false;

  @override
  Future<void> clearData() async => cleared = true;

  @override
  Future<List<SmsPreset>> getAllPresets() async => const [];

  @override
  Future<List<SmsPreset>> getEnabledPresets() async => const [];

  @override
  Future<void> savePreset(SmsPreset preset) async {}

  @override
  Future<void> deletePreset(String presetId) async {}

  @override
  Future<void> togglePreset(String presetId, bool isEnabled) async {}

  @override
  Future<DateTime?> getLastSyncTimestamp() async => null;

  @override
  Future<void> setLastSyncTimestamp(DateTime timestamp) async {}

  @override
  Future<List<SmsMessage>> getSmsMessages({
    DateTime? since,
    List<String>? senderFilters,
  }) async => const [];

  @override
  Stream<SmsMessage> listenForSms() => const Stream<SmsMessage>.empty();

  @override
  Future<bool> hasSmsPermission() async => false;

  @override
  Future<bool> requestSmsPermission() async => false;
}
