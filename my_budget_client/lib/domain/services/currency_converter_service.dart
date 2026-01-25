import 'package:my_budget_client/domain/entities/exchange_rate.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';

class CurrencyConverterService {
  final CurrencyRepository _currencyRepository;

  CurrencyConverterService(this._currencyRepository);

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

    // 1. Direct Fetch
    final directRates = await _currencyRepository.getExchangeRatesFiltered(
      fromCurrency: fromCurrencyCode,
      toCurrency: toCurrencyCode,
      presets: [preset],
      sortAscending: false,
    );
    for (var r in directRates) {
      tryUpdateBest(r.rate, r.date);
    }

    // 2. Inverse Fetch (To -> From)
    final inverseRates = await _currencyRepository.getExchangeRatesFiltered(
      fromCurrency: toCurrencyCode,
      toCurrency: fromCurrencyCode,
      presets: [preset],
      sortAscending: false,
    );
    for (var r in inverseRates) {
      if (r.rate != 0) {
        tryUpdateBest(1.0 / r.rate, r.date);
      }
    }

    // 3. Triangular Fetch (Main -> From, Main -> To)
    if (fromCurrencyCode != mainCurrencyCode &&
        toCurrencyCode != mainCurrencyCode) {
      final baseToFrom = await _currencyRepository.getExchangeRatesFiltered(
        fromCurrency: mainCurrencyCode,
        toCurrency: fromCurrencyCode,
        presets: [preset],
        sortAscending: false,
      );
      final baseToTo = await _currencyRepository.getExchangeRatesFiltered(
        fromCurrency: mainCurrencyCode,
        toCurrency: toCurrencyCode,
        presets: [preset],
        sortAscending: false,
      );

      ExchangeRateDomain? closestBaseToFrom;
      Duration? minDistFrom;
      for (var r in baseToFrom) {
        final dist = r.date.difference(targetDate).abs();
        if (minDistFrom == null || dist < minDistFrom) {
          minDistFrom = dist;
          closestBaseToFrom = r;
        }
      }

      ExchangeRateDomain? closestBaseToTo;
      Duration? minDistTo;
      for (var r in baseToTo) {
        final dist = r.date.difference(targetDate).abs();
        if (minDistTo == null || dist < minDistTo) {
          minDistTo = dist;
          closestBaseToTo = r;
        }
      }

      if (closestBaseToFrom != null && closestBaseToTo != null) {
        if (closestBaseToFrom.rate != 0) {
          final calculatedRate = closestBaseToTo.rate / closestBaseToFrom.rate;
          tryUpdateBest(calculatedRate, closestBaseToFrom.date);
        }
      }
    }

    if (bestRateValue != null) {
      return ExchangeRateDomain(
        fromCurrencyCode: fromCurrencyCode,
        toCurrencyCode: toCurrencyCode,
        rate: bestRateValue!,
        date: bestDate!,
        preset: preset,
      );
    }

    return null;
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
