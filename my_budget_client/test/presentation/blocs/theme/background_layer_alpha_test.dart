// `effectOpacity` carries two different meanings and the app shell only ever
// knew one of them. For a blur it is a plain opacity. For a transparent window
// it is the argument for Windows' `setWindowAlphaValue`, whose behaviour is
// parabolic - 0.0 and 1.0 both come out opaque, the middle is the most
// see-through - so the theme screen stores it reversed there: its "Opaque" chip
// saves 0.0 and its "fully transparent" chip saves 0.5. The shell handed that
// straight to a colour's alpha, so asking for an opaque background got you a
// completely see-through one.
//
// Lives beside the theme bloc tests because the mapping is only reachable from
// `MaterialApp.builder`, which cannot be pumped without the whole DI graph.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/app.dart';
import 'package:my_budget_client/core/theme/app_theme.dart';
import 'package:my_budget_client/domain/entities/custom_theme.dart';

CustomTheme _theme(WindowEffectType effect, double effectOpacity) =>
    CustomTheme(
      id: 't',
      name: 'T',
      primaryColor: const Color(0xFF2196F3),
      secondaryColor: const Color(0xFF9C27B0),
      surfaceColor: const Color(0xFF252525),
      backgroundColor: const Color(0xFF121212),
      windowEffectType: effect,
      effectOpacity: effectOpacity,
      themeMode: ThemeMode.dark,
    );

void main() {
  group('a transparent window', () {
    // The five chips the theme screen offers, and the value each one saves.
    test('"Opaque" paints an opaque background', () {
      expect(
        backgroundLayerAlpha(_theme(WindowEffectType.transparent, 0.0)),
        1.0,
      );
    });

    test('"fully transparent" paints nothing', () {
      expect(
        backgroundLayerAlpha(_theme(WindowEffectType.transparent, 0.5)),
        0.0,
      );
    });

    test(
      'the chips in between match the transparency they are labelled with',
      () {
        expect(
          backgroundLayerAlpha(_theme(WindowEffectType.transparent, 0.1)),
          closeTo(0.75, 0.001),
        );
        expect(
          backgroundLayerAlpha(_theme(WindowEffectType.transparent, 0.2)),
          closeTo(0.5, 0.001),
        );
        expect(
          backgroundLayerAlpha(_theme(WindowEffectType.transparent, 0.35)),
          closeTo(0.25, 0.001),
        );
      },
    );

    test('more transparency chosen is never more background painted', () {
      var previous = 2.0;
      for (final stored in [0.0, 0.1, 0.2, 0.35, 0.5]) {
        final alpha = backgroundLayerAlpha(
          _theme(WindowEffectType.transparent, stored),
        );
        expect(alpha, lessThan(previous));
        previous = alpha;
      }
    });

    test('a value past the peak of the parabola is read off the other arm', () {
      // What a theme carries when the user switched over from a blur, whose
      // slider runs the whole 0..1, or synced one in from another device.
      expect(
        backgroundLayerAlpha(_theme(WindowEffectType.transparent, 1.0)),
        1.0,
      );
      expect(
        backgroundLayerAlpha(_theme(WindowEffectType.transparent, 0.8)),
        closeTo(
          backgroundLayerAlpha(_theme(WindowEffectType.transparent, 0.2)),
          0.001,
        ),
      );
    });
  });

  group('every other effect', () {
    test('uses the value the slider shows, unchanged', () {
      for (final effect in [
        WindowEffectType.none,
        WindowEffectType.acrylic,
        WindowEffectType.mica,
        WindowEffectType.aero,
        WindowEffectType.vibrancy,
      ]) {
        expect(backgroundLayerAlpha(_theme(effect, 0.0)), 0.0);
        expect(backgroundLayerAlpha(_theme(effect, 0.8)), closeTo(0.8, 0.001));
        expect(backgroundLayerAlpha(_theme(effect, 1.0)), 1.0);
      }
    });
  });
}
