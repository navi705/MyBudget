import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/domain/entities/custom_data_source.dart';
import 'package:my_budget_client/domain/repositories/custom_data_source_repository.dart';

class LocalCustomDataSourceRepository implements CustomDataSourceRepository {
  final CustomDataSourcesDao _customDataSourcesDao;

  LocalCustomDataSourceRepository(this._customDataSourcesDao);

  @override
  Future<List<CustomDataSourceDomain>> getAllDataSources() async {
    final sources = await _customDataSourcesDao.getAllDataSources();
    return sources.map((s) => _mapToDomain(s)).toList();
  }

  @override
  Future<CustomDataSourceDomain?> getDataSourceById(String id) async {
    final source = await _customDataSourcesDao.getDataSourceById(id);
    if (source == null) return null;
    return _mapToDomain(source);
  }

  @override
  Future<void> saveDataSource(CustomDataSourceDomain dataSource) async {
    final companion = CustomDataSourcesCompanion(
      id: Value(dataSource.id),
      name: Value(dataSource.name),
      url: Value(dataSource.url),
      dataType: Value(dataSource.dataType.index),
      enabled: Value(dataSource.enabled),
      autoFetch: Value(dataSource.autoFetch),
      lastFetchAt: Value(dataSource.lastFetchAt?.millisecondsSinceEpoch),
    );

    // Tombstones count as existing. `getDataSourceById` hides soft-deleted
    // rows, so saving a deleted id looked like a brand new record and took the
    // insertOrReplace path, which wiped the delete flag: an endpoint the user
    // removed silently started being fetched again, and the resurrection was
    // pushed to every paired device.
    final existing = await _customDataSourcesDao
        .getDataSourceByIdIncludingDeleted(dataSource.id);
    if (existing != null) {
      // Record exists — update (preserves modifiedAt bump + sync log). The DAO
      // only writes live rows, so a deleted id stays deleted.
      await _customDataSourcesDao.updateCustomDataSource(companion);
    } else {
      // New record — insert
      await _customDataSourcesDao.insertDataSource(companion);
    }
  }

  @override
  Future<void> deleteDataSource(String id) async {
    final source = await _customDataSourcesDao.getDataSourceById(id);
    if (source != null) {
      await _customDataSourcesDao.deleteDataSource(id);
    }
  }

  CustomDataSourceDomain _mapToDomain(CustomDataSource data) {
    return CustomDataSourceDomain(
      id: data.id,
      name: data.name,
      url: data.url,
      dataType: ApiDataType.values[data.dataType],
      enabled: data.enabled,
      autoFetch: data.autoFetch,
      lastFetchAt: data.lastFetchAt != null
          ? DateTime.fromMillisecondsSinceEpoch(data.lastFetchAt!)
          : null,
    );
  }
}
