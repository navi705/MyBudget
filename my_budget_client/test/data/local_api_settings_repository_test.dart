import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/data/repositories/local_db/local_api_settings_repository.dart';
import 'package:my_budget_client/domain/entities/api_setting.dart';

/// One row per built-in provider ("exchange_rates", "inflation", "assets")
/// holding whether it is enabled, whether it auto-fetches and when it last ran.
/// The table has no isDeleted column, so the things worth pinning are the
/// replace-on-save semantics, the epoch-millisecond conversion of lastFetchAt,
/// and the sync bookkeeping.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LocalApiSettingsRepository repo;

  setUpAll(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalApiSettingsRepository(db.apiSettingsDao);
  });

  tearDownAll(() async => db.close());

  setUp(() async {
    await db.delete(db.apiSettingsTable).go();
    await db.delete(db.syncLog).go();
  });

  Future<List<SyncLogData>> logs() =>
      (db.select(db.syncLog)
            ..where((l) => l.changedTableName.equals('api_settings_table')))
          .get();

  Future<ApiSettingsTableData?> rowFor(String id) =>
      (db.select(db.apiSettingsTable)..where((s) => s.id.equals(id)))
          .getSingleOrNull();

  test('a setting round-trips its id, flags and last fetch time', () async {
    await repo.saveSetting(
      ApiSettingDomain(
        id: 'exchange_rates',
        enabled: false,
        autoFetch: true,
        lastFetchAt: DateTime(2024, 5, 5, 12, 30),
      ),
    );

    final read = await repo.getSettingById('exchange_rates');

    expect(read!.id, 'exchange_rates');
    expect(read.enabled, isFalse);
    expect(read.autoFetch, isTrue);
    expect(read.lastFetchAt, DateTime(2024, 5, 5, 12, 30));
  });

  test('a setting that has never fetched round-trips a null lastFetchAt, not '
      'the epoch', () async {
    // The settings screen shows "never" for null; a 1970 date would show as a
    // real past fetch and suppress the "fetch now" prompt.
    await repo.saveSetting(const ApiSettingDomain(id: 'inflation'));

    expect((await repo.getSettingById('inflation'))!.lastFetchAt, isNull);
  });

  test('lastFetchAt keeps millisecond precision', () async {
    final stamp = DateTime.fromMillisecondsSinceEpoch(1715000000123);

    await repo.saveSetting(
      ApiSettingDomain(id: 'assets', lastFetchAt: stamp),
    );

    expect((await repo.getSettingById('assets'))!.lastFetchAt, stamp);
  });

  test('the domain defaults are enabled and no auto-fetch', () async {
    await repo.saveSetting(const ApiSettingDomain(id: 'inflation'));

    final read = await repo.getSettingById('inflation');
    expect(read!.enabled, isTrue);
    expect(read.autoFetch, isFalse);
  });

  test('getSettingById returns null for a provider that was never '
      'saved', () async {
    expect(await repo.getSettingById('nope'), isNull);
  });

  test('getAllSettings returns every provider row', () async {
    await repo.saveSetting(const ApiSettingDomain(id: 'exchange_rates'));
    await repo.saveSetting(const ApiSettingDomain(id: 'inflation'));

    expect(await repo.getAllSettings(), hasLength(2));
  });

  test('getAllSettings is empty when nothing has been saved', () async {
    expect(await repo.getAllSettings(), isEmpty);
  });

  test('saving the same provider twice replaces the row instead of '
      'duplicating it', () async {
    await repo.saveSetting(const ApiSettingDomain(id: 'inflation'));
    await repo.saveSetting(
      const ApiSettingDomain(id: 'inflation', enabled: false),
    );

    final all = await repo.getAllSettings();
    expect(all, hasLength(1));
    expect(all.single.enabled, isFalse);
  });

  test('saving with a null lastFetchAt clears the stored fetch time', () async {
    // Worth pinning: the write is a full row replace, so a caller that builds
    // the domain object from scratch instead of copyWith wipes the timestamp.
    await repo.saveSetting(
      ApiSettingDomain(id: 'assets', lastFetchAt: DateTime(2024, 1, 1)),
    );

    await repo.saveSetting(const ApiSettingDomain(id: 'assets'));

    expect((await repo.getSettingById('assets'))!.lastFetchAt, isNull);
  });

  test('saving stamps modifiedAt so the change wins the next sync', () async {
    final before = DateTime.now().millisecondsSinceEpoch;

    await repo.saveSetting(const ApiSettingDomain(id: 'inflation'));

    expect(
      (await rowFor('inflation'))!.modifiedAt,
      greaterThanOrEqualTo(before),
    );
  });

  test('saving appends one upsert to sync_log under the api_settings_table '
      'name', () async {
    // The name has to match `_tableNameToId` in sync_service_io.dart, which
    // looks for exactly 'api_settings_table'; any other spelling is dropped
    // silently by the sender.
    await repo.saveSetting(const ApiSettingDomain(id: 'inflation'));

    final logged = await logs();
    expect(logged.single.recordId, 'inflation');
    expect(logged.single.action, 'upsert');
    expect(logged.single.timestamp, greaterThan(0));
  });

  test('each save logs again, so a toggle after a sync is not lost', () async {
    await repo.saveSetting(const ApiSettingDomain(id: 'inflation'));
    await repo.saveSetting(
      const ApiSettingDomain(id: 'inflation', enabled: false),
    );

    expect(await logs(), hasLength(2));
  });
}
