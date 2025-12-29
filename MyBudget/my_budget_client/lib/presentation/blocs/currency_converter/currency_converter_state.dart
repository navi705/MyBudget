part of 'currency_converter_bloc.dart';

abstract class CurrencyConverterState extends Equatable {
  const CurrencyConverterState();

  @override
  List<Object> get props => [];
}

class CurrencyConverterInitial extends CurrencyConverterState {}

class CurrencyConverterLoadInProgress extends CurrencyConverterState {}

class CurrencyConverterLoadSuccess extends CurrencyConverterState {
  final List<Currency> allCurrencies;
  final List<ExchangeRate> exchangeRates;
  final List<Currency> selectedCurrencies;
  final String baseCurrencyCode;

  Map<String, Map<String, List<ExchangeRate>>>? _groupedRates;

  CurrencyConverterLoadSuccess({
    this.allCurrencies = const [],
    this.exchangeRates = const [],
    this.selectedCurrencies = const [],
    required this.baseCurrencyCode,
  }) {
    // Pre-sort the rates by date to optimize finding the latest rate.
    exchangeRates.sort((a, b) => b.date.compareTo(a.date));

    // Pre-process the rates for faster lookups.
    final map = <String, Map<String, List<ExchangeRate>>>{};
    for (final rate in exchangeRates) {
      map
          .putIfAbsent(rate.fromCurrencyCode, () => {})
          .putIfAbsent(rate.toCurrencyCode, () => [])
          .add(rate);
    }
    _groupedRates = map;
  }

  Map<String, Map<String, List<ExchangeRate>>> get groupedRates {
    return _groupedRates!;
  }

  CurrencyConverterLoadSuccess copyWith({
    List<Currency>? allCurrencies,
    List<ExchangeRate>? exchangeRates,
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
  required List<ExchangeRate> exchangeRates,
  required String baseCurrencyCode,
  required DateTime date,
  required Map<String, Map<String, List<ExchangeRate>>> groupedRates,
}) {
  double total = 0;
  for (final account in accounts) {
    if (account.currencyCode == currency.code) {
      total += account.balance;
    } else {
      final rate = _findRate(
          account.currencyCode, currency.code, exchangeRates, date, groupedRates);
      if (rate != null) {
        total += account.balance * rate;
      } else {
        final rateFromBase = _findRate(
            baseCurrencyCode, currency.code, exchangeRates, date, groupedRates);
        final rateToBase = _findRate(account.currencyCode, baseCurrencyCode,
            exchangeRates, date, groupedRates);
        if (rateFromBase != null && rateToBase != null) {
          total += (account.balance * rateToBase) * rateFromBase;
        }
      }
    }
  }
  return total;
}

double? _findRate(
    String fromCurrencyCode,
    String toCurrencyCode,
    List<ExchangeRate> exchangeRates,
    DateTime date,
    Map<String, Map<String, List<ExchangeRate>>> groupedRates) {
  
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
