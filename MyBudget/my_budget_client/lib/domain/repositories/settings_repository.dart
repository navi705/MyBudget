import 'package:flutter/material.dart';
import 'package:my_budget_client/domain/entities/settings.dart';

abstract class SettingsRepository {
  Stream<ThemeMode> get themeMode;
  Future<void> setThemeMode(ThemeMode themeMode, String device);

  Stream<List<Settings>> watchAllSettings();
  Stream<Settings?> watchSetting(String key);
  Future<Settings?> getSetting(String key);
  Future<void> setSetting(Settings setting);
}
