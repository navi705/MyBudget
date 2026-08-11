import 'package:intl/intl.dart';
import 'package:my_budget_client/domain/value_objects/currency_precision.dart';

/// Central money formatter. Fiat amounts use the currency's ISO minor-unit
/// decimals (0 for JPY/…, 3 for KWD/…, else 2); crypto/commodity keep a dynamic
/// precision that shows more places for very small holdings. Thousands are
/// separated by spaces, matching the app's existing convention.
class MoneyFormatter {
  const MoneyFormatter._();

  /// Format [value] (already in [currencyCode]'s units) as a grouped number
  /// string, without the currency symbol. Set [signed] to prefix a '+' for
  /// positive values.
  static String format(
    double value,
    String currencyCode, {
    bool signed = false,
  }) {
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
