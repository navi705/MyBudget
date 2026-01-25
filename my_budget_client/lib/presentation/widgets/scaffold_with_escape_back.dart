import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/core/utils/hotkey_utils.dart';
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';

/// A widget that wraps a child and adds Escape key handling to pop the route
/// when the back button would be visible (i.e., when there's a route to pop).
class EscapeBackHandler extends StatelessWidget {
  const EscapeBackHandler({required this.child, this.onBack, super.key});

  final Widget child;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        final backKeyString = state.hotkeys['back'] ?? '';
        final activator =
            HotKeyUtils.parseToActivator(backKeyString) ??
            const SingleActivator(LogicalKeyboardKey.escape);

        return CallbackShortcuts(
          bindings: {
            activator: () {
              if (onBack != null) {
                onBack!();
              } else if (context.canPop()) {
                context.pop();
              }
            },
          },
          child: Focus(autofocus: true, child: child),
        );
      },
    );
  }
}
