part of 'currency_bloc.dart';

abstract class CurrencyEvent extends Equatable {
  const CurrencyEvent();

  @override
  List<Object> get props => [];
}

class LoadCurrencies extends CurrencyEvent {}

class _CurrenciesAndDesignationsUpdated extends CurrencyEvent {
  final List<Currency> currencies;
  final List<CurrencyDesignation> designations;

  const _CurrenciesAndDesignationsUpdated(this.currencies, this.designations);

  @override
  List<Object> get props => [currencies, designations];
}
