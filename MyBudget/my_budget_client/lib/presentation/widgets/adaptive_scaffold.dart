import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/presentation/widgets/navigation_item.dart';

class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    required this.child,
    required this.destinations,
    super.key,
  });

  final Widget child;
  final List<NavigationItem> destinations;

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    // Find the best match. Longer routes are more specific.
    int bestMatchIndex = -1;
    int longestMatch = -1;

    for (int i = 0; i < destinations.length; i++) {
      final route = destinations[i].route;
      if (location.startsWith(route) && route.length > longestMatch) {
        longestMatch = route.length;
        bestMatchIndex = i;
      }
    }
    
    return bestMatchIndex < 0 ? 0 : bestMatchIndex;
  }

  void _onItemTapped(int index, BuildContext context) {
    context.go(destinations[index].route);
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Scaffold(
            body: child,
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: selectedIndex,
              onTap: (index) => _onItemTapped(index, context),
              items: destinations.map((item) {
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
                  onDestinationSelected: (index) => _onItemTapped(index, context),
                  labelType: NavigationRailLabelType.all,
                  destinations: destinations.map((item) {
                    return NavigationRailDestination(
                      icon: Icon(item.icon),
                      label: Text(item.label),
                    );
                  }).toList(),
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: child),
              ],
            ),
          );
        }
      },
    );
  }
}
