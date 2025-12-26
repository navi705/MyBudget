part of 'currency_converter_bloc.dart';

abstract class CurrencyConverterEvent extends Equatable {
  const CurrencyConverterEvent();

  @override
  List<Object> get props => [];
}

class LoadCurrencyConverter extends CurrencyConverterEvent {}

class AddSelectedCurrency extends CurrencyConverterEvent {
  final Currency currency;

  const AddSelectedCurrency(this.currency);

  @override
  List<Object> get props => [currency];
}

class RemoveSelectedCurrency extends CurrencyConverterEvent {
  final Currency currency;

  const RemoveSelectedCurrency(this.currency);

  @override
  List<Object> get props => [currency];
}

class _CurrencyConverterDataUpdated extends CurrencyConverterEvent {
  final List<Currency> allCurrencies;
  final List<ExchangeRate> exchangeRates;
  final List<Account> accounts;
  final Settings? baseCurrencySetting;
  final Settings? selectedCurrenciesSetting;

  const _CurrencyConverterDataUpdated({
    required this.allCurrencies,
    required this.exchangeRates,
    required this.accounts,
    required this.baseCurrencySetting,
    required this.selectedCurrenciesSetting,
  });

  @override
  List<Object> get props => [
        allCurrencies,
        exchangeRates,
        accounts,
        baseCurrencySetting ?? 0,
        selectedCurrenciesSetting ?? 0,
      ];
}
