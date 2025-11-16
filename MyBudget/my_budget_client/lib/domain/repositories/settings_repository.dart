import 'package:flutter/material.dart';

abstract class SettingsRepository {
  Stream<ThemeMode> get themeMode;
  Future<void> setThemeMode(ThemeMode themeMode);
}
