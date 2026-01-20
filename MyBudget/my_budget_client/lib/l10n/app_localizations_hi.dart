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
    return 'शेष: $balance';
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
  String get addAccountDialogTitle => 'नया खाता जोड़ें';

  @override
  String get accountNameHint => 'खाते का नाम';

  @override
  String get initialBalanceHint => 'प्रारंभिक शेष';

  @override
  String get currencyLabel => 'मुद्रा';

  @override
  String get cancelButton => 'रद्द करें';

  @override
  String get saveButton => 'सहेजें';

  @override
  String get formValidationPleaseEnterName => 'कृपया एक नाम दर्ज करें';

  @override
  String get formValidationPleaseEnterBalance => 'कृपया एक शेष राशि दर्ज करें';

  @override
  String get formValidationPleaseEnterValidNumber =>
      'कृपया एक वैध संख्या दर्ज करें';

  @override
  String get formValidationPleaseSelectCurrency =>
      'कृपया एक मुद्रा का चयन करें';

  @override
  String get currencyLoadError => 'मुद्राएं लोड करने में त्रुटि';

  @override
  String get noCurrenciesAvailable => 'कोई मुद्रा उपलब्ध नहीं है';

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
  String get filePickerChooserTitle => 'Select File';

  @override
  String get imagePickerChooserTitle => 'Select Image';
}
