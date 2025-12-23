import 'package:flutter/material.dart';
import 'package:my_budget_client/core/database/app_database.dart';

abstract class SettingsRepository {
  Stream<ThemeMode> get themeMode;
  Future<void> setThemeMode(ThemeMode themeMode, String device);

  Stream<List<Setting>> watchAllSettings();
  Stream<Setting?> watchSetting(String key);
  Future<void> setSetting(Setting setting);
}
