import 'package:flutter/material.dart';

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

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight * 1.5); // Increase default for safety or use dynamic

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final bool hasNavigation =
        onNavigatePrevious != null && onNavigateNext != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final actualHeight = kToolbarHeight;

        return Container(
          height: actualHeight + MediaQuery.of(context).padding.top,
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
                      icon: Icon(
                        Icons.arrow_back_ios,
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
                  if (actions != null && actions!.isNotEmpty && !isMobile)
                    Row(mainAxisSize: MainAxisSize.min, children: actions!)
                  else if (hasNavigation)
                    IconButton(
                      icon: Icon(
                        Icons.arrow_forward_ios,
                        color: onSurface,
                        size: 20,
                      ),
                      onPressed: onNavigateNext,
                    )
                  else if (!isMobile)
                    const SizedBox(width: 48)
                  else
                    const SizedBox(width: 0),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
