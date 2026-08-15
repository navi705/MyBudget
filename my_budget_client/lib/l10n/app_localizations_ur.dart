// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get collapseMenuTooltip => 'مینو سکیڑیں';

  @override
  String get expandMenuTooltip => 'مینو پھیلائیں';

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
  String get editAccountDialogTitle => 'اکاؤنٹ میں ترمیم کریں';

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
  String get selectButton => 'منتخب کریں';

  @override
  String get selectAllButton => 'سب منتخب کریں';

  @override
  String get deselectAllButton => 'سب غیر منتخب کریں';

  @override
  String get deleteSelectedButton => 'منتخب حذف کریں';

  @override
  String totalCountLabel(Object count) {
    return 'کل: $count';
  }

  @override
  String selectedCountLabel(Object count) {
    return '$count منتخب';
  }

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
  String get dashboardNetWorthTrend => 'خالص مالیت کا رجحان';

  @override
  String get dashboardWealthDistributionByAccount => 'دولت کی تقسیم (اکاؤنٹ کے لحاظ سے)';

  @override
  String get dashboardCurrencyExposure => 'کرنسی کی نمائش';

  @override
  String get dashboardNoAccountsFound => 'کوئی اکاؤنٹ نہیں ملا';

  @override
  String get dashboardTotalNetWorthTrend => 'کل خالص مالیت کا رجحان';

  @override
  String get dashboardAccountBalanceTrend => 'اکاؤنٹ بیلنس کا رجحان';

  @override
  String get dashboardWealthDistribution => 'دولت کی تقسیم';

  @override
  String get dashboardCurrencyBreakdown => 'کرنسی کی تفصیل';

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
  String get closeSelectionTooltip => 'انتخاب بند کریں';

  @override
  String get exitSelectionDescription => 'انتخاب موڈ سے باہر نکلیں';

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
  String get exitTransactionsSelectionDescription => 'لین دین کے انتخاب کے موڈ سے باہر نکلیں';

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
  String get amountLabel => 'رقم';

  @override
  String quantityLabel(Object quantity) {
    return 'مقدار: $quantity';
  }

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
  String get addTransactionTitle => 'لین دین شامل کریں';

  @override
  String get editTransactionTitle => 'لین دین میں ترمیم کریں';

  @override
  String get newTransferTitle => 'نیا تبادلہ';

  @override
  String get editTransferTitle => 'تبادلے میں ترمیم کریں';

  @override
  String get descriptionLabel => 'تفصیل';

  @override
  String get descriptionOptionalLabel => 'تفصیل (اختیاری)';

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
  String get themeSettingsTitle => 'تھیم کی ترتیبات';

  @override
  String get appearanceSection => 'ظاہری شکل';

  @override
  String get themeModeLabel => 'تھیم موڈ';

  @override
  String get systemTheme => 'سسٹم';

  @override
  String get lightTheme => 'ہلکا (Light)';

  @override
  String get darkTheme => 'تاریک (Dark)';

  @override
  String get colorCustomizationSection => 'رنگوں کی تخصیص';

  @override
  String get primaryColorLabel => 'بنیادی رنگ';

  @override
  String get secondaryColorLabel => 'ثانوی رنگ';

  @override
  String get surfaceColorLabel => 'سطحی رنگ';

  @override
  String get windowEffectsSection => 'ونڈو اثرات (ڈیسک ٹاپ)';

  @override
  String get enableEffectsLabel => 'ونڈو اثرات فعال کریں';

  @override
  String get windowEffectLabel => 'ونڈو اثر';

  @override
  String get backgroundLabel => 'پس منظر';

  @override
  String get removeBackgroundColor => 'پس منظر کا رنگ ہٹائیں';

  @override
  String get transparentSurfaceLabel => 'شفاف سطح (کارڈز)';

  @override
  String get fullyTransparentLabel => 'مکمل شفاف';

  @override
  String get opaqueLabel => 'غیر شفاف';

  @override
  String opacityLabel(Object value) {
    return 'شفافیت: $value%';
  }

  @override
  String get backgroundSettingsSection => 'پس منظر کی ترتیبات';

  @override
  String get enableBackgroundImageLabel => 'پس منظر کی تصویر فعال کریں';

  @override
  String get backgroundBlurLabel => 'پس منظر کا دھندلا پن';

  @override
  String get surfaceGlassStyleTitle => 'سطح/شیشے کا انداز';

  @override
  String get chooseImageButton => 'تصویر منتخب کریں';

  @override
  String get selectImageFileError => 'براہ کرم ایک تصویر فائل منتخب کریں۔';

  @override
  String get clearImageButton => 'تصویر صاف کریں';

  @override
  String get saveThemePresetTitle => 'تھیم پیش سیٹ محفوظ کریں';

  @override
  String get presetNameLabel => 'پیش سیٹ کا نام';

  @override
  String get presetNameHint => 'میرا زبردست تھیم';

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
  String get apiManagementTitle => 'API مینجمنٹ';

  @override
  String apiErrorLabel(String error) {
    return 'خرابی: $error';
  }

  @override
  String apiLastFetchLabel(String date) {
    return 'تاریخ: $date';
  }

  @override
  String get apiCategoriesSection => 'API زمرہ جات';

  @override
  String get manualUtilitiesSection => 'دستی یوٹیلیٹیز';

  @override
  String get startupDataSyncLabel => 'اسٹارٹ اپ پر ڈیٹا کی مطابقت پذیری';

  @override
  String get startupDataSyncDescription => 'ایپ لانچ پر بیرونی ڈیٹا کی بازیافت اور سرور کی مطابقت پذیری دونوں کو کنٹرول کرتا ہے۔';

  @override
  String get standardApiLabel => 'معیاری API';

  @override
  String get syncOnStartupDescription => 'اسٹارٹ اپ پر مطابقت پذیری کریں';

  @override
  String get customSourcesLabel => 'حسب ضرورت ذرائع';

  @override
  String syncCustomSourcesDescription(Object count) {
    return 'اسٹارٹ اپ پر تمام ($count) کی مطابقت پذیری کریں';
  }

  @override
  String get individualCustomSourcesTitle => 'انفرادی حسب ضرورت ذرائع';

  @override
  String get noCustomSourcesAdded => 'کوئی حسب ضرورت ذریعہ شامل نہیں کیا گیا۔';

  @override
  String get fetchTodaysRatesButton => 'آج کی شرحیں حاصل کریں';

  @override
  String get inflationConfigTitle => 'افراط زر کی ترتیب';

  @override
  String get countryCodeHint => 'ملک کا کوڈ (مثلاً SRB)';

  @override
  String fetchDataForCountryButton(Object country) {
    return '$country کے لیے ڈیٹا حاصل کریں';
  }

  @override
  String get steamSettingsTitle => 'Steam ترتیبات';

  @override
  String get steamIdLabel => 'Steam ID (64-bit)';

  @override
  String get steamIdHint => 'مثلاً 76561198085715972';

  @override
  String get preferredGameLabel => 'پسندیدہ گیم';

  @override
  String get fetchInventoryNowButton => 'انوینٹری ابھی حاصل کریں';

  @override
  String get manualExchangeRatesTitle => 'شرح تبادلہ کی دستی بازیافت';

  @override
  String get selectStartDate => 'شروع کی تاریخ منتخب کریں';

  @override
  String startDateFrom(Object date) {
    return 'سے: $date';
  }

  @override
  String get selectEndDate => 'ختم ہونے کی تاریخ منتخب کریں';

  @override
  String endDateTo(Object date) {
    return 'تک: $date';
  }

  @override
  String get fetchRangeButton => 'رینج حاصل کریں';

  @override
  String get manualSteamInventoryTitle => 'دستی Steam انوینٹری';

  @override
  String get selectGameHint => 'گیم منتخب کریں';

  @override
  String get fetchValueButton => 'قدر حاصل کریں';

  @override
  String get manualInflationDataTitle => 'دستی افراط زر کا ڈیٹا';

  @override
  String get selectStartYear => 'شروع کا سال منتخب کریں';

  @override
  String startYearFrom(Object year) {
    return 'سے: $year';
  }

  @override
  String get selectEndYear => 'ختم ہونے کا سال منتخب کریں';

  @override
  String endYearTo(Object year) {
    return 'تک: $year';
  }

  @override
  String get fetchDataButton => 'ڈیٹا حاصل کریں';

  @override
  String get connectionOk => 'کنکشن ٹھیک ہے';

  @override
  String get connectionFailed => 'کنکشن ناکام ہوگیا';

  @override
  String get testConnectionButton => 'کنکشن ٹیسٹ کریں';

  @override
  String get editCustomSourceTitle => 'حسب ضرورت ذریعہ میں ترمیم کریں';

  @override
  String get addCustomSourceTitle => 'حسب ضرورت ذریعہ شامل کریں';

  @override
  String get addressFormatsHelp => 'ایڈریس فارمیٹ:\n• 192.168.1.10 (IP)\n• localhost یا api.my.com\n• http://myserver.com';

  @override
  String get customSourceNameHint => 'میرا ہوم سرور';

  @override
  String get urlIpLabel => 'URL / IP';

  @override
  String get urlIpHint => '192.168.1.10:8080';

  @override
  String get dataTypeLabel => 'ڈیٹا کی قسم';

  @override
  String get apiTitleExchangeRates => 'شرح تبادلہ';

  @override
  String get apiTitleInflation => 'افراط زر';

  @override
  String get apiTitleAssetPrices => 'اثاثوں کی قیمتیں';

  @override
  String get apiTitleSteamInventory => 'Steam انوینٹری';

  @override
  String get transferLabel => 'منتقلی';

  @override
  String get uncategorizedLabel => 'بغیر کسی زمرے کے';

  @override
  String get defaultLabel => 'ڈیفالٹ';

  @override
  String receivedTotalLabel(Object total) {
    return 'وصول شدہ: $total';
  }

  @override
  String spentTotalLabel(Object total) {
    return 'خرچ شدہ: $total';
  }

  @override
  String get periodSummaryTitle => 'مدت کا خلاصہ';

  @override
  String get incomeLabel => 'آمدنی';

  @override
  String get expenseLabel => 'اخراجات';

  @override
  String get netLabel => 'کل منافع/نقصان';

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
  String get failedToLoadDashboard => 'ڈیش بورڈ لوڈ کرنے میں ناکامی';

  @override
  String get dashboardCalendarTab => 'کیلنڈر';

  @override
  String get dashboardTabCalendar => 'کیلنڈر';

  @override
  String get dashboardCalendarTooltip => 'کیلنڈر ویو';

  @override
  String get dashboardCalendarDescription => 'ترسیلات کو کیلنڈر فارمیٹ میں دیکھیں';

  @override
  String get dashboardCategoriesTab => 'اقسام';

  @override
  String get dashboardTabCategories => 'اقسام';

  @override
  String get dashboardCategoriesTooltip => 'اقسام کا تجزیہ';

  @override
  String get dashboardCategoriesDescription => 'قسم کے لحاظ سے اخراجات کی تفصیل';

  @override
  String get dashboardBalanceTab => 'بیلنس';

  @override
  String get dashboardTabBalance => 'بیلنس';

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
  String get manageStylesDeleteTitle => 'آئیکنز حذف کریں';

  @override
  String manageStylesDeleteConfirm(Object count) {
    return 'کیا آپ واقعی $count منتخب کردہ آئیکنز حذف کرنا چاہتے ہیں؟';
  }

  @override
  String manageStylesDeleteConfirmWithTransfer(Object count) {
    return 'کیا آپ واقعی $count منتخب کردہ آئیکنز حذف کرنا چاہتے ہیں؟ (تبادلہ آئیکن کو چھوڑ دیا جائے گا)';
  }

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

  @override
  String get languageLabel => 'زبان';

  @override
  String get systemDefaultLabel => 'سسٹم ڈیفالٹ';

  @override
  String get selectLanguageTitle => 'زبان منتخب کریں';

  @override
  String get dashboardLabel => 'ڈیش بورڈ';

  @override
  String get homeLabel => 'ہوم';

  @override
  String get historyLabel => 'تاریخ';

  @override
  String get syncScreenTitle => 'مطابقت پذیری کی ترتیبات';

  @override
  String get syncP2PSection => 'P2P مطابقت پذیری (Syncthing)';

  @override
  String get syncEnableP2P => 'P2P مطابقت پذیری فعال کریں';

  @override
  String get syncP2PSubtitle => 'مشترکہ فولڈر میں .sync فائلوں کے ذریعے مطابقت پذیری کریں';

  @override
  String get syncFolderLabel => 'مطابقت پذیری فولڈر';

  @override
  String get syncFolderNotSelected => 'منتخب نہیں کیا گیا';

  @override
  String get syncBrowseButton => 'براؤز کریں';

  @override
  String get syncClearFilesButton => 'مطابقت پذیری فائلیں صاف کریں';

  @override
  String get syncServerSection => 'کلاؤڈ مطابقت پذیری (سرور)';

  @override
  String get syncServerUrlLabel => 'سرور URL';

  @override
  String get syncApiTokenLabel => 'API ٹوکن';

  @override
  String get syncApiTokenHint => 'اپنا سیکیورٹی ٹوکن درج کریں';

  @override
  String get syncApiTokenHelp => 'یہ ٹوکن آپ کا مشترکہ راز ہے۔ مطابقت پذیری کی اجازت دینے کے لیے اپنے تمام آلات پر ایک ہی ویلیو درج کریں۔';

  @override
  String get syncTestConnectionButton => 'کنکشن ٹیسٹ کریں';

  @override
  String get syncTestingLabel => 'ٹیسٹنگ...';

  @override
  String get syncSaveServerSettingsButton => 'سرور کی ترتیبات محفوظ کریں';

  @override
  String get syncEnableServer => 'سرور کی مطابقت پذیری فعال کریں';

  @override
  String get syncServerSubtitle => 'MyBudget Server کے انسٹنس کے ساتھ مطابقت پذیری کریں';

  @override
  String get syncPendingLocalChanges => 'زیر التواء مقامی تبدیلیاں:';

  @override
  String get syncSyncNowButton => 'ابھی مطابقت پذیری کریں';

  @override
  String get syncSyncingLabel => 'مطابقت پذیری ہو رہی ہے...';

  @override
  String get syncWebNotAvailable => 'ویب پر مطابقت پذیری دستیاب نہیں ہے';

  @override
  String get syncPermissionRequired => 'مطابقت پذیری کے لیے اسٹوریج کی اجازت درکار ہے۔ براہ کرم ترتیبات میں \"تمام فائلوں تک رسائی\" کو فعال کریں۔';

  @override
  String get syncSelectFolderTitle => 'Syncthing فولڈر منتخب کریں';

  @override
  String get syncClearFilesTitle => 'مطابقت پذیری فائلیں صاف کریں';

  @override
  String get syncClearFilesConfirm => 'یہ منتخب کردہ فولڈر سے تمام .sync فائلیں حذف کر دے گا۔ اسے واپس نہیں لیا جا سکتا۔';

  @override
  String syncDeletedFilesCount(Object count) {
    return '$count مطابقت پذیری فائلیں حذف کر دی گئیں';
  }

  @override
  String syncClearFilesError(Object error) {
    return 'فائلیں صاف کرنے میں خرابی: $error';
  }

  @override
  String get syncSettingsSaved => 'سرور کی ترتیبات محفوظ ہو گئیں';

  @override
  String get syncConnectionSuccessful => 'کنکشن کامیاب رہا!';

  @override
  String get syncConnectionFailed => 'کنکشن ناکام ہوگیا۔ URL اور ٹوکن چیک کریں۔';

  @override
  String get syncConnectionUnauthorized => 'سرور نے ٹوکن مسترد کر دیا۔ پتہ نہیں، ٹوکن جانچیں۔';

  @override
  String get syncServerNotConfigured => 'سرور پر کوئی سنک ٹوکن ترتیب نہیں دیا گیا، اس لیے وہ تمام ڈیوائسز مسترد کر رہا ہے۔ سرور پر SYNC_TOKEN مقرر کریں اور یہاں وہی قدر استعمال کریں۔';

  @override
  String get syncCompleted => 'مطابقت پذیری کامیابی سے مکمل ہوگئی';

  @override
  String syncFailed(Object error) {
    return 'مطابقت پذیری ناکام ہوگئی: $error';
  }

  @override
  String get smsRuleAddTitle => 'اصول (Rule) شامل کریں';

  @override
  String get smsRuleEditTitle => 'اصول میں ترمیم کریں';

  @override
  String get smsRuleTransactionType => 'ٹرانزیکشن کی قسم';

  @override
  String get smsRuleMatchPattern => 'میچ پیٹرن (Regex)';

  @override
  String get smsRuleMatchPatternHint => 'مثلاً: کارڈ کے ذریعے ادائیگی';

  @override
  String get smsRuleMatchPatternHelp => 'اس قسم کے ایس ایم ایس کی شناخت کرنے کے لیے پیٹرن';

  @override
  String get smsRuleAmountPattern => 'رقم کا پیٹرن (Regex)';

  @override
  String get smsRuleAmountPatternHint => 'مثلاً: رقم\\s+([\\d,.]+)';

  @override
  String get smsRuleAmountPatternHelp => 'گروپ 1 کو رقم کو کیپچر کرنا چاہیے';

  @override
  String get smsRuleCurrencyPattern => 'کرنسی کا پیٹرن (Regex، اختیاری)';

  @override
  String get smsRuleCurrencyPatternHint => 'مثلاً: [\\d,.]+\\s*(\\w\\w\\w)';

  @override
  String get smsRuleCurrencyPatternHelp => 'گروپ 1 کو کرنسی کوڈ کو کیپچر کرنا چاہیے';

  @override
  String get smsRuleTestTitle => 'اپنے اصول کی جانچ کریں';

  @override
  String get smsRuleTestSmsHint => 'ایس ایم ایس ٹیکسٹ یہاں پیسٹ کریں';

  @override
  String get smsRuleTestButton => 'پیٹرن کی جانچ کریں';

  @override
  String get smsRuleTestEnterSmsError => 'ٹیسٹ کے لیے ایس ایم ایس ٹیکسٹ درج کریں';

  @override
  String get smsRuleTestMatchError => '✗ میچ پیٹرن کا کوئی نتیجہ نہیں ملا';

  @override
  String get smsRuleTestAmountError => '✗ رقم کے پیٹرن کا کوئی نتیجہ نہیں ملا';

  @override
  String smsRuleTestSuccess(Object amount, Object currency, Object type) {
    return '✓ میچ مل گیا!\nقسم: $type\nرقم: $amount\nکرنسی: $currency';
  }

  @override
  String smsRuleTestRegexError(Object error) {
    return '✗ غلط Regex: $error';
  }

  @override
  String get smsRuleRequiredError => 'میچ پیٹرن اور رقم کے پیٹرن درکار ہیں';

  @override
  String inflationError(Object error) {
    return 'خرابی: $error';
  }

  @override
  String get inflationNoRatesFound => 'افراط زر کی شرح نہیں ملی۔';

  @override
  String get inflationAddRate => 'افراط زر کی شرح شامل کریں';

  @override
  String get inflationDeleteConfirmTitle => 'شرحیں حذف کریں؟';

  @override
  String inflationDeleteConfirmMessage(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ان $count شرحوں',
      one: 'اس شرح',
    );
    return 'کیا آپ واقعی $_temp0 کو حذف کرنا چاہتے ہیں؟';
  }

  @override
  String inflationSelectedCount(Object count) {
    return '$count منتخب کردہ';
  }

  @override
  String get inflationFiltersTitle => 'افراط زر کے فلٹرز';

  @override
  String get inflationCountries => 'ممالک';

  @override
  String get inflationPresets => 'پیش سیٹ';

  @override
  String deleteCategoryConfirmTitle(Object name) {
    return '\"$name\" حذف کریں؟';
  }

  @override
  String get deleteCategoryMessage => 'اس زمرے میں متعلقہ ترسیلات موجود ہیں۔ آپ کیا کرنا چاہیں گے؟';

  @override
  String get deleteCategoryReassign => 'ترسیلات دوسرے زمرے میں منتقل کریں';

  @override
  String get deleteCategoryNewCategory => 'نیا زمرہ';

  @override
  String get deleteCategoryDeleteAll => 'تمام متعلقہ ترسیلات حذف کریں';

  @override
  String deleteAccountConfirmTitle(Object name) {
    return '\"$name\" حذف کریں؟';
  }

  @override
  String get deleteAccountMessage => 'اس اکاؤنٹ میں متعلقہ ترسیلات موجود ہوسکتی ہیں۔ آپ کیا کرنا چاہیں گے؟';

  @override
  String get deleteAccountReassign => 'ترسیلات دوسرے اکاؤنٹ میں منتقل کریں';

  @override
  String get deleteAccountNewAccount => 'نیا اکاؤنٹ';

  @override
  String get deleteAccountDeleteAll => 'تمام متعلقہ ترسیلات حذف کریں';

  @override
  String get confirmButton => 'تصدیق کریں';

  @override
  String get okButton => 'ٹھیک ہے';

  @override
  String get noItemsFound => 'کوئی آئٹم نہیں ملا۔';

  @override
  String get noDataForPeriod => 'اس مدت کے لیے کوئی ڈیٹا نہیں ہے';

  @override
  String get noDataForRange => 'اس رینج کے لیے کوئی ڈیٹا نہیں ہے';

  @override
  String get noHistoryData => 'تاریخ کا کوئی ڈیٹا دستیاب نہیں ہے';

  @override
  String get disabledByGlobalSync => 'عالمی مطابقت پذیری کی وجہ سے معطل ہے';

  @override
  String dateCreatedLabel(Object date) {
    return 'تخلیق کی تاریخ: $date';
  }

  @override
  String get anyLabel => 'کوئی بھی';

  @override
  String get balanceDisplayLabel => 'بیلنس ڈسپلے';

  @override
  String currenciesActiveLabel(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فعال کرنسیاں',
      one: '1 فعال کرنسی',
    );
    return '$_temp0';
  }

  @override
  String get searchCountryLabel => 'ملک تلاش کریں';

  @override
  String get addNewIconLabel => 'نیا آئیکن شامل کریں';

  @override
  String get noIconsFoundLabel => 'کوئی آئیکن نہیں ملا';

  @override
  String get addNewStyleLabel => 'نیا اسٹائل شامل کریں';

  @override
  String get styleNameLabel => 'اسٹائل کا نام';

  @override
  String get pleaseEnterStyleName => 'براہ کرم اسٹائل کا نام درج کریں';

  @override
  String get colorLabel => 'رنگ';

  @override
  String get netBalanceMetric => 'خالص بیلنس';

  @override
  String get investedMetric => 'سرمایہ کاری';

  @override
  String get realizedMetric => 'حصول شدہ';

  @override
  String get feesMetric => 'فیس/ٹیکس';

  @override
  String get persistFiltersLabel => 'فلٹرز برقرار رکھیں';

  @override
  String get searchByNameHint => 'نام سے تلاش کریں...';

  @override
  String get searchDescriptionHint => 'تفصیل سے تلاش کریں...';

  @override
  String get advancedFiltersTitle => 'اعلی درجے کے فلٹرز';

  @override
  String get transactionTypeLabel => 'ترسیل کی قسم';

  @override
  String get assetFiltersTitle => 'اثاثہ کے فلٹرز';

  @override
  String get minValueLabel => 'کم از کم قیمت';

  @override
  String get maxValueLabel => 'زیادہ سے زیادہ قیمت';

  @override
  String get assetTypesLabel => 'اثاثہ کی اقسام';

  @override
  String get allLabel => 'تمام';

  @override
  String get currenciesLabel => 'کرنسیاں';

  @override
  String get sourcesLabel => 'ذرائع';

  @override
  String get presetsLabel => 'پیش سیٹ';

  @override
  String get enterCategoryNameHint => 'زمرہ کا نام درج کریں';

  @override
  String get selectTypeHint => 'قسم منتخب کریں';

  @override
  String get hotKeysTitle => 'ہاٹ کیز';

  @override
  String get searchHotkeysHint => 'ہاٹ کیز تلاش کریں...';

  @override
  String get noMatchingHotkeys => 'کوئی مماثل ہاٹ کی نہیں ملی۔';

  @override
  String recordingHotkeyTitle(Object label) {
    return '录制 \"$label\" کے لیے ہاٹ کی ریکارڈ کی جا رہی ہے';
  }

  @override
  String get pressKeysHint => 'کلیدیں دبائیں...';

  @override
  String get pressAnyCombinationHint => 'کسی بھی کلید کا مجموعہ دبائیں۔';

  @override
  String get clearSaveButton => 'صاف کریں / محفوظ کریں';

  @override
  String get duplicateHotkeyTooltip => 'ڈپلیکیٹ ہاٹ کی';

  @override
  String usedByLabel(Object action) {
    return '$action کی طرف سے استعمال کیا جاتا ہے';
  }

  @override
  String get hkCategoryNavigation => 'نیویگیشن';

  @override
  String get hkCategoryDashboardTabs => 'ڈیش بورڈ ٹیبز';

  @override
  String get hkCategoryDataTabs => 'ڈیٹا ٹیبز';

  @override
  String get hkCategoryPeriodControl => 'مدت کا کنٹرول';

  @override
  String get hkCategoryActions => 'اقدامات';

  @override
  String get hkCategorySelectionMode => 'سلیکشن موڈ';

  @override
  String get hkActionBack => 'عالمی: واپس / باہر نکلیں';

  @override
  String get hkActionDashboard => 'ڈیش بورڈ پر جائیں';

  @override
  String get hkActionAccounts => 'اکاؤنٹس پر جائیں';

  @override
  String get hkActionTransactions => 'ترسیلات پر جائیں';

  @override
  String get hkActionCategories => 'زمرہ جات پر جائیں';

  @override
  String get hkActionData => 'ڈیٹا / شرحوں پر جائیں';

  @override
  String get hkActionSettings => 'ترتیبات پر جائیں';

  @override
  String get hkActionDashboardTab1 => 'کیلنڈر ٹیب';

  @override
  String get hkActionDashboardTab2 => 'زمرہ جاب ٹیب';

  @override
  String get hkActionDashboardTab3 => 'بیلنس ٹیب';

  @override
  String get hkActionDataTab1 => 'شرح تبادلہ';

  @override
  String get hkActionDataTab2 => 'افراط زر';

  @override
  String get hkActionDataTab3 => 'اثاثے';

  @override
  String get hkActionPrevPeriod => 'پچھلی مدت';

  @override
  String get hkActionNextPeriod => 'اگلی مدت';

  @override
  String get hkActionAddAction => 'عام شامل کرنے کا عمل';

  @override
  String get hkActionPickDate => 'تاریخ منتخب کریں';

  @override
  String get hkActionDashboardSwitchView => 'ڈیش بورڈ: ویو تبدیل کریں';

  @override
  String get hkActionSortOrder => 'ترتیب دیں';

  @override
  String get hkActionFilterAction => 'فلٹر';

  @override
  String get hkActionDashboardCurrency => 'ڈیش بورڈ: کرنسی';

  @override
  String get hkActionAccountsSelectionClose => 'اکاؤنٹس: بند کریں';

  @override
  String get hkActionAccountsSelectionAll => 'اکاؤنٹس: سب منتخب کریں';

  @override
  String get hkActionAccountsSelectionDelete => 'اکاؤنٹس: حذف کریں';

  @override
  String get hkActionAccountsSelectionChangeType => 'اکاؤنٹس: قسم تبدیل کریں';

  @override
  String get hkActionTransactionsSelectionClose => 'ترسیلات: بند کریں';

  @override
  String get hkActionTransactionsSelectionDelete => 'ترسیلات: حذف کریں';

  @override
  String get hkActionTransactionsSelectionChangeDate => 'ترسیلات: تاریخ تبدیل کریں';

  @override
  String get hkActionTransactionsSelectionChangeCategory => 'ترسیلات: زمرہ تبدیل کریں';

  @override
  String get hkActionCategoriesSelectionClose => 'زمرہ جات: بند کریں';

  @override
  String get hkActionCategoriesSelectionAll => 'زمرہ جات: سب منتخب کریں';

  @override
  String get hkActionCategoriesSelectionDelete => 'زمرہ جات: حذف کریں';

  @override
  String get hkActionCategoriesSelectionChangeType => 'زمرہ جات: قسم تبدیل کریں';

  @override
  String get hkActionDataSelectionClose => 'شرح تبادلہ: بند کریں';

  @override
  String get hkActionDataSelectionAll => 'شرح تبادلہ: سب منتخب کریں';

  @override
  String get hkActionDataSelectionDelete => 'شرح تبادلہ: حذف کریں';

  @override
  String get hkActionDataSelectionChangePreset => 'شرح تبادلہ: پیش سیٹ تبدیل کریں';

  @override
  String get hkActionInflationSelectionClose => 'افراط زر: بند کریں';

  @override
  String get hkActionInflationSelectionAll => 'افراط زر: سب منتخب کریں';

  @override
  String get hkActionInflationSelectionDelete => 'افراط زر: حذف کریں';

  @override
  String get hkActionAssetSelectionClose => 'اثاثے: بند کریں';

  @override
  String get hkActionAssetSelectionAll => 'اثاثے: سب منتخب کریں';

  @override
  String get hkActionAssetSelectionDelete => 'اثاثے: حذف کریں';

  @override
  String get styNotFound => 'اسٹائل نہیں ملا۔';

  @override
  String get stySaveChanges => 'تبدیلیاں محفوظ کریں';

  @override
  String get styAddIcon => 'آئیکن شامل کریں';

  @override
  String get smsOnlyAndroid => 'ایس ایم ایس درآمد صرف Android پر دستیاب ہے';

  @override
  String get smsImportSms => 'ایس ایم ایس درآمد کریں';

  @override
  String get smsPermissionRequired => 'ایس ایم ایس کی اجازت درکار ہے';

  @override
  String get smsPermissionRationale => 'ایس ایم ایس سے لین دین درآمد کرنے کے لیے، ہمیں آپ کے پیغامات پڑھنے کی اجازت درکار ہے۔';

  @override
  String get smsGrantPermission => 'اجازت دیں';

  @override
  String get smsNoPresets => 'کوئی پیش سیٹ ترتیب نہیں دیا گیا۔ شامل کرنے کے لیے + دبائیں۔';

  @override
  String get smsImportDescription => 'ایس ایم ایس پیغامات سے لین دین درآمد کریں۔ ایک مدت منتخب کریں:';

  @override
  String get smsLast7Days => 'پچھلے 7 دن';

  @override
  String get smsAllTime => 'تمام وقت';

  @override
  String smsFilterLabel(Object filter) {
    return 'فلٹر: $filter';
  }

  @override
  String get smsEditPreset => 'پیش سیٹ میں ترمیم کریں';

  @override
  String get smsNewPreset => 'نیا پیش سیٹ';

  @override
  String get smsPresetNameHint => 'مثلاً: میرا بینک';

  @override
  String get smsSenderFilter => 'بھیجنے والے کا فلٹر';

  @override
  String get smsSenderFilterHint => 'مثلاً: ALTA یا +381...';

  @override
  String get smsSenderFilterHelper => 'بھیجنے والے کے نام یا فون نمبر سے ایس ایم ایس فلٹر کریں';

  @override
  String get smsDefaults => 'ڈیفالٹ';

  @override
  String get smsDefaultAccount => 'ڈیفالٹ اکاؤنٹ';

  @override
  String get smsDefaultCategory => 'ڈیفالٹ زمرہ';

  @override
  String get smsImportMessages => 'پیغامات درآمد کریں';

  @override
  String get smsSelectDefaultsFirst => 'پہلے ڈیفالٹ منتخب کریں';

  @override
  String get smsCustomRange => 'حسب ضرورت رینج';

  @override
  String smsImportSuccessCount(Object count) {
    return 'کامیاب: $count لین دین درآمد ہوئے';
  }

  @override
  String get smsParsingRules => 'تجزیہ کے اصول';

  @override
  String get smsNoRules => 'کوئی اصول متعین نہیں۔ شامل کرنے کے لیے + دبائیں۔';

  @override
  String smsMatchLabel(Object pattern) {
    return 'میچ: $pattern';
  }

  @override
  String get smsNameSenderRequired => 'نام اور بھیجنے والے کا فلٹر درکار ہیں';

  @override
  String get smsCategoryKeywords => 'زمرہ کے کلیدی الفاظ';

  @override
  String get smsCategoryKeywordsSubtitle => 'ایس ایم ایس متن کے کلیدی الفاظ کو زمروں سے جوڑیں';

  @override
  String get smsNoKeywordRules => 'کوئی کلیدی لفظ کا اصول نہیں۔ شامل کرنے کے لیے + دبائیں۔';

  @override
  String get smsAddKeywordRule => 'کلیدی لفظ کا اصول شامل کریں';

  @override
  String get smsKeyword => 'کلیدی لفظ';

  @override
  String get smsKeywordHint => 'مثلاً: گروسری، Netflix';

  @override
  String get smsKeywordHelper => 'ایس ایم ایس متن میں ملانے کے لیے حروف سے بے نیاز جزوی لفظ';

  @override
  String get smsSelectCategoryHint => 'زمرہ منتخب کریں';

  @override
  String get dshSelectDateDescription => 'مخصوص تاریخ یا رینج منتخب کرنے کے لیے کیلنڈر کھولیں';

  @override
  String get dshCurrencyDescription => 'ڈسپلے کے لیے بنیادی کرنسی منتخب کریں';

  @override
  String get dshChangeViewTooltip => 'ویو تبدیل کریں';

  @override
  String get dshChangeViewDescription => 'ماہانہ اور سالانہ ویو کے درمیان سوئچ کریں';

  @override
  String get dshMonthlyAbbreviation => 'م';

  @override
  String get dshYearlyAbbreviation => 'س';

  @override
  String dshBalancesOnDate(Object date) {
    return '$date کے بیلنس';
  }

  @override
  String get dshSearchCurrency => 'کرنسی تلاش کریں';

  @override
  String get dshUnknownCategory => 'نامعلوم';

  @override
  String get pckSelectItem => 'آئٹم منتخب کریں';

  @override
  String get pckSelectItems => 'آئٹمز منتخب کریں';

  @override
  String get pckClearAll => 'سب صاف کریں';

  @override
  String get pckSelectIcon => 'آئیکن منتخب کریں';

  @override
  String get pckMaterialIcons => 'Material آئیکنز';

  @override
  String get pckCustomIcons => 'حسب ضرورت آئیکنز';

  @override
  String get fltAmountFrom => 'رقم سے';

  @override
  String get fltAmountTo => 'رقم تک';

  @override
  String get fltSelectRange => 'رینج منتخب کریں';

  @override
  String get fltAdvancedFilterTooltip => 'اعلی درجے کا فلٹر';

  @override
  String get fltAdvancedFilterDescription => 'اکاؤنٹ، زمرہ یا رقم کے لحاظ سے لین دین فلٹر کریں';

  @override
  String get fltSortOrderDescription => 'صعودی اور نزولی ترتیب کے درمیان سوئچ کریں';

  @override
  String get fltAccountFiltersTitle => 'اکاؤنٹ کے فلٹرز';

  @override
  String get fltNameLabel => 'نام';

  @override
  String get fltAccountTypesLabel => 'اکاؤنٹ کی اقسام';

  @override
  String get fltFilterCurrenciesLabel => 'کرنسیاں فلٹر کریں';

  @override
  String get fltSelectCurrenciesLabel => 'کرنسیاں منتخب کریں';

  @override
  String get fltFilterCategoriesTitle => 'زمرہ جات فلٹر کریں';

  @override
  String get exchAddExchangeRate => 'شرح تبادلہ شامل کریں';

  @override
  String get exchEditExchangeRate => 'شرح تبادلہ میں ترمیم کریں';

  @override
  String get exchAddRateDescription => 'دو کرنسیوں کے درمیان تبادلے کی شرح دستی طور پر درج کریں';

  @override
  String get exchNoRatesFound => 'کوئی شرح تبادلہ نہیں ملی۔';

  @override
  String get exchChangePreset => 'پیش سیٹ تبدیل کریں';

  @override
  String get exchFromCurrency => 'کرنسی سے';

  @override
  String get exchToCurrency => 'کرنسی میں';

  @override
  String get exchRate => 'شرح';

  @override
  String get exchPresetIdLabel => 'پیش سیٹ آئی ڈی';

  @override
  String exchPresetValue(Object preset) {
    return 'پیش سیٹ: $preset';
  }

  @override
  String get exchSelectRange => 'رینج منتخب کریں';

  @override
  String get exchPreviousPeriodDescription => 'پچھلے دن، مہینے یا سال پر جائیں';

  @override
  String get exchNextPeriodDescription => 'اگلے دن، مہینے یا سال پر جائیں';

  @override
  String get exchFilterDescription => 'کرنسی سے/تک اور پیش سیٹ آئی ڈی کے لحاظ سے شرحیں فلٹر کریں';

  @override
  String get exchSelectDateDescription => 'تاریخی شرحیں دیکھنے کے لیے مخصوص تاریخ یا رینج منتخب کریں';

  @override
  String get exchSortOrderDescription => 'تاریخ/شرح کی صعودی اور نزولی ترتیب کے درمیان سوئچ کریں';

  @override
  String get exchFilterExchangeRates => 'شرح تبادلہ فلٹر کریں';

  @override
  String get exchExitSelectionDescription => 'شرح تبادلہ کے انتخاب کے موڈ سے باہر نکلیں';

  @override
  String get exchSelectAllDescription => 'درج تمام شرح تبادلہ منتخب کریں';

  @override
  String get exchDeselectAllDescription => 'تمام شرحیں غیر منتخب کریں';

  @override
  String get exchChangePresetDescription => 'تمام منتخب شرح تبادلہ کے لیے پیش سیٹ آئی ڈی اپ ڈیٹ کریں';

  @override
  String get exchDeleteSelectedDescription => 'تمام منتخب شرح تبادلہ مستقل طور پر حذف کریں';

  @override
  String get exchDeleteExchangeRatesTitle => 'شرح تبادلہ حذف کریں';

  @override
  String exchDeleteConfirmMessage(Object count) {
    return 'کیا آپ واقعی $count شرح تبادلہ حذف کرنا چاہتے ہیں؟';
  }

  @override
  String get exchUpdatePresetTitle => 'پیش سیٹ اپ ڈیٹ کریں';

  @override
  String get exchUpdatePresetMessage => 'منتخب آئٹمز کے لیے نئی پیش سیٹ آئی ڈی درج کریں:';

  @override
  String dashboardUnconvertibleCurrencies(String currencies) {
    return '$currencies کو تبدیل نہیں کیا جا سکا، اس لیے یہ رقوم کل میں شامل نہیں ہیں';
  }

  @override
  String get addAccountBeforeTransactionDescription => 'لین دین کے لیے اکاؤنٹ ضروری ہے۔ شروع کرنے کے لیے پہلا اکاؤنٹ بنائیں';

  @override
  String get selectDialogEmptyState => 'ابھی منتخب کرنے کے لیے کچھ نہیں ہے';

  @override
  String get selectDialogNoMatches => 'آپ کی تلاش سے کوئی چیز مطابقت نہیں رکھتی';

  @override
  String get addButton => 'شامل کریں';

  @override
  String get retryButton => 'دوبارہ کوشش کریں';

  @override
  String get unknownLabel => 'نامعلوم';

  @override
  String get globalLabel => 'عالمی';

  @override
  String dateWithValueLabel(String date) {
    return 'تاریخ: $date';
  }

  @override
  String selectColorTitle(String label) {
    return '$label رنگ منتخب کریں';
  }

  @override
  String get assetAddTitle => 'اثاثے کا ڈیٹا شامل کریں';

  @override
  String get assetEditTitle => 'اثاثے کا ڈیٹا ترمیم کریں';

  @override
  String get assetAddDescription => 'کسی مخصوص اثاثے کی قیمت یا مقدار درج کریں';

  @override
  String get assetNameLabel => 'اثاثے کا نام (مثلاً ایپل اسٹاک)';

  @override
  String get assetIdLabel => 'اثاثے کی شناخت (مثلاً AAPL)';

  @override
  String get assetValueLabel => 'قیمت (فی یونٹ)';

  @override
  String get assetTypeOptionalLabel => 'اثاثے کی قسم (اختیاری)';

  @override
  String get assetLinkedAccountOptionalLabel => 'منسلک اکاؤنٹ (اختیاری)';

  @override
  String get assetNameRequiredError => 'اثاثے کو ایک نام دیں';

  @override
  String get assetIdRequiredError => 'اثاثے کے لیے شناخت درج کریں، مثلاً AAPL';

  @override
  String get assetValueInvalidError => 'ایک عدد درج کریں، مثلاً 150.25';

  @override
  String get assetNoAssetsFound => 'کوئی اثاثہ نہیں ملا۔';

  @override
  String assetError(String error) {
    return 'خرابی: $error';
  }

  @override
  String get assetDeleteConfirmTitle => 'اثاثے حذف کریں؟';

  @override
  String assetDeleteConfirmMessage(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
      
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ان $countString اثاثوں',
      one: 'اس اثاثے',
    );
    return 'کیا آپ واقعی $_temp0 کو حذف کرنا چاہتے ہیں؟';
  }

  @override
  String get assetDeleteSelectedDescription => 'منتخب تمام اثاثہ ریکارڈ مستقل طور پر حذف کریں';

  @override
  String get inflationEditRate => 'افراط زر کی شرح میں ترمیم کریں';

  @override
  String get inflationAddDescription => 'کسی مخصوص تاریخ اور ملک کے لیے نئی افراط زر کی شرح درج کریں';

  @override
  String get inflationPercentLabel => 'افراط زر کا فیصد (%)';

  @override
  String get inflationPercentHint => 'مثلاً 2.5';

  @override
  String get inflationPercentInvalidError => 'ایک عدد درج کریں، مثلاً 2.5';

  @override
  String get inflationCountryGlobal => 'ملک: عالمی';

  @override
  String inflationCountryNamed(String country) {
    return 'ملک: $country';
  }

  @override
  String get inflationUseWorldwideRate => 'عالمی شرح استعمال کریں';

  @override
  String get pickerSingleDate => 'واحد تاریخ';

  @override
  String get pickerRange => 'دورانیہ';

  @override
  String get dateStepDay => 'دن';

  @override
  String get dateStepMonth => 'مہینہ';

  @override
  String get dateStepYear => 'سال';

  @override
  String get feeStructureTitle => 'فیس کا ڈھانچہ';

  @override
  String get feeNoRulesApplied => 'کوئی فیس قاعدہ لاگو نہیں ہے۔';

  @override
  String get feeAddRule => 'فیس قاعدہ شامل کریں';

  @override
  String get feeFixedFee => 'مقررہ فیس';

  @override
  String get feePercentFee => 'فیصد فیس';

  @override
  String get feeTaxRate => 'ٹیکس کی شرح';

  @override
  String get feeUnknownRule => 'نامعلوم قاعدہ';

  @override
  String get feeRatePercentLabel => 'شرح (%)';

  @override
  String get feeTaxRatePercentLabel => 'ٹیکس کی شرح (%)';

  @override
  String get feeCostBasisLabel => 'لاگت کی بنیاد';

  @override
  String deleteAccountsConfirmTitle(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
      
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString اکاؤنٹس',
      one: 'یہ اکاؤنٹ',
    );
    return '$_temp0 حذف کریں؟';
  }

  @override
  String get deleteAccountsConfirmMessage => 'کیا آپ واقعی منتخب اکاؤنٹس حذف کرنا چاہتے ہیں؟ تمام متعلقہ لین دین حذف ہو جائیں گے۔';

  @override
  String get changeAccountTypeTitle => 'اکاؤنٹ کی قسم تبدیل کریں';

  @override
  String get accountsPreviousPeriodDescription => 'پچھلے مہینے یا سال پر جائیں';

  @override
  String get accountsNextPeriodDescription => 'اگلے مہینے یا سال پر جائیں';

  @override
  String get accountsFilterDescription => 'اکاؤنٹس کو قسم یا پوشیدہ حالت کے مطابق فلٹر کریں';

  @override
  String get accountsSelectDateDescription => 'ماضی کے بیلنس دیکھنے کے لیے مخصوص تاریخ منتخب کریں';

  @override
  String get accountsSortDescription => 'بیلنس کی صعودی اور نزولی ترتیب کے درمیان تبدیل کریں';

  @override
  String get smsRuleCategoryOptional => 'زمرہ (اختیاری)';

  @override
  String get smsRuleCategoryHelp => 'اس قاعدے کے لیے زمرہ تبدیل کریں';
}
