import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';

class WindowUtils {
  static Future<void> initialize() async {
    if (Platform.isWindows) {
      await Window.initialize();
    }
  }
}
