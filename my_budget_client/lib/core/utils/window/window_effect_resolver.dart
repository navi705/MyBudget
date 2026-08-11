import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:my_budget_client/core/theme/app_theme.dart';
import 'package:my_budget_client/core/utils/platform/platform_utils.dart';

/// Whether [type] is worth offering to the user on the running platform.
///
/// The picker must never list an effect the backend would silently swap for
/// something else, otherwise the selection reads as broken.
bool effectAvailableOnPlatform(WindowEffectType type) {
  if (AppPlatform.isLinux) {
    // The GTK backend implements only "off" and "see-through"; every other
    // effect is rejected outright by the native plugin.
    return type == WindowEffectType.none ||
        type == WindowEffectType.transparent;
  }
  if (AppPlatform.isMacOS) return true;
  return type != WindowEffectType.vibrancy && type != WindowEffectType.aero;
}

/// Maps a stored effect choice onto an effect the running platform's backend
/// can actually render.
///
/// This clamping is not cosmetic: flutter_acrylic forwards the raw enum index
/// to the native side without validating it, so an unsupported value is not a
/// graceful no-op. The Windows plugin casts it straight to an ACCENT_STATE and
/// the Linux plugin answers anything above index 2 with a NOT_SUPPORTED_ON_LINUX
/// platform exception.
///
/// A theme is synced, so a value the local picker never offered still arrives
/// here: a Windows device sets mica, and the Linux device it syncs with has to
/// render that theme with a backend that has no such effect.
WindowEffect resolveWindowEffect(WindowEffectType type) {
  if (AppPlatform.isLinux) {
    // Only an explicit "transparent" makes the window see-through. Treating
    // every unsupported blur as transparent instead turned a synced acrylic
    // theme into a window the user could see straight through, while the
    // picker - which does not offer acrylic here at all - showed no such
    // choice. An opaque window is a degraded blur; a see-through one is not a
    // window.
    return type == WindowEffectType.transparent
        ? WindowEffect.transparent
        : WindowEffect.disabled;
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
      // flutter_acrylic converts to NSVisualEffectViewMaterial.sidebar. It has
      // no Windows counterpart - its index would land on an undefined
      // ACCENT_STATE there - so Windows falls back to its closest blur.
      return AppPlatform.isMacOS ? WindowEffect.sidebar : WindowEffect.acrylic;
    case WindowEffectType.transparent:
      return WindowEffect.transparent;
  }
}

/// Everything the native backend has to be told to render one theme.
///
/// [alphaValue] is the argument for `Window.setWindowAlphaValue`, or null when
/// that call must not be made at all — it is not a no-op, so passing 1.0
/// instead of skipping it would forcibly undo a transparency the theme never
/// asked to change.
typedef WindowEffectPlan = ({
  WindowEffect effect,
  Color color,
  bool dark,
  double? alphaValue,
});

/// The floor a blur's tint is held at.
///
/// Below this the tint stops reading as the theme colour and the window turns
/// into an unlabelled sheet of blur. Transparency is exempt: there, low really
/// does mean see-through, which is the point of the effect.
const double _minTintOpacity = 0.15;

/// Turns a theme into the exact calls the backend needs.
///
/// This is separate from making those calls so the decision can be tested:
/// `Window.setEffect` is a static plugin call into native code and cannot be
/// observed from a Dart test. The three places that used to apply effects
/// (launch, the theme screen, the preset row) each decided this for themselves
/// and had already drifted — the launch path inverted the tint opacity and
/// dropped the transparency handling entirely, so a transparent theme came
/// back opaque and mis-tinted after every restart.
WindowEffectPlan planWindowEffect({
  required WindowEffectType type,
  required Color backgroundColor,
  required Color surfaceColor,
  required double effectOpacity,
  required Brightness brightness,
}) {
  final resolved = resolveWindowEffect(type);
  final dark = brightness == Brightness.dark;

  // A fully transparent background colour means "remove the background
  // colour", not "tint with nothing" — the surface colour keeps the window
  // tinted with something of the theme instead of pure black.
  final tintColor = backgroundColor.a == 0 ? surfaceColor : backgroundColor;

  // Keyed off the resolved effect, not the requested one: on Linux a synced
  // acrylic resolves to `disabled`, and `disabled` must not be handed the
  // transparency treatment.
  if (resolved == WindowEffect.transparent) {
    if (AppPlatform.isLinux) {
      // Linux has no window-alpha call; its backend derives translucency
      // straight from the tint colour's alpha channel, so the requested
      // opacity has to travel in the colour instead.
      return (
        effect: WindowEffect.transparent,
        color: tintColor.withValues(alpha: effectOpacity),
        dark: dark,
        alphaValue: null,
      );
    }
    return (
      effect: WindowEffect.transparent,
      color: Colors.transparent,
      dark: dark,
      alphaValue: effectOpacity,
    );
  }

  final effectiveOpacity = effectOpacity < _minTintOpacity
      ? _minTintOpacity
      : effectOpacity;

  return (
    effect: resolved,
    color: AppTheme.getWindowTintColor(
      tintColor,
      brightness,
      effectiveOpacity,
      type,
    ),
    dark: dark,
    alphaValue: null,
  );
}
