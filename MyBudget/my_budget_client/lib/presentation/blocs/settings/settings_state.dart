part of 'settings_bloc.dart';

class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final String device;

  const SettingsState({this.themeMode = ThemeMode.system, this.device = ''}); //TODO: What i need to this empty string?

  SettingsState copyWith({ThemeMode? themeMode, String? device}) {
    return SettingsState(themeMode: themeMode ?? this.themeMode, device: device ?? this.device);
  }

  @override
  List<Object> get props => [themeMode, device];
}
  