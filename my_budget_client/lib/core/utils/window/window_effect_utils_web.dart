import 'package:flutter/material.dart';
import 'package:my_budget_client/core/theme/app_theme.dart';

class WindowEffectUtils {
  static Future<void> applyEffect({
    required BuildContext context,
    required Color color,
    required double opacity,
    required WindowEffectType type,
  }) async {
    // No-op for web
  }
}
