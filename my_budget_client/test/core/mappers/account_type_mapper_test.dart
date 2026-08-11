import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart' as drift;
import 'package:my_budget_client/core/mappers/account_type_mapper.dart';
import 'package:my_budget_client/domain/entities/account_type.dart';

void main() {
  drift.AccountType rowFromCompanion(drift.AccountTypesCompanion c) =>
      drift.AccountType(
        id: c.id.value,
        name: c.name.value,
        languageCode: c.languageCode.value,
        modifiedAt: 0,
        isDeleted: false,
      );

  test('round trip preserves every field', () {
    const original = AccountType(
      id: 'general',
      name: 'General',
      languageCode: 'en',
    );

    final roundTripped = rowFromCompanion(original.toCompanion()).toDomain();

    expect(roundTripped, original); // Equatable equality
  });

  test('list mapper round trips element-wise', () {
    const domainList = [
      AccountType(id: 'general', name: 'General', languageCode: 'en'),
      AccountType(id: 'savings', name: 'Savings', languageCode: 'en'),
    ];

    final rows = domainList
        .map((d) => rowFromCompanion(d.toCompanion()))
        .toList();
    final roundTripped = rows.toDomainList();

    expect(roundTripped, domainList);
  });
}
