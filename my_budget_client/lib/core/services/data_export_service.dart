import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart'; // Optional for mobile, but file_picker is good for desktop

class DataExportService {
  final AppDatabase _db;

  DataExportService(this._db);

  Future<void> exportData(bool isCsv) async {
    if (isCsv) {
      await _exportCsv();
    } else {
      await _exportJson();
    }
  }

  Future<void> _exportJson() async {
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
    await _saveFile(jsonString, 'my_budget_backup.json');
  }

  Future<void> _exportCsv() async {
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
    await _saveFile(csvString, 'my_budget_transactions.csv');
  }

  Future<void> _saveFile(String content, String fileName) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Please select an output file:',
        fileName: fileName,
      );

      if (outputFile == null) {
        // User canceled the picker
        return;
      }

      final File file = File(outputFile);
      await file.writeAsString(content);
    } else {
      // Mobile Support
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(content);

      // Using XFile from share_plus (cross_file)
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'MyBudget Export',
        text: 'Here is your exported data.',
      );
    }
  }
}
