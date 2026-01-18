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

    on<AddEditTransactionDeletePreset>(_onDeletePreset); // Added
    on<AddEditTransactionToggleRateDirection>(_onToggleRateDirection); // Added
    on<AddEditTransactionSwapAccounts>(_onSwapAccounts); // Added
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
      var initialTransaction = event.transaction;

      // NEW LOGIC: Check for "Cash Side" of Asset Transaction and SWAP context to Asset Side
      // This ensures we always open the "Asset Edit" UI (Qty/Value) even if clicking the Cash Tx.
      if (initialTransaction != null &&
          initialTransaction.linkedTransactionId != null) {
        try {
          final linkedTx = await _transactionRepository.getTransactionById(
            initialTransaction!.linkedTransactionId!,
          );
          if (linkedTx != null) {
            final linkedAcc = accounts.firstWhereOrNull(
              (a) => a.id == linkedTx.accountId,
            );
            // If the LINKED account is an ASSET account, and CURRENT is CASH
            // We want to edit from the ASSET perspective.
            if (linkedAcc?.assetId != null) {
              final currentAcc = accounts.firstWhereOrNull(
                (a) => a.id == initialTransaction!.accountId,
              );
              if (currentAcc?.assetId == null) {
                // SWAP to Edit Asset Transaction
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
      if (state.isForeignCurrency) {
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
    emit(state.copyWith(isLoadingRates: true));
    try {
      List<ExchangeRateDomain> rates = [];
      ExchangeRateDomain? selectedRate;
      String manualRate = '1.0';

      if (assetCurrency != cashCurrency) {
        final rawRates = await _currencyRepository.getExchangeRatesFiltered(
          fromCurrency: assetCurrency,
          toCurrency: cashCurrency,
          endDate: date ?? DateTime.now(),
          limit:
              100, // Fetch enough to cover recent history of multiple presets
          sortAscending: false,
        );

        // Deduplicate: Keep latest per preset
        final uniqueMap = <int, ExchangeRateDomain>{};
        for (final rate in rawRates) {
          if (!uniqueMap.containsKey(rate.preset)) {
            uniqueMap[rate.preset] = rate;
          }
        }
        rates = uniqueMap.values.toList()
          ..sort((a, b) => a.preset.compareTo(b.preset));

        selectedRate =
            rates.firstWhereOrNull((r) => r.preset == 1) ?? rates.firstOrNull;
        manualRate = selectedRate?.rate.toString() ?? '1.0';
      }

      var newState = state.copyWith(
        availableExchangeRates: rates,
        selectedExchangeRate: selectedRate,
        manualExchangeRate: manualRate,
        isLoadingRates: false,
      );

      // Recalculate Total Value if Quantity exists
      if (state.amount.isNotEmpty && state.assetPrice != null) {
        final qty = double.tryParse(state.amount) ?? 0.0;
        final rate = double.tryParse(manualRate) ?? 1.0;
        final total = qty * state.assetPrice! * rate;
        newState = newState.copyWith(totalValue: total.toStringAsFixed(2));
      }

      emit(newState);
    } catch (e) {
      emit(state.copyWith(isLoadingRates: false));
    }
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
      final rate = double.tryParse(newState.manualExchangeRate) ?? 1.0;
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
    if (state.isTransferMode) {
      // Find the currency object matching the account's currency code
      final accountCurrency = state.currencies.firstWhereOrNull(
        (c) => c.code == event.account.currencyCode,
      );
      newState = newState.copyWith(selectedCurrency: accountCurrency);
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
    } else if (state.isTransferMode && state.selectedCurrency != null) {
      // Standard Transfer: Fetch Rates if Linked Account Changed (Target Currency Changed)
      await _fetchRates(
        emit,
        state.selectedCurrency,
        state.selectedAccount,
        state.date,
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
      final rate = double.tryParse(newState.manualExchangeRate) ?? 1.0;
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
        print(
          'DEBUG SAVE: manualExchangeRate=${state.manualExchangeRate}, isRateInputInverted=${state.isRateInputInverted}, rateValue=$rateValue',
        );

        // Apply inversion if user toggled to inverted direction
        if (rateValue != null && rateValue != 0 && state.isRateInputInverted) {
          rateValue = 1 / rateValue;
          print('DEBUG SAVE: After inversion rateValue=$rateValue');
        }

        finalExchangeRate = rateValue;

        // Keep preset reference if still selected (for tracking)
        if (state.selectedExchangeRate != null) {
          finalPreset = state.selectedExchangeRate!.preset;
        }
      }

      print(
        'DEBUG SAVE: isAssetTransaction=${state.isAssetTransaction}, isTransferMode=${state.isTransferMode}, isEditing=${state.isEditing}',
      );
      print(
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
            accountId: accountId!,
            categoryId: categoryId!,
            currencyCode: finalCurrency,
            exchangeRate: finalExchangeRate,
            exchangeRatePreset: finalPreset,
            fee: fee,
          );
          print('DEBUG SAVE: Saving standard new transaction...');
          await _transactionRepository.addTransaction(newTransaction);
          print('DEBUG SAVE: Standard transaction saved successfully!');
        }
      }

      emit(state.copyWith(isSaving: false, isSaveSuccess: true));
    } catch (e, stackTrace) {
      print('DEBUG SAVE ERROR: $e');
      print('DEBUG SAVE STACKTRACE: $stackTrace');
      emit(
        state.copyWith(isSaving: false, validationError: 'Error saving: $e'),
      );
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

    String targetCurrencyCode;
    // Fix for Transfer Mode: Use linked account currency if available
    if (state.isTransferMode && state.linkedAccount != null) {
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

    emit(state.copyWith(isLoadingRates: true));
    try {
      final targetDate = date ?? DateTime.now();

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
      // Only needed if neither Direct nor Inverse gave us a good rate (or to better match date?)
      // AND if we are not involving the Base currency directly (optimization).
      // If From or To IS Base, we already did Direct/Inverse.
      if (fromCurrency.code != state.mainCurrencyCode &&
          toCurrencyCode != state.mainCurrencyCode) {
        // Fetch Base -> From
        final baseToFrom = await _currencyRepository.getExchangeRatesFiltered(
          fromCurrency: state.mainCurrencyCode,
          toCurrency: fromCurrency.code,
          sortAscending: false,
        );
        // Fetch Base -> To
        final baseToTo = await _currencyRepository.getExchangeRatesFiltered(
          fromCurrency: state.mainCurrencyCode,
          toCurrency: toCurrencyCode,
          sortAscending: false,
        );

        // Find closest match for Base->From
        ExchangeRateDomain? closestBaseToFrom;
        Duration? minDistFrom;
        for (var r in baseToFrom) {
          if (r.preset == 1) {
            final dist = r.date.difference(targetDate).abs();
            if (minDistFrom == null || dist < minDistFrom) {
              minDistFrom = dist;
              closestBaseToFrom = r;
            }
          }
        }

        // Find closest match for Base->To
        ExchangeRateDomain? closestBaseToTo;
        Duration? minDistTo;
        for (var r in baseToTo) {
          if (r.preset == 1) {
            final dist = r.date.difference(targetDate).abs();
            if (minDistTo == null || dist < minDistTo) {
              minDistTo = dist;
              closestBaseToTo = r;
            }
          }
        }

        if (closestBaseToFrom != null && closestBaseToTo != null) {
          // Rate = (Base->To) / (Base->From)
          // valid if closestBaseToFrom.rate != 0
          if (closestBaseToFrom.rate != 0) {
            final calculatedRate =
                closestBaseToTo.rate / closestBaseToFrom.rate;
            // Use date that is "worst" (furthest) or "average"?
            // Let's use the older of the two as the limiting factor?
            // Or just targetDate since it's a derived calculation on demand?
            // Let's use the date of the 'From' rate for reference.
            tryUpdateBest(calculatedRate, closestBaseToFrom.date);
          }
        }
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

      List<ExchangeRateDomain> finalRates = validPresets.values.toList();
      finalRates.sort((a, b) => a.preset.compareTo(b.preset));

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

      // Only set manualExchangeRate on initial load (when it's empty)
      // This prevents overwriting user's typed value on rate refresh
      final newManualRate = state.manualExchangeRate.isEmpty
          ? (selectedRate?.rate.toString() ?? '')
          : state.manualExchangeRate; // Keep current value

      emit(
        state.copyWith(
          availableExchangeRates: finalRates,
          selectedExchangeRate: selectedRate,
          manualExchangeRate: newManualRate,
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
    var newState = state.copyWith(
      selectedExchangeRate: event.rate,
      manualExchangeRate:
          event.rate?.rate.toString() ?? state.manualExchangeRate,
    );

    // Asset Sync: Recalculate Total Value
    if (newState.isAssetTransaction &&
        newState.assetPrice != null &&
        newState.amount.isNotEmpty) {
      final qty = double.tryParse(newState.amount) ?? 0.0;
      final rate = double.tryParse(newState.manualExchangeRate) ?? 1.0;
      final total = qty * newState.assetPrice! * rate;
      newState = newState.copyWith(totalValue: total.toStringAsFixed(2));
    }

    emit(newState);
  }

  void _onManualRateChanged(
    AddEditTransactionManualRateChanged event,
    Emitter<AddEditTransactionState> emit,
  ) {
    // SIMPLIFIED: Store exactly what user types
    // Inversion is applied only at SAVE time based on isRateInputInverted
    var newState = state.copyWith(
      manualExchangeRate: event.rate,
      selectedExchangeRate: null,
    );

    // Asset Sync: Recalculate Total Value
    if (newState.isAssetTransaction &&
        newState.assetPrice != null &&
        newState.amount.isNotEmpty) {
      final qty = double.tryParse(newState.amount) ?? 0.0;
      final rate = double.tryParse(newState.manualExchangeRate) ?? 1.0;
      final total = qty * newState.assetPrice! * rate;
      newState = newState.copyWith(totalValue: total.toStringAsFixed(2));
    }

    emit(newState);
  }

  void _onToggleRateDirection(
    AddEditTransactionToggleRateDirection event,
    Emitter<AddEditTransactionState> emit,
  ) {
    // SIMPLIFIED: Just toggle the flag
    // manualExchangeRate stores user's raw input, interpretation changes based on flag
    final newValue = !state.isRateInputInverted;
    print(
      'DEBUG TOGGLE: isRateInputInverted changing from ${state.isRateInputInverted} to $newValue',
    );
    emit(state.copyWith(isRateInputInverted: newValue));
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

      var rateValue = double.tryParse(state.manualExchangeRate);
      if (rateValue == null) {
        emit(state.copyWith(isLoadingRates: false));
        return;
      }

      // Apply inversion if toggled (same as save logic)
      if (rateValue != 0 && state.isRateInputInverted) {
        rateValue = 1 / rateValue;
        print('DEBUG NEW PRESET: Inverted rate to $rateValue');
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
      if (state.isAssetTransaction) {
        await _fetchAssetToCashRate(
          emit,
          assetCurrency: fromCode,
          cashCurrency: toCode,
          date: state.date,
        );
      } else {
        await _fetchRates(
          emit,
          state.selectedCurrency,
          state.selectedAccount,
          state.date,
        );
      }

      // Auto-select the new rate (find by preset)
      final createdRate = state.availableExchangeRates.firstWhereOrNull(
        (r) => r.preset == nextPreset,
      );
      // Keep direction preference, just select the new rate
      emit(state.copyWith(selectedExchangeRate: createdRate));

      // If Asset, manually trigger calculation update too (normally _fetchAssetToCashRate does it but logic is conditional)
      // Actually _fetchAssetToCashRate updates state.
    } catch (e) {
      emit(state.copyWith(isLoadingRates: false));
    }
  }

  Future<void> _onUpdatePreset(
    AddEditTransactionUpdatePreset event,
    Emitter<AddEditTransactionState> emit,
  ) async {
    if (!state.isForeignCurrency || state.date == null) return;

    var rateValue = double.tryParse(state.manualExchangeRate);
    if (rateValue == null) return;

    // Apply inversion if toggled (same as save logic)
    if (rateValue != 0 && state.isRateInputInverted) {
      rateValue = 1 / rateValue;
    }

    emit(state.copyWith(isLoadingRates: true));
    try {
      print(
        'DEBUG UPDATE PRESET: Updating preset ${event.rate.preset} with rate $rateValue',
      );
      final updatedRate = event.rate.copyWith(rate: rateValue);
      await _currencyRepository.updateExchangeRate(updatedRate);

      await _fetchRates(
        emit,
        state.selectedCurrency,
        state.selectedAccount,
        state.date,
      );

      // Re-select the updated rate, keep direction preference
      emit(state.copyWith(selectedExchangeRate: updatedRate));
    } catch (e) {
      emit(state.copyWith(isLoadingRates: false));
    }
  }

  Future<void> _onDeletePreset(
    AddEditTransactionDeletePreset event,
    Emitter<AddEditTransactionState> emit,
  ) async {
    emit(state.copyWith(isLoadingRates: true));
    try {
      await _currencyRepository.deleteExchangeRates([event.rate]);
      await _fetchRates(
        emit,
        state.selectedCurrency,
        state.selectedAccount,
        state.date,
      );
    } catch (_) {
      emit(state.copyWith(isLoadingRates: false));
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
}
