import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/data/repositories/local_db/local_transaction_repository.dart';
import 'package:my_budget_client/domain/entities/transaction.dart' as domain;

/// Covers the repository's two invariants:
///   1. a transaction write and the balance it implies always land together;
///   2. every write that touches `accounts` or `transactions` leaves a
///      `sync_log` row, or the change never reaches another device.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LocalTransactionRepository repo;
  late String categoryId;

  Future<void> insertAccount(String id) async {
    final designationId =
        (await db.select(db.currencyDesignations).get()).first.id;
    final accountTypeId = (await db.select(db.accountTypes).get()).first.id;
    await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: Value(id),
            name: id,
            balance: 0,
            balanceMinor: const Value(0),
            currencyCode: 'EUR',
            currencyDesignationId: designationId,
            accountTypeId: accountTypeId,
          ),
        );
  }

  Future<DbAccount> account(String id) =>
      (db.select(db.accounts)..where((a) => a.id.equals(id))).getSingle();

  Future<List<SyncLogData>> logsFor(String table) => (db.select(
    db.syncLog,
  )..where((l) => l.changedTableName.equals(table))).get();

  domain.Transaction tx(
    String id,
    double amount, {
    String accountId = 'a',
    String? linkedTransactionId,
    String currencyCode = 'EUR',
  }) => domain.Transaction(
    id: id,
    description: id,
    amount: amount,
    date: DateTime(2024, 1, 1),
    accountId: accountId,
    categoryId: categoryId,
    currencyCode: currencyCode,
    linkedTransactionId: linkedTransactionId,
  );

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalTransactionRepository(db);
    categoryId = (await db.select(db.categories).get()).first.id;
    await insertAccount('a');
    await insertAccount('b');
    // Seeding wrote sync_log rows we do not care about; start each test clean.
    await db.delete(db.syncLog).go();
  });

  tearDown(() async => db.close());

  group('addTransaction', () {
    test('applies the amount to the account balance', () async {
      await repo.addTransaction(tx('t1', 25.50));

      final acc = await account('a');
      expect(acc.balanceMinor, 2550);
      expect(acc.balance, closeTo(25.50, 1e-9));
    });

    test('logs both the transaction and the account it moved', () async {
      await repo.addTransaction(tx('t1', 25.50));

      expect(
        (await logsFor('transactions')).map((l) => l.recordId),
        contains('t1'),
      );
      // The balance mutation is a separate row change on `accounts`. Without
      // its own log entry the peer replays the transaction but keeps the old
      // balance, and the two devices disagree forever.
      expect((await logsFor('accounts')).map((l) => l.recordId), contains('a'));
    });

    test(
      'rolls the insert back when the balance update cannot apply',
      () async {
        // A row whose FK targets are valid but whose account does not exist:
        // the balance write finds no row, so nothing may be committed.
        await expectLater(
          repo.addTransaction(tx('bad', 10, accountId: 'no-such-account')),
          throwsA(anything),
        );

        expect(await db.select(db.transactions).get(), isEmpty);
      },
    );
  });

  group('addTransactions', () {
    test('aggregates per account in one pass', () async {
      await repo.addTransactions([
        tx('t1', 10),
        tx('t2', 5),
        tx('t3', 7, accountId: 'b'),
      ]);

      expect((await account('a')).balanceMinor, 1500);
      expect((await account('b')).balanceMinor, 700);
    });

    test('logs every inserted transaction and every touched account', () async {
      await repo.addTransactions([tx('t1', 10), tx('t3', 7, accountId: 'b')]);

      expect(
        (await logsFor('transactions')).map((l) => l.recordId),
        containsAll(['t1', 't3']),
      );
      expect(
        (await logsFor('accounts')).map((l) => l.recordId),
        containsAll(['a', 'b']),
      );
    });
  });

  group('updateTransaction', () {
    test('applies only the delta when the account is unchanged', () async {
      await repo.addTransaction(tx('t1', 100));
      await repo.updateTransaction(tx('t1', 130));

      expect((await account('a')).balanceMinor, 13000);
    });

    test('moves the full amount when the account changes', () async {
      await repo.addTransaction(tx('t1', 100));
      await repo.updateTransaction(tx('t1', 100, accountId: 'b'));

      expect((await account('a')).balanceMinor, 0);
      expect((await account('b')).balanceMinor, 10000);
    });

    test('moves the new amount, not the old, when both change', () async {
      await repo.addTransaction(tx('t1', 100));
      await repo.updateTransaction(tx('t1', 250, accountId: 'b'));

      expect((await account('a')).balanceMinor, 0);
      expect((await account('b')).balanceMinor, 25000);
    });

    test('is a no-op for an id that does not exist', () async {
      await repo.addTransaction(tx('t1', 100));
      await repo.updateTransaction(tx('ghost', 999));

      expect((await account('a')).balanceMinor, 10000);
      expect(await repo.getTransactionById('ghost'), isNull);
    });
  });

  group('a transaction denominated in a currency the account does not hold', () {
    // The write paths keep a transaction in its own currency whenever no
    // exchange rate is on file, so this is an ordinary state, not a corrupt
    // one. What must never happen is the foreign digits being added to the
    // balance as though they were euros.
    test('does not move the balance by its raw foreign amount', () async {
      await repo.addTransaction(tx('usd', 100, currencyCode: 'USD'));

      expect((await account('a')).balanceMinor, 0);
      expect(
        await repo.getTransactionById('usd'),
        isNotNull,
        reason:
            'the transaction itself is still recorded — only the balance '
            'waits for a rate',
      );
    });

    test('is left out of a rebuild too, so both paths agree', () async {
      await repo.addTransaction(tx('usd', 100, currencyCode: 'USD'));
      await repo.addTransaction(tx('eur', 40));

      await db.accountsDao.recomputeBalances(['a']);

      expect((await account('a')).balanceMinor, 4000);
    });

    test(
      'joins the balance once it is restated in the account currency',
      () async {
        await repo.addTransaction(tx('usd', 100, currencyCode: 'USD'));
        expect((await account('a')).balanceMinor, 0);

        // What happens when the rate finally arrives and the amount is converted.
        await repo.updateTransaction(tx('usd', 117.5));

        expect((await account('a')).balanceMinor, 11750);
      },
    );

    test('leaves the balance alone again when it is taken back out', () async {
      await repo.addTransaction(tx('usd', 100, currencyCode: 'USD'));
      await repo.deleteTransaction('usd');

      // Reverting a delta that was never applied would push the account
      // 100 euros into the red on a delete.
      expect((await account('a')).balanceMinor, 0);
    });

    test('a batch keeps each currency to its own account', () async {
      await repo.addTransactions([
        tx('t1', 10),
        tx('usd', 100, currencyCode: 'USD'),
        tx('t2', 7, accountId: 'b'),
      ]);

      expect((await account('a')).balanceMinor, 1000);
      expect((await account('b')).balanceMinor, 700);
    });
  });

  group('rebuilding a balance from the opening-balance anchor', () {
    test(
      'counts a fiat transaction that arrived without minor units',
      () async {
        await repo.addTransaction(tx('t1', 10));
        // A peer or an importer that predates the minor-unit columns sends only
        // the double. The incremental path works off that double and counts the
        // row, so a rebuild that skipped it would quietly disagree with the
        // running balance by the whole transaction.
        await db.customStatement(
          'UPDATE transactions SET amount_minor = NULL WHERE id = ?',
          ['t1'],
        );

        await db.accountsDao.recomputeBalances(['a']);

        expect((await account('a')).balanceMinor, 1000);
        expect((await account('a')).balance, closeTo(10.0, 1e-9));
      },
    );
  });

  group('deleteTransaction', () {
    test('reverts the amount it had applied', () async {
      await repo.addTransaction(tx('t1', 100));
      await repo.deleteTransaction('t1');

      expect((await account('a')).balanceMinor, 0);
      expect(await repo.getTransactionById('t1'), isNull);
    });

    test('deletes the linked transfer leg and reverts both balances', () async {
      // A transfer: -100 leaves account a, +100 arrives in account b.
      await repo.addTransaction(tx('out', -100, linkedTransactionId: 'in'));
      await repo.addTransaction(
        tx('in', 100, accountId: 'b', linkedTransactionId: 'out'),
      );

      await repo.deleteTransaction('out');

      // Deleting one leg must not leave the other stranded — a half-transfer
      // is money that exists on one account and nowhere else.
      expect(await repo.getTransactionById('out'), isNull);
      expect(await repo.getTransactionById('in'), isNull);
      expect((await account('a')).balanceMinor, 0);
      expect((await account('b')).balanceMinor, 0);
    });

    test('logs the delete for both legs', () async {
      await repo.addTransaction(tx('out', -100, linkedTransactionId: 'in'));
      await repo.addTransaction(
        tx('in', 100, accountId: 'b', linkedTransactionId: 'out'),
      );
      await db.delete(db.syncLog).go();

      await repo.deleteTransaction('out');

      final deletes = (await logsFor(
        'transactions',
      )).where((l) => l.action == 'delete').map((l) => l.recordId);
      expect(deletes, containsAll(['out', 'in']));
    });
  });

  group('deleteMultipleTransactions', () {
    test('reverts balances across accounts and follows links', () async {
      await repo.addTransaction(tx('t1', 40));
      await repo.addTransaction(tx('out', -100, linkedTransactionId: 'in'));
      await repo.addTransaction(
        tx('in', 100, accountId: 'b', linkedTransactionId: 'out'),
      );

      // 'in' is not in the list — it must be pulled in by following the link.
      await repo.deleteMultipleTransactions(['t1', 'out']);

      expect(await repo.getTransactionById('t1'), isNull);
      expect(await repo.getTransactionById('out'), isNull);
      expect(await repo.getTransactionById('in'), isNull);
      expect((await account('a')).balanceMinor, 0);
      expect((await account('b')).balanceMinor, 0);
    });

    test('ignores ids that do not exist', () async {
      await repo.addTransaction(tx('t1', 40));

      await repo.deleteMultipleTransactions(['t1', 'ghost']);

      expect((await account('a')).balanceMinor, 0);
    });
  });

  group('bulk field updates', () {
    test('updateDateForMultipleTransactions logs each row', () async {
      await repo.addTransaction(tx('t1', 10));
      await repo.addTransaction(tx('t2', 10));
      await db.delete(db.syncLog).go();

      await repo.updateDateForMultipleTransactions([
        't1',
        't2',
      ], DateTime(2025, 6, 1));

      expect(
        (await logsFor('transactions')).map((l) => l.recordId),
        containsAll(['t1', 't2']),
      );
      final updated = await repo.getTransactionById('t1');
      expect(updated!.date, DateTime(2025, 6, 1));
    });

    test('updateCategoryForMultipleTransactions logs each row', () async {
      final otherCategory = (await db.select(db.categories).get())
          .firstWhere((c) => c.id != categoryId)
          .id;
      await repo.addTransaction(tx('t1', 10));
      await db.delete(db.syncLog).go();

      await repo.updateCategoryForMultipleTransactions(['t1'], otherCategory);

      expect(
        (await logsFor('transactions')).map((l) => l.recordId),
        contains('t1'),
      );
      expect((await repo.getTransactionById('t1'))!.categoryId, otherCategory);
    });
  });
}
