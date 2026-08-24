import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/value_objects/currency_precision.dart';

/// A monetary amount that is either exact fiat minor units ([FiatAmount]) or a
/// raw fractional value for non-fiat assets ([RawAmount]).
///
/// The type is `sealed` so every consumer must handle both branches — the
/// compiler is the safety net for the money migration: no site can silently
/// treat a crypto holding as fiat cents or vice-versa.
sealed class Amount {
  const Amount();

  /// Build the right variant for a currency [type]/[code] from a major-unit
  /// value (e.g. the legacy stored `double`, or a parsed user input).
  ///
  /// Fiat is scaled to integer minor units with rounding — this is where the
  /// classic `0.1 + 0.2` representation error is eliminated. Non-fiat keeps the
  /// value verbatim.
  factory Amount.fromMajor(double major, TypeCurrency type, String code) {
    if (!CurrencyPrecision.isMinorUnit(type)) return RawAmount(major);
    final decimals = CurrencyPrecision.decimalsFor(code);
    return FiatAmount(toMinorUnits(major, decimals), decimals);
  }

  /// Same as [fromMajor] but resolves fiat/non-fiat from the [code] alone (data
  /// layer). Used to turn a major-unit value — legacy stored double or parsed
  /// input — into the right [Amount] variant.
  factory Amount.fromMajorCode(double major, String code) {
    if (!CurrencyPrecision.isMinorUnitCode(code)) return RawAmount(major);
    final decimals = CurrencyPrecision.decimalsFor(code);
    return FiatAmount(toMinorUnits(major, decimals), decimals);
  }

  /// Decode a value stored in the POST-migration convention: fiat is an integer
  /// minor-unit count (held in the RealColumn as a whole-valued double), non-fiat
  /// is a raw major-unit double.
  factory Amount.decode(double stored, String code) {
    if (!CurrencyPrecision.isMinorUnitCode(code)) return RawAmount(stored);
    return FiatAmount(stored.round(), CurrencyPrecision.decimalsFor(code));
  }

  /// The value to persist under the post-migration convention: fiat stores its
  /// integer minor units, non-fiat stores its raw major-unit double. Kept as a
  /// [double] because the column stays a Drift RealColumn (decision A).
  double encode() => switch (this) {
    FiatAmount(:final minorUnits) => minorUnits.toDouble(),
    RawAmount(:final value) => value,
  };

  /// Value in major units (currency's natural scale), for conversion/display
  /// math where a [double] is acceptable. Storage/summation stays exact via the
  /// [FiatAmount.minorUnits] integer.
  double get major;
}

/// Exact fiat money: an integer count of minor units at a fixed [decimals]
/// scale (2 for most currencies, 0 for JPY/KRW/…, 3 for KWD/BHD/…).
final class FiatAmount extends Amount {
  final int minorUnits;
  final int decimals;

  const FiatAmount(this.minorUnits, this.decimals);

  @override
  double get major => minorUnits / CurrencyPrecision.scaleFor(decimals);

  /// Add another amount of the SAME currency scale. Throws if [decimals]
  /// differ, which would mean mixing currencies — a bug, not a rounding case.
  FiatAmount operator +(FiatAmount other) {
    assert(
      decimals == other.decimals,
      'Cannot add FiatAmounts of different scale ($decimals vs ${other.decimals})',
    );
    return FiatAmount(minorUnits + other.minorUnits, decimals);
  }

  FiatAmount operator -(FiatAmount other) {
    assert(
      decimals == other.decimals,
      'Cannot subtract FiatAmounts of different scale ($decimals vs ${other.decimals})',
    );
    return FiatAmount(minorUnits - other.minorUnits, decimals);
  }

  @override
  bool operator ==(Object other) =>
      other is FiatAmount &&
      other.minorUnits == minorUnits &&
      other.decimals == decimals;

  @override
  int get hashCode => Object.hash(minorUnits, decimals);

  @override
  String toString() => 'FiatAmount($minorUnits, d$decimals)';
}

/// A raw fractional amount for non-fiat assets (crypto, commodities, …), kept
/// as a [double] because integer minor units would overflow at their native
/// precision and holding sizes.
final class RawAmount extends Amount {
  final double value;

  const RawAmount(this.value);

  @override
  double get major => value;

  @override
  bool operator ==(Object other) => other is RawAmount && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'RawAmount($value)';
}

/// Scale a major-unit [major] value to integer minor units at [decimals],
/// rounding half-away-from-zero. Used both for user input and for migrating the
/// legacy stored doubles. `round()` is what removes the float representation
/// error: `toMinorUnits(0.1, 2) + toMinorUnits(0.2, 2) == 30`, exactly.
///
/// Throws on a non-finite [major]. `double.round()` throws for NaN and the
/// infinities on its own, but as an `UnsupportedError` with no value in it,
/// raised from inside whatever transaction was writing - a CSV import failed
/// whole with a message that named neither the row nor the number. There is no
/// safe silent answer here: any integer this returned for NaN would be money
/// the app invented.
int toMinorUnits(double major, int decimals) {
  if (!major.isFinite) {
    throw ArgumentError.value(major, 'major', 'not a finite amount');
  }
  return (major * CurrencyPrecision.scaleFor(decimals)).round();
}

/// Parse a decimal string ("123.45", "0,30", "-7") straight into minor units
/// WITHOUT going through a binary [double], so no representation error can creep
/// in even before rounding. Returns null if [input] is not a valid number.
int? parseMinorUnits(String input, int decimals) {
  var s = input.trim().replaceAll(',', '.');
  if (s.isEmpty) return null;

  var negative = false;
  if (s.startsWith('-')) {
    negative = true;
    s = s.substring(1);
  } else if (s.startsWith('+')) {
    s = s.substring(1);
  }

  final dot = s.indexOf('.');
  final intPart = dot < 0 ? s : s.substring(0, dot);
  var fracPart = dot < 0 ? '' : s.substring(dot + 1);

  if (s.indexOf('.') != s.lastIndexOf('.')) return null; // more than one dot
  if (intPart.isEmpty && fracPart.isEmpty) return null;
  if (!_isDigits(intPart) || !_isDigits(fracPart)) return null;

  // Round the fractional part to [decimals] places (half-up on the next digit).
  var roundUp = false;
  if (fracPart.length > decimals) {
    roundUp = fracPart.codeUnitAt(decimals) >= _char5;
    fracPart = fracPart.substring(0, decimals);
  }
  fracPart = fracPart.padRight(decimals, '0');

  final digits = '${intPart.isEmpty ? '0' : intPart}$fracPart';
  var units = int.tryParse(digits);
  if (units == null) return null;
  if (roundUp) units += 1;
  return negative ? -units : units;
}

const int _char5 = 0x35; // '5'

bool _isDigits(String s) {
  for (var i = 0; i < s.length; i++) {
    final c = s.codeUnitAt(i);
    if (c < 0x30 || c > 0x39) return false;
  }
  return true;
}
