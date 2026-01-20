// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

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
  String get accountsEmptyState => 'কোনো অ্যাকাউন্ট নেই';

  @override
  String get accountsRefreshTooltip => 'রিফ্রেশ';

  @override
  String get accountsAddTooltip => 'অ্যাকাউন্ট যোগ করুন';

  @override
  String get addAccountDialogTitle => 'নতুন অ্যাকাউন্ট যোগ করুন';

  @override
  String get accountNameHint => 'অ্যাকাউন্টের নাম';

  @override
  String get initialBalanceHint => 'প্রাথমিক ব্যালেন্স';

  @override
  String get currencyLabel => 'মুদ্রা';

  @override
  String get cancelButton => 'বাতিল করুন';

  @override
  String get saveButton => 'সংরক্ষণ করুন';

  @override
  String get formValidationPleaseEnterName => 'একটি নাম লিখুন';

  @override
  String get formValidationPleaseEnterBalance => 'একটি ব্যালেন্স লিখুন';

  @override
  String get formValidationPleaseEnterValidNumber => 'একটি বৈধ সংখ্যা লিখুন';

  @override
  String get formValidationPleaseSelectCurrency => 'একটি মুদ্রা নির্বাচন করুন';

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
  String get filePickerChooserTitle => 'Select File';

  @override
  String get imagePickerChooserTitle => 'Select Image';
}
