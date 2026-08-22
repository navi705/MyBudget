import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
import 'package:my_budget_client/core/navigation/navigator_keys.dart';
import 'package:my_budget_client/core/theme/pane_layout.dart';
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
  /// Whether the user has collapsed or expanded the rail by hand.
  ///
  /// `null` means untouched, and untouched is the only state the pane is
  /// allowed to answer for: once a person has pressed the toggle, resizing the
  /// window must not undo their choice.
  bool? _userExpandedRail;

  /// The rail shows its labels unless the user has said otherwise.
  bool get _railExpanded => _userExpandedRail ?? true;

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
    return LayoutBuilder(
      builder: (context, constraints) {
        // The layout follows the box this shell was actually given, not the
        // host OS: a half-width desktop window has to behave like a phone, and
        // a tablet like a desktop.
        //
        // Publishing that box as a [PaneLayout] first means the rail-or-bar
        // decision below and every screen underneath ask one authority, rather
        // than two that disagree (`constraints` here, `MediaQuery.size` there)
        // right across the ~142dp the rail and its divider take off the window.
        return PaneLayout(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          child: Builder(
            builder: (context) {
              // Width alone cannot answer "rail or bar". The rail needs ~446dp
              // for its toggle plus seven destinations, and a phone in
              // landscape is 360dp tall while being over 600dp wide: it passed
              // the width test and dropped its last three destinations off the
              // bottom, taking Settings - and everything only Settings reaches
              // - with them. `prefersRail` is width *and* height.
              final useRail = context.prefersRail;
              final selectedIndex = _calculateSelectedIndex(
                context,
                isMobile: !useRail,
              );

              return useRail
                  ? _buildRailScaffold(context, selectedIndex)
                  : _buildBottomBarScaffold(context, selectedIndex);
            },
          ),
        );
      },
    );
  }

  /// Republishes the pane as the *content* box rather than the shell box.
  ///
  /// What a screen is given is the window minus the rail, minus its divider,
  /// minus the bottom bar - and, now that the soft keyboard is allowed to
  /// resize the body, minus the keyboard too. Measuring inside the [Scaffold]
  /// body is the one place all of those have already been subtracted.
  Widget _paneOf(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) => PaneLayout(
        size: Size(constraints.maxWidth, constraints.maxHeight),
        child: child,
      ),
    );
  }

  Widget _buildBottomBarScaffold(BuildContext context, int selectedIndex) {
    final primaryColor = Theme.of(context).primaryColor;
    final colorScheme = Theme.of(context).colorScheme;

    // `resizeToAvoidBottomInset` is deliberately left at its default. The shell
    // must not decide on behalf of nineteen screens that the soft keyboard may
    // cover the field being typed into; a screen that genuinely needs the
    // pinned layout opts out for itself.
    return Scaffold(
      body: _paneOf(widget.child),
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
            return NavigationDestination(icon: iconWidget, label: item.label);
          }).toList(),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        ),
      ),
    );
  }

  Widget _buildRailScaffold(BuildContext context, int selectedIndex) {
    final primaryColor = Theme.of(context).primaryColor;
    final colorScheme = Theme.of(context).colorScheme;

    // A collapsed rail keeps its labels in a hover-only tooltip, which a touch
    // device can never summon. Past ~900dp there is room to simply show them,
    // so that is the default - until the user presses the toggle, after which
    // `_userExpandedRail` is the only opinion that counts.
    final bool expanded = _railExpanded;
    final bool extended = expanded && context.prefersExtendedRail;

    return Scaffold(
      // On `resizeToAvoidBottomInset`, see the note in
      // _buildBottomBarScaffold: the keyboard inset is the screen's call.
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) => _onItemTapped(index, context),
            extended: extended,
            // Belt and braces to the height-aware branch above: whatever the
            // window is doing, the destinations scroll instead of falling off
            // the bottom. An unreachable destination is a missing feature.
            scrollable: true,
            minWidth: expanded ? 72.0 : 56.0,
            // `extended` draws each label beside its icon and forbids any
            // other label type; stacked labels are the sub-900dp expansion.
            labelType: extended || !expanded
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            // Use primary color for the indicator (highlight)
            indicatorColor: primaryColor,
            // Use white (or onPrimary) for the icon inside the indicator
            selectedIconTheme: IconThemeData(
              color: colorScheme.onPrimary,
              size: expanded ? 24.0 : 20.0,
            ),
            unselectedIconTheme: IconThemeData(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              size: expanded ? 24.0 : 20.0,
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
                      _userExpandedRail = !expanded;
                    });
                  },
                  // Dynamic icon based on state. The rail sits on the
                  // start edge, so under RTL collapsing moves the panel
                  // right — the arrow has to follow the text direction
                  // or it points at the screen edge it opens away from.
                  icon: Icon(
                    expanded ==
                            (Directionality.of(context) == TextDirection.rtl)
                        ? Icons.keyboard_double_arrow_right
                        : Icons.keyboard_double_arrow_left,
                    color: colorScheme.onSurface,
                    size: expanded ? 24.0 : 20.0,
                  ),
                  tooltip: expanded
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
          Expanded(child: _paneOf(widget.child)),
        ],
      ),
    );
  }
}
