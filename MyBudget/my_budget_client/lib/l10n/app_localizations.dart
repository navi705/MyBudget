import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_ur.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('bn'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('pt'),
    Locale('ru'),
    Locale('ur'),
    Locale('zh')
  ];

  /// No description provided for @helloWorld.
  ///
  /// In en, this message translates to:
  /// **'Hello World!'**
  String get helloWorld;

  /// No description provided for @accountsAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accountsAppBarTitle;

  /// No description provided for @accountsBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Balance: {balance}'**
  String accountsBalanceLabel(Object balance);

  /// No description provided for @accountsLoadFailure.
  ///
  /// In en, this message translates to:
  /// **'Failed to load accounts'**
  String get accountsLoadFailure;

  /// No description provided for @accountsEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No accounts'**
  String get accountsEmptyState;

  /// No description provided for @accountsRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get accountsRefreshTooltip;

  /// No description provided for @accountsAddTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add Account'**
  String get accountsAddTooltip;

  /// No description provided for @addAccountDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a new bank account, wallet, or asset'**
  String get addAccountDescription;

  /// No description provided for @addAccountDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a new account'**
  String get addAccountDialogTitle;

  /// No description provided for @accountNameHint.
  ///
  /// In en, this message translates to:
  /// **'Account name'**
  String get accountNameHint;

  /// No description provided for @initialBalanceHint.
  ///
  /// In en, this message translates to:
  /// **'Initial balance'**
  String get initialBalanceHint;

  /// No description provided for @currencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currencyLabel;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// No description provided for @editButton.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editButton;

  /// No description provided for @applyButton.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get applyButton;

  /// No description provided for @clearButton.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearButton;

  /// No description provided for @formValidationPleaseEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get formValidationPleaseEnterName;

  /// No description provided for @formValidationPleaseEnterBalance.
  ///
  /// In en, this message translates to:
  /// **'Please enter a balance'**
  String get formValidationPleaseEnterBalance;

  /// No description provided for @formValidationPleaseEnterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get formValidationPleaseEnterValidNumber;

  /// No description provided for @formValidationPleaseSelectCurrency.
  ///
  /// In en, this message translates to:
  /// **'Please select a currency'**
  String get formValidationPleaseSelectCurrency;

  /// No description provided for @currencyLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading currencies'**
  String get currencyLoadError;

  /// No description provided for @noCurrenciesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No currencies available'**
  String get noCurrenciesAvailable;

  /// No description provided for @categoriesAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesAppBarTitle;

  /// No description provided for @categoriesScreenBody.
  ///
  /// In en, this message translates to:
  /// **'Categories Screen'**
  String get categoriesScreenBody;

  /// No description provided for @transactionsAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactionsAppBarTitle;

  /// No description provided for @transactionsScreenBody.
  ///
  /// In en, this message translates to:
  /// **'Transactions Screen'**
  String get transactionsScreenBody;

  /// No description provided for @settingsAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsAppBarTitle;

  /// No description provided for @settingsScreenBody.
  ///
  /// In en, this message translates to:
  /// **'Settings Screen'**
  String get settingsScreenBody;

  /// No description provided for @filePickerChooserTitle.
  ///
  /// In en, this message translates to:
  /// **'Select File'**
  String get filePickerChooserTitle;

  /// No description provided for @imagePickerChooserTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Image'**
  String get imagePickerChooserTitle;

  /// No description provided for @totalNetWorth.
  ///
  /// In en, this message translates to:
  /// **'Total Net Worth'**
  String get totalNetWorth;

  /// No description provided for @currencyBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Currency Breakdown'**
  String get currencyBreakdown;

  /// No description provided for @metricBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get metricBalance;

  /// No description provided for @metricIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get metricIncome;

  /// No description provided for @metricExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get metricExpense;

  /// No description provided for @metricReal.
  ///
  /// In en, this message translates to:
  /// **'Real'**
  String get metricReal;

  /// No description provided for @metricChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get metricChange;

  /// No description provided for @contextMenuSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get contextMenuSelect;

  /// No description provided for @contextMenuDeselect.
  ///
  /// In en, this message translates to:
  /// **'Deselect'**
  String get contextMenuDeselect;

  /// No description provided for @contextMenuSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get contextMenuSelectAll;

  /// No description provided for @contextMenuDeselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get contextMenuDeselectAll;

  /// No description provided for @contextMenuAddTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get contextMenuAddTransaction;

  /// No description provided for @addTransactionDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a new transaction'**
  String get addTransactionDescription;

  /// No description provided for @contextMenuTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get contextMenuTransfer;

  /// No description provided for @contextMenuEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get contextMenuEdit;

  /// No description provided for @contextMenuDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get contextMenuDelete;

  /// No description provided for @contextMenuChangeType.
  ///
  /// In en, this message translates to:
  /// **'Change Type'**
  String get contextMenuChangeType;

  /// No description provided for @deleteConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {item}?'**
  String deleteConfirmationTitle(Object item);

  /// No description provided for @deleteConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this {item} and all its data?'**
  String deleteConfirmationMessage(Object item);

  /// No description provided for @deleteAccountsConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete accounts?'**
  String get deleteAccountsConfirmationTitle;

  /// No description provided for @deleteAccountsConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} selected accounts and their transactions?'**
  String deleteAccountsConfirmationMessage(Object count);

  /// No description provided for @deleteAccountDialogReassign.
  ///
  /// In en, this message translates to:
  /// **'Reassign transactions to another account'**
  String get deleteAccountDialogReassign;

  /// No description provided for @deleteAccountDialogDeleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all associated transactions'**
  String get deleteAccountDialogDeleteAll;

  /// No description provided for @deleteAccountDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'This account may have associated transactions. What would you like to do?'**
  String get deleteAccountDialogMessage;

  /// No description provided for @newAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'New Account'**
  String get newAccountLabel;

  /// No description provided for @warningOverwriteTitle.
  ///
  /// In en, this message translates to:
  /// **'Warning: Overwrite Data?'**
  String get warningOverwriteTitle;

  /// No description provided for @warningOverwriteMessage.
  ///
  /// In en, this message translates to:
  /// **'Restoring a backup will DELETE ALL current data and replace it with the backup. This cannot be undone.'**
  String get warningOverwriteMessage;

  /// No description provided for @restoreOverwriteButton.
  ///
  /// In en, this message translates to:
  /// **'Restore & Overwrite'**
  String get restoreOverwriteButton;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Import completed successfully.'**
  String get importSuccess;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String importFailed(Object error);

  /// No description provided for @deleteCategoriesConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} categories?'**
  String deleteCategoriesConfirmationTitle(Object count);

  /// No description provided for @deleteCategoriesConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the selected categories?'**
  String get deleteCategoriesConfirmationMessage;

  /// No description provided for @changeCategoryTypeDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Category Type'**
  String get changeCategoryTypeDialogTitle;

  /// No description provided for @noCategoriesCreated.
  ///
  /// In en, this message translates to:
  /// **'No categories created yet.'**
  String get noCategoriesCreated;

  /// No description provided for @addCategoryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get addCategoryTooltip;

  /// No description provided for @addCategoryDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a new expense or income category'**
  String get addCategoryDescription;

  /// No description provided for @previousPeriodTooltip.
  ///
  /// In en, this message translates to:
  /// **'Previous Period'**
  String get previousPeriodTooltip;

  /// No description provided for @previousPeriodDescription.
  ///
  /// In en, this message translates to:
  /// **'Go to the previous month or year'**
  String get previousPeriodDescription;

  /// No description provided for @nextPeriodTooltip.
  ///
  /// In en, this message translates to:
  /// **'Next Period'**
  String get nextPeriodTooltip;

  /// No description provided for @nextPeriodDescription.
  ///
  /// In en, this message translates to:
  /// **'Go to the next month or year'**
  String get nextPeriodDescription;

  /// No description provided for @filterTooltip.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filterTooltip;

  /// No description provided for @filterCategoriesDescription.
  ///
  /// In en, this message translates to:
  /// **'Filter categories by type (Income/Expense)'**
  String get filterCategoriesDescription;

  /// No description provided for @selectDateTooltip.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDateTooltip;

  /// No description provided for @selectDateDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose a specific date range to view totals'**
  String get selectDateDescription;

  /// No description provided for @sortOrderTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sort Order'**
  String get sortOrderTooltip;

  /// No description provided for @sortOrderDescription.
  ///
  /// In en, this message translates to:
  /// **'Switch between ascending and descending amount order'**
  String get sortOrderDescription;

  /// No description provided for @totalCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Total: {count}'**
  String totalCountLabel(Object count);

  /// No description provided for @closeSelectionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close Selection'**
  String get closeSelectionTooltip;

  /// No description provided for @exitSelectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Exit selection mode'**
  String get exitSelectionDescription;

  /// No description provided for @selectedCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCountLabel(Object count);

  /// No description provided for @categoryNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get categoryNameLabel;

  /// No description provided for @categoriesChangeButton.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get categoriesChangeButton;

  /// No description provided for @parentCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Parent Category'**
  String get parentCategoryLabel;

  /// No description provided for @styleLabel.
  ///
  /// In en, this message translates to:
  /// **'Style (Icon & Color)'**
  String get styleLabel;

  /// No description provided for @typeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get typeLabel;

  /// No description provided for @deleteTransactionsConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Transactions'**
  String get deleteTransactionsConfirmationTitle;

  /// No description provided for @deleteTransactionsConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {count} selected transactions?'**
  String deleteTransactionsConfirmationMessage(Object count);

  /// No description provided for @changeDateTooltip.
  ///
  /// In en, this message translates to:
  /// **'Change Date'**
  String get changeDateTooltip;

  /// No description provided for @changeDateDescription.
  ///
  /// In en, this message translates to:
  /// **'Update the date for all selected transactions'**
  String get changeDateDescription;

  /// No description provided for @changeCategoryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Change Category'**
  String get changeCategoryTooltip;

  /// No description provided for @changeCategoryDescription.
  ///
  /// In en, this message translates to:
  /// **'Update the category for all selected transactions'**
  String get changeCategoryDescription;

  /// No description provided for @deleteTransactionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete Selected'**
  String get deleteTransactionsTooltip;

  /// No description provided for @deleteTransactionsDescription.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete all selected transactions'**
  String get deleteTransactionsDescription;

  /// No description provided for @exitTransactionsSelectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Exit transaction selection mode'**
  String get exitTransactionsSelectionDescription;

  /// No description provided for @quantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Qty: {quantity}'**
  String quantityLabel(Object quantity);

  /// No description provided for @addTransactionTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get addTransactionTitle;

  /// No description provided for @editTransactionTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Transaction'**
  String get editTransactionTitle;

  /// No description provided for @newTransferTitle.
  ///
  /// In en, this message translates to:
  /// **'New Transfer'**
  String get newTransferTitle;

  /// No description provided for @editTransferTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Transfer'**
  String get editTransferTitle;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @descriptionOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get descriptionOptionalLabel;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @quantityFormLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityFormLabel;

  /// No description provided for @selectAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Account'**
  String get selectAccountTitle;

  /// No description provided for @selectCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get selectCategoryTitle;

  /// No description provided for @selectCurrencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Currency'**
  String get selectCurrencyTitle;

  /// No description provided for @accountLabel.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountLabel;

  /// No description provided for @fromAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'From Account'**
  String get fromAccountLabel;

  /// No description provided for @toAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'To Account'**
  String get toAccountLabel;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @selectDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDateLabel;

  /// No description provided for @swapAccountsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Swap Accounts'**
  String get swapAccountsTooltip;

  /// No description provided for @incomeType.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get incomeType;

  /// No description provided for @expenseType.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expenseType;

  /// No description provided for @failedToLoadData.
  ///
  /// In en, this message translates to:
  /// **'Failed to load data'**
  String get failedToLoadData;

  /// No description provided for @invalidAmountError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get invalidAmountError;

  /// No description provided for @emptyAmountError.
  ///
  /// In en, this message translates to:
  /// **'Please enter an amount'**
  String get emptyAmountError;

  /// No description provided for @selectAccountError.
  ///
  /// In en, this message translates to:
  /// **'Please select an account'**
  String get selectAccountError;

  /// No description provided for @selectCategoryError.
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get selectCategoryError;

  /// No description provided for @selectDateError.
  ///
  /// In en, this message translates to:
  /// **'Please select a date'**
  String get selectDateError;

  /// No description provided for @currencyLockedMessage.
  ///
  /// In en, this message translates to:
  /// **'Locked to From Account currency'**
  String get currencyLockedMessage;

  /// No description provided for @totalValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Value'**
  String get totalValueLabel;

  /// No description provided for @feeLabel.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get feeLabel;

  /// No description provided for @exchangeRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Exchange Rate'**
  String get exchangeRateLabel;

  /// No description provided for @pricePerUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Price per unit'**
  String get pricePerUnitLabel;

  /// No description provided for @buyAction.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get buyAction;

  /// No description provided for @sellAction.
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get sellAction;

  /// No description provided for @transferToDescription.
  ///
  /// In en, this message translates to:
  /// **'Transfer to {accountName}'**
  String transferToDescription(Object accountName);

  /// No description provided for @transferFromDescription.
  ///
  /// In en, this message translates to:
  /// **'Transfer from {accountName}'**
  String transferFromDescription(Object accountName);

  /// No description provided for @buyDescription.
  ///
  /// In en, this message translates to:
  /// **'Buy {assetName}'**
  String buyDescription(Object assetName);

  /// No description provided for @sellDescription.
  ///
  /// In en, this message translates to:
  /// **'Sell {assetName}'**
  String sellDescription(Object assetName);

  /// No description provided for @assetTransferDescription.
  ///
  /// In en, this message translates to:
  /// **'Transfer for {action} {assetName}'**
  String assetTransferDescription(Object action, Object assetName);

  /// No description provided for @swapDirectionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Swap Direction'**
  String get swapDirectionTooltip;

  /// No description provided for @availablePresetsLabel.
  ///
  /// In en, this message translates to:
  /// **'Available Presets:'**
  String get availablePresetsLabel;

  /// No description provided for @updateButton.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateButton;

  /// No description provided for @newPresetButton.
  ///
  /// In en, this message translates to:
  /// **'New Preset'**
  String get newPresetButton;

  /// No description provided for @amountToAddToAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount to Add to Account:'**
  String get amountToAddToAccountLabel;

  /// No description provided for @valueInGlobalLabel.
  ///
  /// In en, this message translates to:
  /// **'Value in Global ({currency}):'**
  String valueInGlobalLabel(Object currency);

  /// No description provided for @feeCommissionLabel.
  ///
  /// In en, this message translates to:
  /// **'Fee (Commission)'**
  String get feeCommissionLabel;

  /// No description provided for @requiredError.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredError;

  /// No description provided for @currentPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Price: {price} {currency}'**
  String currentPriceLabel(Object currency, Object price);

  /// No description provided for @linkedAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Linked Account'**
  String get linkedAccountLabel;

  /// No description provided for @selectLinkedAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Linked Account'**
  String get selectLinkedAccountTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @manageIconsLabel.
  ///
  /// In en, this message translates to:
  /// **'Manage Icons'**
  String get manageIconsLabel;

  /// No description provided for @manageThemeLabel.
  ///
  /// In en, this message translates to:
  /// **'Manage Theme'**
  String get manageThemeLabel;

  /// No description provided for @mainCurrencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Main Currency'**
  String get mainCurrencyLabel;

  /// No description provided for @defaultInflationCountryLabel.
  ///
  /// In en, this message translates to:
  /// **'Default Inflation Country'**
  String get defaultInflationCountryLabel;

  /// No description provided for @persistAdvancedFiltersLabel.
  ///
  /// In en, this message translates to:
  /// **'Persist Advanced Filters'**
  String get persistAdvancedFiltersLabel;

  /// No description provided for @hotKeysLabel.
  ///
  /// In en, this message translates to:
  /// **'Hot Keys'**
  String get hotKeysLabel;

  /// No description provided for @smsImportLabel.
  ///
  /// In en, this message translates to:
  /// **'SMS Import'**
  String get smsImportLabel;

  /// No description provided for @smsImportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Import transactions from bank SMS'**
  String get smsImportSubtitle;

  /// No description provided for @apiManagementLabel.
  ///
  /// In en, this message translates to:
  /// **'API Management'**
  String get apiManagementLabel;

  /// No description provided for @dataLabel.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get dataLabel;

  /// No description provided for @syncSettingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Sync Settings'**
  String get syncSettingsLabel;

  /// No description provided for @syncSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'P2P sync via Syncthing'**
  String get syncSettingsSubtitle;

  /// No description provided for @importDataLabel.
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get importDataLabel;

  /// No description provided for @exportDataLabel.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportDataLabel;

  /// No description provided for @exportFormatMessage.
  ///
  /// In en, this message translates to:
  /// **'Choose format:\n\nJSON: Full backup of all data.\nCSV: Readable report of transactions.'**
  String get exportFormatMessage;

  /// No description provided for @jsonFormat.
  ///
  /// In en, this message translates to:
  /// **'JSON'**
  String get jsonFormat;

  /// No description provided for @csvFormat.
  ///
  /// In en, this message translates to:
  /// **'CSV'**
  String get csvFormat;

  /// No description provided for @importExchangeRatesLabel.
  ///
  /// In en, this message translates to:
  /// **'Import Exchange Rates (CSV/JSON)'**
  String get importExchangeRatesLabel;

  /// No description provided for @resetDataLabel.
  ///
  /// In en, this message translates to:
  /// **'Reset Data to Defaults'**
  String get resetDataLabel;

  /// No description provided for @resetDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This will delete all data and restore default settings.'**
  String get resetDataSubtitle;

  /// No description provided for @debugMenuLabel.
  ///
  /// In en, this message translates to:
  /// **'Debug Menu'**
  String get debugMenuLabel;

  /// No description provided for @debugMenuSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Internal developer tools'**
  String get debugMenuSubtitle;

  /// No description provided for @exportSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Export completed successfully'**
  String get exportSuccessMessage;

  /// No description provided for @exportFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailedMessage(Object error);

  /// No description provided for @importSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Import completed successfully'**
  String get importSuccessMessage;

  /// No description provided for @importFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String importFailedMessage(Object error);

  /// No description provided for @resetDataConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Data?'**
  String get resetDataConfirmationTitle;

  /// No description provided for @resetDataConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'Warning! This will delete ALL your transactions, accounts, and settings.\n\nThe app will be restored to its initial state with default data.\nThis action CANNOT be undone.'**
  String get resetDataConfirmationMessage;

  /// No description provided for @resetEverythingButton.
  ///
  /// In en, this message translates to:
  /// **'Reset Everything'**
  String get resetEverythingButton;

  /// No description provided for @resetSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Data reset and defaults restored.'**
  String get resetSuccessMessage;

  /// No description provided for @resetFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Reset failed: {error}'**
  String resetFailedMessage(Object error);

  /// No description provided for @importParsingStep.
  ///
  /// In en, this message translates to:
  /// **'Parsing CSV files...'**
  String get importParsingStep;

  /// No description provided for @importFetchingRatesStep.
  ///
  /// In en, this message translates to:
  /// **'Fetching exchange rates...'**
  String get importFetchingRatesStep;

  /// No description provided for @importErrorLabel.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String importErrorLabel(Object error);

  /// No description provided for @importOneMoneyLabel.
  ///
  /// In en, this message translates to:
  /// **'Import from OneMoney (CSV)'**
  String get importOneMoneyLabel;

  /// No description provided for @importMyBudgetLabel.
  ///
  /// In en, this message translates to:
  /// **'Import MyBudget Transactions (CSV)'**
  String get importMyBudgetLabel;

  /// No description provided for @restoreBackupLabel.
  ///
  /// In en, this message translates to:
  /// **'Restore Backup (JSON)'**
  String get restoreBackupLabel;

  /// No description provided for @importSelectionHelp.
  ///
  /// In en, this message translates to:
  /// **'Select \'OneMoney\' for migration, \'MyBudget\' for adding transactions, or \'Restore Backup\' to overwrite all data.'**
  String get importSelectionHelp;

  /// No description provided for @importCreateAllNew.
  ///
  /// In en, this message translates to:
  /// **'Create All New'**
  String get importCreateAllNew;

  /// No description provided for @importNewAccountFound.
  ///
  /// In en, this message translates to:
  /// **'New account found: \"{accountName}\"'**
  String importNewAccountFound(Object accountName);

  /// No description provided for @importMapAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Map \"{accountName}\" to...'**
  String importMapAccountTitle(Object accountName);

  /// No description provided for @importMapToExisting.
  ///
  /// In en, this message translates to:
  /// **'Map to Existing'**
  String get importMapToExisting;

  /// No description provided for @importCreateNew.
  ///
  /// In en, this message translates to:
  /// **'Create New'**
  String get importCreateNew;

  /// No description provided for @importNewCategoryFound.
  ///
  /// In en, this message translates to:
  /// **'New category found: \"{categoryName}\"'**
  String importNewCategoryFound(Object categoryName);

  /// No description provided for @importMapCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Map \"{categoryName}\" to...'**
  String importMapCategoryTitle(Object categoryName);

  /// No description provided for @importNewCurrencyFound.
  ///
  /// In en, this message translates to:
  /// **'New currency found: \"{currencyName}\"'**
  String importNewCurrencyFound(Object currencyName);

  /// No description provided for @importMapCurrencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Map \"{currencyName}\" to...'**
  String importMapCurrencyTitle(Object currencyName);

  /// No description provided for @importSkipAll.
  ///
  /// In en, this message translates to:
  /// **'Skip All'**
  String get importSkipAll;

  /// No description provided for @importImportAll.
  ///
  /// In en, this message translates to:
  /// **'Import All'**
  String get importImportAll;

  /// No description provided for @importPotentialDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Potential Duplicate:'**
  String get importPotentialDuplicate;

  /// No description provided for @importDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String importDateLabel(Object date);

  /// No description provided for @importFromLabel.
  ///
  /// In en, this message translates to:
  /// **'From: {from}'**
  String importFromLabel(Object from);

  /// No description provided for @importToLabel.
  ///
  /// In en, this message translates to:
  /// **'To: {to}'**
  String importToLabel(Object to);

  /// No description provided for @importAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount: {amount} {currency}'**
  String importAmountLabel(Object amount, Object currency);

  /// No description provided for @importSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get importSkip;

  /// No description provided for @importImportAnyway.
  ///
  /// In en, this message translates to:
  /// **'Import Anyway'**
  String get importImportAnyway;

  /// No description provided for @importDecisionLabel.
  ///
  /// In en, this message translates to:
  /// **'Decision: {decision}'**
  String importDecisionLabel(Object decision);

  /// No description provided for @importReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready to Import'**
  String get importReadyTitle;

  /// No description provided for @importReadyMessage.
  ///
  /// In en, this message translates to:
  /// **'{count} transactions are ready to be imported.'**
  String importReadyMessage(Object count);

  /// No description provided for @importFinalizeButton.
  ///
  /// In en, this message translates to:
  /// **'Finalize Import'**
  String get importFinalizeButton;

  /// No description provided for @importingTitle.
  ///
  /// In en, this message translates to:
  /// **'Importing...'**
  String get importingTitle;

  /// No description provided for @importCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Complete'**
  String get importCompleteTitle;

  /// No description provided for @importStartOverTooltip.
  ///
  /// In en, this message translates to:
  /// **'Start Over'**
  String get importStartOverTooltip;

  /// No description provided for @importDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get importDataTitle;

  /// No description provided for @importAccountsCreatedLabel.
  ///
  /// In en, this message translates to:
  /// **'New Accounts Created: {count}'**
  String importAccountsCreatedLabel(Object count);

  /// No description provided for @importCategoriesCreatedLabel.
  ///
  /// In en, this message translates to:
  /// **'New Categories Created: {count}'**
  String importCategoriesCreatedLabel(Object count);

  /// No description provided for @importTransactionsImportedLabel.
  ///
  /// In en, this message translates to:
  /// **'Transactions Imported: {count}'**
  String importTransactionsImportedLabel(Object count);

  /// No description provided for @importDuplicatesSkippedLabel.
  ///
  /// In en, this message translates to:
  /// **'Duplicates Skipped: {count}'**
  String importDuplicatesSkippedLabel(Object count);

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchHint;

  /// No description provided for @debugAllDataClearedMessage.
  ///
  /// In en, this message translates to:
  /// **'All data cleared and re-seeded with defaults.'**
  String get debugAllDataClearedMessage;

  /// No description provided for @debugClearAllDataLabel.
  ///
  /// In en, this message translates to:
  /// **'Clear All Data (and re-seed defaults)'**
  String get debugClearAllDataLabel;

  /// No description provided for @debugMinimumDataSeededMessage.
  ///
  /// In en, this message translates to:
  /// **'Minimum data seeded.'**
  String get debugMinimumDataSeededMessage;

  /// No description provided for @debugSeedMinimumDataLabel.
  ///
  /// In en, this message translates to:
  /// **'Seed Minimum Data'**
  String get debugSeedMinimumDataLabel;

  /// No description provided for @debugMediumDataSeededMessage.
  ///
  /// In en, this message translates to:
  /// **'Medium data seeded.'**
  String get debugMediumDataSeededMessage;

  /// No description provided for @debugSeedMediumDataLabel.
  ///
  /// In en, this message translates to:
  /// **'Seed Medium Data'**
  String get debugSeedMediumDataLabel;

  /// No description provided for @debugMaximumDataSeededMessage.
  ///
  /// In en, this message translates to:
  /// **'Maximum data seeded.'**
  String get debugMaximumDataSeededMessage;

  /// No description provided for @debugSeedMaximumDataLabel.
  ///
  /// In en, this message translates to:
  /// **'Seed Maximum Data (for performance test)'**
  String get debugSeedMaximumDataLabel;

  /// No description provided for @debugRunningInDebugModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Running in DEBUG mode'**
  String get debugRunningInDebugModeLabel;

  /// No description provided for @deleteAllButton.
  ///
  /// In en, this message translates to:
  /// **'Delete All'**
  String get deleteAllButton;

  /// No description provided for @changeButton.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeButton;

  /// No description provided for @undoButton.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undoButton;

  /// No description provided for @itemDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} deleted'**
  String itemDeletedMessage(Object name);

  /// No description provided for @totalBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Balance'**
  String get totalBalanceLabel;

  /// No description provided for @noCurrenciesSelected.
  ///
  /// In en, this message translates to:
  /// **'No currencies selected.'**
  String get noCurrenciesSelected;

  /// No description provided for @incomeLabel.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get incomeLabel;

  /// No description provided for @expenseLabel.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expenseLabel;

  /// No description provided for @failedToLoadDashboard.
  ///
  /// In en, this message translates to:
  /// **'Failed to load dashboard'**
  String get failedToLoadDashboard;

  /// No description provided for @dashboardCalendarTab.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get dashboardCalendarTab;

  /// No description provided for @dashboardCalendarTooltip.
  ///
  /// In en, this message translates to:
  /// **'Calendar View'**
  String get dashboardCalendarTooltip;

  /// No description provided for @dashboardCalendarDescription.
  ///
  /// In en, this message translates to:
  /// **'View transactions in a calendar format'**
  String get dashboardCalendarDescription;

  /// No description provided for @dashboardCategoriesTab.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get dashboardCategoriesTab;

  /// No description provided for @dashboardCategoriesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Category Analysis'**
  String get dashboardCategoriesTooltip;

  /// No description provided for @dashboardCategoriesDescription.
  ///
  /// In en, this message translates to:
  /// **'Breakdown of expenses by category'**
  String get dashboardCategoriesDescription;

  /// No description provided for @dashboardBalanceTab.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get dashboardBalanceTab;

  /// No description provided for @dashboardBalanceTooltip.
  ///
  /// In en, this message translates to:
  /// **'Balance History'**
  String get dashboardBalanceTooltip;

  /// No description provided for @dashboardBalanceDescription.
  ///
  /// In en, this message translates to:
  /// **'Track net worth over time'**
  String get dashboardBalanceDescription;

  /// No description provided for @dashboardExpensesLabel.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get dashboardExpensesLabel;

  /// No description provided for @dashboardIncomeLabel.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get dashboardIncomeLabel;

  /// No description provided for @manageIconsTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Icons'**
  String get manageIconsTitle;

  /// No description provided for @noIconsCreated.
  ///
  /// In en, this message translates to:
  /// **'No icons created yet.'**
  String get noIconsCreated;

  /// No description provided for @failedToLoadIcons.
  ///
  /// In en, this message translates to:
  /// **'Failed to load icons.'**
  String get failedToLoadIcons;

  /// No description provided for @cannotDeleteTransferIcon.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete the Transfer icon.'**
  String get cannotDeleteTransferIcon;

  /// No description provided for @deleteIconsDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Icons'**
  String get deleteIconsDialogTitle;

  /// No description provided for @deleteIconsConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {count} selected icons?'**
  String deleteIconsConfirmationMessage(Object count);

  /// No description provided for @deleteIconsWithSkipTransferMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {count} selected icons? (Transfer icon will be skipped)'**
  String deleteIconsWithSkipTransferMessage(Object count);

  /// No description provided for @deleteIconDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Icon'**
  String get deleteIconDialogTitle;

  /// No description provided for @deleteIconConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String deleteIconConfirmationMessage(Object name);

  /// No description provided for @deleteMultipleAccountsTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} accounts?'**
  String deleteMultipleAccountsTitle(Object count);

  /// No description provided for @deleteMultipleAccountsMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the selected accounts? All associated transactions will be deleted.'**
  String get deleteMultipleAccountsMessage;

  /// No description provided for @changeAccountTypeDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Account Type'**
  String get changeAccountTypeDialogTitle;

  /// No description provided for @editAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit: {name}'**
  String editAccountTitle(Object name);

  /// No description provided for @balanceCalculatedFromAsset.
  ///
  /// In en, this message translates to:
  /// **'Balance is calculated from Asset Quantity * Price'**
  String get balanceCalculatedFromAsset;

  /// No description provided for @selectAccountTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Account Type'**
  String get selectAccountTypeTitle;

  /// No description provided for @selectCountryTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Country'**
  String get selectCountryTitle;

  /// No description provided for @selectIconSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select an icon'**
  String get selectIconSubtitle;

  /// No description provided for @bindToAssetLabel.
  ///
  /// In en, this message translates to:
  /// **'Bind to Asset (Optional)'**
  String get bindToAssetLabel;

  /// No description provided for @selectAssetTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Asset'**
  String get selectAssetTitle;

  /// No description provided for @selectedAssetLabel.
  ///
  /// In en, this message translates to:
  /// **'Selected Asset'**
  String get selectedAssetLabel;

  /// No description provided for @balanceAutoCalculatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Balance is calculated automatically'**
  String get balanceAutoCalculatedLabel;

  /// No description provided for @tapToBindAssetLabel.
  ///
  /// In en, this message translates to:
  /// **'Tap to bind an asset'**
  String get tapToBindAssetLabel;

  /// No description provided for @assetQuantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Asset Quantity'**
  String get assetQuantityLabel;

  /// No description provided for @linkedAssetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Linked Assets'**
  String get linkedAssetsTitle;

  /// No description provided for @noneLabel.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get noneLabel;

  /// No description provided for @accountTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Account Type'**
  String get accountTypeLabel;

  /// No description provided for @formValidationPleaseSelectAccountType.
  ///
  /// In en, this message translates to:
  /// **'Please select an account type'**
  String get formValidationPleaseSelectAccountType;

  /// No description provided for @iconLabel.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get iconLabel;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @systemDefaultLabel.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefaultLabel;

  /// No description provided for @selectLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguageTitle;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'bn', 'en', 'es', 'fr', 'hi', 'pt', 'ru', 'ur', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'bn': return AppLocalizationsBn();
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'fr': return AppLocalizationsFr();
    case 'hi': return AppLocalizationsHi();
    case 'pt': return AppLocalizationsPt();
    case 'ru': return AppLocalizationsRu();
    case 'ur': return AppLocalizationsUr();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
