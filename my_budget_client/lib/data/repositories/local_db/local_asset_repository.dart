import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/mappers/asset_data_mapper.dart';
import 'package:my_budget_client/domain/entities/asset_data.dart';
import 'package:my_budget_client/domain/repositories/asset_repository.dart';

class LocalAssetRepository implements AssetRepository {
  final AssetEntriesDao _dao;

  LocalAssetRepository(this._dao);

  @override
  Future<List<AssetDataDomain>> getAssetData({
    int limit = 50,
    int offset = 0,
    String? assetId,
    String? accountId, // Added
    DateTime? startDate,
    DateTime? endDate,
    String? name,
    List<String>? assetTypes,
    String? description,
    List<String>? currencyCodes,
    List<String>? sources,
    List<int>? presets,
    double? minValue,
    double? maxValue,
    bool sortAscending = false,
  }) async {
    final entries = await _dao.getAssetData(
      limit: limit,
      offset: offset,
      assetId: assetId,
      accountId: accountId, // Added
      startDate: startDate,
      endDate: endDate,
      name: name,
      assetTypes: assetTypes,
      description: description,
      currencyCodes: currencyCodes,
      sources: sources,
      presets: presets,
      minValue: minValue,
      maxValue: maxValue,
      sort: sortAscending ? OrderingMode.asc : OrderingMode.desc,
    );
    return entries.map((e) => e.toDomain()).toList();
  }

  @override
  Stream<List<AssetDataDomain>> watchAssetData({
    int limit = 50,
    int offset = 0,
    String? assetId,
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
    String? name,
    List<String>? assetTypes,
    String? description,
    List<String>? currencyCodes,
    List<String>? sources,
    List<int>? presets,
    double? minValue,
    double? maxValue,
    bool sortAscending = false,
  }) {
    return _dao
        .watchAssetData(
          limit: limit,
          offset: offset,
          assetId: assetId,
          accountId: accountId,
          startDate: startDate,
          endDate: endDate,
          name: name,
          assetTypes: assetTypes,
          description: description,
          currencyCodes: currencyCodes,
          sources: sources,
          presets: presets,
          minValue: minValue,
          maxValue: maxValue,
          sort: sortAscending ? OrderingMode.asc : OrderingMode.desc,
        )
        .map((entries) => entries.map((e) => e.toDomain()).toList());
  }

  @override
  Future<void> addAssetData(AssetDataDomain data) async {
    await _dao.addAssetData(data.toCompanion());
  }

  @override
  Future<void> updateAssetData(AssetDataDomain data) async {
    await _dao.updateAssetData(data.toCompanion());
  }

  @override
  Future<void> deleteAssetData(String id) async {
    await _dao.deleteAssetEntry(id);
  }

  @override
  Future<void> deleteAssets(List<String> ids) async {
    await _dao.deleteAssets(ids);
  }

  @override
  Future<List<String>> getAvailableAssetIds() async {
    return _dao.getAvailableAssetIds();
  }

  @override
  Future<List<String>> getAvailableAssetTypes() async {
    return _dao.getAvailableAssetTypes();
  }

  @override
  Future<List<String>> getAvailableSources() async {
    return _dao.getAvailableSources();
  }

  @override
  Future<List<int>> getAvailablePresets() async {
    return _dao.getAvailablePresets();
  }

  @override
  Future<int> getAssetDataCount({
    String? assetId,
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
    String? name,
    List<String>? assetTypes,
    String? description,
    List<String>? currencyCodes,
    List<String>? sources,
    List<int>? presets,
    double? minValue,
    double? maxValue,
  }) {
    return _dao.getAssetDataCount(
      assetId: assetId,
      accountId: accountId,
      startDate: startDate,
      endDate: endDate,
      name: name,
      assetTypes: assetTypes,
      description: description,
      currencyCodes: currencyCodes,
      sources: sources,
      presets: presets,
      minValue: minValue,
      maxValue: maxValue,
    );
  }
}
