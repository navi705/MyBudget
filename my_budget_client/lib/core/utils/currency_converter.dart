import 'package:collection/collection.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';

class CurrencyConverter {
  final Map<String, Map<String, List<ExchangeRateDomain>>> _groupedRates = {};
  final List<ExchangeRateDomain> rates;

  CurrencyConverter(this.rates) {
    final sortedRates = rates.toList()..sort((a, b) => b.date.compareTo(a.date));
    for (final rate in sortedRates) {
      _groupedRates
          .putIfAbsent(rate.fromCurrencyCode, () => {})
          .putIfAbsent(rate.toCurrencyCode, () => [])
          .add(rate);
    }
  }

  double? _findRate(String from, String to, DateTime date) {
    if (from == to) return 1.0;
  
    // Direct rate A -> B
    final ratesForFrom = _groupedRates[from];
    if (ratesForFrom != null) {
      final ratesForTo = ratesForFrom[to];
      if (ratesForTo != null) {
        final rate = ratesForTo.firstWhereOrNull((r) => !r.date.isAfter(date));
        if (rate != null) return rate.rate;
      }
    }

    // Reverse rate B -> A
    final reverseRatesForFrom = _groupedRates[to];
    if (reverseRatesForFrom != null) {
      final reverseRatesForTo = reverseRatesForFrom[from];
      if (reverseRatesForTo != null) {
        final rate = reverseRatesForTo.firstWhereOrNull((r) => !r.date.isAfter(date));
        if (rate != null && rate.rate != 0) return 1 / rate.rate;
      }
    }
    return null;
  }

  double convert({
    required double amount,
    required String from,
    required String to,
    required DateTime date,
  }) {
    if (from == to) return amount;

    // Try direct conversion: FROM -> TO
    final directRate = _findRate(from, to, date);
    if (directRate != null) {
      return amount * directRate;
    }

    // Try pivot conversion: FROM -> EUR -> TO
    const baseCurrency = 'EUR';
    final rateFromToEur = _findRate(from, baseCurrency, date);
    final rateEurToTo = _findRate(baseCurrency, to, date);

    if (rateFromToEur != null && rateEurToTo != null) {
      return amount * rateFromToEur * rateEurToTo;
    }
    
    // If no conversion path is found, return 0. This prevents corrupting
    // a total with un-converted amounts from different currencies.
    return 0.0;
  }
}
