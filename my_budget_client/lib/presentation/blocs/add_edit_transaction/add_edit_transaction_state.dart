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
    this.editingExchangeRate,
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
    this.isTransferMode = false,
    this.isRateInputInverted = false,
    this.validationError,
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
  // The preset the Update/Delete buttons act on. Kept separate from
  // `selectedExchangeRate` because that field is deliberately cleared the
  // moment the user types a rate by hand (see `_onManualRateChanged`) so the
  // preset chip stops claiming a conversion it no longer describes - but the
  // whole point of typing over a preset's rate is to then press Update, and a
  // button that vanishes the instant its target field is edited can never be
  // pressed. This field tracks the same preset without being reset by typing.
  final ExchangeRateDomain? editingExchangeRate;
  final String manualExchangeRate;
  final bool isLoadingRates;
  final bool isSaving;
  final bool isSaveSuccess;
  final String mainCurrencyCode;

  final Account? linkedAccount;
  final double? assetPrice;
  final AssetAction assetAction;
  final String totalValue; // Value in Cash Currency
  final double? marketRate; // Market Rate (Preset 1) for Loss Calculation
  final bool isTransferMode;
  final bool isRateInputInverted; // New field for UX Toggle
  final String? validationError; // Error message for user feedback

  bool get isEditing =>
      initialTransaction != null &&
      (initialTransaction!.id?.isNotEmpty ?? false);

  bool get isForeignCurrency {
    if (selectedAccount == null || selectedCurrency == null) return false;

    // Asset Transaction: Check if Asset Currency (From) != Cash Currency (To)
    if (isAssetTransaction && linkedAccount != null) {
      return selectedAccount!.currencyCode != linkedAccount!.currencyCode;
    }

    // Transfer Mode: Check if From and To accounts have different currencies
    if (isTransferMode && linkedAccount != null) {
      return selectedAccount!.currencyCode != linkedAccount!.currencyCode;
    }

    // Standard Mode: Show rate section ONLY if transaction currency differs from account currency
    return selectedAccount!.currencyCode != selectedCurrency!.code;
  }

  bool get isAssetTransaction =>
      selectedAccount?.assetId != null && !isTransferMode;

  AddEditTransactionState copyWith({
    AddEditTransactionStatus? status,
    bool? isSaving,
    bool? isSaveSuccess,
    bool? isLoadingRates,
    List<Account>? accounts,
    List<Category>? categories,
    List<Currency>? currencies,
    Transaction? initialTransaction,
    String? description,
    String? amount,
    String? fee,
    Account? selectedAccount,
    // Same reason as clearLinkedAccount/clearValidationError: `null` is a
    // meaningful value here - "the account this transaction was on is gone" -
    // and a bare `selectedAccount ?? this.selectedAccount` cannot express it,
    // so a deleted account would stay selected and keep collecting writes.
    bool clearSelectedAccount = false,
    Category? selectedCategory,
    Currency? selectedCurrency,
    List<ExchangeRateDomain>? availableExchangeRates,
    ExchangeRateDomain? selectedExchangeRate,
    // Same reason as clearLinkedAccount/clearValidationError: `null` is a
    // meaningful value here - "no preset chip is selected" - and a bare
    // `selectedExchangeRate ?? this.selectedExchangeRate` cannot express it.
    bool clearSelectedExchangeRate = false,
    ExchangeRateDomain? editingExchangeRate,
    bool clearEditingExchangeRate = false,
    String? manualExchangeRate,
    DateTime? date,
    bool? isTransferMode,
    Account? linkedAccount,
    bool clearLinkedAccount = false, // Added to allow clearing
    String? mainCurrencyCode,
    AssetAction? assetAction,
    String? totalValue,
    double? assetPrice,
    double? marketRate,
    bool? isRateInputInverted,
    String? validationError,
    bool clearValidationError = false,
  }) {
    return AddEditTransactionState(
      status: status ?? this.status,
      isSaving: isSaving ?? this.isSaving,
      isSaveSuccess: isSaveSuccess ?? this.isSaveSuccess,
      isLoadingRates: isLoadingRates ?? this.isLoadingRates,
      accounts: accounts ?? this.accounts,
      categories: categories ?? this.categories,
      currencies: currencies ?? this.currencies,
      initialTransaction: initialTransaction ?? this.initialTransaction,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      fee: fee ?? this.fee,
      selectedAccount: clearSelectedAccount
          ? null
          : (selectedAccount ?? this.selectedAccount),
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedCurrency: selectedCurrency ?? this.selectedCurrency,
      availableExchangeRates:
          availableExchangeRates ?? this.availableExchangeRates,
      selectedExchangeRate: clearSelectedExchangeRate
          ? null
          : (selectedExchangeRate ?? this.selectedExchangeRate),
      editingExchangeRate: clearEditingExchangeRate
          ? null
          : (editingExchangeRate ?? this.editingExchangeRate),
      manualExchangeRate: manualExchangeRate ?? this.manualExchangeRate,
      date: date ?? this.date,
      isTransferMode: isTransferMode ?? this.isTransferMode,
      linkedAccount: clearLinkedAccount
          ? null
          : (linkedAccount ?? this.linkedAccount),
      mainCurrencyCode: mainCurrencyCode ?? this.mainCurrencyCode,
      assetAction: assetAction ?? this.assetAction,
      totalValue: totalValue ?? this.totalValue,
      assetPrice: assetPrice ?? this.assetPrice,
      marketRate: marketRate ?? this.marketRate,
      isRateInputInverted: isRateInputInverted ?? this.isRateInputInverted,
      validationError: clearValidationError
          ? null
          : (validationError ?? this.validationError),
    );
  }

  @override
  List<Object?> get props => [
    status,
    isSaving,
    isSaveSuccess,
    isLoadingRates,
    accounts,
    categories,
    currencies,
    initialTransaction,
    description,
    amount,
    fee,
    selectedAccount,
    selectedCategory,
    selectedCurrency,
    availableExchangeRates,
    selectedExchangeRate,
    editingExchangeRate,
    manualExchangeRate,
    date,
    isTransferMode,
    linkedAccount,
    mainCurrencyCode,
    assetAction,
    totalValue,
    assetPrice,
    marketRate,
    isRateInputInverted,
    validationError,
  ];
}
