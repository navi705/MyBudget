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
