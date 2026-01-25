import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HotKeyUtils {
  static LogicalKeyboardKey? getKeyById(int keyId) {
    // We can construct a LogicalKeyboardKey from ID.
    // However, for modifiers to work correctly with SingleActivator,
    // we need to match the specific constants if possible, or at least ensure SingleActivator recognizes them.
    // Fortunately LogicalKeyboardKey equality is based on keyId.
    return LogicalKeyboardKey(keyId);
  }

  static SingleActivator? parseToActivator(String keyString) {
    if (keyString.isEmpty) return null;

    final parts = keyString.split('+');
    if (parts.isEmpty) return null;

    LogicalKeyboardKey? trigger;
    bool control = false;
    bool shift = false;
    bool alt = false;
    bool meta = false;

    for (var part in parts) {
      final keyId = int.tryParse(part.trim());
      if (keyId == null) continue;

      final key = LogicalKeyboardKey(keyId);

      if (key == LogicalKeyboardKey.control ||
          key == LogicalKeyboardKey.controlLeft ||
          key == LogicalKeyboardKey.controlRight) {
        control = true;
      } else if (key == LogicalKeyboardKey.shift ||
          key == LogicalKeyboardKey.shiftLeft ||
          key == LogicalKeyboardKey.shiftRight) {
        shift = true;
      } else if (key == LogicalKeyboardKey.alt ||
          key == LogicalKeyboardKey.altLeft ||
          key == LogicalKeyboardKey.altRight) {
        alt = true;
      } else if (key == LogicalKeyboardKey.meta ||
          key == LogicalKeyboardKey.metaLeft ||
          key == LogicalKeyboardKey.metaRight) {
        meta = true;
      } else {
        trigger = key;
      }
    }

    if (trigger != null) {
      return SingleActivator(
        trigger,
        control: control,
        shift: shift,
        alt: alt,
        meta: meta,
      );
    }
    // If only modifiers? e.g. "Esc"
    // Wait, "Esc" is a trigger.
    // If we only found modifiers, return null.
    // But wait the loop handles trigger.
    return null;
  }

  static String serializeKeys(Set<LogicalKeyboardKey> keys) {
    // Sort: modifiers first
    final sorted = keys.toList();
    sorted.sort((a, b) {
      final aIsMod = _isModifier(a);
      final bIsMod = _isModifier(b);
      if (aIsMod && !bIsMod) return -1;
      if (!aIsMod && bIsMod) return 1;
      return a.keyId.compareTo(b.keyId);
    });
    return sorted.map((k) => k.keyId.toString()).join('+');
  }

  static String getDisplayString(String keyString) {
    if (keyString.isEmpty) return 'None';
    final parts = keyString.split('+');
    final labels = <String>[];

    for (var part in parts) {
      final keyId = int.tryParse(part.trim());
      if (keyId != null) {
        final key = LogicalKeyboardKey(keyId);
        // Try to equate to known keys for better labels?
        // key.keyLabel is usually good.
        labels.add(key.keyLabel);
      }
    }
    return labels.join(' + ');
  }

  static bool _isModifier(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.control ||
        key == LogicalKeyboardKey.controlLeft ||
        key == LogicalKeyboardKey.controlRight ||
        key == LogicalKeyboardKey.alt ||
        key == LogicalKeyboardKey.altLeft ||
        key == LogicalKeyboardKey.altRight ||
        key == LogicalKeyboardKey.shift ||
        key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight ||
        key == LogicalKeyboardKey.meta ||
        key == LogicalKeyboardKey.metaLeft ||
        key == LogicalKeyboardKey.metaRight;
  }
}
