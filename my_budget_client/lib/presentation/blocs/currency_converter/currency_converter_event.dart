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

class DateChanged extends CurrencyConverterEvent {
  final DateTime date;

  const DateChanged(this.date);

  @override
  List<Object> get props => [date];
}
