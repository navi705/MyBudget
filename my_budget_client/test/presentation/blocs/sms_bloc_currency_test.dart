import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';
import 'package:my_budget_client/domain/entities/settings.dart';
import 'package:my_budget_client/domain/entities/sms_preset.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/domain/repositories/sms_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/domain/services/currency_converter_service.dart';
import 'package:my_budget_client/presentation/blocs/sms/sms_bloc.dart';

/// Guards the currency labelling of SMS-created transactions.
///
/// The regression this pins: [SmsBloc] used to stamp every SMS transaction with
/// the ACCOUNT's currency code while leaving the amount unconverted whenever no
/// exchange rate could be found, so a 100 USD notification on an RSD account was
/// persisted as "100 RSD". Nothing in the UI can catch that — the whole path is
/// driven by OS message delivery.
///
/// Hand-written [Fake]s rather than generated mocks: the bloc subscribes to
/// `listenForSms()` inside its CONSTRUCTOR, so the stream has to exist before
/// the bloc does, and a fake with an eagerly-created controller makes that
/// ordering impossible to get wrong.
class _FakeSmsRepository extends Fake implements SmsRepository {
  _FakeSmsRepository({this.presets = const [], this.messages = const []});

  final List<SmsPreset> presets;
  final List<SmsMessage> messages;
  final StreamController<SmsMessage> incoming =
      StreamController<SmsMessage>.broadcast();
  DateTime? lastSync;

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
  }) async => messages;

  @override
  Future<DateTime?> getLastSyncTimestamp() async => lastSync;

  @override
  Future<void> setLastSyncTimestamp(DateTime timestamp) async {
    lastSync = timestamp;
  }

  @override
  Future<bool> hasSmsPermission() async => true;
}

class _FakeTransactionRepository extends Fake implements TransactionRepository {
  _FakeTransactionRepository({this.failWrites = false});

  final bool failWrites;
  final List<Transaction> added = [];

  @override
  Future<void> addTransaction(Transaction transaction) async {
    if (failWrites) {
      throw StateError('repository refused the write');
    }
    added.add(transaction);
  }
}

class _FakeCurrencyRepository extends Fake implements CurrencyRepository {
  _FakeCurrencyRepository(this.currencies);

  final List<Currency> currencies;

  @override
  Future<List<Currency>> getCurrencies() async => currencies;
}

class _FakeAccountRepository extends Fake implements AccountRepository {
  _FakeAccountRepository(this.account);

  final Account account;

  @override
  Future<Account?> getAccountById(String id) async =>
      id == account.id ? account : null;
}

class _FakeSettingsRepository extends Fake implements SettingsRepository {
  @override
  Future<Settings?> getSetting(String key) async => null;
}

/// [rate] of null reproduces "no rate on file for this pair/date", which is the
/// exact condition the corruption needed.
class _FakeCurrencyConverterService extends Fake
    implements CurrencyConverterService {
  _FakeCurrencyConverterService(this.rate);

  final double? rate;

  @override
  Future<ExchangeRateDomain?> getExchangeRate({
    required String fromCurrencyCode,
    required String toCurrencyCode,
    required DateTime date,
    required String mainCurrencyCode,
    int preset = 1,
  }) async {
    final value = rate;
    if (value == null) return null;
    return ExchangeRateDomain(
      fromCurrencyCode: fromCurrencyCode,
      toCurrencyCode: toCurrencyCode,
      rate: value,
      date: date,
      preset: preset,
    );
  }
}

void main() {
  final account = Account(
    id: 'acc-rsd',
    name: 'Dinar account',
    balance: 0,
    currencyCode: 'RSD',
    currencyDesignationId: 'des-1',
    accountTypeId: 'type-1',
    creationDate: DateTime(2020),
  );

  const currencies = [
    Currency(
      name: 'Serbian dinar',
      code: 'RSD',
      languageCode: 'sr',
      type: TypeCurrency.currency,
    ),
    Currency(
      name: 'US dollar',
      code: 'USD',
      languageCode: 'en',
      type: TypeCurrency.currency,
    ),
  ];

  const preset = SmsPreset(
    id: 'preset-1',
    name: 'Test bank',
    senderFilter: 'TestBank',
    defaultAccountId: 'acc-rsd',
    defaultCategoryId: 'cat-1',
    rules: [
      SmsParsingRule(
        id: 'rule-1',
        type: TransactionType.expense,
        matchPattern: r'Kupovina',
        amountPattern: r'Kupovina\s+([\d.,]+)',
        currencyPattern: r'\b(USD|EUR|RSD)\b',
      ),
    ],
  );

  // 100 USD spent, on an account denominated in RSD.
  final foreignSms = SmsMessage(
    sender: 'TestBank',
    body: 'Kupovina 100.00 USD na racunu 1234',
    date: DateTime(2024, 5, 17),
  );

  SmsBloc buildBloc({
    required _FakeSmsRepository smsRepository,
    required _FakeTransactionRepository transactionRepository,
    double? rate,
  }) {
    return SmsBloc(
      smsRepository: smsRepository,
      transactionRepository: transactionRepository,
      currencyRepository: _FakeCurrencyRepository(currencies),
      accountRepository: _FakeAccountRepository(account),
      currencyConverterService: _FakeCurrencyConverterService(rate),
      settingsRepository: _FakeSettingsRepository(),
    );
  }

  group('SmsBloc foreign-currency transactions', () {
    test(
      'converts and relabels to the account currency when a rate exists',
      () async {
        final smsRepository = _FakeSmsRepository(presets: const [preset]);
        final transactionRepository = _FakeTransactionRepository();
        final bloc = buildBloc(
          smsRepository: smsRepository,
          transactionRepository: transactionRepository,
          rate: 117.0,
        );

        smsRepository.incoming.add(foreignSms);
        await pumpEventQueue();

        expect(transactionRepository.added, hasLength(1));
        final tx = transactionRepository.added.single;
        expect(tx.currencyCode, 'RSD');
        expect(tx.amount, -11700.0);
        expect(tx.exchangeRate, 117.0);
        // Amount and label agree: dividing out the applied rate gives the 100 USD
        // the SMS actually reported.
        expect(tx.amount / tx.exchangeRate!, -100.0);

        await bloc.close();
        await smsRepository.incoming.close();
      },
    );

    test(
      'keeps the raw amount under the SMS currency when no rate exists',
      () async {
        final smsRepository = _FakeSmsRepository(presets: const [preset]);
        final transactionRepository = _FakeTransactionRepository();
        final bloc = buildBloc(
          smsRepository: smsRepository,
          transactionRepository: transactionRepository,
          rate: null,
        );

        smsRepository.incoming.add(foreignSms);
        await pumpEventQueue();

        expect(transactionRepository.added, hasLength(1));
        final tx = transactionRepository.added.single;
        // The core regression: 100 unconverted units must NOT be labelled RSD.
        expect(tx.currencyCode, 'USD');
        expect(tx.amount, -100.0);
        expect(tx.exchangeRate, isNull);
        expect(tx.exchangeRatePreset, isNull);

        await bloc.close();
        await smsRepository.incoming.close();
      },
    );

    test(
      'counts the transaction only once it reached the repository',
      () async {
        final smsRepository = _FakeSmsRepository(
          presets: const [preset],
          messages: [foreignSms],
        );
        final transactionRepository = _FakeTransactionRepository(
          failWrites: true,
        );
        final bloc = buildBloc(
          smsRepository: smsRepository,
          transactionRepository: transactionRepository,
          rate: 117.0,
        );

        bloc.add(const ImportSmsMessages());
        await pumpEventQueue();

        expect(transactionRepository.added, isEmpty);
        expect(bloc.state.createdTransactionsCount, 0);
        expect(bloc.state.failedTransactionsCount, 1);
        expect(bloc.state.importError, isNotNull);

        await bloc.close();
        await smsRepository.incoming.close();
      },
    );

    test(
      'does not emit for an SMS that lands while the bloc is closing',
      () async {
        final smsRepository = _FakeSmsRepository(presets: const [preset]);
        final transactionRepository = _FakeTransactionRepository();
        final bloc = buildBloc(
          smsRepository: smsRepository,
          transactionRepository: transactionRepository,
          rate: 117.0,
        );

        // close() awaits the cancel, so an SMS delivered afterwards can never
        // reach add() on a closed bloc (which throws).
        await bloc.close();
        smsRepository.incoming.add(foreignSms);
        await pumpEventQueue();

        expect(transactionRepository.added, isEmpty);

        await smsRepository.incoming.close();
      },
    );
  });
}
