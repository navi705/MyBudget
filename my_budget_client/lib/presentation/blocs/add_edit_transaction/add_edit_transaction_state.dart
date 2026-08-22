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
    this.manualRateIsHistorical = false,
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

  /// Whether [manualExchangeRate] is the rate this transfer was actually made
  /// at, read back off the stored row, rather than a rate looked up now.
  ///
  /// The two are not interchangeable. A refetch keeps the field in step with
  /// Preset 1 whenever the two disagree, which is right for a form being
  /// filled in and wrong for one being reopened: it would replace the bank's
  /// rate from six months ago with today's, and the save writes the receiving
  /// leg from this field - so merely opening a transfer and pressing Save
  /// would move money the user never asked to move. While this is set, a
  /// refetch that was not asked to resync leaves the field alone.
  ///
  /// Cleared as soon as the field stops describing that stored rate: the user
  /// types over it, picks a preset, or changes the currency pair.
  final bool manualRateIsHistorical;
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

  /// The rate a conversion on this form actually multiplies by.
  ///
  /// [manualExchangeRate] is what the rate field holds and what selecting a
  /// preset writes into, and [isRateInputInverted] says which way round the
  /// user is stating it. Every consumer has to apply both, and every consumer
  /// that applied only one has been a bug: the preview that multiplied where
  /// the save divided, the preview that read `selectedExchangeRate` while the
  /// save read the typed value. Reading it from one place is what keeps the
  /// received-amount field, the rate summary and the saved row agreeing.
  ///
  /// Falls back to 1.0 - "no conversion" - so a caller can multiply without
  /// testing first. A transfer that reaches the save with no rate is refused
  /// there rather than silently converted at one.
  double get effectiveExchangeRate {
    if (manualExchangeRate.isNotEmpty) {
      final value = double.tryParse(manualExchangeRate) ?? 1.0;
      if (isRateInputInverted && value != 0) return 1.0 / value;
      return value;
    }
    return selectedExchangeRate?.rate ?? 1.0;
  }

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
    bool? manualRateIsHistorical,
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
      manualRateIsHistorical:
          manualRateIsHistorical ?? this.manualRateIsHistorical,
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
    manualRateIsHistorical,
    validationError,
  ];
}
