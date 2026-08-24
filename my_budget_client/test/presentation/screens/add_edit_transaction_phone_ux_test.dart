// Writing down an ordinary expense - the thing this app is opened for, several
// times a day, usually one-handed on a phone.
//
// The transfer flow has its own file; this one is about the everyday entry: an
// amount, a category, Save. It runs on a 390x844 phone and again at twice the
// text size, because that setting is turned on once by someone who cannot read
// the default and every screen after it either fits or paints the overflow
// stripe over the number being entered. An overflow is a failure on its own
// here - the framework reports it - so what is asserted is the part that is
// left: that every step is still reachable and the save goes through.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
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

/// A phone in portrait: the narrowest surface the form is filled in on.
const Size _phone = Size(390, 844);

/// A desktop window, where the same form is filled in with a keyboard.
const Size _desktop = Size(1440, 900);

const Currency _euro = Currency(
  name: 'Euro',
  code: 'EUR',
  languageCode: 'en',
  type: TypeCurrency.currency,
);

final Account _wallet = Account(
  id: 'a1',
  name: 'Wallet',
  balance: 100,
  currencyCode: 'EUR',
  currencyDesignationId: 'd1',
  accountTypeId: 't1',
  creationDate: DateTime(2024, 1, 1),
);

final Category _groceries = Category(
  id: 'c1',
  name: 'Groceries',
  type: CategoryType.expense,
);

class _FakeTransactionRepository extends Fake implements TransactionRepository {
  final added = <Transaction>[];

  @override
  Future<void> addTransaction(Transaction transaction) async =>
      added.add(transaction);

  @override
  Future<void> updateTransaction(Transaction transaction) async {}

  @override
  Future<Transaction?> getTransactionById(String id) async => null;

  @override
  Stream<void> watchTransactionChanges() => const Stream.empty();
}

class _FakeAccountRepository extends Fake implements AccountRepository {
  @override
  Future<List<Account>> getAccounts() async => [_wallet];

  @override
  Stream<List<Account>> watchAccounts() => const Stream<List<Account>>.empty();
}

class _FakeCategoryRepository extends Fake implements CategoryRepository {
  @override
  Future<List<Category>> getCategories({bool includeSystem = false}) async => [
    _groceries,
  ];

  @override
  Stream<List<Category>> watchCategories({bool includeSystem = false}) =>
      const Stream<List<Category>>.empty();
}

class _FakeCurrencyRepository extends Fake implements CurrencyRepository {
  @override
  Future<List<Currency>> getCurrencies() async => const [_euro];

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

/// Opens the form the way the "+" on the transactions screen does.
Future<(AppLocalizations, _FakeTransactionRepository)> _pumpForm(
  WidgetTester tester, {
  Size surface = _phone,
  double textScale = 1.0,
}) async {
  final transactions = _FakeTransactionRepository();

  GetIt.I.registerSingleton<TransactionRepository>(transactions);
  GetIt.I.registerSingleton<AccountRepository>(_FakeAccountRepository());
  GetIt.I.registerSingleton<CategoryRepository>(_FakeCategoryRepository());
  GetIt.I.registerSingleton<CurrencyRepository>(_FakeCurrencyRepository());
  GetIt.I.registerSingleton<SettingsRepository>(_FakeSettingsRepository());
  GetIt.I.registerSingleton<AssetRepository>(_FakeAssetRepository());

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('list'))),
        routes: [
          GoRoute(
            path: 'transaction',
            builder: (context, state) => const AddEditTransactionScreen(),
          ),
        ],
      ),
    ],
  );

  setSurfaceSize(tester, surface);
  await tester.pumpWidget(
    wrapWithBlocs(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery.withClampedTextScaling(
          minScaleFactor: textScale,
          maxScaleFactor: textScale,
          child: child!,
        ),
      ),
      settingsBloc: createSettingsBloc(),
      stylesBloc: createStylesBloc(),
      accountsBloc: MockAccountsBloc(),
      transactionsBloc: MockTransactionsBloc(),
    ),
  );
  addTearDown(router.dispose);

  router.push('/transaction');
  await tester.pumpAndSettle();

  return (await loadL10n(), transactions);
}

/// Picks the only category on offer.
Future<void> _pickCategory(WidgetTester tester) async {
  final field = find.byKey(const Key('categoryPickerField'));
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.tap(find.text(_groceries.name).last);
  await tester.pumpAndSettle();
}

/// Types [amount] into the amount field, scrolling to it first.
Future<void> _enterAmount(
  WidgetTester tester,
  AppLocalizations l10n,
  String amount,
) async {
  final field = find.widgetWithText(TextFormField, l10n.amountLabel);
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.enterText(field, amount);
  await tester.pump();
}

Future<void> _save(WidgetTester tester, AppLocalizations l10n) async {
  final save = find.widgetWithText(FilledButton, l10n.saveButton);
  await tester.ensureVisible(save);
  await tester.pumpAndSettle();
  await tester.tap(save);
  await tester.pumpAndSettle();
}

void main() {
  tearDown(GetIt.I.reset);

  testWidgets('the form opens with the cursor already in the amount', (
    tester,
  ) async {
    // The first thing a person has to type is the number, and a form that
    // opens with nothing focused costs a tap before every single entry.
    final (l10n, _) = await _pumpForm(tester);

    final amount = find.descendant(
      of: find.widgetWithText(TextFormField, l10n.amountLabel),
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(amount).focusNode.hasFocus, isTrue);
  });

  testWidgets('an expense can be written down on a phone', (tester) async {
    final (l10n, transactions) = await _pumpForm(tester);

    await _enterAmount(tester, l10n, '12.5');
    await _pickCategory(tester);
    await _save(tester, l10n);

    expect(transactions.added, hasLength(1));
    expect(transactions.added.single.amount.abs(), 12.5);
    expect(transactions.added.single.accountId, _wallet.id);
  });

  testWidgets('the same entry works with the phone set to large text', (
    tester,
  ) async {
    // At 2x the form is far taller than the screen: the amount, the category
    // picker and Save are each behind a scroll, and the category dialog has to
    // fit as well.
    final (l10n, transactions) = await _pumpForm(tester, textScale: 2.0);

    await _enterAmount(tester, l10n, '12.5');
    await _pickCategory(tester);
    await _save(tester, l10n);

    expect(
      transactions.added,
      hasLength(1),
      reason: 'large text is a setting, not a reason to be unable to save',
    );
  });

  testWidgets('the same entry works in a desktop window', (tester) async {
    // The other end of the range: nothing here needs scrolling, and the form
    // must not stretch its fields across a 1440px window either.
    final (l10n, transactions) = await _pumpForm(tester, surface: _desktop);

    await _enterAmount(tester, l10n, '12.5');

    // Measured before saving, because saving pops the form off the stack.
    final amountWidth = tester
        .getSize(find.widgetWithText(TextFormField, l10n.amountLabel))
        .width;
    expect(
      amountWidth,
      lessThanOrEqualTo(700),
      reason:
          'a field a thousand pixels wide puts the label and the value it '
          'labels at opposite ends of the screen',
    );

    await _pickCategory(tester);
    await _save(tester, l10n);

    expect(transactions.added, hasLength(1));
  });
}
