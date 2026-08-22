import 'package:flutter/services.dart';

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
