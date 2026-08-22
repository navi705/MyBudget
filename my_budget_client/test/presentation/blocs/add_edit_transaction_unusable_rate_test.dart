// Exchange rates the form accepts that no conversion can use.
//
// A rate is a multiplier, so zero and negatives are not rates: at 0 the
// receiving leg of a transfer is written for nothing and the money leaves the
// source account and arrives nowhere; at a negative rate the receiving leg is
// written negative too, so both accounts lose. The import path already refuses
// exactly these - `!rate.isFinite || rate <= 0` - but the rate a user types by
// hand reached the write with nothing checked beyond `double.tryParse`.
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

class _RecordingTransactionRepository extends Fake
    implements TransactionRepository {
  final List<Transaction> added = [];

  @override
  Future<void> addTransaction(Transaction transaction) async =>
      added.add(transaction);

  @override
  Stream<void> watchTransactionChanges() => const Stream.empty();
}

class _RecordingCurrencyRepository extends Fake implements CurrencyRepository {
  final List<ExchangeRateDomain> added = [];
  final List<ExchangeRateDomain> updated = [];

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
  }) async => [_preset1];

  @override
  Future<List<Currency>> getCurrencies() async => const [_usd, _eur];

  @override
  Future<void> addExchangeRate(ExchangeRateDomain rate) async =>
      added.add(rate);

  @override
  Future<void> updateExchangeRate(ExchangeRateDomain rate) async =>
      updated.add(rate);
}

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

/// 1000 USD leaving the dollar account for the euro one, at whatever rate the
/// user has typed.
AddEditTransactionState _seedTransfer(String manualExchangeRate) =>
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

void main() {
  late _RecordingTransactionRepository transactionRepository;
  late _RecordingCurrencyRepository currencyRepository;

  AddEditTransactionBloc build() {
    transactionRepository = _RecordingTransactionRepository();
    currencyRepository = _RecordingCurrencyRepository();
    return AddEditTransactionBloc(
      transactionRepository: transactionRepository,
      accountRepository: _FakeAccountRepository(),
      categoryRepository: _FakeCategoryRepository(),
      currencyRepository: currencyRepository,
      settingsRepository: _FakeSettingsRepository(),
      assetRepository: _FakeAssetRepository(),
    );
  }

  group('a rate that cannot convert anything is refused by the save', () {
    for (final rate in const ['0', '0.0', '-0.9', '-1']) {
      blocTest<AddEditTransactionBloc, AddEditTransactionState>(
        'a transfer at a rate of $rate writes nothing',
        build: build,
        seed: () => _seedTransfer(rate),
        act: (bloc) => bloc.add(const AddEditTransactionSubmitted()),
        verify: (bloc) {
          expect(
            transactionRepository.added,
            isEmpty,
            reason: 'neither leg may be written at a rate of $rate',
          );
          expect(bloc.state.validationError, isNotNull);
        },
      );
    }

    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'a transfer at an ordinary rate is still written',
      build: build,
      seed: () => _seedTransfer('0.9'),
      act: (bloc) => bloc.add(const AddEditTransactionSubmitted()),
      verify: (_) {
        expect(transactionRepository.added, hasLength(2));
        final received = transactionRepository.added.firstWhere(
          (t) => t.accountId == _euroAccount.id,
        );
        expect(received.amount, closeTo(900, 1e-9));
      },
    );
  });

  group('a rate that cannot convert anything is refused by the presets', () {
    for (final rate in const ['0', '-0.9']) {
      blocTest<AddEditTransactionBloc, AddEditTransactionState>(
        'saving $rate as a new preset stores nothing',
        build: build,
        seed: () => _seedTransfer(rate),
        act: (bloc) => bloc.add(const AddEditTransactionSaveRateAsDefault()),
        verify: (bloc) {
          expect(currencyRepository.added, isEmpty);
          expect(bloc.state.validationError, isNotNull);
        },
      );

      blocTest<AddEditTransactionBloc, AddEditTransactionState>(
        'overwriting a preset with $rate stores nothing',
        build: build,
        seed: () => _seedTransfer(rate),
        act: (bloc) => bloc.add(AddEditTransactionUpdatePreset(_preset1)),
        verify: (bloc) {
          expect(currencyRepository.updated, isEmpty);
          expect(bloc.state.validationError, isNotNull);
        },
      );
    }
  });
}
