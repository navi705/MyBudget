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
  String get accountsLoadFailure => 'Error al cargar cuentas';

  @override
  String get accountsEmptyState => 'Sin cuentas';

  @override
  String get accountsRefreshTooltip => 'Actualizar';

  @override
  String get accountsAddTooltip => 'Agregar Cuenta';

  @override
  String get addAccountDescription => 'Crear una nueva cuenta bancaria, billetera o activo';

  @override
  String get addAccountDialogTitle => 'Agregar nueva cuenta';

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
  String get deleteButton => 'Eliminar';

  @override
  String get editButton => 'Editar';

  @override
  String get applyButton => 'Aplicar';

  @override
  String get clearButton => 'Limpiar';

  @override
  String get formValidationPleaseEnterName => 'Por favor ingrese un nombre';

  @override
  String get formValidationPleaseEnterBalance => 'Por favor ingrese un saldo';

  @override
  String get formValidationPleaseEnterValidNumber => 'Por favor ingrese un número válido';

  @override
  String get formValidationPleaseSelectCurrency => 'Por favor seleccione una moneda';

  @override
  String get currencyLoadError => 'Error al cargar monedas';

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
  String get filePickerChooserTitle => 'Seleccionar Archivo';

  @override
  String get imagePickerChooserTitle => 'Seleccionar Imagen';

  @override
  String get totalNetWorth => 'Patrimonio Neto Total';

  @override
  String get currencyBreakdown => 'Desglose por Moneda';

  @override
  String get metricBalance => 'Saldo';

  @override
  String get metricIncome => 'Ingresos';

  @override
  String get metricExpense => 'Gastos';

  @override
  String get metricReal => 'Real';

  @override
  String get metricChange => 'Cambio';

  @override
  String get contextMenuSelect => 'Seleccionar';

  @override
  String get contextMenuDeselect => 'Deseleccionar';

  @override
  String get contextMenuSelectAll => 'Seleccionar Todo';

  @override
  String get contextMenuDeselectAll => 'Deseleccionar Todo';

  @override
  String get contextMenuAddTransaction => 'Añadir Transacción';

  @override
  String get addTransactionDescription => 'Crea una nueva transacción';

  @override
  String get contextMenuTransfer => 'Transferir';

  @override
  String get contextMenuEdit => 'Editar';

  @override
  String get contextMenuDelete => 'Eliminar';

  @override
  String get contextMenuChangeType => 'Cambiar Tipo';

  @override
  String deleteConfirmationTitle(Object item) {
    return '¿Eliminar $item?';
  }

  @override
  String deleteConfirmationMessage(Object item) {
    return '¿Está seguro de que desea eliminar este $item y todos sus datos?';
  }

  @override
  String get deleteAccountsConfirmationTitle => '¿Eliminar cuentas?';

  @override
  String deleteAccountsConfirmationMessage(Object count) {
    return '¿Eliminar $count cuentas seleccionadas y sus transacciones?';
  }

  @override
  String get deleteAccountDialogReassign => 'Reasignar transacciones a otra cuenta';

  @override
  String get deleteAccountDialogDeleteAll => 'Eliminar todas las transacciones asociadas';

  @override
  String get deleteAccountDialogMessage => 'Esta cuenta puede tener transacciones asociadas. ¿Qué le gustaría hacer?';

  @override
  String get newAccountLabel => 'Nueva Cuenta';

  @override
  String get warningOverwriteTitle => 'Advertencia: ¿Sobrescribir datos?';

  @override
  String get warningOverwriteMessage => 'Restaurar una copia de seguridad ELIMINARÁ TODOS los datos actuales y los reemplazará con la copia de seguridad. Esto no se puede deshacer.';

  @override
  String get restoreOverwriteButton => 'Restaurar y Sobrescribir';

  @override
  String get importSuccess => 'Importación completada con éxito.';

  @override
  String importFailed(Object error) {
    return 'Importación fallida: $error';
  }

  @override
  String deleteCategoriesConfirmationTitle(Object count) {
    return '¿Eliminar $count categorías?';
  }

  @override
  String get deleteCategoriesConfirmationMessage => '¿Está seguro de que desea eliminar las categorías seleccionadas?';

  @override
  String get changeCategoryTypeDialogTitle => 'Cambiar Tipo de Categoría';

  @override
  String get noCategoriesCreated => 'Aún no se han creado categorías.';

  @override
  String get addCategoryTooltip => 'Añadir Categoría';

  @override
  String get addCategoryDescription => 'Crear una nueva categoría de gastos o ingresos';

  @override
  String get previousPeriodTooltip => 'Periodo Anterior';

  @override
  String get previousPeriodDescription => 'Ir al mes o año anterior';

  @override
  String get nextPeriodTooltip => 'Periodo Siguiente';

  @override
  String get nextPeriodDescription => 'Ir al mes o año siguiente';

  @override
  String get filterTooltip => 'Filtrar';

  @override
  String get filterCategoriesDescription => 'Filtrar categorías por tipo (Ingresos/Gastos)';

  @override
  String get selectDateTooltip => 'Seleccionar Fecha';

  @override
  String get selectDateDescription => 'Elegir un rango de fechas específico para ver totales';

  @override
  String get sortOrderTooltip => 'Orden de Clasificación';

  @override
  String get sortOrderDescription => 'Cambiar entre orden ascendente y descendente por cantidad';

  @override
  String totalCountLabel(Object count) {
    return 'Total: $count';
  }

  @override
  String get closeSelectionTooltip => 'Cerrar Selección';

  @override
  String get exitSelectionDescription => 'Salir del modo de selección';

  @override
  String selectedCountLabel(Object count) {
    return '$count seleccionados';
  }

  @override
  String get categoryNameLabel => 'Nombre de la Categoría';

  @override
  String get categoriesChangeButton => 'Cambiar';

  @override
  String get parentCategoryLabel => 'Categoría Padre';

  @override
  String get styleLabel => 'Estilo (Icono y Color)';

  @override
  String get typeLabel => 'Tipo';

  @override
  String get deleteTransactionsConfirmationTitle => 'Eliminar Transacciones';

  @override
  String deleteTransactionsConfirmationMessage(Object count) {
    return '¿Está seguro de que desea eliminar $count transacciones seleccionadas?';
  }

  @override
  String get changeDateTooltip => 'Cambiar Fecha';

  @override
  String get changeDateDescription => 'Actualizar la fecha para todas las transacciones seleccionadas';

  @override
  String get changeCategoryTooltip => 'Cambiar Categoría';

  @override
  String get changeCategoryDescription => 'Actualizar la categoría para todas las transacciones seleccionadas';

  @override
  String get deleteTransactionsTooltip => 'Eliminar Seleccionadas';

  @override
  String get deleteTransactionsDescription => 'Eliminar permanentemente todas las transacciones seleccionadas';

  @override
  String get exitTransactionsSelectionDescription => 'Salir del modo de selección de transacciones';

  @override
  String quantityLabel(Object quantity) {
    return 'Cant: $quantity';
  }

  @override
  String get addTransactionTitle => 'Añadir Transacción';

  @override
  String get editTransactionTitle => 'Editar Transacción';

  @override
  String get newTransferTitle => 'Nueva Transferencia';

  @override
  String get editTransferTitle => 'Editar Transferencia';

  @override
  String get descriptionLabel => 'Descripción';

  @override
  String get descriptionOptionalLabel => 'Descripción (Opcional)';

  @override
  String get amountLabel => 'Cantidad';

  @override
  String get quantityFormLabel => 'Cantidad';

  @override
  String get selectAccountTitle => 'Seleccionar Cuenta';

  @override
  String get selectCategoryTitle => 'Seleccionar Categoría';

  @override
  String get selectCurrencyTitle => 'Seleccionar Moneda';

  @override
  String get accountLabel => 'Cuenta';

  @override
  String get fromAccountLabel => 'Desde Cuenta';

  @override
  String get toAccountLabel => 'A Cuenta';

  @override
  String get categoryLabel => 'Categoría';

  @override
  String get dateLabel => 'Fecha';

  @override
  String get selectDateLabel => 'Seleccionar Fecha';

  @override
  String get swapAccountsTooltip => 'Intercambiar Cuentas';

  @override
  String get incomeType => 'Ingresos';

  @override
  String get expenseType => 'Gastos';

  @override
  String get failedToLoadData => 'Error al cargar datos';

  @override
  String get invalidAmountError => 'Por favor ingrese un número válido';

  @override
  String get emptyAmountError => 'Por favor ingrese una cantidad';

  @override
  String get selectAccountError => 'Por favor seleccione una cuenta';

  @override
  String get selectCategoryError => 'Por favor seleccione una categoría';

  @override
  String get selectDateError => 'Por favor seleccione una fecha';

  @override
  String get currencyLockedMessage => 'Bloqueado a la moneda de la Cuenta de Origen';

  @override
  String get totalValueLabel => 'Valor Total';

  @override
  String get feeLabel => 'Tarifa';

  @override
  String get exchangeRateLabel => 'Tipo de Cambio';

  @override
  String get pricePerUnitLabel => 'Precio por unidad';

  @override
  String get buyAction => 'Comprar';

  @override
  String get sellAction => 'Vender';

  @override
  String transferToDescription(Object accountName) {
    return 'Transferir a $accountName';
  }

  @override
  String transferFromDescription(Object accountName) {
    return 'Transferir desde $accountName';
  }

  @override
  String buyDescription(Object assetName) {
    return 'Comprar $assetName';
  }

  @override
  String sellDescription(Object assetName) {
    return 'Vender $assetName';
  }

  @override
  String assetTransferDescription(Object action, Object assetName) {
    return 'Transferencia para $action $assetName';
  }

  @override
  String get swapDirectionTooltip => 'Cambiar Dirección';

  @override
  String get availablePresetsLabel => 'Preajustes Disponibles:';

  @override
  String get updateButton => 'Actualizar';

  @override
  String get newPresetButton => 'Nuevo Preajuste';

  @override
  String get amountToAddToAccountLabel => 'Cantidad a Añadir a la Cuenta:';

  @override
  String valueInGlobalLabel(Object currency) {
    return 'Valor en Global ($currency):';
  }

  @override
  String get feeCommissionLabel => 'Tarifa (Comisión)';

  @override
  String get requiredError => 'Requerido';

  @override
  String currentPriceLabel(Object currency, Object price) {
    return 'Precio Actual: $price $currency';
  }

  @override
  String get linkedAccountLabel => 'Cuenta Vinculada';

  @override
  String get selectLinkedAccountTitle => 'Seleccionar Cuenta Vinculada';

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get manageIconsLabel => 'Gestionar Iconos';

  @override
  String get manageThemeLabel => 'Gestionar Tema';

  @override
  String get mainCurrencyLabel => 'Moneda Principal';

  @override
  String get defaultInflationCountryLabel => 'País de Inflación Predeterminado';

  @override
  String get persistAdvancedFiltersLabel => 'Persistir Filtros Avanzados';

  @override
  String get hotKeysLabel => 'Teclas Rápidas';

  @override
  String get smsImportLabel => 'Importación SMS';

  @override
  String get smsImportSubtitle => 'Importar transacciones desde SMS bancarios';

  @override
  String get apiManagementLabel => 'Gestión de API';

  @override
  String get dataLabel => 'Datos';

  @override
  String get syncSettingsLabel => 'Configuración de Sincronización';

  @override
  String get syncSettingsSubtitle => 'Sincronización P2P vía Syncthing';

  @override
  String get importDataLabel => 'Importar Datos';

  @override
  String get exportDataLabel => 'Exportar Datos';

  @override
  String get exportFormatMessage => 'Elegir formato:\n\nJSON: Copia de seguridad completa de todos los datos.\nCSV: Informe legible de transacciones.';

  @override
  String get jsonFormat => 'JSON';

  @override
  String get csvFormat => 'CSV';

  @override
  String get importExchangeRatesLabel => 'Importar Tipos de Cambio (CSV/JSON)';

  @override
  String get resetDataLabel => 'Restablecer Datos a Predeterminados';

  @override
  String get resetDataSubtitle => 'Esto eliminará todos los datos y restaurará la configuración predeterminada.';

  @override
  String get debugMenuLabel => 'Menú de Depuración';

  @override
  String get debugMenuSubtitle => 'Herramientas de desarrollador internas';

  @override
  String get exportSuccessMessage => 'Exportación completada con éxito';

  @override
  String exportFailedMessage(Object error) {
    return 'Exportación fallida: $error';
  }

  @override
  String get importSuccessMessage => 'Importación completada con éxito';

  @override
  String importFailedMessage(Object error) {
    return 'Importación fallida: $error';
  }

  @override
  String get resetDataConfirmationTitle => '¿Restablecer Datos?';

  @override
  String get resetDataConfirmationMessage => '¡Advertencia! Esto eliminará TODAS sus transacciones, cuentas y configuraciones.\n\nLa aplicación se restaurará a su estado inicial con datos predeterminados.\nEsta acción NO se puede deshacer.';

  @override
  String get resetEverythingButton => 'Restablecer Todo';

  @override
  String get resetSuccessMessage => 'Datos restablecidos y valores predeterminados restaurados.';

  @override
  String resetFailedMessage(Object error) {
    return 'Restablecimiento fallido: $error';
  }

  @override
  String get importParsingStep => 'Analizando archivos CSV...';

  @override
  String get importFetchingRatesStep => 'Obteniendo tipos de cambio...';

  @override
  String importErrorLabel(Object error) {
    return 'Error: $error';
  }

  @override
  String get importOneMoneyLabel => 'Importar desde OneMoney (CSV)';

  @override
  String get importMyBudgetLabel => 'Importar transacciones de MyBudget (CSV)';

  @override
  String get restoreBackupLabel => 'Restaurar copia de seguridad (JSON)';

  @override
  String get importSelectionHelp => 'Seleccione \'OneMoney\' para migración, \'MyBudget\' para añadir transacciones, o \'Restaurar copia de seguridad\' para sobrescribir todos los datos.';

  @override
  String get importCreateAllNew => 'Crear todo como nuevo';

  @override
  String importNewAccountFound(Object accountName) {
    return 'Nuevo cuenta encontrada: \"$accountName\"';
  }

  @override
  String importMapAccountTitle(Object accountName) {
    return 'Asignar \"$accountName\" a...';
  }

  @override
  String get importMapToExisting => 'Asignar a existente';

  @override
  String get importCreateNew => 'Crear nuevo';

  @override
  String importNewCategoryFound(Object categoryName) {
    return 'Nueva categoría encontrada: \"$categoryName\"';
  }

  @override
  String importMapCategoryTitle(Object categoryName) {
    return 'Asignar \"$categoryName\" a...';
  }

  @override
  String importNewCurrencyFound(Object currencyName) {
    return 'Nueva moneda encontrada: \"$currencyName\"';
  }

  @override
  String importMapCurrencyTitle(Object currencyName) {
    return 'Asignar \"$currencyName\" a...';
  }

  @override
  String get importSkipAll => 'Omitir todo';

  @override
  String get importImportAll => 'Importar todo';

  @override
  String get importPotentialDuplicate => 'Posible duplicado:';

  @override
  String importDateLabel(Object date) {
    return 'Fecha: $date';
  }

  @override
  String importFromLabel(Object from) {
    return 'De: $from';
  }

  @override
  String importToLabel(Object to) {
    return 'A: $to';
  }

  @override
  String importAmountLabel(Object amount, Object currency) {
    return 'Cantidad: $amount $currency';
  }

  @override
  String get importSkip => 'Omitir';

  @override
  String get importImportAnyway => 'Importar de todos modos';

  @override
  String importDecisionLabel(Object decision) {
    return 'Decisión: $decision';
  }

  @override
  String get importReadyTitle => 'Listo para importar';

  @override
  String importReadyMessage(Object count) {
    return '$count transacciones están listas para ser importadas.';
  }

  @override
  String get importFinalizeButton => 'Finalizar importación';

  @override
  String get importingTitle => 'Importando...';

  @override
  String get importCompleteTitle => 'Importación completa';

  @override
  String get importStartOverTooltip => 'Empezar de nuevo';

  @override
  String get importDataTitle => 'Importar datos';

  @override
  String importAccountsCreatedLabel(Object count) {
    return 'Nuevas cuentas creadas: $count';
  }

  @override
  String importCategoriesCreatedLabel(Object count) {
    return 'Nuevas categorías creadas: $count';
  }

  @override
  String importTransactionsImportedLabel(Object count) {
    return 'Transacciones importadas: $count';
  }

  @override
  String importDuplicatesSkippedLabel(Object count) {
    return 'Duplicados omitidos: $count';
  }

  @override
  String get searchHint => 'Buscar';

  @override
  String get debugAllDataClearedMessage => 'Todos los datos borrados y re-sembrados con valores predeterminados.';

  @override
  String get debugClearAllDataLabel => 'Borrar todos los datos (y re-sembrar predeterminados)';

  @override
  String get debugMinimumDataSeededMessage => 'Datos mínimos sembrados.';

  @override
  String get debugSeedMinimumDataLabel => 'Sembrar datos mínimos';

  @override
  String get debugMediumDataSeededMessage => 'Datos medianos sembrados.';

  @override
  String get debugSeedMediumDataLabel => 'Sembrar datos medianos';

  @override
  String get debugMaximumDataSeededMessage => 'Datos máximos sembrados.';

  @override
  String get debugSeedMaximumDataLabel => 'Sembrar datos máximos (para prueba de rendimiento)';

  @override
  String get debugRunningInDebugModeLabel => 'Funcionando en modo DEBUG';

  @override
  String get deleteAllButton => 'Eliminar todo';

  @override
  String get changeButton => 'Cambiar';

  @override
  String get undoButton => 'Deshacer';

  @override
  String itemDeletedMessage(Object name) {
    return '$name eliminado';
  }

  @override
  String get totalBalanceLabel => 'Balance total';

  @override
  String get noCurrenciesSelected => 'No hay monedas seleccionadas.';

  @override
  String get incomeLabel => 'Ingresos';

  @override
  String get expenseLabel => 'Gastos';

  @override
  String get failedToLoadDashboard => 'Error al cargar el tablero';

  @override
  String get dashboardCalendarTab => 'Calendario';

  @override
  String get dashboardCalendarTooltip => 'Vista de calendario';

  @override
  String get dashboardCalendarDescription => 'Ver transacciones en formato de calendario';

  @override
  String get dashboardCategoriesTab => 'Categorías';

  @override
  String get dashboardCategoriesTooltip => 'Vista de categorías';

  @override
  String get dashboardCategoriesDescription => 'Administrar sus categorías de dinero';

  @override
  String get dashboardBalanceTab => 'Saldo';

  @override
  String get dashboardBalanceTooltip => 'Vista de saldo';

  @override
  String get dashboardBalanceDescription => 'Resumen rápido de su saldo';

  @override
  String get dashboardExpensesLabel => 'Gastos';

  @override
  String get dashboardIncomeLabel => 'Ingresos';

  @override
  String get manageIconsTitle => 'Administrar iconos';

  @override
  String get noIconsCreated => 'No se han creado iconos todavía.';

  @override
  String get failedToLoadIcons => 'Error al cargar los iconos.';

  @override
  String get cannotDeleteTransferIcon => 'No se puede eliminar el icono de transferencia.';

  @override
  String get deleteIconsDialogTitle => 'Eliminar iconos';

  @override
  String deleteIconsConfirmationMessage(Object count) {
    return '¿Estás seguro de que quieres eliminar $count iconos seleccionados?';
  }

  @override
  String deleteIconsWithSkipTransferMessage(Object count) {
    return '¿Estás seguro de que quieres eliminar $count iconos seleccionados? (El icono de transferencia se omitirá)';
  }

  @override
  String get deleteIconDialogTitle => 'Eliminar icono';

  @override
  String deleteIconConfirmationMessage(Object name) {
    return '¿Estás seguro de que quieres eliminar \"$name\"?';
  }

  @override
  String deleteMultipleAccountsTitle(Object count) {
    return '¿Eliminar $count cuentas?';
  }

  @override
  String get deleteMultipleAccountsMessage => '¿Estás seguro de que quieres eliminar las cuentas seleccionadas? Se eliminarán todas las transacciones asociadas.';

  @override
  String get changeAccountTypeDialogTitle => 'Cambiar tipo de cuenta';

  @override
  String editAccountTitle(Object name) {
    return 'Editar: $name';
  }

  @override
  String get balanceCalculatedFromAsset => 'El saldo se calcula como Cantidad de activo * Precio';

  @override
  String get selectAccountTypeTitle => 'Seleccionar tipo de cuenta';

  @override
  String get selectCountryTitle => 'Seleccionar país';

  @override
  String get selectIconSubtitle => 'Seleccionar un icono';

  @override
  String get bindToAssetLabel => 'Vincular a activo (opcional)';

  @override
  String get selectAssetTitle => 'Seleccionar activo';

  @override
  String get selectedAssetLabel => 'Activo seleccionado';

  @override
  String get balanceAutoCalculatedLabel => 'El saldo se calcula automáticamente';

  @override
  String get tapToBindAssetLabel => 'Toca para vincular un activo';

  @override
  String get assetQuantityLabel => 'Cantidad de activo';

  @override
  String get linkedAssetsTitle => 'Activos vinculados';

  @override
  String get noneLabel => 'Ninguno';

  @override
  String get accountTypeLabel => 'Tipo de cuenta';

  @override
  String get formValidationPleaseSelectAccountType => 'Por favor, seleccione un tipo de cuenta';

  @override
  String get iconLabel => 'Icono';

  @override
  String get languageLabel => 'Idioma';

  @override
  String get systemDefaultLabel => 'Predeterminado del sistema';

  @override
  String get selectLanguageTitle => 'Seleccionar idioma';
}
