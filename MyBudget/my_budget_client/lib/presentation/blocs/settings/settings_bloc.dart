import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _settingsRepository;
  StreamSubscription? _settingsSubscription;

  SettingsBloc({required SettingsRepository settingsRepository})
      : _settingsRepository = settingsRepository,
        super(const SettingsState()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateThemeMode>(_onUpdateThemeMode);
    on<_SettingsUpdated>(_onSettingsUpdated);
  }

  void _onLoadSettings(LoadSettings event, Emitter<SettingsState> emit) {
    _settingsSubscription?.cancel();
    _settingsSubscription = _settingsRepository.themeMode.listen(
      (themeMode) => add(_SettingsUpdated(themeMode)),
    );
  }

  Future<void> _onUpdateThemeMode(
    UpdateThemeMode event,
    Emitter<SettingsState> emit,
  ) async {
    await _settingsRepository.setThemeMode(event.themeMode);
  }

  void _onSettingsUpdated(
    _SettingsUpdated event,
    Emitter<SettingsState> emit,
  ) {
    emit(state.copyWith(themeMode: event.themeMode));
  }

  @override
  Future<void> close() {
    _settingsSubscription?.cancel();
    return super.close();
  }
}
