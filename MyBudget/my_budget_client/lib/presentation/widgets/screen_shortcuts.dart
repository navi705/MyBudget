import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/core/utils/hotkey_utils.dart';
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';

class ScreenShortcuts extends StatelessWidget {
  final Widget child;
  final Map<String, VoidCallback> actions;

  const ScreenShortcuts({
    super.key,
    required this.child,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (previous, current) => previous.hotkeys != current.hotkeys,
      builder: (context, state) {
        final bindings = <ShortcutActivator, VoidCallback>{};

        actions.forEach((id, callback) {
          final keyString = state.hotkeys[id];
          if (keyString != null && keyString.isNotEmpty) {
            final activator = HotKeyUtils.parseToActivator(keyString);
            if (activator != null) {
              bindings[activator] = callback;
            }
          }
        });

        // Use Focus to ensure the Shortcuts are in the focus tree
        // Note: The child usually contains focusable elements (buttons, text fields).
        // If the child has no focusable elements, we might need autfocus here.
        // But usually Scaffold implies some focus structure.
        return CallbackShortcuts(
          bindings: bindings,
          child: Focus(
            autofocus: true,
            debugLabel: 'ScreenShortcutsFocus',
            // Allow focus to move to children
            canRequestFocus: true,
            child: child,
          ),
        );
      },
    );
  }
}
