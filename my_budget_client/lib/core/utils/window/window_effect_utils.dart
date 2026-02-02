import 'package:flutter/material.dart';
import 'package:my_budget_client/core/theme/app_theme.dart';

export 'window_effect_utils_io.dart'
    if (dart.library.html) 'window_effect_utils_web.dart';

abstract class WindowEffectUtils {
  static Future<void> applyEffect({
    required BuildContext context,
    required Color color,
    required double opacity,
    required WindowEffectType type,
  }) async {
    // Platform-specific implementation via conditional exports
  }
}
