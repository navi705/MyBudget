import 'dart:math';
// import 'package:flutter/foundation.dart'; // Removed to avoid Category collision
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/asset_data.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';
import 'package:my_budget_client/domain/entities/inflation_rate.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart'; // For DateStep
import 'package:my_budget_client/core/utils/calendar_day.dart';
import 'package:my_budget_client/domain/services/fee_calculator.dart'; // Added

/// Snapshot of all financial data required for calculations at a specific point in time.
class FinancialSnapshot {
  final List<Account> accounts;
  final List<Transaction> transactions;
  final List<AssetDataDomain> assetData;
  final List<Category> categories; // Added
  final List<ExchangeRateDomain> exchangeRates;
  final List<InflationRateDomain> inflationRates;
  final DateTime date; // The reference date for calculation
  final DateStep dateStep; // Context for period-based calcs (Day, Month, Year)
  final String baseCurrency;

  FinancialSnapshot({
    required this.accounts,
    required this.transactions,
    required this.assetData,
    required this.categories,
    required this.exchangeRates,
    required this.inflationRates,
    required this.date,
    required this.dateStep,
    required this.baseCurrency,
  });

  FinancialSnapshot copyWith({
    List<Account>? accounts,
    List<Transaction>? transactions,
    List<AssetDataDomain>? assetData,
    List<Category>? categories,
    List<ExchangeRateDomain>? exchangeRates,
    List<InflationRateDomain>? inflationRates,
    DateTime? date,
    DateStep? dateStep,
    String? baseCurrency,
  }) {
    return FinancialSnapshot(
      accounts: accounts ?? this.accounts,
      transactions: transactions ?? this.transactions,
      assetData: assetData ?? this.assetData,
      categories: categories ?? this.categories,
      exchangeRates: exchangeRates ?? this.exchangeRates,
      inflationRates: inflationRates ?? this.inflationRates,
      date: date ?? this.date,
      dateStep: dateStep ?? this.dateStep,
      baseCurrency: baseCurrency ?? this.baseCurrency,
    );
  }

  DatePeriod get currentPeriod {
    DateTime start;
    DateTime end;
    switch (dateStep) {
      case DateStep.day:
        start = DateTime(date.year, date.month, date.day);
        end = DateTime(date.year, date.month, date.day, 23, 59, 59);
        break;
      case DateStep.month:
        start = DateTime(date.year, date.month, 1);
        end = DateTime(date.year, date.month + 1, 0, 23, 59, 59);
        break;
      case DateStep.year:
        start = DateTime(date.year, 1, 1);
        end = DateTime(date.year, 12, 31, 23, 59, 59);
        break;
    }
    return DatePeriod(start, end);
  }
}

class DatePeriod {
  final DateTime start;
  final DateTime end;

  DatePeriod(this.start, this.end);

  /// The period one [step] before this one.
  ///
  /// Days used to be handled inline by the accounts bloc as
  /// `start.subtract(const Duration(days: 1))` for BOTH ends, which made the
  /// previous day the single instant of its midnight: [FinanceCalculator
  /// .calculatePeriodStats] takes the period inclusively, so yesterday's
  /// income and expense counted only a transaction stamped exactly 00:00:00
  /// and every day-step comparison on the accounts screen read as
  /// "yesterday: nothing". Subtracting a duration also walks off midnight the
  /// two days a year the clocks move - the day after a spring-forward asked
  /// for 23:00 on the day before yesterday.
  ///
  /// Built the same way [FinancialSnapshot.currentPeriod] builds the current
  /// one, so the two are always the same shape and the comparison is between
  /// like and like.
  DatePeriod previousFor(DateStep step) {
    switch (step) {
      case DateStep.day:
        final day = previousDay(start);
        return DatePeriod(
          day,
          DateTime(day.year, day.month, day.day, 23, 59, 59),
        );
      case DateStep.month:
        final first = DateTime(start.year, start.month - 1, 1);
        return DatePeriod(
          first,
          DateTime(first.year, first.month + 1, 0, 23, 59, 59),
        );
      case DateStep.year:
        return DatePeriod(
          DateTime(start.year - 1, 1, 1),
          DateTime(start.year - 1, 12, 31, 23, 59, 59),
        );
    }
  }
}

class PeriodStats {
  final Map<String, double> income; // Key: AccountId
  final Map<String, double> expense; // Key: AccountId
  final Map<String, double> realIncome; // Key: AccountId
  final Map<String, double> realExpense; // Key: AccountId
  final double totalIncome; // In Base Currency
  final double totalExpense; // In Base Currency

  PeriodStats({
    required this.income,
    required this.expense,
    required this.realIncome,
    required this.realExpense,
    required this.totalIncome,
    required this.totalExpense,
  });
}

class FinanceCalculator {
  // --- Derived-data caches ---------------------------------------------------
  //
  // Everything in this block is DERIVED from a snapshot's rate and inflation
  // lists, and one date-period switch on the accounts screen hands the very
  // same two lists to calculateBalances, calculateTotalNetWorth,
  // calculateCurrencyBreakdown, calculateAssetStats and calculatePeriodStats
  // (that last one twice - this period and the previous one, for the delta).
  // Each of those used to re-group every exchange rate into a fresh nested map
  // and re-sort every per-pair list from scratch: five-plus O(n log n) rebuilds
  // per gesture over rate rows that were identical from the first rebuild to
  // the last. On top of that sat one rate resolution per ACCOUNT and one per
  // TRANSACTION ROW, each rescanning up to four pair lists (direct, inverse,
  // two pivot legs) for an answer a sibling call had already worked out.
  //
  // Validity is checked, never assumed. A cached index is reused only when the
  // caller hands back the very same List instance AND that instance still
  // hashes to what it hashed to when the index was built. Identity alone would
  // survive `rates.add(...)` on the growable list the bloc state holds, and a
  // cache that keeps answering from rates the user has since edited is the
  // "totals stay wrong until you restart the app" bug - strictly worse than the
  // lag it fixes. The fingerprint is an O(n) walk over immutable value objects;
  // what it guards is an O(n log n) rebuild plus a map and a list allocation
  // per currency pair.
  //
  // Not thread-safe, and does not need to be: every method here is synchronous,
  // so no await can interleave inside one, and Dart runs them on a single
  // isolate. The instance is nonetheless SHARED - injection_container registers
  // one lazy singleton (the accounts bloc's), while dashboard_bloc news up its
  // own - so two callers alternating with DIFFERENT rate lists would thrash
  // these caches back to today's cost. They do not share an instance today, and
  // if they ever do, the answers stay correct; only the speedup is lost.

  List<ExchangeRateDomain>? _rateSource;
  int _rateSourceHash = 0;
  Map<String, Map<String, List<ExchangeRateDomain>>>? _rateIndex;

  List<InflationRateDomain>? _inflationSource;
  int _inflationSourceHash = 0;
  Map<String, List<InflationRateDomain>>? _inflationIndex;

  /// Resolved rates, keyed by everything the answer depends on that the index
  /// generation does not already pin down: the pair, the exact instant, and the
  /// currency the pivots are picked for. Dropped whenever an index is rebuilt,
  /// so an entry can never outlive the rows it was derived from.
  final Map<(String, String, int, String), double?> _resolvedRates = {};

  /// The same contract for inflation: (country, start instant, end instant).
  final Map<(String, int, int), double> _resolvedMultipliers = {};

  /// These maps grow with USE, not with the data - a walk-back over a year asks
  /// a fresh question per day - and the calculator is a process-lifetime
  /// singleton. Dropping the whole map on overflow re-earns entries that are,
  /// by the time it happens, overwhelmingly cold.
  static const int _memoLimit = 20000;

  /// Returns map of AccountId -> Nominal Balance
  ///
  /// For Asset Accounts: Quantity * Price at [data.date]
  /// For Standard Accounts: Initial + Sum(Transactions <= [data.date])
  ///
  /// A balance is `double.nan` when the asset's price currency cannot be
  /// converted to the account currency — see [_getExchangeRate].
  Map<String, double> calculateBalances(FinancialSnapshot data) {
    final balances = <String, double>{};

    // 1. Group transactions by account
    final transactionsByAccount = <String, List<Transaction>>{};
    for (final tx in data.transactions) {
      // Include ALL transactions.
      // For Standard Accounts (Reverse Calc), we need future transactions to subtract them.
      // For Forward Calc (if used), we would filter later.
      transactionsByAccount.putIfAbsent(tx.accountId, () => []).add(tx);
    }

    // 2. Pre-calculate asset values for the specific date
    // Optimization: Group asset data by assetId -> List<AssetDataDomain>
    final assetDataMap = <String, List<AssetDataDomain>>{};
    for (final entry in data.assetData) {
      assetDataMap.putIfAbsent(entry.assetId, () => []).add(entry);
    }
    // Finding #4: Pre-sort each asset's entries once (ascending by date)
    // instead of sorting inside the account loop on every calculateBalances call.
    for (final entries in assetDataMap.values) {
      entries.sort((a, b) => a.date.compareTo(b.date));
    }

    // Finding #2: Build exchange rate index once before the account loop.
    final rateIndex = _buildRateIndex(data.exchangeRates);

    for (final account in data.accounts) {
      double balance = 0.0;

      if (account.assetId != null &&
          assetDataMap.containsKey(account.assetId)) {
        // Asset Bound Logic
        final entries = assetDataMap[account.assetId]!;
        final targetDate = DateTime(
          data.date.year,
          data.date.month,
          data.date.day,
        );

        // Entries are pre-sorted ascending by date (done before the loop)

        // Find the first entry date (earliestEntry)
        final earliestEntry = entries.isNotEmpty ? entries.first : null;

        // If target date is BEFORE the earliest entry, we don't have data yet
        if (earliestEntry != null) {
          final earliestDate = DateTime(
            earliestEntry.date.year,
            earliestEntry.date.month,
            earliestEntry.date.day,
          );

          if (targetDate.isBefore(earliestDate)) {
            // Asset didn't exist yet at this date
            balance = 0.0;
          } else {
            // Find exact match or closest BEFORE/EQUAL the target date
            // For future dates (after last entry), use the last available entry
            AssetDataDomain? bestEntry;
            for (final e in entries) {
              final eDate = DateTime(e.date.year, e.date.month, e.date.day);
              if (eDate.isAtSameMomentAs(targetDate)) {
                // Exact match - use it
                bestEntry = e;
                break;
              } else if (eDate.isBefore(targetDate)) {
                // Closest before target - keep updating until we pass target
                bestEntry = e;
              } else {
                // Passed target date, stop
                break;
              }
            }

            // If no entry found (shouldn't happen since earliestDate check passed)
            // OR if target date is in the future (after all entries), use the last entry
            if (bestEntry == null && entries.isNotEmpty) {
              bestEntry = entries.last; // Use last known price for future dates
            }

            if (bestEntry != null) {
              // Calculate dynamic quantity from transactions
              double currentQuantity = account.assetQuantity;
              final accountTx = transactionsByAccount[account.id] ?? [];
              for (final tx in accountTx) {
                if (!tx.date.isAfter(data.date)) {
                  currentQuantity += tx.amount;
                }
              }

              double assetValue = bestEntry.value;
              if (bestEntry.currency != account.currencyCode) {
                final rate = _getExchangeRate(
                  bestEntry.currency,
                  account.currencyCode,
                  rateIndex,
                  data.date,
                  data.baseCurrency,
                );
                // Without a rate the holding's worth in the account's own
                // currency is unknown — not zero, and not the raw foreign
                // number. NaN keeps the account in the map (callers index it
                // with `!`) while refusing to state a figure the user could
                // act on, and it cannot be laundered into a total.
                assetValue = rate == null ? double.nan : assetValue * rate;
              }
              balance = assetValue * currentQuantity;
            } else {
              balance = 0.0;
            }
          }
        } else {
          balance = 0.0;
        }
      } else {
        // Standard Logic: Reverse Calculation from Anchor
        // We assume account.balance is the "Latest" state including ALL transactions in history.
        // To get balance at [data.date], we subtract transactions that happened AFTER [data.date].

        double calculatedBalance = account.balance;

        final accountTx = transactionsByAccount[account.id] ?? [];
        for (final tx in accountTx) {
          // If transaction is AFTER the target date, we must "undo" it to get back to the state at date.
          if (tx.date.isAfter(data.date)) {
            calculatedBalance -= tx.amount;
          }
        }
        balance = calculatedBalance;
      }
      balances[account.id!] = balance;
    }

    return balances;
  }

  /// Returns map of AccountId -> Real Balance
  ///
  /// Adjusts Nominal Balance to Present Value using Inflation Rates.
  /// Formula: Real = Nominal * Product(1 + Rate) for all rates between [data.date] and Now.
  Map<String, double> calculateRealBalances(
    FinancialSnapshot data, {
    String? defaultCountry,
    Map<String, double>? balances,
  }) {
    balances ??= calculateBalances(data);
    final realBalances = <String, double>{};
    // Grouped and sorted once per rate LIST rather than once per call - see
    // [_buildInflationIndex].
    final ratesByCountry = _buildInflationIndex(data.inflationRates);

    // Finding #3: Build account lookup map once for O(1) access
    // instead of O(A) firstWhere scan inside the loop.
    final accountMap = <String, Account>{
      for (final a in data.accounts)
        if (a.id != null) a.id!: a,
    };

    for (final accountId in balances.keys) {
      final balance = balances[accountId]!;
      final account = accountMap[accountId]!;

      // Determine country: Account's country > Default > null
      final country = account.country ?? defaultCountry;

      // New Strategy: Deflate to Account Creation Date (Anchor)
      // Real Value = Nominal / (1 + Cumulative Inflation)
      // This shows purchasing power relative to when the account started.
      final anchorDate = account.creationDate;

      // A multiplier is specific to (Country, Anchor, Current Date), so all
      // three are the memo key: keyed on country alone, as the old note here
      // wondered about, an account would inherit the deflation of some other
      // account's creation date.
      double multiplier = _inflationMultiplier(
        country,
        anchorDate,
        data.date,
        ratesByCountry,
      );

      // Avoid division by zero (though multiplier starts at 1.0 and goes up with positive inflation)
      if (multiplier == 0) multiplier = 1.0;

      realBalances[accountId] = balance / multiplier;
    }
    return realBalances;
  }

  double _calculateInflationMultiplier(
    DateTime start,
    DateTime end,
    List<InflationRateDomain> rates,
  ) {
    // debugPrint('  Calc Multiplier for $start to $end with ${rates.length} rates');
    double multiplier = 1.0;

    // Rates should be pre-sorted outside this method for performance

    for (final rate in rates) {
      // Logic: Treat 'rate' as Annual Inflation for the Calendar Year of rate.date
      // Example: Rate 12% at 2024-06-01 means "2024 has 12% inflation".

      final rateYearStart = DateTime(rate.date.year, 1, 1);
      final rateYearEnd = DateTime(rate.date.year, 12, 31, 23, 59, 59);

      // Calculate Overlap between [start, end] and [rateYearStart, rateYearEnd]
      final overlapStart = start.isAfter(rateYearStart) ? start : rateYearStart;
      final overlapEnd = end.isBefore(rateYearEnd) ? end : rateYearEnd;

      if (overlapEnd.isAfter(overlapStart)) {
        final overlapDuration = overlapEnd.difference(overlapStart);
        // The length of THIS year, not a flat 365 days. A leap year is 366 of
        // them, so a balance held through one used to be deflated by the
        // year's inflation raised to 1.0027 - a whole year's rate applied and
        // then a little more, compounding over every leap year in an account's
        // life. Measured with the constructor rather than by adding a
        // duration, so a clock change inside the year is counted the way the
        // overlap above already counts it.
        final yearDuration = DateTime(
          rate.date.year + 1,
          1,
          1,
        ).difference(rateYearStart);

        // Fraction of the year covered
        final fraction = overlapDuration.inSeconds / yearDuration.inSeconds;

        // Annual Rate = r.
        // Effective Rate for fraction = (1+r)^fraction - 1?
        // OR simply linear scalar if rate is "Annualized"?
        // Most accurately: (1 + r)^fraction

        final partialMultiplier = pow(1 + (rate.percent / 100), fraction);
        multiplier *= partialMultiplier;

        // debugPrint('    Rate ${rate.percent}% in ${rate.date.year}: Fraction $fraction -> Partial $partialMultiplier');
      }
    }
    // debugPrint('  Total Multiplier: $multiplier');
    return multiplier;
  }

  /// Returns Total Net Worth in Base Currency
  ///
  /// Sum of all (Real or Nominal?) balances converted to [data.baseCurrency].
  /// Returns `double.nan` if any account cannot be converted, because a
  /// partial sum is indistinguishable from a correct one.
  double calculateTotalNetWorth(
    FinancialSnapshot data, {
    Map<String, double>? balances,
  }) {
    balances ??= calculateBalances(data);
    double total = 0.0;

    // Finding #3: Build account lookup map once for O(1) access.
    final accountMap = <String, Account>{
      for (final a in data.accounts)
        if (a.id != null) a.id!: a,
    };
    // Finding #2: Build exchange rate index once for O(1) lookup.
    final rateIndex = _buildRateIndex(data.exchangeRates);

    for (final accountId in balances.keys) {
      final balance = balances[accountId]!;
      final account = accountMap[accountId]!;

      final rate = _getExchangeRate(
        account.currencyCode,
        data.baseCurrency,
        rateIndex,
        data.date,
        data.baseCurrency,
      );
      if (rate == null) {
        // An account we cannot price in the base currency makes the TOTAL
        // unknown, not smaller: quietly dropping it would return a
        // plausible-looking net worth that leaves real money out. NaN is
        // sticky under the `+=` below, so the rest of the loop still runs.
        total = double.nan;
        continue;
      }

      total += balance * rate;
    }
    return total;
  }

  /// Returns map of CurrencyCode -> total value in [data.baseCurrency].
  ///
  /// A bucket is `double.nan` when that currency cannot be converted; the
  /// other buckets stay valid.
  Map<String, double> calculateCurrencyBreakdown(
    FinancialSnapshot data, {
    Map<String, double>? balances,
  }) {
    balances ??= calculateBalances(data);
    final breakdown = <String, double>{};

    // Finding #3: Build account lookup map once for O(1) access.
    final accountMap = <String, Account>{
      for (final a in data.accounts)
        if (a.id != null) a.id!: a,
    };
    // Finding #2: Build exchange rate index once for O(1) lookup.
    final rateIndex = _buildRateIndex(data.exchangeRates);

    for (final accountId in balances.keys) {
      final balance = balances[accountId]!;
      final account = accountMap[accountId]!;

      final rate = _getExchangeRate(
        account.currencyCode,
        data.baseCurrency,
        rateIndex,
        data.date,
        data.baseCurrency,
      );

      // Only the bucket for the unpriceable currency is unknown; the other
      // currencies in the breakdown are unaffected, so poison just this one.
      final valueInBase = rate == null ? double.nan : balance * rate;
      breakdown[account.currencyCode] =
          (breakdown[account.currencyCode] ?? 0.0) + valueInBase;
    }
    return breakdown;
  }

  /// Finding #2: Builds a pre-grouped, pre-sorted exchange rate index.
  /// Only includes rates with [ExchangeRateDomain.preset] == 1.
  /// Each inner list is sorted descending by date (most recent first).
  /// Call once per snapshot and pass the result to [_getExchangeRate].
  ///
  /// Cached per rate list - see the cache notes at the top of the class. The
  /// grouping order and the sort are untouched, so a rebuilt index is
  /// element-for-element what the old unconditional build produced and two rows
  /// sharing a date still resolve to the same one.
  Map<String, Map<String, List<ExchangeRateDomain>>> _buildRateIndex(
    List<ExchangeRateDomain> rates,
  ) {
    final cached = _rateIndex;
    final hash = Object.hashAll(rates);
    if (cached != null &&
        identical(_rateSource, rates) &&
        _rateSourceHash == hash) {
      return cached;
    }

    final index = <String, Map<String, List<ExchangeRateDomain>>>{};
    for (final rate in rates) {
      if (rate.preset != 1) continue;
      index
          .putIfAbsent(rate.fromCurrencyCode, () => {})
          .putIfAbsent(rate.toCurrencyCode, () => [])
          .add(rate);
    }
    // Sort each list descending by date (most recent first) — done once.
    for (final inner in index.values) {
      for (final list in inner.values) {
        list.sort((a, b) => b.date.compareTo(a.date));
      }
    }

    // Every resolved rate was derived from the rows we just replaced; they say
    // nothing about these ones.
    _resolvedRates.clear();
    _rateSource = rates;
    _rateSourceHash = hash;
    _rateIndex = index;
    return index;
  }

  /// Inflation rates grouped by country, each group sorted ascending by date.
  ///
  /// Built exactly the way the two inline copies it replaces were built - drop
  /// rows with no country, group in list order, sort each group ascending - so
  /// [_calculateInflationMultiplier] multiplies the same rates in the same
  /// order. That order is load-bearing: floating-point multiplication is not
  /// associative, and this change must not move a single returned figure.
  ///
  /// Cached on the same terms as [_buildRateIndex]. The lists handed out are
  /// shared across calls: read them, never sort or add to them.
  Map<String, List<InflationRateDomain>> _buildInflationIndex(
    List<InflationRateDomain> rates,
  ) {
    final cached = _inflationIndex;
    final hash = Object.hashAll(rates);
    if (cached != null &&
        identical(_inflationSource, rates) &&
        _inflationSourceHash == hash) {
      return cached;
    }

    final index = <String, List<InflationRateDomain>>{};
    for (final r in rates) {
      if (r.country != null) {
        index.putIfAbsent(r.country!, () => []).add(r);
      }
    }
    for (final group in index.values) {
      group.sort((a, b) => a.date.compareTo(b.date));
    }

    _resolvedMultipliers.clear();
    _inflationSource = rates;
    _inflationSourceHash = hash;
    _inflationIndex = index;
    return index;
  }

  /// [_calculateInflationMultiplier] for [country], memoized on the exact
  /// (country, start instant, end instant) triple.
  ///
  /// calculatePeriodStats asks this once per transaction row and
  /// calculateRealBalances once per account, and the question repeats hard:
  /// every account opened on the same day in the same country, and every
  /// transaction sharing an instant, asked for a number that was then
  /// recomputed by walking that country's entire rate history again.
  ///
  /// Answers are only served against the index this class built and still owns.
  /// An index from anywhere else resolves from scratch, because nothing here
  /// knows which rows are in it.
  double _inflationMultiplier(
    String? country,
    DateTime start,
    DateTime end,
    Map<String, List<InflationRateDomain>> index,
  ) {
    if (country == null) return 1.0;
    final rates = index[country] ?? const <InflationRateDomain>[];
    if (!identical(index, _inflationIndex)) {
      return _calculateInflationMultiplier(start, end, rates);
    }

    final key = (
      country,
      start.microsecondsSinceEpoch,
      end.microsecondsSinceEpoch,
    );
    final hit = _resolvedMultipliers[key];
    if (hit != null) return hit;

    final value = _calculateInflationMultiplier(start, end, rates);
    if (_resolvedMultipliers.length >= _memoLimit) _resolvedMultipliers.clear();
    _resolvedMultipliers[key] = value;
    return value;
  }

  /// Most recent [from]->[to] rate dated at or before [date], or null.
  ///
  /// Only rows already in effect are eligible: a valuation dated in the past
  /// must not be priced with a rate that did not exist yet.
  ExchangeRateDomain? _latestRateAtOrBefore(
    Map<String, Map<String, List<ExchangeRateDomain>>> rateIndex,
    String from,
    String to,
    DateTime date,
  ) {
    final candidates = rateIndex[from]?[to];
    if (candidates == null) return null;
    // Lists are pre-sorted descending by date, so "not in the future" is a
    // monotone predicate over the list: false while we are still above [date],
    // true from the first eligible row onwards. Binary-searching for that first
    // true row lands on the row the linear scan returned - the LOWEST eligible
    // index, so two rows sharing a date still break the tie the same way -
    // while a pair carrying a year of daily rows costs nine comparisons rather
    // than up to three hundred and sixty-five, per leg, per lookup, per
    // transaction row.
    var lo = 0;
    var hi = candidates.length;
    while (lo < hi) {
      final mid = lo + ((hi - lo) >> 1);
      if (candidates[mid].date.isAfter(date)) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo < candidates.length ? candidates[lo] : null;
  }

  /// The currencies worth pivoting a triangular conversion through: the
  /// caller's [mainCurrency] first, then the currency the table is anchored on.
  ///
  /// [mainCurrency] is the currency the *result* is shown in, which callers
  /// change whenever the user switches the dashboard currency. A rate table is
  /// anchored on whatever it was fetched against — here every row is `EUR -> X`
  /// — so pivoting through the display currency asked for rows like
  /// `RUB -> ETH` that were never stored, and priced nothing. The anchor is the
  /// `from` code that reaches the most other currencies, read off the index, so
  /// no setting has to be correct for a total to add up.
  ///
  /// Memoized on the index and the currency it was computed for: the walk-back
  /// asks for a rate once per account per day, and rebuilding a two-element
  /// list that many times is pure waste.
  Map<String, Map<String, List<ExchangeRateDomain>>>? _pivotIndex;
  String? _pivotMainCurrency;
  List<String>? _pivotCache;

  List<String> _pivotsFor(
    Map<String, Map<String, List<ExchangeRateDomain>>> rateIndex,
    String mainCurrency,
  ) {
    if (identical(_pivotIndex, rateIndex) &&
        _pivotMainCurrency == mainCurrency) {
      return _pivotCache!;
    }
    final pivots = <String>[mainCurrency];
    String? anchor;
    int anchorReach = 0;
    for (final entry in rateIndex.entries) {
      if (entry.value.length > anchorReach) {
        anchor = entry.key;
        anchorReach = entry.value.length;
      }
    }
    // One pair stored the other way round is not an anchor: an anchor is a
    // currency that prices many others.
    if (anchor != null && anchor != mainCurrency && anchorReach > 1) {
      pivots.add(anchor);
    }
    _pivotIndex = rateIndex;
    _pivotMainCurrency = mainCurrency;
    _pivotCache = pivots;
    return pivots;
  }

  /// Resolves [from]->[to] at [date], or **null** when no rate can be derived.
  ///
  /// Same "smart search" shape as CurrencyConverterService.getExchangeRate:
  /// direct, inverse, then triangular through [mainCurrency].
  ///
  /// Null rather than 1.0 is deliberate. Parity is only ever true for
  /// identical codes; handing back 1.0 for an unresolved pair made the
  /// calculator add e.g. JPY straight onto USD, producing totals that were
  /// simply wrong with nothing on screen to indicate it.
  double? _getExchangeRate(
    String from,
    String to,
    Map<String, Map<String, List<ExchangeRateDomain>>> rateIndex,
    DateTime date,
    String mainCurrency,
  ) {
    if (from == to) return 1.0;

    // Memoized on every input the answer depends on: the pair, the exact
    // instant, the currency the pivots are chosen for, and - through the index
    // generation, which clears this map - the rate rows themselves.
    // calculateTotalNetWorth and calculateCurrencyBreakdown each ask
    // (accountCurrency -> base) at the SAME snapshot date once per account, and
    // calculatePeriodStats asks once per transaction row; every miss walks up
    // to four pair lists and ranks three candidates. Same shape as
    // CurrencyConverter._resolved, plus the key components this class needs
    // because its index, unlike that one's, is not final.
    final memoized = identical(rateIndex, _rateIndex);
    final key = (from, to, date.microsecondsSinceEpoch, mainCurrency);
    if (memoized && _resolvedRates.containsKey(key)) return _resolvedRates[key];

    double? bestRate;
    DateTime? bestDate;

    // Every candidate is dated at or before [date], so "closest to the
    // target" reduces to "latest". Ties keep the incumbent, which makes the
    // order of the offers below the tie-break: direct, then inverse, then
    // triangular.
    void offer(double rate, DateTime rateDate) {
      if (bestDate == null || rateDate.isAfter(bestDate!)) {
        bestRate = rate;
        bestDate = rateDate;
      }
    }

    final direct = _latestRateAtOrBefore(rateIndex, from, to, date);
    if (direct != null) offer(direct.rate, direct.date);

    // Stored as "1 [to] = X [from]", so the [from]->[to] rate is 1/X.
    final inverse = _latestRateAtOrBefore(rateIndex, to, from, date);
    if (inverse != null && inverse.rate != 0) {
      offer(1.0 / inverse.rate, inverse.date);
    }

    // Triangular: Value(to) = Value(from) * Rate(pivot->to) / Rate(pivot->from).
    for (final pivot in _pivotsFor(rateIndex, mainCurrency)) {
      // Skipped when either side already IS the pivot — that pairing
      // degenerates into the direct/inverse lookups already tried above.
      if (from == pivot || to == pivot) continue;
      final mainToFrom = _latestRateAtOrBefore(rateIndex, pivot, from, date);
      final mainToTo = _latestRateAtOrBefore(rateIndex, pivot, to, date);
      if (mainToFrom != null && mainToTo != null && mainToFrom.rate != 0) {
        // A triangular rate is only as fresh as its STALEST leg — ranking it
        // by the closer leg would let a pairing of (today, three years ago)
        // beat an honest same-week direct rate.
        final effectiveDate = mainToFrom.date.isBefore(mainToTo.date)
            ? mainToFrom.date
            : mainToTo.date;
        offer(mainToTo.rate / mainToFrom.rate, effectiveDate);
      }
    }

    if (memoized) {
      // Null is an answer too: for this generation of rows the pair is simply
      // underivable, and re-deriving nothing costs the same four scans.
      if (_resolvedRates.length >= _memoLimit) _resolvedRates.clear();
      _resolvedRates[key] = bestRate;
    }
    return bestRate;
  }

  /// Returns Income/Expense for a specific period
  ///
  /// [PeriodStats.totalIncome]/[PeriodStats.totalExpense] are `double.nan`
  /// when a transaction cannot be converted to [data.baseCurrency]; the
  /// per-account maps are in account currency and stay valid regardless.
  PeriodStats calculatePeriodStats(
    FinancialSnapshot data,
    DatePeriod period, {
    String? defaultCountry,
  }) {
    // 1. Filter Transactions
    // Assumption: Income > 0, Expense < 0.
    final periodTx = data.transactions.where(
      (tx) =>
          (tx.date.isAfter(period.start) ||
              tx.date.isAtSameMomentAs(period.start)) &&
          (tx.date.isBefore(period.end) ||
              tx.date.isAtSameMomentAs(period.end)),
    );

    final incomeMap = <String, double>{};
    final expenseMap = <String, double>{};
    final realIncomeMap = <String, double>{};
    final realExpenseMap = <String, double>{};

    double totalIncome = 0.0;
    double totalExpense = 0.0;

    // Grouped and sorted once per rate LIST rather than once per call - see
    // [_buildInflationIndex]. This method runs TWICE per period switch (current
    // period and previous), and each run used to redo the grouping and the sort.
    final ratesByCountry = _buildInflationIndex(data.inflationRates);

    // Map Category types for quick lookup
    final categoryTypes = <String, CategoryType>{};
    for (final cat in data.categories) {
      if (cat.id != null) {
        categoryTypes[cat.id!] = cat.type;
      }
    }

    // Map Accounts for O(1) lookup
    final accountMap = {for (var a in data.accounts) a.id: a};
    // Finding #2: Build exchange rate index once for O(1) lookup.
    final rateIndex = _buildRateIndex(data.exchangeRates);

    for (final tx in periodTx) {
      // Filter out Transfers
      final type = categoryTypes[tx.categoryId];
      if (type == CategoryType.transfer) {
        continue;
      }

      final account = accountMap[tx.accountId];
      // Exclude Asset Quantity Transactions from Income/Expense Stats
      // (Assets are tracked via Net Worth / Asset Value, not Income flows)
      if (account?.assetId != null) {
        continue;
      }

      final amount = tx.amount;
      // Aggregating by AccountId
      final accountId = tx.accountId;

      // Calculate Total in Base Currency
      final toBaseRate = _getExchangeRate(
        tx.currencyCode,
        data.baseCurrency,
        rateIndex,
        tx.date,
        data.baseCurrency,
      );
      // A transaction we cannot price in the base currency poisons only the
      // base-currency totals — the per-account maps below stay in the
      // account's own currency and remain valid.
      final amountInBase = amount * (toBaseRate ?? double.nan);

      // Nominal Stats (Per Account, in Account Currency)
      if (amount > 0) {
        incomeMap[accountId] = (incomeMap[accountId] ?? 0.0) + amount;
        totalIncome += amountInBase;
      } else {
        expenseMap[accountId] = (expenseMap[accountId] ?? 0.0) + amount;
        totalExpense += amountInBase;
      }

      // Real Stats (Adjusted to Now)
      // We need to resolve Account -> Country for inflation.
      double multiplier = 1.0;
      final country = account?.country ?? defaultCountry;

      if (account != null) {
        multiplier = _inflationMultiplier(
          country,
          account.creationDate,
          tx.date,
          ratesByCountry,
        );
      }

      if (multiplier == 0) multiplier = 1.0;

      final realAmount = amount / multiplier;
      if (realAmount > 0) {
        realIncomeMap[accountId] =
            (realIncomeMap[accountId] ?? 0.0) + realAmount;
      } else {
        realExpenseMap[accountId] =
            (realExpenseMap[accountId] ?? 0.0) + realAmount;
      }
    }

    return PeriodStats(
      income: incomeMap,
      expense: expenseMap,
      realIncome: realIncomeMap,
      realExpense: realExpenseMap,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
    );
  }

  /// Returns percentage change vs previous period
  /// ((Current - Previous) / |Previous|) * 100
  /// Returns 0.0 if Previous is 0.
  double calculatePercentageChange(double currentValue, double previousValue) {
    if (previousValue == 0) return 0.0;
    return ((currentValue - previousValue) / previousValue.abs()) * 100;
  }

  /// Returns map of AccountId -> AssetStats
  /// Calculates Net Balance (Post-Exit), Invested, Realized, and Commissions.
  ///
  /// Cross-currency cash legs are priced at the *transaction's* date, so
  /// invested/realized are a true historical cost basis. They are
  /// `double.nan` when such a leg cannot be converted.
  Map<String, AssetStats> calculateAssetStats(
    FinancialSnapshot data, {
    Map<String, double>? balances,
  }) {
    final stats = <String, AssetStats>{};
    balances ??= calculateBalances(data);

    // Group transactions by account
    final transactionsByAccount = <String, List<Transaction>>{};
    for (final tx in data.transactions) {
      transactionsByAccount.putIfAbsent(tx.accountId, () => []).add(tx);
    }

    // Build a map for fast lookup of linked transactions
    final txMap = {
      for (var tx in data.transactions)
        if (tx.id != null) tx.id!: tx,
    };

    // Finding #2: Build exchange rate index once for O(1) lookup.
    final rateIndex = _buildRateIndex(data.exchangeRates);

    for (final account in data.accounts) {
      if (account.assetId == null) continue;

      final nominalBalance = balances[account.id] ?? 0.0;
      final feeStructure = account.feeStructure;

      // 1. Net Balance (Exit Strategy)
      final netBalance = FeeCalculator.calculateNetValue(
        nominalValue: nominalBalance,
        feeStructureJson: feeStructure,
      );

      // 2. Historical Stats
      double invested = 0.0;
      double realized = 0.0;
      double commissions = 0.0;

      final accountTx = transactionsByAccount[account.id] ?? [];

      for (final tx in accountTx) {
        // Filter out transactions after the snapshot date
        if (tx.date.isAfter(data.date)) {
          continue;
        }

        commissions += tx.fee;

        double cashValue = 0.0;
        if (tx.linkedTransactionId != null &&
            txMap.containsKey(tx.linkedTransactionId)) {
          final linkedTx = txMap[tx.linkedTransactionId]!;
          double linkedAmount = linkedTx.amount.abs();

          // Convert Linked Currency (Cash) -> Account Currency (Asset)
          if (linkedTx.currencyCode != account.currencyCode) {
            final rate = _getExchangeRate(
              linkedTx.currencyCode,
              account.currencyCode,
              rateIndex,
              // Cost basis is what the trade actually cost when it happened,
              // so it must be priced at the trade's own date. The snapshot
              // date used to sit here, which restated every historical
              // cross-currency buy/sell at a near-today rate.
              tx.date,
              data.baseCurrency,
            );
            // No rate means this leg's cost basis is unknown; NaN propagates
            // into invested/realized rather than quietly counting the raw
            // foreign amount as if it were account currency.
            linkedAmount *= rate ?? double.nan;
          }
          cashValue = linkedAmount;
        }

        if (tx.amount > 0) {
          // Buy / Inflow
          invested += cashValue;
        } else {
          // Sell / Outflow
          realized += cashValue;
        }
      }

      stats[account.id!] = AssetStats(
        accountId: account.id!,
        nominalBalance: nominalBalance,
        netBalance: netBalance,
        invested: invested,
        realized: realized,
        commissions: commissions,
      );
    }

    return stats;
  }
}

class AssetStats {
  final String accountId;
  final double nominalBalance; // Market Value
  final double netBalance; // Exit Value (After Fees)
  final double invested; // Total Inflow + Fees
  final double realized; // Total Outflow - Fees
  final double commissions; // Total Fees Paid

  AssetStats({
    required this.accountId,
    required this.nominalBalance,
    required this.netBalance,
    required this.invested,
    required this.realized,
    required this.commissions,
  });
}
