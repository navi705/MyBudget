import 'package:flutter/material.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:rxdart/rxdart.dart';

const String themeModeKey = 'themeMode';

class LocalSettingsRepository implements SettingsRepository {
  final AppDatabase _database;

  LocalSettingsRepository(this._database);

  @override
  Stream<ThemeMode> get themeMode {
    return watchSetting(themeModeKey).map((setting) {
      return _stringToThemeMode(setting?.value ?? 'system');
    }).startWith(ThemeMode.system);
  }

  @override
  Future<void> setThemeMode(ThemeMode themeMode, String device) {
    final setting = Setting(
      key: themeModeKey,
      value: _themeModeToString(themeMode),
      device: device
    );
    return setSetting(setting);
  }

  @override
  Stream<Setting?> watchSetting(String key) {
    return _database.settingsDao.watchSetting(key);
  }

  @override
  Future<void> setSetting(Setting setting) {
    return _database.settingsDao.setSetting(setting);
  }

  ThemeMode _stringToThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
