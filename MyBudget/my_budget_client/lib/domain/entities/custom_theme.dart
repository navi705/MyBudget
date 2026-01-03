import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:my_budget_client/core/theme/app_theme.dart';

class CustomTheme extends Equatable {
  final String id;
  final String name;
  final Color primaryColor;
  final Color secondaryColor;
  final Color surfaceColor;
  final Color backgroundColor;
  final String? backgroundImagePath;
  final double backgroundImageOpacity;
  final double backgroundImageBlur;
  final WindowEffectType windowEffectType;
  final double effectOpacity;
  final double surfaceOpacity;
  final double surfaceBlur;
  final ThemeMode themeMode;
  final bool isPreset;
  final bool isActive;

  const CustomTheme({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    required this.surfaceColor,
    required this.backgroundColor,
    this.backgroundImagePath,
    this.backgroundImageOpacity = 1.0,
    this.backgroundImageBlur = 0.0,
    required this.windowEffectType,
    this.effectOpacity = 1.0,
    this.surfaceOpacity = 1.0,
    this.surfaceBlur = 0.0,
    required this.themeMode,
    this.isPreset = false,
    this.isActive = false,
  });

  CustomTheme copyWith({
    String? id,
    String? name,
    Color? primaryColor,
    Color? secondaryColor,
    Color? surfaceColor,
    Color? backgroundColor,
    String? backgroundImagePath,
    double? backgroundImageOpacity,
    double? backgroundImageBlur,
    WindowEffectType? windowEffectType,
    double? effectOpacity,
    double? surfaceOpacity,
    double? surfaceBlur,
    ThemeMode? themeMode,
    bool? isPreset,
    bool? isActive,
  }) {
    return CustomTheme(
      id: id ?? this.id,
      name: name ?? this.name,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundImagePath: backgroundImagePath ?? this.backgroundImagePath,
      backgroundImageOpacity:
          backgroundImageOpacity ?? this.backgroundImageOpacity,
      backgroundImageBlur: backgroundImageBlur ?? this.backgroundImageBlur,
      windowEffectType: windowEffectType ?? this.windowEffectType,
      effectOpacity: effectOpacity ?? this.effectOpacity,
      surfaceOpacity: surfaceOpacity ?? this.surfaceOpacity,
      surfaceBlur: surfaceBlur ?? this.surfaceBlur,
      themeMode: themeMode ?? this.themeMode,
      isPreset: isPreset ?? this.isPreset,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    primaryColor,
    secondaryColor,
    surfaceColor,
    backgroundColor,
    backgroundImagePath,
    backgroundImageOpacity,
    backgroundImageBlur,
    windowEffectType,
    effectOpacity,
    surfaceOpacity,
    surfaceBlur,
    themeMode,
    isPreset,
    isActive,
  ];
}
