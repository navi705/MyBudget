// The CSV side of the import/export layer. Unlike the JSON backup this is a
// report format - it carries names instead of ids and only a subset of the
// columns - so these tests pin both what it does preserve and, explicitly,
// what it throws away, plus every way a mangled file must be refused instead
// of imported as something that merely looks plausible.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_budget_client/core/database/app_database.dart'
    hide Transaction;
import 'package:my_budget_client/core/services/android_file_picker_service.dart';
import 'package:my_budget_client/core/services/data_export_service.dart';
import 'package:my_budget_client/core/services/data_import_service.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late DataExportService exporter;
  late DataImportService importer;
  late String designationId;
  late String accountTypeId;

  Future<void> wipeBusinessTables() async {
    await db.customStatement('PRAGMA foreign_keys = OFF');
    await db.delete(db.transactions).go();
    await db.delete(db.assetEntries).go();
    await db.delete(db.accounts).go();
    await db.delete(db.categories).go();
    await db.customStatement('PRAGMA foreign_keys = ON');
  }

  setUpAll(() async {
    // Opening the database seeds exchange rates, and the CSV export/import
    // path itself formats and parses dates with a locale-pinned DateFormat.
    // Load its CLDR data before either runs.
    await initializeDateFormatting();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    exporter = DataExportService(db);
    importer = DataImportService(db, AndroidFilePickerService());
    designationId = (await db.select(db.currencyDesignations).get()).first.id;
    accountTypeId = (await db.select(db.accountTypes).get()).first.id;
  });

  tearDownAll(() async {
    await db.close();
  });

  setUp(() async {
    await wipeBusinessTables();

    await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: const Value('csv_acc_eur'),
            name: 'Кошелёк 💶',
            balance: 0.0,
            balanceMinor: const Value(0),
            currencyCode: 'EUR',
            currencyDesignationId: designationId,
            accountTypeId: accountTypeId,
          ),
        );
    await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: const Value('csv_acc_jpy'),
            name: 'Japan, Ltd "JPY"',
            balance: 0.0,
            balanceMinor: const Value(0),
            currencyCode: 'JPY',
            currencyDesignationId: designationId,
            accountTypeId: accountTypeId,
          ),
        );
    await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: const Value('csv_acc_btc'),
            name: 'Cold wallet',
            balance: 0.0,
            currencyCode: 'BTC',
            currencyDesignationId: designationId,
            accountTypeId: accountTypeId,
          ),
        );

    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: const Value('csv_cat_food'),
            name: 'Продукты 🍎',
            type: const Value(CategoryType.expense),
          ),
        );
    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: const Value('csv_cat_income'),
            name: 'Salary',
            type: const Value(CategoryType.income),
          ),
        );

    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: const Value('csv_tx_a'),
            description: 'Point one',
            amount: 0.1,
            amountMinor: const Value(10),
            date: DateTime(2025, 3, 30, 0, 15),
            accountId: 'csv_acc_eur',
            categoryId: 'csv_cat_food',
            currencyCode: 'EUR',
          ),
        );
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: const Value('csv_tx_b'),
            description: 'Two, with a "quote" and a comma',
            amount: 0.2,
            amountMinor: const Value(20),
            date: DateTime(2025, 3, 30, 23, 45),
            accountId: 'csv_acc_eur',
            categoryId: 'csv_cat_food',
            currencyCode: 'EUR',
            fee: const Value(0.03),
            feeMinor: const Value(3),
            exchangeRate: const Value(1.0876),
            linkedTransactionId: const Value('csv_tx_a'),
          ),
        );
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: const Value('csv_tx_jpy'),
            description: 'ラーメン',
            amount: 1234.0,
            amountMinor: const Value(1234),
            date: DateTime(2025, 3, 31, 19, 0),
            accountId: 'csv_acc_jpy',
            categoryId: 'csv_cat_food',
            currencyCode: 'JPY',
          ),
        );
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: const Value('csv_tx_btc'),
            description: 'Sats',
            amount: 0.12345678,
            date: DateTime(2025, 4, 1, 8, 0),
            accountId: 'csv_acc_btc',
            categoryId: 'csv_cat_income',
            currencyCode: 'BTC',
          ),
        );
    // Soft-deleted: the CSV is a report of live data, so this must stay out.
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: const Value('csv_tx_dead'),
            description: 'Deleted one',
            amount: -1.0,
            amountMinor: const Value(-100),
            date: DateTime(2025, 3, 29, 10, 0),
            accountId: 'csv_acc_eur',
            categoryId: 'csv_cat_food',
            currencyCode: 'EUR',
            isDeleted: const Value(true),
          ),
        );
  });

  group('CSV export', () {
    test(
      'writes the documented header and one line per live transaction',
      () async {
        final csv = await exporter.buildTransactionsCsv();
        final lines = csv.split('\r\n').where((l) => l.isNotEmpty).toList();

        expect(
          lines.first,
          'Date,Amount,Currency,Description,Category,Account,Type,'
          'Exchange Rate,Fee,Linked Transaction ID',
        );
        expect(lines.length, 5, reason: '4 live transactions plus the header');
        expect(
          csv.contains('Deleted one'),
          isFalse,
          reason: 'the CSV is a report, so soft-deleted rows stay out of it',
        );
      },
    );

    test('writes CRLF line endings', () async {
      final csv = await exporter.buildTransactionsCsv();
      expect(csv.contains('\r\n'), isTrue);
      expect(csv.replaceAll('\r\n', '').contains('\n'), isFalse);
    });

    test('quotes a value containing a comma or a quote', () async {
      final csv = await exporter.buildTransactionsCsv();
      expect(csv.contains('"Two, with a ""quote"" and a comma"'), isTrue);
      expect(csv.contains('"Japan, Ltd ""JPY"""'), isTrue);
    });

    test(
      'names categories and accounts rather than referencing their ids',
      () async {
        final csv = await exporter.buildTransactionsCsv();
        expect(csv.contains('Продукты 🍎'), isTrue);
        expect(csv.contains('Кошелёк 💶'), isTrue);
        expect(csv.contains('csv_cat_food'), isFalse);
        expect(csv.contains('csv_acc_eur'), isFalse);
      },
    );
  });

  group('CSV round trip', () {
    test('re-imports onto the existing accounts and categories, matched by '
        'name - no CRLF-mangled duplicates', () async {
      final csv = await exporter.buildTransactionsCsv();
      final accountsBefore = (await db.select(db.accounts).get()).length;
      final categoriesBefore = (await db.select(db.categories).get()).length;

      await db.delete(db.transactions).go();
      await importer.importContent(csv, isCsv: true);

      // The exporter writes RFC-conform CRLF. A parser pinned to `eol: '\n'`
      // reads "\r" as ordinary text, so every last column arrived with a
      // trailing carriage return and "Кошелёк 💶\r" became a second account.
      expect((await db.select(db.accounts).get()).length, accountsBefore);
      expect((await db.select(db.categories).get()).length, categoriesBefore);
      for (final a in await db.select(db.accounts).get()) {
        expect(a.name.contains('\r'), isFalse);
      }

      final imported = await db.transactionsDao.getAllTransactions();
      expect(imported.length, 4);
      expect(imported.map((t) => t.accountId).toSet(), {
        'csv_acc_eur',
        'csv_acc_jpy',
        'csv_acc_btc',
      });
      expect(imported.map((t) => t.categoryId).toSet(), {
        'csv_cat_food',
        'csv_cat_income',
      });
    });

    test('date, amount, currency and description survive verbatim', () async {
      final csv = await exporter.buildTransactionsCsv();
      await db.delete(db.transactions).go();
      await importer.importContent(csv, isCsv: true);

      final imported = await db.transactionsDao.getAllTransactions();
      final byDescription = {for (final t in imported) t.description: t};

      expect(
        byDescription.keys,
        containsAll(<String>[
          'Point one',
          'Two, with a "quote" and a comma',
          'ラーメン',
          'Sats',
        ]),
      );

      final a = byDescription['Point one']!;
      expect(
        a.date,
        DateTime(2025, 3, 30, 0, 15),
        reason:
            'a transaction 15 minutes after midnight must not slide '
            'onto the previous day',
      );
      expect(a.amount, 0.1);
      expect(a.currencyCode, 'EUR');

      final late = byDescription['Two, with a "quote" and a comma']!;
      expect(late.date, DateTime(2025, 3, 30, 23, 45));
      expect(late.date.day, 30);
    });

    test('money keeps its exact encoding: minor units for fiat, NULL for '
        'crypto', () async {
      final csv = await exporter.buildTransactionsCsv();
      await db.delete(db.transactions).go();
      await importer.importContent(csv, isCsv: true);

      final byDescription = {
        for (final t in await db.transactionsDao.getAllTransactions())
          t.description: t,
      };

      expect(byDescription['Point one']!.amountMinor, 10);
      expect(
        byDescription['ラーメン']!.amountMinor,
        1234,
        reason: 'JPY has no cents, so 1234 yen is 1234 minor units',
      );
      expect(
        byDescription['Sats']!.amountMinor,
        isNull,
        reason: 'a non-fiat amount stays on the double',
      );
      expect(byDescription['Sats']!.amount, 0.12345678);
      // A fiat row whose minor column is NULL is silently skipped by the
      // exact-sum SQL (SUM ignores NULL), so "no fee" has to be 0, not NULL.
      expect(byDescription['Point one']!.feeMinor, 0);
    });

    test('an account created by the import gets minor units matching its '
        'currency', () async {
      final csv = await exporter.buildTransactionsCsv();
      await wipeBusinessTables();
      await importer.importContent(csv, isCsv: true);

      final accounts = {
        for (final a in await db.select(db.accounts).get()) a.name: a,
      };
      expect(accounts['Кошелёк 💶']!.balanceMinor, 0);
      expect(accounts['Кошелёк 💶']!.openingBalanceMinor, 0);
      expect(accounts['Cold wallet']!.balanceMinor, isNull);
      expect(accounts['Cold wallet']!.openingBalanceMinor, isNull);
    });

    test('non-ASCII names and descriptions survive', () async {
      final csv = await exporter.buildTransactionsCsv();
      await wipeBusinessTables();
      await importer.importContent(csv, isCsv: true);

      final names = (await db.select(db.accounts).get()).map((a) => a.name);
      expect(names, contains('Кошелёк 💶'));
      expect(names, contains('Japan, Ltd "JPY"'));
      final categories = (await db.select(db.categories).get()).map(
        (c) => c.name,
      );
      expect(categories, contains('Продукты 🍎'));
      final descriptions = (await db.select(db.transactions).get()).map(
        (t) => t.description,
      );
      expect(descriptions, contains('ラーメン'));
      expect(descriptions, contains('Two, with a "quote" and a comma'));
    });

    test(
      'LF-only input parses the same as the CRLF the exporter writes',
      () async {
        final csv = await exporter.buildTransactionsCsv();
        await db.delete(db.transactions).go();
        await importer.importContent(csv.replaceAll('\r\n', '\n'), isCsv: true);

        final imported = await db.transactionsDao.getAllTransactions();
        expect(imported.length, 4);
        for (final t in imported) {
          expect(t.description.contains('\r'), isFalse);
        }
      },
    );
  });

  group('what the CSV format loses, by design', () {
    test('transaction ids are not carried, so a re-import is a new set of '
        'rows rather than the same ones', () async {
      final csv = await exporter.buildTransactionsCsv();
      await db.delete(db.transactions).go();
      await importer.importContent(csv, isCsv: true);

      final ids = (await db.select(db.transactions).get())
          .map((t) => t.id)
          .toSet();
      expect(ids.contains('csv_tx_a'), isFalse);
      expect(ids.length, 4);
    });

    test('fee, exchange rate and the linked-transaction id are written but '
        'never read back', () async {
      final csv = await exporter.buildTransactionsCsv();
      expect(csv.contains('1.0876'), isTrue, reason: 'the exporter writes it');
      expect(csv.contains('csv_tx_a'), isTrue);

      await db.delete(db.transactions).go();
      await importer.importContent(csv, isCsv: true);

      final restored = (await db.transactionsDao.getAllTransactions())
          .firstWhere((t) => t.description.startsWith('Two,'));
      expect(restored.fee, 0.0);
      expect(restored.exchangeRate, isNull);
      expect(restored.linkedTransactionId, isNull);
    });

    test(
      'a category created by the import is always an expense category',
      () async {
        final csv = await exporter.buildTransactionsCsv();
        await wipeBusinessTables();
        await importer.importContent(csv, isCsv: true);

        final salary = (await db.select(db.categories).get()).firstWhere(
          (c) => c.name == 'Salary',
        );
        expect(
          salary.type,
          CategoryType.expense,
          reason:
              'the CSV carries no category type, so the income category '
              'comes back as an expense one',
        );
      },
    );

    test('the CSV import appends rather than replacing', () async {
      final csv = await exporter.buildTransactionsCsv();
      await importer.importContent(csv, isCsv: true);
      expect(
        (await db.transactionsDao.getAllTransactions()).length,
        8,
        reason: '4 originals plus 4 appended copies',
      );
    });
  });

  group('malformed CSV is refused, never half-imported', () {
    const header = 'Date,Amount,Currency,Description,Category,Account';
    late int before;

    setUp(() async {
      before = (await db.select(db.transactions).get()).length;
    });

    Future<void> expectRefused(String content, Matcher messageMatcher) async {
      await expectLater(
        importer.importContent(content, isCsv: true),
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
        before,
        reason: 'a refused file must not leave a partial import behind',
      );
    }

    test('an empty file', () async {
      await expectRefused('', contains('empty'));
    });

    test('a missing required column', () async {
      await expectRefused(
        'Date,Amount,Currency,Description,Category\r\n'
        '2025-03-30 12:00:00,1.5,EUR,Lunch,Продукты 🍎\r\n',
        contains('Missing required columns'),
      );
    });

    test('a row with fewer columns than the header', () async {
      await expectRefused(
        '$header\r\n'
        '2025-03-30 12:00:00,1.5,EUR,Lunch,Продукты 🍎,Кошелёк 💶\r\n'
        '2025-03-31 12:00:00,2.5\r\n',
        allOf(contains('line 3'), contains('columns')),
      );
    });

    test('text where the amount belongs', () async {
      await expectRefused(
        '$header\r\n'
        '2025-03-30 12:00:00,twelve,EUR,Lunch,Продукты 🍎,Кошелёк 💶\r\n',
        allOf(contains('line 2'), contains('amount'), contains('twelve')),
      );
    });

    test('text where the date belongs', () async {
      await expectRefused(
        '$header\r\n'
        'yesterday,1.5,EUR,Lunch,Продукты 🍎,Кошелёк 💶\r\n',
        allOf(contains('line 2'), contains('date'), contains('yesterday')),
      );
    });

    test('the good rows around a bad one are not imported either', () async {
      await expectRefused(
        '$header\r\n'
        '2025-03-30 12:00:00,1.5,EUR,Good one,Продукты 🍎,Кошелёк 💶\r\n'
        '2025-03-31 12:00:00,oops,EUR,Bad one,Продукты 🍎,Кошелёк 💶\r\n'
        '2025-04-01 12:00:00,2.5,EUR,Good two,Продукты 🍎,Кошелёк 💶\r\n',
        contains('line 3'),
      );
      final descriptions = (await db.select(db.transactions).get()).map(
        (t) => t.description,
      );
      expect(descriptions.contains('Good one'), isFalse);
      expect(descriptions.contains('Good two'), isFalse);
    });
  });

  group('tolerated CSV variations', () {
    const header = 'Date,Amount,Currency,Description,Category,Account';

    test('an extra unknown column is ignored', () async {
      await db.delete(db.transactions).go();
      await importer.importContent(
        '$header,Tags,Notes\r\n'
        '2025-03-30 12:00:00,1.5,EUR,Lunch,Продукты 🍎,Кошелёк 💶,#food,ok\r\n',
        isCsv: true,
      );

      final imported = await db.transactionsDao.getAllTransactions();
      expect(imported.length, 1);
      expect(imported.single.description, 'Lunch');
      expect(imported.single.amount, 1.5);
      expect(imported.single.accountId, 'csv_acc_eur');
    });

    test(
      'a blank separator line is skipped, not treated as a short row',
      () async {
        await db.delete(db.transactions).go();
        await importer.importContent(
          '$header\r\n'
          '2025-03-30 12:00:00,1.5,EUR,Lunch,Продукты 🍎,Кошелёк 💶\r\n'
          '\r\n'
          '2025-03-31 12:00:00,2.5,EUR,Dinner,Продукты 🍎,Кошелёк 💶\r\n',
          isCsv: true,
        );
        expect((await db.transactionsDao.getAllTransactions()).length, 2);
      },
    );

    test('a lower-case header still resolves its columns', () async {
      await db.delete(db.transactions).go();
      await importer.importContent(
        'date,amount,currency,description,category,account\r\n'
        '2025-03-30 12:00:00,1.5,EUR,Lunch,Продукты 🍎,Кошелёк 💶\r\n',
        isCsv: true,
      );
      expect((await db.transactionsDao.getAllTransactions()).length, 1);
    });
  });
}
