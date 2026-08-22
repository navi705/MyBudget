import 'package:intl/intl.dart';
import 'package:my_budget_client/domain/value_objects/currency_precision.dart';

/// Central money formatter. Fiat amounts use the currency's ISO minor-unit
/// decimals (0 for JPY/…, 3 for KWD/…, else 2); crypto/commodity keep a dynamic
/// precision that shows more places for very small holdings. Thousands are
/// separated by spaces, matching the app's existing convention.
///
/// ## Why the separator is U+00A0 and not a plain space
///
/// The app ships two right-to-left locales (`ar`, `ur`). A plain U+0020 is
/// bidi class WS (whitespace), which *terminates* a number run: under an RTL
/// paragraph the Unicode bidi algorithm then lays the surviving groups out
/// right-to-left, so `1 234.56` was painted as `234.56 1` — a finance app
/// stating a different number than the one it holds. U+00A0 NO-BREAK SPACE is
/// bidi class CS (common separator), which keeps the digits in one run, and is
/// the correct typographic group separator anyway. It renders identically to a
/// space in every locale, so `en`/`ru` are unchanged.
///
/// Grouping alone is not enough once an amount is *concatenated* into
/// surrounding text — a currency code, a symbol, or a translated sentence.
/// There the neighbouring letters decide the run's direction and the amount
/// can still be reordered relative to them. [isolate], [formatIsolated] and
/// [formatWithSymbol] wrap the result in U+2066 LEFT-TO-RIGHT ISOLATE …
/// U+2069 POP DIRECTIONAL ISOLATE so the amount is a single opaque LTR chunk
/// whatever it is embedded in. Every caller that puts an amount inside a
/// larger string should use one of those rather than [format].
class MoneyFormatter {
  const MoneyFormatter._();

  /// Rendered in place of a number whenever the amount is not a real figure.
  static const String unknownPlaceholder = '—';

  /// U+00A0 NO-BREAK SPACE — the thousands separator, and the joiner between
  /// an amount and its symbol. See the class doc for why it is not U+0020.
  static const String groupSeparator = '\u00A0';

  /// U+2066 LEFT-TO-RIGHT ISOLATE.
  static const String _lri = '\u2066';

  /// U+2069 POP DIRECTIONAL ISOLATE.
  static const String _pdi = '\u2069';

  /// Wrap [text] so the bidi algorithm treats it as one left-to-right chunk,
  /// neutral to whatever surrounds it. Use on any number that is embedded in
  /// localised prose or joined to a symbol.
  static String isolate(String text) => '$_lri$text$_pdi';

  /// True when [value] is not a real amount — NaN or either infinity.
  ///
  /// The conversion engines (`FinanceCalculator`, `CurrencyConverter`) return
  /// `double.nan` for a figure that genuinely could not be priced in the
  /// target currency. Callers that want to style or omit such a figure rather
  /// than print the placeholder can branch on this.
  static bool isUnknown(double value) => !value.isFinite;

  /// Format [value] (already in [currencyCode]'s units) as a grouped number
  /// string, without the currency symbol. Set [signed] to prefix a '+' for
  /// positive values.
  ///
  /// Non-finite values render as [unknownPlaceholder] ('—'). A NaN reaching
  /// here is not a crash — it is an amount that could not be converted to the
  /// requested currency. `NumberFormat` would print the literal text `NaN` in
  /// the middle of a money column, which reads as a broken app; a dash reads
  /// as "unknown", which is exactly what it is.
  static String format(
    double value,
    String currencyCode, {
    bool signed = false,
  }) {
    if (!value.isFinite) return unknownPlaceholder;

    final pattern = _patternFor(currencyCode, value);
    final text = NumberFormat(
      pattern,
      'en_US',
    ).format(value).replaceAll(',', groupSeparator);
    final sign = signed && value > 0 ? '+' : '';
    return '$sign$text';
  }

  /// [format]'s output for anything under [_compactFrom], and a compacted
  /// figure ("110K") above it.
  ///
  /// For the calendar cells, which are a seventh of the screen wide and hold
  /// two amounts each. They render inside a `FittedBox`, so a long value does
  /// not overflow - it shrinks, and a six-figure total shrank so far past the
  /// neighbouring cells that it was no longer readable. Losing the last digits
  /// of a number that big costs nothing at a glance; losing all of them does.
  static String formatCompact(double value, String currencyCode) {
    if (!value.isFinite) return unknownPlaceholder;
    if (value.abs() < _compactFrom) return format(value, currencyCode);
    return NumberFormat.compact(locale: 'en_US').format(value);
  }

  /// Magnitude at which [formatCompact] stops printing every digit. Five
  /// figures plus a group separator, a sign and a symbol is about as much as a
  /// calendar cell can show before the text starts shrinking.
  static const double _compactFrom = 10000;

  /// [format]'s output, bidi-isolated. Use whenever the amount is dropped into
  /// a localised sentence (`l10n.currentPriceLabel(...)`) rather than standing
  /// alone in its own `Text`.
  static String formatIsolated(
    double value,
    String currencyCode, {
    bool signed = false,
  }) => isolate(format(value, currencyCode, signed: signed));

  /// The amount, a no-break space and [symbol] — the app's usual money line —
  /// as one bidi-isolated chunk.
  ///
  /// [prefix] carries a direction glyph (see `MoneyColors.signGlyph`) inside
  /// the isolate so it stays welded to the digits; it is dropped for a
  /// non-finite value, where there is no number for it to qualify.
  static String formatWithSymbol(
    double value,
    String currencyCode,
    String symbol, {
    bool signed = false,
    String prefix = '',
  }) {
    final effectivePrefix = value.isFinite ? prefix : '';
    final amount = format(value, currencyCode, signed: signed);
    return isolate('$effectivePrefix$amount$groupSeparator$symbol');
  }

  /// Number of fraction digits [format] will use for [currencyCode] at [value].
  static int decimalsFor(String currencyCode, [double value = 0]) {
    if (CurrencyPrecision.isMinorUnitCode(currencyCode)) {
      return CurrencyPrecision.decimalsFor(currencyCode);
    }
    return value.abs() < 0.01 && value != 0 ? 6 : 2;
  }

  static String _patternFor(String code, double value) {
    if (CurrencyPrecision.isMinorUnitCode(code)) {
      final d = CurrencyPrecision.decimalsFor(code);
      return d == 0 ? '#,##0' : '#,##0.${'0' * d}';
    }
    // Crypto / commodity: extra places for sub-cent values, else 2.
    return value.abs() < 0.01 && value != 0 ? '#,##0.00####' : '#,##0.00';
  }
}
