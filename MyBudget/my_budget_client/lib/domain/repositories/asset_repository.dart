import 'package:my_budget_client/domain/entities/asset_data.dart';

abstract class AssetRepository {
  Future<List<AssetDataDomain>> getAssetData({
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
  });
  Future<void> addAssetData(AssetDataDomain data);
  Future<void> updateAssetData(AssetDataDomain data);
  Future<void> deleteAssetData(String id);
  Future<void> deleteAssets(List<String> ids);
  Future<List<String>> getAvailableAssetIds();
  Future<List<String>> getAvailableAssetTypes();
  Future<List<String>> getAvailableSources();
  Future<List<int>> getAvailablePresets();
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
  });
}
