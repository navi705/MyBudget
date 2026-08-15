// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get collapseMenuTooltip => 'Contraer Menú';

  @override
  String get expandMenuTooltip => 'Expandir Menú';

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
  String get accountsEmptyState => 'No cuentas';

  @override
  String get accountsRefreshTooltip => 'Actualizar';

  @override
  String get accountsAddTooltip => 'Agregar Cuenta';

  @override
  String get addAccountDescription => 'Crear una nueva cuenta bancaria, billetera o activo';

  @override
  String get addAccountDialogTitle => 'Agregar nueva cuenta';

  @override
  String get editAccountDialogTitle => 'Editar Cuenta';

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
  String get selectButton => 'Seleccionar';

  @override
  String get selectAllButton => 'Seleccionar Todo';

  @override
  String get deselectAllButton => 'Deseleccionar Todo';

  @override
  String get deleteSelectedButton => 'Eliminar Seleccionados';

  @override
  String totalCountLabel(Object count) {
    return 'Total: $count';
  }

  @override
  String selectedCountLabel(Object count) {
    return '$count seleccionados';
  }

  @override
  String get formValidationPleaseEnterName => 'Por favor, introduzca un nombre';

  @override
  String get formValidationPleaseEnterBalance => 'Por favor, introduzca un saldo';

  @override
  String get formValidationPleaseEnterValidNumber => 'Por favor, introduzca un número válido';

  @override
  String get formValidationPleaseSelectCurrency => 'Por favor, seleccione una moneda';

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
  String get currencyBreakdown => 'Desglose de Moneda';

  @override
  String get dashboardNetWorthTrend => 'Tendencia del Patrimonio Neto';

  @override
  String get dashboardWealthDistributionByAccount => 'Distribución de Riqueza (por Cuenta)';

  @override
  String get dashboardCurrencyExposure => 'Exposición de Moneda';

  @override
  String get dashboardNoAccountsFound => 'No se encontraron cuentas';

  @override
  String get dashboardTotalNetWorthTrend => 'Tendencia Total del Patrimonio Neto';

  @override
  String get dashboardAccountBalanceTrend => 'Tendencia del Saldo de la Cuenta';

  @override
  String get dashboardWealthDistribution => 'Distribución de Riqueza';

  @override
  String get dashboardCurrencyBreakdown => 'Desglose de Moneda';

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
  String get addTransactionDescription => 'Crear una nueva transacción';

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
  String get warningOverwriteTitle => 'Advertencia: ¿Sobrescribir Datos?';

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
  String get noCategoriesCreated => 'No se han creado categorías aún.';

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
  String get selectDateDescription => 'Elija un rango de fechas específico para ver los totales';

  @override
  String get sortOrderTooltip => 'Orden de Clasificación';

  @override
  String get sortOrderDescription => 'Cambiar entre orden de cantidad ascendente y descendente';

  @override
  String get closeSelectionTooltip => 'Cerrar Selección';

  @override
  String get exitSelectionDescription => 'Salir del modo de selección';

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
  String get exitTransactionsSelectionDescription => 'Salir del modo de selección de transacciones';

  @override
  String get changeDateTooltip => 'Cambiar Fecha';

  @override
  String get changeDateDescription => 'Actualizar la fecha de todas las transacciones seleccionadas';

  @override
  String get changeCategoryTooltip => 'Cambiar Categoría';

  @override
  String get changeCategoryDescription => 'Actualizar la categoría de todas las transacciones seleccionadas';

  @override
  String get deleteTransactionsTooltip => 'Eliminar Seleccionados';

  @override
  String get deleteTransactionsDescription => 'Eliminar permanentemente todas las transacciones seleccionadas';

  @override
  String get amountLabel => 'Cantidad';

  @override
  String quantityLabel(Object quantity) {
    return 'Cant: $quantity';
  }

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
  String get swapAccountsTooltip => 'Intercambiar Cuentas';

  @override
  String get incomeType => 'Ingresos';

  @override
  String get expenseType => 'Gastos';

  @override
  String get failedToLoadData => 'Error al cargar datos';

  @override
  String get invalidAmountError => 'Por favor, introduzca un número válido';

  @override
  String get emptyAmountError => 'Por favor, introduzca una cantidad';

  @override
  String get selectAccountError => 'Por favor, seleccione una cuenta';

  @override
  String get selectCategoryError => 'Por favor, seleccione una categoría';

  @override
  String get selectDateError => 'Por favor, seleccione una fecha';

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
    return 'Transferencia a $accountName';
  }

  @override
  String transferFromDescription(Object accountName) {
    return 'Transferencia desde $accountName';
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
  String get amountToAddToAccountLabel => 'Cantidad para Añadir a la Cuenta:';

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
  String get smsImportSubtitle => 'Importar transacciones bancarias por SMS';

  @override
  String get apiManagementLabel => 'Gestión de API';

  @override
  String get dataLabel => 'Datos';

  @override
  String get syncSettingsLabel => 'Configuración de Sincronización';

  @override
  String get syncSettingsSubtitle => 'Sincronización P2P vía Syncthing';

  @override
  String get themeSettingsTitle => 'Configuración del Tema';

  @override
  String get appearanceSection => 'Apariencia';

  @override
  String get themeModeLabel => 'Modo de Tema';

  @override
  String get systemTheme => 'Sistema';

  @override
  String get lightTheme => 'Claro';

  @override
  String get darkTheme => 'Oscuro';

  @override
  String get colorCustomizationSection => 'Personalización de Colores';

  @override
  String get primaryColorLabel => 'Color Primario';

  @override
  String get secondaryColorLabel => 'Color Secundario';

  @override
  String get surfaceColorLabel => 'Color de Superficie';

  @override
  String get windowEffectsSection => 'Efectos de Ventana (Escritorio)';

  @override
  String get enableEffectsLabel => 'Activar Efectos de Ventana';

  @override
  String get windowEffectLabel => 'Efecto de Ventana';

  @override
  String get backgroundLabel => 'Fondo';

  @override
  String get removeBackgroundColor => 'Eliminar color de fondo';

  @override
  String get transparentSurfaceLabel => 'Superficie Transparente (Tarjetas)';

  @override
  String get fullyTransparentLabel => 'Totalmente Transparente';

  @override
  String get opaqueLabel => 'Opaco';

  @override
  String opacityLabel(Object value) {
    return 'Opacidad: $value%';
  }

  @override
  String get backgroundSettingsSection => 'Configuración de Fondo';

  @override
  String get enableBackgroundImageLabel => 'Activar Imagen de Fondo';

  @override
  String get backgroundBlurLabel => 'Desenfoque de Fondo';

  @override
  String get surfaceGlassStyleTitle => 'Estilo de Superficie/Cristal';

  @override
  String get chooseImageButton => 'Elegir Imagen';

  @override
  String get selectImageFileError => 'Por favor, seleccione un archivo de imagen.';

  @override
  String get clearImageButton => 'Borrar Imagen';

  @override
  String get saveThemePresetTitle => 'Guardar Preajuste de Tema';

  @override
  String get presetNameLabel => 'Nombre del Preajuste';

  @override
  String get presetNameHint => 'Mi Increíble Tema';

  @override
  String get importDataLabel => 'Importar Datos';

  @override
  String get exportDataLabel => 'Exportar Datos';

  @override
  String get exportFormatMessage => 'Elija el formato:\n\nJSON: Copia de seguridad completa de todos los datos.\nCSV: Informe legible de transacciones.';

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
  String get apiManagementTitle => 'Gestión de API';

  @override
  String apiErrorLabel(String error) {
    return 'Error: $error';
  }

  @override
  String apiLastFetchLabel(String date) {
    return 'Fecha: $date';
  }

  @override
  String get apiCategoriesSection => 'Categorías de API';

  @override
  String get manualUtilitiesSection => 'Utilidades Manuales';

  @override
  String get startupDataSyncLabel => 'Sincronización de Datos al Inicio';

  @override
  String get startupDataSyncDescription => 'Controla tanto la obtención de datos externos como la sincronización del servidor al iniciar la aplicación.';

  @override
  String get standardApiLabel => 'API Estándar';

  @override
  String get syncOnStartupDescription => 'Sincronizar al inicio';

  @override
  String get customSourcesLabel => 'Fuentes Personalizadas';

  @override
  String syncCustomSourcesDescription(Object count) {
    return 'Sincronizar todas ($count) al inicio';
  }

  @override
  String get individualCustomSourcesTitle => 'Fuentes Personalizadas Individuales';

  @override
  String get noCustomSourcesAdded => 'No se han añadido fuentes personalizadas.';

  @override
  String get fetchTodaysRatesButton => 'Obtener Tipos de Hoy';

  @override
  String get inflationConfigTitle => 'Configuración de Inflación';

  @override
  String get countryCodeHint => 'Código de País (ej. SRB)';

  @override
  String fetchDataForCountryButton(Object country) {
    return 'Obtener Datos para $country';
  }

  @override
  String get steamSettingsTitle => 'Configuración de Steam';

  @override
  String get steamIdLabel => 'ID de Steam (64 bits)';

  @override
  String get steamIdHint => 'p. ej. 76561198085715972';

  @override
  String get preferredGameLabel => 'Juego Preferido';

  @override
  String get fetchInventoryNowButton => 'Obtener Inventario Ahora';

  @override
  String get manualExchangeRatesTitle => 'Obtención Manual de Tipos de Cambio';

  @override
  String get selectStartDate => 'Seleccionar Fecha de Inicio';

  @override
  String startDateFrom(Object date) {
    return 'Desde: $date';
  }

  @override
  String get selectEndDate => 'Seleccionar Fecha de Finalización';

  @override
  String endDateTo(Object date) {
    return 'Hasta: $date';
  }

  @override
  String get fetchRangeButton => 'Obtener Rango';

  @override
  String get manualSteamInventoryTitle => 'Inventario de Steam Manual';

  @override
  String get selectGameHint => 'Seleccionar Juego';

  @override
  String get fetchValueButton => 'Obtener Valor';

  @override
  String get manualInflationDataTitle => 'Datos de Inflación Manuales';

  @override
  String get selectStartYear => 'Seleccionar Año de Inicio';

  @override
  String startYearFrom(Object year) {
    return 'Desde: $year';
  }

  @override
  String get selectEndYear => 'Seleccionar Año de Finalización';

  @override
  String endYearTo(Object year) {
    return 'Hasta: $year';
  }

  @override
  String get fetchDataButton => 'Obtener Datos';

  @override
  String get connectionOk => 'Conexión OK';

  @override
  String get connectionFailed => 'Conexión Fallida';

  @override
  String get testConnectionButton => 'Probar Conexión';

  @override
  String get editCustomSourceTitle => 'Editar Fuente Personalizada';

  @override
  String get addCustomSourceTitle => 'Añadir Fuente Personalizada';

  @override
  String get addressFormatsHelp => 'Formatos de Dirección:\n• 192.168.1.10 (IP)\n• localhost o api.mi.com\n• http://miservidor.com';

  @override
  String get customSourceNameHint => 'Mi Servidor Doméstico';

  @override
  String get urlIpLabel => 'URL / IP';

  @override
  String get urlIpHint => '192.168.1.10:8080';

  @override
  String get dataTypeLabel => 'Tipo de Datos';

  @override
  String get apiTitleExchangeRates => 'Tipos de Cambio';

  @override
  String get apiTitleInflation => 'Inflación';

  @override
  String get apiTitleAssetPrices => 'Precios de Activos';

  @override
  String get apiTitleSteamInventory => 'Inventario de Steam';

  @override
  String get transferLabel => 'Transferencia';

  @override
  String get uncategorizedLabel => 'Sin Categoría';

  @override
  String get defaultLabel => 'Predeterminado';

  @override
  String receivedTotalLabel(Object total) {
    return 'Recibido: $total';
  }

  @override
  String spentTotalLabel(Object total) {
    return 'Gastado: $total';
  }

  @override
  String get periodSummaryTitle => 'Resumen del Periodo';

  @override
  String get incomeLabel => 'Ingresos';

  @override
  String get expenseLabel => 'Gastos';

  @override
  String get netLabel => 'Neto';

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
  String get resetDataConfirmationMessage => '¡Atención! Esto eliminará TODAS sus transacciones, cuentas y configuraciones.\n\nLa aplicación se restaurará a su estado inicial con datos predeterminados.\nEsta acción NO se puede deshacer.';

  @override
  String get resetEverythingButton => 'Restablecer Todo';

  @override
  String get resetSuccessMessage => 'Datos restablecidos y valores predeterminados restaurados.';

  @override
  String resetFailedMessage(Object error) {
    return 'Error al restablecer: $error';
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
  String get importMyBudgetLabel => 'Importar Transacciones de MyBudget (CSV)';

  @override
  String get restoreBackupLabel => 'Restaurar Copia de Seguridad (JSON)';

  @override
  String get importSelectionHelp => 'Seleccione \'OneMoney\' para migración, \'MyBudget\' para añadir transacciones, o \'Restaurar Copia de Seguridad\' para sobrescribir todo.';

  @override
  String get importCreateAllNew => 'Crear Todo Nuevo';

  @override
  String importNewAccountFound(Object accountName) {
    return 'Nueva cuenta encontrada: \"$accountName\"';
  }

  @override
  String importMapAccountTitle(Object accountName) {
    return 'Asignar \"$accountName\" a...';
  }

  @override
  String get importMapToExisting => 'Asignar a Existente';

  @override
  String get importCreateNew => 'Crear Nuevo';

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
  String get importSkipAll => 'Omitir Todo';

  @override
  String get importImportAll => 'Importar Todo';

  @override
  String get importPotentialDuplicate => 'Posible Duplicado:';

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
  String get importImportAnyway => 'Importar de Todas Formas';

  @override
  String importDecisionLabel(Object decision) {
    return 'Decisión: $decision';
  }

  @override
  String get importReadyTitle => 'Listo para Importar';

  @override
  String importReadyMessage(Object count) {
    return '$count transacciones están listas para ser importadas.';
  }

  @override
  String get importFinalizeButton => 'Finalizar Importación';

  @override
  String get importingTitle => 'Importando...';

  @override
  String get importCompleteTitle => 'Importación Completa';

  @override
  String get importStartOverTooltip => 'Empezar de Nuevo';

  @override
  String get importDataTitle => 'Importar Datos';

  @override
  String importAccountsCreatedLabel(Object count) {
    return 'Nuevas Cuentas Creadas: $count';
  }

  @override
  String importCategoriesCreatedLabel(Object count) {
    return 'Nuevas Categorías Creadas: $count';
  }

  @override
  String importTransactionsImportedLabel(Object count) {
    return 'Transacciones Importadas: $count';
  }

  @override
  String importDuplicatesSkippedLabel(Object count) {
    return 'Duplicados Omitidos: $count';
  }

  @override
  String get searchHint => 'Buscar';

  @override
  String get debugAllDataClearedMessage => 'Todos los datos borrados y re-sembrados con valores predeterminados.';

  @override
  String get debugClearAllDataLabel => 'Borrar Todos los Datos (y re-sembrar predeterminados)';

  @override
  String get debugMinimumDataSeededMessage => 'Datos mínimos sembrados.';

  @override
  String get debugSeedMinimumDataLabel => 'Sembrar Datos Mínimos';

  @override
  String get debugMediumDataSeededMessage => 'Datos medianos sembrados.';

  @override
  String get debugSeedMediumDataLabel => 'Sembrar Datos Medianos';

  @override
  String get debugMaximumDataSeededMessage => 'Datos máximos sembrados.';

  @override
  String get debugSeedMaximumDataLabel => 'Sembrar Datos Máximos (para prueba de rendimiento)';

  @override
  String get debugRunningInDebugModeLabel => 'Ejecutando en modo DEBUG';

  @override
  String get deleteAllButton => 'Eliminar Todo';

  @override
  String get changeButton => 'Cambiar';

  @override
  String get undoButton => 'Deshacer';

  @override
  String itemDeletedMessage(Object name) {
    return '$name eliminado';
  }

  @override
  String get totalBalanceLabel => 'Saldo Total';

  @override
  String get noCurrenciesSelected => 'No se han seleccionado monedas.';

  @override
  String get failedToLoadDashboard => 'Error al cargar el panel';

  @override
  String get dashboardCalendarTab => 'Calendario';

  @override
  String get dashboardTabCalendar => 'Calendario';

  @override
  String get dashboardCalendarTooltip => 'Vista de Calendario';

  @override
  String get dashboardCalendarDescription => 'Ver transacciones en formato de calendario';

  @override
  String get dashboardCategoriesTab => 'Categorías';

  @override
  String get dashboardTabCategories => 'Categorías';

  @override
  String get dashboardCategoriesTooltip => 'Análisis de Categorías';

  @override
  String get dashboardCategoriesDescription => 'Desglose de gastos por categoría';

  @override
  String get dashboardBalanceTab => 'Saldo';

  @override
  String get dashboardTabBalance => 'Saldo';

  @override
  String get dashboardBalanceTooltip => 'Historial de Saldo';

  @override
  String get dashboardBalanceDescription => 'Seguimiento del patrimonio neto a lo largo del tiempo';

  @override
  String get dashboardExpensesLabel => 'Gastos';

  @override
  String get dashboardIncomeLabel => 'Ingresos';

  @override
  String get manageIconsTitle => 'Gestionar Iconos';

  @override
  String get manageStylesDeleteTitle => 'Eliminar Iconos';

  @override
  String manageStylesDeleteConfirm(Object count) {
    return '¿Está seguro de que desea eliminar $count iconos seleccionados?';
  }

  @override
  String manageStylesDeleteConfirmWithTransfer(Object count) {
    return '¿Está seguro de que desea eliminar $count iconos seleccionados? (El icono de transferencia se omitirá)';
  }

  @override
  String get noIconsCreated => 'No se han creado iconos aún.';

  @override
  String get failedToLoadIcons => 'Error al cargar los iconos.';

  @override
  String get cannotDeleteTransferIcon => 'No se puede eliminar el icono de Transferencia.';

  @override
  String get deleteIconsDialogTitle => 'Eliminar Iconos';

  @override
  String deleteIconsConfirmationMessage(Object count) {
    return '¿Está seguro de que desea eliminar $count iconos seleccionados?';
  }

  @override
  String deleteIconsWithSkipTransferMessage(Object count) {
    return '¿Está seguro de que desea eliminar $count iconos seleccionados? (El icono de Transferencia se omitirá)';
  }

  @override
  String get deleteIconDialogTitle => 'Eliminar Icono';

  @override
  String deleteIconConfirmationMessage(Object name) {
    return '¿Está seguro de que desea eliminar \"$name\"?';
  }

  @override
  String deleteMultipleAccountsTitle(Object count) {
    return '¿Eliminar $count cuentas?';
  }

  @override
  String get deleteMultipleAccountsMessage => '¿Está seguro de que desea eliminar las cuentas seleccionadas? Todas las transacciones asociadas serán eliminadas.';

  @override
  String get changeAccountTypeDialogTitle => 'Cambiar Tipo de Cuenta';

  @override
  String editAccountTitle(Object name) {
    return 'Editar: $name';
  }

  @override
  String get balanceCalculatedFromAsset => 'El saldo se calcula a partir de Cantidad de Activo * Precio';

  @override
  String get selectAccountTypeTitle => 'Seleccionar Tipo de Cuenta';

  @override
  String get selectCountryTitle => 'Seleccionar País';

  @override
  String get selectIconSubtitle => 'Seleccionar un icono';

  @override
  String get bindToAssetLabel => 'Vincular a Activo (Opcional)';

  @override
  String get selectAssetTitle => 'Seleccionar Activo';

  @override
  String get selectedAssetLabel => 'Activo Seleccionado';

  @override
  String get balanceAutoCalculatedLabel => 'El saldo se calcula automáticamente';

  @override
  String get tapToBindAssetLabel => 'Toque para vincular un activo';

  @override
  String get assetQuantityLabel => 'Cantidad de Activo';

  @override
  String get linkedAssetsTitle => 'Activos Vinculados';

  @override
  String get noneLabel => 'Ninguno';

  @override
  String get accountTypeLabel => 'Tipo de Cuenta';

  @override
  String get formValidationPleaseSelectAccountType => 'Por favor, seleccione un tipo de cuenta';

  @override
  String get iconLabel => 'Icono';

  @override
  String get languageLabel => 'Idioma';

  @override
  String get systemDefaultLabel => 'Predeterminado del Sistema';

  @override
  String get selectLanguageTitle => 'Seleccionar Idioma';

  @override
  String get dashboardLabel => 'Panel';

  @override
  String get homeLabel => 'Inicio';

  @override
  String get historyLabel => 'Historial';

  @override
  String get syncScreenTitle => 'Configuración de Sincronización';

  @override
  String get syncP2PSection => 'Sincronización P2P (Syncthing)';

  @override
  String get syncEnableP2P => 'Activar Sincronización P2P';

  @override
  String get syncP2PSubtitle => 'Sincronizar mediante archivos .sync en una carpeta compartida';

  @override
  String get syncFolderLabel => 'Carpeta de Sincronización';

  @override
  String get syncFolderNotSelected => 'No seleccionado';

  @override
  String get syncBrowseButton => 'Examinar';

  @override
  String get syncClearFilesButton => 'Borrar archivos de sincronización';

  @override
  String get syncServerSection => 'Sincronización en la Nube (Servidor)';

  @override
  String get syncServerUrlLabel => 'URL del Servidor';

  @override
  String get syncApiTokenLabel => 'Token de API';

  @override
  String get syncApiTokenHint => 'Introduzca su token de seguridad';

  @override
  String get syncApiTokenHelp => 'Este token es su secreto compartido. Introduzca el mismo valor en todos sus dispositivos para autorizar la sincronización.';

  @override
  String get syncTestConnectionButton => 'Probar Conexión';

  @override
  String get syncTestingLabel => 'Probando...';

  @override
  String get syncSaveServerSettingsButton => 'Guardar Configuración del Servidor';

  @override
  String get syncEnableServer => 'Activar Sincronización con Servidor';

  @override
  String get syncServerSubtitle => 'Sincronizar con una instancia de MyBudget Server';

  @override
  String get syncPendingLocalChanges => 'Cambios locales pendientes:';

  @override
  String get syncSyncNowButton => 'Sincronizar Ahora';

  @override
  String get syncSyncingLabel => 'Sincronizando...';

  @override
  String get syncWebNotAvailable => 'La sincronización no está disponible en la Web';

  @override
  String get syncPermissionRequired => 'Se requiere permiso de almacenamiento para la sincronización. Por favor, active \"Acceso a todos los archivos\" en la configuración.';

  @override
  String get syncSelectFolderTitle => 'Seleccionar Carpeta de Syncthing';

  @override
  String get syncClearFilesTitle => 'Borrar Archivos de Sincronización';

  @override
  String get syncClearFilesConfirm => 'Esto eliminará todos los archivos .sync de la carpeta seleccionada. Esta acción no se puede deshacer.';

  @override
  String syncDeletedFilesCount(Object count) {
    return 'Se han eliminado $count archivos de sincronización';
  }

  @override
  String syncClearFilesError(Object error) {
    return 'Error al borrar archivos: $error';
  }

  @override
  String get syncSettingsSaved => 'Configuración del servidor guardada';

  @override
  String get syncConnectionSuccessful => '¡Conexión exitosa!';

  @override
  String get syncConnectionFailed => 'Conexión fallida. Compruebe la URL y el Token.';

  @override
  String get syncConnectionUnauthorized => 'El servidor rechazó el token. Revise el token, no la dirección.';

  @override
  String get syncServerNotConfigured => 'El servidor no tiene un token de sincronización configurado y rechaza todos los dispositivos. Defina SYNC_TOKEN en el servidor y use el mismo valor aquí.';

  @override
  String get syncCompleted => 'Sincronización completada con éxito';

  @override
  String syncFailed(Object error) {
    return 'Sincronización fallida: $error';
  }

  @override
  String get smsRuleAddTitle => 'Añadir Regla';

  @override
  String get smsRuleEditTitle => 'Editar Regla';

  @override
  String get smsRuleTransactionType => 'Tipo de Transacción';

  @override
  String get smsRuleMatchPattern => 'Patrón de Coincidencia (Regex)';

  @override
  String get smsRuleMatchPatternHint => 'ej., Pago.*con tarjeta';

  @override
  String get smsRuleMatchPatternHelp => 'Patrón para identificar este tipo de SMS';

  @override
  String get smsRuleAmountPattern => 'Patrón de Cantidad (Regex)';

  @override
  String get smsRuleAmountPatternHint => 'ej., importe\\s+([\\d,.]+)';

  @override
  String get smsRuleAmountPatternHelp => 'El Grupo 1 debe capturar la cantidad';

  @override
  String get smsRuleCurrencyPattern => 'Patrón de Moneda (Regex, opcional)';

  @override
  String get smsRuleCurrencyPatternHint => 'ej., [\\d,.]+\\s*(\\w\\w\\w)';

  @override
  String get smsRuleCurrencyPatternHelp => 'El Grupo 1 debe capturar el código de moneda';

  @override
  String get smsRuleTestTitle => 'Pruebe su Regla';

  @override
  String get smsRuleTestSmsHint => 'Pegue el texto del SMS aquí';

  @override
  String get smsRuleTestButton => 'Probar Patrón';

  @override
  String get smsRuleTestEnterSmsError => 'Introduzca el texto del SMS para probar';

  @override
  String get smsRuleTestMatchError => '✗ El patrón de coincidencia no encontró resultados';

  @override
  String get smsRuleTestAmountError => '✗ El patrón de cantidad no encontró resultados';

  @override
  String smsRuleTestSuccess(Object amount, Object currency, Object type) {
    return '✓ ¡Coincidencia encontrada!\nTipo: $type\nCantidad: $amount\nMoneda: $currency';
  }

  @override
  String smsRuleTestRegexError(Object error) {
    return '✗ Regex inválido: $error';
  }

  @override
  String get smsRuleRequiredError => 'Los patrones de Coincidencia y Cantidad son obligatorios';

  @override
  String inflationError(Object error) {
    return 'Error: $error';
  }

  @override
  String get inflationNoRatesFound => 'No se encontraron tasas de inflación.';

  @override
  String get inflationAddRate => 'Añadir Tasa de Inflación';

  @override
  String get inflationDeleteConfirmTitle => '¿Eliminar Tasas?';

  @override
  String inflationDeleteConfirmMessage(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasas',
      one: 'esta tasa',
    );
    return '¿Está seguro de que desea eliminar $_temp0?';
  }

  @override
  String inflationSelectedCount(Object count) {
    return '$count seleccionados';
  }

  @override
  String get inflationFiltersTitle => 'Filtros de Inflación';

  @override
  String get inflationCountries => 'Países';

  @override
  String get inflationPresets => 'Preajustes';

  @override
  String deleteCategoryConfirmTitle(Object name) {
    return '¿Eliminar $name?';
  }

  @override
  String get deleteCategoryMessage => 'Esta categoría tiene transacciones asociadas. ¿Qué le gustaría hacer?';

  @override
  String get deleteCategoryReassign => 'Reasignar transacciones a otra categoría';

  @override
  String get deleteCategoryNewCategory => 'Nueva Categoría';

  @override
  String get deleteCategoryDeleteAll => 'Eliminar todas las transacciones asociadas';

  @override
  String deleteAccountConfirmTitle(Object name) {
    return '¿Eliminar $name?';
  }

  @override
  String get deleteAccountMessage => 'Esta cuenta puede tener transacciones asociadas. ¿Qué le gustaría hacer?';

  @override
  String get deleteAccountReassign => 'Reasignar transacciones a otra cuenta';

  @override
  String get deleteAccountNewAccount => 'Nueva Cuenta';

  @override
  String get deleteAccountDeleteAll => 'Eliminar todas las transacciones asociadas';

  @override
  String get confirmButton => 'Confirmar';

  @override
  String get okButton => 'Aceptar';

  @override
  String get noItemsFound => 'No se han encontrado elementos.';

  @override
  String get noDataForPeriod => 'No hay datos para este periodo';

  @override
  String get noDataForRange => 'No hay datos para este rango';

  @override
  String get noHistoryData => 'No hay datos de historial disponibles';

  @override
  String get disabledByGlobalSync => 'Desactivado por Sincronización Global';

  @override
  String dateCreatedLabel(Object date) {
    return 'Fecha de creación: $date';
  }

  @override
  String get anyLabel => 'Cualquiera';

  @override
  String get balanceDisplayLabel => 'Visualización de Saldo';

  @override
  String currenciesActiveLabel(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count monedas activas',
      one: '1 moneda activa',
    );
    return '$_temp0';
  }

  @override
  String get searchCountryLabel => 'Buscar País';

  @override
  String get addNewIconLabel => 'Añadir Nuevo Icono';

  @override
  String get noIconsFoundLabel => 'No se han encontrado iconos';

  @override
  String get addNewStyleLabel => 'Añadir Nuevo Estilo';

  @override
  String get styleNameLabel => 'Nombre del Estilo';

  @override
  String get pleaseEnterStyleName => 'Por favor, introduzca un nombre de estilo';

  @override
  String get colorLabel => 'Color';

  @override
  String get netBalanceMetric => 'Saldo Net.';

  @override
  String get investedMetric => 'Invertido';

  @override
  String get realizedMetric => 'Realizado';

  @override
  String get feesMetric => 'Tasas';

  @override
  String get persistFiltersLabel => 'Persistir Filtros';

  @override
  String get searchByNameHint => 'Buscar por nombre...';

  @override
  String get searchDescriptionHint => 'Buscar descripción...';

  @override
  String get advancedFiltersTitle => 'Filtros Avanzados';

  @override
  String get transactionTypeLabel => 'Tipo de Transacción';

  @override
  String get assetFiltersTitle => 'Filtros de Activos';

  @override
  String get minValueLabel => 'Valor Mínimo';

  @override
  String get maxValueLabel => 'Valor Máximo';

  @override
  String get assetTypesLabel => 'Tipos de Activo';

  @override
  String get allLabel => 'Todo';

  @override
  String get currenciesLabel => 'Monedas';

  @override
  String get sourcesLabel => 'Fuentes';

  @override
  String get presetsLabel => 'Preajustes';

  @override
  String get enterCategoryNameHint => 'Introduzca el nombre de la categoría';

  @override
  String get selectTypeHint => 'Seleccionar Tipo';

  @override
  String get hotKeysTitle => 'Teclas Rápidas';

  @override
  String get searchHotkeysHint => 'Buscar teclas rápidas...';

  @override
  String get noMatchingHotkeys => 'No se han encontrado teclas rápidas coincidentes.';

  @override
  String recordingHotkeyTitle(Object label) {
    return 'Grabando Tecla Rápida para \"$label\"';
  }

  @override
  String get pressKeysHint => 'Presione las teclas...';

  @override
  String get pressAnyCombinationHint => 'Presione cualquier combinación de teclas.';

  @override
  String get clearSaveButton => 'Borrar / Guardar';

  @override
  String get duplicateHotkeyTooltip => 'Tecla Rápida Duplicada';

  @override
  String usedByLabel(Object action) {
    return 'Usado por $action';
  }

  @override
  String get hkCategoryNavigation => 'Navegación';

  @override
  String get hkCategoryDashboardTabs => 'Pestañas del Panel (Ctrl + 1/2/3)';

  @override
  String get hkCategoryDataTabs => 'Pestañas de Datos (Ctrl + 1/2/3)';

  @override
  String get hkCategoryPeriodControl => 'Control de Periodo';

  @override
  String get hkCategoryActions => 'Acciones';

  @override
  String get hkCategorySelectionMode => 'Modo de Selección';

  @override
  String get hkActionBack => 'Global: Volver / Salir';

  @override
  String get hkActionDashboard => 'Ir al Panel';

  @override
  String get hkActionAccounts => 'Ir a Cuentas';

  @override
  String get hkActionTransactions => 'Ir a Transacciones';

  @override
  String get hkActionCategories => 'Ir a Categorías';

  @override
  String get hkActionData => 'Ir a Datos / Tipos de Cambio';

  @override
  String get hkActionSettings => 'Ir a Configuración';

  @override
  String get hkActionDashboardTab1 => 'Pestaña de Calendario';

  @override
  String get hkActionDashboardTab2 => 'Pestaña de Categorías';

  @override
  String get hkActionDashboardTab3 => 'Pestaña de Saldo';

  @override
  String get hkActionDataTab1 => 'Tipos de Cambio';

  @override
  String get hkActionDataTab2 => 'Inflación';

  @override
  String get hkActionDataTab3 => 'Activos';

  @override
  String get hkActionPrevPeriod => 'Periodo Anterior';

  @override
  String get hkActionNextPeriod => 'Periodo Siguiente';

  @override
  String get hkActionAddAction => 'Acción de Añadir Genérica';

  @override
  String get hkActionPickDate => 'Seleccionar Fecha';

  @override
  String get hkActionSortOrder => 'Orden de Clasificación';

  @override
  String get hkActionFilterAction => 'Filtrar';

  @override
  String get hkActionAccountsSelectionClose => 'Cuentas: Cerrar';

  @override
  String get hkActionAccountsSelectionAll => 'Cuentas: Seleccionar Todo';

  @override
  String get hkActionAccountsSelectionDelete => 'Cuentas: Eliminar';

  @override
  String get hkActionAccountsSelectionChangeType => 'Cuentas: Cambiar Tipo';

  @override
  String get hkActionTransactionsSelectionClose => 'Transacciones: Cerrar';

  @override
  String get hkActionTransactionsSelectionDelete => 'Transacciones: Eliminar';

  @override
  String get hkActionTransactionsSelectionChangeDate => 'Transacciones: Cambiar Fecha';

  @override
  String get hkActionTransactionsSelectionChangeCategory => 'Transacciones: Cambiar Categoría';

  @override
  String get hkActionCategoriesSelectionClose => 'Categorías: Cerrar';

  @override
  String get hkActionCategoriesSelectionAll => 'Categorías: Seleccionar Todo';

  @override
  String get hkActionCategoriesSelectionDelete => 'Categorías: Eliminar';

  @override
  String get hkActionCategoriesSelectionChangeType => 'Categorías: Cambiar Tipo';

  @override
  String get hkActionDataSelectionClose => 'Tipos de Cambio: Cerrar';

  @override
  String get hkActionDataSelectionAll => 'Tipos de Cambio: Seleccionar Todo';

  @override
  String get hkActionDataSelectionDelete => 'Tipos de Cambio: Eliminar';

  @override
  String get hkActionDataSelectionChangePreset => 'Tipos de Cambio: Cambiar Preajuste';

  @override
  String get hkActionInflationSelectionClose => 'Inflación: Cerrar';

  @override
  String get hkActionInflationSelectionAll => 'Inflación: Seleccionar Todo';

  @override
  String get hkActionInflationSelectionDelete => 'Inflación: Eliminar';

  @override
  String get hkActionAssetSelectionClose => 'Activos: Cerrar';

  @override
  String get hkActionAssetSelectionAll => 'Activos: Seleccionar Todo';

  @override
  String get hkActionAssetSelectionDelete => 'Activos: Eliminar';

  @override
  String get styNotFound => 'Estilo no encontrado.';

  @override
  String get stySaveChanges => 'Guardar Cambios';

  @override
  String get styAddIcon => 'Añadir Icono';

  @override
  String get smsOnlyAndroid => 'La importación SMS solo está disponible en Android';

  @override
  String get smsImportSms => 'Importar SMS';

  @override
  String get smsPermissionRequired => 'Se Requiere Permiso de SMS';

  @override
  String get smsPermissionRationale => 'Para importar transacciones desde SMS, necesitamos permiso para leer sus mensajes.';

  @override
  String get smsGrantPermission => 'Conceder Permiso';

  @override
  String get smsNoPresets => 'No hay preajustes configurados. Toque + para añadir uno.';

  @override
  String get smsImportDescription => 'Importar transacciones desde mensajes SMS. Elija un rango de tiempo:';

  @override
  String get smsLast7Days => 'Últimos 7 Días';

  @override
  String get smsAllTime => 'Todo el Tiempo';

  @override
  String smsFilterLabel(Object filter) {
    return 'Filtro: $filter';
  }

  @override
  String get smsEditPreset => 'Editar Preajuste';

  @override
  String get smsNewPreset => 'Nuevo Preajuste';

  @override
  String get smsPresetNameHint => 'ej., Mi Banco';

  @override
  String get smsSenderFilter => 'Filtro de Remitente';

  @override
  String get smsSenderFilterHint => 'ej., ALTA o +381...';

  @override
  String get smsSenderFilterHelper => 'Filtrar SMS por nombre del remitente o número de teléfono';

  @override
  String get smsDefaults => 'Predeterminados';

  @override
  String get smsDefaultAccount => 'Cuenta Predeterminada';

  @override
  String get smsDefaultCategory => 'Categoría Predeterminada';

  @override
  String get smsImportMessages => 'Importar Mensajes';

  @override
  String get smsSelectDefaultsFirst => 'Seleccione primero los predeterminados';

  @override
  String get smsCustomRange => 'Rango Personalizado';

  @override
  String smsImportSuccessCount(Object count) {
    return 'Éxito: $count transacciones importadas';
  }

  @override
  String get smsParsingRules => 'Reglas de Análisis';

  @override
  String get smsNoRules => 'No hay reglas definidas. Toque + para añadir una.';

  @override
  String smsMatchLabel(Object pattern) {
    return 'Coincidencia: $pattern';
  }

  @override
  String get smsNameSenderRequired => 'El nombre y el filtro de remitente son obligatorios';

  @override
  String get smsCategoryKeywords => 'Palabras Clave de Categoría';

  @override
  String get smsCategoryKeywordsSubtitle => 'Asignar palabras clave del texto del SMS a categorías';

  @override
  String get smsNoKeywordRules => 'No hay reglas de palabras clave. Toque + para añadir una.';

  @override
  String get smsAddKeywordRule => 'Añadir Regla de Palabra Clave';

  @override
  String get smsKeyword => 'Palabra Clave';

  @override
  String get smsKeywordHint => 'ej., Supermercado, Netflix';

  @override
  String get smsKeywordHelper => 'Subcadena sin distinción de mayúsculas a buscar en el texto del SMS';

  @override
  String get smsSelectCategoryHint => 'Seleccionar categoría';

  @override
  String get dshSelectDateDescription => 'Abrir el calendario para elegir una fecha o rango específico';

  @override
  String get dshCurrencyDescription => 'Seleccionar la moneda principal para mostrar';

  @override
  String get dshChangeViewTooltip => 'Cambiar Vista';

  @override
  String get dshChangeViewDescription => 'Cambiar entre vista Mensual y Anual';

  @override
  String get dshMonthlyAbbreviation => 'M';

  @override
  String get dshYearlyAbbreviation => 'A';

  @override
  String dshBalancesOnDate(Object date) {
    return 'Saldos al $date';
  }

  @override
  String get dshSearchCurrency => 'Buscar Moneda';

  @override
  String get dshUnknownCategory => 'Desconocido';

  @override
  String get pckSelectItem => 'Seleccionar Elemento';

  @override
  String get pckSelectItems => 'Seleccionar Elementos';

  @override
  String get pckClearAll => 'Limpiar Todo';

  @override
  String get pckSelectIcon => 'Seleccionar Icono';

  @override
  String get pckMaterialIcons => 'Iconos Material';

  @override
  String get pckCustomIcons => 'Iconos Personalizados';

  @override
  String get fltAmountFrom => 'Cantidad Desde';

  @override
  String get fltAmountTo => 'Cantidad Hasta';

  @override
  String get fltSelectRange => 'Seleccionar Rango';

  @override
  String get fltAdvancedFilterTooltip => 'Filtro Avanzado';

  @override
  String get fltAdvancedFilterDescription => 'Filtrar transacciones por cuenta, categoría o cantidad';

  @override
  String get fltSortOrderDescription => 'Cambiar entre orden ascendente y descendente';

  @override
  String get fltAccountFiltersTitle => 'Filtros de Cuentas';

  @override
  String get fltNameLabel => 'Nombre';

  @override
  String get fltAccountTypesLabel => 'Tipos de Cuenta';

  @override
  String get fltFilterCurrenciesLabel => 'Filtrar Monedas';

  @override
  String get fltSelectCurrenciesLabel => 'Seleccionar Monedas';

  @override
  String get fltFilterCategoriesTitle => 'Filtrar Categorías';

  @override
  String get exchAddExchangeRate => 'Añadir Tipo de Cambio';

  @override
  String get exchEditExchangeRate => 'Editar Tipo de Cambio';

  @override
  String get exchAddRateDescription => 'Introducir manualmente un tipo de conversión entre dos monedas';

  @override
  String get exchNoRatesFound => 'No se encontraron tipos de cambio.';

  @override
  String get exchChangePreset => 'Cambiar Preajuste';

  @override
  String get exchFromCurrency => 'Moneda de Origen';

  @override
  String get exchToCurrency => 'Moneda de Destino';

  @override
  String get exchRate => 'Tipo de Cambio';

  @override
  String get exchPresetIdLabel => 'ID de Preajuste';

  @override
  String exchPresetValue(Object preset) {
    return 'Preajuste: $preset';
  }

  @override
  String get exchSelectRange => 'Seleccionar Rango';

  @override
  String get exchPreviousPeriodDescription => 'Ir al día, mes o año anterior';

  @override
  String get exchNextPeriodDescription => 'Ir al día, mes o año siguiente';

  @override
  String get exchFilterDescription => 'Filtrar tipos por moneda de origen/destino e ID de preajuste';

  @override
  String get exchSelectDateDescription => 'Elegir una fecha o rango específico para ver tipos históricos';

  @override
  String get exchSortOrderDescription => 'Cambiar entre orden ascendente y descendente por fecha/tipo';

  @override
  String get exchFilterExchangeRates => 'Filtrar Tipos de Cambio';

  @override
  String get exchExitSelectionDescription => 'Salir del modo de selección de tipos de cambio';

  @override
  String get exchSelectAllDescription => 'Seleccionar todos los tipos de cambio listados';

  @override
  String get exchDeselectAllDescription => 'Deseleccionar todos los tipos';

  @override
  String get exchChangePresetDescription => 'Actualizar el ID de preajuste de todos los tipos de cambio seleccionados';

  @override
  String get exchDeleteSelectedDescription => 'Eliminar permanentemente todos los tipos de cambio seleccionados';

  @override
  String get exchDeleteExchangeRatesTitle => 'Eliminar Tipos de Cambio';

  @override
  String exchDeleteConfirmMessage(Object count) {
    return '¿Está seguro de que desea eliminar $count tipos de cambio?';
  }

  @override
  String get exchUpdatePresetTitle => 'Actualizar Preajuste';

  @override
  String get exchUpdatePresetMessage => 'Introduzca el nuevo ID de preajuste para los elementos seleccionados:';

  @override
  String dashboardUnconvertibleCurrencies(String currencies) {
    return 'No se pudo convertir $currencies; esos importes no se incluyen en el total';
  }

  @override
  String get addAccountBeforeTransactionDescription => 'Una transacción necesita una cuenta. Cree la primera para empezar';

  @override
  String get selectDialogEmptyState => 'Todavía no hay nada para elegir';

  @override
  String get selectDialogNoMatches => 'No hay resultados para su búsqueda';

  @override
  String get addButton => 'Añadir';

  @override
  String get retryButton => 'Reintentar';

  @override
  String get unknownLabel => 'Desconocido';

  @override
  String get globalLabel => 'Global';

  @override
  String dateWithValueLabel(String date) {
    return 'Fecha: $date';
  }

  @override
  String selectColorTitle(String label) {
    return 'Seleccionar color $label';
  }

  @override
  String get assetAddTitle => 'Añadir datos del activo';

  @override
  String get assetEditTitle => 'Editar datos del activo';

  @override
  String get assetAddDescription => 'Registrar el valor o la cantidad de un activo concreto';

  @override
  String get assetNameLabel => 'Nombre del activo (p. ej. acciones de Apple)';

  @override
  String get assetIdLabel => 'ID del activo (p. ej. AAPL)';

  @override
  String get assetValueLabel => 'Valor (precio por unidad)';

  @override
  String get assetTypeOptionalLabel => 'Tipo de activo (opcional)';

  @override
  String get assetLinkedAccountOptionalLabel => 'Cuenta vinculada (opcional)';

  @override
  String get assetNameRequiredError => 'Ponle un nombre al activo';

  @override
  String get assetIdRequiredError => 'Indica un ID para el activo, por ejemplo AAPL';

  @override
  String get assetValueInvalidError => 'Introduce un número, por ejemplo 150,25';

  @override
  String get assetNoAssetsFound => 'No se encontraron activos.';

  @override
  String assetError(String error) {
    return 'Error: $error';
  }

  @override
  String get assetDeleteConfirmTitle => '¿Eliminar activos?';

  @override
  String assetDeleteConfirmMessage(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
      
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString activos',
      one: 'este activo',
    );
    return '¿Está seguro de que desea eliminar $_temp0?';
  }

  @override
  String get assetDeleteSelectedDescription => 'Eliminar definitivamente todos los registros de activos seleccionados';

  @override
  String get inflationEditRate => 'Editar tasa de inflación';

  @override
  String get inflationAddDescription => 'Introduce un nuevo porcentaje de inflación para una fecha y un país concretos';

  @override
  String get inflationPercentLabel => 'Porcentaje de inflación (%)';

  @override
  String get inflationPercentHint => 'p. ej. 2,5';

  @override
  String get inflationPercentInvalidError => 'Introduce un número, por ejemplo 2,5';

  @override
  String get inflationCountryGlobal => 'País: global';

  @override
  String inflationCountryNamed(String country) {
    return 'País: $country';
  }

  @override
  String get inflationUseWorldwideRate => 'Usar la tasa mundial';

  @override
  String get pickerSingleDate => 'Fecha única';

  @override
  String get pickerRange => 'Rango';

  @override
  String get dateStepDay => 'Día';

  @override
  String get dateStepMonth => 'Mes';

  @override
  String get dateStepYear => 'Año';

  @override
  String get feeStructureTitle => 'Estructura de comisiones';

  @override
  String get feeNoRulesApplied => 'No se aplican reglas de comisión.';

  @override
  String get feeAddRule => 'Añadir regla de comisión';

  @override
  String get feeFixedFee => 'Comisión fija';

  @override
  String get feePercentFee => 'Comisión porcentual';

  @override
  String get feeTaxRate => 'Tasa impositiva';

  @override
  String get feeUnknownRule => 'Regla desconocida';

  @override
  String get feeRatePercentLabel => 'Tasa (%)';

  @override
  String get feeTaxRatePercentLabel => 'Tasa impositiva (%)';

  @override
  String get feeCostBasisLabel => 'Coste base';

  @override
  String deleteAccountsConfirmTitle(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
      
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString cuentas',
      one: 'esta cuenta',
    );
    return '¿Eliminar $_temp0?';
  }

  @override
  String get deleteAccountsConfirmMessage => '¿Seguro que quieres eliminar las cuentas seleccionadas? Se eliminarán todas las transacciones asociadas.';

  @override
  String get changeAccountTypeTitle => 'Cambiar tipo de cuenta';

  @override
  String get accountsPreviousPeriodDescription => 'Ir al mes o año anterior';

  @override
  String get accountsNextPeriodDescription => 'Ir al mes o año siguiente';

  @override
  String get accountsFilterDescription => 'Filtrar cuentas por tipo o por estado oculto';

  @override
  String get accountsSelectDateDescription => 'Elige una fecha concreta para ver los saldos históricos';

  @override
  String get accountsSortDescription => 'Alternar entre orden ascendente y descendente del saldo';

  @override
  String get smsRuleCategoryOptional => 'Categoría (opcional)';

  @override
  String get smsRuleCategoryHelp => 'Sustituir la categoría para esta regla';
}
