import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart'
    hide Transaction;
import 'package:my_budget_client/data/repositories/local_db/local_currency_repository.dart';

/// What the currency picker orders itself by: the codes the user starred and
/// the codes they already have money in. Neither is a new table - the stars
/// live in the settings key/value store and the counts are read back out of
/// the accounts and transactions that were written anyway - so these tests are
/// the only thing pinning either shape.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LocalCurrencyRepository repository;
  late String designationId;
  late String accountTypeId;
  late String categoryId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = LocalCurrencyRepository(db);
    designationId = (await db.select(db.currencyDesignations).get()).first.id;
    accountTypeId = (await db.select(db.accountTypes).get()).first.id;
    await db.categoriesDao.insertCategory(
      CategoriesCompanion.insert(id: const Value('cat'), name: 'Food'),
    );
    categoryId = 'cat';
  });

  tearDown(() async => db.close());

  Future<void> addAccount(String id, String currencyCode) {
    return db.accountsDao.insertAccount(
      AccountsCompanion.insert(
        id: Value(id),
        name: id,
        balance: 0,
        currencyCode: currencyCode,
        currencyDesignationId: designationId,
        accountTypeId: accountTypeId,
      ),
    );
  }

  Future<void> addTransaction(String id, String accountId, String code) {
    return db.transactionsDao.insertTransaction(
      TransactionsCompanion.insert(
        id: Value(id),
        description: id,
        amount: 10,
        date: DateTime(2026, 1, 1),
        accountId: accountId,
        categoryId: categoryId,
        currencyCode: code,
      ),
    );
  }

  group('usage counts', () {
    test('count the accounts and the transactions in each currency', () async {
      await addAccount('a_eur', 'EUR');
      await addAccount('a_usd', 'USD');
      await addTransaction('t1', 'a_eur', 'EUR');
      await addTransaction('t2', 'a_eur', 'EUR');

      final counts = await repository.getCurrencyUsageCounts();

      expect(counts['EUR'], 3);
      expect(counts['USD'], 1);
    });

    test('leave out a currency the user has never used', () async {
      await addAccount('a_eur', 'EUR');

      final counts = await repository.getCurrencyUsageCounts();

      // Absent rather than zero: the picker lifts what is in this map above
      // the alphabetical list, and a zero would lift all 341 of them.
      expect(counts.containsKey('JPY'), isFalse);
    });

    test('drop what the user deleted', () async {
      await addAccount('a_eur', 'EUR');
      await addAccount('a_usd', 'USD');
      await addTransaction('t1', 'a_usd', 'USD');
      await db.transactionsDao.deleteTransaction(
        const TransactionsCompanion(id: Value('t1')),
      );
      await db.accountsDao.deleteAccount(
        const AccountsCompanion(id: Value('a_usd')),
      );

      final counts = await repository.getCurrencyUsageCounts();

      expect(counts['EUR'], 1);
      // Both rows still physically exist - the delete is a soft one - so a
      // count that did not filter would still report USD as in use.
      expect(counts.containsKey('USD'), isFalse);
    });
  });

  group('favorites', () {
    test('start empty', () async {
      expect(await repository.getFavoriteCurrencyCodes(), isEmpty);
    });

    test('keep the order they were starred in', () async {
      await repository.setFavoriteCurrency('USD', favorite: true);
      await repository.setFavoriteCurrency('EUR', favorite: true);

      expect(await repository.getFavoriteCurrencyCodes(), ['USD', 'EUR']);
    });

    test('starring one that is already starred adds nothing', () async {
      await repository.setFavoriteCurrency('USD', favorite: true);
      await repository.setFavoriteCurrency('USD', favorite: true);

      expect(await repository.getFavoriteCurrencyCodes(), ['USD']);
    });

    test('unstarring removes only that one', () async {
      await repository.setFavoriteCurrency('USD', favorite: true);
      await repository.setFavoriteCurrency('EUR', favorite: true);
      await repository.setFavoriteCurrency('USD', favorite: false);

      expect(await repository.getFavoriteCurrencyCodes(), ['EUR']);
    });

    test('unstarring one that was never starred is not an error', () async {
      await repository.setFavoriteCurrency('EUR', favorite: false);

      expect(await repository.getFavoriteCurrencyCodes(), isEmpty);
    });

    test('the stored setting carries a modification time', () async {
      await repository.setFavoriteCurrency('USD', favorite: true);

      final setting = await db.settingsDao.getSetting(
        'favorite_currency_codes',
      );
      // Settings sync last-write-wins. A row left at 0 loses to every peer's
      // untouched default, so the stars would come back off on the next pull.
      expect(setting, isNotNull);
      expect(setting!.modifiedAt, greaterThan(0));
    });

    test('the watch stream reports the list as it changes', () async {
      final seen = <List<String>>[];
      final subscription = repository.watchFavoriteCurrencyCodes().listen(
        seen.add,
      );
      addTearDown(subscription.cancel);

      await repository.setFavoriteCurrency('USD', favorite: true);
      await repository.setFavoriteCurrency('EUR', favorite: true);
      await Future<void>.delayed(Duration.zero);

      expect(seen.last, ['USD', 'EUR']);
    });
  });
}
