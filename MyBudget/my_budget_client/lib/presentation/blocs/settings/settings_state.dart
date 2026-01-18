part of 'settings_bloc.dart';

class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final Map<String, String> settings;
  final List<String> countries;
  final Map<String, String> hotkeys;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.settings = const {},
    this.countries = const [],
    this.hotkeys = const {},
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    Map<String, String>? settings,
    List<String>? countries,
    Map<String, String>? hotkeys,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      settings: settings ?? this.settings,
      countries: countries ?? this.countries,
      hotkeys: hotkeys ?? this.hotkeys,
    );
  }

  @override
  List<Object> get props => [themeMode, settings, countries, hotkeys];
}
