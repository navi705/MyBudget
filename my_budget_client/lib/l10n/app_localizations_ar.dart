// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get collapseMenuTooltip => 'طي القائمة';

  @override
  String get expandMenuTooltip => 'توسيع القائمة';

  @override
  String get helloWorld => 'أهلاً بالعالم!';

  @override
  String get accountsAppBarTitle => 'الحسابات';

  @override
  String accountsBalanceLabel(Object balance) {
    return 'الرصيد: $balance';
  }

  @override
  String get accountsLoadFailure => 'فشل تحميل الحسابات';

  @override
  String get accountsEmptyState => 'لا توجد حسابات';

  @override
  String get accountsRefreshTooltip => 'تحديث';

  @override
  String get accountsAddTooltip => 'إضافة حساب';

  @override
  String get addAccountDescription => 'إنشاء حساب بنكي جديد أو محفظة أو أصل';

  @override
  String get addAccountDialogTitle => 'إضافة حساب جديد';

  @override
  String get editAccountDialogTitle => 'تعديل الحساب';

  @override
  String get accountNameHint => 'اسم الحساب';

  @override
  String get initialBalanceHint => 'الرصيد الأولي';

  @override
  String get currencyLabel => 'العملة';

  @override
  String get cancelButton => 'إلغاء';

  @override
  String get saveButton => 'حفظ';

  @override
  String get deleteButton => 'حذف';

  @override
  String get editButton => 'تعديل';

  @override
  String get applyButton => 'تطبيق';

  @override
  String get clearButton => 'مسح';

  @override
  String get selectButton => 'تحديد';

  @override
  String get selectAllButton => 'تحديد الكل';

  @override
  String get deselectAllButton => 'إلغاء تحديد الكل';

  @override
  String get deleteSelectedButton => 'حذف المحدد';

  @override
  String totalCountLabel(Object count) {
    return 'الإجمالي: $count';
  }

  @override
  String selectedCountLabel(Object count) {
    return '$count محدد';
  }

  @override
  String get formValidationPleaseEnterName => 'يرجى إدخال اسم';

  @override
  String get formValidationPleaseEnterBalance => 'يرجى إدخال الرصيد';

  @override
  String get formValidationPleaseEnterValidNumber => 'يرجى إدخال رقم صحيح';

  @override
  String get formValidationPleaseSelectCurrency => 'يرجى تحديد عملة';

  @override
  String get currencyLoadError => 'خطأ في تحميل العملات';

  @override
  String get noCurrenciesAvailable => 'لا توجد عملات متاحة';

  @override
  String get categoriesAppBarTitle => 'الفئات';

  @override
  String get categoriesScreenBody => 'شاشة الفئات';

  @override
  String get transactionsAppBarTitle => 'المعاملات';

  @override
  String get transactionsScreenBody => 'شاشة المعاملات';

  @override
  String get settingsAppBarTitle => 'الإعدادات';

  @override
  String get settingsScreenBody => 'شاشة الإعدادات';

  @override
  String get filePickerChooserTitle => 'اختر ملفاً';

  @override
  String get imagePickerChooserTitle => 'اختر صورة';

  @override
  String get totalNetWorth => 'إجمالي صافي القيمة';

  @override
  String get currencyBreakdown => 'تفصيل العملات';

  @override
  String get dashboardNetWorthTrend => 'اتجاه صافي القيمة';

  @override
  String get dashboardWealthDistributionByAccount => 'توزيع الثروة (حسب الحساب)';

  @override
  String get dashboardCurrencyExposure => 'التعرض للعملات';

  @override
  String get dashboardNoAccountsFound => 'لم يتم العثور على حسابات';

  @override
  String get dashboardTotalNetWorthTrend => 'اتجاه إجمالي صافي القيمة';

  @override
  String get dashboardAccountBalanceTrend => 'اتجاه رصيد الحساب';

  @override
  String get dashboardWealthDistribution => 'توزيع الثروة';

  @override
  String get dashboardCurrencyBreakdown => 'تفصيل العملات';

  @override
  String get metricBalance => 'الرصيد';

  @override
  String get metricIncome => 'الدخل';

  @override
  String get metricExpense => 'المصروفات';

  @override
  String get metricReal => 'الحقيقي';

  @override
  String get metricChange => 'التغيير';

  @override
  String get contextMenuSelect => 'تحديد';

  @override
  String get contextMenuDeselect => 'إلغاء التحديد';

  @override
  String get contextMenuSelectAll => 'تحديد الكل';

  @override
  String get contextMenuDeselectAll => 'إلغاء تحديد الكل';

  @override
  String get contextMenuAddTransaction => 'إضافة معاملة';

  @override
  String get addTransactionDescription => 'إنشاء معاملة جديدة';

  @override
  String get contextMenuTransfer => 'تحويل';

  @override
  String get contextMenuEdit => 'تعديل';

  @override
  String get contextMenuDelete => 'حذف';

  @override
  String get contextMenuChangeType => 'تغيير النوع';

  @override
  String deleteConfirmationTitle(Object item) {
    return 'حذف $item؟';
  }

  @override
  String deleteConfirmationMessage(Object item) {
    return 'هل أنت متأكد من رغبتك في حذف $item وكافة بياناته؟';
  }

  @override
  String get deleteAccountsConfirmationTitle => 'حذف الحسابات؟';

  @override
  String deleteAccountsConfirmationMessage(Object count) {
    return 'حذف $count حسابات محددة ومعاملاتها؟';
  }

  @override
  String get deleteAccountDialogReassign => 'إعادة تخصيص المعاملات لحساب آخر';

  @override
  String get deleteAccountDialogDeleteAll => 'حذف جميع المعاملات المرتبطة';

  @override
  String get deleteAccountDialogMessage => 'قد يحتوي هذا الحساب على معاملات مرتبطة. ماذا تود أن تفعل؟';

  @override
  String get newAccountLabel => 'حساب جديد';

  @override
  String get warningOverwriteTitle => 'تحذير: كتابة فوق البيانات؟';

  @override
  String get warningOverwriteMessage => 'استعادة نسخة احتياطية سيحذف كافة البيانات الحالية ويستبدلها بالنسخة الاحتياطية. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get restoreOverwriteButton => 'استعادة وكتابة فوق البيانات';

  @override
  String get importSuccess => 'اكتمل الاستيراد بنجاح.';

  @override
  String importFailed(Object error) {
    return 'فشل الاستيراد: $error';
  }

  @override
  String deleteCategoriesConfirmationTitle(Object count) {
    return 'حذف $count فئات؟';
  }

  @override
  String get deleteCategoriesConfirmationMessage => 'هل أنت متأكد من رغبتك في حذف الفئات المحددة؟';

  @override
  String get changeCategoryTypeDialogTitle => 'تغيير نوع الفئة';

  @override
  String get noCategoriesCreated => 'لم يتم إنشاء فئات بعد.';

  @override
  String get addCategoryTooltip => 'إضافة فئة';

  @override
  String get addCategoryDescription => 'إنشاء فئة مصروفات أو دخل جديدة';

  @override
  String get previousPeriodTooltip => 'الفترة السابقة';

  @override
  String get previousPeriodDescription => 'الذهاب إلى الشهر أو العام السابق';

  @override
  String get nextPeriodTooltip => 'الفترة التالية';

  @override
  String get nextPeriodDescription => 'الذهاب إلى الشهر أو العام التالي';

  @override
  String get filterTooltip => 'تصفية';

  @override
  String get filterCategoriesDescription => 'تصفية الفئات حسب النوع (دخل/مصروفات)';

  @override
  String get selectDateTooltip => 'تحديد تاريخ';

  @override
  String get selectDateDescription => 'اختر نطاقاً زمنياً محدداً لرؤية الإجماليات';

  @override
  String get sortOrderTooltip => 'ترتيب الفرز';

  @override
  String get sortOrderDescription => 'التبديل بين الترتيب التصاعدي والتنازلي حسب المبلغ';

  @override
  String get closeSelectionTooltip => 'إغلاق التحديد';

  @override
  String get exitSelectionDescription => 'الخروج من وضع التحديد';

  @override
  String get categoryNameLabel => 'اسم الفئة';

  @override
  String get categoriesChangeButton => 'تغيير';

  @override
  String get parentCategoryLabel => 'الفئة الأم';

  @override
  String get styleLabel => 'النمط (أيقونة ولون)';

  @override
  String get typeLabel => 'النوع';

  @override
  String get deleteTransactionsConfirmationTitle => 'حذف المعاملات';

  @override
  String deleteTransactionsConfirmationMessage(Object count) {
    return 'هل أنت متأكد من رغبتك في حذف $count معاملات محددة؟';
  }

  @override
  String get exitTransactionsSelectionDescription => 'الخروج من وضع اختيار المعاملات';

  @override
  String get changeDateTooltip => 'تغيير التاريخ';

  @override
  String get changeDateDescription => 'تحديث التاريخ لكافة المعاملات المحددة';

  @override
  String get changeCategoryTooltip => 'تغيير الفئة';

  @override
  String get changeCategoryDescription => 'تحديث الفئة لكافة المعاملات المحددة';

  @override
  String get deleteTransactionsTooltip => 'حذف المحدد';

  @override
  String get deleteTransactionsDescription => 'حذف كافة المعاملات المحددة نهائياً';

  @override
  String get amountLabel => 'المبلغ';

  @override
  String quantityLabel(Object quantity) {
    return 'الكمية: $quantity';
  }

  @override
  String get quantityFormLabel => 'الكمية';

  @override
  String get selectAccountTitle => 'تحديد حساب';

  @override
  String get selectCategoryTitle => 'تحديد فئة';

  @override
  String get selectCurrencyTitle => 'تحديد عملة';

  @override
  String get accountLabel => 'الحساب';

  @override
  String get fromAccountLabel => 'من حساب';

  @override
  String get toAccountLabel => 'إلى حساب';

  @override
  String get categoryLabel => 'الفئة';

  @override
  String get dateLabel => 'التاريخ';

  @override
  String get selectDateLabel => 'تحديد تاريخ';

  @override
  String get addTransactionTitle => 'إضافة معاملة';

  @override
  String get editTransactionTitle => 'تعديل المعاملة';

  @override
  String get newTransferTitle => 'تحويل جديد';

  @override
  String get editTransferTitle => 'تعديل التحويل';

  @override
  String get descriptionLabel => 'الوصف';

  @override
  String get descriptionOptionalLabel => 'الوصف (اختياري)';

  @override
  String get swapAccountsTooltip => 'تبديل الحسابات';

  @override
  String get incomeType => 'الدخل';

  @override
  String get expenseType => 'المصروفات';

  @override
  String get failedToLoadData => 'فشل تحميل البيانات';

  @override
  String get invalidAmountError => 'يرجى إدخال رقم صحيح';

  @override
  String get emptyAmountError => 'يرجى إدخال مبلغ';

  @override
  String get selectAccountError => 'يرجى تحديد حساب';

  @override
  String get selectCategoryError => 'يرجى تحديد فئة';

  @override
  String get selectDateError => 'يرجى تحديد تاريخ';

  @override
  String get currencyLockedMessage => 'مغلق على عملة حساب المصدر';

  @override
  String get totalValueLabel => 'إجمالي القيمة';

  @override
  String get feeLabel => 'الرسوم';

  @override
  String get exchangeRateLabel => 'سعر الصرف';

  @override
  String get pricePerUnitLabel => 'السعر للوحدة';

  @override
  String get buyAction => 'شراء';

  @override
  String get sellAction => 'بيع';

  @override
  String transferToDescription(Object accountName) {
    return 'تحويل إلى $accountName';
  }

  @override
  String transferFromDescription(Object accountName) {
    return 'تحويل من $accountName';
  }

  @override
  String buyDescription(Object assetName) {
    return 'شراء $assetName';
  }

  @override
  String sellDescription(Object assetName) {
    return 'بيع $assetName';
  }

  @override
  String assetTransferDescription(Object action, Object assetName) {
    return 'تحويل من أجل $action $assetName';
  }

  @override
  String get swapDirectionTooltip => 'تبديل الاتجاه';

  @override
  String get availablePresetsLabel => 'النماذج المتاحة:';

  @override
  String get updateButton => 'تحديث';

  @override
  String get newPresetButton => 'نموذج جديد';

  @override
  String get amountToAddToAccountLabel => 'المبلغ المراد إضافته للحساب:';

  @override
  String valueInGlobalLabel(Object currency) {
    return 'القيمة بالعالمية ($currency):';
  }

  @override
  String get feeCommissionLabel => 'الرسوم (العمولة)';

  @override
  String get requiredError => 'مطلوب';

  @override
  String currentPriceLabel(Object currency, Object price) {
    return 'السعر الحالي: $price $currency';
  }

  @override
  String get linkedAccountLabel => 'الحساب المرتبط';

  @override
  String get selectLinkedAccountTitle => 'اختر الحساب المرتبط';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get manageIconsLabel => 'إدارة الأيقونات';

  @override
  String get manageThemeLabel => 'إدارة المظهر';

  @override
  String get mainCurrencyLabel => 'العملة الرئيسية';

  @override
  String get defaultInflationCountryLabel => 'بلد التضخم الافتراضي';

  @override
  String get persistAdvancedFiltersLabel => 'الاحتفاظ بالفلاتر المتقدمة';

  @override
  String get hotKeysLabel => 'مفاتيح الاختصار';

  @override
  String get smsImportLabel => 'استيراد SMS';

  @override
  String get smsImportSubtitle => 'استيراد معاملات بنكية من الرسائل القصيرة';

  @override
  String get apiManagementLabel => 'إدارة API';

  @override
  String get dataLabel => 'البيانات';

  @override
  String get syncSettingsLabel => 'إعدادات المزامنة';

  @override
  String get syncSettingsSubtitle => 'مزامنة P2P عبر Syncthing';

  @override
  String get themeSettingsTitle => 'إعدادات المظهر';

  @override
  String get appearanceSection => 'المظهر';

  @override
  String get themeModeLabel => 'وضع المظهر';

  @override
  String get systemTheme => 'النظام';

  @override
  String get lightTheme => 'فاتح';

  @override
  String get darkTheme => 'داكن';

  @override
  String get colorCustomizationSection => 'تخصيص الألوان';

  @override
  String get primaryColorLabel => 'اللون الأساسي';

  @override
  String get secondaryColorLabel => 'اللون الثانوي';

  @override
  String get surfaceColorLabel => 'لون السطح';

  @override
  String get windowEffectsSection => 'تأثيرات النافذة (سطح المكتب)';

  @override
  String get enableEffectsLabel => 'تفعيل تأثيرات النافذة';

  @override
  String get windowEffectLabel => 'تأثير النافذة';

  @override
  String get backgroundLabel => 'الخلفية';

  @override
  String get removeBackgroundColor => 'إزالة لون الخلفية';

  @override
  String get transparentSurfaceLabel => 'سطح شفاف (البطاقات)';

  @override
  String get fullyTransparentLabel => 'شفاف تماماً';

  @override
  String get opaqueLabel => 'معتم';

  @override
  String opacityLabel(Object value) {
    return 'الشفافية: $value%';
  }

  @override
  String get backgroundSettingsSection => 'إعدادات الخلفية';

  @override
  String get enableBackgroundImageLabel => 'تفعيل صورة الخلفية';

  @override
  String get backgroundBlurLabel => 'تغبيش الخلفية';

  @override
  String get surfaceGlassStyleTitle => 'نمط السطح/الزجاج';

  @override
  String get chooseImageButton => 'اختر صورة';

  @override
  String get selectImageFileError => 'يرجى اختيار ملف صورة.';

  @override
  String get clearImageButton => 'مسح الصورة';

  @override
  String get saveThemePresetTitle => 'حفظ نموذج المظهر';

  @override
  String get presetNameLabel => 'اسم النموذج';

  @override
  String get presetNameHint => 'مظهري الرائع';

  @override
  String get importDataLabel => 'استيراد البيانات';

  @override
  String get exportDataLabel => 'تصدير البيانات';

  @override
  String get exportFormatMessage => 'اختر التنسيق:\n\nJSON: نسخة احتياطية كاملة لكافة البيانات.\nCSV: تقرير معاملات قابل للقراءة.';

  @override
  String get jsonFormat => 'JSON';

  @override
  String get csvFormat => 'CSV';

  @override
  String get importExchangeRatesLabel => 'استيراد أسعار الصرف (CSV/JSON)';

  @override
  String get resetDataLabel => 'إعادة تعيين البيانات للافتراضي';

  @override
  String get resetDataSubtitle => 'سيؤدي هذا لحذف كافة البيانات واستعادة الإعدادات الافتراضية.';

  @override
  String get debugMenuLabel => 'قائمة التصحيح';

  @override
  String get debugMenuSubtitle => 'أدوات المطور الداخلية';

  @override
  String get apiManagementTitle => 'إدارة API';

  @override
  String get apiCategoriesSection => 'فئات API';

  @override
  String get manualUtilitiesSection => 'أدوات يدوية';

  @override
  String get startupDataSyncLabel => 'مزامنة البيانات عند بدء التشغيل';

  @override
  String get startupDataSyncDescription => 'يتحكم في جلب البيانات الخارجية ومزامنة الخادم عند تشغيل التطبيق.';

  @override
  String get standardApiLabel => 'Standard API';

  @override
  String get syncOnStartupDescription => 'مزامنة عند البدء';

  @override
  String get customSourcesLabel => 'مصادر مخصصة';

  @override
  String syncCustomSourcesDescription(Object count) {
    return 'مزامنة كافة المصادر ($count) عند البدء';
  }

  @override
  String get individualCustomSourcesTitle => 'مصادر مخصصة فردية';

  @override
  String get noCustomSourcesAdded => 'لم يتم إضافة مصادر مخصصة بعد.';

  @override
  String get fetchTodaysRatesButton => 'جلب أسعار اليوم';

  @override
  String get inflationConfigTitle => 'إعدادات التضخم';

  @override
  String get countryCodeHint => 'كود الدولة (مثلاً SRB)';

  @override
  String fetchDataForCountryButton(Object country) {
    return 'جلب بيانات لـ $country';
  }

  @override
  String get steamSettingsTitle => 'إعدادات Steam';

  @override
  String get steamIdLabel => 'Steam ID (64-bit)';

  @override
  String get preferredGameLabel => 'اللعبة المفضلة';

  @override
  String get fetchInventoryNowButton => 'جلب المخزون الآن';

  @override
  String get manualExchangeRatesTitle => 'جلب أسعار الصرف يدوياً';

  @override
  String get selectStartDate => 'اختر تاريخ البدء';

  @override
  String startDateFrom(Object date) {
    return 'من: $date';
  }

  @override
  String get selectEndDate => 'اختر تاريخ الانتهاء';

  @override
  String endDateTo(Object date) {
    return 'إلى: $date';
  }

  @override
  String get fetchRangeButton => 'جلب النطاق';

  @override
  String get manualSteamInventoryTitle => 'مخزون Steam اليدوي';

  @override
  String get selectGameHint => 'اختر اللعبة';

  @override
  String get fetchValueButton => 'جلب القيمة';

  @override
  String get manualInflationDataTitle => 'بيانات تضخم يدوية';

  @override
  String get selectStartYear => 'اختر سنة البدء';

  @override
  String startYearFrom(Object year) {
    return 'من: $year';
  }

  @override
  String get selectEndYear => 'اختر سنة الانتهاء';

  @override
  String endYearTo(Object year) {
    return 'إلى: $year';
  }

  @override
  String get fetchDataButton => 'جلب البيانات';

  @override
  String get connectionOk => 'الاتصال متاح';

  @override
  String get connectionFailed => 'الاتصال فشل';

  @override
  String get testConnectionButton => 'اختبار الاتصال';

  @override
  String get editCustomSourceTitle => 'تعديل مصدر مخصص';

  @override
  String get addCustomSourceTitle => 'إضافة مصدر مخصص';

  @override
  String get addressFormatsHelp => 'نماذج العنوان:\n• 192.168.1.10 (IP)\n• localhost أو api.my.com\n• http://myserver.com';

  @override
  String get urlIpLabel => 'URL / IP';

  @override
  String get urlIpHint => '192.168.1.10:8080';

  @override
  String get dataTypeLabel => 'نوع البيانات';

  @override
  String get apiTitleExchangeRates => 'أسعار الصرف';

  @override
  String get apiTitleInflation => 'التضخم';

  @override
  String get apiTitleAssetPrices => 'أسعار الأصول';

  @override
  String get apiTitleSteamInventory => 'مخزون Steam';

  @override
  String get transferLabel => 'تحويل';

  @override
  String get uncategorizedLabel => 'غير مصنف';

  @override
  String get defaultLabel => 'افتراضي';

  @override
  String receivedTotalLabel(Object total) {
    return 'المستلم: $total';
  }

  @override
  String spentTotalLabel(Object total) {
    return 'المنفق: $total';
  }

  @override
  String get periodSummaryTitle => 'ملخص الفترة';

  @override
  String get incomeLabel => 'دخل';

  @override
  String get expenseLabel => 'مصروفات';

  @override
  String get netLabel => 'الصافي';

  @override
  String get exportSuccessMessage => 'اكتمل التصدير بنجاح';

  @override
  String exportFailedMessage(Object error) {
    return 'فشل التصدير: $error';
  }

  @override
  String get importSuccessMessage => 'اكتمل الاستيراد بنجاح';

  @override
  String importFailedMessage(Object error) {
    return 'فشل الاستيراد: $error';
  }

  @override
  String get resetDataConfirmationTitle => 'إعادة تعيين البيانات؟';

  @override
  String get resetDataConfirmationMessage => 'تحذير! سيؤدي هذا لمسح كااااافة معاملاتك وحساباتك وإعداداتك.\n\nسيعود التطبيق لحالته الأصلية مع البيانات الافتراضية.\nلا يمكن التراجع عن هذا الإجراء.';

  @override
  String get resetEverythingButton => 'إعادة تعيين الكل';

  @override
  String get resetSuccessMessage => 'تمت إعادة تعيين البيانات واستعادة الافتراضيات.';

  @override
  String resetFailedMessage(Object error) {
    return 'فشل إعادة التعيين: $error';
  }

  @override
  String get importParsingStep => 'تحليل ملفات CSV...';

  @override
  String get importFetchingRatesStep => 'جلب أسعار الصرف...';

  @override
  String importErrorLabel(Object error) {
    return 'خطأ: $error';
  }

  @override
  String get importOneMoneyLabel => 'استيراد من OneMoney (CSV)';

  @override
  String get importMyBudgetLabel => 'استيراد معاملات MyBudget (CSV)';

  @override
  String get restoreBackupLabel => 'استعادة النسخة الاحتياطية (JSON)';

  @override
  String get importSelectionHelp => 'اختر \'OneMoney\' للهجرة، \'MyBudget\' لإضافة معاملات، أو \'استعادة النسخة الاحتياطية\' للكتابة فوق كافة البيانات الحالية.';

  @override
  String get importCreateAllNew => 'إنشاء كافة البيانات كجديدة';

  @override
  String importNewAccountFound(Object accountName) {
    return 'تم العثور على حساب جديد: \"$accountName\"';
  }

  @override
  String importMapAccountTitle(Object accountName) {
    return 'تخصيص \"$accountName\" لـ...';
  }

  @override
  String get importMapToExisting => 'تخصيص لـ موجود';

  @override
  String get importCreateNew => 'إنشاء جديد';

  @override
  String importNewCategoryFound(Object categoryName) {
    return 'تم العثور على فئة جديدة: \"$categoryName\"';
  }

  @override
  String importMapCategoryTitle(Object categoryName) {
    return 'تخصيص \"$categoryName\" لـ...';
  }

  @override
  String importNewCurrencyFound(Object currencyName) {
    return 'تم العثور على عملة جديدة: \"$currencyName\"';
  }

  @override
  String importMapCurrencyTitle(Object currencyName) {
    return 'تخصيص \"$currencyName\" لـ...';
  }

  @override
  String get importSkipAll => 'تخطي الكل';

  @override
  String get importImportAll => 'استيراد الكل';

  @override
  String get importPotentialDuplicate => 'احتمال تكرار:';

  @override
  String importDateLabel(Object date) {
    return 'التاريخ: $date';
  }

  @override
  String importFromLabel(Object from) {
    return 'من: $from';
  }

  @override
  String importToLabel(Object to) {
    return 'إلى: $to';
  }

  @override
  String importAmountLabel(Object amount, Object currency) {
    return 'المبلغ: $amount $currency';
  }

  @override
  String get importSkip => 'تخطي';

  @override
  String get importImportAnyway => 'استيراد على أي حال';

  @override
  String importDecisionLabel(Object decision) {
    return 'القرار: $decision';
  }

  @override
  String get importReadyTitle => 'جاهز للاستيراد';

  @override
  String importReadyMessage(Object count) {
    return '$count معاملات جاهزة للاستيراد.';
  }

  @override
  String get importFinalizeButton => 'إنهاء الاستيراد';

  @override
  String get importingTitle => 'جارٍ الاستيراد...';

  @override
  String get importCompleteTitle => 'اكتمل الاستيراد';

  @override
  String get importStartOverTooltip => 'البدء من جديد';

  @override
  String get importDataTitle => 'استيراد البيانات';

  @override
  String importAccountsCreatedLabel(Object count) {
    return 'حسابات جديدة تم إنشاؤها: $count';
  }

  @override
  String importCategoriesCreatedLabel(Object count) {
    return 'فئات جديدة تم إنشاؤها: $count';
  }

  @override
  String importTransactionsImportedLabel(Object count) {
    return 'معاملات تم استيرادها: $count';
  }

  @override
  String importDuplicatesSkippedLabel(Object count) {
    return 'تكرارات تم تخطيها: $count';
  }

  @override
  String get searchHint => 'بحث';

  @override
  String get debugAllDataClearedMessage => 'تم مسح كافة البيانات وإعادة بذر الافتراضيات.';

  @override
  String get debugClearAllDataLabel => 'مسح كافة البيانات (وإعادة بذر الافتراضيات)';

  @override
  String get debugMinimumDataSeededMessage => 'تم بذر البيانات الدنيا.';

  @override
  String get debugSeedMinimumDataLabel => 'بذر بيانات دنيا';

  @override
  String get debugMediumDataSeededMessage => 'تم بذر بيانات متوسطة.';

  @override
  String get debugSeedMediumDataLabel => 'بذر بيانات متوسطة';

  @override
  String get debugMaximumDataSeededMessage => 'تم بذر البيانات القصوى.';

  @override
  String get debugSeedMaximumDataLabel => 'بذر بيانات قصوى (لاختبار الأداء)';

  @override
  String get debugRunningInDebugModeLabel => 'يعمل في وضع DEBUG';

  @override
  String get deleteAllButton => 'حذف الكل';

  @override
  String get changeButton => 'تغيير';

  @override
  String get undoButton => 'تراجع';

  @override
  String itemDeletedMessage(Object name) {
    return 'تم حذف $name';
  }

  @override
  String get totalBalanceLabel => 'إجمالي الرصيد';

  @override
  String get noCurrenciesSelected => 'لم يتم تحديد عملات.';

  @override
  String get failedToLoadDashboard => 'فشل تحميل لوحة المعلومات';

  @override
  String get dashboardCalendarTab => 'التقويم';

  @override
  String get dashboardTabCalendar => 'التقويم';

  @override
  String get dashboardCalendarTooltip => 'عرض التقويم';

  @override
  String get dashboardCalendarDescription => 'عرض المعاملات بتنسيق التقويم';

  @override
  String get dashboardCategoriesTab => 'الفئات';

  @override
  String get dashboardTabCategories => 'الفئات';

  @override
  String get dashboardCategoriesTooltip => 'تحليل الفئات';

  @override
  String get dashboardCategoriesDescription => 'تفصيل المصروفات حسب الفئة';

  @override
  String get dashboardBalanceTab => 'الرصيد';

  @override
  String get dashboardTabBalance => 'الرصيد';

  @override
  String get dashboardBalanceTooltip => 'تاريخ الرصيد';

  @override
  String get dashboardBalanceDescription => 'تتبع صافي القيمة بمرور الوقت';

  @override
  String get dashboardExpensesLabel => 'المصروفات';

  @override
  String get dashboardIncomeLabel => 'الدخل';

  @override
  String get manageIconsTitle => 'إدارة الأيقونات';

  @override
  String get manageStylesDeleteTitle => 'حذف الأيقونات';

  @override
  String manageStylesDeleteConfirm(Object count) {
    return 'هل أنت متأكد من رغبتك في حذف $count أيقونات محددة؟';
  }

  @override
  String manageStylesDeleteConfirmWithTransfer(Object count) {
    return 'هل أنت متأكد من رغبتك في حذف $count أيقونات محددة؟ (سيتم تجاهل أيقونة التحويل)';
  }

  @override
  String get noIconsCreated => 'لم يتم إنشاء أيقونات بعد.';

  @override
  String get failedToLoadIcons => 'فشل تحميل الأيقونات.';

  @override
  String get cannotDeleteTransferIcon => 'لا يمكن حذف أيقونة التحويل.';

  @override
  String get deleteIconsDialogTitle => 'حذف الأيقونات';

  @override
  String deleteIconsConfirmationMessage(Object count) {
    return 'هل أنت متأكد من رغبتك في حذف $count أيقونات محددة؟';
  }

  @override
  String deleteIconsWithSkipTransferMessage(Object count) {
    return 'هل أنت متأكد من رغبتك في حذف $count أيقونات محددة؟ (سيتم تخطي أيقونة التحويل)';
  }

  @override
  String get deleteIconDialogTitle => 'حذف الأيقونة';

  @override
  String deleteIconConfirmationMessage(Object name) {
    return 'هل أنت متأكد من رغبتك في حذف \"$name\"؟';
  }

  @override
  String deleteMultipleAccountsTitle(Object count) {
    return 'حذف $count حسابات؟';
  }

  @override
  String get deleteMultipleAccountsMessage => 'هل أنت متأكد من رغبتك في حذف الحسابات المحددة؟ سيتم حذف كافة المعاملات المرتبطة.';

  @override
  String get changeAccountTypeDialogTitle => 'تغيير نوع الحساب';

  @override
  String editAccountTitle(Object name) {
    return 'تعديل: $name';
  }

  @override
  String get balanceCalculatedFromAsset => 'يتم حساب الرصيد من كمية الأصول * السعر';

  @override
  String get selectAccountTypeTitle => 'اختر نوع الحساب';

  @override
  String get selectCountryTitle => 'اختر الدولة';

  @override
  String get selectIconSubtitle => 'اختر أيقونة';

  @override
  String get bindToAssetLabel => 'ربط بأصل (اختياري)';

  @override
  String get selectAssetTitle => 'اختر أصل';

  @override
  String get selectedAssetLabel => 'الأصل المحدد';

  @override
  String get balanceAutoCalculatedLabel => 'الرصيد يتم حسابه تلقائياً';

  @override
  String get tapToBindAssetLabel => 'انقر لربط أصل';

  @override
  String get assetQuantityLabel => 'كمية الأصول';

  @override
  String get linkedAssetsTitle => 'الأصول المرتبطة';

  @override
  String get noneLabel => 'لا يوجد';

  @override
  String get accountTypeLabel => 'نوع الحساب';

  @override
  String get formValidationPleaseSelectAccountType => 'يرجى تحديد نوع الحساب';

  @override
  String get iconLabel => 'أيقونة';

  @override
  String get languageLabel => 'اللغة';

  @override
  String get systemDefaultLabel => 'افتراضي النظام';

  @override
  String get selectLanguageTitle => 'اختر اللغة';

  @override
  String get dashboardLabel => 'لوحة المعلومات';

  @override
  String get homeLabel => 'الرئيسية';

  @override
  String get historyLabel => 'السجل';

  @override
  String get syncScreenTitle => 'إعدادات المزامنة';

  @override
  String get syncP2PSection => 'مزامنة P2P (Syncthing)';

  @override
  String get syncEnableP2P => 'تفعيل مزاينة P2P';

  @override
  String get syncP2PSubtitle => 'مزامنة عبر ملفات .sync في مجلد مشترك';

  @override
  String get syncFolderLabel => 'مجلد المزامنة';

  @override
  String get syncFolderNotSelected => 'غير محدد';

  @override
  String get syncBrowseButton => 'تصفح';

  @override
  String get syncClearFilesButton => 'مسح ملفات المزامنة';

  @override
  String get syncServerSection => 'مزامنة سحابية (خادم)';

  @override
  String get syncServerUrlLabel => 'URL الخادم';

  @override
  String get syncApiTokenLabel => 'رمز API';

  @override
  String get syncApiTokenHint => 'أدخل رمز الأمان الخاص بك';

  @override
  String get syncApiTokenHelp => 'هذا الرمز هو سرك المشترك. أدخل نفس القيمة على كافة أجهزتك للسماح بالمزامنة.';

  @override
  String get syncTestConnectionButton => 'اختبار الاتصال';

  @override
  String get syncTestingLabel => 'جارٍ الاختبار...';

  @override
  String get syncSaveServerSettingsButton => 'حفظ إعدادات الخادم';

  @override
  String get syncEnableServer => 'تفعيل مزامنة الخادم';

  @override
  String get syncServerSubtitle => 'مزامنة مع نسخة من MyBudget Server';

  @override
  String get syncPendingLocalChanges => 'تغييرات محلية معلقة:';

  @override
  String get syncSyncNowButton => 'مزامنة الآن';

  @override
  String get syncSyncingLabel => 'جارٍ المزامنة...';

  @override
  String get syncWebNotAvailable => 'المزامنة غير متوفرة على الويب';

  @override
  String get syncPermissionRequired => 'إذن التخزين مطلوب للمزامنة. يرجى تفعيل \"الوصول لكافة الملفات\" في الإعدادات.';

  @override
  String get syncSelectFolderTitle => 'اختر مجلد Syncthing';

  @override
  String get syncClearFilesTitle => 'مسح ملفات المزامنة';

  @override
  String get syncClearFilesConfirm => 'سيتم حذف كافة ملفات .sync من المجلد المحدد. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String syncDeletedFilesCount(Object count) {
    return 'تم حذف $count من ملفات المزامنة';
  }

  @override
  String syncClearFilesError(Object error) {
    return 'خطأ في مسح الملفات: $error';
  }

  @override
  String get syncSettingsSaved => 'تم حفظ إعدادات الخادم';

  @override
  String get syncConnectionSuccessful => 'تم الاتصال بنجاح!';

  @override
  String get syncConnectionFailed => 'فشل الاتصال. تحقق من URL والرمز.';

  @override
  String get syncConnectionUnauthorized => 'رفض الخادم الرمز. تحقق من الرمز وليس العنوان.';

  @override
  String get syncServerNotConfigured => 'لم يتم تكوين رمز مزامنة على الخادم وهو يرفض جميع الأجهزة. عيّن SYNC_TOKEN على الخادم واستخدم القيمة نفسها هنا.';

  @override
  String get syncCompleted => 'اكتملت المزامنة بنجاح';

  @override
  String syncFailed(Object error) {
    return 'فشلت المزامنة: $error';
  }

  @override
  String get smsRuleAddTitle => 'إضافة قاعدة';

  @override
  String get smsRuleEditTitle => 'تعديل القاعدة';

  @override
  String get smsRuleTransactionType => 'نوع المعاملة';

  @override
  String get smsRuleMatchPattern => 'نمط المطابقة (Regex)';

  @override
  String get smsRuleMatchPatternHint => 'مثال: دفع.*بالبطاقة';

  @override
  String get smsRuleMatchPatternHelp => 'نمط للتعرف على هذا النوع من الرسائل';

  @override
  String get smsRuleAmountPattern => 'نمط المبلغ (Regex)';

  @override
  String get smsRuleAmountPatternHint => 'مثال: مبلغ\\s+([\\d,.]+)';

  @override
  String get smsRuleAmountPatternHelp => 'يجب أن يلتقط جروب 1 المبلغ';

  @override
  String get smsRuleCurrencyPattern => 'نمط العملة (Regex, اختياري)';

  @override
  String get smsRuleCurrencyPatternHint => 'مثال: [\\d,.]+\\s*(\\w\\w\\w)';

  @override
  String get smsRuleCurrencyPatternHelp => 'يجب أن يلتقط جروب 1 كود العملة';

  @override
  String get smsRuleTestTitle => 'اختبر قاعدتك';

  @override
  String get smsRuleTestSmsHint => 'الصق نص الرسالة هنا';

  @override
  String get smsRuleTestButton => 'اختبار النمط';

  @override
  String get smsRuleTestEnterSmsError => 'أدخل نص الرسالة للاختبار';

  @override
  String get smsRuleTestMatchError => '✗ لم يجد نمط المطابقة أي نتائج';

  @override
  String get smsRuleTestAmountError => '✗ لم يجد نمط المبلغ أي نتائج';

  @override
  String smsRuleTestSuccess(Object amount, Object currency, Object type) {
    return '✓ تم العثور على مطابقة!\nالنوع: $type\nالمبلغ: $amount\nالعملة: $currency';
  }

  @override
  String smsRuleTestRegexError(Object error) {
    return '✗ Regex غير صالح: $error';
  }

  @override
  String get smsRuleRequiredError => 'نمطي المطابقة والمبلغ مطلوبان';

  @override
  String inflationError(Object error) {
    return 'خطأ: $error';
  }

  @override
  String get inflationNoRatesFound => 'لم يتم العثور على معدلات تضخم.';

  @override
  String get inflationAddRate => 'إضافة معدل تضخم';

  @override
  String get inflationDeleteConfirmTitle => 'حذف المعدلات؟';

  @override
  String inflationDeleteConfirmMessage(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count معدلات',
      one: 'هذا المعدل',
    );
    return 'هل أنت متأكد من رغبتك في حذف $_temp0؟';
  }

  @override
  String inflationSelectedCount(Object count) {
    return '$count محدد';
  }

  @override
  String get inflationFiltersTitle => 'فلاتر التضخم';

  @override
  String get inflationCountries => 'الدول';

  @override
  String get inflationPresets => 'النماذج';

  @override
  String deleteCategoryConfirmTitle(Object name) {
    return 'حذف $name؟';
  }

  @override
  String get deleteCategoryMessage => 'هذه الفئة تحتوي على معاملات مرتبطة. ماذا تود أن تفعل؟';

  @override
  String get deleteCategoryReassign => 'إعادة تخصيص المعاملات لفئة أخرى';

  @override
  String get deleteCategoryNewCategory => 'فئة جديدة';

  @override
  String get deleteCategoryDeleteAll => 'حذف كافة المعاملات المرتبطة';

  @override
  String deleteAccountConfirmTitle(Object name) {
    return 'حذف $name؟';
  }

  @override
  String get deleteAccountMessage => 'هذا الحساب قد يحتوي على معاملات مرتبطة. ماذا تود أن تفعل؟';

  @override
  String get deleteAccountReassign => 'إعادة تخصيص المعاملات لحساب آخر';

  @override
  String get deleteAccountNewAccount => 'حساب جديد';

  @override
  String get deleteAccountDeleteAll => 'حذف كافة المعاملات المرتبطة';

  @override
  String get confirmButton => 'تأكيد';

  @override
  String get okButton => 'موافق';

  @override
  String get noItemsFound => 'لم يتم العثور على عناصر.';

  @override
  String get noDataForPeriod => 'لا توجد بيانات لهذه الفترة';

  @override
  String get noDataForRange => 'لا توجد بيانات لهذا النطاق';

  @override
  String get noHistoryData => 'لا توجد بيانات سجل متاحة';

  @override
  String get disabledByGlobalSync => 'معطل بسبب المزامنة العالمية';

  @override
  String dateCreatedLabel(Object date) {
    return 'تاريخ الإنشاء: $date';
  }

  @override
  String get anyLabel => 'أي';

  @override
  String get balanceDisplayLabel => 'عرض الرصيد';

  @override
  String currenciesActiveLabel(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عملات نشطة',
      one: 'عملة واحدة نشطة',
    );
    return '$_temp0';
  }

  @override
  String get searchCountryLabel => 'بحث عن دولة';

  @override
  String get addNewIconLabel => 'إضافة أيقونة جديدة';

  @override
  String get noIconsFoundLabel => 'لم يتم العثور على أيقونات';

  @override
  String get addNewStyleLabel => 'إضافة نمط جديد';

  @override
  String get styleNameLabel => 'اسم النمط';

  @override
  String get pleaseEnterStyleName => 'يرجى إدخال اسم النمط';

  @override
  String get colorLabel => 'اللون';

  @override
  String get netBalanceMetric => 'صافي الرصيد';

  @override
  String get investedMetric => 'المستثمر';

  @override
  String get realizedMetric => 'المحقق';

  @override
  String get feesMetric => 'الرسوم';

  @override
  String get persistFiltersLabel => 'الاحتفاظ بالفلاتر';

  @override
  String get searchByNameHint => 'بحث بالاسم...';

  @override
  String get searchDescriptionHint => 'بحث بالوصف...';

  @override
  String get advancedFiltersTitle => 'فلاتر متقدمة';

  @override
  String get transactionTypeLabel => 'نوع المعاملة';

  @override
  String get assetFiltersTitle => 'فلاتر الأصول';

  @override
  String get minValueLabel => 'أقل قيمة';

  @override
  String get maxValueLabel => 'أعلى قيمة';

  @override
  String get assetTypesLabel => 'أنواع الأصول';

  @override
  String get allLabel => 'الكل';

  @override
  String get currenciesLabel => 'العملات';

  @override
  String get sourcesLabel => 'المصادر';

  @override
  String get presetsLabel => 'النماذج';

  @override
  String get enterCategoryNameHint => 'أدخل اسم الفئة';

  @override
  String get selectTypeHint => 'اختر النوع';

  @override
  String get hotKeysTitle => 'مفاتيح الاختصار';

  @override
  String get searchHotkeysHint => 'بحث عن مفاتيح الاختصار...';

  @override
  String get noMatchingHotkeys => 'لم يتم العثور على مفاتيح اختصار مطابقة.';

  @override
  String recordingHotkeyTitle(Object label) {
    return 'تسجيل مفتاح اختصار لـ \"$label\"';
  }

  @override
  String get pressKeysHint => 'اضغط على المفاتيح...';

  @override
  String get pressAnyCombinationHint => 'اضغط على أي مزيج من المفاتيح.';

  @override
  String get clearSaveButton => 'مسح / حفظ';

  @override
  String get duplicateHotkeyTooltip => 'مفتاح اختصار مكرر';

  @override
  String usedByLabel(Object action) {
    return 'مستخدم من قبل $action';
  }

  @override
  String get hkCategoryNavigation => 'التنقل';

  @override
  String get hkCategoryDashboardTabs => 'تبويبات لوحة المعلومات (Ctrl + 1/2/3)';

  @override
  String get hkCategoryDataTabs => 'تبويبات البيانات (Ctrl + 1/2/3)';

  @override
  String get hkCategoryPeriodControl => 'التحكم في الفترة';

  @override
  String get hkCategoryActions => 'الإجراءات';

  @override
  String get hkCategorySelectionMode => 'وضع التحديد';

  @override
  String get hkActionBack => 'عام: عودة / خروج';

  @override
  String get hkActionDashboard => 'الذهاب للوحة المعلومات';

  @override
  String get hkActionAccounts => 'الذهاب للحسابات';

  @override
  String get hkActionTransactions => 'الذهاب للمعاملات';

  @override
  String get hkActionCategories => 'الذهاب للفئات';

  @override
  String get hkActionData => 'الذهاب للبيانات / الأسعار';

  @override
  String get hkActionSettings => 'الذهاب للإعدادات';

  @override
  String get hkActionDashboardTab1 => 'تبويب التقويم';

  @override
  String get hkActionDashboardTab2 => 'تبويب الفئات';

  @override
  String get hkActionDashboardTab3 => 'تبويب الرصيد';

  @override
  String get hkActionDataTab1 => 'أسعار الصرف';

  @override
  String get hkActionDataTab2 => 'التضخم';

  @override
  String get hkActionDataTab3 => 'الأصول';

  @override
  String get hkActionPrevPeriod => 'الفترة السابقة';

  @override
  String get hkActionNextPeriod => 'الفترة التالية';

  @override
  String get hkActionAddAction => 'إجراء إضافة عام';

  @override
  String get hkActionAccountsSelectionClose => 'الحسابات: إغلاق';

  @override
  String get hkActionAccountsSelectionAll => 'الحسابات: تحديد الكل';

  @override
  String get hkActionAccountsSelectionDelete => 'الحسابات: حذف';

  @override
  String get hkActionAccountsSelectionChangeType => 'الحسابات: تغيير النوع';

  @override
  String get hkActionCategoriesSelectionClose => 'الفئات: إغلاق';

  @override
  String get hkActionCategoriesSelectionAll => 'الفئات: تحديد الكل';

  @override
  String get hkActionCategoriesSelectionDelete => 'الفئات: حذف';

  @override
  String get hkActionCategoriesSelectionChangeType => 'الفئات: تغيير النوع';

  @override
  String get hkActionDataSelectionClose => 'البيانات: إغلاق';

  @override
  String get hkActionDataSelectionAll => 'البيانات: تحديد الكل';

  @override
  String get hkActionDataSelectionDelete => 'البيانات: حذف';

  @override
  String get hkActionDataSelectionChangePreset => 'البيانات: تغيير النموذج';

  @override
  String get styNotFound => 'لم يتم العثور على النمط.';

  @override
  String get stySaveChanges => 'حفظ التغييرات';

  @override
  String get styAddIcon => 'إضافة أيقونة';

  @override
  String get smsOnlyAndroid => 'استيراد SMS متاح على أندرويد فقط';

  @override
  String get smsImportSms => 'استيراد SMS';

  @override
  String get smsPermissionRequired => 'إذن SMS مطلوب';

  @override
  String get smsPermissionRationale => 'لاستيراد المعاملات من الرسائل القصيرة، نحتاج إلى إذن لقراءة رسائلك.';

  @override
  String get smsGrantPermission => 'منح الإذن';

  @override
  String get smsNoPresets => 'لا توجد نماذج مهيأة. انقر + لإضافة واحد.';

  @override
  String get smsImportDescription => 'استيراد المعاملات من الرسائل القصيرة. اختر نطاقاً زمنياً:';

  @override
  String get smsLast7Days => 'آخر 7 أيام';

  @override
  String get smsAllTime => 'كل الأوقات';

  @override
  String smsFilterLabel(Object filter) {
    return 'تصفية: $filter';
  }

  @override
  String get smsEditPreset => 'تعديل النموذج';

  @override
  String get smsNewPreset => 'نموذج جديد';

  @override
  String get smsPresetNameHint => 'مثال: بنكي';

  @override
  String get smsSenderFilter => 'تصفية المرسل';

  @override
  String get smsSenderFilterHint => 'مثال: ALTA أو +381...';

  @override
  String get smsSenderFilterHelper => 'تصفية الرسائل حسب اسم المرسل أو رقم الهاتف';

  @override
  String get smsDefaults => 'الافتراضيات';

  @override
  String get smsDefaultAccount => 'الحساب الافتراضي';

  @override
  String get smsDefaultCategory => 'الفئة الافتراضية';

  @override
  String get smsImportMessages => 'استيراد الرسائل';

  @override
  String get smsSelectDefaultsFirst => 'حدد الافتراضيات أولاً';

  @override
  String get smsCustomRange => 'نطاق مخصص';

  @override
  String smsImportSuccessCount(Object count) {
    return 'نجح: تم استيراد $count معاملات';
  }

  @override
  String get smsParsingRules => 'قواعد التحليل';

  @override
  String get smsNoRules => 'لم يتم تعريف قواعد. انقر + لإضافة واحدة.';

  @override
  String smsMatchLabel(Object pattern) {
    return 'المطابقة: $pattern';
  }

  @override
  String get smsNameSenderRequired => 'الاسم وتصفية المرسل مطلوبان';

  @override
  String get smsCategoryKeywords => 'الكلمات المفتاحية للفئات';

  @override
  String get smsCategoryKeywordsSubtitle => 'ربط الكلمات المفتاحية في نص الرسالة بالفئات';

  @override
  String get smsNoKeywordRules => 'لا توجد قواعد كلمات مفتاحية. انقر + لإضافة واحدة.';

  @override
  String get smsAddKeywordRule => 'إضافة قاعدة كلمة مفتاحية';

  @override
  String get smsKeyword => 'كلمة مفتاحية';

  @override
  String get smsKeywordHint => 'مثال: بقالة، Netflix';

  @override
  String get smsKeywordHelper => 'نص جزئي غير حساس لحالة الأحرف للمطابقة في نص الرسالة';

  @override
  String get smsSelectCategoryHint => 'اختر فئة';

  @override
  String get dshSelectDateDescription => 'افتح التقويم لاختيار تاريخ أو نطاق محدد';

  @override
  String get dshCurrencyDescription => 'اختر العملة الأساسية للعرض';

  @override
  String get dshChangeViewTooltip => 'تغيير العرض';

  @override
  String get dshChangeViewDescription => 'التبديل بين العرض الشهري والسنوي';

  @override
  String get dshMonthlyAbbreviation => 'ش';

  @override
  String get dshYearlyAbbreviation => 'س';

  @override
  String dshBalancesOnDate(Object date) {
    return 'الأرصدة في $date';
  }

  @override
  String get dshSearchCurrency => 'بحث عن عملة';

  @override
  String get dshUnknownCategory => 'غير معروف';

  @override
  String get pckSelectItem => 'تحديد عنصر';

  @override
  String get pckSelectItems => 'تحديد عناصر';

  @override
  String get pckClearAll => 'مسح الكل';

  @override
  String get pckSelectIcon => 'تحديد أيقونة';

  @override
  String get pckMaterialIcons => 'أيقونات Material';

  @override
  String get pckCustomIcons => 'أيقونات مخصصة';

  @override
  String get fltAmountFrom => 'المبلغ من';

  @override
  String get fltAmountTo => 'المبلغ إلى';

  @override
  String get fltSelectRange => 'تحديد نطاق';

  @override
  String get fltAdvancedFilterTooltip => 'تصفية متقدمة';

  @override
  String get fltAdvancedFilterDescription => 'تصفية المعاملات حسب الحساب أو الفئة أو المبلغ';

  @override
  String get fltSortOrderDescription => 'التبديل بين الترتيب التصاعدي والتنازلي';

  @override
  String get fltAccountFiltersTitle => 'فلاتر الحسابات';

  @override
  String get fltNameLabel => 'الاسم';

  @override
  String get fltAccountTypesLabel => 'أنواع الحسابات';

  @override
  String get fltFilterCurrenciesLabel => 'تصفية العملات';

  @override
  String get fltSelectCurrenciesLabel => 'تحديد العملات';

  @override
  String get fltFilterCategoriesTitle => 'تصفية الفئات';

  @override
  String get exchAddExchangeRate => 'إضافة سعر صرف';

  @override
  String get exchEditExchangeRate => 'تعديل سعر الصرف';

  @override
  String get exchAddRateDescription => 'أدخل سعر تحويل بين عملتين يدوياً';

  @override
  String get exchNoRatesFound => 'لم يتم العثور على أسعار صرف.';

  @override
  String get exchChangePreset => 'تغيير النموذج';

  @override
  String get exchFromCurrency => 'من عملة';

  @override
  String get exchToCurrency => 'إلى عملة';

  @override
  String get exchRate => 'السعر';

  @override
  String get exchPresetIdLabel => 'معرّف النموذج';

  @override
  String exchPresetValue(Object preset) {
    return 'النموذج: $preset';
  }

  @override
  String get exchSelectRange => 'تحديد نطاق';

  @override
  String get exchPreviousPeriodDescription => 'الذهاب إلى اليوم أو الشهر أو العام السابق';

  @override
  String get exchNextPeriodDescription => 'الذهاب إلى اليوم أو الشهر أو العام التالي';

  @override
  String get exchFilterDescription => 'تصفية الأسعار حسب العملة من/إلى ومعرّف النموذج';

  @override
  String get exchSelectDateDescription => 'اختر تاريخاً أو نطاقاً محدداً لعرض الأسعار التاريخية';

  @override
  String get exchSortOrderDescription => 'التبديل بين الترتيب التصاعدي والتنازلي حسب التاريخ/السعر';

  @override
  String get exchFilterExchangeRates => 'تصفية أسعار الصرف';

  @override
  String get exchExitSelectionDescription => 'الخروج من وضع تحديد أسعار الصرف';

  @override
  String get exchSelectAllDescription => 'تحديد كافة أسعار الصرف المعروضة';

  @override
  String get exchDeselectAllDescription => 'إلغاء تحديد كافة الأسعار';

  @override
  String get exchChangePresetDescription => 'تحديث معرّف النموذج لكافة أسعار الصرف المحددة';

  @override
  String get exchDeleteSelectedDescription => 'حذف كافة أسعار الصرف المحددة نهائياً';

  @override
  String get exchDeleteExchangeRatesTitle => 'حذف أسعار الصرف';

  @override
  String exchDeleteConfirmMessage(Object count) {
    return 'هل أنت متأكد من رغبتك في حذف $count أسعار صرف؟';
  }

  @override
  String get exchUpdatePresetTitle => 'تحديث النموذج';

  @override
  String get exchUpdatePresetMessage => 'أدخل معرّف النموذج الجديد للعناصر المحددة:';

  @override
  String dashboardUnconvertibleCurrencies(String currencies) {
    return 'تعذّر تحويل $currencies، وهي غير مُدرجة في الإجمالي';
  }

  @override
  String get addAccountBeforeTransactionDescription => 'تحتاج المعاملة إلى حساب. أنشئ حسابك الأول للبدء';

  @override
  String get selectDialogEmptyState => 'لا يوجد شيء للاختيار منه بعد';

  @override
  String get selectDialogNoMatches => 'لا توجد نتائج مطابقة لبحثك';

  @override
  String get addButton => 'إضافة';

  @override
  String get retryButton => 'إعادة المحاولة';

  @override
  String get unknownLabel => 'غير معروف';

  @override
  String get globalLabel => 'عالمي';

  @override
  String dateWithValueLabel(String date) {
    return 'التاريخ: $date';
  }

  @override
  String selectColorTitle(String label) {
    return 'اختر لون $label';
  }

  @override
  String get assetAddTitle => 'إضافة بيانات الأصل';

  @override
  String get assetEditTitle => 'تعديل بيانات الأصل';

  @override
  String get assetAddDescription => 'تسجيل قيمة أصل معين أو كميته';

  @override
  String get assetNameLabel => 'اسم الأصل (مثل سهم آبل)';

  @override
  String get assetIdLabel => 'معرّف الأصل (مثل AAPL)';

  @override
  String get assetValueLabel => 'القيمة (سعر الوحدة)';

  @override
  String get assetTypeOptionalLabel => 'نوع الأصل (اختياري)';

  @override
  String get assetLinkedAccountOptionalLabel => 'الحساب المرتبط (اختياري)';

  @override
  String get assetNameRequiredError => 'أدخل اسمًا للأصل';

  @override
  String get assetIdRequiredError => 'أدخل معرّفًا للأصل، مثل AAPL';

  @override
  String get assetValueInvalidError => 'أدخل رقمًا، مثل 150.25';

  @override
  String get assetNoAssetsFound => 'لم يتم العثور على أصول.';

  @override
  String assetError(String error) {
    return 'خطأ: $error';
  }

  @override
  String get assetDeleteConfirmTitle => 'حذف الأصول؟';

  @override
  String assetDeleteConfirmMessage(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
      
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString أصول',
      one: 'هذا الأصل',
    );
    return 'هل أنت متأكد من رغبتك في حذف $_temp0؟';
  }

  @override
  String get assetDeleteSelectedDescription => 'حذف جميع سجلات الأصول المحددة نهائيًا';

  @override
  String get inflationEditRate => 'تعديل معدل التضخم';

  @override
  String get inflationAddDescription => 'أدخل نسبة تضخم جديدة لتاريخ وبلد محددين';

  @override
  String get inflationPercentLabel => 'نسبة التضخم (%)';

  @override
  String get inflationPercentHint => 'مثل 2.5';

  @override
  String get inflationPercentInvalidError => 'أدخل رقمًا، مثل 2.5';

  @override
  String get inflationCountryGlobal => 'البلد: عالمي';

  @override
  String inflationCountryNamed(String country) {
    return 'البلد: $country';
  }

  @override
  String get inflationUseWorldwideRate => 'استخدام المعدل العالمي';

  @override
  String get pickerSingleDate => 'تاريخ واحد';

  @override
  String get pickerRange => 'نطاق';

  @override
  String get dateStepDay => 'يوم';

  @override
  String get dateStepMonth => 'شهر';

  @override
  String get dateStepYear => 'سنة';

  @override
  String get feeStructureTitle => 'هيكل الرسوم';

  @override
  String get feeNoRulesApplied => 'لم تُطبَّق أي قواعد رسوم.';

  @override
  String get feeAddRule => 'إضافة قاعدة رسوم';

  @override
  String get feeFixedFee => 'رسوم ثابتة';

  @override
  String get feePercentFee => 'رسوم بالنسبة المئوية';

  @override
  String get feeTaxRate => 'معدل الضريبة';

  @override
  String get feeUnknownRule => 'قاعدة غير معروفة';

  @override
  String get feeRatePercentLabel => 'المعدل (%)';

  @override
  String get feeTaxRatePercentLabel => 'معدل الضريبة (%)';

  @override
  String get feeCostBasisLabel => 'أساس التكلفة';

  @override
  String deleteAccountsConfirmTitle(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
      
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString حسابات',
      one: 'هذا الحساب',
    );
    return 'حذف $_temp0؟';
  }

  @override
  String get deleteAccountsConfirmMessage => 'هل تريد بالتأكيد حذف الحسابات المحددة؟ ستُحذف جميع المعاملات المرتبطة بها.';

  @override
  String get changeAccountTypeTitle => 'تغيير نوع الحساب';

  @override
  String get accountsPreviousPeriodDescription => 'الانتقال إلى الشهر أو السنة السابقة';

  @override
  String get accountsNextPeriodDescription => 'الانتقال إلى الشهر أو السنة التالية';

  @override
  String get accountsFilterDescription => 'تصفية الحسابات حسب النوع أو حالة الإخفاء';

  @override
  String get accountsSelectDateDescription => 'اختر تاريخًا محددًا لعرض الأرصدة السابقة';

  @override
  String get accountsSortDescription => 'التبديل بين ترتيب الأرصدة تصاعديًا وتنازليًا';

  @override
  String get smsRuleCategoryOptional => 'الفئة (اختياري)';

  @override
  String get smsRuleCategoryHelp => 'تجاوز الفئة لهذه القاعدة';
}
