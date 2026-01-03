import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/data/api/external_data.dart';
import 'package:drift/drift.dart';

class ExchangeRateApiService {
  final ExchangeRatesDao _exchangeRatesDao;
  final ApiFetchStatusesDao _apiFetchStatusesDao;
  final SettingsDao _settingsDao;

  ExchangeRateApiService(
    this._exchangeRatesDao,
    this._apiFetchStatusesDao,
    this._settingsDao,
  );

  static const String _debugJsonPath =
      r'C:\Users\vrclu\Documents\NewFilePC\Programing\Projects\MyBudget\MyBudget\my_budget_client\lib\data\currency_history.json';
  static const String _prodJsonPath = r'assets/currency_history.json';

  Future<void> fetchRatesForDate(DateTime date) async {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);

    // 1. Check if fetching is enabled
    final enabledSetting = await (_settingsDao.select(
      _settingsDao.settings,
    )..where((t) => t.key.equals('api_fetching_enabled'))).getSingleOrNull();
    if (enabledSetting?.value != 'true') return;

    // 2. Check if we already have a status that prevents fetching
    final status = await _apiFetchStatusesDao.getStatus(dateKey);
    if (status != null &&
        (status.status == 'success' ||
            status.status == 'permanent_fail' ||
            status.attempts >= 5)) {
      return;
    }

    // 3. Determine Mode
    final modeSetting = await (_settingsDao.select(
      _settingsDao.settings,
    )..where((t) => t.key.equals('api_fetch_mode'))).getSingleOrNull();
    final isDebugMode = modeSetting?.value == 'debug';

    try {
      Map<String, double> rates = {};

      // Strategy: JSON (if exists) -> API
      final jsonFile = File(isDebugMode ? _debugJsonPath : _prodJsonPath);
      if (await jsonFile.exists()) {
        final content = await jsonFile.readAsString();
        final Map<String, dynamic> fullJson = jsonDecode(content);
        if (fullJson.containsKey(dateKey)) {
          final rawRates = fullJson[dateKey] as Map<String, dynamic>;
          rates = rawRates.map((k, v) => MapEntry(k, (v as num).toDouble()));
        }
      }

      if (rates.isEmpty) {
        // Call External API
        rates = await ExternalData.getCurrencyRatesFromFreeExchangeRates(date);

        if (rates.isNotEmpty && isDebugMode) {
          // Write back to JSON in debug mode
          await _updateDebugJson(dateKey, rates);
        }
      }

      if (rates.isNotEmpty) {
        // Save to DB
        final companions = rates.entries
            .map(
              (e) => ExchangeRatesCompanion(
                fromCurrencyCode: const Value('EUR'),
                toCurrencyCode: Value(e.key.toUpperCase()),
                rate: Value(e.value),
                date: Value(date),
                preset: const Value(1),
              ),
            )
            .toList();

        await _exchangeRatesDao.batch((batch) {
          batch.insertAllOnConflictUpdate(
            _exchangeRatesDao.exchangeRates,
            companions,
          );
        });

        await _apiFetchStatusesDao.upsertStatus(
          ApiFetchStatusesCompanion(
            id: Value(dateKey),
            status: const Value('success'),
            attempts: Value((status?.attempts ?? 0) + 1),
            lastAttempt: Value(DateTime.now()),
          ),
        );
      } else {
        throw Exception('No data returned from API/JSON');
      }
    } catch (e) {
      final attempts = (status?.attempts ?? 0) + 1;
      await _apiFetchStatusesDao.upsertStatus(
        ApiFetchStatusesCompanion(
          id: Value(dateKey),
          status: Value(attempts >= 5 ? 'permanent_fail' : 'failed'),
          attempts: Value(attempts),
          lastAttempt: Value(DateTime.now()),
        ),
      );
    }
  }

  Future<void> _updateDebugJson(
    String dateKey,
    Map<String, double> rates,
  ) async {
    final file = File(_debugJsonPath);
    Map<String, dynamic> fullJson = {};
    if (await file.exists()) {
      fullJson = jsonDecode(await file.readAsString());
    }
    fullJson[dateKey] = rates;
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(fullJson),
    );
  }

  Future<void> fetchRatesForRange(DateTime start, DateTime end) async {
    DateTime current = start;
    while (!current.isAfter(end)) {
      await fetchRatesForDate(current);
      current = current.add(const Duration(days: 1));
      await Future.delayed(const Duration(milliseconds: 200)); // Throttling
    }
  }
}
