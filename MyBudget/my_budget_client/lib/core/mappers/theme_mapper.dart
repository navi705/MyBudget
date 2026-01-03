import 'package:flutter/material.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/theme/app_theme.dart';
import 'package:my_budget_client/domain/entities/custom_theme.dart';
import 'package:drift/drift.dart';

extension DbCustomThemeExtensions on DbCustomTheme {
  CustomTheme toDomain() {
    return CustomTheme(
      id: id,
      name: name,
      primaryColor: AppTheme.parseHex(primaryColorHex),
      secondaryColor: AppTheme.parseHex(secondaryColorHex),
      surfaceColor: AppTheme.parseHex(surfaceColorHex),
      backgroundColor: AppTheme.parseHex(backgroundColorHex),
      backgroundImagePath: backgroundImagePath,
      backgroundImageOpacity: backgroundImageOpacity,
      backgroundImageBlur: backgroundImageBlur,
      windowEffectType: WindowEffectType.values[windowEffectType],
      effectOpacity: effectOpacity,
      surfaceOpacity: surfaceOpacity,
      themeMode: ThemeMode.values[themeMode],
      isPreset: isPreset,
      isActive: isActive,
    );
  }
}

extension CustomThemeExtensions on CustomTheme {
  CustomThemesCompanion toCompanion() {
    return CustomThemesCompanion(
      id: Value(id),
      name: Value(name),
      primaryColorHex: Value(AppTheme.toHex(primaryColor)),
      secondaryColorHex: Value(AppTheme.toHex(secondaryColor)),
      surfaceColorHex: Value(AppTheme.toHex(surfaceColor)),
      backgroundColorHex: Value(AppTheme.toHex(backgroundColor)),
      backgroundImagePath: Value(backgroundImagePath),
      backgroundImageOpacity: Value(backgroundImageOpacity),
      backgroundImageBlur: Value(backgroundImageBlur),
      windowEffectType: Value(windowEffectType.index),
      effectOpacity: Value(effectOpacity),
      surfaceOpacity: Value(surfaceOpacity),
      themeMode: Value(themeMode.index),
      isPreset: Value(isPreset),
      isActive: Value(isActive),
    );
  }
}
