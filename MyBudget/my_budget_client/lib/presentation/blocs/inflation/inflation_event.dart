part of 'inflation_bloc.dart';

abstract class InflationEvent extends Equatable {
  const InflationEvent();

  @override
  List<Object?> get props => [];
}

class LoadInflationRates extends InflationEvent {}

class LoadMoreInflationRates extends InflationEvent {}

class ChangeInflationDateStep extends InflationEvent {
  final DateStep dateStep;
  const ChangeInflationDateStep(this.dateStep);
  @override
  List<Object?> get props => [dateStep];
}

class ChangeInflationFilterMode extends InflationEvent {
  final FilterMode filterMode;
  const ChangeInflationFilterMode(this.filterMode);
  @override
  List<Object?> get props => [filterMode];
}

class ChangeInflationActiveDate extends InflationEvent {
  final DateTime date;
  const ChangeInflationActiveDate(this.date);
  @override
  List<Object?> get props => [date];
}

class ChangeInflationActiveDateRange extends InflationEvent {
  final DateTimeRange dateRange;
  const ChangeInflationActiveDateRange(this.dateRange);
  @override
  List<Object?> get props => [dateRange];
}

class ChangeInflationSort extends InflationEvent {
  final Sort sort;
  const ChangeInflationSort(this.sort);
  @override
  List<Object?> get props => [sort];
}

class ChangeInflationFilters extends InflationEvent {
  final List<String>? countries;
  final List<int>? presets;
  const ChangeInflationFilters({this.countries, this.presets});
  @override
  List<Object?> get props => [countries, presets];
}

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

class ToggleInflationSelection extends InflationEvent {
  final InflationRateDomain rate;
  const ToggleInflationSelection(this.rate);
  @override
  List<Object?> get props => [rate];
}

class SelectAllInflationRates extends InflationEvent {}

class DeselectAllInflationRates extends InflationEvent {}

class DeleteSelectedInflationRates extends InflationEvent {}
