import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/utils/exchange_rate_validation.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

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
  /// Returns the number of items imported, or throws exception on failure.
  Future<int> fetchCustomData(String url) async {
    try {
      final uri = _getUri(url);
      debugPrint('[CustomApiService] Fetching from $uri...');
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Failed with status: ${response.statusCode}');
      }

      final body = response.body.trim();
      if (body.isEmpty) {
        throw Exception('Empty response from server');
      }

      // Simple check to ensure response looks like JSON
      if (!body.startsWith('{') && !body.startsWith('[')) {
        // If it sends back plain text (like "MyBudget Custom API is running"), show that.
        final preview = body.length > 50 ? '${body.substring(0, 50)}...' : body;
        throw Exception('Invalid JSON response: "$preview"');
      }

      final json = jsonDecode(body);
      // Read rather than cast. A cast on an answer the user's own server wrote
      // reaches the UI as "type 'Null' is not a subtype of type 'String'",
      // which says nothing about what to change; the shape of the answer is
      // the one thing the user is in a position to fix.
      if (json is! Map<String, dynamic>) {
        throw Exception('Expected a JSON object at the top level');
      }
      final type = json['type'];
      if (type is! String || type.trim().isEmpty) {
        throw Exception('Missing "type" field');
      }
      final data = json['data'];
      if (data is! List) {
        throw Exception('Missing "data" list');
      }

      int count = 0;
      switch (type.trim()) {
        case 'exchange_rates':
          count = await _parseExchangeRates(data);
          break;
        case 'inflation':
          count = await _parseInflation(data);
          break;
        case 'assets':
          count = await _parseAssets(data);
          break;
        default:
          throw Exception('Unknown data type: $type');
      }
      return count;
    } catch (e) {
      debugPrint('[CustomApiService] Error fetching/parsing $url: $e');
      rethrow; // Re-throw so the UI knows it failed
    }
  }

  /// The text [key] holds on [row], trimmed, or null when it holds anything
  /// else - including a blank string, which names no currency and no country.
  static String? _text(dynamic row, String key) {
    if (row is! Map) return null;
    final value = row[key];
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// The number [key] holds on [row], or null.
  ///
  /// A number quoted as a string is read too: the server behind a custom
  /// source is whatever the user pointed at, and a rate rendered as "1.05" is
  /// a rate, not a reason to drop the row.
  static double? _number(dynamic row, String key) {
    if (row is! Map) return null;
    final value = row[key];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  /// The date [key] holds on [row], or null when it is missing or unreadable.
  static DateTime? _date(dynamic row, String key) {
    final text = _text(row, key);
    if (text == null) return null;
    return DateTime.tryParse(text);
  }

  /// The exchange rates worth storing out of what a custom source answered
  /// with.
  ///
  /// Every row is read on its own and a row that cannot be read is skipped.
  /// The reads used to be bare casts - `item['rate'] as num`,
  /// `DateTime.parse(item['date'])` - so one row the user's own server wrote
  /// in the wrong shape threw out of the middle of the loop and took the
  /// entire answer with it: five hundred good rates dropped over one bad one,
  /// reported to the user as a failed fetch with nothing to say which row did
  /// it.
  ///
  /// Codes are upper-cased because that is how every other writer of this
  /// table stores them, and a code stored in another case is a code no lookup
  /// in the app will ever find.
  @visibleForTesting
  static List<ExchangeRatesCompanion> rateCompanionsFor(List data) {
    final List<ExchangeRatesCompanion> companions = [];
    for (final item in data) {
      final rate = _number(item, 'rate');
      // A rate is a multiplier: zero converts every amount to nothing, a
      // negative one flips its sign, and a non-finite one poisons every
      // balance it reaches. The file import path has always refused these; a
      // custom source is not a reason to stop.
      if (rate == null || !isUsableExchangeRate(rate)) {
        debugPrint('[CustomApiService] Skipping unusable rate: $rate');
        continue;
      }
      final date = _date(item, 'date');
      final from = _text(item, 'from');
      final to = _text(item, 'to');
      if (date == null || from == null || to == null) {
        debugPrint('[CustomApiService] Skipping rate row: $item');
        continue;
      }
      companions.add(
        ExchangeRatesCompanion(
          date: Value(date),
          fromCurrencyCode: Value(from.toUpperCase()),
          toCurrencyCode: Value(to.toUpperCase()),
          rate: Value(rate),
          preset: const Value(2), // Preset 2 for Custom API data
        ),
      );
    }
    return companions;
  }

  /// The inflation rows worth storing, under the same rule as
  /// [rateCompanionsFor].
  ///
  /// A percent is stored as a real and read straight into arithmetic, so a
  /// non-finite one is not a slightly wrong figure but one that turns every
  /// total it reaches into NaN.
  @visibleForTesting
  static List<InflationRatesCompanion> inflationCompanionsFor(List data) {
    final List<InflationRatesCompanion> companions = [];
    for (final item in data) {
      final percent = _number(item, 'rate');
      final date = _date(item, 'date');
      final country = _text(item, 'country');
      if (percent == null || !percent.isFinite || date == null ||
          country == null) {
        debugPrint('[CustomApiService] Skipping inflation row: $item');
        continue;
      }
      companions.add(
        InflationRatesCompanion(
          date: Value(date),
          country: Value(country.toUpperCase()),
          percent: Value(percent),
          preset: const Value(2),
        ),
      );
    }
    return companions;
  }

  /// The asset entries worth storing, under the same rule as
  /// [rateCompanionsFor].
  ///
  /// The id is derived from `(code, day, source)` so that fetching the same
  /// day twice updates one row instead of adding a second.
  ///
  /// A value of zero or below is kept: an asset can be worth nothing, and a
  /// holding can be a debt. Only a value that is not a number at all, or one
  /// arithmetic cannot use, is refused.
  @visibleForTesting
  static List<AssetEntriesCompanion> assetCompanionsFor(List data) {
    final List<AssetEntriesCompanion> companions = [];
    for (final item in data) {
      final value = _number(item, 'value');
      final date = _date(item, 'date');
      final code = _text(item, 'code');
      if (value == null || !value.isFinite || date == null || code == null) {
        debugPrint('[CustomApiService] Skipping asset row: $item');
        continue;
      }
      final dateStr = DateFormat('yyyy-MM-dd', 'en').format(date);
      final deterministicId = _uuid.v5(
        Uuid.NAMESPACE_URL,
        '$code|$dateStr|custom_api',
      );
      companions.add(
        AssetEntriesCompanion(
          id: Value(deterministicId),
          assetId: Value(code),
          name: Value(_text(item, 'name') ?? code),
          date: Value(date),
          value: Value(value),
          currencyCode: Value(
            (_text(item, 'currency') ?? 'EUR').toUpperCase(),
          ),
          source: const Value('custom_api'),
          preset: const Value(2),
        ),
      );
    }
    return companions;
  }

  Future<int> _parseExchangeRates(List data) async {
    final companions = rateCompanionsFor(data);
    if (companions.isNotEmpty) {
      await _exchangeRatesDao.insertAllExchangeRates(companions);
      debugPrint(
        '[CustomApiService] Imported ${companions.length} exchange rates',
      );
    }
    return companions.length;
  }

  Future<int> _parseInflation(List data) async {
    final companions = inflationCompanionsFor(data);
    if (companions.isNotEmpty) {
      await _inflationRatesDao.insertAllInflationRates(companions);
      debugPrint(
        '[CustomApiService] Imported ${companions.length} inflation records',
      );
    }
    return companions.length;
  }

  Future<int> _parseAssets(List data) async {
    debugPrint(
      '[CustomApiService] _parseAssets called with ${data.length} items',
    );
    final companions = assetCompanionsFor(data);
    for (final companion in companions) {
      await _assetEntriesDao.upsertAssetData(companion);
    }
    debugPrint(
      '[CustomApiService] Upserted ${companions.length} asset records '
      '(dedup via deterministic ID)',
    );
    return companions.length;
  }
}
