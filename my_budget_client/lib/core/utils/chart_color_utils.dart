import 'package:flutter/material.dart';

class ChartColorUtils {
  /// Adjusts a color to harmonize with the background brightness.
  ///
  /// - If [isDarkTheme] is true (dark background):
  ///   Softens colors by damping lightness and saturation to avoid excessive
  ///   vibrancy/neon effects that can be jarring on dark surfaces.
  /// - If [isDarkTheme] is false (light background):
  ///   Ensures colors are vibrant but not washed out by clamping lightness.
  static Color getAdaptiveColor(Color color, bool isDarkTheme) {
    try {
      final hsl = HSLColor.fromColor(color);

      if (isDarkTheme) {
        // For dark mode:
        // We want colors to be visible but "sober" (сдержаны).
        // Neon colors on true black look too harsh.
        // We dampen saturation slightly and clamp lightness to a comfortable middle-high range.
        return hsl
            .withSaturation((hsl.saturation * 0.7).clamp(0.4, 0.8))
            .withLightness(hsl.lightness.clamp(0.3, 0.6))
            .toColor();
      } else {
        // For light mode:
        // We want colors to be vibrant and clear.
        // Clamping lightness ensures they don't get too dark or too light (white-on-white).
        return hsl
            .withSaturation((hsl.saturation * 1.0).clamp(0.6, 1.0))
            .withLightness(hsl.lightness.clamp(0.4, 0.7))
            .toColor();
      }
    } catch (_) {
      return color;
    }
  }

  /// Returns a text color (black or white) that provides the best contrast
  /// against the given [backgroundColor].
  static Color getContrastColor(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;
  }

  static const List<Color> _fixedPalette = [
    Color(0xFF2196F3), // Blue
    Color(0xFFF44336), // Red
    Color(0xFF4CAF50), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFF9C27B0), // Purple
    Color(0xFF009688), // Teal
    Color(0xFFE91E63), // Pink
    Color(0xFFFFC107), // Amber
    Color(0xFF3F51B5), // Indigo
    Color(0xFFFF5722), // Deep Orange
    Color(0xFF00BCD4), // Cyan
    Color(0xFF8BC34A), // Light Green
    Color(0xFF673AB7), // Deep Purple
    Color(0xFF03A9F4), // Light Blue
    Color(0xFFCDDC39), // Lime
    Color(0xFFFFEB3B), // Yellow
    Color(0xFF795548), // Brown
    Color(0xFF607D8B), // Blue Grey
    Color(0xFF9E9E9E), // Grey
    Color(0xFF333333), // Dark Grey
  ];

  /// Returns a color from a fixed 20-color palette based on the [index].
  static Color getPaletteColor(int index) {
    return _fixedPalette[index % _fixedPalette.length];
  }
}
