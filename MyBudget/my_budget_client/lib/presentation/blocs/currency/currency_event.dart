part of 'currency_bloc.dart';

abstract class CurrencyEvent extends Equatable {
  const CurrencyEvent();

  @override
  List<Object> get props => [];
}

class LoadCurrencies extends CurrencyEvent {}

class _CurrenciesUpdated extends CurrencyEvent {
  final List<Currency> currencies;

  const _CurrenciesUpdated(this.currencies);

  @override
  List<Object> get props => [currencies];
}
