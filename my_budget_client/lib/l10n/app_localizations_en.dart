// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get collapseMenuTooltip => 'Collapse Menu';

  @override
  String get expandMenuTooltip => 'Expand Menu';

  @override
  String get helloWorld => 'Hello World!';

  @override
  String get accountsAppBarTitle => 'Accounts';

  @override
  String accountsBalanceLabel(Object balance) {
    return 'Balance: $balance';
  }

  @override
  String get accountsLoadFailure => 'Failed to load accounts';

  @override
  String get accountsEmptyState => 'No accounts';

  @override
  String get accountsRefreshTooltip => 'Refresh';

  @override
  String get accountsAddTooltip => 'Add Account';

  @override
  String get addAccountDescription => 'Create a new bank account, wallet, or asset';

  @override
  String get addAccountDialogTitle => 'Add a new account';

  @override
  String get editAccountDialogTitle => 'Edit Account';

  @override
  String get accountNameHint => 'Account name';

  @override
  String get initialBalanceHint => 'Initial balance';

  @override
  String get currencyLabel => 'Currency';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get saveButton => 'Save';

  @override
  String get deleteButton => 'Delete';

  @override
  String get editButton => 'Edit';

  @override
  String get applyButton => 'Apply';

  @override
  String get clearButton => 'Clear';

  @override
  String get selectButton => 'Select';

  @override
  String get selectAllButton => 'Select All';

  @override
  String get deselectAllButton => 'Deselect All';

  @override
  String get deleteSelectedButton => 'Delete Selected';

  @override
  String totalCountLabel(Object count) {
    return 'Total: $count';
  }

  @override
  String selectedCountLabel(Object count) {
    return '$count selected';
  }

  @override
  String get formValidationPleaseEnterName => 'Please enter a name';

  @override
  String get formValidationPleaseEnterBalance => 'Please enter a balance';

  @override
  String get formValidationPleaseEnterValidNumber => 'Please enter a valid number';

  @override
  String get formValidationPleaseSelectCurrency => 'Please select a currency';

  @override
  String get currencyLoadError => 'Error loading currencies';

  @override
  String get noCurrenciesAvailable => 'No currencies available';

  @override
  String get categoriesAppBarTitle => 'Categories';

  @override
  String get categoriesScreenBody => 'Categories Screen';

  @override
  String get transactionsAppBarTitle => 'Transactions';

  @override
  String get transactionsScreenBody => 'Transactions Screen';

  @override
  String get settingsAppBarTitle => 'Settings';

  @override
  String get settingsScreenBody => 'Settings Screen';

  @override
  String get filePickerChooserTitle => 'Select File';

  @override
  String get imagePickerChooserTitle => 'Select Image';

  @override
  String get totalNetWorth => 'Total Net Worth';

  @override
  String get currencyBreakdown => 'Currency Breakdown';

  @override
  String get dashboardNetWorthTrend => 'Net Worth Trend';

  @override
  String get dashboardWealthDistributionByAccount => 'Wealth Distribution (by Account)';

  @override
  String get dashboardCurrencyExposure => 'Currency Exposure';

  @override
  String get dashboardNoAccountsFound => 'No accounts found';

  @override
  String get dashboardTotalNetWorthTrend => 'Total Net Worth Trend';

  @override
  String get dashboardAccountBalanceTrend => 'Account Balance Trend';

  @override
  String get dashboardWealthDistribution => 'Wealth Distribution';

  @override
  String get dashboardCurrencyBreakdown => 'Currency Breakdown';

  @override
  String get metricBalance => 'Balance';

  @override
  String get metricIncome => 'Income';

  @override
  String get metricExpense => 'Expense';

  @override
  String get metricReal => 'Real';

  @override
  String get metricChange => 'Change';

  @override
  String get contextMenuSelect => 'Select';

  @override
  String get contextMenuDeselect => 'Deselect';

  @override
  String get contextMenuSelectAll => 'Select All';

  @override
  String get contextMenuDeselectAll => 'Deselect All';

  @override
  String get contextMenuAddTransaction => 'Add Transaction';

  @override
  String get addTransactionDescription => 'Create a new transaction';

  @override
  String get contextMenuTransfer => 'Transfer';

  @override
  String get contextMenuEdit => 'Edit';

  @override
  String get contextMenuDelete => 'Delete';

  @override
  String get contextMenuChangeType => 'Change Type';

  @override
  String deleteConfirmationTitle(Object item) {
    return 'Delete $item?';
  }

  @override
  String deleteConfirmationMessage(Object item) {
    return 'Are you sure you want to delete this $item and all its data?';
  }

  @override
  String get deleteAccountsConfirmationTitle => 'Delete accounts?';

  @override
  String deleteAccountsConfirmationMessage(Object count) {
    return 'Delete $count selected accounts and their transactions?';
  }

  @override
  String get deleteAccountDialogReassign => 'Reassign transactions to another account';

  @override
  String get deleteAccountDialogDeleteAll => 'Delete all associated transactions';

  @override
  String get deleteAccountDialogMessage => 'This account may have associated transactions. What would you like to do?';

  @override
  String get newAccountLabel => 'New Account';

  @override
  String get warningOverwriteTitle => 'Warning: Overwrite Data?';

  @override
  String get warningOverwriteMessage => 'Restoring a backup will DELETE ALL current data and replace it with the backup. This cannot be undone.';

  @override
  String get restoreOverwriteButton => 'Restore & Overwrite';

  @override
  String get importSuccess => 'Import completed successfully.';

  @override
  String importFailed(Object error) {
    return 'Import failed: $error';
  }

  @override
  String deleteCategoriesConfirmationTitle(Object count) {
    return 'Delete $count categories?';
  }

  @override
  String get deleteCategoriesConfirmationMessage => 'Are you sure you want to delete the selected categories?';

  @override
  String get changeCategoryTypeDialogTitle => 'Change Category Type';

  @override
  String get noCategoriesCreated => 'No categories created yet.';

  @override
  String get addCategoryTooltip => 'Add Category';

  @override
  String get addCategoryDescription => 'Create a new expense or income category';

  @override
  String get previousPeriodTooltip => 'Previous Period';

  @override
  String get previousPeriodDescription => 'Go to the previous month or year';

  @override
  String get nextPeriodTooltip => 'Next Period';

  @override
  String get nextPeriodDescription => 'Go to the next month or year';

  @override
  String get filterTooltip => 'Filter';

  @override
  String get filterCategoriesDescription => 'Filter categories by type (Income/Expense)';

  @override
  String get selectDateTooltip => 'Select Date';

  @override
  String get selectDateDescription => 'Choose a specific date range to view totals';

  @override
  String get sortOrderTooltip => 'Sort Order';

  @override
  String get sortOrderDescription => 'Switch between ascending and descending amount order';

  @override
  String get closeSelectionTooltip => 'Close Selection';

  @override
  String get exitSelectionDescription => 'Exit selection mode';

  @override
  String get categoryNameLabel => 'Category Name';

  @override
  String get categoriesChangeButton => 'Change';

  @override
  String get parentCategoryLabel => 'Parent Category';

  @override
  String get styleLabel => 'Style (Icon & Color)';

  @override
  String get typeLabel => 'Type';

  @override
  String get deleteTransactionsConfirmationTitle => 'Delete Transactions';

  @override
  String deleteTransactionsConfirmationMessage(Object count) {
    return 'Are you sure you want to delete $count selected transactions?';
  }

  @override
  String get exitTransactionsSelectionDescription => 'Exit transaction selection mode';

  @override
  String get changeDateTooltip => 'Change Date';

  @override
  String get changeDateDescription => 'Update the date for all selected transactions';

  @override
  String get changeCategoryTooltip => 'Change Category';

  @override
  String get changeCategoryDescription => 'Update the category for all selected transactions';

  @override
  String get deleteTransactionsTooltip => 'Delete Selected';

  @override
  String get deleteTransactionsDescription => 'Permanently delete all selected transactions';

  @override
  String get amountLabel => 'Amount';

  @override
  String quantityLabel(Object quantity) {
    return 'Qty: $quantity';
  }

  @override
  String get quantityFormLabel => 'Quantity';

  @override
  String get selectAccountTitle => 'Select Account';

  @override
  String get selectCategoryTitle => 'Select Category';

  @override
  String get selectCurrencyTitle => 'Select Currency';

  @override
  String get accountLabel => 'Account';

  @override
  String get fromAccountLabel => 'From Account';

  @override
  String get toAccountLabel => 'To Account';

  @override
  String get categoryLabel => 'Category';

  @override
  String get dateLabel => 'Date';

  @override
  String get selectDateLabel => 'Select Date';

  @override
  String get addTransactionTitle => 'Add Transaction';

  @override
  String get editTransactionTitle => 'Edit Transaction';

  @override
  String get newTransferTitle => 'New Transfer';

  @override
  String get editTransferTitle => 'Edit Transfer';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get descriptionOptionalLabel => 'Description (Optional)';

  @override
  String get swapAccountsTooltip => 'Swap Accounts';

  @override
  String get incomeType => 'Income';

  @override
  String get expenseType => 'Expense';

  @override
  String get failedToLoadData => 'Failed to load data';

  @override
  String get invalidAmountError => 'Please enter a valid number';

  @override
  String get emptyAmountError => 'Please enter an amount';

  @override
  String get selectAccountError => 'Please select an account';

  @override
  String get selectCategoryError => 'Please select a category';

  @override
  String get selectDateError => 'Please select a date';

  @override
  String get currencyLockedMessage => 'Locked to From Account currency';

  @override
  String get totalValueLabel => 'Total Value';

  @override
  String get feeLabel => 'Fee';

  @override
  String get exchangeRateLabel => 'Exchange Rate';

  @override
  String get pricePerUnitLabel => 'Price per unit';

  @override
  String get buyAction => 'Buy';

  @override
  String get sellAction => 'Sell';

  @override
  String transferToDescription(Object accountName) {
    return 'Transfer to $accountName';
  }

  @override
  String transferFromDescription(Object accountName) {
    return 'Transfer from $accountName';
  }

  @override
  String buyDescription(Object assetName) {
    return 'Buy $assetName';
  }

  @override
  String sellDescription(Object assetName) {
    return 'Sell $assetName';
  }

  @override
  String assetTransferDescription(Object action, Object assetName) {
    return 'Transfer for $action $assetName';
  }

  @override
  String get swapDirectionTooltip => 'Swap Direction';

  @override
  String get availablePresetsLabel => 'Available Presets:';

  @override
  String get updateButton => 'Update';

  @override
  String get newPresetButton => 'New Preset';

  @override
  String get amountToAddToAccountLabel => 'Amount to Add to Account:';

  @override
  String valueInGlobalLabel(Object currency) {
    return 'Value in Global ($currency):';
  }

  @override
  String get feeCommissionLabel => 'Fee (Commission)';

  @override
  String get requiredError => 'Required';

  @override
  String currentPriceLabel(Object currency, Object price) {
    return 'Current Price: $price $currency';
  }

  @override
  String get linkedAccountLabel => 'Linked Account';

  @override
  String get selectLinkedAccountTitle => 'Select Linked Account';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get manageIconsLabel => 'Manage Icons';

  @override
  String get manageThemeLabel => 'Manage Theme';

  @override
  String get mainCurrencyLabel => 'Main Currency';

  @override
  String get defaultInflationCountryLabel => 'Default Inflation Country';

  @override
  String get persistAdvancedFiltersLabel => 'Persist Advanced Filters';

  @override
  String get hotKeysLabel => 'Hot Keys';

  @override
  String get smsImportLabel => 'SMS Import';

  @override
  String get smsImportSubtitle => 'Import transactions from bank SMS';

  @override
  String get apiManagementLabel => 'API Management';

  @override
  String get dataLabel => 'Data';

  @override
  String get syncSettingsLabel => 'Sync Settings';

  @override
  String get syncSettingsSubtitle => 'P2P sync via Syncthing';

  @override
  String get themeSettingsTitle => 'Theme Settings';

  @override
  String get appearanceSection => 'Appearance';

  @override
  String get themeModeLabel => 'Theme Mode';

  @override
  String get systemTheme => 'System';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get colorCustomizationSection => 'Color Customization';

  @override
  String get primaryColorLabel => 'Primary Color';

  @override
  String get secondaryColorLabel => 'Secondary Color';

  @override
  String get surfaceColorLabel => 'Surface Color';

  @override
  String get windowEffectsSection => 'Window Effects (Desktop)';

  @override
  String get enableEffectsLabel => 'Enable Window Effects';

  @override
  String get windowEffectLabel => 'Window Effect';

  @override
  String get backgroundLabel => 'Background';

  @override
  String get removeBackgroundColor => 'Remove background color';

  @override
  String get transparentSurfaceLabel => 'Transparent Surface (Cards)';

  @override
  String get fullyTransparentLabel => 'Fully Transparent';

  @override
  String get opaqueLabel => 'Opaque';

  @override
  String opacityLabel(Object value) {
    return 'Opacity: $value%';
  }

  @override
  String get backgroundSettingsSection => 'Background Settings';

  @override
  String get enableBackgroundImageLabel => 'Enable Background Image';

  @override
  String get backgroundBlurLabel => 'Background Blur';

  @override
  String get surfaceGlassStyleTitle => 'Surface/Glass Style';

  @override
  String get chooseImageButton => 'Choose Image';

  @override
  String get selectImageFileError => 'Please select an image file.';

  @override
  String get clearImageButton => 'Clear Image';

  @override
  String get saveThemePresetTitle => 'Save Theme Preset';

  @override
  String get presetNameLabel => 'Preset Name';

  @override
  String get presetNameHint => 'My Amazing Theme';

  @override
  String get importDataLabel => 'Import Data';

  @override
  String get exportDataLabel => 'Export Data';

  @override
  String get exportFormatMessage => 'Choose format:\n\nJSON: Full backup of all data.\nCSV: Readable report of transactions.';

  @override
  String get jsonFormat => 'JSON';

  @override
  String get csvFormat => 'CSV';

  @override
  String get importExchangeRatesLabel => 'Import Exchange Rates (CSV/JSON)';

  @override
  String get resetDataLabel => 'Reset Data to Defaults';

  @override
  String get resetDataSubtitle => 'This will delete all data and restore default settings.';

  @override
  String get debugMenuLabel => 'Debug Menu';

  @override
  String get debugMenuSubtitle => 'Internal developer tools';

  @override
  String get apiManagementTitle => 'API Management';

  @override
  String get apiCategoriesSection => 'API Categories';

  @override
  String get manualUtilitiesSection => 'Manual Utilities';

  @override
  String get startupDataSyncLabel => 'Startup Data Sync';

  @override
  String get startupDataSyncDescription => 'Controls both external data fetching and server synchronization on application launch.';

  @override
  String get standardApiLabel => 'Standard API';

  @override
  String get syncOnStartupDescription => 'Sync on startup';

  @override
  String get customSourcesLabel => 'Custom Sources';

  @override
  String syncCustomSourcesDescription(Object count) {
    return 'Sync all $count on startup';
  }

  @override
  String get individualCustomSourcesTitle => 'Individual Custom Sources';

  @override
  String get noCustomSourcesAdded => 'No custom sources added.';

  @override
  String get fetchTodaysRatesButton => 'Fetch Today\'s Rates';

  @override
  String get inflationConfigTitle => 'Inflation Config';

  @override
  String get countryCodeHint => 'Country Code (e.g. SRB)';

  @override
  String fetchDataForCountryButton(Object country) {
    return 'Fetch Data for $country';
  }

  @override
  String get steamSettingsTitle => 'Steam Settings';

  @override
  String get steamIdLabel => 'Steam ID (64-bit)';

  @override
  String get preferredGameLabel => 'Preferred Game';

  @override
  String get fetchInventoryNowButton => 'Fetch Inventory Now';

  @override
  String get manualExchangeRatesTitle => 'Manual Exchange Rates Fetch';

  @override
  String get selectStartDate => 'Select Start Date';

  @override
  String startDateFrom(Object date) {
    return 'From: $date';
  }

  @override
  String get selectEndDate => 'Select End Date';

  @override
  String endDateTo(Object date) {
    return 'To: $date';
  }

  @override
  String get fetchRangeButton => 'Fetch Range';

  @override
  String get manualSteamInventoryTitle => 'Manual Steam Inventory';

  @override
  String get selectGameHint => 'Select Game';

  @override
  String get fetchValueButton => 'Fetch Value';

  @override
  String get manualInflationDataTitle => 'Manual Inflation Data';

  @override
  String get selectStartYear => 'Select Start Year';

  @override
  String startYearFrom(Object year) {
    return 'From: $year';
  }

  @override
  String get selectEndYear => 'Select End Year';

  @override
  String endYearTo(Object year) {
    return 'To: $year';
  }

  @override
  String get fetchDataButton => 'Fetch Data';

  @override
  String get connectionOk => 'Connection OK';

  @override
  String get connectionFailed => 'Connection Failed';

  @override
  String get testConnectionButton => 'Test Connection';

  @override
  String get editCustomSourceTitle => 'Edit Custom Source';

  @override
  String get addCustomSourceTitle => 'Add Custom Source';

  @override
  String get addressFormatsHelp => 'Address Formats:\n• 192.168.1.10 (IP)\n• localhost or api.my.com\n• http://myserver.com';

  @override
  String get urlIpLabel => 'URL / IP';

  @override
  String get urlIpHint => '192.168.1.10:8080';

  @override
  String get dataTypeLabel => 'Data Type';

  @override
  String get apiTitleExchangeRates => 'Exchange Rates';

  @override
  String get apiTitleInflation => 'Inflation';

  @override
  String get apiTitleAssetPrices => 'Asset Prices';

  @override
  String get apiTitleSteamInventory => 'Steam Inventory';

  @override
  String get transferLabel => 'Transfer';

  @override
  String get uncategorizedLabel => 'Uncategorized';

  @override
  String get defaultLabel => 'Default';

  @override
  String receivedTotalLabel(Object total) {
    return 'Received: $total';
  }

  @override
  String spentTotalLabel(Object total) {
    return 'Spent: $total';
  }

  @override
  String get periodSummaryTitle => 'Period Summary';

  @override
  String get incomeLabel => 'Income';

  @override
  String get expenseLabel => 'Expense';

  @override
  String get netLabel => 'Net';

  @override
  String get exportSuccessMessage => 'Export completed successfully';

  @override
  String exportFailedMessage(Object error) {
    return 'Export failed: $error';
  }

  @override
  String get importSuccessMessage => 'Import completed successfully';

  @override
  String importFailedMessage(Object error) {
    return 'Import failed: $error';
  }

  @override
  String get resetDataConfirmationTitle => 'Reset Data?';

  @override
  String get resetDataConfirmationMessage => 'Warning! This will delete ALL your transactions, accounts, and settings.\n\nThe app will be restored to its initial state with default data.\nThis action CANNOT be undone.';

  @override
  String get resetEverythingButton => 'Reset Everything';

  @override
  String get resetSuccessMessage => 'Data reset and defaults restored.';

  @override
  String resetFailedMessage(Object error) {
    return 'Reset failed: $error';
  }

  @override
  String get importParsingStep => 'Parsing CSV files...';

  @override
  String get importFetchingRatesStep => 'Fetching exchange rates...';

  @override
  String importErrorLabel(Object error) {
    return 'Error: $error';
  }

  @override
  String get importOneMoneyLabel => 'Import from OneMoney (CSV)';

  @override
  String get importMyBudgetLabel => 'Import MyBudget Transactions (CSV)';

  @override
  String get restoreBackupLabel => 'Restore Backup (JSON)';

  @override
  String get importSelectionHelp => 'Select \'OneMoney\' for migration, \'MyBudget\' for adding transactions, or \'Restore Backup\' to overwrite all data.';

  @override
  String get importCreateAllNew => 'Create All New';

  @override
  String importNewAccountFound(Object accountName) {
    return 'New account found: \"$accountName\"';
  }

  @override
  String importMapAccountTitle(Object accountName) {
    return 'Map \"$accountName\" to...';
  }

  @override
  String get importMapToExisting => 'Map to Existing';

  @override
  String get importCreateNew => 'Create New';

  @override
  String importNewCategoryFound(Object categoryName) {
    return 'New category found: \"$categoryName\"';
  }

  @override
  String importMapCategoryTitle(Object categoryName) {
    return 'Map \"$categoryName\" to...';
  }

  @override
  String importNewCurrencyFound(Object currencyName) {
    return 'New currency found: \"$currencyName\"';
  }

  @override
  String importMapCurrencyTitle(Object currencyName) {
    return 'Map \"$currencyName\" to...';
  }

  @override
  String get importSkipAll => 'Skip All';

  @override
  String get importImportAll => 'Import All';

  @override
  String get importPotentialDuplicate => 'Potential Duplicate:';

  @override
  String importDateLabel(Object date) {
    return 'Date: $date';
  }

  @override
  String importFromLabel(Object from) {
    return 'From: $from';
  }

  @override
  String importToLabel(Object to) {
    return 'To: $to';
  }

  @override
  String importAmountLabel(Object amount, Object currency) {
    return 'Amount: $amount $currency';
  }

  @override
  String get importSkip => 'Skip';

  @override
  String get importImportAnyway => 'Import Anyway';

  @override
  String importDecisionLabel(Object decision) {
    return 'Decision: $decision';
  }

  @override
  String get importReadyTitle => 'Ready to Import';

  @override
  String importReadyMessage(Object count) {
    return '$count transactions are ready to be imported.';
  }

  @override
  String get importFinalizeButton => 'Finalize Import';

  @override
  String get importingTitle => 'Importing...';

  @override
  String get importCompleteTitle => 'Import Complete';

  @override
  String get importStartOverTooltip => 'Start Over';

  @override
  String get importDataTitle => 'Import Data';

  @override
  String importAccountsCreatedLabel(Object count) {
    return 'New Accounts Created: $count';
  }

  @override
  String importCategoriesCreatedLabel(Object count) {
    return 'New Categories Created: $count';
  }

  @override
  String importTransactionsImportedLabel(Object count) {
    return 'Transactions Imported: $count';
  }

  @override
  String importDuplicatesSkippedLabel(Object count) {
    return 'Duplicates Skipped: $count';
  }

  @override
  String get searchHint => 'Search';

  @override
  String get debugAllDataClearedMessage => 'All data cleared and re-seeded with defaults.';

  @override
  String get debugClearAllDataLabel => 'Clear All Data (and re-seed defaults)';

  @override
  String get debugMinimumDataSeededMessage => 'Minimum data seeded.';

  @override
  String get debugSeedMinimumDataLabel => 'Seed Minimum Data';

  @override
  String get debugMediumDataSeededMessage => 'Medium data seeded.';

  @override
  String get debugSeedMediumDataLabel => 'Seed Medium Data';

  @override
  String get debugMaximumDataSeededMessage => 'Maximum data seeded.';

  @override
  String get debugSeedMaximumDataLabel => 'Seed Maximum Data (for performance test)';

  @override
  String get debugRunningInDebugModeLabel => 'Running in DEBUG mode';

  @override
  String get deleteAllButton => 'Delete All';

  @override
  String get changeButton => 'Change';

  @override
  String get undoButton => 'Undo';

  @override
  String itemDeletedMessage(Object name) {
    return '$name deleted';
  }

  @override
  String get totalBalanceLabel => 'Total Balance';

  @override
  String get noCurrenciesSelected => 'No currencies selected.';

  @override
  String get failedToLoadDashboard => 'Failed to load dashboard';

  @override
  String get dashboardCalendarTab => 'Calendar';

  @override
  String get dashboardTabCalendar => 'Calendar';

  @override
  String get dashboardCalendarTooltip => 'Calendar View';

  @override
  String get dashboardCalendarDescription => 'View transactions in a calendar format';

  @override
  String get dashboardCategoriesTab => 'Categories';

  @override
  String get dashboardTabCategories => 'Categories';

  @override
  String get dashboardCategoriesTooltip => 'Category Analysis';

  @override
  String get dashboardCategoriesDescription => 'Breakdown of expenses by category';

  @override
  String get dashboardBalanceTab => 'Balance';

  @override
  String get dashboardTabBalance => 'Balance';

  @override
  String get dashboardBalanceTooltip => 'Balance History';

  @override
  String get dashboardBalanceDescription => 'Track net worth over time';

  @override
  String get dashboardExpensesLabel => 'Expenses';

  @override
  String get dashboardIncomeLabel => 'Income';

  @override
  String get manageIconsTitle => 'Manage Icons';

  @override
  String get manageStylesDeleteTitle => 'Delete Icons';

  @override
  String manageStylesDeleteConfirm(Object count) {
    return 'Are you sure you want to delete $count selected icons?';
  }

  @override
  String manageStylesDeleteConfirmWithTransfer(Object count) {
    return 'Are you sure you want to delete $count selected icons? (Transfer icon will be skipped)';
  }

  @override
  String get noIconsCreated => 'No icons created yet.';

  @override
  String get failedToLoadIcons => 'Failed to load icons.';

  @override
  String get cannotDeleteTransferIcon => 'Cannot delete the Transfer icon.';

  @override
  String get deleteIconsDialogTitle => 'Delete Icons';

  @override
  String deleteIconsConfirmationMessage(Object count) {
    return 'Are you sure you want to delete $count selected icons?';
  }

  @override
  String deleteIconsWithSkipTransferMessage(Object count) {
    return 'Are you sure you want to delete $count selected icons? (Transfer icon will be skipped)';
  }

  @override
  String get deleteIconDialogTitle => 'Delete Icon';

  @override
  String deleteIconConfirmationMessage(Object name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String deleteMultipleAccountsTitle(Object count) {
    return 'Delete $count accounts?';
  }

  @override
  String get deleteMultipleAccountsMessage => 'Are you sure you want to delete the selected accounts? All associated transactions will be deleted.';

  @override
  String get changeAccountTypeDialogTitle => 'Change Account Type';

  @override
  String editAccountTitle(Object name) {
    return 'Edit: $name';
  }

  @override
  String get balanceCalculatedFromAsset => 'Balance is calculated from Asset Quantity * Price';

  @override
  String get selectAccountTypeTitle => 'Select Account Type';

  @override
  String get selectCountryTitle => 'Select Country';

  @override
  String get selectIconSubtitle => 'Select an icon';

  @override
  String get bindToAssetLabel => 'Bind to Asset (Optional)';

  @override
  String get selectAssetTitle => 'Select Asset';

  @override
  String get selectedAssetLabel => 'Selected Asset';

  @override
  String get balanceAutoCalculatedLabel => 'Balance is calculated automatically';

  @override
  String get tapToBindAssetLabel => 'Tap to bind an asset';

  @override
  String get assetQuantityLabel => 'Asset Quantity';

  @override
  String get linkedAssetsTitle => 'Linked Assets';

  @override
  String get noneLabel => 'None';

  @override
  String get accountTypeLabel => 'Account Type';

  @override
  String get formValidationPleaseSelectAccountType => 'Please select an account type';

  @override
  String get iconLabel => 'Icon';

  @override
  String get languageLabel => 'Language';

  @override
  String get systemDefaultLabel => 'System Default';

  @override
  String get selectLanguageTitle => 'Select Language';

  @override
  String get dashboardLabel => 'Dashboard';

  @override
  String get homeLabel => 'Home';

  @override
  String get historyLabel => 'History';

  @override
  String get syncScreenTitle => 'Synchronization Settings';

  @override
  String get syncP2PSection => 'P2P Synchronization (Syncthing)';

  @override
  String get syncEnableP2P => 'Enable P2P Sync';

  @override
  String get syncP2PSubtitle => 'Sync via .sync files in a shared folder';

  @override
  String get syncFolderLabel => 'Sync Folder';

  @override
  String get syncFolderNotSelected => 'Not selected';

  @override
  String get syncBrowseButton => 'Browse';

  @override
  String get syncClearFilesButton => 'Clear sync files';

  @override
  String get syncServerSection => 'Cloud Synchronization (Server)';

  @override
  String get syncServerUrlLabel => 'Server URL';

  @override
  String get syncApiTokenLabel => 'API Token';

  @override
  String get syncApiTokenHint => 'Enter your security token';

  @override
  String get syncApiTokenHelp => 'This token is your shared secret. Enter the same value on all your devices to authorize synchronization.';

  @override
  String get syncTestConnectionButton => 'Test Connection';

  @override
  String get syncTestingLabel => 'Testing...';

  @override
  String get syncSaveServerSettingsButton => 'Save Server Settings';

  @override
  String get syncEnableServer => 'Enable Server Sync';

  @override
  String get syncServerSubtitle => 'Sync with a MyBudget Server instance';

  @override
  String get syncPendingLocalChanges => 'Pending local changes:';

  @override
  String get syncSyncNowButton => 'Sync Now';

  @override
  String get syncSyncingLabel => 'Syncing...';

  @override
  String get syncWebNotAvailable => 'Synchronization is not available on Web';

  @override
  String get syncPermissionRequired => 'Storage permission required for sync. Please enable \"All files access\" in settings.';

  @override
  String get syncSelectFolderTitle => 'Select Syncthing Folder';

  @override
  String get syncClearFilesTitle => 'Clear Sync Files';

  @override
  String get syncClearFilesConfirm => 'This will delete all .sync files from the selected folder. This action cannot be undone.';

  @override
  String syncDeletedFilesCount(Object count) {
    return 'Deleted $count sync files';
  }

  @override
  String syncClearFilesError(Object error) {
    return 'Error clearing files: $error';
  }

  @override
  String get syncSettingsSaved => 'Server settings saved';

  @override
  String get syncConnectionSuccessful => 'Connection successful!';

  @override
  String get syncConnectionFailed => 'Connection failed. Check URL and Token.';

  @override
  String get syncConnectionUnauthorized => 'Token rejected by the server. Check the token, not the address.';

  @override
  String get syncServerNotConfigured => 'The server has no sync token configured and is refusing every device. Set SYNC_TOKEN on the server and use the same value here.';

  @override
  String get syncCompleted => 'Sync completed successfully';

  @override
  String syncFailed(Object error) {
    return 'Sync failed: $error';
  }

  @override
  String get smsRuleAddTitle => 'Add Rule';

  @override
  String get smsRuleEditTitle => 'Edit Rule';

  @override
  String get smsRuleTransactionType => 'Transaction Type';

  @override
  String get smsRuleMatchPattern => 'Match Pattern (Regex)';

  @override
  String get smsRuleMatchPatternHint => 'e.g., Placanje.*karticom';

  @override
  String get smsRuleMatchPatternHelp => 'Pattern to identify this SMS type';

  @override
  String get smsRuleAmountPattern => 'Amount Pattern (Regex)';

  @override
  String get smsRuleAmountPatternHint => 'e.g., iznos\\s+([\\d,.]+)';

  @override
  String get smsRuleAmountPatternHelp => 'Group 1 should capture the amount';

  @override
  String get smsRuleCurrencyPattern => 'Currency Pattern (Regex, optional)';

  @override
  String get smsRuleCurrencyPatternHint => 'e.g., [\\d,.]+\\s*(\\w\\w\\w)';

  @override
  String get smsRuleCurrencyPatternHelp => 'Group 1 should capture currency code';

  @override
  String get smsRuleTestTitle => 'Test Your Rule';

  @override
  String get smsRuleTestSmsHint => 'Paste SMS text here';

  @override
  String get smsRuleTestButton => 'Test Pattern';

  @override
  String get smsRuleTestEnterSmsError => 'Enter SMS text to test';

  @override
  String get smsRuleTestMatchError => '✗ Match pattern did not find a match';

  @override
  String get smsRuleTestAmountError => '✗ Amount pattern did not find a match';

  @override
  String smsRuleTestSuccess(Object amount, Object currency, Object type) {
    return '✓ Match found!\nType: $type\nAmount: $amount\nCurrency: $currency';
  }

  @override
  String smsRuleTestRegexError(Object error) {
    return '✗ Invalid regex: $error';
  }

  @override
  String get smsRuleRequiredError => 'Match and Amount patterns are required';

  @override
  String inflationError(Object error) {
    return 'Error: $error';
  }

  @override
  String get inflationNoRatesFound => 'No inflation rates found.';

  @override
  String get inflationAddRate => 'Add Inflation Rate';

  @override
  String get inflationDeleteConfirmTitle => 'Delete Rates?';

  @override
  String inflationDeleteConfirmMessage(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rates',
      one: 'this rate',
    );
    return 'Are you sure you want to delete $_temp0?';
  }

  @override
  String inflationSelectedCount(Object count) {
    return '$count selected';
  }

  @override
  String get inflationFiltersTitle => 'Inflation Filters';

  @override
  String get inflationCountries => 'Countries';

  @override
  String get inflationPresets => 'Presets';

  @override
  String deleteCategoryConfirmTitle(Object name) {
    return 'Delete $name?';
  }

  @override
  String get deleteCategoryMessage => 'This category has associated transactions. What would you like to do?';

  @override
  String get deleteCategoryReassign => 'Reassign transactions to another category';

  @override
  String get deleteCategoryNewCategory => 'New Category';

  @override
  String get deleteCategoryDeleteAll => 'Delete all associated transactions';

  @override
  String deleteAccountConfirmTitle(Object name) {
    return 'Delete $name?';
  }

  @override
  String get deleteAccountMessage => 'This account may have associated transactions. What would you like to do?';

  @override
  String get deleteAccountReassign => 'Reassign transactions to another account';

  @override
  String get deleteAccountNewAccount => 'New Account';

  @override
  String get deleteAccountDeleteAll => 'Delete all associated transactions';

  @override
  String get confirmButton => 'Confirm';

  @override
  String get okButton => 'OK';

  @override
  String get noItemsFound => 'No items found.';

  @override
  String get noDataForPeriod => 'No data for this period';

  @override
  String get noDataForRange => 'No data for this range';

  @override
  String get noHistoryData => 'No history data available';

  @override
  String get disabledByGlobalSync => 'Disabled by Global Sync';

  @override
  String dateCreatedLabel(Object date) {
    return 'Date created: $date';
  }

  @override
  String get anyLabel => 'Any';

  @override
  String get balanceDisplayLabel => 'Balance Display';

  @override
  String currenciesActiveLabel(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count currencies active',
      one: '1 currency active',
    );
    return '$_temp0';
  }

  @override
  String get searchCountryLabel => 'Search Country';

  @override
  String get addNewIconLabel => 'Add New Icon';

  @override
  String get noIconsFoundLabel => 'No icons found';

  @override
  String get addNewStyleLabel => 'Add New Style';

  @override
  String get styleNameLabel => 'Style Name';

  @override
  String get pleaseEnterStyleName => 'Please enter a style name';

  @override
  String get colorLabel => 'Color';

  @override
  String get netBalanceMetric => 'Net Bal.';

  @override
  String get investedMetric => 'Invested';

  @override
  String get realizedMetric => 'Realized';

  @override
  String get feesMetric => 'Fees';

  @override
  String get persistFiltersLabel => 'Persist Filters';

  @override
  String get searchByNameHint => 'Search by name...';

  @override
  String get searchDescriptionHint => 'Search description...';

  @override
  String get advancedFiltersTitle => 'Advanced Filters';

  @override
  String get transactionTypeLabel => 'Transaction Type';

  @override
  String get assetFiltersTitle => 'Asset Filters';

  @override
  String get minValueLabel => 'Min Value';

  @override
  String get maxValueLabel => 'Max Value';

  @override
  String get assetTypesLabel => 'Asset Types';

  @override
  String get allLabel => 'All';

  @override
  String get currenciesLabel => 'Currencies';

  @override
  String get sourcesLabel => 'Sources';

  @override
  String get presetsLabel => 'Presets';

  @override
  String get enterCategoryNameHint => 'Enter category name';

  @override
  String get selectTypeHint => 'Select Type';

  @override
  String get hotKeysTitle => 'Hot Keys';

  @override
  String get searchHotkeysHint => 'Search hotkeys...';

  @override
  String get noMatchingHotkeys => 'No matching hotkeys found.';

  @override
  String recordingHotkeyTitle(Object label) {
    return 'Recording Hotkey for \"$label\"';
  }

  @override
  String get pressKeysHint => 'Press keys...';

  @override
  String get pressAnyCombinationHint => 'Press any key combination.';

  @override
  String get clearSaveButton => 'Clear / Save';

  @override
  String get duplicateHotkeyTooltip => 'Duplicate Hotkey';

  @override
  String usedByLabel(Object action) {
    return 'Used by $action';
  }

  @override
  String get hkCategoryNavigation => 'Navigation';

  @override
  String get hkCategoryDashboardTabs => 'Dashboard Tabs (Ctrl + 1/2/3)';

  @override
  String get hkCategoryDataTabs => 'Data Tabs (Ctrl + 1/2/3)';

  @override
  String get hkCategoryPeriodControl => 'Period Control';

  @override
  String get hkCategoryActions => 'Actions';

  @override
  String get hkCategorySelectionMode => 'Selection Mode';

  @override
  String get hkActionBack => 'Global: Go Back / Exit';

  @override
  String get hkActionDashboard => 'Go to Dashboard';

  @override
  String get hkActionAccounts => 'Go to Accounts';

  @override
  String get hkActionTransactions => 'Go to Transactions';

  @override
  String get hkActionCategories => 'Go to Categories';

  @override
  String get hkActionData => 'Go to Data / Exchange Rates';

  @override
  String get hkActionSettings => 'Go to Settings';

  @override
  String get hkActionDashboardTab1 => 'Calendar Tab';

  @override
  String get hkActionDashboardTab2 => 'Categories Tab';

  @override
  String get hkActionDashboardTab3 => 'Balance Tab';

  @override
  String get hkActionDataTab1 => 'Exchange Rates';

  @override
  String get hkActionDataTab2 => 'Inflation';

  @override
  String get hkActionDataTab3 => 'Assets';

  @override
  String get hkActionPrevPeriod => 'Previous Period';

  @override
  String get hkActionNextPeriod => 'Next Period';

  @override
  String get hkActionAddAction => 'Generic Add Action';

  @override
  String get hkActionAccountsSelectionClose => 'Accounts: Close';

  @override
  String get hkActionAccountsSelectionAll => 'Accounts: Select All';

  @override
  String get hkActionAccountsSelectionDelete => 'Accounts: Delete';

  @override
  String get hkActionAccountsSelectionChangeType => 'Accounts: Change Type';

  @override
  String get hkActionCategoriesSelectionClose => 'Categories: Close';

  @override
  String get hkActionCategoriesSelectionAll => 'Categories: Select All';

  @override
  String get hkActionCategoriesSelectionDelete => 'Categories: Delete';

  @override
  String get hkActionCategoriesSelectionChangeType => 'Categories: Change Type';

  @override
  String get hkActionDataSelectionClose => 'Data: Close';

  @override
  String get hkActionDataSelectionAll => 'Data: Select All';

  @override
  String get hkActionDataSelectionDelete => 'Data: Delete';

  @override
  String get hkActionDataSelectionChangePreset => 'Data: Change Preset';

  @override
  String get styNotFound => 'Style not found.';

  @override
  String get stySaveChanges => 'Save Changes';

  @override
  String get styAddIcon => 'Add Icon';

  @override
  String get smsOnlyAndroid => 'SMS import is only available on Android';

  @override
  String get smsImportSms => 'Import SMS';

  @override
  String get smsPermissionRequired => 'SMS Permission Required';

  @override
  String get smsPermissionRationale => 'To import transactions from SMS, we need permission to read your messages.';

  @override
  String get smsGrantPermission => 'Grant Permission';

  @override
  String get smsNoPresets => 'No presets configured. Tap + to add one.';

  @override
  String get smsImportDescription => 'Import transactions from SMS messages. Choose a time range:';

  @override
  String get smsLast7Days => 'Last 7 Days';

  @override
  String get smsAllTime => 'All Time';

  @override
  String smsFilterLabel(Object filter) {
    return 'Filter: $filter';
  }

  @override
  String get smsEditPreset => 'Edit Preset';

  @override
  String get smsNewPreset => 'New Preset';

  @override
  String get smsPresetNameHint => 'e.g., My Bank';

  @override
  String get smsSenderFilter => 'Sender Filter';

  @override
  String get smsSenderFilterHint => 'e.g., ALTA or +381...';

  @override
  String get smsSenderFilterHelper => 'Filter SMS by sender name or phone number';

  @override
  String get smsDefaults => 'Defaults';

  @override
  String get smsDefaultAccount => 'Default Account';

  @override
  String get smsDefaultCategory => 'Default Category';

  @override
  String get smsImportMessages => 'Import Messages';

  @override
  String get smsSelectDefaultsFirst => 'Select defaults first';

  @override
  String get smsCustomRange => 'Custom Range';

  @override
  String smsImportSuccessCount(Object count) {
    return 'Success: $count transactions imported';
  }

  @override
  String get smsParsingRules => 'Parsing Rules';

  @override
  String get smsNoRules => 'No rules defined. Tap + to add one.';

  @override
  String smsMatchLabel(Object pattern) {
    return 'Match: $pattern';
  }

  @override
  String get smsNameSenderRequired => 'Name and sender filter are required';

  @override
  String get smsCategoryKeywords => 'Category Keywords';

  @override
  String get smsCategoryKeywordsSubtitle => 'Map keywords in SMS body to categories';

  @override
  String get smsNoKeywordRules => 'No keyword rules. Tap + to add one.';

  @override
  String get smsAddKeywordRule => 'Add Keyword Rule';

  @override
  String get smsKeyword => 'Keyword';

  @override
  String get smsKeywordHint => 'e.g., Grocery, Netflix';

  @override
  String get smsKeywordHelper => 'Case-insensitive substring to match in SMS body';

  @override
  String get smsSelectCategoryHint => 'Select category';

  @override
  String get dshSelectDateDescription => 'Open calendar to pick a specific date or range';

  @override
  String get dshCurrencyDescription => 'Select the primary currency for display';

  @override
  String get dshChangeViewTooltip => 'Change View';

  @override
  String get dshChangeViewDescription => 'Switch between Monthly and Yearly views';

  @override
  String get dshMonthlyAbbreviation => 'M';

  @override
  String get dshYearlyAbbreviation => 'Y';

  @override
  String dshBalancesOnDate(Object date) {
    return 'Balances on $date';
  }

  @override
  String get dshSearchCurrency => 'Search Currency';

  @override
  String get dshUnknownCategory => 'Unknown';

  @override
  String get pckSelectItem => 'Select Item';

  @override
  String get pckSelectItems => 'Select Items';

  @override
  String get pckClearAll => 'Clear All';

  @override
  String get pckSelectIcon => 'Select Icon';

  @override
  String get pckMaterialIcons => 'Material Icons';

  @override
  String get pckCustomIcons => 'Custom Icons';

  @override
  String get fltAmountFrom => 'Amount From';

  @override
  String get fltAmountTo => 'Amount To';

  @override
  String get fltSelectRange => 'Select Range';

  @override
  String get fltAdvancedFilterTooltip => 'Advanced Filter';

  @override
  String get fltAdvancedFilterDescription => 'Filter transactions by account, category, or amount';

  @override
  String get fltSortOrderDescription => 'Toggle between ascending and descending order';

  @override
  String get fltAccountFiltersTitle => 'Account Filters';

  @override
  String get fltNameLabel => 'Name';

  @override
  String get fltAccountTypesLabel => 'Account Types';

  @override
  String get fltFilterCurrenciesLabel => 'Filter Currencies';

  @override
  String get fltSelectCurrenciesLabel => 'Select Currencies';

  @override
  String get fltFilterCategoriesTitle => 'Filter Categories';

  @override
  String get exchAddExchangeRate => 'Add Exchange Rate';

  @override
  String get exchEditExchangeRate => 'Edit Exchange Rate';

  @override
  String get exchAddRateDescription => 'Manually enter a conversion rate between two currencies';

  @override
  String get exchNoRatesFound => 'No exchange rates found.';

  @override
  String get exchChangePreset => 'Change Preset';

  @override
  String get exchFromCurrency => 'From Currency';

  @override
  String get exchToCurrency => 'To Currency';

  @override
  String get exchRate => 'Rate';

  @override
  String get exchPresetIdLabel => 'Preset ID';

  @override
  String exchPresetValue(Object preset) {
    return 'Preset: $preset';
  }

  @override
  String get exchSelectRange => 'Select Range';

  @override
  String get exchPreviousPeriodDescription => 'Go to the previous day, month, or year';

  @override
  String get exchNextPeriodDescription => 'Go to the next day, month, or year';

  @override
  String get exchFilterDescription => 'Filter rates by from/to currency and preset ID';

  @override
  String get exchSelectDateDescription => 'Choose a specific date or range to view historical rates';

  @override
  String get exchSortOrderDescription => 'Switch between ascending and descending date/rate order';

  @override
  String get exchFilterExchangeRates => 'Filter Exchange Rates';

  @override
  String get exchExitSelectionDescription => 'Exit exchange rate selection mode';

  @override
  String get exchSelectAllDescription => 'Select all listed exchange rates';

  @override
  String get exchDeselectAllDescription => 'Unselect all rates';

  @override
  String get exchChangePresetDescription => 'Update the preset ID for all selected exchange rates';

  @override
  String get exchDeleteSelectedDescription => 'Permanently delete all selected exchange rates';

  @override
  String get exchDeleteExchangeRatesTitle => 'Delete Exchange Rates';

  @override
  String exchDeleteConfirmMessage(Object count) {
    return 'Are you sure you want to delete $count exchange rates?';
  }

  @override
  String get exchUpdatePresetTitle => 'Update Preset';

  @override
  String get exchUpdatePresetMessage => 'Enter the new preset ID for the selected items:';

  @override
  String dashboardUnconvertibleCurrencies(String currencies) {
    return '$currencies could not be converted and are not included in the total';
  }

  @override
  String get addAccountBeforeTransactionDescription => 'A transaction needs an account. Create your first one to get started';

  @override
  String get selectDialogEmptyState => 'There is nothing to choose from yet';

  @override
  String get selectDialogNoMatches => 'No matches for your search';

  @override
  String get addButton => 'Add';

  @override
  String get retryButton => 'Retry';

  @override
  String get unknownLabel => 'Unknown';

  @override
  String get globalLabel => 'Global';

  @override
  String dateWithValueLabel(String date) {
    return 'Date: $date';
  }

  @override
  String selectColorTitle(String label) {
    return 'Select $label Color';
  }

  @override
  String get assetAddTitle => 'Add Asset Data';

  @override
  String get assetEditTitle => 'Edit Asset Data';

  @override
  String get assetAddDescription => 'Record value or quantity of a specific asset';

  @override
  String get assetNameLabel => 'Asset Name (e.g. Apple Stock)';

  @override
  String get assetIdLabel => 'Asset ID (e.g. AAPL)';

  @override
  String get assetValueLabel => 'Value (Price per unit)';

  @override
  String get assetTypeOptionalLabel => 'Asset Type (Optional)';

  @override
  String get assetLinkedAccountOptionalLabel => 'Linked Account (Optional)';

  @override
  String get assetNameRequiredError => 'Give the asset a name';

  @override
  String get assetIdRequiredError => 'Give the asset an ID, for example AAPL';

  @override
  String get assetValueInvalidError => 'Enter a number, for example 150.25';

  @override
  String get assetNoAssetsFound => 'No assets found.';

  @override
  String assetError(String error) {
    return 'Error: $error';
  }

  @override
  String get assetDeleteConfirmTitle => 'Delete Assets?';

  @override
  String assetDeleteConfirmMessage(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
      
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString assets',
      one: 'this asset',
    );
    return 'Are you sure you want to delete $_temp0?';
  }

  @override
  String get assetDeleteSelectedDescription => 'Permanently delete all selected asset records';

  @override
  String get inflationEditRate => 'Edit Inflation Rate';

  @override
  String get inflationAddDescription => 'Enter a new inflation percentage for a specific date and country';

  @override
  String get inflationPercentLabel => 'Inflation Percent (%)';

  @override
  String get inflationPercentHint => 'e.g. 2.5';

  @override
  String get inflationPercentInvalidError => 'Enter a number, for example 2.5';

  @override
  String get inflationCountryGlobal => 'Country: Global';

  @override
  String inflationCountryNamed(String country) {
    return 'Country: $country';
  }

  @override
  String get inflationUseWorldwideRate => 'Use the worldwide rate';

  @override
  String get pickerSingleDate => 'Single Date';

  @override
  String get pickerRange => 'Range';

  @override
  String get dateStepDay => 'Day';

  @override
  String get dateStepMonth => 'Month';

  @override
  String get dateStepYear => 'Year';

  @override
  String get feeStructureTitle => 'Fee Structure';

  @override
  String get feeNoRulesApplied => 'No fee rules applied.';

  @override
  String get feeAddRule => 'Add Fee Rule';

  @override
  String get feeFixedFee => 'Fixed Fee';

  @override
  String get feePercentFee => 'Percent Fee';

  @override
  String get feeTaxRate => 'Tax Rate';

  @override
  String get feeUnknownRule => 'Unknown Rule';

  @override
  String get feeRatePercentLabel => 'Rate (%)';

  @override
  String get feeTaxRatePercentLabel => 'Tax Rate (%)';

  @override
  String get feeCostBasisLabel => 'Cost Basis';

  @override
  String deleteAccountsConfirmTitle(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
      
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString accounts',
      one: 'this account',
    );
    return 'Delete $_temp0?';
  }

  @override
  String get deleteAccountsConfirmMessage => 'Are you sure you want to delete the selected accounts? All associated transactions will be deleted.';

  @override
  String get changeAccountTypeTitle => 'Change Account Type';

  @override
  String get accountsPreviousPeriodDescription => 'Go to the previous month or year';

  @override
  String get accountsNextPeriodDescription => 'Go to the next month or year';

  @override
  String get accountsFilterDescription => 'Filter accounts by type or hidden status';

  @override
  String get accountsSelectDateDescription => 'Choose a specific date to view historical balances';

  @override
  String get accountsSortDescription => 'Switch between ascending and descending balance order';

  @override
  String get smsRuleCategoryOptional => 'Category (optional)';

  @override
  String get smsRuleCategoryHelp => 'Override category for this rule';
}
