// _fetchRates resolved `selectedRate` from the freshly fetched rate list and
// passed it straight to `copyWith` as `selectedExchangeRate`/
// `editingExchangeRate`. copyWith reads a null argument as "no change", so
// switching to a currency pair with no stored rate at all - no direct rate,
// no reversed rate, no rate derivable through a pivot currency - left both
// fields holding the PREVIOUS pair's rate. The preset chips vanished (they
// come from `availableExchangeRates`, which correctly went empty) while the
// Update/Delete buttons stayed on screen, gated on `editingExchangeRate`,
// silently wired to a different currency pair's stored rate.
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

/// Serves whatever `_fetchRates` asks for by exact from/to pair, and nothing
/// else - a pair with no entry here is exactly "no stored rate", which is
/// the scenario under test.
///
/// Everything unimplemented on the other fakes is left that way on purpose:
/// a call the handlers were not meant to make should fail loudly instead of
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

/// A form filled in far enough for the rate section to be live: the account
/// is in EUR, the main currency is EUR (so the triangular pivot attempts
/// through EUR are skipped as "pivot == target"), and no currency has been
/// picked yet - the test picks one via the real event.
AddEditTransactionState _seed() => AddEditTransactionState(
  selectedAccount: _euroAccount,
  date: DateTime(2025, 3, 15),
  mainCurrencyCode: 'EUR',
);

void main() {
  late _FakeCurrencyRepository currencyRepository;

  AddEditTransactionBloc build() {
    currencyRepository = _FakeCurrencyRepository()
      ..ratesByPair['USD->EUR'] = [_preset1, _preset2];
    return AddEditTransactionBloc(
      transactionRepository: _FakeTransactionRepository(),
      accountRepository: _FakeAccountRepository(),
      categoryRepository: _FakeCategoryRepository(),
      currencyRepository: currencyRepository,
      settingsRepository: _FakeSettingsRepository(),
      assetRepository: _FakeAssetRepository(),
    );
  }

  blocTest<AddEditTransactionBloc, AddEditTransactionState>(
    'switching to a currency pair with no stored rate at all clears the '
    'selected and editing rate rather than carrying over the previous '
    "pair's",
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

      // 3. Switch to a currency pair with no rate anywhere: no direct rate,
      // no reversed rate, no rate derivable through a pivot currency.
      bloc.add(const AddEditTransactionCurrencyChanged(_jpy));
    },
    verify: (bloc) {
      expect(bloc.state.availableExchangeRates, isEmpty);
      expect(bloc.state.selectedExchangeRate, isNull);
      expect(bloc.state.editingExchangeRate, isNull);
    },
  );
}
