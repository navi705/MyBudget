import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart' as drift;
import 'package:my_budget_client/core/mappers/currency_mapper.dart';
import 'package:my_budget_client/domain/entities/currency.dart';

void main() {
  drift.Currency rowFromCompanion(drift.CurrenciesCompanion c) =>
      drift.Currency(
        name: c.name.value,
        code: c.code.value,
        languageCode: c.languageCode.value,
        type: c.type.value,
        modifiedAt: 0,
      );

  test('round trip preserves every field for a fiat currency', () {
    const original = Currency(
      name: 'US Dollar',
      code: 'USD',
      languageCode: 'en',
      type: TypeCurrency.currency,
    );

    final roundTripped = rowFromCompanion(original.toCompanion()).toDomain();

    expect(roundTripped, original); // Equatable equality
  });

  test('round trip preserves every field for a crypto currency', () {
    const original = Currency(
      name: 'Bitcoin',
      code: 'BTC',
      languageCode: 'en',
      type: TypeCurrency.crypto,
    );

    final roundTripped = rowFromCompanion(original.toCompanion()).toDomain();

    expect(roundTripped.type, TypeCurrency.crypto);
    expect(roundTripped, original);
  });

  test('list mappers round trip element-wise', () {
    const domainList = [
      Currency(
        name: 'US Dollar',
        code: 'USD',
        languageCode: 'en',
        type: TypeCurrency.currency,
      ),
      Currency(
        name: 'Gold',
        code: 'XAU',
        languageCode: 'en',
        type: TypeCurrency.commoditity,
      ),
    ];

    final rows = domainList
        .map((d) => rowFromCompanion(d.toCompanion()))
        .toList();
    final roundTripped = rows.toDomainList();

    expect(roundTripped, domainList);
  });
}
