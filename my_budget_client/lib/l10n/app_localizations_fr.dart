// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get collapseMenuTooltip => 'Réduire le Menu';

  @override
  String get expandMenuTooltip => 'Développer le Menu';

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
  String get editAccountDialogTitle => 'Modifier le Compte';

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
  String get selectButton => 'Sélectionner';

  @override
  String get selectAllButton => 'Tout sélectionner';

  @override
  String get deselectAllButton => 'Tout désélectionner';

  @override
  String get deleteSelectedButton => 'Supprimer la sélection';

  @override
  String totalCountLabel(Object count) {
    return 'Total: $count';
  }

  @override
  String selectedCountLabel(Object count) {
    return '$count sélectionnés';
  }

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
  String get dashboardNetWorthTrend => 'Tendance de la Valeur Nette';

  @override
  String get dashboardWealthDistributionByAccount => 'Répartition de la Richesse (par Compte)';

  @override
  String get dashboardCurrencyExposure => 'Exposition aux Devises';

  @override
  String get dashboardNoAccountsFound => 'Aucun compte trouvé';

  @override
  String get dashboardTotalNetWorthTrend => 'Tendance de la Valeur Nette Totale';

  @override
  String get dashboardAccountBalanceTrend => 'Tendance du Solde du Compte';

  @override
  String get dashboardWealthDistribution => 'Répartition de la Richesse';

  @override
  String get dashboardCurrencyBreakdown => 'Répartition par Devise';

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
  String get addTransactionDescription => 'Modifier une nouvelle transaction';

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
  String get closeSelectionTooltip => 'Fermer la sélection';

  @override
  String get exitSelectionDescription => 'Quitter le mode de sélection';

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
  String get exitTransactionsSelectionDescription => 'Quitter le mode de sélection des transactions';

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
  String get amountLabel => 'Montant';

  @override
  String quantityLabel(Object quantity) {
    return 'Qté : $quantity';
  }

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
  String get addTransactionTitle => 'Ajouter une Transaction';

  @override
  String get editTransactionTitle => 'Modifier la Transaction';

  @override
  String get newTransferTitle => 'Nouveau Transfert';

  @override
  String get editTransferTitle => 'Modifier le Transfert';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get descriptionOptionalLabel => 'Description (Optionnel)';

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
  String get accountDeletedError => 'Le compte que vous aviez sélectionné a été supprimé. Veuillez en sélectionner un autre.';

  @override
  String get linkedAccountDeletedError => 'Le compte lié que vous aviez sélectionné a été supprimé. Veuillez en sélectionner un autre.';

  @override
  String get enterExchangeRateError => 'Veuillez entrer un taux de change. Ce transfert s\'effectue entre deux devises et aucun taux de change n\'est enregistré pour celles-ci.';

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
  String get themeSettingsTitle => 'Paramètres du Thème';

  @override
  String get appearanceSection => 'Apparence';

  @override
  String get themeModeLabel => 'Mode Thème';

  @override
  String get systemTheme => 'Système';

  @override
  String get lightTheme => 'Clair';

  @override
  String get darkTheme => 'Sombre';

  @override
  String get colorCustomizationSection => 'Personnalisation des Couleurs';

  @override
  String get primaryColorLabel => 'Couleur Primaire';

  @override
  String get secondaryColorLabel => 'Couleur Secondaire';

  @override
  String get surfaceColorLabel => 'Couleur de Surface';

  @override
  String get windowEffectsSection => 'Effets de Fenêtre (Bureau)';

  @override
  String get enableEffectsLabel => 'Activer les Effets de Fenêtre';

  @override
  String get windowEffectLabel => 'Effet de Fenêtre';

  @override
  String get backgroundLabel => 'Arrière-plan';

  @override
  String get removeBackgroundColor => 'Supprimer la couleur d\'arrière-plan';

  @override
  String get transparentSurfaceLabel => 'Surface Transparente (Cartes)';

  @override
  String get fullyTransparentLabel => 'Totalement Transparent';

  @override
  String get opaqueLabel => 'Opaque';

  @override
  String opacityLabel(Object value) {
    return 'Opacité: $value%';
  }

  @override
  String get backgroundSettingsSection => 'Paramètres d\'Arrière-plan';

  @override
  String get enableBackgroundImageLabel => 'Activer l\'Image d\'Arrière-plan';

  @override
  String get backgroundBlurLabel => 'Flou d\'Arrière-plan';

  @override
  String get surfaceGlassStyleTitle => 'Style de Surface/Verre';

  @override
  String get chooseImageButton => 'Choisir une Image';

  @override
  String get selectImageFileError => 'Veuillez sélectionner un fichier image.';

  @override
  String get clearImageButton => 'Effacer l\'Image';

  @override
  String get saveThemePresetTitle => 'Enregistrer le Préréglage de Thème';

  @override
  String get presetNameLabel => 'Nom du Préréglage';

  @override
  String get presetNameHint => 'Mon Thème Incroyable';

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
  String get apiManagementTitle => 'Gestion API';

  @override
  String apiErrorLabel(String error) {
    return 'Erreur: $error';
  }

  @override
  String apiLastFetchLabel(String date) {
    return 'Date: $date';
  }

  @override
  String get apiCategoriesSection => 'Catégories API';

  @override
  String get manualUtilitiesSection => 'Utilitaires Manuels';

  @override
  String get startupDataSyncLabel => 'Sync des Données au Démarrage';

  @override
  String get startupDataSyncDescription => 'Contrôle à la fois la récupération des données externes et la synchronisation du serveur au lancement de l\'application.';

  @override
  String get standardApiLabel => 'API Standard';

  @override
  String get syncOnStartupDescription => 'Synchroniser au démarrage';

  @override
  String get customSourcesLabel => 'Sources Personnalisées';

  @override
  String syncCustomSourcesDescription(Object count) {
    return 'Synchroniser tout ($count) au démarrage';
  }

  @override
  String get individualCustomSourcesTitle => 'Sources Personnalisées Individuelles';

  @override
  String get noCustomSourcesAdded => 'Aucune source personnalisée ajoutée.';

  @override
  String get fetchTodaysRatesButton => 'Récupérer les Taux d\'Aujourd\'hui';

  @override
  String get inflationConfigTitle => 'Configuration Inflation';

  @override
  String get countryCodeHint => 'Code Pays (ex: SRB)';

  @override
  String fetchDataForCountryButton(Object country) {
    return 'Récupérer les Données pour $country';
  }

  @override
  String get steamSettingsTitle => 'Paramètres Steam';

  @override
  String get steamIdLabel => 'Steam ID (64-bit)';

  @override
  String get steamIdHint => 'p. ex. 76561198085715972';

  @override
  String get preferredGameLabel => 'Jeu Préféré';

  @override
  String get fetchInventoryNowButton => 'Récupérer l\'Inventaire Maintenant';

  @override
  String get manualExchangeRatesTitle => 'Récupération Manuelle des Taux de Change';

  @override
  String get selectStartDate => 'Selección de la Date de Début';

  @override
  String startDateFrom(Object date) {
    return 'De: $date';
  }

  @override
  String get selectEndDate => 'Selección de la Date de Fin';

  @override
  String endDateTo(Object date) {
    return 'À: $date';
  }

  @override
  String get fetchRangeButton => 'Récupérer la Plage';

  @override
  String get manualSteamInventoryTitle => 'Inventaire Steam Manuel';

  @override
  String get selectGameHint => 'Sélectionner le Jeu';

  @override
  String get fetchValueButton => 'Récupérer la Valeur';

  @override
  String get manualInflationDataTitle => 'Données Inflation Manuelles';

  @override
  String get selectStartYear => 'Sélectionner l\'Année de Début';

  @override
  String startYearFrom(Object year) {
    return 'De: $year';
  }

  @override
  String get selectEndYear => 'Sélectionner l\'Année de Fin';

  @override
  String endYearTo(Object year) {
    return 'À: $year';
  }

  @override
  String get fetchDataButton => 'Récupérer les Données';

  @override
  String get connectionOk => 'Connexion OK';

  @override
  String get connectionFailed => 'Connexion Échouée';

  @override
  String get testConnectionButton => 'Tester la Connexion';

  @override
  String get editCustomSourceTitle => 'Modifier la Source Personnalisée';

  @override
  String get addCustomSourceTitle => 'Ajouter une Source Personnalisée';

  @override
  String get addressFormatsHelp => 'Formats d\'Adresse:\n• 192.168.1.10 (IP)\n• localhost ou api.my.com\n• http://myserver.com';

  @override
  String get customSourceNameHint => 'Mon Serveur Domestique';

  @override
  String get urlIpLabel => 'URL / IP';

  @override
  String get urlIpHint => '192.168.1.10:8080';

  @override
  String get dataTypeLabel => 'Type de Données';

  @override
  String get apiTitleExchangeRates => 'Taux de Change';

  @override
  String get apiTitleInflation => 'Inflation';

  @override
  String get apiTitleAssetPrices => 'Prix des Actifs';

  @override
  String get apiTitleSteamInventory => 'Inventaire Steam';

  @override
  String get transferLabel => 'Transfert';

  @override
  String get uncategorizedLabel => 'Non Catégorisé';

  @override
  String get defaultLabel => 'Par Défaut';

  @override
  String receivedTotalLabel(Object total) {
    return 'Reçu: $total';
  }

  @override
  String spentTotalLabel(Object total) {
    return 'Dépensé: $total';
  }

  @override
  String get categoriesGridViewTooltip => 'Vue en grille';

  @override
  String get categoriesListViewTooltip => 'Vue en liste';

  @override
  String get categoriesGridBackTooltip => 'Toutes les catégories';

  @override
  String get periodSummaryTitle => 'Résumé de la Période';

  @override
  String get incomeLabel => 'Revenus';

  @override
  String get expenseLabel => 'Dépenses';

  @override
  String get netLabel => 'Net';

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
  String get importCreateAllNew => 'Tout Créer à Nouveau';

  @override
  String importNewAccountFound(Object accountName) {
    return 'Nouveau compte trouvé: \"$accountName\"';
  }

  @override
  String importMapAccountTitle(Object accountName) {
    return 'Mapper \"$accountName\" à...';
  }

  @override
  String get importMapToExisting => 'Mapper à l\'Existant';

  @override
  String get importCreateNew => 'Créer un Nouveau';

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
  String get importSkipAll => 'Tout Ignorer';

  @override
  String get importImportAll => 'Tout Importer';

  @override
  String get importPotentialDuplicate => 'Doublon Potentiel:';

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
  String get importReadyTitle => 'Prêt à Importer';

  @override
  String importReadyMessage(Object count) {
    return '$count transactions sont prêtes à être importées.';
  }

  @override
  String get importFinalizeButton => 'Finaliser l\'Importation';

  @override
  String get importingTitle => 'Importation...';

  @override
  String get importCompleteTitle => 'Importation Terminée';

  @override
  String get importStartOverTooltip => 'Recommencer';

  @override
  String get importDataTitle => 'Importer des Données';

  @override
  String importAccountsCreatedLabel(Object count) {
    return 'Nouveaux Comptes Créés: $count';
  }

  @override
  String importCategoriesCreatedLabel(Object count) {
    return 'Nouvelles Catégories Créées: $count';
  }

  @override
  String importTransactionsImportedLabel(Object count) {
    return 'Transactions Importées: $count';
  }

  @override
  String importDuplicatesSkippedLabel(Object count) {
    return 'Doublons Ignorés: $count';
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
  String get deleteAllButton => 'Tout Supprimer';

  @override
  String get changeButton => 'Modifier';

  @override
  String get undoButton => 'Annuler';

  @override
  String itemDeletedMessage(Object name) {
    return '$name supprimé';
  }

  @override
  String get totalBalanceLabel => 'Solde Total';

  @override
  String get noCurrenciesSelected => 'Aucune devise sélectionnée.';

  @override
  String get failedToLoadDashboard => 'Échec du chargement du tableau de bord';

  @override
  String get dashboardCalendarTab => 'Calendrier';

  @override
  String get dashboardTabCalendar => 'Calendrier';

  @override
  String get dashboardCalendarTooltip => 'Vue Calendrier';

  @override
  String get dashboardCalendarDescription => 'Voir les transactions au format calendrier';

  @override
  String get dashboardCategoriesTab => 'Catégories';

  @override
  String get dashboardTabCategories => 'Catégories';

  @override
  String get dashboardCategoriesTooltip => 'Analyse par Catégorie';

  @override
  String get dashboardCategoriesDescription => 'Répartition des dépenses par catégorie';

  @override
  String get dashboardBalanceTab => 'Solde';

  @override
  String get dashboardTabBalance => 'Solde';

  @override
  String get dashboardBalanceTooltip => 'Historique du Solde';

  @override
  String get dashboardBalanceDescription => 'Suivre la valeur nette au fil du temps';

  @override
  String get dashboardExpensesLabel => 'Dépenses';

  @override
  String get dashboardIncomeLabel => 'Revenus';

  @override
  String get manageIconsTitle => 'Gérer les Icônes';

  @override
  String get manageStylesDeleteTitle => 'Supprimer les Icônes';

  @override
  String manageStylesDeleteConfirm(Object count) {
    return 'Êtes-vous sûr de vouloir supprimer $count icônes sélectionnées ?';
  }

  @override
  String manageStylesDeleteConfirmWithTransfer(Object count) {
    return 'Êtes-vous sûr de vouloir supprimer $count icônes sélectionnées ? (L\'icône de transfert sera ignorée)';
  }

  @override
  String get noIconsCreated => 'Aucune icône créée pour le moment.';

  @override
  String get failedToLoadIcons => 'Échec du chargement des icônes.';

  @override
  String get cannotDeleteTransferIcon => 'Impossible de supprimer l\'icône de transfert.';

  @override
  String get deleteIconsDialogTitle => 'Supprimer les Icônes';

  @override
  String deleteIconsConfirmationMessage(Object count) {
    return 'Voulez-vous vraiment supprimer $count icônes sélectionnées ?';
  }

  @override
  String deleteIconsWithSkipTransferMessage(Object count) {
    return 'Voulez-vous vraiment supprimer $count icônes sélectionnées ? (L\'icône de transfert sera ignorée)';
  }

  @override
  String get deleteIconDialogTitle => 'Supprimer l\'Icône';

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
  String get changeAccountTypeDialogTitle => 'Modifier le Type de Compte';

  @override
  String editAccountTitle(Object name) {
    return 'Modifier: $name';
  }

  @override
  String get balanceCalculatedFromAsset => 'Le solde est calculé à partir de Quantité d\'Actif * Prix';

  @override
  String get selectAccountTypeTitle => 'Sélectionner le Type de Compte';

  @override
  String get selectCountryTitle => 'Sélectionner le Pays';

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

  @override
  String get languageLabel => 'Langue';

  @override
  String get systemDefaultLabel => 'Par Défaut du Système';

  @override
  String get selectLanguageTitle => 'Choisir la Langue';

  @override
  String get dashboardLabel => 'Tableau de Bord';

  @override
  String get homeLabel => 'Accueil';

  @override
  String get historyLabel => 'Historique';

  @override
  String get syncScreenTitle => 'Paramètres de Synchronisation';

  @override
  String get syncP2PSection => 'Synchronisation P2P (Syncthing)';

  @override
  String get syncEnableP2P => 'Activer la Sync P2P';

  @override
  String get syncP2PSubtitle => 'Sync via les fichiers .sync dans un dossier partagé';

  @override
  String get syncFolderLabel => 'Dossier de Sync';

  @override
  String get syncFolderNotSelected => 'Non sélectionné';

  @override
  String get syncBrowseButton => 'Parcourir';

  @override
  String get syncClearFilesButton => 'Effacer les fichiers de sync';

  @override
  String get syncServerSection => 'Synchronisation Cloud (Serveur)';

  @override
  String get syncServerUrlLabel => 'URL du Serveur';

  @override
  String get syncApiTokenLabel => 'Jeton API';

  @override
  String get syncApiTokenHint => 'Entrez votre jeton de sécurité';

  @override
  String get syncApiTokenHelp => 'Ce jeton est votre secret partagé. Entrez la même valeur sur tous vos appareils pour autoriser la synchronisation.';

  @override
  String get syncTestConnectionButton => 'Tester la Connexion';

  @override
  String get syncTestingLabel => 'Test en cours...';

  @override
  String get syncSaveServerSettingsButton => 'Enregistrer les Paramètres Serveur';

  @override
  String get syncEnableServer => 'Activer la Sync Serveur';

  @override
  String get syncServerSubtitle => 'Synchroniser avec une instance MyBudget Server';

  @override
  String get syncPendingLocalChanges => 'Modifications locales en attente:';

  @override
  String get syncSyncNowButton => 'Sync Maintenant';

  @override
  String get syncSyncingLabel => 'Synchronisation...';

  @override
  String get syncWebNotAvailable => 'La synchronisation n\'est pas disponible sur le Web';

  @override
  String get syncPermissionRequired => 'La permission de stockage est requise pour la sync. Veuillez activer \"Accès à tous les fichiers\" dans les paramètres.';

  @override
  String get syncSelectFolderTitle => 'Sélectionner le Dossier Syncthing';

  @override
  String get syncClearFilesTitle => 'Effacer les Fichiers de Sync';

  @override
  String get syncClearFilesConfirm => 'Ceci supprimera tous les fichiers .sync du dossier sélectionné. Cette action est irréversible.';

  @override
  String syncDeletedFilesCount(Object count) {
    return '$count fichiers de sync supprimés';
  }

  @override
  String syncClearFilesError(Object error) {
    return 'Erreur lors de l\'effacement des fichiers: $error';
  }

  @override
  String get syncSettingsSaved => 'Paramètres serveur enregistrés';

  @override
  String get syncConnectionSuccessful => 'Connexion réussie !';

  @override
  String get syncConnectionFailed => 'Échec de la connexion. Vérifiez l\'URL et le Jeton.';

  @override
  String get syncConnectionUnauthorized => 'Jeton refusé par le serveur. Vérifiez le jeton, pas l\'adresse.';

  @override
  String get syncServerNotConfigured => 'Aucun jeton de synchronisation n\'est configuré sur le serveur, qui refuse donc tous les appareils. Définissez SYNC_TOKEN sur le serveur et saisissez la même valeur ici.';

  @override
  String get syncUrlNotConfigured => 'Aucune adresse de serveur. Saisissez une URL comme https://example.com avant d\'activer la synchronisation.';

  @override
  String get syncCompleted => 'Sync terminée avec succès';

  @override
  String syncFailed(Object error) {
    return 'Échec de la sync: $error';
  }

  @override
  String get smsRuleAddTitle => 'Ajouter une Règle';

  @override
  String get smsRuleEditTitle => 'Modifier la Règle';

  @override
  String get smsRuleTransactionType => 'Type de Transaction';

  @override
  String get smsRuleMatchPattern => 'Modèle de Correspondance (Regex)';

  @override
  String get smsRuleMatchPatternHint => 'ex: Paiement.*par carte';

  @override
  String get smsRuleMatchPatternHelp => 'Modèle pour identifier ce type de SMS';

  @override
  String get smsRuleAmountPattern => 'Modèle de Montant (Regex)';

  @override
  String get smsRuleAmountPatternHint => 'ex: montant\\s+([\\d,.]+)';

  @override
  String get smsRuleAmountPatternHelp => 'Le groupe 1 doit capturer le montant';

  @override
  String get smsRuleCurrencyPattern => 'Modèle de Devise (Regex, optionnel)';

  @override
  String get smsRuleCurrencyPatternHint => 'ex: [\\d,.]+\\s*(\\w\\w\\w)';

  @override
  String get smsRuleCurrencyPatternHelp => 'Le groupe 1 doit capturer le code de la devise';

  @override
  String get smsRuleTestTitle => 'Testez votre Règle';

  @override
  String get smsRuleTestSmsHint => 'Collez le texte du SMS ici';

  @override
  String get smsRuleTestButton => 'Tester le Modèle';

  @override
  String get smsRuleTestEnterSmsError => 'Entrez le texte du SMS à tester';

  @override
  String get smsRuleTestMatchError => '✗ Le modèle de correspondance n\'a rien trouvé';

  @override
  String get smsRuleTestAmountError => '✗ Le modèle de montant n\'a rien trouvé';

  @override
  String smsRuleTestSuccess(Object amount, Object currency, Object type) {
    return '✓ Correspondance trouvée !\nType: $type\nAmount: $amount\nDevise: $currency';
  }

  @override
  String smsRuleTestRegexError(Object error) {
    return '✗ Regex invalide: $error';
  }

  @override
  String get smsRuleRequiredError => 'Les modèles de Correspondance et de Montant sont requis';

  @override
  String inflationError(Object error) {
    return 'Erreur: $error';
  }

  @override
  String get inflationNoRatesFound => 'Aucun taux d\'inflation trouvé.';

  @override
  String get inflationAddRate => 'Ajouter un Taux d\'Inflation';

  @override
  String get inflationDeleteConfirmTitle => 'Supprimer les Taux ?';

  @override
  String inflationDeleteConfirmMessage(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count taux',
      one: 'ce taux',
    );
    return 'Êtes-vous sûr de vouloir supprimer $_temp0 ?';
  }

  @override
  String inflationSelectedCount(Object count) {
    return '$count sélectionnés';
  }

  @override
  String get inflationFiltersTitle => 'Filtres d\'Inflation';

  @override
  String get inflationCountries => 'Pays';

  @override
  String get inflationPresets => 'Préréglages';

  @override
  String deleteCategoryConfirmTitle(Object name) {
    return 'Supprimer $name ?';
  }

  @override
  String get deleteCategoryMessage => 'Cette catégorie a des transactions associées. Que souhaitez-vous faire ?';

  @override
  String get deleteCategoryReassign => 'Réassigner les transactions à une autre catégorie';

  @override
  String get deleteCategoryNewCategory => 'Nouvelle Catégorie';

  @override
  String get deleteCategoryDeleteAll => 'Supprimer toutes les transactions associées';

  @override
  String deleteAccountConfirmTitle(Object name) {
    return 'Supprimer $name ?';
  }

  @override
  String get deleteAccountMessage => 'Ce compte peut avoir des transactions associées. Que souhaitez-vous faire ?';

  @override
  String get deleteAccountReassign => 'Réassigner les transactions à un autre compte';

  @override
  String get deleteAccountNewAccount => 'Nouveau Compte';

  @override
  String get deleteAccountDeleteAll => 'Supprimer toutes les transactions associées';

  @override
  String get confirmButton => 'Confirmer';

  @override
  String get okButton => 'OK';

  @override
  String get noItemsFound => 'Aucun élément trouvé.';

  @override
  String get noDataForPeriod => 'Aucune donnée pour cette période';

  @override
  String get noDataForRange => 'Aucune donnée pour cette plage';

  @override
  String get noHistoryData => 'Aucune donnée d\'historique disponible';

  @override
  String get disabledByGlobalSync => 'Désactivé par la Sync Globale';

  @override
  String dateCreatedLabel(Object date) {
    return 'Date de création: $date';
  }

  @override
  String get anyLabel => 'Tous';

  @override
  String get balanceDisplayLabel => 'Affichage du Solde';

  @override
  String currenciesActiveLabel(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count devises actives',
      one: '1 devise active',
    );
    return '$_temp0';
  }

  @override
  String get searchCountryLabel => 'Rechercher un Pays';

  @override
  String get addNewIconLabel => 'Ajouter une Nouvelle Icône';

  @override
  String get noIconsFoundLabel => 'Aucune icône trouvée';

  @override
  String get addNewStyleLabel => 'Ajouter un Nouveau Style';

  @override
  String get styleNameLabel => 'Nom du Style';

  @override
  String get pleaseEnterStyleName => 'Veuillez entrer un nom de style';

  @override
  String get colorLabel => 'Color';

  @override
  String get netBalanceMetric => 'Solde Net';

  @override
  String get investedMetric => 'Investi';

  @override
  String get realizedMetric => 'Réalisé';

  @override
  String get feesMetric => 'Frais';

  @override
  String get persistFiltersLabel => 'Persister les Filtres';

  @override
  String get searchByNameHint => 'Rechercher par nom...';

  @override
  String get searchDescriptionHint => 'Rechercher dans la description...';

  @override
  String get advancedFiltersTitle => 'Filtres Avancés';

  @override
  String get transactionTypeLabel => 'Type de Transaction';

  @override
  String get assetFiltersTitle => 'Filtres d\'Actifs';

  @override
  String get minValueLabel => 'Valeur Min';

  @override
  String get maxValueLabel => 'Valeur Max';

  @override
  String get assetTypesLabel => 'Types d\'Actifs';

  @override
  String get allLabel => 'Tout';

  @override
  String get currenciesLabel => 'Devises';

  @override
  String get sourcesLabel => 'Sources';

  @override
  String get presetsLabel => 'Préréglages';

  @override
  String get enterCategoryNameHint => 'Entrez le nom de la catégorie';

  @override
  String get selectTypeHint => 'Sélectionner le Type';

  @override
  String get hotKeysTitle => 'Raccourcis Clavier';

  @override
  String get searchHotkeysHint => 'Rechercher des raccourcis...';

  @override
  String get noMatchingHotkeys => 'Aucun raccourci correspondant trouvé.';

  @override
  String recordingHotkeyTitle(Object label) {
    return 'Enregistrement du raccourci pour \"$label\"';
  }

  @override
  String get pressKeysHint => 'Appuyez sur les touches...';

  @override
  String get pressAnyCombinationHint => 'Appuyez sur n\'importe quelle combinaison de touches.';

  @override
  String get clearSaveButton => 'Effacer / Enregistrer';

  @override
  String get duplicateHotkeyTooltip => 'Raccourci Doublon';

  @override
  String usedByLabel(Object action) {
    return 'Utilisé par $action';
  }

  @override
  String get hkCategoryNavigation => 'Navigation';

  @override
  String get hkCategoryDashboardTabs => 'Onglets Tableau de Bord';

  @override
  String get hkCategoryDataTabs => 'Onglets Données';

  @override
  String get hkCategoryPeriodControl => 'Contrôle de Période';

  @override
  String get hkCategoryActions => 'Actions';

  @override
  String get hkCategorySelectionMode => 'Mode de Sélection';

  @override
  String get hkActionBack => 'Global: Retour / Quitter';

  @override
  String get hkActionDashboard => 'Aller au Tableau de Bord';

  @override
  String get hkActionAccounts => 'Aller aux Comptes';

  @override
  String get hkActionTransactions => 'Aller aux Transactions';

  @override
  String get hkActionCategories => 'Aller aux Catégories';

  @override
  String get hkActionData => 'Aller aux Données / Taux';

  @override
  String get hkActionSettings => 'Aller aux Paramètres';

  @override
  String get hkActionDashboardTab1 => 'Onglet Calendrier';

  @override
  String get hkActionDashboardTab2 => 'Onglet Catégories';

  @override
  String get hkActionDashboardTab3 => 'Onglet Solde';

  @override
  String get hkActionDataTab1 => 'Taux de Change';

  @override
  String get hkActionDataTab2 => 'Inflation';

  @override
  String get hkActionDataTab3 => 'Actifs';

  @override
  String get hkActionPrevPeriod => 'Période Précédente';

  @override
  String get hkActionNextPeriod => 'Période Suivante';

  @override
  String get hkActionAddAction => 'Action d\'Ajout Générique';

  @override
  String get hkActionSaveForm => 'Enregistrer le formulaire';

  @override
  String get hkActionPickDate => 'Sélectionner une date';

  @override
  String get hkActionDashboardSwitchView => 'Tableau de Bord: Changer de Vue';

  @override
  String get hkActionSortOrder => 'Ordre de tri';

  @override
  String get hkActionFilterAction => 'Filtrer';

  @override
  String get hkActionDashboardCurrency => 'Tableau de Bord: Devise';

  @override
  String get hkActionAccountsSelectionClose => 'Comptes: Fermer';

  @override
  String get hkActionAccountsSelectionAll => 'Comptes: Tout Sélectionner';

  @override
  String get hkActionAccountsSelectionDelete => 'Comptes: Supprimer';

  @override
  String get hkActionAccountsSelectionChangeType => 'Comptes: Changer le Type';

  @override
  String get hkActionTransactionsSelectionClose => 'Transactions: Fermer';

  @override
  String get hkActionTransactionsSelectionDelete => 'Transactions: Supprimer';

  @override
  String get hkActionTransactionsSelectionChangeDate => 'Transactions: Modifier la Date';

  @override
  String get hkActionTransactionsSelectionChangeCategory => 'Transactions: Changer de Catégorie';

  @override
  String get hkActionCategoriesSelectionClose => 'Catégories: Fermer';

  @override
  String get hkActionCategoriesSelectionAll => 'Catégories: Tout Sélectionner';

  @override
  String get hkActionCategoriesSelectionDelete => 'Catégories: Supprimer';

  @override
  String get hkActionCategoriesSelectionChangeType => 'Catégories: Changer le Type';

  @override
  String get hkActionDataSelectionClose => 'Taux de Change: Fermer';

  @override
  String get hkActionDataSelectionAll => 'Taux de Change: Tout Sélectionner';

  @override
  String get hkActionDataSelectionDelete => 'Taux de Change: Supprimer';

  @override
  String get hkActionDataSelectionChangePreset => 'Taux de Change: Changer de Préréglage';

  @override
  String get hkActionInflationSelectionClose => 'Inflation: Fermer';

  @override
  String get hkActionInflationSelectionAll => 'Inflation: Tout Sélectionner';

  @override
  String get hkActionInflationSelectionDelete => 'Inflation: Supprimer';

  @override
  String get hkActionAssetSelectionClose => 'Actifs: Fermer';

  @override
  String get hkActionAssetSelectionAll => 'Actifs: Tout Sélectionner';

  @override
  String get hkActionAssetSelectionDelete => 'Actifs: Supprimer';

  @override
  String get styNotFound => 'Style introuvable.';

  @override
  String get stySaveChanges => 'Enregistrer les Modifications';

  @override
  String get styAddIcon => 'Ajouter une Icône';

  @override
  String get smsOnlyAndroid => 'L\'importation SMS n\'est disponible que sur Android';

  @override
  String get smsImportSms => 'Importer les SMS';

  @override
  String get smsPermissionRequired => 'Permission SMS Requise';

  @override
  String get smsPermissionRationale => 'Pour importer des transactions depuis les SMS, nous avons besoin de la permission de lire vos messages.';

  @override
  String get smsGrantPermission => 'Accorder la Permission';

  @override
  String get smsNoPresets => 'Aucun préréglage configuré. Appuyez sur + pour en ajouter un.';

  @override
  String get smsImportDescription => 'Importer des transactions depuis les SMS. Choisissez une plage de dates:';

  @override
  String get smsLast7Days => '7 Derniers Jours';

  @override
  String get smsAllTime => 'Tout l\'Historique';

  @override
  String smsFilterLabel(Object filter) {
    return 'Filtre: $filter';
  }

  @override
  String get smsEditPreset => 'Modifier le Préréglage';

  @override
  String get smsNewPreset => 'Nouveau Préréglage';

  @override
  String get smsPresetNameHint => 'ex: Ma Banque';

  @override
  String get smsSenderFilter => 'Filtre d\'Expéditeur';

  @override
  String get smsSenderFilterHint => 'ex: ALTA ou +381...';

  @override
  String get smsSenderFilterHelper => 'Filtrer les SMS par nom d\'expéditeur ou numéro de téléphone';

  @override
  String get smsDefaults => 'Valeurs par Défaut';

  @override
  String get smsDefaultAccount => 'Compte par Défaut';

  @override
  String get smsDefaultCategory => 'Catégorie par Défaut';

  @override
  String get smsImportMessages => 'Importer les Messages';

  @override
  String get smsSelectDefaultsFirst => 'Sélectionnez d\'abord les valeurs par défaut';

  @override
  String get smsCustomRange => 'Plage Personnalisée';

  @override
  String smsImportSuccessCount(Object count) {
    return 'Succès: $count transactions importées';
  }

  @override
  String get smsParsingRules => 'Règles d\'Analyse';

  @override
  String get smsNoRules => 'Aucune règle définie. Appuyez sur + pour en ajouter une.';

  @override
  String smsMatchLabel(Object pattern) {
    return 'Correspondance: $pattern';
  }

  @override
  String get smsNameSenderRequired => 'Le nom et le filtre d\'expéditeur sont requis';

  @override
  String get smsCategoryKeywords => 'Mots-clés de Catégorie';

  @override
  String get smsCategoryKeywordsSubtitle => 'Mapper les mots-clés du SMS aux catégories';

  @override
  String get smsNoKeywordRules => 'Aucune règle de mots-clés. Appuyez sur + pour en ajouter une.';

  @override
  String get smsAddKeywordRule => 'Ajouter une Règle de Mot-clé';

  @override
  String get smsKeyword => 'Mot-clé';

  @override
  String get smsKeywordHint => 'ex: Épicerie, Netflix';

  @override
  String get smsKeywordHelper => 'Sous-chaîne insensible à la casse à rechercher dans le SMS';

  @override
  String get smsSelectCategoryHint => 'Sélectionner une catégorie';

  @override
  String get dshSelectDateDescription => 'Ouvrir le calendrier pour choisir une date ou une plage';

  @override
  String get dshCurrencyDescription => 'Sélectionner la devise principale pour l\'affichage';

  @override
  String get dshChangeViewTooltip => 'Changer de Vue';

  @override
  String get dshChangeViewDescription => 'Basculer entre les vues Mensuelle et Annuelle';

  @override
  String get dshMonthlyAbbreviation => 'M';

  @override
  String get dshYearlyAbbreviation => 'A';

  @override
  String dshBalancesOnDate(Object date) {
    return 'Soldes au $date';
  }

  @override
  String get dshSearchCurrency => 'Rechercher une Devise';

  @override
  String get dshUnknownCategory => 'Inconnu';

  @override
  String get pckSelectItem => 'Sélectionner un Élément';

  @override
  String get pckSelectItems => 'Sélectionner des Éléments';

  @override
  String get pckClearAll => 'Tout Effacer';

  @override
  String get pckSelectIcon => 'Sélectionner une Icône';

  @override
  String get pckMaterialIcons => 'Icônes Material';

  @override
  String get pckCustomIcons => 'Icônes Personnalisées';

  @override
  String get fltAmountFrom => 'Montant De';

  @override
  String get fltAmountTo => 'Montant À';

  @override
  String get fltSelectRange => 'Sélectionner une Plage';

  @override
  String get fltAdvancedFilterTooltip => 'Filtre Avancé';

  @override
  String get fltAdvancedFilterDescription => 'Filtrer les transactions par compte, catégorie ou montant';

  @override
  String get fltSortOrderDescription => 'Basculer entre l\'ordre croissant et décroissant';

  @override
  String get fltAccountFiltersTitle => 'Filtres de Comptes';

  @override
  String get fltNameLabel => 'Nom';

  @override
  String get fltAccountTypesLabel => 'Types de Comptes';

  @override
  String get fltFilterCurrenciesLabel => 'Filtrer les Devises';

  @override
  String get fltSelectCurrenciesLabel => 'Sélectionner les Devises';

  @override
  String get fltFilterCategoriesTitle => 'Filtrer les Catégories';

  @override
  String get exchAddExchangeRate => 'Ajouter un Taux de Change';

  @override
  String get exchEditExchangeRate => 'Modifier le Taux de Change';

  @override
  String get exchAddRateDescription => 'Saisir manuellement un taux de conversion entre deux devises';

  @override
  String get exchNoRatesFound => 'Aucun taux de change trouvé.';

  @override
  String get exchChangePreset => 'Changer de Préréglage';

  @override
  String get exchFromCurrency => 'Devise Source';

  @override
  String get exchToCurrency => 'Devise Cible';

  @override
  String get exchRate => 'Taux';

  @override
  String get exchPresetIdLabel => 'ID du Préréglage';

  @override
  String exchPresetValue(Object preset) {
    return 'Préréglage: $preset';
  }

  @override
  String get exchSelectRange => 'Sélectionner une Plage';

  @override
  String get exchPreviousPeriodDescription => 'Aller au jour, mois ou année précédent';

  @override
  String get exchNextPeriodDescription => 'Aller au jour, mois ou année suivant';

  @override
  String get exchFilterDescription => 'Filtrer les taux par devise source/cible et ID de préréglage';

  @override
  String get exchSelectDateDescription => 'Choisir une date ou une plage spécifique pour voir les taux historiques';

  @override
  String get exchSortOrderDescription => 'Basculer entre l\'ordre croissant et décroissant par date/taux';

  @override
  String get exchFilterExchangeRates => 'Filtrer les Taux de Change';

  @override
  String get exchExitSelectionDescription => 'Quitter le mode de sélection des taux de change';

  @override
  String get exchSelectAllDescription => 'Sélectionner tous les taux de change listés';

  @override
  String get exchDeselectAllDescription => 'Désélectionner tous les taux';

  @override
  String get exchChangePresetDescription => 'Mettre à jour l\'ID de préréglage pour tous les taux de change sélectionnés';

  @override
  String get exchDeleteSelectedDescription => 'Supprimer définitivement tous les taux de change sélectionnés';

  @override
  String get exchDeleteExchangeRatesTitle => 'Supprimer les Taux de Change';

  @override
  String exchDeleteConfirmMessage(Object count) {
    return 'Êtes-vous sûr de vouloir supprimer $count taux de change ?';
  }

  @override
  String get exchUpdatePresetTitle => 'Mettre à jour le Préréglage';

  @override
  String get exchUpdatePresetMessage => 'Saisissez le nouvel ID de préréglage pour les éléments sélectionnés:';

  @override
  String dashboardUnconvertibleCurrencies(String currencies) {
    return 'Impossible de convertir $currencies ; ces montants ne sont pas inclus dans le total';
  }

  @override
  String get addAccountBeforeTransactionDescription => 'Une transaction nécessite un compte. Créez le premier pour commencer';

  @override
  String get selectDialogEmptyState => 'Il n\'y a encore rien à choisir';

  @override
  String get selectDialogNoMatches => 'Aucun résultat pour votre recherche';

  @override
  String get addButton => 'Ajouter';

  @override
  String get retryButton => 'Réessayer';

  @override
  String get unknownLabel => 'Inconnu';

  @override
  String get globalLabel => 'Mondial';

  @override
  String dateWithValueLabel(String date) {
    return 'Date : $date';
  }

  @override
  String selectColorTitle(String label) {
    return 'Choisir la couleur $label';
  }

  @override
  String get assetAddTitle => 'Ajouter des données d\'actif';

  @override
  String get assetEditTitle => 'Modifier les données d\'actif';

  @override
  String get assetAddDescription => 'Enregistrer la valeur ou la quantité d\'un actif précis';

  @override
  String get assetNameLabel => 'Nom de l\'actif (p. ex. action Apple)';

  @override
  String get assetIdLabel => 'Identifiant de l\'actif (p. ex. AAPL)';

  @override
  String get assetValueLabel => 'Valeur (prix unitaire)';

  @override
  String get assetTypeOptionalLabel => 'Type d\'actif (facultatif)';

  @override
  String get assetLinkedAccountOptionalLabel => 'Compte lié (facultatif)';

  @override
  String get assetNameRequiredError => 'Donnez un nom à l\'actif';

  @override
  String get assetIdRequiredError => 'Indiquez un identifiant pour l\'actif, par exemple AAPL';

  @override
  String get assetValueInvalidError => 'Saisissez un nombre, par exemple 150,25';

  @override
  String get assetNoAssetsFound => 'Aucun actif trouvé.';

  @override
  String assetError(String error) {
    return 'Erreur : $error';
  }

  @override
  String get assetDeleteConfirmTitle => 'Supprimer les actifs ?';

  @override
  String assetDeleteConfirmMessage(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
      
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString actifs',
      one: 'cet actif',
    );
    return 'Êtes-vous sûr de vouloir supprimer $_temp0 ?';
  }

  @override
  String get assetDeleteSelectedDescription => 'Supprimer définitivement tous les enregistrements d\'actifs sélectionnés';

  @override
  String get inflationEditRate => 'Modifier le taux d\'inflation';

  @override
  String get inflationAddDescription => 'Saisissez un nouveau pourcentage d\'inflation pour une date et un pays précis';

  @override
  String get inflationPercentLabel => 'Pourcentage d\'inflation (%)';

  @override
  String get inflationPercentHint => 'p. ex. 2,5';

  @override
  String get inflationPercentInvalidError => 'Saisissez un nombre, par exemple 2,5';

  @override
  String get inflationCountryGlobal => 'Pays : mondial';

  @override
  String inflationCountryNamed(String country) {
    return 'Pays : $country';
  }

  @override
  String get inflationUseWorldwideRate => 'Utiliser le taux mondial';

  @override
  String get pickerSingleDate => 'Date unique';

  @override
  String get pickerRange => 'Plage';

  @override
  String get dateStepDay => 'Jour';

  @override
  String get dateStepMonth => 'Mois';

  @override
  String get dateStepYear => 'Année';

  @override
  String get feeStructureTitle => 'Structure des frais';

  @override
  String get feeNoRulesApplied => 'Aucune règle de frais appliquée.';

  @override
  String get feeAddRule => 'Ajouter une règle de frais';

  @override
  String get feeFixedFee => 'Frais fixes';

  @override
  String get feePercentFee => 'Frais en pourcentage';

  @override
  String get feeTaxRate => 'Taux d\'imposition';

  @override
  String get feeUnknownRule => 'Règle inconnue';

  @override
  String get feeRatePercentLabel => 'Taux (%)';

  @override
  String get feeTaxRatePercentLabel => 'Taux d\'imposition (%)';

  @override
  String get feeCostBasisLabel => 'Prix de revient';

  @override
  String deleteAccountsConfirmTitle(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
      
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString comptes',
      one: 'ce compte',
    );
    return 'Supprimer $_temp0 ?';
  }

  @override
  String get deleteAccountsConfirmMessage => 'Voulez-vous vraiment supprimer les comptes sélectionnés ? Toutes les transactions associées seront supprimées.';

  @override
  String get changeAccountTypeTitle => 'Changer le type de compte';

  @override
  String get accountsPreviousPeriodDescription => 'Aller au mois ou à l\'année précédente';

  @override
  String get accountsNextPeriodDescription => 'Aller au mois ou à l\'année suivante';

  @override
  String get accountsFilterDescription => 'Filtrer les comptes par type ou par statut masqué';

  @override
  String get accountsSelectDateDescription => 'Choisissez une date précise pour consulter les soldes historiques';

  @override
  String get accountsSortDescription => 'Basculer entre l\'ordre croissant et décroissant des soldes';

  @override
  String get smsRuleCategoryOptional => 'Catégorie (facultatif)';

  @override
  String get smsRuleCategoryHelp => 'Remplacer la catégorie pour cette règle';

  @override
  String amountSentLabel(Object currency) {
    return 'Montant envoyé ($currency)';
  }

  @override
  String amountReceivedLabel(Object currency) {
    return 'Montant reçu ($currency)';
  }

  @override
  String transferRateSummary(Object from, Object rate, Object to) {
    return '1 $from = $rate $to';
  }

  @override
  String get adjustRateLabel => 'Ajuster le taux';

  @override
  String get favoriteCurrenciesHeader => 'Favorites';

  @override
  String get frequentCurrenciesHeader => 'Fréquemment utilisées';

  @override
  String get allCurrenciesHeader => 'Toutes les devises';

  @override
  String get addFavoriteCurrencyTooltip => 'Ajouter aux favorites';

  @override
  String get removeFavoriteCurrencyTooltip => 'Retirer des favorites';
}
