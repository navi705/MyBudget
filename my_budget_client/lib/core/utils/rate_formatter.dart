import 'dart:math' as math;

/// Renders an exchange rate as a plain decimal string.
///
/// `double.toString()` switches to scientific notation below 1e-6, and the
/// transfer form seeds its rate field straight from it: a MZM -> XAUT rate
/// reached the user as `3.4222877778838255e-9`, in a field whose keyboard
/// offers no `e` and whose input formatter strips every letter, so the value
/// could be read but never retyped - and the first keystroke turned it into a
/// rate 10^9 too large. `toStringAsFixed(4)` - what the preset chips used - is
/// the same problem from the other end: every rate below 0.00005 renders as
/// `0.0000`, so a row of chips offering four different rates showed four
/// identical labels.
class RateFormatter {
  const RateFormatter._();

  /// Digits [short] keeps, counted from the first non-zero one.
  static const int _significantDigits = 6;

  /// `toStringAsFixed` refuses anything above this.
  static const int _maxDecimals = 20;

  /// The text an editable rate field is seeded with.
  ///
  /// Every digit `toString` produced is kept and only the exponent is spelled
  /// out, so a rate that goes through this and back is the same double it
  /// started as. Rounding here would be a quiet edit to a stored historical
  /// rate every time a transfer was reopened and saved again.
  static String forInput(double rate) {
    if (!rate.isFinite) return '';
    return _withoutExponent(rate.toString());
  }

  /// A short label for a chip or a summary line, where the full precision of
  /// [forInput] would not fit and is not being edited.
  static String short(double rate) {
    if (!rate.isFinite) return '';
    if (rate == 0) return '0';
    final text = rate.toStringAsFixed(_decimalsFor(rate));
    if (!text.contains('.')) return text;
    return text
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  static int _decimalsFor(double rate) {
    // log10 of the magnitude says where the first significant digit sits: -9
    // for 3.4e-9, 2 for 342. Keeping [_significantDigits] from there means 14
    // decimals in the first case and 3 in the second.
    final exponent = (math.log(rate.abs()) / math.ln10).floor();
    return (_significantDigits - 1 - exponent).clamp(0, _maxDecimals);
  }

  /// Moves the decimal point of `1.5e-9` by hand rather than rounding to a
  /// fixed number of places, so no digit is lost.
  static String _withoutExponent(String text) {
    final eIndex = text.indexOf('e');
    if (eIndex < 0) return text;

    final exponent = int.parse(text.substring(eIndex + 1));
    var mantissa = text.substring(0, eIndex);

    final isNegative = mantissa.startsWith('-');
    if (isNegative) mantissa = mantissa.substring(1);

    final point = mantissa.indexOf('.');
    final digits = point < 0 ? mantissa : mantissa.replaceFirst('.', '');
    // Where the point sits once the exponent has moved it. Counted from the
    // left of [digits], so a value <= 0 means leading zeros are needed.
    final pointAt = (point < 0 ? mantissa.length : point) + exponent;

    final String plain;
    if (pointAt <= 0) {
      plain = '0.${'0' * -pointAt}$digits';
    } else if (pointAt >= digits.length) {
      plain = digits + '0' * (pointAt - digits.length);
    } else {
      plain = '${digits.substring(0, pointAt)}.${digits.substring(pointAt)}';
    }

    return isNegative ? '-$plain' : plain;
  }
}
