import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/asset_data.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';
import 'package:my_budget_client/domain/entities/inflation_rate.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/services/finance_calculator.dart';

/// FinanceCalculator caches its derived rate/inflation indexes and its resolved
/// rates and multipliers, because a single date-period switch on the accounts
/// screen used to rebuild and re-scan all of it five-plus times over data that
/// had not moved.
///
/// The half of that which can actually hurt a user is invalidation, so it is
/// tested first and at length: the calculator is a lazy SINGLETON, it outlives
/// every snapshot it is handed, and an answer it keeps one edit too long is a
/// wrong balance that survives until the app restarts. Every test in the first
/// group therefore warms the cache, changes the underlying data, and demands
/// the new answer - including the two mutations that leave the list's identity
/// alone (append, and same-length element replacement), which identity-keyed
/// caching would sail straight past.
///
/// The second group pins the numbers themselves against values captured from
/// the pre-cache implementation, so "faster" can be shown to have cost nothing.
void main() {
  // ---------------------------------------------------------------------------
  // Fixture
  // ---------------------------------------------------------------------------

  final snapshotDate = DateTime(2024, 7, 15, 12);

  // All rows are anchored on EUR, so EUR is the pivot the index recovers, and
  // RUB <-> USD is only reachable triangularly through it.
  List<ExchangeRateDomain> rates() => [
    ExchangeRateDomain(
      fromCurrencyCode: 'EUR',
      toCurrencyCode: 'USD',
      preset: 1,
      rate: 1.10,
      date: DateTime(2024, 1, 1),
    ),
    ExchangeRateDomain(
      fromCurrencyCode: 'EUR',
      toCurrencyCode: 'USD',
      preset: 1,
      rate: 1.08,
      date: DateTime(2024, 6, 1),
    ),
    ExchangeRateDomain(
      fromCurrencyCode: 'EUR',
      toCurrencyCode: 'RUB',
      preset: 1,
      rate: 95.0,
      date: DateTime(2024, 1, 1),
    ),
    ExchangeRateDomain(
      fromCurrencyCode: 'EUR',
      toCurrencyCode: 'RUB',
      preset: 1,
      rate: 100.0,
      date: DateTime(2024, 6, 1),
    ),
    ExchangeRateDomain(
      fromCurrencyCode: 'EUR',
      toCurrencyCode: 'GBP',
      preset: 1,
      rate: 0.85,
      date: DateTime(2024, 6, 1),
    ),
    // preset != 1 must stay invisible to the index; if it ever leaked in it
    // would beat every row above on date.
    ExchangeRateDomain(
      fromCurrencyCode: 'EUR',
      toCurrencyCode: 'USD',
      preset: 0,
      rate: 99.0,
      date: DateTime(2024, 7, 1),
    ),
  ];

  List<InflationRateDomain> inflation() => [
    InflationRateDomain(
      country: 'US',
      preset: 1,
      percent: 3.0,
      date: DateTime(2023, 6, 15),
    ),
    InflationRateDomain(
      country: 'US',
      preset: 1,
      percent: 4.0,
      date: DateTime(2024, 6, 15),
    ),
    InflationRateDomain(
      country: 'DE',
      preset: 1,
      percent: 2.5,
      date: DateTime(2024, 6, 15),
    ),
    InflationRateDomain(
      country: 'RU',
      preset: 1,
      percent: 11.9,
      date: DateTime(2022, 6, 15),
    ),
    InflationRateDomain(
      country: 'RU',
      preset: 1,
      percent: 7.4,
      date: DateTime(2023, 6, 15),
    ),
    InflationRateDomain(
      country: 'RU',
      preset: 1,
      percent: 9.0,
      date: DateTime(2024, 6, 15),
    ),
    // Country-less rows are dropped by the grouping, in the cached index
    // exactly as they were by the two inline copies it replaced.
    InflationRateDomain(preset: 1, percent: 50.0, date: DateTime(2024, 6, 15)),
  ];

  final accountUsd = Account(
    id: 'acc_usd',
    name: 'Checking',
    balance: 1000.0,
    currencyCode: 'USD',
    currencyDesignationId: 'code',
    accountTypeId: 'general',
    creationDate: DateTime(2020, 1, 1),
    country: 'US',
  );
  final accountEur = Account(
    id: 'acc_eur',
    name: 'Euro',
    balance: 500.0,
    currencyCode: 'EUR',
    currencyDesignationId: 'code',
    accountTypeId: 'general',
    creationDate: DateTime(2022, 6, 15),
    country: 'DE',
  );
  final accountRub = Account(
    id: 'acc_rub',
    name: 'Rouble',
    balance: 90000.0,
    currencyCode: 'RUB',
    currencyDesignationId: 'code',
    accountTypeId: 'general',
    creationDate: DateTime(2021, 3, 10),
    country: 'RU',
  );
  // Priced in RUB, held in USD: valuing it needs the triangular path.
  final accountGold = Account(
    id: 'acc_gold',
    name: 'Gold',
    balance: 0.0,
    currencyCode: 'USD',
    currencyDesignationId: 'code',
    accountTypeId: 'general',
    creationDate: DateTime(2021, 1, 1),
    country: 'US',
    assetId: 'gold',
    assetQuantity: 2.0,
  );

  final assetRows = [
    AssetDataDomain(
      assetId: 'gold',
      name: 'Gold',
      date: DateTime(2024, 1, 5),
      value: 180000.0,
      currency: 'RUB',
      source: 'test',
    ),
    AssetDataDomain(
      assetId: 'gold',
      name: 'Gold',
      date: DateTime(2024, 7, 1),
      value: 200000.0,
      currency: 'RUB',
      source: 'test',
    ),
  ];

  final categories = [
    Category(id: 'cat_income', name: 'Salary', type: CategoryType.income),
    Category(id: 'cat_food', name: 'Food', type: CategoryType.expense),
    Category(id: 'cat_move', name: 'Transfer', type: CategoryType.transfer),
  ];

  final transactions = [
    Transaction(
      id: 't1',
      description: 'Salary',
      amount: 200.0,
      date: DateTime(2024, 7, 3, 10),
      accountId: 'acc_usd',
      categoryId: 'cat_income',
      currencyCode: 'USD',
    ),
    // After the snapshot date: undone by the reverse balance walk, and outside
    // the period either way.
    Transaction(
      id: 't2',
      description: 'Later',
      amount: -50.0,
      date: DateTime(2024, 7, 20, 10),
      accountId: 'acc_usd',
      categoryId: 'cat_food',
      currencyCode: 'USD',
    ),
    Transaction(
      id: 't3',
      description: 'Groceries',
      amount: -80.0,
      date: DateTime(2024, 7, 10, 9, 30),
      accountId: 'acc_eur',
      categoryId: 'cat_food',
      currencyCode: 'EUR',
    ),
    Transaction(
      id: 't4',
      description: 'Bonus',
      amount: 30000.0,
      date: DateTime(2024, 7, 12, 8),
      accountId: 'acc_rub',
      categoryId: 'cat_income',
      currencyCode: 'RUB',
    ),
    Transaction(
      id: 't5',
      description: 'Moved',
      amount: -5000.0,
      date: DateTime(2024, 7, 12, 8),
      accountId: 'acc_rub',
      categoryId: 'cat_move',
      currencyCode: 'RUB',
    ),
    Transaction(
      id: 't6',
      description: 'Buy gold',
      amount: 0.5,
      date: DateTime(2024, 7, 5, 11),
      accountId: 'acc_gold',
      categoryId: 'cat_income',
      currencyCode: 'USD',
      fee: 3.0,
      linkedTransactionId: 't7',
    ),
    Transaction(
      id: 't7',
      description: 'Cash leg',
      amount: -1000.0,
      date: DateTime(2024, 7, 5, 11),
      accountId: 'acc_eur',
      categoryId: 'cat_income',
      currencyCode: 'EUR',
      linkedTransactionId: 't6',
    ),
  ];

  FinancialSnapshot snapshot({
    required List<ExchangeRateDomain> exchangeRates,
    required List<InflationRateDomain> inflationRates,
    DateTime? date,
    String baseCurrency = 'USD',
  }) {
    return FinancialSnapshot(
      accounts: [accountUsd, accountEur, accountRub, accountGold],
      transactions: transactions,
      assetData: assetRows,
      categories: categories,
      exchangeRates: exchangeRates,
      inflationRates: inflationRates,
      date: date ?? snapshotDate,
      dateStep: DateStep.month,
      baseCurrency: baseCurrency,
    );
  }

  double netWorth(
    FinanceCalculator calc,
    List<ExchangeRateDomain> rateRows,
    List<InflationRateDomain> inflationRows,
  ) {
    return calc.calculateTotalNetWorth(
      snapshot(exchangeRates: rateRows, inflationRates: inflationRows),
    );
  }

  // ---------------------------------------------------------------------------
  // (b) Invalidation - the property whose failure is a wrong number on screen
  // ---------------------------------------------------------------------------

  group('cache invalidation', () {
    test('a NEW rate list is not answered out of the previous list', () {
      final calc = FinanceCalculator();
      final before = netWorth(calc, rates(), inflation());

      final repriced = rates()
        ..add(
          ExchangeRateDomain(
            fromCurrencyCode: 'EUR',
            toCurrencyCode: 'USD',
            preset: 1,
            rate: 2.0,
            date: DateTime(2024, 7, 10),
          ),
        );
      final after = netWorth(calc, repriced, inflation());

      expect(after, isNot(equals(before)));
      // The figure a calculator that never saw the old rows produces is the
      // only acceptable answer.
      expect(after, equals(netWorth(FinanceCalculator(), repriced, inflation())));
    });

    test('APPENDING to the list already handed over is noticed, even though '
        'the list is the same instance', () {
      final calc = FinanceCalculator();
      final live = rates();
      final before = netWorth(calc, live, inflation());

      live.add(
        ExchangeRateDomain(
          fromCurrencyCode: 'EUR',
          toCurrencyCode: 'USD',
          preset: 1,
          rate: 2.0,
          date: DateTime(2024, 7, 10),
        ),
      );
      final after = netWorth(calc, live, inflation());

      expect(after, isNot(equals(before)));
      expect(after, equals(netWorth(FinanceCalculator(), live, inflation())));
    });

    test('REPLACING a row in place is noticed - same instance, same length, '
        'different rate', () {
      final calc = FinanceCalculator();
      final live = rates();
      final before = netWorth(calc, live, inflation());

      // The user corrects the current EUR->USD row. Nothing about the list's
      // identity or its length has changed; only its content has.
      live[1] = live[1].copyWith(rate: 2.0);
      final after = netWorth(calc, live, inflation());

      expect(after, isNot(equals(before)));
      expect(after, equals(netWorth(FinanceCalculator(), live, inflation())));
    });

    test('an edited INFLATION row is noticed in place', () {
      final calc = FinanceCalculator();
      final live = inflation();
      final before = calc.calculateRealBalances(
        snapshot(exchangeRates: rates(), inflationRates: live),
      );

      live[1] = live[1].copyWith(percent: 40.0); // US 2024: 4% -> 40%
      final after = calc.calculateRealBalances(
        snapshot(exchangeRates: rates(), inflationRates: live),
      );

      expect(after['acc_usd'], isNot(equals(before['acc_usd'])));
      expect(
        after['acc_usd'],
        equals(
          FinanceCalculator().calculateRealBalances(
            snapshot(exchangeRates: rates(), inflationRates: live),
          )['acc_usd'],
        ),
      );
      // DE is untouched by a US edit.
      expect(after['acc_eur'], equals(before['acc_eur']));
    });

    test('switching back and forth between two rate lists answers from the '
        'right one each time', () {
      final calc = FinanceCalculator();
      final listA = rates();
      final listB = rates()
        ..[1] = ExchangeRateDomain(
          fromCurrencyCode: 'EUR',
          toCurrencyCode: 'USD',
          preset: 1,
          rate: 3.0,
          date: DateTime(2024, 6, 1),
        );

      final a1 = netWorth(calc, listA, inflation());
      final b1 = netWorth(calc, listA, inflation());
      final b2 = netWorth(calc, listB, inflation());
      final a2 = netWorth(calc, listA, inflation());
      final b3 = netWorth(calc, listB, inflation());

      expect(b1, equals(a1));
      expect(a2, equals(a1));
      expect(b3, equals(b2));
      expect(b2, isNot(equals(a1)));
    });

    test('the AS-OF DATE is part of the key: an older snapshot gets the older '
        'rate, not the one just computed for today', () {
      final calc = FinanceCalculator();
      final rateRows = rates();

      // 2024-07-15 sees the June row (1.08); 2024-03-01 must still see the
      // January row (1.10), which is the only difference between these two.
      final july = calc.calculateCurrencyBreakdown(
        snapshot(exchangeRates: rateRows, inflationRates: inflation()),
        balances: {'acc_eur': 100.0},
      );
      final march = calc.calculateCurrencyBreakdown(
        snapshot(
          exchangeRates: rateRows,
          inflationRates: inflation(),
          date: DateTime(2024, 3, 1),
        ),
        balances: {'acc_eur': 100.0},
      );

      expect(july['EUR'], closeTo(108.0, 1e-9));
      expect(march['EUR'], closeTo(110.0, 1e-9));
    });

    test('a date BEFORE every stored row still resolves to nothing after a '
        'later date has been resolved', () {
      final calc = FinanceCalculator();
      final rateRows = rates();

      final priced = calc.calculateCurrencyBreakdown(
        snapshot(exchangeRates: rateRows, inflationRates: inflation()),
        balances: {'acc_eur': 100.0},
      );
      final tooEarly = calc.calculateCurrencyBreakdown(
        snapshot(
          exchangeRates: rateRows,
          inflationRates: inflation(),
          date: DateTime(2023, 1, 1),
        ),
        balances: {'acc_eur': 100.0},
      );

      expect(priced['EUR'], closeTo(108.0, 1e-9));
      expect(tooEarly['EUR']!.isNaN, isTrue);
    });

    test('the MAIN currency is part of the key: it decides which pivots exist', () {
      // CHF prices AAA and BBB; EUR prices three others and is therefore the
      // recovered anchor. AAA->BBB is only derivable when CHF is also a pivot,
      // which happens only when CHF is the main currency. The asset conversion
      // below uses the base currency ONLY as the pivot hint - the target is the
      // account's own currency - so this isolates that one input.
      final rateRows = rates()
        ..addAll([
          ExchangeRateDomain(
            fromCurrencyCode: 'CHF',
            toCurrencyCode: 'AAA',
            preset: 1,
            rate: 2.0,
            date: DateTime(2024, 6, 1),
          ),
          ExchangeRateDomain(
            fromCurrencyCode: 'CHF',
            toCurrencyCode: 'BBB',
            preset: 1,
            rate: 6.0,
            date: DateTime(2024, 6, 1),
          ),
        ]);

      final aaaAccount = Account(
        id: 'acc_aaa',
        name: 'Exotic',
        balance: 0.0,
        currencyCode: 'BBB',
        currencyDesignationId: 'code',
        accountTypeId: 'general',
        creationDate: DateTime(2024, 1, 1),
        assetId: 'exotic',
        assetQuantity: 1.0,
      );

      FinancialSnapshot exotic(String baseCurrency) => FinancialSnapshot(
        accounts: [aaaAccount],
        transactions: const [],
        assetData: [
          AssetDataDomain(
            assetId: 'exotic',
            name: 'Exotic',
            date: DateTime(2024, 6, 1),
            value: 10.0,
            currency: 'AAA',
            source: 'test',
          ),
        ],
        categories: const [],
        exchangeRates: rateRows,
        inflationRates: const [],
        date: snapshotDate,
        dateStep: DateStep.month,
        baseCurrency: baseCurrency,
      );

      final calc = FinanceCalculator();
      final viaChf = calc.calculateBalances(exotic('CHF'))['acc_aaa']!;
      final viaUsd = calc.calculateBalances(exotic('USD'))['acc_aaa']!;
      // And back again, to prove neither answer poisoned the other.
      final viaChfAgain = calc.calculateBalances(exotic('CHF'))['acc_aaa']!;

      expect(viaChf, closeTo(30.0, 1e-9)); // 10 * (6.0 / 2.0)
      expect(viaUsd.isNaN, isTrue);
      expect(viaChfAgain, closeTo(30.0, 1e-9));
    });

    test('the inflation multiplier is keyed on the whole (country, anchor, '
        'as-of) triple, not on the country', () {
      final calc = FinanceCalculator();
      final young = accountUsd.copyWith(
        id: 'acc_young',
        creationDate: DateTime(2024, 1, 1),
      );
      final old = accountUsd.copyWith(
        id: 'acc_old',
        creationDate: DateTime(2020, 1, 1),
      );

      final data = FinancialSnapshot(
        accounts: [young, old],
        transactions: const [],
        assetData: const [],
        categories: const [],
        exchangeRates: rates(),
        inflationRates: inflation(),
        date: snapshotDate,
        dateStep: DateStep.month,
        baseCurrency: 'USD',
      );

      final real = calc.calculateRealBalances(
        data,
        balances: {'acc_young': 1000.0, 'acc_old': 1000.0},
      );

      // Same country, same as-of date, same nominal: only the anchor differs,
      // and the older account has more inflation behind it.
      expect(real['acc_old']!, lessThan(real['acc_young']!));

      // The as-of date is in the key too: a later snapshot deflates further.
      final later = calc.calculateRealBalances(
        FinancialSnapshot(
          accounts: [young, old],
          transactions: const [],
          assetData: const [],
          categories: const [],
          exchangeRates: rates(),
          inflationRates: inflation(),
          date: DateTime(2024, 12, 31),
          dateStep: DateStep.month,
          baseCurrency: 'USD',
        ),
        balances: {'acc_young': 1000.0, 'acc_old': 1000.0},
      );
      expect(later['acc_young']!, lessThan(real['acc_young']!));
    });
  });

  // ---------------------------------------------------------------------------
  // Rate selection - the binary search must pick the row the linear scan picked
  // ---------------------------------------------------------------------------

  group('rate selection is unchanged by the binary search', () {
    ExchangeRateDomain row(double rate, DateTime date) => ExchangeRateDomain(
      fromCurrencyCode: 'EUR',
      toCurrencyCode: 'USD',
      preset: 1,
      rate: rate,
      date: date,
    );

    double eurPricedAt(List<ExchangeRateDomain> rows, DateTime date) {
      return FinanceCalculator().calculateCurrencyBreakdown(
        FinancialSnapshot(
          accounts: [accountEur],
          transactions: const [],
          assetData: const [],
          categories: const [],
          exchangeRates: rows,
          inflationRates: const [],
          date: date,
          dateStep: DateStep.month,
          baseCurrency: 'USD',
        ),
        balances: {'acc_eur': 1.0},
      )['EUR']!;
    }

    test('the newest row at or before the date wins, whatever order the rows '
        'were stored in', () {
      final shuffled = [
        row(1.5, DateTime(2024, 5, 1)),
        row(1.9, DateTime(2024, 9, 1)),
        row(1.1, DateTime(2024, 1, 1)),
        row(1.7, DateTime(2024, 7, 1)),
        row(1.3, DateTime(2024, 3, 1)),
      ];
      expect(eurPricedAt(shuffled, DateTime(2024, 7, 15)), closeTo(1.7, 1e-9));
      expect(eurPricedAt(shuffled, DateTime(2024, 7, 1)), closeTo(1.7, 1e-9));
      expect(
        eurPricedAt(shuffled, DateTime(2024, 6, 30, 23, 59)),
        closeTo(1.5, 1e-9),
      );
      expect(eurPricedAt(shuffled, DateTime(2024, 12, 1)), closeTo(1.9, 1e-9));
    });

    test('a row dated after the query date is never used, not even as the only '
        'row', () {
      final future = [row(4.0, DateTime(2025, 1, 1))];
      expect(eurPricedAt(future, DateTime(2024, 7, 15)).isNaN, isTrue);
    });

    test('one row, exactly on the date, is eligible', () {
      final single = [row(2.5, DateTime(2024, 7, 15))];
      expect(eurPricedAt(single, DateTime(2024, 7, 15)), closeTo(2.5, 1e-9));
    });

    test('rows sharing a date resolve to the same row on every call', () {
      final tied = [
        row(1.2, DateTime(2024, 7, 1)),
        row(1.4, DateTime(2024, 7, 1)),
        row(1.0, DateTime(2024, 1, 1)),
      ];
      final first = eurPricedAt(tied, DateTime(2024, 7, 15));
      expect(eurPricedAt(tied, DateTime(2024, 7, 15)), equals(first));
      expect(first, anyOf(closeTo(1.2, 1e-9), closeTo(1.4, 1e-9)));
    });
  });

  // ---------------------------------------------------------------------------
  // (a) The numbers themselves, against the pre-cache implementation
  // ---------------------------------------------------------------------------

  group('results are byte-identical to the pre-cache implementation', () {
    test('every figure of a four-account, four-currency, pivoted, inflated '
        'snapshot', () {
      final produced = _allFigures(
        FinanceCalculator(),
        snapshot(exchangeRates: rates(), inflationRates: inflation()),
      );

      expect(produced.keys.toSet(), equals(_golden.keys.toSet()));
      for (final entry in _golden.entries) {
        expect(
          produced[entry.key],
          equals(entry.value),
          reason: '${entry.key} moved',
        );
      }
    });

    test('a warm calculator returns exactly what a cold one does, across the '
        'whole set of public methods', () {
      final cold = _allFigures(
        FinanceCalculator(),
        snapshot(exchangeRates: rates(), inflationRates: inflation()),
      );

      final warm = FinanceCalculator();
      // Warm every cache on data that is NOT this snapshot's: other rates,
      // other inflation, another date, another main currency.
      _allFigures(
        warm,
        snapshot(
          exchangeRates: rates()..[1] = rates()[1].copyWith(rate: 5.0),
          inflationRates: inflation()
            ..[1] = inflation()[1].copyWith(percent: 44.0),
          date: DateTime(2024, 2, 2),
          baseCurrency: 'EUR',
        ),
      );

      // Now ask twice over ONE snapshot - the same list instances both times,
      // which is what a real gesture does and the only way the index and both
      // memos are genuinely hot on the second pass.
      final data = snapshot(exchangeRates: rates(), inflationRates: inflation());
      final second = _allFigures(warm, data);
      final third = _allFigures(warm, data);

      expect(second, equals(cold));
      expect(third, equals(cold));
    });
  });
}

/// Every number the calculator can be asked for, flattened, so one comparison
/// covers all of them.
Map<String, double> _allFigures(
  FinanceCalculator calc,
  FinancialSnapshot data,
) {
  final out = <String, double>{};
  final balances = calc.calculateBalances(data);
  balances.forEach((k, v) => out['balance.$k'] = v);

  calc
      .calculateRealBalances(data, balances: balances)
      .forEach((k, v) => out['real.$k'] = v);

  out['netWorth'] = calc.calculateTotalNetWorth(data, balances: balances);

  calc
      .calculateCurrencyBreakdown(data, balances: balances)
      .forEach((k, v) => out['breakdown.$k'] = v);

  final stats = calc.calculatePeriodStats(data, data.currentPeriod);
  out['period.totalIncome'] = stats.totalIncome;
  out['period.totalExpense'] = stats.totalExpense;
  stats.income.forEach((k, v) => out['period.income.$k'] = v);
  stats.expense.forEach((k, v) => out['period.expense.$k'] = v);
  stats.realIncome.forEach((k, v) => out['period.realIncome.$k'] = v);
  stats.realExpense.forEach((k, v) => out['period.realExpense.$k'] = v);

  final previous = calc.calculatePeriodStats(
    data,
    data.currentPeriod.previousFor(data.dateStep),
  );
  out['prev.totalIncome'] = previous.totalIncome;
  out['prev.totalExpense'] = previous.totalExpense;

  calc.calculateAssetStats(data, balances: balances).forEach((k, v) {
    out['asset.$k.nominal'] = v.nominalBalance;
    out['asset.$k.net'] = v.netBalance;
    out['asset.$k.invested'] = v.invested;
    out['asset.$k.realized'] = v.realized;
    out['asset.$k.commissions'] = v.commissions;
  });
  return out;
}

/// Captured by running [_allFigures] against finance_calculator.dart as it was
/// BEFORE any caching existed. Exact equality, not closeTo: a cache is allowed
/// to change how long an answer takes and nothing else.
const Map<String, double> _golden = <String, double>{
  'balance.acc_usd': 1050.0,
  'balance.acc_eur': 500.0,
  'balance.acc_rub': 90000.0,
  'balance.acc_gold': 5400.0,
  'real.acc_usd': 998.1804630250247,
  'real.acc_eur': 493.4165814958799,
  'real.acc_rub': 71502.0791188873,
  'real.acc_gold': 5133.499524128698,
  'netWorth': 7962.0,
  'breakdown.USD': 6450.0,
  'breakdown.EUR': 540.0,
  'breakdown.RUB': 972.0,
  'period.totalIncome': 524.0,
  'period.totalExpense': -1216.4,
  'period.income.acc_usd': 200.0,
  'period.income.acc_rub': 30000.0,
  'period.expense.acc_usd': -50.0,
  'period.expense.acc_eur': -1080.0,
  'period.realIncome.acc_usd': 190.3759617534101,
  'period.realIncome.acc_rub': 23851.804069134716,
  'period.realExpense.acc_usd': -47.507366102430225,
  'period.realExpense.acc_eur': -1066.4757856416554,
  'prev.totalIncome': 0.0,
  'prev.totalExpense': 0.0,
  'asset.acc_gold.nominal': 5400.0,
  'asset.acc_gold.net': 5400.0,
  'asset.acc_gold.invested': 1080.0,
  'asset.acc_gold.realized': 0.0,
  'asset.acc_gold.commissions': 3.0,
};
