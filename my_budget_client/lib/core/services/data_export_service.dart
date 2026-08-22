import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:my_budget_client/core/utils/platform/platform_utils.dart';
import 'package:my_budget_client/core/utils/platform/io_helper.dart';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:path_provider/path_provider.dart'; // Needed for temp file on mobile share path
import 'package:share_plus/share_plus.dart'; // Mobile sharing; file_picker is used for desktop

class DataExportService {
  final AppDatabase _db;

  DataExportService(this._db);

  /// Exports the data and returns whether it was actually delivered
  /// (file written on desktop, share sheet invoked on mobile, or browser
  /// download started on web).
  /// Returns `false` when the user cancels.
  Future<bool> exportData(bool isCsv) async {
    if (isCsv) {
      return _exportCsv();
    } else {
      return _exportJson();
    }
  }

  Future<bool> _exportJson() async {
    return _saveFile(await buildJsonBackup(), 'my_budget_backup.json');
  }

  /// Builds the whole-database JSON backup document.
  ///
  /// Split out of [_exportJson] so the document can be produced — and asserted
  /// on — without the native save dialog that [_saveFile] ends in.
  ///
  /// Every table is read straight off the table rather than through its DAO:
  /// the `getAllX` DAO methods filter `is_deleted = 1` away, so the backup used
  /// to drop soft-deleted rows while keeping the live rows that still point at
  /// them (a child category whose parent was deleted, an account whose style
  /// was deleted). Restoring such a file left those references pointing at rows
  /// that no longer existed, and threw away the tombstones sync needs.
  @visibleForTesting
  Future<String> buildJsonBackup() async {
    final transactions = await _db.select(_db.transactions).get();
    final categories = await _db.select(_db.categories).get();
    final accounts = await _db.select(_db.accounts).get();
    final styles = await _db.select(_db.styles).get();
    final accountTypes = await _db.select(_db.accountTypes).get();
    final currencies = await _db.select(_db.currencies).get();
    final designations = await _db.select(_db.currencyDesignations).get();
    final rates = await _db.select(_db.exchangeRates).get();
    final assetEntries = await _db.select(_db.assetEntries).get();

    // Missing tables in previous version
    final languages = await _db.select(_db.languages).get();
    final inflationRates = await _db.select(_db.inflationRates).get();
    final settings = await _db.select(_db.settings).get();
    final customThemes = await _db.select(_db.customThemes).get();
    final customDataSources = await _db.select(_db.customDataSources).get();
    final apiSettings = await _db.select(_db.apiSettingsTable).get();
    final smsPresets = await _db.select(_db.smsPresets).get();

    final data = {
      'version': 2, // Incremented version
      'timestamp': DateTime.now().toIso8601String(),
      'transactions': transactions.map((e) => e.toJson()).toList(),
      'categories': categories.map((e) => e.toJson()).toList(),
      'accounts': accounts.map((e) => e.toJson()).toList(),
      'styles': styles.map((e) => e.toJson()).toList(),
      'account_types': accountTypes.map((e) => e.toJson()).toList(),
      'currencies': currencies.map((e) => e.toJson()).toList(),
      'currency_designations': designations.map((e) => e.toJson()).toList(),
      'exchange_rates': rates.map((e) => e.toJson()).toList(),
      'asset_entries': assetEntries.map((e) => e.toJson()).toList(),
      'languages': languages.map((e) => e.toJson()).toList(),
      'inflation_rates': inflationRates.map((e) => e.toJson()).toList(),
      'settings': settings.map((e) => e.toJson()).toList(),
      'custom_themes': customThemes.map((e) => e.toJson()).toList(),
      'custom_data_sources': customDataSources.map((e) => e.toJson()).toList(),
      'api_settings': apiSettings.map((e) => e.toJson()).toList(),
      'sms_presets': smsPresets.map((e) => e.toJson()).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<bool> _exportCsv() async {
    return _saveFile(
      await buildTransactionsCsv(),
      'my_budget_transactions.csv',
    );
  }

  /// Builds the human-readable transactions CSV.
  ///
  /// Split out of [_exportCsv] for the same reason as [buildJsonBackup]. Unlike
  /// the JSON backup this is a report, not a snapshot: it goes through the DAOs
  /// on purpose, so deleted rows stay out of it.
  @visibleForTesting
  Future<String> buildTransactionsCsv() async {
    // For CSV, we flatten Transactions as the main value.
    // We join Categories and Accounts to get readable names.
    final transactions = await _db.transactionsDao.getAllTransactions();
    final categories = await _db.categoriesDao.getAllCategories();
    final accounts = await _db.accountsDao.getAllAccounts();

    final categoryMap = {for (var c in categories) c.id: c.name};
    final accountMap = {for (var a in accounts) a.id: a.name};

    final List<List<dynamic>> rows = [];
    // Header
    rows.add([
      'Date',
      'Amount',
      'Currency',
      'Description',
      'Category',
      'Account',
      'Type',
      'Exchange Rate',
      'Fee',
      'Linked Transaction ID',
    ]);

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss', 'en');

    for (var t in transactions) {
      rows.add([
        dateFormat.format(t.date),
        t.amount,
        t.currencyCode,
        t.description,
        categoryMap[t.categoryId] ?? t.categoryId,
        accountMap[t.accountId] ?? t.accountId,
        t.amount >= 0 ? 'Income' : 'Expense',
        t.exchangeRate ?? '',
        t.fee,
        t.linkedTransactionId ?? '',
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Persists [content] to a file for the user.
  ///
  /// Returns `true` when the file is written (desktop), the share sheet is
  /// invoked (mobile) or the browser download is started (web); `false` on
  /// user cancellation.
  Future<bool> _saveFile(String content, String fileName) async {
    if (kIsWeb) {
      // file_picker's web backend wraps the bytes in a Blob and clicks a
      // hidden download anchor. The browser owns the destination from there,
      // so `saveFile` resolves to null even on success — unlike desktop, a
      // null result here must not be read as a cancellation.
      await FilePicker.platform.saveFile(
        fileName: fileName,
        bytes: utf8.encode(content),
      );
      return true;
    }

    if (AppPlatform.isWindows || AppPlatform.isLinux || AppPlatform.isMacOS) {
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Please select an output file:',
        fileName: fileName,
      );

      if (outputFile == null) {
        // User cancelled the save dialog.
        return false;
      }

      await IoHelper.writeAsString(outputFile, content);
      return true;
    } else {
      // Mobile (Android/iOS): write to a temp file and hand it to the OS
      // share sheet via share_plus.
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$fileName';
      await IoHelper.writeAsString(filePath, content);

      // share_plus 10.x uses the static Share.shareXFiles API.
      final result = await Share.shareXFiles([XFile(filePath)]);

      // Android generally reports `unavailable` (no result feedback), while
      // iOS reports `success`/`dismissed`. Treat anything other than an
      // explicit user dismissal as a completed share.
      return result.status != ShareResultStatus.dismissed;
    }
  }
}
