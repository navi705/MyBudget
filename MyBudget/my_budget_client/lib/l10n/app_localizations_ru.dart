// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get helloWorld => 'Привет мир!';

  @override
  String get accountsAppBarTitle => 'Счета';

  @override
  String accountsBalanceLabel(Object balance) {
    return 'Баланс: $balance';
  }

  @override
  String get accountsLoadFailure => 'Не удалось загрузить счета';

  @override
  String get accountsEmptyState => 'Нет счетов';

  @override
  String get accountsRefreshTooltip => 'Обновить';

  @override
  String get accountsAddTooltip => 'Добавить счет';

  @override
  String get addAccountDialogTitle => 'Добавить новый счет';

  @override
  String get accountNameHint => 'Название счета';

  @override
  String get initialBalanceHint => 'Начальный баланс';

  @override
  String get currencyLabel => 'Валюта';

  @override
  String get cancelButton => 'Отмена';

  @override
  String get saveButton => 'Сохранить';

  @override
  String get formValidationPleaseEnterName => 'Пожалуйста, введите имя';

  @override
  String get formValidationPleaseEnterBalance => 'Пожалуйста, введите баланс';

  @override
  String get formValidationPleaseEnterValidNumber =>
      'Пожалуйста, введите действительное число';

  @override
  String get formValidationPleaseSelectCurrency =>
      'Пожалуйста, выберите валюту';

  @override
  String get currencyLoadError => 'Ошибка загрузки валют';

  @override
  String get noCurrenciesAvailable => 'Валюты недоступны';

  @override
  String get categoriesAppBarTitle => 'Категории';

  @override
  String get categoriesScreenBody => 'Экран категорий';

  @override
  String get transactionsAppBarTitle => 'Транзакции';

  @override
  String get transactionsScreenBody => 'Экран транзакций';

  @override
  String get settingsAppBarTitle => 'Настройки';

  @override
  String get settingsScreenBody => 'Экран настроек';

  @override
  String get filePickerChooserTitle => 'Выберите файл';

  @override
  String get imagePickerChooserTitle => 'Выберите изображение';
}
