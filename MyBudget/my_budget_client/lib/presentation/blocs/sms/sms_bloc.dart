import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:my_budget_client/core/utils/sms_parser.dart';
import 'package:my_budget_client/domain/entities/sms_preset.dart';
import 'package:my_budget_client/domain/repositories/sms_repository.dart';

part 'sms_event.dart';
part 'sms_state.dart';

class SmsBloc extends Bloc<SmsEvent, SmsState> {
  final SmsRepository _smsRepository;
  final SmsParser _parser = SmsParser();

  SmsBloc({required SmsRepository smsRepository})
    : _smsRepository = smsRepository,
      super(const SmsState()) {
    on<LoadSmsPresets>(_onLoadPresets);
    on<ToggleSmsPreset>(_onTogglePreset);
    on<SaveSmsPreset>(_onSavePreset);
    on<DeleteSmsPreset>(_onDeletePreset);
    on<TestSmsRule>(_onTestRule);
    on<ImportSmsMessages>(_onImportMessages);
    on<RequestSmsPermission>(_onRequestPermission);
  }

  Future<void> _onLoadPresets(
    LoadSmsPresets event,
    Emitter<SmsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final hasPermission = await _smsRepository.hasSmsPermission();
    final presets = await _smsRepository.getAllPresets();

    emit(
      state.copyWith(
        isLoading: false,
        hasPermission: hasPermission,
        presets: presets,
      ),
    );
  }

  Future<void> _onTogglePreset(
    ToggleSmsPreset event,
    Emitter<SmsState> emit,
  ) async {
    await _smsRepository.togglePreset(event.presetId, event.isEnabled);
    add(LoadSmsPresets());
  }

  Future<void> _onSavePreset(
    SaveSmsPreset event,
    Emitter<SmsState> emit,
  ) async {
    await _smsRepository.savePreset(event.preset);
    add(LoadSmsPresets());
  }

  Future<void> _onDeletePreset(
    DeleteSmsPreset event,
    Emitter<SmsState> emit,
  ) async {
    await _smsRepository.deletePreset(event.presetId);
    add(LoadSmsPresets());
  }

  Future<void> _onTestRule(TestSmsRule event, Emitter<SmsState> emit) async {
    final result = _parser.testRule(event.smsBody, event.rule);
    emit(state.copyWith(testResult: result));
  }

  Future<void> _onImportMessages(
    ImportSmsMessages event,
    Emitter<SmsState> emit,
  ) async {
    emit(state.copyWith(isImporting: true, importProgress: 0));

    final enabledPresets = await _smsRepository.getEnabledPresets();
    if (enabledPresets.isEmpty) {
      emit(
        state.copyWith(isImporting: false, importError: 'No presets enabled'),
      );
      return;
    }

    final senderFilters = enabledPresets.map((p) => p.senderFilter).toList();
    final messages = await _smsRepository.getSmsMessages(
      since: event.since,
      senderFilters: senderFilters,
    );

    final parsed = <SmsParseResult>[];
    for (var i = 0; i < messages.length; i++) {
      final msg = messages[i];
      for (final preset in enabledPresets) {
        if (msg.sender.toLowerCase().contains(
          preset.senderFilter.toLowerCase(),
        )) {
          final result = _parser.parse(msg.body, preset);
          if (result.isMatch) {
            parsed.add(result);
            break;
          }
        }
      }
      emit(state.copyWith(importProgress: (i + 1) / messages.length));
    }

    await _smsRepository.setLastSyncTimestamp(DateTime.now());

    emit(
      state.copyWith(
        isImporting: false,
        importedResults: parsed,
        lastSyncTimestamp: DateTime.now(),
      ),
    );
  }

  Future<void> _onRequestPermission(
    RequestSmsPermission event,
    Emitter<SmsState> emit,
  ) async {
    final granted = await _smsRepository.requestSmsPermission();
    emit(state.copyWith(hasPermission: granted));
    if (granted) {
      add(LoadSmsPresets());
    }
  }
}
