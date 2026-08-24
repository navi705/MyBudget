// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get collapseMenuTooltip => '收起菜单';

  @override
  String get expandMenuTooltip => '展开菜单';

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
  String get editAccountDialogTitle => '编辑账户';

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
  String get selectButton => '选择';

  @override
  String get selectAllButton => '全选';

  @override
  String get deselectAllButton => '取消全选';

  @override
  String get deleteSelectedButton => '删除选中';

  @override
  String totalCountLabel(Object count) {
    return '总计: $count';
  }

  @override
  String selectedCountLabel(Object count) {
    return '已选择 $count 个';
  }

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
  String get dashboardNetWorthTrend => '净资产趋势';

  @override
  String get dashboardWealthDistributionByAccount => '财富分布（按账户）';

  @override
  String get dashboardCurrencyExposure => '货币风险敞口';

  @override
  String get dashboardNoAccountsFound => '未找到账户';

  @override
  String get dashboardTotalNetWorthTrend => '总净资产趋势';

  @override
  String get dashboardAccountBalanceTrend => '账户余额趋势';

  @override
  String get dashboardWealthDistribution => '财富分布';

  @override
  String get dashboardCurrencyBreakdown => '货币明细';

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
  String get reviewQueueTooltip => '待核对队列';

  @override
  String get reviewQueueDescription => '仅显示导入时无法确定归类的交易';

  @override
  String get needsReviewBadgeLabel => '需要核对';

  @override
  String get selectDateTooltip => '选择日期';

  @override
  String get selectDateDescription => '选择特定日期范围以查看总计';

  @override
  String get sortOrderTooltip => '排序顺序';

  @override
  String get sortOrderDescription => '按金额切换升序和降序';

  @override
  String get closeSelectionTooltip => '关闭选择';

  @override
  String get exitSelectionDescription => '退出选择模式';

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
  String get exitTransactionsSelectionDescription => '退出交易选择模式';

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
  String get amountLabel => '金额';

  @override
  String quantityLabel(Object quantity) {
    return '数量: $quantity';
  }

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
  String get addTransactionTitle => '添加交易';

  @override
  String get editTransactionTitle => '编辑交易';

  @override
  String get newTransferTitle => '新建转账';

  @override
  String get editTransferTitle => '编辑转账';

  @override
  String get descriptionLabel => '描述';

  @override
  String get descriptionOptionalLabel => '描述（可选）';

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
  String get accountDeletedError => '您选择的账户已被删除，请另选一个。';

  @override
  String get linkedAccountDeletedError => '您选择的关联账户已被删除，请另选一个。';

  @override
  String get enterExchangeRateError => '请输入汇率。此转账在两种货币之间进行，但系统中没有它们之间的汇率记录。';

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
  String get themeSettingsTitle => '主题设置';

  @override
  String get appearanceSection => '外观';

  @override
  String get themeModeLabel => '主题模式';

  @override
  String get systemTheme => '系统默认';

  @override
  String get lightTheme => '浅色主题';

  @override
  String get darkTheme => '深色主题';

  @override
  String get colorCustomizationSection => '颜色自定义';

  @override
  String get primaryColorLabel => '主色';

  @override
  String get secondaryColorLabel => '辅色';

  @override
  String get surfaceColorLabel => '表面颜色';

  @override
  String get windowEffectsSection => '窗口效果（桌面端）';

  @override
  String get enableEffectsLabel => '启用窗口效果';

  @override
  String get windowEffectLabel => '窗口效果';

  @override
  String get backgroundLabel => '背景';

  @override
  String get removeBackgroundColor => '移除背景颜色';

  @override
  String get transparentSurfaceLabel => '透明表面（卡片）';

  @override
  String get fullyTransparentLabel => '完全透明';

  @override
  String get opaqueLabel => '不透明';

  @override
  String opacityLabel(Object value) {
    return '透明度: $value%';
  }

  @override
  String get backgroundSettingsSection => '背景设置';

  @override
  String get enableBackgroundImageLabel => '启用背景图片';

  @override
  String get backgroundBlurLabel => '背景模糊';

  @override
  String get surfaceGlassStyleTitle => '表面/玻璃样式';

  @override
  String get chooseImageButton => '选择图片';

  @override
  String get selectImageFileError => '请选择一个图片文件。';

  @override
  String get clearImageButton => '清除图片';

  @override
  String get saveThemePresetTitle => '保存主题预设';

  @override
  String get presetNameLabel => '预设名称';

  @override
  String get presetNameHint => '我的酷炫主题';

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
  String get apiManagementTitle => 'API 管理';

  @override
  String apiErrorLabel(String error) {
    return '错误: $error';
  }

  @override
  String apiLastFetchLabel(String date) {
    return '日期: $date';
  }

  @override
  String get apiCategoriesSection => 'API 类别';

  @override
  String get manualUtilitiesSection => '手动工具';

  @override
  String get startupDataSyncLabel => '启动时数据同步';

  @override
  String get startupDataSyncDescription => '控制应用启动时外部数据获取和服务器同步。';

  @override
  String get standardApiLabel => '标准 API';

  @override
  String get syncOnStartupDescription => '启动时同步';

  @override
  String get customSourcesLabel => '自定义来源';

  @override
  String syncCustomSourcesDescription(Object count) {
    return '启动时同步所有 ($count) 个来源';
  }

  @override
  String get individualCustomSourcesTitle => '单个自定义来源';

  @override
  String get noCustomSourcesAdded => '尚未添加自定义来源。';

  @override
  String get fetchTodaysRatesButton => '获取今日汇率';

  @override
  String get inflationConfigTitle => '通胀配置';

  @override
  String get countryCodeHint => '国家代码 (如 SRB)';

  @override
  String fetchDataForCountryButton(Object country) {
    return '获取 $country 的数据';
  }

  @override
  String get steamSettingsTitle => 'Steam 设置';

  @override
  String get steamIdLabel => 'Steam ID (64位)';

  @override
  String get steamIdHint => '例如 76561198085715972';

  @override
  String get preferredGameLabel => '首选游戏';

  @override
  String get fetchInventoryNowButton => '立即获取库存';

  @override
  String get manualExchangeRatesTitle => '手动获取汇率';

  @override
  String get selectStartDate => '选择开始日期';

  @override
  String startDateFrom(Object date) {
    return '自: $date';
  }

  @override
  String get selectEndDate => '选择结束日期';

  @override
  String endDateTo(Object date) {
    return '至: $date';
  }

  @override
  String get fetchRangeButton => '获取范围数据';

  @override
  String get manualSteamInventoryTitle => '手动获取 Steam 库存';

  @override
  String get selectGameHint => '选择游戏';

  @override
  String get fetchValueButton => '获取价值';

  @override
  String get manualInflationDataTitle => '手动获取通胀数据';

  @override
  String get selectStartYear => '选择开始年份';

  @override
  String startYearFrom(Object year) {
    return '自: $year';
  }

  @override
  String get selectEndYear => '选择结束年份';

  @override
  String endYearTo(Object year) {
    return '至: $year';
  }

  @override
  String get fetchDataButton => '获取数据';

  @override
  String get connectionOk => '连接正常';

  @override
  String get connectionFailed => '连接失败';

  @override
  String get testConnectionButton => '测试连接';

  @override
  String get editCustomSourceTitle => '编辑自定义来源';

  @override
  String get addCustomSourceTitle => '添加自定义来源';

  @override
  String get addressFormatsHelp => '地址格式：\n• 192.168.1.10 (IP)\n• localhost 或 api.my.com\n• http://myserver.com';

  @override
  String get customSourceNameHint => '我的家庭服务器';

  @override
  String get urlIpLabel => 'URL / IP';

  @override
  String get urlIpHint => '192.168.1.10:8080';

  @override
  String get dataTypeLabel => '数据类型';

  @override
  String get apiTitleExchangeRates => '汇率';

  @override
  String get apiTitleInflation => '通胀';

  @override
  String get apiTitleAssetPrices => '资产价格';

  @override
  String get apiTitleSteamInventory => 'Steam 库存';

  @override
  String get transferLabel => '转账';

  @override
  String get transactionModeLabel => '交易';

  @override
  String get uncategorizedLabel => '未分类';

  @override
  String get defaultLabel => '默认';

  @override
  String receivedTotalLabel(Object total) {
    return '已收取：$total';
  }

  @override
  String spentTotalLabel(Object total) {
    return '已花费：$total';
  }

  @override
  String get categoriesGridViewTooltip => '网格视图';

  @override
  String get categoriesListViewTooltip => '列表视图';

  @override
  String get categoriesGridBackTooltip => '所有类别';

  @override
  String get periodSummaryTitle => '期间摘要';

  @override
  String get incomeLabel => '收入';

  @override
  String get expenseLabel => '支出';

  @override
  String get netLabel => '净额';

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
  String get failedToLoadDashboard => '加载仪表板失败';

  @override
  String get dashboardCalendarTab => '日历';

  @override
  String get dashboardTabCalendar => '日历';

  @override
  String get dashboardCalendarTooltip => '日历视图';

  @override
  String get dashboardCalendarDescription => '以日历格式查看交易';

  @override
  String get dashboardCategoriesTab => '分类';

  @override
  String get dashboardTabCategories => '分类';

  @override
  String get dashboardCategoriesTooltip => '分类分析';

  @override
  String get dashboardCategoriesDescription => '按分类细分支出';

  @override
  String get dashboardBalanceTab => '余额';

  @override
  String get dashboardTabBalance => '余额';

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
  String get manageStylesDeleteTitle => '删除图标';

  @override
  String manageStylesDeleteConfirm(Object count) {
    return '您确定要删除选中的 $count 个图标吗？';
  }

  @override
  String manageStylesDeleteConfirmWithTransfer(Object count) {
    return '您确定要删除选中的 $count 个图标吗？（传输图标将被跳过）';
  }

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

  @override
  String get dashboardLabel => '仪表板';

  @override
  String get homeLabel => '首页';

  @override
  String get historyLabel => '历史';

  @override
  String get syncScreenTitle => '同步设置';

  @override
  String get syncP2PSection => 'P2P 同步 (Syncthing)';

  @override
  String get syncEnableP2P => '启用 P2P 同步';

  @override
  String get syncP2PSubtitle => '通过共享文件夹中的 .sync 文件进行同步';

  @override
  String get syncFolderLabel => '同步文件夹';

  @override
  String get syncFolderNotSelected => '未选择';

  @override
  String get syncBrowseButton => '浏览';

  @override
  String get syncClearFilesButton => '清除同步文件';

  @override
  String get syncServerSection => '云同步（服务器）';

  @override
  String get syncServerUrlLabel => '服务器 URL';

  @override
  String get syncApiTokenLabel => 'API 令牌';

  @override
  String get syncApiTokenHint => '输入您的安全令牌';

  @override
  String get syncApiTokenHelp => '此令牌是您的共享密钥。在所有设备上输入相同的值以授权同步。';

  @override
  String get syncTestConnectionButton => '测试连接';

  @override
  String get syncTestingLabel => '正在测试...';

  @override
  String get syncSaveServerSettingsButton => '保存服务器设置';

  @override
  String get syncEnableServer => '启用服务器同步';

  @override
  String get syncServerSubtitle => '与 MyBudget Server 实例同步';

  @override
  String get syncPendingLocalChanges => '待处理的本地更改：';

  @override
  String get syncSyncNowButton => '立即同步';

  @override
  String get syncSyncingLabel => '正在同步...';

  @override
  String get syncWebNotAvailable => '网页端不可用同步功能';

  @override
  String get syncPermissionRequired => '同步需要存储权限。请在设置中启用“访问所有文件”。';

  @override
  String get syncSelectFolderTitle => '选择 Syncthing 文件夹';

  @override
  String get syncClearFilesTitle => '清除同步文件';

  @override
  String get syncClearFilesConfirm => '这将删除选中文件夹中的所有 .sync 文件。此操作无法撤销。';

  @override
  String syncDeletedFilesCount(Object count) {
    return '已删除 $count 个同步文件';
  }

  @override
  String syncClearFilesError(Object error) {
    return '清除文件失败: $error';
  }

  @override
  String get syncSettingsSaved => '服务器设置已保存';

  @override
  String get syncConnectionSuccessful => '连接成功！';

  @override
  String get syncConnectionFailed => '连接失败。请检查 URL 和令牌。';

  @override
  String get syncConnectionUnauthorized => '服务器拒绝了该令牌。请检查令牌，而非地址。';

  @override
  String get syncServerNotConfigured => '服务器未配置同步令牌，因此拒绝所有设备。请在服务器上设置 SYNC_TOKEN，并在此处填入相同的值。';

  @override
  String get syncUrlNotConfigured => '未填写服务器地址。请先输入类似 https://example.com 的网址，再开启同步。';

  @override
  String get syncCompleted => '同步成功完成';

  @override
  String syncFailed(Object error) {
    return '同步失败: $error';
  }

  @override
  String get smsRuleAddTitle => '添加规则';

  @override
  String get smsRuleEditTitle => '编辑规则';

  @override
  String get smsRuleTransactionType => '交易类型';

  @override
  String get smsRuleMatchPattern => '匹配模式 (Regex)';

  @override
  String get smsRuleMatchPatternHint => '例如，卡消费';

  @override
  String get smsRuleMatchPatternHelp => '用于识别此类短信的模式';

  @override
  String get smsRuleAmountPattern => '金额模式 (Regex)';

  @override
  String get smsRuleAmountPatternHint => '例如，金额\\s+([\\d,.]+)';

  @override
  String get smsRuleAmountPatternHelp => '捕获组 1 应对应金额';

  @override
  String get smsRuleCurrencyPattern => '货币模式 (Regex, 可选)';

  @override
  String get smsRuleCurrencyPatternHint => '例如，[\\d,.]+\\s*(\\w\\w\\w)';

  @override
  String get smsRuleCurrencyPatternHelp => '捕获组 1 应对应货币代码';

  @override
  String get smsRuleTestTitle => '测试规则';

  @override
  String get smsRuleTestSmsHint => '在此粘贴短信文本';

  @override
  String get smsRuleTestButton => '测试模式';

  @override
  String get smsRuleTestEnterSmsError => '请输入短信文本进行测试';

  @override
  String get smsRuleTestMatchError => '✗ 匹配模式未找到结果';

  @override
  String get smsRuleTestAmountError => '✗ 金额模式未找到结果';

  @override
  String smsRuleTestSuccess(Object amount, Object currency, Object type) {
    return '✓ 找到匹配项！\n类型: $type\n金额: $amount\n货币: $currency';
  }

  @override
  String smsRuleTestRegexError(Object error) {
    return '✗ Regex 无效: $error';
  }

  @override
  String get smsRuleRequiredError => '匹配模式和金额模式为必填项';

  @override
  String inflationError(Object error) {
    return '错误: $error';
  }

  @override
  String get inflationNoRatesFound => '未找到通胀率。';

  @override
  String get inflationAddRate => '添加通胀率';

  @override
  String get inflationDeleteConfirmTitle => '删除通胀率？';

  @override
  String inflationDeleteConfirmMessage(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个通胀率',
      one: '个通胀率',
    );
    return '您确定要删除这 $_temp0 吗？';
  }

  @override
  String inflationSelectedCount(Object count) {
    return '已选择 $count 个';
  }

  @override
  String get inflationFiltersTitle => '通胀筛选';

  @override
  String get inflationCountries => '国家';

  @override
  String get inflationPresets => '预设';

  @override
  String deleteCategoryConfirmTitle(Object name) {
    return '删除 $name？';
  }

  @override
  String get deleteCategoryMessage => '此分类有关联交易。您希望怎么做？';

  @override
  String get deleteCategoryReassign => '将交易重新分配到另一个分类';

  @override
  String get deleteCategoryNewCategory => '新分类';

  @override
  String get deleteCategoryDeleteAll => '删除所有关联交易';

  @override
  String deleteAccountConfirmTitle(Object name) {
    return '删除 $name？';
  }

  @override
  String get deleteAccountMessage => '此账户可能有相关交易。您希望怎么做？';

  @override
  String get deleteAccountReassign => '将交易重新分配到另一个账户';

  @override
  String get deleteAccountNewAccount => '新账户';

  @override
  String get deleteAccountDeleteAll => '删除所有关联交易';

  @override
  String get confirmButton => '确认';

  @override
  String get okButton => '确定';

  @override
  String get noItemsFound => '未找到任何项。';

  @override
  String get noDataForPeriod => '此期间没有数据';

  @override
  String get noDataForRange => '此范围没有数据';

  @override
  String get noHistoryData => '无历史数据可用';

  @override
  String get disabledByGlobalSync => '由于全局同步已禁用';

  @override
  String dateCreatedLabel(Object date) {
    return '创建日期：$date';
  }

  @override
  String get anyLabel => '任意';

  @override
  String get balanceDisplayLabel => '显示余额';

  @override
  String currenciesActiveLabel(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 种活跃货币',
      one: '1 种活跃货币',
    );
    return '$_temp0';
  }

  @override
  String get searchCountryLabel => '搜索国家';

  @override
  String get addNewIconLabel => '添加新图标';

  @override
  String get noIconsFoundLabel => '未找到图标';

  @override
  String get addNewStyleLabel => '添加新样式';

  @override
  String get styleNameLabel => '样式名称';

  @override
  String get pleaseEnterStyleName => '请输入样式名称';

  @override
  String get colorLabel => '颜色';

  @override
  String get netBalanceMetric => '净余额';

  @override
  String get investedMetric => '已投资';

  @override
  String get realizedMetric => '已实现';

  @override
  String get feesMetric => '费用';

  @override
  String get persistFiltersLabel => '保留筛选';

  @override
  String get searchByNameHint => '通过名称搜索...';

  @override
  String get searchDescriptionHint => '通过描述搜索...';

  @override
  String get advancedFiltersTitle => '高级筛选';

  @override
  String get transactionTypeLabel => '交易类型';

  @override
  String get assetFiltersTitle => '资产筛选';

  @override
  String get minValueLabel => '最小值';

  @override
  String get maxValueLabel => '最大值';

  @override
  String get assetTypesLabel => '资产类型';

  @override
  String get allLabel => '全部';

  @override
  String get currenciesLabel => '货币';

  @override
  String get sourcesLabel => '来源';

  @override
  String get presetsLabel => '预设';

  @override
  String get enterCategoryNameHint => '输入分类名称';

  @override
  String get selectTypeHint => '选择类型';

  @override
  String get hotKeysTitle => '快捷键';

  @override
  String get searchHotkeysHint => '搜索快捷键...';

  @override
  String get noMatchingHotkeys => '未找到匹配的快捷键。';

  @override
  String recordingHotkeyTitle(Object label) {
    return '正在为“$label”录制快捷键';
  }

  @override
  String get pressKeysHint => '按键...';

  @override
  String get pressAnyCombinationHint => '按任意组合键。';

  @override
  String get clearSaveButton => '清除/保存';

  @override
  String get duplicateHotkeyTooltip => '预设快捷键重复';

  @override
  String usedByLabel(Object action) {
    return '用于 $action';
  }

  @override
  String get hkCategoryNavigation => '导航';

  @override
  String get hkCategoryDashboardTabs => '仪表板标签';

  @override
  String get hkCategoryDataTabs => '数据标签';

  @override
  String get hkCategoryPeriodControl => '周期控制';

  @override
  String get hkCategoryActions => '操作';

  @override
  String get hkCategorySelectionMode => '选择模式';

  @override
  String get hkActionBack => '全局: 返回/退出';

  @override
  String get hkActionDashboard => '前往仪表板';

  @override
  String get hkActionAccounts => '前往账户';

  @override
  String get hkActionTransactions => '前往交易';

  @override
  String get hkActionCategories => '前往分类';

  @override
  String get hkActionData => '前往数据/汇率';

  @override
  String get hkActionSettings => '前往设置';

  @override
  String get hkActionDashboardTab1 => '日历标签页';

  @override
  String get hkActionDashboardTab2 => '分类标签页';

  @override
  String get hkActionDashboardTab3 => '余额标签页';

  @override
  String get hkActionDataTab1 => '汇率';

  @override
  String get hkActionDataTab2 => '通胀';

  @override
  String get hkActionDataTab3 => '资产';

  @override
  String get hkActionPrevPeriod => '上一周期';

  @override
  String get hkActionNextPeriod => '下一周期';

  @override
  String get hkActionAddAction => '通用添加操作';

  @override
  String get hkActionSaveForm => '保存表单';

  @override
  String get hkActionPickDate => '选择日期';

  @override
  String get hkActionDashboardSwitchView => '仪表板: 更改视图';

  @override
  String get hkActionSortOrder => '排序顺序';

  @override
  String get hkActionFilterAction => '筛选';

  @override
  String get hkActionReviewQueue => '待复核队列';

  @override
  String get hkActionDashboardCurrency => '仪表板: 货币';

  @override
  String get hkActionAccountsSelectionClose => '账户: 关闭';

  @override
  String get hkActionAccountsSelectionAll => '账户: 全选';

  @override
  String get hkActionAccountsSelectionDelete => '账户: 删除';

  @override
  String get hkActionAccountsSelectionChangeType => '账户: 更改类型';

  @override
  String get hkActionTransactionsSelectionClose => '交易: 关闭';

  @override
  String get hkActionTransactionsSelectionDelete => '交易: 删除';

  @override
  String get hkActionTransactionsSelectionChangeDate => '交易: 更改日期';

  @override
  String get hkActionTransactionsSelectionChangeCategory => '交易: 更改分类';

  @override
  String get hkActionCategoriesSelectionClose => '分类: 关闭';

  @override
  String get hkActionCategoriesSelectionAll => '分类: 全选';

  @override
  String get hkActionCategoriesSelectionDelete => '分类: 删除';

  @override
  String get hkActionCategoriesSelectionChangeType => '分类: 更改类型';

  @override
  String get hkActionDataSelectionClose => '汇率: 关闭';

  @override
  String get hkActionDataSelectionAll => '汇率: 全选';

  @override
  String get hkActionDataSelectionDelete => '汇率: 删除';

  @override
  String get hkActionDataSelectionChangePreset => '汇率: 更改预设';

  @override
  String get hkActionInflationSelectionClose => '通胀: 关闭';

  @override
  String get hkActionInflationSelectionAll => '通胀: 全选';

  @override
  String get hkActionInflationSelectionDelete => '通胀: 删除';

  @override
  String get hkActionAssetSelectionClose => '资产: 关闭';

  @override
  String get hkActionAssetSelectionAll => '资产: 全选';

  @override
  String get hkActionAssetSelectionDelete => '资产: 删除';

  @override
  String get styNotFound => '未找到样式。';

  @override
  String get stySaveChanges => '保存更改';

  @override
  String get styAddIcon => '添加图标';

  @override
  String get smsOnlyAndroid => '短信导入仅在 Android 上可用';

  @override
  String get smsImportSms => '导入短信';

  @override
  String get smsPermissionRequired => '需要短信权限';

  @override
  String get smsPermissionRationale => '要从短信导入交易，我们需要读取您短信的权限。';

  @override
  String get smsGrantPermission => '授予权限';

  @override
  String get smsNoPresets => '尚未配置预设。点击 + 添加一个。';

  @override
  String get smsImportDescription => '从短信导入交易。请选择时间范围：';

  @override
  String get smsLast7Days => '最近 7 天';

  @override
  String get smsAllTime => '全部时间';

  @override
  String smsFilterLabel(Object filter) {
    return '筛选: $filter';
  }

  @override
  String get smsEditPreset => '编辑预设';

  @override
  String get smsNewPreset => '新预设';

  @override
  String get smsPresetNameHint => '例如，我的银行';

  @override
  String get smsSenderFilter => '发件人筛选';

  @override
  String get smsSenderFilterHint => '例如，ALTA 或 +381...';

  @override
  String get smsSenderFilterHelper => '按发件人名称或电话号码筛选短信';

  @override
  String get smsDefaults => '默认值';

  @override
  String get smsDefaultAccount => '默认账户';

  @override
  String get smsDefaultCategory => '默认分类';

  @override
  String get smsImportMessages => '导入消息';

  @override
  String get smsSelectDefaultsFirst => '请先选择默认值';

  @override
  String get smsCustomRange => '自定义范围';

  @override
  String smsImportSuccessCount(Object count) {
    return '成功: 已导入 $count 笔交易';
  }

  @override
  String get smsParsingRules => '解析规则';

  @override
  String get smsNoRules => '尚未定义规则。点击 + 添加一个。';

  @override
  String smsMatchLabel(Object pattern) {
    return '匹配: $pattern';
  }

  @override
  String get smsNameSenderRequired => '名称和发件人筛选为必填项';

  @override
  String get smsCategoryKeywords => '分类关键词';

  @override
  String get smsCategoryKeywordsSubtitle => '将短信内容中的关键词映射到分类';

  @override
  String get smsNoKeywordRules => '没有关键词规则。点击 + 添加一个。';

  @override
  String get smsAddKeywordRule => '添加关键词规则';

  @override
  String get smsKeyword => '关键词';

  @override
  String get smsKeywordHint => '例如，杂货, Netflix';

  @override
  String get smsKeywordHelper => '在短信内容中匹配的子字符串（不区分大小写）';

  @override
  String get smsSelectCategoryHint => '选择分类';

  @override
  String get dshSelectDateDescription => '打开日历以选择特定日期或范围';

  @override
  String get dshCurrencyDescription => '选择显示的主货币';

  @override
  String get dshChangeViewTooltip => '更改视图';

  @override
  String get dshChangeViewDescription => '在月度视图和年度视图之间切换';

  @override
  String get dshMonthlyAbbreviation => '月';

  @override
  String get dshYearlyAbbreviation => '年';

  @override
  String dshBalancesOnDate(Object date) {
    return '$date 的余额';
  }

  @override
  String get dshSearchCurrency => '搜索货币';

  @override
  String get dshUnknownCategory => '未知';

  @override
  String get pckSelectItem => '选择项目';

  @override
  String get pckSelectItems => '选择多个项目';

  @override
  String get pckClearAll => '全部清除';

  @override
  String get pckSelectIcon => '选择图标';

  @override
  String get pckMaterialIcons => 'Material 图标';

  @override
  String get pckCustomIcons => '自定义图标';

  @override
  String get fltAmountFrom => '金额从';

  @override
  String get fltAmountTo => '金额至';

  @override
  String get fltSelectRange => '选择范围';

  @override
  String get fltAdvancedFilterTooltip => '高级筛选';

  @override
  String get fltAdvancedFilterDescription => '按账户、分类或金额筛选交易';

  @override
  String get fltSortOrderDescription => '在升序和降序之间切换';

  @override
  String get fltAccountFiltersTitle => '账户筛选';

  @override
  String get fltNameLabel => '名称';

  @override
  String get fltAccountTypesLabel => '账户类型';

  @override
  String get fltFilterCurrenciesLabel => '筛选货币';

  @override
  String get fltSelectCurrenciesLabel => '选择货币';

  @override
  String get fltFilterCategoriesTitle => '筛选分类';

  @override
  String get exchAddExchangeRate => '添加汇率';

  @override
  String get exchEditExchangeRate => '编辑汇率';

  @override
  String get exchAddRateDescription => '手动输入两种货币之间的换算汇率';

  @override
  String get exchNoRatesFound => '未找到汇率。';

  @override
  String get exchChangePreset => '更改预设';

  @override
  String get exchFromCurrency => '源货币';

  @override
  String get exchToCurrency => '目标货币';

  @override
  String get exchRate => '汇率';

  @override
  String get exchPresetIdLabel => '预设 ID';

  @override
  String exchPresetValue(Object preset) {
    return '预设: $preset';
  }

  @override
  String get exchSelectRange => '选择范围';

  @override
  String get exchPreviousPeriodDescription => '转到上一天、上个月或上一年';

  @override
  String get exchNextPeriodDescription => '转到下一天、下个月或下一年';

  @override
  String get exchFilterDescription => '按源/目标货币和预设 ID 筛选汇率';

  @override
  String get exchSelectDateDescription => '选择特定日期或范围以查看历史汇率';

  @override
  String get exchSortOrderDescription => '按日期/汇率切换升序和降序';

  @override
  String get exchFilterExchangeRates => '筛选汇率';

  @override
  String get exchExitSelectionDescription => '退出汇率选择模式';

  @override
  String get exchSelectAllDescription => '选择所有列出的汇率';

  @override
  String get exchDeselectAllDescription => '取消选择所有汇率';

  @override
  String get exchChangePresetDescription => '更新所有选中汇率的预设 ID';

  @override
  String get exchDeleteSelectedDescription => '永久删除所有选中汇率';

  @override
  String get exchDeleteExchangeRatesTitle => '删除汇率';

  @override
  String exchDeleteConfirmMessage(Object count) {
    return '您确定要删除这 $count 个汇率吗？';
  }

  @override
  String get exchUpdatePresetTitle => '更新预设';

  @override
  String get exchUpdatePresetMessage => '为选中的项目输入新的预设 ID:';

  @override
  String dashboardUnconvertibleCurrencies(String currencies) {
    return '无法换算 $currencies，这些金额未计入总额';
  }

  @override
  String get addAccountBeforeTransactionDescription => '记录交易需要账户，请先创建第一个账户';

  @override
  String get selectDialogEmptyState => '暂时没有可供选择的内容';

  @override
  String get selectDialogNoMatches => '没有符合搜索的结果';

  @override
  String get addButton => '添加';

  @override
  String get retryButton => '重试';

  @override
  String get unknownLabel => '未知';

  @override
  String get globalLabel => '全球';

  @override
  String dateWithValueLabel(String date) {
    return '日期：$date';
  }

  @override
  String selectColorTitle(String label) {
    return '选择$label颜色';
  }

  @override
  String get assetAddTitle => '添加资产数据';

  @override
  String get assetEditTitle => '编辑资产数据';

  @override
  String get assetAddDescription => '记录某项资产的价值或数量';

  @override
  String get assetNameLabel => '资产名称（例如 苹果股票）';

  @override
  String get assetIdLabel => '资产代码（例如 AAPL）';

  @override
  String get assetValueLabel => '价值（单价）';

  @override
  String get assetTypeOptionalLabel => '资产类型（可选）';

  @override
  String get assetLinkedAccountOptionalLabel => '关联账户（可选）';

  @override
  String get assetNameRequiredError => '请为该资产填写名称';

  @override
  String get assetIdRequiredError => '请为该资产填写代码，例如 AAPL';

  @override
  String get assetValueInvalidError => '请输入数字，例如 150.25';

  @override
  String get assetNoAssetsFound => '未找到资产。';

  @override
  String assetError(String error) {
    return '错误：$error';
  }

  @override
  String get assetDeleteConfirmTitle => '删除资产？';

  @override
  String assetDeleteConfirmMessage(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
      
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '这 $countString 项资产',
      one: '这项资产',
    );
    return '您确定要删除$_temp0吗？';
  }

  @override
  String get assetDeleteSelectedDescription => '永久删除所有选中的资产记录';

  @override
  String get inflationEditRate => '编辑通胀率';

  @override
  String get inflationAddDescription => '为指定日期和国家输入新的通胀百分比';

  @override
  String get inflationPercentLabel => '通胀百分比 (%)';

  @override
  String get inflationPercentHint => '例如 2.5';

  @override
  String get inflationPercentInvalidError => '请输入数字，例如 2.5';

  @override
  String get inflationCountryGlobal => '国家：全球';

  @override
  String inflationCountryNamed(String country) {
    return '国家：$country';
  }

  @override
  String get inflationUseWorldwideRate => '使用全球通用比率';

  @override
  String get pickerSingleDate => '单个日期';

  @override
  String get pickerRange => '日期范围';

  @override
  String get dateStepDay => '日';

  @override
  String get dateStepMonth => '月';

  @override
  String get dateStepYear => '年';

  @override
  String get feeStructureTitle => '费用结构';

  @override
  String get feeNoRulesApplied => '未应用任何费用规则。';

  @override
  String get feeAddRule => '添加费用规则';

  @override
  String get feeFixedFee => '固定费用';

  @override
  String get feePercentFee => '百分比费用';

  @override
  String get feeTaxRate => '税率';

  @override
  String get feeUnknownRule => '未知规则';

  @override
  String get feeRatePercentLabel => '费率 (%)';

  @override
  String get feeTaxRatePercentLabel => '税率 (%)';

  @override
  String get feeCostBasisLabel => '成本基础';

  @override
  String deleteAccountsConfirmTitle(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
      
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString 个账户',
      one: '此账户',
    );
    return '删除$_temp0？';
  }

  @override
  String get deleteAccountsConfirmMessage => '确定要删除所选账户吗？所有关联的交易都将被删除。';

  @override
  String get changeAccountTypeTitle => '更改账户类型';

  @override
  String get accountsPreviousPeriodDescription => '转到上一个月或上一年';

  @override
  String get accountsNextPeriodDescription => '转到下一个月或下一年';

  @override
  String get accountsFilterDescription => '按类型或隐藏状态筛选账户';

  @override
  String get accountsSelectDateDescription => '选择具体日期以查看历史余额';

  @override
  String get accountsSortDescription => '在余额升序和降序之间切换';

  @override
  String get smsRuleCategoryOptional => '类别（可选）';

  @override
  String get smsRuleCategoryHelp => '为此规则覆盖类别';

  @override
  String amountSentLabel(Object currency) {
    return '转出金额（$currency）';
  }

  @override
  String amountReceivedLabel(Object currency) {
    return '转入金额（$currency）';
  }

  @override
  String transferRateSummary(Object from, Object rate, Object to) {
    return '1 $from = $rate $to';
  }

  @override
  String get adjustRateLabel => '调整汇率';

  @override
  String get favoriteCurrenciesHeader => '收藏';

  @override
  String get frequentCurrenciesHeader => '常用';

  @override
  String get allCurrenciesHeader => '全部货币';

  @override
  String get addFavoriteCurrencyTooltip => '添加到收藏';

  @override
  String get removeFavoriteCurrencyTooltip => '从收藏中移除';
}
