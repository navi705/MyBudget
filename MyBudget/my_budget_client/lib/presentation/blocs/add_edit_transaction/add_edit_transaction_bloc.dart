import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart'; // Added
import 'package:uuid/uuid.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/domain/repositories/asset_repository.dart';
import 'package:my_budget_client/core/constants/app_constants.dart'; // Added

part 'add_edit_transaction_event.dart';
part 'add_edit_transaction_state.dart';

class AddEditTransactionBloc
    extends Bloc<AddEditTransactionEvent, AddEditTransactionState> {
  final TransactionRepository _transactionRepository;
  final AccountRepository _accountRepository;
  final CategoryRepository _categoryRepository;
  final CurrencyRepository _currencyRepository;
  final SettingsRepository _settingsRepository;
  final AssetRepository _assetRepository; // Added

  AddEditTransactionBloc({
    required TransactionRepository transactionRepository,
    required AccountRepository accountRepository,
    required CategoryRepository categoryRepository,
    required CurrencyRepository currencyRepository,
    required SettingsRepository settingsRepository,
    required AssetRepository assetRepository, // Added
  }) : _transactionRepository = transactionRepository,
       _accountRepository = accountRepository,
       _categoryRepository = categoryRepository,
       _currencyRepository = currencyRepository,
       _settingsRepository = settingsRepository,
       _assetRepository = assetRepository, // Added
       super(const AddEditTransactionState()) {
    on<AddEditTransactionLoad>(_onLoad);
    on<AddEditTransactionDescriptionChanged>(_onDescriptionChanged);
    on<AddEditTransactionAmountChanged>(_onAmountChanged);
    on<AddEditTransactionFeeChanged>(_onFeeChanged); // Added
    on<AddEditTransactionAccountChanged>(_onAccountChanged);
    on<AddEditTransactionCategoryChanged>(_onCategoryChanged);
    on<AddEditTransactionDateChanged>(_onDateChanged);
    on<AddEditTransactionSubmitted>(_onSubmitted);
    on<AddEditTransactionCurrencyChanged>(_onCurrencyChanged); // Added
    on<AddEditTransactionRatePresetChanged>(_onRatePresetChanged);
    on<AddEditTransactionManualRateChanged>(_onManualRateChanged);
    on<AddEditTransactionAddNewRate>(_onAddNewRate);
    on<AddEditTransactionUpdatePreset>(_onUpdatePreset);
    on<AddEditTransactionLinkedAccountChanged>(
      _onLinkedAccountChanged,
    ); // Added
    on<AddEditTransactionAssetActionChanged>(_onAssetActionChanged); // Added
    on<AddEditTransactionTotalValueChanged>(_onTotalValueChanged); // Added
    on<AddEditTransactionRecordExchangeLossChanged>(
      _onRecordExchangeLossChanged,
    ); // Added
  }

  Future<void> _onLoad(
    AddEditTransactionLoad event,
    Emitter<AddEditTransactionState> emit,
  ) async {
    emit(state.copyWith(status: AddEditTransactionStatus.loading));

    try {
      final accounts = await _accountRepository.getAccounts();
      final categories = await _categoryRepository.getCategories();
      final currencies = await _currencyRepository.getCurrencies();
      final mainCurrencySetting = await _settingsRepository.getSetting(
        'main_currency_code',
      );
      final mainCurrencyCode = mainCurrencySetting?.value ?? 'EUR';
      final initialTransaction = event.transaction;

      Account? selectedAccount;
      if (initialTransaction != null) {
        selectedAccount = accounts.firstWhereOrNull(
          (a) => a.id == initialTransaction.accountId,
        );
      } else if (event.accountId != null) {
        selectedAccount = accounts.firstWhereOrNull(
          (a) => a.id == event.accountId,
        );
      }

      if (selectedAccount == null && accounts.isNotEmpty) {
        selectedAccount = accounts.first;
      }

      final selectedCategory = initialTransaction != null
          ? categories.firstWhereOrNull(
              (c) => c.id == initialTransaction.categoryId,
            )
          : (categories.isNotEmpty ? categories.first : null);

      Currency? selectedCurrency;
      if (initialTransaction != null) {
        selectedCurrency = currencies.firstWhereOrNull(
          (c) => c.code == initialTransaction.currencyCode,
        );
      }
      if (selectedCurrency == null && selectedAccount != null) {
        selectedCurrency = currencies.firstWhereOrNull(
          (c) => c.code == selectedAccount!.currencyCode,
        );
      }
      if (selectedCurrency == null && currencies.isNotEmpty) {
        selectedCurrency = currencies.first;
      }

      emit(
        state.copyWith(
          status: AddEditTransactionStatus.success,
          accounts: accounts,
          categories: categories,
          currencies: currencies, // Added
          initialTransaction: initialTransaction,
          description: initialTransaction?.description ?? '',
          amount: initialTransaction?.amount.toString() ?? '',
          fee: initialTransaction?.fee.toString() ?? '', // Added
          selectedAccount: selectedAccount,
          selectedCategory: selectedCategory,
          isTransferMode: event.isTransfer, // Set transfer mode
          selectedCurrency: selectedCurrency, // Added
          date: initialTransaction?.date ?? DateTime.now(),
          manualExchangeRate:
              initialTransaction?.exchangeRate?.toString() ?? '',
          mainCurrencyCode: mainCurrencyCode,
        ),
      );

      // Trigger fetch if foreign currency
      if (state.isForeignCurrency) {
        await _fetchRates(emit, selectedCurrency, selectedAccount, state.date);
      }

      // Check if existing transaction is a Transfer (for Edit Mode)
      bool isTransferEdit = false;
      Account? linkedAccount;

      if (initialTransaction != null &&
          initialTransaction.linkedTransactionId != null) {
        final transferId = await _getOrCreateTransferCategory();
        // Allow for legacy 'Transfer' type check or specific System Category ID
        final isTransferCat =
            initialTransaction.categoryId == transferId ||
            selectedCategory?.type == CategoryType.transfer;

        if (isTransferCat) {
          isTransferEdit = true;
          // Fetch Linked Transaction to get Account
          try {
            final linkedTx = await _transactionRepository.getTransactionById(
              initialTransaction.linkedTransactionId!,
            );
            if (linkedTx != null) {
              linkedAccount = accounts.firstWhereOrNull(
                (a) => a.id == linkedTx.accountId,
              );
            }
          } catch (_) {
            // Ignore if linked tx not found
          }
        }
      }

      if (isTransferEdit) {
        emit(
          state.copyWith(isTransferMode: true, linkedAccount: linkedAccount),
        );
      }

      // Trigger fetch if asset account (unless it's a transfer we just handled?)
      // Asset transactions also have linkedTransactionId, but they set isAssetTransaction = true.
      // If selectedAccount.assetId != null, it's an asset transaction.
      // isTransferMode should ideally be false for Asset Transactions?
      // User requested "Split Transfer Action", so Transfer Mode implies Cash Transfer.
      // If it is Asset Transaction, we use Asset UI.
      if (selectedAccount?.assetId != null) {
        await _fetchAssetDetails(emit, selectedAccount!);
      }

      // Handle Transfer Mode initialization
      if (event.isTransfer) {
        final transferId = await _getOrCreateTransferCategory();
        // Force selection of system transfer category
        // Fetch it specifically since it might be hidden from standard list
        Category? transferCat = categories.firstWhereOrNull(
          (c) => c.id == transferId,
        );
        if (transferCat == null) {
          final allCats = await _categoryRepository.getCategories(
            includeSystem: true,
          );
          transferCat = allCats.firstWhereOrNull((c) => c.id == transferId);
        }

        emit(state.copyWith(selectedCategory: transferCat));

        // Auto-select linked account if not set (first other account)
        if (state.linkedAccount == null && accounts.isNotEmpty) {
          final other = accounts.firstWhereOrNull(
            (a) => a.id != selectedAccount?.id,
          );
          emit(state.copyWith(linkedAccount: other));
        }
      }
    } catch (_) {
      emit(state.copyWith(status: AddEditTransactionStatus.failure));
    }
  }

  Future<void> _fetchAssetDetails(
    Emitter<AddEditTransactionState> emit,
    Account account,
  ) async {
    if (account.assetId == null) return;
    try {
      final assets = await _assetRepository.getAssetData(
        assetId: account.assetId,
        limit: 1,
        // TODO: should we fetch latest available or for the specific date?
        // Ideally specific date, but for "Add" it's Usually Now.
        // For Edit, it should be transaction date.
        endDate: state.date ?? DateTime.now(),
      );

      if (assets.isNotEmpty) {
        final asset = assets.first;
        var newState = state.copyWith(assetPrice: asset.value);

        // Also set linked account if not set (default to first cash account)
        Account? linked = state.linkedAccount;
        if (linked == null) {
          linked = state.accounts.firstWhereOrNull(
            (a) => a.assetId == null && a.id != account.id,
          );
          newState = newState.copyWith(linkedAccount: linked);
        }

        emit(newState); // Emit first with price/linked

        // Fetch Rate Asset -> Cash
        if (linked != null) {
          await _fetchAssetToCashRate(
            emit,
            assetCurrency: asset.currency,
            cashCurrency: linked.currencyCode,
            date: state.date,
          );
        }
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _fetchAssetToCashRate(
    Emitter<AddEditTransactionState> emit, {
    required String assetCurrency,
    required String cashCurrency,
    DateTime? date,
  }) async {
    if (assetCurrency == cashCurrency) {
      emit(state.copyWith(marketRate: 1.0));
    } else {
      final rates = await _currencyRepository.getExchangeRatesFiltered(
        fromCurrency: assetCurrency,
        toCurrency: cashCurrency,
        endDate: date ?? DateTime.now(),
        limit: 10,
        sortAscending: false,
      );
      final market =
          rates.firstWhereOrNull((r) => r.preset == 1) ?? rates.firstOrNull;
      emit(state.copyWith(marketRate: market?.rate ?? 1.0));
    }

    // Recalculate Logic after rate update
    _updateAssetCalculations(emit, state);
  }

  void _updateAssetCalculations(
    Emitter<AddEditTransactionState> emit,
    AddEditTransactionState newState,
  ) {
    if (!newState.isAssetTransaction) {
      // emit(newState); // Loop danger if called from fetch? No.
      return;
    }

    // Calculate Projected Loss
    double loss = 0.0;
    // Only calculate if we have price and rate
    if (newState.assetPrice != null && newState.marketRate != null) {
      double qty = double.tryParse(newState.amount) ?? 0.0;
      double totalCash = double.tryParse(newState.totalValue) ?? 0.0;

      // Market Value in Cash = Qty * Price(Asset) * Rate(Asset->Cash)
      double marketValue = qty * newState.assetPrice! * newState.marketRate!;

      if (newState.assetAction == AssetAction.buy) {
        loss = totalCash - marketValue;
      } else {
        loss = marketValue - totalCash;
      }
    }

    emit(newState.copyWith(projectedLoss: loss));
  }

  void _onDescriptionChanged(
    AddEditTransactionDescriptionChanged event,
    Emitter<AddEditTransactionState> emit,
  ) {
    emit(state.copyWith(description: event.description));
  }

  void _onAmountChanged(
    AddEditTransactionAmountChanged event,
    Emitter<AddEditTransactionState> emit,
  ) {
    var newState = state.copyWith(amount: event.amount);

    // If Asset Transaction, sync Total Value
    if (newState.isAssetTransaction && newState.assetPrice != null) {
      final qty = double.tryParse(event.amount) ?? 0.0;
      // Total = Qty * Price * Rate
      final rate = newState.marketRate ?? 1.0;
      final total = qty * newState.assetPrice! * rate;
      newState = newState.copyWith(totalValue: total.toStringAsFixed(2));
    }

    emit(newState);
    _updateAssetCalculations(emit, newState);
  }

  void _onFeeChanged(
    AddEditTransactionFeeChanged event,
    Emitter<AddEditTransactionState> emit,
  ) {
    emit(state.copyWith(fee: event.fee));
  }

  Future<void> _onAccountChanged(
    AddEditTransactionAccountChanged event,
    Emitter<AddEditTransactionState> emit,
  ) async {
    emit(state.copyWith(selectedAccount: event.account));

    if (event.account.assetId != null) {
      await _fetchAssetDetails(emit, event.account);
    }

    // Check for foreign currency logic
    if (state.selectedCurrency != null && state.date != null) {
      await _fetchRates(
        emit,
        state.selectedCurrency,
        event.account,
        state.date,
      );
    }
  }

  void _onCategoryChanged(
    AddEditTransactionCategoryChanged event,
    Emitter<AddEditTransactionState> emit,
  ) {
    emit(state.copyWith(selectedCategory: event.category));
  }

  Future<void> _onLinkedAccountChanged(
    AddEditTransactionLinkedAccountChanged event,
    Emitter<AddEditTransactionState> emit,
  ) async {
    emit(state.copyWith(linkedAccount: event.account));

    // Fetch Rate Asset -> New Linked Account
    if (state.selectedAccount != null &&
        state.selectedAccount!.assetId != null) {
      await _fetchAssetToCashRate(
        emit,
        assetCurrency: state.selectedAccount!.currencyCode,
        cashCurrency: event.account.currencyCode,
        date: state.date,
      );
    }
  }

  void _onAssetActionChanged(
    AddEditTransactionAssetActionChanged event,
    Emitter<AddEditTransactionState> emit,
  ) {
    emit(state.copyWith(assetAction: event.action));
  }

  void _onTotalValueChanged(
    AddEditTransactionTotalValueChanged event,
    Emitter<AddEditTransactionState> emit,
  ) {
    var newState = state.copyWith(totalValue: event.value);

    if (newState.isAssetTransaction &&
        newState.assetPrice != null &&
        newState.assetPrice! > 0) {
      final total = double.tryParse(event.value) ?? 0.0;
      final rate = newState.marketRate ?? 1.0;
      // Qty = Total / (Price * Rate)
      if (rate > 0) {
        final qty = total / (newState.assetPrice! * rate);
        newState = newState.copyWith(amount: qty.toStringAsFixed(6));
      }
    }

    emit(newState);
    _updateAssetCalculations(emit, newState);
  }

  void _onRecordExchangeLossChanged(
    AddEditTransactionRecordExchangeLossChanged event,
    Emitter<AddEditTransactionState> emit,
  ) {
    emit(state.copyWith(recordExchangeLoss: event.record));
  }

  Future<void> _onDateChanged(
    AddEditTransactionDateChanged event,
    Emitter<AddEditTransactionState> emit,
  ) async {
    emit(state.copyWith(date: event.date));
    if (state.selectedCurrency != null && state.selectedAccount != null) {
      await _fetchRates(
        emit,
        state.selectedCurrency,
        state.selectedAccount,
        event.date,
      );
    }
  }

  Future<void> _onSubmitted(
    AddEditTransactionSubmitted event,
    Emitter<AddEditTransactionState> emit,
  ) async {
    emit(state.copyWith(isSaving: true));

    try {
      var amount = double.tryParse(state.amount);
      var fee = double.tryParse(state.fee) ?? 0.0;
      final date = state.date;
      final accountId = state.selectedAccount?.id;
      // For Asset transactions, category is resolved later
      var categoryId = state.selectedCategory?.id;
      final categoryType = state.selectedCategory?.type;

      // Basic Validation
      if (amount == null || accountId == null || date == null) {
        // Note: Category validation moved lower for asset tx
        emit(state.copyWith(isSaving: false));
        return;
      }

      // Category Validation (Asset transactions auto-resolve, others need selection)
      if (!state.isAssetTransaction &&
          !state.isTransferMode &&
          categoryId == null) {
        emit(state.copyWith(isSaving: false));
        return;
      }

      if (state.isTransferMode) {
        categoryId = await _getOrCreateTransferCategory();
      }

      // Asset Transaction Validation
      if (state.isAssetTransaction) {
        if (state.linkedAccount == null) {
          // Error: Linked account required
          emit(state.copyWith(isSaving: false));
          return;
        }

        // Auto-resolve Transfer Category
        categoryId = await _getOrCreateTransferCategory();
      }

      // Enforce sign based on CategoryType (for Standard Transactions)
      if (!state.isAssetTransaction) {
        if (categoryType == CategoryType.expense) {
          if (amount > 0) amount = -amount;
        } else if (categoryType == CategoryType.income) {
          if (amount < 0) amount = amount.abs();
        }
      }

      double? finalExchangeRate;
      int? finalPreset;

      if (state.isForeignCurrency) {
        if (state.selectedExchangeRate != null) {
          finalExchangeRate = state.selectedExchangeRate!.rate;
          finalPreset = state.selectedExchangeRate!.preset;
        } else {
          finalExchangeRate = double.tryParse(state.manualExchangeRate);
        }
      }

      if (state.isAssetTransaction) {
        // --- ASSET TRANSACTION LOGIC ---
        final qty = amount; // amount is Quantity and non-null here
        final totalValue = double.tryParse(state.totalValue) ?? 0.0;

        // IDs
        final assetTxId = const Uuid().v4();
        final cashTxId = const Uuid().v4();

        // 1. Asset Transaction (Quantity)
        // Buy = Positive Quantity, Sell = Negative Quantity
        final assetAmount = state.assetAction == AssetAction.buy
            ? qty.abs()
            : -qty.abs();

        // Ensure categoryId is not null (should be resolved by now)
        if (categoryId == null) {
          emit(state.copyWith(isSaving: false));
          return;
        }

        // 2. Cash Transaction (Value)

        // If Recording Exchange Loss, we split the Total Value into:
        // Market Value (Transfer) + Loss (Expense)

        double adjustedTotalValue = totalValue;
        if (state.recordExchangeLoss && state.projectedLoss > 0) {
          if (state.assetAction == AssetAction.buy) {
            // Buy: Loss = Total (Paid) - Market.
            // So Market = Total - Loss.
            adjustedTotalValue = totalValue - state.projectedLoss;
          } else {
            // Sell: Loss = Market - Total (Received).
            // So Market = Total + Loss.
            adjustedTotalValue = totalValue + state.projectedLoss;
          }
        }

        final cashAmount = state.assetAction == AssetAction.buy
            ? -(adjustedTotalValue + fee)
            : (adjustedTotalValue - fee);

        final assetTx = Transaction(
          id: assetTxId,
          description: state.description.isEmpty
              ? '${state.assetAction == AssetAction.buy ? 'Buy' : 'Sell'} ${state.selectedAccount?.name}'
              : state.description,
          amount: assetAmount,
          date: date,
          accountId: accountId,
          categoryId: categoryId,
          currencyCode: state.selectedAccount!.currencyCode,
          fee: fee,
          linkedTransactionId: cashTxId,
        );

        final cashTx = Transaction(
          id: cashTxId,
          description:
              'Transfer for ${state.assetAction == AssetAction.buy ? 'Buy' : 'Sell'} ${state.selectedAccount?.name}',
          amount: cashAmount,
          date: date,
          accountId: state.linkedAccount!.id!,
          categoryId: categoryId, // Same category?
          currencyCode:
              state.linkedAccount!.currencyCode, // Could be different!
          // Conversion rate handling if currencies differ...
          // For now assume Cash Value is explicitly entered in Cash Currency via Total Value?
          // Or Total Value is in Asset Currency and converted?
          // Plan said: "Bidirectional between Qty and Total Value".
          // If Price is in Asset Currency (e.g. USD) and Linked Account is EUR.
          // We need conversion rate.
          linkedTransactionId: assetTxId,
        );

        // Currency Conversion:
        // Asset Price is in [state.selectedAccount!.currencyCode].
        // Cash Account is [state.linkedAccount!.currencyCode].
        // If they differ, we need to convert `totalValue` before using it for Cash Amount?
        // Actually, Total Value Field currently displays [linkedAccount.currencyCode] prefix.
        // So the user enters the CASH VALUE directly.
        // Thus, no conversion needed for cashAmount.
        // BUT, we might need to store the Exchange Rate used for reference?
        // Or calculate the Asset Price in Asset Currency?
        // Asset Price = (Total Value / Quantity) * ExchangeRate?
        // For simplicity now: User inputs Quantity and Total Value (in Cash Currency).
        // The Asset Transaction Amount is Quantity.
        // The Cash Transaction Amount is Total Value.

        // If currencies differ, valid exchange rate is implicit:
        // Rate = Total Value (Cash Curr) / (Quantity * Asset Price (Asset Curr))?
        // No, keep it simple. Just transfer values.

        await _transactionRepository.addTransaction(assetTx);
        await _transactionRepository.addTransaction(cashTx);
      } else if (state.isTransferMode) {
        // --- TRANSFER LOGIC ---
        // 1. From Account (Expense)
        // 2. To Account (Income)

        if (state.linkedAccount == null) {
          emit(state.copyWith(isSaving: false));
          return;
        }

        final txId1 = const Uuid().v4();
        final txId2 = const Uuid().v4();

        // From: Expense
        final tx1 = Transaction(
          id: txId1,
          description: state.description.isEmpty
              ? 'Transfer to ${state.linkedAccount!.name}'
              : state.description,
          amount: -(amount.abs()),
          date: date,
          accountId: accountId!,
          categoryId: categoryId!,
          currencyCode:
              state.selectedCurrency?.code ??
              state.selectedAccount!.currencyCode,
          linkedTransactionId: txId2,
        );

        // To: Income
        // Check for currency conversion?
        // Basic implementation: Just add positive amount (assuming same currency or raw value transfer)
        // If currencies differ, users usually expect the "Value" to be converted.
        // But for now, let's assume raw amount transfer or handle basic same-value Different-Currency?
        // Ideally we should ask for "Receive Amount", currently we only have one Amount field.
        // We will assume 1:1 value transfer for simplicity unless exchange rate is used.
        // But Exchange Rate UI is shown if currencies differ.
        // Adjusted Amount = Amount * Rate.

        double receiveAmount = amount.abs();
        if (state.isForeignCurrency && finalExchangeRate != null) {
          receiveAmount = receiveAmount * finalExchangeRate;
        }

        final tx2 = Transaction(
          id: txId2,
          description: 'Transfer from ${state.selectedAccount!.name}',
          amount: receiveAmount,
          date: date,
          accountId: state.linkedAccount!.id!,
          categoryId: categoryId,
          currencyCode: state.linkedAccount!.currencyCode,
          linkedTransactionId: txId1,
        );

        await _transactionRepository.addTransaction(tx1);
        await _transactionRepository.addTransaction(tx2);
      } else {
        // --- STANDARD LOGIC ---
        if (state.isEditing) {
          final updatedTransaction = state.initialTransaction!.copyWith(
            description: state.description,
            amount: amount,
            date: date,
            accountId: accountId,
            categoryId: categoryId,
            currencyCode:
                state.selectedCurrency?.code ??
                state.selectedAccount!.currencyCode,
            exchangeRate: finalExchangeRate,
            exchangeRatePreset: finalPreset,
            fee: fee,
          );
          await _transactionRepository.updateTransaction(updatedTransaction);
        } else {
          final newTransaction = Transaction(
            description: state.description,
            amount: amount,
            date: date,
            accountId: accountId!,
            categoryId: categoryId!,
            currencyCode:
                state.selectedCurrency?.code ??
                state.selectedAccount!.currencyCode,
            exchangeRate: finalExchangeRate,
            exchangeRatePreset: finalPreset,
            fee: fee,
          );
          await _transactionRepository.addTransaction(newTransaction);
        }
      }

      // --- EXCHANGE LOSS LOGIC ---
      if (state.recordExchangeLoss && state.projectedLoss > 0) {
        // Create 3rd transaction
        final lossTx = Transaction(
          description: 'Exchange Loss: ${state.description}',
          amount: -state.projectedLoss, // Expense
          date: date,
          accountId: state.isAssetTransaction
              ? state.linkedAccount!.id!
              : accountId!,
          categoryId: categoryId!,
          currencyCode: state.linkedAccount!.currencyCode,
        );
        await _transactionRepository.addTransaction(lossTx);
      }

      emit(state.copyWith(isSaving: false, isSaveSuccess: true));
    } catch (_) {
      emit(state.copyWith(isSaving: false));
    }
  }

  Future<void> _onCurrencyChanged(
    AddEditTransactionCurrencyChanged event,
    Emitter<AddEditTransactionState> emit,
  ) async {
    emit(state.copyWith(selectedCurrency: event.currency));
    if (state.selectedAccount != null && state.date != null) {
      await _fetchRates(
        emit,
        event.currency,
        state.selectedAccount,
        state.date,
      );
    }
  }

  Future<String> _getOrCreateTransferCategory() async {
    try {
      final categories = await _categoryRepository.getCategories(
        includeSystem: true,
      );
      var transferCat = categories.firstWhereOrNull(
        (c) => c.name == AppConstants.systemTransferCategoryName,
      );

      if (transferCat != null) return transferCat.id!;

      // Create if not exists
      final newCat = Category(
        name: AppConstants.systemTransferCategoryName,
        type: CategoryType.transfer,
      );
      await _categoryRepository.addCategory(newCat);

      final newCategories = await _categoryRepository.getCategories(
        includeSystem: true,
      );
      return newCategories
          .firstWhere((c) => c.name == AppConstants.systemTransferCategoryName)
          .id!;
    } catch (e) {
      final categories = await _categoryRepository.getCategories(
        includeSystem: true,
      );
      return categories.first.id!;
    }
  }

  Future<void> _fetchRates(
    Emitter<AddEditTransactionState> emit,
    Currency? fromCurrency,
    Account? toAccount,
    DateTime? date,
  ) async {
    if (fromCurrency == null || toAccount == null || date == null) return;

    // If same currency AND it is the main currency, clear rates
    if (fromCurrency.code == toAccount.currencyCode &&
        fromCurrency.code == state.mainCurrencyCode) {
      emit(state.copyWith(availableExchangeRates: []));
      return;
    }

    final toCurrencyCode = fromCurrency.code == toAccount.currencyCode
        ? state.mainCurrencyCode
        : toAccount.currencyCode;

    emit(state.copyWith(isLoadingRates: true));
    try {
      // Fetch ALL rates for this currency pair, ignoring date first.
      List<ExchangeRateDomain> allRates = await _currencyRepository
          .getExchangeRatesFiltered(
            fromCurrency: fromCurrency.code,
            toCurrency: toCurrencyCode,
            sortAscending: false,
          );

      // Group by Preset and find the one CLOSEST to the selected [date]
      final closestRatesByPreset = <int, ExchangeRateDomain>{};

      // We assume date is never null due to early check, but use check just in case
      final targetDate = date ?? DateTime.now();

      for (final rate in allRates) {
        final currentBest = closestRatesByPreset[rate.preset];
        if (currentBest == null) {
          closestRatesByPreset[rate.preset] = rate;
        } else {
          // Compare distance to targetDate
          final distCurrent = (currentBest.date.difference(targetDate).abs());
          final distNew = (rate.date.difference(targetDate).abs());

          if (distNew < distCurrent) {
            closestRatesByPreset[rate.preset] = rate;
          } else if (distNew == distCurrent) {
            // If distances equal, prefer the later one (arbitrary tie break)
            if (rate.date.isAfter(currentBest.date)) {
              closestRatesByPreset[rate.preset] = rate;
            }
          }
        }
      }

      // Ensure Preset 1 ALWAYS exists in the UI (Virtual/Memory only - do NOT save to DB)
      if (!closestRatesByPreset.containsKey(1)) {
        final virtualRate = ExchangeRateDomain(
          fromCurrencyCode: fromCurrency.code,
          toCurrencyCode: toCurrencyCode,
          rate: 1.0,
          date: targetDate,
          preset: 1,
        );
        closestRatesByPreset[1] = virtualRate;
      }

      List<ExchangeRateDomain> rates = closestRatesByPreset.values.toList();
      // Sort by preset index
      rates.sort((a, b) => a.preset.compareTo(b.preset));

      ExchangeRateDomain? selectedRate = state.selectedExchangeRate;

      // 1. Try to maintain selection
      if (selectedRate != null) {
        selectedRate = rates.firstWhereOrNull(
          (r) => r.preset == selectedRate!.preset,
        );
      }

      if (state.initialTransaction?.exchangeRatePreset != null) {
        selectedRate = rates.firstWhereOrNull(
          (r) => r.preset == state.initialTransaction!.exchangeRatePreset,
        );
      }

      // Default to Preset 1
      selectedRate ??= rates.firstWhereOrNull((r) => r.preset == 1);

      // 3. Fallback to first available if still null
      if (selectedRate == null && rates.isNotEmpty) {
        selectedRate = rates.first;
      }

      emit(
        state.copyWith(
          availableExchangeRates: rates,
          selectedExchangeRate: selectedRate,
          manualExchangeRate:
              selectedRate?.rate.toString() ?? '', // Sync Manual Rate
          isLoadingRates: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoadingRates: false));
    }
  }

  void _onRatePresetChanged(
    AddEditTransactionRatePresetChanged event,
    Emitter<AddEditTransactionState> emit,
  ) {
    emit(
      state.copyWith(
        selectedExchangeRate: event.rate,
        manualExchangeRate:
            event.rate?.rate.toString() ?? state.manualExchangeRate,
      ),
    );
  }

  void _onManualRateChanged(
    AddEditTransactionManualRateChanged event,
    Emitter<AddEditTransactionState> emit,
  ) {
    emit(state.copyWith(manualExchangeRate: event.rate));
  }

  Future<void> _onAddNewRate(
    AddEditTransactionAddNewRate event,
    Emitter<AddEditTransactionState> emit,
  ) async {
    if (!state.isForeignCurrency || state.date == null) return;

    emit(state.copyWith(isLoadingRates: true));
    try {
      // Calc next preset
      final currentPresets = state.availableExchangeRates
          .map((e) => e.preset)
          .toList();
      final maxPreset = currentPresets.isNotEmpty
          ? currentPresets.reduce((curr, next) => curr > next ? curr : next)
          : 0;
      final nextPreset = maxPreset + 1;

      final rateValue = double.tryParse(state.manualExchangeRate);
      if (rateValue == null) {
        emit(state.copyWith(isLoadingRates: false));
        return;
      }

      final newRate = ExchangeRateDomain(
        fromCurrencyCode: state.selectedCurrency!.code,
        toCurrencyCode:
            state.selectedCurrency!.code == state.selectedAccount!.currencyCode
            ? state.mainCurrencyCode
            : state.selectedAccount!.currencyCode,
        rate: rateValue,
        date: state.date!,
        preset: nextPreset,
      );

      await _currencyRepository.addExchangeRate(newRate);

      // Refresh
      await _fetchRates(
        emit,
        state.selectedCurrency,
        state.selectedAccount,
        state.date,
      );

      // Auto-select the new rate (find by preset)
      final createdRate = state.availableExchangeRates.firstWhereOrNull(
        (r) => r.preset == nextPreset,
      );
      emit(state.copyWith(selectedExchangeRate: createdRate));
    } catch (e) {
      emit(state.copyWith(isLoadingRates: false));
    }
  }

  Future<void> _onUpdatePreset(
    AddEditTransactionUpdatePreset event,
    Emitter<AddEditTransactionState> emit,
  ) async {
    if (!state.isForeignCurrency || state.date == null) return;

    final rateValue = double.tryParse(state.manualExchangeRate);
    if (rateValue == null) return;

    emit(state.copyWith(isLoadingRates: true));
    try {
      final updatedRate = event.rate.copyWith(rate: rateValue);
      await _currencyRepository.updateExchangeRate(updatedRate);

      await _fetchRates(
        emit,
        state.selectedCurrency,
        state.selectedAccount,
        state.date,
      );

      // Re-select the updated rate
      emit(state.copyWith(selectedExchangeRate: updatedRate));
    } catch (e) {
      emit(state.copyWith(isLoadingRates: false));
    }
  }
}
