part of 'settings_bloc.dart';

class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final Map<String, String> settings;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.settings = const {},
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    Map<String, String>? settings,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      settings: settings ?? this.settings,
    );
  }

  @override
  List<Object> get props => [themeMode, settings];
}