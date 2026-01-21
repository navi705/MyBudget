// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get helloWorld => 'Привет, мир!';

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
  String get addAccountDescription => 'Создать новый банковский счет, кошелек или актив';

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
  String get deleteButton => 'Удалить';

  @override
  String get editButton => 'Изменить';

  @override
  String get applyButton => 'Применить';

  @override
  String get clearButton => 'Очистить';

  @override
  String get formValidationPleaseEnterName => 'Пожалуйста, введите название';

  @override
  String get formValidationPleaseEnterBalance => 'Пожалуйста, введите баланс';

  @override
  String get formValidationPleaseEnterValidNumber => 'Пожалуйста, введите корректное число';

  @override
  String get formValidationPleaseSelectCurrency => 'Пожалуйста, выберите валюту';

  @override
  String get currencyLoadError => 'Ошибка загрузки валют';

  @override
  String get noCurrenciesAvailable => 'Нет доступных валют';

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

  @override
  String get totalNetWorth => 'Общий капитал';

  @override
  String get currencyBreakdown => 'Распределение по валютам';

  @override
  String get metricBalance => 'Баланс';

  @override
  String get metricIncome => 'Доход';

  @override
  String get metricExpense => 'Расход';

  @override
  String get metricReal => 'Реальный';

  @override
  String get metricChange => 'Изменение';

  @override
  String get contextMenuSelect => 'Выбрать';

  @override
  String get contextMenuDeselect => 'Отменить выбор';

  @override
  String get contextMenuSelectAll => 'Выбрать все';

  @override
  String get contextMenuDeselectAll => 'Отменить выбор всех';

  @override
  String get contextMenuAddTransaction => 'Добавить транзакцию';

  @override
  String get addTransactionDescription => 'Создать новую транзакцию';

  @override
  String get contextMenuTransfer => 'Перевод';

  @override
  String get contextMenuEdit => 'Изменить';

  @override
  String get contextMenuDelete => 'Удалить';

  @override
  String get contextMenuChangeType => 'Изменить тип';

  @override
  String deleteConfirmationTitle(Object item) {
    return 'Удалить $item?';
  }

  @override
  String deleteConfirmationMessage(Object item) {
    return 'Вы уверены, что хотите удалить этот $item и все связанные данные?';
  }

  @override
  String get deleteAccountsConfirmationTitle => 'Удалить счета?';

  @override
  String deleteAccountsConfirmationMessage(Object count) {
    return 'Удалить $count выбранных счетов и их транзакции?';
  }

  @override
  String get deleteAccountDialogReassign => 'Переназначить транзакции другому счету';

  @override
  String get deleteAccountDialogDeleteAll => 'Удалить все связанные транзакции';

  @override
  String get deleteAccountDialogMessage => 'У этого счета могут быть связанные транзакции. Что вы хотите сделать?';

  @override
  String get newAccountLabel => 'Новый счет';

  @override
  String get warningOverwriteTitle => 'Предупреждение: Перезаписать данные?';

  @override
  String get warningOverwriteMessage => 'Восстановление из резервной копии УДАЛИТ ВСЕ текущие данные и заменит их данными из копии. Это действие нельзя отменить.';

  @override
  String get restoreOverwriteButton => 'Восстановить с перезаписью';

  @override
  String get importSuccess => 'Импорт успешно завершен.';

  @override
  String importFailed(Object error) {
    return 'Ошибка импорта: $error';
  }

  @override
  String deleteCategoriesConfirmationTitle(Object count) {
    return 'Удалить $count категорий?';
  }

  @override
  String get deleteCategoriesConfirmationMessage => 'Вы уверены, что хотите удалить выбранные категории?';

  @override
  String get changeCategoryTypeDialogTitle => 'Изменить тип категории';

  @override
  String get noCategoriesCreated => 'Категории еще не созданы.';

  @override
  String get addCategoryTooltip => 'Добавить категорию';

  @override
  String get addCategoryDescription => 'Создать новую категорию расходов или доходов';

  @override
  String get previousPeriodTooltip => 'Предыдущий период';

  @override
  String get previousPeriodDescription => 'Перейти к предыдущему месяцу или году';

  @override
  String get nextPeriodTooltip => 'Следующий период';

  @override
  String get nextPeriodDescription => 'Перейти к следующему месяцу или году';

  @override
  String get filterTooltip => 'Фильтр';

  @override
  String get filterCategoriesDescription => 'Фильтровать категории по типу (Расход/Доход)';

  @override
  String get selectDateTooltip => 'Выбрать дату';

  @override
  String get selectDateDescription => 'Выбрать определенный диапазон дат для просмотра итогов';

  @override
  String get sortOrderTooltip => 'Порядок сортировки';

  @override
  String get sortOrderDescription => 'Переключение между возрастающим и убывающим порядком сумм';

  @override
  String totalCountLabel(Object count) {
    return 'Всего: $count';
  }

  @override
  String get closeSelectionTooltip => 'Закрыть выбор';

  @override
  String get exitSelectionDescription => 'Выйти из режима выбора';

  @override
  String selectedCountLabel(Object count) {
    return 'Выбрано: $count';
  }

  @override
  String get categoryNameLabel => 'Название категории';

  @override
  String get categoriesChangeButton => 'Изменить';

  @override
  String get parentCategoryLabel => 'Родительская категория';

  @override
  String get styleLabel => 'Стиль (Иконка и Цвет)';

  @override
  String get typeLabel => 'Тип';

  @override
  String get deleteTransactionsConfirmationTitle => 'Удалить транзакции';

  @override
  String deleteTransactionsConfirmationMessage(Object count) {
    return 'Вы уверены, что хотите удалить $count выбранных транзакций?';
  }

  @override
  String get changeDateTooltip => 'Изменить дату';

  @override
  String get changeDateDescription => 'Обновить дату для всех выбранных транзакций';

  @override
  String get changeCategoryTooltip => 'Изменить категорию';

  @override
  String get changeCategoryDescription => 'Обновить категорию для всех выбранных транзакций';

  @override
  String get deleteTransactionsTooltip => 'Удалить выбранные';

  @override
  String get deleteTransactionsDescription => 'Безвозвратно удалить все выбранные транзакции';

  @override
  String get exitTransactionsSelectionDescription => 'Выйти из режима выбора транзакций';

  @override
  String quantityLabel(Object quantity) {
    return 'Кол-во: $quantity';
  }

  @override
  String get addTransactionTitle => 'Добавить транзакцию';

  @override
  String get editTransactionTitle => 'Редактировать транзакцию';

  @override
  String get newTransferTitle => 'Новый перевод';

  @override
  String get editTransferTitle => 'Редактировать перевод';

  @override
  String get descriptionLabel => 'Описание';

  @override
  String get descriptionOptionalLabel => 'Описание (необязательно)';

  @override
  String get amountLabel => 'Сумма';

  @override
  String get quantityFormLabel => 'Количество';

  @override
  String get selectAccountTitle => 'Выберите счет';

  @override
  String get selectCategoryTitle => 'Выберите категорию';

  @override
  String get selectCurrencyTitle => 'Выберите валюту';

  @override
  String get accountLabel => 'Счет';

  @override
  String get fromAccountLabel => 'Со счета';

  @override
  String get toAccountLabel => 'На счет';

  @override
  String get categoryLabel => 'Категория';

  @override
  String get dateLabel => 'Дата';

  @override
  String get selectDateLabel => 'Выберите дату';

  @override
  String get swapAccountsTooltip => 'Поменять счета местами';

  @override
  String get incomeType => 'Доход';

  @override
  String get expenseType => 'Расход';

  @override
  String get failedToLoadData => 'Не удалось загрузить данные';

  @override
  String get invalidAmountError => 'Пожалуйста, введите корректное число';

  @override
  String get emptyAmountError => 'Пожалуйста, введите сумму';

  @override
  String get selectAccountError => 'Пожалуйста, выберите счет';

  @override
  String get selectCategoryError => 'Пожалуйста, выберите категорию';

  @override
  String get selectDateError => 'Пожалуйста, выберите дату';

  @override
  String get currencyLockedMessage => 'Привязано к валюте счета отправителя';

  @override
  String get totalValueLabel => 'Общая стоимость';

  @override
  String get feeLabel => 'Комиссия';

  @override
  String get exchangeRateLabel => 'Курс обмена';

  @override
  String get pricePerUnitLabel => 'Цена за единицу';

  @override
  String get buyAction => 'Купить';

  @override
  String get sellAction => 'Продать';

  @override
  String transferToDescription(Object accountName) {
    return 'Перевод на $accountName';
  }

  @override
  String transferFromDescription(Object accountName) {
    return 'Перевод со счета $accountName';
  }

  @override
  String buyDescription(Object assetName) {
    return 'Покупка $assetName';
  }

  @override
  String sellDescription(Object assetName) {
    return 'Продажа $assetName';
  }

  @override
  String assetTransferDescription(Object action, Object assetName) {
    return 'Перевод для: $action $assetName';
  }

  @override
  String get swapDirectionTooltip => 'Поменять направление';

  @override
  String get availablePresetsLabel => 'Доступные пресеты:';

  @override
  String get updateButton => 'Обновить';

  @override
  String get newPresetButton => 'Новый пресет';

  @override
  String get amountToAddToAccountLabel => 'Сумма для зачисления на счет:';

  @override
  String valueInGlobalLabel(Object currency) {
    return 'Стоимость в основной валюте ($currency):';
  }

  @override
  String get feeCommissionLabel => 'Комиссия';

  @override
  String get requiredError => 'Обязательно';

  @override
  String currentPriceLabel(Object currency, Object price) {
    return 'Текущая цена: $price $currency';
  }

  @override
  String get linkedAccountLabel => 'Связанный счет';

  @override
  String get selectLinkedAccountTitle => 'Выберите связанный счет';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get manageIconsLabel => 'Управление иконками';

  @override
  String get manageThemeLabel => 'Управление темой';

  @override
  String get mainCurrencyLabel => 'Основная валюта';

  @override
  String get defaultInflationCountryLabel => 'Страна инфляции по умолчанию';

  @override
  String get persistAdvancedFiltersLabel => 'Сохранять расширенные фильтры';

  @override
  String get hotKeysLabel => 'Горячие клавиши';

  @override
  String get smsImportLabel => 'Импорт SMS';

  @override
  String get smsImportSubtitle => 'Импорт транзакций из банковских SMS';

  @override
  String get apiManagementLabel => 'Управление API';

  @override
  String get dataLabel => 'Данные';

  @override
  String get syncSettingsLabel => 'Настройки синхронизации';

  @override
  String get syncSettingsSubtitle => 'P2P синхронизация через Syncthing';

  @override
  String get importDataLabel => 'Импорт данных';

  @override
  String get exportDataLabel => 'Экспорт данных';

  @override
  String get exportFormatMessage => 'Выберите формат:\n\nJSON: Полная резервная копия всех данных.\nCSV: Читаемый отчет по транзакциям.';

  @override
  String get jsonFormat => 'JSON';

  @override
  String get csvFormat => 'CSV';

  @override
  String get importExchangeRatesLabel => 'Импорт курсов валют (CSV/JSON)';

  @override
  String get resetDataLabel => 'Сброс данных к начальным';

  @override
  String get resetDataSubtitle => 'Это Удалит все данные и восстановит настройки по умолчанию.';

  @override
  String get debugMenuLabel => 'Меню отладки';

  @override
  String get debugMenuSubtitle => 'Внутренние инструменты разработчика';

  @override
  String get exportSuccessMessage => 'Экспорт успешно завершен';

  @override
  String exportFailedMessage(Object error) {
    return 'Ошибка экспорта: $error';
  }

  @override
  String get importSuccessMessage => 'Импорт успешно завершен';

  @override
  String importFailedMessage(Object error) {
    return 'Ошибка импорта: $error';
  }

  @override
  String get resetDataConfirmationTitle => 'Сбросить данные?';

  @override
  String get resetDataConfirmationMessage => 'Внимание! Это удалит ВСЕ ваши транзакции, счета и настройки.\n\nПриложение будет возвращено в исходное состояние с данными по умолчанию.\nЭто действие НЕВОЗМОЖНО отменить.';

  @override
  String get resetEverythingButton => 'Сбросить всё';

  @override
  String get resetSuccessMessage => 'Данные сброшены, настройки по умолчанию восстановлены.';

  @override
  String resetFailedMessage(Object error) {
    return 'Ошибка сброса: $error';
  }

  @override
  String get importParsingStep => 'Парсинг CSV файлов...';

  @override
  String get importFetchingRatesStep => 'Загрузка курсов валют...';

  @override
  String importErrorLabel(Object error) {
    return 'Ошибка: $error';
  }

  @override
  String get importOneMoneyLabel => 'Импорт из OneMoney (CSV)';

  @override
  String get importMyBudgetLabel => 'Импорт транзакций MyBudget (CSV)';

  @override
  String get restoreBackupLabel => 'Восстановить из копии (JSON)';

  @override
  String get importSelectionHelp => 'Выберите \'OneMoney\' для миграции, \'MyBudget\' для добавления транзакций или \'Восстановить из копии\' для полной перезаписи данных.';

  @override
  String get importCreateAllNew => 'Создать все как новые';

  @override
  String importNewAccountFound(Object accountName) {
    return 'Найден новый счет: \"$accountName\"';
  }

  @override
  String importMapAccountTitle(Object accountName) {
    return 'Привязать \"$accountName\" к...';
  }

  @override
  String get importMapToExisting => 'Привязать к существующему';

  @override
  String get importCreateNew => 'Создать новый';

  @override
  String importNewCategoryFound(Object categoryName) {
    return 'Найдена новая категория: \"$categoryName\"';
  }

  @override
  String importMapCategoryTitle(Object categoryName) {
    return 'Привязать \"$categoryName\" к...';
  }

  @override
  String importNewCurrencyFound(Object currencyName) {
    return 'Найдена новая валюта: \"$currencyName\"';
  }

  @override
  String importMapCurrencyTitle(Object currencyName) {
    return 'Привязать \"$currencyName\" к...';
  }

  @override
  String get importSkipAll => 'Пропустить все';

  @override
  String get importImportAll => 'Импортировать все';

  @override
  String get importPotentialDuplicate => 'Потенциальный дубликат:';

  @override
  String importDateLabel(Object date) {
    return 'Дата: $date';
  }

  @override
  String importFromLabel(Object from) {
    return 'Откуда: $from';
  }

  @override
  String importToLabel(Object to) {
    return 'Куда: $to';
  }

  @override
  String importAmountLabel(Object amount, Object currency) {
    return 'Сумма: $amount $currency';
  }

  @override
  String get importSkip => 'Пропустить';

  @override
  String get importImportAnyway => 'Импортировать';

  @override
  String importDecisionLabel(Object decision) {
    return 'Решение: $decision';
  }

  @override
  String get importReadyTitle => 'Готово к импорту';

  @override
  String importReadyMessage(Object count) {
    return '$count транзакций готовы к импорту.';
  }

  @override
  String get importFinalizeButton => 'Завершить импорт';

  @override
  String get importingTitle => 'Импорт...';

  @override
  String get importCompleteTitle => 'Импорт завершен';

  @override
  String get importStartOverTooltip => 'Начать заново';

  @override
  String get importDataTitle => 'Импорт данных';

  @override
  String importAccountsCreatedLabel(Object count) {
    return 'Создано новых счетов: $count';
  }

  @override
  String importCategoriesCreatedLabel(Object count) {
    return 'Создано новых категорий: $count';
  }

  @override
  String importTransactionsImportedLabel(Object count) {
    return 'Транзакций импортировано: $count';
  }

  @override
  String importDuplicatesSkippedLabel(Object count) {
    return 'Дубликатов пропущено: $count';
  }

  @override
  String get searchHint => 'Поиск';

  @override
  String get debugAllDataClearedMessage => 'Все данные очищены и заполнены значениями по умолчанию.';

  @override
  String get debugClearAllDataLabel => 'Очистить все данные (и заполнить по умолчанию)';

  @override
  String get debugMinimumDataSeededMessage => 'Минимальный набор данных загружен.';

  @override
  String get debugSeedMinimumDataLabel => 'Загрузить минимальный набор данных';

  @override
  String get debugMediumDataSeededMessage => 'Средний набор данных загружен.';

  @override
  String get debugSeedMediumDataLabel => 'Загрузить средний набор данных';

  @override
  String get debugMaximumDataSeededMessage => 'Максимальный набор данных загружен.';

  @override
  String get debugSeedMaximumDataLabel => 'Загрузить максимальный набор данных (тест производительности)';

  @override
  String get debugRunningInDebugModeLabel => 'Запущено в режиме ОТЛАДКИ';

  @override
  String get deleteAllButton => 'Удалить все';

  @override
  String get changeButton => 'Изменить';

  @override
  String get undoButton => 'Отменить';

  @override
  String itemDeletedMessage(Object name) {
    return '$name удалено';
  }

  @override
  String get totalBalanceLabel => 'Общий баланс';

  @override
  String get noCurrenciesSelected => 'Валюты не выбраны.';

  @override
  String get incomeLabel => 'Доход';

  @override
  String get expenseLabel => 'Расход';

  @override
  String get failedToLoadDashboard => 'Не удалось загрузить панель управления';

  @override
  String get dashboardCalendarTab => 'Календарь';

  @override
  String get dashboardCalendarTooltip => 'Просмотр календаря';

  @override
  String get dashboardCalendarDescription => 'Просмотр транзакций в формате календаря';

  @override
  String get dashboardCategoriesTab => 'Категории';

  @override
  String get dashboardCategoriesTooltip => 'Анализ категорий';

  @override
  String get dashboardCategoriesDescription => 'Разбивка расходов по категориям';

  @override
  String get dashboardBalanceTab => 'Баланс';

  @override
  String get dashboardBalanceTooltip => 'История баланса';

  @override
  String get dashboardBalanceDescription => 'Отслеживание чистого капитала со временем';

  @override
  String get dashboardExpensesLabel => 'Расходы';

  @override
  String get dashboardIncomeLabel => 'Доходы';

  @override
  String get manageIconsTitle => 'Управление иконками';

  @override
  String get noIconsCreated => 'Иконки еще не созданы.';

  @override
  String get failedToLoadIcons => 'Не удалось загрузить иконки.';

  @override
  String get cannotDeleteTransferIcon => 'Нельзя удалить иконку \'Перевод\'.';

  @override
  String get deleteIconsDialogTitle => 'Удалить иконки';

  @override
  String deleteIconsConfirmationMessage(Object count) {
    return 'Вы уверены, что хотите удалить $count выбранных иконок?';
  }

  @override
  String deleteIconsWithSkipTransferMessage(Object count) {
    return 'Вы уверены, что хотите удалить $count выбранных иконок? (Иконка \'Перевод\' будет пропущена)';
  }

  @override
  String get deleteIconDialogTitle => 'Удалить иконку';

  @override
  String deleteIconConfirmationMessage(Object name) {
    return 'Вы уверены, что хотите удалить \"$name\"?';
  }

  @override
  String deleteMultipleAccountsTitle(Object count) {
    return 'Удалить $count аккаунтов?';
  }

  @override
  String get deleteMultipleAccountsMessage => 'Вы уверены, что хотите удалить выбранные аккаунты? Все связанные транзакции будут удалены.';

  @override
  String get changeAccountTypeDialogTitle => 'Изменить тип аккаунта';

  @override
  String editAccountTitle(Object name) {
    return 'Редактирование: $name';
  }

  @override
  String get balanceCalculatedFromAsset => 'Баланс рассчитывается как Количество актива * Цена';

  @override
  String get selectAccountTypeTitle => 'Выберите тип аккаунта';

  @override
  String get selectCountryTitle => 'Выберите страну';

  @override
  String get selectIconSubtitle => 'Выберите иконку';

  @override
  String get bindToAssetLabel => 'Привязать к активу (опционально)';

  @override
  String get selectAssetTitle => 'Выберите актив';

  @override
  String get selectedAssetLabel => 'Выбранный актив';

  @override
  String get balanceAutoCalculatedLabel => 'Баланс рассчитывается автоматически';

  @override
  String get tapToBindAssetLabel => 'Нажмите, чтобы привязать актив';

  @override
  String get assetQuantityLabel => 'Количество актива';

  @override
  String get linkedAssetsTitle => 'Привязанные активы';

  @override
  String get noneLabel => 'Нет';

  @override
  String get accountTypeLabel => 'Тип аккаунта';

  @override
  String get formValidationPleaseSelectAccountType => 'Пожалуйста, выберите тип аккаунта';

  @override
  String get iconLabel => 'Иконка';

  @override
  String get languageLabel => 'Язык';

  @override
  String get systemDefaultLabel => 'Системный';

  @override
  String get selectLanguageTitle => 'Выберите язык';

  @override
  String get dashboardLabel => 'Сводка';

  @override
  String get homeLabel => 'Главная';

  @override
  String get historyLabel => 'История';
}
