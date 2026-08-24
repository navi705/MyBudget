import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/data/api/external_data.dart';

/// The currency-api answer is one object of about 300 rates. Reading it used
/// to throw from inside the loop the moment one of them was not a number, so a
/// single malformed entry cost the whole day for every currency in the file -
/// and the caller then stood today's quote in for a day that had a real rate.
void main() {
  Map<String, double> read(String json) =>
      ExternalData.ratesFrom(jsonDecode(json));

  test('reads the rates', () {
    final rates = read('{"date":"2026-08-22","eur":{"usd":1.09,"gbp":0.85}}');

    expect(rates, {'usd': 1.09, 'gbp': 0.85});
  });

  test('reads a rate quoted as a string', () {
    expect(read('{"eur":{"usd":"1.09"}}'), {'usd': 1.09});
  });

  test('keeps the other rates when one is not a number', () {
    final rates = read('{"eur":{"usd":1.09,"gbp":"n/a","chf":0.94}}');

    expect(rates, {'usd': 1.09, 'chf': 0.94});
  });

  test('drops a rate that cannot convert', () {
    // Zero converts every amount to nothing and a negative flips its sign.
    final rates = read('{"eur":{"usd":1.09,"gbp":0,"chf":-0.94}}');

    expect(rates, {'usd': 1.09});
  });

  test('drops a rate that is not a scalar at all', () {
    expect(read('{"eur":{"usd":1.09,"gbp":{"rate":0.85},"chf":null}}'), {
      'usd': 1.09,
    });
  });

  test('answers empty for an answer with no eur object', () {
    expect(read('{"date":"2026-08-22"}'), isEmpty);
    expect(read('{"eur":"none"}'), isEmpty);
    expect(read('[1,2,3]'), isEmpty);
    expect(read('null'), isEmpty);
  });

  test('answers empty rather than throwing on an empty eur object', () {
    expect(read('{"eur":{}}'), isEmpty);
  });
}
