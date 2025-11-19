import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/presentation/blocs/currency_converter/currency_converter_bloc.dart';
import 'package:my_budget_client/core/database/app_database.dart' as db;


import 'currency_converter_bloc_test.mocks.dart';

@GenerateMocks([
  CurrencyRepository,
  AccountRepository,
  SettingsRepository,
])
void main() {
  late MockCurrencyRepository mockCurrencyRepository;
  late MockAccountRepository mockAccountRepository;
  late MockSettingsRepository mockSettingsRepository;
  late CurrencyConverterBloc currencyConverterBloc;

  setUp(() {
    mockCurrencyRepository = MockCurrencyRepository();
    mockAccountRepository = MockAccountRepository();
    mockSettingsRepository = MockSettingsRepository();

    // Mock the streams
    when(mockCurrencyRepository.watchCurrencies())
        .thenAnswer((_) => Stream.value(const [
              Currency(id: 1, name: 'US Dollar', code: 'USD'),
              Currency(id: 2, name: 'Euro', code: 'EUR'),
            ]));
    when(mockCurrencyRepository.watchAllExchangeRates())
        .thenAnswer((_) => Stream.value([
              ExchangeRate(
                  fromCurrencyId: 1,
                  toCurrencyId: 2,
                  rate: 0.9,
                  date: DateTime.now()),
            ]));
    when(mockAccountRepository.watchAccounts())
        .thenAnswer((_) => Stream.value(const [
              Account(
                id: 1,
                name: 'Account 1',
                balance: 100,
                currencyId: 1,
                currencyDesignationId: 1,
                accountTypeId: 1,
              ),
              Account(
                id: 2,
                name: 'Account 2',
                balance: 50,
                currencyId: 2,
                currencyDesignationId: 2,
                accountTypeId: 1,
              ),
            ]));
    when(mockSettingsRepository.watchSetting('conversion_base_currency_id'))
        .thenAnswer((_) => Stream.value(const db.Setting(
            key: 'conversion_base_currency_id', value: '1')));
    
    currencyConverterBloc = CurrencyConverterBloc(
      currencyRepository: mockCurrencyRepository,
      accountRepository: mockAccountRepository,
      settingsRepository: mockSettingsRepository,
    );
  });
  
  tearDown(() {
    currencyConverterBloc.close();
  });

  blocTest<CurrencyConverterBloc, CurrencyConverterState>(
    'emits [CurrencyConverterLoadSuccess] with correct total balance when LoadCurrencyConverter is added.',
    build: () => currencyConverterBloc,
    act: (bloc) => bloc.add(LoadCurrencyConverter()),
    wait: const Duration(milliseconds: 100), // wait for streams to emit
    expect: () => [
      isA<CurrencyConverterLoadInProgress>(),
      isA<CurrencyConverterLoadSuccess>().having(
        (state) => state.totalBalanceFor(const Currency(id: 2, name: 'Euro', code: 'EUR')),
        'total balance for EUR',
        140.0, // 100 USD * 0.9 = 90 EUR + 50 EUR = 140 EUR
      ),
    ],
  );
}
