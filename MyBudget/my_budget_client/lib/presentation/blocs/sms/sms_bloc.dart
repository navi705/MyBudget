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
import 'package:uuid/uuid.dart';

part 'sms_event.dart';
part 'sms_state.dart';

class SmsBloc extends Bloc<SmsEvent, SmsState> {
  final SmsRepository _smsRepository;
  final TransactionRepository _transactionRepository;
  final CurrencyRepository _currencyRepository;
  final SmsParser _parser = SmsParser();

  SmsBloc({
    required SmsRepository smsRepository,
    required TransactionRepository transactionRepository,
    required CurrencyRepository currencyRepository,
  }) : _smsRepository = smsRepository,
       _transactionRepository = transactionRepository,
       _currencyRepository = currencyRepository,
       super(const SmsState()) {
    on<LoadSmsPresets>(_onLoadPresets);
    on<ToggleSmsPreset>(_onTogglePreset);
    on<SaveSmsPreset>(_onSavePreset);
    on<DeleteSmsPreset>(_onDeletePreset);
    on<TestSmsRule>(_onTestRule);
    on<ImportSmsMessages>(_onImportMessages);
    on<ImportSmsWithPreset>(_onImportWithPreset);
    on<RequestSmsPermission>(_onRequestPermission);
  }

  Future<void> _onLoadPresets(
    LoadSmsPresets event,
    Emitter<SmsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final hasPermission = await _smsRepository.hasSmsPermission();
    final presets = await _smsRepository.getAllPresets();

    emit(
      state.copyWith(
        isLoading: false,
        hasPermission: hasPermission,
        presets: presets,
      ),
    );
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

  Future<void> _onTestRule(TestSmsRule event, Emitter<SmsState> emit) async {
    final result = _parser.testRule(event.smsBody, event.rule);
    emit(state.copyWith(testResult: result));
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
    final currencies = await _currencyRepository.getCurrencies();

    for (var i = 0; i < messages.length; i++) {
      final msg = messages[i];
      for (final preset in presets) {
        if (msg.sender.toLowerCase().contains(
          preset.senderFilter.toLowerCase(),
        )) {
          final result = _parser.parse(msg.body, preset);
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
    // Find currency by code
    String? currencyCode = result.currencyCode;
    if (currencyCode != null) {
      final found = currencies.any(
        (c) => c.code.toUpperCase() == currencyCode!.toUpperCase(),
      );
      if (!found) {
        currencyCode = null; // Use default
      }
    }

    final isIncome = result.type == TransactionType.income;
    final amount = isIncome ? result.amount!.abs() : -result.amount!.abs();

    final rawDescription = result.rawMessage ?? 'Imported from SMS';
    final description = rawDescription.length > 100
        ? rawDescription.substring(0, 100)
        : rawDescription;

    final transaction = Transaction(
      id: const Uuid().v4(),
      amount: amount,
      currencyCode: currencyCode ?? 'RSD',
      date: result.date ?? DateTime.now(),
      description: description,
      categoryId: preset.defaultCategoryId ?? 'other',
      accountId: preset.defaultAccountId ?? 'default',
    );

    await _transactionRepository.addTransaction(transaction);
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
