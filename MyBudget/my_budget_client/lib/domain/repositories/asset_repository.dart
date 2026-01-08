import 'package:my_budget_client/domain/entities/asset_data.dart';

abstract class AssetRepository {
  Future<List<AssetDataDomain>> getAssetData({
    int limit = 50,
    int offset = 0,
    String? assetId,
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
    bool sortAscending = false,
  });
  Future<void> addAssetData(AssetDataDomain data);
  Future<void> updateAssetData(AssetDataDomain data);
  Future<void> deleteAssetData(String id);
}
