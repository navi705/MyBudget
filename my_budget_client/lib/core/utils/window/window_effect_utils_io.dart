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
    // flutter_acrylic ships a native backend for all three desktop platforms
    // (see the windows/, macos/ and linux/ folders of the plugin), so Linux
    // belongs here too - it just supports fewer effects, which _resolveEffect
    // takes care of.
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) return;

    await Window.setEffect(effect: _resolveEffect(type), color: color);
  }

  /// Maps a stored effect choice onto an effect the running platform's backend
  /// can actually render.
  ///
  /// This clamping is not cosmetic: flutter_acrylic forwards the raw enum index
  /// to the native side without validating it, so an unsupported value is not a
  /// graceful no-op. The Windows plugin casts it straight to an ACCENT_STATE
  /// and the Linux plugin answers anything above index 2 with a
  /// NOT_SUPPORTED_ON_LINUX platform exception.
  static WindowEffect _resolveEffect(WindowEffectType type) {
    if (Platform.isLinux) {
      // The GTK backend only paints a flat colour over the window, so the only
      // meaningful distinction it can honour is opaque versus see-through.
      return type == WindowEffectType.none
          ? WindowEffect.disabled
          : WindowEffect.transparent;
    }

    switch (type) {
      case WindowEffectType.none:
        return WindowEffect.disabled;
      case WindowEffectType.acrylic:
        return WindowEffect.acrylic;
      case WindowEffectType.mica:
        return WindowEffect.mica;
      case WindowEffectType.aero:
        return WindowEffect.aero;
      case WindowEffectType.vibrancy:
        // Vibrancy is the macOS blur, and `sidebar` is the WindowEffect that
        // flutter_acrylic converts to NSVisualEffectViewMaterial.sidebar. It
        // has no Windows counterpart - its index would land on an undefined
        // ACCENT_STATE there - so Windows falls back to its closest blur.
        return Platform.isMacOS ? WindowEffect.sidebar : WindowEffect.acrylic;
      case WindowEffectType.transparent:
        return WindowEffect.transparent;
    }
  }
}
