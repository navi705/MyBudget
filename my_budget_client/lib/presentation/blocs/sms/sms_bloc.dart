import 'dart:async';
import 'package:collection/collection.dart';
import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:my_budget_client/core/utils/sms_parser.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/sms_preset.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/domain/repositories/sms_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/domain/services/currency_converter_service.dart';

import '../bloc_lifecycle.dart';

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

/// What became of one message that a preset matched.
///
/// [duplicate] is deliberately not [failed]: re-running an import is the normal
/// way to use this screen ("All time" re-reads the entire inbox), and reporting
/// those rows as failures would train the user to ignore a counter that is also
/// how a genuinely broken write announces itself.
enum _SmsWriteOutcome { created, duplicate, failed }

/// Whether [error] is SQLite refusing a row because its primary key is already
/// taken.
///
/// Matched on the message rather than on an exception type: the type is
/// `SqliteException` on a device and something else behind drift's web and
/// remote executors, and this runs on whatever the app was built for.
bool _isDuplicateIdConflict(Object error) {
  final text = error.toString();
  return text.contains('UNIQUE constraint failed: transactions.id') ||
      text.contains('PRIMARY KEY must be unique');
}

/// FNV-1a, one 32-bit lane. The seed is the lane's offset basis; four lanes
/// over different seeds give the 128 bits [_transactionIdForSms] needs.
///
/// Both bytes of each code unit are folded in separately so a body that differs
/// only in its non-ASCII characters - Serbian bank messages are full of them -
/// still changes the hash.
int _fnv1a32(String input, int seed) {
  const prime = 0x01000193;
  var hash = seed;
  for (var i = 0; i < input.length; i++) {
    final unit = input.codeUnitAt(i);
    hash = ((hash ^ (unit & 0xFF)) * prime) & 0xFFFFFFFF;
    hash = ((hash ^ ((unit >> 8) & 0xFF)) * prime) & 0xFFFFFFFF;
  }
  return hash;
}

/// The id under which [msg] is written, the same one on every run.
///
/// The import is re-runnable by design, so a fresh uuid per row meant the
/// second run wrote a second copy of every transaction AND moved the account
/// balance again (addTransaction adjusts the balance in the same unit of work).
/// Deriving the id from the message instead makes the write idempotent without
/// a schema change: the primary key itself is what refuses the duplicate.
///
/// The device's own message id is the strongest material available and it is
/// what the OS uses to identify the row; where the platform gives us none, the
/// sender, the exact delivery timestamp and the full body together identify a
/// message about as well as anything can - two of those colliding means the
/// same bank sent the same text in the same millisecond.
///
/// Hashed rather than used raw so the id stays a fixed, sane length whatever
/// the body was, and so a bank message body never ends up sitting in a primary
/// key. A hand-rolled FNV-1a rather than sha1 from package:crypto: this is not
/// a security boundary - the worst a collision does is drop one transaction
/// into the review queue's blind spot - and it is the only hash in the app, so
/// it does not earn a dependency.
String _transactionIdForSms(SmsMessage msg) {
  final material =
      msg.id ?? '${msg.sender}|${msg.date.millisecondsSinceEpoch}|${msg.body}';
  // Distinct offset bases: the same string through the same function four
  // times would give four identical lanes and 32 bits of id.
  const seeds = [0x811C9DC5, 0x01000193, 0x9E3779B9, 0x85EBCA6B];
  final lanes = seeds
      .map((seed) => _fnv1a32(material, seed).toRadixString(16).padLeft(8, '0'))
      .join();
  return 'sms_$lanes';
}

class SmsBloc extends Bloc<SmsEvent, SmsState>
    with BlocShutdownGuard<SmsEvent, SmsState> {
  final SmsRepository _smsRepository;
  final TransactionRepository _transactionRepository;
  final CurrencyRepository _currencyRepository;
  final AccountRepository _accountRepository;
  final CategoryRepository _categoryRepository;
  final CurrencyConverterService _currencyConverterService;
  final SettingsRepository _settingsRepository;
  final SmsParser _parser = SmsParser();
  StreamSubscription? _smsSubscription;

  SmsBloc({
    required SmsRepository smsRepository,
    required TransactionRepository transactionRepository,
    required CurrencyRepository currencyRepository,
    required AccountRepository accountRepository,
    required CategoryRepository categoryRepository,
    required CurrencyConverterService currencyConverterService,
    required SettingsRepository settingsRepository,
  }) : _smsRepository = smsRepository,
       _transactionRepository = transactionRepository,
       _currencyRepository = currencyRepository,
       _accountRepository = accountRepository,
       _categoryRepository = categoryRepository,
       _currencyConverterService = currencyConverterService,
       _settingsRepository = settingsRepository,
       super(const SmsState()) {
    on<LoadSmsPresets>(_onLoadPresets);
    on<ToggleSmsPreset>(_onTogglePreset);
    on<SaveSmsPreset>(_onSavePreset);
    on<DeleteSmsPreset>(_onDeletePreset);
    // Droppable, not the default concurrent transformer: LoadSmsPresets is
    // dispatched on app start, on opening Settings and after every preset
    // toggle/save/delete, and each dispatch reads the sync watermark and fires
    // its own catch-up import. Run concurrently, two of them read the same
    // `since` and walk the same window at once. Dropping the second is right
    // rather than merely cheap - it covers exactly the same messages as the
    // one already running, so there is nothing to queue it for.
    on<ImportSmsMessages>(_onImportMessages, transformer: droppable());
    on<ImportSmsWithPreset>(_onImportWithPreset, transformer: droppable());
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
    markClosing();
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
      if (senderLower.contains(preset.senderFilter.toLowerCase())) {
        _smsLog('Matched sender filter for preset: ${preset.name}');
        final result = _parser.parse(msg.body, preset, msg.date);

        if (result.isMatch && result.amount != null) {
          _smsLog('Parser matched for preset: ${preset.name}');
          final outcome = await _createTransactionFromResult(
            msg,
            result,
            preset,
            currencies,
          );

          // Update default sync timestamp to avoid re-importing this later
          await _smsRepository.setLastSyncTimestamp(DateTime.now());

          // The user can pop the settings screen at any point during those
          // awaits; isClosed alone isn't enough (see bloc_lifecycle.dart) so
          // the shutdown guard covers the window close() leaves open too.
          if (isShuttingDown) return;
          final failed = outcome == _SmsWriteOutcome.failed;
          emit(
            state.copyWith(
              lastSyncTimestamp: DateTime.now(),
              // Only a transaction that actually reached the repository counts.
              createdTransactionsCount: outcome == _SmsWriteOutcome.created
                  ? state.createdTransactionsCount + 1
                  : state.createdTransactionsCount,
              duplicateTransactionsCount: outcome == _SmsWriteOutcome.duplicate
                  ? state.duplicateTransactionsCount + 1
                  : state.duplicateTransactionsCount,
              failedTransactionsCount: failed
                  ? state.failedTransactionsCount + 1
                  : state.failedTransactionsCount,
              importError: failed ? _importErrorFor(1) : null,
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

    if (isShuttingDown) return;
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
        if (isShuttingDown) return;
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
    if (isShuttingDown) return;
    add(LoadSmsPresets());
  }

  Future<void> _onSavePreset(
    SaveSmsPreset event,
    Emitter<SmsState> emit,
  ) async {
    await _smsRepository.savePreset(event.preset);
    if (isShuttingDown) return;
    add(LoadSmsPresets());
  }

  Future<void> _onDeletePreset(
    DeleteSmsPreset event,
    Emitter<SmsState> emit,
  ) async {
    await _smsRepository.deletePreset(event.presetId);
    if (isShuttingDown) return;
    add(LoadSmsPresets());
  }

  Future<void> _onImportMessages(
    ImportSmsMessages event,
    Emitter<SmsState> emit,
  ) async {
    emit(state.copyWith(isImporting: true, importProgress: 0));

    final enabledPresets = await _smsRepository.getEnabledPresets();
    if (isShuttingDown) return;
    if (enabledPresets.isEmpty) {
      emit(
        state.copyWith(isImporting: false, importError: 'No presets enabled'),
      );
      return;
    }

    final (created, duplicate, failed) = await _processImport(
      presets: enabledPresets,
      since: event.since,
      until: event.until,
      emit: emit,
    );

    if (isShuttingDown) return;
    emit(
      state.copyWith(
        isImporting: false,
        createdTransactionsCount: created,
        duplicateTransactionsCount: duplicate,
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

    final (created, duplicate, failed) = await _processImport(
      presets: [preset],
      since: event.since,
      until: event.until,
      emit: emit,
    );

    if (isShuttingDown) return;
    emit(
      state.copyWith(
        isImporting: false,
        createdTransactionsCount: created,
        duplicateTransactionsCount: duplicate,
        failedTransactionsCount: failed,
        importError: _importErrorFor(failed),
        lastSyncTimestamp: DateTime.now(),
      ),
    );
  }

  /// Free-form (non-localised) summary, matching the other importError strings
  /// produced here. Returns null when nothing failed so the field clears.
  String? _importErrorFor(int failed) =>
      failed == 0 ? null : '$failed message(s) matched but could not be saved';

  /// Returns how many transactions were actually written, how many were already
  /// on file from an earlier run, and how many matched a preset but failed to
  /// write — the three must be reported separately, or a failing repository is
  /// indistinguishable from a successful import, and a re-import of a window
  /// already covered is indistinguishable from an import that found nothing.
  Future<(int created, int duplicate, int failed)> _processImport({
    required List<SmsPreset> presets,
    required Emitter<SmsState> emit,
    DateTime? since,
    DateTime? until,
  }) async {
    // Captured before the read, not after the loop: a message delivered while
    // the loop is running must fall on the next run's side of the watermark
    // rather than be skipped by it.
    final importStartedAt = DateTime.now();

    final senderFilters = presets.map((p) => p.senderFilter).toList();
    var messages = await _smsRepository.getSmsMessages(
      since: since,
      senderFilters: senderFilters,
    );

    if (until != null) {
      messages = messages.where((msg) => msg.date.isBefore(until)).toList();
    }

    // Advanced BEFORE the loop rather than after it. Every LoadSmsPresets -
    // app start, opening Settings, each preset toggle - reads this watermark
    // and dispatches its own catch-up import from it, so leaving it stale for
    // the length of the loop left a window in which a second import read the
    // same `since` and walked the same messages. The droppable transformer on
    // the event closes the concurrent case; this closes the case where the
    // first import has already finished and a second is dispatched from a
    // watermark that was never written because the run threw halfway.
    // Writing it early can no longer lose messages the way it once could:
    // ids are derived from the message now, so re-importing a window is a
    // no-op rather than a second copy of everything in it.
    await _smsRepository.setLastSyncTimestamp(importStartedAt);

    if (messages.isEmpty) return (0, 0, 0);

    int created = 0;
    int duplicate = 0;
    int failed = 0;
    final currencies = await _currencyRepository.getCurrencies(); // Fetch once

    for (var i = 0; i < messages.length; i++) {
      final msg = messages[i];
      // OPTIMIZATION: Compute toLowerCase() once before the inner loop
      final senderLower = msg.sender.toLowerCase();
      for (final preset in presets) {
        if (senderLower.contains(preset.senderFilter.toLowerCase())) {
          final result = _parser.parse(msg.body, preset, msg.date);
          if (result.isMatch && result.amount != null) {
            // Immediate creation
            switch (await _createTransactionFromResult(
              msg,
              result,
              preset,
              currencies,
            )) {
              case _SmsWriteOutcome.created:
                created++;
              case _SmsWriteOutcome.duplicate:
                duplicate++;
              case _SmsWriteOutcome.failed:
                failed++;
            }
            break;
          }
        }
      }
      // If the screen was popped mid-import we skip the progress emit but keep
      // importing: the sync timestamp above is written either way, so bailing
      // out here would mark the remaining messages as synced without ever
      // having created them.
      if (!isShuttingDown) {
        emit(state.copyWith(importProgress: (i + 1) / messages.length));
      }
    }

    return (created, duplicate, failed);
  }

  /// Writes the transaction [result] describes, and says which of the three
  /// things happened to it — see [_SmsWriteOutcome].
  Future<_SmsWriteOutcome> _createTransactionFromResult(
    SmsMessage message,
    SmsParseResult result,
    SmsPreset preset,
    List<Currency> currencies,
  ) async {
    final transactionId = _transactionIdForSms(message);

    // Asked before any of the work below, not just before the insert: an
    // "All time" import re-reads the whole inbox, so on a mature install most
    // messages land here having already been imported, and each one would
    // otherwise pay for a category lookup, an account lookup and possibly an
    // exchange-rate lookup only to be refused by the primary key at the end.
    //
    // The key itself remains the actual guarantee - this check is a read, and
    // two writers could both pass it - but the handlers that write are now
    // serialised (droppable imports, and the real-time path runs one event at
    // a time), so the race it cannot cover is not one this bloc can reach.
    final existing = await _transactionRepository.getTransactionById(
      transactionId,
    );
    if (existing != null) {
      _smsLog('Message already imported; skipping');
      return _SmsWriteOutcome.duplicate;
    }

    final isIncome = result.type == TransactionType.income;

    // One reading for the whole write: the conversion, the duplicate check and
    // the stored row all have to be talking about the same instant.
    final txDate = result.date ?? DateTime.now();

    // Category BEFORE the account: which wallet a payment came from is
    // predicted from its category (see _resolveAccount), so resolving the
    // account first would throw away the only signal there is.
    final (categoryId, uncertainCategory) = await _resolveCategory(
      result,
      preset,
      isIncome: isIncome,
    );

    final account = await _resolveAccount(preset, categoryId);
    if (account?.id == null) {
      // Nothing to write this against. Previously the code invented the id
      // 'default' here, which no seed creates: the foreign key refused the row
      // and the failure looked like a broken parser rather than an install
      // with no usable account.
      _smsLog(
        'No account could be resolved for preset ${preset.name}; '
        'transaction not written',
      );
      return _SmsWriteOutcome.failed;
    }
    final accountId = account!.id!;
    // Taken from the account that was actually resolved. The old hard-coded
    // 'RSD' fallback could only ever be right by accident, and being wrong
    // here mislabels an amount rather than failing loudly.
    final accountCurrency = account.currencyCode;

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
      id: transactionId,
      amount: finalAmount,
      currencyCode: finalCurrency,
      date: txDate,
      // The merchant when the rule could read one. The preset name is the
      // fallback and it is the same word on every row it writes - "Alta_Bank"
      // tells whoever works through the review queue nothing at all.
      description: result.description ?? preset.name,
      categoryId: categoryId,
      accountId: accountId,
      exchangeRate: finalExchangeRate,
      exchangeRatePreset: finalExchangeRate != null ? 1 : null,
      needsReview: result.needsReview || uncertainCategory,
    );

    // Second guard, for the copies the id cannot see. The id check above only
    // recognises rows this import wrote since the id became derived from the
    // message; everything imported before that, and everything a bank
    // statement put in for the same payments, carries a random uuid. Without
    // this, re-running an "All time" import writes a second copy of each of
    // them - which is exactly how this install ended up with 116 pairs of the
    // same payment under two different descriptions.
    //
    // Deliberately not applied to rows the import wrote itself: two genuine
    // messages for the same amount in the same second (a retried card charge)
    // must still both land, and those are told apart by their ids.
    final alreadyRecorded = await _transactionRepository
        .findExistingImportedTransaction(
          accountId: accountId,
          date: txDate,
          amount: finalAmount,
        );
    if (alreadyRecorded != null) {
      _smsLog(
        'A transaction for this amount is already recorded on this account '
        'at this time (${alreadyRecorded.id}); skipping',
      );
      return _SmsWriteOutcome.duplicate;
    }

    try {
      await _transactionRepository.addTransaction(transaction);
      _smsLog('Transaction added successfully via repository');
    } catch (e) {
      // The id is derived from the message, so the primary key refusing the
      // row means this message is already on file - the same thing the two
      // checks above look for, caught by the one mechanism that cannot be
      // raced. Counting it as a failure put a re-run of "All time" behind a
      // red "matched but could not be saved" line.
      if (_isDuplicateIdConflict(e)) {
        _smsLog('Message already imported (primary key refused it); skipping');
        return _SmsWriteOutcome.duplicate;
      }
      // Reported, not swallowed: the caller counts this as a failure so the
      // "N transactions created" banner cannot claim writes that never landed.
      _smsLog('Transaction addition FAILED: $e');
      return _SmsWriteOutcome.failed;
    }

    // One movement of money, two messages: a currency exchange or a cash
    // operation is announced leg by leg, and each leg becomes a row of its own
    // here. Unlinked they cancel out in the account balance while adding their
    // whole size to both the income and the expense total - which is how one
    // month came to show 727442 RSD of salary against 743317 of groceries. The
    // row is already written and counted at this point, so a failure to find
    // its other half is not a failure to import it.
    try {
      final counterpart = await _transactionRepository.linkOffsettingTransfer(
        transactionId,
      );
      if (counterpart != null) {
        _smsLog('Linked to $counterpart as the two legs of one transfer');
      }
    } catch (e) {
      _smsLog('Transfer-leg linking failed: $e');
    }

    return _SmsWriteOutcome.created;
  }

  /// The account an imported message is written against, or null when the
  /// install has none that could hold it.
  ///
  /// The chain is: the preset's own default, then the wallet this category is
  /// usually paid from, then the first ordinary account. The middle link is the
  /// suggestion the manual entry form has always made - a category is nearly
  /// always paid from the same place - and the SMS path had simply never asked
  /// for it, because it picked the account before it knew the category.
  ///
  /// Every link is verified against a real row before it is used. That is the
  /// whole point: the previous code invented the id 'default', found no account
  /// under it, silently labelled the amount 'RSD' and then lost the row to the
  /// foreign key.
  Future<Account?> _resolveAccount(SmsPreset preset, String categoryId) async {
    final preferredId = preset.defaultAccountId;
    if (preferredId != null) {
      final preferred = await _accountRepository.getAccountById(preferredId);
      // A preset can outlive the account it names - deleting an account does
      // not walk the presets - so a dangling default falls through to the
      // suggestion rather than failing the row.
      if (preferred != null) return preferred;
    }

    final suggestedId = await _transactionRepository
        .getMostUsedAccountForCategory(
          categoryId,
          since: DateTime.now().subtract(const Duration(days: 30)),
        );
    if (suggestedId != null) {
      final suggested = await _accountRepository.getAccountById(suggestedId);
      if (suggested != null) return suggested;
    }

    // getAccounts() already excludes deleted rows. Asset accounts are excluded
    // here because money moved against one is a trade, not a payment, and
    // AddEditTransactionBloc avoids them in its own fallbacks for the same
    // reason - an SMS about a card payment must not land on a gold holding.
    final accounts = await _accountRepository.getAccounts();
    return accounts.firstWhereOrNull((a) => a.id != null && a.assetId == null);
  }

  /// The category to file [result] under, and whether the answer is a guess.
  ///
  /// A keyword may name a category the user made themselves - "Ai", "VPS" -
  /// which no id shipped in this app can point at, so the name is looked up
  /// among the user's own categories before anything else. Everything after
  /// that is a fallback chain, and it exists because a transaction carrying a
  /// category id no row answers to is refused by the foreign key and lost:
  /// this path reads each SMS once and never returns to it.
  ///
  /// The second value is true when the category was picked rather than
  /// recognised, which is what puts the row in the review queue.
  Future<(String, bool)> _resolveCategory(
    SmsParseResult result,
    SmsPreset preset, {
    required bool isIncome,
  }) async {
    final categories = await _categoryRepository.getCategories();
    bool exists(String? id) => id != null && categories.any((c) => c.id == id);

    final hint = result.categoryNameHint;
    if (hint != null) {
      final named = categories.firstWhereOrNull(
        (c) => c.name.trim().toLowerCase() == hint.trim().toLowerCase(),
      );
      if (named?.id != null) return (named!.id!, false);
    }

    if (exists(result.categoryId)) return (result.categoryId!, false);
    if (exists(preset.defaultCategoryId)) {
      // The preset's own default is a setting, not a reading of the message,
      // so it is only certain when the message named nothing to begin with -
      // and in that case the parser has already asked for review.
      return (preset.defaultCategoryId!, false);
    }

    // Nothing recognised the message, or what it recognised has since been
    // deleted. Fall back to the built-in catch-all of the right direction.
    final wanted = isIncome ? CategoryType.income : CategoryType.expense;
    final fallbackId = isIncome ? 'cat_other_income' : 'cat_other_expense';
    if (exists(fallbackId)) return (fallbackId, true);

    final sameType = categories.firstWhereOrNull((c) => c.type == wanted);
    // With no category of the right type left there is nothing truthful to
    // pick; the write fails and is counted as a failure by the caller, which
    // is better than filing income as an expense.
    return (sameType?.id ?? fallbackId, true);
  }

  Future<void> _onRequestPermission(
    RequestSmsPermission event,
    Emitter<SmsState> emit,
  ) async {
    final granted = await _smsRepository.requestSmsPermission();
    if (isShuttingDown) return;
    emit(state.copyWith(hasPermission: granted));
    if (granted) {
      add(LoadSmsPresets());
    }
  }
}
