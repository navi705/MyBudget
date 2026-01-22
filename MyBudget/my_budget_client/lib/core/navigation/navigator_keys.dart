import 'package:flutter/material.dart';

class AppNavigator {
  static final rootNavigatorKey = GlobalKey<NavigatorState>();
  static final shellNavigatorKey = GlobalKey<NavigatorState>();

  /// Dismisses all overlays (menus, dialogs, etc.) from both navigators.
  static void dismissAllOverlays() {
    // Pop shell navigator routes until only the first one remains
    if (shellNavigatorKey.currentState?.canPop() ?? false) {
      shellNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    }

    // Pop root navigator routes until only the first one remains
    if (rootNavigatorKey.currentState?.canPop() ?? false) {
      rootNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    }
  }
}
