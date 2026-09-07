// The shared formatters behind every decimal field.
//
// The widget test in test/presentation/widgets/decimal_comma_input_test.dart
// proves one field end to end; this pins the rules the other eighteen share,
// including the one difference between the two lists.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/utils/decimal_input.dart';

/// Types [input] into an empty field through [formatters], the way the engine
/// feeds an edit through them in order.
String typed(List<TextInputFormatter> formatters, String input) {
  var value = TextEditingValue.empty;
  for (final char in input.split('')) {
    final next = TextEditingValue(
      text: value.text + char,
      selection: TextSelection.collapsed(offset: value.text.length + 1),
    );
    var result = next;
    for (final formatter in formatters) {
      result = formatter.formatEditUpdate(value, result);
    }
    value = result;
  }
  return value.text;
}

void main() {
  group('decimalInputFormatters', () {
    test('a comma becomes the dot every parser in the app expects', () {
      expect(typed(decimalInputFormatters, '1000,50'), '1000.50');
    });

    test('a dot is left alone', () {
      expect(typed(decimalInputFormatters, '1000.50'), '1000.50');
    });

    test('letters and currency symbols never reach the field', () {
      expect(typed(decimalInputFormatters, r'1a2$3 4'), '1234');
    });

    test(
      'a minus is rejected, because these fields have no negative value',
      () {
        expect(typed(decimalInputFormatters, '-40'), '40');
      },
    );

    test('the caret stays where the user left it', () {
      // The rewrite is length-preserving, so a selection into the old text is
      // still valid in the new one. A formatter that changed the length here
      // would drop the caret to the start on every comma.
      const old = TextEditingValue(text: '10');
      const edit = TextEditingValue(
        text: '10,',
        selection: TextSelection.collapsed(offset: 3),
      );
      var result = edit;
      for (final formatter in decimalInputFormatters) {
        result = formatter.formatEditUpdate(old, result);
      }

      expect(result.text, '10.');
      expect(result.selection.baseOffset, 3);
    });
  });

  group('signedDecimalInputFormatters', () {
    test('keeps the minus a credit card balance needs', () {
      expect(typed(signedDecimalInputFormatters, '-40,25'), '-40.25');
    });

    test('still drops everything that is not a number', () {
      expect(typed(signedDecimalInputFormatters, r'-1a2 EUR'), '-12');
    });

    test('normalises the comma the same way the unsigned list does', () {
      expect(typed(signedDecimalInputFormatters, '0,3'), '0.3');
    });
  });

  group('decimalFieldText rounds money to its currency', () {
    test('a balance carrying float noise is offered at cents', () {
      // What the account form used to put in the field: a salary imported
      // through a 32-bit float, expanded to every digit the double holds.
      expect(decimalFieldText(158265.09375, currencyCode: 'RSD'), '158265.09');
    });

    test('trailing zeros go so an exact amount reads plainly', () {
      expect(decimalFieldText(12.0, currencyCode: 'EUR'), '12');
      expect(decimalFieldText(12.5, currencyCode: 'EUR'), '12.5');
    });

    test('a zero-decimal currency is offered whole', () {
      expect(decimalFieldText(1200.4, currencyCode: 'JPY'), '1200');
    });

    test('a three-decimal currency keeps its third digit', () {
      expect(decimalFieldText(12.3456, currencyCode: 'KWD'), '12.346');
    });

    test('an amount that rounds away is blank like any other zero', () {
      // The readers all parse back through `?? 0.0`, so blank and zero mean
      // the same thing to them - and 0.004 is not an amount in euros.
      expect(decimalFieldText(0.004, currencyCode: 'EUR'), '');
    });

    test('a crypto holding keeps every digit it was given', () {
      expect(decimalFieldText(0.00012345, currencyCode: 'BTC'), '0.00012345');
    });

    test('without a currency nothing is rounded', () {
      // The exchange rate, asset quantity and inflation fields pass no code.
      expect(decimalFieldText(0.0123456789), '0.0123456789');
    });

    test('zero and null are still blank', () {
      expect(decimalFieldText(null, currencyCode: 'EUR'), '');
      expect(decimalFieldText(0, currencyCode: 'EUR'), '');
    });
  });
}
