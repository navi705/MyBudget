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

    final tCurrencyDesignation = CurrencyDesignation(id: 1, value: '\$');
    final tCurrency = Currency(
      id: 1,
      name: 'US Dollar',
      code: 'USD',
      designation: tCurrencyDesignation,
    );
    final tCurrencyList = [tCurrency];

    blocTest<CurrencyBloc, CurrencyState>(
      'emits [CurrencyLoadInProgress, CurrencyLoadSuccess] when LoadCurrencies is added and repository returns data',
      build: () {
        when(mockCurrencyRepository.watchCurrencies())
            .thenAnswer((_) => Stream.value(tCurrencyList));
        return currencyBloc;
      },
      act: (bloc) => bloc.add(LoadCurrencies()),
      expect: () => [
        CurrencyLoadInProgress(),
        CurrencyLoadSuccess(tCurrencyList),
      ],
      verify: (_) {
        verify(mockCurrencyRepository.watchCurrencies()).called(1);
      },
    );

    blocTest<CurrencyBloc, CurrencyState>(
      'emits [CurrencyLoadInProgress, CurrencyLoadSuccess] with empty list when LoadCurrencies is added and repository returns empty data',
      build: () {
        when(mockCurrencyRepository.watchCurrencies())
            .thenAnswer((_) => Stream.value([]));
        return currencyBloc;
      },
      act: (bloc) => bloc.add(LoadCurrencies()),
      expect: () => [
        CurrencyLoadInProgress(),
        const CurrencyLoadSuccess([]),
      ],
      verify: (_) {
        verify(mockCurrencyRepository.watchCurrencies()).called(1);
      },
    );

    blocTest<CurrencyBloc, CurrencyState>(
      'emits [CurrencyLoadInProgress, CurrencyLoadFailure] when LoadCurrencies is added and repository throws an error',
      build: () {
        when(mockCurrencyRepository.watchCurrencies())
            .thenAnswer((_) => Stream.error('Error'));
        return currencyBloc;
      },
      act: (bloc) => bloc.add(LoadCurrencies()),
      expect: () => [
        CurrencyLoadInProgress(),
        CurrencyLoadFailure(),
      ],
      verify: (_) {
        verify(mockCurrencyRepository.watchCurrencies()).called(1);
      },
    );
  });
}
