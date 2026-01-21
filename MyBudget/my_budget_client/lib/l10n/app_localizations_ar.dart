// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get helloWorld => 'مرحبا بالعالم!';

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
  String get addAccountDescription => 'إنشاء حساب بنكي أو محفظة أو أصل جديد';

  @override
  String get addAccountDialogTitle => 'إضافة حساب جديد';

  @override
  String get accountNameHint => 'اسم الحساب';

  @override
  String get initialBalanceHint => 'الرصيد الافتتاحي';

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
  String get formValidationPleaseEnterName => 'الرجاء إدخال اسم';

  @override
  String get formValidationPleaseEnterBalance => 'الرجاء إدخال الرصيد';

  @override
  String get formValidationPleaseEnterValidNumber => 'الرجاء إدخال رقم صحيح';

  @override
  String get formValidationPleaseSelectCurrency => 'الرجاء اختيار العملة';

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
  String get filePickerChooserTitle => 'اختيار ملف';

  @override
  String get imagePickerChooserTitle => 'اختيار صورة';

  @override
  String get totalNetWorth => 'إجمالي صافي القيمة';

  @override
  String get currencyBreakdown => 'تفصيل العملات';

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
    return 'هل أنت متأكد أنك تريد حذف هذا $item وجميع بياناته؟';
  }

  @override
  String get deleteAccountsConfirmationTitle => 'حذف الحسابات؟';

  @override
  String deleteAccountsConfirmationMessage(Object count) {
    return 'حذف $count حسابات محددة ومعاملاتها؟';
  }

  @override
  String get deleteAccountDialogReassign => 'إعادة تعيين المعاملات لحساب آخر';

  @override
  String get deleteAccountDialogDeleteAll => 'حذف جميع المعاملات المرتبطة';

  @override
  String get deleteAccountDialogMessage => 'قد يحتوي هذا الحساب على معاملات مرتبطة. ماذا تود أن تفعل؟';

  @override
  String get newAccountLabel => 'حساب جديد';

  @override
  String get warningOverwriteTitle => 'تحذير: الكتابة فوق البيانات؟';

  @override
  String get warningOverwriteMessage => 'استعادة نسخة احتياطية ستحذف جميع البيانات الحالية وتستبدلها بالنسخة الاحتياطية. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get restoreOverwriteButton => 'استعادة وكتابة فوق';

  @override
  String get importSuccess => 'تم الاستيراد بنجاح.';

  @override
  String importFailed(Object error) {
    return 'فشل الاستيراد: $error';
  }

  @override
  String deleteCategoriesConfirmationTitle(Object count) {
    return 'حذف $count فئات؟';
  }

  @override
  String get deleteCategoriesConfirmationMessage => 'هل أنت متأكد أنك تريد حذف الفئات المحددة؟';

  @override
  String get changeCategoryTypeDialogTitle => 'تغيير نوع الفئة';

  @override
  String get noCategoriesCreated => 'لم يتم إنشاء فئات بعد.';

  @override
  String get addCategoryTooltip => 'إضافة فئة';

  @override
  String get addCategoryDescription => 'إنشاء فئة جديدة للمصروفات أو الدخل';

  @override
  String get previousPeriodTooltip => 'الفترة السابقة';

  @override
  String get previousPeriodDescription => 'الذهاب إلى الشهر أو السنة السابقة';

  @override
  String get nextPeriodTooltip => 'الفترة التالية';

  @override
  String get nextPeriodDescription => 'الذهاب إلى الشهر أو السنة التالية';

  @override
  String get filterTooltip => 'تصفية';

  @override
  String get filterCategoriesDescription => 'تصفية الفئات حسب النوع (دخل/مصروف)';

  @override
  String get selectDateTooltip => 'تحديد التاريخ';

  @override
  String get selectDateDescription => 'اختيار نطاق زمني محدد لعرض الإجماليات';

  @override
  String get sortOrderTooltip => 'ترتيب الفرز';

  @override
  String get sortOrderDescription => 'التبديل بين الترتيب التصاعدي والتنازلي حسب المبلغ';

  @override
  String totalCountLabel(Object count) {
    return 'الإجمالي: $count';
  }

  @override
  String get closeSelectionTooltip => 'إغلاق التحديد';

  @override
  String get exitSelectionDescription => 'الخروج من وضع التحديد';

  @override
  String selectedCountLabel(Object count) {
    return 'تم تحديد $count';
  }

  @override
  String get categoryNameLabel => 'اسم الفئة';

  @override
  String get categoriesChangeButton => 'تغيير';

  @override
  String get parentCategoryLabel => 'الفئة الرئيسية';

  @override
  String get styleLabel => 'النمط (الأيقونة واللون)';

  @override
  String get typeLabel => 'النوع';

  @override
  String get deleteTransactionsConfirmationTitle => 'حذف المعاملات';

  @override
  String deleteTransactionsConfirmationMessage(Object count) {
    return 'هل أنت متأكد أنك تريد حذف $count معاملات محددة؟';
  }

  @override
  String get changeDateTooltip => 'تغيير التاريخ';

  @override
  String get changeDateDescription => 'تحديث التاريخ لجميع المعاملات المحددة';

  @override
  String get changeCategoryTooltip => 'تغيير الفئة';

  @override
  String get changeCategoryDescription => 'تحديث الفئة لجميع المعاملات المحددة';

  @override
  String get deleteTransactionsTooltip => 'حذف المحدد';

  @override
  String get deleteTransactionsDescription => 'حذف جميع المعاملات المحددة نهائيًا';

  @override
  String get exitTransactionsSelectionDescription => 'الخروج من وضع تحديد المعاملات';

  @override
  String quantityLabel(Object quantity) {
    return 'الكمية: $quantity';
  }

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
  String get amountLabel => 'المبلغ';

  @override
  String get quantityFormLabel => 'الكمية';

  @override
  String get selectAccountTitle => 'اختيار حساب';

  @override
  String get selectCategoryTitle => 'اختيار فئة';

  @override
  String get selectCurrencyTitle => 'اختيار عملة';

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
  String get selectDateLabel => 'تحديد التاريخ';

  @override
  String get swapAccountsTooltip => 'تبديل الحسابات';

  @override
  String get incomeType => 'دخل';

  @override
  String get expenseType => 'مصروف';

  @override
  String get failedToLoadData => 'فشل تحميل البيانات';

  @override
  String get invalidAmountError => 'الرجاء إدخال رقم صحيح';

  @override
  String get emptyAmountError => 'الرجاء إدخال مبلغ';

  @override
  String get selectAccountError => 'الرجاء اختيار حساب';

  @override
  String get selectCategoryError => 'الرجاء اختيار فئة';

  @override
  String get selectDateError => 'الرجاء اختيار تاريخ';

  @override
  String get currencyLockedMessage => 'مقفول بعملة الحساب المصدر';

  @override
  String get totalValueLabel => 'القيمة الإجمالية';

  @override
  String get feeLabel => 'الرسوم';

  @override
  String get exchangeRateLabel => 'سعر الصرف';

  @override
  String get pricePerUnitLabel => 'السعر لكل وحدة';

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
    return 'تحويل لـ $action $assetName';
  }

  @override
  String get swapDirectionTooltip => 'تبديل الاتجاه';

  @override
  String get availablePresetsLabel => 'الإعدادات المسبقة المتاحة:';

  @override
  String get updateButton => 'تحديث';

  @override
  String get newPresetButton => 'إعداد مسبق جديد';

  @override
  String get amountToAddToAccountLabel => 'المبلغ للإضافة إلى الحساب:';

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
  String get linkedAccountLabel => 'حساب مرتبط';

  @override
  String get selectLinkedAccountTitle => 'اختيار حساب مرتبط';

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
  String get persistAdvancedFiltersLabel => 'الحفاظ على الفلاتر المتقدمة';

  @override
  String get hotKeysLabel => 'مفاتيح الاختصار';

  @override
  String get smsImportLabel => 'استيراد الرسائل القصيرة';

  @override
  String get smsImportSubtitle => 'استيراد المعاملات من رسائل البنك القصيرة';

  @override
  String get apiManagementLabel => 'إدارة API';

  @override
  String get dataLabel => 'البيانات';

  @override
  String get syncSettingsLabel => 'إعدادات المزامنة';

  @override
  String get syncSettingsSubtitle => 'مزامنة P2P عبر Syncthing';

  @override
  String get importDataLabel => 'استيراد البيانات';

  @override
  String get exportDataLabel => 'تصدير البيانات';

  @override
  String get exportFormatMessage => 'اختر التنسيق:\n\nJSON: نسخة احتياطية كاملة لجميع البيانات.\nCSV: تقرير مقروء للمعاملات.';

  @override
  String get jsonFormat => 'JSON';

  @override
  String get csvFormat => 'CSV';

  @override
  String get importExchangeRatesLabel => 'استيراد أسعار الصرف (CSV/JSON)';

  @override
  String get resetDataLabel => 'إعادة تعيين البيانات للافتراضي';

  @override
  String get resetDataSubtitle => 'سيؤدي هذا إلى حذف جميع البيانات واستعادة الإعدادات الافتراضية.';

  @override
  String get debugMenuLabel => 'قائمة التصحيح';

  @override
  String get debugMenuSubtitle => 'أدوات المطور الداخلية';

  @override
  String get exportSuccessMessage => 'تم التصدير بنجاح';

  @override
  String exportFailedMessage(Object error) {
    return 'فشل التصدير: $error';
  }

  @override
  String get importSuccessMessage => 'تم الاستيراد بنجاح';

  @override
  String importFailedMessage(Object error) {
    return 'فشل الاستيراد: $error';
  }

  @override
  String get resetDataConfirmationTitle => 'إعادة تعيين البيانات؟';

  @override
  String get resetDataConfirmationMessage => 'تحذير! سيؤدي هذا إلى حذف جميع معاملاتك وحساباتك وإعداداتك.\n\nستتم استعادة التطبيق إلى حالته الأولية مع البيانات الافتراضية.\nلا يمكن التراجع عن هذا الإجراء.';

  @override
  String get resetEverythingButton => 'إعادة تعيين الكل';

  @override
  String get resetSuccessMessage => 'تم إعادة تعيين البيانات واستعادة الافتراضيات.';

  @override
  String resetFailedMessage(Object error) {
    return 'فشل إعادة التعيين: $error';
  }

  @override
  String get importParsingStep => 'جاري تحليل ملفات CSV...';

  @override
  String get importFetchingRatesStep => 'جاري جلب أسعار الصرف...';

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
  String get importSelectionHelp => 'اختر \'OneMoney\' للهجرة، \'MyBudget\' لإضافة معاملات، أو \'استعادة النسخة الاحتياطية\' للكتابة فوق جميع البيانات.';

  @override
  String get importCreateAllNew => 'إنشاء الكل كجديد';

  @override
  String importNewAccountFound(Object accountName) {
    return 'تم العثور على حساب جديد: \"$accountName\"';
  }

  @override
  String importMapAccountTitle(Object accountName) {
    return 'تخصيص \"$accountName\" إلى...';
  }

  @override
  String get importMapToExisting => 'تخصيص للموجود';

  @override
  String get importCreateNew => 'إنشاء جديد';

  @override
  String importNewCategoryFound(Object categoryName) {
    return 'تم العثور على فئة جديدة: \"$categoryName\"';
  }

  @override
  String importMapCategoryTitle(Object categoryName) {
    return 'تخصيص \"$categoryName\" إلى...';
  }

  @override
  String importNewCurrencyFound(Object currencyName) {
    return 'تم العثور على عملة جديدة: \"$currencyName\"';
  }

  @override
  String importMapCurrencyTitle(Object currencyName) {
    return 'تخصيص \"$currencyName\" إلى...';
  }

  @override
  String get importSkipAll => 'تجاهل الكل';

  @override
  String get importImportAll => 'استيراد الكل';

  @override
  String get importPotentialDuplicate => 'محتمل أن يكون مكرراً:';

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
  String get importSkip => 'تجاهل';

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
  String get importingTitle => 'جاري الاستيراد...';

  @override
  String get importCompleteTitle => 'اكتمل الاستيراد';

  @override
  String get importStartOverTooltip => 'البدء من جديد';

  @override
  String get importDataTitle => 'استيراد البيانات';

  @override
  String importAccountsCreatedLabel(Object count) {
    return 'الحسابات الجديدة المنشأة: $count';
  }

  @override
  String importCategoriesCreatedLabel(Object count) {
    return 'الفئات الجديدة المنشأة: $count';
  }

  @override
  String importTransactionsImportedLabel(Object count) {
    return 'المعاملات المستوردة: $count';
  }

  @override
  String importDuplicatesSkippedLabel(Object count) {
    return 'المكررات التي تم تجاهلها: $count';
  }

  @override
  String get searchHint => 'بحث';

  @override
  String get debugAllDataClearedMessage => 'تم مسح جميع البيانات وإعادة تعبئتها بالقيم الافتراضية.';

  @override
  String get debugClearAllDataLabel => 'مسح جميع البيانات (وإعادة التعبئة الافتراضية)';

  @override
  String get debugMinimumDataSeededMessage => 'تمت تعبئة الحد الأدنى من البيانات.';

  @override
  String get debugSeedMinimumDataLabel => 'تعبئة الحد الأدنى من البيانات';

  @override
  String get debugMediumDataSeededMessage => 'تمت تعبئة بيانات متوسطة.';

  @override
  String get debugSeedMediumDataLabel => 'تعبئة بيانات متوسطة';

  @override
  String get debugMaximumDataSeededMessage => 'تمت تعبئة أقصى قدر من البيانات.';

  @override
  String get debugSeedMaximumDataLabel => 'تعبئة أقصى قدر من البيانات (لاختبار الأداء)';

  @override
  String get debugRunningInDebugModeLabel => 'يعمل في وضع التصحيح';

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
  String get noCurrenciesSelected => 'لم يتم اختيار عملات.';

  @override
  String get incomeLabel => 'دخل';

  @override
  String get expenseLabel => 'مصروف';

  @override
  String get failedToLoadDashboard => 'فشل تحميل لوحة القيادة';

  @override
  String get dashboardCalendarTab => 'التقويم';

  @override
  String get dashboardCalendarTooltip => 'عرض التقويم';

  @override
  String get dashboardCalendarDescription => 'عرض المعاملات بتنسيق التقويم';

  @override
  String get dashboardCategoriesTab => 'الفئات';

  @override
  String get dashboardCategoriesTooltip => 'تحليل الفئات';

  @override
  String get dashboardCategoriesDescription => 'تفصيل المصاريف حسب الفئة';

  @override
  String get dashboardBalanceTab => 'الرصيد';

  @override
  String get dashboardBalanceTooltip => 'سجل الرصيد';

  @override
  String get dashboardBalanceDescription => 'تتبع صافي القيمة مع مرور الوقت';

  @override
  String get dashboardExpensesLabel => 'المصاريف';

  @override
  String get dashboardIncomeLabel => 'الدخل';

  @override
  String get manageIconsTitle => 'إدارة الأيقونات';

  @override
  String get noIconsCreated => 'لم يتم إنشاء أي أيقونات بعد.';

  @override
  String get failedToLoadIcons => 'فشل تحميل الأيقونات.';

  @override
  String get cannotDeleteTransferIcon => 'لا يمكن حذف أيقونة التحويل.';

  @override
  String get deleteIconsDialogTitle => 'حذف الأيقونات';

  @override
  String deleteIconsConfirmationMessage(Object count) {
    return 'هل أنت متأكد من أنك تريد حذف $count من الأيقونات المختارة؟';
  }

  @override
  String deleteIconsWithSkipTransferMessage(Object count) {
    return 'هل أنت متأكد من أنك تريد حذف $count من الأيقونات المختارة؟ (سيتم تخطي أيقونة التحويل)';
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
  String get deleteMultipleAccountsMessage => 'هل أنت متأكد من أنك تريد حذف الحسابات المختارة؟ سيتم حذف جميع المعاملات المرتبطة.';

  @override
  String get changeAccountTypeDialogTitle => 'تغيير نوع الحساب';

  @override
  String editAccountTitle(Object name) {
    return 'تعديل: $name';
  }

  @override
  String get balanceCalculatedFromAsset => 'يتم حساب الرصيد من كمية الأصل * السعر';

  @override
  String get selectAccountTypeTitle => 'اختر نوع الحساب';

  @override
  String get selectCountryTitle => 'اختر الدولة';

  @override
  String get selectIconSubtitle => 'اختر أيقونة';

  @override
  String get bindToAssetLabel => 'ربط بأصل (اختياري)';

  @override
  String get selectAssetTitle => 'اختر الأصل';

  @override
  String get selectedAssetLabel => 'الأصل المختار';

  @override
  String get balanceAutoCalculatedLabel => 'يتم حساب الرصيد تلقائيًا';

  @override
  String get tapToBindAssetLabel => 'اضغط لربط أصل';

  @override
  String get assetQuantityLabel => 'كمية الأصل';

  @override
  String get linkedAssetsTitle => 'الأصول المرتبطة';

  @override
  String get noneLabel => 'لا يوجد';

  @override
  String get accountTypeLabel => 'نوع الحساب';

  @override
  String get formValidationPleaseSelectAccountType => 'يرجى اختيار نوع الحساب';

  @override
  String get iconLabel => 'أيقونة';

  @override
  String get languageLabel => 'اللغة';

  @override
  String get systemDefaultLabel => 'افتراضي النظام';

  @override
  String get selectLanguageTitle => 'اختر اللغة';
}
