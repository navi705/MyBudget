part of 'currency_converter_bloc.dart';

abstract class CurrencyConverterState extends Equatable {
  const CurrencyConverterState();

  @override
  List<Object> get props => [];
}

class CurrencyConverterInitial extends CurrencyConverterState {}

class CurrencyConverterLoadInProgress extends CurrencyConverterState {}

// ignore: must_be_immutable
class CurrencyConverterLoadSuccess extends CurrencyConverterState {
  final List<Currency> allCurrencies;
  final List<ExchangeRateDomain> exchangeRates;
  final List<Currency> selectedCurrencies;
  final String baseCurrencyCode;

  Map<String, Map<String, List<ExchangeRateDomain>>>? _groupedRates;  

  CurrencyConverterLoadSuccess({
    this.allCurrencies = const [],
    this.exchangeRates = const [],
    this.selectedCurrencies = const [],
    required this.baseCurrencyCode,
  }) {
    // Pre-sort the rates by date to optimize finding the latest rate.
    exchangeRates.sort((a, b) => b.date.compareTo(a.date));

    // Pre-process the rates for faster lookups.
    final map = <String, Map<String, List<ExchangeRateDomain>>>{};
    for (final rate in exchangeRates) {
      map
          .putIfAbsent(rate.fromCurrencyCode, () => {})
          .putIfAbsent(rate.toCurrencyCode, () => [])
          .add(rate);
    }
    _groupedRates = map;
  }

  Map<String, Map<String, List<ExchangeRateDomain>>> get groupedRates {
  return _groupedRates!;
  }

  CurrencyConverterLoadSuccess copyWith({
    List<Currency>? allCurrencies,
    List<ExchangeRateDomain>? exchangeRates,
    List<Currency>? selectedCurrencies,
    String? baseCurrencyCode,
  }) {
    return CurrencyConverterLoadSuccess(
      allCurrencies: allCurrencies ?? this.allCurrencies,
      exchangeRates: exchangeRates ?? this.exchangeRates,
      selectedCurrencies: selectedCurrencies ?? this.selectedCurrencies,
      baseCurrencyCode: baseCurrencyCode ?? this.baseCurrencyCode,
    );
  }

  @override
  List<Object> get props => [
        allCurrencies,
        exchangeRates,
        selectedCurrencies,
        baseCurrencyCode,
      ];
}

class CurrencyConverterLoadFailure extends CurrencyConverterState {}

double totalBalanceFor({
  required Currency currency,
  required List<Account> accounts,
  required List<ExchangeRateDomain> exchangeRates,
  required String baseCurrencyCode,
  required DateTime date,
  required Map<String, Map<String, List<ExchangeRateDomain>>> groupedRates,
}) {
  double totalInBase = 0.0;

  for (final account in accounts) {
    if (account.currencyCode == baseCurrencyCode) {
      totalInBase += account.balance;
    } else {
      final rateToBase = _findRate(
        account.currencyCode,
        baseCurrencyCode,
        exchangeRates,
        date,
        groupedRates,
      );
      if (rateToBase != null) {
        totalInBase += account.balance * rateToBase;
      }
    }
  }

  if (currency.code == baseCurrencyCode) {
    return totalInBase;
  }

  final rateFromBase = _findRate(
    baseCurrencyCode,
    currency.code,
    exchangeRates,
    date,
    groupedRates,
  );

  return rateFromBase != null ? totalInBase * rateFromBase : 0.0;
}

double? _findRate(
    String fromCurrencyCode,
    String toCurrencyCode,
    List<ExchangeRateDomain> exchangeRates,
    DateTime date,
    Map<String, Map<String, List<ExchangeRateDomain>>> groupedRates) {
  if (fromCurrencyCode == toCurrencyCode) {
    return 1.0;
  }
  
  final ratesForFrom = groupedRates[fromCurrencyCode];
  if (ratesForFrom != null) {
    final ratesForTo = ratesForFrom[toCurrencyCode];
    if (ratesForTo != null) {
      final rate = ratesForTo.firstWhereOrNull((r) => !r.date.isAfter(date));
      if (rate != null) {
        return rate.rate;
      }
    }
  }

  // Try reverse rate
  final reverseRatesForFrom = groupedRates[toCurrencyCode];
  if (reverseRatesForFrom != null) {
    final reverseRatesForTo = reverseRatesForFrom[fromCurrencyCode];
    if (reverseRatesForTo != null) {
      final rate =
          reverseRatesForTo.firstWhereOrNull((r) => !r.date.isAfter(date));
      if (rate != null && rate.rate != 0) {
        return 1 / rate.rate;
      }
    }
  }

  return null;
}
