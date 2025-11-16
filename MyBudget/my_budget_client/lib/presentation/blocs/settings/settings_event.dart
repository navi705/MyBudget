part of 'settings_bloc.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override
  List<Object> get props => [];
}

class LoadSettings extends SettingsEvent {}

class UpdateThemeMode extends SettingsEvent {
  final ThemeMode themeMode;
  const UpdateThemeMode(this.themeMode);
  @override
  List<Object> get props => [themeMode];
}

class _SettingsUpdated extends SettingsEvent {
  final ThemeMode themeMode;
  const _SettingsUpdated(this.themeMode);
  @override
  List<Object> get props => [themeMode];
}
