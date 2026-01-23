import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:drift/drift.dart';

class CustomApiService {
  final ExchangeRatesDao _exchangeRatesDao;
  final InflationRatesDao _inflationRatesDao;
  final AssetEntriesDao _assetEntriesDao;

  CustomApiService(
    this._exchangeRatesDao,
    this._inflationRatesDao,
    this._assetEntriesDao,
  );

  /// Helper to convert string to Uri, adding http:// if no scheme is present
  Uri _getUri(String url) {
    String formattedUrl = url.trim();
    if (!formattedUrl.contains('://')) {
      formattedUrl = 'http://$formattedUrl';
    }
    return Uri.parse(formattedUrl);
  }

  /// Tests connection and returns true if status 200
  Future<bool> testConnection(String url) async {
    try {
      final response = await http
          .get(_getUri(url))
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[CustomApiService] Test connection failed for $url: $e');
      return false;
    }
  }

  /// Fetches data and parses it based on 'type' field in JSON
  Future<void> fetchCustomData(String url) async {
    try {
      final uri = _getUri(url);
      debugPrint('[CustomApiService] Fetching from $uri...');
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        debugPrint(
          '[CustomApiService] Failed with status: ${response.statusCode}',
        );
        return;
      }

      final json = jsonDecode(response.body);
      final String type = json['type'] as String;
      final List data = json['data'] as List;

      switch (type) {
        case 'exchange_rates':
          await _parseExchangeRates(data);
          break;
        case 'inflation':
          await _parseInflation(data);
          break;
        case 'assets':
          await _parseAssets(data);
          break;
        default:
          debugPrint('[CustomApiService] Unknown data type: $type');
      }
    } catch (e) {
      debugPrint('[CustomApiService] Error fetching/parsing $url: $e');
    }
  }

  Future<void> _parseExchangeRates(List data) async {
    final List<ExchangeRatesCompanion> companions = [];
    for (final item in data) {
      companions.add(
        ExchangeRatesCompanion(
          date: Value(DateTime.parse(item['date'])),
          fromCurrencyCode: Value(item['from'] as String),
          toCurrencyCode: Value(item['to'] as String),
          rate: Value((item['rate'] as num).toDouble()),
          preset: const Value(2), // Preset 2 for Custom API data
        ),
      );
    }
    if (companions.isNotEmpty) {
      await _exchangeRatesDao.insertAllExchangeRates(companions);
      debugPrint(
        '[CustomApiService] Imported ${companions.length} exchange rates',
      );
    }
  }

  Future<void> _parseInflation(List data) async {
    for (final item in data) {
      await _inflationRatesDao.insertInflationRate(
        InflationRatesCompanion(
          date: Value(DateTime.parse(item['date'])),
          country: Value(item['country'] as String),
          percent: Value((item['rate'] as num).toDouble()),
          preset: const Value(2),
        ),
      );
    }
    debugPrint('[CustomApiService] Imported ${data.length} inflation records');
  }

  Future<void> _parseAssets(List data) async {
    for (final item in data) {
      final date = DateTime.parse(item['date']);
      final code = item['code'] as String;
      final value = (item['value'] as num).toDouble();

      final currency = item['currency'] as String? ?? 'EUR';
      final name = item['name'] as String? ?? code;

      await _assetEntriesDao.addAssetData(
        AssetEntriesCompanion(
          assetId: Value(code),
          name: Value(name),
          date: Value(date),
          value: Value(value),
          currencyCode: Value(currency),
          source: const Value('custom_api'),
          preset: const Value(2),
        ),
      );
    }
    debugPrint('[CustomApiService] Imported ${data.length} asset records');
  }
}
