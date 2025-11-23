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
  final List<Account> accounts;
  final List<Currency> selectedCurrencies;
  final String baseCurrencyCode;

  const CurrencyConverterLoadSuccess({
    this.allCurrencies = const [],
    this.exchangeRates = const [],
    this.accounts = const [],
    this.selectedCurrencies = const [],
    required this.baseCurrencyCode,
  });

  // Method to calculate total balance for a given currency
  double totalBalanceFor(Currency currency) {
    double total = 0;
    for (final account in accounts) {
      if (account.currencyCode == currency.code) {
        total += account.balance;
      } else {
        // Find exchange rate
        final rate = _findRate(account.currencyCode, currency.code);
        if (rate != null) {
          total += account.balance * rate;
        } else {
          // Try converting through base currency
          final rateFromBase = _findRate(baseCurrencyCode, currency.code);
          final rateToBase = _findRate(account.currencyCode, baseCurrencyCode);
          if (rateFromBase != null && rateToBase != null) {
            total += (account.balance * rateToBase) * rateFromBase;
          }
        }
      }
    }
    return total;
  }

  double? _findRate(String fromCurrencyCode, String toCurrencyCode) {
    // For simplicity, we're taking the most recent rate.
    // A real implementation would consider the date.
    final rate = exchangeRates.lastWhereOrNull((r) =>
        r.fromCurrencyCode == fromCurrencyCode &&
        r.toCurrencyCode == toCurrencyCode);
    return rate?.rate;
  }

  CurrencyConverterLoadSuccess copyWith({
    List<Currency>? allCurrencies,
    List<ExchangeRate>? exchangeRates,
    List<Account>? accounts,
    List<Currency>? selectedCurrencies,
    String? baseCurrencyCode,
  }) {
    return CurrencyConverterLoadSuccess(
      allCurrencies: allCurrencies ?? this.allCurrencies,
      exchangeRates: exchangeRates ?? this.exchangeRates,
      accounts: accounts ?? this.accounts,
      selectedCurrencies: selectedCurrencies ?? this.selectedCurrencies,
      baseCurrencyCode: baseCurrencyCode ?? this.baseCurrencyCode,
    );
  }

  @override
  List<Object> get props => [
        allCurrencies,
        exchangeRates,
        accounts,
        selectedCurrencies,
        baseCurrencyCode,
      ];
}

class CurrencyConverterLoadFailure extends CurrencyConverterState {}
