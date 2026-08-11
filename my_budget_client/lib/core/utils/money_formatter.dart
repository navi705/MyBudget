import 'package:intl/intl.dart';
import 'package:my_budget_client/domain/value_objects/currency_precision.dart';

/// Central money formatter. Fiat amounts use the currency's ISO minor-unit
/// decimals (0 for JPY/…, 3 for KWD/…, else 2); crypto/commodity keep a dynamic
/// precision that shows more places for very small holdings. Thousands are
/// separated by spaces, matching the app's existing convention.
class MoneyFormatter {
  const MoneyFormatter._();

  /// Rendered in place of a number whenever the amount is not a real figure.
  static const String unknownPlaceholder = '—';

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
    final text = NumberFormat(pattern, 'en_US').format(value).replaceAll(
          ',',
          ' ',
        );
    final sign = signed && value > 0 ? '+' : '';
    return '$sign$text';
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
