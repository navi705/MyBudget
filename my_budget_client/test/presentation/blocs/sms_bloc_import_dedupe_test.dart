// Re-running an SMS import, and which account the imported row lands on.
//
// The two belong in one file because they were one bug in practice. "All time"
// re-reads the entire inbox, so the import is re-runnable by design; every
// transaction used to be written under a fresh uuid, which meant the second run
// wrote a second copy of everything AND moved the account balance again, since
// addTransaction adjusts the balance in the same unit of work. Meanwhile a
// preset with no default account wrote against the invented id 'default',
// which no seed creates: the amount was silently labelled 'RSD' and the row was
// then refused by the foreign key.
import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';
import 'package:my_budget_client/domain/entities/settings.dart';
import 'package:my_budget_client/domain/entities/sms_preset.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/domain/repositories/sms_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/domain/services/currency_converter_service.dart';
import 'package:my_budget_client/presentation/blocs/sms/sms_bloc.dart';

/// Hand-written fakes rather than generated mocks, for the same reason the
/// sibling SMS tests use them: the bloc subscribes to `listenForSms()` inside
/// its constructor, so the stream has to exist before the bloc does.
class _FakeSmsRepository extends Fake implements SmsRepository {
  _FakeSmsRepository({this.presets = const [], this.messages = const []});

  final List<SmsPreset> presets;
  List<SmsMessage> messages;
  final StreamController<SmsMessage> incoming =
      StreamController<SmsMessage>.broadcast();

  DateTime? lastSync;
  int getMessagesCalls = 0;

  /// When set, the first read of the inbox parks here — the only way to hold an
  /// import open long enough for a second one to be dispatched into it.
  Completer<void>? gate;

  @override
  Stream<SmsMessage> listenForSms() => incoming.stream;

  @override
  Future<List<SmsPreset>> getAllPresets() async => presets;

  @override
  Future<List<SmsPreset>> getEnabledPresets() async =>
      presets.where((p) => p.isEnabled).toList();

  @override
  Future<List<SmsMessage>> getSmsMessages({
    DateTime? since,
    List<String>? senderFilters,
  }) async {
    getMessagesCalls++;
    final held = gate;
    if (held != null) {
      gate = null;
      await held.future;
    }
    return messages;
  }

  @override
  Future<DateTime?> getLastSyncTimestamp() async => lastSync;

  @override
  Future<void> setLastSyncTimestamp(DateTime timestamp) async {
    lastSync = timestamp;
  }

  @override
  Future<bool> hasSmsPermission() async => true;
}

/// Holds rows in a map keyed by id, which is the part of the real table this
/// test is actually about: a second insert under an id already present is
/// refused rather than silently duplicated.
class _FakeTransactionRepository extends Fake implements TransactionRepository {
  _FakeTransactionRepository({this.mostUsedAccountId});

  final String? mostUsedAccountId;
  final Map<String, Transaction> rows = {};
  final List<String> writeLog = [];
  DateTime? mostUsedSince;

  List<Transaction> get added => rows.values.toList();

  @override
  Future<void> addTransaction(Transaction transaction) async {
    if (rows.containsKey(transaction.id)) {
      throw StateError('primary key already holds ${transaction.id}');
    }
    rows[transaction.id!] = transaction;
    writeLog.add(transaction.id!);
  }

  @override
  Future<Transaction?> getTransactionById(String id) async => rows[id];

  /// The ids handed to [linkOffsettingTransfer], in the order they were
  /// offered.
  final List<String> transferLinkChecks = [];

  @override
  Future<String?> linkOffsettingTransfer(String transactionId) async {
    transferLinkChecks.add(transactionId);
    return null;
  }

  @override
  Future<String?> getMostUsedAccountForCategory(
    String categoryId, {
    required DateTime since,
  }) async {
    mostUsedSince = since;
    return mostUsedAccountId;
  }

  /// Mirrors the second duplicate guard's SQL: rows on the same account at the
  /// same instant that this import did not write itself.
  @override
  Future<Transaction?> findExistingImportedTransaction({
    required String accountId,
    required DateTime date,
    required double amount,
  }) async => rows.values.firstWhereOrNull(
    (t) =>
        !(t.id ?? '').startsWith('sms') &&
        t.accountId == accountId &&
        t.date == date &&
        (t.amount - amount).abs() < 0.005,
  );

  @override
  Stream<void> watchTransactionChanges() => const Stream.empty();
}

class _FakeCurrencyRepository extends Fake implements CurrencyRepository {
  @override
  Future<List<Currency>> getCurrencies() async => const [
    Currency(
      name: 'Serbian dinar',
      code: 'RSD',
      languageCode: 'sr',
      type: TypeCurrency.currency,
    ),
    Currency(
      name: 'Euro',
      code: 'EUR',
      languageCode: 'en',
      type: TypeCurrency.currency,
    ),
  ];
}

class _FakeAccountRepository extends Fake implements AccountRepository {
  _FakeAccountRepository(this.accounts);

  /// Stands for the non-deleted rows only — the real getAccounts() filters
  /// deleted accounts out in SQL, so a test that put one here would be
  /// testing a database that cannot exist.
  final List<Account> accounts;

  @override
  Future<Account?> getAccountById(String id) async =>
      accounts.firstWhereOrNull((a) => a.id == id);

  @override
  Future<List<Account>> getAccounts() async => accounts;

  @override
  Stream<List<Account>> watchAccounts() => const Stream.empty();
}

class _FakeCategoryRepository extends Fake implements CategoryRepository {
  @override
  Future<List<Category>> getCategories({bool includeSystem = false}) async => [
    Category(id: 'cat-1', name: 'Test category'),
  ];
}

class _FakeSettingsRepository extends Fake implements SettingsRepository {
  @override
  Future<Settings?> getSetting(String key) async => null;
}

class _FakeCurrencyConverterService extends Fake
    implements CurrencyConverterService {
  @override
  Future<ExchangeRateDomain?> getExchangeRate({
    required String fromCurrencyCode,
    required String toCurrencyCode,
    required DateTime date,
    required String mainCurrencyCode,
    int preset = 1,
  }) async => null;
}

Account _account(String id, {String currencyCode = 'RSD', String? assetId}) =>
    Account(
      id: id,
      name: id,
      balance: 0,
      currencyCode: currencyCode,
      currencyDesignationId: 'des-1',
      accountTypeId: 'type-1',
      creationDate: DateTime(2020),
      assetId: assetId,
    );

SmsPreset _preset({String? defaultAccountId}) => SmsPreset(
  id: 'preset-1',
  name: 'Test bank',
  senderFilter: 'TestBank',
  defaultAccountId: defaultAccountId,
  defaultCategoryId: 'cat-1',
  rules: const [
    SmsParsingRule(
      id: 'rule-1',
      type: TransactionType.expense,
      matchPattern: r'Kupovina',
      amountPattern: r'Kupovina\s+([\d.,]+)',
      // Deliberately never matched by the bodies below, so the transaction is
      // labelled with the RESOLVED ACCOUNT's currency and the assertions on it
      // are about account resolution rather than about conversion.
      currencyPattern: r'\b(USD)\b',
    ),
  ],
);

SmsMessage _sms({
  String? id,
  String body = 'Kupovina 100.00 na racunu 1234',
  DateTime? date,
}) => SmsMessage(
  sender: 'TestBank',
  body: body,
  date: date ?? DateTime(2024, 5, 17, 12, 30, 15),
  id: id,
);

/// A repository whose duplicate guards see nothing but whose write is refused
/// by the primary key, which is what a second importer committing between the
/// check and the write looks like from here.
class _RacingTransactionRepository extends _FakeTransactionRepository {
  @override
  Future<Transaction?> getTransactionById(String id) async => null;

  @override
  Future<void> addTransaction(Transaction transaction) async {
    throw Exception(
      'SqliteException(1555): UNIQUE constraint failed: transactions.id',
    );
  }
}

void main() {
  SmsBloc buildBloc({
    required _FakeSmsRepository smsRepository,
    required _FakeTransactionRepository transactionRepository,
    required _FakeAccountRepository accountRepository,
  }) => SmsBloc(
    smsRepository: smsRepository,
    transactionRepository: transactionRepository,
    currencyRepository: _FakeCurrencyRepository(),
    accountRepository: accountRepository,
    categoryRepository: _FakeCategoryRepository(),
    currencyConverterService: _FakeCurrencyConverterService(),
    settingsRepository: _FakeSettingsRepository(),
  );

  group('a write the primary key refuses', () {
    test('counts as already imported, not as a failure', () async {
      final smsRepository = _FakeSmsRepository(
        presets: [_preset(defaultAccountId: 'acc-rsd')],
        messages: [_sms(id: 'device-1')],
      );
      final bloc = buildBloc(
        smsRepository: smsRepository,
        transactionRepository: _RacingTransactionRepository(),
        accountRepository: _FakeAccountRepository([_account('acc-rsd')]),
      );

      bloc.add(const ImportSmsMessages());
      await pumpEventQueue();

      expect(bloc.state.duplicateTransactionsCount, 1);
      expect(bloc.state.failedTransactionsCount, 0);
      expect(bloc.state.createdTransactionsCount, 0);
      expect(
        bloc.state.importError,
        isNull,
        reason: 'the row was already on file; nothing is broken',
      );

      await bloc.close();
      await smsRepository.incoming.close();
    });
  });

  group('a row that could be half of one movement of money', () {
    test('is offered to the transfer-leg check once it is written', () async {
      // A bank announces a currency exchange or a cash operation one leg at a
      // time, and each leg lands here as a row of its own. Unlinked they
      // cancel out in the balance and count their whole size as both income
      // and expense - so every written row is offered its other half.
      final smsRepository = _FakeSmsRepository(
        presets: [_preset(defaultAccountId: 'acc-rsd')],
        messages: [_sms(id: 'device-1')],
      );
      final transactionRepository = _FakeTransactionRepository();
      final bloc = buildBloc(
        smsRepository: smsRepository,
        transactionRepository: transactionRepository,
        accountRepository: _FakeAccountRepository([_account('acc-rsd')]),
      );

      bloc.add(const ImportSmsMessages());
      await pumpEventQueue();

      expect(transactionRepository.transferLinkChecks, [
        transactionRepository.writeLog.single,
      ]);
      // Nothing about the linking changes what the import reports it did.
      expect(bloc.state.createdTransactionsCount, 1);
      expect(bloc.state.failedTransactionsCount, 0);

      await bloc.close();
      await smsRepository.incoming.close();
    });
  });

  group('re-importing a window that was already imported', () {
    test('writes nothing the second time and says so', () async {
      final smsRepository = _FakeSmsRepository(
        presets: [_preset(defaultAccountId: 'acc-rsd')],
        messages: [
          _sms(id: 'device-1'),
          _sms(id: 'device-2', body: 'Kupovina 250.00'),
        ],
      );
      final transactionRepository = _FakeTransactionRepository();
      final bloc = buildBloc(
        smsRepository: smsRepository,
        transactionRepository: transactionRepository,
        accountRepository: _FakeAccountRepository([_account('acc-rsd')]),
      );

      // "All time" both times: since == null, so the whole inbox is re-read.
      bloc.add(const ImportSmsMessages());
      await pumpEventQueue();
      expect(bloc.state.createdTransactionsCount, 2);
      expect(bloc.state.duplicateTransactionsCount, 0);

      bloc.add(const ImportSmsMessages());
      await pumpEventQueue();

      // The balance is moved inside addTransaction, so a second write here is
      // not merely an extra row — it is the account silently going wrong.
      expect(transactionRepository.writeLog, hasLength(2));
      expect(bloc.state.createdTransactionsCount, 0);
      expect(
        bloc.state.duplicateTransactionsCount,
        2,
        reason:
            'the user must be able to tell "nothing new" from "nothing '
            'worked"',
      );
      expect(
        bloc.state.failedTransactionsCount,
        0,
        reason: 'a re-import is a normal thing to do, not a failure',
      );
      expect(bloc.state.importError, isNull);

      await bloc.close();
      await smsRepository.incoming.close();
    });

    test('the id follows the device message id, not the body', () async {
      // Same device id, different text: the platform says these are one
      // message, and the body of an SMS is not something the device rewrites.
      final smsRepository = _FakeSmsRepository(
        presets: [_preset(defaultAccountId: 'acc-rsd')],
        messages: [
          _sms(id: 'device-1'),
          _sms(id: 'device-1', body: 'Kupovina 999.00 na racunu 1234'),
        ],
      );
      final transactionRepository = _FakeTransactionRepository();
      final bloc = buildBloc(
        smsRepository: smsRepository,
        transactionRepository: transactionRepository,
        accountRepository: _FakeAccountRepository([_account('acc-rsd')]),
      );

      bloc.add(const ImportSmsMessages());
      await pumpEventQueue();

      expect(transactionRepository.writeLog, hasLength(1));
      expect(bloc.state.duplicateTransactionsCount, 1);
      expect(transactionRepository.added.single.id, startsWith('sms_'));

      await bloc.close();
      await smsRepository.incoming.close();
    });

    test(
      'with no device id the sender, timestamp and body identify the message',
      () async {
        // Not every platform read gives an id. Two genuinely different
        // messages must still get different ids; the same one re-read must get
        // the same id back.
        final smsRepository = _FakeSmsRepository(
          presets: [_preset(defaultAccountId: 'acc-rsd')],
          messages: [
            _sms(),
            _sms(body: 'Kupovina 250.00 na racunu 1234'),
            _sms(date: DateTime(2024, 5, 17, 12, 30, 16)),
          ],
        );
        final transactionRepository = _FakeTransactionRepository();
        final bloc = buildBloc(
          smsRepository: smsRepository,
          transactionRepository: transactionRepository,
          accountRepository: _FakeAccountRepository([_account('acc-rsd')]),
        );

        bloc.add(const ImportSmsMessages());
        await pumpEventQueue();
        expect(transactionRepository.writeLog, hasLength(3));

        // Re-read of the exact same three.
        bloc.add(const ImportSmsMessages());
        await pumpEventQueue();

        expect(transactionRepository.writeLog, hasLength(3));
        expect(bloc.state.duplicateTransactionsCount, 3);

        await bloc.close();
        await smsRepository.incoming.close();
      },
    );

    test(
      'a message that arrives live is not re-imported by a later run',
      () async {
        final message = _sms(id: 'device-1');
        final smsRepository = _FakeSmsRepository(
          presets: [_preset(defaultAccountId: 'acc-rsd')],
          messages: [message],
        );
        final transactionRepository = _FakeTransactionRepository();
        final bloc = buildBloc(
          smsRepository: smsRepository,
          transactionRepository: transactionRepository,
          accountRepository: _FakeAccountRepository([_account('acc-rsd')]),
        );

        // Delivered by the OS first, then swept up by a catch-up import — which
        // is the ordinary sequence, since the watermark is coarse.
        smsRepository.incoming.add(message);
        await pumpEventQueue();
        expect(transactionRepository.writeLog, hasLength(1));

        bloc.add(const ImportSmsMessages());
        await pumpEventQueue();

        expect(transactionRepository.writeLog, hasLength(1));
        expect(bloc.state.duplicateTransactionsCount, 1);

        await bloc.close();
        await smsRepository.incoming.close();
      },
    );
  });

  group('two imports dispatched at once', () {
    test('the second is dropped rather than walking the same window', () async {
      // LoadSmsPresets fires on app start, on opening Settings and after every
      // preset toggle, and each one dispatches its own catch-up import from the
      // watermark. Two running together read the same `since`.
      final smsRepository = _FakeSmsRepository(
        presets: [_preset(defaultAccountId: 'acc-rsd')],
        messages: [_sms(id: 'device-1')],
      )..gate = Completer<void>();
      final transactionRepository = _FakeTransactionRepository();
      final bloc = buildBloc(
        smsRepository: smsRepository,
        transactionRepository: transactionRepository,
        accountRepository: _FakeAccountRepository([_account('acc-rsd')]),
      );

      bloc.add(const ImportSmsMessages());
      await pumpEventQueue();
      bloc.add(const ImportSmsMessages());
      await pumpEventQueue();

      smsRepository.gate = null;
      await pumpEventQueue();

      expect(
        smsRepository.getMessagesCalls,
        1,
        reason:
            'the second import covers exactly the window the first is '
            'already walking, so there is nothing to queue it for',
      );

      await bloc.close();
      await smsRepository.incoming.close();
    });

    test('the watermark is advanced before the loop, not after it', () async {
      final smsRepository = _FakeSmsRepository(
        presets: [_preset(defaultAccountId: 'acc-rsd')],
        messages: [_sms(id: 'device-1')],
      );
      final transactionRepository = _FakeTransactionRepository();
      final bloc = buildBloc(
        smsRepository: smsRepository,
        transactionRepository: transactionRepository,
        accountRepository: _FakeAccountRepository([_account('acc-rsd')]),
      );

      // Parked inside the inbox read, i.e. before a single message has been
      // processed: the watermark must already be written by then.
      final gate = Completer<void>();
      smsRepository.gate = gate;
      bloc.add(const ImportSmsMessages());
      await pumpEventQueue();

      gate.complete();
      await pumpEventQueue();

      expect(smsRepository.lastSync, isNotNull);

      await bloc.close();
      await smsRepository.incoming.close();
    });
  });

  group('which account the imported row lands on', () {
    test('the preset default wins when it still exists', () async {
      final smsRepository = _FakeSmsRepository(
        presets: [_preset(defaultAccountId: 'acc-eur')],
        messages: [_sms(id: 'device-1')],
      );
      final transactionRepository = _FakeTransactionRepository(
        mostUsedAccountId: 'acc-rsd',
      );
      final bloc = buildBloc(
        smsRepository: smsRepository,
        transactionRepository: transactionRepository,
        accountRepository: _FakeAccountRepository([
          _account('acc-eur', currencyCode: 'EUR'),
          _account('acc-rsd'),
        ]),
      );

      bloc.add(const ImportSmsMessages());
      await pumpEventQueue();

      final tx = transactionRepository.added.single;
      expect(tx.accountId, 'acc-eur');
      // The setting the user made outranks a statistical guess, so the
      // suggestion must not even be asked for.
      expect(transactionRepository.mostUsedSince, isNull);

      await bloc.close();
      await smsRepository.incoming.close();
    });

    test(
      'with no default it goes to the wallet this category is usually paid from',
      () async {
        // The suggestion the manual entry form has always made; the SMS path
        // never asked for it, because it picked the account before it knew the
        // category.
        final smsRepository = _FakeSmsRepository(
          presets: [_preset()],
          messages: [_sms(id: 'device-1')],
        );
        final transactionRepository = _FakeTransactionRepository(
          mostUsedAccountId: 'acc-eur',
        );
        final bloc = buildBloc(
          smsRepository: smsRepository,
          transactionRepository: transactionRepository,
          accountRepository: _FakeAccountRepository([
            _account('acc-rsd'),
            _account('acc-eur', currencyCode: 'EUR'),
          ]),
        );

        bloc.add(const ImportSmsMessages());
        await pumpEventQueue();

        final tx = transactionRepository.added.single;
        expect(tx.accountId, 'acc-eur');
        // The currency comes from the account that was actually resolved. The
        // old code hard-coded 'RSD' here, which could only be right by
        // accident.
        expect(tx.currencyCode, 'EUR');
        expect(
          DateTime.now()
              .difference(transactionRepository.mostUsedSince!)
              .inDays,
          30,
        );

        await bloc.close();
        await smsRepository.incoming.close();
      },
    );

    test('a default pointing at a deleted account falls through', () async {
      // Deleting an account does not walk the presets, so the id a preset
      // holds can outlive the row.
      final smsRepository = _FakeSmsRepository(
        presets: [_preset(defaultAccountId: 'acc-gone')],
        messages: [_sms(id: 'device-1')],
      );
      final transactionRepository = _FakeTransactionRepository(
        mostUsedAccountId: 'acc-eur',
      );
      final bloc = buildBloc(
        smsRepository: smsRepository,
        transactionRepository: transactionRepository,
        accountRepository: _FakeAccountRepository([
          _account('acc-eur', currencyCode: 'EUR'),
        ]),
      );

      bloc.add(const ImportSmsMessages());
      await pumpEventQueue();

      expect(transactionRepository.added.single.accountId, 'acc-eur');

      await bloc.close();
      await smsRepository.incoming.close();
    });

    test('the last resort skips asset accounts', () async {
      // Money moved against an asset account is a trade, not a payment; a card
      // purchase must not land on a gold holding.
      final smsRepository = _FakeSmsRepository(
        presets: [_preset()],
        messages: [_sms(id: 'device-1')],
      );
      final transactionRepository = _FakeTransactionRepository();
      final bloc = buildBloc(
        smsRepository: smsRepository,
        transactionRepository: transactionRepository,
        accountRepository: _FakeAccountRepository([
          _account('acc-gold', assetId: 'asset-xau'),
          _account('acc-eur', currencyCode: 'EUR'),
        ]),
      );

      bloc.add(const ImportSmsMessages());
      await pumpEventQueue();

      expect(transactionRepository.added.single.accountId, 'acc-eur');

      await bloc.close();
      await smsRepository.incoming.close();
    });

    test(
      'with no usable account the row fails instead of inventing one',
      () async {
        final smsRepository = _FakeSmsRepository(
          presets: [_preset()],
          messages: [_sms(id: 'device-1')],
        );
        final transactionRepository = _FakeTransactionRepository();
        final bloc = buildBloc(
          smsRepository: smsRepository,
          transactionRepository: transactionRepository,
          accountRepository: _FakeAccountRepository([
            _account('acc-gold', assetId: 'asset-xau'),
          ]),
        );

        bloc.add(const ImportSmsMessages());
        await pumpEventQueue();

        // Nothing written under a phantom id, and the failure is reported rather
        // than looking like an import that found nothing.
        expect(transactionRepository.added, isEmpty);
        expect(bloc.state.failedTransactionsCount, 1);
        expect(bloc.state.createdTransactionsCount, 0);
        expect(bloc.state.importError, isNotNull);

        await bloc.close();
        await smsRepository.incoming.close();
      },
    );
  });
}
