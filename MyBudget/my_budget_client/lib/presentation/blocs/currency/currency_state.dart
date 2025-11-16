part of 'currency_bloc.dart';

abstract class CurrencyState extends Equatable {
  const CurrencyState();

  @override
  List<Object> get props => [];
}

class CurrencyInitial extends CurrencyState {}

class CurrencyLoadInProgress extends CurrencyState {}

class CurrencyLoadSuccess extends CurrencyState {
  final List<Currency> currencies;

  const CurrencyLoadSuccess([this.currencies = const []]);

  @override
  List<Object> get props => [currencies];
}

class CurrencyLoadFailure extends CurrencyState {}
