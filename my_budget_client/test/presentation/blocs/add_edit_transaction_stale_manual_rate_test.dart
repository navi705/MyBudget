// `_fetchRates` resynced the rate field from the freshly resolved preset, but
// only when a preset was resolved at all: `if (shouldUpdateManualRate &&
// selectedRate != null)`. A currency pair with no stored rate anywhere - no
// direct rate, no reversed rate, no rate derivable through a pivot currency -
// resolves nothing, so the field kept the PREVIOUS pair's number and presented
// it as the rate for the new one.
//
// It is not cosmetic. `_onSubmitted` reads `manualExchangeRate` verbatim as the
// rate to convert at, and nothing checks which pair it came from, so 1000 units
// were converted at a leftover 0.0024 and saved that way.
//
// Blanking the field is only half of it, and the interesting half is what Save
// then does with an empty one:
//
//   - Standard transactions are fine, deliberately. The row is written with the
//     foreign currency code and a null rate, and `adjustBalance` counts a row
//     only against an account of the same currency - so it is recorded in full
//     and simply not counted until it is restated. That is the codebase's
//     stated policy (SmsBloc spells it out and names this handler as its
//     reference), and it is what makes typing a rate for a rateless pair
//     optional rather than mandatory.
//   - Transfers are not. Both legs are written in their own accounts'
//     currencies, so both are counted, and the receiving leg falls back to
//     `amount.abs()` unmultiplied: 1000 leaves the USD account and 1000 arrives
//     in the EUR one. Each leg agrees with the account it lands on, so nothing
//     downstream can catch it - net worth just grows by the spread.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/constants/app_constants.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/domain/repositories/asset_repository.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/presentation/blocs/add_edit_transaction/add_edit_transaction_bloc.dart';

/// Serves whatever `_fetchRates` asks for by exact from/to pair, and nothing
/// else - a pair with no entry here is exactly "no stored rate", which is the
/// scenario under test.
///
/// Everything unimplemented on the other fakes is left that way on purpose: a
/// call the handlers were not meant to make should fail loudly instead of
/// quietly returning a default that would change what the test proves.
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
}

/// Records what actually reached the write path, so a save that was supposed to
/// be refused can be told apart from one that was merely not asserted on.
class _RecordingTransactionRepository extends Fake
    implements TransactionRepository {
  final List<Transaction> added = [];

  @override
  Future<void> addTransaction(Transaction transaction) async {
    added.add(transaction);
  }

  @override
  Stream<void> watchTransactionChanges() => const Stream.empty();
}

/// Holds the system transfer category `_onSubmitted` resolves for a transfer,
/// so the handler reaches the rate check instead of failing earlier.
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
  Stream<List<Account>> watchAccounts() => const Stream.empty();
}

class _FakeSettingsRepository extends Fake implements SettingsRepository {}

class _FakeAssetRepository extends Fake implements AssetRepository {}

const _usd = Currency(
  name: 'US Dollar',
  code: 'USD',
  languageCode: 'en',
  type: TypeCurrency.currency,
);

// No rate connects this to EUR directly, in reverse, or through EUR/USD as a
// pivot (it IS one of the pivots the bloc tries, and the main currency, so
// there is nothing left to derive it from).
const _jpy = Currency(
  name: 'Japanese Yen',
  code: 'JPY',
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

final _preset2 = ExchangeRateDomain(
  fromCurrencyCode: 'USD',
  toCurrencyCode: 'EUR',
  rate: 0.95,
  date: DateTime(2025, 3, 15),
  preset: 2,
);

final _expenseCategory = Category(
  id: 'c1',
  name: 'Groceries',
  type: CategoryType.expense,
);

const _enterExchangeRateMessage = 'Please enter an exchange rate';

/// A form filled in far enough for the rate section to be live: the account is
/// in EUR, the main currency is EUR (so the triangular pivot attempts through
/// EUR are skipped as "pivot == target"), and no currency has been picked yet -
/// the test picks one via the real event.
AddEditTransactionState _seed() => AddEditTransactionState(
  selectedAccount: _euroAccount,
  date: DateTime(2025, 3, 15),
  mainCurrencyCode: 'EUR',
);

/// A saveable cross-currency transfer: 1000 leaves the USD account, and the
/// EUR account is the other leg. The currency field is locked to the From
/// account's currency in transfer mode, so `selectedCurrency` is USD.
AddEditTransactionState _seedTransfer({String manualExchangeRate = ''}) =>
    AddEditTransactionState(
      selectedAccount: _dollarAccount,
      linkedAccount: _euroAccount,
      selectedCurrency: _usd,
      isTransferMode: true,
      amount: '1000',
      date: DateTime(2025, 3, 15),
      manualExchangeRate: manualExchangeRate,
      mainCurrencyCode: 'EUR',
    );

/// A saveable ordinary expense of 1000 USD on the EUR account.
AddEditTransactionState _seedStandard() => AddEditTransactionState(
  selectedAccount: _euroAccount,
  selectedCurrency: _usd,
  selectedCategory: _expenseCategory,
  amount: '1000',
  date: DateTime(2025, 3, 15),
  mainCurrencyCode: 'EUR',
);

void main() {
  late _FakeCurrencyRepository currencyRepository;
  late _RecordingTransactionRepository transactionRepository;

  AddEditTransactionBloc build() {
    currencyRepository = _FakeCurrencyRepository()
      ..ratesByPair['USD->EUR'] = [_preset1, _preset2];
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

  group('the rate field when the pair changes', () {
    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'switching to a currency pair with no stored rate at all empties the '
      "rate field rather than leaving the previous pair's number in it",
      build: build,
      seed: _seed,
      act: (bloc) async {
        // 1. Pick USD, which has rates against the EUR account: this is the
        // real path _fetchRates runs through, not a hand-built state.
        bloc.add(const AddEditTransactionCurrencyChanged(_usd));
        await Future<void>.delayed(Duration.zero);

        // 2. Pick a non-preset-1 rate - the one whose staleness would be
        // easiest to miss, since it is not the value _fetchRates defaults to.
        bloc.add(AddEditTransactionRatePresetChanged(_preset2));
        await Future<void>.delayed(Duration.zero);

        // Sanity: the field really is holding a number to go stale.
        expect(bloc.state.manualExchangeRate, '0.95');

        // 3. Switch to a currency pair with no rate anywhere: no direct rate,
        // no reversed rate, no rate derivable through a pivot currency.
        bloc.add(const AddEditTransactionCurrencyChanged(_jpy));
      },
      verify: (bloc) {
        // Sanity: this really is the rateless pair, not a failed fetch.
        expect(bloc.state.availableExchangeRates, isEmpty);
        expect(bloc.state.isLoadingRates, isFalse);

        expect(bloc.state.manualExchangeRate, isEmpty);
      },
    );

    // The other half: emptying must not become "every refresh wipes the
    // field", or a pair that does have rates would lose its preset sync.
    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'a pair that does have rates still fills the field from its preset',
      build: build,
      seed: _seed,
      act: (bloc) async {
        bloc.add(const AddEditTransactionCurrencyChanged(_usd));
        await Future<void>.delayed(Duration.zero);
      },
      verify: (bloc) {
        expect(bloc.state.availableExchangeRates, [_preset1, _preset2]);
        expect(bloc.state.selectedExchangeRate, _preset1);
        expect(bloc.state.manualExchangeRate, '0.9');
      },
    );

    // A pair with no stored rate is exactly when typing one by hand is the
    // right thing to do, so emptying the field must not amount to forbidding
    // it - and the typed rate has to survive a refresh that did not change the
    // pair, which is what a date change is.
    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'a rate typed by hand for a rateless pair stands, and survives a date '
      'change',
      build: build,
      seed: _seed,
      act: (bloc) async {
        bloc.add(const AddEditTransactionCurrencyChanged(_jpy));
        await Future<void>.delayed(Duration.zero);

        // Sanity: the field started empty, so what is in it below is the
        // typed value and not a leftover.
        expect(bloc.state.manualExchangeRate, isEmpty);

        bloc.add(const AddEditTransactionManualRateChanged('0.0062'));
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state.manualExchangeRate, '0.0062');

        bloc.add(AddEditTransactionDateChanged(DateTime(2025, 3, 16)));
        await Future<void>.delayed(Duration.zero);
      },
      verify: (bloc) {
        expect(bloc.state.date, DateTime(2025, 3, 16));
        // Still no rates on file for this pair on the new date either.
        expect(bloc.state.availableExchangeRates, isEmpty);

        expect(bloc.state.manualExchangeRate, '0.0062');
      },
    );

    // The inversion toggle rewrites the same field, and it is the one place a
    // rate typed for a rateless pair gets touched without a refetch.
    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'flipping the rate direction still inverts a hand-typed rate on a '
      'rateless pair',
      build: build,
      seed: _seed,
      act: (bloc) async {
        bloc.add(const AddEditTransactionCurrencyChanged(_jpy));
        await Future<void>.delayed(Duration.zero);

        bloc.add(const AddEditTransactionManualRateChanged('0.008'));
        await Future<void>.delayed(Duration.zero);

        bloc.add(const AddEditTransactionToggleRateDirection());
        await Future<void>.delayed(Duration.zero);
      },
      verify: (bloc) {
        expect(bloc.state.isRateInputInverted, isTrue);
        expect(bloc.state.manualExchangeRate, (1.0 / 0.008).toString());
      },
    );
  });

  group('saving with an empty rate field', () {
    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'a cross-currency transfer with no rate is refused instead of moving '
      'the same number into an account of a different currency',
      build: build,
      seed: () => _seedTransfer(),
      act: (bloc) async {
        bloc.add(const AddEditTransactionSubmitted());
        await Future<void>.delayed(const Duration(milliseconds: 20));
      },
      verify: (bloc) {
        // Sanity: this is the shape the guard is about.
        expect(bloc.state.isTransferMode, isTrue);
        expect(bloc.state.isForeignCurrency, isTrue);

        expect(bloc.state.validationError, _enterExchangeRateMessage);
        expect(bloc.state.isSaving, isFalse);
        expect(bloc.state.isSaveSuccess, isFalse);
        // Neither leg was written: 1000 USD out and 1000 EUR in would have
        // balanced on paper while inventing the difference.
        expect(transactionRepository.added, isEmpty);
      },
    );

    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'a cross-currency transfer with a rate of zero is refused too',
      build: build,
      seed: () => _seedTransfer(manualExchangeRate: '0'),
      act: (bloc) async {
        bloc.add(const AddEditTransactionSubmitted());
        await Future<void>.delayed(const Duration(milliseconds: 20));
      },
      verify: (bloc) {
        // Zero parses, so a guard that only asks whether a rate is present
        // lets it through - and it is worse than the empty field it stands in
        // for: 1000 leaves the USD account and the receiving leg is
        // multiplied down to nothing.
        expect(bloc.state.validationError, _enterExchangeRateMessage);
        expect(bloc.state.isSaveSuccess, isFalse);
        expect(transactionRepository.added, isEmpty);
      },
    );

    // The guard must refuse only the transfer it cannot convert, not transfers
    // generally.
    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'a cross-currency transfer with a rate still saves, converted',
      build: build,
      seed: () => _seedTransfer(manualExchangeRate: '0.9'),
      act: (bloc) async {
        bloc.add(const AddEditTransactionSubmitted());
        await Future<void>.delayed(const Duration(milliseconds: 20));
      },
      verify: (bloc) {
        expect(bloc.state.validationError, isNull);
        expect(bloc.state.isSaveSuccess, isTrue);

        expect(transactionRepository.added, hasLength(2));
        final outgoing = transactionRepository.added[0];
        final incoming = transactionRepository.added[1];
        expect(outgoing.amount, -1000);
        expect(outgoing.currencyCode, 'USD');
        // The point of the rate: what arrives is not what left.
        expect(incoming.amount, 900);
        expect(incoming.currencyCode, 'EUR');
      },
    );

    // Deliberate, and the reason the empty field is not simply refused
    // everywhere: an ordinary foreign transaction is recorded truthfully in its
    // own currency with a null rate, and the balance layer declines to count it
    // until it is restated. Refusing it here would make a rate mandatory in the
    // one case where none is on file to supply.
    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'an ordinary foreign transaction with no rate is still recorded, in its '
      'own currency and with no rate attached',
      build: build,
      seed: _seedStandard,
      act: (bloc) async {
        bloc.add(const AddEditTransactionSubmitted());
        await Future<void>.delayed(const Duration(milliseconds: 20));
      },
      verify: (bloc) {
        // Sanity: foreign, but not a transfer.
        expect(bloc.state.isForeignCurrency, isTrue);
        expect(bloc.state.isTransferMode, isFalse);

        expect(bloc.state.validationError, isNull);
        expect(bloc.state.isSaveSuccess, isTrue);

        expect(transactionRepository.added, hasLength(1));
        final saved = transactionRepository.added.single;
        expect(saved.amount, -1000);
        expect(saved.currencyCode, 'USD');
        expect(saved.exchangeRate, isNull);
      },
    );
  });
}
