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
  final int baseCurrencyId;

  const CurrencyConverterLoadSuccess({
    this.allCurrencies = const [],
    this.exchangeRates = const [],
    this.accounts = const [],
    this.selectedCurrencies = const [],
    required this.baseCurrencyId,
  });

  // Method to calculate total balance for a given currency
  double totalBalanceFor(Currency currency) {
    double total = 0;
    for (final account in accounts) {
      if (account.currencyId == currency.id) {
        total += account.balance;
      } else {
        // Find exchange rate
        final rate = _findRate(account.currencyId, currency.id);
        if (rate != null) {
          total += account.balance * rate;
        } else {
          // Try converting through base currency
          final rateFromBase = _findRate(baseCurrencyId, currency.id);
          final rateToBase = _findRate(account.currencyId, baseCurrencyId);
          if (rateFromBase != null && rateToBase != null) {
            total += (account.balance * rateToBase) * rateFromBase;
          }
        }
      }
    }
    return total;
  }

  double? _findRate(int fromCurrencyId, int toCurrencyId) {
    try {
      // For simplicity, we're taking the most recent rate.
      // A real implementation would consider the date.
      final rate = exchangeRates
          .lastWhere((r) => r.fromCurrencyId == fromCurrencyId && r.toCurrencyId == toCurrencyId)
          .rate;
      return rate;
    } catch (e) {
      return null;
    }
  }

  CurrencyConverterLoadSuccess copyWith({
    List<Currency>? allCurrencies,
    List<ExchangeRate>? exchangeRates,
    List<Account>? accounts,
    List<Currency>? selectedCurrencies,
    int? baseCurrencyId,
  }) {
    return CurrencyConverterLoadSuccess(
      allCurrencies: allCurrencies ?? this.allCurrencies,
      exchangeRates: exchangeRates ?? this.exchangeRates,
      accounts: accounts ?? this.accounts,
      selectedCurrencies: selectedCurrencies ?? this.selectedCurrencies,
      baseCurrencyId: baseCurrencyId ?? this.baseCurrencyId,
    );
  }

  @override
  List<Object> get props => [
        allCurrencies,
        exchangeRates,
        accounts,
        selectedCurrencies,
        baseCurrencyId,
      ];
}

class CurrencyConverterLoadFailure extends CurrencyConverterState {}
