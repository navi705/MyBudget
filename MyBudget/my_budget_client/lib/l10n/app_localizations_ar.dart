// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get helloWorld => 'أهلاً بالعالم!';

  @override
  String get accountsAppBarTitle => 'الحسابات';

  @override
  String accountsBalanceLabel(Object balance) {
    return 'الرصيد: $balance';
  }

  @override
  String get accountsLoadFailure => 'فشل تحميل الحسابات';

  @override
  String get accountsEmptyState => 'لا توجد حسابات';

  @override
  String get accountsRefreshTooltip => 'تحديث';

  @override
  String get accountsAddTooltip => 'إضافة حساب';

  @override
  String get addAccountDialogTitle => 'إضافة حساب جديد';

  @override
  String get accountNameHint => 'اسم الحساب';

  @override
  String get initialBalanceHint => 'الرصيد الأولي';

  @override
  String get currencyLabel => 'العملة';

  @override
  String get cancelButton => 'إلغاء';

  @override
  String get saveButton => 'حفظ';

  @override
  String get formValidationPleaseEnterName => 'الرجاء إدخال اسم';

  @override
  String get formValidationPleaseEnterBalance => 'الرجاء إدخال رصيد';

  @override
  String get formValidationPleaseEnterValidNumber => 'الرجاء إدخال رقم صحيح';

  @override
  String get formValidationPleaseSelectCurrency => 'الرجاء اختيار عملة';

  @override
  String get currencyLoadError => 'خطأ في تحميل العملات';

  @override
  String get noCurrenciesAvailable => 'لا توجد عملات متاحة';

  @override
  String get categoriesAppBarTitle => 'الفئات';

  @override
  String get categoriesScreenBody => 'شاشة الفئات';

  @override
  String get transactionsAppBarTitle => 'المعاملات';

  @override
  String get transactionsScreenBody => 'شاشة المعاملات';

  @override
  String get settingsAppBarTitle => 'الإعدادات';

  @override
  String get settingsScreenBody => 'شاشة الإعدادات';
}
