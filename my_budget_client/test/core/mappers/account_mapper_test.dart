import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart' as drift;
import 'package:my_budget_client/core/mappers/account_mapper.dart';
import 'package:my_budget_client/domain/entities/account.dart';

/// domain -> companion -> drift row -> domain round trips for AccountMapper,
/// with emphasis on the dual money representation (balance / balanceMinor).
void main() {
  Account account({
    String? id = 'acc1',
    String? description,
    double balance = 123.45,
    int? balanceMinor,
    String currencyCode = 'EUR',
    String? styleId,
    String? country,
    String? assetId,
    double assetQuantity = 0.0,
    String? feeStructure,
  }) => Account(
    id: id,
    name: 'Checking',
    description: description,
    balance: balance,
    balanceMinor: balanceMinor,
    currencyCode: currencyCode,
    currencyDesignationId: 'code',
    styleId: styleId,
    accountTypeId: 'general',
    creationDate: DateTime(2024, 1, 1),
    country: country,
    assetId: assetId,
    assetQuantity: assetQuantity,
    feeStructure: feeStructure,
  );

  drift.DbAccount rowFromCompanion(
    drift.AccountsCompanion c,
  ) => drift.DbAccount(
    id: c.id.value,
    name: c.name.value,
    description: c.description.value,
    balance: c.balance.value,
    balanceMinor: c.balanceMinor.value,
    // The companion the mapper builds carries no anchor: the DAO derives it
    // from the balance after the write, so the mapper has nothing to say here.
    openingBalance: 0.0,
    currencyCode: c.currencyCode.value,
    currencyDesignationId: c.currencyDesignationId.value,
    styleId: c.styleId.value,
    accountTypeId: c.accountTypeId.value,
    creationDate: c.creationDate.value,
    country: c.country.value,
    assetId: c.assetId.value,
    assetQuantity: c.assetQuantity.value,
    feeStructure: c.feeStructure.value,
    modifiedAt: 0,
    deviceId: null,
    isDeleted: false,
  );

  test(
    'toCompanion recomputes balanceMinor from balance+currencyCode, ignoring a stale domain.balanceMinor',
    () {
      final a = account(
        balance: 123.45,
        currencyCode: 'EUR',
        balanceMinor: 999,
      );
      final c = a.toCompanion();
      expect(c.balanceMinor.value, 12345); // not 999
    },
  );

  test('crypto leaves balanceMinor null in the companion', () {
    final a = account(balance: 0.5, currencyCode: 'BTC');
    final c = a.toCompanion();
    expect(c.balanceMinor.value, isNull);
  });

  test(
    '0-decimal fiat (JPY) scales balanceMinor with no fractional digits',
    () {
      final a = account(balance: 1000, currencyCode: 'JPY');
      expect(a.toCompanion().balanceMinor.value, 1000);
    },
  );

  test(
    'full round trip preserves every field for a fiat account with all optional fields set',
    () {
      final original = account(
        id: 'acc-full',
        description: 'Main checking',
        balance: 2500.10,
        currencyCode: 'USD',
        styleId: 'style1',
        country: 'US',
        assetId: null,
        assetQuantity: 3.5,
        feeStructure: '[{"type":"fixed","amount":1.5}]',
      );

      final row = rowFromCompanion(original.toCompanion());
      final roundTripped = row.toDomain();

      expect(roundTripped.id, original.id);
      expect(roundTripped.name, original.name);
      expect(roundTripped.description, original.description);
      expect(roundTripped.balance, original.balance);
      expect(
        roundTripped.balanceMinor,
        250010,
      ); // exact minor units, recomputed on write
      expect(roundTripped.currencyCode, original.currencyCode);
      expect(
        roundTripped.currencyDesignationId,
        original.currencyDesignationId,
      );
      expect(roundTripped.styleId, original.styleId);
      expect(roundTripped.accountTypeId, original.accountTypeId);
      expect(roundTripped.creationDate, original.creationDate);
      expect(roundTripped.country, original.country);
      expect(roundTripped.assetId, original.assetId);
      expect(roundTripped.assetQuantity, original.assetQuantity);
      expect(roundTripped.feeStructure, original.feeStructure);
    },
  );

  test(
    'full round trip preserves every field for a crypto account (balanceMinor stays null throughout)',
    () {
      final original = account(
        id: 'acc-crypto',
        balance: 0.12345678,
        currencyCode: 'BTC',
        assetId: 'btc-asset',
        assetQuantity: 1.5,
      );

      final row = rowFromCompanion(original.toCompanion());
      final roundTripped = row.toDomain();

      expect(roundTripped.balance, original.balance);
      expect(roundTripped.balanceMinor, isNull);
      expect(roundTripped.assetId, original.assetId);
      expect(roundTripped.assetQuantity, original.assetQuantity);
    },
  );

  test('round trip preserves all-null optional fields', () {
    final original = account(
      id: 'acc-nulls',
      description: null,
      styleId: null,
      country: null,
      assetId: null,
      feeStructure: null,
    );

    final row = rowFromCompanion(original.toCompanion());
    final roundTripped = row.toDomain();

    expect(roundTripped.description, isNull);
    expect(roundTripped.styleId, isNull);
    expect(roundTripped.country, isNull);
    expect(roundTripped.assetId, isNull);
    expect(roundTripped.feeStructure, isNull);
  });

  test(
    'toCompanion with nullToAbsent:true marks null optional fields absent instead of Value(null)',
    () {
      final a = account(
        description: null,
        styleId: null,
        country: null,
        assetId: null,
        feeStructure: null,
      );
      final c = a.toCompanion(nullToAbsent: true);

      expect(c.description.present, isFalse);
      expect(c.styleId.present, isFalse);
      expect(c.country.present, isFalse);
      expect(c.assetId.present, isFalse);
      expect(c.feeStructure.present, isFalse);
      // Non-optional fields are always present regardless of nullToAbsent.
      expect(c.name.present, isTrue);
      expect(c.balance.present, isTrue);
    },
  );

  test(
    'null domain id becomes an absent companion id (insert lets the DB/caller assign one)',
    () {
      final a = account(id: null);
      final c = a.toCompanion();
      expect(c.id.present, isFalse);
    },
  );

  test(
    'toDomain trusts the stored balanceMinor as-is (read path does not recompute)',
    () {
      // Simulates a row that was written by a previous, buggy code path where
      // balance and balanceMinor disagree. toDomain must not silently coerce
      // or drop the stored integer minor units.
      final row = drift.DbAccount(
        id: 'acc1',
        name: 'X',
        balance: 1.0,
        balanceMinor: 42, // deliberately inconsistent with balance
        openingBalance: 1.0,
        currencyCode: 'EUR',
        currencyDesignationId: 'code',
        accountTypeId: 'general',
        creationDate: DateTime(2024, 1, 1),
        assetQuantity: 0.0,
        modifiedAt: 0,
        isDeleted: false,
      );

      expect(row.toDomain().balanceMinor, 42);
    },
  );
}
