part of 'currency_bloc.dart';

abstract class CurrencyState extends Equatable {
  final List<Currency> currencies;
  final List<CurrencyDesignation> designations;

  const CurrencyState({
    this.currencies = const [],
    this.designations = const [],
  });

  @override
  List<Object> get props => [currencies, designations];
}

class CurrencyInitial extends CurrencyState {}

class CurrencyLoadInProgress extends CurrencyState {}

class CurrencyLoadSuccess extends CurrencyState {
  const CurrencyLoadSuccess({super.currencies, super.designations});

  CurrencyLoadSuccess copyWith({
    List<Currency>? currencies,
    List<CurrencyDesignation>? designations,
  }) {
    return CurrencyLoadSuccess(
      currencies: currencies ?? this.currencies,
      designations: designations ?? this.designations,
    );
  }

  @override
  List<Object> get props => [currencies, designations];
}

class CurrencyLoadFailure extends CurrencyState {}
