import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/currency_designation.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/domain/services/currency_converter_service.dart';

/// Hand-written fake — no mockito codegen. Mimics the subset of DB query
/// semantics [CurrencyConverterService] actually relies on:
/// exact from/to/preset match, startDate/endDate bounds, sort order and
/// limit. Every other repository method is unused by the service and just
/// throws if a test accidentally calls it.
class FakeCurrencyRepository implements CurrencyRepository {
  FakeCurrencyRepository(this.rates);

  final List<ExchangeRateDomain> rates;

  /// Counts calls to [getExchangeRatesFiltered] so tests can assert on
  /// cache hits/misses and on how many DB round-trips a lookup costs.
  int filteredCallCount = 0;

  final _changesController = StreamController<void>.broadcast();

  /// Test hook: simulates a write to the exchange_rates table.
  void emitRateChange() => _changesController.add(null);

  @override
  Stream<void> watchExchangeRateChanges() => _changesController.stream;

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
  }) async {
    filteredCallCount++;
    var result = rates.where((r) {
      if (fromCurrency != null && r.fromCurrencyCode != fromCurrency) {
        return false;
      }
      if (toCurrency != null && r.toCurrencyCode != toCurrency) return false;
      if (presets != null && !presets.contains(r.preset)) return false;
      if (startDate != null && r.date.isBefore(startDate)) return false;
      if (endDate != null && r.date.isAfter(endDate)) return false;
      return true;
    }).toList();
    result.sort(
      (a, b) =>
          sortAscending ? a.date.compareTo(b.date) : b.date.compareTo(a.date),
    );
    if (offset > 0) {
      result = offset >= result.length ? [] : result.sublist(offset);
    }
    if (result.length > limit) result = result.sublist(0, limit);
    return result;
  }

  // --- Unused by CurrencyConverterService ---
  @override
  Future<List<Currency>> getCurrencies() => throw UnimplementedError();

  @override
  Future<Map<String, int>> getCurrencyUsageCounts() =>
      throw UnimplementedError();

  @override
  Stream<List<String>> watchFavoriteCurrencyCodes() =>
      throw UnimplementedError();

  @override
  Future<List<String>> getFavoriteCurrencyCodes() => throw UnimplementedError();

  @override
  Future<void> setFavoriteCurrency(String code, {required bool favorite}) =>
      throw UnimplementedError();
  @override
  Stream<List<Currency>> watchCurrencies() => throw UnimplementedError();
  @override
  Future<Currency?> getCurrencyByCode(String code) =>
      throw UnimplementedError();
  @override
  Future<void> addCurrency(Currency currency) => throw UnimplementedError();
  @override
  Future<void> addCurrencies(List<Currency> currencies) =>
      throw UnimplementedError();
  @override
  Future<void> updateCurrency(Currency currency) => throw UnimplementedError();
  @override
  Future<void> deleteCurrency(Currency currency) => throw UnimplementedError();
  @override
  Stream<List<CurrencyDesignation>> watchCurrencyDesignationsForCurrency(
    String currencyCode,
  ) => throw UnimplementedError();
  @override
  Future<List<CurrencyDesignation>> getCurrencyDesignationsForCurrency(
    String currencyCode,
  ) => throw UnimplementedError();
  @override
  Future<CurrencyDesignation?> getCurrencyDesignationById(String id) =>
      throw UnimplementedError();
  @override
  Future<void> addCurrencyDesignation(CurrencyDesignation designation) =>
      throw UnimplementedError();
  @override
  Stream<List<CurrencyDesignation>> watchAllCurrencyDesignations() =>
      throw UnimplementedError();
  @override
  Future<List<CurrencyDesignation>> getAllCurrencyDesignations() =>
      throw UnimplementedError();
  @override
  Future<List<ExchangeRateDomain>> getLatestExchangeRates(DateTime date) =>
      throw UnimplementedError();
  @override
  Future<List<ExchangeRateDomain>> getLatestExchangeRatesAll() =>
      throw UnimplementedError();
  @override
  Future<List<ExchangeRateDomain>> getLatestExchangeRatesByList(
    List<DateTime> date, {
    Set<String>? currencyCodes,
  }) => throw UnimplementedError();
  @override
  Future<int> getExchangeRatesCount({
    DateTime? startDate,
    DateTime? endDate,
    String? fromCurrency,
    String? toCurrency,
    List<int>? presets,
  }) => throw UnimplementedError();
  @override
  Future<void> deleteExchangeRates(List<ExchangeRateDomain> rates) =>
      throw UnimplementedError();
  @override
  Future<void> updateExchangeRatePresets(
    List<ExchangeRateDomain> rates,
    int newPreset,
  ) => throw UnimplementedError();
  @override
  Future<List<int>> getAvailablePresets() => throw UnimplementedError();
  @override
  Future<void> addExchangeRate(ExchangeRateDomain exchangeRate) =>
      throw UnimplementedError();
  @override
  Future<void> addExchangeRates(List<ExchangeRateDomain> exchangeRates) =>
      throw UnimplementedError();
  @override
  Future<void> updateExchangeRate(ExchangeRateDomain exchangeRate) =>
      throw UnimplementedError();
  @override
  Future<void> replaceExchangeRate(
    ExchangeRateDomain original,
    ExchangeRateDomain updated,
  ) => throw UnimplementedError();
}

ExchangeRateDomain _rate(
  String from,
  String to,
  double rate,
  DateTime date, {
  int preset = 1,
}) => ExchangeRateDomain(
  fromCurrencyCode: from,
  toCurrencyCode: to,
  preset: preset,
  rate: rate,
  date: date,
);

void main() {
  group('CurrencyConverterService._nearestRate (via getExchangeRate)', () {
    // mainCurrencyCode == fromCurrencyCode disables the triangular leg so
    // these tests exercise the direct-rate probe pair in isolation.
    final target = DateTime(2024, 6, 15);

    test(
      'tie between an equally-distant before/after rate picks the EARLIER one',
      () async {
        final repo = FakeCurrencyRepository([
          _rate('USD', 'EUR', 1.1, DateTime(2024, 6, 10)), // 5 days before
          _rate('USD', 'EUR', 1.2, DateTime(2024, 6, 20)), // 5 days after
        ]);
        final service = CurrencyConverterService(repo);

        final r = await service.getExchangeRate(
          fromCurrencyCode: 'USD',
          toCurrencyCode: 'EUR',
          date: target,
          mainCurrencyCode: 'USD',
        );
        expect(r!.date, DateTime(2024, 6, 10));
        expect(r.rate, 1.1);
      },
    );

    test('closer "before" rate wins over a farther "after" rate', () async {
      final repo = FakeCurrencyRepository([
        _rate('USD', 'EUR', 1.1, DateTime(2024, 6, 14)), // 1 day before
        _rate('USD', 'EUR', 1.2, DateTime(2024, 6, 25)), // 10 days after
      ]);
      final service = CurrencyConverterService(repo);

      final r = await service.getExchangeRate(
        fromCurrencyCode: 'USD',
        toCurrencyCode: 'EUR',
        date: target,
        mainCurrencyCode: 'USD',
      );
      expect(r!.date, DateTime(2024, 6, 14));
      expect(r.rate, 1.1);
    });

    test('closer "after" rate wins over a farther "before" rate', () async {
      final repo = FakeCurrencyRepository([
        _rate('USD', 'EUR', 1.1, DateTime(2024, 6, 5)), // 10 days before
        _rate('USD', 'EUR', 1.2, DateTime(2024, 6, 16)), // 1 day after
      ]);
      final service = CurrencyConverterService(repo);

      final r = await service.getExchangeRate(
        fromCurrencyCode: 'USD',
        toCurrencyCode: 'EUR',
        date: target,
        mainCurrencyCode: 'USD',
      );
      expect(r!.date, DateTime(2024, 6, 16));
      expect(r.rate, 1.2);
    });
  });

  group('historical rate regression (was: naive limit:100 page scan)', () {
    test(
      'a transaction dated years ago still finds the old rate among hundreds of newer rows',
      () async {
        final oldDate = DateTime(2021, 3, 1); // ~3+ years before "today" below
        final rows = <ExchangeRateDomain>[
          // The row the old transaction should match, exactly on target date.
          _rate('USD', 'EUR', 0.85, oldDate),
        ];
        // 150 decoy rows, all much more recent than the target date. A naive
        // `getExchangeRatesFiltered(limit: 100)` call with no date bound and
        // sorted descending would return only these — never the old row.
        for (var i = 0; i < 150; i++) {
          rows.add(
            _rate(
              'USD',
              'EUR',
              1.10,
              DateTime(2024, 6, 1).subtract(Duration(days: i)),
            ),
          );
        }

        final repo = FakeCurrencyRepository(rows);
        final service = CurrencyConverterService(repo);

        final r = await service.getExchangeRate(
          fromCurrencyCode: 'USD',
          toCurrencyCode: 'EUR',
          date: oldDate,
          mainCurrencyCode: 'USD', // disable triangular, isolate direct probe
        );

        expect(r, isNotNull);
        expect(r!.date, oldDate);
        expect(r.rate, 0.85);
        // Direct + inverse legs, each issuing two bounded LIMIT-1 probes: 4
        // total calls regardless of how many rows exist for the pair — not a
        // 100-row page scan that would have missed the old row entirely.
        expect(repo.filteredCallCount, 4);
      },
    );
  });

  group('direct / inverse / triangular resolution', () {
    final target = DateTime(2025, 1, 10);

    test('direct rate is used when present', () async {
      final repo = FakeCurrencyRepository([
        _rate('USD', 'EUR', 2.0, target.subtract(const Duration(days: 2))),
      ]);
      final service = CurrencyConverterService(repo);

      final r = await service.getExchangeRate(
        fromCurrencyCode: 'USD',
        toCurrencyCode: 'EUR',
        date: target,
        mainCurrencyCode: 'USD',
      );
      expect(r!.rate, 2.0);
    });

    test(
      'inverse rate is used (and inverted) when no direct rate exists',
      () async {
        final repo = FakeCurrencyRepository([
          _rate('EUR', 'USD', 0.25, target.subtract(const Duration(days: 1))),
        ]);
        final service = CurrencyConverterService(repo);

        final r = await service.getExchangeRate(
          fromCurrencyCode: 'USD',
          toCurrencyCode: 'EUR',
          date: target,
          mainCurrencyCode: 'USD',
        );
        expect(r!.rate, 4.0); // 1 / 0.25
      },
    );

    test(
      'triangular resolution via main currency when no direct/inverse rate exists',
      () async {
        final repo = FakeCurrencyRepository([
          _rate('GBP', 'USD', 2.0, target), // main->from, on target date
          _rate('GBP', 'EUR', 8.0, target.subtract(const Duration(days: 30))),
        ]);
        final service = CurrencyConverterService(repo);

        final r = await service.getExchangeRate(
          fromCurrencyCode: 'USD',
          toCurrencyCode: 'EUR',
          date: target,
          mainCurrencyCode: 'GBP',
        );
        // (GBP->EUR) / (GBP->USD) = 8.0 / 2.0
        expect(r!.rate, 4.0);
        // Dated by the STALEST leg (GBP->EUR, 30 days off), not the fresh one.
        expect(r.date, target.subtract(const Duration(days: 30)));
      },
    );

    test(
      'a same-distance tie between direct and inverse favors direct',
      () async {
        final repo = FakeCurrencyRepository([
          _rate('USD', 'EUR', 2.0, target), // direct, on target date
          _rate(
            'EUR',
            'USD',
            0.1,
            target,
          ), // inverse, also on target date -> would invert to 10.0
        ]);
        final service = CurrencyConverterService(repo);

        final r = await service.getExchangeRate(
          fromCurrencyCode: 'USD',
          toCurrencyCode: 'EUR',
          date: target,
          mainCurrencyCode: 'USD',
        );
        expect(r!.rate, 2.0);
      },
    );

    test(
      'a stale (today, three-years-ago) triangular pairing does not outrank an honest same-week direct rate',
      () async {
        final repo = FakeCurrencyRepository([
          // Honest direct rate, 5 days off target.
          _rate('USD', 'EUR', 1.23, target.subtract(const Duration(days: 5))),
          // Triangular legs: one fresh (on target date), one three years stale.
          // Effective date = stalest leg = ~3 years off, which must lose to
          // the 5-day-old direct rate.
          _rate('GBP', 'USD', 2.0, target),
          _rate(
            'GBP',
            'EUR',
            9.99,
            target.subtract(const Duration(days: 365 * 3)),
          ),
        ]);
        final service = CurrencyConverterService(repo);

        final r = await service.getExchangeRate(
          fromCurrencyCode: 'USD',
          toCurrencyCode: 'EUR',
          date: target,
          mainCurrencyCode: 'GBP',
        );
        expect(r!.rate, 1.23);
        expect(r.date, target.subtract(const Duration(days: 5)));
      },
    );
  });

  group('cache', () {
    final target = DateTime(2025, 2, 1);

    test('an identical query hits the repository only once', () async {
      final repo = FakeCurrencyRepository([_rate('USD', 'EUR', 1.5, target)]);
      final service = CurrencyConverterService(repo);

      final args = () => service.getExchangeRate(
        fromCurrencyCode: 'USD',
        toCurrencyCode: 'EUR',
        date: target,
        mainCurrencyCode: 'USD',
      );

      final first = await args();
      final callsAfterFirst = repo.filteredCallCount;
      expect(callsAfterFirst, greaterThan(0));

      final second = await args();
      expect(repo.filteredCallCount, callsAfterFirst); // no new DB calls
      expect(second, first);

      await service.dispose();
    });

    test(
      'a rate-change signal clears the cache so the next lookup re-reads',
      () async {
        final repo = FakeCurrencyRepository([_rate('USD', 'EUR', 1.5, target)]);
        final service = CurrencyConverterService(repo);

        Future<ExchangeRateDomain?> lookup() => service.getExchangeRate(
          fromCurrencyCode: 'USD',
          toCurrencyCode: 'EUR',
          date: target,
          mainCurrencyCode: 'USD',
        );

        await lookup();
        final callsAfterFirst = repo.filteredCallCount;

        repo.emitRateChange();
        // Let the stream subscription's listener callback run.
        await Future<void>.delayed(Duration.zero);

        await lookup();
        expect(repo.filteredCallCount, greaterThan(callsAfterFirst));

        await service.dispose();
      },
    );

    test(
      'cache key includes mainCurrencyCode: switching main does not serve a stale triangular result',
      () async {
        final repo = FakeCurrencyRepository([
          _rate('GBP', 'USD', 2.0, target),
          _rate('GBP', 'EUR', 4.0, target),
        ]);
        final service = CurrencyConverterService(repo);

        // main = GBP: triangular route resolves.
        final withGbpMain = await service.getExchangeRate(
          fromCurrencyCode: 'USD',
          toCurrencyCode: 'EUR',
          date: target,
          mainCurrencyCode: 'GBP',
        );
        expect(withGbpMain, isNotNull);

        // main = USD (== fromCurrencyCode): triangular is skipped entirely,
        // and there's no direct/inverse rate, so this must resolve to null —
        // NOT the cached GBP-keyed triangular result.
        final withUsdMain = await service.getExchangeRate(
          fromCurrencyCode: 'USD',
          toCurrencyCode: 'EUR',
          date: target,
          mainCurrencyCode: 'USD',
        );
        expect(withUsdMain, isNull);

        await service.dispose();
      },
    );
  });

  group('dispose()', () {
    test(
      'cancels the rate-change subscription so later signals no longer clear the cache',
      () async {
        final target = DateTime(2025, 3, 1);
        final repo = FakeCurrencyRepository([_rate('USD', 'EUR', 1.5, target)]);
        final service = CurrencyConverterService(repo);

        Future<ExchangeRateDomain?> lookup() => service.getExchangeRate(
          fromCurrencyCode: 'USD',
          toCurrencyCode: 'EUR',
          date: target,
          mainCurrencyCode: 'USD',
        );

        await lookup(); // populates cache
        final callsBeforeDispose = repo.filteredCallCount;

        await service.dispose(); // also clears the cache itself

        await lookup(); // cache was cleared by dispose -> re-reads
        final callsAfterDisposeLookup = repo.filteredCallCount;
        expect(callsAfterDisposeLookup, greaterThan(callsBeforeDispose));

        // If the subscription were still active, this would clear the cache
        // again and the next lookup would hit the repository.
        repo.emitRateChange();
        await Future<void>.delayed(Duration.zero);

        await lookup();
        expect(
          repo.filteredCallCount,
          callsAfterDisposeLookup,
        ); // cache hit, no new calls
      },
    );
  });

  group('misc', () {
    test(
      'same-currency short-circuits to rate 1.0 without touching the repository',
      () async {
        final repo = FakeCurrencyRepository([]);
        final service = CurrencyConverterService(repo);

        final r = await service.getExchangeRate(
          fromCurrencyCode: 'EUR',
          toCurrencyCode: 'EUR',
          date: DateTime(2025, 1, 1),
          mainCurrencyCode: 'EUR',
        );
        expect(r!.rate, 1.0);
        expect(repo.filteredCallCount, 0);
      },
    );

    test('convertAmount multiplies by the resolved rate', () async {
      final target = DateTime(2025, 4, 1);
      final repo = FakeCurrencyRepository([_rate('USD', 'EUR', 0.9, target)]);
      final service = CurrencyConverterService(repo);

      final converted = await service.convertAmount(
        amount: 100.0,
        fromCurrencyCode: 'USD',
        toCurrencyCode: 'EUR',
        date: target,
        mainCurrencyCode: 'USD',
      );
      expect(converted, 90.0);
    });

    test('convertAmount returns null when no rate can be resolved', () async {
      final repo = FakeCurrencyRepository([]);
      final service = CurrencyConverterService(repo);

      final converted = await service.convertAmount(
        amount: 100.0,
        fromCurrencyCode: 'USD',
        toCurrencyCode: 'ZZZ',
        date: DateTime(2025, 1, 1),
        mainCurrencyCode: 'USD',
      );
      expect(converted, isNull);
    });
  });
}
