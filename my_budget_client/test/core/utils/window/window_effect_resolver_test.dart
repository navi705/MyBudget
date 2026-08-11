// A theme travels between devices, so the effect the resolver is handed is not
// bounded by what the local picker offers. These tests pin what each desktop
// backend is given for a value it cannot render — the case where the picker is
// no help because the choice was made on another OS.
import 'package:flutter/material.dart';
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

  group('planWindowEffect', () {
    const background = Color(0xFF102030);
    const surface = Color(0xFF405060);

    WindowEffectPlan plan({
      WindowEffectType type = WindowEffectType.acrylic,
      Color backgroundColor = background,
      double effectOpacity = 0.5,
      Brightness brightness = Brightness.dark,
    }) => planWindowEffect(
      type: type,
      backgroundColor: backgroundColor,
      surfaceColor: surface,
      effectOpacity: effectOpacity,
      brightness: brightness,
    );

    setUp(() => debugAppPlatformOverride = AppPlatformKind.windows);

    test('tints a blur with the requested opacity, not its inverse', () {
      // The launch path used to build the tint from `1.0 - effectOpacity`,
      // so an effect looked one way when picked and the other way after a
      // restart.
      expect(plan(effectOpacity: 0.8).color.a, closeTo(0.8, 0.005));
    });

    test('holds a blur tint at a floor so the theme colour stays visible', () {
      expect(plan(effectOpacity: 0.0).color.a, closeTo(0.15, 0.005));
    });

    test('tints with the surface colour when the background was removed', () {
      final result = plan(backgroundColor: const Color(0x00102030));
      expect(result.color.r, closeTo(surface.r, 0.005));
      expect(result.color.g, closeTo(surface.g, 0.005));
      expect(result.color.b, closeTo(surface.b, 0.005));
    });

    test('carries transparency in the alpha call, not in the tint', () {
      final result = plan(type: WindowEffectType.transparent, effectOpacity: 0.3);
      expect(result.effect, WindowEffect.transparent);
      expect(result.color, Colors.transparent);
      expect(result.alphaValue, 0.3);
    });

    test('leaves transparency below the blur floor alone', () {
      // A barely-there window is what "transparent at 0.05" asks for; only
      // blurs need the floor.
      expect(plan(type: WindowEffectType.transparent, effectOpacity: 0.05)
          .alphaValue, 0.05);
    });

    test('never asks for a window alpha when no transparency was chosen', () {
      // The call is not a no-op, so sending 1.0 would undo a transparency the
      // theme never touched.
      expect(plan(type: WindowEffectType.mica).alphaValue, isNull);
    });

    test('passes the brightness through as the dark flag', () {
      expect(plan(brightness: Brightness.light).dark, isFalse);
      expect(plan(brightness: Brightness.dark).dark, isTrue);
    });

    group('on Linux', () {
      setUp(() => debugAppPlatformOverride = AppPlatformKind.linux);

      test('puts transparency in the tint alpha instead', () {
        final result = plan(
          type: WindowEffectType.transparent,
          effectOpacity: 0.3,
        );
        expect(result.effect, WindowEffect.transparent);
        expect(result.color.a, closeTo(0.3, 0.005));
        expect(
          result.alphaValue,
          isNull,
          reason: 'the GTK backend has no window-alpha call',
        );
      });

      test('does not hand a synced blur the transparency treatment', () {
        // acrylic resolves to `disabled` here; branching on the requested
        // effect rather than the resolved one would make it see-through.
        final result = plan(type: WindowEffectType.acrylic);
        expect(result.effect, WindowEffect.disabled);
        expect(result.alphaValue, isNull);
        expect(result.color.a, greaterThan(0));
      });
    });
  });
}
