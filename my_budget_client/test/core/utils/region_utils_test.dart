import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/utils/region_utils.dart';

void main() {
  group('RegionUtils Tests', () {
    test('mapAlpha2ToAlpha3 should map correctly', () {
      expect(RegionUtils.mapAlpha2ToAlpha3('RS'), 'SRB');
      expect(RegionUtils.mapAlpha2ToAlpha3('US'), 'USA');
      expect(RegionUtils.mapAlpha2ToAlpha3('RU'), 'RUS');
      expect(RegionUtils.mapAlpha2ToAlpha3('me'), 'MNE');
    });

    test('mapAlpha2ToAlpha3 should return null for unknown codes', () {
      expect(RegionUtils.mapAlpha2ToAlpha3('XX'), null);
    });

    test('mapAlpha2ToAlpha3 should handle lowercase', () {
      expect(RegionUtils.mapAlpha2ToAlpha3('rs'), 'SRB');
    });
  });
}
