import 'package:flutter/material.dart';
import 'package:my_budget_client/core/theme/app_theme.dart';
import 'package:my_budget_client/domain/entities/custom_theme.dart';

final List<CustomTheme> defaultThemePresets = [
  const CustomTheme(
    id: 'classic-blue',
    name: 'Classic Blue',
    primaryColor: Color(0xFF2196F3),
    secondaryColor: Color(0xFF9C27B0),
    surfaceColor: Color(0xFF1E1E1E),
    backgroundColor: Color(0xFF121212),
    windowEffectType: WindowEffectType.none,
    themeMode: ThemeMode.dark,
    isPreset: true,
  ),
  const CustomTheme(
    id: 'midnight',
    name: 'Midnight',
    primaryColor: Color(0xFF3F51B5),
    secondaryColor: Color(0xFFFF4081),
    surfaceColor: Color(0xFF121212),
    backgroundColor: Color(0xFF000000),
    windowEffectType: WindowEffectType.acrylic,
    effectOpacity: 0.6,
    themeMode: ThemeMode.dark,
    isPreset: true,
  ),
  const CustomTheme(
    id: 'emerald',
    name: 'Emerald Coast',
    primaryColor: Color(0xFF009688),
    secondaryColor: Color(0xFFCDDC39),
    surfaceColor: Color(0xFF1B262C),
    backgroundColor: Color(0xFF0F4C75),
    windowEffectType: WindowEffectType.mica,
    themeMode: ThemeMode.dark,
    isPreset: true,
  ),
  const CustomTheme(
    id: 'aero-glass',
    name: 'Aero Glass',
    primaryColor: Color(0xFF607D8B),
    secondaryColor: Color(0xFF03A9F4),
    surfaceColor: Color(0x33FFFFFF),
    backgroundColor: Color(0x11000000),
    windowEffectType: WindowEffectType.aero,
    effectOpacity: 0.1,
    surfaceOpacity: 0.2,
    surfaceBlur: 20.0,
    themeMode: ThemeMode.system,
    isPreset: true,
  ),
];
