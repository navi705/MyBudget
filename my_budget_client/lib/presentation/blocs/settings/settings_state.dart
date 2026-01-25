part of 'settings_bloc.dart';

class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final Map<String, String> settings;
  final Map<String, String> countries;
  final Map<String, String> allCountries;
  final Map<String, String> hotkeys;
  final String? deviceName;
  final Locale? locale;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.settings = const {},
    this.countries = const {},
    this.allCountries = const {},
    this.hotkeys = const {},
    this.deviceName,
    this.locale,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    Map<String, String>? settings,
    Map<String, String>? countries,
    Map<String, String>? allCountries,
    Map<String, String>? hotkeys,
    String? deviceName,
    Locale? locale,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      settings: settings ?? this.settings,
      countries: countries ?? this.countries,
      allCountries: allCountries ?? this.allCountries,
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
    allCountries,
    hotkeys,
    deviceName,
    locale,
  ];
}
