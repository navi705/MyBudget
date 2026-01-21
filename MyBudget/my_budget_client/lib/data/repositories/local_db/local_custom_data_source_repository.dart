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
    await _customDataSourcesDao.insertDataSource(
      CustomDataSourcesCompanion(
        id: Value(dataSource.id),
        name: Value(dataSource.name),
        url: Value(dataSource.url),
        dataType: Value(dataSource.dataType.index),
        enabled: Value(dataSource.enabled),
        autoFetch: Value(dataSource.autoFetch),
        lastFetchAt: Value(dataSource.lastFetchAt?.millisecondsSinceEpoch),
      ),
    );
  }

  @override
  Future<void> deleteDataSource(String id) async {
    final source = await _customDataSourcesDao.getDataSourceById(id);
    if (source != null) {
      await _customDataSourcesDao.deleteDataSource(
        CustomDataSourcesCompanion(id: Value(id)),
      );
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
