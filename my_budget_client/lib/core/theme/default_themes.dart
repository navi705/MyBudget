import 'package:flutter/material.dart';
import 'package:my_budget_client/core/theme/app_theme.dart';
import 'package:my_budget_client/domain/entities/custom_theme.dart';

final List<CustomTheme> defaultThemePresets = [
  const CustomTheme(
    id: 'classic-blue',
    name: 'Classic Blue',
    primaryColor: Color(0xFF2196F3),
    secondaryColor: Color(0xFF9C27B0),
    surfaceColor: Color(0xFF252525), // Slightly lighter for better contrast
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
    surfaceColor: Color(0xFF1A1A1A), // Lighter surface
    backgroundColor: Color(0xFF000000),
    windowEffectType: WindowEffectType.acrylic,
    effectOpacity: 0.8, // Increased for better readability
    themeMode: ThemeMode.dark,
    isPreset: true,
  ),
  const CustomTheme(
    id: 'emerald',
    name: 'Emerald Coast',
    primaryColor: Color(0xFF00BFA5), // Brighter teal
    secondaryColor: Color(0xFFD4E157),
    surfaceColor: Color(0xFF1B262C),
    backgroundColor: Color(0xFF0A2E46), // Darker background for better contrast
    windowEffectType: WindowEffectType.mica,
    themeMode: ThemeMode.dark,
    isPreset: true,
  ),
  const CustomTheme(
    id: 'forest-zen',
    name: 'Forest Zen',
    primaryColor: Color(0xFF4CAF50),
    secondaryColor: Color(0xFF81C784),
    surfaceColor: Color(0xFF1B211B),
    backgroundColor: Color(0xFF0D110D),
    windowEffectType: WindowEffectType.acrylic,
    effectOpacity: 0.85,
    themeMode: ThemeMode.dark,
    isPreset: true,
  ),
  const CustomTheme(
    id: 'pastel-vibes',
    name: 'Pastel Vibes',
    primaryColor: Color(0xFFF48FB1),
    secondaryColor: Color(0xFF4DD0E1),
    surfaceColor: Color(0xFFFFF0F5),
    backgroundColor: Color(0xFFFAFAFA),
    backgroundImagePath: 'assets/backgrounds/pattern_geometric_pastel.png',
    backgroundImageOpacity: 0.3, // Reduced for better text readability
    windowEffectType: WindowEffectType.mica,
    themeMode: ThemeMode.light,
    isPreset: true,
  ),
  const CustomTheme(
    id: 'deep-ocean',
    name: 'Deep Ocean',
    primaryColor: Color(0xFF0077B6),
    secondaryColor: Color(0xFF00B4D8),
    surfaceColor: Color(0xFF023E8A),
    backgroundColor: Color(0xFF03045E),
    windowEffectType: WindowEffectType.acrylic,
    effectOpacity: 0.8,
    themeMode: ThemeMode.dark,
    isPreset: true,
  ),
  const CustomTheme(
    id: 'nordic-frost',
    name: 'Nordic Frost',
    primaryColor: Color(0xFF5E81AC),
    secondaryColor: Color(0xFF88C0D0),
    surfaceColor: Color(0xFFECEFF4),
    backgroundColor: Color(0xFFF0F4F8),
    windowEffectType: WindowEffectType.mica,
    themeMode: ThemeMode.light,
    isPreset: true,
  ),
  const CustomTheme(
    id: 'nebula-dreams',
    name: 'Nebula',
    primaryColor: Color(0xFF7E57C2),
    secondaryColor: Color(0xFF26A69A),
    surfaceColor: Color(0xFF120024),
    backgroundColor: Color(0xFF0A0014),
    backgroundImagePath: 'assets/backgrounds/pattern_nebula.png',
    backgroundImageOpacity: 0.4,
    windowEffectType: WindowEffectType.acrylic,
    effectOpacity: 0.7,
    themeMode: ThemeMode.dark,
    isPreset: true,
  ),
];
