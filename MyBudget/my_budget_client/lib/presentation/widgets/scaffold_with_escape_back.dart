import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// A widget that wraps a child and adds Escape key handling to pop the route
/// when the back button would be visible (i.e., when there's a route to pop).
class EscapeBackHandler extends StatelessWidget {
  const EscapeBackHandler({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.escape): const _EscapeBackIntent(),
      },
      child: Actions(
        actions: {
          _EscapeBackIntent: CallbackAction<_EscapeBackIntent>(
            onInvoke: (intent) {
              if (context.canPop()) {
                context.pop();
                return;
              }
              return null;
            },
          ),
        },
        child: Focus(autofocus: false, child: child),
      ),
    );
  }
}

class _EscapeBackIntent extends Intent {
  const _EscapeBackIntent();
}
