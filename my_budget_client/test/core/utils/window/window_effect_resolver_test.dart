// A theme travels between devices, so the effect the resolver is handed is not
// bounded by what the local picker offers. These tests pin what each desktop
// backend is given for a value it cannot render — the case where the picker is
// no help because the choice was made on another OS.
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/theme/app_theme.dart';
import 'package:my_budget_client/core/utils/platform/platform_utils.dart';
import 'package:my_budget_client/core/utils/window/window_effect_resolver.dart';

void main() {
  tearDown(() => debugAppPlatformOverride = null);

  group('resolveWindowEffect on Linux', () {
    setUp(() => debugAppPlatformOverride = AppPlatformKind.linux);

    test('keeps a see-through window only when transparency was asked for', () {
      expect(
        resolveWindowEffect(WindowEffectType.transparent),
        WindowEffect.transparent,
      );
    });

    test('turns every blur the GTK backend lacks into an opaque window', () {
      for (final type in [
        WindowEffectType.acrylic,
        WindowEffectType.mica,
        WindowEffectType.aero,
        WindowEffectType.vibrancy,
      ]) {
        expect(
          resolveWindowEffect(type),
          WindowEffect.disabled,
          reason:
              '$type has no Linux backend; a see-through fallback would leave '
              'the window unusable while the picker shows no such choice',
        );
      }
    });

    test('offers the picker only the two effects it can render', () {
      expect(
        WindowEffectType.values.where(effectAvailableOnPlatform),
        [WindowEffectType.none, WindowEffectType.transparent],
      );
    });
  });

  group('resolveWindowEffect on macOS', () {
    setUp(() => debugAppPlatformOverride = AppPlatformKind.macOS);

    test('maps vibrancy onto the sidebar material', () {
      expect(
        resolveWindowEffect(WindowEffectType.vibrancy),
        WindowEffect.sidebar,
      );
    });

    test('offers every effect', () {
      expect(
        WindowEffectType.values.where(effectAvailableOnPlatform),
        WindowEffectType.values,
      );
    });
  });

  group('resolveWindowEffect on Windows', () {
    setUp(() => debugAppPlatformOverride = AppPlatformKind.windows);

    test('falls back to acrylic for the macOS-only vibrancy', () {
      // Its enum index would reach the native side as an undefined
      // ACCENT_STATE, so the nearest blur is the safe answer.
      expect(
        resolveWindowEffect(WindowEffectType.vibrancy),
        WindowEffect.acrylic,
      );
    });

    test('passes its own effects through untouched', () {
      expect(resolveWindowEffect(WindowEffectType.none), WindowEffect.disabled);
      expect(
        resolveWindowEffect(WindowEffectType.acrylic),
        WindowEffect.acrylic,
      );
      expect(resolveWindowEffect(WindowEffectType.mica), WindowEffect.mica);
      expect(
        resolveWindowEffect(WindowEffectType.transparent),
        WindowEffect.transparent,
      );
    });

    test('hides the effects the picker would be lying about', () {
      final offered = WindowEffectType.values.where(effectAvailableOnPlatform);
      expect(offered, isNot(contains(WindowEffectType.vibrancy)));
      expect(offered, isNot(contains(WindowEffectType.aero)));
    });
  });
}
