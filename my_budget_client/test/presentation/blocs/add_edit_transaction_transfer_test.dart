// What a transfer writes down, and what it can read back.
//
// A transfer is the one shape in this app that writes TWO rows from one form.
// Everything below is about the gap that opens between them, or between what
// the form showed and what the rows ended up holding.
//
//   - The rate. Both legs used to be written with `exchangeRate` null, so a
//     cross-currency transfer kept no record of the rate it was made at.
//     Reopening it recovered the rate by dividing one leg's amount by the
//     other's - which works only while both amounts are still exactly as
//     saved, and not at all when the sent amount is zero.
//   - The direction toggle. `manualExchangeRate` is held in the direction the
//     field is currently displaying, so an inverted field holds the
//     reciprocal, and the save inverts it back. The converted-amount preview
//     did not, so the number the user approved and the number written to the
//     receiving account differed by a factor of the rate squared.
//   - The second leg on edit. `updateTransaction` reads the old row first and
//     returns silently when there is none, so editing a transfer whose
//     `linkedTransactionId` was null generated a fresh id and then "updated" a
//     row that did not exist: the money left the source account and never
//     arrived anywhere.
//   - The wording. Both descriptions were hardcoded English, in an app that
//     ships fifteen locales and already had `transferToDescription` and
//     `transferFromDescription` sitting unused in every one of its .arb files.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/constants/app_constants.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';
import 'package:my_budget_client/domain/entities/settings.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/domain/repositories/asset_repository.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/presentation/blocs/add_edit_transaction/add_edit_transaction_bloc.dart';

/// Separates the two write paths, because the whole point of one of these
/// tests is that a row reached `add` when it had been reaching `update`.
///
/// `updateTransaction` also mirrors the real one's defining behaviour: a row
/// that is not there is not written and not reported. A fake that recorded the
/// call regardless would let the bug under test pass.
class _RecordingTransactionRepository extends Fake
    implements TransactionRepository {
  final Map<String, Transaction> rows = {};
  final List<Transaction> added = [];
  final List<Transaction> updated = [];

  @override
  Future<void> addTransaction(Transaction transaction) async {
    added.add(transaction);
    rows[transaction.id!] = transaction;
  }

  @override
  Future<void> updateTransaction(Transaction transaction) async {
    if (!rows.containsKey(transaction.id)) return;
    updated.add(transaction);
    rows[transaction.id!] = transaction;
  }

  @override
  Future<Transaction?> getTransactionById(String id) async => rows[id];

  @override
  Stream<void> watchTransactionChanges() => const Stream.empty();
}

class _FakeCurrencyRepository extends Fake implements CurrencyRepository {
  final Map<String, List<ExchangeRateDomain>> ratesByPair = {};

  @override
  Future<List<ExchangeRateDomain>> getExchangeRatesFiltered({
    int limit = 100,
    int offset = 0,
    DateTime? startDate,
    DateTime? endDate,
    String? fromCurrency,
    String? toCurrency,
    List<int>? presets,
    bool sortAscending = false,
  }) async {
    return ratesByPair['$fromCurrency->$toCurrency'] ?? const [];
  }

  @override
  Future<List<Currency>> getCurrencies() async => const [_usd, _eur];
}

/// Holds the system transfer category `_onSubmitted` resolves for a transfer,
/// so the handler reaches the write instead of failing earlier.
class _FakeCategoryRepository extends Fake implements CategoryRepository {
  @override
  Future<List<Category>> getCategories({bool includeSystem = false}) async => [
    Category(
      id: 'transfer-cat',
      name: AppConstants.systemTransferCategoryName,
      type: CategoryType.transfer,
    ),
  ];

  @override
  Stream<List<Category>> watchCategories({bool includeSystem = false}) =>
      const Stream.empty();
}

class _FakeAccountRepository extends Fake implements AccountRepository {
  @override
  Future<List<Account>> getAccounts({bool includeArchived = false}) async => [
    _dollarAccount,
    _euroAccount,
  ];

  @override
  Stream<List<Account>> watchAccounts({bool includeArchived = false}) =>
      const Stream.empty();
}

/// The account list a transfer is opened against when an asset account is in
/// it. `getAllAccounts` has no ORDER BY, so "whatever comes first" is a real
/// possibility and this fake makes it the deliberate case: the asset account
/// is first.
class _AssetFirstAccountRepository extends Fake implements AccountRepository {
  @override
  Future<List<Account>> getAccounts({bool includeArchived = false}) async => [
    _bitcoinAccount,
    _euroAccount,
    _dollarAccount,
  ];

  @override
  Stream<List<Account>> watchAccounts({bool includeArchived = false}) =>
      const Stream.empty();
}

final _bitcoinAccount = Account(
  id: 'a3',
  name: 'BTC',
  balance: 0,
  currencyCode: 'EUR',
  currencyDesignationId: 'eur',
  accountTypeId: 'asset',
  assetId: 'btc',
  creationDate: DateTime(2025, 1, 1),
);

class _FakeSettingsRepository extends Fake implements SettingsRepository {
  @override
  Future<Settings?> getSetting(String key) async => null;
}

class _FakeAssetRepository extends Fake implements AssetRepository {}

const _usd = Currency(
  name: 'US Dollar',
  code: 'USD',
  languageCode: 'en',
  type: TypeCurrency.currency,
);

const _eur = Currency(
  name: 'Euro',
  code: 'EUR',
  languageCode: 'en',
  type: TypeCurrency.currency,
);

final _euroAccount = Account(
  id: 'a1',
  name: 'Wallet',
  balance: 0,
  currencyCode: 'EUR',
  currencyDesignationId: 'eur',
  accountTypeId: 'cash',
  creationDate: DateTime(2025, 1, 1),
);

final _dollarAccount = Account(
  id: 'a2',
  name: 'Savings',
  balance: 0,
  currencyCode: 'USD',
  currencyDesignationId: 'usd',
  accountTypeId: 'cash',
  creationDate: DateTime(2025, 1, 1),
);

final _preset1 = ExchangeRateDomain(
  fromCurrencyCode: 'USD',
  toCurrencyCode: 'EUR',
  rate: 0.9,
  date: DateTime(2025, 3, 15),
  preset: 1,
);

/// 1000 USD leaving the dollar account for the euro one. In transfer mode the
/// currency field is locked to the From account's currency, so
/// `selectedCurrency` is USD and the pair really is cross-currency.
AddEditTransactionState _seedTransfer({
  String manualExchangeRate = '',
  bool isRateInputInverted = false,
  String amount = '1000',
  Transaction? initialTransaction,
  ExchangeRateDomain? selectedExchangeRate,
}) => AddEditTransactionState(
  selectedAccount: _dollarAccount,
  linkedAccount: _euroAccount,
  selectedCurrency: _usd,
  isTransferMode: true,
  amount: amount,
  date: DateTime(2025, 3, 15),
  manualExchangeRate: manualExchangeRate,
  isRateInputInverted: isRateInputInverted,
  initialTransaction: initialTransaction,
  selectedExchangeRate: selectedExchangeRate,
  mainCurrencyCode: 'EUR',
);

Transaction _sentLeg({double amount = -1000, String? linkedTransactionId}) =>
    Transaction(
      id: 't1',
      description: 'Transfer to Wallet',
      amount: amount,
      date: DateTime(2025, 3, 15),
      accountId: _dollarAccount.id!,
      categoryId: 'transfer-cat',
      currencyCode: 'USD',
      linkedTransactionId: linkedTransactionId,
    );

void main() {
  late _RecordingTransactionRepository transactionRepository;
  late _FakeCurrencyRepository currencyRepository;

  AddEditTransactionBloc build() {
    currencyRepository = _FakeCurrencyRepository()
      ..ratesByPair['USD->EUR'] = [_preset1];
    transactionRepository = _RecordingTransactionRepository();
    return AddEditTransactionBloc(
      transactionRepository: transactionRepository,
      accountRepository: _FakeAccountRepository(),
      categoryRepository: _FakeCategoryRepository(),
      currencyRepository: currencyRepository,
      settingsRepository: _FakeSettingsRepository(),
      assetRepository: _FakeAssetRepository(),
    );
  }

  group('the rate a transfer was made at', () {
    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'is written onto both legs, not left to be divided back out of the '
      'amounts later',
      build: build,
      seed: () => _seedTransfer(manualExchangeRate: '0.9'),
      act: (bloc) => bloc.add(const AddEditTransactionSubmitted()),
      verify: (_) {
        expect(transactionRepository.added, hasLength(2));
        final sent = transactionRepository.added.firstWhere(
          (t) => t.accountId == _dollarAccount.id,
        );
        final received = transactionRepository.added.firstWhere(
          (t) => t.accountId == _euroAccount.id,
        );

        // The two legs still say what they always said...
        expect(sent.amount, -1000);
        expect(received.amount, closeTo(900, 1e-9));
        // ...and now they also say what turned one into the other.
        expect(sent.exchangeRate, closeTo(0.9, 1e-9));
        expect(received.exchangeRate, closeTo(0.9, 1e-9));
      },
    );

    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'carries the preset the rate came from, so the row can still be traced '
      'to the stored rate it used',
      build: build,
      seed: () => _seedTransfer(
        manualExchangeRate: '0.9',
        selectedExchangeRate: _preset1,
      ),
      act: (bloc) => bloc.add(const AddEditTransactionSubmitted()),
      verify: (_) {
        expect(transactionRepository.added, hasLength(2));
        for (final leg in transactionRepository.added) {
          expect(leg.exchangeRatePreset, 1);
        }
      },
    );

    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'is read back off the row when the transfer is reopened, instead of '
      'being re-derived from amounts that may since have changed',
      build: build,
      act: (bloc) async {
        // A transfer already on disk whose amounts do NOT imply its rate: the
        // sent leg was later corrected to 500 while the received leg still
        // holds the 900 it arrived as. Dividing gives 1.8; the rate actually
        // used, and recorded, was 0.9.
        final sent = Transaction(
          id: 't1',
          description: 'Transfer to Wallet',
          amount: -500,
          date: DateTime(2025, 3, 15),
          accountId: _dollarAccount.id!,
          categoryId: 'transfer-cat',
          currencyCode: 'USD',
          exchangeRate: 0.9,
          linkedTransactionId: 't2',
        );
        await transactionRepository.addTransaction(sent);
        await transactionRepository.addTransaction(
          Transaction(
            id: 't2',
            description: 'Transfer from Savings',
            amount: 900,
            date: DateTime(2025, 3, 15),
            accountId: _euroAccount.id!,
            categoryId: 'transfer-cat',
            currencyCode: 'EUR',
            exchangeRate: 0.9,
            linkedTransactionId: 't1',
          ),
        );
        transactionRepository.added.clear();

        bloc.add(AddEditTransactionLoad(transaction: sent));
        await Future<void>.delayed(Duration.zero);
      },
      verify: (bloc) {
        expect(bloc.state.manualExchangeRate, '0.9');
      },
    );

    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'is still recovered by division for the transfers saved before it was '
      'recorded, so their history does not come back blank',
      build: build,
      act: (bloc) async {
        // No `exchangeRate` on either row: this is what the old save wrote.
        final sent = Transaction(
          id: 't1',
          description: 'Transfer to Wallet',
          amount: -1000,
          date: DateTime(2025, 3, 15),
          accountId: _dollarAccount.id!,
          categoryId: 'transfer-cat',
          currencyCode: 'USD',
          linkedTransactionId: 't2',
        );
        await transactionRepository.addTransaction(sent);
        await transactionRepository.addTransaction(
          Transaction(
            id: 't2',
            description: 'Transfer from Savings',
            amount: 900,
            date: DateTime(2025, 3, 15),
            accountId: _euroAccount.id!,
            categoryId: 'transfer-cat',
            currencyCode: 'EUR',
            linkedTransactionId: 't1',
          ),
        );
        bloc.add(AddEditTransactionLoad(transaction: sent));
        await Future<void>.delayed(Duration.zero);
      },
      verify: (bloc) {
        expect(double.parse(bloc.state.manualExchangeRate), closeTo(0.9, 1e-9));
      },
    );
  });

  group('the direction toggle', () {
    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'is applied exactly once: an inverted field holding 1.25 converts at '
      '0.8, not at 1.25 and not at 1.5625',
      build: build,
      // The user flipped the field to read EUR->USD and typed 1.25 there. The
      // rate that converts the transfer is its reciprocal, 0.8.
      seed: () =>
          _seedTransfer(manualExchangeRate: '1.25', isRateInputInverted: true),
      act: (bloc) => bloc.add(const AddEditTransactionSubmitted()),
      verify: (_) {
        final received = transactionRepository.added.firstWhere(
          (t) => t.accountId == _euroAccount.id,
        );
        expect(received.amount, closeTo(800, 1e-9));
        expect(received.exchangeRate, closeTo(0.8, 1e-9));
      },
    );
  });

  group('the second leg of a transfer being edited', () {
    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'is inserted when the edited row has no linked leg, rather than being '
      'updated into a row that does not exist',
      build: build,
      // The row being edited is a transfer leg that lost its partner - or
      // never had one. There is nothing for the receiving side to update.
      seed: () => _seedTransfer(
        manualExchangeRate: '0.9',
        initialTransaction: _sentLeg(),
      ),
      act: (bloc) async {
        // The source leg exists on disk; the receiving one does not.
        await transactionRepository.addTransaction(_sentLeg());
        transactionRepository.added.clear();
        bloc.add(const AddEditTransactionSubmitted());
      },
      verify: (_) {
        // The receiving leg reached the write path as an insert...
        expect(transactionRepository.added, hasLength(1));
        final received = transactionRepository.added.single;
        expect(received.accountId, _euroAccount.id);
        expect(received.amount, closeTo(900, 1e-9));

        // ...and the money is actually somewhere: 1000 left one account and
        // 900 arrived in the other. Before, only the departure was recorded.
        expect(transactionRepository.rows[received.id!], isNotNull);
        expect(transactionRepository.rows['t1']!.amount, -1000);

        // The two rows point at each other, so deleting or reopening either
        // finds the other.
        expect(
          transactionRepository.rows['t1']!.linkedTransactionId,
          received.id,
        );
        expect(received.linkedTransactionId, 't1');
      },
    );

    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'is updated in place when the edited row does name a linked leg',
      build: build,
      seed: () => _seedTransfer(
        amount: '2000',
        manualExchangeRate: '0.9',
        initialTransaction: _sentLeg(linkedTransactionId: 't2'),
      ),
      act: (bloc) async {
        await transactionRepository.addTransaction(
          _sentLeg(linkedTransactionId: 't2'),
        );
        await transactionRepository.addTransaction(
          Transaction(
            id: 't2',
            description: 'Transfer from Savings',
            amount: 900,
            date: DateTime(2025, 3, 15),
            accountId: _euroAccount.id!,
            categoryId: 'transfer-cat',
            currencyCode: 'EUR',
            linkedTransactionId: 't1',
          ),
        );
        transactionRepository.added.clear();
        bloc.add(const AddEditTransactionSubmitted());
      },
      verify: (_) {
        // No new rows: the pair that existed is the pair that remains.
        expect(transactionRepository.added, isEmpty);
        expect(transactionRepository.updated, hasLength(2));
        expect(transactionRepository.rows, hasLength(2));
        expect(transactionRepository.rows['t1']!.amount, -2000);
        expect(transactionRepository.rows['t2']!.amount, closeTo(1800, 1e-9));
      },
    );
  });

  group('the descriptions a transfer writes for the user', () {
    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'are the localized ones when the screen supplies them',
      build: build,
      seed: () => _seedTransfer(manualExchangeRate: '0.9'),
      act: (bloc) => bloc.add(
        // What the screen passes after filling in `l10n.transferToDescription`
        // and `transferFromDescription` with the account names - here in
        // Russian, the shape any non-English locale produces.
        const AddEditTransactionSubmitted(
          transferToDescription: 'Перевод на Wallet',
          transferFromDescription: 'Перевод с Savings',
        ),
      ),
      verify: (_) {
        final sent = transactionRepository.added.firstWhere(
          (t) => t.accountId == _dollarAccount.id,
        );
        final received = transactionRepository.added.firstWhere(
          (t) => t.accountId == _euroAccount.id,
        );
        expect(sent.description, 'Перевод на Wallet');
        expect(received.description, 'Перевод с Savings');
      },
    );

    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'fall back to the English wording when no localizations are offered, so '
      'a caller without a BuildContext still writes what it always wrote',
      build: build,
      seed: () => _seedTransfer(manualExchangeRate: '0.9'),
      act: (bloc) => bloc.add(const AddEditTransactionSubmitted()),
      verify: (_) {
        final sent = transactionRepository.added.firstWhere(
          (t) => t.accountId == _dollarAccount.id,
        );
        final received = transactionRepository.added.firstWhere(
          (t) => t.accountId == _euroAccount.id,
        );
        expect(sent.description, 'Transfer to Wallet');
        expect(received.description, 'Transfer from Savings');
      },
    );

    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'leave the description the user typed alone on the leg they typed it for',
      build: build,
      seed: () => _seedTransfer(
        manualExchangeRate: '0.9',
      ).copyWith(description: 'Rent'),
      act: (bloc) => bloc.add(
        const AddEditTransactionSubmitted(
          transferToDescription: 'Перевод на Wallet',
          transferFromDescription: 'Перевод с Savings',
        ),
      ),
      verify: (_) {
        final sent = transactionRepository.added.firstWhere(
          (t) => t.accountId == _dollarAccount.id,
        );
        expect(sent.description, 'Rent');
      },
    );
  });
  group('stating what arrived instead of the rate', () {
    // A bank statement gives two amounts and no rate. Dividing one by the
    // other was left to the user, and the form's only input was the quotient.
    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'the arriving amount is stored as the rate it implies',
      build: build,
      seed: () => _seedTransfer(amount: '1000'),
      act: (bloc) =>
          bloc.add(const AddEditTransactionReceivedAmountChanged('900')),
      verify: (bloc) {
        expect(bloc.state.manualExchangeRate, '0.9');
        // The save reads `manualExchangeRate` raw and only inverts it when
        // this flag is set, so a rate derived From-to-To has to clear it - or
        // 1000 USD would arrive as 1111.11 EUR.
        expect(bloc.state.isRateInputInverted, isFalse);
      },
    );

    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'and it is the rate the save actually converts at',
      build: build,
      seed: () => _seedTransfer(amount: '1000'),
      act: (bloc) async {
        bloc.add(const AddEditTransactionReceivedAmountChanged('900'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const AddEditTransactionSubmitted());
      },
      verify: (_) {
        final received = transactionRepository.added.firstWhere(
          (t) => t.accountId == _euroAccount.id,
        );
        expect(received.amount, closeTo(900, 1e-9));
      },
    );

    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'typing over a preset drops the preset rather than keeping both',
      build: build,
      // A preset is selected, so the rate came from the list. Overtyping the
      // arriving amount contradicts it, and leaving the preset selected would
      // leave the chip lit next to a rate it does not name.
      seed: () => _seedTransfer(
        amount: '1000',
        manualExchangeRate: '0.85',
        selectedExchangeRate: _preset1,
      ),
      act: (bloc) =>
          bloc.add(const AddEditTransactionReceivedAmountChanged('900')),
      verify: (bloc) {
        expect(bloc.state.manualExchangeRate, '0.9');
        expect(bloc.state.selectedExchangeRate, isNull);
      },
    );

    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'an arriving amount with nothing sent yet changes no rate',
      build: build,
      // Zero would divide to infinity and an empty amount parses to nothing.
      // Either would overwrite a rate the user may have already chosen.
      seed: () => _seedTransfer(amount: '', manualExchangeRate: '0.85'),
      act: (bloc) =>
          bloc.add(const AddEditTransactionReceivedAmountChanged('900')),
      verify: (bloc) => expect(bloc.state.manualExchangeRate, '0.85'),
    );

    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'a half-typed arriving amount changes no rate either',
      build: build,
      seed: () => _seedTransfer(amount: '1000', manualExchangeRate: '0.85'),
      // What the field holds between the dot and the first decimal digit.
      act: (bloc) =>
          bloc.add(const AddEditTransactionReceivedAmountChanged('.')),
      verify: (bloc) => expect(bloc.state.manualExchangeRate, '0.85'),
    );

    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'a rate too small to write in plain decimals is still written in plain '
      'decimals',
      build: build,
      // 1 IDR is some 3.4e-9 BTC. `toString` reaches for the exponent at this
      // magnitude, and `double.tryParse` in the save reads it back fine - but
      // the user is shown, and asked to edit, "3.4222877778838255e-9".
      seed: () => _seedTransfer(amount: '1000000000'),
      act: (bloc) =>
          bloc.add(const AddEditTransactionReceivedAmountChanged('3.42')),
      verify: (bloc) {
        expect(bloc.state.manualExchangeRate, isNot(contains('e')));
        expect(
          double.parse(bloc.state.manualExchangeRate),
          closeTo(3.42e-9, 1e-20),
        );
      },
    );
  });

  group('opening a transfer from an account row', () {
    AddEditTransactionBloc buildWithAssetFirst() {
      currencyRepository = _FakeCurrencyRepository()
        ..ratesByPair['USD->EUR'] = [_preset1];
      transactionRepository = _RecordingTransactionRepository();
      return AddEditTransactionBloc(
        transactionRepository: transactionRepository,
        accountRepository: _AssetFirstAccountRepository(),
        categoryRepository: _FakeCategoryRepository(),
        currencyRepository: currencyRepository,
        settingsRepository: _FakeSettingsRepository(),
        assetRepository: _FakeAssetRepository(),
      );
    }

    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'puts the account the row belongs to on the From side, not the To side',
      build: buildWithAssetFirst,
      // "Transfer" on the euro account. It used to be installed as the
      // destination with some other account picked as the source, so the one
      // account the user had named was the one they had not chosen a role for,
      // and the money left an account they never pointed at.
      act: (bloc) => bloc.add(
        AddEditTransactionLoad(accountId: _euroAccount.id, isTransfer: true),
      ),
      verify: (bloc) {
        final state = bloc.state;
        expect(state.selectedAccount?.id, _euroAccount.id);
        // The only other account money can move between, so it is not a guess.
        expect(state.linkedAccount?.id, _dollarAccount.id);
        expect(state.isTransferMode, isTrue);
      },
    );

    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'does not pick an asset account as the source, which would drop the '
      'form out of transfer mode for good',
      build: buildWithAssetFirst,
      // Asked to transfer out of the bitcoin account, which holds a quantity
      // rather than a balance. The menu no longer offers this, but a route can
      // still be opened with any id.
      act: (bloc) => bloc.add(
        AddEditTransactionLoad(accountId: _bitcoinAccount.id, isTransfer: true),
      ),
      verify: (bloc) {
        final state = bloc.state;
        expect(state.selectedAccount?.assetId, isNull);
        expect(state.selectedAccount?.id, _euroAccount.id);
        expect(state.linkedAccount?.id, _dollarAccount.id);
        // The one that matters. `isTransferMode` is written only here, in
        // `_onLoad`, so a false at this point can never be corrected: the user
        // asked to transfer and would have been handed the asset Buy/Sell
        // form, and saving from it wrote a single unlinked row.
        expect(state.isTransferMode, isTrue);
        expect(state.isAssetTransaction, isFalse);
      },
    );
  });

  group('reopening a saved transfer', () {
    /// A transfer made at 116.0 while today's Preset 1 says 117.4 - the gap
    /// the app must not close on its own.
    AddEditTransactionBloc buildWithStoredTransfer() {
      currencyRepository = _FakeCurrencyRepository()
        ..ratesByPair['USD->EUR'] = [
          ExchangeRateDomain(
            fromCurrencyCode: 'USD',
            toCurrencyCode: 'EUR',
            rate: 117.4,
            date: DateTime(2025, 3, 15),
            preset: 1,
          ),
        ];
      transactionRepository = _RecordingTransactionRepository();
      final sent = Transaction(
        id: 't1',
        description: 'Transfer to Wallet',
        amount: -1000,
        date: DateTime(2025, 3, 15),
        accountId: _dollarAccount.id!,
        categoryId: 'transfer-cat',
        currencyCode: 'USD',
        exchangeRate: 116.0,
        linkedTransactionId: 't2',
      );
      final received = Transaction(
        id: 't2',
        description: 'Transfer from Savings',
        amount: 116000,
        date: DateTime(2025, 3, 15),
        accountId: _euroAccount.id!,
        categoryId: 'transfer-cat',
        currencyCode: 'EUR',
        exchangeRate: 116.0,
        linkedTransactionId: 't1',
      );
      transactionRepository.rows['t1'] = sent;
      transactionRepository.rows['t2'] = received;
      return AddEditTransactionBloc(
        transactionRepository: transactionRepository,
        accountRepository: _FakeAccountRepository(),
        categoryRepository: _FakeCategoryRepository(),
        currencyRepository: currencyRepository,
        settingsRepository: _FakeSettingsRepository(),
        assetRepository: _FakeAssetRepository(),
      );
    }

    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'keeps the rate it was made at instead of resyncing to the rate on file '
      'today',
      build: buildWithStoredTransfer,
      act: (bloc) => bloc.add(
        AddEditTransactionLoad(transaction: transactionRepository.rows['t1']),
      ),
      verify: (bloc) {
        // The load ends with a refetch, and the refetch keeps the field in
        // step with Preset 1 whenever the two disagree. For a form being
        // filled in that is right; here it would have replaced 116.0 with
        // 117.4, and `_onSubmitted` reads this field verbatim - so reopening
        // the transfer, changing nothing and pressing Save moved ~1.2% of it.
        expect(double.parse(bloc.state.manualExchangeRate), closeTo(116, 1e-9));
        expect(bloc.state.manualRateIsHistorical, isTrue);
      },
    );

    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'still lets the user type a different rate over it',
      build: buildWithStoredTransfer,
      act: (bloc) async {
        bloc.add(
          AddEditTransactionLoad(transaction: transactionRepository.rows['t1']),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(const AddEditTransactionManualRateChanged('118'));
      },
      verify: (bloc) {
        expect(bloc.state.manualExchangeRate, '118');
        expect(bloc.state.manualRateIsHistorical, isFalse);
      },
    );

    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'shows the sent amount as a number the user could have typed',
      build: buildWithStoredTransfer,
      act: (bloc) => bloc.add(
        AddEditTransactionLoad(transaction: transactionRepository.rows['t1']),
      ),
      verify: (bloc) {
        // The stored row is -1000: the sign is the app's, recomputed on every
        // save from which leg is being written. The Amount field denies '-'
        // outright, so seeding it signed put a character in the field that the
        // user could not have produced and could not meaningfully remove - and
        // the converted-amount preview parsed the same string and announced a
        // negative arriving balance.
        expect(double.parse(bloc.state.amount), 1000);
        expect(bloc.state.amount.startsWith('-'), isFalse);
      },
    );
  });

  group('what an asset buy writes down', () {
    // The same defect as the transfer wording, one branch over: an asset buy
    // writes two rows the user never describes - the asset leg and the cash
    // leg that pays for it - and both were hardcoded English while
    // `buyDescription`, `sellDescription` and `assetTransferDescription` sat
    // translated and unused in every .arb file. The screen fills the templates
    // in (a bloc has no BuildContext to reach l10n with) and the bloc falls
    // back to the old English wording for callers that pass nothing.
    AddEditTransactionState seedAssetBuy() => AddEditTransactionState(
      selectedAccount: _bitcoinAccount,
      linkedAccount: _euroAccount,
      selectedCurrency: _eur,
      amount: '2',
      totalValue: '1000',
      date: DateTime(2025, 3, 15),
      mainCurrencyCode: 'EUR',
    );

    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'describes both legs in the words the screen handed it',
      build: build,
      seed: seedAssetBuy,
      act: (bloc) => bloc.add(
        const AddEditTransactionSubmitted(
          assetDescription: 'Покупка BTC',
          assetTransferDescription: 'Перевод за покупку BTC',
        ),
      ),
      verify: (_) {
        expect(transactionRepository.added, hasLength(2));
        final assetLeg = transactionRepository.added.firstWhere(
          (t) => t.accountId == _bitcoinAccount.id,
        );
        final cashLeg = transactionRepository.added.firstWhere(
          (t) => t.accountId == _euroAccount.id,
        );
        expect(assetLeg.description, 'Покупка BTC');
        expect(cashLeg.description, 'Перевод за покупку BTC');
      },
    );

    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'keeps the English wording for a caller that offers none',
      build: build,
      seed: seedAssetBuy,
      act: (bloc) => bloc.add(const AddEditTransactionSubmitted()),
      verify: (_) {
        final assetLeg = transactionRepository.added.firstWhere(
          (t) => t.accountId == _bitcoinAccount.id,
        );
        expect(assetLeg.description, 'Buy BTC');
      },
    );

    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'still lets a description the user typed win over both',
      build: build,
      seed: () => seedAssetBuy().copyWith(description: 'Rent money'),
      act: (bloc) => bloc.add(
        const AddEditTransactionSubmitted(assetDescription: 'Покупка BTC'),
      ),
      verify: (_) {
        final assetLeg = transactionRepository.added.firstWhere(
          (t) => t.accountId == _bitcoinAccount.id,
        );
        expect(assetLeg.description, 'Rent money');
      },
    );
  });
}
