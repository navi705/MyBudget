import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:my_budget_client/core/theme/app_theme.dart';
import 'package:my_budget_client/core/utils/window/window_effect_resolver.dart';

class WindowEffectUtils {
  /// Applies [type] to the host window, tinted for the given theme.
  ///
  /// Every caller goes through here so launch, the effect picker and the preset
  /// row cannot disagree about what a theme looks like; what to send is decided
  /// by [planWindowEffect], which is testable.
  static Future<void> applyTheme({
    required WindowEffectType type,
    required Color backgroundColor,
    required Color surfaceColor,
    required double effectOpacity,
    required Brightness brightness,
  }) async {
    // flutter_acrylic ships a native backend for all three desktop platforms
    // (see the windows/, macos/ and linux/ folders of the plugin), so Linux
    // belongs here too - it just supports fewer effects, which
    // resolveWindowEffect takes care of.
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) return;

    final plan = planWindowEffect(
      type: type,
      backgroundColor: backgroundColor,
      surfaceColor: surfaceColor,
      effectOpacity: effectOpacity,
      brightness: brightness,
    );

    await Window.setEffect(
      effect: plan.effect,
      color: plan.color,
      dark: plan.dark,
    );

    final alphaValue = plan.alphaValue;
    if (alphaValue != null) {
      await Window.setWindowAlphaValue(alphaValue);
    }
  }
}
