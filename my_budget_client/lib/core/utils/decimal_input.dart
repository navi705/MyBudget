import 'package:flutter/services.dart';
import 'package:my_budget_client/domain/value_objects/currency_precision.dart';

/// Input formatters for the fields that ask for
/// `TextInputType.numberWithOptions(decimal: true)`.
///
/// That keyboard draws whichever decimal separator the DEVICE locale uses, so
/// a phone set to Russian, German or French offers a comma and no dot at all.
/// Every one of these fields then reads its text back through `double.parse`
/// or `double.tryParse`, which accept only a dot — so "1000,50" came back as
/// "not a valid number" on the very key the app had asked the keyboard for.
///
/// The separator is rewritten as the user types rather than at parse time
/// because the text is read in more places than it is written: validators,
/// `onChanged` handlers, bloc events and the save path all parse the same
/// controller. Normalising once at the source leaves every one of them
/// looking at a dot.
///
/// `replaceAll` is length-preserving, so the caret in [newValue] still points
/// where the user left it.
final List<TextInputFormatter> decimalInputFormatters = [
  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
  TextInputFormatter.withFunction(
    (oldValue, newValue) =>
        newValue.copyWith(text: newValue.text.replaceAll(',', '.')),
  ),
];

/// [decimalInputFormatters] for a field that also has to accept a minus.
///
/// A credit card's balance is negative, which is why those fields ask for a
/// signed keyboard; a filter that allowed only digits and the separator would
/// take the sign back off again.
final List<TextInputFormatter> signedDecimalInputFormatters = [
  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\-]')),
  TextInputFormatter.withFunction(
    (oldValue, newValue) =>
        newValue.copyWith(text: newValue.text.replaceAll(',', '.')),
  ),
];

/// The text a numeric field is seeded with, blank when the value is zero.
///
/// Zero is what these fields hold when there is nothing to say yet: tapping a
/// category tile opens the transaction form on a prototype whose amount is 0,
/// a fee is 0 until one is charged, a new account starts at 0. Rendering that
/// as "0.0" put a character in the field that every entry had to begin by
/// deleting - and the amount field is auto-focused, so the caret was already
/// sitting behind it.
///
/// Blank rather than "0" is what the readers already expect: they parse these
/// back through `double.tryParse(...) ?? 0.0`, so an empty field and a zero
/// mean the same thing to every one of them.
///
/// Only exact zero is blanked. A stored 0.004 is a value someone entered and
/// stays visible.
///
/// [currencyCode] says the value is money in that currency, and the text is
/// then rounded to the currency's minor unit. Balances and amounts are stored
/// as doubles, and a double that came out of a currency conversion or out of
/// an import that rounded through a 32-bit float carries digits the currency
/// cannot hold: the account form was handing the user `158265.09375` to edit
/// in a field that means dinars and paras. Trailing zeros go, so an exact
/// 12.00 still reads as "12", and a value that rounds away to nothing is
/// blank like any other zero. Leave it off for the fields that are not money
/// in a currency - an asset quantity, an exchange rate, an inflation
/// percentage - which are meant to keep every digit they were given.
String decimalFieldText(num? value, {String? currencyCode}) {
  if (value == null || value == 0) return '';
  if (currencyCode == null ||
      !CurrencyPrecision.isMinorUnitCode(currencyCode)) {
    return value.toString();
  }
  final rounded = value.toDouble().toStringAsFixed(
    CurrencyPrecision.decimalsFor(currencyCode),
  );
  final trimmed = rounded.contains('.')
      ? rounded
            .replaceFirst(RegExp(r'0+$'), '')
            .replaceFirst(RegExp(r'\.$'), '')
      : rounded;
  return double.parse(trimmed) == 0 ? '' : trimmed;
}
