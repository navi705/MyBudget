import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// A widget that wraps a child and adds Escape key handling to pop the route
/// when the back button would be visible (i.e., when there's a route to pop).
class EscapeBackHandler extends StatelessWidget {
  const EscapeBackHandler({required this.child, this.onBack, super.key});

  final Widget child;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (onBack != null) {
            onBack!();
          } else if (context.canPop()) {
            context.pop();
          }
        },
      },
      child: Focus(autofocus: true, child: child),
    );
  }
}
