// Schema v10 made `inflation_rates.country` NOT NULL and moved the worldwide
// series onto the `globalInflationCountry` sentinel. Two inputs still carry the
// old null spelling and cannot be migrated in place: a JSON backup taken before
// v10, and a peer or server row written by a device still on v9.
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/services/data_import_service.dart';

void main() {
  group('withGlobalInflationCountry', () {
    test('names the worldwide series where a pre-v10 backup left it null', () {
      // fromJson would throw on the null, and the restore is one transaction -
      // a single such row would abort every other table with it.
      final row = withGlobalInflationCountry({
        'date': '2025-03-01T00:00:00.000',
        'percent': 2.5,
        'country': null,
        'preset': 1,
      });

      expect(row['country'], globalInflationCountry);
      expect(row['percent'], 2.5, reason: 'the rest of the row is untouched');
    });

    test('treats an empty country the same as a missing one', () {
      expect(withGlobalInflationCountry({'country': ''})['country'],
          globalInflationCountry);
    });

    test('fills in a country the backup omitted entirely', () {
      expect(withGlobalInflationCountry({'percent': 1.0})['country'],
          globalInflationCountry);
    });

    test('leaves a real country alone', () {
      expect(withGlobalInflationCountry({'country': 'RS'})['country'], 'RS');
    });

    test('does not mutate the map it was handed', () {
      final original = <String, dynamic>{'country': null};
      withGlobalInflationCountry(original);
      expect(original['country'], isNull);
    });
  });
}
