// Which category an imported SMS lands in, and when the row is put in the
// review queue instead of filed silently.
//
// A preset ships inside the app, so the categories it wants to name can only be
// named by id - but "Ai" and "VPS" are categories this user made, and no id in
// the app points at them. The keyword therefore carries a name hint and an id
// beside it, and the whole chain below exists because a transaction written
// with a category id no row answers to is refused by the foreign key and lost:
// this path reads each message once and never comes back to it.
import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
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

class _FakeSmsRepository extends Fake implements SmsRepository {
  _FakeSmsRepository({this.presets = const []});

  final List<SmsPreset> presets;
  final StreamController<SmsMessage> incoming =
      StreamController<SmsMessage>.broadcast();

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
  }) async => const [];

  @override
  Future<DateTime?> getLastSyncTimestamp() async => null;

  @override
  Future<void> setLastSyncTimestamp(DateTime timestamp) async {}

  @override
  Future<bool> hasSmsPermission() async => true;
}

class _FakeTransactionRepository extends Fake implements TransactionRepository {
  final List<Transaction> added = [];

  @override
  Future<void> addTransaction(Transaction transaction) async {
    added.add(transaction);
  }

  /// Backs the bloc's "have I written this message already?" check, and stands
  /// in for the primary key: adding the same id twice would be refused by the
  /// real table.
  @override
  Future<Transaction?> getTransactionById(String id) async =>
      added.firstWhereOrNull((t) => t.id == id);

  /// Mirrors the second duplicate guard's SQL: rows on the same account at the
  /// same instant that this import did not write itself.
  @override
  Future<Transaction?> findExistingImportedTransaction({
    required String accountId,
    required DateTime date,
    required double amount,
  }) async => added.firstWhereOrNull(
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
  ];
}

class _FakeAccountRepository extends Fake implements AccountRepository {
  @override
  Future<Account?> getAccountById(String id) async =>
      id == _account.id ? _account : null;

  @override
  Stream<List<Account>> watchAccounts() => const Stream.empty();
}

class _FakeCategoryRepository extends Fake implements CategoryRepository {
  _FakeCategoryRepository(this.categories);

  final List<Category> categories;

  @override
  Future<List<Category>> getCategories({bool includeSystem = false}) async =>
      categories;
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

final _account = Account(
  id: 'acc-rsd',
  name: 'Dinar account',
  balance: 0,
  currencyCode: 'RSD',
  currencyDesignationId: 'des-1',
  accountTypeId: 'type-1',
  creationDate: DateTime(2020),
);

/// The catch-alls the app seeds. Present on every install that has not had them
/// deleted, which is what the last link of the chain counts on.
final _fallbacks = [
  Category(
    id: 'cat_other_expense',
    name: 'Other expenses',
    type: CategoryType.expense,
  ),
  Category(
    id: 'cat_other_income',
    name: 'Other income',
    type: CategoryType.income,
  ),
];

/// The category the app seeds for subscriptions - the id the "Ai" and "VPS"
/// keywords fall back to on an install without those user categories.
final _subscriptions = Category(
  id: 'cat_subscriptions',
  name: 'Subscriptions',
  type: CategoryType.expense,
);

const _expenseRule = SmsParsingRule(
  id: 'rule-expense',
  type: TransactionType.expense,
  matchPattern: r'Placanje',
  amountPattern: r'iznos\s+([\d.,]+)',
  currencyPattern: r'\b(RSD|EUR)\b',
  descriptionPattern: r'mesto\s+([^,]+)',
);

const _incomeRule = SmsParsingRule(
  id: 'rule-income',
  type: TransactionType.income,
  matchPattern: r'Priliv',
  amountPattern: r'iznos\s+([\d.,]+)',
  currencyPattern: r'\b(RSD|EUR)\b',
);

// Names the ATM rather than a merchant, so it says outright that it cannot know
// the category and skips the keywords entirely.
const _withdrawalRule = SmsParsingRule(
  id: 'rule-withdrawal',
  type: TransactionType.expense,
  matchPattern: r'Podizanje gotovine',
  amountPattern: r'iznos\s+([\d.,]+)',
  currencyPattern: r'\b(RSD|EUR)\b',
  descriptionPattern: r'mesto\s+([^,]+)',
  forceReview: true,
);

SmsPreset _preset({String? defaultCategoryId}) => SmsPreset(
  id: 'preset-1',
  name: 'Test bank',
  senderFilter: 'TestBank',
  defaultAccountId: 'acc-rsd',
  defaultCategoryId: defaultCategoryId,
  rules: const [_expenseRule, _incomeRule, _withdrawalRule],
  categoryKeywords: const [
    SmsCategoryKeyword(
      keyword: 'anthropic',
      categoryId: 'cat_subscriptions',
      categoryNameHint: 'Ai',
    ),
  ],
);

SmsMessage _sms(String body) =>
    SmsMessage(sender: 'TestBank', body: body, date: DateTime(2026, 1, 19));

final _anthropic = _sms(
  'Placanje VISA karticom **3677: iznos 20.00 RSD, mesto ANTHROPIC, '
  'dana 19.01.2026 u 12:52:35h',
);

void main() {
  /// Delivers [message] to a bloc whose database holds exactly [categories],
  /// and returns the transaction that was written.
  Future<Transaction> importedWith(
    List<Category> categories, {
    required SmsMessage message,
    String? defaultCategoryId,
  }) async {
    final smsRepository = _FakeSmsRepository(
      presets: [_preset(defaultCategoryId: defaultCategoryId)],
    );
    final transactionRepository = _FakeTransactionRepository();
    final bloc = SmsBloc(
      smsRepository: smsRepository,
      transactionRepository: transactionRepository,
      currencyRepository: _FakeCurrencyRepository(),
      accountRepository: _FakeAccountRepository(),
      categoryRepository: _FakeCategoryRepository(categories),
      currencyConverterService: _FakeCurrencyConverterService(),
      settingsRepository: _FakeSettingsRepository(),
    );

    smsRepository.incoming.add(message);
    await pumpEventQueue();
    await bloc.close();
    await smsRepository.incoming.close();

    expect(transactionRepository.added, hasLength(1));
    return transactionRepository.added.single;
  }

  group('the category an imported message is filed under', () {
    test('a name hint finds the category the user made themselves', () async {
      final ai = Category(id: 'usr-7', name: 'Ai', type: CategoryType.expense);

      final tx = await importedWith([
        ..._fallbacks,
        _subscriptions,
        ai,
      ], message: _anthropic);

      // The user's own category wins over the id shipped beside the hint: the
      // id is only there so the row is never lost.
      expect(tx.categoryId, 'usr-7');
      expect(tx.needsReview, isFalse);
    });

    test('the hint is matched on the name, not on the case or spacing', () {
      // The user typed the name into a text field; the preset carries a
      // literal. Requiring them to agree exactly would file everything under
      // the fallback on a name like " ai ".
      return importedWith([
        ..._fallbacks,
        Category(id: 'usr-7', name: '  AI ', type: CategoryType.expense),
      ], message: _anthropic).then((tx) => expect(tx.categoryId, 'usr-7'));
    });

    test(
      'without that category the keyword id is used and nothing is queued',
      () async {
        // The install has no "Ai" category. Filing under the app's own
        // subscriptions category is still a reading of the message, not a
        // guess, so it does not belong in the queue.
        final tx = await importedWith([
          ..._fallbacks,
          _subscriptions,
        ], message: _anthropic);

        expect(tx.categoryId, 'cat_subscriptions');
        expect(tx.needsReview, isFalse);
      },
    );

    test('a keyword id that has been deleted falls to the catch-all', () async {
      // The user deleted the subscriptions category. The id it left behind is
      // refused by the foreign key, so the row would be lost outright.
      final tx = await importedWith(_fallbacks, message: _anthropic);

      expect(tx.categoryId, 'cat_other_expense');
      expect(
        tx.needsReview,
        isTrue,
        reason: 'the category was picked, not recognised',
      );
    });

    test('the preset default is used for a message that names nothing', () async {
      final tx = await importedWith(
        [
          ..._fallbacks,
          Category(id: 'usr-9', name: 'Shopping', type: CategoryType.expense),
        ],
        message: _sms(
          'Placanje VISA karticom **3677: iznos 30.00 RSD, mesto NEKA PRODAVN, '
          'dana 19.01.2026 u 12:52:35h',
        ),
        defaultCategoryId: 'usr-9',
      );

      expect(tx.categoryId, 'usr-9');
      // Still queued: the default is a setting the user made once, not
      // anything the message said, so the row is a guess with a
      // reasonable prior rather than a reading.
      expect(tx.needsReview, isTrue);
    });

    test('income falls to the income catch-all, never an expense one', () async {
      // Filing income under an expense category would flip the sign of a
      // month's report, which is worse than an unfiled row.
      final tx = await importedWith(
        _fallbacks,
        message: _sms('Priliv na racun: iznos 5000.00 RSD'),
      );

      expect(tx.categoryId, 'cat_other_income');
      expect(tx.needsReview, isTrue);
    });

    test('with the catch-all gone any category of the right type is taken', () async {
      // Nothing truthful is left to pick. Some category of the right direction
      // keeps the amount and the date, which is the part of the message that
      // cannot be recovered; the queue flag is what brings the user to it.
      final tx = await importedWith([
        Category(id: 'usr-3', name: 'Bills', type: CategoryType.expense),
        Category(id: 'usr-4', name: 'Salary', type: CategoryType.income),
      ], message: _anthropic);

      expect(tx.categoryId, 'usr-3');
      expect(tx.needsReview, isTrue);
    });
  });

  group('the messages that go straight to the queue', () {
    test('a cash withdrawal is queued and skips the keywords', () async {
      // "ATM BPS- ANTHROPIC" is absurd on purpose: it proves the rule stops the
      // keyword matching rather than merely losing to it. A real one reads
      // "ATM BPS- MAXI V", which the grocery keyword would happily claim.
      final tx = await importedWith(
        [
          ..._fallbacks,
          _subscriptions,
          Category(id: 'usr-7', name: 'Ai', type: CategoryType.expense),
        ],
        message: _sms(
          'Podizanje gotovine DINA karticom **9574: iznos 40000.00 RSD, '
          'mesto ATM BPS- ANTHROPIC, dana 05.01.2026 u 17:24:10h',
        ),
      );

      expect(tx.categoryId, 'cat_other_expense');
      expect(tx.needsReview, isTrue);
      expect(tx.amount, -40000.0);
      // The cash is real and already gone from the account; only where it went
      // is unknown.
      expect(tx.description, 'ATM BPS- ANTHROPIC');
    });
  });
}
