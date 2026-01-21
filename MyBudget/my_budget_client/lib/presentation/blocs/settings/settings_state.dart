part of 'settings_bloc.dart';

class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final Map<String, String> settings;
  final List<String> countries;
  final Map<String, String> hotkeys;
  final String? deviceName;
  final Locale? locale;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.settings = const {},
    this.countries = const [],
    this.hotkeys = const {},
    this.deviceName,
    this.locale,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    Map<String, String>? settings,
    List<String>? countries,
    Map<String, String>? hotkeys,
    String? deviceName,
    Locale? locale,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      settings: settings ?? this.settings,
      countries: countries ?? this.countries,
      hotkeys: hotkeys ?? this.hotkeys,
      deviceName: deviceName ?? this.deviceName,
      locale: locale ?? this.locale,
    );
  }

  @override
  List<Object?> get props => [
    themeMode,
    settings,
    countries,
    hotkeys,
    deviceName,
    locale,
  ];
}
