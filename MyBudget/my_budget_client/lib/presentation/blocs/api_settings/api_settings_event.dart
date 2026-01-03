import 'package:equatable/equatable.dart';

abstract class ApiSettingsEvent extends Equatable {
  const ApiSettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadApiSettings extends ApiSettingsEvent {}

class ToggleApiFetching extends ApiSettingsEvent {
  final bool enabled;
  const ToggleApiFetching(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class SetApiFetchMode extends ApiSettingsEvent {
  final String mode; // 'debug' or 'production'
  const SetApiFetchMode(this.mode);

  @override
  List<Object?> get props => [mode];
}

class ManualFetchRange extends ApiSettingsEvent {
  final DateTime start;
  final DateTime end;
  const ManualFetchRange(this.start, this.end);

  @override
  List<Object?> get props => [start, end];
}
