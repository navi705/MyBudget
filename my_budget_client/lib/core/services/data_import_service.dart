import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import 'package:my_budget_client/core/utils/platform/io_helper.dart';
import 'package:my_budget_client/core/utils/platform/platform_utils.dart';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:uuid/uuid.dart';
import 'package:my_budget_client/core/services/android_file_picker_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataImportService {
  final AppDatabase _db;
  final AndroidFilePickerService _androidFilePicker;

  DataImportService(this._db, this._androidFilePicker);

  Future<bool> importData(bool isCsv, {String? title}) async {
    final expectedExt = isCsv ? 'csv' : 'json';
    List<String>? pickedPaths;
    FilePickerResult? result;

    if (AppPlatform.isAndroid) {
      pickedPaths = await _androidFilePicker.pickFile(
        mimeType: '*/*',
        title: title ?? (isCsv ? 'Select CSV' : 'Select JSON'),
      );
    } else {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [expectedExt],
      );
      if (result != null && result.files.isNotEmpty) {
        pickedPaths = [result.files.single.path!];
      }
    }

    if ((pickedPaths != null && pickedPaths.isNotEmpty) ||
        (result != null && result.files.isNotEmpty)) {
      final String content;
      final String extension;

      if (result != null && result.files.isNotEmpty) {
        final platformFile = result.files.first;
        extension = platformFile.name.split('.').last.toLowerCase();
        if (platformFile.bytes != null) {
          content = utf8.decode(platformFile.bytes!);
        } else {
          content = await IoHelper.readAsString(platformFile.path!);
        }
      } else {
        final pickedPath = pickedPaths!.first;
        extension = pickedPath.split('.').last.toLowerCase();
        content = await IoHelper.readAsString(pickedPath);
      }

      if (extension != expectedExt) {
        throw Exception(
          'Invalid file type. Please select a .$expectedExt file.',
        );
      }

      if (content.trim().isEmpty) {
        throw Exception('The selected file is empty.');
      }

      if (isCsv) {
        await _importCsv(content);
      } else {
        await _importJson(content);
      }
      return true;
    }
    return false;
  }

  Future<void> importExchangeRates({String? title}) async {
    FilePickerResult? result;
    List<String>? pickedPaths;

    if (AppPlatform.isAndroid) {
      pickedPaths = await _androidFilePicker.pickFile(
        mimeType: '*/*',
        title: title ?? 'Select CSV or JSON',
      );
    } else {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'json'],
      );
      if (result != null && result.files.isNotEmpty) {
        pickedPaths = [result.files.single.path!];
      }
    }

    if ((pickedPaths != null && pickedPaths.isNotEmpty) ||
        (result != null && result.files.isNotEmpty)) {
      final String content;
      final String extension;

      if (result != null && result.files.isNotEmpty) {
        final platformFile = result.files.first;
        extension = platformFile.name.split('.').last.toLowerCase();
        if (platformFile.bytes != null) {
          content = utf8.decode(platformFile.bytes!);
        } else {
          content = await IoHelper.readAsString(platformFile.path!);
        }
      } else {
        final pickedPath = pickedPaths!.first;
        extension = pickedPath.split('.').last.toLowerCase();
        content = await IoHelper.readAsString(pickedPath);
      }

      if (extension != 'csv' && extension != 'json') {
        throw Exception(
          'Invalid file type. Please select a .csv or .json file.',
        );
      }

      final isCsv = extension == 'csv';

      if (isCsv) {
        await _importExchangeRatesCsv(content);
      } else {
        await _importExchangeRatesJson(content);
      }
    }
  }

  Future<void> _importExchangeRatesJson(String content) async {
    final data = jsonDecode(content);
    if (data is List) {
      await _db.batch((batch) {
        batch.insertAll(
          _db.exchangeRates,
          data.map((e) => ExchangeRate.fromJson(e)).toList(),
          mode: InsertMode.insertOrReplace,
        );
      });
    } else if (data is Map<String, dynamic>) {
      // Logic for date-indexed JSON (like currency_history.json)
      final List<ExchangeRatesCompanion> rates = [];
      data.forEach((dateKey, dateValue) {
        final DateTime recordDate = DateTime.parse(dateKey);
        if (dateValue is Map) {
          dateValue.forEach((currencyKey, rateValue) {
            if (rateValue is num) {
              rates.add(
                ExchangeRatesCompanion.insert(
                  fromCurrencyCode: 'EUR',
                  toCurrencyCode: currencyKey.toString().toUpperCase(),
                  rate: rateValue.toDouble(),
                  date: recordDate,
                  preset: 0,
                ),
              );
            }
          });
        }
      });
      await _db.batch((batch) {
        batch.insertAll(
          _db.exchangeRates,
          rates,
          mode: InsertMode.insertOrReplace,
        );
      });
    }
  }

  Future<void> _importExchangeRatesCsv(String content) async {
    final rows = const CsvToListConverter().convert(content, eol: '\n');
    if (rows.isEmpty) return;

    final header = rows.first
        .map((e) => e.toString().trim().toLowerCase())
        .toList();
    rows.removeAt(0);

    final dateIdx = header.indexOf('date');
    final fromIdx = header.indexOf('from');
    final toIdx = header.indexOf('to');
    final rateIdx = header.indexOf('rate');

    if (dateIdx == -1 || fromIdx == -1 || toIdx == -1 || rateIdx == -1) {
      throw Exception('Invalid CSV format. Missing Date, From, To, or Rate.');
    }

    final List<ExchangeRatesCompanion> rates = [];
    for (var row in rows) {
      if (row.length < header.length) continue;
      final date = DateTime.tryParse(row[dateIdx].toString()) ?? DateTime.now();
      final from = row[fromIdx].toString().toUpperCase();
      final to = row[toIdx].toString().toUpperCase();
      final rate = double.tryParse(row[rateIdx].toString()) ?? 1.0;

      rates.add(
        ExchangeRatesCompanion.insert(
          fromCurrencyCode: from,
          toCurrencyCode: to,
          rate: rate,
          date: date,
          preset: 0,
        ),
      );
    }

    await _db.batch((batch) {
      batch.insertAll(
        _db.exchangeRates,
        rates,
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  Future<void> _importJson(String content) async {
    debugPrint('[RESTORE] _importJson: parsing JSON...');
    // RESTORE STRATEGY: Wipe and Replace
    final data = jsonDecode(content) as Map<String, dynamic>;
    final now = DateTime.now().millisecondsSinceEpoch;
    debugPrint('[RESTORE] backup version: ${data['version']}, timestamp: ${data['timestamp']}');

    // Deduplicate asset_entries BEFORE modifiedAt update so original timestamps are used for dedup
    // Partial UNIQUE INDEX: (asset_id, date, source) WHERE source = 'custom_api'
    // Old backups may contain duplicates created before the index existed.
    if (data['asset_entries'] != null) {
      final rawEntries = data['asset_entries'] as List;
      final deduped = _deduplicateAssetEntries(rawEntries);
      debugPrint('[RESTORE] asset_entries: ${rawEntries.length} raw → ${deduped.length} after dedup');
      data['asset_entries'] = deduped;
    }

    // Mark all imported records as new by updating their modified_at
    data.forEach((key, value) {
      if (value is List) {
        for (var item in value) {
          if (item is Map<String, dynamic>) {
            item['modifiedAt'] = now;
          }
        }
      }
    });

    // PRAGMA foreign_keys must be set outside transaction in SQLite
    await _db.customStatement('PRAGMA foreign_keys = OFF');

    try {
      await _db.transaction(() async {
        // 1. Delete all existing data (including technical tables)
        debugPrint('[RESTORE] Deleting existing data...');
        // Business Tables
        await _db.delete(_db.transactions).go();
        await _db.delete(_db.accounts).go();
        await _db.delete(_db.categories).go();
        await _db.delete(_db.exchangeRates).go();
        await _db.delete(_db.inflationRates).go();
        await _db.delete(_db.assetEntries).go();
        await _db.delete(_db.currencyDesignations).go();
        await _db.delete(_db.currencies).go();
        await _db.delete(_db.accountTypes).go();
        await _db.delete(_db.styles).go();
        await _db.delete(_db.languages).go();

        // Technical/Other Tables
        await _db.delete(_db.settings).go();
        await _db.delete(_db.customThemes).go();
        await _db.delete(_db.customDataSources).go();
        await _db.delete(_db.apiSettingsTable).go();
        await _db.delete(_db.smsPresets).go();
        await _db.delete(_db.syncLog).go();
        await _db.delete(_db.conflictHistory).go();
        await _db.delete(_db.apiFetchStatuses).go();
        await _db.delete(_db.syncProcessedFiles).go();
        debugPrint('[RESTORE] Existing data deleted.');

        // 2. Insert new data
        // Order matters due to foreign key constraints
        if (data['languages'] != null) {
          final list = data['languages'] as List;
          debugPrint('[RESTORE] Inserting ${list.length} languages...');
          await _db.batch((batch) {
            batch.insertAll(
              _db.languages,
              list.map((e) => Language.fromJson(e as Map<String, dynamic>)).toList(),
              mode: InsertMode.insertOrIgnore,
            );
          });
        }

        if (data['styles'] != null) {
          final list = data['styles'] as List;
          debugPrint('[RESTORE] Inserting ${list.length} styles...');
          await _db.batch((batch) {
            batch.insertAll(
              _db.styles,
              list.map((e) => Style.fromJson(e as Map<String, dynamic>)).toList(),
              mode: InsertMode.insertOrIgnore,
            );
          });
        }

        if (data['account_types'] != null) {
          final list = data['account_types'] as List;
          debugPrint('[RESTORE] Inserting ${list.length} account_types...');
          await _db.batch((batch) {
            batch.insertAll(
              _db.accountTypes,
              list.map((e) => AccountType.fromJson(e as Map<String, dynamic>)).toList(),
              mode: InsertMode.insertOrIgnore,
            );
          });
        }

        if (data['currencies'] != null) {
          final list = data['currencies'] as List;
          debugPrint('[RESTORE] Inserting ${list.length} currencies...');
          await _db.batch((batch) {
            batch.insertAll(
              _db.currencies,
              list.map((e) => Currency.fromJson(e as Map<String, dynamic>)).toList(),
              mode: InsertMode.insertOrIgnore,
            );
          });
        }

        if (data['currency_designations'] != null) {
          final list = data['currency_designations'] as List;
          debugPrint('[RESTORE] Inserting ${list.length} currency_designations...');
          await _db.batch((batch) {
            batch.insertAll(
              _db.currencyDesignations,
              list.map((e) => CurrencyDesignation.fromJson(e as Map<String, dynamic>)).toList(),
              mode: InsertMode.insertOrIgnore,
            );
          });
        }

        if (data['accounts'] != null) {
          final list = data['accounts'] as List;
          debugPrint('[RESTORE] Inserting ${list.length} accounts...');
          await _db.batch((batch) {
            batch.insertAll(
              _db.accounts,
              list.map((e) => DbAccount.fromJson(e as Map<String, dynamic>)).toList(),
              mode: InsertMode.insertOrIgnore,
            );
          });
        }

        if (data['categories'] != null) {
          final list = data['categories'] as List;
          debugPrint('[RESTORE] Inserting ${list.length} categories...');
          await _db.batch((batch) {
            batch.insertAll(
              _db.categories,
              list.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList(),
              mode: InsertMode.insertOrIgnore,
            );
          });
        }

        if (data['exchange_rates'] != null) {
          final list = data['exchange_rates'] as List;
          debugPrint('[RESTORE] Inserting ${list.length} exchange_rates...');
          await _db.batch((batch) {
            batch.insertAll(
              _db.exchangeRates,
              list.map((e) => ExchangeRate.fromJson(e as Map<String, dynamic>)).toList(),
              mode: InsertMode.insertOrIgnore,
            );
          });
        }

        if (data['inflation_rates'] != null) {
          final list = data['inflation_rates'] as List;
          debugPrint('[RESTORE] Inserting ${list.length} inflation_rates...');
          await _db.batch((batch) {
            batch.insertAll(
              _db.inflationRates,
              list.map((e) => InflationRate.fromJson(e as Map<String, dynamic>)).toList(),
              mode: InsertMode.insertOrIgnore,
            );
          });
        }

        if (data['asset_entries'] != null) {
          final list = data['asset_entries'] as List;
          debugPrint('[RESTORE] Inserting ${list.length} asset_entries...');
          await _db.batch((batch) {
            batch.insertAll(
              _db.assetEntries,
              list.map((e) => AssetEntry.fromJson(e as Map<String, dynamic>)).toList(),
              // insertOrIgnore: skip duplicates that violate partial UNIQUE INDEX
              mode: InsertMode.insertOrIgnore,
            );
          });
          debugPrint('[RESTORE] asset_entries inserted.');
        }

        if (data['transactions'] != null) {
          final list = data['transactions'] as List;
          debugPrint('[RESTORE] Inserting ${list.length} transactions...');
          await _db.batch((batch) {
            batch.insertAll(
              _db.transactions,
              list.map((e) => Transaction.fromJson(e as Map<String, dynamic>)).toList(),
              mode: InsertMode.insertOrIgnore,
            );
          });
          debugPrint('[RESTORE] transactions inserted.');
        }

        // Technical Tables
        if (data['settings'] != null) {
          final list = data['settings'] as List;
          debugPrint('[RESTORE] Inserting ${list.length} settings...');
          await _db.batch((batch) {
            batch.insertAll(
              _db.settings,
              list.map((e) => Setting.fromJson(e as Map<String, dynamic>)).toList(),
              mode: InsertMode.insertOrIgnore,
            );
          });
        }

        if (data['custom_themes'] != null) {
          final list = data['custom_themes'] as List;
          debugPrint('[RESTORE] Inserting ${list.length} custom_themes...');
          await _db.batch((batch) {
            batch.insertAll(
              _db.customThemes,
              list.map((e) => DbCustomTheme.fromJson(e as Map<String, dynamic>)).toList(),
              mode: InsertMode.insertOrIgnore,
            );
          });
        }

        if (data['custom_data_sources'] != null) {
          final list = data['custom_data_sources'] as List;
          debugPrint('[RESTORE] Inserting ${list.length} custom_data_sources...');
          await _db.batch((batch) {
            batch.insertAll(
              _db.customDataSources,
              list.map((e) => CustomDataSource.fromJson(e as Map<String, dynamic>)).toList(),
              mode: InsertMode.insertOrIgnore,
            );
          });
        }

        if (data['api_settings'] != null) {
          final list = data['api_settings'] as List;
          debugPrint('[RESTORE] Inserting ${list.length} api_settings...');
          await _db.batch((batch) {
            batch.insertAll(
              _db.apiSettingsTable,
              list.map((e) => ApiSettingsTableData.fromJson(e as Map<String, dynamic>)).toList(),
              mode: InsertMode.insertOrIgnore,
            );
          });
        }

        if (data['sms_presets'] != null) {
          final list = data['sms_presets'] as List;
          debugPrint('[RESTORE] Inserting ${list.length} sms_presets...');
          await _db.batch((batch) {
            batch.insertAll(
              _db.smsPresets,
              list.map((e) => SmsPreset.fromJson(e as Map<String, dynamic>)).toList(),
              mode: InsertMode.insertOrIgnore,
            );
          });
        }

        debugPrint('[RESTORE] All tables inserted successfully.');
      });

      // Reset sync state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('server_last_sync_timestamp', 0);
      await prefs.setInt('server_last_push_timestamp', 0);
      debugPrint('[RESTORE] Sync state reset. Restore complete.');
    } catch (e, stack) {
      debugPrint('[RESTORE] ERROR: $e');
      debugPrint('[RESTORE] Stack: $stack');
      rethrow;
    } finally {
      // Re-enable foreign key checks
      await _db.customStatement('PRAGMA foreign_keys = ON');
    }
  }

  /// Deduplicate asset_entries from backup.
  /// Partial UNIQUE INDEX: (asset_id, date, source) WHERE source = 'custom_api'
  /// Old backups may contain duplicates created before the index existed.
  /// Keep the entry with the highest modifiedAt for each (assetId, date, source) group.
  List<Map<String, dynamic>> _deduplicateAssetEntries(List<dynamic> raw) {
    final seen = <String, Map<String, dynamic>>{};

    for (final item in raw) {
      if (item is! Map<String, dynamic>) continue;
      final source = item['source'] as String? ?? '';
      if (source == 'custom_api') {
        final assetId = item['assetId'] as String? ?? '';
        final date = item['date']?.toString() ?? '';
        final key = '$assetId|$date|$source';
        final existing = seen[key];
        if (existing == null) {
          seen[key] = item;
        } else {
          // Keep the one with higher modifiedAt
          final existingModified = (existing['modifiedAt'] as num?)?.toInt() ?? 0;
          final itemModified = (item['modifiedAt'] as num?)?.toInt() ?? 0;
          if (itemModified > existingModified) {
            seen[key] = item;
          }
        }
      } else {
        // Non-custom_api entries: deduplicate by id only
        final id = item['id'] as String? ?? '';
        if (id.isNotEmpty && !seen.containsKey('id:$id')) {
          seen['id:$id'] = item;
        } else if (id.isEmpty) {
          // No id — keep as-is (shouldn't happen)
          seen['noid:${seen.length}'] = item;
        }
      }
    }

    return seen.values.toList();
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
            ? row[currencyIdx].toString().toUpperCase()
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
