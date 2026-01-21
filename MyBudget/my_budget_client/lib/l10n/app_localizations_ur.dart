// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get helloWorld => 'ہیلو دنیا!';

  @override
  String get accountsAppBarTitle => 'اکاؤنٹس';

  @override
  String accountsBalanceLabel(Object balance) {
    return 'بیلنس: $balance';
  }

  @override
  String get accountsLoadFailure => 'اکاؤنٹس لوڈ کرنے میں ناکام';

  @override
  String get accountsEmptyState => 'کوئی اکاؤنٹ نہیں';

  @override
  String get accountsRefreshTooltip => 'ریفریش';

  @override
  String get accountsAddTooltip => 'اکاؤنٹ شامل کریں';

  @override
  String get addAccountDescription => 'ایک نیا بینک اکاؤنٹ، والٹ یا اثاثہ بنائیں';

  @override
  String get addAccountDialogTitle => 'نیا اکاؤنٹ شامل کریں';

  @override
  String get accountNameHint => 'اکاؤنٹ کا نام';

  @override
  String get initialBalanceHint => 'ابتدائی بیلنس';

  @override
  String get currencyLabel => 'کرنسی';

  @override
  String get cancelButton => 'منسوخ کریں';

  @override
  String get saveButton => 'محفوظ کریں';

  @override
  String get deleteButton => 'حذف کریں';

  @override
  String get editButton => 'ترمیم کریں';

  @override
  String get applyButton => 'لاگو کریں';

  @override
  String get clearButton => 'صاف کریں';

  @override
  String get formValidationPleaseEnterName => 'براہ کرم نام درج کریں';

  @override
  String get formValidationPleaseEnterBalance => 'براہ کرم بیلنس درج کریں';

  @override
  String get formValidationPleaseEnterValidNumber => 'براہ کرم ایک درست نمبر درج کریں';

  @override
  String get formValidationPleaseSelectCurrency => 'براہ کرم کرنسی منتخب کریں';

  @override
  String get currencyLoadError => 'کرنسی لوڈ کرنے میں خرابی';

  @override
  String get noCurrenciesAvailable => 'کوئی کرنسی دستیاب نہیں';

  @override
  String get categoriesAppBarTitle => 'زمرہ جات';

  @override
  String get categoriesScreenBody => 'زمرہ جات اسکرین';

  @override
  String get transactionsAppBarTitle => 'لین دین';

  @override
  String get transactionsScreenBody => 'لین دین اسکرین';

  @override
  String get settingsAppBarTitle => 'ترتیبات';

  @override
  String get settingsScreenBody => 'ترتیبات اسکرین';

  @override
  String get filePickerChooserTitle => 'فائل منتخب کریں';

  @override
  String get imagePickerChooserTitle => 'تصویر منتخب کریں';

  @override
  String get totalNetWorth => 'کل خالص مالیت';

  @override
  String get currencyBreakdown => 'کرنسی کی تفصیل';

  @override
  String get metricBalance => 'بیلنس';

  @override
  String get metricIncome => 'آمدنی';

  @override
  String get metricExpense => 'اخراجات';

  @override
  String get metricReal => 'حقیقی';

  @override
  String get metricChange => 'تبدیلی';

  @override
  String get contextMenuSelect => 'منتخب کریں';

  @override
  String get contextMenuDeselect => 'غیر منتخب کریں';

  @override
  String get contextMenuSelectAll => 'سب منتخب کریں';

  @override
  String get contextMenuDeselectAll => 'سب غیر منتخب کریں';

  @override
  String get contextMenuAddTransaction => 'لین دین شامل کریں';

  @override
  String get addTransactionDescription => 'ایک نیا لین دین بنائیں';

  @override
  String get contextMenuTransfer => 'منتقلی';

  @override
  String get contextMenuEdit => 'ترمیم کریں';

  @override
  String get contextMenuDelete => 'حذف کریں';

  @override
  String get contextMenuChangeType => 'قسم تبدیل کریں';

  @override
  String deleteConfirmationTitle(Object item) {
    return '$item حذف کریں؟';
  }

  @override
  String deleteConfirmationMessage(Object item) {
    return 'کیا آپ واقعی یہ $item اور اس کا تمام ڈیٹا حذف کرنا چاہتے ہیں؟';
  }

  @override
  String get deleteAccountsConfirmationTitle => 'اکاؤنٹس حذف کریں؟';

  @override
  String deleteAccountsConfirmationMessage(Object count) {
    return 'منتخب $count اکاؤنٹس اور ان کے لین دین حذف کریں؟';
  }

  @override
  String get deleteAccountDialogReassign => 'لین دین کو دوسرے اکاؤنٹ میں دوبارہ تفویض کریں';

  @override
  String get deleteAccountDialogDeleteAll => 'تمام متعلقہ لین دین حذف کریں';

  @override
  String get deleteAccountDialogMessage => 'اس اکاؤنٹ میں متعلقہ لین دین ہوسکتے ہیں۔ آپ کیا کرنا چاہیں گے؟';

  @override
  String get newAccountLabel => 'نیا اکاؤنٹ';

  @override
  String get warningOverwriteTitle => 'انتباہ: ڈیٹا کو اوور رائٹ کریں؟';

  @override
  String get warningOverwriteMessage => 'بیک اپ بحال کرنے سے تمام موجودہ ڈیٹا حذف ہوجائے گا اور بیک اپ سے تبدیل ہوجائے گا۔ اسے کالعدم نہیں کیا جاسکتا۔';

  @override
  String get restoreOverwriteButton => 'بحال اور اوور رائٹ کریں';

  @override
  String get importSuccess => 'درآمد کامیابی سے مکمل ہوئی۔';

  @override
  String importFailed(Object error) {
    return 'درآمد ناکام: $error';
  }

  @override
  String deleteCategoriesConfirmationTitle(Object count) {
    return '$count زمرہ جات حذف کریں؟';
  }

  @override
  String get deleteCategoriesConfirmationMessage => 'کیا آپ واقعی منتخب زمرہ جات حذف کرنا چاہتے ہیں؟';

  @override
  String get changeCategoryTypeDialogTitle => 'زمرہ کی قسم تبدیل کریں';

  @override
  String get noCategoriesCreated => 'ابھی تک کوئی زمرہ نہیں بنایا گیا ہے۔';

  @override
  String get addCategoryTooltip => 'زمرہ شامل کریں';

  @override
  String get addCategoryDescription => 'نئی اخراجات یا آمدنی کا زمرہ بنائیں';

  @override
  String get previousPeriodTooltip => 'پچھلی مدت';

  @override
  String get previousPeriodDescription => 'پچھلے مہینے یا سال پر جائیں';

  @override
  String get nextPeriodTooltip => 'اگلی مدت';

  @override
  String get nextPeriodDescription => 'اگلے مہینے یا سال پر جائیں';

  @override
  String get filterTooltip => 'فلٹر';

  @override
  String get filterCategoriesDescription => 'قسم (آمدنی/اخراجات) کے لحاظ سے زمرہ جات فلٹر کریں';

  @override
  String get selectDateTooltip => 'تاریخ منتخب کریں';

  @override
  String get selectDateDescription => 'کل دیکھنے کے لیے ایک مخصوص تاریخ کی حد منتخب کریں';

  @override
  String get sortOrderTooltip => 'ترتیب دیں';

  @override
  String get sortOrderDescription => 'رقم کے لحاظ سے صعودی اور نزولی ترتیب کے درمیان سوئچ کریں';

  @override
  String totalCountLabel(Object count) {
    return 'کل: $count';
  }

  @override
  String get closeSelectionTooltip => 'انتخاب بند کریں';

  @override
  String get exitSelectionDescription => 'انتخاب موڈ سے باہر نکلیں';

  @override
  String selectedCountLabel(Object count) {
    return '$count منتخب';
  }

  @override
  String get categoryNameLabel => 'زمرہ کا نام';

  @override
  String get categoriesChangeButton => 'تبدیل کریں';

  @override
  String get parentCategoryLabel => 'بنیادی زمرہ';

  @override
  String get styleLabel => 'انداز (آئیکن اور رنگ)';

  @override
  String get typeLabel => 'قسم';

  @override
  String get deleteTransactionsConfirmationTitle => 'لین دین حذف کریں';

  @override
  String deleteTransactionsConfirmationMessage(Object count) {
    return 'کیا آپ واقعی $count منتخب لین دین حذف کرنا چاہتے ہیں؟';
  }

  @override
  String get changeDateTooltip => 'تاریخ تبدیل کریں';

  @override
  String get changeDateDescription => 'تمام منتخب لین دین کے لیے تاریخ کو اپ ڈیٹ کریں';

  @override
  String get changeCategoryTooltip => 'زمرہ تبدیل کریں';

  @override
  String get changeCategoryDescription => 'تمام منتخب لین دین کے لیے زمرہ کو اپ ڈیٹ کریں';

  @override
  String get deleteTransactionsTooltip => 'منتخب حذف کریں';

  @override
  String get deleteTransactionsDescription => 'تمام منتخب لین دین کو مستقل طور پر حذف کریں';

  @override
  String get exitTransactionsSelectionDescription => 'لین دین کے انتخاب موڈ سے باہر نکلیں';

  @override
  String quantityLabel(Object quantity) {
    return 'مقدار: $quantity';
  }

  @override
  String get addTransactionTitle => 'لین دین شامل کریں';

  @override
  String get editTransactionTitle => 'لین دین میں ترمیم کریں';

  @override
  String get newTransferTitle => 'نئی منتقلی';

  @override
  String get editTransferTitle => 'منتقلی میں ترمیم کریں';

  @override
  String get descriptionLabel => 'تفصیل';

  @override
  String get descriptionOptionalLabel => 'تفصیل (اختیاری)';

  @override
  String get amountLabel => 'رقم';

  @override
  String get quantityFormLabel => 'مقدار';

  @override
  String get selectAccountTitle => 'اکاؤنٹ منتخب کریں';

  @override
  String get selectCategoryTitle => 'زمرہ منتخب کریں';

  @override
  String get selectCurrencyTitle => 'کرنسی منتخب کریں';

  @override
  String get accountLabel => 'اکاؤنٹ';

  @override
  String get fromAccountLabel => 'اکاؤنٹ سے';

  @override
  String get toAccountLabel => 'اکاؤنٹ میں';

  @override
  String get categoryLabel => 'زمرہ';

  @override
  String get dateLabel => 'تاریخ';

  @override
  String get selectDateLabel => 'تاریخ منتخب کریں';

  @override
  String get swapAccountsTooltip => 'اکاؤنٹس تبدیل کریں';

  @override
  String get incomeType => 'آمدنی';

  @override
  String get expenseType => 'اخراجات';

  @override
  String get failedToLoadData => 'ڈیٹا لوڈ کرنے میں ناکام';

  @override
  String get invalidAmountError => 'براہ کرم ایک درست نمبر درج کریں';

  @override
  String get emptyAmountError => 'براہ کرم رقم درج کریں';

  @override
  String get selectAccountError => 'براہ کرم ایک اکاؤنٹ منتخب کریں';

  @override
  String get selectCategoryError => 'براہ کرم ایک زمرہ منتخب کریں';

  @override
  String get selectDateError => 'براہ کرم ایک تاریخ منتخب کریں';

  @override
  String get currencyLockedMessage => 'ماخذ اکاؤنٹ کی کرنسی پر مقفل';

  @override
  String get totalValueLabel => 'کل قدر';

  @override
  String get feeLabel => 'فیس';

  @override
  String get exchangeRateLabel => 'شرح تبادلہ';

  @override
  String get pricePerUnitLabel => 'فی یونٹ قیمت';

  @override
  String get buyAction => 'خریدیں';

  @override
  String get sellAction => 'بیچیں';

  @override
  String transferToDescription(Object accountName) {
    return '$accountName کو منتقلی';
  }

  @override
  String transferFromDescription(Object accountName) {
    return '$accountName سے منتقلی';
  }

  @override
  String buyDescription(Object assetName) {
    return '$assetName خریدیں';
  }

  @override
  String sellDescription(Object assetName) {
    return '$assetName بیچیں';
  }

  @override
  String assetTransferDescription(Object action, Object assetName) {
    return '$action $assetName کے لیے منتقلی';
  }

  @override
  String get swapDirectionTooltip => 'سمت تبدیل کریں';

  @override
  String get availablePresetsLabel => 'دستیاب پیش سیٹ:';

  @override
  String get updateButton => 'اپ ڈیٹ';

  @override
  String get newPresetButton => 'نیا پیش سیٹ';

  @override
  String get amountToAddToAccountLabel => 'اکاؤنٹ میں شامل کرنے کی رقم:';

  @override
  String valueInGlobalLabel(Object currency) {
    return 'عالمی قدر ($currency):';
  }

  @override
  String get feeCommissionLabel => 'فیس (کمیشن)';

  @override
  String get requiredError => 'مطلوب';

  @override
  String currentPriceLabel(Object currency, Object price) {
    return 'موجودہ قیمت: $price $currency';
  }

  @override
  String get linkedAccountLabel => 'منسلک اکاؤنٹ';

  @override
  String get selectLinkedAccountTitle => 'منسلک اکاؤنٹ منتخب کریں';

  @override
  String get settingsTitle => 'ترتیبات';

  @override
  String get manageIconsLabel => 'آئیکنز کا نظم کریں';

  @override
  String get manageThemeLabel => 'تھیم کا نظم کریں';

  @override
  String get mainCurrencyLabel => 'مرکزی کرنسی';

  @override
  String get defaultInflationCountryLabel => 'پہلے سے طے شدہ افراط زر ملک';

  @override
  String get persistAdvancedFiltersLabel => 'اعلی درجے کے فلٹرز برقرار رکھیں';

  @override
  String get hotKeysLabel => 'ہاٹ کیز';

  @override
  String get smsImportLabel => 'ایس ایم ایس درآمد';

  @override
  String get smsImportSubtitle => 'بینک ایس ایم ایس سے لین دین درآمد کریں';

  @override
  String get apiManagementLabel => 'API مینجمنٹ';

  @override
  String get dataLabel => 'ڈیٹا';

  @override
  String get syncSettingsLabel => 'مطابقت پذیری کی ترتیبات';

  @override
  String get syncSettingsSubtitle => 'Syncthing کے ذریعے P2P مطابقت پذیری';

  @override
  String get importDataLabel => 'ڈیٹا درآمد کریں';

  @override
  String get exportDataLabel => 'ڈیٹا برآمد کریں';

  @override
  String get exportFormatMessage => 'فارمیٹ منتخب کریں:\n\nJSON: تمام ڈیٹا کا مکمل بیک اپ۔\nCSV: لین دین کی قابل مطالعہ رپورٹ۔';

  @override
  String get jsonFormat => 'JSON';

  @override
  String get csvFormat => 'CSV';

  @override
  String get importExchangeRatesLabel => 'شرح تبادلہ درآمد کریں (CSV/JSON)';

  @override
  String get resetDataLabel => 'ڈیٹا کو ڈیفالٹ پر ری سیٹ کریں';

  @override
  String get resetDataSubtitle => 'یہ تمام ڈیٹا حذف کر دے گا اور ڈیفالٹ ترتیبات بحال کر دے گا۔';

  @override
  String get debugMenuLabel => 'ڈیبگ مینو';

  @override
  String get debugMenuSubtitle => 'اندرونی ڈویلپر ٹولز';

  @override
  String get exportSuccessMessage => 'برآمد کامیابی سے مکمل ہوئی۔';

  @override
  String exportFailedMessage(Object error) {
    return 'برآمد ناکام: $error';
  }

  @override
  String get importSuccessMessage => 'درآمد کامیابی سے مکمل ہوئی۔';

  @override
  String importFailedMessage(Object error) {
    return 'درآمد ناکام: $error';
  }

  @override
  String get resetDataConfirmationTitle => 'ڈیٹا ری سیٹ کریں؟';

  @override
  String get resetDataConfirmationMessage => 'انتباہ! یہ آپ کے تمام لین دین، اکاؤنٹس اور ترتیبات کو حذف کر دے گا۔\n\nایپ اپنی ابتدائی حالت میں ڈیفالٹ ڈیٹا کے ساتھ بحال ہو جائے گی۔\nیہ عمل کالعدم نہیں کیا جا سکتا۔';

  @override
  String get resetEverythingButton => 'سب کچھ ری سیٹ کریں';

  @override
  String get resetSuccessMessage => 'ڈیٹا ری سیٹ اور ڈیفالٹ بحال۔';

  @override
  String resetFailedMessage(Object error) {
    return 'ری سیٹ ناکام: $error';
  }

  @override
  String get importParsingStep => 'CSV فائلوں کا تجزیہ کیا جا رہا ہے...';

  @override
  String get importFetchingRatesStep => 'شرح مبادلہ حاصل کی جا رہی ہے...';

  @override
  String importErrorLabel(Object error) {
    return 'خرابی: $error';
  }

  @override
  String get importOneMoneyLabel => 'OneMoney (CSV) سے درآمد کریں';

  @override
  String get importMyBudgetLabel => 'MyBudget لین دین (CSV) درآمد کریں';

  @override
  String get restoreBackupLabel => 'بیک اپ بحال کریں (JSON)';

  @override
  String get importSelectionHelp => 'ہجرت کے لیے \'OneMoney\'، لین دین کے اضافے کے لیے \'MyBudget\'، یا تمام ڈیٹا کو اوور رائٹ کرنے کے لیے \'بیک اپ بحال کریں\' منتخب کریں۔';

  @override
  String get importCreateAllNew => 'سب نیا بنائیں';

  @override
  String importNewAccountFound(Object accountName) {
    return 'نیا اکاؤنٹ ملا: \"$accountName\"';
  }

  @override
  String importMapAccountTitle(Object accountName) {
    return '\"$accountName\" کو اس کے ساتھ میپ کریں...';
  }

  @override
  String get importMapToExisting => 'موجودہ کے ساتھ میپ کریں';

  @override
  String get importCreateNew => 'نیا بنائیں';

  @override
  String importNewCategoryFound(Object categoryName) {
    return 'نئی کیٹیگری ملی: \"$categoryName\"';
  }

  @override
  String importMapCategoryTitle(Object categoryName) {
    return '\"$categoryName\" کو اس کے ساتھ میپ کریں...';
  }

  @override
  String importNewCurrencyFound(Object currencyName) {
    return 'نئی کرنسی ملی: \"$currencyName\"';
  }

  @override
  String importMapCurrencyTitle(Object currencyName) {
    return '\"$currencyName\" کو اس کے ساتھ میپ کریں...';
  }

  @override
  String get importSkipAll => 'سب چھوڑ دیں';

  @override
  String get importImportAll => 'سب درآمد کریں';

  @override
  String get importPotentialDuplicate => 'ممکنہ نقل:';

  @override
  String importDateLabel(Object date) {
    return 'تاریخ: $date';
  }

  @override
  String importFromLabel(Object from) {
    return 'سے: $from';
  }

  @override
  String importToLabel(Object to) {
    return 'تک: $to';
  }

  @override
  String importAmountLabel(Object amount, Object currency) {
    return 'رقم: $amount $currency';
  }

  @override
  String get importSkip => 'چھوڑ دیں';

  @override
  String get importImportAnyway => 'بہر حال درآمد کریں';

  @override
  String importDecisionLabel(Object decision) {
    return 'فیصلہ: $decision';
  }

  @override
  String get importReadyTitle => 'درآمد کے لیے تیار';

  @override
  String importReadyMessage(Object count) {
    return '$count لین دین درآمد کے لیے تیار ہیں۔';
  }

  @override
  String get importFinalizeButton => 'درآمد مکمل کریں';

  @override
  String get importingTitle => 'درآمد ہو رہا ہے...';

  @override
  String get importCompleteTitle => 'درآمد مکمل';

  @override
  String get importStartOverTooltip => 'دوبارہ شروع کریں';

  @override
  String get importDataTitle => 'ڈیٹا درآمد کریں';

  @override
  String importAccountsCreatedLabel(Object count) {
    return 'بنائے گئے نئے اکاؤنٹس: $count';
  }

  @override
  String importCategoriesCreatedLabel(Object count) {
    return 'بنائی گئی نئی کیٹیگریز: $count';
  }

  @override
  String importTransactionsImportedLabel(Object count) {
    return 'درآمد شدہ لین دین: $count';
  }

  @override
  String importDuplicatesSkippedLabel(Object count) {
    return 'چھوڑی گئی نقول: $count';
  }

  @override
  String get searchHint => 'تلاش کریں';

  @override
  String get debugAllDataClearedMessage => 'تمام ڈیٹا صاف کر دیا گیا اور ڈیفالٹ کے ساتھ دوبارہ بھر دیا گیا۔';

  @override
  String get debugClearAllDataLabel => 'تمام ڈیٹا صاف کریں (اور ڈیفالٹ بھریں)';

  @override
  String get debugMinimumDataSeededMessage => 'کم سے کم ڈیٹا بھر دیا گیا۔';

  @override
  String get debugSeedMinimumDataLabel => 'کم سے کم ڈیٹا بھریں';

  @override
  String get debugMediumDataSeededMessage => 'درمیانہ ڈیٹا بھر دیا گیا۔';

  @override
  String get debugSeedMediumDataLabel => 'درمیانہ ڈیٹا بھریں';

  @override
  String get debugMaximumDataSeededMessage => 'زیادہ سے زیادہ ڈیٹا بھر دیا گیا۔';

  @override
  String get debugSeedMaximumDataLabel => 'زیادہ سے زیادہ ڈیٹا بھریں (کارکردگی ٹیسٹ کے لیے)';

  @override
  String get debugRunningInDebugModeLabel => 'ڈیبگ موڈ میں چل رہا ہے';

  @override
  String get deleteAllButton => 'تمام حذف کریں';

  @override
  String get changeButton => 'تبدیل کریں';

  @override
  String get undoButton => 'واپس کریں';

  @override
  String itemDeletedMessage(Object name) {
    return '$name حذف کر دیا گیا';
  }

  @override
  String get totalBalanceLabel => 'کل بیلنس';

  @override
  String get noCurrenciesSelected => 'کوئی کرنسی منتخب نہیں کی گئی۔';

  @override
  String get incomeLabel => 'آمدنی';

  @override
  String get expenseLabel => 'اخراجات';

  @override
  String get failedToLoadDashboard => 'ڈیش بورڈ لوڈ کرنے میں ناکامی';

  @override
  String get dashboardCalendarTab => 'کیلنڈر';

  @override
  String get dashboardCalendarTooltip => 'کیلنڈر ویو';

  @override
  String get dashboardCalendarDescription => 'ترسیلات کو کیلنڈر فارمیٹ میں دیکھیں';

  @override
  String get dashboardCategoriesTab => 'اقسام';

  @override
  String get dashboardCategoriesTooltip => 'اقسام کا تجزیہ';

  @override
  String get dashboardCategoriesDescription => 'قسم کے لحاظ سے اخراجات کی تفصیل';

  @override
  String get dashboardBalanceTab => 'بیلنس';

  @override
  String get dashboardBalanceTooltip => 'بیلنس کی تاریخ';

  @override
  String get dashboardBalanceDescription => 'وقت کے ساتھ کل مالیت کا پتہ لگائیں';

  @override
  String get dashboardExpensesLabel => 'اخراجات';

  @override
  String get dashboardIncomeLabel => 'آمدنی';

  @override
  String get manageIconsTitle => 'آئیکنز کا انتظام کریں';

  @override
  String get noIconsCreated => 'ابھی تک کوئی آئیکن نہیں بنایا گیا۔';

  @override
  String get failedToLoadIcons => 'آئیکنز لوڈ کرنے میں ناکامی۔';

  @override
  String get cannotDeleteTransferIcon => 'منتقلی (Transfer) کا آئیکن حذف نہیں کیا جا سکتا۔';

  @override
  String get deleteIconsDialogTitle => 'آئیکنز حذف کریں';

  @override
  String deleteIconsConfirmationMessage(Object count) {
    return 'کیا آپ واقعی $count منتخب کردہ آئیکنز حذف کرنا چاہتے ہیں؟';
  }

  @override
  String deleteIconsWithSkipTransferMessage(Object count) {
    return 'کیا آپ واقعی $count منتخب کردہ آئیکنز حذف کرنا چاہتے ہیں؟ (منتقلی کا آئیکن نظر انداز کر دیا جائے گا)';
  }

  @override
  String get deleteIconDialogTitle => 'آئیکن حذف کریں';

  @override
  String deleteIconConfirmationMessage(Object name) {
    return 'کیا آپ واقعی \"$name\" کو حذف کرنا چاہتے ہیں؟';
  }

  @override
  String deleteMultipleAccountsTitle(Object count) {
    return '$count اکاؤنٹ حذف کریں؟';
  }

  @override
  String get deleteMultipleAccountsMessage => 'کیا آپ واقعی منتخب کردہ اکاؤنٹس حذف کرنا چاہتے ہیں؟ تمام متعلقہ ترسیلات حذف کر دی جائیں گی۔';

  @override
  String get changeAccountTypeDialogTitle => 'اکاؤنٹ کی قسم تبدیل کریں';

  @override
  String editAccountTitle(Object name) {
    return 'ترمیم: $name';
  }

  @override
  String get balanceCalculatedFromAsset => 'بیلنس اثاثہ کی مقدار * قیمت سے شمار کیا جاتا ہے';

  @override
  String get selectAccountTypeTitle => 'اکاؤنٹ کی قسم منتخب کریں';

  @override
  String get selectCountryTitle => 'ملک منتخب کریں';

  @override
  String get selectIconSubtitle => 'آئیکن منتخب کریں';

  @override
  String get bindToAssetLabel => 'اثاثہ سے منسلک کریں (اختیاری)';

  @override
  String get selectAssetTitle => 'اثاثہ منتخب کریں';

  @override
  String get selectedAssetLabel => 'منتخب کردہ اثاثہ';

  @override
  String get balanceAutoCalculatedLabel => 'بیلنس خود بخود شمار ہوتا ہے';

  @override
  String get tapToBindAssetLabel => 'اثاثہ منسلک کرنے کے لیے تھپتھپائیں';

  @override
  String get assetQuantityLabel => 'اثاثہ کی مقدار';

  @override
  String get linkedAssetsTitle => 'منسلک اثاثے';

  @override
  String get noneLabel => 'کوئی نہیں';

  @override
  String get accountTypeLabel => 'اکاؤنٹ کی قسم';

  @override
  String get formValidationPleaseSelectAccountType => 'براہ کرم اکاؤنٹ کی قسم منتخب کریں';

  @override
  String get iconLabel => 'آئیکن';
}
