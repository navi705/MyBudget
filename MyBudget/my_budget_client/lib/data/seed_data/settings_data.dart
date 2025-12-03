import 'package:my_budget_client/core/database/app_database.dart';

List<Setting> getDefaultSettings(String deviceName) {
  return [
    Setting(
      key: 'themeMode',
      value: 'system',
      device: deviceName,
    ),
    Setting(
      key: 'conversion_base_currency_id',
      value: '1', // USD
      device: deviceName,
    ),
  ];
}
