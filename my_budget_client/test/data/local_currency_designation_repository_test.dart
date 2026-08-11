import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/data/repositories/local_db/local_currency_designation_repository.dart';
// `CurrencyDesignation` is both a drift row class and a domain entity.
import 'package:my_budget_client/domain/entities/currency_designation.dart'
    as domain;

/// Designations are the per-currency symbols ("$", "€"). They are soft-deleted
/// and synced, so the two things worth pinning are that deleted symbols never
/// come back out of a read, and that every write leaves a `sync_log` row.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LocalCurrencyDesignationRepository repo;
  late String currencyCode;

  setUpAll(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalCurrencyDesignationRepository(db);
    currencyCode = (await db.select(db.currencies).get()).first.code;
  });

  tearDownAll(() async => db.close());

  setUp(() async {
    await db.delete(db.currencyDesignations).go();
    await db.delete(db.syncLog).go();
  });

  Future<List<SyncLogData>> logs() =>
      (db.select(db.syncLog)
            ..where((l) => l.changedTableName.equals('currency_designations')))
          .get();

  Future<CurrencyDesignation?> rowFor(String id) =>
      (db.select(db.currencyDesignations)
            ..where((d) => d.id.equals(id)))
          .getSingleOrNull();

  domain.CurrencyDesignation designation({
    String id = 'd1',
    String value = 'Z\$',
  }) => domain.CurrencyDesignation(
    id: id,
    value: value,
    currencyCode: currencyCode,
  );

  group('reading', () {
    test('a designation round-trips its id, value and currency code', () async {
      await repo.addDesignation(designation(value: 'Zł'));

      final read = (await repo.getDesignations()).single;

      expect(read.id, 'd1');
      expect(read.value, 'Zł');
      expect(read.currencyCode, currencyCode);
    });

    test('getDesignations returns every live designation', () async {
      await repo.addDesignation(designation(id: 'd1'));
      await repo.addDesignation(designation(id: 'd2'));

      expect(await repo.getDesignations(), hasLength(2));
    });

    test('a soft-deleted designation is not returned by '
        'getDesignations', () async {
      await repo.addDesignation(designation(id: 'd1'));
      await repo.addDesignation(designation(id: 'd2'));

      await repo.deleteDesignation('d1');

      final live = await repo.getDesignations();
      expect(live.map((d) => d.id).toList(), ['d2']);
    });

    test('a soft-deleted designation is not returned by '
        'getDesignationById', () async {
      // The row is still physically there - only `isDeleted` flips - so a read
      // path that forgets the filter would hand back a deleted symbol.
      await repo.addDesignation(designation(id: 'd1'));
      await repo.deleteDesignation('d1');

      expect(await rowFor('d1'), isNotNull);
      expect(await repo.getDesignationById('d1'), isNull);
    });

    test('getDesignationById returns null for an id that was never '
        'stored', () async {
      expect(await repo.getDesignationById('nope'), isNull);
    });

    test('getDesignations is empty when nothing is stored', () async {
      expect(await repo.getDesignations(), isEmpty);
    });
  });

  group('addDesignation', () {
    test('stamps modifiedAt so the new symbol wins the next sync', () async {
      final before = DateTime.now().millisecondsSinceEpoch;

      await repo.addDesignation(designation());

      expect((await rowFor('d1'))!.modifiedAt, greaterThanOrEqualTo(before));
    });

    test('appends one upsert to sync_log so other devices see the '
        'symbol', () async {
      await repo.addDesignation(designation());

      final logged = await logs();
      expect(logged, hasLength(1));
      expect(logged.single.recordId, 'd1');
      expect(logged.single.action, 'upsert');
      expect(logged.single.timestamp, greaterThan(0));
    });

    test('a new designation starts out not deleted', () async {
      await repo.addDesignation(designation());

      expect((await rowFor('d1'))!.isDeleted, isFalse);
    });

    test('addDesignations inserts every designation in the list', () async {
      await repo.addDesignations([
        designation(id: 'd1', value: 'A'),
        designation(id: 'd2', value: 'B'),
        designation(id: 'd3', value: 'C'),
      ]);

      expect(await repo.getDesignations(), hasLength(3));
    });

    test('addDesignations logs one upsert per designation, not one for the '
        'batch', () async {
      // A single log row for the batch would sync only one of the symbols.
      await repo.addDesignations([
        designation(id: 'd1', value: 'A'),
        designation(id: 'd2', value: 'B'),
      ]);

      final logged = await logs();
      expect(logged, hasLength(2));
      expect(logged.map((l) => l.recordId), containsAll(['d1', 'd2']));
    });

    test('addDesignations stamps modifiedAt on every row', () async {
      final before = DateTime.now().millisecondsSinceEpoch;

      await repo.addDesignations([
        designation(id: 'd1', value: 'A'),
        designation(id: 'd2', value: 'B'),
      ]);

      final rows = await db.select(db.currencyDesignations).get();
      expect(
        rows.every((r) => r.modifiedAt >= before),
        isTrue,
        reason: 'a row left at modifiedAt 0 loses to any remote copy',
      );
    });

    test('addDesignations replaces a designation that already exists instead '
        'of failing', () async {
      await repo.addDesignation(designation(id: 'd1', value: 'A'));

      await repo.addDesignations([designation(id: 'd1', value: 'B')]);

      expect((await repo.getDesignations()).single.value, 'B');
    });
  });

  group('updateDesignation', () {
    test('overwrites the stored symbol', () async {
      await repo.addDesignation(designation(id: 'd1', value: 'A'));

      await repo.updateDesignation(designation(id: 'd1', value: 'B'));

      expect((await repo.getDesignationById('d1'))!.value, 'B');
    });

    test('refreshes modifiedAt so the edit wins the next sync', () async {
      await repo.addDesignation(designation(id: 'd1', value: 'A'));
      await db
          .update(db.currencyDesignations)
          .write(const CurrencyDesignationsCompanion(modifiedAt: Value(1)));
      final before = DateTime.now().millisecondsSinceEpoch;

      await repo.updateDesignation(designation(id: 'd1', value: 'B'));

      expect((await rowFor('d1'))!.modifiedAt, greaterThanOrEqualTo(before));
    });

    test('logs an upsert for the edited designation', () async {
      await repo.addDesignation(designation(id: 'd1', value: 'A'));
      await db.delete(db.syncLog).go();

      await repo.updateDesignation(designation(id: 'd1', value: 'B'));

      final logged = await logs();
      expect(logged.single.recordId, 'd1');
      expect(logged.single.action, 'upsert');
    });

    test('updating an id that does not exist changes nothing and logs '
        'nothing', () async {
      // `replace` matches on the primary key, so this is a silent no-op. The
      // sync log must not gain a row for a record that was never written.
      await repo.updateDesignation(designation(id: 'ghost', value: 'X'));

      expect(await repo.getDesignations(), isEmpty);
      expect(await logs(), isEmpty);
    });

    test('updating a soft-deleted designation does not bring it back', () async {
      // The companion the UI builds carries only id/value/currencyCode, so a
      // write that touches every column would reset isDeleted and the symbol
      // the user deleted would reappear - here and, with its fresh modifiedAt
      // beating the tombstone, on every other device.
      await repo.addDesignation(designation(id: 'd1', value: 'A'));
      await repo.deleteDesignation('d1');
      await db.delete(db.syncLog).go();

      await repo.updateDesignation(designation(id: 'd1', value: 'B'));

      expect(await repo.getDesignationById('d1'), isNull);
      expect((await rowFor('d1'))!.isDeleted, isTrue);
      expect((await rowFor('d1'))!.value, 'A', reason: 'no columns written');
      expect(await logs(), isEmpty, reason: 'nothing changed, nothing to sync');
    });
  });

  group('deleteDesignation', () {
    test('marks the row deleted instead of removing it, so the delete can '
        'sync', () async {
      await repo.addDesignation(designation(id: 'd1'));

      await repo.deleteDesignation('d1');

      final row = await rowFor('d1');
      expect(row, isNotNull);
      expect(row!.isDeleted, isTrue);
    });

    test('bumps modifiedAt so the tombstone beats the older live copy on '
        'another device', () async {
      await repo.addDesignation(designation(id: 'd1'));
      await db
          .update(db.currencyDesignations)
          .write(const CurrencyDesignationsCompanion(modifiedAt: Value(1)));
      final before = DateTime.now().millisecondsSinceEpoch;

      await repo.deleteDesignation('d1');

      expect((await rowFor('d1'))!.modifiedAt, greaterThanOrEqualTo(before));
    });

    test('logs a delete action, not an upsert', () async {
      await repo.addDesignation(designation(id: 'd1'));
      await db.delete(db.syncLog).go();

      await repo.deleteDesignation('d1');

      expect(logs().then((l) => l.single.action), completion('delete'));
    });

    test('deleting an id that does not exist logs nothing', () async {
      await repo.deleteDesignation('ghost');

      expect(await logs(), isEmpty);
    });

    test('deleting one designation leaves the others alone', () async {
      await repo.addDesignation(designation(id: 'd1'));
      await repo.addDesignation(designation(id: 'd2'));

      await repo.deleteDesignation('d1');

      expect((await repo.getDesignations()).single.id, 'd2');
    });
  });
}
