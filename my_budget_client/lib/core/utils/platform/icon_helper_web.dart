import 'package:flutter/material.dart';

class IconPlatformHelper {
  static Widget buildSvgFromFile(
    String path, {
    ColorFilter? colorFilter,
    double? width,
    double? height,
  }) {
    // On web, local file paths are not accessible directly like this.
    // Return a placeholder or empty widget.
    return const Icon(Icons.broken_image, color: Colors.grey);
  }

  static Widget buildImageFromFile(
    String path, {
    Color? color,
    double? width,
    double? height,
  }) {
    // On web, local file paths are not accessible directly like this.
    // Return a placeholder or empty widget.
    return const Icon(Icons.broken_image, color: Colors.grey);
  }

  static ImageProvider getImageFromFile(String path) {
    // Return a placeholder or transparent image for web if path is not asset/network
    return const NetworkImage('about:blank');
  }
}
