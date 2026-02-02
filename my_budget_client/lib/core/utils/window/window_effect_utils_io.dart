import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:my_budget_client/core/theme/app_theme.dart';
import 'dart:io';

class WindowEffectUtils {
  static Future<void> applyEffect({
    required BuildContext context,
    required Color color,
    required double opacity,
    required WindowEffectType type,
  }) async {
    if (Platform.isWindows || Platform.isMacOS) {
      WindowEffect windowEffect;
      switch (type) {
        case WindowEffectType.none:
          windowEffect = WindowEffect.disabled;
          break;
        case WindowEffectType.acrylic:
          windowEffect = WindowEffect.acrylic;
          break;
        case WindowEffectType.mica:
          windowEffect = WindowEffect.mica;
          break;
        case WindowEffectType.aero:
          windowEffect = WindowEffect.aero;
          break;
        case WindowEffectType.vibrancy:
          windowEffect = WindowEffect.disabled;
          break;
        case WindowEffectType.transparent:
          windowEffect = WindowEffect.transparent;
          break;
      }

      await Window.setEffect(effect: windowEffect, color: color);
    }
  }
}
