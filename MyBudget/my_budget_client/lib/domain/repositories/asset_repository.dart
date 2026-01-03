import 'package:my_budget_client/domain/entities/asset_data.dart';

abstract class AssetRepository {
  Future<List<AssetDataDomain>> getAssetData({
    String? assetId,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<void> addAssetData(AssetDataDomain data);
  Future<void> updateAssetData(AssetDataDomain data);
  Future<void> deleteAssetData(String id);
}
