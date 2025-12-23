part of 'settings_bloc.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override
  List<Object> get props => [];
}

class LoadSettings extends SettingsEvent {}

class UpdateSetting extends SettingsEvent {
  final String key;
  final String value;

  const UpdateSetting(this.key, this.value);

  @override
  List<Object> get props => [key, value];
}

class UpdateThemeMode extends SettingsEvent {
  final ThemeMode themeMode;
  const UpdateThemeMode(this.themeMode);
  @override
  List<Object> get props => [themeMode];
}

class _SettingsChanged extends SettingsEvent {
  final List<Setting> settings;

  const _SettingsChanged(this.settings);

  @override
  List<Object> get props => [settings];
}
