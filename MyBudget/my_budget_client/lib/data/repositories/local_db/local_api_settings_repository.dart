import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/domain/entities/api_setting.dart';
import 'package:my_budget_client/domain/repositories/api_settings_repository.dart';

class LocalApiSettingsRepository implements ApiSettingsRepository {
  final ApiSettingsDao _apiSettingsDao;

  LocalApiSettingsRepository(this._apiSettingsDao);

  @override
  Future<List<ApiSettingDomain>> getAllSettings() async {
    final settings = await _apiSettingsDao.getAllSettings();
    return settings.map((s) => _mapToDomain(s)).toList();
  }

  @override
  Future<ApiSettingDomain?> getSettingById(String id) async {
    final setting = await _apiSettingsDao.getSettingById(id);
    if (setting == null) return null;
    return _mapToDomain(setting);
  }

  @override
  Future<void> saveSetting(ApiSettingDomain setting) async {
    await _apiSettingsDao.upsertSetting(
      ApiSettingsTableCompanion(
        id: Value(setting.id),
        enabled: Value(setting.enabled),
        autoFetch: Value(setting.autoFetch),
        lastFetchAt: Value(setting.lastFetchAt?.millisecondsSinceEpoch),
      ),
    );
  }

  ApiSettingDomain _mapToDomain(ApiSettingsTableData data) {
    return ApiSettingDomain(
      id: data.id,
      enabled: data.enabled,
      autoFetch: data.autoFetch,
      lastFetchAt: data.lastFetchAt != null
          ? DateTime.fromMillisecondsSinceEpoch(data.lastFetchAt!)
          : null,
    );
  }
}
