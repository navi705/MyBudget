import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/currency_designation.dart';
import 'package:my_budget_client/domain/entities/style.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/domain/repositories/style_repository.dart';
import 'package:my_budget_client/presentation/blocs/currency/currency_bloc.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';

/// Pins the Emitter lifecycle of the two watch-a-stream blocs.
///
/// Both used to call `emit(...Failure())` from the `onError` of a subscription
/// opened inside their load handler. That error arrives long after the handler
/// returned, so the Emitter it captured is already completed: the emit threw
/// `StateError: Emitter is already completed` out of a stream callback (an
/// unhandled async error) and the failure state was unreachable.
///
/// Each test therefore asserts BOTH halves — the failure state is observed, and
/// nothing escapes into the zone's error handler.
class _FakeStyleRepository extends Fake implements StyleRepository {
  _FakeStyleRepository(this.styles);

  final Stream<List<Style>> styles;

  @override
  Stream<List<Style>> watchAllStyles() => styles;
}

class _FakeCurrencyRepository extends Fake implements CurrencyRepository {
  _FakeCurrencyRepository(this.currencies, this.designations);

  final Stream<List<Currency>> currencies;
  final Stream<List<CurrencyDesignation>> designations;

  @override
  Stream<List<Currency>> watchCurrencies() => currencies;

  @override
  Stream<List<CurrencyDesignation>> watchAllCurrencyDesignations() =>
      designations;
}

void main() {
  group('StylesBloc stream errors', () {
    test('emits StylesLoadFailure without escaping a StateError', () async {
      final controller = StreamController<List<Style>>();
      final states = <StylesState>[];
      final zoneErrors = <Object>[];

      await runZonedGuarded(() async {
        final bloc = StylesBloc(
          styleRepository: _FakeStyleRepository(controller.stream),
        );
        final sub = bloc.stream.listen(states.add);

        bloc.add(LoadStyles());
        controller.add(<Style>[]);
        await pumpEventQueue();

        // Reaching a success state proves the load handler has returned and its
        // Emitter is completed — the precise condition the old onError hit.
        controller.addError(Exception('watch failed'));
        await pumpEventQueue();

        await sub.cancel();
        await bloc.close();
      }, (error, stack) => zoneErrors.add(error));

      expect(
        zoneErrors,
        isEmpty,
        reason: 'the stream error must not blow up inside the callback',
      );
      expect(
        states.map((s) => s.runtimeType),
        containsAllInOrder([
          StylesLoadInProgress,
          StylesLoadSuccess,
          StylesLoadFailure,
        ]),
      );

      await controller.close();
    });

    test(
      'close() cancels the watch before shutting the event controller',
      () async {
        final controller = StreamController<List<Style>>();
        final zoneErrors = <Object>[];

        await runZonedGuarded(() async {
          final bloc = StylesBloc(
            styleRepository: _FakeStyleRepository(controller.stream),
          );
          bloc.add(LoadStyles());
          controller.add(<Style>[]);
          await pumpEventQueue();

          await bloc.close();
          // Without an awaited cancel this list would reach the listener and be
          // add()-ed to a closed bloc, which throws.
          controller.add(<Style>[]);
          await pumpEventQueue();
        }, (error, stack) => zoneErrors.add(error));

        expect(zoneErrors, isEmpty);

        await controller.close();
      },
    );
  });

  group('CurrencyBloc stream errors', () {
    const currency = Currency(
      name: 'Euro',
      code: 'EUR',
      languageCode: 'en',
      type: TypeCurrency.currency,
    );

    test('emits CurrencyLoadFailure without escaping a StateError', () async {
      final currencies = StreamController<List<Currency>>();
      final designations = StreamController<List<CurrencyDesignation>>();
      final states = <CurrencyState>[];
      final zoneErrors = <Object>[];

      await runZonedGuarded(() async {
        final bloc = CurrencyBloc(
          currencyRepository: _FakeCurrencyRepository(
            currencies.stream,
            designations.stream,
          ),
        );
        final sub = bloc.stream.listen(states.add);

        bloc.add(LoadCurrencies());
        currencies.add(const [currency]);
        designations.add(const <CurrencyDesignation>[]);
        await pumpEventQueue();

        currencies.addError(Exception('watch failed'));
        await pumpEventQueue();

        await sub.cancel();
        await bloc.close();
      }, (error, stack) => zoneErrors.add(error));

      expect(
        zoneErrors,
        isEmpty,
        reason: 'the stream error must not blow up inside the callback',
      );
      expect(
        states.map((s) => s.runtimeType),
        containsAllInOrder([
          CurrencyLoadInProgress,
          CurrencyLoadSuccess,
          CurrencyLoadFailure,
        ]),
      );
      // Dispatching now happens in onData, not in the combineLatest2 combiner —
      // the success state still has to carry the combined payload.
      final success = states.whereType<CurrencyLoadSuccess>().first;
      expect(success.currencies, const [currency]);

      await currencies.close();
      await designations.close();
    });

    test(
      'close() cancels the combined watch before shutting the bloc',
      () async {
        final currencies = StreamController<List<Currency>>();
        final designations = StreamController<List<CurrencyDesignation>>();
        final zoneErrors = <Object>[];

        await runZonedGuarded(() async {
          final bloc = CurrencyBloc(
            currencyRepository: _FakeCurrencyRepository(
              currencies.stream,
              designations.stream,
            ),
          );
          bloc.add(LoadCurrencies());
          currencies.add(const [currency]);
          designations.add(const <CurrencyDesignation>[]);
          await pumpEventQueue();

          await bloc.close();
          currencies.add(const [currency]);
          await pumpEventQueue();
        }, (error, stack) => zoneErrors.add(error));

        expect(zoneErrors, isEmpty);

        await currencies.close();
        await designations.close();
      },
    );
  });
}
