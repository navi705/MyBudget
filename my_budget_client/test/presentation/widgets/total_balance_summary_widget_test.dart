// What the summary card adds up, and when it bothers to add it up at all.
//
// Both of this widget's `ExpansionTile`s open collapsed, and an `ExpansionTile`
// builds the `children` list its caller hands it whether or not it will show
// it - so the accounts screen used to run ten `totalBalanceFor` walks of every
// account, per currency, per build, for pixels nobody had asked to see. The
// children are now built on first expansion instead, and every figure comes
// from a cache keyed on the pair of bloc states behind it.
//
// That is exactly the change that can quietly alter a number, so this file
// pins the numbers rather than the mechanism: the same totals, in the same
// currencies, once the cards are open.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/utils/money_formatter.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency_converter/currency_converter_bloc.dart';
import 'package:my_budget_client/presentation/widgets/total_balance_summary_widget.dart';

import '../test_app.dart';

final _date = DateTime(2024, 1, 15);

Currency _currency(String code) =>
    Currency(name: code, code: code, languageCode: 'en', type: TypeCurrency.currency);

Account _account({
  required String id,
  required String currencyCode,
  required double balance,
}) => Account(
  id: id,
  name: id,
  balance: balance,
  currencyCode: currencyCode,
  currencyDesignationId: 'd1',
  accountTypeId: 't1',
  creationDate: DateTime(2024, 1, 1),
);

/// 100 EUR in one account, 11 700 RSD in another, priced at 117 RSD per EUR:
/// 200 EUR of net worth, and a breakdown of 100 EUR beside 11 700 RSD.
final _accounts = [
  _account(id: 'eur', currencyCode: 'EUR', balance: 100),
  _account(id: 'rsd', currencyCode: 'RSD', balance: 11700),
];

AccountsLoadSuccess _accountsState({
  List<Account>? accounts,
  Map<String, double>? previousPeriodBalances,
}) => AccountsLoadSuccess(
  accounts: accounts ?? _accounts,
  accountTypes: const [],
  hasReachedMax: true,
  totalCount: (accounts ?? _accounts).length,
  exchangeRates: const [],
  activeDate: _date,
  previousPeriodBalances: previousPeriodBalances ?? const {},
);

CurrencyConverterLoadSuccess _converterState() => CurrencyConverterLoadSuccess(
  allCurrencies: [_currency('EUR'), _currency('RSD')],
  exchangeRates: [
    ExchangeRateDomain(
      fromCurrencyCode: 'EUR',
      toCurrencyCode: 'RSD',
      preset: 1,
      rate: 117.0,
      date: _date,
    ),
  ],
  selectedCurrencies: [_currency('EUR')],
  baseCurrencyCode: 'EUR',
);

/// The rendered amount for [value] in [code], exactly as the card writes it.
///
/// Built through [MoneyFormatter] rather than typed out: the group separator is
/// a no-break space and the decimals are per-currency, so a literal would pin
/// the formatter's spelling instead of the total.
String _amount(double value, String code) =>
    '${MoneyFormatter.format(value, code)} $code';

Future<void> _pumpSummary(
  WidgetTester tester, {
  AccountsLoadSuccess? accountsState,
}) async {
  await pumpAppWidget(
    tester,
    SingleChildScrollView(
      child: TotalBalanceSummaryWidget(
        accountsState: accountsState ?? _accountsState(),
        converterState: _converterState(),
      ),
    ),
    surfaceSize: const Size(1000, 1200),
    aboveApp: (app) => wrapWithBlocs(app, settingsBloc: createSettingsBloc()),
  );
  await tester.pumpAndSettle();
}

/// Opens the card titled [title] and settles its expansion animation.
Future<void> _expand(WidgetTester tester, String title) async {
  await tester.tap(find.text(title));
  await tester.pumpAndSettle();
}

void main() {
  group('TotalBalanceSummaryWidget', () {
    testWidgets('shows nothing until a card is opened', (tester) async {
      await _pumpSummary(tester);
      final l10n = await loadL10n();

      // Both titles are there; neither card's contents are, which is the whole
      // point - the figures below cost ten walks of every account to produce.
      expect(find.text(l10n.totalNetWorth), findsOneWidget);
      expect(find.text(l10n.currencyBreakdown), findsOneWidget);
      expect(find.text(l10n.metricBalance), findsNothing);
      expect(find.textContaining(_amount(200, 'EUR')), findsNothing);
    });

    testWidgets('totals every account into the selected currency once the net '
        'worth card is open', (tester) async {
      await _pumpSummary(tester);
      final l10n = await loadL10n();

      await _expand(tester, l10n.totalNetWorth);

      // 100 EUR + 11 700 RSD at 117 RSD/EUR.
      expect(find.textContaining(_amount(200, 'EUR')), findsOneWidget);
    });

    testWidgets('prices each currency in itself in the breakdown card', (
      tester,
    ) async {
      await _pumpSummary(tester);
      final l10n = await loadL10n();

      await _expand(tester, l10n.currencyBreakdown);

      // The breakdown asks a different question of the same code than the net
      // worth card does - only the accounts already in that currency - so the
      // two must not share a cache entry. 100 EUR here, not 200.
      expect(find.textContaining(_amount(100, 'EUR')), findsOneWidget);
      expect(find.textContaining(_amount(11700, 'RSD')), findsOneWidget);
    });

    testWidgets('keeps the change figure against the previous period', (
      tester,
    ) async {
      await _pumpSummary(
        tester,
        accountsState: _accountsState(
          // 50 EUR last period, nothing in the RSD account: 200 EUR now
          // against 50 then.
          previousPeriodBalances: const {'eur': 50.0},
        ),
      );
      final l10n = await loadL10n();

      await _expand(tester, l10n.totalNetWorth);

      expect(find.textContaining(_amount(200, 'EUR')), findsOneWidget);
      expect(find.textContaining('+150.00 EUR (+300.00%)'), findsOneWidget);
    });

    // The cards are built once per pair of bloc states and looked up after
    // that, so a rebuild driven by anything else must still show the same
    // numbers - not a stale set, and not an empty one.
    testWidgets('shows the same totals after a rebuild that changed no data', (
      tester,
    ) async {
      await _pumpSummary(tester);
      final l10n = await loadL10n();

      await _expand(tester, l10n.totalNetWorth);
      expect(find.textContaining(_amount(200, 'EUR')), findsOneWidget);

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.textContaining(_amount(200, 'EUR')), findsOneWidget);
    });
  });
}
