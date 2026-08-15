import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_budget_client/core/database/app_database.dart'
    hide Transaction;

/// Characterization tests: every local mutation to a user-data table must
/// also write a row to `sync_log` (changedTableName/recordId/action/
/// timestamp), or the change never reaches another device on next sync
/// (see SyncLogDao, lib/core/database/app_database.dart ~3867-3906, and each
/// DAO's private `_logChange`/`_logChanges` helper). These tests pin the
/// DAOs confirmed (by reading the source) to log correctly, so a regression
/// (someone adding a raw `update(...)...write(...)` without the
/// `_logChange` call, as already happened elsewhere — see below) is caught.
///
/// The four gaps this file used to only *describe* are now fixed in the DAOs
/// and pinned by the `regression fixes` groups at the bottom:
/// AccountsDao.updateAccountTypeForMultipleAccounts, the whole of
/// CustomThemesDao, CurrenciesDao.insertCurrency, and the two
/// CategoriesDao.deleteCategory*Transactions methods.
///
/// Checked and NOT a bug (by design / unreachable, not reported):
///  - LanguageDao.insertLanguage/updateLanguage/deleteLanguage: no
///    `_logChange`, but grepping lib/ found zero call sites outside the DAO
///    itself — dead code, languages are seed-only static reference data.
///  - SmsPresetsDao.insertPreset/updatePreset/deletePreset: no
///    `_logChange`, but `LocalSmsRepository` (native) persists presets to
///    SharedPreferences JSON directly (local_sms_repository_native.dart
///    savePreset/deletePreset/togglePreset) and never calls these DAO
///    methods at all — the `sms_presets` SQL table is dead from the app's
///    perspective (only read by data_export_service.dart:49).
///  - ApiFetchStatusesDao: no SyncLog table access at all
///    (`@DriftAccessor(tables: [ApiFetchStatuses])`); tracks per-device API
///    fetch attempt counters, plausibly intentional device-local state.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late String eurCode;
  late String languageCode;
  late String designationId;
  late String accountTypeId;

  Future<List<SyncLogData>> logsFor(String table, String recordId) {
    return (db.select(db.syncLog)
          ..where((t) => t.changedTableName.equals(table))
          ..where((t) => t.recordId.equals(recordId)))
        .get();
  }

  setUpAll(() async {
    // Opening the database seeds exchange rates, and each seeded row's sync
    // record id is built with a locale-pinned DateFormat. Load its CLDR data
    // before that runs.
    await initializeDateFormatting();
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
    test('insertCategory logs exactly one upsert row', () async {
      await db.categoriesDao.insertCategory(
        CategoriesCompanion.insert(
          id: const Value('sl_cat_1'),
          name: 'SL Cat 1',
        ),
      );
      final logs = await logsFor('categories', 'sl_cat_1');
      // Would fail if insertCategory's _logChange call were removed.
      expect(logs.length, 1);
      expect(logs.single.action, 'upsert');
    });

    test('updateCategory logs an additional upsert row', () async {
      final cat = await db.categoriesDao.getCategoryById('sl_cat_1');
      await db.categoriesDao.updateCategory(
        cat!.toCompanion(true).copyWith(name: const Value('Renamed')),
      );
      final logs = await logsFor('categories', 'sl_cat_1');
      // 1 from insert + 1 from this update; would fail if updateCategory
      // stopped calling _logChange.
      expect(logs.where((l) => l.action == 'upsert').length, 2);
    });

    test('deleteCategory logs a delete row', () async {
      final cat = await db.categoriesDao.getCategoryById('sl_cat_1');
      await db.categoriesDao.deleteCategory(cat!.toCompanion(true));
      final logs = await logsFor('categories', 'sl_cat_1');
      expect(logs.any((l) => l.action == 'delete'), isTrue);
    });

    test(
      'insertAllCategories (bulk) logs one upsert row per category',
      () async {
        await db.categoriesDao.insertAllCategories([
          CategoriesCompanion.insert(
            id: const Value('sl_cat_bulk_1'),
            name: 'Bulk 1',
          ),
          CategoriesCompanion.insert(
            id: const Value('sl_cat_bulk_2'),
            name: 'Bulk 2',
          ),
        ]);
        // Would fail if insertAllCategories' _logChanges(ids, 'upsert') were
        // removed or only logged the first id.
        expect((await logsFor('categories', 'sl_cat_bulk_1')).length, 1);
        expect((await logsFor('categories', 'sl_cat_bulk_2')).length, 1);
      },
    );
  });

  group('StylesDao', () {
    test('insertStyle / updateStyle / deleteStyle each log', () async {
      await db.stylesDao.insertStyle(
        StylesCompanion.insert(
          id: const Value('sl_style_1'),
          name: 'SL Style',
          iconName: 'star',
          colorHex: '#FFFFFF',
        ),
      );
      expect((await logsFor('styles', 'sl_style_1')).single.action, 'upsert');

      final style = await db.stylesDao.getStyleById('sl_style_1');
      await db.stylesDao.updateStyle(
        style!.toCompanion(true).copyWith(colorHex: const Value('#000000')),
      );
      expect(
        (await logsFor(
          'styles',
          'sl_style_1',
        )).where((l) => l.action == 'upsert').length,
        2,
      );

      await db.stylesDao.deleteStyle(style.toCompanion(true));
      expect(
        (await logsFor(
          'styles',
          'sl_style_1',
        )).any((l) => l.action == 'delete'),
        isTrue,
      );
    });
  });

  group('AccountTypesDao', () {
    test('insertAccountType / updateAccountType / deleteAccountType each '
        'log', () async {
      await db.accountTypesDao.insertAccountType(
        AccountTypesCompanion.insert(
          id: const Value('sl_at_1'),
          name: 'SL Account Type',
          languageCode: languageCode,
        ),
      );
      expect(
        (await logsFor('account_types', 'sl_at_1')).single.action,
        'upsert',
      );

      final at = await db.accountTypesDao.getAccountTypeById('sl_at_1');
      await db.accountTypesDao.updateAccountType(
        at!.toCompanion(true).copyWith(name: const Value('Renamed AT')),
      );
      expect(
        (await logsFor(
          'account_types',
          'sl_at_1',
        )).where((l) => l.action == 'upsert').length,
        2,
      );

      await db.accountTypesDao.deleteAccountType(at.toCompanion(true));
      expect(
        (await logsFor(
          'account_types',
          'sl_at_1',
        )).any((l) => l.action == 'delete'),
        isTrue,
      );
    });
  });

  group('CurrencyDesignationsDao', () {
    test('insertDesignation / updateDesignation / deleteDesignation each '
        'log', () async {
      await db.currencyDesignationsDao.insertDesignation(
        CurrencyDesignationsCompanion.insert(
          id: const Value('sl_desig_1'),
          value: '@',
          currencyCode: eurCode,
        ),
      );
      expect(
        (await logsFor('currency_designations', 'sl_desig_1')).single.action,
        'upsert',
      );

      final d = await db.currencyDesignationsDao.getDesignationById(
        'sl_desig_1',
      );
      await db.currencyDesignationsDao.updateDesignation(
        d!.toCompanion(true).copyWith(value: const Value('#')),
      );
      expect(
        (await logsFor(
          'currency_designations',
          'sl_desig_1',
        )).where((l) => l.action == 'upsert').length,
        2,
      );

      await db.currencyDesignationsDao.deleteDesignation(d.toCompanion(true));
      expect(
        (await logsFor(
          'currency_designations',
          'sl_desig_1',
        )).any((l) => l.action == 'delete'),
        isTrue,
      );
    });
  });

  group('AccountsDao', () {
    test('insertAccount / updateAccount / deleteAccount each log', () async {
      await db.accountsDao.insertAccount(
        AccountsCompanion.insert(
          id: const Value('sl_acc_1'),
          name: 'SL Account',
          balance: 100.0,
          currencyCode: eurCode,
          currencyDesignationId: designationId,
          accountTypeId: accountTypeId,
        ),
      );
      expect((await logsFor('accounts', 'sl_acc_1')).single.action, 'upsert');

      final acc = await db.accountsDao.getAccountById('sl_acc_1');
      await db.accountsDao.updateAccount(
        acc!.toCompanion(true).copyWith(name: const Value('Renamed Acc')),
      );
      expect(
        (await logsFor(
          'accounts',
          'sl_acc_1',
        )).where((l) => l.action == 'upsert').length,
        2,
      );

      await db.accountsDao.deleteAccount(acc.toCompanion(true));
      expect(
        (await logsFor(
          'accounts',
          'sl_acc_1',
        )).any((l) => l.action == 'delete'),
        isTrue,
      );
    });

    test('adjustBalance logs an upsert (balance is materialised, not '
        'peer-derivable from the transaction alone)', () async {
      await db.accountsDao.insertAccount(
        AccountsCompanion.insert(
          id: const Value('sl_acc_bal'),
          name: 'SL Balance Account',
          balance: 0.0,
          currencyCode: eurCode,
          currencyDesignationId: designationId,
          accountTypeId: accountTypeId,
        ),
      );
      await db.accountsDao.adjustBalance(
        'sl_acc_bal',
        25.5,
        currencyCode: eurCode,
      );
      final logs = await logsFor('accounts', 'sl_acc_bal');
      // 1 from insertAccount + 1 from adjustBalance.
      expect(logs.where((l) => l.action == 'upsert').length, 2);
    });

    test(
      'deleteMultipleAccounts (bulk) logs one delete row per account id',
      () async {
        await db.accountsDao.insertAllAccounts([
          AccountsCompanion.insert(
            id: const Value('sl_acc_bulk_1'),
            name: 'Bulk Acc 1',
            balance: 0.0,
            currencyCode: eurCode,
            currencyDesignationId: designationId,
            accountTypeId: accountTypeId,
          ),
          AccountsCompanion.insert(
            id: const Value('sl_acc_bulk_2'),
            name: 'Bulk Acc 2',
            balance: 0.0,
            currencyCode: eurCode,
            currencyDesignationId: designationId,
            accountTypeId: accountTypeId,
          ),
        ]);
        await db.accountsDao.deleteMultipleAccounts([
          'sl_acc_bulk_1',
          'sl_acc_bulk_2',
        ]);
        expect(
          (await logsFor(
            'accounts',
            'sl_acc_bulk_1',
          )).any((l) => l.action == 'delete'),
          isTrue,
        );
        expect(
          (await logsFor(
            'accounts',
            'sl_acc_bulk_2',
          )).any((l) => l.action == 'delete'),
          isTrue,
        );
      },
    );
  });

  group('TransactionsDao', () {
    late String accId;
    late String catId;

    setUpAll(() async {
      accId = 'sl_tx_acc';
      catId = 'sl_tx_cat';
      await db.accountsDao.insertAccount(
        AccountsCompanion.insert(
          id: Value(accId),
          name: 'SL Tx Account',
          balance: 500.0,
          currencyCode: eurCode,
          currencyDesignationId: designationId,
          accountTypeId: accountTypeId,
        ),
      );
      await db.categoriesDao.insertCategory(
        CategoriesCompanion.insert(id: Value(catId), name: 'SL Tx Category'),
      );
    });

    test(
      'insertTransaction / updateTransaction / deleteTransaction each log',
      () async {
        await db.transactionsDao.insertTransaction(
          TransactionsCompanion.insert(
            id: const Value('sl_tx_1'),
            description: 'SL Tx',
            amount: -10.0,
            date: DateTime(2025, 1, 1),
            accountId: accId,
            categoryId: catId,
            currencyCode: eurCode,
          ),
        );
        expect(
          (await logsFor('transactions', 'sl_tx_1')).single.action,
          'upsert',
        );

        final tx = await db.transactionsDao.getTransactionById('sl_tx_1');
        await db.transactionsDao.updateTransaction(
          tx!.toCompanion(true).copyWith(amount: const Value(-20.0)),
        );
        expect(
          (await logsFor(
            'transactions',
            'sl_tx_1',
          )).where((l) => l.action == 'upsert').length,
          2,
        );

        await db.transactionsDao.deleteTransaction(tx.toCompanion(true));
        expect(
          (await logsFor(
            'transactions',
            'sl_tx_1',
          )).any((l) => l.action == 'delete'),
          isTrue,
        );
      },
    );
  });

  group('ExchangeRatesDao', () {
    test('addExchangeRate logs an upsert row keyed by the composite '
        'from_to_date_preset id (the table has no single id column)', () async {
      await db.exchangeRatesDao.addExchangeRate(
        ExchangeRatesCompanion.insert(
          fromCurrencyCode: 'EUR',
          toCurrencyCode: 'BTC',
          rate: 0.00003,
          preset: 7,
          date: DateTime(2030, 1, 1),
        ),
      );
      final logs = await logsFor('exchange_rates', 'EUR_BTC_2030-01-01_7');
      // Would fail if addExchangeRate's recordId format or _logChange call
      // changed/regressed.
      expect(logs.length, 1);
      expect(logs.single.action, 'upsert');
    });
  });

  group('ApiSettingsDao', () {
    test('upsertSetting logs an upsert row', () async {
      await db.apiSettingsDao.upsertSetting(
        ApiSettingsTableCompanion.insert(
          id: 'sl_api_setting_1',
          enabled: const Value(true),
        ),
      );
      final logs = await logsFor('api_settings_table', 'sl_api_setting_1');
      expect(logs.length, 1);
      expect(logs.single.action, 'upsert');
    });
  });

  // --- regression fixes: mutations that used to reach no other device ---

  group('AccountsDao.updateAccountTypeForMultipleAccounts', () {
    setUpAll(() async {
      await db.accountsDao.insertAllAccounts([
        for (final i in [1, 2])
          AccountsCompanion.insert(
            id: Value('sl_acc_type_$i'),
            name: 'Retype Acc $i',
            balance: 0.0,
            currencyCode: eurCode,
            currencyDesignationId: designationId,
            accountTypeId: accountTypeId,
          ),
      ]);
      await db.accountTypesDao.insertAccountType(
        AccountTypesCompanion.insert(
          id: const Value('sl_at_retype'),
          name: 'Retype Target',
          languageCode: languageCode,
        ),
      );
      await db.accountsDao.updateAccountTypeForMultipleAccounts([
        'sl_acc_type_1',
        'sl_acc_type_2',
      ], 'sl_at_retype');
    });

    test('logs one upsert row per account id', () async {
      // Was a bare `update(...)...write(...)` with no log at all, so the
      // retyped accounts stayed on their old type on every other device.
      for (final id in ['sl_acc_type_1', 'sl_acc_type_2']) {
        expect(
          (await logsFor(
            'accounts',
            id,
          )).where((l) => l.action == 'upsert').length,
          2, // 1 from insertAllAccounts + 1 from the retype
        );
      }
    });

    test('bumps modifiedAt, without which last-write-wins discards the '
        'change even once it is logged', () async {
      final acc = await db.accountsDao.getAccountById('sl_acc_type_1');
      expect(acc!.accountTypeId, 'sl_at_retype');
      expect(acc.modifiedAt, greaterThan(0));
    });
  });

  group('CustomThemesDao', () {
    CustomThemesCompanion theme(String id, String name) =>
        CustomThemesCompanion.insert(
          id: Value(id),
          name: name,
          primaryColorHex: '#111111',
          secondaryColorHex: '#222222',
          surfaceColorHex: '#333333',
          backgroundColorHex: '#444444',
          windowEffectType: 0,
          themeMode: 0,
        );

    test('insertTheme / updateTheme / deleteTheme each log', () async {
      await db.customThemesDao.insertTheme(theme('sl_theme_1', 'SL Theme'));
      expect(
        (await logsFor('custom_themes', 'sl_theme_1')).single.action,
        'upsert',
      );

      final stored = await db.customThemesDao.getThemeById('sl_theme_1');
      await db.customThemesDao.updateTheme(
        stored!.toCompanion(true).copyWith(name: const Value('SL Renamed')),
      );
      expect(
        (await logsFor(
          'custom_themes',
          'sl_theme_1',
        )).where((l) => l.action == 'upsert').length,
        2,
      );

      await db.customThemesDao.deleteTheme('sl_theme_1');
      expect(
        (await logsFor(
          'custom_themes',
          'sl_theme_1',
        )).any((l) => l.action == 'delete'),
        isTrue,
      );
    });

    test('insertAllThemes (bulk) logs one upsert row per theme', () async {
      await db.customThemesDao.insertAllThemes([
        theme('sl_theme_bulk_1', 'SL Bulk 1'),
        theme('sl_theme_bulk_2', 'SL Bulk 2'),
      ]);
      expect((await logsFor('custom_themes', 'sl_theme_bulk_1')).length, 1);
      expect((await logsFor('custom_themes', 'sl_theme_bulk_2')).length, 1);
    });

    test(
      'setActiveTheme logs the theme it deactivates as well as the one it '
      'activates - a peer told only about the winner keeps two active themes',
      () async {
        await db.customThemesDao.insertTheme(theme('sl_theme_a', 'SL A'));
        await db.customThemesDao.insertTheme(theme('sl_theme_b', 'SL B'));
        await db.customThemesDao.setActiveTheme('sl_theme_a');
        await db.customThemesDao.setActiveTheme('sl_theme_b');

        // sl_theme_a: 1 insert + 1 activation + 1 deactivation.
        expect((await logsFor('custom_themes', 'sl_theme_a')).length, 3);
        // sl_theme_b: 1 insert + 1 activation.
        expect((await logsFor('custom_themes', 'sl_theme_b')).length, 2);
      },
    );
  });

  group('CurrenciesDao.insertCurrency', () {
    setUpAll(() async {
      // What ImportBloc does when a CSV names a currency code with no row.
      await db.currenciesDao.insertCurrency(
        CurrenciesCompanion.insert(
          name: 'SL Imported Currency',
          code: 'SLQ',
          languageCode: languageCode,
        ),
      );
    });

    test('logs an upsert row keyed by the currency code (the table has no '
        'id column)', () async {
      final logs = await logsFor('currencies', 'SLQ');
      expect(logs.length, 1);
      expect(logs.single.action, 'upsert');
    });

    test(
      'bumps modifiedAt, which is what ServerSyncService pushes on',
      () async {
        final currency = await db.currenciesDao.getCurrencyByCode('SLQ');
        // Left at the column default of 0, the row is older than every push
        // cutoff and no server sync ever picks it up.
        expect(currency!.modifiedAt, greaterThan(0));
      },
    );
  });

  group('CategoriesDao bulk category deletes', () {
    late String accId;

    setUpAll(() async {
      accId = 'sl_catdel_acc';
      await db.accountsDao.insertAccount(
        AccountsCompanion.insert(
          id: Value(accId),
          name: 'SL CatDel Account',
          balance: 0.0,
          currencyCode: eurCode,
          currencyDesignationId: designationId,
          accountTypeId: accountTypeId,
        ),
      );
    });

    Future<void> addTx(String id, String categoryId) {
      return db.transactionsDao.insertTransaction(
        TransactionsCompanion.insert(
          id: Value(id),
          description: id,
          amount: -1.0,
          date: DateTime(2025, 2, 2),
          accountId: accId,
          categoryId: categoryId,
          currencyCode: eurCode,
        ),
      );
    }

    test(
      'deleteCategoryWithTransactions logs a delete for every transaction it '
      'soft-deletes, not just for the category',
      () async {
        await db.categoriesDao.insertCategory(
          CategoriesCompanion.insert(
            id: const Value('sl_catdel_with'),
            name: 'SL CatDel With',
          ),
        );
        await addTx('sl_catdel_tx_1', 'sl_catdel_with');
        await addTx('sl_catdel_tx_2', 'sl_catdel_with');

        await db.categoriesDao.deleteCategoryWithTransactions('sl_catdel_with');

        expect(
          (await logsFor(
            'categories',
            'sl_catdel_with',
          )).any((l) => l.action == 'delete'),
          isTrue,
        );
        for (final id in ['sl_catdel_tx_1', 'sl_catdel_tx_2']) {
          expect(
            (await logsFor(
              'transactions',
              id,
            )).any((l) => l.action == 'delete'),
            isTrue,
            reason: '$id was soft-deleted locally but never announced',
          );
        }
      },
    );

    test('deleteCategoryAndReassignTransactions logs the moved transactions as '
        'upserts (they survive, they only changed category)', () async {
      await db.categoriesDao.insertCategory(
        CategoriesCompanion.insert(
          id: const Value('sl_catdel_from'),
          name: 'SL CatDel From',
        ),
      );
      await db.categoriesDao.insertCategory(
        CategoriesCompanion.insert(
          id: const Value('sl_catdel_to'),
          name: 'SL CatDel To',
        ),
      );
      await addTx('sl_catmove_tx_1', 'sl_catdel_from');
      await addTx('sl_catmove_tx_2', 'sl_catdel_from');

      await db.categoriesDao.deleteCategoryAndReassignTransactions(
        'sl_catdel_from',
        'sl_catdel_to',
      );

      for (final id in ['sl_catmove_tx_1', 'sl_catmove_tx_2']) {
        final logs = await logsFor('transactions', id);
        // 1 from insertTransaction + 1 from the reassignment.
        expect(logs.where((l) => l.action == 'upsert').length, 2);
        expect(logs.any((l) => l.action == 'delete'), isFalse);
        final tx = await db.transactionsDao.getTransactionById(id);
        expect(tx!.categoryId, 'sl_catdel_to');
      }
    });
  });
}
