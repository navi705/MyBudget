import 'package:my_budget_client/core/utils/platform/platform_utils.dart';
import 'package:flutter/material.dart';

/// Utility for showing dialogs with platform-specific behavior
class DialogUtils {
  /// Shows a dialog that optionally avoids shrinking when the keyboard appears on Android.
  static Future<T?> showAppDialog<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
    bool useSafeArea = true,
    bool useRootNavigator = true,
    RouteSettings? routeSettings,
    Offset? anchorPoint,
    bool resizeToAvoidBottomInset = true,
  }) {
    // On Android, if we want to avoid shrinking, we wrap the dialog in a Scaffold
    // with resizeToAvoidBottomInset: false.
    if (AppPlatform.isAndroid && !resizeToAvoidBottomInset) {
      return showDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        barrierColor: barrierColor,
        barrierLabel: barrierLabel,
        useSafeArea: useSafeArea,
        useRootNavigator: useRootNavigator,
        routeSettings: routeSettings,
        anchorPoint: anchorPoint,
        builder: (context) => Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: false,
          body: GestureDetector(
            onTap: barrierDismissible
                ? () => Navigator.of(context).pop()
                : null,
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: GestureDetector(
                  onTap: () {}, // Prevent pop when tapping dialog itself
                  child: RepaintBoundary(child: child),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Default Flutter behavior for other platforms or when resize is allowed
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
      useSafeArea: useSafeArea,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
      anchorPoint: anchorPoint,
      builder: (context) => child,
    );
  }
}
