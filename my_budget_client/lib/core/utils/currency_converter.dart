import 'package:my_budget_client/domain/entities/exchange_rate.dart';

/// A resolved rate together with the date of the row it came from. The date is
/// what lets competing candidates (direct / inverse / triangular) be ranked
/// against each other by freshness.
typedef DatedRate = ({double rate, DateTime date});

/// Synchronous, isolate-safe currency conversion over a pre-loaded list of
/// exchange rates.
///
/// Mirrors the algorithm of `CurrencyConverterService` (async, DB-backed) and
/// `FinanceCalculator._getExchangeRate` (sync, in-memory): for a pair and a
/// date it gathers a direct rate, an inverse rate and a triangular rate pivoted
/// through [baseCurrency], then keeps whichever candidate is dated closest to
/// the requested date. Each leg is the *nearest* stored row on either side of
/// the target date, not merely the newest row at or before it.
class CurrencyConverter {
  final Map<String, Map<String, List<ExchangeRateDomain>>> _groupedRates = {};
  final List<ExchangeRateDomain> rates;

  /// The pivot used for triangular conversion — the user's main currency.
  ///
  /// Deliberately has no default. This used to be a hardcoded `'EUR'`, which
  /// silently produced wrong (or zero) totals for every user whose rate set is
  /// anchored on something else. A required parameter makes the caller say
  /// which currency the rate table is actually built around.
  final String baseCurrency;

  /// The currencies worth pivoting a triangular conversion through, in the
  /// order they are tried.
  ///
  /// [baseCurrency] is what the caller asked for, but callers pass the currency
  /// the result is displayed in — and a rate table is anchored on whatever
  /// currency it was fetched against, which is a different thing. This app's
  /// rates are all stored as `EUR -> X`, so viewing the dashboard in RUB used
  /// to make every pivot lookup ask for `RUB -> ETH`, find nothing, and report
  /// ETH, RSD, USD and USDT as unconvertible while the rows to price them sat
  /// in the table. The anchor is recovered from the data itself, so no setting
  /// has to be right for a total to add up.
  late final List<String> _pivots = _resolvePivots();

  /// Answers already worked out, keyed by the question.
  final Map<_MemoKey, DatedRate?> _resolved = {};

  CurrencyConverter(this.rates, {required this.baseCurrency}) {
    // Ascending by date: _findRate scans in this order, and scanning ascending
    // is what makes a distance tie resolve to the EARLIER row (see below).
    final sortedRates = rates.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    for (final rate in sortedRates) {
      _groupedRates
          .putIfAbsent(rate.fromCurrencyCode, () => {})
          .putIfAbsent(rate.toCurrencyCode, () => [])
          .add(rate);
    }
  }

  /// [baseCurrency], then the currency the stored table is actually anchored
  /// on — the `from` code that prices the most other currencies.
  List<String> _resolvePivots() {
    final pivots = <String>[baseCurrency];
    String? anchor;
    int anchorReach = 0;
    for (final entry in _groupedRates.entries) {
      if (entry.value.length > anchorReach) {
        anchor = entry.key;
        anchorReach = entry.value.length;
      }
    }
    // One pair stored the other way round must not be promoted to pivot: an
    // anchor is a currency that prices many others.
    if (anchor != null && anchor != baseCurrency && anchorReach > 1) {
      pivots.add(anchor);
    }
    return pivots;
  }

  /// The stored [from]->[to] row whose date is nearest [date], on **either**
  /// side of it, or null when the pair is not stored at all.
  ///
  /// Looking only backwards (the previous behaviour) meant a transaction dated
  /// before the earliest stored row for a pair found nothing at all, even with
  /// a rate one day later sitting in the table. Ties go to the earlier row: a
  /// rate already in effect on the target day is a better estimate than one
  /// that only came into effect afterwards.
  DatedRate? _findRate(String from, String to, DateTime date) {
    final candidates = _groupedRates[from]?[to];
    if (candidates == null || candidates.isEmpty) return null;

    ExchangeRateDomain? best;
    Duration? bestDist;
    for (final r in candidates) {
      final dist = r.date.difference(date).abs();
      // Dates ascend, so distance falls until the list crosses [date] and then
      // rises — the first increase is past the minimum. Strict `<` keeps the
      // incumbent on a tie, and the incumbent is always the earlier row.
      if (bestDist != null && dist > bestDist) break;
      if (bestDist == null || dist < bestDist) {
        best = r;
        bestDist = dist;
      }
    }

    if (best == null) return null;
    return (rate: best.rate, date: best.date);
  }

  /// Resolves [from]->[to] at [date], or null when no path exists.
  ///
  /// 1. Direct rate (from -> to)
  /// 2. Inverse rate (to -> from) => 1/rate
  /// 3. Triangular through [baseCurrency] => Rate(base->to) / Rate(base->from)
  ///
  /// The winner is the candidate dated closest to [date], not the first one
  /// found — a same-week direct rate should beat a triangular pairing built
  /// from rows years away.
  DatedRate? resolveRate(String from, String to, DateTime date) {
    if (from == to) return (rate: 1.0, date: date);

    // The answer depends only on (from, to, date) and the rate list, which
    // cannot change - `rates` is final and the grouping is built once in the
    // constructor. The dashboard's net-worth walk-back asks the same handful
    // of questions once per account per day: a hundred accounts over a year is
    // thirty-six thousand calls resolving a few dozen distinct pairs, each one
    // re-scanning the stored rows for the pair and re-ranking three candidates.
    final key = _MemoKey(from, to, date.millisecondsSinceEpoch);
    final memo = _resolved;
    if (memo.containsKey(key)) return memo[key];

    double? bestRate;
    DateTime? bestDate;

    void offer(double rate, DateTime rateDate) {
      if (bestDate == null) {
        bestRate = rate;
        bestDate = rateDate;
        return;
      }
      final distCurrent = bestDate!.difference(date).abs();
      final distNew = rateDate.difference(date).abs();
      if (distNew < distCurrent) {
        bestRate = rate;
        bestDate = rateDate;
      }
    }

    final direct = _findRate(from, to, date);
    if (direct != null) offer(direct.rate, direct.date);

    // Stored as "1 [to] = X [from]", so the [from]->[to] rate is 1/X. The
    // `!= 0` guard keeps a placeholder zero row from yielding an infinity.
    final inverse = _findRate(to, from, date);
    if (inverse != null && inverse.rate != 0) {
      offer(1.0 / inverse.rate, inverse.date);
    }

    for (final pivot in _pivots) {
      // Skipped when either side already IS the pivot — that pairing
      // degenerates into the direct/inverse lookups already tried above.
      if (from == pivot || to == pivot) continue;
      final baseToFrom = _findRate(pivot, from, date);
      final baseToTo = _findRate(pivot, to, date);
      if (baseToFrom != null && baseToTo != null && baseToFrom.rate != 0) {
        // A triangular rate is only as fresh as its STALEST leg — ranking it
        // by the closer leg would let a pairing of (today, three years ago)
        // beat an honest same-week direct rate.
        final distFrom = baseToFrom.date.difference(date).abs();
        final distTo = baseToTo.date.difference(date).abs();
        final effectiveDate = distFrom >= distTo
            ? baseToFrom.date
            : baseToTo.date;
        offer(baseToTo.rate / baseToFrom.rate, effectiveDate);
      }
    }

    final rate = bestRate;
    // A pair with no path is memoised as null too: an unconvertible currency is
    // asked about just as often as a convertible one, and it is the expensive
    // case - every candidate is tried and every one of them misses.
    final DatedRate? resolved = rate == null
        ? null
        : (rate: rate, date: bestDate!);
    memo[key] = resolved;
    return resolved;
  }

  /// Converts [amount] from [from] to [to] as of [date], or **null** when the
  /// pair cannot be priced at all.
  ///
  /// Prefer this over [convert] wherever the result is summed: null is the
  /// caller's cue to leave the amount out of the total *and say so*, rather
  /// than let it vanish silently.
  double? tryConvert({
    required double amount,
    required String from,
    required String to,
    required DateTime date,
  }) {
    if (from == to) return amount;

    final resolved = resolveRate(from, to, date);
    if (resolved == null) return null;
    return amount * resolved.rate;
  }

  /// Converts [amount] from [from] to [to] as of [date], returning
  /// `double.nan` when no conversion path exists.
  ///
  /// NaN, not 0.0. Returning zero used to be justified as "prevents corrupting
  /// a total" — it did the opposite: a 5 000 USD account with no path to the
  /// target currency was counted as zero and simply disappeared from net
  /// worth, with nothing on screen to say so. NaN at least propagates, so a
  /// wrong total is visibly wrong instead of quietly wrong.
  ///
  /// Callers that must not poison a sum (charts, running totals) should use
  /// [tryConvert] and account for the miss explicitly.
  double convert({
    required double amount,
    required String from,
    required String to,
    required DateTime date,
  }) {
    return tryConvert(amount: amount, from: from, to: to, date: date) ??
        double.nan;
  }
}

/// A (from, to, date) question, as a value.
///
/// The date is carried as milliseconds rather than a [DateTime] so that two
/// instants that differ only by their `isUtc` flag - which `DateTime ==`
/// distinguishes and the rate lookup does not - do not split into two entries.
class _MemoKey {
  final String from;
  final String to;
  final int millis;

  const _MemoKey(this.from, this.to, this.millis);

  @override
  bool operator ==(Object other) =>
      other is _MemoKey &&
      other.from == from &&
      other.to == to &&
      other.millis == millis;

  @override
  int get hashCode => Object.hash(from, to, millis);
}
