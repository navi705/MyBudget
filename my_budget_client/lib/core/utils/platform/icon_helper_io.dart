import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class IconPlatformHelper {
  static Widget buildSvgFromFile(
    String path, {
    ColorFilter? colorFilter,
    double? width,
    double? height,
  }) {
    return SvgPicture.file(
      File(path),
      colorFilter: colorFilter,
      width: width,
      height: height,
    );
  }

  static Widget buildImageFromFile(
    String path, {
    Color? color,
    double? width,
    double? height,
  }) {
    return Image.file(File(path), color: color, width: width, height: height);
  }

  static ImageProvider getImageFromFile(String path) {
    return FileImage(File(path));
  }
}
