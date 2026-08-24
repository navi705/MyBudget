import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/data/models/world_bank_inflation_model.dart';

/// The World Bank answer is `[header, rows]`, and the shapes it takes when
/// there is nothing to return are not the shape the reader used to assume.
void main() {
  List<InflationDataPoint> read(String json) =>
      WorldBankInflationResponse.fromJson(jsonDecode(json)).data;

  test('reads the series', () {
    final points = read(
      '[{"page":1},'
      '[{"date":"2025","value":4.2},{"date":"2024","value":7.8}]]',
    );

    expect(points.map((p) => p.date), ['2025', '2024']);
    expect(points.map((p) => p.value), [4.2, 7.8]);
  });

  test('reads an integer reading', () {
    expect(read('[{"page":1},[{"date":"2025","value":4}]]').single.value, 4.0);
  });

  test('keeps a year with no reading', () {
    // The series has gaps, and a gap is an answer.
    final points = read('[{"page":1},[{"date":"2025","value":null}]]');

    expect(points.single.date, '2025');
    expect(points.single.value, isNull);
  });

  test('answers empty for a range the API has no series for', () {
    // What the API actually replies with, rather than an empty list.
    expect(read('[{"page":0,"total":0},null]'), isEmpty);
  });

  test('answers empty for an unknown country or indicator', () {
    expect(
      read('[{"message":[{"id":"120","key":"Invalid value"}]}]'),
      isEmpty,
    );
  });

  test('answers empty for an answer that is not a list at all', () {
    expect(read('{"message":"nope"}'), isEmpty);
    expect(read('null'), isEmpty);
  });

  test('skips a row it cannot read and keeps the rest', () {
    final points = read(
      '[{"page":1},['
      '{"date":"2025","value":4.2},'
      'null,'
      '{"value":9.9},'
      '{"date":2024,"value":1.1},'
      '{"date":"2023","value":"7.8"},'
      '{"date":"2022","value":3.3}]]',
    );

    expect(points.map((p) => p.date), ['2025', '2022']);
  });
}
