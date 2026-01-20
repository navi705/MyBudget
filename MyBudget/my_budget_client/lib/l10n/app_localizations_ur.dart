// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get helloWorld => 'ہیلو ورلڈ!';

  @override
  String get accountsAppBarTitle => 'اکاؤنٹس';

  @override
  String accountsBalanceLabel(Object balance) {
    return 'بیلنس: $balance';
  }

  @override
  String get accountsLoadFailure => 'اکاؤنٹس لوڈ کرنے میں ناکام';

  @override
  String get accountsEmptyState => 'کوئی اکاؤنٹس نہیں';

  @override
  String get accountsRefreshTooltip => 'ریفریش';

  @override
  String get accountsAddTooltip => 'اکاؤنٹ شامل کریں';

  @override
  String get addAccountDialogTitle => 'نیا اکاؤنٹ شامل کریں';

  @override
  String get accountNameHint => 'اکاؤنٹ کا نام';

  @override
  String get initialBalanceHint => 'ابتدائی بیلنس';

  @override
  String get currencyLabel => 'کرنسی';

  @override
  String get cancelButton => 'منسوخ کریں';

  @override
  String get saveButton => 'محفوظ کریں';

  @override
  String get formValidationPleaseEnterName => 'براہ کرم ایک نام درج کریں';

  @override
  String get formValidationPleaseEnterBalance => 'براہ کرم ایک بیلنس درج کریں';

  @override
  String get formValidationPleaseEnterValidNumber =>
      'براہ کرم ایک درست نمبر درج کریں';

  @override
  String get formValidationPleaseSelectCurrency =>
      'براہ کرم ایک کرنسی منتخب کریں';

  @override
  String get currencyLoadError => 'کرنسیاں لوڈ کرنے میں خرابی';

  @override
  String get noCurrenciesAvailable => 'کوئی کرنسی دستیاب نہیں';

  @override
  String get categoriesAppBarTitle => 'اقسام';

  @override
  String get categoriesScreenBody => 'اقسام کی سکرین';

  @override
  String get transactionsAppBarTitle => 'لین دین';

  @override
  String get transactionsScreenBody => 'لین دین کی سکرین';

  @override
  String get settingsAppBarTitle => 'ترتیبات';

  @override
  String get settingsScreenBody => 'ترتیبات کی سکرین';

  @override
  String get filePickerChooserTitle => 'Select File';

  @override
  String get imagePickerChooserTitle => 'Select Image';
}
