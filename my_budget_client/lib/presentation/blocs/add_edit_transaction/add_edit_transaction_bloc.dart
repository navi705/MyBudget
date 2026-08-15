import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show debugPrint;
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

  StreamSubscription<List<Account>>? _accountsSubscription;
  StreamSubscription<List<Category>>? _categoriesUpdatedSubscription;

  // OPTIMIZATION: Cache for exchange rates to avoid redundant DB queries.
  // Key: "fromCode_toCode_YYYY-M-D_mainCurrency"
  // Cleared when exchange rates are modified (add/update/delete).
  final Map<String, List<ExchangeRateDomain>> _ratesCache = {};

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
    on<AddEditTransactionSaveRateAsDefault>(_onSaveRateAsDefault);
    on<AddEditTransactionUpdatePreset>(_onUpdatePreset);
    on<AddEditTransactionLinkedAccountChanged>(
      _onLinkedAccountChanged,
    ); // Added
    on<AddEditTransactionAssetActionChanged>(_onAssetActionChanged); // Added
    on<AddEditTransactionTotalValueChanged>(_onTotalValueChanged); // Added

    on<AddEditTransactionDeletePreset>(_onDeletePreset); // Added
    on<AddEditTransactionToggleRateDirection>(_onToggleRateDirection); // Added
    on<AddEditTransactionSwapAccounts>(_onSwapAccounts); // Added

    on<_AddEditTransactionAccountsUpdated>(_onAccountsUpdated);
    on<_AddEditTransactionCategoriesUpdated>(_onCategoriesUpdated);
  }

  Future<void> _onLoad(
    AddEditTransactionLoad event,
    Emitter<AddEditTransactionState> emit,
  ) async {
    emit(state.copyWith(status: AddEditTransactionStatus.loading));

    try {
      // 1. Setup Reactive Listeners
      // Awaited: an unawaited cancel lets the old subscription keep
      // delivering into the new one's callback race window, and either
      // stray delivery can call add() after the bloc has moved on.
      await _accountsSubscription?.cancel();
      _accountsSubscription = _accountRepository.watchAccounts().listen((
        accounts,
      ) {
        add(_AddEditTransactionAccountsUpdated(accounts));
      });

      await _categoriesUpdatedSubscription?.cancel();
      _categoriesUpdatedSubscription = _categoryRepository
          .watchCategories()
          .listen((categories) {
            add(_AddEditTransactionCategoriesUpdated(categories));
          });

      // 2. Initial Fetch (still needed for logic that depends on full data set available at start)
      final accounts = await _accountRepository.getAccounts();
      final categories = await _categoryRepository.getCategories();
      final currencies = await _currencyRepository.getCurrencies();
      final mainCurrencySetting = await _settingsRepository.getSetting(
        'main_currency_code',
      );
      final mainCurrencyCode = mainCurrencySetting?.value ?? 'EUR';
      var initialTransaction = event.transaction;

      // NEW LOGIC: Check for "Cash Side" of Asset Transaction and SWAP context to Asset Side
      // This ensures we always open the "Asset Edit" UI (Qty/Value) even if clicking the Cash Tx.
      // Also: For standard transfers, always load from the "From" (negative amount) perspective,
      // so that selectedAccount = From account and linkedAccount = To account, regardless of
      // which transaction the user tapped on. This fixes the Android From/To display issue.
      if (initialTransaction != null &&
          initialTransaction.linkedTransactionId != null) {
        try {
          final linkedTx = await _transactionRepository.getTransactionById(
            initialTransaction.linkedTransactionId!,
          );
          if (linkedTx != null) {
            final linkedAcc = accounts.firstWhereOrNull(
              (a) => a.id == linkedTx.accountId,
            );
            final currentAcc = accounts.firstWhereOrNull(
              (a) => a.id == initialTransaction!.accountId,
            );
            // If the LINKED account is an ASSET account, and CURRENT is CASH
            // We want to edit from the ASSET perspective.
            if (linkedAcc?.assetId != null && currentAcc?.assetId == null) {
              // SWAP to Edit Asset Transaction
              initialTransaction = linkedTx;
            } else if (linkedAcc?.assetId == null &&
                currentAcc?.assetId == null) {
              // Standard Transfer: Always load from "From" (negative amount) perspective.
              // If the current transaction is the "To" side (positive amount),
              // swap to the linked transaction (the "From" side with negative amount).
              // This ensures From/To accounts are always displayed correctly on all platforms.
              if (initialTransaction.amount > 0 && linkedTx.amount < 0) {
                // Current is "To" side (positive), swap to "From" side (negative)
                initialTransaction = linkedTx;
              }
            }
          }
        } catch (_) {
          // ignore
        }
      }

      Account? selectedAccount;
      Account?
      initialLinkedAccount; // For Transfer Mode: the account user selected

      if (initialTransaction != null) {
        selectedAccount = accounts.firstWhereOrNull(
          (a) => a.id == initialTransaction!.accountId,
        );
      } else if (event.accountId != null) {
        // NEW LOGIC: If in Transfer Mode, set this as "To Account" (destination)
        if (event.isTransfer) {
          initialLinkedAccount = accounts.firstWhereOrNull(
            (a) => a.id == event.accountId,
          );
          // selectedAccount should be a DIFFERENT account
          selectedAccount = accounts.firstWhereOrNull(
            (a) => a.id != event.accountId,
          );
        } else {
          selectedAccount = accounts.firstWhereOrNull(
            (a) => a.id == event.accountId,
          );
        }
      }

      if (selectedAccount == null && accounts.isNotEmpty) {
        selectedAccount = accounts.first;
      }

      final selectedCategory = initialTransaction != null
          ? categories.firstWhereOrNull(
              (c) => c.id == initialTransaction!.categoryId,
            )
          : (categories.isNotEmpty ? categories.first : null);

      Currency? selectedCurrency;
      if (initialTransaction != null) {
        selectedCurrency = currencies.firstWhereOrNull(
          (c) => c.code == initialTransaction!.currencyCode,
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
          isTransferMode:
              event.isTransfer &&
              selectedAccount?.assetId == null, // Set transfer mode
          selectedCurrency: selectedCurrency, // Added
          date: initialTransaction?.date ?? DateTime.now(),
          manualExchangeRate:
              initialTransaction?.exchangeRate?.toString() ?? '',
          mainCurrencyCode: mainCurrencyCode,
        ),
      );

      // Trigger fetch if foreign currency
      if (selectedCurrency?.code != mainCurrencyCode) {
        await _fetchRates(emit, selectedCurrency, selectedAccount, state.date);
      }

      // Check if existing transaction is a Linked Transaction (Transfer or Asset)
      // This handles restoring Linked Account, Total Value (for Assets), and Exchange Rate (for Transfers)
      bool isLinkedEdit = false;
      Account? linkedAccount;
      String? restoredTotalValue;
      String? restoredExchangeRate;

      if (initialTransaction != null &&
          initialTransaction.linkedTransactionId != null) {
        try {
          final linkedTx = await _transactionRepository.getTransactionById(
            initialTransaction.linkedTransactionId!,
          );

          if (linkedTx != null) {
            isLinkedEdit = true;
            linkedAccount = accounts.firstWhereOrNull(
              (a) => a.id == linkedTx.accountId,
            );

            // Determine if Asset or Standard Transfer
            final isAsset = selectedAccount?.assetId != null;

            if (isAsset) {
              // Asset Transaction: Restore Total Value (Cash Amount)
              // Linked Tx Amount is the cash value.
              restoredTotalValue = linkedTx.amount.abs().toString();
            } else {
              // Standard Transfer: Restore Exchange Rate
              // We infer the effective rate used: LinkedAmount / MainAmount
              if (initialTransaction.amount != 0) {
                final rate =
                    linkedTx.amount.abs() / initialTransaction.amount.abs();
                // We set manual rate if it deviates from 1:1 or implies conversion
                // This ensures we preserve the historical "Effective Rate"
                restoredExchangeRate = rate.toString();
              }
            }
          }
        } catch (_) {
          // Ignore if linked tx not found
        }
      }

      if (isLinkedEdit) {
        // If it was identified as a linked edit (Transfer category or Asset), set the mode
        // For Assets, isAssetTransaction getter takes precedence, but we set linkedAccount here.
        emit(
          state.copyWith(
            isTransferMode: selectedAccount?.assetId == null,
            linkedAccount: linkedAccount,
            totalValue: restoredTotalValue ?? state.totalValue,
            // If we calculated a restored rate, use it. Otherwise keep existing (from initialTx or default)
            manualExchangeRate:
                restoredExchangeRate ?? state.manualExchangeRate,
          ),
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

        // Auto-select linked account
        // Priority: initialLinkedAccount (from event.accountId for transfer), else find 'other'
        if (state.linkedAccount == null && accounts.isNotEmpty) {
          Account? linkedToEmit = initialLinkedAccount;

          // Fallback if initialLinkedAccount is null (e.g., no accountId passed)
          if (linkedToEmit == null && selectedAccount != null) {
            linkedToEmit = accounts.firstWhereOrNull(
              (a) => a.id != selectedAccount!.id,
            );
          }

          // Safety: don't allow same account
          if (linkedToEmit?.id == selectedAccount?.id) {
            linkedToEmit = null;
          }

          emit(state.copyWith(linkedAccount: linkedToEmit));
        }
      }

      // Final check: If we are now in a foreign currency state (e.g. Transfer determined), fetch rates
      // This is needed because _fetchRates earlier might have been skipped if linkedAccount was null
      if (state.isForeignCurrency) {
        await _fetchRates(
          emit,
          state.selectedCurrency,
          state.selectedAccount,
          state.date,
        );
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

        // Also update selected currency to match asset currency
        final assetCurrency = state.currencies.firstWhereOrNull(
          (c) => c.code == asset.currency,
        );
        if (assetCurrency != null) {
          newState = newState.copyWith(selectedCurrency: assetCurrency);
        }

        emit(newState); // Emit first with price/linked/currency

        // Fetch Rate Asset -> Cash
        if (linked != null) {
          await _fetchRates(
            emit,
            newState.selectedCurrency,
            account,
            state.date,
            forceSync: true,
          );
        }
      }
    } catch (e) {
      // ignore
    }
  }

  double _getEffectiveRate(AddEditTransactionState state) {
    if (state.manualExchangeRate.isNotEmpty) {
      final val = double.tryParse(state.manualExchangeRate) ?? 1.0;
      if (state.isRateInputInverted && val != 0) {
        return 1.0 / val;
      }
      return val;
    }
    return state.selectedExchangeRate?.rate ?? 1.0;
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
      final rate = _getEffectiveRate(newState);
      final total = qty * newState.assetPrice! * rate;
      newState = newState.copyWith(totalValue: total.toStringAsFixed(2));
    }

    emit(newState);
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
    var newState = state.copyWith(selectedAccount: event.account);

    // FIX: If in Transfer Mode, the 'Currency' field must be locked to the 'From Account'
    // So if the account changes, we MUST update the selectedCurrency to match.
    if (newState.isTransferMode) {
      final accCurrency = state.currencies.firstWhereOrNull(
        (c) => c.code == event.account.currencyCode,
      );
      if (accCurrency != null) {
        newState = newState.copyWith(selectedCurrency: accCurrency);
      }
    }

    // FIX: Clear Linked Account if it becomes invalid (same as Selected)
    // This happens if user switches From Account to the same account as current To Account
    if (event.account.id == newState.linkedAccount?.id) {
      newState = newState.copyWith(clearLinkedAccount: true);
    }

    emit(newState);

    if (event.account.assetId != null) {
      await _fetchAssetDetails(emit, event.account);
    }

    // Refresh after potential changes in _fetchAssetDetails
    final currentState = state;
    if (currentState.selectedCurrency != null && currentState.date != null) {
      await _fetchRates(
        emit,
        currentState.selectedCurrency,
        currentState.selectedAccount,
        currentState.date,
        forceSync: true,
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
    if (state.selectedAccount?.assetId != null) {
      await _fetchRates(
        emit,
        state.selectedCurrency,
        state.selectedAccount,
        state.date,
        forceSync: true,
      );
    } else if (state.isTransferMode && state.selectedCurrency != null) {
      // Standard Transfer: Fetch Rates if Linked Account Changed (Target Currency Changed)
      await _fetchRates(
        emit,
        state.selectedCurrency,
        state.selectedAccount,
        state.date,
        forceSync: true,
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
      final rate = _getEffectiveRate(newState);
      // Qty = Total / (Price * Rate)
      if (rate > 0) {
        final qty = total / (newState.assetPrice! * rate);
        newState = newState.copyWith(amount: qty.toStringAsFixed(6));
      }
    }

    emit(newState);
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
    emit(state.copyWith(isSaving: true, clearValidationError: true));

    try {
      var amount = double.tryParse(state.amount);
      var fee = double.tryParse(state.fee) ?? 0.0;
      final date = state.date;
      final accountId = state.selectedAccount?.id;
      // For Asset transactions, category is resolved later
      var categoryId = state.selectedCategory?.id;
      final categoryType = state.selectedCategory?.type;

      // Basic Validation with error messages
      if (amount == null || state.amount.isEmpty) {
        emit(
          state.copyWith(
            isSaving: false,
            validationError: 'Please enter an amount',
          ),
        );
        return;
      }
      if (accountId == null) {
        emit(
          state.copyWith(
            isSaving: false,
            validationError: 'Please select an account',
          ),
        );
        return;
      }
      if (date == null) {
        emit(
          state.copyWith(
            isSaving: false,
            validationError: 'Please select a date',
          ),
        );
        return;
      }

      // Category Validation (Asset transactions auto-resolve, others need selection)
      if (!state.isAssetTransaction &&
          !state.isTransferMode &&
          categoryId == null) {
        emit(
          state.copyWith(
            isSaving: false,
            validationError: 'Please select a category',
          ),
        );
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
        // Always use manualExchangeRate (which is synced from presets when selected)
        var rateValue = double.tryParse(state.manualExchangeRate);

        // DEBUG: Print inversion state
        debugPrint(
          'DEBUG SAVE: manualExchangeRate=${state.manualExchangeRate}, isRateInputInverted=${state.isRateInputInverted}, rateValue=$rateValue',
        );

        // Apply inversion if user toggled to inverted direction
        if (rateValue != null && rateValue != 0 && state.isRateInputInverted) {
          rateValue = 1 / rateValue;
          debugPrint('DEBUG SAVE: After inversion rateValue=$rateValue');
        }

        finalExchangeRate = rateValue;

        // Keep preset reference if still selected (for tracking)
        if (state.selectedExchangeRate != null) {
          finalPreset = state.selectedExchangeRate!.preset;
        }
      }

      debugPrint(
        'DEBUG SAVE: isAssetTransaction=${state.isAssetTransaction}, isTransferMode=${state.isTransferMode}, isEditing=${state.isEditing}',
      );
      debugPrint(
        'DEBUG SAVE: amount=$amount, categoryId=$categoryId, finalExchangeRate=$finalExchangeRate',
      );

      if (state.isAssetTransaction) {
        // --- ASSET TRANSACTION LOGIC ---
        final qty = amount; // amount is Quantity and non-null here
        final totalValue = double.tryParse(state.totalValue) ?? 0.0;
        final isEdit = state.isEditing;

        // IDs
        final assetTxId = isEdit
            ? state.initialTransaction!.id!
            : const Uuid().v4();
        final cashTxId = isEdit
            ? (state.initialTransaction!.linkedTransactionId ??
                  const Uuid().v4())
            : const Uuid().v4();

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
        // Direct assignment from totalValue (which user can edit)
        final adjustedTotalValue = totalValue;

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

        if (isEdit) {
          await _transactionRepository.updateTransaction(assetTx);
          await _transactionRepository.updateTransaction(cashTx);
        } else {
          await _transactionRepository.addTransaction(assetTx);
          await _transactionRepository.addTransaction(cashTx);
        }
      } else if (state.isTransferMode) {
        // --- TRANSFER LOGIC ---
        // 1. From Account (Expense)
        // 2. To Account (Income)

        if (state.linkedAccount == null) {
          emit(state.copyWith(isSaving: false));
          return;
        }

        final isEdit = state.isEditing;
        final txId1 = isEdit
            ? state.initialTransaction!.id!
            : const Uuid().v4();
        final txId2 = isEdit
            ? (state.initialTransaction!.linkedTransactionId ??
                  const Uuid().v4())
            : const Uuid().v4();

        // From: Expense
        final tx1 = Transaction(
          id: txId1,
          description: state.description.isEmpty
              ? 'Transfer to ${state.linkedAccount!.name}'
              : state.description,
          amount: -(amount.abs()),
          date: date,
          accountId: accountId,
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

        if (isEdit) {
          await _transactionRepository.updateTransaction(tx1);
          await _transactionRepository.updateTransaction(tx2);
        } else {
          await _transactionRepository.addTransaction(tx1);
          await _transactionRepository.addTransaction(tx2);
        }
      } else {
        // --- STANDARD LOGIC ---
        // Determine Final Amount and Currency
        // If foreign currency, we MUST convert to Account Currency for valid Balance calculation
        // (Assuming Account Ledger is single-currency based)
        double finalAmount = amount;
        String finalCurrency =
            state.selectedCurrency?.code ?? state.selectedAccount!.currencyCode;

        if (state.isForeignCurrency &&
            finalExchangeRate != null &&
            finalCurrency != state.selectedAccount!.currencyCode) {
          finalAmount = amount * finalExchangeRate;
          finalCurrency = state.selectedAccount!.currencyCode;
        }

        if (state.isEditing) {
          final updatedTransaction = state.initialTransaction!.copyWith(
            description: state.description,
            amount: finalAmount,
            date: date,
            accountId: accountId,
            categoryId: categoryId,
            currencyCode: finalCurrency,
            exchangeRate: finalExchangeRate,
            exchangeRatePreset: finalPreset,
            fee: fee,
          );
          await _transactionRepository.updateTransaction(updatedTransaction);
        } else {
          // Use default description if empty (database requires at least 1 char)
          final finalDescription = state.description.isEmpty
              ? '-'
              : state.description;

          final newTransaction = Transaction(
            description: finalDescription,
            amount: finalAmount,
            date: date,
            accountId: accountId,
            categoryId: categoryId!,
            currencyCode: finalCurrency,
            exchangeRate: finalExchangeRate,
            exchangeRatePreset: finalPreset,
            fee: fee,
          );
          debugPrint('DEBUG SAVE: Saving standard new transaction...');
          await _transactionRepository.addTransaction(newTransaction);
          debugPrint('DEBUG SAVE: Standard transaction saved successfully!');
        }
      }

      emit(state.copyWith(isSaving: false, isSaveSuccess: true));
    } catch (e, stackTrace) {
      debugPrint('DEBUG SAVE ERROR: $e');
      debugPrint('DEBUG SAVE STACKTRACE: $stackTrace');
      // The exception alone: the screen puts a localized "Error: {…}" around
      // anything it does not recognise, and an English prefix here would only
      // be shown twice over.
      emit(state.copyWith(isSaving: false, validationError: '$e'));
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
        forceSync: true,
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
    DateTime? date, {
    bool forceSync = false,
  }) async {
    if (fromCurrency == null || toAccount == null || date == null) return;

    String targetCurrencyCode;
    // Fix for Transfer/Asset Mode: Use linked account currency if available
    if ((state.isTransferMode || state.isAssetTransaction) &&
        state.linkedAccount != null) {
      targetCurrencyCode = state.linkedAccount!.currencyCode;
    } else {
      targetCurrencyCode = fromCurrency.code == toAccount.currencyCode
          ? state.mainCurrencyCode
          : toAccount.currencyCode;
    }

    // Optimization: If Target == Source, we don't need rates (Rate=1)
    if (fromCurrency.code == targetCurrencyCode) {
      emit(state.copyWith(availableExchangeRates: []));
      return;
    }

    final toCurrencyCode = targetCurrencyCode;
    final normalizedDate = DateTime(date.year, date.month, date.day);

    emit(state.copyWith(isLoadingRates: true));
    debugPrint(
      'DEBUG RATES: Fetching for ${fromCurrency.code} -> $targetCurrencyCode at $normalizedDate',
    );

    // OPTIMIZATION: Cache key for this rate lookup.
    // Includes from/to currencies, date, and main currency (used for triangular).
    // Cache is cleared when exchange rates are modified (add/update/delete).
    final cacheKey =
        '${fromCurrency.code}_${toCurrencyCode}_${normalizedDate.year}-${normalizedDate.month}-${normalizedDate.day}_${state.mainCurrencyCode}';

    try {
      final targetDate = normalizedDate;

      // Declare finalRates here so it's accessible in both cache-hit and cache-miss branches
      List<ExchangeRateDomain> finalRates;

      if (_ratesCache.containsKey(cacheKey)) {
        // Cache hit: reuse previously computed rates, skip all DB queries
        finalRates = _ratesCache[cacheKey]!;
      } else {
        // Cache miss: perform DB queries to find the best rate

        // --- STRATEGY: Find Best "System" Rate (Virtual Preset 1) ---
        // We look for:
        // 1. Direct Rate (From -> To)
        // 2. Inverse Rate (To -> From) => 1/Rate
        // 3. Triangular (Base -> From, Base -> To) => Rate(Base->To) / Rate(Base->From)

        ExchangeRateDomain? derivedPreset1;
        double? bestDerivedRateValue;
        DateTime? bestDerivedDate;

        // Helper to update best derived rate if this one is "closer" to target date
        void tryUpdateBest(double rate, DateTime rateDate) {
          if (bestDerivedDate == null) {
            bestDerivedRateValue = rate;
            bestDerivedDate = rateDate;
          } else {
            final distCurrent = bestDerivedDate!.difference(targetDate).abs();
            final distNew = rateDate.difference(targetDate).abs();
            if (distNew < distCurrent) {
              bestDerivedRateValue = rate;
              bestDerivedDate = rateDate;
            }
          }
        }

        // 1. Direct Fetch
        final directRates = await _currencyRepository.getExchangeRatesFiltered(
          fromCurrency: fromCurrency.code,
          toCurrency: toCurrencyCode,
          sortAscending: false,
        );
        // Look for Preset 1 specifically or any rate?
        // User wants "Preset 1" to be this smart logic.
        // We'll scan ALL history for this pair to find closest date.
        for (var r in directRates) {
          // We prioritize Preset 1 records if they exist, but generally any record works for history?
          // Actually, user said "Preset 1 goes by this logic".
          // Let's assume we use ANY preset's history to find the market rate?
          // Or strictly Preset 1?
          // "I want simply to write value EUR->RSD... in Preset 1 I have logic... others as usual."
          // So Preset 1 is the "Market/Derived" preset.
          if (r.preset == 1) {
            tryUpdateBest(r.rate, r.date);
          }
        }

        // 2. Inverse Fetch (To -> From)
        final inverseRates = await _currencyRepository.getExchangeRatesFiltered(
          fromCurrency: toCurrencyCode,
          toCurrency: fromCurrency.code,
          sortAscending: false,
        );
        for (var r in inverseRates) {
          if (r.preset == 1) {
            if (r.rate != 0) {
              tryUpdateBest(1.0 / r.rate, r.date);
            }
          }
        }

        // 3. Triangular Fetch (Base -> From, Base -> To)
        // Helper to attempt triangular calculation via a pivot currency
        Future<void> attemptTriangular(String pivotCode) async {
          // If pivot is one of the currencies, it's just a direct rate (already checked)
          if (fromCurrency.code == pivotCode || toCurrencyCode == pivotCode) {
            return;
          }

          // -- Leg 1: Pivot <-> From --
          double? ratePivotToFrom;
          DateTime? datePivotToFrom;
          int? presetPivotToFrom;

          void updateLeg1(double r, DateTime d, int p) {
            if (datePivotToFrom == null) {
              ratePivotToFrom = r;
              datePivotToFrom = d;
              presetPivotToFrom = p;
            } else {
              // Prioritize Preset 1
              final isCurrentP1 = presetPivotToFrom == 1;
              final isNewP1 = p == 1;

              if (isNewP1 && !isCurrentP1) {
                ratePivotToFrom = r;
                datePivotToFrom = d;
                presetPivotToFrom = p;
              } else if (isNewP1 == isCurrentP1) {
                final distCurrent = datePivotToFrom!
                    .difference(targetDate)
                    .abs();
                final distNew = d.difference(targetDate).abs();
                if (distNew < distCurrent) {
                  ratePivotToFrom = r;
                  datePivotToFrom = d;
                  presetPivotToFrom = p;
                }
              }
            }
          }

          // Fetch Pivot -> From
          final directLeg1 = await _currencyRepository.getExchangeRatesFiltered(
            fromCurrency: pivotCode,
            toCurrency: fromCurrency.code,
            sortAscending: false,
            limit: 1000,
          );
          for (var r in directLeg1) updateLeg1(r.rate, r.date, r.preset);

          // Fetch From -> Pivot
          final inverseLeg1 = await _currencyRepository
              .getExchangeRatesFiltered(
                fromCurrency: fromCurrency.code,
                toCurrency: pivotCode,
                sortAscending: false,
                limit: 1000,
              );
          for (var r in inverseLeg1) {
            if (r.rate != 0) updateLeg1(1.0 / r.rate, r.date, r.preset);
          }

          // -- Leg 2: Pivot <-> To --
          double? ratePivotToTo;
          DateTime? datePivotToTo;
          int? presetPivotToTo;

          void updateLeg2(double r, DateTime d, int p) {
            if (datePivotToTo == null) {
              ratePivotToTo = r;
              datePivotToTo = d;
              presetPivotToTo = p;
            } else {
              final isCurrentP1 = presetPivotToTo == 1;
              final isNewP1 = p == 1;

              if (isNewP1 && !isCurrentP1) {
                ratePivotToTo = r;
                datePivotToTo = d;
                presetPivotToTo = p;
              } else if (isNewP1 == isCurrentP1) {
                final distCurrent = datePivotToTo!.difference(targetDate).abs();
                final distNew = d.difference(targetDate).abs();
                if (distNew < distCurrent) {
                  ratePivotToTo = r;
                  datePivotToTo = d;
                  presetPivotToTo = p;
                }
              }
            }
          }

          // Fetch Pivot -> To
          final directLeg2 = await _currencyRepository.getExchangeRatesFiltered(
            fromCurrency: pivotCode,
            toCurrency: toCurrencyCode,
            sortAscending: false,
            limit: 1000,
          );
          for (var r in directLeg2) updateLeg2(r.rate, r.date, r.preset);

          // Fetch To -> Pivot
          final inverseLeg2 = await _currencyRepository
              .getExchangeRatesFiltered(
                fromCurrency: toCurrencyCode,
                toCurrency: pivotCode,
                sortAscending: false,
                limit: 1000,
              );
          for (var r in inverseLeg2) {
            if (r.rate != 0) updateLeg2(1.0 / r.rate, r.date, r.preset);
          }

          // Calculate
          if (ratePivotToFrom != null && ratePivotToTo != null) {
            // Rate = (Pivot->To) / (Pivot->From)
            if (ratePivotToFrom != 0) {
              final calculatedRate = ratePivotToTo! / ratePivotToFrom!;
              final representativeDate =
                  datePivotToFrom!.isBefore(datePivotToTo!)
                  ? datePivotToFrom!
                  : datePivotToTo!;
              tryUpdateBest(calculatedRate, representativeDate);
            }
          }
        }

        // 1. Try Main Currency Payload
        await attemptTriangular(state.mainCurrencyCode);

        // 2. Try EUR (if not already tried)
        if (bestDerivedRateValue == null && state.mainCurrencyCode != 'EUR') {
          await attemptTriangular('EUR');
        }

        // 3. Try USD (if not already tried)
        // 3. Try USD (if not already tried)
        if (bestDerivedRateValue == null &&
            state.mainCurrencyCode != 'USD' &&
            state.mainCurrencyCode != 'EUR') {
          await attemptTriangular('USD');
        }

        // Create the Virtual Preset 1 if we have a derived value
        if (bestDerivedRateValue != null) {
          derivedPreset1 = ExchangeRateDomain(
            fromCurrencyCode: fromCurrency.code,
            toCurrencyCode: toCurrencyCode,
            rate: bestDerivedRateValue!,
            date: bestDerivedDate!,
            preset: 1,
          );
        } else {
          // Fallback if absolutely no history found: Default to 1.0 (or leave null?)
          // User hated "Default 1.0", so leave null if not found.
        }

        // --- END SMART LOGIC ---

        // Now prepare list for UI.
        // We include the "Direct" rates from DB for other Presets (2, 3, etc.)
        // AND our Virtual/Derived Preset 1.

        final Map<int, ExchangeRateDomain> validPresets = {};

        // Add Direct rates (only custom presets or if we want to show raw DB preset 1?)
        // User said: "Preset 1 goes by this logic". So we overwrite DB Preset 1 with Smart Preset 1.
        for (var r in directRates) {
          if (r.preset != 1) {
            final current = validPresets[r.preset];
            if (current == null) {
              validPresets[r.preset] = r;
            } else {
              // Closeness check
              final distCurrent = current.date.difference(targetDate).abs();
              final distNew = r.date.difference(targetDate).abs();
              if (distNew < distCurrent) {
                validPresets[r.preset] = r;
              }
            }
          }
        }

        if (derivedPreset1 != null) {
          validPresets[1] = derivedPreset1;
        }

        finalRates = validPresets.values.toList();
        finalRates.sort((a, b) => a.preset.compareTo(b.preset));

        // Store in cache for future calls with the same parameters
        _ratesCache[cacheKey] = finalRates;
      } // end cache miss branch

      ExchangeRateDomain? selectedRate = state.selectedExchangeRate;

      // Maintain selection or default to Preset 1
      if (selectedRate != null) {
        // Try to find matching preset
        selectedRate = finalRates.firstWhereOrNull(
          (r) => r.preset == selectedRate!.preset,
        );
      }

      // Default to Preset 1
      selectedRate ??= finalRates.firstWhereOrNull((r) => r.preset == 1);

      // Fallback
      if (selectedRate == null && finalRates.isNotEmpty) {
        selectedRate = finalRates.first;
      }

      bool shouldUpdateManualRate =
          state.manualExchangeRate.isEmpty || forceSync;

      // If we found a Preset 1 (derived or real), and it's the selected one,
      // we should probably sync manualRate if it's currently different.
      if (!shouldUpdateManualRate &&
          selectedRate?.preset == 1 &&
          state.manualExchangeRate.isNotEmpty) {
        final currentManual = double.tryParse(state.manualExchangeRate) ?? 0.0;
        double effectiveRate = selectedRate!.rate;
        if (state.isRateInputInverted && effectiveRate != 0) {
          effectiveRate = 1 / effectiveRate;
        }

        if ((currentManual - effectiveRate).abs() > 0.000001) {
          shouldUpdateManualRate = true;
        }
      }

      var newManualRateStr = state.manualExchangeRate;
      if (shouldUpdateManualRate && selectedRate != null) {
        double rateToDisplay = selectedRate.rate;
        if (state.isRateInputInverted && rateToDisplay != 0) {
          rateToDisplay = 1 / rateToDisplay;
        }
        newManualRateStr = rateToDisplay.toString();
      }

      var finalState = state.copyWith(
        availableExchangeRates: finalRates,
        selectedExchangeRate: selectedRate,
        // copyWith treats a null selectedExchangeRate/editingExchangeRate as
        // "no change", not "clear it" - without these flags a currency pair
        // with zero derivable rates (no direct, reversed, or triangular rate)
        // would leave both fields pointing at the PREVIOUS pair's rate. The
        // preset chips (built from availableExchangeRates, which correctly
        // went empty) would then vanish while the Update/Delete buttons
        // (gated on editingExchangeRate) stayed on screen, silently wired to
        // a different currency pair's stored rate.
        clearSelectedExchangeRate: selectedRate == null,
        // A refresh always resolves a fresh answer to "what preset is this",
        // so the Update/Delete target is re-synced here too, the same way
        // selectedExchangeRate just was above - it only diverges from
        // selectedExchangeRate while the user is mid-typing, and typing never
        // calls _fetchRates.
        editingExchangeRate: selectedRate,
        clearEditingExchangeRate: selectedRate == null,
        manualExchangeRate: newManualRateStr,
        isLoadingRates: false,
      );

      // If Asset Transaction, recalculate totalValue based on new rate
      // Use correct absolute rate for calculation
      if (finalState.isAssetTransaction && finalState.assetPrice != null) {
        final qty = double.tryParse(finalState.amount) ?? 0.0;
        final absRate = _getEffectiveRate(finalState);
        final total = qty * finalState.assetPrice! * absRate;
        finalState = finalState.copyWith(totalValue: total.toStringAsFixed(2));
      }

      emit(finalState);
    } catch (e) {
      // A failed refresh used to leave the previous rate list on screen with
      // the spinner gone, so a rate that could not be read looked like a rate
      // that had not changed - and the transaction was converted at the stale
      // one.
      _emitRateFailure(emit, e);
    }
  }

  void _onRatePresetChanged(
    AddEditTransactionRatePresetChanged event,
    Emitter<AddEditTransactionState> emit,
  ) {
    double? displayRate = event.rate?.rate;
    if (displayRate != null && state.isRateInputInverted && displayRate != 0) {
      displayRate = 1.0 / displayRate;
    }

    var newState = state.copyWith(
      selectedExchangeRate: event.rate,
      // The event's rate is nullable, and a null one means "no preset": without
      // this the deselection would be dropped exactly as the manual-rate one
      // was. No caller passes null today; this keeps the event honest.
      clearSelectedExchangeRate: event.rate == null,
      // Tapping a chip is what the Update/Delete buttons should act on next,
      // same as selectedExchangeRate above.
      editingExchangeRate: event.rate,
      clearEditingExchangeRate: event.rate == null,
      manualExchangeRate: displayRate?.toString() ?? state.manualExchangeRate,
    );

    // Asset Sync: Recalculate Total Value
    if (newState.isAssetTransaction &&
        newState.assetPrice != null &&
        newState.amount.isNotEmpty) {
      final qty = double.tryParse(newState.amount) ?? 0.0;
      final rate = _getEffectiveRate(newState);
      final total = qty * newState.assetPrice! * rate;
      newState = newState.copyWith(totalValue: total.toStringAsFixed(2));
    }

    emit(newState);
  }

  void _onManualRateChanged(
    AddEditTransactionManualRateChanged event,
    Emitter<AddEditTransactionState> emit,
  ) {
    // Typing a rate by hand is what the conversion will use, so the preset
    // chip must stop claiming otherwise. Passing `selectedExchangeRate: null`
    // used to be swallowed by copyWith's `??`, leaving a chip highlighted that
    // named a rate the transaction was no longer converted at - and the saved
    // row still carried that preset number (see _onSubmitted).
    //
    // editingExchangeRate is deliberately left untouched: it is what the
    // Update/Delete buttons target, and overwriting a preset's rate by typing
    // over it is the entire point of pressing Update next. Clearing it here
    // the way selectedExchangeRate is cleared would hide the Update button
    // the instant its target field is edited.
    var newState = state.copyWith(
      manualExchangeRate: event.rate,
      clearSelectedExchangeRate: true,
    );

    // Asset Sync: Recalculate Total Value
    if (newState.isAssetTransaction &&
        newState.assetPrice != null &&
        newState.amount.isNotEmpty) {
      final qty = double.tryParse(newState.amount) ?? 0.0;
      final rate = _getEffectiveRate(newState);
      final total = qty * newState.assetPrice! * rate;
      newState = newState.copyWith(totalValue: total.toStringAsFixed(2));
    }

    emit(newState);
  }

  void _onToggleRateDirection(
    AddEditTransactionToggleRateDirection event,
    Emitter<AddEditTransactionState> emit,
  ) {
    final newValue = !state.isRateInputInverted;

    // Invert the manual rate string so the numerical value matches the new direction
    var newManualRateStr = state.manualExchangeRate;
    if (state.manualExchangeRate.isNotEmpty) {
      final manualRate = double.tryParse(state.manualExchangeRate) ?? 0.0;
      if (manualRate != 0) {
        newManualRateStr = (1.0 / manualRate).toString();
      }
    }

    var newState = state.copyWith(
      isRateInputInverted: newValue,
      manualExchangeRate: newManualRateStr,
    );

    // Asset Sync: Recalculate Total Value if necessary
    if (newState.isAssetTransaction &&
        newState.assetPrice != null &&
        newState.amount.isNotEmpty) {
      final qty = double.tryParse(newState.amount) ?? 0.0;
      final rate = _getEffectiveRate(newState);
      final total = qty * newState.assetPrice! * rate;
      newState = newState.copyWith(totalValue: total.toStringAsFixed(2));
    }

    emit(newState);
  }

  /// Reports a rate operation that did not happen.
  ///
  /// The four rate handlers below used to catch into a bare
  /// `isLoadingRates: false`: the spinner stopped and nothing else changed, so
  /// a failed "save as default" looked exactly like a successful one and the
  /// next transaction converted at the rate the user thought they had
  /// replaced.
  ///
  /// The message is the raw exception; the screen wraps whatever it does not
  /// recognise in a localized frame.
  void _emitRateFailure(Emitter<AddEditTransactionState> emit, Object error) {
    emit(state.copyWith(isLoadingRates: false, validationError: '$error'));
  }

  /// The rate the user typed cannot be read as a number.
  ///
  /// Sentinel string, matched by name in the screen's lookup - the bloc has no
  /// localizations of its own, and the existing validation messages here work
  /// the same way.
  static const _invalidRateMessage = 'Please enter a valid number';

  Future<void> _onSaveRateAsDefault(
    AddEditTransactionSaveRateAsDefault event,
    Emitter<AddEditTransactionState> emit,
  ) async {
    if (!state.isForeignCurrency || state.date == null) return;

    // Clearing first is what lets the same failure be reported twice: the
    // screen shows a message once per occurrence, and two identical strings in
    // a row are indistinguishable without a null in between.
    emit(state.copyWith(isLoadingRates: true, clearValidationError: true));
    try {
      var rateValue = _getEffectiveRate(state);
      if (rateValue == 0) {
        emit(
          state.copyWith(
            isLoadingRates: false,
            validationError: _invalidRateMessage,
          ),
        );
        return;
      }

      String fromCode = state.selectedCurrency!.code;
      String toCode;

      if (state.isAssetTransaction) {
        fromCode = state.selectedAccount?.currencyCode ?? fromCode;
        toCode = state.linkedAccount?.currencyCode ?? state.mainCurrencyCode;
      } else if (state.isTransferMode) {
        fromCode = state.selectedAccount?.currencyCode ?? fromCode;
        toCode = state.linkedAccount?.currencyCode ?? state.mainCurrencyCode;
      } else {
        toCode =
            state.selectedCurrency!.code == state.selectedAccount!.currencyCode
            ? state.mainCurrencyCode
            : state.selectedAccount!.currencyCode;
      }

      final normalizedDate = DateTime(
        state.date!.year,
        state.date!.month,
        state.date!.day,
      );
      final newRate = ExchangeRateDomain(
        fromCurrencyCode: fromCode,
        toCurrencyCode: toCode,
        rate: rateValue,
        date: normalizedDate,
        preset: 1, // Explicitly Preset 1
      );

      debugPrint(
        'DEBUG DEFAULT: Saving rate $rateValue for $fromCode -> $toCode as Preset 1',
      );
      await _currencyRepository.addExchangeRate(newRate);
      debugPrint('DEBUG DEFAULT: Save successful. Refreshing...');

      // Refresh rates with LATEST state
      // Invalidate cache since exchange rates were modified
      _ratesCache.clear();
      await _fetchRates(
        emit,
        state.selectedCurrency,
        state.selectedAccount,
        state.date,
        forceSync: true,
      );
      debugPrint('DEBUG DEFAULT: Refresh complete.');
    } catch (e, stack) {
      debugPrint('DEBUG DEFAULT ERROR: $e\n$stack');
      _emitRateFailure(emit, e);
    }
  }

  Future<void> _onAddNewRate(
    AddEditTransactionAddNewRate event,
    Emitter<AddEditTransactionState> emit,
  ) async {
    if (!state.isForeignCurrency || state.date == null) return;

    emit(state.copyWith(isLoadingRates: true, clearValidationError: true));
    try {
      // Calc next preset
      final currentPresets = state.availableExchangeRates
          .map((e) => e.preset)
          .toList();
      final maxPreset = currentPresets.isNotEmpty
          ? currentPresets.reduce((curr, next) => curr > next ? curr : next)
          : 0;
      final nextPreset = maxPreset + 1;

      var rateValue = double.tryParse(state.manualExchangeRate);
      if (rateValue == null) {
        emit(
          state.copyWith(
            isLoadingRates: false,
            validationError: _invalidRateMessage,
          ),
        );
        return;
      }

      // Apply inversion if toggled (same as save logic)
      if (rateValue != 0 && state.isRateInputInverted) {
        rateValue = 1 / rateValue;
        debugPrint('DEBUG NEW PRESET: Inverted rate to $rateValue');
      }

      String fromCode = state.selectedCurrency!.code;
      String toCode;

      if (state.isAssetTransaction) {
        fromCode = state.selectedAccount?.currencyCode ?? fromCode;
        toCode = state.linkedAccount?.currencyCode ?? state.mainCurrencyCode;
      } else if (state.isTransferMode) {
        // Transfer Mode: From Account -> To Account (Linked)
        // Usually selectedCurrency matches From Account, but just in case.
        fromCode = state.selectedAccount?.currencyCode ?? fromCode;
        toCode = state.linkedAccount?.currencyCode ?? state.mainCurrencyCode;
      } else {
        // Standard Mode
        toCode =
            state.selectedCurrency!.code == state.selectedAccount!.currencyCode
            ? state.mainCurrencyCode
            : state.selectedAccount!.currencyCode;
      }

      final newRate = ExchangeRateDomain(
        fromCurrencyCode: fromCode,
        toCurrencyCode: toCode,
        rate: rateValue,
        date: state.date!,
        preset: nextPreset,
      );

      await _currencyRepository.addExchangeRate(newRate);

      // Refresh
      // Invalidate cache since exchange rates were modified
      _ratesCache.clear();
      await _fetchRates(
        emit,
        state.selectedCurrency,
        state.selectedAccount,
        state.date,
        forceSync: true,
      );

      // Auto-select the new rate (find by preset)
      final createdRate = state.availableExchangeRates.firstWhereOrNull(
        (r) => r.preset == nextPreset,
      );
      // Keep direction preference, just select the new rate
      emit(
        state.copyWith(
          selectedExchangeRate: createdRate,
          editingExchangeRate: createdRate,
        ),
      );

      // If Asset, manually trigger calculation update too (normally _fetchAssetToCashRate does it but logic is conditional)
      // Actually _fetchAssetToCashRate updates state.
    } catch (e) {
      _emitRateFailure(emit, e);
    }
  }

  Future<void> _onUpdatePreset(
    AddEditTransactionUpdatePreset event,
    Emitter<AddEditTransactionState> emit,
  ) async {
    if (!state.isForeignCurrency || state.date == null) return;

    var rateValue = double.tryParse(state.manualExchangeRate);
    if (rateValue == null) {
      emit(state.copyWith(validationError: _invalidRateMessage));
      return;
    }

    // Apply inversion if toggled (same as save logic)
    if (rateValue != 0 && state.isRateInputInverted) {
      rateValue = 1 / rateValue;
    }

    emit(state.copyWith(isLoadingRates: true, clearValidationError: true));
    try {
      debugPrint(
        'DEBUG UPDATE PRESET: Updating preset ${event.rate.preset} with rate $rateValue',
      );
      final updatedRate = event.rate.copyWith(rate: rateValue);
      await _currencyRepository.updateExchangeRate(updatedRate);

      // Invalidate cache since exchange rates were modified
      _ratesCache.clear();
      await _fetchRates(
        emit,
        state.selectedCurrency,
        state.selectedAccount,
        state.date,
      );

      // Re-select the updated rate, keep direction preference
      emit(
        state.copyWith(
          selectedExchangeRate: updatedRate,
          editingExchangeRate: updatedRate,
        ),
      );
    } catch (e) {
      _emitRateFailure(emit, e);
    }
  }

  Future<void> _onDeletePreset(
    AddEditTransactionDeletePreset event,
    Emitter<AddEditTransactionState> emit,
  ) async {
    emit(state.copyWith(isLoadingRates: true, clearValidationError: true));
    try {
      await _currencyRepository.deleteExchangeRates([event.rate]);
      // Invalidate cache since exchange rates were modified
      _ratesCache.clear();
      await _fetchRates(
        emit,
        state.selectedCurrency,
        state.selectedAccount,
        state.date,
      );
    } catch (e) {
      _emitRateFailure(emit, e);
    }
  }

  Future<void> _onSwapAccounts(
    AddEditTransactionSwapAccounts event,
    Emitter<AddEditTransactionState> emit,
  ) async {
    if (!state.isTransferMode ||
        state.selectedAccount == null ||
        state.linkedAccount == null) {
      return;
    }

    final oldFrom = state.selectedAccount!;
    final oldTo = state.linkedAccount!;

    // Swap Logic
    final newFrom = oldTo;
    final newTo = oldFrom;

    // Currency must follow the NEW From Account
    final newCurrency = state.currencies.firstWhereOrNull(
      (c) => c.code == newFrom.currencyCode,
    );

    emit(
      state.copyWith(
        selectedAccount: newFrom,
        linkedAccount:
            newTo, // This works now because we are just swapping valid accounts
        selectedCurrency: newCurrency,
      ),
    );

    // Refresh Rates for the new pair
    if (newCurrency != null && state.date != null) {
      await _fetchRates(emit, newCurrency, newFrom, state.date);
    }
  }

  // Sentinels, not user-facing text: `validationError` carries an English
  // string that add_edit_transaction_screen.dart maps to a localized message.
  // Anything missing from that lookup table is shown through
  // `l10n.importErrorLabel(...)` as a raw error, so these two constants must
  // stay in step with the entries there.
  static const _selectedAccountDeletedMessage =
      'The account you selected has been deleted';
  static const _linkedAccountDeletedMessage =
      'The linked account you selected has been deleted';

  Future<void> _onAccountsUpdated(
    _AddEditTransactionAccountsUpdated event,
    Emitter<AddEditTransactionState> emit,
  ) async {
    final currentSelectedAccount = state.selectedAccount;
    Account? updatedSelectedAccount = currentSelectedAccount;

    if (currentSelectedAccount != null) {
      updatedSelectedAccount = event.accounts.firstWhereOrNull(
        (a) => a.id == currentSelectedAccount.id,
      );
    }

    // Similarly for linkedAccount
    final currentLinkedAccount = state.linkedAccount;
    Account? updatedLinkedAccount = currentLinkedAccount;
    if (currentLinkedAccount != null) {
      updatedLinkedAccount = event.accounts.firstWhereOrNull(
        (a) => a.id == currentLinkedAccount.id,
      );
    }

    // "There WAS a selection and it is no longer in the pushed list" - the
    // account was deleted, typically on another device and pulled in by sync
    // while this form sat open. That is a different thing from "there was
    // never a selection", which must leave the field exactly as it is.
    //
    // The clear flags are not optional tidiness. copyWith reads a null
    // argument as "no change", so without them the deleted account stays
    // selected and the save writes to a row every list, total and net-worth
    // query filters out - deleting an account soft-deletes its transactions
    // too, so the user has already said "remove this and everything on it":
    //
    // - linkedAccount, transfers: the outgoing leg lands correctly on the From
    //   account and the balance drops by 500 EUR, while the incoming leg goes
    //   to the deleted row. Net worth falls by 500 EUR and no account gained
    //   anything. An asset buy inverts it: 0.5 BTC arrives, the deleted cash
    //   account "pays", and net worth jumps by 30,000 EUR out of nothing.
    // - selectedAccount: a 240 EUR expense appears in the transactions list
    //   and in every category report (those queries filter deleted
    //   transactions, not deleted accounts) while the balance adjustment lands
    //   on the hidden row. The monthly spending total is 240 EUR larger than
    //   the sum of what the accounts actually lost, and the offending row has
    //   no account name to search by.
    final selectedAccountDeleted =
        currentSelectedAccount != null && updatedSelectedAccount == null;
    final linkedAccountDeleted =
        currentLinkedAccount != null && updatedLinkedAccount == null;

    // Clearing silently is its own trap. Save would eventually complain with
    // "Please select an account", but never says why the choice vanished -
    // and for an asset account, clearing selectedAccount also turns
    // `isAssetTransaction` false, which swaps the Buy/Sell toggle and the
    // Quantity + Total Value pair for the ordinary
    // Description/Amount/Category/Currency layout, leaving a number typed as
    // "0.5 BTC" sitting in a field labelled "Amount". The transaction's own
    // account and the transfer/asset linked account get distinct messages
    // because they fail differently; when both go at once the transaction's
    // own account is the one to name first, since the form cannot be saved
    // without it at all.
    final String? deletionMessage = selectedAccountDeleted
        ? _selectedAccountDeletedMessage
        : (linkedAccountDeleted ? _linkedAccountDeletedMessage : null);

    emit(
      state.copyWith(
        accounts: event.accounts,
        selectedAccount: updatedSelectedAccount,
        clearSelectedAccount: selectedAccountDeleted,
        linkedAccount: updatedLinkedAccount,
        clearLinkedAccount: linkedAccountDeleted,
        validationError: deletionMessage,
      ),
    );

    // If selected account changed its properties (like assetId), refetch price
    if (updatedSelectedAccount != null &&
        updatedSelectedAccount != currentSelectedAccount &&
        state.isAssetTransaction) {
      await _fetchAssetDetails(emit, updatedSelectedAccount);
    }
  }

  Future<void> _onCategoriesUpdated(
    _AddEditTransactionCategoriesUpdated event,
    Emitter<AddEditTransactionState> emit,
  ) async {
    final currentSelectedCategory = state.selectedCategory;
    Category? updatedSelectedCategory = currentSelectedCategory;

    if (currentSelectedCategory != null) {
      updatedSelectedCategory = event.categories.firstWhereOrNull(
        (c) => c.id == currentSelectedCategory.id,
      );
    }

    emit(
      state.copyWith(
        categories: event.categories,
        selectedCategory: updatedSelectedCategory,
      ),
    );
  }

  @override
  Future<void> close() async {
    // Awaited: leaving these unawaited lets the subscriptions outlive the
    // bloc, so late-arriving data calls add() after the event controller is
    // closed and throws "Bad state: Cannot add new events after calling
    // close".
    await _accountsSubscription?.cancel();
    await _categoriesUpdatedSubscription?.cancel();
    return super.close();
  }
}
