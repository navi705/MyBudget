import 'dart:ui' show PlatformDispatcher;
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:my_budget_client/core/theme/app_theme.dart';
import 'package:my_budget_client/core/theme/default_themes.dart';
import 'package:my_budget_client/domain/entities/custom_theme.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/domain/repositories/theme_repository.dart';
import 'package:my_budget_client/core/utils/platform/platform_utils.dart';
import 'package:my_budget_client/core/utils/platform/io_helper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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

  /// The built-in theme to paint with when the saved one cannot be read.
  ///
  /// Mirrors the first-run choice further down, so a user whose theme fails to
  /// load sees the same defaults a fresh install would rather than an
  /// arbitrary preset.
  CustomTheme get _fallbackTheme {
    final wantsDark =
        PlatformDispatcher.instance.platformBrightness == Brightness.dark;
    return defaultThemePresets.firstWhere(
      (t) => t.id == (wantsDark ? 'classic-blue' : 'nordic-frost'),
      orElse: () => defaultThemePresets.first,
    );
  }

  /// A theme from [themes] to hand the app in place of [excludedId],
  /// preferring a built-in preset over one the user made.
  ///
  /// Returns null only when nothing at all is left.
  static CustomTheme? _firstSurviving(
    List<CustomTheme> themes,
    String excludedId,
  ) {
    CustomTheme? custom;
    for (final theme in themes) {
      if (theme.id == excludedId) continue;
      if (theme.isPreset) return theme;
      custom ??= theme;
    }
    return custom;
  }

  Future<void> _onLoadThemeSettings(
    LoadThemeSettings event,
    Emitter<ThemeState> emit,
  ) async {
    ThemeState result;
    try {
      result = await _loadThemeSettings();
    } catch (e) {
      // A theme the database cannot answer for used to take the entire app
      // down with it: this handler had no catch, ThemeState had no way to say
      // "failed", and the app shell renders nothing but a spinner until
      // `isLoaded` turns true. LoadThemeSettings is dispatched exactly once at
      // startup, so there was no second chance either - two rows carrying
      // is_active (which a sync can produce, and which getActiveTheme's
      // getSingleOrNull rejects) meant an app that never came back, with no
      // message and nothing to press.
      //
      // Painting with a built-in preset keeps every screen reachable; the
      // failure rides along in state so the shell can say so and offer a retry.
      debugPrint('[THEME_DEBUG] Theme load failed: $e');
      result = state.copyWith(
        activeTheme: state.activeTheme ?? _fallbackTheme,
        presets: state.presets.isEmpty ? defaultThemePresets : state.presets,
        isLoaded: true,
        loadError: e.toString(),
      );
    }
    emit(result);
  }

  Future<ThemeState> _loadThemeSettings() async {
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
    debugPrint(
      '[THEME_DEBUG] Loaded activeTheme from repo: ${activeTheme?.id}',
    );

    // 4. Fallback: Check old settings if no active theme found (Migration)
    if (activeTheme == null) {
      final activeId = await _settingsRepository.getSetting('active_theme_id');
      debugPrint(
        '[THEME_DEBUG] Fallback active_theme_id from settings: ${activeId?.value}',
      );
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
          // New logic: Select default based on system theme
          // We use PlatformDispatcher.instance as it works outside of the widget tree
          final platformBrightness =
              PlatformDispatcher.instance.platformBrightness;
          debugPrint('[THEME_DEBUG] Entering default selection logic');
          debugPrint(
            '[THEME_DEBUG] Platform brightness detected: $platformBrightness',
          );

          if (platformBrightness == Brightness.dark) {
            debugPrint('[THEME_DEBUG] System is DARK, selecting classic-blue');
            activeTheme = themes.firstWhere(
              (t) => t.id == 'classic-blue',
              orElse: () => themes.first,
            );
          } else {
            debugPrint('[THEME_DEBUG] System is LIGHT, selecting nordic-frost');
            activeTheme = themes.firstWhere(
              (t) => t.id == 'nordic-frost',
              orElse: () => themes.first,
            );
          }
          debugPrint('[THEME_DEBUG] Selected default theme: ${activeTheme.id}');
        }
      }
      debugPrint(
        '[THEME_DEBUG] Finalizing theme selection with ID: ${activeTheme.id}',
      );
      await _themeRepository.setActiveTheme(activeTheme.id);
      // Sync the mode as well to be sure
      await _settingsRepository.setThemeMode(activeTheme.themeMode, 'all');
    }

    return state.copyWith(
      activeTheme: activeTheme,
      presets: themes,
      isLoaded: true,
      clearLoadError: true,
    );
  }

  /// Records a write that did not take, leaving the painted theme alone.
  ///
  /// The four write handlers below had no catch at all, so a repository that
  /// could not answer left the tap looking like it had simply been ignored -
  /// the tile did not move, the slider snapped back, and nothing said why.
  /// Clearing the message at the start of each handler is what makes the same
  /// failure twice reach the screen twice.
  ThemeState _actionFailed(Object error) {
    debugPrint('[THEME_DEBUG] Theme action failed: $error');
    return state.copyWith(actionError: error.toString());
  }

  Future<void> _onSelectThemePreset(
    SelectThemePreset event,
    Emitter<ThemeState> emit,
  ) async {
    emit(state.copyWith(clearActionError: true));
    try {
      await _themeRepository.setActiveTheme(event.presetId);
      final themes = await _themeRepository.getAllThemes();
      // A preset another device deleted between this list being drawn and the
      // tile being tapped is not there to read back. The `firstWhere` here
      // carried no orElse, so that race arrived as an unhandled StateError
      // rather than as a message.
      final matches = themes.where((t) => t.id == event.presetId);
      if (matches.isEmpty) {
        throw StateError('Theme "${event.presetId}" no longer exists');
      }
      final activeTheme = matches.first;

      // Also sync the old settings for backward compatibility if any parts still use them
      await _settingsRepository.saveSetting('active_theme_id', event.presetId);
      await _settingsRepository.setThemeMode(activeTheme.themeMode, 'all');

      emit(state.copyWith(activeTheme: activeTheme, presets: themes));
    } catch (e) {
      emit(_actionFailed(e));
    }
  }

  Future<void> _onUpdateThemeProperty(
    UpdateThemeProperty event,
    Emitter<ThemeState> emit,
  ) async {
    if (state.activeTheme == null) return;
    emit(state.copyWith(clearActionError: true));

    String? bgPath = event.backgroundImagePath;

    // Logic to save image to app storage if it's new and not an asset
    if (!kIsWeb &&
        event.persist &&
        bgPath != null &&
        !event.clearBackgroundImage &&
        !bgPath.startsWith('assets/')) {
      try {
        if (await IoHelper.exists(bgPath)) {
          final appDir = await getApplicationDocumentsDirectory();
          final fileName = p.basename(bgPath);
          final savedDir = p.join(appDir.path, 'custom_backgrounds');
          await IoHelper.createDirectory(savedDir);
          final savedFilePath = p.join(savedDir, fileName);

          // Copy only if paths are different (avoid error if user picks same file from app dir)
          if (bgPath != savedFilePath) {
            await IoHelper.copyFile(bgPath, savedFilePath);
            bgPath = savedFilePath;
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

    // Customising a built-in preset writes a copy instead of the preset
    // itself, and that copy is keyed to the preset it came from. Every preset
    // used to land on the one id 'custom-theme', and saving is an
    // insert-or-replace: a user who had built a look on top of one preset lost
    // it the moment they nudged a single colour on another, with no prompt and
    // nothing to undo it with. The name follows the source too, so the picker
    // does not end up with a row of tiles that all read "Custom Theme".
    final source = state.activeTheme!;
    if (updatedTheme.isPreset) {
      updatedTheme = updatedTheme.copyWith(
        id: 'custom-${source.id}',
        name: '${source.name} (Custom)',
        isPreset: false,
        isActive: true,
      );
    }

    if (event.persist) {
      try {
        await _themeRepository.saveTheme(updatedTheme);
        await _themeRepository.setActiveTheme(updatedTheme.id);

        final themes = await _themeRepository.getAllThemes();
        emit(state.copyWith(activeTheme: updatedTheme, presets: themes));
      } catch (e) {
        // The preview has already been painted by the un-persisted emits this
        // screen sends while a slider is dragged, so a failure here means the
        // app looks changed and the database does not agree. Saying so is the
        // only way the user learns the look will not survive a restart.
        emit(_actionFailed(e));
      }
    } else {
      emit(state.copyWith(activeTheme: updatedTheme));
    }
  }

  Future<void> _onSaveThemePreset(
    SaveThemePreset event,
    Emitter<ThemeState> emit,
  ) async {
    if (state.activeTheme == null) return;
    emit(state.copyWith(clearActionError: true));

    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newPreset = state.activeTheme!.copyWith(
      id: newId,
      name: event.name,
      isPreset: false,
      isActive: true,
    );

    try {
      await _themeRepository.saveTheme(newPreset);
      await _themeRepository.setActiveTheme(newId);

      final themes = await _themeRepository.getAllThemes();
      emit(state.copyWith(activeTheme: newPreset, presets: themes));
    } catch (e) {
      // The dialog that collects the name closes on submit, so a failure with
      // nothing to show it leaves the user believing the preset they just
      // named is in the list.
      emit(_actionFailed(e));
    }
  }

  Future<void> _onDeleteThemePreset(
    DeleteThemePreset event,
    Emitter<ThemeState> emit,
  ) async {
    emit(state.copyWith(clearActionError: true));
    try {
      await _deleteThemePreset(event, emit);
    } catch (e) {
      // A delete that throws used to leave the tile on screen with no
      // explanation, which reads as "the button does nothing".
      emit(_actionFailed(e));
    }
  }

  Future<void> _deleteThemePreset(
    DeleteThemePreset event,
    Emitter<ThemeState> emit,
  ) async {
    if (event.presetId == state.activeTheme?.id) {
      // The theme in use has to be handed over before it is removed. This
      // `firstWhere` carried no orElse, so once a sync soft-deleted the
      // built-in presets - leaving only themes the user made - deleting a theme
      // stopped being a deletion and became an unhandled StateError. Any
      // surviving theme is a better answer than that.
      final replacement = _firstSurviving(state.presets, event.presetId);
      if (replacement != null) {
        await _themeRepository.setActiveTheme(replacement.id);
      }
    }

    await _themeRepository.deleteTheme(event.presetId);
    final themes = await _themeRepository.getAllThemes();
    var activeTheme = await _themeRepository.getActiveTheme();

    if (activeTheme == null) {
      // The repository answers null when the row that was active is the row we
      // just deleted. ThemeState.copyWith reads a null as "leave it alone", so
      // the deleted theme stayed painted on screen and the picker still ticked
      // it as current. Adopting a survivor - and recording it, so the next
      // launch agrees - is the only outcome that leaves the app in a state the
      // user can see and change.
      final survivor = _firstSurviving(themes, event.presetId);
      if (survivor != null) {
        await _themeRepository.setActiveTheme(survivor.id);
      }
      activeTheme = survivor ?? _fallbackTheme;
    }

    emit(state.copyWith(activeTheme: activeTheme, presets: themes));
  }
}
