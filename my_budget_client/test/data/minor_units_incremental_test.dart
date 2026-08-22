import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/data/repositories/local_db/local_transaction_repository.dart';
import 'package:my_budget_client/domain/entities/transaction.dart' as domain;

/// Proves balance_minor stays EXACT as transactions accumulate, where the legacy
/// double balance drifts (the classic 0.1 + 0.2 case).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LocalTransactionRepository repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalTransactionRepository(db);

    final designationId =
        (await db.select(db.currencyDesignations).get()).first.id;
    final accountTypeId = (await db.select(db.accountTypes).get()).first.id;
    await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: const Value('eur'),
            name: 'eur',
            balance: 0,
            balanceMinor: const Value(0),
            currencyCode: 'EUR',
            currencyDesignationId: designationId,
            accountTypeId: accountTypeId,
          ),
        );
  });

  tearDown(() async => db.close());

  test('balance_minor is exact where the double balance drifts', () async {
    final categoryId = (await db.select(db.categories).get()).first.id;

    Future<void> addTx(String id, double amount) => repo.addTransaction(
      domain.Transaction(
        id: id,
        description: id,
        amount: amount,
        date: DateTime(2024, 1, 1),
        accountId: 'eur',
        categoryId: categoryId,
        currencyCode: 'EUR',
      ),
    );

    await addTx('a', 0.1);
    await addTx('b', 0.2);

    final acc = await (db.select(
      db.accounts,
    )..where((a) => a.id.equals('eur'))).getSingle();

    // Exact: 10 + 20 minor units.
    expect(acc.balanceMinor, 30);
    // The legacy double really is off — this is the bug we are fixing.
    expect(acc.balance, isNot(0.3));
    expect((acc.balance - 0.3).abs() < 1e-9, isTrue);
  });
}
