import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/data/repositories/local_db/local_custom_data_source_repository.dart';
import 'package:my_budget_client/domain/entities/custom_data_source.dart';

/// User-defined API endpoints. `saveDataSource` is a single entry point that
/// has to pick insert or update itself, so the split between those two paths -
/// and what each of them does to modifiedAt, sync_log and the soft-delete flag
/// - is the thing worth pinning.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LocalCustomDataSourceRepository repo;

  setUpAll(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalCustomDataSourceRepository(db.customDataSourcesDao);
  });

  tearDownAll(() async => db.close());

  setUp(() async {
    await db.delete(db.customDataSources).go();
    await db.delete(db.syncLog).go();
  });

  Future<List<SyncLogData>> logs() =>
      (db.select(db.syncLog)
            ..where((l) => l.changedTableName.equals('custom_data_sources')))
          .get();

  Future<CustomDataSource?> rowFor(String id) =>
      (db.select(db.customDataSources)..where((s) => s.id.equals(id)))
          .getSingleOrNull();

  CustomDataSourceDomain source({
    String id = 'src-1',
    String name = 'My rates',
    String url = 'https://example.test/rates.json',
    ApiDataType dataType = ApiDataType.exchange,
    bool enabled = true,
    bool autoFetch = false,
    DateTime? lastFetchAt,
  }) => CustomDataSourceDomain(
    id: id,
    name: name,
    url: url,
    dataType: dataType,
    enabled: enabled,
    autoFetch: autoFetch,
    lastFetchAt: lastFetchAt,
  );

  group('saving a new data source', () {
    test('round-trips every field', () async {
      await repo.saveDataSource(
        source(
          dataType: ApiDataType.inflation,
          enabled: false,
          autoFetch: true,
          lastFetchAt: DateTime(2024, 3, 3, 9, 15),
        ),
      );

      final read = await repo.getDataSourceById('src-1');

      expect(read!.name, 'My rates');
      expect(read.url, 'https://example.test/rates.json');
      expect(read.dataType, ApiDataType.inflation);
      expect(read.enabled, isFalse);
      expect(read.autoFetch, isTrue);
      expect(read.lastFetchAt, DateTime(2024, 3, 3, 9, 15));
    });

    test('a source that has never fetched round-trips a null lastFetchAt, not '
        'the epoch', () async {
      await repo.saveDataSource(source());

      expect((await repo.getDataSourceById('src-1'))!.lastFetchAt, isNull);
    });

    test('the data type is stored as its enum index and comes back as the '
        'same enum value', () async {
      // The column is a bare int, so a reordering of ApiDataType would
      // repoint every saved source at the wrong parser.
      await repo.saveDataSource(source(dataType: ApiDataType.asset));

      final row = await rowFor('src-1');
      expect(row!.dataType, ApiDataType.asset.index);
      expect(
        (await repo.getDataSourceById('src-1'))!.dataType,
        ApiDataType.asset,
      );
    });

    test('stamps modifiedAt so the new source wins the next sync', () async {
      final before = DateTime.now().millisecondsSinceEpoch;

      await repo.saveDataSource(source());

      expect((await rowFor('src-1'))!.modifiedAt, greaterThanOrEqualTo(before));
    });

    test('appends one upsert to sync_log', () async {
      await repo.saveDataSource(source());

      final logged = await logs();
      expect(logged.single.recordId, 'src-1');
      expect(logged.single.action, 'upsert');
      expect(logged.single.timestamp, greaterThan(0));
    });

    test('a new source starts out not deleted', () async {
      await repo.saveDataSource(source());

      expect((await rowFor('src-1'))!.isDeleted, isFalse);
    });
  });

  group('saving over an existing data source', () {
    test('updates the row in place instead of adding a second one', () async {
      await repo.saveDataSource(source(name: 'First'));

      await repo.saveDataSource(source(name: 'Second'));

      final all = await repo.getAllDataSources();
      expect(all, hasLength(1));
      expect(all.single.name, 'Second');
    });

    test('refreshes modifiedAt so the edit wins the next sync', () async {
      await repo.saveDataSource(source());
      await db
          .update(db.customDataSources)
          .write(const CustomDataSourcesCompanion(modifiedAt: Value(1)));
      final before = DateTime.now().millisecondsSinceEpoch;

      await repo.saveDataSource(source(name: 'Second'));

      expect((await rowFor('src-1'))!.modifiedAt, greaterThanOrEqualTo(before));
    });

    test('logs another upsert so the edit reaches other devices', () async {
      await repo.saveDataSource(source());
      await db.delete(db.syncLog).go();

      await repo.saveDataSource(source(name: 'Second'));

      expect((await logs()).single.action, 'upsert');
    });
  });

  group('reading', () {
    test('getAllDataSources returns every live source', () async {
      await repo.saveDataSource(source(id: 'src-1'));
      await repo.saveDataSource(source(id: 'src-2'));

      expect(await repo.getAllDataSources(), hasLength(2));
    });

    test('a soft-deleted source is not returned by '
        'getAllDataSources', () async {
      await repo.saveDataSource(source(id: 'src-1'));
      await repo.saveDataSource(source(id: 'src-2'));

      await repo.deleteDataSource('src-1');

      expect((await repo.getAllDataSources()).single.id, 'src-2');
    });

    test('a soft-deleted source is not returned by '
        'getDataSourceById', () async {
      await repo.saveDataSource(source());
      await repo.deleteDataSource('src-1');

      expect(await rowFor('src-1'), isNotNull, reason: 'row is only flagged');
      expect(await repo.getDataSourceById('src-1'), isNull);
    });

    test('getDataSourceById returns null for an unknown id', () async {
      expect(await repo.getDataSourceById('nope'), isNull);
    });

    test('getAllDataSources is empty when nothing is stored', () async {
      expect(await repo.getAllDataSources(), isEmpty);
    });
  });

  group('deleting', () {
    test('marks the row deleted instead of removing it, so the delete can '
        'sync', () async {
      await repo.saveDataSource(source());

      await repo.deleteDataSource('src-1');

      expect((await rowFor('src-1'))!.isDeleted, isTrue);
    });

    test('bumps modifiedAt so the tombstone beats an older live copy', () async {
      await repo.saveDataSource(source());
      await db
          .update(db.customDataSources)
          .write(const CustomDataSourcesCompanion(modifiedAt: Value(1)));
      final before = DateTime.now().millisecondsSinceEpoch;

      await repo.deleteDataSource('src-1');

      expect((await rowFor('src-1'))!.modifiedAt, greaterThanOrEqualTo(before));
    });

    test('logs a delete action, not an upsert', () async {
      await repo.saveDataSource(source());
      await db.delete(db.syncLog).go();

      await repo.deleteDataSource('src-1');

      expect((await logs()).single.action, 'delete');
    });

    test('deleting an id that does not exist does nothing and logs '
        'nothing', () async {
      await repo.deleteDataSource('ghost');

      expect(await logs(), isEmpty);
    });

    test('deleting an already deleted source does not log a second '
        'tombstone', () async {
      // The repository looks the row up first, and that lookup filters
      // isDeleted - so the second delete is a no-op.
      await repo.saveDataSource(source());
      await repo.deleteDataSource('src-1');
      await db.delete(db.syncLog).go();

      await repo.deleteDataSource('src-1');

      expect(await logs(), isEmpty);
    });

    test('saving a source whose id was deleted leaves it deleted', () async {
      // An import or a restore that re-saves a source the user had deleted must
      // not put the endpoint back: a resurrected row carries a newer modifiedAt
      // than the tombstone, so it would start fetching again on every device.
      await repo.saveDataSource(source());
      await repo.deleteDataSource('src-1');
      await db.delete(db.syncLog).go();

      await repo.saveDataSource(source(name: 'Back'));

      expect(await repo.getDataSourceById('src-1'), isNull);
      expect((await rowFor('src-1'))!.isDeleted, isTrue);
      expect((await rowFor('src-1'))!.name, isNot('Back'));
      expect(await logs(), isEmpty, reason: 'nothing changed, nothing to sync');
    });
  });
}
