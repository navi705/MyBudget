part of 'add_edit_transaction_bloc.dart';

enum AddEditTransactionStatus { initial, loading, success, failure }

enum AssetAction { buy, sell }

class AddEditTransactionState extends Equatable {
  const AddEditTransactionState({
    this.status = AddEditTransactionStatus.initial,
    this.initialTransaction,
    this.description = '',
    this.amount = '',
    this.fee = '',
    this.selectedAccount,
    this.selectedCategory,
    this.date,
    this.accounts = const [],
    this.categories = const [],
    this.currencies = const [],
    this.selectedCurrency,
    this.availableExchangeRates = const [],
    this.selectedExchangeRate,
    this.manualExchangeRate = '',
    this.isLoadingRates = false,
    this.isSaving = false,
    this.isSaveSuccess = false,
    this.mainCurrencyCode = 'EUR',
    this.linkedAccount,
    this.assetPrice,
    this.assetAction = AssetAction.buy,
    this.totalValue = '',
    this.marketRate,
    this.projectedLoss = 0.0,
    this.recordExchangeLoss = false,
  });

  final AddEditTransactionStatus status;
  final Transaction? initialTransaction;
  final String description;
  final String amount;
  final String fee;
  final Account? selectedAccount;
  final Category? selectedCategory;
  final DateTime? date;
  final List<Account> accounts;
  final List<Category> categories;
  final List<Currency> currencies;
  final Currency? selectedCurrency;
  final List<ExchangeRateDomain> availableExchangeRates;
  final ExchangeRateDomain? selectedExchangeRate;
  final String manualExchangeRate;
  final bool isLoadingRates;
  final bool isSaving;
  final bool isSaveSuccess;
  final String mainCurrencyCode;

  bool get isEditing =>
      initialTransaction != null &&
      (initialTransaction!.id?.isNotEmpty ?? false);

  bool get isForeignCurrency {
    if (selectedAccount == null || selectedCurrency == null) return false;
    // Show rate section if transaction currency differs from account currency
    // OR if transaction currency is not the main currency (so we can set the rate to main).
    return selectedAccount!.currencyCode != selectedCurrency!.code ||
        selectedCurrency!.code != mainCurrencyCode;
  }

  final Account? linkedAccount;
  final double? assetPrice;
  final AssetAction assetAction;
  final String totalValue; // Value in Cash Currency
  final double? marketRate; // Market Rate (Preset 1) for Loss Calculation
  final double projectedLoss;
  final bool recordExchangeLoss;

  bool get isAssetTransaction => selectedAccount?.assetId != null;

  AddEditTransactionState copyWith({
    AddEditTransactionStatus? status,
    Transaction? initialTransaction,
    String? description,
    String? amount,
    String? fee,
    Account? selectedAccount,
    Category? selectedCategory,
    DateTime? date,
    List<Account>? accounts,
    List<Category>? categories,
    List<Currency>? currencies,
    Currency? selectedCurrency,
    List<ExchangeRateDomain>? availableExchangeRates,
    ExchangeRateDomain? selectedExchangeRate,
    String? manualExchangeRate,
    bool? isLoadingRates,
    bool? isSaving,
    bool? isSaveSuccess,
    String? mainCurrencyCode,
    Account? linkedAccount,
    double? assetPrice,
    AssetAction? assetAction,
    String? totalValue,
    double? marketRate,
    double? projectedLoss,
    bool? recordExchangeLoss,
  }) {
    return AddEditTransactionState(
      status: status ?? this.status,
      initialTransaction: initialTransaction ?? this.initialTransaction,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      fee: fee ?? this.fee,
      selectedAccount: selectedAccount ?? this.selectedAccount,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      date: date ?? this.date,
      accounts: accounts ?? this.accounts,
      categories: categories ?? this.categories,
      currencies: currencies ?? this.currencies,
      selectedCurrency: selectedCurrency ?? this.selectedCurrency,
      availableExchangeRates:
          availableExchangeRates ?? this.availableExchangeRates,
      selectedExchangeRate: selectedExchangeRate ?? this.selectedExchangeRate,
      manualExchangeRate: manualExchangeRate ?? this.manualExchangeRate,
      isLoadingRates: isLoadingRates ?? this.isLoadingRates,
      isSaving: isSaving ?? this.isSaving,
      isSaveSuccess: isSaveSuccess ?? this.isSaveSuccess,
      mainCurrencyCode: mainCurrencyCode ?? this.mainCurrencyCode,
      linkedAccount: linkedAccount ?? this.linkedAccount,
      assetPrice: assetPrice ?? this.assetPrice,
      assetAction: assetAction ?? this.assetAction,
      totalValue: totalValue ?? this.totalValue,
      marketRate: marketRate ?? this.marketRate,
      projectedLoss: projectedLoss ?? this.projectedLoss,
      recordExchangeLoss: recordExchangeLoss ?? this.recordExchangeLoss,
    );
  }

  @override
  List<Object?> get props => [
    status,
    initialTransaction,
    description,
    amount,
    fee,
    selectedAccount,
    selectedCategory,
    date,
    accounts,
    categories,
    currencies,
    selectedCurrency,
    availableExchangeRates,
    selectedExchangeRate,
    manualExchangeRate,
    isLoadingRates,
    isSaving,
    isSaveSuccess,
    mainCurrencyCode,
    linkedAccount,
    assetPrice,
    assetAction,
    totalValue,
    marketRate,
    projectedLoss,
    recordExchangeLoss,
  ];
}
