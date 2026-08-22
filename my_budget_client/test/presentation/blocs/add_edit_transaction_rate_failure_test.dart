// Every exchange-rate handler in AddEditTransactionBloc used to catch into a
// bare `emit(isLoadingRates: false)`. The spinner stopped and nothing else
// changed, so "save this rate as the default" failing looked exactly like it
// succeeding - and the next transaction was converted at the rate the user
// believed they had just replaced.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/domain/repositories/asset_repository.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/presentation/blocs/add_edit_transaction/add_edit_transaction_bloc.dart';
import 'package:my_budget_client/domain/entities/category.dart';

/// Fails every rate write, and records that it was asked.
///
/// Anything the handlers do not call stays unimplemented on purpose: a call
/// that was not meant to happen should fail loudly rather than return a
/// default that quietly changes what the test proves.
class _FailingCurrencyRepository extends Fake implements CurrencyRepository {
  _FailingCurrencyRepository(this.failure);

  final Object failure;
  final added = <ExchangeRateDomain>[];
  final updated = <ExchangeRateDomain>[];
  final deleted = <ExchangeRateDomain>[];

  @override
  Future<void> addExchangeRate(ExchangeRateDomain rate) async {
    added.add(rate);
    throw failure;
  }

  @override
  Future<void> updateExchangeRate(ExchangeRateDomain rate) async {
    updated.add(rate);
    throw failure;
  }

  @override
  Future<void> deleteExchangeRates(List<ExchangeRateDomain> rates) async {
    deleted.addAll(rates);
    throw failure;
  }
}

/// Takes the write and then fails the reload that follows it.
///
/// The refresh runs inside every rate handler, and its own catch was just as
/// bare: the rate was stored but the list on screen stayed as it was, with no
/// spinner and no message to say the two had parted ways.
class _UnreadableRatesRepository extends Fake implements CurrencyRepository {
  _UnreadableRatesRepository(this.failure);

  final Object failure;

  @override
  Future<void> addExchangeRate(ExchangeRateDomain rate) async {}

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
    throw failure;
  }
}

class _FakeTransactionRepository extends Fake
    implements TransactionRepository {
  @override
  Stream<void> watchTransactionChanges() => const Stream.empty();
}

class _FakeAccountRepository extends Fake implements AccountRepository {
  @override
  Stream<List<Account>> watchAccounts() => const Stream.empty();
}

class _FakeCategoryRepository extends Fake implements CategoryRepository {
  @override
  Stream<List<Category>> watchCategories({bool includeSystem = false}) =>
      const Stream.empty();
}

class _FakeSettingsRepository extends Fake implements SettingsRepository {}

class _FakeAssetRepository extends Fake implements AssetRepository {}

const _usd = Currency(
  name: 'US Dollar',
  code: 'USD',
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

final _existingRate = ExchangeRateDomain(
  fromCurrencyCode: 'USD',
  toCurrencyCode: 'EUR',
  rate: 0.9,
  date: DateTime(2025, 3, 15),
  preset: 1,
);

/// A form filled in far enough for the rate section to be live: the account is
/// in EUR and the transaction in USD, so `isForeignCurrency` holds.
AddEditTransactionState _seed({String manualExchangeRate = '2'}) =>
    AddEditTransactionState(
      selectedAccount: _euroAccount,
      selectedCurrency: _usd,
      date: DateTime(2025, 3, 15),
      manualExchangeRate: manualExchangeRate,
      availableExchangeRates: [_existingRate],
      mainCurrencyCode: 'EUR',
    );

void main() {
  late _FailingCurrencyRepository currencyRepository;

  final failure = Exception('database is locked');

  AddEditTransactionBloc buildWith(CurrencyRepository repository) =>
      AddEditTransactionBloc(
        transactionRepository: _FakeTransactionRepository(),
        accountRepository: _FakeAccountRepository(),
        categoryRepository: _FakeCategoryRepository(),
        currencyRepository: repository,
        settingsRepository: _FakeSettingsRepository(),
        assetRepository: _FakeAssetRepository(),
      );

  AddEditTransactionBloc build() {
    currencyRepository = _FailingCurrencyRepository(failure);
    return buildWith(currencyRepository);
  }

  Matcher reportsFailure() => isA<AddEditTransactionState>()
      .having(
        (s) => s.validationError,
        'validationError',
        contains('database is locked'),
      )
      .having((s) => s.isLoadingRates, 'isLoadingRates', isFalse);

  Matcher isLoading() => isA<AddEditTransactionState>()
      .having((s) => s.isLoadingRates, 'isLoadingRates', isTrue)
      .having((s) => s.validationError, 'validationError', isNull);

  Matcher reportsInvalidRate() => isA<AddEditTransactionState>()
      .having(
        (s) => s.validationError,
        'validationError',
        'Please enter a valid number',
      )
      .having((s) => s.isLoadingRates, 'isLoadingRates', isFalse);

  blocTest<AddEditTransactionBloc, AddEditTransactionState>(
    'a failed save-as-default reports the error instead of just stopping the '
    'spinner',
    build: build,
    seed: _seed,
    act: (bloc) => bloc.add(const AddEditTransactionSaveRateAsDefault()),
    expect: () => [isLoading(), reportsFailure()],
    verify: (_) => expect(currencyRepository.added.single.rate, 2),
  );

  blocTest<AddEditTransactionBloc, AddEditTransactionState>(
    'a failed new preset reports the error',
    build: build,
    seed: _seed,
    act: (bloc) => bloc.add(const AddEditTransactionAddNewRate()),
    expect: () => [isLoading(), reportsFailure()],
    // The existing rate is preset 1, so the new one has to be preset 2.
    verify: (_) => expect(currencyRepository.added.single.preset, 2),
  );

  blocTest<AddEditTransactionBloc, AddEditTransactionState>(
    'a failed preset update reports the error',
    build: build,
    seed: _seed,
    act: (bloc) => bloc.add(AddEditTransactionUpdatePreset(_existingRate)),
    expect: () => [isLoading(), reportsFailure()],
    verify: (_) => expect(currencyRepository.updated.single.rate, 2),
  );

  blocTest<AddEditTransactionBloc, AddEditTransactionState>(
    'a failed preset delete reports the error',
    build: build,
    seed: _seed,
    act: (bloc) => bloc.add(AddEditTransactionDeletePreset(_existingRate)),
    expect: () => [isLoading(), reportsFailure()],
    verify: (_) => expect(currencyRepository.deleted, [_existingRate]),
  );

  blocTest<AddEditTransactionBloc, AddEditTransactionState>(
    'a rate that is not a number is named rather than ignored',
    build: build,
    seed: () => _seed(manualExchangeRate: 'abc'),
    act: (bloc) => bloc.add(const AddEditTransactionAddNewRate()),
    expect: () => [isLoading(), reportsInvalidRate()],
    verify: (_) => expect(currencyRepository.added, isEmpty),
  );

  blocTest<AddEditTransactionBloc, AddEditTransactionState>(
    'updating a preset with an unreadable rate says so before any write',
    build: build,
    // This one returned before it ever set the spinner, so there was nothing
    // on screen at all - the button simply did nothing.
    seed: () => _seed(manualExchangeRate: 'abc'),
    act: (bloc) => bloc.add(AddEditTransactionUpdatePreset(_existingRate)),
    expect: () => [reportsInvalidRate()],
    verify: (_) => expect(currencyRepository.updated, isEmpty),
  );

  blocTest<AddEditTransactionBloc, AddEditTransactionState>(
    'a stored rate that cannot be read back is reported, not left to look '
    'like an unchanged list',
    build: () => buildWith(_UnreadableRatesRepository(failure)),
    seed: _seed,
    act: (bloc) => bloc.add(const AddEditTransactionAddNewRate()),
    expect: () => [isLoading(), reportsFailure()],
  );

  blocTest<AddEditTransactionBloc, AddEditTransactionState>(
    'the same failure twice is reported twice',
    build: build,
    seed: _seed,
    act: (bloc) => bloc
      ..add(const AddEditTransactionSaveRateAsDefault())
      ..add(const AddEditTransactionSaveRateAsDefault()),
    // The retry clears the message before it runs, so the second failure is a
    // new state rather than an equal one bloc would drop - and the screen,
    // which shows a message once per occurrence, sees the null in between.
    expect: () => [
      isLoading(),
      reportsFailure(),
      isLoading(),
      reportsFailure(),
    ],
    verify: (_) => expect(currencyRepository.added, hasLength(2)),
  );
}
