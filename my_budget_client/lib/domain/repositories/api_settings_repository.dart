import 'package:my_budget_client/domain/entities/api_setting.dart';

abstract class ApiSettingsRepository {
  Future<List<ApiSettingDomain>> getAllSettings();
  Future<ApiSettingDomain?> getSettingById(String id);
  Future<void> saveSetting(ApiSettingDomain setting);
}
