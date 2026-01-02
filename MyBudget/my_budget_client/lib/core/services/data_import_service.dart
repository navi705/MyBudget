import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:uuid/uuid.dart';

class DataImportService {
  final AppDatabase _db;

  DataImportService(this._db);

  Future<void> importData(bool isCsv) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: isCsv ? ['csv'] : ['json'],
    );

    if (result != null && result.files.isNotEmpty) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();

      if (content.trim().isEmpty) {
        throw Exception('The selected file is empty.');
      }

      if (isCsv) {
        await _importCsv(content);
      } else {
        await _importJson(content);
      }
    }
  }

  Future<void> _importJson(String content) async {
    // RESTORE STRATEGY: Wipe and Replace
    final data = jsonDecode(content) as Map<String, dynamic>;

    await _db.transaction(() async {
      // 1. Delete all existing data
      // Delete in reverse order of dependencies usually, but here with drift we can just delete.
      // Tables: Transactions, ExchangeRates, CurrencyDesignations, Currencies, AccountTypes, Styles, Accounts, Categories
      await _db.delete(_db.transactions).go();
      await _db.delete(_db.exchangeRates).go();
      await _db.delete(_db.currencyDesignations).go();
      await _db.delete(_db.currencies).go();
      await _db.delete(_db.accounts).go();
      await _db.delete(_db.categories).go();
      await _db.delete(_db.accountTypes).go();
      await _db.delete(_db.styles).go();

      // 2. Insert new data
      // Helpers to map list of json to inserts
      if (data['styles'] != null) {
        await _db.batch((batch) {
          batch.insertAll(
            _db.styles,
            (data['styles'] as List).map((e) => Style.fromJson(e)).toList(),
          );
        });
      }

      if (data['account_types'] != null) {
        await _db.batch((batch) {
          batch.insertAll(
            _db.accountTypes,
            (data['account_types'] as List)
                .map((e) => AccountType.fromJson(e))
                .toList(),
          );
        });
      }

      if (data['accounts'] != null) {
        await _db.batch((batch) {
          batch.insertAll(
            _db.accounts,
            (data['accounts'] as List)
                .map((e) => DbAccount.fromJson(e))
                .toList(),
          );
        });
      }

      if (data['categories'] != null) {
        await _db.batch((batch) {
          batch.insertAll(
            _db.categories,
            (data['categories'] as List)
                .map((e) => Category.fromJson(e))
                .toList(),
          );
        });
      }

      if (data['currencies'] != null) {
        await _db.batch((batch) {
          batch.insertAll(
            _db.currencies,
            (data['currencies'] as List)
                .map((e) => Currency.fromJson(e))
                .toList(),
          );
        });
      }

      if (data['currency_designations'] != null) {
        await _db.batch((batch) {
          batch.insertAll(
            _db.currencyDesignations,
            (data['currency_designations'] as List)
                .map((e) => CurrencyDesignation.fromJson(e))
                .toList(),
          );
        });
      }

      if (data['exchange_rates'] != null) {
        await _db.batch((batch) {
          batch.insertAll(
            _db.exchangeRates,
            (data['exchange_rates'] as List)
                .map((e) => ExchangeRate.fromJson(e))
                .toList(),
          );
        });
      }

      if (data['transactions'] != null) {
        await _db.batch((batch) {
          batch.insertAll(
            _db.transactions,
            (data['transactions'] as List)
                .map((e) => Transaction.fromJson(e))
                .toList(),
          );
        });
      }
    });
  }

  Future<void> _importCsv(String content) async {
    // APPEND STRATEGY
    // Expected Columns: Date, Amount, Currency, Description, Category, Account, Type
    List<List<dynamic>> rows = const CsvToListConverter().convert(
      content,
      eol: '\n',
    );
    if (rows.isEmpty) return;

    // Determine indices from header
    final header = rows.first
        .map((e) => e.toString().trim().toLowerCase())
        .toList();
    rows.removeAt(0); // Remove header

    final dateIdx = header.indexOf('date');
    final amountIdx = header.indexOf('amount');
    final currencyIdx = header.indexOf('currency');
    final descIdx = header.indexOf('description');
    final catIdx = header.indexOf('category');
    final accIdx = header.indexOf('account');

    if (dateIdx == -1 || amountIdx == -1 || catIdx == -1 || accIdx == -1) {
      throw Exception('Invalid CSV format. Missing required columns.');
    }

    // Pre-fetch reference data
    final allCategories = await _db.categoriesDao.getAllCategories();
    final allAccounts = await _db.accountsDao.getAllAccounts();

    // Maps for fast lookup by name
    final categoryMap = {
      for (var c in allCategories) c.name.toLowerCase(): c.id,
    };
    final accountMap = {for (var a in allAccounts) a.name.toLowerCase(): a.id};

    // Default values for new creations
    final defaultStyle = (await _db.stylesDao.getAllStyles()).firstOrNull;
    final defaultAccType =
        (await _db.accountTypesDao.getAllAccountTypes()).firstOrNull;
    final defaultDesignation =
        (await _db.currencyDesignationsDao.getAllDesignations()).firstOrNull;

    // Fallback ID if DB is somehow empty, but constraints will fail anyway if missing.
    // We assume seed data exists.
    final defaultAccTypeId = defaultAccType?.id ?? 'general';
    final defaultCurrencyDesId = defaultDesignation?.id ?? 'symbol';

    // We need to generate IDs manually since insert() doesn't return them for batch/void operations
    // and we need them for foreign keys immediately in the loop
    final uuid = const Uuid();

    await _db.transaction(() async {
      for (var row in rows) {
        if (row.length < header.length) continue; // Skip malformed rows

        final dateStr = row[dateIdx].toString();
        final date = DateTime.tryParse(dateStr) ?? DateTime.now();

        final amount = double.tryParse(row[amountIdx].toString()) ?? 0.0;
        final currencyCode = currencyIdx != -1
            ? row[currencyIdx].toString()
            : 'EUR';
        final description = descIdx != -1 ? row[descIdx].toString() : '';

        final categoryName = row[catIdx].toString();
        final accountName = row[accIdx].toString();

        // 1. Resolve Category
        String categoryId;
        if (categoryMap.containsKey(categoryName.toLowerCase())) {
          categoryId = categoryMap[categoryName.toLowerCase()]!;
        } else {
          categoryId = uuid.v4();
          await _db.categoriesDao.insertCategory(
            CategoriesCompanion(
              id: Value(categoryId),
              name: Value(categoryName),
              type: const Value(CategoryType.expense),
              styleId: Value(defaultStyle?.id),
            ),
          );
          categoryMap[categoryName.toLowerCase()] = categoryId;
        }

        // 2. Resolve Account
        String accountId;
        if (accountMap.containsKey(accountName.toLowerCase())) {
          accountId = accountMap[accountName.toLowerCase()]!;
        } else {
          accountId = uuid.v4();
          await _db.accountsDao.insertAccount(
            AccountsCompanion(
              id: Value(accountId),
              name: Value(accountName),
              currencyCode: Value(currencyCode),
              accountTypeId: Value(defaultAccTypeId),
              currencyDesignationId: Value(defaultCurrencyDesId),
              styleId: Value(defaultStyle?.id),
              balance: const Value(
                0.0,
              ), // Initial balance, can be updated later? Or assume transaction affects it.
              description: const Value('Imported'),
              creationDate: Value(DateTime.now()),
            ),
          );
          accountMap[accountName.toLowerCase()] = accountId;
        }

        // 3. Insert Transaction
        await _db.transactionsDao.insertTransaction(
          TransactionsCompanion(
            date: Value(date),
            amount: Value(amount),
            currencyCode: Value(currencyCode),
            description: Value(description),
            categoryId: Value(categoryId),
            accountId: Value(accountId),
          ),
        );
      }
    });
  }
}
