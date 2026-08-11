import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/currency_designation.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/presentation/blocs/exchange_rates/exchange_rates_bloc.dart';

/// Pins the reporting of failed exchange-rate mutations.
///
/// The regression: every mutation handler caught its error into
/// `state.error` but left `status` untouched, and the only widget that reads
/// `error` is gated on `status == failure`. So an add/edit/delete that threw
/// closed its dialog over an unchanged list and told the user nothing - the
/// rate looked saved. Nothing about that is visible from the widget tree,
/// which is why it is pinned here at the bloc.
class _ThrowingCurrencyRepository extends Fake implements CurrencyRepository {
  _ThrowingCurrencyRepository({this.rates = const []});

  /// What a load returns. Mutations always throw.
  final List<ExchangeRateDomain> rates;

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
  }) async => rates;

  @override
  Future<int> getExchangeRatesCount({
    DateTime? startDate,
    DateTime? endDate,
    String? fromCurrency,
    String? toCurrency,
    List<int>? presets,
  }) async => rates.length;

  @override
  Future<List<Currency>> getCurrencies() async => const [];

  @override
  Future<List<CurrencyDesignation>> getAllCurrencyDesignations() async =>
      const [];

  @override
  Future<void> addExchangeRate(ExchangeRateDomain exchangeRate) async =>
      throw Exception('write failed');

  @override
  Future<void> replaceExchangeRate(
    ExchangeRateDomain original,
    ExchangeRateDomain updated,
  ) async => throw Exception('write failed');

  @override
  Future<void> deleteExchangeRates(List<ExchangeRateDomain> rates) async =>
      throw Exception('write failed');

  @override
  Future<void> updateExchangeRatePresets(
    List<ExchangeRateDomain> rates,
    int newPreset,
  ) async => throw Exception('write failed');
}

ExchangeRateDomain _rate({double value = 1.5, int preset = 1}) =>
    ExchangeRateDomain(
      fromCurrencyCode: 'USD',
      toCurrencyCode: 'RSD',
      preset: preset,
      rate: value,
      date: DateTime(2025, 3),
    );

/// Waits for the state that satisfies [test], or fails the test on timeout.
///
/// A mutation handler emits its failure and only then dispatches
/// `LoadExchangeRates`, so the failure is never the last state - it cannot be
/// asserted by reading `bloc.state` after an `await`.
Future<ExchangeRatesState> _firstStateWhere(
  ExchangeRatesBloc bloc,
  bool Function(ExchangeRatesState) test,
) => bloc.stream.firstWhere(test).timeout(const Duration(seconds: 5));

void main() {
  group('a failed exchange rate mutation reaches the UI', () {
    late _ThrowingCurrencyRepository repository;
    late ExchangeRatesBloc bloc;

    setUp(() {
      repository = _ThrowingCurrencyRepository(rates: [_rate()]);
      bloc = ExchangeRatesBloc(currencyRepository: repository);
    });

    tearDown(() => bloc.close());

    test('add marks the state failed, not just sets an error string', () async {
      final failed = _firstStateWhere(
        bloc,
        (s) => s.status == ExchangeRatesStatus.failure,
      );

      bloc.add(AddExchangeRate(_rate()));

      final state = await failed;
      expect(state.error, contains('write failed'));
    });

    test('edit marks the state failed', () async {
      final failed = _firstStateWhere(
        bloc,
        (s) => s.status == ExchangeRatesStatus.failure,
      );

      bloc.add(
        UpdateExchangeRate(
          originalExchangeRate: _rate(),
          updatedExchangeRate: _rate(value: 2),
        ),
      );

      expect((await failed).error, contains('write failed'));
    });

    test('bulk delete marks the state failed', () async {
      bloc.add(ToggleExchangeRateSelection(_rate()));
      await bloc.stream.firstWhere((s) => s.selectedExchangeRates.isNotEmpty);

      final failed = _firstStateWhere(
        bloc,
        (s) => s.status == ExchangeRatesStatus.failure,
      );
      bloc.add(const DeleteSelectedExchangeRates());

      expect((await failed).error, contains('write failed'));
    });

    test('bulk preset change marks the state failed', () async {
      bloc.add(ToggleExchangeRateSelection(_rate()));
      await bloc.stream.firstWhere((s) => s.selectedExchangeRates.isNotEmpty);

      final failed = _firstStateWhere(
        bloc,
        (s) => s.status == ExchangeRatesStatus.failure,
      );
      bloc.add(const UpdateSelectedExchangeRatesPreset(2));

      expect((await failed).error, contains('write failed'));
    });

    test('a later successful load clears the error it left behind', () async {
      final failed = _firstStateWhere(
        bloc,
        (s) => s.status == ExchangeRatesStatus.failure,
      );
      bloc.add(AddExchangeRate(_rate()));
      await failed;

      // The reload a mutation handler queues sits after its await, so a throw
      // skips it and the failure state is where the bloc stays. Recovery only
      // comes from the next load the screen asks for.
      final recovering = _firstStateWhere(
        bloc,
        (s) => s.status == ExchangeRatesStatus.success,
      );
      bloc.add(const LoadExchangeRates(isRefresh: true));
      final recovered = await recovering;

      expect(
        recovered.error,
        isNull,
        reason: 'a stale message would be reported again as if it were new',
      );
      expect(recovered.exchangeRates, hasLength(1));
    });
  });
}
