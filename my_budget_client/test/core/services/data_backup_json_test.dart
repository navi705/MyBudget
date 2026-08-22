// The JSON backup is the only path that moves the user's whole budget out of
// the app and back in, and it is a wipe-and-replace restore: whatever it gets
// wrong is not a display glitch, it is the data. These tests drive
// [DataExportService.buildJsonBackup] and [DataImportService.importContent]
// against a real in-memory database and assert the document survives the round
// trip row for row - ids included - plus the ways a bad file must be refused
// BEFORE anything is deleted.
import 'dart:convert';

import 'package:drift/drift.dart' show DataClass, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart'
    hide Transaction;
import 'package:my_budget_client/core/services/android_file_picker_service.dart';
import 'package:my_budget_client/core/services/data_export_service.dart';
import 'package:my_budget_client/core/services/data_import_service.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late DataExportService exporter;
  late DataImportService importer;
  late String designationId;
  late String accountTypeId;
  late String styleId;

  /// `modifiedAt` is deliberately rewritten to "now" by the restore so the
  /// restored rows look new to sync, so it is the one column a round trip is
  /// not expected to preserve.
  List<Map<String, dynamic>> normalize(List<DataClass> rows) {
    final maps = rows
        .map((r) => Map<String, dynamic>.of(r.toJson())..remove('modifiedAt'))
        .toList();
    maps.sort((a, b) => jsonEncode(a).compareTo(jsonEncode(b)));
    return maps;
  }

  Future<void> wipeBusinessTables() async {
    await db.customStatement('PRAGMA foreign_keys = OFF');
    await db.delete(db.transactions).go();
    await db.delete(db.assetEntries).go();
    await db.delete(db.accounts).go();
    await db.delete(db.categories).go();
    await db.delete(db.exchangeRates).go();
    await db.delete(db.inflationRates).go();
    await db.customStatement('PRAGMA foreign_keys = ON');
  }

  setUpAll(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    exporter = DataExportService(db);
    importer = DataImportService(db, AndroidFilePickerService());
    designationId = (await db.select(db.currencyDesignations).get()).first.id;
    accountTypeId = (await db.select(db.accountTypes).get()).first.id;
    styleId = (await db.select(db.styles).get()).first.id;
  });

  tearDownAll(() async {
    await db.close();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await wipeBusinessTables();

    // Fiat with a 2-decimal scale, fiat with none (JPY), and a non-fiat asset
    // whose amounts stay a raw double - the three branches of the money model.
    await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: const Value('bk_acc_eur'),
            name: 'Кошелёк 💶',
            balance: 30.0,
            balanceMinor: const Value(3000),
            openingBalance: const Value(10.0),
            openingBalanceMinor: const Value(1000),
            currencyCode: 'EUR',
            currencyDesignationId: designationId,
            accountTypeId: accountTypeId,
            styleId: Value(styleId),
            creationDate: Value(DateTime(2024, 5, 17, 9, 30, 15)),
            description: const Value('Основной, "рабочий"'),
          ),
        );
    await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: const Value('bk_acc_jpy'),
            name: '日本 account',
            balance: 1234.0,
            balanceMinor: const Value(1234),
            currencyCode: 'JPY',
            currencyDesignationId: designationId,
            accountTypeId: accountTypeId,
            creationDate: Value(DateTime(2024, 6, 1)),
          ),
        );
    await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: const Value('bk_acc_btc'),
            name: 'Cold wallet',
            balance: 0.12345678,
            currencyCode: 'BTC',
            currencyDesignationId: designationId,
            accountTypeId: accountTypeId,
            creationDate: Value(DateTime(2024, 6, 2)),
          ),
        );

    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: const Value('bk_cat_food'),
            name: 'Продукты 🍎',
            type: const Value(CategoryType.expense),
            styleId: Value(styleId),
          ),
        );
    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: const Value('bk_cat_child'),
            name: 'Хлеб',
            parentId: const Value('bk_cat_food'),
            type: const Value(CategoryType.expense),
          ),
        );
    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: const Value('bk_cat_income'),
            name: 'Salary',
            type: const Value(CategoryType.income),
          ),
        );
    // A tombstone: soft-deleted, but still the parent of a live row.
    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: const Value('bk_cat_dead'),
            name: 'Removed',
            isDeleted: const Value(true),
          ),
        );

    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: const Value('bk_tx_a'),
            description: 'Point one',
            amount: 0.1,
            amountMinor: const Value(10),
            date: DateTime(2025, 3, 30, 12, 0),
            accountId: 'bk_acc_eur',
            categoryId: 'bk_cat_food',
            currencyCode: 'EUR',
          ),
        );
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: const Value('bk_tx_b'),
            description: 'Point two, with a "quote" and, a comma',
            amount: 0.2,
            amountMinor: const Value(20),
            date: DateTime(2025, 3, 30, 12, 5),
            accountId: 'bk_acc_eur',
            categoryId: 'bk_cat_food',
            currencyCode: 'EUR',
            fee: const Value(0.03),
            feeMinor: const Value(3),
            exchangeRate: const Value(1.0876),
            linkedTransactionId: const Value('bk_tx_a'),
          ),
        );
    // Zero-decimal fiat: 1234 yen is 1234 minor units, not 123400.
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: const Value('bk_tx_jpy'),
            description: 'ラーメン',
            amount: 1234.0,
            amountMinor: const Value(1234),
            date: DateTime(2025, 3, 31, 19, 0),
            accountId: 'bk_acc_jpy',
            categoryId: 'bk_cat_food',
            currencyCode: 'JPY',
          ),
        );
    // Crypto: 8 decimals, minor columns stay NULL on purpose.
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: const Value('bk_tx_btc'),
            description: 'Sats',
            amount: 0.12345678,
            date: DateTime(2025, 4, 1, 8, 0),
            accountId: 'bk_acc_btc',
            categoryId: 'bk_cat_income',
            currencyCode: 'BTC',
          ),
        );
    // Both edges of a calendar day, local time.
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: const Value('bk_tx_midnight'),
            description: 'Just after midnight',
            amount: -5.0,
            amountMinor: const Value(-500),
            date: DateTime(2025, 3, 30, 0, 15),
            accountId: 'bk_acc_eur',
            categoryId: 'bk_cat_food',
            currencyCode: 'EUR',
          ),
        );
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: const Value('bk_tx_late'),
            description: 'Just before midnight',
            amount: -7.0,
            amountMinor: const Value(-700),
            date: DateTime(2025, 3, 30, 23, 45),
            accountId: 'bk_acc_eur',
            categoryId: 'bk_cat_food',
            currencyCode: 'EUR',
          ),
        );
    // A soft-deleted transaction: a tombstone sync still needs.
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: const Value('bk_tx_dead'),
            description: 'Deleted one',
            amount: -1.0,
            amountMinor: const Value(-100),
            date: DateTime(2025, 3, 29, 10, 0),
            accountId: 'bk_acc_eur',
            categoryId: 'bk_cat_dead',
            currencyCode: 'EUR',
            isDeleted: const Value(true),
          ),
        );

    await db
        .into(db.assetEntries)
        .insert(
          AssetEntriesCompanion.insert(
            id: const Value('bk_asset_1'),
            assetId: 'BTC',
            name: 'Bitcoin',
            date: DateTime(2025, 4, 1),
            value: 61234.5,
            quantity: const Value(0.12345678),
            currencyCode: 'EUR',
            accountId: const Value('bk_acc_btc'),
            source: 'manual',
          ),
        );

    await db
        .into(db.exchangeRates)
        .insert(
          ExchangeRatesCompanion.insert(
            fromCurrencyCode: 'EUR',
            toCurrencyCode: 'JPY',
            rate: 163.42,
            preset: 1,
            date: DateTime(2025, 3, 30),
          ),
        );
  });

  group('JSON backup round trip', () {
    test('every table comes back row for row, ids included, nothing '
        'duplicated', () async {
      final before = {
        'accounts': normalize(await db.select(db.accounts).get()),
        'categories': normalize(await db.select(db.categories).get()),
        'transactions': normalize(await db.select(db.transactions).get()),
        'styles': normalize(await db.select(db.styles).get()),
        'account_types': normalize(await db.select(db.accountTypes).get()),
        'currencies': normalize(await db.select(db.currencies).get()),
        'currency_designations': normalize(
          await db.select(db.currencyDesignations).get(),
        ),
        'asset_entries': normalize(await db.select(db.assetEntries).get()),
        'exchange_rates': normalize(await db.select(db.exchangeRates).get()),
        'languages': normalize(await db.select(db.languages).get()),
      };

      final backup = await exporter.buildJsonBackup();
      await wipeBusinessTables();
      expect(await db.select(db.transactions).get(), isEmpty);

      await importer.importContent(backup, isCsv: false);

      final after = {
        'accounts': normalize(await db.select(db.accounts).get()),
        'categories': normalize(await db.select(db.categories).get()),
        'transactions': normalize(await db.select(db.transactions).get()),
        'styles': normalize(await db.select(db.styles).get()),
        'account_types': normalize(await db.select(db.accountTypes).get()),
        'currencies': normalize(await db.select(db.currencies).get()),
        'currency_designations': normalize(
          await db.select(db.currencyDesignations).get(),
        ),
        'asset_entries': normalize(await db.select(db.assetEntries).get()),
        'exchange_rates': normalize(await db.select(db.exchangeRates).get()),
        'languages': normalize(await db.select(db.languages).get()),
      };

      for (final table in before.keys) {
        expect(after[table], before[table], reason: '$table did not survive');
      }
    });

    test('importing the same backup twice changes nothing the second '
        'time', () async {
      final backup = await exporter.buildJsonBackup();
      await importer.importContent(backup, isCsv: false);
      final once = normalize(await db.select(db.transactions).get());
      await importer.importContent(backup, isCsv: false);
      final twice = normalize(await db.select(db.transactions).get());
      expect(twice, once);
      expect(twice.length, 7);
    });

    test('soft-deleted rows are carried, not dropped', () async {
      // The DAO read paths filter `is_deleted = 1` away. A backup built off
      // them loses every tombstone - and with it the parent of any live row
      // that still points at one.
      final backup = await exporter.buildJsonBackup();
      await wipeBusinessTables();
      await importer.importContent(backup, isCsv: false);

      final deadCategory = await (db.select(
        db.categories,
      )..where((t) => t.id.equals('bk_cat_dead'))).getSingleOrNull();
      expect(deadCategory, isNotNull);
      expect(deadCategory!.isDeleted, isTrue);

      final deadTx = await (db.select(
        db.transactions,
      )..where((t) => t.id.equals('bk_tx_dead'))).getSingleOrNull();
      expect(deadTx, isNotNull);
      expect(deadTx!.isDeleted, isTrue);
      expect(deadTx.categoryId, 'bk_cat_dead');
    });

    test('the exported document names every table it snapshots', () async {
      final data =
          jsonDecode(await exporter.buildJsonBackup()) as Map<String, dynamic>;
      expect(data['version'], 2);
      for (final key in const [
        'transactions',
        'categories',
        'accounts',
        'styles',
        'account_types',
        'currencies',
        'currency_designations',
        'exchange_rates',
        'asset_entries',
        'languages',
        'inflation_rates',
        'settings',
        'custom_themes',
        'custom_data_sources',
        'api_settings',
        'sms_presets',
      ]) {
        expect(data[key], isA<List>(), reason: '$key missing from the backup');
      }
    });
  });

  group('money exactness', () {
    setUp(() async {
      final backup = await exporter.buildJsonBackup();
      await wipeBusinessTables();
      await importer.importContent(backup, isCsv: false);
    });

    test('0.1 and 0.2 survive as exact minor units that sum to 0.30', () async {
      final a = await (db.select(
        db.transactions,
      )..where((t) => t.id.equals('bk_tx_a'))).getSingle();
      final b = await (db.select(
        db.transactions,
      )..where((t) => t.id.equals('bk_tx_b'))).getSingle();
      expect(a.amountMinor, 10);
      expect(b.amountMinor, 20);
      expect(a.amountMinor! + b.amountMinor!, 30);
      expect(a.amount, 0.1);
      expect(b.amount, 0.2);
      expect(b.feeMinor, 3);
      expect(b.exchangeRate, 1.0876);
      expect(b.linkedTransactionId, 'bk_tx_a');
    });

    test(
      'a zero-decimal currency keeps 1234 JPY as 1234 minor units',
      () async {
        final jpy = await (db.select(
          db.transactions,
        )..where((t) => t.id.equals('bk_tx_jpy'))).getSingle();
        expect(jpy.amount, 1234.0);
        expect(
          jpy.amountMinor,
          1234,
          reason: 'JPY has no cents; scaling by 100 would be a 100x error',
        );
      },
    );

    test('a crypto amount keeps all 8 decimals and no minor units', () async {
      final btc = await (db.select(
        db.transactions,
      )..where((t) => t.id.equals('bk_tx_btc'))).getSingle();
      expect(btc.amount, 0.12345678);
      expect(
        btc.amountMinor,
        isNull,
        reason:
            'non-fiat stays on the double; a minor-unit count here '
            'would truncate the holding',
      );

      final wallet = await (db.select(
        db.accounts,
      )..where((t) => t.id.equals('bk_acc_btc'))).getSingle();
      expect(wallet.balance, 0.12345678);
      expect(wallet.balanceMinor, isNull);
    });

    test('account opening balance and its minor units both survive', () async {
      final acc = await (db.select(
        db.accounts,
      )..where((t) => t.id.equals('bk_acc_eur'))).getSingle();
      expect(acc.openingBalance, 10.0);
      expect(acc.openingBalanceMinor, 1000);
      expect(acc.balance, 30.0);
      expect(acc.balanceMinor, 3000);
    });
  });

  group('dates', () {
    test('a transaction 15 minutes after midnight stays on the same calendar '
        'day, and so does one 15 minutes before', () async {
      final backup = await exporter.buildJsonBackup();
      await wipeBusinessTables();
      await importer.importContent(backup, isCsv: false);

      final early = await (db.select(
        db.transactions,
      )..where((t) => t.id.equals('bk_tx_midnight'))).getSingle();
      expect(early.date, DateTime(2025, 3, 30, 0, 15));
      expect(early.date.day, 30);

      final late = await (db.select(
        db.transactions,
      )..where((t) => t.id.equals('bk_tx_late'))).getSingle();
      expect(late.date, DateTime(2025, 3, 30, 23, 45));
      expect(late.date.day, 30);
    });

    test('the encoding is an absolute instant, not a local wall-clock string '
        'that a UTC offset could shift', () async {
      final data =
          jsonDecode(await exporter.buildJsonBackup()) as Map<String, dynamic>;
      final row = (data['transactions'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((r) => r['id'] == 'bk_tx_midnight');

      expect(
        row['date'],
        isA<int>(),
        reason:
            'a formatted local string would be read back in whatever '
            'zone the importing device happens to sit in',
      );
      expect(
        DateTime.fromMillisecondsSinceEpoch(row['date'] as int),
        DateTime(2025, 3, 30, 0, 15),
      );
      expect(
        row['date'],
        DateTime(2025, 3, 30, 0, 15).millisecondsSinceEpoch,
        reason: 'no local UTC offset is baked into the number',
      );
    });

    test('an account creation timestamp survives to the second', () async {
      final backup = await exporter.buildJsonBackup();
      await wipeBusinessTables();
      await importer.importContent(backup, isCsv: false);
      final acc = await (db.select(
        db.accounts,
      )..where((t) => t.id.equals('bk_acc_eur'))).getSingle();
      expect(acc.creationDate, DateTime(2024, 5, 17, 9, 30, 15));
    });
  });

  group('non-ASCII text', () {
    test(
      'Cyrillic, an emoji and CJK survive both the encode and the restore',
      () async {
        final backup = await exporter.buildJsonBackup();
        await wipeBusinessTables();
        await importer.importContent(backup, isCsv: false);

        final acc = await (db.select(
          db.accounts,
        )..where((t) => t.id.equals('bk_acc_eur'))).getSingle();
        expect(acc.name, 'Кошелёк 💶');
        expect(acc.description, 'Основной, "рабочий"');

        final jpy = await (db.select(
          db.accounts,
        )..where((t) => t.id.equals('bk_acc_jpy'))).getSingle();
        expect(jpy.name, '日本 account');

        final cat = await (db.select(
          db.categories,
        )..where((t) => t.id.equals('bk_cat_food'))).getSingle();
        expect(cat.name, 'Продукты 🍎');

        final tx = await (db.select(
          db.transactions,
        )..where((t) => t.id.equals('bk_tx_jpy'))).getSingle();
        expect(tx.description, 'ラーメン');
      },
    );
  });

  group('malformed input is refused before anything is deleted', () {
    late int transactionsBefore;

    setUp(() async {
      transactionsBefore = (await db.select(db.transactions).get()).length;
    });

    Future<void> expectRefusedAndIntact(
      Future<void> Function() action,
      Matcher messageMatcher,
    ) async {
      await expectLater(
        action(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            messageMatcher,
          ),
        ),
      );
      expect(
        (await db.select(db.transactions).get()).length,
        transactionsBefore,
        reason: 'a rejected backup must not have cost the user any data',
      );
    }

    test('an empty file', () async {
      await expectRefusedAndIntact(
        () => importer.importContent('', isCsv: false),
        contains('empty'),
      );
    });

    test('a whitespace-only file', () async {
      await expectRefusedAndIntact(
        () => importer.importContent('   \n\t ', isCsv: false),
        contains('empty'),
      );
    });

    test('truncated JSON', () async {
      final backup = await exporter.buildJsonBackup();
      final truncated = backup.substring(0, backup.length ~/ 2);
      await expectLater(
        importer.importContent(truncated, isCsv: false),
        throwsA(isA<FormatException>()),
      );
      expect(
        (await db.select(db.transactions).get()).length,
        transactionsBefore,
      );
    });

    test('valid JSON that is not a backup object', () async {
      await expectRefusedAndIntact(
        () => importer.importContent('[1, 2, 3]', isCsv: false),
        contains('not a My Budget backup'),
      );
    });

    test('a table that is not a list of rows', () async {
      await expectRefusedAndIntact(
        () => importer.importContent(
          jsonEncode({'version': 2, 'accounts': 'oops'}),
          isCsv: false,
        ),
        contains('not a list of rows'),
      );
    });

    test(
      'a transaction pointing at an account the file does not carry',
      () async {
        final data =
            jsonDecode(await exporter.buildJsonBackup())
                as Map<String, dynamic>;
        (data['accounts'] as List).removeWhere(
          (a) => (a as Map)['id'] == 'bk_acc_jpy',
        );

        await expectRefusedAndIntact(
          () => importer.importContent(jsonEncode(data), isCsv: false),
          allOf(contains('bk_acc_jpy'), contains('does not contain')),
        );
      },
    );

    test(
      'a transaction pointing at a category the file does not carry',
      () async {
        final data =
            jsonDecode(await exporter.buildJsonBackup())
                as Map<String, dynamic>;
        (data['categories'] as List).removeWhere(
          (c) => (c as Map)['id'] == 'bk_cat_income',
        );

        await expectRefusedAndIntact(
          () => importer.importContent(jsonEncode(data), isCsv: false),
          allOf(contains('bk_cat_income'), contains('does not contain')),
        );
      },
    );

    test('a duplicated id', () async {
      final data =
          jsonDecode(await exporter.buildJsonBackup()) as Map<String, dynamic>;
      final rows = data['transactions'] as List;
      final clone = Map<String, dynamic>.of(
        rows.firstWhere((r) => (r as Map)['id'] == 'bk_tx_a')
            as Map<String, dynamic>,
      );
      clone['amount'] = 999.0;
      rows.add(clone);

      await expectRefusedAndIntact(
        () => importer.importContent(jsonEncode(data), isCsv: false),
        allOf(contains('bk_tx_a'), contains('reuses')),
      );
    });

    test('text where a number belongs', () async {
      final data =
          jsonDecode(await exporter.buildJsonBackup()) as Map<String, dynamic>;
      (data['transactions'] as List).cast<Map<String, dynamic>>().firstWhere(
        (r) => r['id'] == 'bk_tx_a',
      )['amount'] = 'not a number';

      await expectLater(
        importer.importContent(jsonEncode(data), isCsv: false),
        throwsA(anything),
      );
      // The failure lands inside the restore transaction, which rolls back.
      expect(
        (await db.select(db.transactions).get()).length,
        transactionsBefore,
      );
    });
  });

  group('an older backup', () {
    test(
      'restores even though it predates columns the schema has now',
      () async {
        // A pre-v11 file has no `openingBalance`. The generated fromJson reads
        // every non-nullable column and throws on a missing key, and the whole
        // restore is one transaction - so without a default this file could not
        // be restored at all.
        final data =
            jsonDecode(await exporter.buildJsonBackup())
                as Map<String, dynamic>;
        data['version'] = 1;
        for (final row
            in (data['accounts'] as List).cast<Map<String, dynamic>>()) {
          row.remove('openingBalance');
          row.remove('openingBalanceMinor');
        }
        for (final row
            in (data['transactions'] as List).cast<Map<String, dynamic>>()) {
          row.remove('fee');
          row.remove('feeMinor');
          row.remove('amountMinor');
        }

        await wipeBusinessTables();
        await importer.importContent(jsonEncode(data), isCsv: false);

        final acc = await (db.select(
          db.accounts,
        )..where((t) => t.id.equals('bk_acc_eur'))).getSingle();
        expect(acc.openingBalance, 0.0);
        expect(acc.openingBalanceMinor, isNull);
        expect(acc.balance, 30.0);

        final tx = await (db.select(
          db.transactions,
        )..where((t) => t.id.equals('bk_tx_a'))).getSingle();
        expect(tx.fee, 0.0);
        expect(tx.amount, 0.1);
      },
    );

    test(
      'a table the file does not carry at all is left alone, not emptied',
      () async {
        // A v1 backup has no `languages` key. Wiping the table anyway left every
        // restored currency pointing at a language row that no longer existed.
        final data =
            jsonDecode(await exporter.buildJsonBackup())
                as Map<String, dynamic>;
        data['version'] = 1;
        final languagesBefore = normalize(await db.select(db.languages).get());
        final settingsBefore = normalize(await db.select(db.settings).get());
        expect(languagesBefore, isNotEmpty);
        expect(settingsBefore, isNotEmpty);

        data.remove('languages');
        data.remove('settings');
        data.remove('custom_themes');
        data.remove('custom_data_sources');
        data.remove('api_settings');
        data.remove('sms_presets');
        data.remove('inflation_rates');

        await importer.importContent(jsonEncode(data), isCsv: false);

        expect(normalize(await db.select(db.languages).get()), languagesBefore);
        expect(normalize(await db.select(db.settings).get()), settingsBefore);
      },
    );
  });
}
