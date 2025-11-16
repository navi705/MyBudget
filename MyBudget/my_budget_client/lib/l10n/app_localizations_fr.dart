// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get helloWorld => 'Bonjour le monde!';

  @override
  String get accountsAppBarTitle => 'Comptes';

  @override
  String accountsBalanceLabel(Object balance) {
    return 'Solde: $balance';
  }

  @override
  String get accountsLoadFailure => 'Échec du chargement des comptes';

  @override
  String get accountsEmptyState => 'Aucun compte';

  @override
  String get accountsRefreshTooltip => 'Actualiser';

  @override
  String get accountsAddTooltip => 'Ajouter un compte';

  @override
  String get addAccountDialogTitle => 'Ajouter un nouveau compte';

  @override
  String get accountNameHint => 'Nom du compte';

  @override
  String get initialBalanceHint => 'Solde initial';

  @override
  String get currencyLabel => 'Devise';

  @override
  String get cancelButton => 'Annuler';

  @override
  String get saveButton => 'Enregistrer';

  @override
  String get formValidationPleaseEnterName => 'Veuillez entrer un nom';

  @override
  String get formValidationPleaseEnterBalance => 'Veuillez entrer un solde';

  @override
  String get formValidationPleaseEnterValidNumber =>
      'Veuillez entrer un nombre valide';

  @override
  String get formValidationPleaseSelectCurrency =>
      'Veuillez sélectionner une devise';

  @override
  String get currencyLoadError => 'Erreur de chargement des devises';

  @override
  String get noCurrenciesAvailable => 'Aucune devise disponible';

  @override
  String get categoriesAppBarTitle => 'Catégories';

  @override
  String get categoriesScreenBody => 'Écran Catégories';

  @override
  String get transactionsAppBarTitle => 'Transactions';

  @override
  String get transactionsScreenBody => 'Écran Transactions';

  @override
  String get settingsAppBarTitle => 'Paramètres';

  @override
  String get settingsScreenBody => 'Écran Paramètres';
}
