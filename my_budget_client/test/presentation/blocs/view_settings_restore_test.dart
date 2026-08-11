import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart' show AppDatabase;
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/data/repositories/local_db/local_asset_repository.dart';
import 'package:my_budget_client/data/repositories/local_db/local_inflation_repository.dart';
import 'package:my_budget_client/data/repositories/local_db/local_settings_repository.dart';
import 'package:my_budget_client/presentation/blocs/asset/asset_bloc.dart';
import 'package:my_budget_client/presentation/blocs/asset/asset_event.dart';
import 'package:my_budget_client/presentation/blocs/asset/asset_state.dart';
import 'package:my_budget_client/presentation/blocs/inflation/inflation_bloc.dart';

/// Regression net for "my saved view settings never stick".
///
/// Both AssetBloc and InflationBloc emitted `status: loading` *before* checking
/// `state.status == initial` to decide whether to restore the persisted
/// date-step / filter-mode. The check could therefore never be true and every
/// restore was silently dropped, so these tests assert on the EMITTED state
/// rather than on the settings table: reading the setting back proves nothing,
/// only a state carrying it does.
///
/// Runs against a real in-memory database through the real Local* repositories
/// (same setup as accounts_bloc_load_characterization_test.dart) so the
/// settings round-trip through drift exactly as it does in the app.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LocalSettingsRepository settingsRepository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    settingsRepository = LocalSettingsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  AssetBloc buildAssetBloc() =>
      AssetBloc(LocalAssetRepository(db.assetEntriesDao), settingsRepository);

  InflationBloc buildInflationBloc() => InflationBloc(
    inflationRepository: LocalInflationRepository(db.inflationRatesDao),
    settingsRepository: settingsRepository,
  );

  group('AssetBloc persisted view settings', () {
    test('LoadAssetData emits a state carrying the persisted settings',
        () async {
      // Both differ from AssetState's defaults (month / date), so a passing
      // assertion can only come from the restore path.
      await settingsRepository.saveSetting(
        'asset_date_step',
        DateStep.year.toString(),
      );
      await settingsRepository.saveSetting(
        'asset_filter_mode',
        FilterMode.range.toString(),
      );

      final bloc = buildAssetBloc();
      bloc.add(const LoadAssetData());

      final restored = await bloc.stream
          .firstWhere((s) => s.status == AssetStatus.success)
          .timeout(const Duration(seconds: 10));

      expect(restored.dateStep, DateStep.year);
      expect(restored.filterMode, FilterMode.range);

      await bloc.close();
    });

    test('a second load keeps the in-session choice over the persisted one',
        () async {
      await settingsRepository.saveSetting(
        'asset_date_step',
        DateStep.year.toString(),
      );

      final bloc = buildAssetBloc();
      bloc.add(const LoadAssetData());
      await bloc.stream
          .firstWhere((s) => s.status == AssetStatus.success)
          .timeout(const Duration(seconds: 10));

      // The user picks day; reloading must not snap back to the stored year.
      bloc.add(const ChangeAssetDateStep(DateStep.day));
      await bloc.stream
          .firstWhere((s) => s.dateStep == DateStep.day)
          .timeout(const Duration(seconds: 10));

      bloc.add(const LoadAssetData());
      await pumpEventQueue();
      expect(bloc.state.dateStep, DateStep.day);

      await bloc.close();
    });
  });

  group('InflationBloc persisted view settings', () {
    test('LoadInflationRates emits a state carrying the persisted settings',
        () async {
      // InflationBloc seeds its initial state with DateStep.year, so day is the
      // value that can only appear via the restore.
      await settingsRepository.saveSetting(
        'inflation_date_step',
        DateStep.day.toString(),
      );
      await settingsRepository.saveSetting(
        'inflation_filter_mode',
        FilterMode.range.toString(),
      );

      final bloc = buildInflationBloc();
      bloc.add(LoadInflationRates());

      final restored = await bloc.stream
          .firstWhere((s) => s.status == InflationStatus.success)
          .timeout(const Duration(seconds: 10));

      expect(restored.dateStep, DateStep.day);
      expect(restored.filterMode, FilterMode.range);

      await bloc.close();
    });

    test('ChangeInflationDateStep emits the new step', () async {
      final bloc = buildInflationBloc();
      bloc.add(LoadInflationRates());
      await bloc.stream
          .firstWhere((s) => s.status == InflationStatus.success)
          .timeout(const Duration(seconds: 10));

      // Used to only saveSetting() + reload; because the reload ignores
      // persisted settings after the first load, changing the step produced no
      // state change whatsoever.
      bloc.add(const ChangeInflationDateStep(DateStep.month));

      final changed = await bloc.stream
          .firstWhere((s) => s.dateStep == DateStep.month)
          .timeout(const Duration(seconds: 10));

      expect(changed.dateStep, DateStep.month);

      await bloc.close();
    });

    test('ChangeInflationFilterMode emits the new mode', () async {
      final bloc = buildInflationBloc();
      bloc.add(LoadInflationRates());
      await bloc.stream
          .firstWhere((s) => s.status == InflationStatus.success)
          .timeout(const Duration(seconds: 10));

      bloc.add(const ChangeInflationFilterMode(FilterMode.range));

      final changed = await bloc.stream
          .firstWhere((s) => s.filterMode == FilterMode.range)
          .timeout(const Duration(seconds: 10));

      expect(changed.filterMode, FilterMode.range);

      await bloc.close();
    });
  });
}
