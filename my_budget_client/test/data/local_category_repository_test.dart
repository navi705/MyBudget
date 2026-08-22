import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/constants/app_constants.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/data/repositories/local_db/local_category_repository.dart';
import 'package:my_budget_client/domain/entities/category.dart' as domain;
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';

/// Pins three things the category repository is responsible for:
///   1. the internal `__system_transfer__` category is hidden from the user
///      unless it is asked for explicitly;
///   2. soft-deleted categories disappear from every read;
///   3. deleting or reassigning a category also reports the transactions it
///      dragged along, under the `transactions` table name.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LocalCategoryRepository repo;
  late String accountId;
  late String styleId;

  setUpAll(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalCategoryRepository(db);

    styleId = (await db.select(db.styles).get()).first.id;
    final designationId =
        (await db.select(db.currencyDesignations).get()).first.id;
    final accountTypeId = (await db.select(db.accountTypes).get()).first.id;
    accountId = 'acc-1';
    await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: Value(accountId),
            name: 'Main',
            balance: 0,
            balanceMinor: const Value(0),
            currencyCode: 'EUR',
            currencyDesignationId: designationId,
            accountTypeId: accountTypeId,
          ),
        );
  });

  tearDownAll(() async => db.close());

  setUp(() async {
    await db.delete(db.transactions).go();
    await db.delete(db.categories).go();
    await db.delete(db.syncLog).go();
  });

  domain.Category category(
    String id, {
    String name = 'Food',
    String? parentId,
    String? style,
    CategoryType type = CategoryType.expense,
  }) => domain.Category(
    id: id,
    name: name,
    parentId: parentId,
    styleId: style,
    type: type,
  );

  Future<List<SyncLogData>> logsFor(String table) => (db.select(
    db.syncLog,
  )..where((l) => l.changedTableName.equals(table))).get();

  Future<Category> row(String id) =>
      (db.select(db.categories)..where((c) => c.id.equals(id))).getSingle();

  Future<void> insertTransaction(
    String id,
    double amount, {
    required String categoryId,
    DateTime? date,
  }) => db
      .into(db.transactions)
      .insert(
        TransactionsCompanion.insert(
          id: Value(id),
          description: id,
          amount: amount,
          amountMinor: Value((amount * 100).round()),
          date: date ?? DateTime(2024, 6, 1),
          accountId: accountId,
          categoryId: categoryId,
          currencyCode: 'EUR',
        ),
      );

  group('addCategory', () {
    test('round-trips name, parent, style and type', () async {
      await repo.addCategory(category('parent', name: 'Home'));
      await repo.addCategory(
        category(
          'c1',
          name: 'Rent',
          parentId: 'parent',
          style: styleId,
          type: CategoryType.income,
        ),
      );

      final read = await repo.getCategoryById('c1');
      expect(read!.name, 'Rent');
      expect(read.parentId, 'parent');
      expect(read.styleId, styleId);
      expect(read.type, CategoryType.income);
    });

    test(
      'round-trips a category with no parent and no style as nulls',
      () async {
        await repo.addCategory(category('c1'));

        final read = await repo.getCategoryById('c1');
        expect(read!.parentId, isNull);
        expect(read.styleId, isNull);
        // The entity's own default, not a silently different one.
        expect(read.type, CategoryType.expense);
      },
    );

    test('mints an id when the category has none', () async {
      await repo.addCategory(domain.Category(name: 'Fuel'));

      final all = await repo.getCategories();
      expect(all.single.id, isNotEmpty);
      expect((await logsFor('categories')).single.recordId, all.single.id);
    });

    test('stamps modifiedAt and logs an upsert under categories', () async {
      final before = DateTime.now().millisecondsSinceEpoch;

      await repo.addCategory(category('c1'));

      expect((await row('c1')).modifiedAt, greaterThanOrEqualTo(before));
      expect(
        (await logsFor('categories')).map((l) => '${l.recordId}:${l.action}'),
        ['c1:upsert'],
      );
    });
  });

  group('addCategories', () {
    test('inserts every category and logs one upsert each', () async {
      await repo.addCategories([
        category('c1', name: 'A'),
        category('c2', name: 'B'),
      ]);

      expect((await repo.getCategories()).length, 2);
      expect(
        (await logsFor('categories')).map((l) => l.recordId),
        containsAll(['c1', 'c2']),
      );
    });

    test(
      'replaces an existing category rather than failing on its id',
      () async {
        await repo.addCategory(category('c1', name: 'Old'));

        await repo.addCategories([category('c1', name: 'New')]);

        expect((await repo.getCategoryById('c1'))!.name, 'New');
      },
    );
  });

  group('the internal transfer category', () {
    setUp(() async {
      await repo.addCategory(category('normal', name: 'Food'));
      await repo.addCategory(
        category(
          'system',
          name: AppConstants.systemTransferCategoryName,
          type: CategoryType.transfer,
        ),
      );
    });

    test('is hidden from getCategories by default', () async {
      expect((await repo.getCategories()).map((c) => c.id), ['normal']);
    });

    test('is returned by getCategories when includeSystem is set', () async {
      final all = await repo.getCategories(includeSystem: true);
      expect(all.map((c) => c.id), containsAll(['normal', 'system']));
    });

    test('is hidden from watchCategories by default', () async {
      expect((await repo.watchCategories().first).map((c) => c.id), ['normal']);
    });

    test('is emitted by watchCategories when includeSystem is set', () async {
      final emitted = await repo.watchCategories(includeSystem: true).first;
      expect(emitted.map((c) => c.id), containsAll(['normal', 'system']));
    });

    // BUG (characterisation): LocalCategoryRepository.getCategoriesPaginated
    // (lib/data/repositories/local_db/local_category_repository.dart:57-67)
    // has no `includeSystem` parameter and no filter, unlike getCategories and
    // watchCategories right next to it.
    // CORRECT behaviour: the paginated read should hide
    // `__system_transfer__` the same way the unpaginated one does. As written,
    // any screen that pages through categories shows a row literally named
    // `__system_transfer__`, which the user can then select, rename or delete —
    // breaking every transfer in the app.
    test('leaks into getCategoriesPaginated (WRONG - it should be hidden there '
        'too)', () async {
      final page = await repo.getCategoriesPaginated(limit: 50);

      expect(
        page.map((c) => c.name),
        contains(AppConstants.systemTransferCategoryName),
      );
    });

    // BUG (characterisation): same omission in
    // getCategoriesWithTotalsPaginated (local_category_repository.dart:69-89).
    // CORRECT behaviour: the totals screen should not list the internal
    // transfer category. As written it appears as a normal spending category
    // and its transfer legs are counted into the displayed totals.
    test('leaks into getCategoriesWithTotalsPaginated (WRONG - it should be '
        'hidden there too)', () async {
      final rows = await repo.getCategoriesWithTotalsPaginated();

      expect(
        rows.map((r) => r.category.name),
        contains(AppConstants.systemTransferCategoryName),
      );
    });
  });

  group('soft delete', () {
    setUp(() async {
      await repo.addCategory(category('live', name: 'Food'));
      await repo.addCategory(category('gone', name: 'Travel'));
      await repo.deleteCategory('gone');
      await db.delete(db.syncLog).go();
    });

    test('a soft-deleted category is not returned by getCategories', () async {
      expect((await repo.getCategories()).map((c) => c.id), ['live']);
      // The row is still physically present.
      expect((await row('gone')).isDeleted, isTrue);
    });

    test(
      'a soft-deleted category is not returned even with includeSystem',
      () async {
        // includeSystem must not be a back door around the delete filter.
        expect(
          (await repo.getCategories(includeSystem: true)).map((c) => c.id),
          ['live'],
        );
      },
    );

    test(
      'a soft-deleted category is not returned by getCategoryById',
      () async {
        expect(await repo.getCategoryById('gone'), isNull);
      },
    );

    test(
      'a soft-deleted category is not returned by getCategoriesByIds',
      () async {
        final found = await repo.getCategoriesByIds(['live', 'gone']);
        expect(found.map((c) => c.id), ['live']);
      },
    );

    test(
      'a soft-deleted category is not returned by getCategoriesPaginated',
      () async {
        expect(
          (await repo.getCategoriesPaginated(limit: 50)).map((c) => c.id),
          ['live'],
        );
      },
    );

    test('a soft-deleted category is not emitted by watchCategories', () async {
      expect((await repo.watchCategories().first).map((c) => c.id), ['live']);
    });

    test('a soft-deleted category is not listed by the totals query', () async {
      final rows = await repo.getCategoriesWithTotalsPaginated();
      expect(rows.map((r) => r.category.id), ['live']);
    });

    test('deleteCategory logs a delete under categories', () async {
      await repo.deleteCategory('live');

      expect(
        (await logsFor('categories')).map((l) => '${l.recordId}:${l.action}'),
        ['live:delete'],
      );
    });

    test('deleteCategory on an unknown id writes no sync_log row', () async {
      await repo.deleteCategory('no-such-category');

      expect(await logsFor('categories'), isEmpty);
    });
  });

  group('getCategoriesByIds', () {
    setUp(() async {
      await repo.addCategories([
        category('c1', name: 'A'),
        category('c2', name: 'B'),
        category('c3', name: 'C'),
      ]);
    });

    test('returns the categories in the order they were asked for', () async {
      // Callers zip this result against their own id list, so the order is
      // part of the contract, not an accident of the query plan.
      final found = await repo.getCategoriesByIds(['c3', 'c1', 'c2']);
      expect(found.map((c) => c.id), ['c3', 'c1', 'c2']);
    });

    test('silently drops ids that do not exist', () async {
      final found = await repo.getCategoriesByIds(['c1', 'ghost', 'c2']);
      expect(found.map((c) => c.id), ['c1', 'c2']);
    });

    test('returns an empty list for an empty id list', () async {
      expect(await repo.getCategoriesByIds([]), isEmpty);
    });
  });

  group('getCategoriesPaginated', () {
    test('honours limit and offset', () async {
      for (var i = 0; i < 5; i++) {
        await repo.addCategory(category('c$i', name: 'C$i'));
      }

      final page1 = await repo.getCategoriesPaginated(limit: 2);
      final page2 = await repo.getCategoriesPaginated(limit: 2, offset: 2);

      expect(page1.length, 2);
      expect(page2.length, 2);
      expect(
        page1
            .map((c) => c.id)
            .toSet()
            .intersection(page2.map((c) => c.id).toSet()),
        isEmpty,
      );
    });

    test('defaults to a limit of 10', () async {
      for (var i = 0; i < 12; i++) {
        await repo.addCategory(category('c$i', name: 'C$i'));
      }

      expect((await repo.getCategoriesPaginated()).length, 10);
    });
  });

  group('getCategoriesWithTotalsPaginated', () {
    setUp(() async {
      await repo.addCategory(category('food', name: 'Food'));
      await repo.addCategory(
        category('salary', name: 'Salary', type: CategoryType.income),
      );
      await repo.addCategory(category('empty', name: 'Zzz'));
      await insertTransaction(
        't1',
        -10,
        categoryId: 'food',
        date: DateTime(2024, 6, 1),
      );
      await insertTransaction(
        't2',
        -5,
        categoryId: 'food',
        date: DateTime(2024, 7, 1),
      );
      await insertTransaction(
        't3',
        1000,
        categoryId: 'salary',
        date: DateTime(2024, 6, 1),
      );
    });

    test('sums the transactions belonging to each category', () async {
      final rows = await repo.getCategoriesWithTotalsPaginated();
      final byId = {for (final r in rows) r.category.id: r.total};

      expect(byId['food'], closeTo(-15, 1e-9));
      expect(byId['salary'], closeTo(1000, 1e-9));
    });

    test(
      'reports zero, not null, for a category with no transactions',
      () async {
        final rows = await repo.getCategoriesWithTotalsPaginated();
        final empty = rows.firstWhere((r) => r.category.id == 'empty');

        expect(empty.total, 0.0);
      },
    );

    test('counts only transactions inside the requested date window', () async {
      final rows = await repo.getCategoriesWithTotalsPaginated(
        dateFrom: DateTime(2024, 6, 1),
        dateTo: DateTime(2024, 6, 30),
      );
      final byId = {for (final r in rows) r.category.id: r.total};

      expect(byId['food'], closeTo(-10, 1e-9));
    });

    test('excludes soft-deleted transactions from the totals', () async {
      await db
          .update(db.transactions)
          .write(const TransactionsCompanion(isDeleted: Value(true)));

      final rows = await repo.getCategoriesWithTotalsPaginated();
      // Money the user already threw away must not keep showing up in the
      // category totals.
      expect(rows.every((r) => r.total == 0.0), isTrue);
    });

    test('the name filter matches a substring', () async {
      final rows = await repo.getCategoriesWithTotalsPaginated(
        filters: const CategoryFilters(name: 'ala'),
      );

      expect(rows.map((r) => r.category.id), ['salary']);
    });

    test('the type filter restricts to that category type', () async {
      final rows = await repo.getCategoriesWithTotalsPaginated(
        filters: const CategoryFilters(type: CategoryType.income),
      );

      expect(rows.map((r) => r.category.id), ['salary']);
    });

    test('rows are ordered by name ascending by default', () async {
      final rows = await repo.getCategoriesWithTotalsPaginated();
      expect(rows.map((r) => r.category.name), ['Food', 'Salary', 'Zzz']);
    });

    test('Sort.descending flips the name ordering', () async {
      final rows = await repo.getCategoriesWithTotalsPaginated(
        filters: const CategoryFilters(sort: Sort.descending),
      );

      expect(rows.map((r) => r.category.name), ['Zzz', 'Salary', 'Food']);
    });

    test('honours limit and offset', () async {
      final page = await repo.getCategoriesWithTotalsPaginated(
        limit: 1,
        offset: 1,
      );

      expect(page.map((r) => r.category.name), ['Salary']);
    });
  });

  group('updateCategory', () {
    test('persists the change, bumps modifiedAt and logs an upsert', () async {
      await repo.addCategory(category('c1', name: 'Old'));
      final before = (await row('c1')).modifiedAt;
      await db.delete(db.syncLog).go();
      await Future<void>.delayed(const Duration(milliseconds: 5));

      await repo.updateCategory(
        category('c1', name: 'New', type: CategoryType.income),
      );

      final read = await repo.getCategoryById('c1');
      expect(read!.name, 'New');
      expect(read.type, CategoryType.income);
      // A stale modifiedAt loses last-write-wins against an older remote row.
      expect((await row('c1')).modifiedAt, greaterThan(before));
      expect(
        (await logsFor('categories')).map((l) => '${l.recordId}:${l.action}'),
        ['c1:upsert'],
      );
    });

    // Was a characterised bug: CategoriesDao.updateCategory called `_logChange`
    // unconditionally, ignoring whether the update wrote anything, so an update
    // aimed at an id that is not in the table still queued a sync row and the
    // export pass carried a record that does not exist. It now guards on the
    // row count, the way deleteCategory always has.
    test('an update that matched no row announces nothing', () async {
      await repo.updateCategory(category('ghost', name: 'Nope'));

      expect(await repo.getCategoryById('ghost'), isNull);
      expect(await logsFor('categories'), isEmpty);
    });
  });

  group('deleteCategoryWithTransactions', () {
    setUp(() async {
      await repo.addCategory(category('food', name: 'Food'));
      await repo.addCategory(category('other', name: 'Other'));
      await insertTransaction('t1', -10, categoryId: 'food');
      await insertTransaction('t2', -20, categoryId: 'food');
      await insertTransaction('keep', -30, categoryId: 'other');
      await db.delete(db.syncLog).go();
    });

    test('soft-deletes the category and its transactions', () async {
      await repo.deleteCategoryWithTransactions('food');

      expect(await repo.getCategoryById('food'), isNull);
      final txs = await db.select(db.transactions).get();
      expect(
        {for (final t in txs) t.id: t.isDeleted},
        {'t1': true, 't2': true, 'keep': false},
      );
    });

    test(
      'logs the deleted transactions under the transactions table name',
      () async {
        await repo.deleteCategoryWithTransactions('food');

        // Under the wrong table name the peer would look for accounts or
        // categories with these ids and never delete the transactions.
        expect(
          (await logsFor(
            'transactions',
          )).map((l) => '${l.recordId}:${l.action}'),
          containsAll(['t1:delete', 't2:delete']),
        );
        expect(
          (await logsFor('categories')).map((l) => '${l.recordId}:${l.action}'),
          ['food:delete'],
        );
      },
    );
  });

  group('deleteCategoryAndReassignTransactions', () {
    setUp(() async {
      await repo.addCategory(category('food', name: 'Food'));
      await repo.addCategory(category('other', name: 'Other'));
      await insertTransaction('t1', -10, categoryId: 'food');
      await db.delete(db.syncLog).go();
    });

    test('moves the transactions and keeps them alive', () async {
      await repo.deleteCategoryAndReassignTransactions('food', 'other');

      final t1 = await (db.select(
        db.transactions,
      )..where((t) => t.id.equals('t1'))).getSingle();
      expect(t1.categoryId, 'other');
      expect(t1.isDeleted, isFalse);
      expect(await repo.getCategoryById('food'), isNull);
    });

    test('announces the moved transactions as upserts, not deletes', () async {
      await repo.deleteCategoryAndReassignTransactions('food', 'other');

      // The rows survived, they only changed category; a 'delete' here would
      // wipe them on every other device.
      expect(
        (await logsFor('transactions')).map((l) => '${l.recordId}:${l.action}'),
        ['t1:upsert'],
      );
      expect(
        (await logsFor('categories')).map((l) => '${l.recordId}:${l.action}'),
        ['food:delete'],
      );
    });

    test('bumps modifiedAt on the moved transactions', () async {
      final t1 = await (db.select(
        db.transactions,
      )..where((t) => t.id.equals('t1'))).getSingle();
      final before = t1.modifiedAt;
      await Future<void>.delayed(const Duration(milliseconds: 5));

      await repo.deleteCategoryAndReassignTransactions('food', 'other');

      final after = await (db.select(
        db.transactions,
      )..where((t) => t.id.equals('t1'))).getSingle();
      expect(after.modifiedAt, greaterThan(before));
    });
  });
}
