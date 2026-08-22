// Foundation spacing, radius, and layout constants.
//
// Plain Dart values with no Flutter dependency so they can be shared freely
// across the widget tree without pulling in `material.dart`.

/// Width (in logical pixels) below which the app is treated as "mobile".
const double kMobileBreakpoint = 600.0;

/// Widest a dashboard pane is allowed to grow before it stops stretching and
/// centres instead.
///
/// A maximised window on a desktop monitor is far wider than any of these
/// panes have content for; letting them stretch the whole way spreads a chart
/// and its legend so far apart that they stop reading as one figure.
const double kDashboardPaneMaxWidth = 1200.0;

/// Width the calendar grid is given in the dashboard's two-column layout, and
/// the width it centres at when there is only one column.
///
/// A month grid wider than this spreads seven columns so far apart that a row
/// stops reading as a week.
const double kDashboardCalendarColumnWidth = 700.0;

/// Width at which the dashboard's calendar tab stops stacking its panes and
/// puts the period summary beside the grid instead.
///
/// [kDashboardCalendarColumnWidth] plus a 32dp gutter plus enough left over
/// for an account row to still fit its name and its balance on one line.
const double kDashboardTwoColumnBreakpoint = 1200.0;

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
