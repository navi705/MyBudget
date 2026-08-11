// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get collapseMenuTooltip => 'Recolher Menu';

  @override
  String get expandMenuTooltip => 'Expandir Menu';

  @override
  String get helloWorld => 'Olá Mundo!';

  @override
  String get accountsAppBarTitle => 'Contas';

  @override
  String accountsBalanceLabel(Object balance) {
    return 'Saldo: $balance';
  }

  @override
  String get accountsLoadFailure => 'Falha ao carregar contas';

  @override
  String get accountsEmptyState => 'Sem contas';

  @override
  String get accountsRefreshTooltip => 'Atualizar';

  @override
  String get accountsAddTooltip => 'Adicionar Conta';

  @override
  String get addAccountDescription => 'Criar uma nova conta bancária, carteira ou ativo';

  @override
  String get addAccountDialogTitle => 'Adicionar nova conta';

  @override
  String get editAccountDialogTitle => 'Editar Conta';

  @override
  String get accountNameHint => 'Nome da conta';

  @override
  String get initialBalanceHint => 'Saldo inicial';

  @override
  String get currencyLabel => 'Moeda';

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get saveButton => 'Salvar';

  @override
  String get deleteButton => 'Excluir';

  @override
  String get editButton => 'Editar';

  @override
  String get applyButton => 'Aplicar';

  @override
  String get clearButton => 'Limpar';

  @override
  String get selectButton => 'Selecionar';

  @override
  String get selectAllButton => 'Selecionar Tudo';

  @override
  String get deselectAllButton => 'Desmarcar Tudo';

  @override
  String get deleteSelectedButton => 'Excluir Selecionados';

  @override
  String totalCountLabel(Object count) {
    return 'Total: $count';
  }

  @override
  String selectedCountLabel(Object count) {
    return '$count selecionados';
  }

  @override
  String get formValidationPleaseEnterName => 'Por favor, insira um nome';

  @override
  String get formValidationPleaseEnterBalance => 'Por favor, insira um saldo';

  @override
  String get formValidationPleaseEnterValidNumber => 'Por favor, insira um número válido';

  @override
  String get formValidationPleaseSelectCurrency => 'Por favor, selecione uma moeda';

  @override
  String get currencyLoadError => 'Erro ao carregar moedas';

  @override
  String get noCurrenciesAvailable => 'Nenhuma moeda disponível';

  @override
  String get categoriesAppBarTitle => 'Categorias';

  @override
  String get categoriesScreenBody => 'Tela de Categorias';

  @override
  String get transactionsAppBarTitle => 'Transações';

  @override
  String get transactionsScreenBody => 'Tela de Transações';

  @override
  String get settingsAppBarTitle => 'Configurações';

  @override
  String get settingsScreenBody => 'Tela de Configurações';

  @override
  String get filePickerChooserTitle => 'Selecionar Arquivo';

  @override
  String get imagePickerChooserTitle => 'Selecionar Imagem';

  @override
  String get totalNetWorth => 'Patrimônio Líquido Total';

  @override
  String get currencyBreakdown => 'Detalhamento por Moeda';

  @override
  String get dashboardNetWorthTrend => 'Tendência do Patrimônio Líquido';

  @override
  String get dashboardWealthDistributionByAccount => 'Distribuição de Riqueza (por Conta)';

  @override
  String get dashboardCurrencyExposure => 'Exposição de Moeda';

  @override
  String get dashboardNoAccountsFound => 'Nenhuma conta encontrada';

  @override
  String get dashboardTotalNetWorthTrend => 'Tendência Total do Patrimônio Líquido';

  @override
  String get dashboardAccountBalanceTrend => 'Tendência do Saldo da Conta';

  @override
  String get dashboardWealthDistribution => 'Distribuição de Riqueza';

  @override
  String get dashboardCurrencyBreakdown => 'Detalhamento por Moeda';

  @override
  String get metricBalance => 'Saldo';

  @override
  String get metricIncome => 'Receitas';

  @override
  String get metricExpense => 'Despesas';

  @override
  String get metricReal => 'Real';

  @override
  String get metricChange => 'Variação';

  @override
  String get contextMenuSelect => 'Selecionar';

  @override
  String get contextMenuDeselect => 'Desmarcar';

  @override
  String get contextMenuSelectAll => 'Selecionar Tudo';

  @override
  String get contextMenuDeselectAll => 'Desmarcar Tudo';

  @override
  String get contextMenuAddTransaction => 'Adicionar Transação';

  @override
  String get addTransactionDescription => 'Criar uma nova transação';

  @override
  String get contextMenuTransfer => 'Transferência';

  @override
  String get contextMenuEdit => 'Editar';

  @override
  String get contextMenuDelete => 'Excluir';

  @override
  String get contextMenuChangeType => 'Alterar Tipo';

  @override
  String deleteConfirmationTitle(Object item) {
    return 'Excluir $item?';
  }

  @override
  String deleteConfirmationMessage(Object item) {
    return 'Tem certeza de que deseja excluir este $item e todos os seus dados?';
  }

  @override
  String get deleteAccountsConfirmationTitle => 'Excluir contas?';

  @override
  String deleteAccountsConfirmationMessage(Object count) {
    return 'Excluir $count contas selecionadas e suas transações?';
  }

  @override
  String get deleteAccountDialogReassign => 'Reatribuir transações para outra conta';

  @override
  String get deleteAccountDialogDeleteAll => 'Excluir todas as transações associadas';

  @override
  String get deleteAccountDialogMessage => 'Esta conta pode ter transações associadas. O que você gostaria de fazer?';

  @override
  String get newAccountLabel => 'Nova Conta';

  @override
  String get warningOverwriteTitle => 'Aviso: Sobrescrever Dados?';

  @override
  String get warningOverwriteMessage => 'Restaurar um backup APAGARÁ TODOS os dados atuais e os substituirá pelo backup. Isso não pode ser desfeito.';

  @override
  String get restoreOverwriteButton => 'Restaurar e Sobrescrever';

  @override
  String get importSuccess => 'Importação concluída com sucesso.';

  @override
  String importFailed(Object error) {
    return 'Falha na importação: $error';
  }

  @override
  String deleteCategoriesConfirmationTitle(Object count) {
    return 'Excluir $count categorias?';
  }

  @override
  String get deleteCategoriesConfirmationMessage => 'Tem certeza de que deseja excluir as categorias selecionadas?';

  @override
  String get changeCategoryTypeDialogTitle => 'Alterar Tipo de Categoria';

  @override
  String get noCategoriesCreated => 'Nenhuma categoria criada ainda.';

  @override
  String get addCategoryTooltip => 'Adicionar Categoria';

  @override
  String get addCategoryDescription => 'Criar uma nova categoria de despesa ou receita';

  @override
  String get previousPeriodTooltip => 'Período Anterior';

  @override
  String get previousPeriodDescription => 'Ir para o mês ou ano anterior';

  @override
  String get nextPeriodTooltip => 'Próximo Período';

  @override
  String get nextPeriodDescription => 'Ir para o mês ou ano seguinte';

  @override
  String get filterTooltip => 'Filtrar';

  @override
  String get filterCategoriesDescription => 'Filtrar categorias por tipo (Receita/Despesa)';

  @override
  String get selectDateTooltip => 'Selecionar Data';

  @override
  String get selectDateDescription => 'Escolher um intervalo de datas específico para ver totais';

  @override
  String get sortOrderTooltip => 'Ordem de Classificação';

  @override
  String get sortOrderDescription => 'Alternar entre ordem crescente e decrescente por valor';

  @override
  String get closeSelectionTooltip => 'Fechar Seleção';

  @override
  String get exitSelectionDescription => 'Sair do modo de seleção';

  @override
  String get categoryNameLabel => 'Nome da Categoria';

  @override
  String get categoriesChangeButton => 'Alterar';

  @override
  String get parentCategoryLabel => 'Categoria Pai';

  @override
  String get styleLabel => 'Estilo (Ícone e Cor)';

  @override
  String get typeLabel => 'Tipo';

  @override
  String get deleteTransactionsConfirmationTitle => 'Excluir Transações';

  @override
  String deleteTransactionsConfirmationMessage(Object count) {
    return 'Tem certeza de que deseja excluir $count transações selecionadas?';
  }

  @override
  String get exitTransactionsSelectionDescription => 'Sair do modo de seleção de transações';

  @override
  String get changeDateTooltip => 'Alterar Data';

  @override
  String get changeDateDescription => 'Atualizar a data para todas as transações selecionadas';

  @override
  String get changeCategoryTooltip => 'Alterar Categoria';

  @override
  String get changeCategoryDescription => 'Atualizar a categoria para todas as transações selecionadas';

  @override
  String get deleteTransactionsTooltip => 'Excluir Selecionadas';

  @override
  String get deleteTransactionsDescription => 'Excluir permanentemente todas as transações selecionadas';

  @override
  String get amountLabel => 'Valor';

  @override
  String quantityLabel(Object quantity) {
    return 'Qtd: $quantity';
  }

  @override
  String get quantityFormLabel => 'Quantidade';

  @override
  String get selectAccountTitle => 'Selecionar Conta';

  @override
  String get selectCategoryTitle => 'Selecionar Categoria';

  @override
  String get selectCurrencyTitle => 'Selecionar Moeda';

  @override
  String get accountLabel => 'Conta';

  @override
  String get fromAccountLabel => 'Da Conta';

  @override
  String get toAccountLabel => 'Para Conta';

  @override
  String get categoryLabel => 'Categoria';

  @override
  String get dateLabel => 'Data';

  @override
  String get selectDateLabel => 'Selecionar Data';

  @override
  String get addTransactionTitle => 'Adicionar Transação';

  @override
  String get editTransactionTitle => 'Editar Transação';

  @override
  String get newTransferTitle => 'Nova Transferência';

  @override
  String get editTransferTitle => 'Editar Transferência';

  @override
  String get descriptionLabel => 'Descrição';

  @override
  String get descriptionOptionalLabel => 'Descrição (Opcional)';

  @override
  String get swapAccountsTooltip => 'Inverter Contas';

  @override
  String get incomeType => 'Receita';

  @override
  String get expenseType => 'Despesa';

  @override
  String get failedToLoadData => 'Falha ao carregar dados';

  @override
  String get invalidAmountError => 'Por favor, insira um número válido';

  @override
  String get emptyAmountError => 'Por favor, insira um valor';

  @override
  String get selectAccountError => 'Por favor, selecione uma conta';

  @override
  String get selectCategoryError => 'Por favor, selecione uma categoria';

  @override
  String get selectDateError => 'Por favor, selecione uma data';

  @override
  String get currencyLockedMessage => 'Bloqueado na moeda da Conta de Origem';

  @override
  String get totalValueLabel => 'Valor Total';

  @override
  String get feeLabel => 'Taxa';

  @override
  String get exchangeRateLabel => 'Taxa de Câmbio';

  @override
  String get pricePerUnitLabel => 'Preço por unidade';

  @override
  String get buyAction => 'Comprar';

  @override
  String get sellAction => 'Vender';

  @override
  String transferToDescription(Object accountName) {
    return 'Transferência para $accountName';
  }

  @override
  String transferFromDescription(Object accountName) {
    return 'Transferência de $accountName';
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
    return 'Transferência para $action $assetName';
  }

  @override
  String get swapDirectionTooltip => 'Inverter Direção';

  @override
  String get availablePresetsLabel => 'Predefinições Disponíveis:';

  @override
  String get updateButton => 'Atualizar';

  @override
  String get newPresetButton => 'Nova Predefinição';

  @override
  String get amountToAddToAccountLabel => 'Valor a Adicionar à Conta:';

  @override
  String valueInGlobalLabel(Object currency) {
    return 'Valor em Global ($currency):';
  }

  @override
  String get feeCommissionLabel => 'Taxa (Comissão)';

  @override
  String get requiredError => 'Obrigatório';

  @override
  String currentPriceLabel(Object currency, Object price) {
    return 'Preço Atual: $price $currency';
  }

  @override
  String get linkedAccountLabel => 'Conta Vinculada';

  @override
  String get selectLinkedAccountTitle => 'Selecionar Conta Vinculada';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get manageIconsLabel => 'Gerenciar Ícones';

  @override
  String get manageThemeLabel => 'Gerenciar Tema';

  @override
  String get mainCurrencyLabel => 'Moeda Principal';

  @override
  String get defaultInflationCountryLabel => 'País de Inflação Padrão';

  @override
  String get persistAdvancedFiltersLabel => 'Persistir Filtros Avançados';

  @override
  String get hotKeysLabel => 'Teclas de Atalho';

  @override
  String get smsImportLabel => 'Importação SMS';

  @override
  String get smsImportSubtitle => 'Importar transações de SMS bancários';

  @override
  String get apiManagementLabel => 'Gerenciamento de API';

  @override
  String get dataLabel => 'Dados';

  @override
  String get syncSettingsLabel => 'Configurações de Sincronização';

  @override
  String get syncSettingsSubtitle => 'Sincronização P2P via Syncthing';

  @override
  String get themeSettingsTitle => 'Configurações do Tema';

  @override
  String get appearanceSection => 'Aparência';

  @override
  String get themeModeLabel => 'Modo de Tema';

  @override
  String get systemTheme => 'Sistema';

  @override
  String get lightTheme => 'Claro';

  @override
  String get darkTheme => 'Escuro';

  @override
  String get colorCustomizationSection => 'Personalização de Cores';

  @override
  String get primaryColorLabel => 'Color Primário';

  @override
  String get secondaryColorLabel => 'Cor Secundário';

  @override
  String get surfaceColorLabel => 'Cor de Superfície';

  @override
  String get windowEffectsSection => 'Efeitos de Janela (Desktop)';

  @override
  String get enableEffectsLabel => 'Ativar Efeitos de Janela';

  @override
  String get windowEffectLabel => 'Efeito de Janela';

  @override
  String get backgroundLabel => 'Plano de Fundo';

  @override
  String get removeBackgroundColor => 'Remover cor do plano de fundo';

  @override
  String get transparentSurfaceLabel => 'Superfície Transparente (Cartas)';

  @override
  String get fullyTransparentLabel => 'Totalmente Transparente';

  @override
  String get opaqueLabel => 'Opaco';

  @override
  String opacityLabel(Object value) {
    return 'Opacidade: $value%';
  }

  @override
  String get backgroundSettingsSection => 'Configurações do Plano de Fundo';

  @override
  String get enableBackgroundImageLabel => 'Ativar Imagem de Plano de Fundo';

  @override
  String get backgroundBlurLabel => 'Desfoque do Plano de Fundo';

  @override
  String get surfaceGlassStyleTitle => 'Estilo de Superfície/Vidro';

  @override
  String get chooseImageButton => 'Escolher Imagem';

  @override
  String get selectImageFileError => 'Por favor, selecione um arquivo de imagem.';

  @override
  String get clearImageButton => 'Limpar Imagem';

  @override
  String get saveThemePresetTitle => 'Salvar Predefinição de Tema';

  @override
  String get presetNameLabel => 'Nome da Predefinição';

  @override
  String get presetNameHint => 'Meu Tema Incrível';

  @override
  String get importDataLabel => 'Importar Dados';

  @override
  String get exportDataLabel => 'Exportar Dados';

  @override
  String get exportFormatMessage => 'Escolher formato:\n\nJSON: Backup completo de todos os dados.\nCSV: Relatório legível de transações.';

  @override
  String get jsonFormat => 'JSON';

  @override
  String get csvFormat => 'CSV';

  @override
  String get importExchangeRatesLabel => 'Importar Taxas de Câmbio (CSV/JSON)';

  @override
  String get resetDataLabel => 'Redefinir Dados para Padrões';

  @override
  String get resetDataSubtitle => 'Isso excluirá todos os dados e restaurará as configurações padrão.';

  @override
  String get debugMenuLabel => 'Menu de Depuração';

  @override
  String get debugMenuSubtitle => 'Ferramentas internas de desenvolvedor';

  @override
  String get apiManagementTitle => 'Gerenciamento de API';

  @override
  String get apiCategoriesSection => 'Categorias de API';

  @override
  String get manualUtilitiesSection => 'Utilidades Manuais';

  @override
  String get startupDataSyncLabel => 'Sincronização de Dados na Inicialização';

  @override
  String get startupDataSyncDescription => 'Controla tanto a obtenção de dados externos quanto a sincronização do servidor na inicialização do aplicativo.';

  @override
  String get standardApiLabel => 'API Padrão';

  @override
  String get syncOnStartupDescription => 'Sincronizar na inicialização';

  @override
  String get customSourcesLabel => 'Fontes Personalizadas';

  @override
  String syncCustomSourcesDescription(Object count) {
    return 'Sincronizar todas ($count) na inicialização';
  }

  @override
  String get individualCustomSourcesTitle => 'Fontes Personalizadas Individuais';

  @override
  String get noCustomSourcesAdded => 'Nenhuma fonte personalizada adicionada.';

  @override
  String get fetchTodaysRatesButton => 'Buscar Taxas de Hoje';

  @override
  String get inflationConfigTitle => 'Configuração de Inflação';

  @override
  String get countryCodeHint => 'Código do País (ex. SRB)';

  @override
  String fetchDataForCountryButton(Object country) {
    return 'Buscar Dados para $country';
  }

  @override
  String get steamSettingsTitle => 'Configurações da Steam';

  @override
  String get steamIdLabel => 'ID da Steam (64 bits)';

  @override
  String get preferredGameLabel => 'Jogo Preferido';

  @override
  String get fetchInventoryNowButton => 'Buscar Inventário Agora';

  @override
  String get manualExchangeRatesTitle => 'Busca Manual de Taxas de Câmbio';

  @override
  String get selectStartDate => 'Selecionar Data de Início';

  @override
  String startDateFrom(Object date) {
    return 'De: $date';
  }

  @override
  String get selectEndDate => 'Selecionar Data de Término';

  @override
  String endDateTo(Object date) {
    return 'Para: $date';
  }

  @override
  String get fetchRangeButton => 'Buscar Intervalo';

  @override
  String get manualSteamInventoryTitle => 'Inventário Manual da Steam';

  @override
  String get selectGameHint => 'Selecionar Jogo';

  @override
  String get fetchValueButton => 'Buscar Valor';

  @override
  String get manualInflationDataTitle => 'Dados Manuais de Inflação';

  @override
  String get selectStartYear => 'Selecionar Ano de Início';

  @override
  String startYearFrom(Object year) {
    return 'De: $year';
  }

  @override
  String get selectEndYear => 'Selecionar Ano de Término';

  @override
  String endYearTo(Object year) {
    return 'Para: $year';
  }

  @override
  String get fetchDataButton => 'Buscar Dados';

  @override
  String get connectionOk => 'Conexão OK';

  @override
  String get connectionFailed => 'Falha na Conexão';

  @override
  String get testConnectionButton => 'Testar Conexão';

  @override
  String get editCustomSourceTitle => 'Editar Fonte Personalizada';

  @override
  String get addCustomSourceTitle => 'Adicionar Fonte Personalizada';

  @override
  String get addressFormatsHelp => 'Formatos de Endereço:\n• 192.168.1.10 (IP)\n• localhost ou api.my.com\n• http://myserver.com';

  @override
  String get urlIpLabel => 'URL / IP';

  @override
  String get urlIpHint => '192.168.1.10:8080';

  @override
  String get dataTypeLabel => 'Tipo de Dados';

  @override
  String get apiTitleExchangeRates => 'Taxas de Câmbio';

  @override
  String get apiTitleInflation => 'Inflação';

  @override
  String get apiTitleAssetPrices => 'Preços de Ativos';

  @override
  String get apiTitleSteamInventory => 'Inventário da Steam';

  @override
  String get transferLabel => 'Transferência';

  @override
  String get uncategorizedLabel => 'Sem Categoria';

  @override
  String get defaultLabel => 'Padrão';

  @override
  String receivedTotalLabel(Object total) {
    return 'Recebido: $total';
  }

  @override
  String spentTotalLabel(Object total) {
    return 'Gasto: $total';
  }

  @override
  String get periodSummaryTitle => 'Resumo do Período';

  @override
  String get incomeLabel => 'Receita';

  @override
  String get expenseLabel => 'Despesa';

  @override
  String get netLabel => 'Líquido';

  @override
  String get exportSuccessMessage => 'Exportação concluída com sucesso';

  @override
  String exportFailedMessage(Object error) {
    return 'Falha na exportação: $error';
  }

  @override
  String get importSuccessMessage => 'Importação concluída com sucesso';

  @override
  String importFailedMessage(Object error) {
    return 'Falha na importação: $error';
  }

  @override
  String get resetDataConfirmationTitle => 'Redefinir Dados?';

  @override
  String get resetDataConfirmationMessage => 'Aviso! Isso excluirá TODAS as suas transações, contas e configurações.\n\nO aplicativo será restaurado ao seu estado inicial com dados padrão.\nEsta ação NÃO pode ser desfeita.';

  @override
  String get resetEverythingButton => 'Redefinir Tudo';

  @override
  String get resetSuccessMessage => 'Dados redefinidos e padrões restaurados.';

  @override
  String resetFailedMessage(Object error) {
    return 'Falha na redefinição: $error';
  }

  @override
  String get importParsingStep => 'Analisando arquivos CSV...';

  @override
  String get importFetchingRatesStep => 'Buscando taxas de câmbio...';

  @override
  String importErrorLabel(Object error) {
    return 'Erro: $error';
  }

  @override
  String get importOneMoneyLabel => 'Importar do OneMoney (CSV)';

  @override
  String get importMyBudgetLabel => 'Importar transações do MyBudget (CSV)';

  @override
  String get restoreBackupLabel => 'Restaurar backup (JSON)';

  @override
  String get importSelectionHelp => 'Selecione \'OneMoney\' para migração, \'MyBudget\' para adicionar transações ou \'Restaurar Backup\' para sobrescrever todos os dados.';

  @override
  String get importCreateAllNew => 'Criar Tudo Novo';

  @override
  String importNewAccountFound(Object accountName) {
    return 'Nova conta encontrada: \"$accountName\"';
  }

  @override
  String importMapAccountTitle(Object accountName) {
    return 'Mapear \"$accountName\" para...';
  }

  @override
  String get importMapToExisting => 'Mapear para Existente';

  @override
  String get importCreateNew => 'Criar Novo';

  @override
  String importNewCategoryFound(Object categoryName) {
    return 'Nova categoria encontrada: \"$categoryName\"';
  }

  @override
  String importMapCategoryTitle(Object categoryName) {
    return 'Mapear \"$categoryName\" para...';
  }

  @override
  String importNewCurrencyFound(Object currencyName) {
    return 'Nova moeda encontrada: \"$currencyName\"';
  }

  @override
  String importMapCurrencyTitle(Object currencyName) {
    return 'Mapear \"$currencyName\" para...';
  }

  @override
  String get importSkipAll => 'Pular Tudo';

  @override
  String get importImportAll => 'Importar Tudo';

  @override
  String get importPotentialDuplicate => 'Potencial Duplicado:';

  @override
  String importDateLabel(Object date) {
    return 'Data: $date';
  }

  @override
  String importFromLabel(Object from) {
    return 'De: $from';
  }

  @override
  String importToLabel(Object to) {
    return 'Para: $to';
  }

  @override
  String importAmountLabel(Object amount, Object currency) {
    return 'Valor: $amount $currency';
  }

  @override
  String get importSkip => 'Pular';

  @override
  String get importImportAnyway => 'Importar de Qualquer Maneira';

  @override
  String importDecisionLabel(Object decision) {
    return 'Decisão: $decision';
  }

  @override
  String get importReadyTitle => 'Pronto para Importar';

  @override
  String importReadyMessage(Object count) {
    return '$count transações estão prontas para serem importadas.';
  }

  @override
  String get importFinalizeButton => 'Finalizar Importação';

  @override
  String get importingTitle => 'Importando...';

  @override
  String get importCompleteTitle => 'Importação Concluída';

  @override
  String get importStartOverTooltip => 'Recomeçar';

  @override
  String get importDataTitle => 'Importar dados';

  @override
  String importAccountsCreatedLabel(Object count) {
    return 'Novas Contas Criadas: $count';
  }

  @override
  String importCategoriesCreatedLabel(Object count) {
    return 'Novas Categorias Criadas: $count';
  }

  @override
  String importTransactionsImportedLabel(Object count) {
    return 'Transações Importadas: $count';
  }

  @override
  String importDuplicatesSkippedLabel(Object count) {
    return 'Duplicados Pulados: $count';
  }

  @override
  String get searchHint => 'Pesquisar';

  @override
  String get debugAllDataClearedMessage => 'Todos os dados limpos e alimentados com padrões.';

  @override
  String get debugClearAllDataLabel => 'Limpar todos os dados (e alimentar padrões)';

  @override
  String get debugMinimumDataSeededMessage => 'Dados mínimos alimentados.';

  @override
  String get debugSeedMinimumDataLabel => 'Alimentar dados mínimos';

  @override
  String get debugMediumDataSeededMessage => 'Dados médios alimentados.';

  @override
  String get debugSeedMediumDataLabel => 'Alimentar dados médios';

  @override
  String get debugMaximumDataSeededMessage => 'Dados máximos alimentados.';

  @override
  String get debugSeedMaximumDataLabel => 'Alimentar dados máximos (para teste de desempenho)';

  @override
  String get debugRunningInDebugModeLabel => 'Executando em modo DEBUG';

  @override
  String get deleteAllButton => 'Excluir Tudo';

  @override
  String get changeButton => 'Alterar';

  @override
  String get undoButton => 'Desfazer';

  @override
  String itemDeletedMessage(Object name) {
    return '$name excluído';
  }

  @override
  String get totalBalanceLabel => 'Saldo Total';

  @override
  String get noCurrenciesSelected => 'Nenhuma moeda selecionada.';

  @override
  String get failedToLoadDashboard => 'Falha ao carregar o painel';

  @override
  String get dashboardCalendarTab => 'Calendário';

  @override
  String get dashboardTabCalendar => 'Calendário';

  @override
  String get dashboardCalendarTooltip => 'Vista de Calendário';

  @override
  String get dashboardCalendarDescription => 'Ver transações num formato de calendário';

  @override
  String get dashboardCategoriesTab => 'Categorias';

  @override
  String get dashboardTabCategories => 'Categorias';

  @override
  String get dashboardCategoriesTooltip => 'Análise de Categorias';

  @override
  String get dashboardCategoriesDescription => 'Detalhamento de despesas por categoria';

  @override
  String get dashboardBalanceTab => 'Saldo';

  @override
  String get dashboardTabBalance => 'Saldo';

  @override
  String get dashboardBalanceTooltip => 'Histórico de Saldo';

  @override
  String get dashboardBalanceDescription => 'Seguir o patrimônio líquido ao longo do tempo';

  @override
  String get dashboardExpensesLabel => 'Despesas';

  @override
  String get dashboardIncomeLabel => 'Receita';

  @override
  String get manageIconsTitle => 'Gerenciar Ícones';

  @override
  String get manageStylesDeleteTitle => 'Excluir Ícones';

  @override
  String manageStylesDeleteConfirm(Object count) {
    return 'Tem certeza de que deseja excluir $count ícones selecionados?';
  }

  @override
  String manageStylesDeleteConfirmWithTransfer(Object count) {
    return 'Tem certeza de que deseja excluir $count ícones selecionados? (O ícone de transferência será ignorado)';
  }

  @override
  String get noIconsCreated => 'Nenhum ícone criado ainda.';

  @override
  String get failedToLoadIcons => 'Falha ao carregar ícones.';

  @override
  String get cannotDeleteTransferIcon => 'Não é possível excluir o ícone de Transferência.';

  @override
  String get deleteIconsDialogTitle => 'Excluir Ícones';

  @override
  String deleteIconsConfirmationMessage(Object count) {
    return 'Tem certeza de que deseja excluir $count ícones selecionados?';
  }

  @override
  String deleteIconsWithSkipTransferMessage(Object count) {
    return 'Tem certeza de que deseja excluir $count ícones selecionados? (O ícone de Transferência será ignorado)';
  }

  @override
  String get deleteIconDialogTitle => 'Excluir Ícone';

  @override
  String deleteIconConfirmationMessage(Object name) {
    return 'Tem certeza de que deseja excluir \"$name\"?';
  }

  @override
  String deleteMultipleAccountsTitle(Object count) {
    return 'Excluir $count contas?';
  }

  @override
  String get deleteMultipleAccountsMessage => 'Tem certeza de que deseja excluir as contas selecionadas? Todas as transações associadas serão excluídas.';

  @override
  String get changeAccountTypeDialogTitle => 'Alterar Tipo de Conta';

  @override
  String editAccountTitle(Object name) {
    return 'Editar: $name';
  }

  @override
  String get balanceCalculatedFromAsset => 'O saldo é calculado a partir de Quantidade de Ativo * Preço';

  @override
  String get selectAccountTypeTitle => 'Selecionar Tipo de Conta';

  @override
  String get selectCountryTitle => 'Selecionar País';

  @override
  String get selectIconSubtitle => 'Selecionar um ícone';

  @override
  String get bindToAssetLabel => 'Vincular a Ativo (Opcional)';

  @override
  String get selectAssetTitle => 'Selecionar Ativo';

  @override
  String get selectedAssetLabel => 'Ativo Selecionado';

  @override
  String get balanceAutoCalculatedLabel => 'O saldo é calculado automaticamente';

  @override
  String get tapToBindAssetLabel => 'Toque para vincular um ativo';

  @override
  String get assetQuantityLabel => 'Quantidade de Ativo';

  @override
  String get linkedAssetsTitle => 'Ativos Vinculados';

  @override
  String get noneLabel => 'Nenhum';

  @override
  String get accountTypeLabel => 'Tipo de Conta';

  @override
  String get formValidationPleaseSelectAccountType => 'Por favor, selecione um tipo de conta';

  @override
  String get iconLabel => 'Ícone';

  @override
  String get languageLabel => 'Idioma';

  @override
  String get systemDefaultLabel => 'Padrão do Sistema';

  @override
  String get selectLanguageTitle => 'Selecionar Idioma';

  @override
  String get dashboardLabel => 'Painel';

  @override
  String get homeLabel => 'Início';

  @override
  String get historyLabel => 'Histórico';

  @override
  String get syncScreenTitle => 'Configurações de Sincronização';

  @override
  String get syncP2PSection => 'Sincronização P2P (Syncthing)';

  @override
  String get syncEnableP2P => 'Ativar Sincronização P2P';

  @override
  String get syncP2PSubtitle => 'Sincronizar via arquivos .sync em uma pasta compartilhada';

  @override
  String get syncFolderLabel => 'Pasta de Sincronização';

  @override
  String get syncFolderNotSelected => 'Não selecionado';

  @override
  String get syncBrowseButton => 'Procurar';

  @override
  String get syncClearFilesButton => 'Limpar arquivos de sincronização';

  @override
  String get syncServerSection => 'Sincronização na Nuvem (Servidor)';

  @override
  String get syncServerUrlLabel => 'URL do Servidor';

  @override
  String get syncApiTokenLabel => 'Token da API';

  @override
  String get syncApiTokenHint => 'Digite seu token de segurança';

  @override
  String get syncApiTokenHelp => 'Este token é o seu segredo compartilhado. Digite o mesmo valor em todos os seus dispositivos para autorizar a sincronização.';

  @override
  String get syncTestConnectionButton => 'Testar Conexão';

  @override
  String get syncTestingLabel => 'Testando...';

  @override
  String get syncSaveServerSettingsButton => 'Salvar Configurações do Servidor';

  @override
  String get syncEnableServer => 'Ativar Sincronização com Servidor';

  @override
  String get syncServerSubtitle => 'Sincronizar com uma instância do MyBudget Server';

  @override
  String get syncPendingLocalChanges => 'Alterações locais pendentes:';

  @override
  String get syncSyncNowButton => 'Sincronizar Agora';

  @override
  String get syncSyncingLabel => 'Sincronizando...';

  @override
  String get syncWebNotAvailable => 'A sincronização não está disponível na Web';

  @override
  String get syncPermissionRequired => 'Permissão de armazenamento necessária para a sincronização. Por favor, ative \"Acesso a todos os arquivos\" nas configurações.';

  @override
  String get syncSelectFolderTitle => 'Selecionar Pasta do Syncthing';

  @override
  String get syncClearFilesTitle => 'Limpar Arquivos de Sincronização';

  @override
  String get syncClearFilesConfirm => 'Isso excluirá todos os arquivos .sync da pasta selecionada. Esta ação não pode ser desfeita.';

  @override
  String syncDeletedFilesCount(Object count) {
    return 'Excluídos $count arquivos de sincronização';
  }

  @override
  String syncClearFilesError(Object error) {
    return 'Erro ao limpar arquivos: $error';
  }

  @override
  String get syncSettingsSaved => 'Configurações do servidor salvas';

  @override
  String get syncConnectionSuccessful => 'Conexão bem-sucedida!';

  @override
  String get syncConnectionFailed => 'Falha na conexão. Verifique a URL e o Token.';

  @override
  String get syncConnectionUnauthorized => 'Token rejeitado pelo servidor. Verifique o token, não o endereço.';

  @override
  String get syncServerNotConfigured => 'O servidor não tem um token de sincronização configurado e está recusando todos os dispositivos. Defina SYNC_TOKEN no servidor e use o mesmo valor aqui.';

  @override
  String get syncCompleted => 'Sincronização concluída com sucesso';

  @override
  String syncFailed(Object error) {
    return 'Falha na sincronização: $error';
  }

  @override
  String get smsRuleAddTitle => 'Adicionar Regra';

  @override
  String get smsRuleEditTitle => 'Editar Regla';

  @override
  String get smsRuleTransactionType => 'Tipo de Transação';

  @override
  String get smsRuleMatchPattern => 'Padrão de Correspondência (Regex)';

  @override
  String get smsRuleMatchPatternHint => 'ex: Pagamento.*com cartão';

  @override
  String get smsRuleMatchPatternHelp => 'Padrão para identificar este tipo de SMS';

  @override
  String get smsRuleAmountPattern => 'Padrão de Valor (Regex)';

  @override
  String get smsRuleAmountPatternHint => 'ex: valor\\s+([\\d,.]+)';

  @override
  String get smsRuleAmountPatternHelp => 'O Grupo 1 deve capturar o valor';

  @override
  String get smsRuleCurrencyPattern => 'Padrão de Moeda (Regex, opcional)';

  @override
  String get smsRuleCurrencyPatternHint => 'ex: [\\d,.]+\\s*(\\w\\w\\w)';

  @override
  String get smsRuleCurrencyPatternHelp => 'O Grupo 1 deve capturar o código da moeda';

  @override
  String get smsRuleTestTitle => 'Teste sua Regra';

  @override
  String get smsRuleTestSmsHint => 'Cole o texto do SMS aqui';

  @override
  String get smsRuleTestButton => 'Testar Padrão';

  @override
  String get smsRuleTestEnterSmsError => 'Digite o texto do SMS para testar';

  @override
  String get smsRuleTestMatchError => '✗ O padrão de correspondência não encontrou resultados';

  @override
  String get smsRuleTestAmountError => '✗ O padrão de valor não encontrou resultados';

  @override
  String smsRuleTestSuccess(Object amount, Object currency, Object type) {
    return '✓ Correspondência encontrada!\nTipo: $type\nValor: $amount\nMoeda: $currency';
  }

  @override
  String smsRuleTestRegexError(Object error) {
    return '✗ Regex inválido: $error';
  }

  @override
  String get smsRuleRequiredError => 'Os padrões de Correspondência e Valor são obrigatórios';

  @override
  String inflationError(Object error) {
    return 'Erro: $error';
  }

  @override
  String get inflationNoRatesFound => 'Não foram encontradas taxas de inflação.';

  @override
  String get inflationAddRate => 'Adicionar Taxa de Inflação';

  @override
  String get inflationDeleteConfirmTitle => 'Excluir Taxas?';

  @override
  String inflationDeleteConfirmMessage(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count taxas',
      one: 'esta taxa',
    );
    return 'Tem certeza de que deseja excluir $_temp0?';
  }

  @override
  String inflationSelectedCount(Object count) {
    return '$count selecionados';
  }

  @override
  String get inflationFiltersTitle => 'Filtros de Inflação';

  @override
  String get inflationCountries => 'Países';

  @override
  String get inflationPresets => 'Predefinições';

  @override
  String deleteCategoryConfirmTitle(Object name) {
    return 'Excluir $name?';
  }

  @override
  String get deleteCategoryMessage => 'Esta categoria possui transações associadas. O que você gostaria de fazer?';

  @override
  String get deleteCategoryReassign => 'Reatribuir transações para outra categoria';

  @override
  String get deleteCategoryNewCategory => 'Nova Categoria';

  @override
  String get deleteCategoryDeleteAll => 'Excluir todas as transações associadas';

  @override
  String deleteAccountConfirmTitle(Object name) {
    return 'Excluir $name?';
  }

  @override
  String get deleteAccountMessage => 'Esta conta pode ter transações associadas. O que você gostaria de fazer?';

  @override
  String get deleteAccountReassign => 'Reatribuir transações para outra conta';

  @override
  String get deleteAccountNewAccount => 'Nova Conta';

  @override
  String get deleteAccountDeleteAll => 'Excluir todas as transações associadas';

  @override
  String get confirmButton => 'Confirmar';

  @override
  String get okButton => 'OK';

  @override
  String get noItemsFound => 'Nenhum item encontrado.';

  @override
  String get noDataForPeriod => 'Nenhum dado para este período';

  @override
  String get noDataForRange => 'Nenhum dado para este intervalo';

  @override
  String get noHistoryData => 'Nenhum dado de histórico disponível';

  @override
  String get disabledByGlobalSync => 'Desativado por Sincronização Global';

  @override
  String dateCreatedLabel(Object date) {
    return 'Data de criação: $date';
  }

  @override
  String get anyLabel => 'Qualquer';

  @override
  String get balanceDisplayLabel => 'Exibição do Saldo';

  @override
  String currenciesActiveLabel(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count moedas ativas',
      one: '1 moeda ativa',
    );
    return '$_temp0';
  }

  @override
  String get searchCountryLabel => 'Pesquisar País';

  @override
  String get addNewIconLabel => 'Adicionar Novo Ícone';

  @override
  String get noIconsFoundLabel => 'Nenhum ícone encontrado';

  @override
  String get addNewStyleLabel => 'Adicionar Novo Estilo';

  @override
  String get styleNameLabel => 'Nome do Estilo';

  @override
  String get pleaseEnterStyleName => 'Por favor, insira um nome de estilo';

  @override
  String get colorLabel => 'Cor';

  @override
  String get netBalanceMetric => 'Saldo Líq.';

  @override
  String get investedMetric => 'Investido';

  @override
  String get realizedMetric => 'Realizado';

  @override
  String get feesMetric => 'Taxas';

  @override
  String get persistFiltersLabel => 'Persistir Filtros';

  @override
  String get searchByNameHint => 'Pesquisar por nome...';

  @override
  String get searchDescriptionHint => 'Pesquisar descrição...';

  @override
  String get advancedFiltersTitle => 'Filtros Avançados';

  @override
  String get transactionTypeLabel => 'Tipo de Transação';

  @override
  String get assetFiltersTitle => 'Filtros de Ativos';

  @override
  String get minValueLabel => 'Valor Mín';

  @override
  String get maxValueLabel => 'Valor Máx';

  @override
  String get assetTypesLabel => 'Tipos de Ativos';

  @override
  String get allLabel => 'Todos';

  @override
  String get currenciesLabel => 'Moedas';

  @override
  String get sourcesLabel => 'Fontes';

  @override
  String get presetsLabel => 'Predefinições';

  @override
  String get enterCategoryNameHint => 'Digite o nome da categoria';

  @override
  String get selectTypeHint => 'Selecionar Tipo';

  @override
  String get hotKeysTitle => 'Teclas de Atalho';

  @override
  String get searchHotkeysHint => 'Pesquisar teclas de atalho...';

  @override
  String get noMatchingHotkeys => 'Nenhuma tecla de atalho correspondente encontrada.';

  @override
  String recordingHotkeyTitle(Object label) {
    return 'Gravando Tecla de Atalho para \"$label\"';
  }

  @override
  String get pressKeysHint => 'Pressione as teclas...';

  @override
  String get pressAnyCombinationHint => 'Pressione qualquer combinação de teclas.';

  @override
  String get clearSaveButton => 'Limpar / Salvar';

  @override
  String get duplicateHotkeyTooltip => 'Tecla de Atalho Duplicada';

  @override
  String usedByLabel(Object action) {
    return 'Usado por $action';
  }

  @override
  String get hkCategoryNavigation => 'Navegação';

  @override
  String get hkCategoryDashboardTabs => 'Abas do Painel (Ctrl + 1/2/3)';

  @override
  String get hkCategoryDataTabs => 'Abas de Dados (Ctrl + 1/2/3)';

  @override
  String get hkCategoryPeriodControl => 'Controle de Período';

  @override
  String get hkCategoryActions => 'Ações';

  @override
  String get hkCategorySelectionMode => 'Modo de Seleção';

  @override
  String get hkActionBack => 'Global: Voltar / Sair';

  @override
  String get hkActionDashboard => 'Ir para o Painel';

  @override
  String get hkActionAccounts => 'Ir para Contas';

  @override
  String get hkActionTransactions => 'Ir para Transações';

  @override
  String get hkActionCategories => 'Ir para Categorias';

  @override
  String get hkActionData => 'Ir para Dados / Taxas';

  @override
  String get hkActionSettings => 'Ir para Configurações';

  @override
  String get hkActionDashboardTab1 => 'Aba do Calendário';

  @override
  String get hkActionDashboardTab2 => 'Aba de Categorias';

  @override
  String get hkActionDashboardTab3 => 'Aba de Saldo';

  @override
  String get hkActionDataTab1 => 'Taxas de Câmbio';

  @override
  String get hkActionDataTab2 => 'Inflação';

  @override
  String get hkActionDataTab3 => 'Ativos';

  @override
  String get hkActionPrevPeriod => 'Período Anterior';

  @override
  String get hkActionNextPeriod => 'Próximo Período';

  @override
  String get hkActionAddAction => 'Ação de Adição Genérica';

  @override
  String get hkActionAccountsSelectionClose => 'Contas: Fechar';

  @override
  String get hkActionAccountsSelectionAll => 'Contas: Selecionar Tudo';

  @override
  String get hkActionAccountsSelectionDelete => 'Contas: Excluir';

  @override
  String get hkActionAccountsSelectionChangeType => 'Contas: Alterar Tipo';

  @override
  String get hkActionCategoriesSelectionClose => 'Categorias: Fechar';

  @override
  String get hkActionCategoriesSelectionAll => 'Categorias: Selecionar Tudo';

  @override
  String get hkActionCategoriesSelectionDelete => 'Categorias: Excluir';

  @override
  String get hkActionCategoriesSelectionChangeType => 'Categorias: Alterar Tipo';

  @override
  String get hkActionDataSelectionClose => 'Dados: Fechar';

  @override
  String get hkActionDataSelectionAll => 'Dados: Selecionar Tudo';

  @override
  String get hkActionDataSelectionDelete => 'Dados: Excluir';

  @override
  String get hkActionDataSelectionChangePreset => 'Dados: Alterar Predefinição';

  @override
  String get styNotFound => 'Estilo não encontrado.';

  @override
  String get stySaveChanges => 'Salvar Alterações';

  @override
  String get styAddIcon => 'Adicionar Ícone';

  @override
  String get smsOnlyAndroid => 'A importação de SMS está disponível apenas no Android';

  @override
  String get smsImportSms => 'Importar SMS';

  @override
  String get smsPermissionRequired => 'Permissão de SMS Necessária';

  @override
  String get smsPermissionRationale => 'Para importar transações de SMS, precisamos de permissão para ler suas mensagens.';

  @override
  String get smsGrantPermission => 'Conceder Permissão';

  @override
  String get smsNoPresets => 'Nenhuma predefinição configurada. Toque em + para adicionar.';

  @override
  String get smsImportDescription => 'Importar transações de mensagens SMS. Escolha um intervalo de tempo:';

  @override
  String get smsLast7Days => 'Últimos 7 Dias';

  @override
  String get smsAllTime => 'Todo o Período';

  @override
  String smsFilterLabel(Object filter) {
    return 'Filtro: $filter';
  }

  @override
  String get smsEditPreset => 'Editar Predefinição';

  @override
  String get smsNewPreset => 'Nova Predefinição';

  @override
  String get smsPresetNameHint => 'ex: Meu Banco';

  @override
  String get smsSenderFilter => 'Filtro de Remetente';

  @override
  String get smsSenderFilterHint => 'ex: ALTA ou +381...';

  @override
  String get smsSenderFilterHelper => 'Filtrar SMS por nome do remetente ou número de telefone';

  @override
  String get smsDefaults => 'Padrões';

  @override
  String get smsDefaultAccount => 'Conta Padrão';

  @override
  String get smsDefaultCategory => 'Categoria Padrão';

  @override
  String get smsImportMessages => 'Importar Mensagens';

  @override
  String get smsSelectDefaultsFirst => 'Selecione primeiro os padrões';

  @override
  String get smsCustomRange => 'Intervalo Personalizado';

  @override
  String smsImportSuccessCount(Object count) {
    return 'Sucesso: $count transações importadas';
  }

  @override
  String get smsParsingRules => 'Regras de Análise';

  @override
  String get smsNoRules => 'Nenhuma regra definida. Toque em + para adicionar.';

  @override
  String smsMatchLabel(Object pattern) {
    return 'Correspondência: $pattern';
  }

  @override
  String get smsNameSenderRequired => 'O nome e o filtro de remetente são obrigatórios';

  @override
  String get smsCategoryKeywords => 'Palavras-chave de Categoria';

  @override
  String get smsCategoryKeywordsSubtitle => 'Mapear palavras-chave do texto do SMS para categorias';

  @override
  String get smsNoKeywordRules => 'Nenhuma regra de palavra-chave. Toque em + para adicionar.';

  @override
  String get smsAddKeywordRule => 'Adicionar Regra de Palavra-chave';

  @override
  String get smsKeyword => 'Palavra-chave';

  @override
  String get smsKeywordHint => 'ex: Supermercado, Netflix';

  @override
  String get smsKeywordHelper => 'Subcadeia sem distinção de maiúsculas a procurar no texto do SMS';

  @override
  String get smsSelectCategoryHint => 'Selecionar categoria';

  @override
  String get dshSelectDateDescription => 'Abrir o calendário para escolher uma data ou intervalo específico';

  @override
  String get dshCurrencyDescription => 'Selecionar a moeda principal para exibição';

  @override
  String get dshChangeViewTooltip => 'Alterar Vista';

  @override
  String get dshChangeViewDescription => 'Alternar entre vista Mensal e Anual';

  @override
  String get dshMonthlyAbbreviation => 'M';

  @override
  String get dshYearlyAbbreviation => 'A';

  @override
  String dshBalancesOnDate(Object date) {
    return 'Saldos em $date';
  }

  @override
  String get dshSearchCurrency => 'Pesquisar Moeda';

  @override
  String get dshUnknownCategory => 'Desconhecido';

  @override
  String get pckSelectItem => 'Selecionar Item';

  @override
  String get pckSelectItems => 'Selecionar Itens';

  @override
  String get pckClearAll => 'Limpar Tudo';

  @override
  String get pckSelectIcon => 'Selecionar Ícone';

  @override
  String get pckMaterialIcons => 'Ícones Material';

  @override
  String get pckCustomIcons => 'Ícones Personalizados';

  @override
  String get fltAmountFrom => 'Valor De';

  @override
  String get fltAmountTo => 'Valor Até';

  @override
  String get fltSelectRange => 'Selecionar Intervalo';

  @override
  String get fltAdvancedFilterTooltip => 'Filtro Avançado';

  @override
  String get fltAdvancedFilterDescription => 'Filtrar transações por conta, categoria ou valor';

  @override
  String get fltSortOrderDescription => 'Alternar entre ordem crescente e decrescente';

  @override
  String get fltAccountFiltersTitle => 'Filtros de Contas';

  @override
  String get fltNameLabel => 'Nome';

  @override
  String get fltAccountTypesLabel => 'Tipos de Conta';

  @override
  String get fltFilterCurrenciesLabel => 'Filtrar Moedas';

  @override
  String get fltSelectCurrenciesLabel => 'Selecionar Moedas';

  @override
  String get fltFilterCategoriesTitle => 'Filtrar Categorias';

  @override
  String get exchAddExchangeRate => 'Adicionar Taxa de Câmbio';

  @override
  String get exchEditExchangeRate => 'Editar Taxa de Câmbio';

  @override
  String get exchAddRateDescription => 'Inserir manualmente uma taxa de conversão entre duas moedas';

  @override
  String get exchNoRatesFound => 'Nenhuma taxa de câmbio encontrada.';

  @override
  String get exchChangePreset => 'Alterar Predefinição';

  @override
  String get exchFromCurrency => 'Moeda de Origem';

  @override
  String get exchToCurrency => 'Moeda de Destino';

  @override
  String get exchRate => 'Taxa';

  @override
  String get exchPresetIdLabel => 'ID da Predefinição';

  @override
  String exchPresetValue(Object preset) {
    return 'Predefinição: $preset';
  }

  @override
  String get exchSelectRange => 'Selecionar Intervalo';

  @override
  String get exchPreviousPeriodDescription => 'Ir para o dia, mês ou ano anterior';

  @override
  String get exchNextPeriodDescription => 'Ir para o dia, mês ou ano seguinte';

  @override
  String get exchFilterDescription => 'Filtrar taxas por moeda de origem/destino e ID da predefinição';

  @override
  String get exchSelectDateDescription => 'Escolher uma data ou intervalo específico para ver taxas históricas';

  @override
  String get exchSortOrderDescription => 'Alternar entre ordem crescente e decrescente por data/taxa';

  @override
  String get exchFilterExchangeRates => 'Filtrar Taxas de Câmbio';

  @override
  String get exchExitSelectionDescription => 'Sair do modo de seleção de taxas de câmbio';

  @override
  String get exchSelectAllDescription => 'Selecionar todas as taxas de câmbio listadas';

  @override
  String get exchDeselectAllDescription => 'Desmarcar todas as taxas';

  @override
  String get exchChangePresetDescription => 'Atualizar o ID da predefinição de todas as taxas de câmbio selecionadas';

  @override
  String get exchDeleteSelectedDescription => 'Excluir permanentemente todas as taxas de câmbio selecionadas';

  @override
  String get exchDeleteExchangeRatesTitle => 'Excluir Taxas de Câmbio';

  @override
  String exchDeleteConfirmMessage(Object count) {
    return 'Tem certeza de que deseja excluir $count taxas de câmbio?';
  }

  @override
  String get exchUpdatePresetTitle => 'Atualizar Predefinição';

  @override
  String get exchUpdatePresetMessage => 'Digite o novo ID da predefinição para os itens selecionados:';
}
