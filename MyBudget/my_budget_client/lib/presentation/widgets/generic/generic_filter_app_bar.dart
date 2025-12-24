import 'package:flutter/material.dart';

class GenericFilterAppBar extends StatelessWidget implements PreferredSizeWidget {
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
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final bool hasNavigation = onNavigatePrevious != null && onNavigateNext != null;

    return Container(
      height: preferredSize.height,
      color: Theme.of(context).appBarTheme.backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (hasNavigation)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                  onPressed: onNavigatePrevious,
                )
              else
                const SizedBox(width: 48), // Placeholder for alignment

              Expanded(child: centerWidget),

              if (hasNavigation)
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
                  onPressed: onNavigateNext,
                )
              else
                const SizedBox(width: 48), // Placeholder for alignment
            ],
          ),
          Positioned(
            left: hasNavigation ? 50 : 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: Text(
                totalCountText,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
          if (actions != null)
            Positioned(
              right: hasNavigation ? 50 : 16,
              top: 0,
              bottom: 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: actions!,
              ),
            ),
        ],
      ),
    );
  }
}
