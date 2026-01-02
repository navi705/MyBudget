import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:my_budget_client/core/theme/app_theme.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';

part 'theme_event.dart';
part 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final SettingsRepository _settingsRepository;

  ThemeBloc({required SettingsRepository settingsRepository})
    : _settingsRepository = settingsRepository,
      super(const ThemeState()) {
    on<LoadThemeSettings>(_onLoadThemeSettings);
    on<ChangeThemeColor>(_onChangeThemeColor);
    on<ChangeWindowEffect>(_onChangeWindowEffect);
    on<ChangeWindowOpacity>(_onChangeWindowOpacity);
    on<ChangeThemeMode>(_onChangeThemeMode);
  }

  Future<void> _onLoadThemeSettings(
    LoadThemeSettings event,
    Emitter<ThemeState> emit,
  ) async {
    final settings = await _settingsRepository.getAllSettings();
    final currentThemeMode = await _settingsRepository.getSetting('themeMode');

    final themeColorHex = settings['theme_color'] ?? '#2196F3';
    final windowEffectStr = settings['window_effect'] ?? 'none';
    final windowOpacityStr = settings['window_opacity'] ?? '0.8';

    final themeColor = AppTheme.parseHex(themeColorHex);
    final themeMode = _stringToThemeMode(currentThemeMode?.value ?? 'system');
    final windowEffect = WindowEffectType.values.firstWhere(
      (e) => e.name == windowEffectStr,
      orElse: () => WindowEffectType.none,
    );
    final windowOpacity = double.tryParse(windowOpacityStr) ?? 0.8;

    emit(
      state.copyWith(
        themeColor: themeColor,
        themeMode: themeMode,
        windowEffect: windowEffect,
        windowOpacity: windowOpacity,
        isLoaded: true,
      ),
    );
  }

  Future<void> _onChangeThemeColor(
    ChangeThemeColor event,
    Emitter<ThemeState> emit,
  ) async {
    emit(state.copyWith(themeColor: event.color));
    await _settingsRepository.saveSetting(
      'theme_color',
      AppTheme.toHex(event.color),
    );
  }

  Future<void> _onChangeWindowEffect(
    ChangeWindowEffect event,
    Emitter<ThemeState> emit,
  ) async {
    emit(state.copyWith(windowEffect: event.effect));
    await _settingsRepository.saveSetting('window_effect', event.effect.name);
  }

  Future<void> _onChangeWindowOpacity(
    ChangeWindowOpacity event,
    Emitter<ThemeState> emit,
  ) async {
    emit(state.copyWith(windowOpacity: event.opacity));
    await _settingsRepository.saveSetting(
      'window_opacity',
      event.opacity.toString(),
    );
  }

  Future<void> _onChangeThemeMode(
    ChangeThemeMode event,
    Emitter<ThemeState> emit,
  ) async {
    emit(state.copyWith(themeMode: event.mode));
    await _settingsRepository.setThemeMode(event.mode, 'all');
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
}
