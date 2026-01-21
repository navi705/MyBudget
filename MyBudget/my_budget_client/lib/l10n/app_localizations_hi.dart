// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

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
  String get contextMenuDeselect => 'चुनना रद्द करें';

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
  String get warningOverwriteTitle => 'चेतावनी: डेटा अधिलेखित करें?';

  @override
  String get warningOverwriteMessage => 'बैकअप बहाल करने से सभी मौजूदा डेटा हट जाएगा और बैकअप से बदल जाएगा। इसे पूर्ववत नहीं किया जा सकता है।';

  @override
  String get restoreOverwriteButton => 'बहाल और अधिलेखित करें';

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
  String totalCountLabel(Object count) {
    return 'कुल: $count';
  }

  @override
  String get closeSelectionTooltip => 'चयन बंद करें';

  @override
  String get exitSelectionDescription => 'चयन मोड से बाहर निकलें';

  @override
  String selectedCountLabel(Object count) {
    return '$count चयनित';
  }

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
  String get exitTransactionsSelectionDescription => 'लेन-देन चयन मोड से बाहर निकलें';

  @override
  String quantityLabel(Object quantity) {
    return 'मात्रा: $quantity';
  }

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
  String get amountLabel => 'राशि';

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
  String get currencyLockedMessage => 'स्रोत खाता मुद्रा के लिए लॉक किया गया';

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
    return '$action $assetName के लिए हस्तांतरण';
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
  String get feeCommissionLabel => 'शुल्क (कमीशन)';

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
  String get resetDataConfirmationMessage => 'चेतावनी! यह आपके सभी लेन-देन, खाते और सेटिंग्स को हटा देगा।\n\nऐप डिफ़ॉल्ट डेटा के साथ अपनी प्रारंभिक स्थिति में बहाल हो जाएगा।\nयह कार्रवाई पूर्ववत नहीं की जा सकती है।';

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
  String get importMyBudgetLabel => 'MyBudget लेनदेन (CSV) आयात करें';

  @override
  String get restoreBackupLabel => 'बैकअप बहाल करें (JSON)';

  @override
  String get importSelectionHelp => 'माइग्रेशन के लिए \'OneMoney\', लेनदेन जोड़ने के लिए \'MyBudget\', या सभी डेटा अधिलेखित करने के लिए \'बैकअप बहाल करें\' चुनें।';

  @override
  String get importCreateAllNew => 'सभी नए बनाएं';

  @override
  String importNewAccountFound(Object accountName) {
    return 'नया खाता मिला: \"$accountName\"';
  }

  @override
  String importMapAccountTitle(Object accountName) {
    return '\"$accountName\" को इसके साथ मैप करें...';
  }

  @override
  String get importMapToExisting => 'मौजूदा के साथ मैप करें';

  @override
  String get importCreateNew => 'नया बनाएं';

  @override
  String importNewCategoryFound(Object categoryName) {
    return 'नई श्रेणी मिली: \"$categoryName\"';
  }

  @override
  String importMapCategoryTitle(Object categoryName) {
    return '\"$categoryName\" को इसके साथ मैप करें...';
  }

  @override
  String importNewCurrencyFound(Object currencyName) {
    return 'नई मुद्रा मिली: \"$currencyName\"';
  }

  @override
  String importMapCurrencyTitle(Object currencyName) {
    return '\"$currencyName\" को इसके साथ मैप करें...';
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
    return 'से: $from';
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
    return '$count लेनदेन आयात के लिए तैयार हैं।';
  }

  @override
  String get importFinalizeButton => 'आयात पूरा करें';

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
    return 'बनाई गई नई श्रेणियाँ: $count';
  }

  @override
  String importTransactionsImportedLabel(Object count) {
    return 'लेनदेन आयात किए गए: $count';
  }

  @override
  String importDuplicatesSkippedLabel(Object count) {
    return 'डुप्लिकेट छोड़े गए: $count';
  }

  @override
  String get searchHint => 'खोजें';

  @override
  String get debugAllDataClearedMessage => 'सभी डेटा हटा दिया गया और डिफ़ॉल्ट के साथ फिर से भर दिया गया।';

  @override
  String get debugClearAllDataLabel => 'सभी डेटा हटाएं (और डिफ़ॉल्ट भरें)';

  @override
  String get debugMinimumDataSeededMessage => 'न्यूनतम डेटा भर दिया गया।';

  @override
  String get debugSeedMinimumDataLabel => 'न्यूनतम डेटा भरें';

  @override
  String get debugMediumDataSeededMessage => 'मध्यम डेटा भर दिया गया।';

  @override
  String get debugSeedMediumDataLabel => 'मध्यम डेटा भरें';

  @override
  String get debugMaximumDataSeededMessage => 'अधिकतम डेटा भर दिया गया।';

  @override
  String get debugSeedMaximumDataLabel => 'अधिकतम डेटा भरें (प्रदर्शन परीक्षण के लिए)';

  @override
  String get debugRunningInDebugModeLabel => 'डीबग मोड में चल रहा है';

  @override
  String get deleteAllButton => 'सभी हटाएँ';

  @override
  String get changeButton => 'बदलें';

  @override
  String get undoButton => 'पूर्ववत करें';

  @override
  String itemDeletedMessage(Object name) {
    return '$name हटा दिया गया';
  }

  @override
  String get totalBalanceLabel => 'कुल शेष';

  @override
  String get noCurrenciesSelected => 'कोई मुद्रा नहीं चुनी गई।';

  @override
  String get incomeLabel => 'आय';

  @override
  String get expenseLabel => 'व्यय';

  @override
  String get failedToLoadDashboard => 'डैशबोर्ड लोड करने में विफल';

  @override
  String get dashboardCalendarTab => 'कैलेंडर';

  @override
  String get dashboardCalendarTooltip => 'कैलेंडर देखें';

  @override
  String get dashboardCalendarDescription => 'एक कैलेंडर प्रारूप में लेनदेन देखें';

  @override
  String get dashboardCategoriesTab => 'श्रेणियां';

  @override
  String get dashboardCategoriesTooltip => 'श्रेणी विश्लेषण';

  @override
  String get dashboardCategoriesDescription => 'अपनी धन श्रेणियों का प्रबंधन करें';

  @override
  String get dashboardBalanceTab => 'शेष राशि';

  @override
  String get dashboardBalanceTooltip => 'शेष राशि का इतिहास';

  @override
  String get dashboardBalanceDescription => 'आपके शेष राशि का त्वरित अवलोकन';

  @override
  String get dashboardExpensesLabel => 'खर्चे';

  @override
  String get dashboardIncomeLabel => 'आय';

  @override
  String get manageIconsTitle => 'आइकन प्रबंधित करें';

  @override
  String get noIconsCreated => 'अभी तक कोई आइकन नहीं बनाया गया है।';

  @override
  String get failedToLoadIcons => 'आइकन लोड करने में विफल।';

  @override
  String get cannotDeleteTransferIcon => 'ट्रांसफर आइकन को हटाया नहीं जा सकता।';

  @override
  String get deleteIconsDialogTitle => 'आइकन हटाएं';

  @override
  String deleteIconsConfirmationMessage(Object count) {
    return 'क्या आप वाकई $count चयनित आइकन हटाना चाहते हैं?';
  }

  @override
  String deleteIconsWithSkipTransferMessage(Object count) {
    return 'क्या आप वाकई $count चयनित आइकन हटाना चाहते हैं? (ट्रांसफर आइकन को छोड़ दिया जाएगा)';
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
  String get deleteMultipleAccountsMessage => 'क्या आप वाकई चयनित खाते हटाना चाहते हैं? सभी संबंधित लेनदेन हटा दिए जाएंगे।';

  @override
  String get changeAccountTypeDialogTitle => 'खाता प्रकार बदलें';

  @override
  String editAccountTitle(Object name) {
    return 'संपादित करें: $name';
  }

  @override
  String get balanceCalculatedFromAsset => 'शेष राशि की गणना एसेट मात्रा * मूल्य से की जाती है';

  @override
  String get selectAccountTypeTitle => 'खाता प्रकार चुनें';

  @override
  String get selectCountryTitle => 'देश चुनें';

  @override
  String get selectIconSubtitle => 'एक आइकन चुनें';

  @override
  String get bindToAssetLabel => 'एसेट से बांधें (वैकल्पिक)';

  @override
  String get selectAssetTitle => 'एसेट चुनें';

  @override
  String get selectedAssetLabel => 'चयनित एसेट';

  @override
  String get balanceAutoCalculatedLabel => 'शेष राशि की गणना स्वचालित रूप से की जाती है';

  @override
  String get tapToBindAssetLabel => 'एसेट बांधने के लिए टैप करें';

  @override
  String get assetQuantityLabel => 'एसेट मात्रा';

  @override
  String get linkedAssetsTitle => 'जुड़े हुए एसेट';

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
  String get systemDefaultLabel => 'सिस्टम डिफॉल्ट';

  @override
  String get selectLanguageTitle => 'भाषा चुनें';
}
