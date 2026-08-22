// What counts as a rate a conversion can actually use.
//
// `double.tryParse` accepts '0', '-1', 'NaN' and 'Infinity', and every one of
// them parses into something the arithmetic downstream will happily multiply
// by. This is the single test that says which of them are rates.
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/utils/exchange_rate_validation.dart';

void main() {
  test('an ordinary positive rate is usable', () {
    expect(isUsableExchangeRate(0.9), isTrue);
    expect(isUsableExchangeRate(1), isTrue);
    expect(isUsableExchangeRate(1234.5), isTrue);
  });

  test('a very small positive rate is still usable', () {
    // Currencies really do trade at these: 1 IDR is about 0.00006 EUR.
    expect(isUsableExchangeRate(0.00006), isTrue);
    expect(isUsableExchangeRate(double.minPositive), isTrue);
  });

  test('zero is not a rate', () {
    // It converts every amount to nothing, which on a transfer means the money
    // leaves one account and arrives in neither.
    expect(isUsableExchangeRate(0), isFalse);
    expect(isUsableExchangeRate(-0.0), isFalse);
  });

  test('a negative rate is not a rate', () {
    // It converts with the sign flipped, so both accounts lose.
    expect(isUsableExchangeRate(-1), isFalse);
    expect(isUsableExchangeRate(-0.9), isFalse);
  });

  test('the non-finite results of an earlier division are not rates', () {
    expect(isUsableExchangeRate(double.nan), isFalse);
    expect(isUsableExchangeRate(double.infinity), isFalse);
    expect(isUsableExchangeRate(double.negativeInfinity), isFalse);
  });

  test('no rate at all is not a usable one', () {
    expect(isUsableExchangeRate(null), isFalse);
  });
}
