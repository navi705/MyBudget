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
  final DateTime? until;

  const ImportSmsMessages({this.since, this.until});

  @override
  List<Object?> get props => [since, until];
}

class ImportSmsWithPreset extends SmsEvent {
  final String presetId;
  final DateTime? since;
  final DateTime? until;

  const ImportSmsWithPreset({required this.presetId, this.since, this.until});

  @override
  List<Object?> get props => [presetId, since, until];
}

class RequestSmsPermission extends SmsEvent {}

class CreateTransactionsFromSms extends SmsEvent {
  final List<SmsParseResult> results;
  final String? defaultAccountId;
  final String? defaultCategoryId;

  const CreateTransactionsFromSms({
    required this.results,
    this.defaultAccountId,
    this.defaultCategoryId,
  });

  @override
  List<Object?> get props => [results, defaultAccountId, defaultCategoryId];
}
