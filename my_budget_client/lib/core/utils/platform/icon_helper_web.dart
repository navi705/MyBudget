import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Web counterpart of `icon_helper_io.dart`.
///
/// Custom icons and theme backgrounds are stored as *paths* into the device's
/// documents directory, which the browser cannot reach. The pictures therefore
/// genuinely do not exist on web, and they will not until the bytes themselves
/// are kept in the database instead of a path (out of scope here).
///
/// What this stub owes the user is an honest, calm degradation: a neutral
/// placeholder rather than a "broken" glyph, since nothing is corrupt — the
/// image simply was never uploaded from this browser.
class IconPlatformHelper {
  /// A 1x1 fully transparent PNG.
  ///
  /// Used instead of a remote URL so that a missing background image renders
  /// as "no background" rather than firing a doomed network request on every
  /// theme rebuild and painting a broken-image box behind the whole app.
  static final Uint8List _transparentPixel = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR42mNgAAIAAAUAAen6'
    '3NgAAAAASUVORK5CYII=',
  );

  static Widget buildSvgFromFile(
    String path, {
    ColorFilter? colorFilter,
    double? width,
    double? height,
  }) {
    // A ColorFilter cannot be unpacked back into a plain Color, so the
    // placeholder keeps its own neutral tint here.
    return _unavailableIcon(width: width, height: height);
  }

  static Widget buildImageFromFile(
    String path, {
    Color? color,
    double? width,
    double? height,
  }) {
    return _unavailableIcon(color: color, width: width, height: height);
  }

  static ImageProvider getImageFromFile(String path) {
    return MemoryImage(_transparentPixel);
  }

  /// Stand-in for a file-backed icon the browser cannot load.
  ///
  /// Sized from the caller's [width]/[height] so it occupies the same slot as
  /// the real icon would, keeping layouts stable.
  static Widget _unavailableIcon({
    Color? color,
    double? width,
    double? height,
  }) {
    return Icon(
      Icons.image_outlined,
      color: color ?? Colors.grey,
      size: width ?? height,
    );
  }
}
