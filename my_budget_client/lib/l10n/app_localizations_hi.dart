// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get collapseMenuTooltip => 'मेनू संक्षिप्त करें';

  @override
  String get expandMenuTooltip => 'मेनू विस्तृत करें';

  @override
  String get helloWorld => 'नमस्ते दुनिया!';

  @override
  String get accountsAppBarTitle => 'खाते';

  @override
  String accountsBalanceLabel(Object balance) {
    return 'शेष राशि: $balance';
  }

  @override
  String get accountsLoadFailure => 'खाते लोड करने में विफल';

  @override
  String get accountsEmptyState => 'कोई खाता नहीं';

  @override
  String get accountsRefreshTooltip => 'ताज़ा करें';

  @override
  String get accountsAddTooltip => 'खाता जोड़ें';

  @override
  String get addAccountDescription => 'एक नया बैंक खाता, वॉलेट या एसेट बनाएं';

  @override
  String get addAccountDialogTitle => 'नया खाता जोड़ें';

  @override
  String get editAccountDialogTitle => 'खाता संपादित करें';

  @override
  String get accountNameHint => 'खाता नाम';

  @override
  String get initialBalanceHint => 'प्रारंभिक शेष राशि';

  @override
  String get currencyLabel => 'मुद्रा';

  @override
  String get cancelButton => 'रद्द करें';

  @override
  String get saveButton => 'सहेजें';

  @override
  String get deleteButton => 'हटाएं';

  @override
  String get editButton => 'संपादित करें';

  @override
  String get applyButton => 'लागू करें';

  @override
  String get clearButton => 'साफ़ करें';

  @override
  String get selectButton => 'चुनें';

  @override
  String get selectAllButton => 'सभी चुनें';

  @override
  String get deselectAllButton => 'सभी अचयनित करें';

  @override
  String get deleteSelectedButton => 'चयनित हटाएं';

  @override
  String totalCountLabel(Object count) {
    return 'कुल: $count';
  }

  @override
  String selectedCountLabel(Object count) {
    return '$count चयनित';
  }

  @override
  String get formValidationPleaseEnterName => 'कृपया नाम दर्ज करें';

  @override
  String get formValidationPleaseEnterBalance => 'कृपया शेष राशि दर्ज करें';

  @override
  String get formValidationPleaseEnterValidNumber => 'कृपया एक मान्य संख्या दर्ज करें';

  @override
  String get formValidationPleaseSelectCurrency => 'कृपया एक मुद्रा चुनें';

  @override
  String get currencyLoadError => 'मुद्रा लोड करने में त्रुटि';

  @override
  String get noCurrenciesAvailable => 'कोई मुद्रा उपलब्ध नहीं';

  @override
  String get categoriesAppBarTitle => 'श्रेणियाँ';

  @override
  String get categoriesScreenBody => 'श्रेणियाँ स्क्रीन';

  @override
  String get transactionsAppBarTitle => 'लेन-देन';

  @override
  String get transactionsScreenBody => 'लेन-देन स्क्रीन';

  @override
  String get settingsAppBarTitle => 'सेटिंग्स';

  @override
  String get settingsScreenBody => 'सेटिंग्स स्क्रीन';

  @override
  String get filePickerChooserTitle => 'फ़ाइल चुनें';

  @override
  String get imagePickerChooserTitle => 'छवि चुनें';

  @override
  String get totalNetWorth => 'कुल निवल मूल्य';

  @override
  String get currencyBreakdown => 'मुद्रा विभाजन';

  @override
  String get dashboardNetWorthTrend => 'निवल मूल्य की प्रवृत्ति';

  @override
  String get dashboardWealthDistributionByAccount => 'धन वितरण (खाते द्वारा)';

  @override
  String get dashboardCurrencyExposure => 'मुद्रा जोखिम';

  @override
  String get dashboardNoAccountsFound => 'कोई खाता नहीं मिला';

  @override
  String get dashboardTotalNetWorthTrend => 'कुल निवल मूल्य की प्रवृत्ति';

  @override
  String get dashboardAccountBalanceTrend => 'खाता शेष की प्रवृत्ति';

  @override
  String get dashboardWealthDistribution => 'धन वितरण';

  @override
  String get dashboardCurrencyBreakdown => 'मुद्रा विभाजन';

  @override
  String get metricBalance => 'शेष';

  @override
  String get metricIncome => 'आय';

  @override
  String get metricExpense => 'व्यय';

  @override
  String get metricReal => 'वास्तविक';

  @override
  String get metricChange => 'परिवर्तन';

  @override
  String get contextMenuSelect => 'चुनें';

  @override
  String get contextMenuDeselect => 'अचयनित करें';

  @override
  String get contextMenuSelectAll => 'सभी चुनें';

  @override
  String get contextMenuDeselectAll => 'सभी अचयनित करें';

  @override
  String get contextMenuAddTransaction => 'लेन-देन जोड़ें';

  @override
  String get addTransactionDescription => 'एक नया लेनदेन बनाएं';

  @override
  String get contextMenuTransfer => 'हस्तांतरण';

  @override
  String get contextMenuEdit => 'संपादित करें';

  @override
  String get contextMenuDelete => 'हटाएं';

  @override
  String get contextMenuChangeType => 'प्रकार बदलें';

  @override
  String deleteConfirmationTitle(Object item) {
    return '$item हटाएं?';
  }

  @override
  String deleteConfirmationMessage(Object item) {
    return 'क्या आप वाकई इस $item और इसके सभी डेटा को हटाना चाहते हैं?';
  }

  @override
  String get deleteAccountsConfirmationTitle => 'खाते हटाएं?';

  @override
  String deleteAccountsConfirmationMessage(Object count) {
    return 'चयनित $count खाते और उनके लेन-देन हटाएं?';
  }

  @override
  String get deleteAccountDialogReassign => 'लेन-देन को दूसरे खाते में पुन: असाइन करें';

  @override
  String get deleteAccountDialogDeleteAll => 'सभी संबंधित लेन-देन हटाएं';

  @override
  String get deleteAccountDialogMessage => 'इस खाते में संबंधित लेन-देन हो सकते हैं। आप क्या करना चाहेंगे?';

  @override
  String get newAccountLabel => 'नया खाता';

  @override
  String get warningOverwriteTitle => 'चेतावनी: डेटा ओवरराइट करें?';

  @override
  String get warningOverwriteMessage => 'बैकअप बहाल करने से सभी मौजूदा डेटा हट जाएगा और बैकअप से बदल जाएगा। इसे पूर्ववत नहीं किया जा सकता है।';

  @override
  String get restoreOverwriteButton => 'बहाल और ओवरराइट';

  @override
  String get importSuccess => 'आयात सफलतापूर्वक पूरा हुआ।';

  @override
  String importFailed(Object error) {
    return 'आयात विफल: $error';
  }

  @override
  String deleteCategoriesConfirmationTitle(Object count) {
    return '$count श्रेणियाँ हटाएं?';
  }

  @override
  String get deleteCategoriesConfirmationMessage => 'क्या आप वाकई चयनित श्रेणियाँ हटाना चाहते हैं?';

  @override
  String get changeCategoryTypeDialogTitle => 'श्रेणी प्रकार बदलें';

  @override
  String get noCategoriesCreated => 'अभी तक कोई श्रेणी नहीं बनाई गई है।';

  @override
  String get addCategoryTooltip => 'श्रेणी जोड़ें';

  @override
  String get addCategoryDescription => 'नया व्यय या आय श्रेणी बनाएं';

  @override
  String get previousPeriodTooltip => 'पिछली अवधि';

  @override
  String get previousPeriodDescription => 'पिछले महीने या साल पर जाएं';

  @override
  String get nextPeriodTooltip => 'अगली अवधि';

  @override
  String get nextPeriodDescription => 'अगले महीने या साल पर जाएं';

  @override
  String get filterTooltip => 'फ़िल्टर';

  @override
  String get filterCategoriesDescription => 'प्रकार (आय/व्यय) द्वारा श्रेणियाँ फ़िल्टर करें';

  @override
  String get selectDateTooltip => 'दिनांक चुनें';

  @override
  String get selectDateDescription => 'कुल देखने के लिए एक विशिष्ट दिनांक सीमा चुनें';

  @override
  String get sortOrderTooltip => 'क्रमबद्ध क्रम';

  @override
  String get sortOrderDescription => 'राशि के अनुसार आरोही और अवरोही क्रम के बीच स्विच करें';

  @override
  String get closeSelectionTooltip => 'चयन बंद करें';

  @override
  String get exitSelectionDescription => 'चयन मोड से बाहर निकलें';

  @override
  String get categoryNameLabel => 'श्रेणी का नाम';

  @override
  String get categoriesChangeButton => 'बदलें';

  @override
  String get parentCategoryLabel => 'मूल श्रेणी';

  @override
  String get styleLabel => 'शैली (आइकन और रंग)';

  @override
  String get typeLabel => 'प्रकार';

  @override
  String get deleteTransactionsConfirmationTitle => 'लेन-देन हटाएं';

  @override
  String deleteTransactionsConfirmationMessage(Object count) {
    return 'क्या आप वाकई $count चयनित लेन-देन हटाना चाहते हैं?';
  }

  @override
  String get exitTransactionsSelectionDescription => 'लेन-देन चयन मोड से बाहर निकलें';

  @override
  String get changeDateTooltip => 'दिनांक बदलें';

  @override
  String get changeDateDescription => 'सभी चयनित लेन-देन के लिए दिनांक अपडेट करें';

  @override
  String get changeCategoryTooltip => 'श्रेणी बदलें';

  @override
  String get changeCategoryDescription => 'सभी चयनित लेन-देन के लिए श्रेणी अपडेट करें';

  @override
  String get deleteTransactionsTooltip => 'चयनित हटाएं';

  @override
  String get deleteTransactionsDescription => 'सभी चयनित लेन-देन स्थायी रूप से हटाएं';

  @override
  String get amountLabel => 'राशि';

  @override
  String quantityLabel(Object quantity) {
    return 'मात्रा: $quantity';
  }

  @override
  String get quantityFormLabel => 'मात्रा';

  @override
  String get selectAccountTitle => 'खाता चुनें';

  @override
  String get selectCategoryTitle => 'श्रेणी चुनें';

  @override
  String get selectCurrencyTitle => 'मुद्रा चुनें';

  @override
  String get accountLabel => 'खाता';

  @override
  String get fromAccountLabel => 'खाते से';

  @override
  String get toAccountLabel => 'खाते में';

  @override
  String get categoryLabel => 'श्रेणी';

  @override
  String get dateLabel => 'दिनांक';

  @override
  String get selectDateLabel => 'दिनांक चुनें';

  @override
  String get addTransactionTitle => 'लेन-देन जोड़ें';

  @override
  String get editTransactionTitle => 'लेन-देन संपादित करें';

  @override
  String get newTransferTitle => 'नया हस्तांतरण';

  @override
  String get editTransferTitle => 'हस्तांतरण संपादित करें';

  @override
  String get descriptionLabel => 'विवरण';

  @override
  String get descriptionOptionalLabel => 'विवरण (वैकल्पिक)';

  @override
  String get swapAccountsTooltip => 'खाते अदला-बदली करें';

  @override
  String get incomeType => 'आय';

  @override
  String get expenseType => 'व्यय';

  @override
  String get failedToLoadData => 'डेटा लोड करने में विफल';

  @override
  String get invalidAmountError => 'कृपया एक मान्य संख्या दर्ज करें';

  @override
  String get emptyAmountError => 'कृपया राशि दर्ज करें';

  @override
  String get selectAccountError => 'कृपया एक खाता चुनें';

  @override
  String get selectCategoryError => 'कृपया एक श्रेणी चुनें';

  @override
  String get selectDateError => 'कृपया एक दिनांक चुनें';

  @override
  String get currencyLockedMessage => 'स्रोत खाते की मुद्रा में लॉक किया गया';

  @override
  String get totalValueLabel => 'कुल मूल्य';

  @override
  String get feeLabel => 'शुल्क';

  @override
  String get exchangeRateLabel => 'विनिमय दर';

  @override
  String get pricePerUnitLabel => 'प्रति इकाई मूल्य';

  @override
  String get buyAction => 'खरीदें';

  @override
  String get sellAction => 'बेचें';

  @override
  String transferToDescription(Object accountName) {
    return '$accountName को हस्तांतरण';
  }

  @override
  String transferFromDescription(Object accountName) {
    return '$accountName से हस्तांतरण';
  }

  @override
  String buyDescription(Object assetName) {
    return '$assetName खरीदें';
  }

  @override
  String sellDescription(Object assetName) {
    return '$assetName बेचें';
  }

  @override
  String assetTransferDescription(Object action, Object assetName) {
    return '$action $assetName के लिए स्थानांतरण';
  }

  @override
  String get swapDirectionTooltip => 'दिशा बदलें';

  @override
  String get availablePresetsLabel => 'उपलब्ध प्रीसेट:';

  @override
  String get updateButton => 'अपडेट करें';

  @override
  String get newPresetButton => 'नया प्रीसेट';

  @override
  String get amountToAddToAccountLabel => 'खाते में जोड़ने के लिए राशि:';

  @override
  String valueInGlobalLabel(Object currency) {
    return 'वैश्विक मूल्य ($currency):';
  }

  @override
  String get feeCommissionLabel => 'शुल्क (کमीशन)';

  @override
  String get requiredError => 'आवश्यक';

  @override
  String currentPriceLabel(Object currency, Object price) {
    return 'वर्तमान मूल्य: $price $currency';
  }

  @override
  String get linkedAccountLabel => 'लिंक किया गया खाता';

  @override
  String get selectLinkedAccountTitle => 'लिंक किया गया खाता चुनें';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get manageIconsLabel => 'आइकन प्रबंधित करें';

  @override
  String get manageThemeLabel => 'थीम प्रबंधित करें';

  @override
  String get mainCurrencyLabel => 'मुख्य मुद्रा';

  @override
  String get defaultInflationCountryLabel => 'डिफ़ॉल्ट मुद्रास्फीति देश';

  @override
  String get persistAdvancedFiltersLabel => 'उन्नत फ़िल्टर बनाए रखें';

  @override
  String get hotKeysLabel => 'हॉट कुंजियाँ';

  @override
  String get smsImportLabel => 'एसएमएस आयात';

  @override
  String get smsImportSubtitle => 'बैंक एसएमएस से लेन-देन आयात करें';

  @override
  String get apiManagementLabel => 'एपीआई प्रबंधन';

  @override
  String get dataLabel => 'डेटा';

  @override
  String get syncSettingsLabel => 'सिंक सेटिंग्स';

  @override
  String get syncSettingsSubtitle => 'Syncthing के माध्यम से P2P सिंक';

  @override
  String get themeSettingsTitle => 'थीम सेटिंग्स';

  @override
  String get appearanceSection => 'दिखावट';

  @override
  String get themeModeLabel => 'थीम मोड';

  @override
  String get systemTheme => 'सिस्टम';

  @override
  String get lightTheme => 'लाइट';

  @override
  String get darkTheme => 'डार्क';

  @override
  String get colorCustomizationSection => 'रंग अनुकूलन';

  @override
  String get primaryColorLabel => 'प्राथमिक रंग';

  @override
  String get secondaryColorLabel => 'द्वितीयक रंग';

  @override
  String get surfaceColorLabel => 'सतह का रंग';

  @override
  String get windowEffectsSection => 'विंडो प्रभाव (डेस्कटॉप)';

  @override
  String get enableEffectsLabel => 'विंडो प्रभाव सक्षम करें';

  @override
  String get windowEffectLabel => 'विंडो प्रभाव';

  @override
  String get backgroundLabel => 'पृष्ठभूमि';

  @override
  String get removeBackgroundColor => 'पृष्ठभूमि का रंग हटाएं';

  @override
  String get transparentSurfaceLabel => 'पारदर्शी सतह (कार्ड)';

  @override
  String get fullyTransparentLabel => 'पूरी तरह पारदर्शी';

  @override
  String get opaqueLabel => 'अपारदर्शी';

  @override
  String opacityLabel(Object value) {
    return 'अपारदर्शिता: $value%';
  }

  @override
  String get backgroundSettingsSection => 'पृष्ठभूमि सेटिंग्स';

  @override
  String get enableBackgroundImageLabel => 'पृष्ठभूमि छवि सक्षम करें';

  @override
  String get backgroundBlurLabel => 'पृष्ठभूमि धुंधलापन';

  @override
  String get surfaceGlassStyleTitle => 'सतह/ग्लास शैली';

  @override
  String get chooseImageButton => 'छवि चुनें';

  @override
  String get selectImageFileError => 'कृपया एक छवि फ़ाइल चुनें।';

  @override
  String get clearImageButton => 'छवि साफ़ करें';

  @override
  String get saveThemePresetTitle => 'थीम प्रीसेट सहेजें';

  @override
  String get presetNameLabel => 'प्रीसेट का नाम';

  @override
  String get presetNameHint => 'मेरा अद्भुत थीम';

  @override
  String get importDataLabel => 'डेटा आयात करें';

  @override
  String get exportDataLabel => 'डेटा निर्यात करें';

  @override
  String get exportFormatMessage => 'प्रारूप चुनें:\n\nJSON: सभी डेटा का पूरा बैकअप।\nCSV: लेन-देन की पठनीय रिपोर्ट।';

  @override
  String get jsonFormat => 'JSON';

  @override
  String get csvFormat => 'CSV';

  @override
  String get importExchangeRatesLabel => 'विनिमय दरें आयात करें (CSV/JSON)';

  @override
  String get resetDataLabel => 'डेटा को डिफ़ॉल्ट पर रीसेट करें';

  @override
  String get resetDataSubtitle => 'यह सभी डेटा हटा देगा और डिफ़ॉल्ट सेटिंग्स बहाल करेगा।';

  @override
  String get debugMenuLabel => 'डीबग मेनू';

  @override
  String get debugMenuSubtitle => 'आंतरिक डेवलपर उपकरण';

  @override
  String get apiManagementTitle => 'एपीआई प्रबंधन';

  @override
  String get apiCategoriesSection => 'एपीआई श्रेणियां';

  @override
  String get manualUtilitiesSection => 'मैनुअल उपयोगिताएँ';

  @override
  String get startupDataSyncLabel => 'स्टार्टअप डेटा सिंक';

  @override
  String get startupDataSyncDescription => 'एप्लिकेशन लॉन्च के समय बाहरी डेटा लाने और सर्वर सिंक्रनाइज़ेशन दोनों को नियंत्रित करता है।';

  @override
  String get standardApiLabel => 'मानक एपीआई';

  @override
  String get syncOnStartupDescription => 'स्टार्टअप पर सिंक करें';

  @override
  String get customSourcesLabel => 'कस्टम स्रोत';

  @override
  String syncCustomSourcesDescription(Object count) {
    return 'स्टार्टअप पर सभी ($count) सिंक करें';
  }

  @override
  String get individualCustomSourcesTitle => 'व्यक्तिगत कस्टम स्रोत';

  @override
  String get noCustomSourcesAdded => 'कोई कस्टम स्रोत नहीं जोड़ा गया।';

  @override
  String get fetchTodaysRatesButton => 'आज की दरें प्राप्त करें';

  @override
  String get inflationConfigTitle => 'मुद्रास्फीति कॉन्फ़िग';

  @override
  String get countryCodeHint => 'देश कोड (उदा. SRB)';

  @override
  String fetchDataForCountryButton(Object country) {
    return '$country के लिए डेटा प्राप्त करें';
  }

  @override
  String get steamSettingsTitle => 'स्टीम सेटिंग्स';

  @override
  String get steamIdLabel => 'स्टीम आईडी (64-बिट)';

  @override
  String get preferredGameLabel => 'पसंदीदा खेल';

  @override
  String get fetchInventoryNowButton => 'अभी इन्वेंट्री प्राप्त करें';

  @override
  String get manualExchangeRatesTitle => 'मैनुअल विनिमय दरें प्राप्त करना';

  @override
  String get selectStartDate => 'प्रारंभ तिथि चुनें';

  @override
  String startDateFrom(Object date) {
    return 'से: $date';
  }

  @override
  String get selectEndDate => 'समाप्ति तिथि चुनें';

  @override
  String endDateTo(Object date) {
    return 'तक: $date';
  }

  @override
  String get fetchRangeButton => 'रेंज प्राप्त करें';

  @override
  String get manualSteamInventoryTitle => 'मैनुअल स्टीम इन्वेंट्री';

  @override
  String get selectGameHint => 'खेल चुनें';

  @override
  String get fetchValueButton => 'मान प्राप्त करें';

  @override
  String get manualInflationDataTitle => 'मैनुअल मुद्रास्फीति डेटा';

  @override
  String get selectStartYear => 'प्रारंभ वर्ष चुनें';

  @override
  String startYearFrom(Object year) {
    return 'से: $year';
  }

  @override
  String get selectEndYear => 'समाप्ति वर्ष चुनें';

  @override
  String endYearTo(Object year) {
    return 'तक: $year';
  }

  @override
  String get fetchDataButton => 'डेटा प्राप्त करें';

  @override
  String get connectionOk => 'कनेक्शन ठीक है';

  @override
  String get connectionFailed => 'कनेक्शन विफल';

  @override
  String get testConnectionButton => 'कनेक्शन का परीक्षण करें';

  @override
  String get editCustomSourceTitle => 'कस्टम स्रोत संपादित करें';

  @override
  String get addCustomSourceTitle => 'कस्टम स्रोत जोड़ें';

  @override
  String get addressFormatsHelp => 'पता प्रारूप:\n• 192.168.1.10 (आईपी)\n• localhost या api.my.com\n• http://myserver.com';

  @override
  String get urlIpLabel => 'URL / IP';

  @override
  String get urlIpHint => '192.168.1.10:8080';

  @override
  String get dataTypeLabel => 'डेटा प्रकार';

  @override
  String get apiTitleExchangeRates => 'विनिमय दरें';

  @override
  String get apiTitleInflation => 'मुद्रास्फीति';

  @override
  String get apiTitleAssetPrices => 'संपत्ति की कीमतें';

  @override
  String get apiTitleSteamInventory => 'स्टीम इन्वेंट्री';

  @override
  String get transferLabel => 'स्थानांतरण';

  @override
  String get uncategorizedLabel => 'गैर-वर्गीकृत';

  @override
  String get defaultLabel => 'डिफ़ॉल्ट';

  @override
  String receivedTotalLabel(Object total) {
    return 'प्राप्त: $total';
  }

  @override
  String spentTotalLabel(Object total) {
    return 'खर्च किया: $total';
  }

  @override
  String get periodSummaryTitle => 'अवधि सारांश';

  @override
  String get incomeLabel => 'आय';

  @override
  String get expenseLabel => 'व्यय';

  @override
  String get netLabel => 'शुद्ध';

  @override
  String get exportSuccessMessage => 'निर्यात सफलतापूर्वक पूरा हुआ';

  @override
  String exportFailedMessage(Object error) {
    return 'निर्यात विफल: $error';
  }

  @override
  String get importSuccessMessage => 'आयात सफलतापूर्वक पूरा हुआ';

  @override
  String importFailedMessage(Object error) {
    return 'आयात विफल: $error';
  }

  @override
  String get resetDataConfirmationTitle => 'डेटा रीसेट करें?';

  @override
  String get resetDataConfirmationMessage => 'चेतावनी! यह आपके सभी लेन-देन, खाते और सेटिंग्स को हटा देगा।\n\nऐप को डिफ़ॉल्ट डेटा के साथ उसकी प्रारंभिक स्थिति में बहाल कर दिया जाएगा।\nइस कार्रवाई को पूर्ववत नहीं किया जा सकता है।';

  @override
  String get resetEverythingButton => 'सब कुछ रीसेट करें';

  @override
  String get resetSuccessMessage => 'डेटा रीसेट और डिफ़ॉल्ट बहाल।';

  @override
  String resetFailedMessage(Object error) {
    return 'रीसेट विफल: $error';
  }

  @override
  String get importParsingStep => 'CSV फ़ाइलें पार्स की जा रही हैं...';

  @override
  String get importFetchingRatesStep => 'विनिमय दरें प्राप्त की जा रही हैं...';

  @override
  String importErrorLabel(Object error) {
    return 'त्रुटि: $error';
  }

  @override
  String get importOneMoneyLabel => 'OneMoney (CSV) से आयात करें';

  @override
  String get importMyBudgetLabel => 'MyBudget लेन-देन (CSV) आयात करें';

  @override
  String get restoreBackupLabel => 'बैकअप बहाल करें (JSON)';

  @override
  String get importSelectionHelp => 'माइग्रेशन के लिए \'OneMoney\', लेन-देन जोड़ने के लिए \'MyBudget\', या सब कुछ अधिलेखित करने के लिए \'बैकअप बहाल करें\' चुनें।';

  @override
  String get importCreateAllNew => 'सभी नए बनाएं';

  @override
  String importNewAccountFound(Object accountName) {
    return 'नया खाता मिला: \"$accountName\"';
  }

  @override
  String importMapAccountTitle(Object accountName) {
    return '\"$accountName\" को मैप करें...';
  }

  @override
  String get importMapToExisting => 'मौजूदा में मैप करें';

  @override
  String get importCreateNew => 'नया बनाएं';

  @override
  String importNewCategoryFound(Object categoryName) {
    return 'नई श्रेणी मिली: \"$categoryName\"';
  }

  @override
  String importMapCategoryTitle(Object categoryName) {
    return '\"$categoryName\" को मैप करें...';
  }

  @override
  String importNewCurrencyFound(Object currencyName) {
    return 'नई मुद्रा मिली: \"$currencyName\"';
  }

  @override
  String importMapCurrencyTitle(Object currencyName) {
    return '\"$currencyName\" को मैप करें...';
  }

  @override
  String get importSkipAll => 'सभी छोड़ें';

  @override
  String get importImportAll => 'सभी आयात करें';

  @override
  String get importPotentialDuplicate => 'संभावित डुप्लिकेट:';

  @override
  String importDateLabel(Object date) {
    return 'दिनांक: $date';
  }

  @override
  String importFromLabel(Object from) {
    return 'स: $from';
  }

  @override
  String importToLabel(Object to) {
    return 'तक: $to';
  }

  @override
  String importAmountLabel(Object amount, Object currency) {
    return 'राशि: $amount $currency';
  }

  @override
  String get importSkip => 'छोड़ें';

  @override
  String get importImportAnyway => 'वैसे भी आयात करें';

  @override
  String importDecisionLabel(Object decision) {
    return 'निर्णय: $decision';
  }

  @override
  String get importReadyTitle => 'आयात के लिए तैयार';

  @override
  String importReadyMessage(Object count) {
    return '$count लेन-देन आयात के लिए तैयार हैं।';
  }

  @override
  String get importFinalizeButton => 'आयात को अंतिम रूप दें';

  @override
  String get importingTitle => 'आयात हो रहा है...';

  @override
  String get importCompleteTitle => 'आयात पूर्ण';

  @override
  String get importStartOverTooltip => 'फिर से शुरू करें';

  @override
  String get importDataTitle => 'डेटा आयात करें';

  @override
  String importAccountsCreatedLabel(Object count) {
    return 'बनाए गए नए खाते: $count';
  }

  @override
  String importCategoriesCreatedLabel(Object count) {
    return 'बनाई गई नई श्रेणियां: $count';
  }

  @override
  String importTransactionsImportedLabel(Object count) {
    return 'आयात किए गए लेन-देन: $count';
  }

  @override
  String importDuplicatesSkippedLabel(Object count) {
    return 'छोड़े गए डुप्लिकेट: $count';
  }

  @override
  String get searchHint => 'खोजें';

  @override
  String get debugAllDataClearedMessage => 'सभी डेटा साफ़ किया गया और डिफ़ॉल्ट के साथ फिर से सीड किया गया।';

  @override
  String get debugClearAllDataLabel => 'सभी डेटा साफ़ करें (और डिफ़ॉल्ट फिर से सीड करें)';

  @override
  String get debugMinimumDataSeededMessage => 'न्यूनतम डेटा सीड किया गया।';

  @override
  String get debugSeedMinimumDataLabel => 'न्यूनतम डेटा सीड करें';

  @override
  String get debugMediumDataSeededMessage => 'मध्यम डेटा सीड किया गया।';

  @override
  String get debugSeedMediumDataLabel => 'मध्यम डेटा सीड करें';

  @override
  String get debugMaximumDataSeededMessage => 'अधिकतम डेटा सीड किया गया।';

  @override
  String get debugSeedMaximumDataLabel => 'अधिकतम डेटा सीड करें (प्रदर्शन परीक्षण के लिए)';

  @override
  String get debugRunningInDebugModeLabel => 'डीबग मोड में चल रहा है';

  @override
  String get deleteAllButton => 'सभी हटाएं';

  @override
  String get changeButton => 'बदलें';

  @override
  String get undoButton => 'पूर्ववत करें';

  @override
  String itemDeletedMessage(Object name) {
    return '$name हटाया गया';
  }

  @override
  String get totalBalanceLabel => 'कुल शेष राशि';

  @override
  String get noCurrenciesSelected => 'कोई मुद्रा नहीं चुनी गई।';

  @override
  String get failedToLoadDashboard => 'डैशबोर्ड लोड करने में विफल';

  @override
  String get dashboardCalendarTab => 'कैलेंडर';

  @override
  String get dashboardTabCalendar => 'कैलेंडर';

  @override
  String get dashboardCalendarTooltip => 'कैलेंडर दृश्य';

  @override
  String get dashboardCalendarDescription => 'कैलेंडर प्रारूप में लेन-देन देखें';

  @override
  String get dashboardCategoriesTab => 'श्रेणियां';

  @override
  String get dashboardTabCategories => 'श्रेणियां';

  @override
  String get dashboardCategoriesTooltip => 'श्रेणी विश्लेषण';

  @override
  String get dashboardCategoriesDescription => 'श्रेणी के आधार पर व्यय का विवरण';

  @override
  String get dashboardBalanceTab => 'शेष राशि';

  @override
  String get dashboardTabBalance => 'शेष राशि';

  @override
  String get dashboardBalanceTooltip => 'शेष राशि का इतिहास';

  @override
  String get dashboardBalanceDescription => 'समय के साथ निवल मूल्य को ट्रैक करें';

  @override
  String get dashboardExpensesLabel => 'व्यय';

  @override
  String get dashboardIncomeLabel => 'आय';

  @override
  String get manageIconsTitle => 'आइकन प्रबंधित करें';

  @override
  String get manageStylesDeleteTitle => 'आइकन हटाएं';

  @override
  String manageStylesDeleteConfirm(Object count) {
    return 'क्या आप वाकई $count चयनित आइकन हटाना चाहते हैं?';
  }

  @override
  String manageStylesDeleteConfirmWithTransfer(Object count) {
    return 'क्या आप वाकई $count चयनित आइकन हटाना चाहते हैं? (हस्तांतरण आइकन को छोड़ दिया जाएगा)';
  }

  @override
  String get noIconsCreated => 'अभी तक कोई आइकन नहीं बनाया गया है।';

  @override
  String get failedToLoadIcons => 'आइकन लोड करने में विफल।';

  @override
  String get cannotDeleteTransferIcon => 'स्थानांतरण (Transfer) आइकन को हटाया नहीं जा सकता।';

  @override
  String get deleteIconsDialogTitle => 'आइकन हटाएं';

  @override
  String deleteIconsConfirmationMessage(Object count) {
    return 'क्या आप वाकई $count चयनित आइकन हटाना चाहते हैं?';
  }

  @override
  String deleteIconsWithSkipTransferMessage(Object count) {
    return 'क्या आप वाकई $count चयनित आइकन हटाना चाहते हैं? (स्थानांतरण आइकन को छोड़ दिया जाएगा)';
  }

  @override
  String get deleteIconDialogTitle => 'आइकन हटाएं';

  @override
  String deleteIconConfirmationMessage(Object name) {
    return 'क्या आप वाकई \"$name\" को हटाना चाहते हैं?';
  }

  @override
  String deleteMultipleAccountsTitle(Object count) {
    return '$count खाते हटाएं?';
  }

  @override
  String get deleteMultipleAccountsMessage => 'क्या आप वाकई चयनित खातों को हटाना चाहते हैं? इससे संबंधित सभी लेन-देन हटा दिए जाएंगे।';

  @override
  String get changeAccountTypeDialogTitle => 'खाता प्रकार बदलें';

  @override
  String editAccountTitle(Object name) {
    return 'संपादित करें: $name';
  }

  @override
  String get balanceCalculatedFromAsset => 'शेष राशि की गणना संपत्ति की मात्रा * मूल्य से की जाती है';

  @override
  String get selectAccountTypeTitle => 'खाता प्रकार चुनें';

  @override
  String get selectCountryTitle => 'देश चुनें';

  @override
  String get selectIconSubtitle => 'एक आइकन चुनें';

  @override
  String get bindToAssetLabel => 'संपत्ति से बांधें (वैकल्पिक)';

  @override
  String get selectAssetTitle => 'संपत्ति चुनें';

  @override
  String get selectedAssetLabel => 'चयनित संपत्ति';

  @override
  String get balanceAutoCalculatedLabel => 'शेष राशि की गणना स्वचालित रूप से की जाती है';

  @override
  String get tapToBindAssetLabel => 'संपत्ति बांधने के लिए टैप करें';

  @override
  String get assetQuantityLabel => 'संपत्ति की मात्रा';

  @override
  String get linkedAssetsTitle => 'लिंक की गई संपत्तियां';

  @override
  String get noneLabel => 'कोई नहीं';

  @override
  String get accountTypeLabel => 'खाता प्रकार';

  @override
  String get formValidationPleaseSelectAccountType => 'कृपया खाता प्रकार चुनें';

  @override
  String get iconLabel => 'आइकन';

  @override
  String get languageLabel => 'भाषा';

  @override
  String get systemDefaultLabel => 'सिस्टम डिफ़ॉल्ट';

  @override
  String get selectLanguageTitle => 'भाषा चुनें';

  @override
  String get dashboardLabel => 'डैशबोर्ड';

  @override
  String get homeLabel => 'होम';

  @override
  String get historyLabel => 'इतिहास';

  @override
  String get syncScreenTitle => 'सिंक सेटिंग्स';

  @override
  String get syncP2PSection => 'P2P सिंक्रनाइज़ेशन (Syncthing)';

  @override
  String get syncEnableP2P => 'P2P सिंक सक्षम करें';

  @override
  String get syncP2PSubtitle => 'साझा फ़ोल्डर में .sync फ़ाइलों के माध्यम से सिंक करें';

  @override
  String get syncFolderLabel => 'सिंक फ़ोल्डर';

  @override
  String get syncFolderNotSelected => 'चयनित नहीं';

  @override
  String get syncBrowseButton => 'ब्राउज़ करें';

  @override
  String get syncClearFilesButton => 'सिंक फ़ाइलें साफ़ करें';

  @override
  String get syncServerSection => 'क्लाउड सिंक्रनाइज़ेशन (सर्वर)';

  @override
  String get syncServerUrlLabel => 'सर्वर URL';

  @override
  String get syncApiTokenLabel => 'एपीआई टोकन';

  @override
  String get syncApiTokenHint => 'अपना सुरक्षा टोकन दर्ज करें';

  @override
  String get syncApiTokenHelp => 'यह टोकन आपका साझा रहस्य है। सिंक्रनाइज़ेशन को अधिकृत करने के लिए अपने सभी उपकरणों पर वही मान दर्ज करें।';

  @override
  String get syncTestConnectionButton => 'कनेक्शन का परीक्षण करें';

  @override
  String get syncTestingLabel => 'परीक्षण हो रहा है...';

  @override
  String get syncSaveServerSettingsButton => 'सर्वर सेटिंग्स सहेजें';

  @override
  String get syncEnableServer => 'सर्वर सिंक सक्षम करें';

  @override
  String get syncServerSubtitle => 'MyBudget सर्वर इंस्टेंस के साथ सिंक करें';

  @override
  String get syncPendingLocalChanges => 'लंबित स्थानीय परिवर्तन:';

  @override
  String get syncSyncNowButton => 'अभी सिंक करें';

  @override
  String get syncSyncingLabel => 'सिंक हो रहा है...';

  @override
  String get syncWebNotAvailable => 'वेब पर सिंक्रनाइज़ेशन उपलब्ध नहीं है';

  @override
  String get syncPermissionRequired => 'सिंक के लिए स्टोरेज अनुमति आवश्यक है। कृपया सेटिंग्स में \"सभी फ़ाइलों तक पहुँच\" सक्षम करें।';

  @override
  String get syncSelectFolderTitle => 'Syncthing फ़ोल्डर चुनें';

  @override
  String get syncClearFilesTitle => 'सिंक फ़ाइलें साफ़ करें';

  @override
  String get syncClearFilesConfirm => 'यह चयनित फ़ोल्डर से सभी .sync फ़ाइलों को हटा देगा। इस कार्रवाई को पूर्ववत नहीं किया जा सकता है।';

  @override
  String syncDeletedFilesCount(Object count) {
    return '$count सिंक फ़ाइलें हटाई गईं';
  }

  @override
  String syncClearFilesError(Object error) {
    return 'फ़ाइलें साफ़ करने में त्रुटि: $error';
  }

  @override
  String get syncSettingsSaved => 'सर्वर सेटिंग्स सहेजी गईं';

  @override
  String get syncConnectionSuccessful => 'कनेक्शन सफल!';

  @override
  String get syncConnectionFailed => 'कनेक्शन विफल। URL और टोकन की जाँच करें।';

  @override
  String get syncCompleted => 'सिंक सफलतापूर्वक पूरा हुआ';

  @override
  String syncFailed(Object error) {
    return 'सिंक विफल: $error';
  }

  @override
  String get smsRuleAddTitle => 'नियम जोड़ें';

  @override
  String get smsRuleEditTitle => 'नियम संपादित करें';

  @override
  String get smsRuleTransactionType => 'लेन-देन का प्रकार';

  @override
  String get smsRuleMatchPattern => 'मैच पैटर्न (Regex)';

  @override
  String get smsRuleMatchPatternHint => 'उदा., कार्ड से भुगतान';

  @override
  String get smsRuleMatchPatternHelp => 'इस एसएमएस प्रकार की पहचान करने के लिए पैटर्न';

  @override
  String get smsRuleAmountPattern => 'राशि पैटर्न (Regex)';

  @override
  String get smsRuleAmountPatternHint => 'उदा., राशि\\s+([\\d,.]+)';

  @override
  String get smsRuleAmountPatternHelp => 'समूह 1 को राशि कैप्चर करनी चाहिए';

  @override
  String get smsRuleCurrencyPattern => 'मुद्रा पैटर्न (Regex, वैकल्पि)';

  @override
  String get smsRuleCurrencyPatternHint => 'उदा., [\\d,.]+\\s*(\\w\\w\\w)';

  @override
  String get smsRuleCurrencyPatternHelp => 'समूह 1 को मुद्रा कोड कैप्चर करना चाहिए';

  @override
  String get smsRuleTestTitle => 'अपने नियम का परीक्षण करें';

  @override
  String get smsRuleTestSmsHint => 'यहां एसएमएस टेक्स्ट पेस्ट करें';

  @override
  String get smsRuleTestButton => 'पैटर्न का परीक्षण करें';

  @override
  String get smsRuleTestEnterSmsError => 'परीक्षण के लिए एसएमएस टेक्स्ट दर्ज करें';

  @override
  String get smsRuleTestMatchError => '✗ मैच पैटर्न को कोई मिलान नहीं मिला';

  @override
  String get smsRuleTestAmountError => '✗ राशि पैटर्न को कोई मिलान नहीं मिला';

  @override
  String smsRuleTestSuccess(Object amount, Object currency, Object type) {
    return '✓ मिलान मिल गया!\nप्रकार: $type\nराशि: $amount\nमुद्रा: $currency';
  }

  @override
  String smsRuleTestRegexError(Object error) {
    return '✗ अमान्य रेगएक्स: $error';
  }

  @override
  String get smsRuleRequiredError => 'मैच और राशि पैटर्न आवश्यक हैं';

  @override
  String inflationError(Object error) {
    return 'त्रुटि: $error';
  }

  @override
  String get inflationNoRatesFound => 'कोई मुद्रास्फीति दर नहीं मिली।';

  @override
  String get inflationAddRate => 'मुद्रास्फीति दर जोड़ें';

  @override
  String get inflationDeleteConfirmTitle => 'दरें हटाएं?';

  @override
  String inflationDeleteConfirmMessage(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count दरों',
      one: 'इस दर',
    );
    return 'क्या आप वाकई $_temp0 को हटाना चाहते हैं?';
  }

  @override
  String inflationSelectedCount(Object count) {
    return '$count चयनित';
  }

  @override
  String get inflationFiltersTitle => 'मुद्रास्फीति फ़िल्टर';

  @override
  String get inflationCountries => 'देश';

  @override
  String get inflationPresets => 'प्रीसेट';

  @override
  String deleteCategoryConfirmTitle(Object name) {
    return '$name हटाएं?';
  }

  @override
  String get deleteCategoryMessage => 'इस श्रेणी में संबंधित लेन-देन हैं। आप क्या करना चाहेंगे?';

  @override
  String get deleteCategoryReassign => 'लेन-देन को दूसरी श्रेणी में पुन: असाइन करें';

  @override
  String get deleteCategoryNewCategory => 'नई श्रेणी';

  @override
  String get deleteCategoryDeleteAll => 'सभी संबंधित लेन-देन हटाएं';

  @override
  String deleteAccountConfirmTitle(Object name) {
    return '$name हटाएं?';
  }

  @override
  String get deleteAccountMessage => 'इस खाते में संबंधित लेन-देन हो सकते हैं। आप क्या करना चाहेंगे?';

  @override
  String get deleteAccountReassign => 'लेन-देन को दूसरे खाते में पुन: असाइन करें';

  @override
  String get deleteAccountNewAccount => 'नया खाता';

  @override
  String get deleteAccountDeleteAll => 'सभी संबंधित लेन-देन हटाएं';

  @override
  String get confirmButton => 'पुष्टि करें';

  @override
  String get okButton => 'ठीक है';

  @override
  String get noItemsFound => 'कोई आइटम नहीं मिला।';

  @override
  String get noDataForPeriod => 'इस अवधि के लिए कोई डेटा नहीं है';

  @override
  String get noDataForRange => 'इस रेंज के लिए कोई डेटा नहीं है';

  @override
  String get noHistoryData => 'कोई इतिहास डेटा उपलब्ध नहीं है';

  @override
  String get disabledByGlobalSync => 'वैश्विक सिंक द्वारा अक्षम';

  @override
  String dateCreatedLabel(Object date) {
    return 'निर्माण की तिथि: $date';
  }

  @override
  String get anyLabel => 'कोई भी';

  @override
  String get balanceDisplayLabel => 'शेष राशि का प्रदर्शन';

  @override
  String currenciesActiveLabel(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count मुद्राएं सक्रिय',
      one: '1 मुद्रा सक्रिय',
    );
    return '$_temp0';
  }

  @override
  String get searchCountryLabel => 'देश खोजें';

  @override
  String get addNewIconLabel => 'नया आइकन जोड़ें';

  @override
  String get noIconsFoundLabel => 'कोई आइकन नहीं मिला';

  @override
  String get addNewStyleLabel => 'नई शैली जोड़ें';

  @override
  String get styleNameLabel => 'शैली का नाम';

  @override
  String get pleaseEnterStyleName => 'कृपया शैली का नाम दर्ज करें';

  @override
  String get colorLabel => 'रंग';

  @override
  String get netBalanceMetric => 'शुद्ध शेष';

  @override
  String get investedMetric => 'निवेश किया';

  @override
  String get realizedMetric => 'प्राप्त किया';

  @override
  String get feesMetric => 'शुल्क';

  @override
  String get persistFiltersLabel => 'फ़िल्टर बनाए रखें';

  @override
  String get searchByNameHint => 'नाम से खोजें...';

  @override
  String get searchDescriptionHint => 'विवरण खोजें...';

  @override
  String get advancedFiltersTitle => 'उन्नत फ़िल्टर';

  @override
  String get transactionTypeLabel => 'लेन-देन का प्रकार';

  @override
  String get assetFiltersTitle => 'संपत्ति फ़िल्टर';

  @override
  String get minValueLabel => 'न्यूनतम मान';

  @override
  String get maxValueLabel => 'अधिकतम मान';

  @override
  String get assetTypesLabel => 'संपत्ति के प्रकार';

  @override
  String get allLabel => 'सभी';

  @override
  String get currenciesLabel => 'मुद्राएं';

  @override
  String get sourcesLabel => 'स्रोत';

  @override
  String get presetsLabel => 'प्रीसेट';

  @override
  String get enterCategoryNameHint => 'श्रेणी का नाम दर्ज करें';

  @override
  String get selectTypeHint => 'प्रकार चुनें';

  @override
  String get hotKeysTitle => 'हॉट कुंजियाँ';

  @override
  String get searchHotkeysHint => 'हॉट कुंजियाँ खोजें...';

  @override
  String get noMatchingHotkeys => 'कोई मेल खाती हॉट कुंजी नहीं मिली।';

  @override
  String recordingHotkeyTitle(Object label) {
    return '\"$label\" के लिए हॉट कुंजी रिकॉर्ड की जा रही है';
  }

  @override
  String get pressKeysHint => 'कुंजियाँ दबाएं...';

  @override
  String get pressAnyCombinationHint => 'कोई भी कुंजी संयोजन दबाएं।';

  @override
  String get clearSaveButton => 'साफ़ करें / सहेजें';

  @override
  String get duplicateHotkeyTooltip => 'डुप्लिकेट हॉट कुंजी';

  @override
  String usedByLabel(Object action) {
    return '$action द्वारा उपयोग किया गया';
  }

  @override
  String get hkCategoryNavigation => 'नेविगेशन';

  @override
  String get hkCategoryDashboardTabs => 'डैशबोर्ड टैब (Ctrl + 1/2/3)';

  @override
  String get hkCategoryDataTabs => 'डेटा टैब (Ctrl + 1/2/3)';

  @override
  String get hkCategoryPeriodControl => 'अवधि नियंत्रण';

  @override
  String get hkCategoryActions => 'कार्रवाई';

  @override
  String get hkCategorySelectionMode => 'चयन मोड';

  @override
  String get hkActionBack => 'वैश्विक: वापस जाएं / बाहर निकलें';

  @override
  String get hkActionDashboard => 'डैशबोर्ड पर जाएं';

  @override
  String get hkActionAccounts => 'खातों पर जाएं';

  @override
  String get hkActionTransactions => 'लेन-देन पर जाएं';

  @override
  String get hkActionCategories => 'श्रेणियों पर जाएं';

  @override
  String get hkActionData => 'डेटा / विनिमय दरों पर जाएं';

  @override
  String get hkActionSettings => 'सेटिंग्स पर जाएं';

  @override
  String get hkActionDashboardTab1 => 'कैलेंडर टैब';

  @override
  String get hkActionDashboardTab2 => 'श्रेणियां टैब';

  @override
  String get hkActionDashboardTab3 => 'शेष राशि टैब';

  @override
  String get hkActionDataTab1 => 'विनिमय दरें';

  @override
  String get hkActionDataTab2 => 'मुद्रास्फीति';

  @override
  String get hkActionDataTab3 => 'संपत्तियां';

  @override
  String get hkActionPrevPeriod => 'पिछली अवधि';

  @override
  String get hkActionNextPeriod => 'अगली अवधि';

  @override
  String get hkActionAddAction => 'सामान्य जोड़ने की कार्रवाई';

  @override
  String get hkActionAccountsSelectionClose => 'खाते: बंद करें';

  @override
  String get hkActionAccountsSelectionAll => 'खाते: सभी चुनें';

  @override
  String get hkActionAccountsSelectionDelete => 'खाते: हटाएं';

  @override
  String get hkActionAccountsSelectionChangeType => 'खाते: प्रकार बदलें';

  @override
  String get hkActionCategoriesSelectionClose => 'श्रेणियां: बंद करें';

  @override
  String get hkActionCategoriesSelectionAll => 'श्रेणियां: सभी चुनें';

  @override
  String get hkActionCategoriesSelectionDelete => 'श्रेणियां: हटाएं';

  @override
  String get hkActionCategoriesSelectionChangeType => 'श्रेणियां: प्रकार बदलें';

  @override
  String get hkActionDataSelectionClose => 'डेटा: बंद करें';

  @override
  String get hkActionDataSelectionAll => 'डेटा: सभी चुनें';

  @override
  String get hkActionDataSelectionDelete => 'डेटा: हटाएं';

  @override
  String get hkActionDataSelectionChangePreset => 'डेटा: प्रीसेट बदलें';

  @override
  String get styNotFound => 'शैली नहीं मिली।';

  @override
  String get stySaveChanges => 'परिवर्तन सहेजें';

  @override
  String get styAddIcon => 'आइकन जोड़ें';

  @override
  String get smsOnlyAndroid => 'एसएमएस आयात केवल Android पर उपलब्ध है';

  @override
  String get smsImportSms => 'एसएमएस आयात करें';

  @override
  String get smsPermissionRequired => 'एसएमएस अनुमति आवश्यक';

  @override
  String get smsPermissionRationale => 'एसएमएस से लेन-देन आयात करने के लिए, हमें आपके संदेश पढ़ने की अनुमति चाहिए।';

  @override
  String get smsGrantPermission => 'अनुमति दें';

  @override
  String get smsNoPresets => 'कोई प्रीसेट कॉन्फ़िगर नहीं किया गया। जोड़ने के लिए + पर टैप करें।';

  @override
  String get smsImportDescription => 'एसएमएस संदेशों से लेन-देन आयात करें। एक समय सीमा चुनें:';

  @override
  String get smsLast7Days => 'पिछले 7 दिन';

  @override
  String get smsAllTime => 'सभी समय';

  @override
  String smsFilterLabel(Object filter) {
    return 'फ़िल्टर: $filter';
  }

  @override
  String get smsEditPreset => 'प्रीसेट संपादित करें';

  @override
  String get smsNewPreset => 'नया प्रीसेट';

  @override
  String get smsPresetNameHint => 'उदा., मेरा बैंक';

  @override
  String get smsSenderFilter => 'प्रेषक फ़िल्टर';

  @override
  String get smsSenderFilterHint => 'उदा., ALTA या +381...';

  @override
  String get smsSenderFilterHelper => 'प्रेषक नाम या फ़ोन नंबर द्वारा एसएमएस फ़िल्टर करें';

  @override
  String get smsDefaults => 'डिफ़ॉल्ट';

  @override
  String get smsDefaultAccount => 'डिफ़ॉल्ट खाता';

  @override
  String get smsDefaultCategory => 'डिफ़ॉल्ट श्रेणी';

  @override
  String get smsImportMessages => 'संदेश आयात करें';

  @override
  String get smsSelectDefaultsFirst => 'पहले डिफ़ॉल्ट चुनें';

  @override
  String get smsCustomRange => 'कस्टम रेंज';

  @override
  String smsImportSuccessCount(Object count) {
    return 'सफल: $count लेन-देन आयात किए गए';
  }

  @override
  String get smsParsingRules => 'पार्सिंग नियम';

  @override
  String get smsNoRules => 'कोई नियम परिभाषित नहीं। जोड़ने के लिए + पर टैप करें।';

  @override
  String smsMatchLabel(Object pattern) {
    return 'मैच: $pattern';
  }

  @override
  String get smsNameSenderRequired => 'नाम और प्रेषक फ़िल्टर आवश्यक हैं';

  @override
  String get smsCategoryKeywords => 'श्रेणी कीवर्ड';

  @override
  String get smsCategoryKeywordsSubtitle => 'एसएमएस के मुख्य भाग के कीवर्ड को श्रेणियों से मैप करें';

  @override
  String get smsNoKeywordRules => 'कोई कीवर्ड नियम नहीं। जोड़ने के लिए + पर टैप करें।';

  @override
  String get smsAddKeywordRule => 'कीवर्ड नियम जोड़ें';

  @override
  String get smsKeyword => 'कीवर्ड';

  @override
  String get smsKeywordHint => 'उदा., किराना, Netflix';

  @override
  String get smsKeywordHelper => 'एसएमएस के मुख्य भाग में मिलान के लिए सबस्ट्रिंग (केस-असंवेदनशील)';

  @override
  String get smsSelectCategoryHint => 'श्रेणी चुनें';

  @override
  String get dshSelectDateDescription => 'विशिष्ट दिनांक या सीमा चुनने के लिए कैलेंडर खोलें';

  @override
  String get dshCurrencyDescription => 'प्रदर्शन के लिए मुख्य मुद्रा चुनें';

  @override
  String get dshChangeViewTooltip => 'दृश्य बदलें';

  @override
  String get dshChangeViewDescription => 'मासिक और वार्षिक दृश्य के बीच स्विच करें';

  @override
  String get dshMonthlyAbbreviation => 'मा';

  @override
  String get dshYearlyAbbreviation => 'व';

  @override
  String dshBalancesOnDate(Object date) {
    return '$date को शेष राशि';
  }

  @override
  String get dshSearchCurrency => 'मुद्रा खोजें';

  @override
  String get dshUnknownCategory => 'अज्ञात';

  @override
  String get pckSelectItem => 'एक आइटम चुनें';

  @override
  String get pckSelectItems => 'आइटम चुनें';

  @override
  String get pckClearAll => 'सभी साफ़ करें';

  @override
  String get pckSelectIcon => 'आइकन चुनें';

  @override
  String get pckMaterialIcons => 'Material आइकन';

  @override
  String get pckCustomIcons => 'कस्टम आइकन';

  @override
  String get fltAmountFrom => 'राशि से';

  @override
  String get fltAmountTo => 'राशि तक';

  @override
  String get fltSelectRange => 'रेंज चुनें';

  @override
  String get fltAdvancedFilterTooltip => 'उन्नत फ़िल्टर';

  @override
  String get fltAdvancedFilterDescription => 'खाता, श्रेणी या राशि द्वारा लेन-देन फ़िल्टर करें';

  @override
  String get fltSortOrderDescription => 'आरोही और अवरोही क्रम के बीच स्विच करें';

  @override
  String get fltAccountFiltersTitle => 'खाता फ़िल्टर';

  @override
  String get fltNameLabel => 'नाम';

  @override
  String get fltAccountTypesLabel => 'खाता प्रकार';

  @override
  String get fltFilterCurrenciesLabel => 'मुद्राएं फ़िल्टर करें';

  @override
  String get fltSelectCurrenciesLabel => 'मुद्राएं चुनें';

  @override
  String get fltFilterCategoriesTitle => 'श्रेणियां फ़िल्टर करें';

  @override
  String get exchAddExchangeRate => 'विनिमय दर जोड़ें';

  @override
  String get exchEditExchangeRate => 'विनिमय दर संपादित करें';

  @override
  String get exchAddRateDescription => 'दो मुद्राओं के बीच रूपांतरण दर मैन्युअल रूप से दर्ज करें';

  @override
  String get exchNoRatesFound => 'कोई विनिमय दर नहीं मिली।';

  @override
  String get exchChangePreset => 'प्रीसेट बदलें';

  @override
  String get exchFromCurrency => 'स्रोत मुद्रा';

  @override
  String get exchToCurrency => 'लक्ष्य मुद्रा';

  @override
  String get exchRate => 'दर';

  @override
  String get exchPresetIdLabel => 'प्रीसेट आईडी';

  @override
  String exchPresetValue(Object preset) {
    return 'प्रीसेट: $preset';
  }

  @override
  String get exchSelectRange => 'रेंज चुनें';

  @override
  String get exchPreviousPeriodDescription => 'पिछले दिन, महीने या साल पर जाएं';

  @override
  String get exchNextPeriodDescription => 'अगले दिन, महीने या साल पर जाएं';

  @override
  String get exchFilterDescription => 'स्रोत/लक्ष्य मुद्रा और प्रीसेट आईडी द्वारा दरें फ़िल्टर करें';

  @override
  String get exchSelectDateDescription => 'ऐतिहासिक दरें देखने के लिए विशिष्ट दिनांक या सीमा चुनें';

  @override
  String get exchSortOrderDescription => 'दिनांक/दर के अनुसार आरोही और अवरोही क्रम के बीच स्विच करें';

  @override
  String get exchFilterExchangeRates => 'विनिमय दरें फ़िल्टर करें';

  @override
  String get exchExitSelectionDescription => 'विनिमय दर चयन मोड से बाहर निकलें';

  @override
  String get exchSelectAllDescription => 'सूचीबद्ध सभी विनिमय दरें चुनें';

  @override
  String get exchDeselectAllDescription => 'सभी दरें अचयनित करें';

  @override
  String get exchChangePresetDescription => 'सभी चयनित विनिमय दरों के लिए प्रीसेट आईडी अपडेट करें';

  @override
  String get exchDeleteSelectedDescription => 'सभी चयनित विनिमय दरें स्थायी रूप से हटाएं';

  @override
  String get exchDeleteExchangeRatesTitle => 'विनिमय दरें हटाएं';

  @override
  String exchDeleteConfirmMessage(Object count) {
    return 'क्या आप वाकई $count विनिमय दरें हटाना चाहते हैं?';
  }

  @override
  String get exchUpdatePresetTitle => 'प्रीसेट अपडेट करें';

  @override
  String get exchUpdatePresetMessage => 'चयनित आइटम के लिए नया प्रीसेट आईडी दर्ज करें:';
}
