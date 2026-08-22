// The red bar that would not leave.
//
// `validationError` stays set in the state after a failure - nothing clears it
// until the next attempt - and the screen's BlocListener has to run on *every*
// state to keep the text controllers in step with the bloc. Those two facts
// collided: one refused save, and then every keystroke the user typed
// afterwards re-entered the listener and queued another red SnackBar, so the
// message they had already read followed them down the form. The listener now
// remembers the message it put on screen and only speaks up when it changes.
//
// These tests drive the real `AddEditTransactionBloc` through fake repositories
// registered in the `sl` container the screen builds it from, so the messages
// are the ones the product actually produces, spelling included. The locale is
// French throughout: a sentinel that reached the user untranslated would read
// as English in a French app, which is exactly what these assertions look for.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';
import 'package:my_budget_client/domain/entities/settings.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/domain/repositories/asset_repository.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
import 'package:my_budget_client/presentation/screens/add_edit_transaction_screen.dart';

import '../test_app.dart';

// Tall enough for the whole form - Save included - to be on screen without
// scrolling, so a tap never has to fight the viewport.
const Size _surface = Size(600, 1400);

const Locale _french = Locale('fr');

/// What a repository exception looks like by the time it reaches the screen:
/// the bloc stores `'$e'`, and no lookup can translate it.
final Exception _dbLocked = Exception('database is locked');
const String _dbLockedMessage = 'Exception: database is locked';

const Currency _euro = Currency(
  name: 'Euro',
  code: 'EUR',
  languageCode: 'fr',
  type: TypeCurrency.currency,
);

final Account _euroAccount = Account(
  id: 'a1',
  name: 'Wallet',
  balance: 100,
  currencyCode: 'EUR',
  currencyDesignationId: 'd1',
  accountTypeId: 't1',
  creationDate: DateTime(2024, 1, 1),
);

/// Same account, kept in dollars. The catalogue below only offers EUR, so the
/// form opens with a transaction currency that differs from the account's -
/// `isForeignCurrency`, and therefore the exchange-rate section - without
/// having to drive the currency picker first.
final Account _dollarAccount = Account(
  id: 'a2',
  name: 'Travel',
  balance: 100,
  currencyCode: 'USD',
  currencyDesignationId: 'd2',
  accountTypeId: 't1',
  creationDate: DateTime(2024, 1, 1),
);

final Category _groceries = Category(id: 'c1', name: 'Groceries');

/// A stored preset, so the rate section offers Update - the one path that
/// reports a second problem without clearing the first one on the way.
final ExchangeRateDomain _preset2 = ExchangeRateDomain(
  fromCurrencyCode: 'EUR',
  toCurrencyCode: 'USD',
  rate: 1.1,
  date: DateTime(2024, 6, 1),
  preset: 2,
);

// ---------------------------------------------------------------------------
// Repositories
//
// Only the calls this screen makes are implemented: anything else should fail
// loudly rather than answer with a default that quietly changes what a test
// proves.
// ---------------------------------------------------------------------------

class _FakeTransactionRepository extends Fake implements TransactionRepository {
  _FakeTransactionRepository({this.failure});

  /// Thrown by every write, the way a locked database would.
  final Object? failure;
  final added = <Transaction>[];

  @override
  Future<void> addTransaction(Transaction transaction) async {
    added.add(transaction);
    if (failure != null) throw failure!;
  }

  @override
  Stream<void> watchTransactionChanges() => const Stream.empty();
}

class _FakeAccountRepository extends Fake implements AccountRepository {
  _FakeAccountRepository(this.accounts);

  final List<Account> accounts;

  @override
  Future<List<Account>> getAccounts() async => accounts;

  // Empty rather than a value stream: a late account update would emit a state
  // of its own and blur which emission a SnackBar came from.
  @override
  Stream<List<Account>> watchAccounts() => const Stream<List<Account>>.empty();
}

class _FakeCategoryRepository extends Fake implements CategoryRepository {
  _FakeCategoryRepository(this.categories);

  final List<Category> categories;

  @override
  Future<List<Category>> getCategories({bool includeSystem = false}) async =>
      categories;

  @override
  Stream<List<Category>> watchCategories({bool includeSystem = false}) =>
      const Stream<List<Category>>.empty();
}

class _FakeCurrencyRepository extends Fake implements CurrencyRepository {
  _FakeCurrencyRepository({this.currencies = const [], this.rates = const []});

  final List<Currency> currencies;
  final List<ExchangeRateDomain> rates;

  @override
  Future<List<Currency>> getCurrencies() async => currencies;

  @override
  Future<List<ExchangeRateDomain>> getExchangeRatesFiltered({
    int limit = 100,
    int offset = 0,
    DateTime? startDate,
    DateTime? endDate,
    String? fromCurrency,
    String? toCurrency,
    List<int>? presets,
    bool sortAscending = false,
  }) async => rates;
}

class _FakeSettingsRepository extends Fake implements SettingsRepository {
  _FakeSettingsRepository(this.mainCurrencyCode);

  final String mainCurrencyCode;

  @override
  Future<Settings?> getSetting(String key) async => key == 'main_currency_code'
      ? Settings(key: key, value: mainCurrencyCode, device: 'test')
      : null;
}

class _FakeAssetRepository extends Fake implements AssetRepository {}

// ---------------------------------------------------------------------------
// Harness
// ---------------------------------------------------------------------------

/// Opens the form on a new transaction.
///
/// [saveFailure] is what the transaction repository throws when Save gets that
/// far; [foreignCurrency] swaps in the dollar account so the exchange-rate
/// section is live, and [rates] is what the rate lookup finds.
Future<AppLocalizations> _pumpForm(
  WidgetTester tester, {
  Object? saveFailure,
  bool foreignCurrency = false,
  List<ExchangeRateDomain> rates = const [],
}) async {
  final account = foreignCurrency ? _dollarAccount : _euroAccount;

  // The screen builds its own bloc out of `sl`, so the container is the only
  // seam a widget test has on it.
  GetIt.I.registerSingleton<TransactionRepository>(
    _FakeTransactionRepository(failure: saveFailure),
  );
  GetIt.I.registerSingleton<AccountRepository>(
    _FakeAccountRepository([account]),
  );
  GetIt.I.registerSingleton<CategoryRepository>(
    _FakeCategoryRepository([_groceries]),
  );
  GetIt.I.registerSingleton<CurrencyRepository>(
    _FakeCurrencyRepository(currencies: const [_euro], rates: rates),
  );
  GetIt.I.registerSingleton<SettingsRepository>(_FakeSettingsRepository('EUR'));
  GetIt.I.registerSingleton<AssetRepository>(_FakeAssetRepository());

  await pumpAppWidget(
    tester,
    const AddEditTransactionScreen(),
    locale: _french,
    surfaceSize: _surface,
    // The screen brings its own Scaffold, which is where the SnackBar lands.
    wrapInScaffold: false,
    aboveApp: (app) => wrapWithBlocs(
      app,
      // EscapeBackHandler reads Settings; the account and category fields read
      // Styles; a successful save would reload Transactions and Accounts.
      settingsBloc: createSettingsBloc(),
      stylesBloc: createStylesBloc(),
      accountsBloc: MockAccountsBloc(),
      transactionsBloc: MockTransactionsBloc(),
    ),
  );
  await tester.pumpAndSettle();

  return loadL10n(_french);
}

Finder _fieldLabelled(String label) =>
    find.widgetWithText(TextFormField, label);

Finder _snackBarText(String text) =>
    find.descendant(of: find.byType(SnackBar), matching: find.text(text));

/// Fills the amount so the form's own validators pass and the bloc gets to run.
Future<void> _enterAmount(
  WidgetTester tester,
  AppLocalizations l10n,
  String amount,
) async {
  await tester.enterText(_fieldLabelled(l10n.amountLabel), amount);
  await tester.pump();
}

Future<void> _tapSave(WidgetTester tester, AppLocalizations l10n) async {
  await tester.tap(find.widgetWithText(FilledButton, l10n.saveButton));
}

/// Taps one of the exchange-rate section's buttons by its label.
///
/// By label rather than by `TextButton`: these are built with
/// `TextButton.icon`, whose widget is a private subclass that `find.byType`
/// does not match.
Future<void> _tapRateButton(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
}

/// Lets a state reach the listener and a SnackBar finish animating in (250ms).
///
/// Deliberately not `pumpAndSettle`: these tests type into text fields, and the
/// caret keeps scheduling frames, so settling is not a state this tree reaches.
Future<void> _showSnackBar(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Runs a showing SnackBar's four-second life out, plus its exit animation.
///
/// Every test has to end this way whether or not it asserts on the result: the
/// binding fails a test that leaves a timer pending.
Future<void> _expireSnackBar(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  tearDown(GetIt.I.reset);

  group('AddEditTransactionScreen validation SnackBar', () {
    testWidgets(
      'a failed save is reported once, and typing on does not queue it again',
      (tester) async {
        final l10n = await _pumpForm(tester, saveFailure: _dbLocked);
        await _enterAmount(tester, l10n, '12');

        await _tapSave(tester, l10n);
        await _showSnackBar(tester);

        expect(find.byType(SnackBar), findsOneWidget);
        expect(
          tester.widget<SnackBar>(find.byType(SnackBar)).backgroundColor,
          Colors.red,
          reason: 'a refused save is an error, and reads as one',
        );

        // The user goes back to the form and edits the description. Every
        // keystroke emits a new state, and every one of those states still
        // carries the validationError of the save that failed.
        for (final typed in ['c', 'co', 'cof']) {
          await tester.enterText(
            _fieldLabelled(l10n.descriptionOptionalLabel),
            typed,
          );
          await tester.pump(const Duration(seconds: 1));
          expect(
            find.byType(SnackBar),
            findsOneWidget,
            reason: 'the one message is on screen, not one message per key',
          );
        }

        // The bar is now ~3.4s old. If it is still the one the failure put up,
        // its four seconds are nearly gone and it leaves on its own. A bar
        // re-shown by the last keystroke would have most of its life ahead of
        // it - which is exactly how the bug looked: a red bar that never went
        // away while the user kept typing.
        await tester.pump(const Duration(seconds: 2));
        await tester.pump(const Duration(seconds: 1));
        expect(
          find.byType(SnackBar),
          findsNothing,
          reason: 'the message outlived the failure it was reporting',
        );

        // And one more keystroke, still on the same unchanged error, must not
        // bring it back from nowhere.
        await tester.enterText(
          _fieldLabelled(l10n.descriptionOptionalLabel),
          'coffee',
        );
        await _showSnackBar(tester);
        expect(
          find.byType(SnackBar),
          findsNothing,
          reason: 'an old error re-announced itself mid-typing',
        );
      },
    );

    testWidgets('a different error after the first one is still shown', (
      tester,
    ) async {
      // Two problems in a row, with no clear in between: `_onUpdatePreset`
      // rejects an unreadable rate before it touches the loading flag, so this
      // second message lands directly on top of the first. Gating on "same
      // message" rather than "any message" is what keeps it visible.
      final l10n = await _pumpForm(
        tester,
        saveFailure: _dbLocked,
        foreignCurrency: true,
        rates: [_preset2],
      );
      await _enterAmount(tester, l10n, '12');

      await _tapSave(tester, l10n);
      await _showSnackBar(tester);
      expect(
        _snackBarText(l10n.importErrorLabel(_dbLockedMessage)),
        findsOneWidget,
      );

      // Emptying the rate field is another state carrying the same error, so
      // it must not disturb the bar that is already up.
      await tester.enterText(
        _fieldLabelled('${l10n.exchangeRateLabel} (USD)'),
        '',
      );
      await _showSnackBar(tester);
      expect(
        _snackBarText(l10n.importErrorLabel(_dbLockedMessage)),
        findsOneWidget,
      );

      await _tapRateButton(tester, l10n.updateButton);
      await _showSnackBar(tester);

      expect(
        _snackBarText(l10n.invalidAmountError),
        findsOneWidget,
        reason: 'a new problem the user has not read yet must be shown',
      );
      expect(
        _snackBarText(l10n.importErrorLabel(_dbLockedMessage)),
        findsNothing,
        reason: 'the stale message should have made way for the new one',
      );

      await _expireSnackBar(tester);
    });

    testWidgets('a known sentinel is translated, not shown in English', (
      tester,
    ) async {
      // The bloc has no localizations, so its five known failures travel as
      // English sentinel strings and the screen looks them up. With no stored
      // rate the field opens empty, so "New preset" has nothing to store and
      // reports 'Please enter a valid number' - which a French user must never
      // see in those words.
      final l10n = await _pumpForm(tester, foreignCurrency: true);

      await _tapRateButton(tester, l10n.newPresetButton);
      await _showSnackBar(tester);

      expect(_snackBarText(l10n.invalidAmountError), findsOneWidget);
      expect(
        find.text('Please enter a valid number'),
        findsNothing,
        reason: 'the raw sentinel reached the user untranslated',
      );

      await _expireSnackBar(tester);
    });

    testWidgets('an unknown message is framed as an error and kept intact', (
      tester,
    ) async {
      // A repository exception is not one of the five sentinels and cannot be
      // translated. Wrapping it in the localized frame is what tells the user
      // they are reading a failure and not a result - and the text itself has
      // to survive, because it is all a bug report will ever have.
      final l10n = await _pumpForm(tester, saveFailure: _dbLocked);
      await _enterAmount(tester, l10n, '12');

      await _tapSave(tester, l10n);
      await _showSnackBar(tester);

      final content = tester.widget<Text>(
        find
            .descendant(of: find.byType(SnackBar), matching: find.byType(Text))
            .first,
      );
      expect(content.data, l10n.importErrorLabel(_dbLockedMessage));
      expect(content.data, contains(_dbLockedMessage));
      expect(
        content.data,
        isNot(_dbLockedMessage),
        reason: 'a bare exception reads as a result, not as a failure',
      );

      await _expireSnackBar(tester);
    });

    testWidgets('the same failure is reported again once the error cleared', (
      tester,
    ) async {
      // Saving clears validationError before it runs, so a second attempt that
      // fails the same way is a new failure - and the user, who is watching to
      // see whether the retry worked, has to be told again.
      final l10n = await _pumpForm(tester, saveFailure: _dbLocked);
      await _enterAmount(tester, l10n, '12');

      await _tapSave(tester, l10n);
      await _showSnackBar(tester);
      expect(
        _snackBarText(l10n.importErrorLabel(_dbLockedMessage)),
        findsOneWidget,
      );

      await _expireSnackBar(tester);
      expect(find.byType(SnackBar), findsNothing);

      await _tapSave(tester, l10n);
      await _showSnackBar(tester);
      expect(
        _snackBarText(l10n.importErrorLabel(_dbLockedMessage)),
        findsOneWidget,
        reason: 'the retry failed silently',
      );

      await _expireSnackBar(tester);
    });
  });
}
