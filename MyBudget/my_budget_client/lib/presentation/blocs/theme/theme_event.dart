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
