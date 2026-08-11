import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart' as db;
import 'package:my_budget_client/core/mappers/setting_mapper.dart';
import 'package:my_budget_client/domain/entities/settings.dart';

void main() {
  db.Setting rowFromCompanion(db.SettingsCompanion c) => db.Setting(
    key: c.key.value,
    value: c.value.value,
    device: c.device.value,
    modifiedAt: 0,
  );

  test('round trip preserves every field', () {
    const original = Settings(
      key: 'mainCurrency',
      value: 'USD',
      device: 'device-123',
    );

    final roundTripped = rowFromCompanion(original.toCompanion()).toDomain();

    expect(roundTripped, original); // Equatable equality
  });

  test('toDomain defaults a null stored device to "unknown"', () {
    // Hand-built row simulating data written before `device` was populated.
    const row = db.Setting(key: 'mainCurrency', value: 'USD', modifiedAt: 0);

    expect(row.toDomain().device, 'unknown');
  });

  test('list mapper round trips element-wise', () {
    const domainList = [
      Settings(key: 'k1', value: 'v1', device: 'd1'),
      Settings(key: 'k2', value: 'v2', device: 'd2'),
    ];

    final rows = domainList
        .map((d) => rowFromCompanion(d.toCompanion()))
        .toList();
    final roundTripped = rows.toDomainList();

    expect(roundTripped, domainList);
  });
}
