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
  String get formValidationPleaseEnterName => 'Please enter a name';

  @override
  String get formValidationPleaseEnterBalance => 'Please enter a balance';

  @override
  String get formValidationPleaseEnterValidNumber =>
      'Please enter a valid number';

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
}
