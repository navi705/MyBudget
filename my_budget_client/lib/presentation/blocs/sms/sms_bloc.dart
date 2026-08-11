import 'dart:async';
import 'package:collection/collection.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
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

/// Debug-only tracing for the SMS pipeline.
///
/// Everything this bloc handles is the user's bank traffic and it runs
/// unattended on OS message delivery, so a release build must not leave any of
/// it in the device log — that log is readable by tooling the user never chose.
/// Message bodies and amounts are dropped from the text entirely rather than
/// merely gated, because they are the parts actually worth stealing and the
/// gate is one build flag away from being wrong.
void _smsLog(String message) {
  if (kDebugMode) debugPrint('SMS_DEBUG: $message');
}

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
      _smsLog('Bloc received real-time SMS from ${msg.sender}');
      // Direct processing to avoid database race conditions
      add(SmsReceived(msg));
    });

    _smsLog('SmsBloc initialized & listening');
  }

  @override
  Future<void> close() async {
    // Awaited: the listener above calls add(), and adding to a closed bloc
    // throws. Cancelling without awaiting leaves a window where an SMS already
    // in flight lands after super.close() has shut the event controller.
    await _smsSubscription?.cancel();
    return super.close();
  }

  Future<void> _onSmsReceived(SmsReceived event, Emitter<SmsState> emit) async {
    final msg = event.message;
    _smsLog('Processing received message from ${msg.sender}');

    final enabledPresets = await _smsRepository.getEnabledPresets();
    if (enabledPresets.isEmpty) {
      _smsLog('No enabled presets found during real-time processing.');
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
        _smsLog('Matched sender filter for preset: ${preset.name}');
        final result = _parser.parse(msg.body, preset, msg.date);

        if (result.isMatch && result.amount != null) {
          _smsLog('Parser matched for preset: ${preset.name}');
          final created = await _createTransactionFromResult(
            result,
            preset,
            currencies,
          );

          // Update default sync timestamp to avoid re-importing this later
          await _smsRepository.setLastSyncTimestamp(DateTime.now());

          // The user can pop the settings screen at any point during those
          // awaits; emitting into a closed bloc throws.
          if (isClosed) return;
          emit(
            state.copyWith(
              lastSyncTimestamp: DateTime.now(),
              // Only a transaction that actually reached the repository counts.
              createdTransactionsCount: created
                  ? state.createdTransactionsCount + 1
                  : state.createdTransactionsCount,
              failedTransactionsCount: created
                  ? state.failedTransactionsCount
                  : state.failedTransactionsCount + 1,
              importError: created ? null : _importErrorFor(1),
            ),
          );
          return; // Stop after first match
        } else {
          _smsLog('Parser did NOT match for preset: ${preset.name}');
        }
      }
    }
    _smsLog('No matching preset found for message.');
  }

  Future<void> _onLoadPresets(
    LoadSmsPresets event,
    Emitter<SmsState> emit,
  ) async {
    _smsLog('Bloc _onLoadPresets called');
    emit(state.copyWith(isLoading: true));

    final hasPermission = await _smsRepository.hasSmsPermission();
    final presets = await _smsRepository.getAllPresets();
    _smsLog('Permissions: $hasPermission, Presets: ${presets.length}');

    if (isClosed) return;
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
      _smsLog('Last sync: $lastSync');
      if (lastSync != null) {
        _smsLog('Triggering catch-up import since $lastSync');
        if (isClosed) return;
        add(ImportSmsMessages(since: lastSync));
      } else {
        // First run? Mark 'now' as the sync point so we don't import past messages unless asked.
        _smsLog('No last sync found. Setting sync point to NOW.');
        await _smsRepository.setLastSyncTimestamp(DateTime.now());
      }
    }
  }

  Future<void> _onTogglePreset(
    ToggleSmsPreset event,
    Emitter<SmsState> emit,
  ) async {
    await _smsRepository.togglePreset(event.presetId, event.isEnabled);
    if (isClosed) return;
    add(LoadSmsPresets());
  }

  Future<void> _onSavePreset(
    SaveSmsPreset event,
    Emitter<SmsState> emit,
  ) async {
    await _smsRepository.savePreset(event.preset);
    if (isClosed) return;
    add(LoadSmsPresets());
  }

  Future<void> _onDeletePreset(
    DeleteSmsPreset event,
    Emitter<SmsState> emit,
  ) async {
    await _smsRepository.deletePreset(event.presetId);
    if (isClosed) return;
    add(LoadSmsPresets());
  }

  Future<void> _onImportMessages(
    ImportSmsMessages event,
    Emitter<SmsState> emit,
  ) async {
    emit(state.copyWith(isImporting: true, importProgress: 0));

    final enabledPresets = await _smsRepository.getEnabledPresets();
    if (isClosed) return;
    if (enabledPresets.isEmpty) {
      emit(
        state.copyWith(isImporting: false, importError: 'No presets enabled'),
      );
      return;
    }

    final (created, failed) = await _processImport(
      presets: enabledPresets,
      since: event.since,
      until: event.until,
      emit: emit,
    );

    if (isClosed) return;
    emit(
      state.copyWith(
        isImporting: false,
        createdTransactionsCount: created,
        failedTransactionsCount: failed,
        importError: _importErrorFor(failed),
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

    final (created, failed) = await _processImport(
      presets: [preset],
      since: event.since,
      until: event.until,
      emit: emit,
    );

    if (isClosed) return;
    emit(
      state.copyWith(
        isImporting: false,
        createdTransactionsCount: created,
        failedTransactionsCount: failed,
        importError: _importErrorFor(failed),
        lastSyncTimestamp: DateTime.now(),
      ),
    );
  }

  /// Free-form (non-localised) summary, matching the other importError strings
  /// produced here. Returns null when nothing failed so the field clears.
  String? _importErrorFor(int failed) => failed == 0
      ? null
      : '$failed message(s) matched but could not be saved';

  /// Returns how many transactions were actually written and how many matched
  /// a preset but failed to write — the two must be reported separately, or a
  /// failing repository is indistinguishable from a successful import.
  Future<(int created, int failed)> _processImport({
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

    if (messages.isEmpty) return (0, 0);

    int created = 0;
    int failed = 0;
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
            if (await _createTransactionFromResult(result, preset, currencies)) {
              created++;
            } else {
              failed++;
            }
            break;
          }
        }
      }
      // If the screen was popped mid-import we skip the progress emit but keep
      // importing: the sync timestamp below is written either way, so bailing
      // out here would mark the remaining messages as synced without ever
      // having created them.
      if (!isClosed) {
        emit(state.copyWith(importProgress: (i + 1) / messages.length));
      }
    }

    await _smsRepository.setLastSyncTimestamp(DateTime.now());
    return (created, failed);
  }

  /// Returns true only if the transaction reached the repository.
  Future<bool> _createTransactionFromResult(
    SmsParseResult result,
    SmsPreset preset,
    List<Currency> currencies,
  ) async {
    final accountId = preset.defaultAccountId ?? 'default';
    final account = await _accountRepository.getAccountById(accountId);
    final accountCurrency = account?.currencyCode ?? 'RSD';

    // Find currency by code from SMS result. Resolve it to the CANONICAL
    // spelling held in the currency table — the parser upper-cases whatever
    // the SMS happened to contain, and every rate lookup downstream matches on
    // the table's spelling.
    final smsCurrencyCode = result.currencyCode == null
        ? null
        : currencies
              .firstWhereOrNull(
                (c) =>
                    c.code.toUpperCase() == result.currencyCode!.toUpperCase(),
              )
              ?.code; // null => unknown code, fall back to the account's

    final finalSmsCurrency = smsCurrencyCode ?? accountCurrency;
    final isIncome = result.type == TransactionType.income;
    final rawAmount = isIncome ? result.amount!.abs() : -result.amount!.abs();

    double finalAmount = rawAmount;
    double? finalExchangeRate;
    // The label must describe the amount actually being stored, so it starts
    // as the SMS currency and only becomes the account currency once a rate has
    // genuinely been applied below. It used to be pinned to accountCurrency
    // unconditionally: with no rate on file a 100 USD SMS on an RSD account was
    // written as "100 RSD" — silent, unrecoverable corruption on a path (OS SMS
    // delivery) the user never sees happen.
    String finalCurrency = finalSmsCurrency;

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
        finalCurrency = accountCurrency;
      }
      // No rate on file: keep the raw amount under its true currency instead of
      // dropping the transaction. This is what the manual path already does
      // (AddEditTransactionBloc._onSave leaves the foreign code in place when
      // no rate is available), so the record stays truthful and converts
      // correctly the day the missing rate is imported. Discarding it instead
      // would lose a transaction the user has no other copy of — the SMS is
      // processed once and never revisited.
    }

    _smsLog(
      'Creating transaction for preset ${preset.name} in $finalCurrency, '
      'rate: ${finalExchangeRate != null}, date: ${result.date}',
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
      _smsLog('Transaction added successfully via repository');
      return true;
    } catch (e) {
      // Reported, not swallowed: the caller counts this as a failure so the
      // "N transactions created" banner cannot claim writes that never landed.
      _smsLog('Transaction addition FAILED: $e');
      return false;
    }
  }

  Future<void> _onRequestPermission(
    RequestSmsPermission event,
    Emitter<SmsState> emit,
  ) async {
    final granted = await _smsRepository.requestSmsPermission();
    if (isClosed) return;
    emit(state.copyWith(hasPermission: granted));
    if (granted) {
      add(LoadSmsPresets());
    }
  }
}
