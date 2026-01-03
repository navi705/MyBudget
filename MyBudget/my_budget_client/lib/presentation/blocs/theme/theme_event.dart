part of 'theme_bloc.dart';

abstract class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object?> get props => [];
}

class LoadThemeSettings extends ThemeEvent {
  const LoadThemeSettings();
}

class SelectThemePreset extends ThemeEvent {
  final String presetId;
  const SelectThemePreset(this.presetId);

  @override
  List<Object?> get props => [presetId];
}

class SaveThemePreset extends ThemeEvent {
  final String name;
  const SaveThemePreset(this.name);

  @override
  List<Object?> get props => [name];
}

class DeleteThemePreset extends ThemeEvent {
  final String presetId;
  const DeleteThemePreset(this.presetId);

  @override
  List<Object?> get props => [presetId];
}

class UpdateThemeProperty extends ThemeEvent {
  final Color? primaryColor;
  final Color? secondaryColor;
  final Color? surfaceColor;
  final Color? backgroundColor;
  final String? backgroundImagePath;
  final double? backgroundImageOpacity;
  final double? backgroundImageBlur;
  final WindowEffectType? windowEffectType;
  final double? effectOpacity;
  final double? surfaceOpacity;
  final ThemeMode? themeMode;
  final bool clearBackgroundImage;

  const UpdateThemeProperty({
    this.primaryColor,
    this.secondaryColor,
    this.surfaceColor,
    this.backgroundColor,
    this.backgroundImagePath,
    this.backgroundImageOpacity,
    this.backgroundImageBlur,
    this.windowEffectType,
    this.effectOpacity,
    this.surfaceOpacity,
    this.themeMode,
    this.clearBackgroundImage = false,
  });

  @override
  List<Object?> get props => [
    primaryColor,
    secondaryColor,
    surfaceColor,
    backgroundColor,
    backgroundImagePath,
    backgroundImageOpacity,
    backgroundImageBlur,
    windowEffectType,
    effectOpacity,
    surfaceOpacity,
    themeMode,
    clearBackgroundImage,
  ];
}
