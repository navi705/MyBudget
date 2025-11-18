import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/currency_designation.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/presentation/blocs/currency/currency_bloc.dart';

import 'currency_bloc_test.mocks.dart';

@GenerateMocks([CurrencyRepository])
void main() {
  group('CurrencyBloc', () {
    late MockCurrencyRepository mockCurrencyRepository;
    late CurrencyBloc currencyBloc;

    setUp(() {
      mockCurrencyRepository = MockCurrencyRepository();
      currencyBloc = CurrencyBloc(currencyRepository: mockCurrencyRepository);
    });

    tearDown(() {
      currencyBloc.close();
    });

    final tCurrencyDesignation =
        const CurrencyDesignation(id: 1, value: '\$', currencyId: 1);
    final tCurrencyDesignation2 =
        const CurrencyDesignation(id: 2, value: '€', currencyId: 2);
    final tCurrencyDesignation3 =
        const CurrencyDesignation(id: 3, value: '₽', currencyId: 3);
    final tCurrencyDesignationList = [
      tCurrencyDesignation,
      tCurrencyDesignation2,
      tCurrencyDesignation3,
    ];

    final tCurrency = const Currency(
      id: 1,
      name: 'US Dollar',
      code: 'USD',
    );
    final tCurrency2 = const Currency(
      id: 2,
      name: 'Euro',
      code: 'EUR',
    );
    final tCurrencyList = [tCurrency, tCurrency2];


    blocTest<CurrencyBloc, CurrencyState>(
      'emits [CurrencyLoadInProgress, CurrencyLoadSuccess] when LoadCurrencies is added and repository returns data',
      build: () {
        when(mockCurrencyRepository.watchCurrencies())
            .thenAnswer((_) => Stream.value(tCurrencyList));
        when(mockCurrencyRepository.watchAllCurrencyDesignations())
            .thenAnswer((_) => Stream.value(tCurrencyDesignationList));
        return currencyBloc;
      },
      act: (bloc) => bloc.add(LoadCurrencies()),
      expect: () => [
        CurrencyLoadInProgress(),
        CurrencyLoadSuccess(
            currencies: tCurrencyList, designations: tCurrencyDesignationList),
      ],
      verify: (_) {
        verify(mockCurrencyRepository.watchCurrencies()).called(1);
        verify(mockCurrencyRepository.watchAllCurrencyDesignations()).called(1);
      },
    );

    blocTest<CurrencyBloc, CurrencyState>(
      'emits [CurrencyLoadInProgress, CurrencyLoadSuccess] with empty lists when LoadCurrencies is added and repository returns empty data',
      build: () {
        when(mockCurrencyRepository.watchCurrencies())
            .thenAnswer((_) => Stream.value([]));
        when(mockCurrencyRepository.watchAllCurrencyDesignations())
            .thenAnswer((_) => Stream.value([]));
        return currencyBloc;
      },
      act: (bloc) => bloc.add(LoadCurrencies()),
      expect: () => [
        CurrencyLoadInProgress(),
        const CurrencyLoadSuccess(currencies: [], designations: []),
      ],
      verify: (_) {
        verify(mockCurrencyRepository.watchCurrencies()).called(1);
        verify(mockCurrencyRepository.watchAllCurrencyDesignations()).called(1);
      },
    );

    blocTest<CurrencyBloc, CurrencyState>(
      'emits [CurrencyLoadInProgress, CurrencyLoadFailure] when LoadCurrencies is added and repository throws an error',
      build: () {
        when(mockCurrencyRepository.watchCurrencies())
            .thenAnswer((_) => Stream.error('Error'));
        when(mockCurrencyRepository.watchAllCurrencyDesignations())
            .thenAnswer((_) => Stream.value(tCurrencyDesignationList));
        return currencyBloc;
      },
      act: (bloc) => bloc.add(LoadCurrencies()),
      expect: () => [
        CurrencyLoadInProgress(),
        CurrencyLoadFailure(),
      ],
      verify: (_) {
        verify(mockCurrencyRepository.watchCurrencies()).called(1);
        verify(mockCurrencyRepository.watchAllCurrencyDesignations()).called(1);
      },
    );
  });
}
