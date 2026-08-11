import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/mappers/asset_data_mapper.dart';
import 'package:my_budget_client/domain/entities/asset_data.dart';

void main() {
  AssetEntry rowFromCompanion(AssetEntriesCompanion c) => AssetEntry(
    id: c.id.value,
    assetId: c.assetId.value,
    name: c.name.value,
    date: c.date.value,
    value: c.value.value,
    quantity: c.quantity.value,
    assetType: c.assetType.value,
    description: c.description.value,
    currencyCode: c.currencyCode.value,
    accountId: c.accountId.value,
    source: c.source.value,
    preset: c.preset.value,
    modifiedAt: 0,
    isDeleted: false,
  );

  test('full round trip preserves every field, including all-nulls', () {
    final original = AssetDataDomain(
      id: 'entry1',
      assetId: 'gold',
      name: 'Gold Price',
      date: DateTime(2024, 5, 1),
      value: 1987.65,
      quantity: 2.5,
      assetType: null,
      description: null,
      currency: 'EUR',
      accountId: null,
      source: 'manual',
      preset: 2,
    );

    final roundTripped = rowFromCompanion(original.toCompanion()).toDomain();

    expect(roundTripped.id, original.id);
    expect(roundTripped.assetId, original.assetId);
    expect(roundTripped.name, original.name);
    expect(roundTripped.date, original.date);
    expect(roundTripped.value, original.value);
    expect(roundTripped.quantity, original.quantity);
    expect(roundTripped.assetType, isNull);
    expect(roundTripped.description, isNull);
    expect(roundTripped.currency, original.currency);
    expect(roundTripped.accountId, isNull);
    expect(roundTripped.source, original.source);
    expect(roundTripped.preset, original.preset);
  });

  test('full round trip preserves populated optional fields', () {
    final original = AssetDataDomain(
      id: 'entry2',
      assetId: 'gold',
      name: 'Gold Price',
      date: DateTime(2024, 5, 2),
      value: 2000.0,
      quantity: 1.0,
      assetType: 'commodity',
      description: 'Manual entry',
      currency: 'USD',
      accountId: 'acc1',
      source: 'api',
      preset: 1,
    );

    final roundTripped = rowFromCompanion(original.toCompanion()).toDomain();

    expect(roundTripped.assetType, 'commodity');
    expect(roundTripped.description, 'Manual entry');
    expect(roundTripped.accountId, 'acc1');
  });

  test('null domain id becomes an absent companion id', () {
    final original = AssetDataDomain(
      assetId: 'gold',
      name: 'Gold Price',
      date: DateTime(2024, 5, 1),
      value: 100.0,
      source: 'manual',
    );

    expect(original.toCompanion().id.present, isFalse);
  });
}
