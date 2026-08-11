// Foundation spacing, radius, and layout constants.
//
// Plain Dart values with no Flutter dependency so they can be shared freely
// across the widget tree without pulling in `material.dart`.

/// Width (in logical pixels) below which the app is treated as "mobile".
const double kMobileBreakpoint = 600.0;

/// Standard spacing scale used for padding, gaps, and margins.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Standard corner-radius scale used for cards, sheets, and pills.
class AppRadius {
  const AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double pill = 20;
}
