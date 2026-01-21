// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get helloWorld => 'হ্যালো বিশ্ব!';

  @override
  String get accountsAppBarTitle => 'অ্যাকাউন্ট';

  @override
  String accountsBalanceLabel(Object balance) {
    return 'ব্যালেন্স: $balance';
  }

  @override
  String get accountsLoadFailure => 'অ্যাকাউন্ট লোড করতে ব্যর্থ';

  @override
  String get accountsEmptyState => 'কোনো অ্যাকাউন্ট নেই';

  @override
  String get accountsRefreshTooltip => 'রিফ্রেশ';

  @override
  String get accountsAddTooltip => 'অ্যাকাউন্ট যোগ করুন';

  @override
  String get addAccountDescription => 'একটি নতুন ব্যাঙ্ক অ্যাকাউন্ট, ওয়ালেট বা অ্যাসেট তৈরি করুন';

  @override
  String get addAccountDialogTitle => 'নতুন অ্যাকাউন্ট যোগ করুন';

  @override
  String get accountNameHint => 'অ্যাকাউন্টের নাম';

  @override
  String get initialBalanceHint => 'প্রারম্ভিক ব্যালেন্স';

  @override
  String get currencyLabel => 'মুদ্রা';

  @override
  String get cancelButton => 'বাতিল';

  @override
  String get saveButton => 'সংরক্ষণ';

  @override
  String get deleteButton => 'মুছুন';

  @override
  String get editButton => 'সম্পাদনা';

  @override
  String get applyButton => 'প্রয়োগ';

  @override
  String get clearButton => 'মুছুন';

  @override
  String get formValidationPleaseEnterName => 'অনুগ্রহ করে একটি নাম দিন';

  @override
  String get formValidationPleaseEnterBalance => 'অনুগ্রহ করে একটি ব্যালেন্স দিন';

  @override
  String get formValidationPleaseEnterValidNumber => 'অনুগ্রহ করে একটি বৈধ সংখ্যা দিন';

  @override
  String get formValidationPleaseSelectCurrency => 'অনুগ্রহ করে একটি মুদ্রা নির্বাচন করুন';

  @override
  String get currencyLoadError => 'মুদ্রা লোড করতে ত্রুটি';

  @override
  String get noCurrenciesAvailable => 'কোনো মুদ্রা উপলব্ধ নেই';

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
  String get filePickerChooserTitle => 'ফাইল নির্বাচন করুন';

  @override
  String get imagePickerChooserTitle => 'ছবি নির্বাচন করুন';

  @override
  String get totalNetWorth => 'মোট নেট মূল্য';

  @override
  String get currencyBreakdown => 'মুদ্রার বিবরণ';

  @override
  String get metricBalance => 'ব্যালেন্স';

  @override
  String get metricIncome => 'আয়';

  @override
  String get metricExpense => 'ব্যয়';

  @override
  String get metricReal => 'বাস্তব';

  @override
  String get metricChange => 'পরিবর্তন';

  @override
  String get contextMenuSelect => 'নির্বাচন করুন';

  @override
  String get contextMenuDeselect => 'নির্বাচন বাতিল';

  @override
  String get contextMenuSelectAll => 'সব নির্বাচন করুন';

  @override
  String get contextMenuDeselectAll => 'সব নির্বাচন বাতিল';

  @override
  String get contextMenuAddTransaction => 'লেনদেন যোগ করুন';

  @override
  String get addTransactionDescription => 'একটি নতুন লেনদেন তৈরি করুন';

  @override
  String get contextMenuTransfer => 'স্থানান্তর';

  @override
  String get contextMenuEdit => 'সম্পাদনা';

  @override
  String get contextMenuDelete => 'মুছুন';

  @override
  String get contextMenuChangeType => 'ধরন পরিবর্তন করুন';

  @override
  String deleteConfirmationTitle(Object item) {
    return '$item মুছবেন?';
  }

  @override
  String deleteConfirmationMessage(Object item) {
    return 'আপনি কি নিশ্চিত যে আপনি এই $item এবং এর সমস্ত ডেটা মুছতে চান?';
  }

  @override
  String get deleteAccountsConfirmationTitle => 'অ্যাকাউন্ট মুছবেন?';

  @override
  String deleteAccountsConfirmationMessage(Object count) {
    return 'নির্বাচিত $count টি অ্যাকাউন্ট এবং তাদের লেনদেন মুছবেন?';
  }

  @override
  String get deleteAccountDialogReassign => 'লেনদেন অন্য অ্যাকাউন্টে পুনরায় বরাদ্দ করুন';

  @override
  String get deleteAccountDialogDeleteAll => 'সমস্ত সম্পর্কিত লেনদেন মুছুন';

  @override
  String get deleteAccountDialogMessage => 'এই অ্যাকাউন্টে সম্পর্কিত লেনদেন থাকতে পারে। আপনি কি করতে চান?';

  @override
  String get newAccountLabel => 'নতুন অ্যাকাউন্ট';

  @override
  String get warningOverwriteTitle => 'সতর্কতা: ডেটা ওভাররাইট করবেন?';

  @override
  String get warningOverwriteMessage => 'ব্যাকআপ পুনরুদ্ধার করলে সমস্ত বর্তমান ডেটা মুছে যাবে এবং ব্যাকআপ দিয়ে প্রতিস্থাপিত হবে। এটি পূর্বাবস্থায় ফেরানো যাবে না।';

  @override
  String get restoreOverwriteButton => 'পুনরুদ্ধার এবং ওভাররাইট';

  @override
  String get importSuccess => 'আমদানি সফলভাবে সম্পন্ন হয়েছে।';

  @override
  String importFailed(Object error) {
    return 'আমদানি ব্যর্থ: $error';
  }

  @override
  String deleteCategoriesConfirmationTitle(Object count) {
    return '$count টি বিভাগ মুছবেন?';
  }

  @override
  String get deleteCategoriesConfirmationMessage => 'আপনি কি নিশ্চিত যে আপনি নির্বাচিত বিভাগগুলি মুছতে চান?';

  @override
  String get changeCategoryTypeDialogTitle => 'বিভাগের ধরন পরিবর্তন করুন';

  @override
  String get noCategoriesCreated => 'এখনও কোনো বিভাগ তৈরি করা হয়নি।';

  @override
  String get addCategoryTooltip => 'বিভাগ যোগ করুন';

  @override
  String get addCategoryDescription => 'একটি নতুন ব্যয় বা আয় বিভাগ তৈরি করুন';

  @override
  String get previousPeriodTooltip => 'পূর্ববর্তী সময়কাল';

  @override
  String get previousPeriodDescription => 'আগের মাস বা বছরে যান';

  @override
  String get nextPeriodTooltip => 'পরবর্তী সময়কাল';

  @override
  String get nextPeriodDescription => 'পরের মাস বা বছরে যান';

  @override
  String get filterTooltip => 'ফিল্টার';

  @override
  String get filterCategoriesDescription => 'ধরন অনুযায়ী বিভাগ ফিল্টার করুন (আয়/ব্যয়)';

  @override
  String get selectDateTooltip => 'তারিখ নির্বাচন করুন';

  @override
  String get selectDateDescription => 'মোট দেখতে একটি নির্দিষ্ট তারিখ পরিসীমা নির্বাচন করুন';

  @override
  String get sortOrderTooltip => 'সাজানোর ক্রম';

  @override
  String get sortOrderDescription => 'পরিমাণ অনুযায়ী আরোহী এবং অবরোহী ক্রম পরিবর্তন করুন';

  @override
  String totalCountLabel(Object count) {
    return 'মোট: $count';
  }

  @override
  String get closeSelectionTooltip => 'নির্বাচন বন্ধ করুন';

  @override
  String get exitSelectionDescription => 'নির্বাচন মোড থেকে প্রস্থান করুন';

  @override
  String selectedCountLabel(Object count) {
    return '$count নির্বাচিত';
  }

  @override
  String get categoryNameLabel => 'বিভাগের নাম';

  @override
  String get categoriesChangeButton => 'পরিবর্তন';

  @override
  String get parentCategoryLabel => 'মূল বিভাগ';

  @override
  String get styleLabel => 'শৈলী (আইকন এবং রঙ)';

  @override
  String get typeLabel => 'ধরন';

  @override
  String get deleteTransactionsConfirmationTitle => 'লেনদেন মুছুন';

  @override
  String deleteTransactionsConfirmationMessage(Object count) {
    return 'আপনি কি নিশ্চিত যে আপনি $count টি নির্বাচিত লেনদেন মুছতে চান?';
  }

  @override
  String get changeDateTooltip => 'তারিখ পরিবর্তন করুন';

  @override
  String get changeDateDescription => 'সমস্ত নির্বাচিত লেনদেনের জন্য তারিখ আপডেট করুন';

  @override
  String get changeCategoryTooltip => 'বিভাগ পরিবর্তন করুন';

  @override
  String get changeCategoryDescription => 'সমস্ত নির্বাচিত লেনদেনের জন্য বিভাগ আপডেট করুন';

  @override
  String get deleteTransactionsTooltip => 'নির্বাচিত মুছুন';

  @override
  String get deleteTransactionsDescription => 'সমস্ত নির্বাচিত লেনদেন স্থায়ীভাবে মুছুন';

  @override
  String get exitTransactionsSelectionDescription => 'লেনদেন নির্বাচন মোড থেকে প্রস্থান করুন';

  @override
  String quantityLabel(Object quantity) {
    return 'পরিমাণ: $quantity';
  }

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
  String get amountLabel => 'পরিমাণ';

  @override
  String get quantityFormLabel => 'পরিমাণ';

  @override
  String get selectAccountTitle => 'অ্যাকাউন্ট নির্বাচন করুন';

  @override
  String get selectCategoryTitle => 'বিভাগ নির্বাচন করুন';

  @override
  String get selectCurrencyTitle => 'মুদ্রা নির্বাচন করুন';

  @override
  String get accountLabel => 'অ্যাকাউন্ট';

  @override
  String get fromAccountLabel => 'অ্যাকাউন্ট থেকে';

  @override
  String get toAccountLabel => 'অ্যাকাউন্টে';

  @override
  String get categoryLabel => 'বিভাগ';

  @override
  String get dateLabel => 'তারিখ';

  @override
  String get selectDateLabel => 'তারিখ নির্বাচন করুন';

  @override
  String get swapAccountsTooltip => 'অ্যাকাউন্ট অদলবদল করুন';

  @override
  String get incomeType => 'আয়';

  @override
  String get expenseType => 'ব্যয়';

  @override
  String get failedToLoadData => 'ডেটা লোড করতে ব্যর্থ';

  @override
  String get invalidAmountError => 'অনুগ্রহ করে একটি বৈধ সংখ্যা দিন';

  @override
  String get emptyAmountError => 'অনুগ্রহ করে একটি পরিমাণ দিন';

  @override
  String get selectAccountError => 'অনুগ্রহ করে একটি অ্যাকাউন্ট নির্বাচন করুন';

  @override
  String get selectCategoryError => 'অনুগ্রহ করে একটি বিভাগ নির্বাচন করুন';

  @override
  String get selectDateError => 'অনুগ্রহ করে একটি তারিখ নির্বাচন করুন';

  @override
  String get currencyLockedMessage => 'উৎস অ্যাকাউন্টের মুদ্রায় লক করা';

  @override
  String get totalValueLabel => 'মোট মূল্য';

  @override
  String get feeLabel => 'ফি';

  @override
  String get exchangeRateLabel => 'বিনিময় হার';

  @override
  String get pricePerUnitLabel => 'প্রতি ইউনিটের দাম';

  @override
  String get buyAction => 'ক্রয়';

  @override
  String get sellAction => 'বিক্রয়';

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
    return '$assetName ক্রয়';
  }

  @override
  String sellDescription(Object assetName) {
    return '$assetName বিক্রয়';
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
  String get updateButton => 'আপডেট';

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
  String get selectLinkedAccountTitle => 'সংযুক্ত অ্যাকাউন্ট নির্বাচন করুন';

  @override
  String get settingsTitle => 'সেটিংস';

  @override
  String get manageIconsLabel => 'আইকন পরিচালনা করুন';

  @override
  String get manageThemeLabel => 'থিম পরিচালনা করুন';

  @override
  String get mainCurrencyLabel => 'প্রধান মুদ্রা';

  @override
  String get defaultInflationCountryLabel => 'ডিফল্ট মুদ্রাস্ফীতি দেশ';

  @override
  String get persistAdvancedFiltersLabel => 'উন্নত ফিল্টার বজায় রাখুন';

  @override
  String get hotKeysLabel => 'হট কি';

  @override
  String get smsImportLabel => 'এসএমএস আমদানি';

  @override
  String get smsImportSubtitle => 'ব্যাঙ্ক এসএমএস থেকে লেনদেন আমদানি করুন';

  @override
  String get apiManagementLabel => 'API ব্যবস্থাপনা';

  @override
  String get dataLabel => 'ডেটা';

  @override
  String get syncSettingsLabel => 'সিঙ্ক সেটিংস';

  @override
  String get syncSettingsSubtitle => 'Syncthing এর মাধ্যমে P2P সিঙ্ক';

  @override
  String get importDataLabel => 'ডেটা আমদানি করুন';

  @override
  String get exportDataLabel => 'ডেটা রপ্তানি করুন';

  @override
  String get exportFormatMessage => 'ফরম্যাট চয়ন করুন:\n\nJSON: সমস্ত ডেটার সম্পূর্ণ ব্যাকআপ।\nCSV: লেনদেনের পঠনযোগ্য প্রতিবেদন।';

  @override
  String get jsonFormat => 'JSON';

  @override
  String get csvFormat => 'CSV';

  @override
  String get importExchangeRatesLabel => 'বিনিময় হার আমদানি করুন (CSV/JSON)';

  @override
  String get resetDataLabel => 'ডিফল্টে ডেটা রিসেট করুন';

  @override
  String get resetDataSubtitle => 'এটি সমস্ত ডেটা মুছে ফেলবে এবং ডিফল্ট সেটিংস পুনরুদ্ধার করবে।';

  @override
  String get debugMenuLabel => 'ডিবাগ মেনু';

  @override
  String get debugMenuSubtitle => 'অভ্যন্তরীণ বিকাশকারী সরঞ্জাম';

  @override
  String get exportSuccessMessage => 'রপ্তানি সফলভাবে সম্পন্ন হয়েছে';

  @override
  String exportFailedMessage(Object error) {
    return 'রপ্তানি ব্যর্থ: $error';
  }

  @override
  String get importSuccessMessage => 'আমদানি সফলভাবে সম্পন্ন হয়েছে';

  @override
  String importFailedMessage(Object error) {
    return 'আমদানি ব্যর্থ: $error';
  }

  @override
  String get resetDataConfirmationTitle => 'ডেটা রিসেট করবেন?';

  @override
  String get resetDataConfirmationMessage => 'সতর্কতা! এটি আপনার সমস্ত লেনদেন, অ্যাকাউন্ট এবং সেটিংস মুছে ফেলবে।\n\nঅ্যাপটি ডিফল্ট ডেটা সহ তার প্রাথমিক অবস্থায় পুনরুদ্ধার করা হবে।\nএই ক্রিয়াটি পূর্বাবস্থায় ফেরানো যাবে না।';

  @override
  String get resetEverythingButton => 'সবকিছু রিসেট করুন';

  @override
  String get resetSuccessMessage => 'ডেটা রিসেট এবং ডিফল্ট পুনরুদ্ধার করা হয়েছে।';

  @override
  String resetFailedMessage(Object error) {
    return 'রিসেট ব্যর্থ: $error';
  }

  @override
  String get importParsingStep => 'CSV ফাইল পার্স করা হচ্ছে...';

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
  String get importSelectionHelp => 'মাইগ্রেশনের জন্য \'OneMoney\', লেনদেন যোগ করার জন্য \'MyBudget\', অথবা সব ডেটা ওভাররাইট করতে \'ব্যাকআপ পুনরুদ্ধার করুন\' বেছে নিন।';

  @override
  String get importCreateAllNew => 'সব নতুন তৈরি করুন';

  @override
  String importNewAccountFound(Object accountName) {
    return 'নতুন অ্যাকাউন্ট পাওয়া গেছে: \"$accountName\"';
  }

  @override
  String importMapAccountTitle(Object accountName) {
    return '\"$accountName\" কে এর সাথে ম্যাপ করুন...';
  }

  @override
  String get importMapToExisting => 'বিদ্যমান এর সাথে ম্যাপ করুন';

  @override
  String get importCreateNew => 'নতুন তৈরি করুন';

  @override
  String importNewCategoryFound(Object categoryName) {
    return 'নতুন বিভাগ পাওয়া গেছে: \"$categoryName\"';
  }

  @override
  String importMapCategoryTitle(Object categoryName) {
    return '\"$categoryName\" কে এর সাথে ম্যাপ করুন...';
  }

  @override
  String importNewCurrencyFound(Object currencyName) {
    return 'নতুন মুদ্রা পাওয়া গেছে: \"$currencyName\"';
  }

  @override
  String importMapCurrencyTitle(Object currencyName) {
    return '\"$currencyName\" কে এর সাথে ম্যাপ করুন...';
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
    return 'প্রতি: $to';
  }

  @override
  String importAmountLabel(Object amount, Object currency) {
    return 'পরিমাণ: $amount $currency';
  }

  @override
  String get importSkip => 'এড়িয়ে যান';

  @override
  String get importImportAnyway => 'তবুও আমদানি করুন';

  @override
  String importDecisionLabel(Object decision) {
    return 'সিদ্ধান্ত: $decision';
  }

  @override
  String get importReadyTitle => 'আমদানির জন্য প্রস্তুত';

  @override
  String importReadyMessage(Object count) {
    return '$count টি লেনদেন আমদানির জন্য প্রস্তুত।';
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
  String get importDataTitle => 'ডেটা আমদানি করুন';

  @override
  String importAccountsCreatedLabel(Object count) {
    return 'নতুন অ্যাকাউন্ট তৈরি করা হয়েছে: $count';
  }

  @override
  String importCategoriesCreatedLabel(Object count) {
    return 'নতুন বিভাগ তৈরি করা হয়েছে: $count';
  }

  @override
  String importTransactionsImportedLabel(Object count) {
    return 'লেনদেন আমদানি করা হয়েছে: $count';
  }

  @override
  String importDuplicatesSkippedLabel(Object count) {
    return 'ডুপ্লিকেট এড়িয়ে যাওয়া হয়েছে: $count';
  }

  @override
  String get searchHint => 'অনুসন্ধান';

  @override
  String get debugAllDataClearedMessage => 'সব ডেটা মুছে ফেলা হয়েছে এবং ডিফল্ট দিয়ে পুনরায় পূর্ণ করা হয়েছে।';

  @override
  String get debugClearAllDataLabel => 'সব ডেটা মুছুন (এবং ডিফল্ট পূর্ণ করুন)';

  @override
  String get debugMinimumDataSeededMessage => 'নূন্যতম ডেটা পূর্ণ করা হয়েছে।';

  @override
  String get debugSeedMinimumDataLabel => 'নূন্যতম ডেটা পূর্ণ করুন';

  @override
  String get debugMediumDataSeededMessage => 'মাঝারি ডেটা পূর্ণ করা হয়েছে।';

  @override
  String get debugSeedMediumDataLabel => 'মাঝারি ডেটা পূর্ণ করুন';

  @override
  String get debugMaximumDataSeededMessage => 'সর্বোচ্চ ডেটা পূর্ণ করা হয়েছে।';

  @override
  String get debugSeedMaximumDataLabel => 'সর্বোচ্চ ডেটা পূর্ণ করুন (পারফরম্যান্স টেস্টের জন্য)';

  @override
  String get debugRunningInDebugModeLabel => 'ডিবাগ মোডে চলছে';

  @override
  String get deleteAllButton => 'সব মুছে ফেলুন';

  @override
  String get changeButton => 'পরিবর্তন করুন';

  @override
  String get undoButton => 'পূর্বাবস্থায় ফেরান';

  @override
  String itemDeletedMessage(Object name) {
    return '$name মুছে ফেলা হয়েছে';
  }

  @override
  String get totalBalanceLabel => 'মোট ব্যালেন্স';

  @override
  String get noCurrenciesSelected => 'কোনো মুদ্রা নির্বাচন করা হয়নি।';

  @override
  String get incomeLabel => 'আয়';

  @override
  String get expenseLabel => 'ব্যয়';

  @override
  String get failedToLoadDashboard => 'ড্যাশবোর্ড লোড করতে ব্যর্থ হয়েছে';

  @override
  String get dashboardCalendarTab => 'ক্যালেন্ডার';

  @override
  String get dashboardCalendarTooltip => 'ক্যালেন্ডার ভিউ';

  @override
  String get dashboardCalendarDescription => 'ক্যালেন্ডার ফরম্যাটে লেনদেন দেখুন';

  @override
  String get dashboardCategoriesTab => 'বিভাগ';

  @override
  String get dashboardCategoriesTooltip => 'বিভাগ বিশ্লেষণ';

  @override
  String get dashboardCategoriesDescription => 'বিভাগ অনুযায়ী ব্যয়ের বিবরণ';

  @override
  String get dashboardBalanceTab => 'ব্যালেন্স';

  @override
  String get dashboardBalanceTooltip => 'ব্যালেন্স ইতিহাস';

  @override
  String get dashboardBalanceDescription => 'সময়ের সাথে সাথে নেট ওয়ার্থ ট্র্যাক করুন';

  @override
  String get dashboardExpensesLabel => 'ব্যয়';

  @override
  String get dashboardIncomeLabel => 'আয়';

  @override
  String get manageIconsTitle => 'আইকন পরিচালনা করুন';

  @override
  String get noIconsCreated => 'এখনও কোনও আইকন তৈরি করা হয়নি।';

  @override
  String get failedToLoadIcons => 'আইকন লোড করতে ব্যর্থ হয়েছে।';

  @override
  String get cannotDeleteTransferIcon => 'ট্রান্সফার আইকন মুছে ফেলা যাবে না।';

  @override
  String get deleteIconsDialogTitle => 'আইকন মুছুন';

  @override
  String deleteIconsConfirmationMessage(Object count) {
    return 'আপনি কি নিশ্চিত যে আপনি $count টি নির্বাচিত আইকন মুছে ফেলতে চান?';
  }

  @override
  String deleteIconsWithSkipTransferMessage(Object count) {
    return 'আপনি কি নিশ্চিত যে আপনি $count টি নির্বাচিত আইকন মুছে ফেলতে চান? (ট্রান্সফার আইকনটি বাদ দেওয়া হবে)';
  }

  @override
  String get deleteIconDialogTitle => 'আইকন মুছুন';

  @override
  String deleteIconConfirmationMessage(Object name) {
    return 'আপনি কি নিশ্চিত যে আপনি \"$name\" আইকনটি মুছে ফেলতে চান?';
  }

  @override
  String deleteMultipleAccountsTitle(Object count) {
    return '$count টি অ্যাকাউন্ট মুছবেন?';
  }

  @override
  String get deleteMultipleAccountsMessage => 'আপনি কি নিশ্চিত যে আপনি নির্বাচিত অ্যাকাউন্টগুলি মুছে ফেলতে চান? সমস্ত সম্পর্কিত লেনদেন মুছে ফেলা হবে।';

  @override
  String get changeAccountTypeDialogTitle => 'অ্যাকাউন্টের ধরন পরিবর্তন করুন';

  @override
  String editAccountTitle(Object name) {
    return 'সম্পাদনা: $name';
  }

  @override
  String get balanceCalculatedFromAsset => 'ব্যালেন্স গণনা করা হয় অ্যাসেট পরিমাণ * মূল্য থেকে';

  @override
  String get selectAccountTypeTitle => 'অ্যাকাউন্টের ধরন নির্বাচন করুন';

  @override
  String get selectCountryTitle => 'দেশ নির্বাচন করুন';

  @override
  String get selectIconSubtitle => 'একটি আইকন নির্বাচন করুন';

  @override
  String get bindToAssetLabel => 'সম্পদ বাইন্ড করুন (ঐচ্ছিক)';

  @override
  String get selectAssetTitle => 'সম্পদ নির্বাচন করুন';

  @override
  String get selectedAssetLabel => 'নির্বাচিত সম্পদ';

  @override
  String get balanceAutoCalculatedLabel => 'ব্যালেন্স স্বয়ংক্রিয়ভাবে গণনা করা হয়';

  @override
  String get tapToBindAssetLabel => 'একটি সম্পদ বাইন্ড করতে ট্যাপ করুন';

  @override
  String get assetQuantityLabel => 'সম্পদের পরিমাণ';

  @override
  String get linkedAssetsTitle => 'সংযুক্ত সম্পদ';

  @override
  String get noneLabel => 'কোনটিই নয়';

  @override
  String get accountTypeLabel => 'অ্যাকাউন্টের ধরন';

  @override
  String get formValidationPleaseSelectAccountType => 'অনুগ্রহ করে অ্যাকাউন্টের ধরন নির্বাচন করুন';

  @override
  String get iconLabel => 'আইকন';

  @override
  String get languageLabel => 'ভাষা';

  @override
  String get systemDefaultLabel => 'সিস্টেম ডিফল্ট';

  @override
  String get selectLanguageTitle => 'ভাষা নির্বাচন করুন';
}
