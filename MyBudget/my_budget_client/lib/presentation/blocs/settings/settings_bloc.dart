import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_budget_client/core/utils/device_utils.dart' as dev_utils;
import 'package:my_budget_client/core/utils/hotkey_utils.dart';
import 'package:my_budget_client/domain/entities/settings.dart';
import 'package:my_budget_client/domain/repositories/inflation_repository.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/core/services/inflation_api_service.dart';
import 'package:my_budget_client/core/utils/country_codes.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _settingsRepository;
  final InflationRepository _inflationRepository;
  final InflationApiService _inflationApiService;
  StreamSubscription? _settingsSubscription;

  SettingsBloc({
    required SettingsRepository settingsRepository,
    required InflationRepository inflationRepository,
    required InflationApiService inflationApiService,
  }) : _settingsRepository = settingsRepository,
       _inflationRepository = inflationRepository,
       _inflationApiService = inflationApiService,
       super(const SettingsState()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateSetting>(_onUpdateSetting);
    on<UpdateThemeMode>(_onUpdateThemeMode);
    on<UpdateHotkey>(_onUpdateHotkey);
    on<_SettingsChanged>(_onSettingsChanged);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    final deviceName = await dev_utils.getDeviceName();
    emit(state.copyWith(deviceName: deviceName));

    _settingsSubscription?.cancel();
    _settingsSubscription = _settingsRepository.watchAllSettings().listen(
      (settings) => add(_SettingsChanged(settings)),
    );
  }

  Future<void> _onUpdateSetting(
    UpdateSetting event,
    Emitter<SettingsState> emit,
  ) async {
    await _settingsRepository.saveSetting(event.key, event.value);

    // If default inflation country changed, trigger a fetch in the background
    if (event.key == 'default_inflation_country') {
      unawaited(
        _inflationApiService.fetchInflationForCountry(
          event.value,
          "2000:2024", // Default range
        ),
      );
    }
  }

  Future<void> _onUpdateThemeMode(
    UpdateThemeMode event,
    Emitter<SettingsState> emit,
  ) async {
    await _settingsRepository.saveThemeMode(event.themeMode);
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
        // Clear the existing one
        await _settingsRepository.saveSetting('hotkey_$existingActionId', '');
      }
    }

    await _settingsRepository.saveSetting(
      'hotkey_${event.actionId}',
      event.keySetString,
    );
  }

  Future<void> _onSettingsChanged(
    _SettingsChanged event,
    Emitter<SettingsState> emit,
  ) async {
    final deviceName = state.deviceName ?? await dev_utils.getDeviceName();
    // Filter settings for the current device
    final settingsMap = {
      for (var s in event.settings)
        if (s.device == deviceName) s.key: s.value,
    };
    final themeModeValue = settingsMap['themeMode'] ?? 'system';
    final themeMode = _stringToThemeMode(themeModeValue);

    final languageCode = settingsMap['language_code'];
    final locale = languageCode != null && languageCode.isNotEmpty
        ? Locale(languageCode)
        : null;

    final countries = await _inflationRepository.getAvailableCountries();
    // Convert List<String> to Map<String, String> if needed,
    // but the state now expect Map<String, String> for countries.
    // Actually, getAvailableCountries returns what's already in DB.
    // Convert List<String> to Map<String, String> where key is the code and value is the full name.
    final Map<String, String> availableCountriesMap = {
      for (var code in countries)
        code: worldBankCountryCodes.entries
            .firstWhere(
              (e) => e.value == code,
              orElse: () =>
                  MapEntry(code, code), // If not found, map code to itself
            )
            .key, // Get the full name (key) from worldBankCountryCodes
    };

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
      SettingsState(
        settings: settingsMap,
        themeMode: themeMode,
        countries: availableCountriesMap,
        allCountries: worldBankCountryCodes,
        hotkeys: hotkeys,
        locale: locale,
        deviceName: deviceName,
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

    // Data Tabs
    addIfMissing('data_tab_1', {
      LogicalKeyboardKey.control,
      LogicalKeyboardKey.digit1,
    });
    addIfMissing('data_tab_2', {
      LogicalKeyboardKey.control,
      LogicalKeyboardKey.digit2,
    });
    addIfMissing('data_tab_3', {
      LogicalKeyboardKey.control,
      LogicalKeyboardKey.digit3,
    });

    // Period Navigation
    addIfMissing('prev_period', {LogicalKeyboardKey.arrowLeft});
    addIfMissing('next_period', {LogicalKeyboardKey.arrowRight});

    addIfMissing('add_action', {
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
