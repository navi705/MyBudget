import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
import 'package:my_budget_client/core/navigation/navigator_keys.dart';
import 'package:my_budget_client/core/theme/app_spacing.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';
import 'package:my_budget_client/presentation/widgets/navigation_item.dart';
import 'package:my_budget_client/presentation/widgets/multi_level_tooltip.dart';

class AdaptiveScaffold extends StatefulWidget {
  const AdaptiveScaffold({
    required this.child,
    required this.destinations,
    super.key,
  });

  final Widget child;
  final List<NavigationItem> destinations;

  @override
  State<AdaptiveScaffold> createState() => _AdaptiveScaffoldState();
}

class _AdaptiveScaffoldState extends State<AdaptiveScaffold> {
  bool _isExtended = true;

  int _calculateSelectedIndex(BuildContext context, {required bool isMobile}) {
    final String location = GoRouterState.of(context).uri.toString();

    // Find the best match. Longer routes are more specific.
    int bestMatchIndex = -1;
    int longestMatch = -1;

    for (int i = 0; i < widget.destinations.length; i++) {
      final route = widget.destinations[i].route;

      // Special case for root: only match exactly or if we're at a sub-path we want to group.
      // But usually, we only want '/' to match exactly '/' to avoid it matching everything.
      bool isMatch = false;
      if (route == '/') {
        isMatch = (location == '/');
      } else {
        isMatch = location.startsWith(route);
      }

      if (isMatch && route.length > longestMatch) {
        longestMatch = route.length;
        bestMatchIndex = i;
      }
    }

    // Special case for Mobile: Data screen (exchange-rates) is accessed via Settings.
    // If no match was found and we are on /exchange-rates, find Settings index.
    if (bestMatchIndex < 0 &&
        isMobile &&
        location.startsWith(AppRoutes.exchangeRates)) {
      for (int i = 0; i < widget.destinations.length; i++) {
        // Match on the route, never the label: labels come from l10n, so an
        // English literal silently stops matching in the other nine locales
        // and the highlight falls back to the first destination instead.
        if (widget.destinations[i].route == AppRoutes.settings) {
          return i;
        }
      }
    }

    return bestMatchIndex < 0 ? 0 : bestMatchIndex;
  }

  void _onItemTapped(int index, BuildContext context) {
    // Close any open context menus or popups before navigating
    AppNavigator.dismissAllOverlays();
    context.go(widget.destinations[index].route);
  }

  @override
  Widget build(BuildContext context) {
    // Get the primary color from the current theme
    final primaryColor = Theme.of(context).primaryColor;
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        // The layout follows the width this shell was actually given, not the
        // host OS: a half-width desktop window has to behave like a phone, and
        // a tablet like a desktop. `constraints` rather than MediaQuery.size
        // matters for everything nested inside the rail branch below, where the
        // content pane is 73dp narrower than the window (72dp rail + 1dp
        // divider) — mixing the two makes callers disagree about the breakpoint
        // right in the band where the layout flips.
        final isMobile = constraints.maxWidth < kMobileBreakpoint;
        final selectedIndex = _calculateSelectedIndex(
          context,
          isMobile: isMobile,
        );

        if (isMobile) {
          return Scaffold(
            resizeToAvoidBottomInset:
                false, // Prevent keyboard animation & layout thrashing
            body: widget.child,
            bottomNavigationBar: NavigationBarTheme(
              data: NavigationBarThemeData(
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  final color = states.contains(WidgetState.selected)
                      ? primaryColor
                      : colorScheme.onSurface.withValues(alpha: 0.7);
                  return TextStyle(
                    fontSize: 12,
                    fontWeight: states.contains(WidgetState.selected)
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: color,
                  );
                }),
              ),
              child: NavigationBar(
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) => _onItemTapped(index, context),
                destinations: widget.destinations.map((item) {
                  Widget iconWidget = Icon(item.icon);
                  if (item.tooltip != null || item.hotkeyId != null) {
                    iconWidget = MultiLevelTooltip(
                      message: item.tooltip ?? item.label,
                      actionId: item.hotkeyId ?? '',
                      description: item.tooltipDescription,
                      child: iconWidget,
                    );
                  }
                  return NavigationDestination(
                    icon: iconWidget,
                    label: item.label,
                  );
                }).toList(),
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              ),
            ),
          );
        } else {
          return Scaffold(
            resizeToAvoidBottomInset:
                false, // Prevent keyboard animation & layout thrashing
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) =>
                      _onItemTapped(index, context),
                  extended: false,
                  minWidth: _isExtended ? 72.0 : 56.0,
                  labelType: _isExtended
                      ? NavigationRailLabelType.all
                      : NavigationRailLabelType.none,
                  // Use primary color for the indicator (highlight)
                  indicatorColor: primaryColor,
                  // Use white (or onPrimary) for the icon inside the indicator
                  selectedIconTheme: IconThemeData(
                    color: colorScheme.onPrimary,
                    size: _isExtended ? 24.0 : 20.0,
                  ),
                  unselectedIconTheme: IconThemeData(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    size: _isExtended ? 24.0 : 20.0,
                  ),
                  selectedLabelTextStyle: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  leading: Column(
                    children: [
                      const SizedBox(height: 8),
                      // Collapsed button doesn't need hotkey/multi-level tooltip for now as it's purely UI state
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isExtended = !_isExtended;
                          });
                        },
                        // Dynamic icon based on state. The rail sits on the
                        // start edge, so under RTL collapsing moves the panel
                        // right — the arrow has to follow the text direction
                        // or it points at the screen edge it opens away from.
                        icon: Icon(
                          _isExtended == (Directionality.of(context) ==
                                  TextDirection.rtl)
                              ? Icons.keyboard_double_arrow_right
                              : Icons.keyboard_double_arrow_left,
                          color: colorScheme.onSurface,
                          size: _isExtended ? 24.0 : 20.0,
                        ),
                        tooltip: _isExtended
                            ? context.l10n.collapseMenuTooltip
                            : context.l10n.expandMenuTooltip,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                  destinations: widget.destinations.map((item) {
                    Widget iconWidget = Icon(item.icon);
                    // For NavigationRail, we can wrap the icon.
                    // Note: If extended, we might want to attach tooltip to the whole item, but Rail Destination takes icon.
                    if (item.tooltip != null || item.hotkeyId != null) {
                      iconWidget = MultiLevelTooltip(
                        message: item.tooltip ?? item.label,
                        actionId: item.hotkeyId ?? '',
                        description: item.tooltipDescription,
                        // Side position for rail? Default is bottom, which is fine.
                        child: iconWidget,
                      );
                    }
                    return NavigationRailDestination(
                      icon: iconWidget,
                      label: Text(item.label),
                    );
                  }).toList(),
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: widget.child),
              ],
            ),
          );
        }
      },
    );
  }
}
