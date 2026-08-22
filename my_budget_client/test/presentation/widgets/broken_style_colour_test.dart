// An unreadable colour costs one swatch, not the whole screen.
//
// `styles.color_hex` is a plain text column: nothing in the schema, the wire
// format or the CSV importer constrains it, so a peer on another build or an
// import column pointed at the wrong field can leave any string there. Seven
// screens each parsed it themselves and six ended in a bare `int.parse` —
// which throws `FormatException` from inside `build()`, taking out the entire
// list the style appeared in. Three of those had no length check either, so a
// style whose hex was simply blank threw on the same path.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/icon_type.dart';
import 'package:my_budget_client/domain/entities/style.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/entities/transaction_category.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';
import 'package:my_budget_client/presentation/widgets/transaction_list.dart';

import '../test_app.dart';

final _account = Account(
  id: 'a1',
  name: 'Checking',
  balance: 100,
  currencyCode: 'EUR',
  currencyDesignationId: 'd1',
  accountTypeId: 't1',
  creationDate: DateTime(2024, 1, 1),
);

TransactionCategory _entry(String colorHex) => TransactionCategory(
  transaction: Transaction(
    id: 't1',
    description: 'Bread',
    amount: -12,
    date: DateTime(2024, 1, 1),
    accountId: 'a1',
    categoryId: 'c1',
    currencyCode: 'EUR',
  ),
  style: Style(
    id: 's1',
    name: 'Default',
    iconName: 'help_outline',
    colorHex: colorHex,
    iconType: IconType.material,
  ),
  category: Category(id: 'c1', name: 'Groceries'),
);

Future<void> _pumpList(WidgetTester tester, String colorHex) async {
  setSurfaceSize(tester, const Size(900, 900));

  final accountsBloc = MockAccountsBloc();
  whenListen(
    accountsBloc,
    const Stream<AccountsState>.empty(),
    initialState: AccountsLoadSuccess(
      accounts: [_account],
      accountTypes: const [],
      hasReachedMax: true,
      totalCount: 1,
      exchangeRates: const [],
      activeDate: DateTime(2024, 1, 1),
    ),
  );

  final transactionsBloc = MockTransactionsBloc();
  whenListen(
    transactionsBloc,
    const Stream<TransactionsState>.empty(),
    initialState: TransactionsState(
      status: TransactionStatus.success,
      transactions: [_entry(colorHex)],
      hasMoreDown: false,
      totalCount: 1,
      activeDate: DateTime(2024, 1, 1),
    ),
  );

  final router = GoRouter(
    initialLocation: '/list',
    routes: [
      GoRoute(
        path: '/list',
        builder: (_, _) => const Scaffold(body: TransactionList()),
      ),
      GoRoute(
        path: AppRoutes.addEditTransaction,
        builder: (_, _) => const Text('form'),
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
      accountsBloc: accountsBloc,
      transactionsBloc: transactionsBloc,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  // Each of these reached `int.parse` on the old path: the first two got past
  // the length check that two of the copies had, and the last three got past
  // the copies that had no check at all.
  for (final hex in const [
    'ZZZZZZZZ',
    '#notahex',
    '',
    '#',
    '#FFF',
    '-1234567',
  ]) {
    testWidgets('the list still draws its row when the style hex is "$hex"', (
      tester,
    ) async {
      await _pumpList(tester, hex);

      expect(tester.takeException(), isNull);
      expect(find.text('Bread'), findsOneWidget);
    });
  }

  testWidgets('a readable hex is still the colour it names', (tester) async {
    // The fallback must not have swallowed the working case with the broken
    // ones: this is the assertion that keeps the guard from being "always grey".
    await _pumpList(tester, '#FF5733');

    // The row paints the icon white on a 15%-alpha chip of the style's own
    // colour, so the colour to look for is the chip's, not the glyph's.
    final chips = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => (c.decoration as BoxDecoration?)?.color)
        .toList();
    expect(
      chips,
      contains(const Color(0xFFFF5733).withAlpha((255 * 0.15).round())),
      reason: 'the chip has to keep the colour the style names, '
          'and none of $chips is it',
    );
  });
}
