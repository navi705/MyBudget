import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_budget_client/core/database/app_database.dart'
    hide Transaction;
import 'package:my_budget_client/data/repositories/local_db/local_account_repository.dart';
import 'package:my_budget_client/data/repositories/local_db/local_asset_repository.dart';
import 'package:my_budget_client/data/repositories/local_db/local_category_repository.dart';
import 'package:my_budget_client/data/repositories/local_db/local_style_repository.dart';
import 'package:my_budget_client/domain/entities/account.dart' as domain;
import 'package:my_budget_client/domain/entities/asset_data.dart';
import 'package:my_budget_client/domain/entities/category.dart' as domain_cat;
import 'package:my_budget_client/domain/entities/icon_type.dart';
import 'package:my_budget_client/domain/entities/style.dart' as domain_sty;

/// An edit must not undo a delete.
///
/// Every `update*` DAO method used to be `update(table).replace(companion)`.
/// `replace` rewrites the *whole* row: for each column carrying a
/// `withDefault(...)` that the companion did not set, it writes the column
/// default rather than leaving the stored value alone (drift 2.29.0,
/// `UpdateStatement.replace`, update.dart:124-154). Every domain->companion
/// mapper in lib/core/mappers builds a companion out of the fields the user can
/// edit, and not one of them sets `isDeleted` - so `replace` wrote
/// `is_deleted = 0` on every single update.
///
/// The user-visible failure: a sync pull tombstones a row (sync_service_io.dart
/// applies a peer's delete as `isDeleted: Value(true)`) while the row is still
/// on screen in a list or an open form. The user saves an unrelated edit; the
/// row is silently un-deleted, and because every `update*` stamps a fresh
/// `modifiedAt` the resurrection then *wins* last-write-wins on every other
/// device. The deleted category/style/account/holding comes back everywhere.
///
/// The same mechanism blanks defaulted non-sync columns: a theme companion
/// without `surfaceOpacity` reset the user's tuned surface to 1.0, and a
/// currency companion without `modifiedAt` stamped 0, which makes the edit look
/// older than every remote copy.
///
/// The fix is `(update(t)..where(id))..write(companion)`, which uses
/// `toColumns(true)` and leaves absent fields untouched. `write` also returns a
/// row count, so `_logChange` can stop announcing ids that were never written.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LocalCategoryRepository categoryRepo;
  late LocalStyleRepository styleRepo;
  late LocalAccountRepository accountRepo;
  late LocalAssetRepository assetRepo;

  late String eurCode;
  late String languageCode;
  late String designationId;
  late String accountTypeId;

  // Opening the database seeds exchange rates, and each seeded row's sync
  // record id is built with a locale-pinned DateFormat. Load its CLDR data
  // before that runs.
  setUpAll(() async {
    await initializeDateFormatting();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    categoryRepo = LocalCategoryRepository(db);
    styleRepo = LocalStyleRepository(db);
    accountRepo = LocalAccountRepository(db);
    assetRepo = LocalAssetRepository(db.assetEntriesDao);

    eurCode = 'EUR';
    languageCode = (await db.select(db.languages).get()).first.languageCode;
    designationId = (await db.select(db.currencyDesignations).get()).first.id;
    accountTypeId = (await db.select(db.accountTypes).get()).first.id;
  });

  tearDownAll(() async => db.close());

  setUp(() async => db.delete(db.syncLog).go());

  Future<List<SyncLogData>> logsFor(String table, String recordId) =>
      (db.select(db.syncLog)
            ..where((l) => l.changedTableName.equals(table))
            ..where((l) => l.recordId.equals(recordId)))
          .get();

  // Raw, unfiltered reads: the point of every test below is what the row
  // physically holds, which the DAO getters deliberately hide.
  Future<Category> rawCategory(String id) =>
      (db.select(db.categories)..where((t) => t.id.equals(id))).getSingle();
  Future<Style> rawStyle(String id) =>
      (db.select(db.styles)..where((t) => t.id.equals(id))).getSingle();
  Future<DbAccount> rawAccount(String id) =>
      (db.select(db.accounts)..where((t) => t.id.equals(id))).getSingle();
  Future<AssetEntry> rawAsset(String id) =>
      (db.select(db.assetEntries)..where((t) => t.id.equals(id))).getSingle();

  Future<void> insertAccountRow(String id, {double balance = 100}) =>
      db.accountsDao.insertAccount(
        AccountsCompanion.insert(
          id: Value(id),
          name: 'Account $id',
          balance: balance,
          balanceMinor: Value((balance * 100).round()),
          currencyCode: eurCode,
          currencyDesignationId: designationId,
          accountTypeId: accountTypeId,
        ),
      );

  domain.Account accountEntity(String id, {String name = 'Renamed'}) =>
      domain.Account(
        id: id,
        name: name,
        balance: 100,
        balanceMinor: 10000,
        currencyCode: eurCode,
        currencyDesignationId: designationId,
        accountTypeId: accountTypeId,
        creationDate: DateTime(2024, 1, 1),
      );

  group('an edit through the real repository must not resurrect a tombstone', () {
    test(
      'a deleted category stays deleted when the user saves an edit',
      () async {
        // The user creates a category, and it is deleted - here directly, on a
        // real device by a sync pull applying another device's delete while the
        // category list is still on screen.
        await categoryRepo.addCategory(
          domain_cat.Category(id: 'res_cat', name: 'Groceries'),
        );
        await db.categoriesDao.deleteCategory(
          CategoriesCompanion(id: const Value('res_cat')),
        );
        expect((await rawCategory('res_cat')).isDeleted, isTrue);

        // The stale copy still in the UI is saved with a new name.
        await categoryRepo.updateCategory(
          domain_cat.Category(id: 'res_cat', name: 'Groceries & Household'),
        );

        expect(
          (await rawCategory('res_cat')).isDeleted,
          isTrue,
          reason: 'saving an edit must not undo the delete',
        );
        expect(await categoryRepo.getCategoryById('res_cat'), isNull);
      },
    );

    test('a deleted style stays deleted when the user saves an edit', () async {
      await styleRepo.addStyle(
        domain_sty.Style(
          id: 'res_sty',
          name: 'Rent',
          iconName: 'home',
          colorHex: '#FF0000',
          iconType: IconType.material,
        ),
      );
      await db.stylesDao.deleteStyle(
        StylesCompanion(id: const Value('res_sty')),
      );
      expect((await rawStyle('res_sty')).isDeleted, isTrue);

      await styleRepo.updateStyle(
        domain_sty.Style(
          id: 'res_sty',
          name: 'Rent & Bills',
          iconName: 'home',
          colorHex: '#00FF00',
          iconType: IconType.material,
        ),
      );

      expect((await rawStyle('res_sty')).isDeleted, isTrue);
      expect(await styleRepo.getStyleById('res_sty'), isNull);
    });

    test(
      'a deleted account stays deleted when the user saves an edit',
      () async {
        await insertAccountRow('res_acc');
        await db.accountsDao.deleteAccount(
          AccountsCompanion(id: const Value('res_acc')),
        );
        expect((await rawAccount('res_acc')).isDeleted, isTrue);

        // AccountsBloc hands `event.account` straight to the repository with no
        // re-read, so a stale entity from the list is exactly what arrives here.
        await accountRepo.updateAccount(accountEntity('res_acc'));

        expect(
          (await rawAccount('res_acc')).isDeleted,
          isTrue,
          reason:
              'a resurrected account puts its whole balance back into every '
              'total, on this device and - via the fresh modifiedAt - on every '
              'peer',
        );
        expect(await db.accountsDao.getAccountById('res_acc'), isNull);
      },
    );

    test(
      'a deleted asset entry stays deleted when the user saves an edit',
      () async {
        await assetRepo.addAssetData(
          AssetDataDomain(
            id: 'res_ast',
            assetId: 'BTC',
            name: 'Bitcoin',
            date: DateTime(2024, 1, 1),
            value: 100,
            quantity: 1,
            currency: eurCode,
            source: 'manual',
            preset: 1,
          ),
        );
        await db.assetEntriesDao.deleteAssetEntry('res_ast');
        expect((await rawAsset('res_ast')).isDeleted, isTrue);

        await assetRepo.updateAssetData(
          AssetDataDomain(
            id: 'res_ast',
            assetId: 'BTC',
            name: 'Bitcoin',
            date: DateTime(2024, 1, 1),
            value: 250,
            quantity: 1,
            currency: eurCode,
            source: 'manual',
            preset: 1,
          ),
        );

        expect((await rawAsset('res_ast')).isDeleted, isTrue);
        expect(await db.assetEntriesDao.getAssetEntryById('res_ast'), isNull);
      },
    );
  });

  group('the DAOs called directly must not resurrect a tombstone either', () {
    test('updateTransaction leaves a deleted transaction deleted', () async {
      await insertAccountRow('res_tx_acc');
      await db.categoriesDao.insertCategory(
        CategoriesCompanion.insert(
          id: const Value('res_tx_cat'),
          name: 'Tx Cat',
        ),
      );
      await db.transactionsDao.insertTransaction(
        TransactionsCompanion.insert(
          id: const Value('res_tx'),
          description: 'Coffee',
          amount: -5,
          date: DateTime(2025, 1, 1),
          accountId: 'res_tx_acc',
          categoryId: 'res_tx_cat',
          currencyCode: eurCode,
        ),
      );
      await db.transactionsDao.deleteTransaction(
        TransactionsCompanion(id: const Value('res_tx')),
      );

      // Exactly what TransactionMapper.toCompanion produces: no isDeleted.
      await db.transactionsDao.updateTransaction(
        TransactionsCompanion(
          id: const Value('res_tx'),
          description: const Value('Coffee, large'),
          amount: const Value(-7),
          date: Value(DateTime(2025, 1, 1)),
          accountId: const Value('res_tx_acc'),
          categoryId: const Value('res_tx_cat'),
          currencyCode: Value(eurCode),
          fee: const Value(0),
        ),
      );

      final raw = await (db.select(
        db.transactions,
      )..where((t) => t.id.equals('res_tx'))).getSingle();
      expect(raw.isDeleted, isTrue);
    });

    test('updateAccountType leaves a deleted account type deleted', () async {
      await db.accountTypesDao.insertAccountType(
        AccountTypesCompanion.insert(
          id: const Value('res_at'),
          name: 'Res Savings',
          languageCode: languageCode,
        ),
      );
      await db.accountTypesDao.deleteAccountType(
        AccountTypesCompanion(id: const Value('res_at')),
      );

      // Exactly what AccountTypeMapper.toCompanion produces: no isDeleted.
      await db.accountTypesDao.updateAccountType(
        AccountTypesCompanion(
          id: const Value('res_at'),
          name: const Value('Res Savings Plus'),
          languageCode: Value(languageCode),
        ),
      );

      final raw = await (db.select(
        db.accountTypes,
      )..where((t) => t.id.equals('res_at'))).getSingle();
      expect(raw.isDeleted, isTrue);
    });

    test('updateTheme leaves a deleted theme deleted', () async {
      await db.customThemesDao.insertTheme(
        CustomThemesCompanion.insert(
          id: const Value('res_thm'),
          name: 'Midnight',
          primaryColorHex: '#111111',
          secondaryColorHex: '#222222',
          surfaceColorHex: '#333333',
          backgroundColorHex: '#444444',
          windowEffectType: 2,
          themeMode: 1,
        ),
      );
      await db.customThemesDao.deleteTheme('res_thm');

      await db.customThemesDao.updateTheme(
        const CustomThemesCompanion(
          id: Value('res_thm'),
          name: Value('Midnight Renamed'),
        ),
      );

      final raw = await (db.select(
        db.customThemes,
      )..where((t) => t.id.equals('res_thm'))).getSingle();
      expect(raw.isDeleted, isTrue);
    });

    test('updatePreset leaves a deleted SMS preset deleted and off', () async {
      await db.smsPresetsDao.insertPreset(
        SmsPresetsCompanion.insert(
          id: const Value('res_sms'),
          name: 'Bank A',
          senderFilter: 'BANKA',
          isEnabled: const Value(false),
          rulesJson: '[]',
        ),
      );
      await db.smsPresetsDao.deletePreset('res_sms');

      await db.smsPresetsDao.updatePreset(
        const SmsPresetsCompanion(
          id: Value('res_sms'),
          name: Value('Bank A (EU)'),
        ),
      );

      final raw = await (db.select(
        db.smsPresets,
      )..where((t) => t.id.equals('res_sms'))).getSingle();
      expect(raw.isDeleted, isTrue);
      expect(
        raw.isEnabled,
        isFalse,
        reason:
            'isEnabled defaults to true, so a whole-row rewrite silently '
            'switched a disabled preset back on',
      );
    });
  });

  group('a defaulted column the caller did not mention must survive', () {
    test(
      'a theme rename keeps the surface and effect opacities the user set',
      () async {
        await db.customThemesDao.insertTheme(
          CustomThemesCompanion.insert(
            id: const Value('opa_thm'),
            name: 'Glass',
            primaryColorHex: '#111111',
            secondaryColorHex: '#222222',
            surfaceColorHex: '#333333',
            backgroundColorHex: '#444444',
            windowEffectType: 2,
            themeMode: 1,
            surfaceOpacity: const Value(0.35),
            effectOpacity: const Value(0.6),
          ),
        );

        await db.customThemesDao.updateTheme(
          const CustomThemesCompanion(
            id: Value('opa_thm'),
            name: Value('Glass Dark'),
          ),
        );

        final raw = await (db.select(
          db.customThemes,
        )..where((t) => t.id.equals('opa_thm'))).getSingle();
        expect(raw.name, 'Glass Dark');
        expect(raw.surfaceOpacity, 0.35);
        expect(raw.effectOpacity, 0.6);
      },
    );

    test(
      'renaming a currency bumps modifiedAt instead of stamping 0',
      () async {
        await db.currenciesDao.insertCurrency(
          CurrenciesCompanion.insert(
            name: 'Zeta Nine',
            code: 'ZZ9',
            languageCode: languageCode,
          ),
        );
        final before = DateTime.now().millisecondsSinceEpoch;

        // Exactly what CurrencyMapper.toCompanion produces: no modifiedAt.
        await db.currenciesDao.updateCurrency(
          CurrenciesCompanion(
            code: const Value('ZZ9'),
            name: const Value('Zeta Renamed'),
            languageCode: Value(languageCode),
          ),
        );

        final raw = await (db.select(
          db.currencies,
        )..where((t) => t.code.equals('ZZ9'))).getSingle();
        expect(raw.name, 'Zeta Renamed');
        expect(
          raw.modifiedAt,
          greaterThanOrEqualTo(before),
          reason:
              'modified_at = 0 makes the rename look older than every remote '
              'copy, so last-write-wins throws it away and the old name comes '
              'back on the next sync',
        );
      },
    );
  });

  group('an update that matched no row must announce nothing', () {
    test('updateCategory on an unknown id logs no change', () async {
      final changed = await db.categoriesDao.updateCategory(
        const CategoriesCompanion(id: Value('ghost_cat'), name: Value('Nope')),
      );
      expect(changed, isFalse);
      expect(await logsFor('categories', 'ghost_cat'), isEmpty);
    });

    test('updateAccount on an unknown id logs no change', () async {
      final changed = await db.accountsDao.updateAccount(
        AccountsCompanion(
          id: const Value('ghost_acc'),
          name: const Value('Nope'),
          balance: const Value(1),
          currencyCode: Value(eurCode),
          currencyDesignationId: Value(designationId),
          accountTypeId: Value(accountTypeId),
        ),
      );
      expect(changed, isFalse);
      expect(await logsFor('accounts', 'ghost_acc'), isEmpty);
    });

    test('updateTransaction on an unknown id logs no change', () async {
      final changed = await db.transactionsDao.updateTransaction(
        TransactionsCompanion(
          id: const Value('ghost_tx'),
          description: const Value('Nope'),
          amount: const Value(-1),
          date: Value(DateTime(2025, 1, 1)),
          accountId: const Value('res_tx_acc'),
          categoryId: const Value('res_tx_cat'),
          currencyCode: Value(eurCode),
        ),
      );
      expect(changed, isFalse);
      expect(await logsFor('transactions', 'ghost_tx'), isEmpty);
    });

    test('updateTheme on an unknown id logs no change', () async {
      final changed = await db.customThemesDao.updateTheme(
        const CustomThemesCompanion(
          id: Value('ghost_thm'),
          name: Value('Nope'),
        ),
      );
      expect(changed, isFalse);
      expect(await logsFor('custom_themes', 'ghost_thm'), isEmpty);
    });

    test('updateAssetData on an unknown id logs no change', () async {
      await db.assetEntriesDao.updateAssetData(
        AssetEntriesCompanion(
          id: const Value('ghost_ast'),
          assetId: const Value('BTC'),
          name: const Value('Nope'),
          date: Value(DateTime(2024, 1, 1)),
          value: const Value(1),
          currencyCode: Value(eurCode),
          source: const Value('manual'),
        ),
      );
      expect(await logsFor('asset_entries', 'ghost_ast'), isEmpty);
    });
  });
}
