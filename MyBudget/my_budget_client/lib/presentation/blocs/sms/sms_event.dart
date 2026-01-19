part of 'sms_bloc.dart';

abstract class SmsEvent extends Equatable {
  const SmsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSmsPresets extends SmsEvent {}

class ToggleSmsPreset extends SmsEvent {
  final String presetId;
  final bool isEnabled;

  const ToggleSmsPreset(this.presetId, this.isEnabled);

  @override
  List<Object?> get props => [presetId, isEnabled];
}

class SaveSmsPreset extends SmsEvent {
  final SmsPreset preset;

  const SaveSmsPreset(this.preset);

  @override
  List<Object?> get props => [preset];
}

class DeleteSmsPreset extends SmsEvent {
  final String presetId;

  const DeleteSmsPreset(this.presetId);

  @override
  List<Object?> get props => [presetId];
}

class TestSmsRule extends SmsEvent {
  final String smsBody;
  final SmsParsingRule rule;

  const TestSmsRule(this.smsBody, this.rule);

  @override
  List<Object?> get props => [smsBody, rule];
}

class ImportSmsMessages extends SmsEvent {
  final DateTime? since;

  const ImportSmsMessages({this.since});

  @override
  List<Object?> get props => [since];
}

class RequestSmsPermission extends SmsEvent {}
