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

  const CurrencyConverterLoadSuccess({
    this.allCurrencies = const [],
    this.exchangeRates = const [],
    this.selectedCurrencies = const [],
    required this.baseCurrencyCode,
  });

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
}) {
  double total = 0;
  for (final account in accounts) {
    if (account.currencyCode == currency.code) {
      total += account.balance;
    } else {
      final rate = _findRate(account.currencyCode, currency.code, exchangeRates);
      if (rate != null) {
        total += account.balance * rate;
      } else {
        final rateFromBase = _findRate(baseCurrencyCode, currency.code, exchangeRates);
        final rateToBase = _findRate(account.currencyCode, baseCurrencyCode, exchangeRates);
        if (rateFromBase != null && rateToBase != null) {
          total += (account.balance * rateToBase) * rateFromBase;
        }
      }
    }
  }
  return total;
}

double? _findRate(String fromCurrencyCode, String toCurrencyCode, List<ExchangeRate> exchangeRates) {
  // Try to find the direct rate
  var rate = exchangeRates.lastWhereOrNull((r) =>
      r.fromCurrencyCode == fromCurrencyCode &&
      r.toCurrencyCode == toCurrencyCode);
  if (rate != null) {
    return rate.rate;
  }

  // Try to find the reverse rate and calculate the inverse
  rate = exchangeRates.lastWhereOrNull((r) =>
      r.fromCurrencyCode == toCurrencyCode &&
      r.toCurrencyCode == fromCurrencyCode);
  if (rate != null && rate.rate != 0) {
    return 1 / rate.rate;
  }

  return null;
}
