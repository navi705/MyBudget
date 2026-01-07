import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/data/api/external_data.dart';
import 'package:drift/drift.dart';

class SteamInventoryApiService {
  final AssetEntriesDao _assetEntriesDao;
  final ApiFetchStatusesDao _apiFetchStatusesDao;

  SteamInventoryApiService(
    this._assetEntriesDao,
    this._apiFetchStatusesDao,
  );

  static const String _jsonPath = 'lib/data/steam_inventory_history.json';
  static const String _metadataKey = '_metadata';
  static const String _attemptsKey = 'attempts';

  Future<void> fetchSteamInventoryValue(int accountId, GameApiSteam game) async {
    final date = DateTime.now();
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final assetId = 'steam_${accountId}_${game.name}';

    final entriesInDb = await (_assetEntriesDao.select(_assetEntriesDao.assetEntries)
          ..where((tbl) => tbl.assetId.equals(assetId))
          ..where((tbl) => tbl.date.equals(date)))
        .get();

    if (entriesInDb.isNotEmpty) {
      return;
    }

    if (kDebugMode) {
      await _handleDebugFetch(date, dateKey, accountId, game, assetId);
    } else {
      await _handleProdFetch(date, dateKey, accountId, game, assetId);
    }
  }

  Future<void> _handleDebugFetch(DateTime date, String dateKey, int accountId, GameApiSteam game, String assetId) async {
    final file = File(_jsonPath);
    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsString(jsonEncode({_metadataKey: {_attemptsKey: {}}}));
    }

    final content = await file.readAsString();
    final Map<String, dynamic> fullJson = jsonDecode(content);

    final metadata = (fullJson[_metadataKey] as Map<String, dynamic>?) ?? {};
    final attempts = (metadata[_attemptsKey] as Map<String, dynamic>?) ?? {};
    final String attemptKey = '${dateKey}_${game.name}';
    final int attemptCount = attempts[attemptKey] ?? 0;

    if (attemptCount >= 5) {
      return;
    }

    if (fullJson.containsKey(dateKey) && fullJson[dateKey].containsKey(game.name)) {
      final value = (fullJson[dateKey][game.name] as num).toDouble();
      if (value > 0) {
        await _saveInventoryValueToDb(date, value, assetId, game);
        return;
      }
    }

    try {
      final inventory = await ExternalData.getSteamInvetoryCost(accountId, game);
      if (inventory.isNotEmpty) {
        final totalValue = inventory.values.reduce((a, b) => a + b);
        await _saveInventoryValueToDb(date, totalValue, assetId, game);

        if (!fullJson.containsKey(dateKey)) {
          fullJson[dateKey] = {};
        }
        fullJson[dateKey][game.name] = totalValue;
        
        await file.writeAsString(const JsonEncoder.withIndent('  ').convert(fullJson));
      }
    } catch (e) {
      attempts[attemptKey] = attemptCount + 1;
      metadata[_attemptsKey] = attempts;
      fullJson[_metadataKey] = metadata;
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(fullJson));
    }
  }

  Future<void> _handleProdFetch(DateTime date, String dateKey, int accountId, GameApiSteam game, String assetId) async {
    final statusKey = '${dateKey}_steam_${game.name}';
    final status = await _apiFetchStatusesDao.getStatus(statusKey);
    if (status != null &&
        (status.status == 'success' ||
            status.status == 'permanent_fail' ||
            status.attempts >= 5)) {
      return;
    }

    try {
      final inventory = await ExternalData.getSteamInvetoryCost(accountId, game);
      if (inventory.isNotEmpty) {
        final totalValue = inventory.values.reduce((a, b) => a + b);
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

  Future<void> _saveInventoryValueToDb(DateTime date, double totalValue, String assetId, GameApiSteam game) async {
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
