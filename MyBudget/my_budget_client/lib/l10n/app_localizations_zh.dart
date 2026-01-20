// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get helloWorld => '你好世界！';

  @override
  String get accountsAppBarTitle => '账户';

  @override
  String accountsBalanceLabel(Object balance) {
    return '余额: $balance';
  }

  @override
  String get accountsLoadFailure => '无法加载账户';

  @override
  String get accountsEmptyState => '沒有账户';

  @override
  String get accountsRefreshTooltip => '刷新';

  @override
  String get accountsAddTooltip => '添加账户';

  @override
  String get addAccountDialogTitle => '添加新账户';

  @override
  String get accountNameHint => '账户名称';

  @override
  String get initialBalanceHint => '初始余额';

  @override
  String get currencyLabel => '货币';

  @override
  String get cancelButton => '取消';

  @override
  String get saveButton => '保存';

  @override
  String get formValidationPleaseEnterName => '请输入名称';

  @override
  String get formValidationPleaseEnterBalance => '请输入余额';

  @override
  String get formValidationPleaseEnterValidNumber => '请输入有效数字';

  @override
  String get formValidationPleaseSelectCurrency => '请选择货币';

  @override
  String get currencyLoadError => '加载货币时出错';

  @override
  String get noCurrenciesAvailable => '没有可用货币';

  @override
  String get categoriesAppBarTitle => '类别';

  @override
  String get categoriesScreenBody => '类别屏幕';

  @override
  String get transactionsAppBarTitle => '交易';

  @override
  String get transactionsScreenBody => '交易屏幕';

  @override
  String get settingsAppBarTitle => '设置';

  @override
  String get settingsScreenBody => '设置屏幕';

  @override
  String get filePickerChooserTitle => 'Select File';

  @override
  String get imagePickerChooserTitle => 'Select Image';
}
