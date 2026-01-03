import 'package:flutter/material.dart';
import 'package:my_budget_client/domain/entities/custom_theme.dart';

/// App Theme utilities for generating ThemeData from a CustomTheme
class AppTheme {
  /// Preset color options (deprecated in favor of full theme presets, but kept for UI utilities)
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

  static ThemeData fromCustomTheme(CustomTheme theme, Brightness brightness) {
    if (brightness == Brightness.light) {
      return lightTheme(theme);
    } else {
      return darkTheme(theme);
    }
  }

  /// Generate light theme from custom theme
  static ThemeData lightTheme(CustomTheme theme) {
    final hasWindowEffect = theme.windowEffectType != WindowEffectType.none;
    final translucentSurface = theme.surfaceColor.withValues(
      alpha: theme.surfaceOpacity,
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: theme.primaryColor,
      brightness: Brightness.light,
      primary: theme.primaryColor,
      secondary: theme.secondaryColor,
      surface: translucentSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,
      scaffoldBackgroundColor: hasWindowEffect ? Colors.transparent : null,
      canvasColor: hasWindowEffect ? Colors.transparent : null,
      cardColor: translucentSurface,
      cardTheme: CardThemeData(
        elevation: 4,
        color: translucentSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: translucentSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: theme.backgroundColor.withValues(
          alpha: theme.surfaceOpacity * 0.5,
        ),
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: NoTransitionsBuilder(),
          TargetPlatform.iOS: NoTransitionsBuilder(),
          TargetPlatform.windows: NoTransitionsBuilder(),
          TargetPlatform.linux: NoTransitionsBuilder(),
          TargetPlatform.macOS: NoTransitionsBuilder(),
        },
      ),
    );
  }

  /// Generate dark theme from custom theme
  static ThemeData darkTheme(CustomTheme theme) {
    final hasWindowEffect = theme.windowEffectType != WindowEffectType.none;
    final translucentSurface = theme.surfaceColor.withValues(
      alpha: theme.surfaceOpacity,
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: theme.primaryColor,
      brightness: Brightness.dark,
      primary: theme.primaryColor,
      secondary: theme.secondaryColor,
      surface: translucentSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: hasWindowEffect ? Colors.transparent : null,
      canvasColor: hasWindowEffect ? Colors.transparent : null,
      cardColor: translucentSurface,
      cardTheme: CardThemeData(
        elevation: 8,
        color: translucentSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: translucentSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: theme.backgroundColor.withValues(
          alpha: theme.surfaceOpacity * 0.5,
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: NoTransitionsBuilder(),
          TargetPlatform.iOS: NoTransitionsBuilder(),
          TargetPlatform.windows: NoTransitionsBuilder(),
          TargetPlatform.linux: NoTransitionsBuilder(),
          TargetPlatform.macOS: NoTransitionsBuilder(),
        },
      ),
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
      return surfaceColor.withValues(alpha: opacity * 0.2);
    }
    if (effect == WindowEffectType.acrylic) {
      return surfaceColor.withValues(alpha: opacity);
    }
    if (effect == WindowEffectType.aero) {
      return surfaceColor.withValues(alpha: opacity * 0.5);
    }
    if (effect == WindowEffectType.vibrancy) {
      return surfaceColor.withValues(alpha: opacity);
    }
    return surfaceColor.withValues(alpha: opacity);
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
    return '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }
}

/// A transitions builder that performs no animation.
class NoTransitionsBuilder extends PageTransitionsBuilder {
  const NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T>? route,
    BuildContext? context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

/// Window effect types for Windows and macOS platform
enum WindowEffectType { none, acrylic, mica, aero, vibrancy, transparent }

extension WindowEffectTypeExtension on WindowEffectType {
  String get displayName {
    switch (this) {
      case WindowEffectType.none:
        return 'None';
      case WindowEffectType.acrylic:
        return 'Acrylic';
      case WindowEffectType.mica:
        return 'Mica';
      case WindowEffectType.aero:
        return 'Aero';
      case WindowEffectType.vibrancy:
        return 'Vibrancy (macOS)';
      case WindowEffectType.transparent:
        return 'Transparent';
    }
  }
}
