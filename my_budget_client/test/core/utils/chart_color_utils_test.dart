import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/utils/chart_color_utils.dart';

void main() {
  group('ChartColorUtils Tests', () {
    test('getPaletteColor returns colors from fixed palette', () {
      final color0 = ChartColorUtils.getPaletteColor(0);
      final color1 = ChartColorUtils.getPaletteColor(1);
      final color20 = ChartColorUtils.getPaletteColor(20);

      expect(color0, isA<Color>());
      expect(color1, isNot(equals(color0)));
      // Modulo check
      expect(color20, equals(color0));
    });

    test('getPaletteColor provides distinct colors for subsequent indices', () {
      final colors = List.generate(
        20,
        (i) => ChartColorUtils.getPaletteColor(i),
      );
      final uniqueColors = colors.toSet();

      expect(uniqueColors.length, equals(20));
    });

    test('getAdaptiveColor adjust colors based on theme', () {
      const baseColor = Colors.red;
      final darkColor = ChartColorUtils.getAdaptiveColor(baseColor, true);
      final lightColor = ChartColorUtils.getAdaptiveColor(baseColor, false);

      expect(darkColor, isNot(equals(baseColor)));
      expect(lightColor, isNot(equals(baseColor)));
      expect(darkColor, isNot(equals(lightColor)));
    });
  });
}
