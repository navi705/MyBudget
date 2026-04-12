import 'dart:async';
import 'package:collection/collection.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:my_budget_client/core/utils/sms_parser.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/sms_preset.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/domain/repositories/sms_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/domain/services/currency_converter_service.dart';
import 'package:uuid/uuid.dart';

part 'sms_event.dart';
part 'sms_state.dart';

class SmsBloc extends Bloc<SmsEvent, SmsState> {
  final SmsRepository _smsRepository;
  final TransactionRepository _transactionRepository;
  final CurrencyRepository _currencyRepository;
  final AccountRepository _accountRepository;
  final CurrencyConverterService _currencyConverterService;
  final SettingsRepository _settingsRepository;
  final SmsParser _parser = SmsParser();
  StreamSubscription? _smsSubscription;

  SmsBloc({
    required SmsRepository smsRepository,
    required TransactionRepository transactionRepository,
    required CurrencyRepository currencyRepository,
    required AccountRepository accountRepository,
    required CurrencyConverterService currencyConverterService,
    required SettingsRepository settingsRepository,
  }) : _smsRepository = smsRepository,
       _transactionRepository = transactionRepository,
       _currencyRepository = currencyRepository,
       _accountRepository = accountRepository,
       _currencyConverterService = currencyConverterService,
       _settingsRepository = settingsRepository,
       super(const SmsState()) {
    on<LoadSmsPresets>(_onLoadPresets);
    on<ToggleSmsPreset>(_onTogglePreset);
    on<SaveSmsPreset>(_onSavePreset);
    on<DeleteSmsPreset>(_onDeletePreset);
    on<ImportSmsMessages>(_onImportMessages);
    on<ImportSmsWithPreset>(_onImportWithPreset);
    on<RequestSmsPermission>(_onRequestPermission);
    on<SmsReceived>(_onSmsReceived); // Register handler

    // Listen for incoming SMS messages
    _smsSubscription = _smsRepository.listenForSms().listen((msg) {
      print('SMS_DEBUG: Bloc received real-time SMS from ${msg.sender}');
      // Direct processing to avoid database race conditions
      add(SmsReceived(msg));
    });

    print('SMS_DEBUG: SmsBloc initialized & listening');
  }

  @override
  Future<void> close() {
    _smsSubscription?.cancel();
    return super.close();
  }

  Future<void> _onSmsReceived(SmsReceived event, Emitter<SmsState> emit) async {
    final msg = event.message;
    print('SMS_DEBUG: Processing received message directly: ${msg.body}');

    final enabledPresets = await _smsRepository.getEnabledPresets();
    if (enabledPresets.isEmpty) {
      print('SMS_DEBUG: No enabled presets found during real-time processing.');
      return;
    }

    final currencies = await _currencyRepository.getCurrencies();

    // OPTIMIZATION: Compute toLowerCase() once before the loop
    final senderLower = msg.sender.toLowerCase();
    
    // Iterate presets to find a match
    for (final preset in enabledPresets) {
      if (senderLower.contains(
        preset.senderFilter.toLowerCase(),
      )) {
        print('SMS_DEBUG: Matched sender filter for preset: ${preset.name}');
        final result = _parser.parse(msg.body, preset, msg.date);

        if (result.isMatch && result.amount != null) {
          print('SMS_DEBUG: Parser matched! Amount: ${result.amount}');
          await _createTransactionFromResult(result, preset, currencies);

          // Update default sync timestamp to avoid re-importing this later
          await _smsRepository.setLastSyncTimestamp(DateTime.now());

          emit(
            state.copyWith(
              lastSyncTimestamp: DateTime.now(),
              createdTransactionsCount: state.createdTransactionsCount + 1,
            ),
          );
          return; // Stop after first match
        } else {
          print('SMS_DEBUG: Parser did NOT match for preset: ${preset.name}');
        }
      }
    }
    print('SMS_DEBUG: No matching preset found for message.');
  }

  Future<void> _onLoadPresets(
    LoadSmsPresets event,
    Emitter<SmsState> emit,
  ) async {
    print('SMS_DEBUG: Bloc _onLoadPresets called');
    emit(state.copyWith(isLoading: true));

    final hasPermission = await _smsRepository.hasSmsPermission();
    final presets = await _smsRepository.getAllPresets();
    print('SMS_DEBUG: Permissions: $hasPermission, Presets: ${presets.length}');

    emit(
      state.copyWith(
        isLoading: false,
        hasPermission: hasPermission,
        presets: presets,
      ),
    );

    // Auto-import logic:
    // Only import if we've synced specific presets before (lastSync exists).
    // This prevents importing ALL history on fresh install.
    if (hasPermission && presets.any((p) => p.isEnabled)) {
      final lastSync = await _smsRepository.getLastSyncTimestamp();
      print('SMS_DEBUG: Last sync: $lastSync');
      if (lastSync != null) {
        print('SMS_DEBUG: Triggering catch-up import since $lastSync');
        add(ImportSmsMessages(since: lastSync));
      } else {
        // First run? Mark 'now' as the sync point so we don't import past messages unless asked.
        print('SMS_DEBUG: No last sync found. Setting sync point to NOW.');
        await _smsRepository.setLastSyncTimestamp(DateTime.now());
      }
    }
  }

  Future<void> _onTogglePreset(
    ToggleSmsPreset event,
    Emitter<SmsState> emit,
  ) async {
    await _smsRepository.togglePreset(event.presetId, event.isEnabled);
    add(LoadSmsPresets());
  }

  Future<void> _onSavePreset(
    SaveSmsPreset event,
    Emitter<SmsState> emit,
  ) async {
    await _smsRepository.savePreset(event.preset);
    add(LoadSmsPresets());
  }

  Future<void> _onDeletePreset(
    DeleteSmsPreset event,
    Emitter<SmsState> emit,
  ) async {
    await _smsRepository.deletePreset(event.presetId);
    add(LoadSmsPresets());
  }

  Future<void> _onImportMessages(
    ImportSmsMessages event,
    Emitter<SmsState> emit,
  ) async {
    emit(state.copyWith(isImporting: true, importProgress: 0));

    final enabledPresets = await _smsRepository.getEnabledPresets();
    if (enabledPresets.isEmpty) {
      emit(
        state.copyWith(isImporting: false, importError: 'No presets enabled'),
      );
      return;
    }

    final int created = await _processImport(
      presets: enabledPresets,
      since: event.since,
      until: event.until,
      emit: emit,
    );

    emit(
      state.copyWith(
        isImporting: false,
        createdTransactionsCount: created,
        lastSyncTimestamp: DateTime.now(),
      ),
    );
  }

  Future<void> _onImportWithPreset(
    ImportSmsWithPreset event,
    Emitter<SmsState> emit,
  ) async {
    emit(state.copyWith(isImporting: true, importProgress: 0));

    final preset = state.presets.firstWhereOrNull(
      (p) => p.id == event.presetId,
    );
    if (preset == null) {
      emit(state.copyWith(isImporting: false, importError: 'Preset not found'));
      return;
    }

    final int created = await _processImport(
      presets: [preset],
      since: event.since,
      until: event.until,
      emit: emit,
    );

    emit(
      state.copyWith(
        isImporting: false,
        createdTransactionsCount: created,
        lastSyncTimestamp: DateTime.now(),
      ),
    );
  }

  Future<int> _processImport({
    required List<SmsPreset> presets,
    required Emitter<SmsState> emit,
    DateTime? since,
    DateTime? until,
  }) async {
    final senderFilters = presets.map((p) => p.senderFilter).toList();
    var messages = await _smsRepository.getSmsMessages(
      since: since,
      senderFilters: senderFilters,
    );

    if (until != null) {
      messages = messages.where((msg) => msg.date.isBefore(until)).toList();
    }

    if (messages.isEmpty) return 0;

    int created = 0;
    final currencies = await _currencyRepository.getCurrencies(); // Fetch once

    for (var i = 0; i < messages.length; i++) {
      final msg = messages[i];
      // OPTIMIZATION: Compute toLowerCase() once before the inner loop
      final senderLower = msg.sender.toLowerCase();
      for (final preset in presets) {
        if (senderLower.contains(
          preset.senderFilter.toLowerCase(),
        )) {
          final result = _parser.parse(msg.body, preset, msg.date);
          if (result.isMatch && result.amount != null) {
            // Immediate creation
            await _createTransactionFromResult(result, preset, currencies);
            created++;
            break;
          }
        }
      }
      emit(state.copyWith(importProgress: (i + 1) / messages.length));
    }

    await _smsRepository.setLastSyncTimestamp(DateTime.now());
    return created;
  }

  Future<void> _createTransactionFromResult(
    SmsParseResult result,
    SmsPreset preset,
    List<Currency> currencies,
  ) async {
    final accountId = preset.defaultAccountId ?? 'default';
    final account = await _accountRepository.getAccountById(accountId);
    final accountCurrency = account?.currencyCode ?? 'RSD';

    // Find currency by code from SMS result
    String? smsCurrencyCode = result.currencyCode;
    if (smsCurrencyCode != null) {
      final found = currencies.any(
        (c) => c.code.toUpperCase() == smsCurrencyCode!.toUpperCase(),
      );
      if (!found) {
        smsCurrencyCode = null; // Use default
      }
    }

    final finalSmsCurrency = smsCurrencyCode ?? accountCurrency;
    final isIncome = result.type == TransactionType.income;
    final rawAmount = isIncome ? result.amount!.abs() : -result.amount!.abs();

    double finalAmount = rawAmount;
    double? finalExchangeRate;
    String finalCurrency = accountCurrency;

    // Trigger conversion if SMS currency differs from Account currency
    if (finalSmsCurrency.toUpperCase() != accountCurrency.toUpperCase()) {
      final mainCurrencySetting = await _settingsRepository.getSetting(
        'main_currency_code',
      );
      final mainCurrencyCode = mainCurrencySetting?.value ?? 'EUR';
      final txDate = result.date ?? DateTime.now();

      final rate = await _currencyConverterService.getExchangeRate(
        fromCurrencyCode: finalSmsCurrency,
        toCurrencyCode: accountCurrency,
        date: txDate,
        mainCurrencyCode: mainCurrencyCode,
      );

      if (rate != null) {
        finalAmount = rawAmount * rate.rate;
        finalExchangeRate = rate.rate;
      }
    }

    print(
      'SMS_DEBUG: Creating transaction for preset ${preset.name}, raw amount: $rawAmount $finalSmsCurrency, converted: $finalAmount $finalCurrency, rate: $finalExchangeRate, date: ${result.date}',
    );

    final transaction = Transaction(
      id: const Uuid().v4(),
      amount: finalAmount,
      currencyCode: finalCurrency,
      date: result.date ?? DateTime.now(),
      description: preset.name,
      categoryId: result.categoryId ?? preset.defaultCategoryId ?? 'other',
      accountId: accountId,
      exchangeRate: finalExchangeRate,
      exchangeRatePreset: finalExchangeRate != null ? 1 : null,
    );

    try {
      await _transactionRepository.addTransaction(transaction);
      print('SMS_DEBUG: Transaction added successfully via repository');
    } catch (e) {
      print('SMS_DEBUG: Transaction addition FAILED: $e');
    }
  }

  Future<void> _onRequestPermission(
    RequestSmsPermission event,
    Emitter<SmsState> emit,
  ) async {
    final granted = await _smsRepository.requestSmsPermission();
    emit(state.copyWith(hasPermission: granted));
    if (granted) {
      add(LoadSmsPresets());
    }
  }
}
