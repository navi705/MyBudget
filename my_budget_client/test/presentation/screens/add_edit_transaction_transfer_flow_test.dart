// Making a transfer on a phone, from the screen the user is already on.
//
// A transfer needs two accounts, and until now naming the second one was
// possible from exactly one place in the app: the accounts screen's per-row
// context menu, which on a touch device is the row's overflow button. Everyone
// who reached the transaction form any other way - the "+" on the transactions
// screen, the dashboard, the hotkey - got a form that could only ever write a
// single-account entry, with no way to say the money was going to another
// account of their own.
//
// The surface here is a phone, because that is where the detour cost the most
// and where the transfer form itself has to fit: two account pickers, an
// amount and Save, all reachable without the layout pushing Save off-screen.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/core/constants/app_constants.dart';
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

/// A phone in portrait, not the tall test surface the other form tests use:
/// the point of these is that the flow works where the screen is small.
const Size _phone = Size(390, 844);

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

final Account _savings = Account(
  id: 'a2',
  name: 'Savings',
  balance: 500,
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

/// Hidden from every picker, which is why the form has to select it itself.
final Category _transferCategory = Category(
  id: 'c-transfer',
  name: AppConstants.systemTransferCategoryName,
  type: CategoryType.transfer,
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
  _FakeAccountRepository(this.accounts);

  final List<Account> accounts;

  @override
  Future<List<Account>> getAccounts() async => accounts;

  @override
  Stream<List<Account>> watchAccounts() => const Stream<List<Account>>.empty();
}

class _FakeCategoryRepository extends Fake implements CategoryRepository {
  @override
  Future<List<Category>> getCategories({bool includeSystem = false}) async =>
      includeSystem ? [_groceries, _transferCategory] : [_groceries];

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

/// Opens the transaction form the way the transactions screen's "+" does: no
/// account named, no mode named.
///
/// Through a real router, because a saved transfer pops the screen - and a pop
/// with no router under it is an exception in the middle of the assertion
/// rather than the flow the user gets.
Future<(AppLocalizations, _FakeTransactionRepository)> _pumpForm(
  WidgetTester tester, {
  required List<Account> accounts,
  double textScale = 1.0,
}) async {
  final transactions = _FakeTransactionRepository();

  GetIt.I.registerSingleton<TransactionRepository>(transactions);
  GetIt.I.registerSingleton<AccountRepository>(
    _FakeAccountRepository(accounts),
  );
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

  setSurfaceSize(tester, _phone);
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

Future<void> _tapMode(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(GetIt.I.reset);

  testWidgets('the form offers a transfer without leaving for the accounts '
      'screen', (tester) async {
    final (l10n, _) = await _pumpForm(tester, accounts: [_wallet, _savings]);

    // The ordinary entry is what the form opens on...
    expect(find.text(l10n.categoryLabel), findsOneWidget);
    expect(find.text(l10n.fromAccountLabel), findsNothing);

    await _tapMode(tester, l10n.transferLabel);

    // ...and the switch is right there on it.
    expect(find.text(l10n.fromAccountLabel), findsOneWidget);
    expect(find.text(l10n.toAccountLabel), findsOneWidget);
  });

  testWidgets('a transfer made that way writes both of its legs', (
    tester,
  ) async {
    final (l10n, transactions) = await _pumpForm(
      tester,
      accounts: [_wallet, _savings],
    );

    await _tapMode(tester, l10n.transferLabel);

    // Two accounts, so the destination is the only one it could be and the
    // user is left with one number to type.
    await tester.enterText(
      find.widgetWithText(TextFormField, l10n.amountSentLabel('EUR')),
      '25',
    );
    await tester.pump();

    // On a phone the button is below the fold, which is the point: it has to
    // be reachable, not already on screen.
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, l10n.saveButton),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, l10n.saveButton));
    await tester.pumpAndSettle();

    expect(
      transactions.added,
      hasLength(2),
      reason:
          'a transfer is the money leaving one account and arriving in '
          'another, so it is two rows or it is nothing',
    );
    final sent = transactions.added.firstWhere((t) => t.amount < 0);
    final received = transactions.added.firstWhere((t) => t.amount > 0);
    expect(sent.accountId, _wallet.id);
    expect(received.accountId, _savings.id);
    expect(sent.amount, -25);
    expect(received.amount, 25);
    // Both legs point at each other, which is what makes editing or deleting
    // one of them reach the other.
    expect(sent.categoryId, _transferCategory.id);
    expect(received.categoryId, _transferCategory.id);
  });

  testWidgets('nothing offers a transfer that has nowhere to go', (
    tester,
  ) async {
    // One account: a transfer would open a form whose second picker is empty
    // and whose required field can never be filled.
    final (l10n, _) = await _pumpForm(tester, accounts: [_wallet]);

    expect(find.text(l10n.transferLabel), findsNothing);
    expect(find.text(l10n.transactionModeLabel), findsNothing);
  });

  testWidgets('the amount already typed survives the switch to a transfer', (
    tester,
  ) async {
    // The mode selector sits above the amount, so the switch is often made
    // after the number is in: a form that clears it teaches the user to fill
    // it in twice.
    final (l10n, _) = await _pumpForm(tester, accounts: [_wallet, _savings]);

    await tester.enterText(
      find.widgetWithText(TextFormField, l10n.amountLabel),
      '25',
    );
    await tester.pump();

    await _tapMode(tester, l10n.transferLabel);

    expect(
      find.widgetWithText(TextFormField, '25'),
      findsOneWidget,
      reason: 'the number typed before the switch is still the number meant',
    );
  });

  testWidgets(
    'a transfer can still be saved with the phone set to large text',
    (tester) async {
      // Two account pickers, an amount, a date and a Save on a 390x844 phone at
      // twice the text size: the form is taller than the screen by a long way,
      // and the only thing that matters is that every step of it can still be
      // reached and the save goes through.
      final (l10n, transactions) = await _pumpForm(
        tester,
        accounts: [_wallet, _savings],
        textScale: 2.0,
      );

      await _tapMode(tester, l10n.transferLabel);

      final amountField = find.widgetWithText(
        TextFormField,
        l10n.amountSentLabel('EUR'),
      );
      await tester.ensureVisible(amountField);
      await tester.pumpAndSettle();
      await tester.enterText(amountField, '25');
      await tester.pump();

      final save = find.widgetWithText(FilledButton, l10n.saveButton);
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(transactions.added, hasLength(2));
    },
  );
}
