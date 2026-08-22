import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/utils/rate_formatter.dart';

void main() {
  group('forInput', () {
    test('a rate far below one is spelled out rather than exponentiated', () {
      // What the MZM -> XAUT pair actually produced. `toString()` gave
      // `3.4222877778838255e-9`, which the rate field's own input formatter
      // strips down to `3.42228777788382559` on the first keystroke.
      expect(
        RateFormatter.forInput(3.4222877778838255e-9),
        '0.0000000034222877778838253',
      );
    });

    test('the exponent form never appears', () {
      for (final rate in [1e-7, 1e-12, 5.5e-20, 1e21, 3.25e30]) {
        expect(RateFormatter.forInput(rate), isNot(contains('e')));
      }
    });

    test('every digit survives the round trip', () {
      for (final rate in [
        3.4222877778838255e-9,
        1.2345678901234567e-11,
        0.925,
        117.0,
        1e21,
        5.5e-20,
      ]) {
        expect(double.parse(RateFormatter.forInput(rate)), rate);
      }
    });

    test('a rate that needs no exponent is left as it is', () {
      expect(RateFormatter.forInput(1.5), '1.5');
      expect(RateFormatter.forInput(117.0), '117.0');
      expect(RateFormatter.forInput(0.000925), '0.000925');
    });

    test('a negative value keeps its sign', () {
      expect(RateFormatter.forInput(-1.5e-9), '-0.0000000015');
    });

    test('the non-finite values are handled rather than thrown on', () {
      expect(RateFormatter.forInput(double.nan), '');
      expect(RateFormatter.forInput(double.infinity), '');
    });
  });

  group('short', () {
    test('a tiny rate keeps six significant digits instead of reading 0.0000',
        () {
      expect(RateFormatter.short(3.4222877778838255e-9), '0.00000000342229');
      expect(RateFormatter.short(1.1e-9), isNot(RateFormatter.short(2.2e-9)));
    });

    test('an everyday rate is not padded with zeros', () {
      expect(RateFormatter.short(1.5), '1.5');
      expect(RateFormatter.short(117.0), '117');
      expect(RateFormatter.short(0.925), '0.925');
    });

    test('a large rate is not given decimals it has no digits for', () {
      expect(RateFormatter.short(1234567.0), '1234567');
    });

    test('zero and the non-finite values are handled rather than thrown on', () {
      expect(RateFormatter.short(0), '0');
      expect(RateFormatter.short(double.nan), '');
      expect(RateFormatter.short(double.infinity), '');
    });
  });
}
