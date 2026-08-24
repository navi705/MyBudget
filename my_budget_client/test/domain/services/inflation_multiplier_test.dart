import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/inflation_rate.dart';
import 'package:my_budget_client/domain/services/finance_calculator.dart';

/// How much of a year's inflation a period actually carries.
///
/// The fraction of the year was measured against a flat `Duration(days: 365)`,
/// so a leap year came out as 1.0027 of itself: the whole year's rate applied,
/// and then a little more on top, once for every leap year an account has
/// lived through.
void main() {
  final calculator = FinanceCalculator();

  double realBalanceOver(
    DateTime start,
    DateTime end, {
    required int rateYear,
    required double percent,
  }) {
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

    final snapshot = FinancialSnapshot(
      accounts: [account],
      transactions: const [],
      assetData: const [],
      categories: const [],
      exchangeRates: const [],
      inflationRates: [
        InflationRateDomain(
          country: 'US',
          preset: 1,
          percent: percent,
          date: DateTime(rateYear, 6, 15),
        ),
      ],
      date: end,
      dateStep: DateStep.year,
      baseCurrency: 'USD',
    );

    return calculator.calculateRealBalances(
      snapshot,
      balances: {'acc1': 1000.0},
    )['acc1']!;
  }

  test('a full leap year at 100% deflates a balance to half, not less', () {
    final real = realBalanceOver(
      DateTime(2024, 1, 1),
      DateTime(2024, 12, 31, 23, 59, 59),
      rateYear: 2024,
      percent: 100.0,
    );

    // 366/365 of a doubling is 2.0038, which took 0.95 off the thousand.
    expect(real, closeTo(500.0, 0.01));
  });

  test('a full non-leap year at 100% deflates a balance to half', () {
    final real = realBalanceOver(
      DateTime(2023, 1, 1),
      DateTime(2023, 12, 31, 23, 59, 59),
      rateYear: 2023,
      percent: 100.0,
    );

    expect(real, closeTo(500.0, 0.01));
  });

  test('a leap year and a normal one carry the same full-year rate', () {
    final leap = realBalanceOver(
      DateTime(2024, 1, 1),
      DateTime(2024, 12, 31, 23, 59, 59),
      rateYear: 2024,
      percent: 12.0,
    );
    final normal = realBalanceOver(
      DateTime(2023, 1, 1),
      DateTime(2023, 12, 31, 23, 59, 59),
      rateYear: 2023,
      percent: 12.0,
    );

    expect(leap, closeTo(normal, 0.001));
  });

  test('half a leap year carries about half its rate', () {
    final half = realBalanceOver(
      DateTime(2024, 1, 1),
      DateTime(2024, 7, 1),
      rateYear: 2024,
      percent: 100.0,
    );

    // 182 of the leap year's 366 days, so 1000 / 2^0.4973.
    expect(half, closeTo(708.4, 0.5));
  });

  test('a period outside the rate year is not deflated at all', () {
    final untouched = realBalanceOver(
      DateTime(2022, 1, 1),
      DateTime(2022, 12, 31, 23, 59, 59),
      rateYear: 2024,
      percent: 100.0,
    );

    expect(untouched, closeTo(1000.0, 0.001));
  });
}
