part of 'inflation_bloc.dart';

abstract class InflationState extends Equatable {
  const InflationState();

  @override
  List<Object?> get props => [];
}

class InflationInitial extends InflationState {}

class InflationLoadInProgress extends InflationState {}

class InflationLoadSuccess extends InflationState {
  final List<InflationRateDomain> rates;

  const InflationLoadSuccess({this.rates = const []});

  @override
  List<Object?> get props => [rates];
}

class InflationFailure extends InflationState {
  final String message;
  const InflationFailure(this.message);

  @override
  List<Object?> get props => [message];
}
