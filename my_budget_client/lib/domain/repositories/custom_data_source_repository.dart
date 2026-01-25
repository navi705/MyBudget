import 'package:my_budget_client/domain/entities/custom_data_source.dart';

abstract class CustomDataSourceRepository {
  Future<List<CustomDataSourceDomain>> getAllDataSources();
  Future<CustomDataSourceDomain?> getDataSourceById(String id);
  Future<void> saveDataSource(CustomDataSourceDomain dataSource);
  Future<void> deleteDataSource(String id);
}
