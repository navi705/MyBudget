// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get collapseMenuTooltip => 'মেনু সংকুচিত করুন';

  @override
  String get expandMenuTooltip => 'মেনু প্রসারিত করুন';

  @override
  String get helloWorld => 'ওহে বিশ্ব!';

  @override
  String get accountsAppBarTitle => 'অ্যাকাউন্ট';

  @override
  String accountsBalanceLabel(Object balance) {
    return 'ব্যালেন্স: $balance';
  }

  @override
  String get accountsLoadFailure => 'অ্যাকাউন্ট লোড করতে ব্যর্থ হয়েছে';

  @override
  String get accountsEmptyState => 'কোন অ্যাকাউন্ট নেই';

  @override
  String get accountsRefreshTooltip => 'রিফ্রেশ করুন';

  @override
  String get accountsAddTooltip => 'অ্যাকাউন্ট যোগ করুন';

  @override
  String get addAccountDescription => 'একটি নতুন ব্যাংক অ্যাকাউন্ট, ওয়ালেট বা সম্পদ তৈরি করুন';

  @override
  String get addAccountDialogTitle => 'নতুন অ্যাকাউন্ট যোগ করুন';

  @override
  String get editAccountDialogTitle => 'অ্যাকাউন্ট সম্পাদনা করুন';

  @override
  String get accountNameHint => 'অ্যাকাউন্টের নাম';

  @override
  String get initialBalanceHint => 'প্রারম্ভিক ব্যালেন্স';

  @override
  String get currencyLabel => 'মুদ্রা';

  @override
  String get cancelButton => 'বাতিল করুন';

  @override
  String get saveButton => 'সংরক্ষণ করুন';

  @override
  String get deleteButton => 'মুছে ফেলুন';

  @override
  String get editButton => 'সম্পাদনা করুন';

  @override
  String get applyButton => 'প্রয়োগ করুন';

  @override
  String get clearButton => 'পরিষ্কার করুন';

  @override
  String get selectButton => 'নির্বাচন করুন';

  @override
  String get selectAllButton => 'সব নির্বাচন করুন';

  @override
  String get deselectAllButton => 'সব নির্বাচন বাতিল করুন';

  @override
  String get deleteSelectedButton => 'নির্বাচিতগুলো মুছুন';

  @override
  String totalCountLabel(Object count) {
    return 'মোট: $count';
  }

  @override
  String selectedCountLabel(Object count) {
    return '$countটি নির্বাচিত';
  }

  @override
  String get formValidationPleaseEnterName => 'অনুগ্রহ করে নাম লিখুন';

  @override
  String get formValidationPleaseEnterBalance => 'অনুগ্রহ করে ব্যালেন্স লিখুন';

  @override
  String get formValidationPleaseEnterValidNumber => 'অনুগ্রহ করে একটি সঠিক সংখ্যা লিখুন';

  @override
  String get formValidationPleaseSelectCurrency => 'অনুগ্রহ করে একটি মুদ্রা নির্বাচন করুন';

  @override
  String get currencyLoadError => 'মুদ্রা লোড করতে ত্রুটি হয়েছে';

  @override
  String get noCurrenciesAvailable => 'কোন মুদ্রা উপলব্ধ নেই';

  @override
  String get categoriesAppBarTitle => 'বিভাগ';

  @override
  String get categoriesScreenBody => 'বিভাগ স্ক্রিন';

  @override
  String get transactionsAppBarTitle => 'লেনদেন';

  @override
  String get transactionsScreenBody => 'লেনদেন স্ক্রিন';

  @override
  String get settingsAppBarTitle => 'সেটিংস';

  @override
  String get settingsScreenBody => 'সেটিংস স্ক্রিন';

  @override
  String get filePickerChooserTitle => 'একটি ফাইল চয়ন করুন';

  @override
  String get imagePickerChooserTitle => 'একটি ছবি চয়ন করুন';

  @override
  String get totalNetWorth => 'মোট নেট মূল্য';

  @override
  String get currencyBreakdown => 'মুদ্রা অনুযায়ী বিভাজন';

  @override
  String get dashboardNetWorthTrend => 'নেট মূল্যের ধরণ';

  @override
  String get dashboardWealthDistributionByAccount => 'সম্পদ বন্টন (অ্যাকাউন্ট অনুযায়ী)';

  @override
  String get dashboardCurrencyExposure => 'মুদ্রার এক্সপোজার';

  @override
  String get dashboardNoAccountsFound => 'কোন অ্যাকাউন্ট পাওয়া যায়নি';

  @override
  String get dashboardTotalNetWorthTrend => 'মোট নেট মূল্যের ধরণ';

  @override
  String get dashboardAccountBalanceTrend => 'অ্যাকাউন্ট ব্যালেন্সের ধরণ';

  @override
  String get dashboardWealthDistribution => 'সম্পদ বন্টন';

  @override
  String get dashboardCurrencyBreakdown => 'মুদ্রা অনুযায়ী বিভাজন';

  @override
  String get metricBalance => 'ব্যালেন্স';

  @override
  String get metricIncome => 'আয়';

  @override
  String get metricExpense => 'ব্যয়';

  @override
  String get metricReal => 'প্রকৃত';

  @override
  String get metricChange => 'পরিবর্তন';

  @override
  String get contextMenuSelect => 'নির্বাচন করুন';

  @override
  String get contextMenuDeselect => 'নির্বাচন বাতিল করুন';

  @override
  String get contextMenuSelectAll => 'সব নির্বাচন করুন';

  @override
  String get contextMenuDeselectAll => 'সব নির্বাচন বাতিল করুন';

  @override
  String get contextMenuAddTransaction => 'লেনদেন যোগ করুন';

  @override
  String get addTransactionDescription => 'একটি নতুন লেনদেন তৈরি করুন';

  @override
  String get contextMenuTransfer => 'স্থানান্তর';

  @override
  String get contextMenuEdit => 'সম্পাদনা করুন';

  @override
  String get contextMenuDelete => 'মুছে ফেলুন';

  @override
  String get contextMenuChangeType => 'ধরণ পরিবর্তন করুন';

  @override
  String deleteConfirmationTitle(Object item) {
    return '$item মুছবেন?';
  }

  @override
  String deleteConfirmationMessage(Object item) {
    return 'আপনি কি নিশ্চিত যে আপনি এই $item এবং এর সমস্ত তথ্য মুছে ফেলতে চান?';
  }

  @override
  String get deleteAccountsConfirmationTitle => 'অ্যাকাউন্টগুলো মুছবেন?';

  @override
  String deleteAccountsConfirmationMessage(Object count) {
    return 'নির্বাচিত $countটি অ্যাকাউন্ট এবং তাদের সব লেনদেন মুছে ফেলবেন?';
  }

  @override
  String get deleteAccountDialogReassign => 'লেনদেনগুলো অন্য একটি অ্যাকাউন্টে সরিয়ে নিন';

  @override
  String get deleteAccountDialogDeleteAll => 'সংশ্লিষ্ট সব লেনদেন মুছে ফেলুন';

  @override
  String get deleteAccountDialogMessage => 'এই অ্যাকাউন্টের সাথে সংশ্লিষ্ট লেনদেন থাকতে পারে। আপনি কি করতে চান?';

  @override
  String get newAccountLabel => 'নতুন অ্যাকাউন্ট';

  @override
  String get warningOverwriteTitle => 'সতর্কতা: তথ্য প্রতিস্থাপন করবেন?';

  @override
  String get warningOverwriteMessage => 'ব্যাকআপ পুনরুদ্ধার করলে বর্তমান সমস্ত তথ্য মুছে যাবে এবং ব্যাকআপ দ্বারা প্রতিস্থাপিত হবে। এটি আর ফিরিয়ে আনা যাবে না।';

  @override
  String get restoreOverwriteButton => 'পুনরুদ্ধার এবং প্রতিস্থাপন করুন';

  @override
  String get importSuccess => 'আমদানি সফলভাবে সম্পন্ন হয়েছে।';

  @override
  String importFailed(Object error) {
    return 'আমদানি ব্যর্থ হয়েছে: $error';
  }

  @override
  String deleteCategoriesConfirmationTitle(Object count) {
    return '$countটি বিভাগ মুছবেন?';
  }

  @override
  String get deleteCategoriesConfirmationMessage => 'আপনি কি নিশ্চিত যে আপনি নির্বাচিত বিভাগগুলো মুছে ফেলতে চান?';

  @override
  String get changeCategoryTypeDialogTitle => 'বিভাগের ধরণ পরিবর্তন করুন';

  @override
  String get noCategoriesCreated => 'এখনও কোন বিভাগ তৈরি করা হয়নি।';

  @override
  String get addCategoryTooltip => 'বিভাগ যোগ করুন';

  @override
  String get addCategoryDescription => 'নতুন আয় বা ব্যয়ের বিভাগ তৈরি করুন';

  @override
  String get previousPeriodTooltip => 'পূর্ববর্তী সময়কাল';

  @override
  String get previousPeriodDescription => 'গত মাস বা বছরে যান';

  @override
  String get nextPeriodTooltip => 'পরবর্তী সময়কাল';

  @override
  String get nextPeriodDescription => 'পরবর্তী মাস বা বছরে যান';

  @override
  String get filterTooltip => 'ফিল্টার করুন';

  @override
  String get filterCategoriesDescription => 'ধরণ অনুযায়ী বিভাগ ফিল্টার করুন (আয়/ব্যয়)';

  @override
  String get selectDateTooltip => 'তারিখ নির্বাচন করুন';

  @override
  String get selectDateDescription => 'মোট হিসাব দেখতে একটি সুনির্দিষ্ট তারিখ পরিসীমা নির্বাচন করুন';

  @override
  String get sortOrderTooltip => 'ক্রমবিন্যাস';

  @override
  String get sortOrderDescription => 'পরিমাণ অনুযায়ী আরোহী এবং অবরোহী ক্রমের মধ্যে পরিবর্তন করুন';

  @override
  String get closeSelectionTooltip => 'নির্বাচন বন্ধ করুন';

  @override
  String get exitSelectionDescription => 'নির্বাচন মোড থেকে প্রস্থান করুন';

  @override
  String get categoryNameLabel => 'বিভাগের নাম';

  @override
  String get categoriesChangeButton => 'পরিবর্তন করুন';

  @override
  String get parentCategoryLabel => 'প্রধান বিভাগ';

  @override
  String get styleLabel => 'শৈলী (আইকন এবং রঙ)';

  @override
  String get typeLabel => 'ধরণ';

  @override
  String get deleteTransactionsConfirmationTitle => 'লেনদেনগুলো মুছে ফেলুন';

  @override
  String deleteTransactionsConfirmationMessage(Object count) {
    return 'আপনি কি নিশ্চিত যে আপনি নির্বাচিত $countটি লেনদেন মুছে ফেলতে চান?';
  }

  @override
  String get exitTransactionsSelectionDescription => 'লেনদেন নির্বাচন মোড থেকে প্রস্থান করুন';

  @override
  String get changeDateTooltip => 'তারিখ পরিবর্তন করুন';

  @override
  String get changeDateDescription => 'নির্বাচিত সমস্ত লেনদেনের তারিখ আপডেট করুন';

  @override
  String get changeCategoryTooltip => 'বিভাগ পরিবর্তন করুন';

  @override
  String get changeCategoryDescription => 'নির্বাচিত সমস্ত লেনদেনের বিভাগ আপডেট করুন';

  @override
  String get deleteTransactionsTooltip => 'নির্বাচিতগুলো মুছুন';

  @override
  String get deleteTransactionsDescription => 'নির্বাচিত সমস্ত লেনদেন স্থায়ীভাবে মুছে ফেলুন';

  @override
  String get amountLabel => 'পরিমাণ';

  @override
  String quantityLabel(Object quantity) {
    return 'পরিমাণ: $quantity';
  }

  @override
  String get quantityFormLabel => 'পরিমাণ/সংখ্যা';

  @override
  String get selectAccountTitle => 'অ্যাকাউন্ট নির্বাচন করুন';

  @override
  String get selectCategoryTitle => 'বিভাগ নির্বাচন করুন';

  @override
  String get selectCurrencyTitle => 'মুদ্রা নির্বাচন করুন';

  @override
  String get accountLabel => 'অ্যাকাউন্ট';

  @override
  String get fromAccountLabel => 'উৎস অ্যাকাউন্ট';

  @override
  String get toAccountLabel => 'গন্তব্য অ্যাকাউন্ট';

  @override
  String get categoryLabel => 'বিভাগ';

  @override
  String get dateLabel => 'তারিখ';

  @override
  String get selectDateLabel => 'তারিখ চয়ন করুন';

  @override
  String get addTransactionTitle => 'লেনদেন যোগ করুন';

  @override
  String get editTransactionTitle => 'লেনদেন সম্পাদনা করুন';

  @override
  String get newTransferTitle => 'নতুন স্থানান্তর';

  @override
  String get editTransferTitle => 'স্থানান্তর সম্পাদনা করুন';

  @override
  String get descriptionLabel => 'বিবরণ';

  @override
  String get descriptionOptionalLabel => 'বিবরণ (ঐচ্ছিক)';

  @override
  String get swapAccountsTooltip => 'অ্যাকাউন্ট অদলবدل করুন';

  @override
  String get incomeType => 'আয়';

  @override
  String get expenseType => 'ব্যয়';

  @override
  String get failedToLoadData => 'তথ্য লোড করতে ব্যর্থ হয়েছে';

  @override
  String get invalidAmountError => 'অনুগ্রহ করে একটি সঠিক সংখ্যা লিখুন';

  @override
  String get emptyAmountError => 'অনুগ্রহ করে একটি পরিমাণ লিখুন';

  @override
  String get selectAccountError => 'অনুগ্রহ করে একটি অ্যাকাউন্ট নির্বাচন করুন';

  @override
  String get selectCategoryError => 'অনুগ্রহ করে একটি বিভাগ নির্বাচন করুন';

  @override
  String get selectDateError => 'অনুগ্রহ করে একটি তারিখ নির্বাচন করুন';

  @override
  String get currencyLockedMessage => 'উৎস অ্যাকাউন্টের মুদ্রায় লক করা হয়েছে';

  @override
  String get totalValueLabel => 'মোট মূল্য';

  @override
  String get feeLabel => 'ফি';

  @override
  String get exchangeRateLabel => 'বিনিময় হার';

  @override
  String get pricePerUnitLabel => 'একক প্রতি মূল্য';

  @override
  String get buyAction => 'কেনা';

  @override
  String get sellAction => 'বিক্রি';

  @override
  String transferToDescription(Object accountName) {
    return '$accountName-এ স্থানান্তর';
  }

  @override
  String transferFromDescription(Object accountName) {
    return '$accountName থেকে স্থানান্তর';
  }

  @override
  String buyDescription(Object assetName) {
    return '$assetName কিনুন';
  }

  @override
  String sellDescription(Object assetName) {
    return '$assetName বিক্রি করুন';
  }

  @override
  String assetTransferDescription(Object action, Object assetName) {
    return '$action $assetName-এর জন্য স্থানান্তর';
  }

  @override
  String get swapDirectionTooltip => 'দিক পরিবর্তন করুন';

  @override
  String get availablePresetsLabel => 'উপলব্ধ প্রিসেট:';

  @override
  String get updateButton => 'আপডেট করুন';

  @override
  String get newPresetButton => 'নতুন প্রিসেট';

  @override
  String get amountToAddToAccountLabel => 'অ্যাকাউন্টে যোগ করার পরিমাণ:';

  @override
  String valueInGlobalLabel(Object currency) {
    return 'গ্লোবাল মান ($currency):';
  }

  @override
  String get feeCommissionLabel => 'ফি (কমিশন)';

  @override
  String get requiredError => 'প্রয়োজনীয়';

  @override
  String currentPriceLabel(Object currency, Object price) {
    return 'বর্তমান মূল্য: $price $currency';
  }

  @override
  String get linkedAccountLabel => 'সংযুক্ত অ্যাকাউন্ট';

  @override
  String get selectLinkedAccountTitle => 'সংযুক্ত অ্যাকাউন্টটি নির্বাচন করুন';

  @override
  String get settingsTitle => 'সেটিংস';

  @override
  String get manageIconsLabel => 'আইকন পরিচালনা';

  @override
  String get manageThemeLabel => 'থিম পরিচালনা';

  @override
  String get mainCurrencyLabel => 'প্রধান মুদ্রা';

  @override
  String get defaultInflationCountryLabel => 'ডিফল্ট মুদ্রাস্ফীতির দেশ';

  @override
  String get persistAdvancedFiltersLabel => 'উন্নত ফিল্টারগুলো স্থায়ী করুন';

  @override
  String get hotKeysLabel => 'হট-কি (শর্টকাট)';

  @override
  String get smsImportLabel => 'SMS আমদানি';

  @override
  String get smsImportSubtitle => 'ব্যাংক SMS থেকে লেনদেন আমদানি করুন';

  @override
  String get apiManagementLabel => 'API ব্যবস্থাপনা';

  @override
  String get dataLabel => 'তথ্য';

  @override
  String get syncSettingsLabel => 'সিঙ্ক্রোনাইজেশন সেটিংস';

  @override
  String get syncSettingsSubtitle => 'Syncthing-এর মাধ্যমে P2P সিঙ্ক';

  @override
  String get themeSettingsTitle => 'থিম সেটিংস';

  @override
  String get appearanceSection => 'চেহারা (Appearance)';

  @override
  String get themeModeLabel => 'থিম মোড';

  @override
  String get systemTheme => 'সিস্টেম';

  @override
  String get lightTheme => 'হালকা';

  @override
  String get darkTheme => 'গাঢ়';

  @override
  String get colorCustomizationSection => 'রঙ কাস্টমাইজেশন';

  @override
  String get primaryColorLabel => 'প্রাথমিক রঙ';

  @override
  String get secondaryColorLabel => 'মাধ্যমিক রঙ';

  @override
  String get surfaceColorLabel => 'সারফেস রঙ';

  @override
  String get windowEffectsSection => 'উইন্ডো এফেক্টস (ডেস্কটপ)';

  @override
  String get enableEffectsLabel => 'উইন্ডো এফেক্টস সক্রিয় করুন';

  @override
  String get windowEffectLabel => 'উইন্ডো এফেক্ট';

  @override
  String get backgroundLabel => 'পটভূমি (Background)';

  @override
  String get removeBackgroundColor => 'পটভূমির রঙ সরান';

  @override
  String get transparentSurfaceLabel => 'স্বচ্ছ সারফেস (কার্ডগুলো)';

  @override
  String get fullyTransparentLabel => 'পুরোপুরি স্বচ্ছ';

  @override
  String get opaqueLabel => 'অস্বচ্ছ';

  @override
  String opacityLabel(Object value) {
    return 'স্বচ্ছতা (Opacity): $value%';
  }

  @override
  String get backgroundSettingsSection => 'পটভূমি সেটিংস';

  @override
  String get enableBackgroundImageLabel => 'পটভূমি ছবি সক্রিয় করুন';

  @override
  String get backgroundBlurLabel => 'পটভূমি ব্লার';

  @override
  String get surfaceGlassStyleTitle => 'সারফেস/গ্লাস শৈলী';

  @override
  String get chooseImageButton => 'ছবি চয়ন করুন';

  @override
  String get selectImageFileError => 'অনুগ্রহ করে একটি ছবি ফাইল নির্বাচন করুন।';

  @override
  String get clearImageButton => 'ছবিটি সরান';

  @override
  String get saveThemePresetTitle => 'থিম প্রিসেট সংরক্ষণ করুন';

  @override
  String get presetNameLabel => 'প্রিসেটের নাম';

  @override
  String get presetNameHint => 'আমার চমৎকার থিম';

  @override
  String get importDataLabel => 'তথ্য আমদানি করুন';

  @override
  String get exportDataLabel => 'তথ্য রপ্তানি করুন';

  @override
  String get exportFormatMessage => 'বিন্যাস চয়ন করুন:\n\nJSON: সমস্ত তথ্যের সম্পূর্ণ ব্যাকআপ।\nCSV: লেনদেনের পাঠযোগ্য রিপোর্ট।';

  @override
  String get jsonFormat => 'JSON';

  @override
  String get csvFormat => 'CSV';

  @override
  String get importExchangeRatesLabel => 'বিনিময় হার আমদানি করুন (CSV/JSON)';

  @override
  String get resetDataLabel => 'তথ্য ডিফল্ট অবস্থায় ফিরিয়ে দিন';

  @override
  String get resetDataSubtitle => 'এটি সমস্ত তথ্য মুছে ফেলবে এবং ডিফল্ট সেটিংস পুনরুদ্ধার করবে।';

  @override
  String get debugMenuLabel => 'ডিবাগ মেনু';

  @override
  String get debugMenuSubtitle => 'অভ্যন্তরীণ ডেভেলপার টুলস';

  @override
  String get apiManagementTitle => 'API ব্যবস্থাপনা';

  @override
  String apiErrorLabel(String error) {
    return 'ত্রুটি: $error';
  }

  @override
  String apiLastFetchLabel(String date) {
    return 'তারিখ: $date';
  }

  @override
  String get apiCategoriesSection => 'API বিভাগসমূহ';

  @override
  String get manualUtilitiesSection => 'ম্যানুয়াল ইউটিলিটিস';

  @override
  String get startupDataSyncLabel => 'স্টার্টআপে তথ্য সিঙ্ক';

  @override
  String get startupDataSyncDescription => 'অ্যাপ চালুর সময় এক্সটার্নাল তথ্য সংগ্রহ এবং সার্ভার সিঙ্ক উভয়ই নিয়ন্ত্রণ করে।';

  @override
  String get standardApiLabel => 'স্ট্যান্ডার্ড API';

  @override
  String get syncOnStartupDescription => 'চালু করার সময় সিঙ্ক করুন';

  @override
  String get customSourcesLabel => 'কাস্টম সোর্স';

  @override
  String syncCustomSourcesDescription(Object count) {
    return 'চালু করার সময় সবকটি ($count) সিঙ্ক করুন';
  }

  @override
  String get individualCustomSourcesTitle => 'ব্যক্তিগত কাস্টম সোর্স';

  @override
  String get noCustomSourcesAdded => 'কোন কাস্টম সোর্স যোগ করা হয়নি।';

  @override
  String get fetchTodaysRatesButton => 'আজকের হার সংগ্রহ করুন';

  @override
  String get inflationConfigTitle => 'মুদ্রাস্ফীতি কনফিগারেশন';

  @override
  String get countryCodeHint => 'দেশের কোড (উদা: SRB)';

  @override
  String fetchDataForCountryButton(Object country) {
    return '$country-এর জন্য তথ্য সংগ্রহ করুন';
  }

  @override
  String get steamSettingsTitle => 'Steam সেটিংস';

  @override
  String get steamIdLabel => 'Steam ID (64-bit)';

  @override
  String get steamIdHint => 'যেমন 76561198085715972';

  @override
  String get preferredGameLabel => 'পছন্দসই গেম';

  @override
  String get fetchInventoryNowButton => 'এখনই ইনভেন্টরি সংগ্রহ করুন';

  @override
  String get manualExchangeRatesTitle => 'ম্যানুয়াল বিনিময় হার সংগ্রহ';

  @override
  String get selectStartDate => 'শুরু তারিখ নির্বাচন করুন';

  @override
  String startDateFrom(Object date) {
    return 'থেকে: $date';
  }

  @override
  String get selectEndDate => 'শেষ তারিখ নির্বাচন করুন';

  @override
  String endDateTo(Object date) {
    return 'পর্যন্ত: $date';
  }

  @override
  String get fetchRangeButton => 'পরিসীমা অনুযায়ী সংগ্রহ করুন';

  @override
  String get manualSteamInventoryTitle => 'ম্যানুয়াল Steam ইনভেন্টরি';

  @override
  String get selectGameHint => 'গেম নির্বাচন করুন';

  @override
  String get fetchValueButton => 'মান সংগ্রহ করুন';

  @override
  String get manualInflationDataTitle => 'ম্যানুয়াল মুদ্রাস্ফীতি তথ্য';

  @override
  String get selectStartYear => 'শুরু বছর নির্বাচন করুন';

  @override
  String startYearFrom(Object year) {
    return 'থেকে: $year';
  }

  @override
  String get selectEndYear => 'শেষ বছর নির্বাচন করুন';

  @override
  String endYearTo(Object year) {
    return 'পর্যন্ত: $year';
  }

  @override
  String get fetchDataButton => 'তথ্য সংগ্রহ করুন';

  @override
  String get connectionOk => 'সংযোগ ঠিক আছে';

  @override
  String get connectionFailed => 'সংযোগ ব্যর্থ হয়েছে';

  @override
  String get testConnectionButton => 'সংযোগ পরীক্ষা করুন';

  @override
  String get editCustomSourceTitle => 'কাস্টম সোর্স সম্পাদনা করুন';

  @override
  String get addCustomSourceTitle => 'কাস্টম সোর্স যোগ করুন';

  @override
  String get addressFormatsHelp => 'ঠিকানা বিন্যাস:\n• 192.168.1.10 (IP)\n• localhost অথবা api.my.com\n• http://myserver.com';

  @override
  String get customSourceNameHint => 'আমার হোম সার্ভার';

  @override
  String get urlIpLabel => 'URL / IP';

  @override
  String get urlIpHint => '192.168.1.10:8080';

  @override
  String get dataTypeLabel => 'তথ্য ধরণ';

  @override
  String get apiTitleExchangeRates => 'বিনিময় হার';

  @override
  String get apiTitleInflation => 'মুদ্রাস্ফীতি';

  @override
  String get apiTitleAssetPrices => 'সম্পদের মূল্য';

  @override
  String get apiTitleSteamInventory => 'Steam ইনভেন্টরি';

  @override
  String get transferLabel => 'স্থানান্তর';

  @override
  String get uncategorizedLabel => 'অশ্রেণীবদ্ধ';

  @override
  String get defaultLabel => 'ডিফল্ট';

  @override
  String receivedTotalLabel(Object total) {
    return 'প্রাপ্তি: $total';
  }

  @override
  String spentTotalLabel(Object total) {
    return 'ব্যয়: $total';
  }

  @override
  String get periodSummaryTitle => 'সময়ের সারাংশ';

  @override
  String get incomeLabel => 'আয়';

  @override
  String get expenseLabel => 'ব্যয়';

  @override
  String get netLabel => 'নিট';

  @override
  String get exportSuccessMessage => 'রপ্তানি সফলভাবে সম্পন্ন হয়েছে';

  @override
  String exportFailedMessage(Object error) {
    return 'রপ্তানি ব্যর্থ হয়েছে: $error';
  }

  @override
  String get importSuccessMessage => 'আমদানি সফলভাবে সম্পন্ন হয়েছে';

  @override
  String importFailedMessage(Object error) {
    return 'আমদানি ব্যর্থ হয়েছে: $error';
  }

  @override
  String get resetDataConfirmationTitle => 'তথ্য রিসেট করবেন?';

  @override
  String get resetDataConfirmationMessage => 'সতর্কতা! এটি আপনার সমস্ত লেনদেন, অ্যাকাউন্ট এবং সেটিংস মুছে ফেলবে।\n\nঅ্যাপটি ডিফল্ট তথ্য সহ প্রাথমিক অবস্থায় ফিরে যাবে।\nএটি আর ফিরিয়ে আনা যাবে না।';

  @override
  String get resetEverythingButton => 'সব রিসেট করুন';

  @override
  String get resetSuccessMessage => 'তথ্য রিসেট হয়েছে এবং ডিফল্ট সেটিং পুনরুদ্ধার করা হয়েছে।';

  @override
  String resetFailedMessage(Object error) {
    return 'রিসেট ব্যর্থ হয়েছে: $error';
  }

  @override
  String get importParsingStep => 'CSV ফাইল বিশ্লেষণ করা হচ্ছে...';

  @override
  String get importFetchingRatesStep => 'বিনিময় হার সংগ্রহ করা হচ্ছে...';

  @override
  String importErrorLabel(Object error) {
    return 'ত্রুটি: $error';
  }

  @override
  String get importOneMoneyLabel => 'OneMoney (CSV) থেকে আমদানি করুন';

  @override
  String get importMyBudgetLabel => 'MyBudget লেনদেন (CSV) আমদানি করুন';

  @override
  String get restoreBackupLabel => 'ব্যাকআপ পুনরুদ্ধার করুন (JSON)';

  @override
  String get importSelectionHelp => 'মাইগ্রেশনের জন্য \'OneMoney\', লেনদেন যোগ করতে \'MyBudget\', অথবা সমস্ত তথ্য প্রতিস্থাপন করতে \'ব্যাকআপ পুনরুদ্ধার\' চয়ন করুন।';

  @override
  String get importCreateAllNew => 'সব নতুন হিসেবে তৈরি করুন';

  @override
  String importNewAccountFound(Object accountName) {
    return 'নতুন অ্যাকাউন্ট পাওয়া গেছে: \"$accountName\"';
  }

  @override
  String importMapAccountTitle(Object accountName) {
    return '\"$accountName\"-কে কোনটির সাথে সংযুক্ত করবেন?';
  }

  @override
  String get importMapToExisting => 'বিদ্যমান অ্যাকাউন্টের সাথে সংযোগ করুন';

  @override
  String get importCreateNew => 'নতুন তৈরি করুন';

  @override
  String importNewCategoryFound(Object categoryName) {
    return 'নতুন বিভাগ পাওয়া গেছে: \"$categoryName\"';
  }

  @override
  String importMapCategoryTitle(Object categoryName) {
    return '\"$categoryName\"-কে কোনটির সাথে সংযুক্ত করবেন?';
  }

  @override
  String importNewCurrencyFound(Object currencyName) {
    return 'নতুন মুদ্রা পাওয়া গেছে: \"$currencyName\"';
  }

  @override
  String importMapCurrencyTitle(Object currencyName) {
    return '\"$currencyName\"-কে কোনটির সাথে সংযুক্ত করবেন?';
  }

  @override
  String get importSkipAll => 'সব এড়িয়ে যান';

  @override
  String get importImportAll => 'সব আমদানি করুন';

  @override
  String get importPotentialDuplicate => 'সম্ভাব্য ডুপ্লিকেট:';

  @override
  String importDateLabel(Object date) {
    return 'তারিখ: $date';
  }

  @override
  String importFromLabel(Object from) {
    return 'থেকে: $from';
  }

  @override
  String importToLabel(Object to) {
    return 'পর্যন্ত: $to';
  }

  @override
  String importAmountLabel(Object amount, Object currency) {
    return 'পরিমাণ: $amount $currency';
  }

  @override
  String get importSkip => 'এড়িয়ে যান';

  @override
  String get importImportAnyway => 'যাইহোক আমদানি করুন';

  @override
  String importDecisionLabel(Object decision) {
    return 'সিদ্ধান্ত: $decision';
  }

  @override
  String get importReadyTitle => 'আমদানির জন্য প্রস্তুত';

  @override
  String importReadyMessage(Object count) {
    return '$countটি লেনদেন আমদানির জন্য প্রস্তুত।';
  }

  @override
  String get importFinalizeButton => 'আমদানি সম্পন্ন করুন';

  @override
  String get importingTitle => 'আমদানি করা হচ্ছে...';

  @override
  String get importCompleteTitle => 'আমদানি সম্পন্ন';

  @override
  String get importStartOverTooltip => 'আবার শুরু করুন';

  @override
  String get importDataTitle => 'তথ্য আমদানি করুন';

  @override
  String importAccountsCreatedLabel(Object count) {
    return 'নতুন তৈরি অ্যাকাউন্ট: $count';
  }

  @override
  String importCategoriesCreatedLabel(Object count) {
    return 'নতুন তৈরি বিভাগ: $count';
  }

  @override
  String importTransactionsImportedLabel(Object count) {
    return 'আমদানিকৃত লেনদেন: $count';
  }

  @override
  String importDuplicatesSkippedLabel(Object count) {
    return 'এড়িয়ে চলা ডুপ্লিকেট: $count';
  }

  @override
  String get searchHint => 'অনুসন্ধান করুন';

  @override
  String get debugAllDataClearedMessage => 'সমস্ত তথ্য মুছে ফেলা হয়েছে এবং ডিফল্ট তথ্য প্রবেশ করানো হয়েছে।';

  @override
  String get debugClearAllDataLabel => 'সমস্ত তথ্য মুছুন (এবং ডিফল্ট প্রবেশ করান)';

  @override
  String get debugMinimumDataSeededMessage => 'ন্যূনতম তথ্য প্রবেশ করানো হয়েছে।';

  @override
  String get debugSeedMinimumDataLabel => 'ন্যূনতম তথ্য প্রবেশ করান';

  @override
  String get debugMediumDataSeededMessage => 'মাঝারি তথ্য প্রবেশ করানো হয়েছে।';

  @override
  String get debugSeedMediumDataLabel => 'মাঝারি তথ্য প্রবেশ করান';

  @override
  String get debugMaximumDataSeededMessage => 'সর্বোচ্চ তথ্য প্রবেশ করানো হয়েছে।';

  @override
  String get debugSeedMaximumDataLabel => 'সর্বোচ্চ তথ্য প্রবেশ করান (কর্মদক্ষতা পরীক্ষার জন্য)';

  @override
  String get debugRunningInDebugModeLabel => 'DEBUG মোডে চলছে';

  @override
  String get deleteAllButton => 'সব মুছুন';

  @override
  String get changeButton => 'পরিবর্তন করুন';

  @override
  String get undoButton => 'পূর্বাবস্থায় ফিরুন';

  @override
  String itemDeletedMessage(Object name) {
    return '$name মুছে ফেলা হয়েছে';
  }

  @override
  String get totalBalanceLabel => 'মোট ব্যালেন্স';

  @override
  String get noCurrenciesSelected => 'কোন মুদ্রা নির্বাচিত হয়নি।';

  @override
  String get failedToLoadDashboard => 'ড্যাশবোর্ড লোড করতে ব্যর্থ হয়েছে';

  @override
  String get dashboardCalendarTab => 'ক্যালেন্ডার';

  @override
  String get dashboardTabCalendar => 'ক্যালেন্ডার';

  @override
  String get dashboardCalendarTooltip => 'ক্যালেন্ডার ভিউ';

  @override
  String get dashboardCalendarDescription => 'ক্যালেন্ডার বিন্যাসে লেনদেনগুলো দেখুন';

  @override
  String get dashboardCategoriesTab => 'বিভাগসমূহ';

  @override
  String get dashboardTabCategories => 'বিভাগসমূহ';

  @override
  String get dashboardCategoriesTooltip => 'বিভাগ বিশ্লেষণ';

  @override
  String get dashboardCategoriesDescription => 'বিভাগ অনুযায়ী ব্যয়ের বিভাজন';

  @override
  String get dashboardBalanceTab => 'ব্যালেন্স';

  @override
  String get dashboardTabBalance => 'ব্যালেন্স';

  @override
  String get dashboardBalanceTooltip => 'ব্যালেন্সের ইতিহাস';

  @override
  String get dashboardBalanceDescription => 'সময়ের সাথে সাথে নেট মূল্যের হিসাব রাখুন';

  @override
  String get dashboardExpensesLabel => 'ব্যয়';

  @override
  String get dashboardIncomeLabel => 'আয়';

  @override
  String get manageIconsTitle => 'আইকন পরিচালনা';

  @override
  String get manageStylesDeleteTitle => 'আইকন মুছুন';

  @override
  String manageStylesDeleteConfirm(Object count) {
    return 'আপনি কি নিশ্চিত যে আপনি নির্বাচিত $countটি আইকন মুছে ফেলতে চান?';
  }

  @override
  String manageStylesDeleteConfirmWithTransfer(Object count) {
    return 'আপনি কি নিশ্চিত যে আপনি নির্বাচিত $countটি আইকন মুছে ফেলতে চান? (স্থানান্তর আইকনটি বাদ দেওয়া হবে)';
  }

  @override
  String get noIconsCreated => 'এখনও কোন আইকন তৈরি করা হয়নি।';

  @override
  String get failedToLoadIcons => 'আইকন লোড করতে ব্যর্থ হয়েছে।';

  @override
  String get cannotDeleteTransferIcon => 'স্থানান্তর (Transfer) আইকন মুছে ফেলা সম্ভব নয়।';

  @override
  String get deleteIconsDialogTitle => 'আইকন মুছে ফেলুন';

  @override
  String deleteIconsConfirmationMessage(Object count) {
    return 'আপনি কি নিশ্চিত যে আপনি নির্বাচিত $countটি আইকন মুছে ফেলতে চান?';
  }

  @override
  String deleteIconsWithSkipTransferMessage(Object count) {
    return 'আপনি কি নিশ্চিত যে আপনি নির্বাচিত $countটি আইকন মুছে ফেলতে চান? (স্থানান্তর আইকনটি বাদ দেওয়া হবে)';
  }

  @override
  String get deleteIconDialogTitle => 'আইকন মুছে ফেলুন';

  @override
  String deleteIconConfirmationMessage(Object name) {
    return 'আপনি কি নিশ্চিত যে আপনি \"$name\" মুছে ফেলতে চান?';
  }

  @override
  String deleteMultipleAccountsTitle(Object count) {
    return '$countটি অ্যাকাউন্ট মুছবেন?';
  }

  @override
  String get deleteMultipleAccountsMessage => 'আপনি কি নিশ্চিত যে আপনি নির্বাচিত অ্যাকাউন্টগুলো মুছে ফেলতে চান? সংশ্লিষ্ট সমস্ত লেনদেন মুছে ফেলা হবে।';

  @override
  String get changeAccountTypeDialogTitle => 'অ্যাকাউন্টের ধরণ পরিবর্তন করুন';

  @override
  String editAccountTitle(Object name) {
    return 'সম্পাদনা: $name';
  }

  @override
  String get balanceCalculatedFromAsset => 'ব্যালেন্স হিসাব করা হয় সম্পদের পরিমাণ * মূল্য থেকে';

  @override
  String get selectAccountTypeTitle => 'অ্যাকাউন্টের ধরণ নির্বাচন করুন';

  @override
  String get selectCountryTitle => 'দেশ নির্বাচন করুন';

  @override
  String get selectIconSubtitle => 'একটি আইকন নির্বাচন করুন';

  @override
  String get bindToAssetLabel => 'সম্পদের সাথে সংযুক্ত করুন (ঐচ্ছিক)';

  @override
  String get selectAssetTitle => 'সম্পদ নির্বাচন করুন';

  @override
  String get selectedAssetLabel => 'নির্বাচিত সম্পদ';

  @override
  String get balanceAutoCalculatedLabel => 'ব্যালেন্স স্বয়ংক্রিয়ভাবে হিসাব করা হয়';

  @override
  String get tapToBindAssetLabel => 'সম্পদ সংযুক্ত করতে ট্যাপ করুন';

  @override
  String get assetQuantityLabel => 'সম্পদের পরিমাণ';

  @override
  String get linkedAssetsTitle => 'সংযুক্ত সম্পদসমূহ';

  @override
  String get noneLabel => 'কিছুই না';

  @override
  String get accountTypeLabel => 'অ্যাকাউন্টের ধরণ';

  @override
  String get formValidationPleaseSelectAccountType => 'অনুগ্রহ করে অ্যাকাউন্টের ধরণ নির্বাচন করুন';

  @override
  String get iconLabel => 'আইকন';

  @override
  String get languageLabel => 'ভাষা';

  @override
  String get systemDefaultLabel => 'সিস্টেম ডিফল্ট';

  @override
  String get selectLanguageTitle => 'ভাষা নির্বাচন করুন';

  @override
  String get dashboardLabel => 'ড্যাশবোর্ড';

  @override
  String get homeLabel => 'হোম';

  @override
  String get historyLabel => 'ইতিহাস';

  @override
  String get syncScreenTitle => 'সিঙ্ক সেটিংস';

  @override
  String get syncP2PSection => 'P2P সিঙ্ক্রোনাইজেশন (Syncthing)';

  @override
  String get syncEnableP2P => 'P2P সিঙ্ক সক্রিয় করুন';

  @override
  String get syncP2PSubtitle => 'শেয়ার্ড ফোল্ডারের .sync ফাইলের মাধ্যমে সিঙ্ক করুন';

  @override
  String get syncFolderLabel => 'সিঙ্ক ফোল্ডার';

  @override
  String get syncFolderNotSelected => 'নির্বাচিত হয়নি';

  @override
  String get syncBrowseButton => 'ব্রাউজ করুন';

  @override
  String get syncClearFilesButton => 'সিঙ্ক ফাইলগুলো পরিষ্কার করুন';

  @override
  String get syncServerSection => 'ক্লাউড সিঙ্ক্রোনাইজেশন (সার্ভার)';

  @override
  String get syncServerUrlLabel => 'সার্ভার URL';

  @override
  String get syncApiTokenLabel => 'API টোকেন';

  @override
  String get syncApiTokenHint => 'আপনার সিকিউরিটি টোকেন লিখুন';

  @override
  String get syncApiTokenHelp => 'এই টোকেনটি আপনার গোপন পাসওয়ার্ডের মতো। সিঙ্ক করার অনুমতি দিতে আপনার সমস্ত ডিভাইসে একই মান লিখুন।';

  @override
  String get syncTestConnectionButton => 'সংযোগ পরীক্ষা করুন';

  @override
  String get syncTestingLabel => 'পরীক্ষা করা হচ্ছে...';

  @override
  String get syncSaveServerSettingsButton => 'সার্ভার সেটিংস সংরক্ষণ করুন';

  @override
  String get syncEnableServer => 'সার্ভার সিঙ্ক সক্রিয় করুন';

  @override
  String get syncServerSubtitle => 'MyBudget সার্ভারের সাথে সিঙ্ক করুন';

  @override
  String get syncPendingLocalChanges => 'অপেক্ষমান স্থানীয় পরিবর্তনসমূহ:';

  @override
  String get syncSyncNowButton => 'এখনই সিঙ্ক করুন';

  @override
  String get syncSyncingLabel => 'সিঙ্ক করা হচ্ছে...';

  @override
  String get syncWebNotAvailable => 'ওয়েবে সিঙ্ক্রোনাইজেশন উপলব্ধ নয়';

  @override
  String get syncPermissionRequired => 'সিঙ্ক করার জন্য স্টোরেজ পারমিশন প্রয়োজন। অনুগ্রহ করে সেটিংসে \"সমস্ত ফাইলে অ্যাক্সেস\" সক্রিয় করুন।';

  @override
  String get syncSelectFolderTitle => 'Syncthing ফোল্ডার নির্বাচন করুন';

  @override
  String get syncClearFilesTitle => 'সিঙ্ক ফাইলগুলো পরিষ্কার করুন';

  @override
  String get syncClearFilesConfirm => 'এটি নির্বাচিত ফোল্ডার থেকে সমস্ত .sync ফাইল মুছে ফেলবে। এটি আর ফিরিয়ে আনা যাবে না।';

  @override
  String syncDeletedFilesCount(Object count) {
    return '$countটি সিঙ্ক ফাইল মুছে ফেলা হয়েছে';
  }

  @override
  String syncClearFilesError(Object error) {
    return 'ফাইল পরিষ্কার করতে ত্রুটি: $error';
  }

  @override
  String get syncSettingsSaved => 'সার্ভার সেটিংস সংরক্ষিত হয়েছে';

  @override
  String get syncConnectionSuccessful => 'সংযোগ সফল হয়েছে!';

  @override
  String get syncConnectionFailed => 'সংযোগ ব্যর্থ হয়েছে। URL এবং টোকেন পরীক্ষা করুন।';

  @override
  String get syncConnectionUnauthorized => 'সার্ভার টোকেন প্রত্যাখ্যান করেছে। ঠিকানা নয়, টোকেন পরীক্ষা করুন।';

  @override
  String get syncServerNotConfigured => 'সার্ভারে কোনো সিঙ্ক টোকেন কনফিগার করা নেই, তাই এটি সব ডিভাইস প্রত্যাখ্যান করছে। সার্ভারে SYNC_TOKEN সেট করুন এবং এখানে একই মান ব্যবহার করুন।';

  @override
  String get syncCompleted => 'সিঙ্ক সফলভাবে সম্পন্ন হয়েছে';

  @override
  String syncFailed(Object error) {
    return 'সিঙ্ক ব্যর্থ হয়েছে: $error';
  }

  @override
  String get smsRuleAddTitle => 'নিয়ম যোগ করুন';

  @override
  String get smsRuleEditTitle => 'নিয়ম সম্পাদনা করুন';

  @override
  String get smsRuleTransactionType => 'লেনদেনের ধরণ';

  @override
  String get smsRuleMatchPattern => 'ম্যাচ প্যাটার্ন (Regex)';

  @override
  String get smsRuleMatchPatternHint => 'উদা: কার্ডের মাধ্যমে পেমেন্ট';

  @override
  String get smsRuleMatchPatternHelp => 'এই ধরণের SMS শনাক্ত করার প্যাটার্ন';

  @override
  String get smsRuleAmountPattern => 'পরিমাণের প্যাটার্ন (Regex)';

  @override
  String get smsRuleAmountPatternHint => 'উদা: পরিমাণ\\s+([\\d,.]+)';

  @override
  String get smsRuleAmountPatternHelp => 'গ্রুপ ১-কে পরিমাণটি ধরতে হবে';

  @override
  String get smsRuleCurrencyPattern => 'মুদ্রা প্যাটার্ন (Regex, ঐচ্ছিক)';

  @override
  String get smsRuleCurrencyPatternHint => 'উদা: [\\d,.]+\\s*(\\w\\w\\w)';

  @override
  String get smsRuleCurrencyPatternHelp => 'গ্রুপ ১-কে কারেন্সি কোডটি ধরতে হবে';

  @override
  String get smsRuleTestTitle => 'আপনার নিয়মটি পরীক্ষা করুন';

  @override
  String get smsRuleTestSmsHint => 'SMS টেক্সটটি এখানে পেস্ট করুন';

  @override
  String get smsRuleTestButton => 'প্যাটার্ন পরীক্ষা করুন';

  @override
  String get smsRuleTestEnterSmsError => 'পরীক্ষা করার জন্য SMS টেক্সট লিখুন';

  @override
  String get smsRuleTestMatchError => '✗ ম্যাচ প্যাটার্নটি কোন মিল খুঁজে পায়নি';

  @override
  String get smsRuleTestAmountError => '✗ পরিমাণের প্যাটার্নটি কোন মিল খুঁজে পায়নি';

  @override
  String smsRuleTestSuccess(Object amount, Object currency, Object type) {
    return '✓ মিল পাওয়া গেছে!\nধরণ: $type\nপরিমাণ: $amount\nমুদ্রা: $currency';
  }

  @override
  String smsRuleTestRegexError(Object error) {
    return '✗ ভুল Regex: $error';
  }

  @override
  String get smsRuleRequiredError => 'ম্যাচ প্যাটার্ন এবং পরিমাণের প্যাটার্ন উভয়ই আবশ্যক';

  @override
  String inflationError(Object error) {
    return 'ত্রুটি: $error';
  }

  @override
  String get inflationNoRatesFound => 'মুদ্রাস্ফীতির হার পাওয়া যায়নি।';

  @override
  String get inflationAddRate => 'মুদ্রাস্ফীতির হার যোগ করুন';

  @override
  String get inflationDeleteConfirmTitle => 'হারগুলো মুছবেন?';

  @override
  String inflationDeleteConfirmMessage(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'এই $countটি হার',
      one: 'এই হারটি',
    );
    return 'আপনি কি নিশ্চিত যে আপনি $_temp0 মুছে ফেলতে চান?';
  }

  @override
  String inflationSelectedCount(Object count) {
    return '$countটি নির্বাচিত';
  }

  @override
  String get inflationFiltersTitle => 'মুদ্রাস্ফীতি ফিল্টার';

  @override
  String get inflationCountries => 'দেশসমূহ';

  @override
  String get inflationPresets => 'প্রিসেটসমূহ';

  @override
  String deleteCategoryConfirmTitle(Object name) {
    return '\"$name\" মুছবেন?';
  }

  @override
  String get deleteCategoryMessage => 'এই বিভাগের সাথে সংশ্লিষ্ট লেনদেন রয়েছে। আপনি কি করতে চান?';

  @override
  String get deleteCategoryReassign => 'লেনদেনগুলো অন্য বিভাগে সরিয়ে নিন';

  @override
  String get deleteCategoryNewCategory => 'নতুন বিভাগ';

  @override
  String get deleteCategoryDeleteAll => 'সংশ্লিষ্ট সব লেনদেন মুছে ফেলুন';

  @override
  String deleteAccountConfirmTitle(Object name) {
    return '\"$name\" মুছবেন?';
  }

  @override
  String get deleteAccountMessage => 'এই অ্যাকাউন্টের সাথে সংশ্লিষ্ট লেনদেন থাকতে পারে। আপনি কি করতে চান?';

  @override
  String get deleteAccountReassign => 'লেনদেনগুলো অন্য অ্যাকাউন্টে সরিয়ে নিন';

  @override
  String get deleteAccountNewAccount => 'নতুন অ্যাকাউন্ট';

  @override
  String get deleteAccountDeleteAll => 'সংশ্লিষ্ট সব লেনদেন মুছে ফেলুন';

  @override
  String get confirmButton => 'নিশ্চিত করুন';

  @override
  String get okButton => 'ঠিক আছে';

  @override
  String get noItemsFound => 'কোন আইটেম পাওয়া যায়নি।';

  @override
  String get noDataForPeriod => 'এই সময়ের জন্য কোন তথ্য নেই';

  @override
  String get noDataForRange => 'এই পরিসীমার জন্য কোন তথ্য নেই';

  @override
  String get noHistoryData => 'কোনো ইতিহাসের তথ্য উপলব্ধ নেই';

  @override
  String get disabledByGlobalSync => 'গ্লোবাল সিঙ্কের কারণে নিষ্ক্রিয়';

  @override
  String dateCreatedLabel(Object date) {
    return 'তৈরির তারিখ: $date';
  }

  @override
  String get anyLabel => 'যেকোনো';

  @override
  String get balanceDisplayLabel => 'ব্যালেন্স প্রদর্শন';

  @override
  String currenciesActiveLabel(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি সক্রিয় মুদ্রা',
      one: '১টি সক্রিয় মুদ্রা',
    );
    return '$_temp0';
  }

  @override
  String get searchCountryLabel => 'দেশ অনুসন্ধান করুন';

  @override
  String get addNewIconLabel => 'নতুন আইকন যোগ করুন';

  @override
  String get noIconsFoundLabel => 'কোন আইকন পাওয়া যায়নি';

  @override
  String get addNewStyleLabel => 'নতুন শৈলী যোগ করুন';

  @override
  String get styleNameLabel => 'শৈলীর নাম';

  @override
  String get pleaseEnterStyleName => 'অনুগ্রহ করে শৈলীর নাম লিখুন';

  @override
  String get colorLabel => 'রঙ';

  @override
  String get netBalanceMetric => 'নিট ব্যালেন্স';

  @override
  String get investedMetric => 'বিনিয়োগকৃত';

  @override
  String get realizedMetric => 'অর্জিত';

  @override
  String get feesMetric => 'ফি/ট্যাক্স';

  @override
  String get persistFiltersLabel => 'ফিল্টার ধরে রাখুন';

  @override
  String get searchByNameHint => 'নাম দিয়ে অনুসন্ধান করুন...';

  @override
  String get searchDescriptionHint => 'বিবরণ দিয়ে অনুসন্ধান করুন...';

  @override
  String get advancedFiltersTitle => 'উন্নত ফিল্টার';

  @override
  String get transactionTypeLabel => 'লেনদেনের ধরণ';

  @override
  String get assetFiltersTitle => 'সম্পদ ফিল্টার';

  @override
  String get minValueLabel => 'সর্বনিম্ন মান';

  @override
  String get maxValueLabel => 'সর্বোচ্চ মান';

  @override
  String get assetTypesLabel => 'সম্পদের ধরণ';

  @override
  String get allLabel => 'সব';

  @override
  String get currenciesLabel => 'মুদ্রাসমূহ';

  @override
  String get sourcesLabel => 'উৎসসমূহ';

  @override
  String get presetsLabel => 'প্রিসেটসমূহ';

  @override
  String get enterCategoryNameHint => 'বিভাগের নাম লিখুন';

  @override
  String get selectTypeHint => 'ধরণ নির্বাচন করুন';

  @override
  String get hotKeysTitle => 'হট-কি (শর্টকাট)';

  @override
  String get searchHotkeysHint => 'শর্টকাট অনুসন্ধান করুন...';

  @override
  String get noMatchingHotkeys => 'কোনো শর্টকাট খুঁজে পাওয়া যায়নি।';

  @override
  String recordingHotkeyTitle(Object label) {
    return '\"$label\"-এর জন্য শর্টকাট রেকর্ড করা হচ্ছে';
  }

  @override
  String get pressKeysHint => 'কী (keys) চাপুন...';

  @override
  String get pressAnyCombinationHint => 'যেকোনো কী এর কম্বিনেশন চাপুন।';

  @override
  String get clearSaveButton => 'পরিষ্কার / সংরক্ষণ';

  @override
  String get duplicateHotkeyTooltip => 'ডুপ্লিকেট শর্টকাট';

  @override
  String usedByLabel(Object action) {
    return '$action-এর দ্বারা ব্যবহৃত';
  }

  @override
  String get hkCategoryNavigation => 'ন্যাভিগেশন';

  @override
  String get hkCategoryDashboardTabs => 'ড্যাশবোর্ড ট্যাব (Ctrl + 1/2/3)';

  @override
  String get hkCategoryDataTabs => 'তথ্য ট্যাব (Ctrl + 1/2/3)';

  @override
  String get hkCategoryPeriodControl => 'সময়ের নিয়ন্ত্রণ (Period Control)';

  @override
  String get hkCategoryActions => 'ক্রিয়াকলাপ (Actions)';

  @override
  String get hkCategorySelectionMode => 'সিলেকশন মোড';

  @override
  String get hkActionBack => 'গ্লোবাল: ফিরে যান / প্রস্থান';

  @override
  String get hkActionDashboard => 'ড্যাশবোর্ডে যান';

  @override
  String get hkActionAccounts => 'অ্যাকাউন্টে যান';

  @override
  String get hkActionTransactions => 'লেনদেনে যান';

  @override
  String get hkActionCategories => 'বিভাগে যান';

  @override
  String get hkActionData => 'তথ্য / হারে যান';

  @override
  String get hkActionSettings => 'সেটিংসে যান';

  @override
  String get hkActionDashboardTab1 => 'ক্যালেন্ডার ট্যাব';

  @override
  String get hkActionDashboardTab2 => 'বিভাগ ট্যাব';

  @override
  String get hkActionDashboardTab3 => 'ব্যালেন্স ট্যাব';

  @override
  String get hkActionDataTab1 => 'বিনিময় হার';

  @override
  String get hkActionDataTab2 => 'মুদ্রাস্ফীতি';

  @override
  String get hkActionDataTab3 => 'সম্পদসমূহ';

  @override
  String get hkActionPrevPeriod => 'পূর্ববর্তী সময়কাল';

  @override
  String get hkActionNextPeriod => 'পরবর্তী সময়কাল';

  @override
  String get hkActionAddAction => 'সাধারণ যোগ করার ক্রিয়া';

  @override
  String get hkActionAccountsSelectionClose => 'অ্যাকাউন্ট: বন্ধ';

  @override
  String get hkActionAccountsSelectionAll => 'অ্যাকাউন্ট: সব নির্বাচন';

  @override
  String get hkActionAccountsSelectionDelete => 'অ্যাকাউন্ট: মুছে ফেলুন';

  @override
  String get hkActionAccountsSelectionChangeType => 'অ্যাকাউন্ট: ধরণ পরিবর্তন';

  @override
  String get hkActionCategoriesSelectionClose => 'বিভাগ: বন্ধ';

  @override
  String get hkActionCategoriesSelectionAll => 'বিভাগ: সব নির্বাচন';

  @override
  String get hkActionCategoriesSelectionDelete => 'বিভাগ: মুছে ফেলুন';

  @override
  String get hkActionCategoriesSelectionChangeType => 'বিভাগ: ধরণ পরিবর্তন';

  @override
  String get hkActionDataSelectionClose => 'তথ্য: বন্ধ';

  @override
  String get hkActionDataSelectionAll => 'তথ্য: সব নির্বাচন';

  @override
  String get hkActionDataSelectionDelete => 'তথ্য: মুছে ফেলুন';

  @override
  String get hkActionDataSelectionChangePreset => 'তথ্য: প্রিসেট পরিবর্তন';

  @override
  String get styNotFound => 'শৈলী পাওয়া যায়নি।';

  @override
  String get stySaveChanges => 'পরিবর্তন সংরক্ষণ করুন';

  @override
  String get styAddIcon => 'আইকন যোগ করুন';

  @override
  String get smsOnlyAndroid => 'SMS আমদানি শুধুমাত্র Android-এ উপলব্ধ';

  @override
  String get smsImportSms => 'SMS আমদানি করুন';

  @override
  String get smsPermissionRequired => 'SMS অনুমতি প্রয়োজন';

  @override
  String get smsPermissionRationale => 'SMS থেকে লেনদেন আমদানি করতে, আপনার বার্তা পড়ার অনুমতি প্রয়োজন।';

  @override
  String get smsGrantPermission => 'অনুমতি দিন';

  @override
  String get smsNoPresets => 'কোন প্রিসেট কনফিগার করা হয়নি। যোগ করতে + চাপুন।';

  @override
  String get smsImportDescription => 'SMS বার্তা থেকে লেনদেন আমদানি করুন। একটি সময়সীমা নির্বাচন করুন:';

  @override
  String get smsLast7Days => 'শেষ ৭ দিন';

  @override
  String get smsAllTime => 'সর্বকালীন';

  @override
  String smsFilterLabel(Object filter) {
    return 'ফিল্টার: $filter';
  }

  @override
  String get smsEditPreset => 'প্রিসেট সম্পাদনা করুন';

  @override
  String get smsNewPreset => 'নতুন প্রিসেট';

  @override
  String get smsPresetNameHint => 'উদা: আমার ব্যাংক';

  @override
  String get smsSenderFilter => 'প্রেরক ফিল্টার';

  @override
  String get smsSenderFilterHint => 'উদা: ALTA অথবা +381...';

  @override
  String get smsSenderFilterHelper => 'প্রেরকের নাম বা ফোন নম্বর দিয়ে SMS ফিল্টার করুন';

  @override
  String get smsDefaults => 'ডিফল্ট';

  @override
  String get smsDefaultAccount => 'ডিফল্ট অ্যাকাউন্ট';

  @override
  String get smsDefaultCategory => 'ডিফল্ট বিভাগ';

  @override
  String get smsImportMessages => 'বার্তা আমদানি করুন';

  @override
  String get smsSelectDefaultsFirst => 'প্রথমে ডিফল্ট নির্বাচন করুন';

  @override
  String get smsCustomRange => 'কাস্টম পরিসীমা';

  @override
  String smsImportSuccessCount(Object count) {
    return 'সফল: $countটি লেনদেন আমদানি হয়েছে';
  }

  @override
  String get smsParsingRules => 'বিশ্লেষণের নিয়ম';

  @override
  String get smsNoRules => 'কোন নিয়ম নির্ধারিত হয়নি। যোগ করতে + চাপুন।';

  @override
  String smsMatchLabel(Object pattern) {
    return 'ম্যাচ: $pattern';
  }

  @override
  String get smsNameSenderRequired => 'নাম এবং প্রেরক ফিল্টার আবশ্যক';

  @override
  String get smsCategoryKeywords => 'বিভাগের কীওয়ার্ড';

  @override
  String get smsCategoryKeywordsSubtitle => 'SMS-এর লেখার কীওয়ার্ড বিভাগের সাথে মেলান';

  @override
  String get smsNoKeywordRules => 'কোন কীওয়ার্ড নিয়ম নেই। যোগ করতে + চাপুন।';

  @override
  String get smsAddKeywordRule => 'কীওয়ার্ড নিয়ম যোগ করুন';

  @override
  String get smsKeyword => 'কীওয়ার্ড';

  @override
  String get smsKeywordHint => 'উদা: মুদি, Netflix';

  @override
  String get smsKeywordHelper => 'SMS-এর লেখায় মেলানোর জন্য অক্ষর-নিরপেক্ষ শব্দাংশ';

  @override
  String get smsSelectCategoryHint => 'বিভাগ নির্বাচন করুন';

  @override
  String get dshSelectDateDescription => 'নির্দিষ্ট তারিখ বা পরিসীমা বাছতে ক্যালেন্ডার খুলুন';

  @override
  String get dshCurrencyDescription => 'প্রদর্শনের জন্য প্রধান মুদ্রা নির্বাচন করুন';

  @override
  String get dshChangeViewTooltip => 'ভিউ পরিবর্তন করুন';

  @override
  String get dshChangeViewDescription => 'মাসিক এবং বার্ষিক ভিউয়ের মধ্যে পরিবর্তন করুন';

  @override
  String get dshMonthlyAbbreviation => 'মা';

  @override
  String get dshYearlyAbbreviation => 'ব';

  @override
  String dshBalancesOnDate(Object date) {
    return '$date তারিখের ব্যালেন্স';
  }

  @override
  String get dshSearchCurrency => 'মুদ্রা অনুসন্ধান';

  @override
  String get dshUnknownCategory => 'অজানা';

  @override
  String get pckSelectItem => 'আইটেম নির্বাচন করুন';

  @override
  String get pckSelectItems => 'আইটেমগুলো নির্বাচন করুন';

  @override
  String get pckClearAll => 'সব পরিষ্কার করুন';

  @override
  String get pckSelectIcon => 'আইকন নির্বাচন করুন';

  @override
  String get pckMaterialIcons => 'Material আইকন';

  @override
  String get pckCustomIcons => 'কাস্টম আইকন';

  @override
  String get fltAmountFrom => 'পরিমাণ থেকে';

  @override
  String get fltAmountTo => 'পরিমাণ পর্যন্ত';

  @override
  String get fltSelectRange => 'পরিসীমা নির্বাচন করুন';

  @override
  String get fltAdvancedFilterTooltip => 'উন্নত ফিল্টার';

  @override
  String get fltAdvancedFilterDescription => 'অ্যাকাউন্ট, বিভাগ বা পরিমাণ অনুযায়ী লেনদেন ফিল্টার করুন';

  @override
  String get fltSortOrderDescription => 'আরোহী এবং অবরোহী ক্রমের মধ্যে পরিবর্তন করুন';

  @override
  String get fltAccountFiltersTitle => 'অ্যাকাউন্ট ফিল্টার';

  @override
  String get fltNameLabel => 'নাম';

  @override
  String get fltAccountTypesLabel => 'অ্যাকাউন্টের ধরণ';

  @override
  String get fltFilterCurrenciesLabel => 'মুদ্রা ফিল্টার করুন';

  @override
  String get fltSelectCurrenciesLabel => 'মুদ্রা নির্বাচন করুন';

  @override
  String get fltFilterCategoriesTitle => 'বিভাগ ফিল্টার করুন';

  @override
  String get exchAddExchangeRate => 'বিনিময় হার যোগ করুন';

  @override
  String get exchEditExchangeRate => 'বিনিময় হার সম্পাদনা করুন';

  @override
  String get exchAddRateDescription => 'দুটি মুদ্রার মধ্যে রূপান্তর হার নিজে লিখুন';

  @override
  String get exchNoRatesFound => 'কোন বিনিময় হার পাওয়া যায়নি।';

  @override
  String get exchChangePreset => 'প্রিসেট পরিবর্তন করুন';

  @override
  String get exchFromCurrency => 'উৎস মুদ্রা';

  @override
  String get exchToCurrency => 'গন্তব্য মুদ্রা';

  @override
  String get exchRate => 'হার';

  @override
  String get exchPresetIdLabel => 'প্রিসেট আইডি';

  @override
  String exchPresetValue(Object preset) {
    return 'প্রিসেট: $preset';
  }

  @override
  String get exchSelectRange => 'পরিসীমা নির্বাচন করুন';

  @override
  String get exchPreviousPeriodDescription => 'পূর্ববর্তী দিন, মাস বা বছরে যান';

  @override
  String get exchNextPeriodDescription => 'পরবর্তী দিন, মাস বা বছরে যান';

  @override
  String get exchFilterDescription => 'উৎস/গন্তব্য মুদ্রা এবং প্রিসেট আইডি অনুযায়ী হার ফিল্টার করুন';

  @override
  String get exchSelectDateDescription => 'পূর্বের হার দেখতে একটি নির্দিষ্ট তারিখ বা পরিসীমা চয়ন করুন';

  @override
  String get exchSortOrderDescription => 'তারিখ/হারের আরোহী ও অবরোহী ক্রমের মধ্যে পরিবর্তন করুন';

  @override
  String get exchFilterExchangeRates => 'বিনিময় হার ফিল্টার করুন';

  @override
  String get exchExitSelectionDescription => 'বিনিময় হার নির্বাচন মোড থেকে প্রস্থান করুন';

  @override
  String get exchSelectAllDescription => 'তালিকাভুক্ত সব বিনিময় হার নির্বাচন করুন';

  @override
  String get exchDeselectAllDescription => 'সব হারের নির্বাচন বাতিল করুন';

  @override
  String get exchChangePresetDescription => 'নির্বাচিত সব বিনিময় হারের প্রিসেট আইডি আপডেট করুন';

  @override
  String get exchDeleteSelectedDescription => 'নির্বাচিত সব বিনিময় হার স্থায়ীভাবে মুছে ফেলুন';

  @override
  String get exchDeleteExchangeRatesTitle => 'বিনিময় হার মুছে ফেলুন';

  @override
  String exchDeleteConfirmMessage(Object count) {
    return 'আপনি কি নিশ্চিত যে আপনি $countটি বিনিময় হার মুছে ফেলতে চান?';
  }

  @override
  String get exchUpdatePresetTitle => 'প্রিসেট আপডেট করুন';

  @override
  String get exchUpdatePresetMessage => 'নির্বাচিত আইটেমগুলোর জন্য নতুন প্রিসেট আইডি লিখুন:';

  @override
  String dashboardUnconvertibleCurrencies(String currencies) {
    return '$currencies রূপান্তর করা যায়নি, তাই এই পরিমাণগুলো মোটের মধ্যে অন্তর্ভুক্ত নয়';
  }

  @override
  String get addAccountBeforeTransactionDescription => 'লেনদেনের জন্য একটি অ্যাকাউন্ট প্রয়োজন। শুরু করতে প্রথমটি তৈরি করুন';

  @override
  String get selectDialogEmptyState => 'এখনও বেছে নেওয়ার মতো কিছু নেই';

  @override
  String get selectDialogNoMatches => 'আপনার অনুসন্ধানের সাথে কিছুই মেলেনি';

  @override
  String get addButton => 'যোগ করুন';

  @override
  String get retryButton => 'আবার চেষ্টা করুন';

  @override
  String get unknownLabel => 'অজানা';

  @override
  String get globalLabel => 'বৈশ্বিক';

  @override
  String dateWithValueLabel(String date) {
    return 'তারিখ: $date';
  }

  @override
  String selectColorTitle(String label) {
    return '$label রঙ নির্বাচন করুন';
  }

  @override
  String get assetAddTitle => 'সম্পদের তথ্য যোগ করুন';

  @override
  String get assetEditTitle => 'সম্পদের তথ্য সম্পাদনা করুন';

  @override
  String get assetAddDescription => 'একটি নির্দিষ্ট সম্পদের মূল্য বা পরিমাণ নথিভুক্ত করুন';

  @override
  String get assetNameLabel => 'সম্পদের নাম (যেমন Apple স্টক)';

  @override
  String get assetIdLabel => 'সম্পদের আইডি (যেমন AAPL)';

  @override
  String get assetValueLabel => 'মূল্য (প্রতি এককের দাম)';

  @override
  String get assetTypeOptionalLabel => 'সম্পদের ধরন (ঐচ্ছিক)';

  @override
  String get assetLinkedAccountOptionalLabel => 'সংযুক্ত অ্যাকাউন্ট (ঐচ্ছিক)';

  @override
  String get assetNameRequiredError => 'সম্পদটির একটি নাম দিন';

  @override
  String get assetIdRequiredError => 'সম্পদটির জন্য একটি আইডি দিন, যেমন AAPL';

  @override
  String get assetValueInvalidError => 'একটি সংখ্যা লিখুন, যেমন 150.25';

  @override
  String get assetNoAssetsFound => 'কোনও সম্পদ পাওয়া যায়নি।';

  @override
  String assetError(String error) {
    return 'ত্রুটি: $error';
  }

  @override
  String get assetDeleteConfirmTitle => 'সম্পদ মুছবেন?';

  @override
  String assetDeleteConfirmMessage(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
      
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'এই $countStringটি সম্পদ',
      one: 'এই সম্পদটি',
    );
    return 'আপনি কি নিশ্চিত যে আপনি $_temp0 মুছে ফেলতে চান?';
  }

  @override
  String get assetDeleteSelectedDescription => 'নির্বাচিত সব সম্পদ রেকর্ড স্থায়ীভাবে মুছে ফেলুন';

  @override
  String get inflationEditRate => 'মুদ্রাস্ফীতির হার সম্পাদনা করুন';

  @override
  String get inflationAddDescription => 'একটি নির্দিষ্ট তারিখ ও দেশের জন্য নতুন মুদ্রাস্ফীতির শতাংশ লিখুন';

  @override
  String get inflationPercentLabel => 'মুদ্রাস্ফীতির শতাংশ (%)';

  @override
  String get inflationPercentHint => 'যেমন 2.5';

  @override
  String get inflationPercentInvalidError => 'একটি সংখ্যা লিখুন, যেমন 2.5';

  @override
  String get inflationCountryGlobal => 'দেশ: বৈশ্বিক';

  @override
  String inflationCountryNamed(String country) {
    return 'দেশ: $country';
  }

  @override
  String get inflationUseWorldwideRate => 'বিশ্বব্যাপী হার ব্যবহার করুন';

  @override
  String get pickerSingleDate => 'একক তারিখ';

  @override
  String get pickerRange => 'পরিসর';

  @override
  String get dateStepDay => 'দিন';

  @override
  String get dateStepMonth => 'মাস';

  @override
  String get dateStepYear => 'বছর';

  @override
  String get feeStructureTitle => 'ফি কাঠামো';

  @override
  String get feeNoRulesApplied => 'কোনও ফি নিয়ম প্রয়োগ করা হয়নি।';

  @override
  String get feeAddRule => 'ফি নিয়ম যোগ করুন';

  @override
  String get feeFixedFee => 'নির্দিষ্ট ফি';

  @override
  String get feePercentFee => 'শতাংশ ফি';

  @override
  String get feeTaxRate => 'করের হার';

  @override
  String get feeUnknownRule => 'অজানা নিয়ম';

  @override
  String get feeRatePercentLabel => 'হার (%)';

  @override
  String get feeTaxRatePercentLabel => 'করের হার (%)';

  @override
  String get feeCostBasisLabel => 'ব্যয়ের ভিত্তি';

  @override
  String deleteAccountsConfirmTitle(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
      
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countStringটি অ্যাকাউন্ট',
      one: 'এই অ্যাকাউন্টটি',
    );
    return '$_temp0 মুছবেন?';
  }

  @override
  String get deleteAccountsConfirmMessage => 'আপনি কি নিশ্চিতভাবে নির্বাচিত অ্যাকাউন্টগুলি মুছতে চান? সমস্ত সংশ্লিষ্ট লেনদেন মুছে যাবে।';

  @override
  String get changeAccountTypeTitle => 'অ্যাকাউন্টের ধরন পরিবর্তন করুন';

  @override
  String get accountsPreviousPeriodDescription => 'পূর্ববর্তী মাস বা বছরে যান';

  @override
  String get accountsNextPeriodDescription => 'পরবর্তী মাস বা বছরে যান';

  @override
  String get accountsFilterDescription => 'ধরন বা লুকানো অবস্থা অনুসারে অ্যাকাউন্ট ফিল্টার করুন';

  @override
  String get accountsSelectDateDescription => 'ঐতিহাসিক ব্যালেন্স দেখতে একটি নির্দিষ্ট তারিখ বেছে নিন';

  @override
  String get accountsSortDescription => 'ব্যালেন্সের ঊর্ধ্বক্রম ও অধঃক্রমের মধ্যে পরিবর্তন করুন';

  @override
  String get smsRuleCategoryOptional => 'বিভাগ (ঐচ্ছিক)';

  @override
  String get smsRuleCategoryHelp => 'এই নিয়মের জন্য বিভাগ ওভাররাইড করুন';
}
