import 'package:flutter/material.dart';

/// App Theme utilities for generating ThemeData from a primary color
class AppTheme {
  /// Preset color options for quick selection
  static const List<Color> presetColors = [
    Color(0xFF2196F3), // Blue
    Color(0xFF9C27B0), // Purple
    Color(0xFF4CAF50), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFFE91E63), // Pink
    Color(0xFF00BCD4), // Cyan
    Color(0xFFFF5722), // Deep Orange
    Color(0xFF607D8B), // Blue Grey
    Color(0xFF673AB7), // Deep Purple
    Color(0xFF009688), // Teal
  ];

  /// Generate light theme from primary color
  static ThemeData lightTheme(
    Color primaryColor, {
    bool hasWindowEffect = false,
    double windowOpacity = 0.8,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    );
    final surfaceOpacity = hasWindowEffect
        ? windowOpacity.clamp(0.0, 0.9)
        : 1.0;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,
      scaffoldBackgroundColor: hasWindowEffect ? Colors.transparent : null,
      canvasColor: hasWindowEffect ? Colors.transparent : null,
      cardColor: hasWindowEffect
          ? Colors.white.withOpacity(surfaceOpacity * 0.5)
          : null,
      dialogBackgroundColor: hasWindowEffect
          ? Colors.white.withOpacity(surfaceOpacity * 0.8)
          : null,
      navigationRailTheme: hasWindowEffect
          ? const NavigationRailThemeData(backgroundColor: Colors.transparent)
          : null,
      popupMenuTheme: hasWindowEffect
          ? PopupMenuThemeData(color: Colors.white.withOpacity(surfaceOpacity))
          : null,
    );
  }

  /// Generate dark theme from primary color
  static ThemeData darkTheme(
    Color primaryColor, {
    bool hasWindowEffect = false,
    double windowOpacity = 0.8,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    );
    final surfaceOpacity = hasWindowEffect
        ? windowOpacity.clamp(0.0, 0.9)
        : 1.0;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: hasWindowEffect ? Colors.transparent : null,
      canvasColor: hasWindowEffect ? Colors.transparent : null,
      cardColor: hasWindowEffect
          ? Colors.black.withOpacity(surfaceOpacity * 0.5)
          : null,
      dialogBackgroundColor: hasWindowEffect
          ? Colors.black.withOpacity(surfaceOpacity * 0.8)
          : null,
      navigationRailTheme: hasWindowEffect
          ? const NavigationRailThemeData(backgroundColor: Colors.transparent)
          : null,
      popupMenuTheme: hasWindowEffect
          ? PopupMenuThemeData(color: Colors.black.withOpacity(surfaceOpacity))
          : null,
    );
  }

  /// Get the tint color for the window effect based on theme and opacity
  static Color getWindowTintColor(
    Color themeColor,
    Brightness brightness,
    double opacity,
    WindowEffectType effect,
  ) {
    final baseColor = brightness == Brightness.light
        ? Colors.white
        : Colors.black;

    if (effect == WindowEffectType.mica) {
      // Mica is very subtle, we use a much lower alpha for the overlay
      return baseColor.withOpacity(opacity * 0.2);
    }

    if (effect == WindowEffectType.acrylic) {
      // For acrylic, standard tint works well, but we can mix a bit of theme color
      return Color.lerp(baseColor, themeColor, 0.05)!.withOpacity(opacity);
    }

    // Transparent effect uses full opacity range
    return baseColor.withOpacity(opacity);
  }

  /// Parse hex color string to Color
  static Color parseHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse('0x$hexColor'));
  }

  /// Convert Color to hex string
  static String toHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }
}

/// Window effect types for Windows platform
enum WindowEffectType { none, acrylic, mica, transparent }

extension WindowEffectTypeExtension on WindowEffectType {
  String get displayName {
    switch (this) {
      case WindowEffectType.none:
        return 'None';
      case WindowEffectType.acrylic:
        return 'Acrylic';
      case WindowEffectType.mica:
        return 'Mica';
      case WindowEffectType.transparent:
        return 'Transparent';
    }
  }
}
