import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';

class WindowUtils {
  static Future<void> initialize() async {
    // Every desktop backend needs this before the first Window.setEffect call.
    // On macOS it boots macos_window_utils' WindowManipulator, which owns the
    // NSVisualEffectView the effect is applied to; on Windows and Linux it
    // completes the internal completer that setEffect awaits, so skipping it
    // leaves every later setEffect hanging forever instead of failing loudly.
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      await Window.initialize();
    }
  }
}
