import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';

import '../../domain/repositories/transaction_repository.dart';

List<Setting> getDefaultSettings(String deviceName) {
  return [
    Setting(key: 'themeMode', value: 'system', device: deviceName),
    Setting(
      key: 'conversion_base_currency_id',
      value: '1', // USD
      device: deviceName,
    ),

    // transction list screen
    Setting(
      key: 'date_step_transaction',
      value: DateStep.month.toString(),
      device: deviceName,
    ),

    Setting(
      key: 'date_sort_transaction',
      value: Sort.descending.toString(),
      device: deviceName,
    ),
    Setting(
      key: 'persist_transaction_list_settings',
      value: 'true',
      device: deviceName,
    ),

    // advanced filters
    Setting(
      key: 'persist_advanced_filters',
      value: 'false',
      device: deviceName,
    ),
    Setting(
      key: 'advanced_filter_description',
      value: '',
      device: deviceName,
    ),
    Setting(
      key: 'advanced_filter_amount_from',
      value: '',
      device: deviceName,
    ),
    Setting(
      key: 'advanced_filter_amount_to',
      value: '',
      device: deviceName,
    ),
    Setting(
      key: 'advanced_filter_account_id',
      value: '',
      device: deviceName,
    ),
    Setting(
      key: 'advanced_filter_category_id',
      value: '',
      device: deviceName,
    ),
    Setting(
      key: 'advanced_filter_currency_code',
      value: '',
      device: deviceName,
    ),
  ];
}
