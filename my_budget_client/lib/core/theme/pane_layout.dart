import 'package:flutter/widgets.dart';
import 'package:my_budget_client/core/theme/app_spacing.dart';

/// Height below which a horizontal navigation bar is the only thing that fits.
///
/// A phone in landscape is ~360dp tall: a `NavigationRail` with six or seven
/// destinations needs roughly 500dp and simply overflows. Width alone cannot
/// answer "rail or bar" — height has to be part of the question.
const double kCompactHeightBreakpoint = 500.0;

/// Pane width above which a rail should show its text labels rather than bare
/// icons. Below it the labels live in a tooltip; a tablet has no pointer to
/// summon one, so the rail extends instead.
const double kExtendedRailBreakpoint = 900.0;

/// The size of the content pane, published by the app shell.
///
/// Screens inside the shell must not size themselves from
/// `MediaQuery.of(context).size`: the navigation rail and its divider take
/// ~73dp off the left, so the window can be over [kMobileBreakpoint] while the
/// pane the screen actually gets is under it. That 73dp band is where the
/// desktop filter bars overflow. Reading the pane from here removes the
/// disagreement — every screen asks the same authority.
class PaneLayout extends InheritedWidget {
  const PaneLayout({required this.size, required super.child, super.key});

  /// The space the screen has been given, not the space the window has.
  final Size size;

  static PaneLayout? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PaneLayout>();

  @override
  bool updateShouldNotify(PaneLayout oldWidget) => oldWidget.size != size;
}

extension PaneLayoutContext on BuildContext {
  /// The pane's size, falling back to the window when a screen is rendered
  /// outside the shell (a full-screen route, a dialog, a widget test).
  Size get paneSize =>
      PaneLayout.maybeOf(this)?.size ?? MediaQuery.sizeOf(this);

  /// True when the pane is too narrow for the desktop layout of a screen.
  /// Replaces every `MediaQuery.of(context).size.width < kMobileBreakpoint`.
  bool get isCompactPane => paneSize.width < kMobileBreakpoint;

  /// True when the pane is too short to stack vertical chrome — a phone in
  /// landscape, or a deliberately squat desktop window.
  bool get isShortPane => paneSize.height < kCompactHeightBreakpoint;

  /// True when a navigation rail would be a better fit than a bottom bar:
  /// wide enough for the rail *and* tall enough to hold its destinations.
  bool get prefersRail => !isCompactPane && !isShortPane;

  /// True when that rail has room to show its labels inline.
  bool get prefersExtendedRail =>
      prefersRail && paneSize.width >= kExtendedRailBreakpoint;
}
