import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/data/repositories/local_db/local_account_repository.dart';
import 'package:my_budget_client/domain/entities/account.dart' as domain;
import 'package:my_budget_client/domain/entities/account_type.dart' as domain;
import 'package:my_budget_client/domain/repositories/account_repository.dart';

/// Pins the account repository's three load-bearing invariants:
///   1. deletion is soft, so EVERY read path has to filter `isDeleted`;
///   2. every write leaves a `sync_log` row, under the right table name;
///   3. balances are kept exact in `balance_minor` for fiat and NULL for
///      non-fiat, and money removed from one account has to be removed from
///      the account it was linked to as well.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // One database for the whole file: seeding inserts ~283k exchange rates and
  // costs ~10s, which a per-test database would pay over and over. Each test
  // instead resets exactly the tables this file writes to.
  late AppDatabase db;
  late LocalAccountRepository repo;
  late String designationId;
  late String accountTypeId;
  late String otherAccountTypeId;
  late String categoryId;

  setUpAll(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalAccountRepository(db);
    designationId = (await db.select(db.currencyDesignations).get()).first.id;
    final types = await db.select(db.accountTypes).get();
    accountTypeId = types.first.id;
    otherAccountTypeId = types[1].id;
    categoryId = (await db.select(db.categories).get()).first.id;
  });

  tearDownAll(() async => db.close());

  setUp(() async {
    await db.delete(db.transactions).go();
    await db.delete(db.accounts).go();
    // Earlier tests soft-delete account types; undo that so each test sees the
    // seeded set.
    await db
        .update(db.accountTypes)
        .write(const AccountTypesCompanion(isDeleted: Value(false)));
    await db.delete(db.syncLog).go();
  });

  domain.Account account(
    String id, {
    String name = 'acc',
    double balance = 0,
    String currencyCode = 'EUR',
    String? description,
    String? typeId,
    DateTime? creationDate,
  }) => domain.Account(
    id: id,
    name: name,
    description: description,
    balance: balance,
    currencyCode: currencyCode,
    currencyDesignationId: designationId,
    accountTypeId: typeId ?? accountTypeId,
    creationDate: creationDate ?? DateTime(2024, 1, 1),
  );

  Future<DbAccount> row(String id) =>
      (db.select(db.accounts)..where((a) => a.id.equals(id))).getSingle();

  Future<List<SyncLogData>> logsFor(String table) =>
      (db.select(db.syncLog)..where((l) => l.changedTableName.equals(table)))
          .get();

  Future<void> insertTransaction(
    String id,
    double amount, {
    required String accountId,
    String? linkedTransactionId,
    DateTime? date,
  }) async {
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: Value(id),
            description: id,
            amount: amount,
            amountMinor: Value((amount * 100).round()),
            date: date ?? DateTime(2024, 1, 1),
            accountId: accountId,
            categoryId: categoryId,
            currencyCode: 'EUR',
            linkedTransactionId: Value(linkedTransactionId),
          ),
        );
    await db.accountsDao.adjustBalance(accountId, amount);
  }

  group('soft delete is honoured by every read path', () {
    setUp(() async {
      await repo.addAccount(account('live', name: 'Live'));
      await repo.addAccount(account('gone', name: 'Gone'));
      await repo.deleteAccount('gone');
    });

    test('a soft-deleted account is not returned by getAccounts', () async {
      expect((await repo.getAccounts()).map((a) => a.id), ['live']);
    });

    test('a soft-deleted account is not returned by getAccountById', () async {
      // The row is still physically there — only the flag hides it.
      expect(await row('gone'), isNotNull);
      expect(await repo.getAccountById('gone'), isNull);
    });

    test('a soft-deleted account is not returned by getAccountsByIds',
        () async {
      final found = await repo.getAccountsByIds(['live', 'gone']);
      expect(found.map((a) => a.id), ['live']);
    });

    test('a soft-deleted account is not returned by getAccountsPaginated',
        () async {
      final found = await repo.getAccountsPaginated(limit: 50);
      expect(found.map((a) => a.id), ['live']);
    });

    test(
        'a soft-deleted account is not returned by getAccountsPaginatedFiltered',
        () async {
      final found = await repo.getAccountsPaginatedFiltered(
        limit: 50,
        accountFilters: const AccountFilters(sort: Sort.descending),
      );
      expect(found.map((a) => a.id), ['live']);
    });

    test('a soft-deleted account is not counted by getCountWithFilters',
        () async {
      expect(await repo.getCountWithFilters(), 1);
    });

    test('a soft-deleted account is not emitted by watchAccounts', () async {
      expect((await repo.watchAccounts().first).map((a) => a.id), ['live']);
    });

    test('a soft-deleted account has no balance in getBalancesAtDate',
        () async {
      final balances = await repo.getBalancesAtDate(DateTime(2025, 1, 1));
      expect(balances.keys, ['live']);
    });

    test('restoreAccount makes the account readable again', () async {
      // restoreAccount replaces the whole row, so it has to be given the full
      // account, not just the id.
      await repo.restoreAccount(account('gone', name: 'Gone'));

      expect(await repo.getAccountById('gone'), isNotNull);
      expect((await row('gone')).isDeleted, isFalse);
    });

    test('deleteAccount logs a delete against the accounts table', () async {
      final deletes = (await logsFor(
        'accounts',
      )).where((l) => l.action == 'delete');
      expect(deletes.map((l) => l.recordId), contains('gone'));
    });

    test('deleteAccount on an unknown id writes no sync_log row', () async {
      await db.delete(db.syncLog).go();

      await repo.deleteAccount('no-such-account');

      // Logging a delete for a row that was never there would make a peer
      // shadow-delete whatever it happens to hold under that id.
      expect(await logsFor('accounts'), isEmpty);
    });
  });

  group('addAccount', () {
    test('round-trips every nullable field, including the nulls', () async {
      await repo.addAccount(
        domain.Account(
          id: 'a1',
          name: 'Main',
          description: null,
          balance: 12.34,
          currencyCode: 'EUR',
          currencyDesignationId: designationId,
          styleId: null,
          accountTypeId: accountTypeId,
          creationDate: DateTime(2023, 5, 6),
          country: null,
          assetId: null,
          feeStructure: null,
        ),
      );

      final read = await repo.getAccountById('a1');
      expect(read!.name, 'Main');
      expect(read.description, isNull);
      expect(read.styleId, isNull);
      expect(read.country, isNull);
      expect(read.assetId, isNull);
      expect(read.feeStructure, isNull);
      expect(read.assetQuantity, 0.0);
      expect(read.creationDate, DateTime(2023, 5, 6));
      expect(read.balance, closeTo(12.34, 1e-9));
    });

    test('round-trips populated optional fields', () async {
      await repo.addAccount(
        domain.Account(
          id: 'a1',
          name: 'Main',
          description: 'salary',
          balance: 0,
          currencyCode: 'EUR',
          currencyDesignationId: designationId,
          accountTypeId: accountTypeId,
          creationDate: DateTime(2023, 5, 6),
          country: 'DE',
          assetId: 'BTC',
          assetQuantity: 1.5,
          feeStructure: '{"kind":"flat"}',
        ),
      );

      final read = (await repo.getAccountById('a1'))!;
      expect(read.description, 'salary');
      expect(read.country, 'DE');
      expect(read.assetId, 'BTC');
      expect(read.assetQuantity, 1.5);
      expect(read.feeStructure, '{"kind":"flat"}');
    });

    test('stores a fiat balance as exact integer minor units', () async {
      // 0.1 + 0.2 in doubles is 0.30000000000000004; the minor-unit column is
      // what keeps the stored balance exact.
      await repo.addAccount(account('a1', balance: 0.1 + 0.2));

      expect((await row('a1')).balanceMinor, 30);
    });

    test('uses the currency scale, not a fixed 100, for minor units', () async {
      // JPY has 0 decimals; scaling it by 100 would inflate the balance 100x.
      await repo.addAccount(account('jpy', balance: 1250, currencyCode: 'JPY'));
      // KWD has 3.
      await repo.addAccount(account('kwd', balance: 1.234, currencyCode: 'KWD'));

      expect((await row('jpy')).balanceMinor, 1250);
      expect((await row('kwd')).balanceMinor, 1234);
    });

    test('leaves balanceMinor NULL for a crypto account', () async {
      // NULL means "not a minor-unit currency". Coercing it to 0 would turn a
      // 2.5 BTC holding into a zero balance for every consumer that trusts the
      // exact column over the double.
      await repo.addAccount(account('btc', balance: 2.5, currencyCode: 'BTC'));

      final stored = await row('btc');
      expect(stored.balanceMinor, isNull);
      expect(stored.balance, 2.5);
      expect((await repo.getAccountById('btc'))!.balanceMinor, isNull);
    });

    test('leaves balanceMinor NULL for a commodity account', () async {
      await repo.addAccount(account('xau', balance: 0.75, currencyCode: 'XAU'));

      expect((await row('xau')).balanceMinor, isNull);
    });

    test('stamps modifiedAt so the row wins against an older remote copy',
        () async {
      final before = DateTime.now().millisecondsSinceEpoch;
      await repo.addAccount(account('a1'));

      expect((await row('a1')).modifiedAt, greaterThanOrEqualTo(before));
    });

    test('logs an upsert for sync', () async {
      await repo.addAccount(account('a1'));

      final logs = await logsFor('accounts');
      expect(logs.map((l) => '${l.recordId}:${l.action}'), ['a1:upsert']);
      expect(logs.single.exported, isFalse);
      expect(logs.single.timestamp, greaterThan(0));
    });

    test('mints an id when the account has none', () async {
      await repo.addAccount(
        domain.Account(
          name: 'No id',
          balance: 0,
          currencyCode: 'EUR',
          currencyDesignationId: designationId,
          accountTypeId: accountTypeId,
          creationDate: DateTime(2024, 1, 1),
        ),
      );

      final all = await repo.getAccounts();
      expect(all.single.id, isNotEmpty);
      // The generated id, not a null, is what has to reach sync_log.
      expect((await logsFor('accounts')).single.recordId, all.single.id);
    });
  });

  group('addAccounts', () {
    test('inserts every account and logs one upsert each', () async {
      await repo.addAccounts([account('a1'), account('a2'), account('a3')]);

      expect((await repo.getAccounts()).length, 3);
      expect(
        (await logsFor('accounts')).map((l) => l.recordId),
        containsAll(['a1', 'a2', 'a3']),
      );
    });

    test('replaces an existing account rather than failing on its id',
        () async {
      await repo.addAccount(account('a1', name: 'Old'));

      await repo.addAccounts([account('a1', name: 'New')]);

      expect((await repo.getAccountById('a1'))!.name, 'New');
    });
  });

  group('updateAccount', () {
    test('persists the change and bumps modifiedAt', () async {
      await repo.addAccount(account('a1', name: 'Old'));
      final oldModified = (await row('a1')).modifiedAt;
      await Future<void>.delayed(const Duration(milliseconds: 5));

      await repo.updateAccount(account('a1', name: 'New', balance: 5));

      final updated = await row('a1');
      expect(updated.name, 'New');
      expect(updated.balanceMinor, 500);
      // A stale modifiedAt loses last-write-wins against an older remote row.
      expect(updated.modifiedAt, greaterThan(oldModified));
    });

    test('logs an upsert for sync', () async {
      await repo.addAccount(account('a1', name: 'Old'));
      await db.delete(db.syncLog).go();

      await repo.updateAccount(account('a1', name: 'New'));

      expect(
        (await logsFor('accounts')).map((l) => '${l.recordId}:${l.action}'),
        ['a1:upsert'],
      );
    });
  });

  group('pagination and filtering', () {
    setUp(() async {
      await repo.addAccount(account('a1', name: 'Alpha', balance: 10));
      await repo.addAccount(account('a2', name: 'Beta', balance: 30));
      await repo.addAccount(
        account('a3', name: 'Gamma', balance: 20, currencyCode: 'USD'),
      );
      await repo.addAccount(
        account('a4', name: 'Delta', balance: 40, typeId: otherAccountTypeId),
      );
    });

    test('getAccountsPaginated honours limit', () async {
      expect((await repo.getAccountsPaginated(limit: 2)).length, 2);
    });

    test('getAccountsPaginated honours offset', () async {
      final page1 = await repo.getAccountsPaginated(limit: 2, offset: 0);
      final page2 = await repo.getAccountsPaginated(limit: 2, offset: 2);

      expect(page2.length, 2);
      // Overlapping pages would show the caller duplicate rows while hiding
      // others entirely.
      expect(
        page1.map((a) => a.id).toSet().intersection(
          page2.map((a) => a.id).toSet(),
        ),
        isEmpty,
      );
    });

    test('getAccountsPaginated defaults to a limit of 10', () async {
      for (var i = 0; i < 12; i++) {
        await repo.addAccount(account('bulk$i'));
      }

      expect((await repo.getAccountsPaginated()).length, 10);
    });

    test('filtered results are ordered by balance descending by default',
        () async {
      final found = await repo.getAccountsPaginatedFiltered(
        limit: 50,
        accountFilters: const AccountFilters(sort: Sort.descending),
      );

      expect(found.map((a) => a.balance), [40, 30, 20, 10]);
    });

    test('Sort.ascending flips the balance ordering', () async {
      final found = await repo.getAccountsPaginatedFiltered(
        limit: 50,
        accountFilters: const AccountFilters(sort: Sort.ascending),
      );

      expect(found.map((a) => a.balance), [10, 20, 30, 40]);
    });

    test('a null filter object still returns accounts, newest balance first',
        () async {
      final found = await repo.getAccountsPaginatedFiltered(limit: 50);

      expect(found.map((a) => a.balance), [40, 30, 20, 10]);
    });

    test('the name filter matches a substring, case-sensitively', () async {
      final found = await repo.getAccountsPaginatedFiltered(
        limit: 50,
        accountFilters: const AccountFilters(name: 'et', sort: Sort.descending),
      );

      expect(found.map((a) => a.name), ['Beta']);
    });

    test('the amountFrom/amountTo filter is inclusive on both ends', () async {
      final found = await repo.getAccountsPaginatedFiltered(
        limit: 50,
        accountFilters: const AccountFilters(
          amountFrom: 20,
          amountTo: 30,
          sort: Sort.ascending,
        ),
      );

      expect(found.map((a) => a.balance), [20, 30]);
    });

    test('the currency filter restricts to the listed codes', () async {
      final found = await repo.getAccountsPaginatedFiltered(
        limit: 50,
        accountFilters: const AccountFilters(
          currenciesIds: ['USD'],
          sort: Sort.descending,
        ),
      );

      expect(found.map((a) => a.id), ['a3']);
    });

    test('the account-type filter restricts to the listed types', () async {
      final found = await repo.getAccountsPaginatedFiltered(
        limit: 50,
        accountFilters: AccountFilters(
          accountTypeIds: [otherAccountTypeId],
          sort: Sort.descending,
        ),
      );

      expect(found.map((a) => a.id), ['a4']);
    });

    test('an empty filter list is treated as no filter at all', () async {
      final found = await repo.getAccountsPaginatedFiltered(
        limit: 50,
        accountFilters: const AccountFilters(
          accountTypeIds: [],
          currenciesIds: [],
          name: '',
          sort: Sort.descending,
        ),
      );

      expect(found.length, 4);
    });

    test('the date filter keeps accounts created on or after that day',
        () async {
      await repo.addAccount(
        account('late', balance: 99, creationDate: DateTime(2025, 3, 4)),
      );

      final found = await repo.getAccountsPaginatedFiltered(
        limit: 50,
        accountFilters: AccountFilters(
          date: DateTime(2025, 3, 4, 18),
          sort: Sort.descending,
        ),
      );

      expect(found.map((a) => a.id), ['late']);
    });

    test('getCountWithFilters counts only the requested account types',
        () async {
      expect(await repo.getCountWithFilters(), 4);
      expect(
        await repo.getCountWithFilters(accountTypeIds: [otherAccountTypeId]),
        1,
      );
    });
  });

  group('getBalancesAtDate', () {
    test('reports zero for a date before the account existed', () async {
      await repo.addAccount(
        account('a1', balance: 100, creationDate: DateTime(2024, 6, 1)),
      );

      final balances = await repo.getBalancesAtDate(DateTime(2024, 5, 31));
      expect(balances['a1'], 0.0);
    });

    test('subtracts transactions dated after the requested day', () async {
      await repo.addAccount(
        account('a1', creationDate: DateTime(2024, 1, 1)),
      );
      await insertTransaction(
        'past',
        60,
        accountId: 'a1',
        date: DateTime(2024, 2, 1),
      );
      await insertTransaction(
        'future',
        40,
        accountId: 'a1',
        date: DateTime(2024, 12, 1),
      );

      final balances = await repo.getBalancesAtDate(DateTime(2024, 6, 1));
      expect(balances['a1'], closeTo(60, 1e-9));
    });

    test('counts a transaction dated later the same day as already applied',
        () async {
      await repo.addAccount(account('a1'));
      await insertTransaction(
        'today',
        40,
        accountId: 'a1',
        date: DateTime(2024, 6, 1, 22),
      );

      // The cut-off snaps to end of day, so a 22:00 transaction counts towards
      // the balance "at" 2024-06-01.
      final balances = await repo.getBalancesAtDate(DateTime(2024, 6, 1));
      expect(balances['a1'], closeTo(40, 1e-9));
    });

    test('ignores soft-deleted transactions', () async {
      await repo.addAccount(account('a1'));
      await insertTransaction(
        'future',
        40,
        accountId: 'a1',
        date: DateTime(2024, 12, 1),
      );
      await db
          .update(db.transactions)
          .write(const TransactionsCompanion(isDeleted: Value(true)));

      // The balance still carries the 40 (delete did not revert it here), so
      // if the sum re-counted the deleted row we would see 0 instead of 40.
      final balances = await repo.getBalancesAtDate(DateTime(2024, 6, 1));
      expect(balances['a1'], closeTo(40, 1e-9));
    });
  });

  group('deleteMultipleAccounts', () {
    test('soft-deletes every listed account and logs each one', () async {
      await repo.addAccounts([account('a1'), account('a2'), account('a3')]);
      await db.delete(db.syncLog).go();

      await repo.deleteMultipleAccounts(['a1', 'a2']);

      expect((await repo.getAccounts()).map((a) => a.id), ['a3']);
      expect((await row('a1')).isDeleted, isTrue);
      expect(
        (await logsFor(
          'accounts',
        )).where((l) => l.action == 'delete').map((l) => l.recordId),
        containsAll(['a1', 'a2']),
      );
    });
  });

  group('updateAccountTypeForMultipleAccounts', () {
    test('moves every listed account to the new type and logs each', () async {
      await repo.addAccounts([account('a1'), account('a2')]);
      await db.delete(db.syncLog).go();

      await repo.updateAccountTypeForMultipleAccounts([
        'a1',
        'a2',
      ], otherAccountTypeId);

      final all = await repo.getAccounts();
      expect(all.every((a) => a.accountTypeId == otherAccountTypeId), isTrue);
      expect(
        (await logsFor(
          'accounts',
        )).where((l) => l.action == 'upsert').map((l) => l.recordId),
        containsAll(['a1', 'a2']),
      );
    });

    test('bumps modifiedAt so the retype is not lost to an older remote row',
        () async {
      await repo.addAccount(account('a1'));
      final before = (await row('a1')).modifiedAt;
      await Future<void>.delayed(const Duration(milliseconds: 5));

      await repo.updateAccountTypeForMultipleAccounts([
        'a1',
      ], otherAccountTypeId);

      expect((await row('a1')).modifiedAt, greaterThan(before));
    });
  });

  group('deleteAccountWithTransactions', () {
    setUp(() async {
      await repo.addAccount(account('a'));
      await repo.addAccount(account('b'));
      // A transfer: -100 leaves a, +100 arrives in b, the two legs linked.
      await insertTransaction(
        'out',
        -100,
        accountId: 'a',
        linkedTransactionId: 'in',
      );
      await insertTransaction(
        'in',
        100,
        accountId: 'b',
        linkedTransactionId: 'out',
      );
      await db.delete(db.syncLog).go();
    });

    test('soft-deletes the account', () async {
      await repo.deleteAccountWithTransactions('a');

      expect(await repo.getAccountById('a'), isNull);
      expect((await row('a')).isDeleted, isTrue);
    });

    test("soft-deletes the account's own transactions", () async {
      await repo.deleteAccountWithTransactions('a');

      final out = await (db.select(
        db.transactions,
      )..where((t) => t.id.equals('out'))).getSingle();
      expect(out.isDeleted, isTrue);
    });

    test('soft-deletes the linked leg sitting on the other account', () async {
      await repo.deleteAccountWithTransactions('a');

      // Leaving the other half alive would be money that exists on one side of
      // a transfer and nowhere else.
      final incoming = await (db.select(
        db.transactions,
      )..where((t) => t.id.equals('in'))).getSingle();
      expect(incoming.isDeleted, isTrue);
    });

    test('logs the account delete against the accounts table', () async {
      await repo.deleteAccountWithTransactions('a');

      expect(
        (await logsFor('accounts')).map((l) => l.recordId),
        contains('a'),
      );
    });

    // BUG (characterisation): AccountsDao.deleteAccountWithTransactions
    // (lib/core/database/app_database.dart:1606-1607) logs the deleted
    // TRANSACTION ids through `_logChanges`, which hardcodes
    // `changedTableName: Value('accounts')` (line 1311). The transaction
    // deletes are therefore announced as account deletes.
    // CORRECT behaviour: the transaction ids belong under
    // changedTableName 'transactions', the way CategoriesDao does it with its
    // separate `_logTransactionChanges`. As written, a peer receiving the log
    // looks for accounts with ids 'out'/'in', finds none, and the deleted
    // transactions stay alive on that device forever — while the account rows
    // it does own may be touched by an id collision.
    test(
      'the deleted transactions are logged under the accounts table name '
      '(WRONG - should be transactions)',
      () async {
        await repo.deleteAccountWithTransactions('a');

        expect(
          (await logsFor('accounts')).map((l) => l.recordId),
          containsAll(['a', 'out', 'in']),
        );
        expect(await logsFor('transactions'), isEmpty);
      },
    );

    // BUG (characterisation): the same method soft-deletes the linked leg on
    // account 'b' but never reverts the balance that leg had contributed.
    // CORRECT behaviour: account b's balance should go back to 0 when the
    // +100 leg is deleted, exactly as
    // TransactionsDao.deleteTransaction already does. As written, deleting an
    // account leaves every account it ever transferred with showing a balance
    // that includes money from transactions that no longer exist, and no
    // amount of re-reading fixes it because the balance is materialised.
    test(
      'the counterpart account keeps the balance of its deleted leg '
      '(WRONG - it should be reverted)',
      () async {
        await repo.deleteAccountWithTransactions('a');

        final b = await row('b');
        expect(b.balance, 100.0);
        expect(b.balanceMinor, 10000);
      },
    );
  });

  group('deleteAccountAndReassignTransactions', () {
    setUp(() async {
      await repo.addAccount(account('a'));
      await repo.addAccount(account('b'));
      await insertTransaction('t1', 50, accountId: 'a');
      await db.delete(db.syncLog).go();
    });

    test('soft-deletes the old account', () async {
      await repo.deleteAccountAndReassignTransactions('a', 'b');

      expect(await repo.getAccountById('a'), isNull);
    });

    test('moves the transactions onto the new account', () async {
      await repo.deleteAccountAndReassignTransactions('a', 'b');

      final t1 = await (db.select(
        db.transactions,
      )..where((t) => t.id.equals('t1'))).getSingle();
      expect(t1.accountId, 'b');
      expect(t1.isDeleted, isFalse);
    });

    test('logs the account delete', () async {
      await repo.deleteAccountAndReassignTransactions('a', 'b');

      expect(
        (await logsFor(
          'accounts',
        )).where((l) => l.action == 'delete').map((l) => l.recordId),
        contains('a'),
      );
    });

    // BUG (characterisation): AccountsDao.deleteAccountAndReassignTransactions
    // (lib/core/database/app_database.dart:1611-1630) rewrites every moved
    // transaction's `account_id` but only logs the account delete.
    // CORRECT behaviour: each reassigned transaction id needs an 'upsert' row
    // under changedTableName 'transactions'. As written, the peer deletes the
    // account and never learns the transactions moved: on that device they
    // still point at the deleted account, so they vanish from every account
    // view while still counting towards totals.
    test(
      'no sync_log row is written for the reassigned transactions '
      '(WRONG - each moved transaction should log an upsert)',
      () async {
        await repo.deleteAccountAndReassignTransactions('a', 'b');

        expect(await logsFor('transactions'), isEmpty);
        expect((await logsFor('accounts')).map((l) => l.recordId), ['a']);
      },
    );

    // BUG (characterisation): the same method moves the transaction but not
    // the money it represents.
    // CORRECT behaviour: the destination account's balance should gain the sum
    // of the reassigned transactions (+50 here). As written, the user reassigns
    // a deleted account's history to another account and that account's balance
    // does not change, so its displayed balance no longer matches the sum of
    // its own transactions.
    test(
      'the destination account balance does not gain the reassigned amount '
      '(WRONG - it should)',
      () async {
        await repo.deleteAccountAndReassignTransactions('a', 'b');

        final b = await row('b');
        expect(b.balance, 0.0);
        expect(b.balanceMinor, 0);
      },
    );
  });

  group('account types', () {
    test('a soft-deleted account type is not returned by getAccountTypes',
        () async {
      final before = (await repo.getAccountTypes()).length;
      await db.accountTypesDao.deleteAccountType(
        AccountTypesCompanion(id: Value(accountTypeId)),
      );

      final after = await repo.getAccountTypes();
      expect(after.length, before - 1);
      expect(after.map((t) => t.id), isNot(contains(accountTypeId)));
    });

    test('a soft-deleted account type is not returned by getAccountTypeById',
        () async {
      await db.accountTypesDao.deleteAccountType(
        AccountTypesCompanion(id: Value(accountTypeId)),
      );

      expect(await repo.getAccountTypeById(accountTypeId), isNull);
    });

    test('a soft-deleted account type is not emitted by watchAccountTypes',
        () async {
      await db.accountTypesDao.deleteAccountType(
        AccountTypesCompanion(id: Value(accountTypeId)),
      );

      final emitted = await repo.watchAccountTypes().first;
      expect(emitted.map((t) => t.id), isNot(contains(accountTypeId)));
    });

    test('addAccountTypes round-trips and logs under account_types', () async {
      await db.delete(db.syncLog).go();

      await repo.addAccountTypes([
        const domain.AccountType(id: 'at1', name: 'Wallet', languageCode: 'en'),
      ]);

      final read = await repo.getAccountTypeById('at1');
      expect(read!.name, 'Wallet');
      expect(read.languageCode, 'en');
      // Under the wrong table name a peer would apply the row to `accounts`.
      expect(
        (await logsFor('account_types')).map((l) => l.recordId),
        contains('at1'),
      );
    });
  });
}
