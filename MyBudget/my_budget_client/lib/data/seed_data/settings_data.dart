import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';

List<SettingsCompanion> getDefaultSettings(String deviceName) {
  return [
    SettingsCompanion.insert(
      key: 'themeMode',
      value: 'system',
      device: deviceName,
    ),
    SettingsCompanion.insert(
      key: 'conversion_base_currency_id',
      value: '1', // USD
      device: deviceName,
    ),
    SettingsCompanion.insert(
      key: 'main_currency_code',
      value: 'EUR',
      device: deviceName,
    ),
    SettingsCompanion.insert(
      key: 'default_inflation_country',
      value: 'SRB',
      device: deviceName,
    ),

    // transction list screen
    SettingsCompanion.insert(
      key: 'date_step_transaction',
      value: DateStep.month.toString(),
      device: deviceName,
    ),

    SettingsCompanion.insert(
      key: 'date_sort_transaction',
      value: Sort.descending.toString(),
      device: deviceName,
    ),
    SettingsCompanion.insert(
      key: 'persist_transaction_list_settings',
      value: 'true',
      device: deviceName,
    ),

    // advanced filters
    SettingsCompanion.insert(
      key: 'persist_advanced_filters',
      value: 'false',
      device: deviceName,
    ),
    SettingsCompanion.insert(
      key: 'advanced_filter_description',
      value: '',
      device: deviceName,
    ),
    SettingsCompanion.insert(
      key: 'advanced_filter_amount_from',
      value: '',
      device: deviceName,
    ),
    SettingsCompanion.insert(
      key: 'advanced_filter_amount_to',
      value: '',
      device: deviceName,
    ),
    SettingsCompanion.insert(
      key: 'advanced_filter_account_id',
      value: '',
      device: deviceName,
    ),
    SettingsCompanion.insert(
      key: 'advanced_filter_category_id',
      value: '',
      device: deviceName,
    ),
    SettingsCompanion.insert(
      key: 'advanced_filter_currency_code',
      value: '',
      device: deviceName,
    ),
    SettingsCompanion.insert(
      key: 'selected_currencies',
      value: '',
      device: deviceName,
    ),
    // AccountFilter
    SettingsCompanion.insert(
      key: 'persist_account_filters',
      value: 'false',
      device: deviceName,
    ),
    SettingsCompanion.insert(
      key: 'account_filter_description',
      value: '',
      device: deviceName,
    ),
    SettingsCompanion.insert(
      key: 'account_filter_amount_from',
      value: '',
      device: deviceName,
    ),
    SettingsCompanion.insert(
      key: 'account_filter_amount_to',
      value: '',
      device: deviceName,
    ),
    SettingsCompanion.insert(
      key: 'account_filter_account_date',
      value: '',
      device: deviceName,
    ),
    SettingsCompanion.insert(
      key: 'account_filter_category_id',
      value: '',
      device: deviceName,
    ),
    SettingsCompanion.insert(
      key: 'account_filter_account_type_id',
      value: '',
      device: deviceName,
    ),
    SettingsCompanion.insert(
      key: 'account_selected_currencies',
      value: '',
      device: deviceName,
    ),
    // Theme & Window Effects
    SettingsCompanion.insert(
      key: 'theme_color',
      value: '#2196F3', // Default blue
      device: deviceName,
    ),
    SettingsCompanion.insert(
      key: 'window_effect',
      value: 'none', // none, acrylic, mica, transparent
      device: deviceName,
    ),
    SettingsCompanion.insert(
      key: 'window_opacity',
      value: '0.8',
      device: deviceName,
    ),
  ];
}
