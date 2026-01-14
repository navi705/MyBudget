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
import 'package:my_budget_client/domain/entities/category_type.dart';

part 'add_edit_transaction_event.dart';
part 'add_edit_transaction_state.dart';

class AddEditTransactionBloc
    extends Bloc<AddEditTransactionEvent, AddEditTransactionState> {
  final TransactionRepository _transactionRepository;
  final AccountRepository _accountRepository;
  final CategoryRepository _categoryRepository;
  final CurrencyRepository _currencyRepository;
  final SettingsRepository _settingsRepository; // Added

  AddEditTransactionBloc({
    required TransactionRepository transactionRepository,
    required AccountRepository accountRepository,
    required CategoryRepository categoryRepository,
    required CurrencyRepository currencyRepository,
    required SettingsRepository settingsRepository, // Added
  }) : _transactionRepository = transactionRepository,
       _accountRepository = accountRepository,
       _categoryRepository = categoryRepository,
       _currencyRepository = currencyRepository,
       _settingsRepository = settingsRepository, // Added
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
    on<AddEditTransactionRatePresetChanged>(_onRatePresetChanged); // Added
    on<AddEditTransactionManualRateChanged>(_onManualRateChanged); // Added
    on<AddEditTransactionAddNewRate>(_onAddNewRate); // Added
    on<AddEditTransactionUpdatePreset>(_onUpdatePreset); // Added
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
          selectedCurrency: selectedCurrency, // Added
          date: initialTransaction?.date ?? DateTime.now(),
          manualExchangeRate:
              initialTransaction?.exchangeRate?.toString() ?? '',
          mainCurrencyCode: mainCurrencyCode,
        ),
      );

      // Trigger fetch if foreign currency
      if (state.isForeignCurrency) {
        // We can't easily emit from here with async gap if we just call helper?
        // We can call helper directly.
        await _fetchRates(emit, selectedCurrency, selectedAccount, state.date);
      }
    } catch (_) {
      emit(state.copyWith(status: AddEditTransactionStatus.failure));
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
    emit(state.copyWith(amount: event.amount));
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
      var fee = double.tryParse(state.fee) ?? 0.0; // Added
      final date = state.date;
      final accountId = state.selectedAccount?.id;
      final categoryId = state.selectedCategory?.id;
      final categoryType = state.selectedCategory?.type;

      if (amount == null ||
          accountId == null ||
          categoryId == null ||
          date == null) {
        // Handle validation failure
        emit(state.copyWith(isSaving: false));
        return;
      }

      // Enforce sign based on CategoryType
      if (categoryType == CategoryType.expense) {
        // Should be negative
        if (amount > 0) amount = -amount;
      } else if (categoryType == CategoryType.income) {
        // Should be positive
        if (amount < 0) amount = amount.abs();
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
          fee: fee, // Added
        );
        await _transactionRepository.updateTransaction(updatedTransaction);
      } else {
        final newTransaction = Transaction(
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
          fee: fee, // Added
        );
        await _transactionRepository.addTransaction(newTransaction);
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
      List<ExchangeRateDomain> rates = await _currencyRepository
          .getExchangeRatesFiltered(
            startDate: date,
            endDate: date,
            fromCurrency: fromCurrency.code,
            toCurrency: toCurrencyCode,
          );

      // Fallback: If no rates for the specific date, try fetching the latest available ones
      if (rates.isEmpty) {
        final latestRates = await _currencyRepository.getLatestExchangeRates(
          date,
        );
        rates = latestRates
            .where(
              (r) =>
                  r.fromCurrencyCode == fromCurrency.code &&
                  r.toCurrencyCode == toCurrencyCode,
            )
            .toList();
      }

      ExchangeRateDomain? selectedRate;
      // 1. Try to match initial transaction preset if editing
      if (state.initialTransaction?.exchangeRatePreset != null) {
        selectedRate = rates.firstWhereOrNull(
          (r) => r.preset == state.initialTransaction!.exchangeRatePreset,
        );
      }

      // 2. Default to Preset 1 if found
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
