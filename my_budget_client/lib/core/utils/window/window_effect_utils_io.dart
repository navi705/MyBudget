import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:my_budget_client/core/theme/app_theme.dart';
import 'package:my_budget_client/core/utils/window/window_effect_resolver.dart';
import 'dart:io';

class WindowEffectUtils {
  static Future<void> applyEffect({
    required BuildContext context,
    required Color color,
    required double opacity,
    required WindowEffectType type,
  }) async {
    // flutter_acrylic ships a native backend for all three desktop platforms
    // (see the windows/, macos/ and linux/ folders of the plugin), so Linux
    // belongs here too - it just supports fewer effects, which _resolveEffect
    // takes care of.
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) return;

    await Window.setEffect(effect: resolveWindowEffect(type), color: color);
  }
}
