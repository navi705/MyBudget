// Money, and the form that enters it.
//
// Five defects met on these two widgets, and every one was something the user
// could read off the screen:
//
//   * the transaction form printed `2026-08-21` - a raw ISO date - in a
//     ten-locale app;
//   * the list's day headers were spelled with a hardcoded `EEE, MMM d, yyyy`,
//     an English skeleton, in those same ten locales;
//   * money was `Colors.green` / `Colors.red`, chosen outside the theme whose
//     seed colour the user picks, and carried by colour alone;
//   * the amount field took its colour from a control three rows further down,
//     so the number went red with nothing on screen saying why;
//   * and the three pickers were `GestureDetector` + `AbsorbPointer`, which
//     left no way at all to open them from a keyboard - on Windows desktop the
//     keyboard path through the app's primary task stopped dead at Account.
//
// The form tests drive the real `AddEditTransactionBloc` through fake
// repositories in the `sl` container the screen builds it from, and the list
// tests render the real `TransactionList`, so what is asserted on is what the
// product produces. French and Arabic throughout: an English date or an
// untranslated pattern is exactly what these assertions look for.
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/app.dart';
import 'package:my_budget_client/core/theme/money_colors.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';
import 'package:my_budget_client/domain/entities/icon_type.dart';
import 'package:my_budget_client/domain/entities/settings.dart';
import 'package:my_budget_client/domain/entities/style.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/entities/transaction_category.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/domain/repositories/asset_repository.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';
import 'package:my_budget_client/presentation/screens/add_edit_transaction_screen.dart';
import 'package:my_budget_client/presentation/widgets/single_select_dialog.dart';
import 'package:my_budget_client/presentation/widgets/transaction_list.dart';

import 'test_app.dart';

// ---------------------------------------------------------------------------
// The characters the money assertions are actually about
// ---------------------------------------------------------------------------

/// U+00A0 NO-BREAK SPACE - the thousands separator, and the joiner between an
/// amount and its currency. Bidi class CS, so it cannot split the number run
/// the way the U+0020 it replaced did.
const String nbsp = '\u00A0';

/// U+2066 LEFT-TO-RIGHT ISOLATE / U+2069 POP DIRECTIONAL ISOLATE.
const String lri = '\u2066';
const String pdi = '\u2069';

/// U+2212 MINUS SIGN, and plus - the direction glyphs, which survive greyscale
/// and red-green colour blindness where the colour alone did not.
const String minus = '\u2212';
const String plus = '+';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

const Locale french = Locale('fr');
const Locale arabic = Locale('ar');

/// A desktop window. The pickers are a Windows-desktop keyboard problem and the
/// saving scrim is a wide-window problem, so both are judged at a width where
/// the 600dp form column is visibly narrower than the screen.
const Size desktop = Size(1440, 900);

/// Tall enough for the whole form - Save included - to be laid out at once.
const Size tallForm = Size(600, 1400);

final DateTime probeDate = DateTime(2026, 8, 21);

const Currency euro = Currency(
  name: 'Euro',
  code: 'EUR',
  languageCode: 'fr',
  type: TypeCurrency.currency,
);

final Account wallet = Account(
  id: 'a1',
  name: 'Wallet',
  balance: 100,
  currencyCode: 'EUR',
  currencyDesignationId: 'd1',
  accountTypeId: 't1',
  creationDate: DateTime(2024, 1, 1),
);

/// A second cash account, so a transfer has somewhere to go and the linked
/// account picker offers a choice rather than an empty list.
final Account savings = Account(
  id: 'a2',
  name: 'Savings',
  balance: 500,
  currencyCode: 'EUR',
  currencyDesignationId: 'd1',
  accountTypeId: 't1',
  creationDate: DateTime(2024, 1, 1),
);

final Category groceries = Category(id: 'c1', name: 'Groceries');
final Category salary = Category(
  id: 'c2',
  name: 'Salary',
  type: CategoryType.income,
);

final Style plainStyle = Style(
  id: 's1',
  name: 'Default',
  iconName: 'help_outline',
  colorHex: '#808080',
  iconType: IconType.material,
);

final Transaction storedTransaction = Transaction(
  id: 't1',
  description: 'Bread',
  amount: -12,
  date: probeDate,
  accountId: 'a1',
  categoryId: 'c1',
  currencyCode: 'EUR',
);

/// The money line the list paints for an amount: glyph, grouped digits and
/// currency, all inside one isolate.
String moneyLine(String glyph, String digits) =>
    '$lri$glyph$digits${nbsp}EUR$pdi';

/// What the row for -1234.56 has to read.
final String outflowLine = moneyLine(minus, '1${nbsp}234.56');

/// What the day header has to read for a positive daily total. Deliberately a
/// different figure from the row, so neither assertion can pick up the other's
/// `Text`.
final String inflowLine = moneyLine(plus, '9${nbsp}876.54');

const double dailyTotal = 9876.54;

// ---------------------------------------------------------------------------
// Repositories - only the calls this screen makes, so anything else fails
// loudly rather than answering with a default
// ---------------------------------------------------------------------------

class _FakeTransactionRepository extends Fake implements TransactionRepository {
  /// Held open so a test can look at the screen mid-save. Completing it makes
  /// the save *fail*, which is the one ending that needs no router to pop.
  final Completer<void> saveGate = Completer<void>();
  bool hold = false;

  @override
  Future<void> addTransaction(Transaction transaction) async {
    if (hold) {
      await saveGate.future;
      throw Exception('cancelled');
    }
  }
}

class _FakeAccountRepository extends Fake implements AccountRepository {
  _FakeAccountRepository(this.accounts);

  final List<Account> accounts;

  @override
  Future<List<Account>> getAccounts() async => accounts;

  // Empty rather than a value stream: a late account update would emit a state
  // of its own and blur which frame an assertion is reading.
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
  @override
  Future<List<Currency>> getCurrencies() async => const [euro];

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
  }) async => const [];
}

class _FakeSettingsRepository extends Fake implements SettingsRepository {
  @override
  Future<Settings?> getSetting(String key) async => key == 'main_currency_code'
      ? Settings(key: key, value: 'EUR', device: 'test')
      : null;
}

class _FakeAssetRepository extends Fake implements AssetRepository {}

// ---------------------------------------------------------------------------
// Harness
// ---------------------------------------------------------------------------

// ignore: library_private_types_in_public_api
late _FakeTransactionRepository transactionRepository;

/// Opens the transaction form on [transaction] (null for a new one).
///
/// [categories] decides which direction the form opens in: the bloc selects the
/// first category for a new transaction, so putting an income category first is
/// how a test asks for an inflow without having to drive the picker.
Future<AppLocalizations> pumpForm(
  WidgetTester tester, {
  Transaction? transaction,
  bool isTransfer = false,
  List<Category> categories = const [],
  Size surfaceSize = tallForm,
  Locale locale = french,
}) async {
  transactionRepository = _FakeTransactionRepository();

  // The screen builds its own bloc out of `sl`, so the container is the only
  // seam a widget test has on it.
  GetIt.I.registerSingleton<TransactionRepository>(transactionRepository);
  GetIt.I.registerSingleton<AccountRepository>(
    _FakeAccountRepository([wallet, savings]),
  );
  GetIt.I.registerSingleton<CategoryRepository>(
    _FakeCategoryRepository(
      categories.isEmpty ? <Category>[groceries] : categories,
    ),
  );
  GetIt.I.registerSingleton<CurrencyRepository>(_FakeCurrencyRepository());
  GetIt.I.registerSingleton<SettingsRepository>(_FakeSettingsRepository());
  GetIt.I.registerSingleton<AssetRepository>(_FakeAssetRepository());

  await pumpAppWidget(
    tester,
    AddEditTransactionScreen(transaction: transaction, isTransfer: isTransfer),
    locale: locale,
    surfaceSize: surfaceSize,
    // The screen brings its own Scaffold, which is where the SnackBar lands.
    wrapInScaffold: false,
    aboveApp: (app) => wrapWithBlocs(
      app,
      // EscapeBackHandler reads Settings; the account and category fields read
      // Styles; a save would reload Transactions and Accounts.
      settingsBloc: createSettingsBloc(),
      stylesBloc: createStylesBloc(),
      currencyBloc: createCurrencyBloc(),
      accountsBloc: MockAccountsBloc(),
      transactionsBloc: MockTransactionsBloc(),
    ),
  );
  await tester.pumpAndSettle();

  return loadL10n(locale);
}

/// The `TextField` that the `TextFormField` labelled [label] decorates - the
/// widget carrying the style and decoration these assertions are about.
TextField fieldLabelled(WidgetTester tester, String label) => tester.widget(
  find.descendant(
    of: find.widgetWithText(TextFormField, label),
    matching: find.byType(TextField),
  ),
);

// ---------------------------------------------------------------------------
// Keyboard traversal
// ---------------------------------------------------------------------------

const Key accountPicker = Key('accountPickerField');
const Key categoryPicker = Key('categoryPickerField');
const Key linkedAccountPicker = Key('linkedAccountPickerField');

/// True when [key] sits on an ancestor of [context] - i.e. the thing holding
/// focus lives inside the picker marked with that key.
bool insideKeyed(BuildContext context, Key key) {
  var found = false;
  context.visitAncestorElements((element) {
    if (element.widget.key == key) {
      found = true;
      return false;
    }
    return true;
  });
  return found;
}

/// Which of [keys] currently holds focus, if any.
Key? focusedPicker(Set<Key> keys) {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null) return null;
  for (final key in keys) {
    if (insideKeyed(context, key)) return key;
  }
  return null;
}

/// Presses Tab until every one of [keys] has held focus, or [times] is spent.
///
/// Traversal *order* is not what is pinned here - only reachability, which is
/// what `AbsorbPointer` took away.
Future<Set<Key>> tabThrough(
  WidgetTester tester,
  Set<Key> keys, {
  int times = 40,
}) async {
  final reached = <Key>{};
  for (var i = 0; i < times && reached.length < keys.length; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final key = focusedPicker(keys);
    if (key != null) reached.add(key);
  }
  return reached;
}

// ---------------------------------------------------------------------------
// The transaction list, rendered for real
// ---------------------------------------------------------------------------

TransactionCategory listEntry(double amount) => TransactionCategory(
  transaction: Transaction(
    id: 't1',
    description: 'Bread',
    amount: amount,
    date: probeDate,
    accountId: 'a1',
    categoryId: 'c1',
    currencyCode: 'EUR',
  ),
  style: plainStyle,
  category: groceries,
);

AccountsBloc listAccountsBloc() {
  final bloc = MockAccountsBloc();
  whenListen(
    bloc,
    const Stream<AccountsState>.empty(),
    initialState: AccountsLoadSuccess(
      accounts: [wallet],
      accountTypes: const [],
      hasReachedMax: true,
      totalCount: 1,
      exchangeRates: const [],
      activeDate: probeDate,
    ),
  );
  return bloc;
}

/// One day holding one transaction, with a daily total of its own.
TransactionsBloc listTransactionsBloc(double amount) {
  final bloc = MockTransactionsBloc();
  whenListen(
    bloc,
    const Stream<TransactionsState>.empty(),
    initialState: TransactionsState(
      status: TransactionStatus.success,
      transactions: [listEntry(amount)],
      dailyTotals: {DateTime(2026, 8, 21): dailyTotal},
      mainCurrencyCode: 'EUR',
      hasMoreDown: false,
      totalCount: 1,
      activeDate: probeDate,
    ),
  );
  return bloc;
}

Future<void> pumpList(
  WidgetTester tester, {
  required double amount,
  Locale locale = french,
  Size surfaceSize = const Size(900, 900),
}) async {
  setSurfaceSize(tester, surfaceSize);

  final router = GoRouter(
    initialLocation: '/list',
    routes: [
      GoRoute(
        // The list has no Scaffold of its own, and its dialogs need one.
        path: '/list',
        builder: (_, _) => const Scaffold(body: TransactionList()),
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
      ),
      settingsBloc: createSettingsBloc(),
      currencyBloc: createCurrencyBloc(),
      stylesBloc: createStylesBloc(),
      accountsBloc: listAccountsBloc(),
      transactionsBloc: listTransactionsBloc(amount),
    ),
  );
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------

void main() {
  // Without the CLDR tables loaded, every locale-qualified DateFormat falls
  // back to en_US - which would make the locale assertions below pass for the
  // wrong reason, and throw outright for `ar`.
  setUpAll(initializeAppDateFormatting);

  tearDown(GetIt.I.reset);

  // =========================================================================
  group('the form states the date in the reader\'s locale', () {
    testWidgets('not as a raw ISO date', (tester) async {
      final l10n = await pumpForm(tester, transaction: storedTransaction);

      final shortDate = DateFormat.yMd('fr').format(probeDate);
      expect(find.text('${l10n.dateLabel}: $shortDate'), findsOneWidget);
      expect(
        find.textContaining('2026-08-21'),
        findsNothing,
        reason: 'a machine date reached the user',
      );
    });

    testWidgets('and reads differently in a different locale', (tester) async {
      // Not a tautology about `DateFormat`: what is pinned is that the *same
      // instant* reads differently in two languages. A hardcoded pattern -
      // which is what this screen had - gives both locales the same answer.
      final l10n = await pumpForm(
        tester,
        transaction: storedTransaction,
        locale: arabic,
      );

      final arabicDate = DateFormat.yMd('ar').format(probeDate);
      expect(arabicDate, isNot(DateFormat.yMd('fr').format(probeDate)));
      expect(find.text('${l10n.dateLabel}: $arabicDate'), findsOneWidget);
    });
  });

  // =========================================================================
  group('the amount field says which way the money is going', () {
    testWidgets('an expense category puts a minus against the digits', (
      tester,
    ) async {
      final l10n = await pumpForm(tester, categories: [groceries]);

      await tester.enterText(
        find.widgetWithText(TextFormField, l10n.amountLabel),
        '1234.56',
      );
      await tester.pump();

      final amount = fieldLabelled(tester, l10n.amountLabel);
      expect(
        amount.decoration?.prefixText,
        minus,
        reason:
            'the direction has to be readable at the field, not three rows '
            'down at the category picker',
      );
      expect(
        amount.style?.color,
        MoneyColors.forBrightness(Brightness.light).outflow,
        reason: 'money colour is a theme token, not Colors.red',
      );
    });

    testWidgets('an income category flips both the glyph and the colour', (
      tester,
    ) async {
      // The bloc selects the first category for a new transaction.
      final l10n = await pumpForm(tester, categories: [salary, groceries]);

      await tester.enterText(
        find.widgetWithText(TextFormField, l10n.amountLabel),
        '1234.56',
      );
      await tester.pump();

      final amount = fieldLabelled(tester, l10n.amountLabel);
      expect(amount.decoration?.prefixText, plus);
      expect(
        amount.style?.color,
        MoneyColors.forBrightness(Brightness.light).inflow,
      );
    });

    testWidgets('a transfer claims no direction at all', (tester) async {
      // Both legs of a transfer are the user's own money and neither is income
      // or expense, so the old "not income, therefore red" was a claim the form
      // had no basis for.
      final l10n = await pumpForm(tester, isTransfer: true);

      final amount = fieldLabelled(tester, l10n.amountLabel);
      expect(amount.decoration?.prefixText, isNull);
      expect(
        amount.style?.color,
        MoneyColors.forBrightness(Brightness.light).neutral,
      );
    });
  });

  // =========================================================================
  group('the pickers are reachable from the keyboard', () {
    testWidgets('account and category both take focus', (tester) async {
      await pumpForm(tester, categories: [groceries], surfaceSize: desktop);

      expect(
        await tabThrough(tester, {accountPicker, categoryPicker}),
        {accountPicker, categoryPicker},
        reason: 'AbsorbPointer left these with no keyboard action at all',
      );
    });

    testWidgets('so does the linked account picker, in transfer mode', (
      tester,
    ) async {
      await pumpForm(tester, isTransfer: true, surfaceSize: desktop);

      expect(await tabThrough(tester, {accountPicker, linkedAccountPicker}), {
        accountPicker,
        linkedAccountPicker,
      });
    });

    testWidgets('and Enter on a focused picker opens it', (tester) async {
      // Focusable but inert would be no better than unreachable: the point is
      // finishing the task without reaching for the mouse.
      final l10n = await pumpForm(
        tester,
        categories: [groceries],
        surfaceSize: desktop,
      );

      expect(
        await tabThrough(tester, {accountPicker}),
        {accountPicker},
        reason: 'Tab never reached the account picker',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.text(l10n.selectAccountTitle), findsOneWidget);

      // Close it, so the test does not end with a route still on the stack.
      await tester.tap(
        find.descendant(
          of: find.byType(SingleSelectDialog<Account>),
          matching: find.text(wallet.name),
        ),
      );
      await tester.pumpAndSettle();
    });
  });

  // =========================================================================
  group('the saving scrim', () {
    testWidgets('covers the window, not the 600dp form column', (tester) async {
      final l10n = await pumpForm(
        tester,
        categories: [groceries],
        surfaceSize: desktop,
      );
      transactionRepository.hold = true;

      await tester.enterText(
        find.widgetWithText(TextFormField, l10n.amountLabel),
        '12',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, l10n.saveButton));

      // Not pumpAndSettle: the progress indicator never stops animating.
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      final scrim = find.byWidgetPredicate(
        (widget) =>
            widget is Container && widget.color == Colors.black.withAlpha(128),
      );
      expect(scrim, findsOneWidget);
      expect(
        tester.getSize(scrim).width,
        desktop.width,
        reason:
            'nested inside the ConstrainedBox the scrim dimmed 600px and '
            'left the other 840px lit and live while the save was in flight',
      );

      // Let the save fail so nothing is left in flight, then run the resulting
      // SnackBar out: the binding fails a test that ends with a pending timer.
      transactionRepository.saveGate.complete();
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 1));
    });
  });

  // =========================================================================
  group('the transaction list', () {
    testWidgets('dates its day headers in the locale, not in English', (
      tester,
    ) async {
      await pumpList(tester, amount: -1234.56);

      expect(
        find.text(DateFormat.yMMMEd('fr').format(probeDate)),
        findsOneWidget,
      );
      expect(
        find.text(DateFormat('EEE, MMM d, yyyy', 'en_US').format(probeDate)),
        findsNothing,
        reason:
            'the header was spelled with an English skeleton in all ten '
            'locales',
      );
    });

    testWidgets('signs and colours a row and its day total from the theme', (
      tester,
    ) async {
      await pumpList(tester, amount: -1234.56);

      final colors = MoneyColors.forBrightness(Brightness.light);

      expect(find.text(outflowLine), findsOneWidget);
      expect(
        tester.widget<Text>(find.text(outflowLine)).style?.color,
        colors.outflow,
      );

      expect(find.text(inflowLine), findsOneWidget);
      expect(
        tester.widget<Text>(find.text(inflowLine)).style?.color,
        colors.inflow,
      );
    });

    testWidgets('keeps the digit groups in order in Arabic', (tester) async {
      // The P0: `1 234.56` was painted `234.56 1` under an RTL paragraph, so
      // the app stated a number it did not hold.
      await pumpList(tester, amount: -1234.56, locale: arabic);

      final paragraph = tester.renderObject<RenderParagraph>(
        find.text(outflowLine),
      );

      Rect boxOf(int start, int end) => paragraph
          .getBoxesForSelection(
            TextSelection(baseOffset: start, extentOffset: end),
          )
          .map((box) => box.toRect())
          .reduce((a, b) => a.expandToInclude(b));

      // The thousands digit, then the rest of the number after the separator.
      final thousands = outflowLine.indexOf('1');
      final leading = boxOf(thousands, thousands + 1);
      final remainder = boxOf(thousands + 2, thousands + 8);

      expect(
        leading.left,
        lessThan(remainder.left),
        reason: 'the 1 of "1 234.56" has to be painted left of the 234.56',
      );

      // And the amount stays in front of its currency code, which is what the
      // isolate is for: groups intact is not enough on its own.
      final code = outflowLine.indexOf('EUR');
      expect(leading.left, lessThan(boxOf(code, code + 3).left));
    });
  });
}
