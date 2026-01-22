import 'package:flutter/foundation.dart';
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
            final isModifier =
                event.logicalKey == LogicalKeyboardKey.alt ||
                event.logicalKey == LogicalKeyboardKey.altLeft ||
                event.logicalKey == LogicalKeyboardKey.altRight ||
                event.logicalKey == LogicalKeyboardKey.control ||
                event.logicalKey == LogicalKeyboardKey.controlLeft ||
                event.logicalKey == LogicalKeyboardKey.controlRight ||
                event.logicalKey == LogicalKeyboardKey.shift ||
                event.logicalKey == LogicalKeyboardKey.shiftLeft ||
                event.logicalKey == LogicalKeyboardKey.shiftRight ||
                event.logicalKey == LogicalKeyboardKey.meta ||
                event.logicalKey == LogicalKeyboardKey.metaLeft ||
                event.logicalKey == LogicalKeyboardKey.metaRight;

            if (event is KeyDownEvent || event is KeyRepeatEvent) {
              for (final entry in bindings.entries) {
                if (entry.key.accepts(event, HardwareKeyboard.instance)) {
                  entry.value();
                  return KeyEventResult.handled;
                }
              }

              // If it's a modifier key and we have shortcuts registered that might use it,
              // handle it to prevent Windows system beep/menu activation.
              if (isModifier) {
                final hasAltActive =
                    HardwareKeyboard.instance.isAltPressed ||
                    event.logicalKey == LogicalKeyboardKey.alt ||
                    event.logicalKey == LogicalKeyboardKey.altLeft ||
                    event.logicalKey == LogicalKeyboardKey.altRight;

                if (hasAltActive) {
                  // Only handle if it's likely part of a shortcut to avoid breaking system combos like Alt+F4
                  // We check if any of our bindings use Alt
                  final anyAltShortcut = bindings.keys.any(
                    (activator) => activator.alt,
                  );
                  if (anyAltShortcut) {
                    return KeyEventResult.handled;
                  }
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
