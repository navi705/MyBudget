import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart'
    hide Transaction;

/// Characterization tests for soft delete (lib/core/database/app_database.dart):
/// every business-data DAO's `delete*` method flips `is_deleted` to true
/// rather than physically removing the row (each read-path method -
/// `getAllX`/`getXById`/`getXByIds` - filters `is_deleted = 0`). This pins
/// both halves of the contract:
///  1. normal read paths must NOT return a soft-deleted row;
///  2. the row must still physically exist afterwards (an unfiltered raw
///     `select` still finds it with `is_deleted = 1`) - a hard DELETE here
///     would silently break sync, since a peer that never saw the delete
///     has nothing to apply.
///
/// Known, deliberate gap (not tested around, per task instructions):
/// `api_settings_table` has NO `is_deleted` column at all
/// (ApiSettingsTable, app_database.dart ~366-378) - it isn't a soft-delete
/// candidate in the same way (only 3 fixed rows: exchange_rates/inflation/
/// assets, upserted not deleted), so it's excluded from this file entirely.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late String eurCode;
  late String languageCode;
  late String designationId;
  late String accountTypeId;

  setUpAll(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final currencies = await db.select(db.currencies).get();
    eurCode = currencies.firstWhere((c) => c.code == 'EUR').code;
    languageCode = (await db.select(db.languages).get()).first.languageCode;
    designationId = (await db.select(db.currencyDesignations).get()).first.id;
    accountTypeId = (await db.select(db.accountTypes).get()).first.id;
  });

  tearDownAll(() async {
    await db.close();
  });

  group('CategoriesDao', () {
    setUpAll(() async {
      await db.categoriesDao.insertCategory(
        CategoriesCompanion.insert(
          id: const Value('sd_cat_keep'),
          name: 'Keep',
        ),
      );
      await db.categoriesDao.insertCategory(
        CategoriesCompanion.insert(
          id: const Value('sd_cat_gone'),
          name: 'Gone',
        ),
      );
      await db.categoriesDao.deleteCategory(
        CategoriesCompanion(id: const Value('sd_cat_gone')),
      );
    });

    test('getAllCategories excludes the soft-deleted row', () async {
      final all = await db.categoriesDao.getAllCategories();
      expect(all.any((c) => c.id == 'sd_cat_gone'), isFalse);
      expect(all.any((c) => c.id == 'sd_cat_keep'), isTrue);
    });

    test('getCategoryById returns null for the soft-deleted row', () async {
      expect(await db.categoriesDao.getCategoryById('sd_cat_gone'), isNull);
      expect(await db.categoriesDao.getCategoryById('sd_cat_keep'), isNotNull);
    });

    test('getCategoriesByIds silently drops the soft-deleted id', () async {
      final result = await db.categoriesDao.getCategoriesByIds([
        'sd_cat_keep',
        'sd_cat_gone',
      ]);
      expect(result.map((c) => c.id), ['sd_cat_keep']);
    });

    test(
      'the row still physically exists (is_deleted=1), not hard-deleted - '
      'a peer that has not synced yet must still be able to see it',
      () async {
        final raw = await (db.select(
          db.categories,
        )..where((t) => t.id.equals('sd_cat_gone'))).getSingleOrNull();
        expect(raw, isNotNull);
        expect(raw!.isDeleted, isTrue);
      },
    );
  });

  group('StylesDao', () {
    setUpAll(() async {
      await db.stylesDao.insertStyle(
        StylesCompanion.insert(
          id: const Value('sd_style_keep'),
          name: 'Keep',
          iconName: 'star',
          colorHex: '#111111',
        ),
      );
      await db.stylesDao.insertStyle(
        StylesCompanion.insert(
          id: const Value('sd_style_gone'),
          name: 'Gone',
          iconName: 'star',
          colorHex: '#222222',
        ),
      );
      await db.stylesDao.deleteStyle(
        StylesCompanion(id: const Value('sd_style_gone')),
      );
    });

    test('getAllStyles excludes the soft-deleted row', () async {
      final all = await db.stylesDao.getAllStyles();
      expect(all.any((s) => s.id == 'sd_style_gone'), isFalse);
      expect(all.any((s) => s.id == 'sd_style_keep'), isTrue);
    });

    test('getStyleById returns null for the soft-deleted row', () async {
      expect(await db.stylesDao.getStyleById('sd_style_gone'), isNull);
    });

    test('the row still physically exists (is_deleted=1)', () async {
      final raw = await (db.select(
        db.styles,
      )..where((t) => t.id.equals('sd_style_gone'))).getSingleOrNull();
      expect(raw, isNotNull);
      expect(raw!.isDeleted, isTrue);
    });
  });

  group('AccountTypesDao', () {
    setUpAll(() async {
      await db.accountTypesDao.insertAccountType(
        AccountTypesCompanion.insert(
          id: const Value('sd_at_keep'),
          name: 'AT Keep',
          languageCode: languageCode,
        ),
      );
      await db.accountTypesDao.insertAccountType(
        AccountTypesCompanion.insert(
          id: const Value('sd_at_gone'),
          name: 'AT Gone',
          languageCode: languageCode,
        ),
      );
      await db.accountTypesDao.deleteAccountType(
        AccountTypesCompanion(id: const Value('sd_at_gone')),
      );
    });

    test('getAllAccountTypes excludes the soft-deleted row', () async {
      final all = await db.accountTypesDao.getAllAccountTypes();
      expect(all.any((a) => a.id == 'sd_at_gone'), isFalse);
      expect(all.any((a) => a.id == 'sd_at_keep'), isTrue);
    });

    test('the row still physically exists (is_deleted=1)', () async {
      final raw = await (db.select(
        db.accountTypes,
      )..where((t) => t.id.equals('sd_at_gone'))).getSingleOrNull();
      expect(raw, isNotNull);
      expect(raw!.isDeleted, isTrue);
    });
  });

  group('CurrencyDesignationsDao', () {
    setUpAll(() async {
      await db.currencyDesignationsDao.insertDesignation(
        CurrencyDesignationsCompanion.insert(
          id: const Value('sd_desig_keep'),
          value: '@',
          currencyCode: eurCode,
        ),
      );
      await db.currencyDesignationsDao.insertDesignation(
        CurrencyDesignationsCompanion.insert(
          id: const Value('sd_desig_gone'),
          value: '#',
          currencyCode: eurCode,
        ),
      );
      await db.currencyDesignationsDao.deleteDesignation(
        CurrencyDesignationsCompanion(id: const Value('sd_desig_gone')),
      );
    });

    test('getAllDesignations excludes the soft-deleted row', () async {
      final all = await db.currencyDesignationsDao.getAllDesignations();
      expect(all.any((d) => d.id == 'sd_desig_gone'), isFalse);
      expect(all.any((d) => d.id == 'sd_desig_keep'), isTrue);
    });

    test('the row still physically exists (is_deleted=1)', () async {
      final raw = await (db.select(
        db.currencyDesignations,
      )..where((t) => t.id.equals('sd_desig_gone'))).getSingleOrNull();
      expect(raw, isNotNull);
      expect(raw!.isDeleted, isTrue);
    });
  });

  group('AccountsDao', () {
    setUpAll(() async {
      await db.accountsDao.insertAccount(
        AccountsCompanion.insert(
          id: const Value('sd_acc_keep'),
          name: 'Acc Keep',
          balance: 10.0,
          currencyCode: eurCode,
          currencyDesignationId: designationId,
          accountTypeId: accountTypeId,
        ),
      );
      await db.accountsDao.insertAccount(
        AccountsCompanion.insert(
          id: const Value('sd_acc_gone'),
          name: 'Acc Gone',
          balance: 20.0,
          currencyCode: eurCode,
          currencyDesignationId: designationId,
          accountTypeId: accountTypeId,
        ),
      );
      await db.accountsDao.deleteAccount(
        AccountsCompanion(id: const Value('sd_acc_gone')),
      );
    });

    test('getAllAccounts excludes the soft-deleted row', () async {
      final all = await db.accountsDao.getAllAccounts();
      expect(all.any((a) => a.id == 'sd_acc_gone'), isFalse);
      expect(all.any((a) => a.id == 'sd_acc_keep'), isTrue);
    });

    test('getAccountById returns null for the soft-deleted row', () async {
      expect(await db.accountsDao.getAccountById('sd_acc_gone'), isNull);
    });

    test(
      'the row still physically exists with balance intact - a hard '
      'DELETE would lose the balance figure entirely, not just hide it',
      () async {
        final raw = await (db.select(
          db.accounts,
        )..where((t) => t.id.equals('sd_acc_gone'))).getSingleOrNull();
        expect(raw, isNotNull);
        expect(raw!.isDeleted, isTrue);
        expect(raw.balance, 20.0);
      },
    );
  });

  group('TransactionsDao', () {
    late String accId;
    late String catId;

    setUpAll(() async {
      accId = 'sd_tx_acc';
      catId = 'sd_tx_cat';
      await db.accountsDao.insertAccount(
        AccountsCompanion.insert(
          id: Value(accId),
          name: 'Tx Account',
          balance: 100.0,
          currencyCode: eurCode,
          currencyDesignationId: designationId,
          accountTypeId: accountTypeId,
        ),
      );
      await db.categoriesDao.insertCategory(
        CategoriesCompanion.insert(id: Value(catId), name: 'Tx Category'),
      );
      await db.transactionsDao.insertTransaction(
        TransactionsCompanion.insert(
          id: const Value('sd_tx_keep'),
          description: 'Keep',
          amount: -5.0,
          date: DateTime(2025, 3, 1),
          accountId: accId,
          categoryId: catId,
          currencyCode: eurCode,
        ),
      );
      await db.transactionsDao.insertTransaction(
        TransactionsCompanion.insert(
          id: const Value('sd_tx_gone'),
          description: 'Gone',
          amount: -50.0,
          date: DateTime(2025, 3, 2),
          accountId: accId,
          categoryId: catId,
          currencyCode: eurCode,
        ),
      );
      await db.transactionsDao.deleteTransaction(
        TransactionsCompanion(id: const Value('sd_tx_gone')),
      );
    });

    test('getAllTransactions excludes the soft-deleted row', () async {
      final all = await db.transactionsDao.getAllTransactions();
      expect(all.any((t) => t.id == 'sd_tx_gone'), isFalse);
      expect(all.any((t) => t.id == 'sd_tx_keep'), isTrue);
    });

    test('getTransactionById returns null for the soft-deleted row', () async {
      expect(await db.transactionsDao.getTransactionById('sd_tx_gone'), isNull);
    });

    test('getTransactionsByCategoryId excludes the soft-deleted row', () async {
      final result = await db.transactionsDao.getTransactionsByCategoryId(
        catId,
      );
      expect(result.any((t) => t.id == 'sd_tx_gone'), isFalse);
      expect(result.any((t) => t.id == 'sd_tx_keep'), isTrue);
    });

    test('the row still physically exists with amount intact (money not '
        'lost, only hidden from normal reads)', () async {
      final raw = await (db.select(
        db.transactions,
      )..where((t) => t.id.equals('sd_tx_gone'))).getSingleOrNull();
      expect(raw, isNotNull);
      expect(raw!.isDeleted, isTrue);
      expect(raw.amount, -50.0);
    });
  });
}
