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
  /// (file written on desktop, or share sheet invoked on mobile).
  /// Returns `false` for user cancellation or unsupported platforms (web).
  Future<bool> exportData(bool isCsv) async {
    if (isCsv) {
      return _exportCsv();
    } else {
      return _exportJson();
    }
  }

  Future<bool> _exportJson() async {
    final transactions = await _db.transactionsDao.getAllTransactions();
    final categories = await _db.categoriesDao.getAllCategories();
    final accounts = await _db.accountsDao.getAllAccounts();
    final styles = await _db.stylesDao.getAllStyles();
    final accountTypes = await _db.accountTypesDao.getAllAccountTypes();
    final currencies = await _db.currenciesDao.getAllCurrencies();
    final designations = await _db.currencyDesignationsDao.getAllDesignations();
    final rates = await _db.exchangeRatesDao.getAllExchangeRates();
    final assetEntries = await _db.assetEntriesDao.getAllAssetEntries();

    // Missing tables in previous version
    final languages = await _db.languageDao.getAllLanguages();
    final inflationRates = await _db.inflationRatesDao.getAllInflationRates();
    final settings = await _db.settingsDao.getAllSettings();
    final customThemes = await _db.customThemesDao.getAllThemes();
    final customDataSources = await _db.customDataSourcesDao
        .getAllDataSources();
    final apiSettings = await _db.apiSettingsDao.getAllSettings();
    final smsPresets = await _db.smsPresetsDao.getAllPresets();

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

    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    return _saveFile(jsonString, 'my_budget_backup.json');
  }

  Future<bool> _exportCsv() async {
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

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

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

    final csvString = const ListToCsvConverter().convert(rows);
    return _saveFile(csvString, 'my_budget_transactions.csv');
  }

  /// Persists [content] to a file for the user.
  ///
  /// Returns `true` when the file is written (desktop) or the share sheet is
  /// invoked (mobile), `false` on user cancellation or on web where file
  /// export is not supported.
  Future<bool> _saveFile(String content, String fileName) async {
    if (kIsWeb) {
      // Web file export is not supported without extra packages / dart:html.
      // Report as unsupported instead of fabricating success.
      debugPrint('LOG: File export requested on Web (unsupported): $fileName');
      return false;
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
