import 'dart:convert';
import 'package:my_budget_client/core/utils/platform/platform_utils.dart';
import 'package:my_budget_client/core/utils/platform/io_helper.dart';
import 'package:flutter/foundation.dart'
    show kDebugMode, kIsWeb, visibleForTesting;
import 'package:intl/intl.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/utils/calendar_day.dart';
import 'package:my_budget_client/data/api/external_data.dart';
import 'package:drift/drift.dart';

class SteamInventoryApiService {
  final AssetEntriesDao _assetEntriesDao;
  final ApiFetchStatusesDao _apiFetchStatusesDao;

  SteamInventoryApiService(this._assetEntriesDao, this._apiFetchStatusesDao);

  static const String _jsonPath = 'lib/data/steam_inventory_history.json';
  static const String _metadataKey = '_metadata';
  static const String _attemptsKey = 'attempts';

  Future<void> fetchSteamInventoryValue(
    int accountId,
    GameApiSteam game,
  ) async {
    final date = DateTime.now();
    final dateKey = DateFormat('yyyy-MM-dd', 'en').format(date);
    final assetId = 'steam_${accountId}_${game.name}';

    // The only "do we already have this?" test is the one below, against the
    // database. There used to be one before it, against the debug JSON cache,
    // which returned the moment that file held today's value - so a device
    // whose database did not have the entry (a fresh install beside an old
    // checkout, a reset, a restore from an export) was told it was up to date
    // and never wrote the row. The cache is a source to read the value FROM,
    // which is what `_handleDebugFetch` does with it; it is not a record of
    // what the database holds.
    final dayStart = startOfDay(date);
    final dayEnd = nextDay(date);

    final entriesInDb =
        await (_assetEntriesDao.select(_assetEntriesDao.assetEntries)
              ..where((tbl) => tbl.assetId.equals(assetId))
              ..where((tbl) => tbl.isDeleted.equals(false))
              ..where(
                (tbl) =>
                    tbl.date.isBiggerOrEqualValue(dayStart) &
                    tbl.date.isSmallerThanValue(dayEnd),
              ))
            .get();

    if (entriesInDb.isNotEmpty) {
      return;
    }

    if (kDebugMode && !kIsWeb) {
      await _handleDebugFetch(date, dateKey, accountId, game, assetId);
    } else {
      await _handleProdFetch(date, dateKey, accountId, game, assetId);
    }
  }

  Future<void> _handleDebugFetch(
    DateTime date,
    String dateKey,
    int accountId,
    GameApiSteam game,
    String assetId,
  ) async {
    if (!await IoHelper.exists(_jsonPath)) {
      await IoHelper.createParent(_jsonPath);
      await IoHelper.writeAsString(
        _jsonPath,
        jsonEncode({
          _metadataKey: {_attemptsKey: {}},
        }),
      );
    }

    final content = await IoHelper.readAsString(_jsonPath);
    final Map<String, dynamic> fullJson = jsonDecode(content);

    final metadata = (fullJson[_metadataKey] as Map<String, dynamic>?) ?? {};
    final attempts = (metadata[_attemptsKey] as Map<String, dynamic>?) ?? {};
    final String attemptKey = '${dateKey}_${game.name}';
    final int attemptCount = attempts[attemptKey] ?? 0;

    if (attemptCount >= 5) {
      return;
    }

    final cached = cachedValue(fullJson, dateKey, game.name);
    if (cached != null) {
      await _saveInventoryValueToDb(date, cached, assetId, game);
      return;
    }

    try {
      final totalValue = await ExternalData.getSteamInventoryValue(
        accountId,
        game,
      );
      if (totalValue > 0) {
        await _saveInventoryValueToDb(date, totalValue, assetId, game);

        if (!fullJson.containsKey(dateKey)) {
          fullJson[dateKey] = {};
        }
        fullJson[dateKey][game.name] = totalValue;

        await IoHelper.writeAsString(
          _jsonPath,
          const JsonEncoder.withIndent('  ').convert(fullJson),
        );
      }
    } catch (e) {
      attempts[attemptKey] = attemptCount + 1;
      metadata[_attemptsKey] = attempts;
      fullJson[_metadataKey] = metadata;
      await IoHelper.writeAsString(
        _jsonPath,
        const JsonEncoder.withIndent('  ').convert(fullJson),
      );
    }
  }

  Future<void> _handleProdFetch(
    DateTime date,
    String dateKey,
    int accountId,
    GameApiSteam game,
    String assetId,
  ) async {
    final statusKey = '${dateKey}_steam_${game.name}';
    final status = await _apiFetchStatusesDao.getStatus(statusKey);
    if (status != null &&
        (status.status == 'success' ||
            status.status == 'permanent_fail' ||
            status.attempts >= 5)) {
      return;
    }

    try {
      final totalValue = await ExternalData.getSteamInventoryValue(
        accountId,
        game,
      );
      if (totalValue > 0) {
        await _saveInventoryValueToDb(date, totalValue, assetId, game);
        await _apiFetchStatusesDao.upsertStatus(
          ApiFetchStatusesCompanion(
            id: Value(statusKey),
            status: const Value('success'),
            attempts: Value((status?.attempts ?? 0) + 1),
            lastAttempt: Value(DateTime.now()),
          ),
        );
      } else {
        throw Exception('No data returned from Steam API');
      }
    } catch (e) {
      final attempts = (status?.attempts ?? 0) + 1;
      await _apiFetchStatusesDao.upsertStatus(
        ApiFetchStatusesCompanion(
          id: Value(statusKey),
          status: Value(attempts >= 5 ? 'permanent_fail' : 'failed'),
          attempts: Value(attempts),
          lastAttempt: Value(DateTime.now()),
        ),
      );
    }
  }

  /// The usable value [fullJson] holds for [gameName] on [dateKey], or null.
  ///
  /// Every step is checked rather than assumed. The day used to be indexed and
  /// then asked for `containsKey` straight off a `dynamic`, so a day written as
  /// anything but a map - which is what an interrupted write or a hand-edit
  /// leaves behind - threw `NoSuchMethodError` out of the middle of the fetch,
  /// and a value written as a string threw on the cast. Neither is a failure
  /// the fetch can do anything about, and both took the whole run down instead
  /// of falling through to the network the file is only a cache for.
  ///
  /// Zero and below are refused for the same reason the network path refuses
  /// them: an inventory worth nothing is what a failed lookup returns, and
  /// storing it as an asset's value writes that failure into net worth.
  @visibleForTesting
  static double? cachedValue(
    Map<String, dynamic> fullJson,
    String dateKey,
    String gameName,
  ) {
    final day = fullJson[dateKey];
    if (day is! Map) return null;
    final value = day[gameName];
    if (value is! num) return null;
    final asDouble = value.toDouble();
    if (!asDouble.isFinite || asDouble <= 0) return null;
    return asDouble;
  }

  Future<void> _saveInventoryValueToDb(
    DateTime date,
    double totalValue,
    String assetId,
    GameApiSteam game,
  ) async {
    final entry = AssetEntriesCompanion(
      assetId: Value(assetId),
      name: Value('Steam Inventory (${game.name})'),
      date: Value(date),
      value: Value(totalValue),
      source: const Value('steam'),
      currencyCode: const Value('EUR'),
    );

    await _assetEntriesDao.addAssetData(entry);
  }
}
