import 'dart:async';

import 'package:my_budget_client/domain/entities/exchange_rate.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';

class CurrencyConverterService {
  final CurrencyRepository _currencyRepository;

  // OPTIMIZATION: Simple LRU cache for exchange rate lookups.
  // Key: "fromCode_toCode_YYYY-M-D_preset_mainCode"
  // Caches up to 500 entries to limit memory usage while improving hit rate.
  // A map literal is already a LinkedHashMap, so `keys.first` is the
  // oldest-inserted entry — which is what the LRU eviction below relies on.
  final _cache = <String, ExchangeRateDomain?>{};
  static const _maxCacheSize = 500;

  StreamSubscription<void>? _ratesChangedSub;

  CurrencyConverterService(this._currencyRepository) {
    // The cache is only sound while the underlying rate table is unchanged.
    // Adding a manual rate, importing history or refreshing from an API all
    // write to exchange_rates — drop the cache so the next lookup re-reads.
    _ratesChangedSub = _currencyRepository.watchExchangeRateChanges().listen(
      (_) => _cache.clear(),
    );
  }

  /// The main currency is part of the key because the triangular fallback
  /// derives the rate through it — the same pair/date can resolve differently
  /// after the user switches their main currency.
  String _cacheKey(
    String from,
    String to,
    DateTime date,
    int preset,
    String main,
  ) => '${from}_${to}_${date.year}-${date.month}-${date.day}_${preset}_$main';

  /// Invalidates the in-memory cache. Called automatically on any exchange
  /// rate write; exposed for callers that mutate rates out of band.
  void invalidateCache() => _cache.clear();

  /// Releases the rate-change subscription. Must be called when the service is
  /// discarded (tests, DI reset) — otherwise the subscription outlives it.
  Future<void> dispose() async {
    await _ratesChangedSub?.cancel();
    _ratesChangedSub = null;
    _cache.clear();
  }

  /// Returns the single rate for [from]->[to] whose date is nearest [date].
  ///
  /// Two `LIMIT 1` probes — the newest row at-or-before the target and the
  /// oldest row at-or-after it — instead of pulling a page of rows and
  /// scanning it in Dart. The page-scan was both slower and *wrong*: the
  /// repository defaults to `limit: 100`, so for a pair with years of daily
  /// history only the 100 most recent rows were ever considered and any older
  /// transaction silently converted at a rate hundreds of days off.
  Future<ExchangeRateDomain?> _nearestRate(
    String from,
    String to,
    DateTime date,
    int preset,
  ) async {
    final probes = await Future.wait([
      _currencyRepository.getExchangeRatesFiltered(
        fromCurrency: from,
        toCurrency: to,
        presets: [preset],
        endDate: date,
        sortAscending: false,
        limit: 1,
      ),
      _currencyRepository.getExchangeRatesFiltered(
        fromCurrency: from,
        toCurrency: to,
        presets: [preset],
        startDate: date,
        sortAscending: true,
        limit: 1,
      ),
    ]);

    final before = probes[0].isEmpty ? null : probes[0].first;
    final after = probes[1].isEmpty ? null : probes[1].first;

    if (before == null) return after;
    if (after == null) return before;

    final distBefore = before.date.difference(date).abs();
    final distAfter = after.date.difference(date).abs();
    // Ties go to the earlier row: a rate already in effect on the target day
    // is a better estimate than one that only came into effect later.
    return distAfter < distBefore ? after : before;
  }

  /// Finds the best exchange rate for a given pair and date using "Smart Search":
  /// 1. Direct Rate (From -> To)
  /// 2. Inverse Rate (To -> From) => 1/Rate
  /// 3. Triangular (Main -> From, Main -> To) => Rate(Main->To) / Rate(Main->From)
  Future<ExchangeRateDomain?> getExchangeRate({
    required String fromCurrencyCode,
    required String toCurrencyCode,
    required DateTime date,
    required String mainCurrencyCode,
    int preset = 1,
  }) async {
    if (fromCurrencyCode == toCurrencyCode) {
      return ExchangeRateDomain(
        fromCurrencyCode: fromCurrencyCode,
        toCurrencyCode: toCurrencyCode,
        rate: 1.0,
        date: date,
        preset: preset,
      );
    }

    // OPTIMIZATION: Check in-memory cache before making DB queries
    final key = _cacheKey(
      fromCurrencyCode,
      toCurrencyCode,
      date,
      preset,
      mainCurrencyCode,
    );
    if (_cache.containsKey(key)) {
      // Move to end for LRU eviction order
      final cached = _cache.remove(key);
      _cache[key] = cached;
      return cached;
    }

    final targetDate = date;
    double? bestRateValue;
    DateTime? bestDate;

    void tryUpdateBest(double rate, DateTime rateDate) {
      if (bestDate == null) {
        bestRateValue = rate;
        bestDate = rateDate;
      } else {
        final distCurrent = bestDate!.difference(targetDate).abs();
        final distNew = rateDate.difference(targetDate).abs();
        if (distNew < distCurrent) {
          bestRateValue = rate;
          bestDate = rateDate;
        }
      }
    }

    // 1./2./3. Direct, inverse and both triangular legs are independent
    // queries — issue them together instead of serially.
    final needsTriangular =
        fromCurrencyCode != mainCurrencyCode &&
        toCurrencyCode != mainCurrencyCode;

    final legs = await Future.wait([
      _nearestRate(fromCurrencyCode, toCurrencyCode, targetDate, preset),
      _nearestRate(toCurrencyCode, fromCurrencyCode, targetDate, preset),
      if (needsTriangular) ...[
        _nearestRate(mainCurrencyCode, fromCurrencyCode, targetDate, preset),
        _nearestRate(mainCurrencyCode, toCurrencyCode, targetDate, preset),
      ],
    ]);

    final direct = legs[0];
    if (direct != null) {
      tryUpdateBest(direct.rate, direct.date);
    }

    final inverse = legs[1];
    if (inverse != null && inverse.rate != 0) {
      tryUpdateBest(1.0 / inverse.rate, inverse.date);
    }

    if (needsTriangular) {
      final baseToFrom = legs[2];
      final baseToTo = legs[3];
      if (baseToFrom != null && baseToTo != null && baseToFrom.rate != 0) {
        final calculatedRate = baseToTo.rate / baseToFrom.rate;
        // A triangular rate is only as fresh as its STALEST leg — ranking it
        // by the closer leg would let a pairing of (today, three years ago)
        // beat an honest same-week direct rate.
        final distFrom = baseToFrom.date.difference(targetDate).abs();
        final distTo = baseToTo.date.difference(targetDate).abs();
        final effectiveDate = distFrom >= distTo
            ? baseToFrom.date
            : baseToTo.date;
        tryUpdateBest(calculatedRate, effectiveDate);
      }
    }

    // Store result in cache (evict oldest entry if at capacity)
    ExchangeRateDomain? result;
    if (bestRateValue != null) {
      result = ExchangeRateDomain(
        fromCurrencyCode: fromCurrencyCode,
        toCurrencyCode: toCurrencyCode,
        rate: bestRateValue!,
        date: bestDate!,
        preset: preset,
      );
    }
    if (_cache.length >= _maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = result;
    return result;
  }

  /// Converts an amount from one currency to another using the best available rate.
  Future<double?> convertAmount({
    required double amount,
    required String fromCurrencyCode,
    required String toCurrencyCode,
    required DateTime date,
    required String mainCurrencyCode,
    int preset = 1,
  }) async {
    if (fromCurrencyCode == toCurrencyCode) return amount;

    final rate = await getExchangeRate(
      fromCurrencyCode: fromCurrencyCode,
      toCurrencyCode: toCurrencyCode,
      date: date,
      mainCurrencyCode: mainCurrencyCode,
      preset: preset,
    );

    if (rate != null) {
      return amount * rate.rate;
    }

    return null;
  }

  /// Returns a list of exchange rates for all available presets.
  /// Preset 1 uses the "Smart Search" logic.
  /// Other presets use direct rates closest to the target date.
  Future<List<ExchangeRateDomain>> getAllExchangeRates({
    required String fromCurrencyCode,
    required String toCurrencyCode,
    required DateTime date,
    required String mainCurrencyCode,
  }) async {
    final List<ExchangeRateDomain> finalRates = [];

    // 1. Get Smart Rate for Preset 1
    final smartRate = await getExchangeRate(
      fromCurrencyCode: fromCurrencyCode,
      toCurrencyCode: toCurrencyCode,
      date: date,
      mainCurrencyCode: mainCurrencyCode,
      preset: 1,
    );
    if (smartRate != null) {
      finalRates.add(smartRate);
    }

    // 2. Get direct rates for other presets
    final directRates = await _currencyRepository.getExchangeRatesFiltered(
      fromCurrency: fromCurrencyCode,
      toCurrency: toCurrencyCode,
      sortAscending: false,
    );

    final Map<int, ExchangeRateDomain> devPresets = {};
    for (var r in directRates) {
      if (r.preset == 1) continue; // Already handled by smartRate if possible

      final current = devPresets[r.preset];
      if (current == null) {
        devPresets[r.preset] = r;
      } else {
        final distCurrent = current.date.difference(date).abs();
        final distNew = r.date.difference(date).abs();
        if (distNew < distCurrent) {
          devPresets[r.preset] = r;
        }
      }
    }

    finalRates.addAll(devPresets.values);
    finalRates.sort((a, b) => a.preset.compareTo(b.preset));

    return finalRates;
  }
}
