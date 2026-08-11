import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart' as drift;
import 'package:my_budget_client/core/mappers/currency_designation_mapper.dart';
import 'package:my_budget_client/domain/entities/currency_designation.dart';

void main() {
  drift.CurrencyDesignation rowFromCompanion(
    drift.CurrencyDesignationsCompanion c,
  ) => drift.CurrencyDesignation(
    id: c.id.value,
    value: c.value.value,
    currencyCode: c.currencyCode.value,
    modifiedAt: 0,
    isDeleted: false,
  );

  test('round trip preserves every field', () {
    const original = CurrencyDesignation(
      id: 'desig1',
      value: r'$',
      currencyCode: 'USD',
    );

    final roundTripped = rowFromCompanion(original.toCompanion()).toDomain();

    expect(roundTripped, original); // Equatable equality
  });

  test('list mappers round trip element-wise', () {
    const domainList = [
      CurrencyDesignation(id: 'd1', value: r'$', currencyCode: 'USD'),
      CurrencyDesignation(id: 'd2', value: '€', currencyCode: 'EUR'),
    ];

    final rows = domainList
        .map((d) => rowFromCompanion(d.toCompanion()))
        .toList();
    final roundTripped = rows.toDomainList();

    expect(roundTripped, domainList);
  });
}
