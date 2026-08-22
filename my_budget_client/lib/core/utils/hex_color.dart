import 'package:flutter/material.dart';

/// A colour read from a `colorHex` / `color` text column, or [fallback] if the
/// text is not a colour.
///
/// Those columns are plain text: nothing in the schema, the wire format or the
/// CSV importer constrains what lands in them, so a peer on another build, a
/// hand-edited export or an import column pointed at the wrong field can put
/// any string there. Seven screens each had their own copy of this parse and
/// six of them ended in a bare `int.parse`, which throws `FormatException` —
/// from inside `build()`, so one unreadable style took out the whole list it
/// appeared in rather than one swatch.
///
/// Three of those copies had no length check either, so a style whose hex was
/// simply empty reached `int.parse('0x')` and threw on the same path.
///
/// Accepts `#RRGGBB`, `#AARRGGBB` and either without the `#`, case
/// insensitively. Everything else is [fallback].
Color parseHexColor(String? hexColor, {required Color fallback}) {
  if (hexColor == null) return fallback;

  var hex = hexColor.replaceAll('#', '').trim();
  if (hex.length == 6) hex = 'FF$hex';
  if (hex.length != 8) return fallback;

  // `tryParse` rather than try/catch: `int.parse('0x$hex')` also accepts a
  // leading sign and underscore separators, so "0x-1234567" and "0x1_234567"
  // parsed as numbers that were never colours.
  if (!RegExp(r'^[0-9a-fA-F]{8}$').hasMatch(hex)) return fallback;
  final value = int.tryParse(hex, radix: 16);
  return value == null ? fallback : Color(value);
}
