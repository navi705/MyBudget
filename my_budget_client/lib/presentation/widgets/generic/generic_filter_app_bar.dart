import 'package:flutter/material.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
import 'package:my_budget_client/core/theme/app_spacing.dart';
import 'package:my_budget_client/presentation/widgets/directional_icon.dart';

class GenericFilterAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final Widget centerWidget;
  final String totalCountText;
  final VoidCallback? onNavigatePrevious;
  final VoidCallback? onNavigateNext;
  final List<Widget>? actions;

  const GenericFilterAppBar({
    super.key,
    required this.centerWidget,
    required this.totalCountText,
    this.onNavigatePrevious,
    this.onNavigateNext,
    this.actions,
  });

  /// The single height authority for this bar.
  ///
  /// There used to be three that disagreed: `preferredSize` said
  /// `kToolbarHeight * 1.5`, `build` drew `kToolbarHeight` plus the status bar
  /// inset, and callers wrapped the whole thing in `kToolbarHeight * 1.8`.
  /// Scaffold reserves `preferredSize.height` and adds the top padding itself,
  /// so the 1.5 left ~28dp of dead space under every filter bar. Anything that
  /// needs to reserve room for this bar reads [barSize].
  static const Size barSize = Size.fromHeight(kToolbarHeight);

  @override
  Size get preferredSize => barSize;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final bool hasNavigation =
        onNavigatePrevious != null && onNavigateNext != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Width the bar was actually handed, which is the pane's width when it
        // sits inside the shell.
        final isMobile = constraints.maxWidth < kMobileBreakpoint;

        return Container(
          height: barSize.height + MediaQuery.paddingOf(context).top,
          color: Theme.of(context).appBarTheme.backgroundColor,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  // Left side
                  if (!hasNavigation)
                    Text(
                      isMobile ? '' : totalCountText,
                      style: TextStyle(
                        color: onSurface,
                        fontSize: isMobile ? 14 : 16,
                      ),
                    )
                  else
                    IconButton(
                      tooltip: context.l10n.previousPeriodTooltip,
                      icon: DirectionalIcon.previousArrow(
                        color: onSurface,
                        size: 20,
                      ),
                      onPressed: onNavigatePrevious,
                    ),

                  // Center: Dropdown
                  Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child: centerWidget,
                    ),
                  ),

                  // Right side
                  ..._buildTrailing(
                    context,
                    isMobile: isMobile,
                    hasNavigation: hasNavigation,
                    onSurface: onSurface,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds the trailing slot.
  ///
  /// A narrow bar has no room for a row of action buttons, but the previous
  /// answer to that was to render nothing at all, which left filter/sort/add
  /// with no reachable entry point anywhere on a phone. Collapsing them into an
  /// overflow menu keeps every action available while costing one icon of
  /// width.
  List<Widget> _buildTrailing(
    BuildContext context, {
    required bool isMobile,
    required bool hasNavigation,
    required Color onSurface,
  }) {
    final trailing = <Widget>[];

    if (actions != null && actions!.isNotEmpty) {
      if (isMobile) {
        trailing.add(
          PopupMenuButton<int>(
            // No `tooltip:` on purpose — PopupMenuButton falls back to
            // MaterialLocalizations' own "Show menu" string, which is already
            // translated for every locale and needs no new ARB key.
            icon: Icon(Icons.more_vert, color: onSurface, size: 20),
            itemBuilder: (context) => [
              for (var i = 0; i < actions!.length; i++)
                // The action widgets are self-contained controls that carry
                // their own gesture handling, so the item is only a container
                // for them and deliberately declares no onTap of its own.
                PopupMenuItem<int>(value: i, child: actions![i]),
            ],
          ),
        );
      } else {
        trailing.add(Row(mainAxisSize: MainAxisSize.min, children: actions!));
      }
    }

    if (hasNavigation) {
      trailing.add(
        IconButton(
          tooltip: context.l10n.nextPeriodTooltip,
          icon: DirectionalIcon.nextArrow(color: onSurface, size: 20),
          onPressed: onNavigateNext,
        ),
      );
    } else if (trailing.isEmpty && !isMobile) {
      // Nothing to show, so reserve the width of the leading total-count text's
      // counterpart to keep the centre widget optically centred.
      trailing.add(const SizedBox(width: 48));
    }

    return trailing;
  }
}
