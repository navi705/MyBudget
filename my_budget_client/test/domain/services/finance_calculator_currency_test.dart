import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/asset_data.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/services/finance_calculator.dart';

/// Currency-resolution coverage for FinanceCalculator's private
/// `_getExchangeRate`, exercised through the public calculation methods:
///  - an unresolvable pair must NEVER come back as parity (it used to return
///    1.0, which added e.g. JPY straight onto USD);
///  - triangular resolution through the snapshot's main currency, dated by
///    its stalest leg, matching CurrencyConverterService's semantics;
///  - cross-currency asset cost basis priced at the TRANSACTION date rather
///    than the snapshot date.
void main() {
  final calculator = FinanceCalculator();

  Account account(
    String id,
    String currency, {
    double balance = 0.0,
    String? assetId,
    double assetQuantity = 0.0,
  }) => Account(
    id: id,
    name: 'Account $id',
    balance: balance,
    currencyCode: currency,
    currencyDesignationId: 'code',
    accountTypeId: 'general',
    creationDate: DateTime(2020, 1, 1),
    assetId: assetId,
    assetQuantity: assetQuantity,
  );

  ExchangeRateDomain rate(
    String from,
    String to,
    double value,
    DateTime date, {
    int preset = 1,
  }) => ExchangeRateDomain(
    fromCurrencyCode: from,
    toCurrencyCode: to,
    preset: preset,
    rate: value,
    date: date,
  );

  AssetDataDomain assetEntry(
    String assetId,
    double value,
    String currency,
    DateTime date,
  ) => AssetDataDomain(
    id: 'entry_$assetId',
    assetId: assetId,
    name: 'Price of $assetId',
    date: date,
    value: value,
    quantity: 1.0,
    currency: currency,
    source: 'test',
  );

  FinancialSnapshot snapshot({
    required List<Account> accounts,
    required DateTime date,
    required String baseCurrency,
    List<Transaction> transactions = const [],
    List<AssetDataDomain> assetData = const [],
    List<ExchangeRateDomain> exchangeRates = const [],
  }) => FinancialSnapshot(
    accounts: accounts,
    transactions: transactions,
    assetData: assetData,
    categories: const [],
    exchangeRates: exchangeRates,
    inflationRates: const [],
    date: date,
    dateStep: DateStep.month,
    baseCurrency: baseCurrency,
  );

  group('unresolvable currency pairs are never treated as parity', () {
    final today = DateTime(2025, 6, 1);

    test(
      'calculateTotalNetWorth does not add an unconvertible account at 1:1',
      () {
        final snap = snapshot(
          accounts: [
            account('usd', 'USD', balance: 100.0),
            account('jpy', 'JPY', balance: 10000.0),
          ],
          date: today,
          baseCurrency: 'USD',
          // No JPY rate anywhere: the pair genuinely cannot be resolved.
          exchangeRates: const [],
        );

        final total = calculator.calculateTotalNetWorth(snap);

        // The old 1.0 fallback produced 10100.0 -- 10000 JPY counted as
        // 10000 USD, and nothing on screen said so.
        expect(total.isNaN, isTrue);
        expect(total, isNot(10100.0));
      },
    );

    test('calculateBalances marks an asset priced in an unconvertible currency '
        'as NaN but keeps the account in the map', () {
      final snap = snapshot(
        accounts: [account('gold', 'USD', assetId: 'gold', assetQuantity: 2.0)],
        date: today,
        baseCurrency: 'USD',
        assetData: [assetEntry('gold', 1000.0, 'JPY', today)],
      );

      final balances = calculator.calculateBalances(snap);

      // Callers index this map with `!`, so the key must survive.
      expect(balances.containsKey('gold'), isTrue);
      expect(balances['gold']!.isNaN, isTrue);
      // Parity would have valued 2 x 1000 JPY as 2000 USD.
      expect(balances['gold'], isNot(2000.0));
    });

    test(
      'calculateCurrencyBreakdown poisons only the unconvertible bucket',
      () {
        final snap = snapshot(
          accounts: [
            account('usd', 'USD', balance: 100.0),
            account('jpy', 'JPY', balance: 10000.0),
          ],
          date: today,
          baseCurrency: 'USD',
        );

        final breakdown = calculator.calculateCurrencyBreakdown(snap);

        expect(breakdown['USD'], closeTo(100.0, 1e-9));
        expect(breakdown['JPY']!.isNaN, isTrue);
      },
    );

    test(
      'calculatePeriodStats keeps per-account nominal figures but reports an '
      'unknown base-currency total',
      () {
        final txDate = DateTime(2025, 6, 10);
        final tx = Transaction(
          id: 'tx1',
          description: 'Salary in JPY',
          amount: 300000.0,
          date: txDate,
          accountId: 'jpy',
          categoryId: 'cat1',
          currencyCode: 'JPY',
        );

        final snap = snapshot(
          accounts: [account('jpy', 'JPY')],
          transactions: [tx],
          date: DateTime(2025, 6, 30),
          baseCurrency: 'USD',
        );

        final stats = calculator.calculatePeriodStats(
          snap,
          DatePeriod(DateTime(2025, 6, 1), DateTime(2025, 6, 30, 23, 59, 59)),
        );

        expect(stats.income['jpy'], closeTo(300000.0, 1e-9));
        expect(stats.totalIncome.isNaN, isTrue);
        expect(stats.totalIncome, isNot(300000.0));
      },
    );

    test('an identical currency code still resolves to parity', () {
      final snap = snapshot(
        accounts: [account('usd', 'USD', balance: 250.0)],
        date: today,
        baseCurrency: 'USD',
      );

      expect(calculator.calculateTotalNetWorth(snap), closeTo(250.0, 1e-9));
    });
  });

  group('triangular resolution through the snapshot main currency', () {
    final tradeDate = DateTime(2025, 3, 10);

    /// Asset account in [assetCurrency] bought with a cash leg in
    /// [cashCurrency]; [baseCurrency] doubles as the app main currency, which
    /// is what the triangular fallback pivots through.
    FinancialSnapshot buySnapshot({
      required String assetCurrency,
      required String cashCurrency,
      required String baseCurrency,
      required List<ExchangeRateDomain> rates,
      required double cashAmount,
      DateTime? txDate,
      DateTime? snapshotDate,
    }) {
      final date = txDate ?? tradeDate;
      return snapshot(
        accounts: [
          account('asset', assetCurrency, assetId: 'gold', assetQuantity: 1.0),
          account('cash', cashCurrency),
        ],
        transactions: [
          Transaction(
            id: 'buy',
            description: 'Buy gold',
            amount: 1.0,
            date: date,
            accountId: 'asset',
            categoryId: 'cat1',
            currencyCode: assetCurrency,
            linkedTransactionId: 'pay',
          ),
          Transaction(
            id: 'pay',
            description: 'Pay for gold',
            amount: -cashAmount,
            date: date,
            accountId: 'cash',
            categoryId: 'cat1',
            currencyCode: cashCurrency,
          ),
        ],
        assetData: [assetEntry('gold', 100.0, assetCurrency, date)],
        exchangeRates: rates,
        date: snapshotDate ?? date,
        baseCurrency: baseCurrency,
      );
    }

    test(
      'a pair with no direct or inverse rate resolves via the main currency',
      () {
        final snap = buySnapshot(
          assetCurrency: 'USD',
          cashCurrency: 'EUR',
          baseCurrency: 'GBP',
          cashAmount: 400.0,
          rates: [
            rate('GBP', 'USD', 2.0, tradeDate),
            rate('GBP', 'EUR', 8.0, tradeDate),
          ],
        );

        final stats = calculator.calculateAssetStats(snap);

        // EUR->USD = Rate(GBP->USD) / Rate(GBP->EUR) = 2.0 / 8.0 = 0.25.
        // 400 EUR * 0.25 = 100 USD.
        expect(stats['asset']!.invested, closeTo(100.0, 1e-9));
      },
    );

    test('a fresh triangular pairing beats a three-year-stale direct rate', () {
      final snap = buySnapshot(
        assetCurrency: 'USD',
        cashCurrency: 'EUR',
        baseCurrency: 'GBP',
        cashAmount: 400.0,
        rates: [
          rate(
            'EUR',
            'USD',
            9.0,
            tradeDate.subtract(const Duration(days: 365 * 3)),
          ),
          rate('GBP', 'USD', 2.0, tradeDate),
          rate('GBP', 'EUR', 8.0, tradeDate),
        ],
      );

      final stats = calculator.calculateAssetStats(snap);

      expect(stats['asset']!.invested, closeTo(100.0, 1e-9));
    });

    test('a triangular pairing is dated by its STALEST leg, so a (fresh, '
        'three-years-stale) pair loses to an honest same-week direct rate', () {
      final snap = buySnapshot(
        assetCurrency: 'USD',
        cashCurrency: 'EUR',
        baseCurrency: 'GBP',
        cashAmount: 400.0,
        rates: [
          rate('EUR', 'USD', 1.25, tradeDate.subtract(const Duration(days: 5))),
          rate('GBP', 'USD', 2.0, tradeDate),
          rate(
            'GBP',
            'EUR',
            8.0,
            tradeDate.subtract(const Duration(days: 365 * 3)),
          ),
        ],
      );

      final stats = calculator.calculateAssetStats(snap);

      // Direct 1.25 wins: 400 EUR * 1.25 = 500 USD. Had the triangular pair
      // been ranked by its fresher leg it would have applied 0.25 -> 100.
      expect(stats['asset']!.invested, closeTo(500.0, 1e-9));
    });

    test(
      'triangular is skipped when one side already IS the main currency',
      () {
        final snap = buySnapshot(
          assetCurrency: 'USD',
          cashCurrency: 'EUR',
          baseCurrency: 'EUR',
          cashAmount: 400.0,
          // Only main-relative legs exist. With main == EUR == the "from" side,
          // EUR->USD would have to come from a direct/inverse row, and there is
          // none -- the leg below is USD-relative in the wrong direction.
          rates: [rate('EUR', 'GBP', 0.5, tradeDate)],
        );

        final stats = calculator.calculateAssetStats(snap);

        expect(stats['asset']!.invested.isNaN, isTrue);
      },
    );

    test('an asset price currency also resolves triangularly', () {
      final snap = snapshot(
        accounts: [account('gold', 'USD', assetId: 'gold', assetQuantity: 3.0)],
        date: tradeDate,
        baseCurrency: 'GBP',
        assetData: [assetEntry('gold', 40.0, 'EUR', tradeDate)],
        exchangeRates: [
          rate('GBP', 'USD', 2.0, tradeDate),
          rate('GBP', 'EUR', 8.0, tradeDate),
        ],
      );

      final balances = calculator.calculateBalances(snap);

      // 40 EUR * (2.0 / 8.0) = 10 USD per unit, 3 units held.
      expect(balances['gold'], closeTo(30.0, 1e-9));
    });
  });

  group('asset cost basis is priced at the transaction date', () {
    test('invested uses the rate in effect on the trade date, not the one in '
        'effect on the snapshot date', () {
      final txDate = DateTime(2023, 1, 15);
      final snapshotDate = DateTime(2024, 6, 1);

      final snap = snapshot(
        accounts: [
          account('asset', 'USD', assetId: 'gold', assetQuantity: 1.0),
          account('cash', 'EUR'),
        ],
        transactions: [
          Transaction(
            id: 'buy',
            description: 'Buy gold',
            amount: 1.0,
            date: txDate,
            accountId: 'asset',
            categoryId: 'cat1',
            currencyCode: 'USD',
            linkedTransactionId: 'pay',
          ),
          Transaction(
            id: 'pay',
            description: 'Pay for gold in EUR',
            amount: -400.0,
            date: txDate,
            accountId: 'cash',
            categoryId: 'cat1',
            currencyCode: 'EUR',
          ),
        ],
        assetData: [assetEntry('gold', 100.0, 'USD', txDate)],
        // Two very different rates, one live at the trade date and one live
        // at the snapshot date, so the assertion discriminates between them.
        exchangeRates: [
          rate('EUR', 'USD', 1.10, DateTime(2023, 1, 10)),
          rate('EUR', 'USD', 2.00, DateTime(2024, 5, 1)),
        ],
        date: snapshotDate,
        baseCurrency: 'USD',
      );

      final stats = calculator.calculateAssetStats(snap);

      // 400 EUR * 1.10 (rate at the trade) = 440 USD.
      expect(stats['asset']!.invested, closeTo(440.0, 1e-9));
      // 800.0 is what the snapshot-date rate would have produced.
      expect(stats['asset']!.invested, isNot(closeTo(800.0, 1e-9)));
    });

    test('realized on a sale is priced at the sale date too', () {
      final saleDate = DateTime(2023, 8, 1);
      final snapshotDate = DateTime(2024, 6, 1);

      final snap = snapshot(
        accounts: [
          account('asset', 'USD', assetId: 'gold', assetQuantity: 1.0),
          account('cash', 'EUR'),
        ],
        transactions: [
          Transaction(
            id: 'sell',
            description: 'Sell gold',
            amount: -1.0,
            date: saleDate,
            accountId: 'asset',
            categoryId: 'cat1',
            currencyCode: 'USD',
            linkedTransactionId: 'proceeds',
          ),
          Transaction(
            id: 'proceeds',
            description: 'Sale proceeds in EUR',
            amount: 250.0,
            date: saleDate,
            accountId: 'cash',
            categoryId: 'cat1',
            currencyCode: 'EUR',
          ),
        ],
        assetData: [assetEntry('gold', 100.0, 'USD', saleDate)],
        exchangeRates: [
          rate('EUR', 'USD', 1.20, DateTime(2023, 7, 20)),
          rate('EUR', 'USD', 5.00, DateTime(2024, 5, 1)),
        ],
        date: snapshotDate,
        baseCurrency: 'USD',
      );

      final stats = calculator.calculateAssetStats(snap);

      // 250 EUR * 1.20 = 300 USD, not 250 * 5.00 = 1250.
      expect(stats['asset']!.realized, closeTo(300.0, 1e-9));
    });
  });

  group('rate index filtering', () {
    test('rates stored under a non-default preset are ignored', () {
      final today = DateTime(2025, 6, 1);
      final snap = snapshot(
        accounts: [account('jpy', 'JPY', balance: 10000.0)],
        date: today,
        baseCurrency: 'USD',
        // Preset 2 is a user/dev preset; only preset 1 feeds the dashboard.
        exchangeRates: [rate('JPY', 'USD', 0.007, today, preset: 2)],
      );

      expect(calculator.calculateTotalNetWorth(snap).isNaN, isTrue);
    });
  });
}
