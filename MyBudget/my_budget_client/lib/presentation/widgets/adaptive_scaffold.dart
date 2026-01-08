import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/presentation/widgets/navigation_item.dart';

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
    // Find the best match. Longer routes are more specific.
    int bestMatchIndex = -1;
    int longestMatch = -1;

    for (int i = 0; i < widget.destinations.length; i++) {
      final route = widget.destinations[i].route;
      if (location.startsWith(route) && route.length > longestMatch) {
        longestMatch = route.length;
        bestMatchIndex = i;
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
            bottomNavigationBar: BottomNavigationBar(
              selectedItemColor: primaryColor,
              type: BottomNavigationBarType.fixed,
              currentIndex: selectedIndex,
              onTap: (index) => _onItemTapped(index, context),
              items: widget.destinations.map((item) {
                return BottomNavigationBarItem(
                  icon: Icon(item.icon),
                  label: item.label,
                );
              }).toList(),
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
                    return NavigationRailDestination(
                      icon: Icon(item.icon),
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
