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
    Color secondaryColor = const Color(0xFF9C27B0),
    Color surfaceColor = Colors.white,
    bool hasWindowEffect = false,
    double windowOpacity = 0.8,
  }) {
    // surfaceOpacity scales with the slider but has a minimum for readability
    final surfaceOpacity = hasWindowEffect
        ? windowOpacity.clamp(0.2, 0.9)
        : 1.0;
    final translucentSurface = surfaceColor.withOpacity(surfaceOpacity * 0.6);

    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
          primary: primaryColor,
          secondary: secondaryColor,
          surface: hasWindowEffect ? translucentSurface : surfaceColor,
        ).copyWith(
          surfaceContainerHighest: hasWindowEffect
              ? Colors.white.withOpacity(surfaceOpacity * 0.4)
              : null,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,
      scaffoldBackgroundColor: hasWindowEffect ? Colors.transparent : null,
      canvasColor: hasWindowEffect ? Colors.transparent : null,
      cardColor: hasWindowEffect ? translucentSurface : null,
      cardTheme: hasWindowEffect
          ? CardThemeData(
              elevation: 4,
              color: translucentSurface,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              shadowColor: Colors.black.withOpacity(0.2),
            )
          : null,
      dialogTheme: hasWindowEffect
          ? DialogThemeData(
              backgroundColor: translucentSurface,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            )
          : null,
      expansionTileTheme: hasWindowEffect
          ? ExpansionTileThemeData(
              backgroundColor: Colors.transparent,
              collapsedBackgroundColor: Colors.transparent,
            )
          : null,
      drawerTheme: hasWindowEffect
          ? DrawerThemeData(backgroundColor: translucentSurface)
          : null,
      appBarTheme: hasWindowEffect
          ? AppBarTheme(
              backgroundColor: Colors.white.withOpacity(surfaceOpacity * 0.5),
              elevation: 0,
              iconTheme: IconThemeData(color: colorScheme.onSurface),
              titleTextStyle: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
      navigationRailTheme: hasWindowEffect
          ? const NavigationRailThemeData(backgroundColor: Colors.transparent)
          : null,
      highlightColor: hasWindowEffect
          ? colorScheme.primary.withOpacity(0.2)
          : null,
      hoverColor: hasWindowEffect ? colorScheme.primary.withOpacity(0.1) : null,
      popupMenuTheme: hasWindowEffect
          ? PopupMenuThemeData(color: Colors.white.withOpacity(surfaceOpacity))
          : null,
    );
  }

  /// Generate dark theme from primary color
  static ThemeData darkTheme(
    Color primaryColor, {
    Color secondaryColor = const Color(0xFF9C27B0),
    Color surfaceColor = const Color(0xFF121212),
    bool hasWindowEffect = false,
    double windowOpacity = 0.8,
  }) {
    // surfaceOpacity scales with the slider but has a minimum for readability
    final surfaceOpacity = hasWindowEffect
        ? windowOpacity.clamp(0.2, 0.9)
        : 1.0;
    final translucentSurface = surfaceColor.withOpacity(surfaceOpacity * 0.4);

    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.dark,
          primary: primaryColor,
          secondary: secondaryColor,
          surface: hasWindowEffect ? translucentSurface : surfaceColor,
        ).copyWith(
          surfaceContainerHighest: hasWindowEffect
              ? Colors.black.withOpacity(surfaceOpacity * 0.3)
              : null,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: hasWindowEffect ? Colors.transparent : null,
      canvasColor: hasWindowEffect ? Colors.transparent : null,
      cardColor: hasWindowEffect ? translucentSurface : null,
      cardTheme: hasWindowEffect
          ? CardThemeData(
              elevation: 8,
              color: translucentSurface,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              shadowColor: Colors.black.withOpacity(0.5),
            )
          : null,
      dialogTheme: hasWindowEffect
          ? DialogThemeData(
              backgroundColor: translucentSurface,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            )
          : null,
      expansionTileTheme: hasWindowEffect
          ? ExpansionTileThemeData(
              backgroundColor: Colors.transparent,
              collapsedBackgroundColor: Colors.transparent,
            )
          : null,
      drawerTheme: hasWindowEffect
          ? DrawerThemeData(backgroundColor: translucentSurface)
          : null,
      appBarTheme: hasWindowEffect
          ? AppBarTheme(
              backgroundColor: Colors.black.withOpacity(surfaceOpacity * 0.5),
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              titleTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
      navigationRailTheme: hasWindowEffect
          ? const NavigationRailThemeData(backgroundColor: Colors.transparent)
          : null,
      highlightColor: hasWindowEffect
          ? colorScheme.primary.withOpacity(0.3)
          : null,
      hoverColor: hasWindowEffect
          ? colorScheme.primary.withOpacity(0.15)
          : null,
      popupMenuTheme: hasWindowEffect
          ? PopupMenuThemeData(color: Colors.black.withOpacity(surfaceOpacity))
          : null,
    );
  }

  /// Get the tint color for the window effect based on theme and opacity
  static Color getWindowTintColor(
    Color surfaceColor,
    Brightness brightness,
    double opacity,
    WindowEffectType effect,
  ) {
    if (effect == WindowEffectType.mica) {
      // Mica is very subtle
      return surfaceColor.withOpacity(opacity * 0.2);
    }

    if (effect == WindowEffectType.acrylic) {
      // For acrylic, we use the user's surface color as the tint
      return surfaceColor.withOpacity(opacity);
    }

    if (effect == WindowEffectType.transparent) {
      return surfaceColor.withOpacity(opacity);
    }

    return surfaceColor.withOpacity(opacity);
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
