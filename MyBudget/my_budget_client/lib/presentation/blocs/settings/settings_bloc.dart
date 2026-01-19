import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_budget_client/core/utils/device_utils.dart';
import 'package:my_budget_client/core/utils/hotkey_utils.dart';
import 'package:my_budget_client/domain/entities/settings.dart';
import 'package:my_budget_client/domain/repositories/inflation_repository.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _settingsRepository;
  final InflationRepository _inflationRepository;
  StreamSubscription? _settingsSubscription;

  SettingsBloc({
    required SettingsRepository settingsRepository,
    required InflationRepository inflationRepository,
  }) : _settingsRepository = settingsRepository,
       _inflationRepository = inflationRepository,
       super(const SettingsState()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateSetting>(_onUpdateSetting);
    on<UpdateThemeMode>(_onUpdateThemeMode);
    on<UpdateHotkey>(_onUpdateHotkey);
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
    await _settingsRepository.setSetting(
      Settings(key: event.key, value: event.value, device: deviceName),
    );
  }

  Future<void> _onUpdateThemeMode(
    UpdateThemeMode event,
    Emitter<SettingsState> emit,
  ) async {
    final deviceName = await getDeviceName();
    await _settingsRepository.setThemeMode(event.themeMode, deviceName);
  }

  Future<void> _onUpdateHotkey(
    UpdateHotkey event,
    Emitter<SettingsState> emit,
  ) async {
    // Duplicate Protection: Check if this hotkey is already assigned to another action
    if (event.keySetString.isNotEmpty) {
      final existingActionId = state.hotkeys.entries
          .where(
            (e) => e.value == event.keySetString && e.key != event.actionId,
          )
          .map((e) => e.key)
          .firstOrNull;

      if (existingActionId != null) {
        // We could emit an error state here, but for now we'll just prevent the update
        // or clear the other one. User asked for "protection", so let's prevent and maybe we could notify (though notify_user is for me).
        // Let's clear the old one to ensure uniqueness.
        final deviceName = await getDeviceName();
        // Clear the existing one
        await _settingsRepository.setSetting(
          Settings(
            key: 'hotkey_$existingActionId',
            value: '',
            device: deviceName,
          ),
        );
      }
    }

    final deviceName = await getDeviceName();
    await _settingsRepository.setSetting(
      Settings(
        key: 'hotkey_${event.actionId}',
        value: event.keySetString,
        device: deviceName,
      ),
    );
  }

  Future<void> _onSettingsChanged(
    _SettingsChanged event,
    Emitter<SettingsState> emit,
  ) async {
    final settingsMap = {for (var s in event.settings) s.key: s.value};
    final themeModeValue = settingsMap['themeMode'] ?? 'system';
    final themeMode = _stringToThemeMode(themeModeValue);

    final countries = await _inflationRepository.getAvailableCountries();

    final hotkeys = <String, String>{};
    settingsMap.forEach((key, value) {
      if (key.startsWith('hotkey_')) {
        final actionId = key.substring(7); // remove 'hotkey_'
        hotkeys[actionId] = value;
      }
    });

    // Default hotkeys if not present
    _addDefaultHotkeys(hotkeys);

    emit(
      state.copyWith(
        settings: settingsMap,
        themeMode: themeMode,
        countries: countries,
        hotkeys: hotkeys,
      ),
    );
  }

  void _addDefaultHotkeys(Map<String, String> hotkeys) {
    void addIfMissing(String id, Set<LogicalKeyboardKey> keys) {
      if (!hotkeys.containsKey(id)) {
        hotkeys[id] = HotKeyUtils.serializeKeys(keys);
      }
    }

    // Navigation (Sidebar)
    addIfMissing('dashboard', {
      LogicalKeyboardKey.alt,
      LogicalKeyboardKey.digit1,
    });
    addIfMissing('accounts', {
      LogicalKeyboardKey.alt,
      LogicalKeyboardKey.digit2,
    });
    addIfMissing('transactions', {
      LogicalKeyboardKey.alt,
      LogicalKeyboardKey.digit3,
    });
    addIfMissing('categories', {
      LogicalKeyboardKey.alt,
      LogicalKeyboardKey.digit4,
    });
    addIfMissing('data', {LogicalKeyboardKey.alt, LogicalKeyboardKey.digit5});
    addIfMissing('settings', {LogicalKeyboardKey.alt, LogicalKeyboardKey.keyS});

    // Dashboard Tabs
    addIfMissing('dashboard_tab_1', {
      LogicalKeyboardKey.control,
      LogicalKeyboardKey.digit1,
    });
    addIfMissing('dashboard_tab_2', {
      LogicalKeyboardKey.control,
      LogicalKeyboardKey.digit2,
    });
    addIfMissing('dashboard_tab_3', {
      LogicalKeyboardKey.control,
      LogicalKeyboardKey.digit3,
    });

    // Period Navigation
    addIfMissing('prev_period', {LogicalKeyboardKey.arrowLeft});
    addIfMissing('next_period', {LogicalKeyboardKey.arrowRight});

    addIfMissing('add_transaction', {
      LogicalKeyboardKey.control,
      LogicalKeyboardKey.keyA,
    });
    addIfMissing('add_account', {
      LogicalKeyboardKey.control,
      LogicalKeyboardKey.keyA,
    });
    addIfMissing('add_category', {
      LogicalKeyboardKey.control,
      LogicalKeyboardKey.keyA,
    });
    addIfMissing('add_exchange_rate', {
      LogicalKeyboardKey.control,
      LogicalKeyboardKey.keyA,
    });
    addIfMissing('add_inflation_rate', {
      LogicalKeyboardKey.control,
      LogicalKeyboardKey.keyA,
    });
    addIfMissing('add_asset', {
      LogicalKeyboardKey.control,
      LogicalKeyboardKey.keyA,
    });
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
