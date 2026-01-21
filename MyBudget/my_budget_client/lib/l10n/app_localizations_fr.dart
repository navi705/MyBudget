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
  String get addAccountDescription => 'Créer un nouveau compte bancaire, portefeuille ou actif';

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
  String get deleteButton => 'Supprimer';

  @override
  String get editButton => 'Modifier';

  @override
  String get applyButton => 'Appliquer';

  @override
  String get clearButton => 'Effacer';

  @override
  String get formValidationPleaseEnterName => 'Veuillez entrer un nom';

  @override
  String get formValidationPleaseEnterBalance => 'Veuillez entrer un solde';

  @override
  String get formValidationPleaseEnterValidNumber => 'Veuillez entrer un nombre valide';

  @override
  String get formValidationPleaseSelectCurrency => 'Veuillez sélectionner une devise';

  @override
  String get currencyLoadError => 'Erreur lors du chargement des devises';

  @override
  String get noCurrenciesAvailable => 'Aucune devise disponible';

  @override
  String get categoriesAppBarTitle => 'Catégories';

  @override
  String get categoriesScreenBody => 'Écran des Catégories';

  @override
  String get transactionsAppBarTitle => 'Transactions';

  @override
  String get transactionsScreenBody => 'Écran des Transactions';

  @override
  String get settingsAppBarTitle => 'Paramètres';

  @override
  String get settingsScreenBody => 'Écran des Paramètres';

  @override
  String get filePickerChooserTitle => 'Choisir un fichier';

  @override
  String get imagePickerChooserTitle => 'Choisir une image';

  @override
  String get totalNetWorth => 'Valeur Nette Totale';

  @override
  String get currencyBreakdown => 'Répartition par Devise';

  @override
  String get metricBalance => 'Solde';

  @override
  String get metricIncome => 'Revenus';

  @override
  String get metricExpense => 'Dépenses';

  @override
  String get metricReal => 'Réel';

  @override
  String get metricChange => 'Variation';

  @override
  String get contextMenuSelect => 'Sélectionner';

  @override
  String get contextMenuDeselect => 'Désélectionner';

  @override
  String get contextMenuSelectAll => 'Tout sélectionner';

  @override
  String get contextMenuDeselectAll => 'Tout désélectionner';

  @override
  String get contextMenuAddTransaction => 'Ajouter Transaction';

  @override
  String get addTransactionDescription => 'Créer une nouvelle transaction';

  @override
  String get contextMenuTransfer => 'Virement';

  @override
  String get contextMenuEdit => 'Modifier';

  @override
  String get contextMenuDelete => 'Supprimer';

  @override
  String get contextMenuChangeType => 'Changer le type';

  @override
  String deleteConfirmationTitle(Object item) {
    return 'Supprimer $item?';
  }

  @override
  String deleteConfirmationMessage(Object item) {
    return 'Êtes-vous sûr de vouloir supprimer cet $item et toutes ses données?';
  }

  @override
  String get deleteAccountsConfirmationTitle => 'Supprimer les comptes?';

  @override
  String deleteAccountsConfirmationMessage(Object count) {
    return 'Supprimer les $count comptes sélectionnés et leurs transactions?';
  }

  @override
  String get deleteAccountDialogReassign => 'Réassigner les transactions à un autre compte';

  @override
  String get deleteAccountDialogDeleteAll => 'Supprimer toutes les transactions associées';

  @override
  String get deleteAccountDialogMessage => 'Ce compte peut avoir des transactions associées. Que souhaitez-vous faire?';

  @override
  String get newAccountLabel => 'Nouveau Compte';

  @override
  String get warningOverwriteTitle => 'Attention: Écraser les données?';

  @override
  String get warningOverwriteMessage => 'Restaurer une sauvegarde SUPPRIMERA TOUTES les données actuelles et les remplacera par la sauvegarde. Cette action est irréversible.';

  @override
  String get restoreOverwriteButton => 'Restaurer et Écraser';

  @override
  String get importSuccess => 'Importation réussie.';

  @override
  String importFailed(Object error) {
    return 'Échec de l\'importation: $error';
  }

  @override
  String deleteCategoriesConfirmationTitle(Object count) {
    return 'Supprimer $count catégories?';
  }

  @override
  String get deleteCategoriesConfirmationMessage => 'Êtes-vous sûr de vouloir supprimer les catégories sélectionnées?';

  @override
  String get changeCategoryTypeDialogTitle => 'Changer le type de catégorie';

  @override
  String get noCategoriesCreated => 'Aucune catégorie créée pour le moment.';

  @override
  String get addCategoryTooltip => 'Ajouter une catégorie';

  @override
  String get addCategoryDescription => 'Créer une nouvelle catégorie de dépenses ou de revenus';

  @override
  String get previousPeriodTooltip => 'Période Précédente';

  @override
  String get previousPeriodDescription => 'Aller au mois ou à l\'année précédente';

  @override
  String get nextPeriodTooltip => 'Période Suivante';

  @override
  String get nextPeriodDescription => 'Aller au mois ou à l\'année suivante';

  @override
  String get filterTooltip => 'Filtrer';

  @override
  String get filterCategoriesDescription => 'Filtrer les catégories par type (Revenus/Dépenses)';

  @override
  String get selectDateTooltip => 'Sélectionner une date';

  @override
  String get selectDateDescription => 'Choisir une plage de dates spécifique pour voir les totaux';

  @override
  String get sortOrderTooltip => 'Ordre de tri';

  @override
  String get sortOrderDescription => 'Basculer entre l\'ordre croissant et décroissant par montant';

  @override
  String totalCountLabel(Object count) {
    return 'Total: $count';
  }

  @override
  String get closeSelectionTooltip => 'Fermer la sélection';

  @override
  String get exitSelectionDescription => 'Quitter le mode de sélection';

  @override
  String selectedCountLabel(Object count) {
    return '$count sélectionnés';
  }

  @override
  String get categoryNameLabel => 'Nom de la Catégorie';

  @override
  String get categoriesChangeButton => 'Modifier';

  @override
  String get parentCategoryLabel => 'Catégorie Parente';

  @override
  String get styleLabel => 'Style (Icône et Couleur)';

  @override
  String get typeLabel => 'Type';

  @override
  String get deleteTransactionsConfirmationTitle => 'Supprimer les transactions';

  @override
  String deleteTransactionsConfirmationMessage(Object count) {
    return 'Êtes-vous sûr de vouloir supprimer $count transactions sélectionnées?';
  }

  @override
  String get changeDateTooltip => 'Modifier la date';

  @override
  String get changeDateDescription => 'Mettre à jour la date pour toutes les transactions sélectionnées';

  @override
  String get changeCategoryTooltip => 'Changer de catégorie';

  @override
  String get changeCategoryDescription => 'Mettre à jour la catégorie pour toutes les transactions sélectionnées';

  @override
  String get deleteTransactionsTooltip => 'Supprimer la sélection';

  @override
  String get deleteTransactionsDescription => 'Supprimer définitivement toutes les transactions sélectionnées';

  @override
  String get exitTransactionsSelectionDescription => 'Quitter le mode de sélection des transactions';

  @override
  String quantityLabel(Object quantity) {
    return 'Qté: $quantity';
  }

  @override
  String get addTransactionTitle => 'Ajouter une Transaction';

  @override
  String get editTransactionTitle => 'Modifier la Transaction';

  @override
  String get newTransferTitle => 'Nouveau Virement';

  @override
  String get editTransferTitle => 'Modifier le Virement';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get descriptionOptionalLabel => 'Description (Optionnel)';

  @override
  String get amountLabel => 'Montant';

  @override
  String get quantityFormLabel => 'Quantité';

  @override
  String get selectAccountTitle => 'Sélectionner un Compte';

  @override
  String get selectCategoryTitle => 'Sélectionner une Catégorie';

  @override
  String get selectCurrencyTitle => 'Sélectionner une Devise';

  @override
  String get accountLabel => 'Compte';

  @override
  String get fromAccountLabel => 'Depuis le Compte';

  @override
  String get toAccountLabel => 'Vers le Compte';

  @override
  String get categoryLabel => 'Catégorie';

  @override
  String get dateLabel => 'Date';

  @override
  String get selectDateLabel => 'Sélectionner une Date';

  @override
  String get swapAccountsTooltip => 'Échanger les comptes';

  @override
  String get incomeType => 'Revenus';

  @override
  String get expenseType => 'Dépenses';

  @override
  String get failedToLoadData => 'Échec du chargement des données';

  @override
  String get invalidAmountError => 'Veuillez entrer un nombre valide';

  @override
  String get emptyAmountError => 'Veuillez entrer un montant';

  @override
  String get selectAccountError => 'Veuillez sélectionner un compte';

  @override
  String get selectCategoryError => 'Veuillez sélectionner une catégorie';

  @override
  String get selectDateError => 'Veuillez sélectionner une date';

  @override
  String get currencyLockedMessage => 'Verrouillé sur la devise du compte source';

  @override
  String get totalValueLabel => 'Valeur Totale';

  @override
  String get feeLabel => 'Frais';

  @override
  String get exchangeRateLabel => 'Taux de Change';

  @override
  String get pricePerUnitLabel => 'Prix unitaire';

  @override
  String get buyAction => 'Acheter';

  @override
  String get sellAction => 'Vendre';

  @override
  String transferToDescription(Object accountName) {
    return 'Virement vers $accountName';
  }

  @override
  String transferFromDescription(Object accountName) {
    return 'Virement depuis $accountName';
  }

  @override
  String buyDescription(Object assetName) {
    return 'Acheter $assetName';
  }

  @override
  String sellDescription(Object assetName) {
    return 'Vendre $assetName';
  }

  @override
  String assetTransferDescription(Object action, Object assetName) {
    return 'Virement pour $action $assetName';
  }

  @override
  String get swapDirectionTooltip => 'Changer de direction';

  @override
  String get availablePresetsLabel => 'Préréglages disponibles:';

  @override
  String get updateButton => 'Mettre à jour';

  @override
  String get newPresetButton => 'Nouveau Préréglage';

  @override
  String get amountToAddToAccountLabel => 'Montant à ajouter au compte:';

  @override
  String valueInGlobalLabel(Object currency) {
    return 'Valeur en Global ($currency):';
  }

  @override
  String get feeCommissionLabel => 'Frais (Commission)';

  @override
  String get requiredError => 'Requis';

  @override
  String currentPriceLabel(Object currency, Object price) {
    return 'Prix Actuel: $price $currency';
  }

  @override
  String get linkedAccountLabel => 'Compte Lié';

  @override
  String get selectLinkedAccountTitle => 'Sélectionner un Compte Lié';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get manageIconsLabel => 'Gérer les Icônes';

  @override
  String get manageThemeLabel => 'Gérer le Thème';

  @override
  String get mainCurrencyLabel => 'Devise Principale';

  @override
  String get defaultInflationCountryLabel => 'Pays d\'inflation par défaut';

  @override
  String get persistAdvancedFiltersLabel => 'Persister les filtres avancés';

  @override
  String get hotKeysLabel => 'Raccourcis Clavier';

  @override
  String get smsImportLabel => 'Importation SMS';

  @override
  String get smsImportSubtitle => 'Importer des transactions depuis les SMS bancaires';

  @override
  String get apiManagementLabel => 'Gestion API';

  @override
  String get dataLabel => 'Données';

  @override
  String get syncSettingsLabel => 'Paramètres de Sync';

  @override
  String get syncSettingsSubtitle => 'Sync P2P via Syncthing';

  @override
  String get importDataLabel => 'Importer des Données';

  @override
  String get exportDataLabel => 'Exporter des Données';

  @override
  String get exportFormatMessage => 'Choisir le format:\n\nJSON: Sauvegarde complète de toutes les données.\nCSV: Rapport lisible des transactions.';

  @override
  String get jsonFormat => 'JSON';

  @override
  String get csvFormat => 'CSV';

  @override
  String get importExchangeRatesLabel => 'Importer Taux de Change (CSV/JSON)';

  @override
  String get resetDataLabel => 'Réinitialiser les données';

  @override
  String get resetDataSubtitle => 'Ceci supprimera toutes les données et restaurera les paramètres par défaut.';

  @override
  String get debugMenuLabel => 'Menu Débogage';

  @override
  String get debugMenuSubtitle => 'Outils développeurs internes';

  @override
  String get exportSuccessMessage => 'Exportation réussie';

  @override
  String exportFailedMessage(Object error) {
    return 'Échec de l\'exportation: $error';
  }

  @override
  String get importSuccessMessage => 'Importation réussie';

  @override
  String importFailedMessage(Object error) {
    return 'Échec de l\'importation: $error';
  }

  @override
  String get resetDataConfirmationTitle => 'Réinitialiser les données?';

  @override
  String get resetDataConfirmationMessage => 'Attention! Ceci supprimera TOUTES vos transactions, comptes et paramètres.\n\nL\'application sera restaurée à son état initial avec les données par défaut.\nCette action est IRRÉVERSIBLE.';

  @override
  String get resetEverythingButton => 'Tout Réinitialiser';

  @override
  String get resetSuccessMessage => 'Données réinitialisées et paramètres par défaut restaurés.';

  @override
  String resetFailedMessage(Object error) {
    return 'Échec de la réinitialisation: $error';
  }

  @override
  String get importParsingStep => 'Analyse des fichiers CSV...';

  @override
  String get importFetchingRatesStep => 'Récupération des taux de change...';

  @override
  String importErrorLabel(Object error) {
    return 'Erreur: $error';
  }

  @override
  String get importOneMoneyLabel => 'Importer de OneMoney (CSV)';

  @override
  String get importMyBudgetLabel => 'Importer des transactions MyBudget (CSV)';

  @override
  String get restoreBackupLabel => 'Restaurer une sauvegarde (JSON)';

  @override
  String get importSelectionHelp => 'Sélectionnez \'OneMoney\' pour la migration, \'MyBudget\' pour ajouter des transactions, ou \'Restaurer une sauvegarde\' pour écraser toutes les données.';

  @override
  String get importCreateAllNew => 'Créer tout comme nouveau';

  @override
  String importNewAccountFound(Object accountName) {
    return 'Nouveau compte trouvé: \"$accountName\"';
  }

  @override
  String importMapAccountTitle(Object accountName) {
    return 'Mapper \"$accountName\" à...';
  }

  @override
  String get importMapToExisting => 'Mapper à l\'existant';

  @override
  String get importCreateNew => 'Créer un nouveau';

  @override
  String importNewCategoryFound(Object categoryName) {
    return 'Nouvelle catégorie trouvée: \"$categoryName\"';
  }

  @override
  String importMapCategoryTitle(Object categoryName) {
    return 'Mapper \"$categoryName\" à...';
  }

  @override
  String importNewCurrencyFound(Object currencyName) {
    return 'Nouvelle devise trouvée: \"$currencyName\"';
  }

  @override
  String importMapCurrencyTitle(Object currencyName) {
    return 'Mapper \"$currencyName\" à...';
  }

  @override
  String get importSkipAll => 'Tout ignorer';

  @override
  String get importImportAll => 'Tout importer';

  @override
  String get importPotentialDuplicate => 'Doublon potentiel:';

  @override
  String importDateLabel(Object date) {
    return 'Date: $date';
  }

  @override
  String importFromLabel(Object from) {
    return 'De: $from';
  }

  @override
  String importToLabel(Object to) {
    return 'À: $to';
  }

  @override
  String importAmountLabel(Object amount, Object currency) {
    return 'Montant: $amount $currency';
  }

  @override
  String get importSkip => 'Ignorer';

  @override
  String get importImportAnyway => 'Importer quand même';

  @override
  String importDecisionLabel(Object decision) {
    return 'Décision: $decision';
  }

  @override
  String get importReadyTitle => 'Prêt à importer';

  @override
  String importReadyMessage(Object count) {
    return '$count transactions sont prêtes à être importées.';
  }

  @override
  String get importFinalizeButton => 'Finaliser l\'importation';

  @override
  String get importingTitle => 'Importation...';

  @override
  String get importCompleteTitle => 'Importation terminée';

  @override
  String get importStartOverTooltip => 'Recommencer';

  @override
  String get importDataTitle => 'Importer des données';

  @override
  String importAccountsCreatedLabel(Object count) {
    return 'Nouveaux comptes créés: $count';
  }

  @override
  String importCategoriesCreatedLabel(Object count) {
    return 'Nouvelles catégories créées: $count';
  }

  @override
  String importTransactionsImportedLabel(Object count) {
    return 'Transactions importées: $count';
  }

  @override
  String importDuplicatesSkippedLabel(Object count) {
    return 'Doublons ignorés: $count';
  }

  @override
  String get searchHint => 'Rechercher';

  @override
  String get debugAllDataClearedMessage => 'Toutes les données ont été effacées et réinitialisées par défaut.';

  @override
  String get debugClearAllDataLabel => 'Effacer toutes les données (et réinitialiser par défaut)';

  @override
  String get debugMinimumDataSeededMessage => 'Données minimales chargées.';

  @override
  String get debugSeedMinimumDataLabel => 'Charger les données minimales';

  @override
  String get debugMediumDataSeededMessage => 'Données moyennes chargées.';

  @override
  String get debugSeedMediumDataLabel => 'Charger les données moyennes';

  @override
  String get debugMaximumDataSeededMessage => 'Données maximales chargées.';

  @override
  String get debugSeedMaximumDataLabel => 'Charger les données maximales (pour test de performance)';

  @override
  String get debugRunningInDebugModeLabel => 'Exécution en mode DEBUG';

  @override
  String get deleteAllButton => 'Tout supprimer';

  @override
  String get changeButton => 'Modifier';

  @override
  String get undoButton => 'Annuler';

  @override
  String itemDeletedMessage(Object name) {
    return '$name supprimé';
  }

  @override
  String get totalBalanceLabel => 'Solde total';

  @override
  String get noCurrenciesSelected => 'Aucune devise sélectionnée.';

  @override
  String get incomeLabel => 'Revenus';

  @override
  String get expenseLabel => 'Dépenses';

  @override
  String get failedToLoadDashboard => 'Échec du chargement du tableau de bord';

  @override
  String get dashboardCalendarTab => 'Calendrier';

  @override
  String get dashboardCalendarTooltip => 'Vue calendrier';

  @override
  String get dashboardCalendarDescription => 'Afficher les transactions au format calendrier';

  @override
  String get dashboardCategoriesTab => 'Catégories';

  @override
  String get dashboardCategoriesTooltip => 'Analyse par catégorie';

  @override
  String get dashboardCategoriesDescription => 'Répartition des dépenses par catégorie';

  @override
  String get dashboardBalanceTab => 'Solde';

  @override
  String get dashboardBalanceTooltip => 'Historique du solde';

  @override
  String get dashboardBalanceDescription => 'Suivre la valeur nette au fil du temps';

  @override
  String get dashboardExpensesLabel => 'Dépenses';

  @override
  String get dashboardIncomeLabel => 'Revenus';

  @override
  String get manageIconsTitle => 'Gérer les icônes';

  @override
  String get noIconsCreated => 'Aucune icône créée pour le moment.';

  @override
  String get failedToLoadIcons => 'Échec du chargement des icônes.';

  @override
  String get cannotDeleteTransferIcon => 'Impossible de supprimer l\'icône de transfert.';

  @override
  String get deleteIconsDialogTitle => 'Supprimer les icônes';

  @override
  String deleteIconsConfirmationMessage(Object count) {
    return 'Voulez-vous vraiment supprimer $count icônes sélectionnées ?';
  }

  @override
  String deleteIconsWithSkipTransferMessage(Object count) {
    return 'Voulez-vous vraiment supprimer $count icônes sélectionnées ? (L\'icône de transfert sera ignorée)';
  }

  @override
  String get deleteIconDialogTitle => 'Supprimer l\'icône';

  @override
  String deleteIconConfirmationMessage(Object name) {
    return 'Voulez-vous vraiment supprimer \"$name\" ?';
  }

  @override
  String deleteMultipleAccountsTitle(Object count) {
    return 'Supprimer $count comptes ?';
  }

  @override
  String get deleteMultipleAccountsMessage => 'Voulez-vous vraiment supprimer les comptes sélectionnés ? Toutes les transactions associées seront supprimées.';

  @override
  String get changeAccountTypeDialogTitle => 'Changer le type de compte';

  @override
  String editAccountTitle(Object name) {
    return 'Modifier : $name';
  }

  @override
  String get balanceCalculatedFromAsset => 'Le solde est calculé à partir de Quantité d\'actif * Prix';

  @override
  String get selectAccountTypeTitle => 'Sélectionner le type de compte';

  @override
  String get selectCountryTitle => 'Sélectionner le pays';

  @override
  String get selectIconSubtitle => 'Sélectionner une icône';

  @override
  String get bindToAssetLabel => 'Lier à un actif (optionnel)';

  @override
  String get selectAssetTitle => 'Sélectionner un actif';

  @override
  String get selectedAssetLabel => 'Actif sélectionné';

  @override
  String get balanceAutoCalculatedLabel => 'Le solde est calculé automatiquement';

  @override
  String get tapToBindAssetLabel => 'Appuyez pour lier un actif';

  @override
  String get assetQuantityLabel => 'Quantité d\'actif';

  @override
  String get linkedAssetsTitle => 'Actifs liés';

  @override
  String get noneLabel => 'Aucun';

  @override
  String get accountTypeLabel => 'Type de compte';

  @override
  String get formValidationPleaseSelectAccountType => 'Veuillez sélectionner un type de compte';

  @override
  String get iconLabel => 'Icône';
}
