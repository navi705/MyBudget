part of 'settings_bloc.dart';

class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final Map<String, String> settings;
  final List<String> countries;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.settings = const {},
    this.countries = const [],
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    Map<String, String>? settings,
    List<String>? countries,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      settings: settings ?? this.settings,
      countries: countries ?? this.countries,
    );
  }

  @override
  List<Object> get props => [themeMode, settings, countries];
}