part of 'inflation_bloc.dart';

abstract class InflationEvent extends Equatable {
  const InflationEvent();

  @override
  List<Object?> get props => [];
}

class LoadInflationRates extends InflationEvent {}

class AddInflationRate extends InflationEvent {
  final InflationRateDomain rate;
  const AddInflationRate(this.rate);

  @override
  List<Object?> get props => [rate];
}

class UpdateInflationRate extends InflationEvent {
  final InflationRateDomain rate;
  const UpdateInflationRate(this.rate);

  @override
  List<Object?> get props => [rate];
}

class DeleteInflationRate extends InflationEvent {
  final DateTime date;
  final String? country;
  final int preset;

  const DeleteInflationRate({
    required this.date,
    this.country,
    required this.preset,
  });

  @override
  List<Object?> get props => [date, country, preset];
}
