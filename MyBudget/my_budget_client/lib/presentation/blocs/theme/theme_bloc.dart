import 'dart:convert';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:my_budget_client/core/theme/app_theme.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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
    on<ChangeBackgroundImage>(_onChangeBackgroundImage);
    on<AddUserPreset>(_onAddUserPreset);
    on<DeleteUserPreset>(_onDeleteUserPreset);
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
    final backgroundImagePath = settings['background_image_path'];

    final themeColor = AppTheme.parseHex(themeColorHex);
    final themeMode = _stringToThemeMode(currentThemeMode?.value ?? 'system');
    final windowEffect = WindowEffectType.values.firstWhere(
      (e) => e.name == windowEffectStr,
      orElse: () => WindowEffectType.none,
    );
    final windowOpacity = double.tryParse(windowOpacityStr) ?? 0.8;

    final userPresetsJson = settings['user_presets'] ?? '[]';
    List<String> userPresets = [];
    try {
      userPresets = List<String>.from(jsonDecode(userPresetsJson));
    } catch (e) {
      debugPrint('Error decoding user presets: $e');
    }

    emit(
      state.copyWith(
        themeColor: themeColor,
        themeMode: themeMode,
        windowEffect: windowEffect,
        windowOpacity: windowOpacity,
        backgroundImagePath: backgroundImagePath,
        userPresets: userPresets,
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

  Future<void> _onChangeBackgroundImage(
    ChangeBackgroundImage event,
    Emitter<ThemeState> emit,
  ) async {
    String? pathToSave = event.path;

    if (event.path != null && !event.path!.startsWith('assets/')) {
      try {
        final appSupportDir = await getApplicationSupportDirectory();
        final fileName = p.basename(event.path!);
        final localPath = p.join(appSupportDir.path, 'backgrounds', fileName);

        // Ensure directory exists
        final bgDir = Directory(p.dirname(localPath));
        if (!await bgDir.exists()) {
          await bgDir.create(recursive: true);
        }

        await File(event.path!).copy(localPath);
        pathToSave = localPath;
      } catch (e) {
        debugPrint('Error saving background image: $e');
        // Fallback to original path if copy fails
      }
    }

    emit(
      state.copyWith(
        backgroundImagePath: pathToSave,
        clearBackgroundImage: pathToSave == null,
      ),
    );

    if (pathToSave == null) {
      await _settingsRepository.saveSetting('background_image_path', '');
    } else {
      await _settingsRepository.saveSetting(
        'background_image_path',
        pathToSave,
      );
    }
  }

  Future<void> _onAddUserPreset(
    AddUserPreset event,
    Emitter<ThemeState> emit,
  ) async {
    if (state.userPresets.contains(event.path)) return;

    final newList = List<String>.from(state.userPresets)..add(event.path);
    emit(state.copyWith(userPresets: newList));
    await _settingsRepository.saveSetting('user_presets', jsonEncode(newList));
  }

  Future<void> _onDeleteUserPreset(
    DeleteUserPreset event,
    Emitter<ThemeState> emit,
  ) async {
    final newList = List<String>.from(state.userPresets)..remove(event.path);
    emit(state.copyWith(userPresets: newList));
    await _settingsRepository.saveSetting('user_presets', jsonEncode(newList));
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
