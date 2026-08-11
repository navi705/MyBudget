// Typing a rate by hand is meant to take over from the preset chip: the number
// in the field is what the transaction is converted at, so the chip must stop
// claiming the conversion. `_onManualRateChanged` said as much - it passed
// `selectedExchangeRate: null` to copyWith - but copyWith read that as "leave
// it alone", so the chip stayed lit next to a rate it no longer described, and
// the saved row still carried that preset's number.
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

// Nothing here is implemented on purpose: editing the rate field is a local
// state change, so any repository call would mean the handler did something it
// was not asked to. Unimplemented, it fails loudly instead of returning a
// default that quietly changes what the test proves.
class _FakeTransactionRepository extends Fake implements TransactionRepository {}

class _FakeAccountRepository extends Fake implements AccountRepository {}

class _FakeCategoryRepository extends Fake implements CategoryRepository {}

class _FakeCurrencyRepository extends Fake implements CurrencyRepository {}

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

/// A form filled in far enough for the rate section to be live: the account is
/// in EUR and the transaction in USD, so `isForeignCurrency` holds.
/// Preset 1 is selected and its rate is in the field, which is where the form
/// starts once rates load.
AddEditTransactionState _seed({bool withSelection = true}) =>
    AddEditTransactionState(
      selectedAccount: _euroAccount,
      selectedCurrency: _usd,
      date: DateTime(2025, 3, 15),
      manualExchangeRate: '0.9',
      availableExchangeRates: [_preset1, _preset2],
      selectedExchangeRate: withSelection ? _preset1 : null,
      mainCurrencyCode: 'EUR',
    );

void main() {
  AddEditTransactionBloc build() => AddEditTransactionBloc(
    transactionRepository: _FakeTransactionRepository(),
    accountRepository: _FakeAccountRepository(),
    categoryRepository: _FakeCategoryRepository(),
    currencyRepository: _FakeCurrencyRepository(),
    settingsRepository: _FakeSettingsRepository(),
    assetRepository: _FakeAssetRepository(),
  );

  blocTest<AddEditTransactionBloc, AddEditTransactionState>(
    'a rate typed by hand deselects the preset chip that no longer describes it',
    build: build,
    seed: _seed,
    act: (bloc) => bloc.add(const AddEditTransactionManualRateChanged('1.25')),
    expect: () => [
      isA<AddEditTransactionState>()
          .having((s) => s.selectedExchangeRate, 'selectedExchangeRate', isNull)
          .having((s) => s.manualExchangeRate, 'manualExchangeRate', '1.25'),
    ],
  );

  blocTest<AddEditTransactionBloc, AddEditTransactionState>(
    'deselecting leaves the presets themselves on offer',
    build: build,
    seed: _seed,
    act: (bloc) => bloc.add(const AddEditTransactionManualRateChanged('1.25')),
    expect: () => [
      isA<AddEditTransactionState>().having(
        (s) => s.availableExchangeRates,
        'availableExchangeRates',
        [_preset1, _preset2],
      ),
    ],
  );

  blocTest<AddEditTransactionBloc, AddEditTransactionState>(
    'clearing the rate field also clears the selection rather than restoring it',
    build: build,
    seed: _seed,
    act: (bloc) => bloc.add(const AddEditTransactionManualRateChanged('')),
    expect: () => [
      isA<AddEditTransactionState>()
          .having((s) => s.selectedExchangeRate, 'selectedExchangeRate', isNull)
          .having((s) => s.manualExchangeRate, 'manualExchangeRate', ''),
    ],
  );

  // The other half of the flag: clearing must stay opt-in, or tapping a chip
  // would no longer select anything.
  blocTest<AddEditTransactionBloc, AddEditTransactionState>(
    'tapping a preset still selects it, and shows its rate in the field',
    build: build,
    seed: () => _seed(withSelection: false),
    act: (bloc) => bloc.add(AddEditTransactionRatePresetChanged(_preset2)),
    expect: () => [
      isA<AddEditTransactionState>()
          .having(
            (s) => s.selectedExchangeRate,
            'selectedExchangeRate',
            _preset2,
          )
          .having((s) => s.manualExchangeRate, 'manualExchangeRate', '0.95'),
    ],
  );

  // The event's rate is nullable; before the flag existed, a null one was
  // dropped the same way the manual-rate deselection was.
  blocTest<AddEditTransactionBloc, AddEditTransactionState>(
    'a preset change to no preset clears the selection',
    build: build,
    seed: _seed,
    act: (bloc) => bloc.add(const AddEditTransactionRatePresetChanged(null)),
    expect: () => [
      isA<AddEditTransactionState>()
          .having((s) => s.selectedExchangeRate, 'selectedExchangeRate', isNull)
          // No rate to show, so whatever the user had typed stands.
          .having((s) => s.manualExchangeRate, 'manualExchangeRate', '0.9'),
    ],
  );
}
