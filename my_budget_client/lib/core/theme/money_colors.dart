import 'package:flutter/material.dart';

/// Semantic colours for money direction.
///
/// Money is the one part of the palette the product owns. The user picks the
/// seed colour, so a hardcoded `Colors.green` can end up indistinguishable
/// from the primary — and a raw `Colors.red` fails contrast on several of the
/// shipped dark surfaces. These hues are fixed per brightness, chosen to clear
/// 4.5:1 against the surfaces both themes generate, and are always paired with
/// [signGlyph] so direction survives greyscale and red-green colourblindness.
@immutable
class MoneyColors {
  const MoneyColors({
    required this.inflow,
    required this.outflow,
    required this.neutral,
    required this.unconvertible,
  });

  /// Money coming in: income, a transfer's destination, a positive balance.
  final Color inflow;

  /// Money going out: an expense, a transfer's source, a negative balance.
  final Color outflow;

  /// A figure with no direction — a count, a rate, a zero balance.
  final Color neutral;

  /// A figure the app cannot fully vouch for, because a rate is missing.
  /// Rendered the same way everywhere it appears, per the dashboard's
  /// unconvertible notice.
  final Color unconvertible;

  static const MoneyColors _light = MoneyColors(
    inflow: Color(0xFF1B7F4C),
    outflow: Color(0xFFB3261E),
    neutral: Color(0xFF49454F),
    unconvertible: Color(0xFF6F6779),
  );

  static const MoneyColors _dark = MoneyColors(
    inflow: Color(0xFF6FD69B),
    outflow: Color(0xFFF2B8B5),
    neutral: Color(0xFFCAC4D0),
    unconvertible: Color(0xFFA8A2B3),
  );

  /// Resolve against the active theme's brightness.
  static MoneyColors of(BuildContext context) =>
      forBrightness(Theme.of(context).brightness);

  static MoneyColors forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? _dark : _light;

  /// The colour for [amount]: [outflow] when negative, [inflow] when positive,
  /// [neutral] at exactly zero, [unconvertible] when the amount is not a real
  /// figure (NaN — a value that could not be priced in the target currency).
  Color forAmount(double amount) {
    if (!amount.isFinite) return unconvertible;
    if (amount > 0) return inflow;
    if (amount < 0) return outflow;
    return neutral;
  }

  /// Colour by explicit direction, for callers that already know the sign from
  /// the transaction type rather than from the number.
  Color forDirection({required bool isIncome}) => isIncome ? inflow : outflow;

  /// The glyph that carries direction without colour. Uses U+2212 MINUS SIGN
  /// rather than a hyphen so it aligns with the digits in a money column.
  static String signGlyph({required bool isIncome}) =>
      isIncome ? '+' : '\u2212';
}
