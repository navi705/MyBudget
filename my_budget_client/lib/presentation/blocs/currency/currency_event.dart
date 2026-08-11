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

/// Carries a currency-stream error back into the bloc. The error surfaces after
/// the LoadCurrencies handler has already returned, so the failure state can
/// only be emitted from a handler that is live at that moment — hence an event.
class _CurrencyLoadFailed extends CurrencyEvent {
  const _CurrencyLoadFailed();
}
