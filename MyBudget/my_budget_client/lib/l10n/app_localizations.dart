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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
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
    Locale('zh'),
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
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'bn',
    'en',
    'es',
    'fr',
    'hi',
    'pt',
    'ru',
    'ur',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'ur':
      return AppLocalizationsUr();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
