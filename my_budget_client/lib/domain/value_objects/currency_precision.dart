import 'package:my_budget_client/domain/entities/currency.dart';

/// Minor-unit precision rules per currency, following ISO 4217.
///
/// Only fiat currencies ([TypeCurrency.currency]) are represented as integer
/// minor units (cents / fils / whole units). Crypto, commodities and every
/// other asset type keep a raw fractional [double] amount, because their native
/// precision (e.g. ETH's 18 decimals) and holding sizes (e.g. trillions of a
/// meme token) overflow a 64-bit — and especially a 53-bit web — integer.
class CurrencyPrecision {
  const CurrencyPrecision._();

  /// Powers of ten for the supported decimal counts (0..3). Avoids `math.pow`,
  /// which returns a [double] and would reintroduce floating-point error.
  static const List<int> _pow10 = [1, 10, 100, 1000];

  /// ISO 4217 fiat currencies with 0 minor-unit decimals.
  static const Set<String> zeroDecimal = {
    'BIF', 'CLP', 'DJF', 'GNF', 'ISK', 'JPY', 'KMF', 'KRW', 'PYG', 'RWF',
    'UGX', 'VND', 'VUV', 'XAF', 'XOF', 'XPF',
  };

  /// ISO 4217 fiat currencies with 3 minor-unit decimals.
  static const Set<String> threeDecimal = {
    'BHD', 'IQD', 'JOD', 'KWD', 'LYD', 'OMR', 'TND',
  };

  /// Whether amounts in a currency of [type] are stored as integer minor units
  /// (true, fiat only) or as a raw fractional double (false — crypto,
  /// commodities, stocks, real assets, obligations, other).
  static bool isMinorUnit(TypeCurrency type) => type == TypeCurrency.currency;

  /// Minor-unit decimal places for a fiat currency [code]. Defaults to 2.
  /// Only meaningful when the currency's type [isMinorUnit].
  static int decimalsFor(String code) {
    final c = code.toUpperCase();
    if (zeroDecimal.contains(c)) return 0;
    if (threeDecimal.contains(c)) return 3;
    return 2;
  }

  /// 10^[decimals]. Only 0..3 are valid ISO 4217 exponents in this app.
  static int scaleFor(int decimals) => _pow10[decimals];
}
