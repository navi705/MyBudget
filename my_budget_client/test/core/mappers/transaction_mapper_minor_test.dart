import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/mappers/transaction_mapper.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';

/// toCompanion must populate the exact minor-unit columns for fiat and leave
/// them NULL for crypto, so every write keeps the minor columns correct.
void main() {
  Transaction txn(double amount, String code, {double fee = 0.0}) =>
      Transaction(
        description: 'x',
        amount: amount,
        date: DateTime(2024, 1, 1),
        accountId: 'a',
        categoryId: 'c',
        currencyCode: code,
        fee: fee,
      );

  test('fiat populates amountMinor / feeMinor at currency scale', () {
    final c = txn(123.45, 'EUR', fee: 0.05).toCompanion();
    expect(c.amountMinor.value, 12345);
    expect(c.feeMinor.value, 5);
  });

  test('0- and 3-decimal fiat scale correctly', () {
    expect(txn(1000, 'JPY').toCompanion().amountMinor.value, 1000);
    expect(txn(1.234, 'KWD').toCompanion().amountMinor.value, 1234);
  });

  test('crypto leaves minor columns null', () {
    final c = txn(0.5, 'BTC', fee: 0.01).toCompanion();
    expect(c.amountMinor.value, isNull);
    expect(c.feeMinor.value, isNull);
  });
}
