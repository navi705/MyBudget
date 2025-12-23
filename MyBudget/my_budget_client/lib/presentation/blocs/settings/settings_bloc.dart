import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/utils/device_utils.dart';
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
    on<UpdateSetting>(_onUpdateSetting);
    on<UpdateThemeMode>(_onUpdateThemeMode);
    on<_SettingsChanged>(_onSettingsChanged);
  }

  void _onLoadSettings(LoadSettings event, Emitter<SettingsState> emit) {
    _settingsSubscription?.cancel();
    _settingsSubscription = _settingsRepository.watchAllSettings().listen(
          (settings) => add(_SettingsChanged(settings)),
        );
  }

  Future<void> _onUpdateSetting(
    UpdateSetting event,
    Emitter<SettingsState> emit,
  ) async {
    final deviceName = await getDeviceName();
    await _settingsRepository.setSetting(Setting(
      key: event.key,
      value: event.value,
      device: deviceName,
    ));
  }

  Future<void> _onUpdateThemeMode(
    UpdateThemeMode event,
    Emitter<SettingsState> emit,
  ) async {
    final deviceName = await getDeviceName();
    await _settingsRepository.setThemeMode(event.themeMode, deviceName);
  }

  void _onSettingsChanged(
    _SettingsChanged event,
    Emitter<SettingsState> emit,
  ) {
    final settingsMap = {for (var s in event.settings) s.key: s.value};
    final themeModeValue = settingsMap['themeMode'] ?? 'system';
    final themeMode = _stringToThemeMode(themeModeValue);

    emit(state.copyWith(
      settings: settingsMap,
      themeMode: themeMode,
    ));
  }

  ThemeMode _stringToThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  @override
  Future<void> close() {
    _settingsSubscription?.cancel();
    return super.close();
  }
}
