import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/mappers/asset_data_mapper.dart';
import 'package:my_budget_client/domain/entities/asset_data.dart';
import 'package:my_budget_client/domain/repositories/asset_repository.dart';

class LocalAssetRepository implements AssetRepository {
  final AssetEntriesDao _dao;

  LocalAssetRepository(this._dao);

  @override
  Future<List<AssetDataDomain>> getAssetData({
    String? assetId,
    String? accountId, // Added
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final entries = await _dao.getAssetData(
      assetId: assetId,
      accountId: accountId, // Added
      startDate: startDate,
      endDate: endDate,
    );
    return entries.map((e) => e.toDomain()).toList();
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
    await _dao.deleteAssetData(id);
  }
}
