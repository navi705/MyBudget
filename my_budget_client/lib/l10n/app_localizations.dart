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

  /// No description provided for @collapseMenuTooltip.
  ///
  /// In en, this message translates to:
  /// **'Collapse Menu'**
  String get collapseMenuTooltip;

  /// No description provided for @expandMenuTooltip.
  ///
  /// In en, this message translates to:
  /// **'Expand Menu'**
  String get expandMenuTooltip;

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

  /// No description provided for @editAccountDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Account'**
  String get editAccountDialogTitle;

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

  /// No description provided for @selectButton.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectButton;

  /// No description provided for @selectAllButton.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAllButton;

  /// No description provided for @deselectAllButton.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get deselectAllButton;

  /// No description provided for @deleteSelectedButton.
  ///
  /// In en, this message translates to:
  /// **'Delete Selected'**
  String get deleteSelectedButton;

  /// No description provided for @totalCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Total: {count}'**
  String totalCountLabel(Object count);

  /// No description provided for @selectedCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCountLabel(Object count);

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

  /// No description provided for @dashboardNetWorthTrend.
  ///
  /// In en, this message translates to:
  /// **'Net Worth Trend'**
  String get dashboardNetWorthTrend;

  /// No description provided for @dashboardWealthDistributionByAccount.
  ///
  /// In en, this message translates to:
  /// **'Wealth Distribution (by Account)'**
  String get dashboardWealthDistributionByAccount;

  /// No description provided for @dashboardCurrencyExposure.
  ///
  /// In en, this message translates to:
  /// **'Currency Exposure'**
  String get dashboardCurrencyExposure;

  /// No description provided for @dashboardNoAccountsFound.
  ///
  /// In en, this message translates to:
  /// **'No accounts found'**
  String get dashboardNoAccountsFound;

  /// No description provided for @dashboardTotalNetWorthTrend.
  ///
  /// In en, this message translates to:
  /// **'Total Net Worth Trend'**
  String get dashboardTotalNetWorthTrend;

  /// No description provided for @dashboardAccountBalanceTrend.
  ///
  /// In en, this message translates to:
  /// **'Account Balance Trend'**
  String get dashboardAccountBalanceTrend;

  /// No description provided for @dashboardWealthDistribution.
  ///
  /// In en, this message translates to:
  /// **'Wealth Distribution'**
  String get dashboardWealthDistribution;

  /// No description provided for @dashboardCurrencyBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Currency Breakdown'**
  String get dashboardCurrencyBreakdown;

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

  /// No description provided for @exitTransactionsSelectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Exit transaction selection mode'**
  String get exitTransactionsSelectionDescription;

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

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @quantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Qty: {quantity}'**
  String quantityLabel(Object quantity);

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

  /// No description provided for @themeSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme Settings'**
  String get themeSettingsTitle;

  /// No description provided for @appearanceSection.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceSection;

  /// No description provided for @themeModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeModeLabel;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemTheme;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// No description provided for @colorCustomizationSection.
  ///
  /// In en, this message translates to:
  /// **'Color Customization'**
  String get colorCustomizationSection;

  /// No description provided for @primaryColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Primary Color'**
  String get primaryColorLabel;

  /// No description provided for @secondaryColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Secondary Color'**
  String get secondaryColorLabel;

  /// No description provided for @surfaceColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Surface Color'**
  String get surfaceColorLabel;

  /// No description provided for @windowEffectsSection.
  ///
  /// In en, this message translates to:
  /// **'Window Effects (Desktop)'**
  String get windowEffectsSection;

  /// No description provided for @enableEffectsLabel.
  ///
  /// In en, this message translates to:
  /// **'Enable Window Effects'**
  String get enableEffectsLabel;

  /// No description provided for @windowEffectLabel.
  ///
  /// In en, this message translates to:
  /// **'Window Effect'**
  String get windowEffectLabel;

  /// No description provided for @backgroundLabel.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get backgroundLabel;

  /// No description provided for @removeBackgroundColor.
  ///
  /// In en, this message translates to:
  /// **'Remove background color'**
  String get removeBackgroundColor;

  /// No description provided for @transparentSurfaceLabel.
  ///
  /// In en, this message translates to:
  /// **'Transparent Surface (Cards)'**
  String get transparentSurfaceLabel;

  /// No description provided for @fullyTransparentLabel.
  ///
  /// In en, this message translates to:
  /// **'Fully Transparent'**
  String get fullyTransparentLabel;

  /// No description provided for @opaqueLabel.
  ///
  /// In en, this message translates to:
  /// **'Opaque'**
  String get opaqueLabel;

  /// No description provided for @opacityLabel.
  ///
  /// In en, this message translates to:
  /// **'Opacity: {value}%'**
  String opacityLabel(Object value);

  /// No description provided for @backgroundSettingsSection.
  ///
  /// In en, this message translates to:
  /// **'Background Settings'**
  String get backgroundSettingsSection;

  /// No description provided for @enableBackgroundImageLabel.
  ///
  /// In en, this message translates to:
  /// **'Enable Background Image'**
  String get enableBackgroundImageLabel;

  /// No description provided for @backgroundBlurLabel.
  ///
  /// In en, this message translates to:
  /// **'Background Blur'**
  String get backgroundBlurLabel;

  /// No description provided for @surfaceGlassStyleTitle.
  ///
  /// In en, this message translates to:
  /// **'Surface/Glass Style'**
  String get surfaceGlassStyleTitle;

  /// No description provided for @chooseImageButton.
  ///
  /// In en, this message translates to:
  /// **'Choose Image'**
  String get chooseImageButton;

  /// No description provided for @selectImageFileError.
  ///
  /// In en, this message translates to:
  /// **'Please select an image file.'**
  String get selectImageFileError;

  /// No description provided for @clearImageButton.
  ///
  /// In en, this message translates to:
  /// **'Clear Image'**
  String get clearImageButton;

  /// No description provided for @saveThemePresetTitle.
  ///
  /// In en, this message translates to:
  /// **'Save Theme Preset'**
  String get saveThemePresetTitle;

  /// No description provided for @presetNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Preset Name'**
  String get presetNameLabel;

  /// No description provided for @presetNameHint.
  ///
  /// In en, this message translates to:
  /// **'My Amazing Theme'**
  String get presetNameHint;

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

  /// No description provided for @apiManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'API Management'**
  String get apiManagementTitle;

  /// Snackbar shown on the API management screen when a fetch or a connection test reports a failure
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String apiErrorLabel(String error);

  /// Subtitle of an API card, carrying the timestamp of the last successful fetch (or the 'None' label when it has never run)
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String apiLastFetchLabel(String date);

  /// No description provided for @apiCategoriesSection.
  ///
  /// In en, this message translates to:
  /// **'API Categories'**
  String get apiCategoriesSection;

  /// No description provided for @manualUtilitiesSection.
  ///
  /// In en, this message translates to:
  /// **'Manual Utilities'**
  String get manualUtilitiesSection;

  /// No description provided for @startupDataSyncLabel.
  ///
  /// In en, this message translates to:
  /// **'Startup Data Sync'**
  String get startupDataSyncLabel;

  /// No description provided for @startupDataSyncDescription.
  ///
  /// In en, this message translates to:
  /// **'Controls both external data fetching and server synchronization on application launch.'**
  String get startupDataSyncDescription;

  /// No description provided for @standardApiLabel.
  ///
  /// In en, this message translates to:
  /// **'Standard API'**
  String get standardApiLabel;

  /// No description provided for @syncOnStartupDescription.
  ///
  /// In en, this message translates to:
  /// **'Sync on startup'**
  String get syncOnStartupDescription;

  /// No description provided for @customSourcesLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom Sources'**
  String get customSourcesLabel;

  /// No description provided for @syncCustomSourcesDescription.
  ///
  /// In en, this message translates to:
  /// **'Sync all {count} on startup'**
  String syncCustomSourcesDescription(Object count);

  /// No description provided for @individualCustomSourcesTitle.
  ///
  /// In en, this message translates to:
  /// **'Individual Custom Sources'**
  String get individualCustomSourcesTitle;

  /// No description provided for @noCustomSourcesAdded.
  ///
  /// In en, this message translates to:
  /// **'No custom sources added.'**
  String get noCustomSourcesAdded;

  /// No description provided for @fetchTodaysRatesButton.
  ///
  /// In en, this message translates to:
  /// **'Fetch Today\'s Rates'**
  String get fetchTodaysRatesButton;

  /// No description provided for @inflationConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'Inflation Config'**
  String get inflationConfigTitle;

  /// No description provided for @countryCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Country Code (e.g. SRB)'**
  String get countryCodeHint;

  /// No description provided for @fetchDataForCountryButton.
  ///
  /// In en, this message translates to:
  /// **'Fetch Data for {country}'**
  String fetchDataForCountryButton(Object country);

  /// No description provided for @steamSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Steam Settings'**
  String get steamSettingsTitle;

  /// No description provided for @steamIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Steam ID (64-bit)'**
  String get steamIdLabel;

  /// Example 64-bit Steam ID shown inside the empty Steam ID field; the digits stay as they are, only the 'e.g.' wording is translated
  ///
  /// In en, this message translates to:
  /// **'e.g. 76561198085715972'**
  String get steamIdHint;

  /// No description provided for @preferredGameLabel.
  ///
  /// In en, this message translates to:
  /// **'Preferred Game'**
  String get preferredGameLabel;

  /// No description provided for @fetchInventoryNowButton.
  ///
  /// In en, this message translates to:
  /// **'Fetch Inventory Now'**
  String get fetchInventoryNowButton;

  /// No description provided for @manualExchangeRatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Manual Exchange Rates Fetch'**
  String get manualExchangeRatesTitle;

  /// No description provided for @selectStartDate.
  ///
  /// In en, this message translates to:
  /// **'Select Start Date'**
  String get selectStartDate;

  /// No description provided for @startDateFrom.
  ///
  /// In en, this message translates to:
  /// **'From: {date}'**
  String startDateFrom(Object date);

  /// No description provided for @selectEndDate.
  ///
  /// In en, this message translates to:
  /// **'Select End Date'**
  String get selectEndDate;

  /// No description provided for @endDateTo.
  ///
  /// In en, this message translates to:
  /// **'To: {date}'**
  String endDateTo(Object date);

  /// No description provided for @fetchRangeButton.
  ///
  /// In en, this message translates to:
  /// **'Fetch Range'**
  String get fetchRangeButton;

  /// No description provided for @manualSteamInventoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Manual Steam Inventory'**
  String get manualSteamInventoryTitle;

  /// No description provided for @selectGameHint.
  ///
  /// In en, this message translates to:
  /// **'Select Game'**
  String get selectGameHint;

  /// No description provided for @fetchValueButton.
  ///
  /// In en, this message translates to:
  /// **'Fetch Value'**
  String get fetchValueButton;

  /// No description provided for @manualInflationDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Manual Inflation Data'**
  String get manualInflationDataTitle;

  /// No description provided for @selectStartYear.
  ///
  /// In en, this message translates to:
  /// **'Select Start Year'**
  String get selectStartYear;

  /// No description provided for @startYearFrom.
  ///
  /// In en, this message translates to:
  /// **'From: {year}'**
  String startYearFrom(Object year);

  /// No description provided for @selectEndYear.
  ///
  /// In en, this message translates to:
  /// **'Select End Year'**
  String get selectEndYear;

  /// No description provided for @endYearTo.
  ///
  /// In en, this message translates to:
  /// **'To: {year}'**
  String endYearTo(Object year);

  /// No description provided for @fetchDataButton.
  ///
  /// In en, this message translates to:
  /// **'Fetch Data'**
  String get fetchDataButton;

  /// No description provided for @connectionOk.
  ///
  /// In en, this message translates to:
  /// **'Connection OK'**
  String get connectionOk;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection Failed'**
  String get connectionFailed;

  /// No description provided for @testConnectionButton.
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get testConnectionButton;

  /// No description provided for @editCustomSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Custom Source'**
  String get editCustomSourceTitle;

  /// No description provided for @addCustomSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Custom Source'**
  String get addCustomSourceTitle;

  /// No description provided for @addressFormatsHelp.
  ///
  /// In en, this message translates to:
  /// **'Address Formats:\n• 192.168.1.10 (IP)\n• localhost or api.my.com\n• http://myserver.com'**
  String get addressFormatsHelp;

  /// Example name shown inside the empty name field of the custom data source dialog
  ///
  /// In en, this message translates to:
  /// **'My Home Server'**
  String get customSourceNameHint;

  /// No description provided for @urlIpLabel.
  ///
  /// In en, this message translates to:
  /// **'URL / IP'**
  String get urlIpLabel;

  /// No description provided for @urlIpHint.
  ///
  /// In en, this message translates to:
  /// **'192.168.1.10:8080'**
  String get urlIpHint;

  /// No description provided for @dataTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Data Type'**
  String get dataTypeLabel;

  /// No description provided for @apiTitleExchangeRates.
  ///
  /// In en, this message translates to:
  /// **'Exchange Rates'**
  String get apiTitleExchangeRates;

  /// No description provided for @apiTitleInflation.
  ///
  /// In en, this message translates to:
  /// **'Inflation'**
  String get apiTitleInflation;

  /// No description provided for @apiTitleAssetPrices.
  ///
  /// In en, this message translates to:
  /// **'Asset Prices'**
  String get apiTitleAssetPrices;

  /// No description provided for @apiTitleSteamInventory.
  ///
  /// In en, this message translates to:
  /// **'Steam Inventory'**
  String get apiTitleSteamInventory;

  /// No description provided for @transferLabel.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transferLabel;

  /// No description provided for @uncategorizedLabel.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get uncategorizedLabel;

  /// No description provided for @defaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultLabel;

  /// No description provided for @receivedTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Received: {total}'**
  String receivedTotalLabel(Object total);

  /// No description provided for @spentTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Spent: {total}'**
  String spentTotalLabel(Object total);

  /// No description provided for @periodSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Period Summary'**
  String get periodSummaryTitle;

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

  /// No description provided for @netLabel.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get netLabel;

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

  /// No description provided for @dashboardTabCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get dashboardTabCalendar;

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

  /// No description provided for @dashboardTabCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get dashboardTabCategories;

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

  /// No description provided for @dashboardTabBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get dashboardTabBalance;

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

  /// No description provided for @manageStylesDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Icons'**
  String get manageStylesDeleteTitle;

  /// No description provided for @manageStylesDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {count} selected icons?'**
  String manageStylesDeleteConfirm(Object count);

  /// No description provided for @manageStylesDeleteConfirmWithTransfer.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {count} selected icons? (Transfer icon will be skipped)'**
  String manageStylesDeleteConfirmWithTransfer(Object count);

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

  /// No description provided for @dashboardLabel.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardLabel;

  /// No description provided for @homeLabel.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeLabel;

  /// No description provided for @historyLabel.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyLabel;

  /// No description provided for @syncScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Synchronization Settings'**
  String get syncScreenTitle;

  /// No description provided for @syncP2PSection.
  ///
  /// In en, this message translates to:
  /// **'P2P Synchronization (Syncthing)'**
  String get syncP2PSection;

  /// No description provided for @syncEnableP2P.
  ///
  /// In en, this message translates to:
  /// **'Enable P2P Sync'**
  String get syncEnableP2P;

  /// No description provided for @syncP2PSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sync via .sync files in a shared folder'**
  String get syncP2PSubtitle;

  /// No description provided for @syncFolderLabel.
  ///
  /// In en, this message translates to:
  /// **'Sync Folder'**
  String get syncFolderLabel;

  /// No description provided for @syncFolderNotSelected.
  ///
  /// In en, this message translates to:
  /// **'Not selected'**
  String get syncFolderNotSelected;

  /// No description provided for @syncBrowseButton.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get syncBrowseButton;

  /// No description provided for @syncClearFilesButton.
  ///
  /// In en, this message translates to:
  /// **'Clear sync files'**
  String get syncClearFilesButton;

  /// No description provided for @syncServerSection.
  ///
  /// In en, this message translates to:
  /// **'Cloud Synchronization (Server)'**
  String get syncServerSection;

  /// No description provided for @syncServerUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get syncServerUrlLabel;

  /// No description provided for @syncApiTokenLabel.
  ///
  /// In en, this message translates to:
  /// **'API Token'**
  String get syncApiTokenLabel;

  /// No description provided for @syncApiTokenHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your security token'**
  String get syncApiTokenHint;

  /// No description provided for @syncApiTokenHelp.
  ///
  /// In en, this message translates to:
  /// **'This token is your shared secret. Enter the same value on all your devices to authorize synchronization.'**
  String get syncApiTokenHelp;

  /// No description provided for @syncTestConnectionButton.
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get syncTestConnectionButton;

  /// No description provided for @syncTestingLabel.
  ///
  /// In en, this message translates to:
  /// **'Testing...'**
  String get syncTestingLabel;

  /// No description provided for @syncSaveServerSettingsButton.
  ///
  /// In en, this message translates to:
  /// **'Save Server Settings'**
  String get syncSaveServerSettingsButton;

  /// No description provided for @syncEnableServer.
  ///
  /// In en, this message translates to:
  /// **'Enable Server Sync'**
  String get syncEnableServer;

  /// No description provided for @syncServerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sync with a MyBudget Server instance'**
  String get syncServerSubtitle;

  /// No description provided for @syncPendingLocalChanges.
  ///
  /// In en, this message translates to:
  /// **'Pending local changes:'**
  String get syncPendingLocalChanges;

  /// No description provided for @syncSyncNowButton.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncSyncNowButton;

  /// No description provided for @syncSyncingLabel.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncSyncingLabel;

  /// No description provided for @syncWebNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Synchronization is not available on Web'**
  String get syncWebNotAvailable;

  /// No description provided for @syncPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Storage permission required for sync. Please enable \"All files access\" in settings.'**
  String get syncPermissionRequired;

  /// No description provided for @syncSelectFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Syncthing Folder'**
  String get syncSelectFolderTitle;

  /// No description provided for @syncClearFilesTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Sync Files'**
  String get syncClearFilesTitle;

  /// No description provided for @syncClearFilesConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will delete all .sync files from the selected folder. This action cannot be undone.'**
  String get syncClearFilesConfirm;

  /// No description provided for @syncDeletedFilesCount.
  ///
  /// In en, this message translates to:
  /// **'Deleted {count} sync files'**
  String syncDeletedFilesCount(Object count);

  /// No description provided for @syncClearFilesError.
  ///
  /// In en, this message translates to:
  /// **'Error clearing files: {error}'**
  String syncClearFilesError(Object error);

  /// No description provided for @syncSettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Server settings saved'**
  String get syncSettingsSaved;

  /// No description provided for @syncConnectionSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Connection successful!'**
  String get syncConnectionSuccessful;

  /// No description provided for @syncConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed. Check URL and Token.'**
  String get syncConnectionFailed;

  /// No description provided for @syncConnectionUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Token rejected by the server. Check the token, not the address.'**
  String get syncConnectionUnauthorized;

  /// No description provided for @syncServerNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'The server has no sync token configured and is refusing every device. Set SYNC_TOKEN on the server and use the same value here.'**
  String get syncServerNotConfigured;

  /// No description provided for @syncCompleted.
  ///
  /// In en, this message translates to:
  /// **'Sync completed successfully'**
  String get syncCompleted;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed: {error}'**
  String syncFailed(Object error);

  /// No description provided for @smsRuleAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Rule'**
  String get smsRuleAddTitle;

  /// No description provided for @smsRuleEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Rule'**
  String get smsRuleEditTitle;

  /// No description provided for @smsRuleTransactionType.
  ///
  /// In en, this message translates to:
  /// **'Transaction Type'**
  String get smsRuleTransactionType;

  /// No description provided for @smsRuleMatchPattern.
  ///
  /// In en, this message translates to:
  /// **'Match Pattern (Regex)'**
  String get smsRuleMatchPattern;

  /// No description provided for @smsRuleMatchPatternHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Placanje.*karticom'**
  String get smsRuleMatchPatternHint;

  /// No description provided for @smsRuleMatchPatternHelp.
  ///
  /// In en, this message translates to:
  /// **'Pattern to identify this SMS type'**
  String get smsRuleMatchPatternHelp;

  /// No description provided for @smsRuleAmountPattern.
  ///
  /// In en, this message translates to:
  /// **'Amount Pattern (Regex)'**
  String get smsRuleAmountPattern;

  /// No description provided for @smsRuleAmountPatternHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., iznos\\s+([\\d,.]+)'**
  String get smsRuleAmountPatternHint;

  /// No description provided for @smsRuleAmountPatternHelp.
  ///
  /// In en, this message translates to:
  /// **'Group 1 should capture the amount'**
  String get smsRuleAmountPatternHelp;

  /// No description provided for @smsRuleCurrencyPattern.
  ///
  /// In en, this message translates to:
  /// **'Currency Pattern (Regex, optional)'**
  String get smsRuleCurrencyPattern;

  /// No description provided for @smsRuleCurrencyPatternHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., [\\d,.]+\\s*(\\w\\w\\w)'**
  String get smsRuleCurrencyPatternHint;

  /// No description provided for @smsRuleCurrencyPatternHelp.
  ///
  /// In en, this message translates to:
  /// **'Group 1 should capture currency code'**
  String get smsRuleCurrencyPatternHelp;

  /// No description provided for @smsRuleTestTitle.
  ///
  /// In en, this message translates to:
  /// **'Test Your Rule'**
  String get smsRuleTestTitle;

  /// No description provided for @smsRuleTestSmsHint.
  ///
  /// In en, this message translates to:
  /// **'Paste SMS text here'**
  String get smsRuleTestSmsHint;

  /// No description provided for @smsRuleTestButton.
  ///
  /// In en, this message translates to:
  /// **'Test Pattern'**
  String get smsRuleTestButton;

  /// No description provided for @smsRuleTestEnterSmsError.
  ///
  /// In en, this message translates to:
  /// **'Enter SMS text to test'**
  String get smsRuleTestEnterSmsError;

  /// No description provided for @smsRuleTestMatchError.
  ///
  /// In en, this message translates to:
  /// **'✗ Match pattern did not find a match'**
  String get smsRuleTestMatchError;

  /// No description provided for @smsRuleTestAmountError.
  ///
  /// In en, this message translates to:
  /// **'✗ Amount pattern did not find a match'**
  String get smsRuleTestAmountError;

  /// No description provided for @smsRuleTestSuccess.
  ///
  /// In en, this message translates to:
  /// **'✓ Match found!\nType: {type}\nAmount: {amount}\nCurrency: {currency}'**
  String smsRuleTestSuccess(Object amount, Object currency, Object type);

  /// No description provided for @smsRuleTestRegexError.
  ///
  /// In en, this message translates to:
  /// **'✗ Invalid regex: {error}'**
  String smsRuleTestRegexError(Object error);

  /// No description provided for @smsRuleRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Match and Amount patterns are required'**
  String get smsRuleRequiredError;

  /// No description provided for @inflationError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String inflationError(Object error);

  /// No description provided for @inflationNoRatesFound.
  ///
  /// In en, this message translates to:
  /// **'No inflation rates found.'**
  String get inflationNoRatesFound;

  /// No description provided for @inflationAddRate.
  ///
  /// In en, this message translates to:
  /// **'Add Inflation Rate'**
  String get inflationAddRate;

  /// No description provided for @inflationDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Rates?'**
  String get inflationDeleteConfirmTitle;

  /// No description provided for @inflationDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {count, plural, =1{this rate} other{{count} rates}}?'**
  String inflationDeleteConfirmMessage(num count);

  /// No description provided for @inflationSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String inflationSelectedCount(Object count);

  /// No description provided for @inflationFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Inflation Filters'**
  String get inflationFiltersTitle;

  /// No description provided for @inflationCountries.
  ///
  /// In en, this message translates to:
  /// **'Countries'**
  String get inflationCountries;

  /// No description provided for @inflationPresets.
  ///
  /// In en, this message translates to:
  /// **'Presets'**
  String get inflationPresets;

  /// No description provided for @deleteCategoryConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteCategoryConfirmTitle(Object name);

  /// No description provided for @deleteCategoryMessage.
  ///
  /// In en, this message translates to:
  /// **'This category has associated transactions. What would you like to do?'**
  String get deleteCategoryMessage;

  /// No description provided for @deleteCategoryReassign.
  ///
  /// In en, this message translates to:
  /// **'Reassign transactions to another category'**
  String get deleteCategoryReassign;

  /// No description provided for @deleteCategoryNewCategory.
  ///
  /// In en, this message translates to:
  /// **'New Category'**
  String get deleteCategoryNewCategory;

  /// No description provided for @deleteCategoryDeleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all associated transactions'**
  String get deleteCategoryDeleteAll;

  /// No description provided for @deleteAccountConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteAccountConfirmTitle(Object name);

  /// No description provided for @deleteAccountMessage.
  ///
  /// In en, this message translates to:
  /// **'This account may have associated transactions. What would you like to do?'**
  String get deleteAccountMessage;

  /// No description provided for @deleteAccountReassign.
  ///
  /// In en, this message translates to:
  /// **'Reassign transactions to another account'**
  String get deleteAccountReassign;

  /// No description provided for @deleteAccountNewAccount.
  ///
  /// In en, this message translates to:
  /// **'New Account'**
  String get deleteAccountNewAccount;

  /// No description provided for @deleteAccountDeleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all associated transactions'**
  String get deleteAccountDeleteAll;

  /// No description provided for @confirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmButton;

  /// No description provided for @okButton.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get okButton;

  /// No description provided for @noItemsFound.
  ///
  /// In en, this message translates to:
  /// **'No items found.'**
  String get noItemsFound;

  /// No description provided for @noDataForPeriod.
  ///
  /// In en, this message translates to:
  /// **'No data for this period'**
  String get noDataForPeriod;

  /// No description provided for @noDataForRange.
  ///
  /// In en, this message translates to:
  /// **'No data for this range'**
  String get noDataForRange;

  /// No description provided for @noHistoryData.
  ///
  /// In en, this message translates to:
  /// **'No history data available'**
  String get noHistoryData;

  /// No description provided for @disabledByGlobalSync.
  ///
  /// In en, this message translates to:
  /// **'Disabled by Global Sync'**
  String get disabledByGlobalSync;

  /// No description provided for @dateCreatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Date created: {date}'**
  String dateCreatedLabel(Object date);

  /// No description provided for @anyLabel.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get anyLabel;

  /// No description provided for @balanceDisplayLabel.
  ///
  /// In en, this message translates to:
  /// **'Balance Display'**
  String get balanceDisplayLabel;

  /// No description provided for @currenciesActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 currency active} other{{count} currencies active}}'**
  String currenciesActiveLabel(num count);

  /// No description provided for @searchCountryLabel.
  ///
  /// In en, this message translates to:
  /// **'Search Country'**
  String get searchCountryLabel;

  /// No description provided for @addNewIconLabel.
  ///
  /// In en, this message translates to:
  /// **'Add New Icon'**
  String get addNewIconLabel;

  /// No description provided for @noIconsFoundLabel.
  ///
  /// In en, this message translates to:
  /// **'No icons found'**
  String get noIconsFoundLabel;

  /// No description provided for @addNewStyleLabel.
  ///
  /// In en, this message translates to:
  /// **'Add New Style'**
  String get addNewStyleLabel;

  /// No description provided for @styleNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Style Name'**
  String get styleNameLabel;

  /// No description provided for @pleaseEnterStyleName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a style name'**
  String get pleaseEnterStyleName;

  /// No description provided for @colorLabel.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get colorLabel;

  /// No description provided for @netBalanceMetric.
  ///
  /// In en, this message translates to:
  /// **'Net Bal.'**
  String get netBalanceMetric;

  /// No description provided for @investedMetric.
  ///
  /// In en, this message translates to:
  /// **'Invested'**
  String get investedMetric;

  /// No description provided for @realizedMetric.
  ///
  /// In en, this message translates to:
  /// **'Realized'**
  String get realizedMetric;

  /// No description provided for @feesMetric.
  ///
  /// In en, this message translates to:
  /// **'Fees'**
  String get feesMetric;

  /// No description provided for @persistFiltersLabel.
  ///
  /// In en, this message translates to:
  /// **'Persist Filters'**
  String get persistFiltersLabel;

  /// No description provided for @searchByNameHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name...'**
  String get searchByNameHint;

  /// No description provided for @searchDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Search description...'**
  String get searchDescriptionHint;

  /// No description provided for @advancedFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced Filters'**
  String get advancedFiltersTitle;

  /// No description provided for @transactionTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Transaction Type'**
  String get transactionTypeLabel;

  /// No description provided for @assetFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Asset Filters'**
  String get assetFiltersTitle;

  /// No description provided for @minValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Min Value'**
  String get minValueLabel;

  /// No description provided for @maxValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Max Value'**
  String get maxValueLabel;

  /// No description provided for @assetTypesLabel.
  ///
  /// In en, this message translates to:
  /// **'Asset Types'**
  String get assetTypesLabel;

  /// No description provided for @allLabel.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allLabel;

  /// No description provided for @currenciesLabel.
  ///
  /// In en, this message translates to:
  /// **'Currencies'**
  String get currenciesLabel;

  /// No description provided for @sourcesLabel.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get sourcesLabel;

  /// No description provided for @presetsLabel.
  ///
  /// In en, this message translates to:
  /// **'Presets'**
  String get presetsLabel;

  /// No description provided for @enterCategoryNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter category name'**
  String get enterCategoryNameHint;

  /// No description provided for @selectTypeHint.
  ///
  /// In en, this message translates to:
  /// **'Select Type'**
  String get selectTypeHint;

  /// No description provided for @hotKeysTitle.
  ///
  /// In en, this message translates to:
  /// **'Hot Keys'**
  String get hotKeysTitle;

  /// No description provided for @searchHotkeysHint.
  ///
  /// In en, this message translates to:
  /// **'Search hotkeys...'**
  String get searchHotkeysHint;

  /// No description provided for @noMatchingHotkeys.
  ///
  /// In en, this message translates to:
  /// **'No matching hotkeys found.'**
  String get noMatchingHotkeys;

  /// No description provided for @recordingHotkeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Recording Hotkey for \"{label}\"'**
  String recordingHotkeyTitle(Object label);

  /// No description provided for @pressKeysHint.
  ///
  /// In en, this message translates to:
  /// **'Press keys...'**
  String get pressKeysHint;

  /// No description provided for @pressAnyCombinationHint.
  ///
  /// In en, this message translates to:
  /// **'Press any key combination.'**
  String get pressAnyCombinationHint;

  /// No description provided for @clearSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Clear / Save'**
  String get clearSaveButton;

  /// No description provided for @duplicateHotkeyTooltip.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Hotkey'**
  String get duplicateHotkeyTooltip;

  /// No description provided for @usedByLabel.
  ///
  /// In en, this message translates to:
  /// **'Used by {action}'**
  String usedByLabel(Object action);

  /// No description provided for @hkCategoryNavigation.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get hkCategoryNavigation;

  /// No description provided for @hkCategoryDashboardTabs.
  ///
  /// In en, this message translates to:
  /// **'Dashboard Tabs (Ctrl + 1/2/3)'**
  String get hkCategoryDashboardTabs;

  /// No description provided for @hkCategoryDataTabs.
  ///
  /// In en, this message translates to:
  /// **'Data Tabs (Ctrl + 1/2/3)'**
  String get hkCategoryDataTabs;

  /// No description provided for @hkCategoryPeriodControl.
  ///
  /// In en, this message translates to:
  /// **'Period Control'**
  String get hkCategoryPeriodControl;

  /// No description provided for @hkCategoryActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get hkCategoryActions;

  /// No description provided for @hkCategorySelectionMode.
  ///
  /// In en, this message translates to:
  /// **'Selection Mode'**
  String get hkCategorySelectionMode;

  /// No description provided for @hkActionBack.
  ///
  /// In en, this message translates to:
  /// **'Global: Go Back / Exit'**
  String get hkActionBack;

  /// No description provided for @hkActionDashboard.
  ///
  /// In en, this message translates to:
  /// **'Go to Dashboard'**
  String get hkActionDashboard;

  /// No description provided for @hkActionAccounts.
  ///
  /// In en, this message translates to:
  /// **'Go to Accounts'**
  String get hkActionAccounts;

  /// No description provided for @hkActionTransactions.
  ///
  /// In en, this message translates to:
  /// **'Go to Transactions'**
  String get hkActionTransactions;

  /// No description provided for @hkActionCategories.
  ///
  /// In en, this message translates to:
  /// **'Go to Categories'**
  String get hkActionCategories;

  /// No description provided for @hkActionData.
  ///
  /// In en, this message translates to:
  /// **'Go to Data / Exchange Rates'**
  String get hkActionData;

  /// No description provided for @hkActionSettings.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings'**
  String get hkActionSettings;

  /// No description provided for @hkActionDashboardTab1.
  ///
  /// In en, this message translates to:
  /// **'Calendar Tab'**
  String get hkActionDashboardTab1;

  /// No description provided for @hkActionDashboardTab2.
  ///
  /// In en, this message translates to:
  /// **'Categories Tab'**
  String get hkActionDashboardTab2;

  /// No description provided for @hkActionDashboardTab3.
  ///
  /// In en, this message translates to:
  /// **'Balance Tab'**
  String get hkActionDashboardTab3;

  /// No description provided for @hkActionDataTab1.
  ///
  /// In en, this message translates to:
  /// **'Exchange Rates'**
  String get hkActionDataTab1;

  /// No description provided for @hkActionDataTab2.
  ///
  /// In en, this message translates to:
  /// **'Inflation'**
  String get hkActionDataTab2;

  /// No description provided for @hkActionDataTab3.
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get hkActionDataTab3;

  /// No description provided for @hkActionPrevPeriod.
  ///
  /// In en, this message translates to:
  /// **'Previous Period'**
  String get hkActionPrevPeriod;

  /// No description provided for @hkActionNextPeriod.
  ///
  /// In en, this message translates to:
  /// **'Next Period'**
  String get hkActionNextPeriod;

  /// No description provided for @hkActionAddAction.
  ///
  /// In en, this message translates to:
  /// **'Generic Add Action'**
  String get hkActionAddAction;

  /// No description provided for @hkActionPickDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get hkActionPickDate;

  /// No description provided for @hkActionDashboardSwitchView.
  ///
  /// In en, this message translates to:
  /// **'Dashboard: Change View'**
  String get hkActionDashboardSwitchView;

  /// No description provided for @hkActionSortOrder.
  ///
  /// In en, this message translates to:
  /// **'Sort Order'**
  String get hkActionSortOrder;

  /// No description provided for @hkActionFilterAction.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get hkActionFilterAction;

  /// No description provided for @hkActionDashboardCurrency.
  ///
  /// In en, this message translates to:
  /// **'Dashboard: Currency'**
  String get hkActionDashboardCurrency;

  /// No description provided for @hkActionAccountsSelectionClose.
  ///
  /// In en, this message translates to:
  /// **'Accounts: Close'**
  String get hkActionAccountsSelectionClose;

  /// No description provided for @hkActionAccountsSelectionAll.
  ///
  /// In en, this message translates to:
  /// **'Accounts: Select All'**
  String get hkActionAccountsSelectionAll;

  /// No description provided for @hkActionAccountsSelectionDelete.
  ///
  /// In en, this message translates to:
  /// **'Accounts: Delete'**
  String get hkActionAccountsSelectionDelete;

  /// No description provided for @hkActionAccountsSelectionChangeType.
  ///
  /// In en, this message translates to:
  /// **'Accounts: Change Type'**
  String get hkActionAccountsSelectionChangeType;

  /// No description provided for @hkActionTransactionsSelectionClose.
  ///
  /// In en, this message translates to:
  /// **'Transactions: Close'**
  String get hkActionTransactionsSelectionClose;

  /// No description provided for @hkActionTransactionsSelectionDelete.
  ///
  /// In en, this message translates to:
  /// **'Transactions: Delete'**
  String get hkActionTransactionsSelectionDelete;

  /// No description provided for @hkActionTransactionsSelectionChangeDate.
  ///
  /// In en, this message translates to:
  /// **'Transactions: Change Date'**
  String get hkActionTransactionsSelectionChangeDate;

  /// No description provided for @hkActionTransactionsSelectionChangeCategory.
  ///
  /// In en, this message translates to:
  /// **'Transactions: Change Category'**
  String get hkActionTransactionsSelectionChangeCategory;

  /// No description provided for @hkActionCategoriesSelectionClose.
  ///
  /// In en, this message translates to:
  /// **'Categories: Close'**
  String get hkActionCategoriesSelectionClose;

  /// No description provided for @hkActionCategoriesSelectionAll.
  ///
  /// In en, this message translates to:
  /// **'Categories: Select All'**
  String get hkActionCategoriesSelectionAll;

  /// No description provided for @hkActionCategoriesSelectionDelete.
  ///
  /// In en, this message translates to:
  /// **'Categories: Delete'**
  String get hkActionCategoriesSelectionDelete;

  /// No description provided for @hkActionCategoriesSelectionChangeType.
  ///
  /// In en, this message translates to:
  /// **'Categories: Change Type'**
  String get hkActionCategoriesSelectionChangeType;

  /// No description provided for @hkActionDataSelectionClose.
  ///
  /// In en, this message translates to:
  /// **'Exchange Rates: Close'**
  String get hkActionDataSelectionClose;

  /// No description provided for @hkActionDataSelectionAll.
  ///
  /// In en, this message translates to:
  /// **'Exchange Rates: Select All'**
  String get hkActionDataSelectionAll;

  /// No description provided for @hkActionDataSelectionDelete.
  ///
  /// In en, this message translates to:
  /// **'Exchange Rates: Delete'**
  String get hkActionDataSelectionDelete;

  /// No description provided for @hkActionDataSelectionChangePreset.
  ///
  /// In en, this message translates to:
  /// **'Exchange Rates: Change Preset'**
  String get hkActionDataSelectionChangePreset;

  /// No description provided for @hkActionInflationSelectionClose.
  ///
  /// In en, this message translates to:
  /// **'Inflation: Close'**
  String get hkActionInflationSelectionClose;

  /// No description provided for @hkActionInflationSelectionAll.
  ///
  /// In en, this message translates to:
  /// **'Inflation: Select All'**
  String get hkActionInflationSelectionAll;

  /// No description provided for @hkActionInflationSelectionDelete.
  ///
  /// In en, this message translates to:
  /// **'Inflation: Delete'**
  String get hkActionInflationSelectionDelete;

  /// No description provided for @hkActionAssetSelectionClose.
  ///
  /// In en, this message translates to:
  /// **'Assets: Close'**
  String get hkActionAssetSelectionClose;

  /// No description provided for @hkActionAssetSelectionAll.
  ///
  /// In en, this message translates to:
  /// **'Assets: Select All'**
  String get hkActionAssetSelectionAll;

  /// No description provided for @hkActionAssetSelectionDelete.
  ///
  /// In en, this message translates to:
  /// **'Assets: Delete'**
  String get hkActionAssetSelectionDelete;

  /// No description provided for @styNotFound.
  ///
  /// In en, this message translates to:
  /// **'Style not found.'**
  String get styNotFound;

  /// No description provided for @stySaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get stySaveChanges;

  /// No description provided for @styAddIcon.
  ///
  /// In en, this message translates to:
  /// **'Add Icon'**
  String get styAddIcon;

  /// No description provided for @smsOnlyAndroid.
  ///
  /// In en, this message translates to:
  /// **'SMS import is only available on Android'**
  String get smsOnlyAndroid;

  /// No description provided for @smsImportSms.
  ///
  /// In en, this message translates to:
  /// **'Import SMS'**
  String get smsImportSms;

  /// No description provided for @smsPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'SMS Permission Required'**
  String get smsPermissionRequired;

  /// No description provided for @smsPermissionRationale.
  ///
  /// In en, this message translates to:
  /// **'To import transactions from SMS, we need permission to read your messages.'**
  String get smsPermissionRationale;

  /// No description provided for @smsGrantPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant Permission'**
  String get smsGrantPermission;

  /// No description provided for @smsNoPresets.
  ///
  /// In en, this message translates to:
  /// **'No presets configured. Tap + to add one.'**
  String get smsNoPresets;

  /// No description provided for @smsImportDescription.
  ///
  /// In en, this message translates to:
  /// **'Import transactions from SMS messages. Choose a time range:'**
  String get smsImportDescription;

  /// No description provided for @smsLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 Days'**
  String get smsLast7Days;

  /// No description provided for @smsAllTime.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get smsAllTime;

  /// No description provided for @smsFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Filter: {filter}'**
  String smsFilterLabel(Object filter);

  /// No description provided for @smsEditPreset.
  ///
  /// In en, this message translates to:
  /// **'Edit Preset'**
  String get smsEditPreset;

  /// No description provided for @smsNewPreset.
  ///
  /// In en, this message translates to:
  /// **'New Preset'**
  String get smsNewPreset;

  /// No description provided for @smsPresetNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., My Bank'**
  String get smsPresetNameHint;

  /// No description provided for @smsSenderFilter.
  ///
  /// In en, this message translates to:
  /// **'Sender Filter'**
  String get smsSenderFilter;

  /// No description provided for @smsSenderFilterHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., ALTA or +381...'**
  String get smsSenderFilterHint;

  /// No description provided for @smsSenderFilterHelper.
  ///
  /// In en, this message translates to:
  /// **'Filter SMS by sender name or phone number'**
  String get smsSenderFilterHelper;

  /// No description provided for @smsDefaults.
  ///
  /// In en, this message translates to:
  /// **'Defaults'**
  String get smsDefaults;

  /// No description provided for @smsDefaultAccount.
  ///
  /// In en, this message translates to:
  /// **'Default Account'**
  String get smsDefaultAccount;

  /// No description provided for @smsDefaultCategory.
  ///
  /// In en, this message translates to:
  /// **'Default Category'**
  String get smsDefaultCategory;

  /// No description provided for @smsImportMessages.
  ///
  /// In en, this message translates to:
  /// **'Import Messages'**
  String get smsImportMessages;

  /// No description provided for @smsSelectDefaultsFirst.
  ///
  /// In en, this message translates to:
  /// **'Select defaults first'**
  String get smsSelectDefaultsFirst;

  /// No description provided for @smsCustomRange.
  ///
  /// In en, this message translates to:
  /// **'Custom Range'**
  String get smsCustomRange;

  /// No description provided for @smsImportSuccessCount.
  ///
  /// In en, this message translates to:
  /// **'Success: {count} transactions imported'**
  String smsImportSuccessCount(Object count);

  /// No description provided for @smsParsingRules.
  ///
  /// In en, this message translates to:
  /// **'Parsing Rules'**
  String get smsParsingRules;

  /// No description provided for @smsNoRules.
  ///
  /// In en, this message translates to:
  /// **'No rules defined. Tap + to add one.'**
  String get smsNoRules;

  /// No description provided for @smsMatchLabel.
  ///
  /// In en, this message translates to:
  /// **'Match: {pattern}'**
  String smsMatchLabel(Object pattern);

  /// No description provided for @smsNameSenderRequired.
  ///
  /// In en, this message translates to:
  /// **'Name and sender filter are required'**
  String get smsNameSenderRequired;

  /// No description provided for @smsCategoryKeywords.
  ///
  /// In en, this message translates to:
  /// **'Category Keywords'**
  String get smsCategoryKeywords;

  /// No description provided for @smsCategoryKeywordsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Map keywords in SMS body to categories'**
  String get smsCategoryKeywordsSubtitle;

  /// No description provided for @smsNoKeywordRules.
  ///
  /// In en, this message translates to:
  /// **'No keyword rules. Tap + to add one.'**
  String get smsNoKeywordRules;

  /// No description provided for @smsAddKeywordRule.
  ///
  /// In en, this message translates to:
  /// **'Add Keyword Rule'**
  String get smsAddKeywordRule;

  /// No description provided for @smsKeyword.
  ///
  /// In en, this message translates to:
  /// **'Keyword'**
  String get smsKeyword;

  /// No description provided for @smsKeywordHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Grocery, Netflix'**
  String get smsKeywordHint;

  /// No description provided for @smsKeywordHelper.
  ///
  /// In en, this message translates to:
  /// **'Case-insensitive substring to match in SMS body'**
  String get smsKeywordHelper;

  /// No description provided for @smsSelectCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get smsSelectCategoryHint;

  /// No description provided for @dshSelectDateDescription.
  ///
  /// In en, this message translates to:
  /// **'Open calendar to pick a specific date or range'**
  String get dshSelectDateDescription;

  /// No description provided for @dshCurrencyDescription.
  ///
  /// In en, this message translates to:
  /// **'Select the primary currency for display'**
  String get dshCurrencyDescription;

  /// No description provided for @dshChangeViewTooltip.
  ///
  /// In en, this message translates to:
  /// **'Change View'**
  String get dshChangeViewTooltip;

  /// No description provided for @dshChangeViewDescription.
  ///
  /// In en, this message translates to:
  /// **'Switch between Monthly and Yearly views'**
  String get dshChangeViewDescription;

  /// No description provided for @dshMonthlyAbbreviation.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get dshMonthlyAbbreviation;

  /// No description provided for @dshYearlyAbbreviation.
  ///
  /// In en, this message translates to:
  /// **'Y'**
  String get dshYearlyAbbreviation;

  /// No description provided for @dshBalancesOnDate.
  ///
  /// In en, this message translates to:
  /// **'Balances on {date}'**
  String dshBalancesOnDate(Object date);

  /// No description provided for @dshSearchCurrency.
  ///
  /// In en, this message translates to:
  /// **'Search Currency'**
  String get dshSearchCurrency;

  /// No description provided for @dshUnknownCategory.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get dshUnknownCategory;

  /// No description provided for @pckSelectItem.
  ///
  /// In en, this message translates to:
  /// **'Select Item'**
  String get pckSelectItem;

  /// No description provided for @pckSelectItems.
  ///
  /// In en, this message translates to:
  /// **'Select Items'**
  String get pckSelectItems;

  /// No description provided for @pckClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get pckClearAll;

  /// No description provided for @pckSelectIcon.
  ///
  /// In en, this message translates to:
  /// **'Select Icon'**
  String get pckSelectIcon;

  /// No description provided for @pckMaterialIcons.
  ///
  /// In en, this message translates to:
  /// **'Material Icons'**
  String get pckMaterialIcons;

  /// No description provided for @pckCustomIcons.
  ///
  /// In en, this message translates to:
  /// **'Custom Icons'**
  String get pckCustomIcons;

  /// No description provided for @fltAmountFrom.
  ///
  /// In en, this message translates to:
  /// **'Amount From'**
  String get fltAmountFrom;

  /// No description provided for @fltAmountTo.
  ///
  /// In en, this message translates to:
  /// **'Amount To'**
  String get fltAmountTo;

  /// No description provided for @fltSelectRange.
  ///
  /// In en, this message translates to:
  /// **'Select Range'**
  String get fltSelectRange;

  /// No description provided for @fltAdvancedFilterTooltip.
  ///
  /// In en, this message translates to:
  /// **'Advanced Filter'**
  String get fltAdvancedFilterTooltip;

  /// No description provided for @fltAdvancedFilterDescription.
  ///
  /// In en, this message translates to:
  /// **'Filter transactions by account, category, or amount'**
  String get fltAdvancedFilterDescription;

  /// No description provided for @fltSortOrderDescription.
  ///
  /// In en, this message translates to:
  /// **'Toggle between ascending and descending order'**
  String get fltSortOrderDescription;

  /// No description provided for @fltAccountFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Filters'**
  String get fltAccountFiltersTitle;

  /// No description provided for @fltNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fltNameLabel;

  /// No description provided for @fltAccountTypesLabel.
  ///
  /// In en, this message translates to:
  /// **'Account Types'**
  String get fltAccountTypesLabel;

  /// No description provided for @fltFilterCurrenciesLabel.
  ///
  /// In en, this message translates to:
  /// **'Filter Currencies'**
  String get fltFilterCurrenciesLabel;

  /// No description provided for @fltSelectCurrenciesLabel.
  ///
  /// In en, this message translates to:
  /// **'Select Currencies'**
  String get fltSelectCurrenciesLabel;

  /// No description provided for @fltFilterCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter Categories'**
  String get fltFilterCategoriesTitle;

  /// No description provided for @exchAddExchangeRate.
  ///
  /// In en, this message translates to:
  /// **'Add Exchange Rate'**
  String get exchAddExchangeRate;

  /// No description provided for @exchEditExchangeRate.
  ///
  /// In en, this message translates to:
  /// **'Edit Exchange Rate'**
  String get exchEditExchangeRate;

  /// No description provided for @exchAddRateDescription.
  ///
  /// In en, this message translates to:
  /// **'Manually enter a conversion rate between two currencies'**
  String get exchAddRateDescription;

  /// No description provided for @exchNoRatesFound.
  ///
  /// In en, this message translates to:
  /// **'No exchange rates found.'**
  String get exchNoRatesFound;

  /// No description provided for @exchChangePreset.
  ///
  /// In en, this message translates to:
  /// **'Change Preset'**
  String get exchChangePreset;

  /// No description provided for @exchFromCurrency.
  ///
  /// In en, this message translates to:
  /// **'From Currency'**
  String get exchFromCurrency;

  /// No description provided for @exchToCurrency.
  ///
  /// In en, this message translates to:
  /// **'To Currency'**
  String get exchToCurrency;

  /// No description provided for @exchRate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get exchRate;

  /// No description provided for @exchPresetIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Preset ID'**
  String get exchPresetIdLabel;

  /// No description provided for @exchPresetValue.
  ///
  /// In en, this message translates to:
  /// **'Preset: {preset}'**
  String exchPresetValue(Object preset);

  /// No description provided for @exchSelectRange.
  ///
  /// In en, this message translates to:
  /// **'Select Range'**
  String get exchSelectRange;

  /// No description provided for @exchPreviousPeriodDescription.
  ///
  /// In en, this message translates to:
  /// **'Go to the previous day, month, or year'**
  String get exchPreviousPeriodDescription;

  /// No description provided for @exchNextPeriodDescription.
  ///
  /// In en, this message translates to:
  /// **'Go to the next day, month, or year'**
  String get exchNextPeriodDescription;

  /// No description provided for @exchFilterDescription.
  ///
  /// In en, this message translates to:
  /// **'Filter rates by from/to currency and preset ID'**
  String get exchFilterDescription;

  /// No description provided for @exchSelectDateDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose a specific date or range to view historical rates'**
  String get exchSelectDateDescription;

  /// No description provided for @exchSortOrderDescription.
  ///
  /// In en, this message translates to:
  /// **'Switch between ascending and descending date/rate order'**
  String get exchSortOrderDescription;

  /// No description provided for @exchFilterExchangeRates.
  ///
  /// In en, this message translates to:
  /// **'Filter Exchange Rates'**
  String get exchFilterExchangeRates;

  /// No description provided for @exchExitSelectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Exit exchange rate selection mode'**
  String get exchExitSelectionDescription;

  /// No description provided for @exchSelectAllDescription.
  ///
  /// In en, this message translates to:
  /// **'Select all listed exchange rates'**
  String get exchSelectAllDescription;

  /// No description provided for @exchDeselectAllDescription.
  ///
  /// In en, this message translates to:
  /// **'Unselect all rates'**
  String get exchDeselectAllDescription;

  /// No description provided for @exchChangePresetDescription.
  ///
  /// In en, this message translates to:
  /// **'Update the preset ID for all selected exchange rates'**
  String get exchChangePresetDescription;

  /// No description provided for @exchDeleteSelectedDescription.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete all selected exchange rates'**
  String get exchDeleteSelectedDescription;

  /// No description provided for @exchDeleteExchangeRatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Exchange Rates'**
  String get exchDeleteExchangeRatesTitle;

  /// No description provided for @exchDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {count} exchange rates?'**
  String exchDeleteConfirmMessage(Object count);

  /// No description provided for @exchUpdatePresetTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Preset'**
  String get exchUpdatePresetTitle;

  /// No description provided for @exchUpdatePresetMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter the new preset ID for the selected items:'**
  String get exchUpdatePresetMessage;

  /// Warning shown beside dashboard totals when some currencies had no exchange rate path to the selected currency, so their amounts were left out
  ///
  /// In en, this message translates to:
  /// **'{currencies} could not be converted and are not included in the total'**
  String dashboardUnconvertibleCurrencies(String currencies);

  /// Explains the add button on the Transactions screen while no account exists yet: it opens account creation, because the transaction form could not be saved without one
  ///
  /// In en, this message translates to:
  /// **'A transaction needs an account. Create your first one to get started'**
  String get addAccountBeforeTransactionDescription;

  /// Shown inside a single-select picker whose whole list is empty, as opposed to a search that filtered everything out
  ///
  /// In en, this message translates to:
  /// **'There is nothing to choose from yet'**
  String get selectDialogEmptyState;

  /// Shown inside a single-select picker when the list has items but the search text matches none of them
  ///
  /// In en, this message translates to:
  /// **'No matches for your search'**
  String get selectDialogNoMatches;

  /// Label of the confirming button on a dialog that creates a new record, as opposed to updating an existing one
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addButton;

  /// Button on an error placeholder that re-runs the failed load
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// Stand-in shown where a value is missing, for example an error with no message attached
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownLabel;

  /// Name for the worldwide inflation rate, the one used when a record names no specific country
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get globalLabel;

  /// Row in a form showing which date the record is filed under; tapping it opens the date picker
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String dateWithValueLabel(String date);

  /// Title of the colour wheel dialog, naming which of the theme colours is being changed
  ///
  /// In en, this message translates to:
  /// **'Select {label} Color'**
  String selectColorTitle(String label);

  /// Title of the dialog that records a new asset price or quantity, and the label of the button that opens it
  ///
  /// In en, this message translates to:
  /// **'Add Asset Data'**
  String get assetAddTitle;

  /// Title of the same dialog when it is editing an asset record that already exists
  ///
  /// In en, this message translates to:
  /// **'Edit Asset Data'**
  String get assetEditTitle;

  /// Second-level tooltip text explaining what the add button on the assets tab does
  ///
  /// In en, this message translates to:
  /// **'Record value or quantity of a specific asset'**
  String get assetAddDescription;

  /// Field label for the human-readable name of an asset, with an example in brackets
  ///
  /// In en, this message translates to:
  /// **'Asset Name (e.g. Apple Stock)'**
  String get assetNameLabel;

  /// Field label for the ticker or symbol that identifies an asset, with an example in brackets
  ///
  /// In en, this message translates to:
  /// **'Asset ID (e.g. AAPL)'**
  String get assetIdLabel;

  /// Field label for the price of one unit of the asset, as opposed to the total holding value
  ///
  /// In en, this message translates to:
  /// **'Value (Price per unit)'**
  String get assetValueLabel;

  /// Field label for the free-text asset category (stock, crypto, property); may be left blank
  ///
  /// In en, this message translates to:
  /// **'Asset Type (Optional)'**
  String get assetTypeOptionalLabel;

  /// Field label for the account whose balance this asset backs; may be left blank
  ///
  /// In en, this message translates to:
  /// **'Linked Account (Optional)'**
  String get assetLinkedAccountOptionalLabel;

  /// Validation message under the asset name field when it was left empty on save
  ///
  /// In en, this message translates to:
  /// **'Give the asset a name'**
  String get assetNameRequiredError;

  /// Validation message under the asset ID field when it was left empty on save
  ///
  /// In en, this message translates to:
  /// **'Give the asset an ID, for example AAPL'**
  String get assetIdRequiredError;

  /// Validation message under the asset value field when it was empty or could not be parsed as a number
  ///
  /// In en, this message translates to:
  /// **'Enter a number, for example 150.25'**
  String get assetValueInvalidError;

  /// Empty state on the assets tab when no asset record matches the active period and filters
  ///
  /// In en, this message translates to:
  /// **'No assets found.'**
  String get assetNoAssetsFound;

  /// Failure text on the assets tab, shown full-screen while the list is empty and as a snack bar otherwise
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String assetError(String error);

  /// Title of the confirmation dialog shown before asset records are deleted
  ///
  /// In en, this message translates to:
  /// **'Delete Assets?'**
  String get assetDeleteConfirmTitle;

  /// Body of the asset delete confirmation, naming how many records are about to go
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {count, plural, =1{this asset} other{{count} assets}}?'**
  String assetDeleteConfirmMessage(num count);

  /// Second-level tooltip on the delete button of the assets selection app bar, warning the removal is permanent
  ///
  /// In en, this message translates to:
  /// **'Permanently delete all selected asset records'**
  String get assetDeleteSelectedDescription;

  /// Title of the inflation dialog when it is editing a rate that already exists
  ///
  /// In en, this message translates to:
  /// **'Edit Inflation Rate'**
  String get inflationEditRate;

  /// Second-level tooltip text explaining what the add button on the inflation tab does
  ///
  /// In en, this message translates to:
  /// **'Enter a new inflation percentage for a specific date and country'**
  String get inflationAddDescription;

  /// Field label for the inflation rate itself, expressed as a percentage
  ///
  /// In en, this message translates to:
  /// **'Inflation Percent (%)'**
  String get inflationPercentLabel;

  /// Placeholder inside the inflation percent field showing the expected number format
  ///
  /// In en, this message translates to:
  /// **'e.g. 2.5'**
  String get inflationPercentHint;

  /// Validation message under the inflation percent field when it was empty or could not be parsed as a number
  ///
  /// In en, this message translates to:
  /// **'Enter a number, for example 2.5'**
  String get inflationPercentInvalidError;

  /// Row in the inflation dialog while no country is picked, meaning the rate applies worldwide
  ///
  /// In en, this message translates to:
  /// **'Country: Global'**
  String get inflationCountryGlobal;

  /// Row in the inflation dialog naming the country the rate is filed under
  ///
  /// In en, this message translates to:
  /// **'Country: {country}'**
  String inflationCountryNamed(String country);

  /// Tooltip on the button that clears the picked country so the rate applies worldwide again
  ///
  /// In en, this message translates to:
  /// **'Use the worldwide rate'**
  String get inflationUseWorldwideRate;

  /// Tab in the date picker that filters by one date rather than a span of dates
  ///
  /// In en, this message translates to:
  /// **'Single Date'**
  String get pickerSingleDate;

  /// Tab in the date picker that filters by a span between two dates
  ///
  /// In en, this message translates to:
  /// **'Range'**
  String get pickerRange;

  /// Granularity button in the date picker: step through the data one day at a time
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get dateStepDay;

  /// Granularity button in the date picker: step through the data one month at a time
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get dateStepMonth;

  /// Granularity button in the date picker: step through the data one year at a time
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get dateStepYear;

  /// Heading of the editor where an account's fee and tax rules are listed
  ///
  /// In en, this message translates to:
  /// **'Fee Structure'**
  String get feeStructureTitle;

  /// Empty state of the fee editor when the account charges no fees at all
  ///
  /// In en, this message translates to:
  /// **'No fee rules applied.'**
  String get feeNoRulesApplied;

  /// Button that opens the menu of fee rule kinds to append to an account
  ///
  /// In en, this message translates to:
  /// **'Add Fee Rule'**
  String get feeAddRule;

  /// Fee rule that charges the same flat amount regardless of transaction size
  ///
  /// In en, this message translates to:
  /// **'Fixed Fee'**
  String get feeFixedFee;

  /// Fee rule that charges a share of the transaction amount
  ///
  /// In en, this message translates to:
  /// **'Percent Fee'**
  String get feePercentFee;

  /// Fee rule that charges tax on the gain over a cost basis
  ///
  /// In en, this message translates to:
  /// **'Tax Rate'**
  String get feeTaxRate;

  /// Fallback heading for a stored fee rule of a kind this build does not recognise
  ///
  /// In en, this message translates to:
  /// **'Unknown Rule'**
  String get feeUnknownRule;

  /// Field label for the share charged by a percent fee rule
  ///
  /// In en, this message translates to:
  /// **'Rate (%)'**
  String get feeRatePercentLabel;

  /// Field label for the share charged by a tax rule
  ///
  /// In en, this message translates to:
  /// **'Tax Rate (%)'**
  String get feeTaxRatePercentLabel;

  /// Field label for the amount a tax rule subtracts before taxing the remainder
  ///
  /// In en, this message translates to:
  /// **'Cost Basis'**
  String get feeCostBasisLabel;

  /// Title of the confirmation shown before deleting several selected accounts at once
  ///
  /// In en, this message translates to:
  /// **'Delete {count, plural, =1{this account} other{{count} accounts}}?'**
  String deleteAccountsConfirmTitle(num count);

  /// Body of the bulk account delete confirmation, warning that the transactions go too
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the selected accounts? All associated transactions will be deleted.'**
  String get deleteAccountsConfirmMessage;

  /// Title of the dialog that reassigns the account type of several selected accounts
  ///
  /// In en, this message translates to:
  /// **'Change Account Type'**
  String get changeAccountTypeTitle;

  /// Second-level tooltip on the accounts app bar's back arrow, which steps the balance date back
  ///
  /// In en, this message translates to:
  /// **'Go to the previous month or year'**
  String get accountsPreviousPeriodDescription;

  /// Second-level tooltip on the accounts app bar's forward arrow, which steps the balance date on
  ///
  /// In en, this message translates to:
  /// **'Go to the next month or year'**
  String get accountsNextPeriodDescription;

  /// Second-level tooltip on the accounts filter button
  ///
  /// In en, this message translates to:
  /// **'Filter accounts by type or hidden status'**
  String get accountsFilterDescription;

  /// Second-level tooltip on the accounts date button, which shows balances as of a chosen day
  ///
  /// In en, this message translates to:
  /// **'Choose a specific date to view historical balances'**
  String get accountsSelectDateDescription;

  /// Second-level tooltip on the accounts sort button, which flips the balance ordering
  ///
  /// In en, this message translates to:
  /// **'Switch between ascending and descending balance order'**
  String get accountsSortDescription;

  /// Field label on the SMS rule builder for the category this rule forces, which may be left unset
  ///
  /// In en, this message translates to:
  /// **'Category (optional)'**
  String get smsRuleCategoryOptional;

  /// Helper text under the SMS rule category field explaining that it overrides the parsed category
  ///
  /// In en, this message translates to:
  /// **'Override category for this rule'**
  String get smsRuleCategoryHelp;
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
