// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

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
  String totalCountLabel(Object count) {
    return 'Total: $count';
  }

  @override
  String get closeSelectionTooltip => 'Fechar Seleção';

  @override
  String get exitSelectionDescription => 'Sair do modo de seleção';

  @override
  String selectedCountLabel(Object count) {
    return '$count selecionados';
  }

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
  String get exitTransactionsSelectionDescription => 'Sair do modo de seleção de transações';

  @override
  String quantityLabel(Object quantity) {
    return 'Qtd: $quantity';
  }

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
  String get amountLabel => 'Valor';

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
  String get importCreateAllNew => 'Criar todos como novos';

  @override
  String importNewAccountFound(Object accountName) {
    return 'Nova conta encontrada: \"$accountName\"';
  }

  @override
  String importMapAccountTitle(Object accountName) {
    return 'Mapear \"$accountName\" para...';
  }

  @override
  String get importMapToExisting => 'Mapear para existente';

  @override
  String get importCreateNew => 'Criar novo';

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
  String get importSkipAll => 'Pular tudo';

  @override
  String get importImportAll => 'Importar tudo';

  @override
  String get importPotentialDuplicate => 'Potencial duplicado:';

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
  String get importImportAnyway => 'Importar de qualquer maneira';

  @override
  String importDecisionLabel(Object decision) {
    return 'Decisão: $decision';
  }

  @override
  String get importReadyTitle => 'Pronto para importar';

  @override
  String importReadyMessage(Object count) {
    return '$count transações estão prontas para serem importadas.';
  }

  @override
  String get importFinalizeButton => 'Finalizar importação';

  @override
  String get importingTitle => 'Importando...';

  @override
  String get importCompleteTitle => 'Importação concluída';

  @override
  String get importStartOverTooltip => 'Recomeçar';

  @override
  String get importDataTitle => 'Importar dados';

  @override
  String importAccountsCreatedLabel(Object count) {
    return 'Novas contas criadas: $count';
  }

  @override
  String importCategoriesCreatedLabel(Object count) {
    return 'Novas categorias criadas: $count';
  }

  @override
  String importTransactionsImportedLabel(Object count) {
    return 'Transações importadas: $count';
  }

  @override
  String importDuplicatesSkippedLabel(Object count) {
    return 'Duplicados pulados: $count';
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
  String get deleteAllButton => 'Excluir tudo';

  @override
  String get changeButton => 'Alterar';

  @override
  String get undoButton => 'Desfazer';

  @override
  String itemDeletedMessage(Object name) {
    return '$name excluído';
  }

  @override
  String get totalBalanceLabel => 'Saldo total';

  @override
  String get noCurrenciesSelected => 'Nenhuma moeda selecionada.';

  @override
  String get incomeLabel => 'Receita';

  @override
  String get expenseLabel => 'Despesa';

  @override
  String get failedToLoadDashboard => 'Falha ao carregar o painel';

  @override
  String get dashboardCalendarTab => 'Calendário';

  @override
  String get dashboardCalendarTooltip => 'Visualização de calendário';

  @override
  String get dashboardCalendarDescription => 'Ver transações em formato de calendário';

  @override
  String get dashboardCategoriesTab => 'Categorias';

  @override
  String get dashboardCategoriesTooltip => 'Visualização de categorias';

  @override
  String get dashboardCategoriesDescription => 'Gerenciar suas categorias de dinheiro';

  @override
  String get dashboardBalanceTab => 'Saldo';

  @override
  String get dashboardBalanceTooltip => 'Visualização de saldo';

  @override
  String get dashboardBalanceDescription => 'Visão geral rápida do seu saldo';

  @override
  String get dashboardExpensesLabel => 'Despesas';

  @override
  String get dashboardIncomeLabel => 'Receita';

  @override
  String get manageIconsTitle => 'Gerir Ícones';

  @override
  String get noIconsCreated => 'Nenhum ícone criado ainda.';

  @override
  String get failedToLoadIcons => 'Falha ao carregar ícones.';

  @override
  String get cannotDeleteTransferIcon => 'Não é possível eliminar o ícone de Transferência.';

  @override
  String get deleteIconsDialogTitle => 'Eliminar Ícones';

  @override
  String deleteIconsConfirmationMessage(Object count) {
    return 'Tem a certeza de que deseja eliminar $count ícones selecionados?';
  }

  @override
  String deleteIconsWithSkipTransferMessage(Object count) {
    return 'Tem a certeza de que deseja eliminar $count ícones selecionados? (O ícone de Transferência será ignorado)';
  }

  @override
  String get deleteIconDialogTitle => 'Eliminar Ícone';

  @override
  String deleteIconConfirmationMessage(Object name) {
    return 'Tem a certeza de que deseja eliminar \"$name\"?';
  }

  @override
  String deleteMultipleAccountsTitle(Object count) {
    return 'Eliminar $count contas?';
  }

  @override
  String get deleteMultipleAccountsMessage => 'Tem a certeza de que deseja eliminar as contas selecionadas? Todas as transações associadas serão eliminadas.';

  @override
  String get changeAccountTypeDialogTitle => 'Alterar Tipo de Conta';

  @override
  String editAccountTitle(Object name) {
    return 'Editar: $name';
  }

  @override
  String get balanceCalculatedFromAsset => 'O saldo é calculado a partir de Quantidade de ativo * Preço';

  @override
  String get selectAccountTypeTitle => 'Selecionar tipo de conta';

  @override
  String get selectCountryTitle => 'Selecionar país';

  @override
  String get selectIconSubtitle => 'Selecionar um ícone';

  @override
  String get bindToAssetLabel => 'Vincular a ativo (opcional)';

  @override
  String get selectAssetTitle => 'Selecionar ativo';

  @override
  String get selectedAssetLabel => 'Ativo selecionado';

  @override
  String get balanceAutoCalculatedLabel => 'O saldo é calculado automaticamente';

  @override
  String get tapToBindAssetLabel => 'Toque para vincular um ativo';

  @override
  String get assetQuantityLabel => 'Quantidade de ativo';

  @override
  String get linkedAssetsTitle => 'Ativos vinculados';

  @override
  String get noneLabel => 'Nenhum';

  @override
  String get accountTypeLabel => 'Tipo de conta';

  @override
  String get formValidationPleaseSelectAccountType => 'Por favor, selecione um tipo de conta';

  @override
  String get iconLabel => 'Ícone';
}
