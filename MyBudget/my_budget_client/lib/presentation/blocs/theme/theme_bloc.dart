import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:my_budget_client/core/theme/app_theme.dart';
import 'package:my_budget_client/core/theme/default_themes.dart';
import 'package:my_budget_client/domain/entities/custom_theme.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/domain/repositories/theme_repository.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'theme_event.dart';
part 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final SettingsRepository _settingsRepository;
  final ThemeRepository _themeRepository;

  ThemeBloc({
    required SettingsRepository settingsRepository,
    required ThemeRepository themeRepository,
  }) : _settingsRepository = settingsRepository,
       _themeRepository = themeRepository,
       super(const ThemeState()) {
    on<LoadThemeSettings>(_onLoadThemeSettings);
    on<SelectThemePreset>(_onSelectThemePreset);
    on<SaveThemePreset>(_onSaveThemePreset);
    on<DeleteThemePreset>(_onDeleteThemePreset);
    on<UpdateThemeProperty>(_onUpdateThemeProperty);
  }

  Future<void> _onLoadThemeSettings(
    LoadThemeSettings event,
    Emitter<ThemeState> emit,
  ) async {
    // 1. Check if we have any themes
    List<CustomTheme> themes = await _themeRepository.getAllThemes();

    // 2. Seed default presets if none exist
    if (themes.isEmpty) {
      for (final preset in defaultThemePresets) {
        await _themeRepository.saveTheme(preset);
      }
      themes = await _themeRepository.getAllThemes();
    }

    // 3. Get active theme
    CustomTheme? activeTheme = await _themeRepository.getActiveTheme();

    // 4. Fallback: Check old settings if no active theme found (Migration)
    if (activeTheme == null) {
      final activeId = await _settingsRepository.getSetting('active_theme_id');
      if (activeId != null) {
        activeTheme = themes.firstWhere(
          (t) => t.id == activeId.value,
          orElse: () => themes.first,
        );
      } else {
        // Migration from old separate settings
        final settings = await _settingsRepository.getAllSettings();
        if (settings.containsKey('theme_color')) {
          activeTheme = CustomTheme(
            id: 'custom-migrated',
            name: 'Custom',
            primaryColor: AppTheme.parseHex(settings['theme_color']!),
            secondaryColor: AppTheme.parseHex(
              settings['secondary_color'] ?? '#9C27B0',
            ),
            surfaceColor: AppTheme.parseHex(
              settings['surface_color'] ?? '#121212',
            ),
            backgroundColor: AppTheme.parseHex(
              settings['background_color'] ?? '#121212',
            ),
            backgroundImagePath: settings['background_image_path'],
            windowEffectType: WindowEffectType.values.firstWhere(
              (e) => e.name == (settings['window_effect'] ?? 'none'),
              orElse: () => WindowEffectType.none,
            ),
            effectOpacity:
                double.tryParse(settings['window_opacity'] ?? '0.8') ?? 0.8,
            themeMode: ThemeMode.values.firstWhere(
              (e) => e.name == (settings['themeMode'] ?? 'system'),
              orElse: () => ThemeMode.system,
            ),
            isPreset: false,
            isActive: true,
          );
          await _themeRepository.saveTheme(activeTheme);
        } else {
          activeTheme = themes.first;
        }
      }
      await _themeRepository.setActiveTheme(activeTheme.id);
    }

    emit(
      state.copyWith(activeTheme: activeTheme, presets: themes, isLoaded: true),
    );
  }

  Future<void> _onSelectThemePreset(
    SelectThemePreset event,
    Emitter<ThemeState> emit,
  ) async {
    await _themeRepository.setActiveTheme(event.presetId);
    final themes = await _themeRepository.getAllThemes();
    final activeTheme = themes.firstWhere((t) => t.id == event.presetId);

    // Also sync the old settings for backward compatibility if any parts still use them
    await _settingsRepository.saveSetting('active_theme_id', event.presetId);
    await _settingsRepository.setThemeMode(activeTheme.themeMode, 'all');

    emit(state.copyWith(activeTheme: activeTheme, presets: themes));
  }

  Future<void> _onUpdateThemeProperty(
    UpdateThemeProperty event,
    Emitter<ThemeState> emit,
  ) async {
    if (state.activeTheme == null) return;

    String? bgPath = event.backgroundImagePath;

    // Logic to save image to app storage if it's new and not an asset
    if (bgPath != null &&
        !event.clearBackgroundImage &&
        !bgPath.startsWith('assets/')) {
      try {
        final File file = File(bgPath);
        if (await file.exists()) {
          final appDir = await getApplicationDocumentsDirectory();
          final fileName = p.basename(bgPath);
          final savedDir = Directory(p.join(appDir.path, 'custom_backgrounds'));
          if (!await savedDir.exists()) {
            await savedDir.create(recursive: true);
          }
          final savedFile = File(p.join(savedDir.path, fileName));

          // Copy only if paths are different (avoid error if user picks same file from app dir)
          if (file.path != savedFile.path) {
            await file.copy(savedFile.path);
            bgPath = savedFile.path;
          }
        }
      } catch (e) {
        debugPrint('Error saving background image: $e');
        // Fallback to original path if copy fails
      }
    }

    CustomTheme updatedTheme = state.activeTheme!.copyWith(
      primaryColor: event.primaryColor,
      secondaryColor: event.secondaryColor,
      surfaceColor:
          event.surfaceColor, // Keep color even if clearBackgroundImage is true
      backgroundColor: event.backgroundColor,
      backgroundImagePath: bgPath,
      clearBackgroundImage: event.clearBackgroundImage,
      backgroundImageOpacity: event.backgroundImageOpacity,
      backgroundImageBlur: event.backgroundImageBlur,
      windowEffectType: event.windowEffectType,
      effectOpacity: event.effectOpacity,
      surfaceOpacity: event.surfaceOpacity,
      themeMode: event.themeMode,
    );

    // If it was a preset, we create a NEW "Custom" theme or update the existing "Custom" theme
    if (updatedTheme.isPreset) {
      updatedTheme = updatedTheme.copyWith(
        id: 'custom-theme',
        name: 'Custom Theme',
        isPreset: false,
        isActive: true,
      );
    }

    await _themeRepository.saveTheme(updatedTheme);
    await _themeRepository.setActiveTheme(updatedTheme.id);

    final themes = await _themeRepository.getAllThemes();
    emit(state.copyWith(activeTheme: updatedTheme, presets: themes));
  }

  Future<void> _onSaveThemePreset(
    SaveThemePreset event,
    Emitter<ThemeState> emit,
  ) async {
    if (state.activeTheme == null) return;

    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newPreset = state.activeTheme!.copyWith(
      id: newId,
      name: event.name,
      isPreset: false,
      isActive: true,
    );

    await _themeRepository.saveTheme(newPreset);
    await _themeRepository.setActiveTheme(newId);

    final themes = await _themeRepository.getAllThemes();
    emit(state.copyWith(activeTheme: newPreset, presets: themes));
  }

  Future<void> _onDeleteThemePreset(
    DeleteThemePreset event,
    Emitter<ThemeState> emit,
  ) async {
    if (event.presetId == state.activeTheme?.id) {
      // Cannot delete active theme, or switch to default first
      final defaultTheme = state.presets.firstWhere((t) => t.isPreset);
      await _themeRepository.setActiveTheme(defaultTheme.id);
    }

    await _themeRepository.deleteTheme(event.presetId);
    final themes = await _themeRepository.getAllThemes();
    final activeTheme = await _themeRepository.getActiveTheme();

    emit(state.copyWith(activeTheme: activeTheme, presets: themes));
  }
}
