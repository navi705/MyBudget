import 'dart:convert';
import 'dart:typed_data';
import 'package:my_budget_client/core/utils/platform/platform_utils.dart';
import 'package:my_budget_client/core/utils/platform/io_helper.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb, debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:my_budget_client/core/utils/currency_history_binary_io.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/data/api/external_data.dart';
import 'package:drift/drift.dart';

class ExchangeRateApiService {
  final ExchangeRatesDao _exchangeRatesDao;
  final ApiFetchStatusesDao _apiFetchStatusesDao;
  final CurrenciesDao _currenciesDao;

  ExchangeRateApiService(
    this._exchangeRatesDao,
    this._apiFetchStatusesDao,
    this._currenciesDao,
  );

  static const String _jsonPath = 'lib/data/currency_history.json';
  static const String _prodBinAssetPath = 'lib/data/currency_history.bin';
  static const String _metadataJsonPath =
      'lib/data/currency_history_metadata.json';
  static const String _metadataKey = '_metadata';
  static const String _attemptsKey = 'attempts';

  Future<void> fetchRatesForDate(DateTime date) async {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);

    final ratesInDb = await (_exchangeRatesDao.select(
      _exchangeRatesDao.exchangeRates,
    )..where((tbl) => tbl.date.equals(date))).get();

    if (ratesInDb.isNotEmpty) {
      return;
    }

    if (kDebugMode && !kIsWeb) {
      await _handleDebugFetch(date, dateKey);
    } else {
      await _handleProdFetch(date, dateKey);
    }
  }

  Future<void> _handleDebugFetch(DateTime date, String dateKey) async {
    if (!await IoHelper.exists(_jsonPath)) return;
    final content = await IoHelper.readAsString(_jsonPath);
    final Map<String, dynamic> fullJson = jsonDecode(content);

    // 1. Read Metadata
    Map<String, dynamic> metadataJson = {};
    if (await IoHelper.exists(_metadataJsonPath)) {
      try {
        metadataJson = jsonDecode(
          await IoHelper.readAsString(_metadataJsonPath),
        );
      } catch (e) {
        debugPrint('Error reading metadata file: $e');
      }
    }

    final attemptsMap =
        (metadataJson[_attemptsKey] as Map<String, dynamic>?) ?? {};
    final int attemptCount = attemptsMap[dateKey] ?? 0;

    if (attemptCount >= 5) {
      return;
    }

    // 2. Read Currency Data (Already read above)

    // Clean up old metadata from main file if present (migration step)
    if (fullJson.containsKey(_metadataKey)) {
      fullJson.remove(_metadataKey);
      await IoHelper.writeAsString(
        _jsonPath,
        const JsonEncoder.withIndent('  ').convert(fullJson),
      );
    }

    if (fullJson.containsKey(dateKey)) {
      final rawRates = fullJson[dateKey] as Map<String, dynamic>;
      final rates = rawRates.map((k, v) => MapEntry(k, (v as num).toDouble()));
      if (rates.isNotEmpty) {
        await _saveRatesToDb(date, rates);
        return;
      }
    }

    // 3. Fetch from API if needed
    try {
      final apiRates = await ExternalData.getCurrencyRatesFromFreeExchangeRates(
        date,
      );
      if (apiRates.isNotEmpty) {
        await _saveRatesToDb(date, apiRates);
        fullJson[dateKey] = apiRates;
        await IoHelper.writeAsString(
          _jsonPath,
          const JsonEncoder.withIndent('  ').convert(fullJson),
        );
      }
    } catch (e) {
      // 4. Update Metadata on Failure
      attemptsMap[dateKey] = attemptCount + 1;
      metadataJson[_attemptsKey] = attemptsMap;
      await IoHelper.writeAsString(
        _metadataJsonPath,
        const JsonEncoder.withIndent('  ').convert(metadataJson),
      );
    }
  }

  Future<void> _handleProdFetch(DateTime date, String dateKey) async {
    final status = await _apiFetchStatusesDao.getStatus(dateKey);
    if (status != null &&
        (status.status == 'success' ||
            status.status == 'permanent_fail' ||
            status.attempts >= 5)) {
      return;
    }

    Map<String, double> rates = {};
    try {
      // Try Binary Asset
      try {
        final ByteData blob = await rootBundle.load(_prodBinAssetPath);
        final Uint8List bytes = blob.buffer.asUint8List(
          blob.offsetInBytes,
          blob.lengthInBytes,
        );
        final historyMap = CurrencyHistoryBinaryIO.readFromBytes(bytes);
        if (historyMap.containsKey(dateKey)) {
          rates = historyMap[dateKey]!;
        }
      } catch (e) {
        debugPrint('Fetch: Binary asset error or missing: $e');
      }

      if (rates.isEmpty) {
        try {
          rates = await ExternalData.getCurrencyRatesFromFreeExchangeRates(
            date,
          );
        } catch (e) {
          debugPrint('Fetch: Specific date failed, trying latest: $e');
          // Fallback to latest if specific date (e.g. today) is not yet available
          rates = await ExternalData.getCurrencyRatesFromLatest();
        }
      }

      if (rates.isNotEmpty) {
        await _saveRatesToDb(date, rates);
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

  Future<void> _saveRatesToDb(DateTime date, Map<String, double> rates) async {
    final existingCodes = (await _currenciesDao.getAllCurrencies())
        .map((c) => c.code)
        .toSet();

    final companions = rates.entries
        .where((e) => existingCodes.contains(e.key.toUpperCase()))
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

    if (companions.isEmpty) {
      return;
    }

    await _exchangeRatesDao.insertAllExchangeRates(companions);
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
