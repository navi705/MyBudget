// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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
  String totalCountLabel(Object count) {
    return 'Total: $count';
  }

  @override
  String get closeSelectionTooltip => 'Close Selection';

  @override
  String get exitSelectionDescription => 'Exit selection mode';

  @override
  String selectedCountLabel(Object count) {
    return '$count selected';
  }

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
  String get exitTransactionsSelectionDescription => 'Exit transaction selection mode';

  @override
  String quantityLabel(Object quantity) {
    return 'Qty: $quantity';
  }

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
  String get amountLabel => 'Amount';

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
  String get incomeLabel => 'Income';

  @override
  String get expenseLabel => 'Expense';

  @override
  String get failedToLoadDashboard => 'Failed to load dashboard';

  @override
  String get dashboardCalendarTab => 'Calendar';

  @override
  String get dashboardCalendarTooltip => 'Calendar View';

  @override
  String get dashboardCalendarDescription => 'View transactions in a calendar format';

  @override
  String get dashboardCategoriesTab => 'Categories';

  @override
  String get dashboardCategoriesTooltip => 'Category Analysis';

  @override
  String get dashboardCategoriesDescription => 'Breakdown of expenses by category';

  @override
  String get dashboardBalanceTab => 'Balance';

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
}
