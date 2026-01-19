import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/presentation/blocs/theme/theme_bloc.dart';
import 'package:my_budget_client/core/theme/app_theme.dart';

class NavigationTabBarItem {
  final IconData icon;
  final String label;

  const NavigationTabBarItem({required this.icon, required this.label});
}

class NavigationTabBar extends StatelessWidget {
  final List<NavigationTabBarItem> items;
  final int selectedIndex;
  final Function(int) onTap;

  const NavigationTabBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // We wrap in MediaQuery to remove the default bottom padding that BottomNavigationBar applies
    // for safe areas, since we might be placing this at the top of the screen or in a specific layout.
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        final activeTheme = state.activeTheme;

        Color backgroundColor;
        if (activeTheme != null) {
          if (activeTheme.windowEffectType != WindowEffectType.none) {
            backgroundColor = Colors.transparent;
          } else {
            backgroundColor = activeTheme.backgroundColor;
          }
        } else {
          backgroundColor = Theme.of(context).colorScheme.surface;
        }

        final primaryColor =
            activeTheme?.primaryColor ?? Theme.of(context).colorScheme.primary;
        final unselectedColor = activeTheme?.surfaceColor != null
            ? (activeTheme!.themeMode == ThemeMode.dark ||
                      (activeTheme.themeMode == ThemeMode.system &&
                          MediaQuery.of(context).platformBrightness ==
                              Brightness.dark)
                  ? Colors.white70
                  : Colors.black54)
            : Theme.of(context).colorScheme.onSurfaceVariant;

        return MediaQuery.removePadding(
          context: context,
          removeBottom: true,
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor, // Use explicit custom theme background
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.5),
                  width: 1,
                ),
              ),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: BottomNavigationBar(
                  currentIndex: selectedIndex,
                  onTap: onTap,
                  backgroundColor:
                      Colors.transparent, // Let Container color show
                  elevation: 0, // We handle border manually for control
                  selectedItemColor: primaryColor,
                  unselectedItemColor: unselectedColor,
                  type: BottomNavigationBarType.fixed,
                  items: items.map((item) {
                    return BottomNavigationBarItem(
                      icon: Icon(item.icon),
                      label: item.label,
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
