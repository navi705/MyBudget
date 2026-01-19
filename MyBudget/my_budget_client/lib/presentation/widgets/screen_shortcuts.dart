import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        final Map<SingleActivator, VoidCallback> bindings = {};
        actions.forEach((id, callback) {
          final keyString = state.hotkeys[id];
          if (keyString != null && keyString.isNotEmpty) {
            final activator = HotKeyUtils.parseToActivator(keyString);
            if (activator != null) {
              bindings[activator] = callback;
            }
          }
        });

        return Focus(
          autofocus: true,
          debugLabel: 'ScreenShortcutsFocus ($actions)',
          canRequestFocus: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              for (final entry in bindings.entries) {
                if (entry.key.accepts(event, HardwareKeyboard.instance)) {
                  entry.value();
                  return KeyEventResult.handled;
                }
              }
            }
            return KeyEventResult.ignored;
          },
          child: child,
        );
      },
    );
  }
}
