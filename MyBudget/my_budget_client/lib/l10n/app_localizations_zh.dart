// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get helloWorld => '你好，世界！';

  @override
  String get accountsAppBarTitle => '账户';

  @override
  String accountsBalanceLabel(Object balance) {
    return '余额: $balance';
  }

  @override
  String get accountsLoadFailure => '账户加载失败';

  @override
  String get accountsEmptyState => '没有账户';

  @override
  String get accountsRefreshTooltip => '刷新';

  @override
  String get accountsAddTooltip => '添加账户';

  @override
  String get addAccountDescription => '创建新的银行账户、钱包或资产';

  @override
  String get addAccountDialogTitle => '添加新账户';

  @override
  String get accountNameHint => '账户名称';

  @override
  String get initialBalanceHint => '初始余额';

  @override
  String get currencyLabel => '货币';

  @override
  String get cancelButton => '取消';

  @override
  String get saveButton => '保存';

  @override
  String get deleteButton => '删除';

  @override
  String get editButton => '编辑';

  @override
  String get applyButton => '应用';

  @override
  String get clearButton => '清除';

  @override
  String get formValidationPleaseEnterName => '请输入名称';

  @override
  String get formValidationPleaseEnterBalance => '请输入余额';

  @override
  String get formValidationPleaseEnterValidNumber => '请输入有效的数字';

  @override
  String get formValidationPleaseSelectCurrency => '请选择货币';

  @override
  String get currencyLoadError => '货币加载错误';

  @override
  String get noCurrenciesAvailable => '无可用货币';

  @override
  String get categoriesAppBarTitle => '分类';

  @override
  String get categoriesScreenBody => '分类屏幕';

  @override
  String get transactionsAppBarTitle => '交易';

  @override
  String get transactionsScreenBody => '交易屏幕';

  @override
  String get settingsAppBarTitle => '设置';

  @override
  String get settingsScreenBody => '设置屏幕';

  @override
  String get filePickerChooserTitle => '选择文件';

  @override
  String get imagePickerChooserTitle => '选择图片';

  @override
  String get totalNetWorth => '总净资产';

  @override
  String get currencyBreakdown => '货币明细';

  @override
  String get metricBalance => '余额';

  @override
  String get metricIncome => '收入';

  @override
  String get metricExpense => '支出';

  @override
  String get metricReal => '实际';

  @override
  String get metricChange => '变化';

  @override
  String get contextMenuSelect => '选择';

  @override
  String get contextMenuDeselect => '取消选择';

  @override
  String get contextMenuSelectAll => '全选';

  @override
  String get contextMenuDeselectAll => '取消全选';

  @override
  String get contextMenuAddTransaction => '添加交易';

  @override
  String get addTransactionDescription => '创建新交易';

  @override
  String get contextMenuTransfer => '转账';

  @override
  String get contextMenuEdit => '编辑';

  @override
  String get contextMenuDelete => '删除';

  @override
  String get contextMenuChangeType => '更改类型';

  @override
  String deleteConfirmationTitle(Object item) {
    return '删除 $item？';
  }

  @override
  String deleteConfirmationMessage(Object item) {
    return '您确定要删除此 $item 及其所有数据吗？';
  }

  @override
  String get deleteAccountsConfirmationTitle => '删除账户？';

  @override
  String deleteAccountsConfirmationMessage(Object count) {
    return '删除选中的 $count 个账户及其交易？';
  }

  @override
  String get deleteAccountDialogReassign => '将交易重新分配到另一个账户';

  @override
  String get deleteAccountDialogDeleteAll => '删除所有相关交易';

  @override
  String get deleteAccountDialogMessage => '此账户可能有相关交易。您希望怎么做？';

  @override
  String get newAccountLabel => '新账户';

  @override
  String get warningOverwriteTitle => '警告：覆盖数据？';

  @override
  String get warningOverwriteMessage => '恢复备份将删除所有当前数据并用备份替换。此操作无法撤销。';

  @override
  String get restoreOverwriteButton => '恢复并覆盖';

  @override
  String get importSuccess => '导入成功完成。';

  @override
  String importFailed(Object error) {
    return '导入失败: $error';
  }

  @override
  String deleteCategoriesConfirmationTitle(Object count) {
    return '删除 $count 个分类？';
  }

  @override
  String get deleteCategoriesConfirmationMessage => '您确定要删除选中的分类吗？';

  @override
  String get changeCategoryTypeDialogTitle => '更改分类类型';

  @override
  String get noCategoriesCreated => '尚未创建分类。';

  @override
  String get addCategoryTooltip => '添加分类';

  @override
  String get addCategoryDescription => '创建新的支出或收入分类';

  @override
  String get previousPeriodTooltip => '上一期间';

  @override
  String get previousPeriodDescription => '转到上个月或上一年';

  @override
  String get nextPeriodTooltip => '下一期间';

  @override
  String get nextPeriodDescription => '转到下个月或下一年';

  @override
  String get filterTooltip => '筛选';

  @override
  String get filterCategoriesDescription => '按类型筛选分类（收入/支出）';

  @override
  String get selectDateTooltip => '选择日期';

  @override
  String get selectDateDescription => '选择特定日期范围以查看总计';

  @override
  String get sortOrderTooltip => '排序顺序';

  @override
  String get sortOrderDescription => '按金额切换升序和降序';

  @override
  String totalCountLabel(Object count) {
    return '总计: $count';
  }

  @override
  String get closeSelectionTooltip => '关闭选择';

  @override
  String get exitSelectionDescription => '退出选择模式';

  @override
  String selectedCountLabel(Object count) {
    return '已选择 $count 个';
  }

  @override
  String get categoryNameLabel => '分类名称';

  @override
  String get categoriesChangeButton => '更改';

  @override
  String get parentCategoryLabel => '父分类';

  @override
  String get styleLabel => '样式（图标和颜色）';

  @override
  String get typeLabel => '类型';

  @override
  String get deleteTransactionsConfirmationTitle => '删除交易';

  @override
  String deleteTransactionsConfirmationMessage(Object count) {
    return '您确定要删除选中的 $count 笔交易吗？';
  }

  @override
  String get changeDateTooltip => '更改日期';

  @override
  String get changeDateDescription => '更新所有选中交易的日期';

  @override
  String get changeCategoryTooltip => '更改分类';

  @override
  String get changeCategoryDescription => '更新所有选中交易的分类';

  @override
  String get deleteTransactionsTooltip => '删除选中';

  @override
  String get deleteTransactionsDescription => '永久删除所有选中交易';

  @override
  String get exitTransactionsSelectionDescription => '退出交易选择模式';

  @override
  String quantityLabel(Object quantity) {
    return '数量: $quantity';
  }

  @override
  String get addTransactionTitle => '添加交易';

  @override
  String get editTransactionTitle => '编辑交易';

  @override
  String get newTransferTitle => '新转账';

  @override
  String get editTransferTitle => '编辑转账';

  @override
  String get descriptionLabel => '描述';

  @override
  String get descriptionOptionalLabel => '描述（可选）';

  @override
  String get amountLabel => '金额';

  @override
  String get quantityFormLabel => '数量';

  @override
  String get selectAccountTitle => '选择账户';

  @override
  String get selectCategoryTitle => '选择分类';

  @override
  String get selectCurrencyTitle => '选择货币';

  @override
  String get accountLabel => '账户';

  @override
  String get fromAccountLabel => '从账户';

  @override
  String get toAccountLabel => '到账户';

  @override
  String get categoryLabel => '分类';

  @override
  String get dateLabel => '日期';

  @override
  String get selectDateLabel => '选择日期';

  @override
  String get swapAccountsTooltip => '交换账户';

  @override
  String get incomeType => '收入';

  @override
  String get expenseType => '支出';

  @override
  String get failedToLoadData => '加载数据失败';

  @override
  String get invalidAmountError => '请输入有效数字';

  @override
  String get emptyAmountError => '请输入金额';

  @override
  String get selectAccountError => '请选择账户';

  @override
  String get selectCategoryError => '请选择分类';

  @override
  String get selectDateError => '请选择日期';

  @override
  String get currencyLockedMessage => '锁定为源账户货币';

  @override
  String get totalValueLabel => '总价值';

  @override
  String get feeLabel => '费用';

  @override
  String get exchangeRateLabel => '汇率';

  @override
  String get pricePerUnitLabel => '单价';

  @override
  String get buyAction => '买入';

  @override
  String get sellAction => '卖出';

  @override
  String transferToDescription(Object accountName) {
    return '转账至 $accountName';
  }

  @override
  String transferFromDescription(Object accountName) {
    return '从 $accountName 转账';
  }

  @override
  String buyDescription(Object assetName) {
    return '买入 $assetName';
  }

  @override
  String sellDescription(Object assetName) {
    return '卖出 $assetName';
  }

  @override
  String assetTransferDescription(Object action, Object assetName) {
    return '$action $assetName 的转账';
  }

  @override
  String get swapDirectionTooltip => '交换方向';

  @override
  String get availablePresetsLabel => '可用预设:';

  @override
  String get updateButton => '更新';

  @override
  String get newPresetButton => '新预设';

  @override
  String get amountToAddToAccountLabel => '充值到账户的金额:';

  @override
  String valueInGlobalLabel(Object currency) {
    return '全局价值 ($currency):';
  }

  @override
  String get feeCommissionLabel => '费用（佣金）';

  @override
  String get requiredError => '必填';

  @override
  String currentPriceLabel(Object currency, Object price) {
    return '当前价格: $price $currency';
  }

  @override
  String get linkedAccountLabel => '关联账户';

  @override
  String get selectLinkedAccountTitle => '选择关联账户';

  @override
  String get settingsTitle => '设置';

  @override
  String get manageIconsLabel => '管理图标';

  @override
  String get manageThemeLabel => '管理主题';

  @override
  String get mainCurrencyLabel => '主货币';

  @override
  String get defaultInflationCountryLabel => '默认通胀国家';

  @override
  String get persistAdvancedFiltersLabel => '保留高级筛选';

  @override
  String get hotKeysLabel => '快捷键';

  @override
  String get smsImportLabel => '短信导入';

  @override
  String get smsImportSubtitle => '从银行短信导入交易';

  @override
  String get apiManagementLabel => 'API 管理';

  @override
  String get dataLabel => '数据';

  @override
  String get syncSettingsLabel => '同步设置';

  @override
  String get syncSettingsSubtitle => '通过 Syncthing 进行 P2P 同步';

  @override
  String get importDataLabel => '导入数据';

  @override
  String get exportDataLabel => '导出数据';

  @override
  String get exportFormatMessage => '选择格式：\n\nJSON：所有数据的完整备份。\nCSV：可读的交易报告。';

  @override
  String get jsonFormat => 'JSON';

  @override
  String get csvFormat => 'CSV';

  @override
  String get importExchangeRatesLabel => '导入汇率 (CSV/JSON)';

  @override
  String get resetDataLabel => '重置数据为默认值';

  @override
  String get resetDataSubtitle => '这将删除所有数据并恢复默认设置。';

  @override
  String get debugMenuLabel => '调试菜单';

  @override
  String get debugMenuSubtitle => '内部开发者工具';

  @override
  String get exportSuccessMessage => '导出成功完成';

  @override
  String exportFailedMessage(Object error) {
    return '导出失败: $error';
  }

  @override
  String get importSuccessMessage => '导入成功完成';

  @override
  String importFailedMessage(Object error) {
    return '导入失败: $error';
  }

  @override
  String get resetDataConfirmationTitle => '重置数据？';

  @override
  String get resetDataConfirmationMessage => '警告！这将删除您所有的交易、账户和设置。\n\n应用将恢复到具有默认数据的初始状态。\n此操作无法撤销。';

  @override
  String get resetEverythingButton => '重置所有';

  @override
  String get resetSuccessMessage => '数据已重置并恢复默认值。';

  @override
  String resetFailedMessage(Object error) {
    return '重置失败: $error';
  }

  @override
  String get importParsingStep => '正在解析 CSV 文件...';

  @override
  String get importFetchingRatesStep => '正在获取汇率...';

  @override
  String importErrorLabel(Object error) {
    return '错误: $error';
  }

  @override
  String get importOneMoneyLabel => '从 OneMoney (CSV) 导入';

  @override
  String get importMyBudgetLabel => '导入 MyBudget 交易 (CSV)';

  @override
  String get restoreBackupLabel => '恢复备份 (JSON)';

  @override
  String get importSelectionHelp => '选择 \'OneMoney\' 进行迁移，\'MyBudget\' 用于添加交易，或 \'恢复备份\' 以覆盖所有数据。';

  @override
  String get importCreateAllNew => '全部新建';

  @override
  String importNewAccountFound(Object accountName) {
    return '发现新账户: \"$accountName\"';
  }

  @override
  String importMapAccountTitle(Object accountName) {
    return '将 \"$accountName\" 映射到...';
  }

  @override
  String get importMapToExisting => '映射到现有账户';

  @override
  String get importCreateNew => '新建';

  @override
  String importNewCategoryFound(Object categoryName) {
    return '发现新分类: \"$categoryName\"';
  }

  @override
  String importMapCategoryTitle(Object categoryName) {
    return '将 \"$categoryName\" 映射到...';
  }

  @override
  String importNewCurrencyFound(Object currencyName) {
    return '发现新货币: \"$currencyName\"';
  }

  @override
  String importMapCurrencyTitle(Object currencyName) {
    return '将 \"$currencyName\" 映射到...';
  }

  @override
  String get importSkipAll => '全部跳过';

  @override
  String get importImportAll => '全部导入';

  @override
  String get importPotentialDuplicate => '潜在重复:';

  @override
  String importDateLabel(Object date) {
    return '日期: $date';
  }

  @override
  String importFromLabel(Object from) {
    return '自: $from';
  }

  @override
  String importToLabel(Object to) {
    return '至: $to';
  }

  @override
  String importAmountLabel(Object amount, Object currency) {
    return '金额: $amount $currency';
  }

  @override
  String get importSkip => '跳过';

  @override
  String get importImportAnyway => '仍然导入';

  @override
  String importDecisionLabel(Object decision) {
    return '决定: $decision';
  }

  @override
  String get importReadyTitle => '准备导入';

  @override
  String importReadyMessage(Object count) {
    return '$count 笔交易已准备好导入。';
  }

  @override
  String get importFinalizeButton => '完成导入';

  @override
  String get importingTitle => '正在导入...';

  @override
  String get importCompleteTitle => '导入完成';

  @override
  String get importStartOverTooltip => '重新开始';

  @override
  String get importDataTitle => '导入数据';

  @override
  String importAccountsCreatedLabel(Object count) {
    return '新建账户数: $count';
  }

  @override
  String importCategoriesCreatedLabel(Object count) {
    return '新建分类数: $count';
  }

  @override
  String importTransactionsImportedLabel(Object count) {
    return '导入交易数: $count';
  }

  @override
  String importDuplicatesSkippedLabel(Object count) {
    return '跳过重复数: $count';
  }

  @override
  String get searchHint => '搜索';

  @override
  String get debugAllDataClearedMessage => '所有数据已清除并重新播种默认值。';

  @override
  String get debugClearAllDataLabel => '清除所有数据（并播种默认值）';

  @override
  String get debugMinimumDataSeededMessage => '已播种最小数据集。';

  @override
  String get debugSeedMinimumDataLabel => '播种最小数据集';

  @override
  String get debugMediumDataSeededMessage => '已播种中等数据集。';

  @override
  String get debugSeedMediumDataLabel => '播种中等数据集';

  @override
  String get debugMaximumDataSeededMessage => '已播种最大数据集。';

  @override
  String get debugSeedMaximumDataLabel => '播种最大数据集（用于性能测试）';

  @override
  String get debugRunningInDebugModeLabel => '正在以调试模式运行';

  @override
  String get deleteAllButton => '全部删除';

  @override
  String get changeButton => '更改';

  @override
  String get undoButton => '撤销';

  @override
  String itemDeletedMessage(Object name) {
    return '$name 已删除';
  }

  @override
  String get totalBalanceLabel => '总余额';

  @override
  String get noCurrenciesSelected => '未选择货币。';

  @override
  String get incomeLabel => '收入';

  @override
  String get expenseLabel => '支出';

  @override
  String get failedToLoadDashboard => '加载仪表板失败';

  @override
  String get dashboardCalendarTab => '日历';

  @override
  String get dashboardCalendarTooltip => '日历视图';

  @override
  String get dashboardCalendarDescription => '以日历格式查看交易';

  @override
  String get dashboardCategoriesTab => '分类';

  @override
  String get dashboardCategoriesTooltip => '分类分析';

  @override
  String get dashboardCategoriesDescription => '按分类细分支出';

  @override
  String get dashboardBalanceTab => '余额';

  @override
  String get dashboardBalanceTooltip => '余额历史';

  @override
  String get dashboardBalanceDescription => '跟踪随时间变化的净资产';

  @override
  String get dashboardExpensesLabel => '支出';

  @override
  String get dashboardIncomeLabel => '收入';

  @override
  String get manageIconsTitle => '管理图标';

  @override
  String get noIconsCreated => '尚未创建任何图标。';

  @override
  String get failedToLoadIcons => '加载图标失败。';

  @override
  String get cannotDeleteTransferIcon => '无法删除“转账”图标。';

  @override
  String get deleteIconsDialogTitle => '删除图标';

  @override
  String deleteIconsConfirmationMessage(Object count) {
    return '您确定要删除这 $count 个选定的图标吗？';
  }

  @override
  String deleteIconsWithSkipTransferMessage(Object count) {
    return '您确定要删除这 $count 个选定的图标吗？（“转账”图标将被跳过）';
  }

  @override
  String get deleteIconDialogTitle => '删除图标';

  @override
  String deleteIconConfirmationMessage(Object name) {
    return '您确定要删除“$name”吗？';
  }

  @override
  String deleteMultipleAccountsTitle(Object count) {
    return '删除 $count 个账户？';
  }

  @override
  String get deleteMultipleAccountsMessage => '您确定要删除选中的账户吗？所有关联的交易都将被删除。';

  @override
  String get changeAccountTypeDialogTitle => '更改账户类型';

  @override
  String editAccountTitle(Object name) {
    return '编辑：$name';
  }

  @override
  String get balanceCalculatedFromAsset => '余额根据资产数量 * 价格计算';

  @override
  String get selectAccountTypeTitle => '选择账户类型';

  @override
  String get selectCountryTitle => '选择国家';

  @override
  String get selectIconSubtitle => '选择一个图标';

  @override
  String get bindToAssetLabel => '绑定到资产（可选）';

  @override
  String get selectAssetTitle => '选择资产';

  @override
  String get selectedAssetLabel => '已选资产';

  @override
  String get balanceAutoCalculatedLabel => '余额自动计算';

  @override
  String get tapToBindAssetLabel => '点击绑定资产';

  @override
  String get assetQuantityLabel => '资产数量';

  @override
  String get linkedAssetsTitle => '关联资产';

  @override
  String get noneLabel => '无';

  @override
  String get accountTypeLabel => '账户类型';

  @override
  String get formValidationPleaseSelectAccountType => '请选择账户类型';

  @override
  String get iconLabel => '图标';

  @override
  String get languageLabel => '语言';

  @override
  String get systemDefaultLabel => '系统默认';

  @override
  String get selectLanguageTitle => '选择语言';
}
