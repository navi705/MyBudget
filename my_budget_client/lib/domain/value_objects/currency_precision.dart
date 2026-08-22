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
    'BIF',
    'CLP',
    'DJF',
    'GNF',
    'ISK',
    'JPY',
    'KMF',
    'KRW',
    'PYG',
    'RWF',
    'UGX',
    'VND',
    'VUV',
    'XAF',
    'XOF',
    'XPF',
  };

  /// ISO 4217 fiat currencies with 3 minor-unit decimals.
  static const Set<String> threeDecimal = {
    'BHD',
    'IQD',
    'JOD',
    'KWD',
    'LYD',
    'OMR',
    'TND',
  };

  /// Codes that are NOT integer-minor-unit money: the seeded crypto (133) and
  /// commodity (4) currencies. Their native precision (BTC 8, ETH 18 decimals)
  /// and holding sizes overflow integer minor units, so they stay a raw double.
  ///
  /// Kept in sync with `lib/data/seed_data/currencies_data.dart` (type crypto /
  /// commoditity); a test cross-checks the count. A user-defined currency not in
  /// this set defaults to fiat (integer minor units, 2 decimals).
  static const Set<String> nonFiat = {
    // Commodities (troy-ounce priced, fractional holdings)
    'XAU', 'XAG', 'XPT', 'XPD',
    // Crypto
    '1INCH', 'AAVE', 'AGIX', 'ADA', 'AKT', 'ALGO', 'AMP', 'APE', 'APT', 'AR',
    'ARB', 'ATOM', 'AVAX', 'AXS', 'BAKE', 'BAT', 'BCH', 'BNB', 'BSV', 'BSW',
    'BTC', 'BTCB', 'BTG', 'BTT', 'BUSD', 'CAKE', 'CELO', 'CFX', 'CHZ', 'COMP',
    'CRO', 'CRV', 'CSPR', 'CVX', 'DAI', 'DASH', 'DCR', 'DFI', 'DOGE', 'DOT',
    'DYDX', 'EGLD', 'ENJ', 'EOS', 'ETC', 'ETH', 'EURC', 'FEI', 'FIL', 'FLOW',
    'FLR', 'FRAX', 'FTT', 'GALA', 'GMX', 'GNO', 'GRT', 'GT', 'GUSD', 'HBAR',
    'HNT', 'HOT', 'HT', 'ICP', 'IMX', 'INJ', 'KAS', 'KAVA', 'KCS', 'KDA',
    'KNC', 'KSM', 'LDO', 'LEO', 'LINK', 'LRC', 'LTC', 'LUNA', 'LUNC', 'MANA',
    'MBX', 'MINA', 'MKR', 'NEAR', 'NEO', 'NEXO', 'NFT', 'OKB', 'ONE', 'OP',
    'ORDI', 'PAXG', 'PEPE', 'PI', 'POL', 'QNT', 'QTUM', 'RPL', 'RUNE', 'RVN',
    'SAND', 'SHIB', 'SNX', 'SOL', 'STX', 'SUI', 'THETA', 'TON', 'TRX', 'TUSD',
    'TWT', 'UNI', 'USDC', 'USDD', 'USDP', 'USDT', 'VET', 'WAVES', 'WEMIX',
    'WOO', 'XAUT', 'XBT', 'XCG', 'XCH', 'XDC', 'XEC', 'XEM', 'XLM', 'XMR',
    'XRP', 'XTZ', 'ZEC', 'ZIL',
  };

  /// Whether amounts in a currency of [type] are stored as integer minor units
  /// (true, fiat only) or as a raw fractional double (false — crypto,
  /// commodities, stocks, real assets, obligations, other).
  static bool isMinorUnit(TypeCurrency type) => type == TypeCurrency.currency;

  /// Code-based counterpart of [isMinorUnit], for the data layer where only the
  /// currency code is at hand. Unknown codes default to fiat (minor units).
  static bool isMinorUnitCode(String code) =>
      !nonFiat.contains(code.toUpperCase());

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
