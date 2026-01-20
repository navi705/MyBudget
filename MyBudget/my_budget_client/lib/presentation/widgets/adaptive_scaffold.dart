import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    final isMobile = MediaQuery.of(context).size.width < 600;

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
        location.startsWith('/exchange-rates')) {
      for (int i = 0; i < widget.destinations.length; i++) {
        if (widget.destinations[i].label == 'Settings') {
          return i;
        }
      }
    }

    return bestMatchIndex < 0 ? 0 : bestMatchIndex;
  }

  void _onItemTapped(int index, BuildContext context) {
    context.go(widget.destinations[index].route);
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    // Get the primary color from the current theme
    final primaryColor = Theme.of(context).primaryColor;
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Scaffold(
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
                        // Dynamic icon based on state
                        icon: Icon(
                          _isExtended
                              ? Icons.keyboard_double_arrow_left
                              : Icons.keyboard_double_arrow_right,
                          color: colorScheme.onSurface,
                          size: _isExtended ? 24.0 : 20.0,
                        ),
                        tooltip: _isExtended ? 'Collapse Menu' : 'Expand Menu',
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
