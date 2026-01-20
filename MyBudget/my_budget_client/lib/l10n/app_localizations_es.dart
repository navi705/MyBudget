// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get helloWorld => '¡Hola Mundo!';

  @override
  String get accountsAppBarTitle => 'Cuentas';

  @override
  String accountsBalanceLabel(Object balance) {
    return 'Saldo: $balance';
  }

  @override
  String get accountsLoadFailure => 'Error al cargar las cuentas';

  @override
  String get accountsEmptyState => 'No hay cuentas';

  @override
  String get accountsRefreshTooltip => 'Actualizar';

  @override
  String get accountsAddTooltip => 'Añadir Cuenta';

  @override
  String get addAccountDialogTitle => 'Añadir nueva cuenta';

  @override
  String get accountNameHint => 'Nombre de la cuenta';

  @override
  String get initialBalanceHint => 'Saldo inicial';

  @override
  String get currencyLabel => 'Moneda';

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get saveButton => 'Guardar';

  @override
  String get formValidationPleaseEnterName => 'Por favor, introduce un nombre';

  @override
  String get formValidationPleaseEnterBalance =>
      'Por favor, introduce un saldo';

  @override
  String get formValidationPleaseEnterValidNumber =>
      'Por favor, introduce un número válido';

  @override
  String get formValidationPleaseSelectCurrency =>
      'Por favor, selecciona una moneda';

  @override
  String get currencyLoadError => 'Error al cargar las monedas';

  @override
  String get noCurrenciesAvailable => 'No hay monedas disponibles';

  @override
  String get categoriesAppBarTitle => 'Categorías';

  @override
  String get categoriesScreenBody => 'Pantalla de Categorías';

  @override
  String get transactionsAppBarTitle => 'Transacciones';

  @override
  String get transactionsScreenBody => 'Pantalla de Transacciones';

  @override
  String get settingsAppBarTitle => 'Configuración';

  @override
  String get settingsScreenBody => 'Pantalla de Configuración';

  @override
  String get filePickerChooserTitle => 'Select File';

  @override
  String get imagePickerChooserTitle => 'Select Image';
}
