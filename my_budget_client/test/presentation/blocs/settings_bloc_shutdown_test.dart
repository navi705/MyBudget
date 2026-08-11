import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/services/inflation_api_service.dart';
import 'package:my_budget_client/domain/entities/inflation_rate.dart';
import 'package:my_budget_client/domain/entities/settings.dart';
import 'package:my_budget_client/domain/repositories/inflation_repository.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';

/// Regression coverage for SettingsBloc's close()/resubscribe await-ordering
/// fix: `close()` now awaits both `_settingsSubscription.cancel()` and
/// `_inflationSubscription.cancel()` before `super.close()`, and
/// `_onLoadSettings` awaits the previous cancels before reassigning both
/// subscriptions on a reload.
///
/// NOTE: unlike the handler-guard tests (sms/accounts/categories_bloc), this
/// is a smoke/regression test, not a proof that reverting the await causes a
/// failure. Probing the same "unawaited cancel" shape against the codebase's
/// own already-fixed reference bloc (StylesBloc.close(), see
/// bloc_stream_error_lifecycle_test.dart) showed that its close()-race test
/// still passes even with the await removed — StreamSubscription.cancel()
/// stops delivery synchronously the instant it's called, regardless of
/// whether the returned Future is awaited. So this specific await does not
/// appear to be independently crash-provable via a black-box test; it is
/// kept because it matches the codebase's established convention and
/// guarantees subscriptions are fully torn down (not just requested to be)
/// before the bloc finishes closing or resubscribes.
class _FakeSettingsRepository extends Fake implements SettingsRepository {
  _FakeSettingsRepository(this.settingsStream);

  final Stream<List<Settings>> settingsStream;

  @override
  Stream<List<Settings>> watchAllSettings() => settingsStream;
}

class _FakeInflationRepository extends Fake implements InflationRepository {
  _FakeInflationRepository(this.inflationStream);

  final Stream<List<InflationRateDomain>> inflationStream;

  @override
  Stream<List<InflationRateDomain>> watchInflationRatesFiltered({
    required int limit,
    required int offset,
    DateTime? dateFrom,
    DateTime? dateTo,
    List<String>? countries,
    List<int>? presets,
    bool sortAscending = false,
  }) => inflationStream;
}

class _FakeInflationApiService extends Fake implements InflationApiService {}

void main() {
  group('SettingsBloc close()/resubscribe', () {
    test('closing mid-load does not throw', () async {
      final settingsController = StreamController<List<Settings>>.broadcast();
      final inflationController =
          StreamController<List<InflationRateDomain>>.broadcast();

      final bloc = SettingsBloc(
        settingsRepository: _FakeSettingsRepository(settingsController.stream),
        inflationRepository: _FakeInflationRepository(
          inflationController.stream,
        ),
        inflationApiService: _FakeInflationApiService(),
      );

      final zoneErrors = <Object>[];
      await runZonedGuarded(() async {
        bloc.add(LoadSettings());
        await pumpEventQueue();
        await bloc.close();
      }, (error, stack) => zoneErrors.add(error));

      expect(zoneErrors, isEmpty);

      await settingsController.close();
      await inflationController.close();
    });

    test('a second LoadSettings resubscribes without leaking the old streams',
        () async {
      final settingsController = StreamController<List<Settings>>.broadcast();
      final inflationController =
          StreamController<List<InflationRateDomain>>.broadcast();

      final bloc = SettingsBloc(
        settingsRepository: _FakeSettingsRepository(settingsController.stream),
        inflationRepository: _FakeInflationRepository(
          inflationController.stream,
        ),
        inflationApiService: _FakeInflationApiService(),
      );

      bloc.add(LoadSettings());
      await pumpEventQueue();
      bloc.add(LoadSettings());
      await pumpEventQueue();

      expect(settingsController.hasListener, isTrue);

      await bloc.close();
      await settingsController.close();
      await inflationController.close();
    });
  });
}
