import 'package:flutter/material.dart';
import 'package:my_budget_client/core/theme/app_theme.dart';

class WindowEffectUtils {
  /// No-op on web: the page has no host window to decorate.
  static Future<void> applyTheme({
    required WindowEffectType type,
    required Color backgroundColor,
    required Color surfaceColor,
    required double effectOpacity,
    required Brightness brightness,
  }) async {}
}
