part of 'theme_bloc.dart';

abstract class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object?> get props => [];
}

class LoadThemeSettings extends ThemeEvent {
  const LoadThemeSettings();
}

class ChangeThemeColor extends ThemeEvent {
  final Color color;

  const ChangeThemeColor(this.color);

  @override
  List<Object?> get props => [color];
}

class ChangeWindowEffect extends ThemeEvent {
  final WindowEffectType effect;

  const ChangeWindowEffect(this.effect);

  @override
  List<Object?> get props => [effect];
}

class ChangeWindowOpacity extends ThemeEvent {
  final double opacity;

  const ChangeWindowOpacity(this.opacity);

  @override
  List<Object?> get props => [opacity];
}

class ChangeThemeMode extends ThemeEvent {
  final ThemeMode mode;

  const ChangeThemeMode(this.mode);

  @override
  List<Object?> get props => [mode];
}

class ChangeBackgroundImage extends ThemeEvent {
  final String? path;

  const ChangeBackgroundImage(this.path);

  @override
  List<Object?> get props => [path];
}

class AddUserPreset extends ThemeEvent {
  final String path;

  const AddUserPreset(this.path);

  @override
  List<Object?> get props => [path];
}

class DeleteUserPreset extends ThemeEvent {
  final String path;

  const DeleteUserPreset(this.path);

  @override
  List<Object?> get props => [path];
}

class ChangeSecondaryColor extends ThemeEvent {
  final Color color;

  const ChangeSecondaryColor(this.color);

  @override
  List<Object?> get props => [color];
}

class ChangeSurfaceColor extends ThemeEvent {
  final Color color;

  const ChangeSurfaceColor(this.color);

  @override
  List<Object?> get props => [color];
}
