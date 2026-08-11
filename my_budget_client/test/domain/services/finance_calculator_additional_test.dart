import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/asset_data.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';
import 'package:my_budget_client/domain/entities/inflation_rate.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/services/finance_calculator.dart';

/// Extra coverage for FinanceCalculator, focused on paths not exercised by
/// test/financial_engine/finance_calculator_test.dart:
///  - calculateAssetStats: linked-pair legs in DIFFERENT currencies (direct
///    and inverse rate resolution through the private _getExchangeRate).
///  - calculateAssetStats: a linkedTransactionId pointing at a transaction
///    that is not present in the snapshot ("one leg missing").
///  - calculateRealBalances: a full-calendar-year 100% inflation rate must
///    yield a multiplier extremely close to 2.0 -- a regression guard for
///    the `rate.percent / 100` division in _calculateInflationMultiplier.
void main() {
  final calculator = FinanceCalculator();

  group('calculateAssetStats - cross-currency linked pairs', () {
    test(
      'invested converts the cash leg using a DIRECT rate when the linked '
      'transaction currency differs from the asset account currency',
      () {
        final now = DateTime.now();
        final goldAccount = Account(
          id: 'acc1',
          name: 'Gold Account',
          balance: 0.0,
          currencyCode: 'USD',
          currencyDesignationId: 'code',
          accountTypeId: 'general',
          creationDate: now.subtract(const Duration(days: 30)),
          assetId: 'gold',
          assetQuantity: 1.0,
        );

        final cashAccount = Account(
          id: 'acc2',
          name: 'Cash Account (EUR)',
          balance: 0.0,
          currencyCode: 'EUR',
          currencyDesignationId: 'code',
          accountTypeId: 'general',
          creationDate: now.subtract(const Duration(days: 30)),
        );

        final buyTx = Transaction(
          id: 'tx1',
          description: 'Buy gold',
          amount: 1.0,
          date: now,
          accountId: 'acc1',
          categoryId: 'cat1',
          currencyCode: 'USD',
          linkedTransactionId: 'tx2',
        );

        final cashTx = Transaction(
          id: 'tx2',
          description: 'Pay for gold in EUR',
          amount: -400.0,
          date: now,
          accountId: 'acc2',
          categoryId: 'cat1',
          currencyCode: 'EUR',
        );

        // Only a direct EUR -> USD rate is stored.
        final rate = ExchangeRateDomain(
          fromCurrencyCode: 'EUR',
          toCurrencyCode: 'USD',
          preset: 1,
          rate: 1.2,
          date: now,
        );

        final assetEntry = AssetDataDomain(
          id: 'asset1',
          assetId: 'gold',
          name: 'Gold Price',
          date: now,
          value: 100.0,
          quantity: 1.0,
          currency: 'USD',
          source: 'test',
        );

        final snap = FinancialSnapshot(
          accounts: [goldAccount, cashAccount],
          transactions: [buyTx, cashTx],
          assetData: [assetEntry],
          categories: [],
          exchangeRates: [rate],
          inflationRates: [],
          date: now,
          dateStep: DateStep.month,
          baseCurrency: 'USD',
        );

        final assetStats = calculator.calculateAssetStats(snap);

        // 400 EUR * 1.2 (EUR->USD) = 480 USD.
        expect(assetStats['acc1']!.invested, closeTo(480.0, 1e-9));
      },
    );

    test(
      'realized converts the cash leg using an INVERSE rate when only the '
      'opposite direction is stored',
      () {
        final now = DateTime.now();
        final goldAccount = Account(
          id: 'acc1',
          name: 'Gold Account',
          balance: 0.0,
          currencyCode: 'USD',
          currencyDesignationId: 'code',
          accountTypeId: 'general',
          creationDate: now.subtract(const Duration(days: 30)),
          assetId: 'gold',
          assetQuantity: 1.0,
        );

        final cashAccount = Account(
          id: 'acc2',
          name: 'Cash Account (EUR)',
          balance: 0.0,
          currencyCode: 'EUR',
          currencyDesignationId: 'code',
          accountTypeId: 'general',
          creationDate: now.subtract(const Duration(days: 30)),
        );

        final sellTx = Transaction(
          id: 'tx1',
          description: 'Sell gold',
          amount: -1.0,
          date: now,
          accountId: 'acc1',
          categoryId: 'cat1',
          currencyCode: 'USD',
          linkedTransactionId: 'tx2',
        );

        final cashTx = Transaction(
          id: 'tx2',
          description: 'Receive from sale in EUR',
          amount: 250.0,
          date: now,
          accountId: 'acc2',
          categoryId: 'cat1',
          currencyCode: 'EUR',
        );

        // Only the USD -> EUR direction is stored; _getExchangeRate must
        // invert it to price the EUR cash leg into the USD asset account.
        final rate = ExchangeRateDomain(
          fromCurrencyCode: 'USD',
          toCurrencyCode: 'EUR',
          preset: 1,
          rate: 0.8, // 1 USD = 0.8 EUR  =>  1 EUR = 1.25 USD
          date: now,
        );

        final assetEntry = AssetDataDomain(
          id: 'asset1',
          assetId: 'gold',
          name: 'Gold Price',
          date: now,
          value: 100.0,
          quantity: 1.0,
          currency: 'USD',
          source: 'test',
        );

        final snap = FinancialSnapshot(
          accounts: [goldAccount, cashAccount],
          transactions: [sellTx, cashTx],
          assetData: [assetEntry],
          categories: [],
          exchangeRates: [rate],
          inflationRates: [],
          date: now,
          dateStep: DateStep.month,
          baseCurrency: 'USD',
        );

        final assetStats = calculator.calculateAssetStats(snap);

        // 250 EUR * (1 / 0.8) = 312.5 USD.
        expect(assetStats['acc1']!.realized, closeTo(312.5, 1e-9));
      },
    );
  });

  group('calculateAssetStats - linkedTransactionId with a missing leg', () {
    test(
      'a linkedTransactionId pointing at a transaction absent from the '
      'snapshot contributes zero cashValue but the fee is still counted',
      () {
        final now = DateTime.now();
        final goldAccount = Account(
          id: 'acc1',
          name: 'Gold Account',
          balance: 0.0,
          currencyCode: 'USD',
          currencyDesignationId: 'code',
          accountTypeId: 'general',
          creationDate: now.subtract(const Duration(days: 30)),
          assetId: 'gold',
          assetQuantity: 1.0,
        );

        // Note: the linked cash transaction ("tx-missing") is intentionally
        // NOT included in the snapshot's transaction list.
        final buyTx = Transaction(
          id: 'tx1',
          description: 'Buy gold, cash leg not in this snapshot',
          amount: 1.0,
          date: now,
          accountId: 'acc1',
          categoryId: 'cat1',
          currencyCode: 'USD',
          fee: 5.0,
          linkedTransactionId: 'tx-missing',
        );

        final assetEntry = AssetDataDomain(
          id: 'asset1',
          assetId: 'gold',
          name: 'Gold Price',
          date: now,
          value: 100.0,
          quantity: 1.0,
          currency: 'USD',
          source: 'test',
        );

        final snap = FinancialSnapshot(
          accounts: [goldAccount],
          transactions: [buyTx],
          assetData: [assetEntry],
          categories: [],
          exchangeRates: [],
          inflationRates: [],
          date: now,
          dateStep: DateStep.month,
          baseCurrency: 'USD',
        );

        final assetStats = calculator.calculateAssetStats(snap);

        expect(assetStats['acc1']!.invested, 0.0);
        expect(assetStats['acc1']!.realized, 0.0);
        expect(assetStats['acc1']!.commissions, 5.0);
      },
    );
  });

  group('calculateRealBalances - inflation multiplier precision', () {
    test(
      'a full calendar year at 100% inflation deflates a balance to '
      'very nearly half (regression guard for the /100 percent division)',
      () {
        // Non-leap year so [start, end] spans (almost) exactly 365 days,
        // giving a fraction of the calendar year extremely close to 1.0.
        final start = DateTime(2023, 1, 1);
        final end = DateTime(2023, 12, 31, 23, 59, 59);

        final account = Account(
          id: 'acc1',
          name: 'Savings',
          balance: 1000.0,
          currencyCode: 'USD',
          currencyDesignationId: 'code',
          accountTypeId: 'general',
          creationDate: start,
          country: 'US',
        );

        final inflation = InflationRateDomain(
          country: 'US',
          preset: 1,
          percent: 100.0,
          date: DateTime(2023, 6, 15),
        );

        final snap = FinancialSnapshot(
          accounts: [account],
          transactions: [],
          assetData: [],
          categories: [],
          exchangeRates: [],
          inflationRates: [inflation],
          date: end,
          dateStep: DateStep.year,
          baseCurrency: 'USD',
        );

        final realBalances = calculator.calculateRealBalances(
          snap,
          balances: {'acc1': 1000.0},
        );

        // If the `/100` were dropped, `percent` (100.0) would be used
        // directly as the growth factor and the multiplier would blow up
        // to roughly 2^100 instead of ~2.0 -- caught by this tight bound.
        expect(realBalances['acc1'], closeTo(500.0, 0.01));
      },
    );
  });
}
