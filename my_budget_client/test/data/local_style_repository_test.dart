import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/data/repositories/local_db/local_style_repository.dart';
import 'package:my_budget_client/domain/entities/icon_type.dart';
// `Style` is both a drift row class and a domain entity.
import 'package:my_budget_client/domain/entities/style.dart' as domain;

/// Styles are the icon + colour pairs that categories and accounts point at.
/// They are soft-deleted and synced, and `getStylesByIds` is expected to give
/// callers the styles back in the order they asked for them.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LocalStyleRepository repo;

  setUpAll(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalStyleRepository(db);
    // The seeded categories point at the seeded styles, so the styles table
    // cannot be emptied between tests until they are gone.
    await db.delete(db.transactions).go();
    await db.delete(db.accounts).go();
    await db.delete(db.categories).go();
  });

  tearDownAll(() async => db.close());

  setUp(() async {
    await db.delete(db.styles).go();
    await db.delete(db.syncLog).go();
  });

  Future<List<SyncLogData>> logs() =>
      (db.select(db.syncLog)..where((l) => l.changedTableName.equals('styles')))
          .get();

  Future<Style?> rowFor(String id) =>
      (db.select(db.styles)..where((s) => s.id.equals(id))).getSingleOrNull();

  domain.Style style({
    String? id,
    String name = 'Groceries',
    String iconName = 'cart',
    String colorHex = '#FF0000',
    IconType iconType = IconType.material,
  }) => domain.Style(
    id: id,
    name: name,
    iconName: iconName,
    colorHex: colorHex,
    iconType: iconType,
  );

  group('reading', () {
    test('a style round-trips its name, icon, colour and icon type', () async {
      await repo.addStyle(
        style(
          id: 's1',
          name: 'Fuel',
          iconName: 'local_gas_station',
          colorHex: '#123456',
          iconType: IconType.values.last,
        ),
      );

      final read = (await repo.watchAllStyles().first).single;

      expect(read.id, 's1');
      expect(read.name, 'Fuel');
      expect(read.iconName, 'local_gas_station');
      expect(read.colorHex, '#123456');
      expect(read.iconType, IconType.values.last);
    });

    test('a soft-deleted style is not emitted by watchAllStyles', () async {
      await repo.addStyle(style(id: 's1'));
      await repo.addStyle(style(id: 's2'));

      await repo.deleteStyle('s1');

      final live = await repo.watchAllStyles().first;
      expect(live.map((s) => s.id).toList(), ['s2']);
    });

    test('a soft-deleted style is not returned by getStyleById', () async {
      await repo.addStyle(style(id: 's1'));
      await repo.deleteStyle('s1');

      expect(await rowFor('s1'), isNotNull, reason: 'row is only flagged');
      expect(await repo.getStyleById('s1'), isNull);
    });

    test('getStyleById returns null for an unknown id', () async {
      expect(await repo.getStyleById('nope'), isNull);
    });

    test('watchAllStyles re-emits when a style is added', () async {
      final stream = repo.watchAllStyles();
      expect(await stream.first, isEmpty);

      final next = stream.skip(1).first;
      await repo.addStyle(style(id: 's1'));

      expect(await next, hasLength(1));
    });
  });

  group('getStylesByIds', () {
    test('returns the styles in the order they were asked for, not the '
        'order they were stored', () async {
      // Callers zip this list against their own list of ids, so the order is
      // part of the contract.
      await repo.addStyle(style(id: 's1'));
      await repo.addStyle(style(id: 's2'));
      await repo.addStyle(style(id: 's3'));

      final read = await repo.getStylesByIds(['s3', 's1', 's2']);

      expect(read.map((s) => s.id).toList(), ['s3', 's1', 's2']);
    });

    test('silently drops ids that do not exist instead of throwing', () async {
      await repo.addStyle(style(id: 's1'));

      final read = await repo.getStylesByIds(['s1', 'ghost']);

      expect(read.map((s) => s.id).toList(), ['s1']);
    });

    test('drops soft-deleted styles', () async {
      await repo.addStyle(style(id: 's1'));
      await repo.addStyle(style(id: 's2'));
      await repo.deleteStyle('s2');

      final read = await repo.getStylesByIds(['s1', 's2']);

      expect(read.map((s) => s.id).toList(), ['s1']);
    });

    test('an empty id list returns an empty result', () async {
      await repo.addStyle(style(id: 's1'));

      expect(await repo.getStylesByIds([]), isEmpty);
    });

    test('a duplicated id is returned once per request slot', () async {
      await repo.addStyle(style(id: 's1'));

      expect(await repo.getStylesByIds(['s1', 's1']), hasLength(2));
    });
  });

  group('addStyle', () {
    test('mints an id when the caller has none', () async {
      await repo.addStyle(style());

      final stored = await db.select(db.styles).get();
      expect(stored.single.id, isNotEmpty);
    });

    test('keeps the id the caller supplied', () async {
      await repo.addStyle(style(id: 'chosen'));

      expect(await rowFor('chosen'), isNotNull);
    });

    test('stamps modifiedAt so the new style wins the next sync', () async {
      final before = DateTime.now().millisecondsSinceEpoch;

      await repo.addStyle(style(id: 's1'));

      expect((await rowFor('s1'))!.modifiedAt, greaterThanOrEqualTo(before));
    });

    test('logs an upsert against the styles table', () async {
      await repo.addStyle(style(id: 's1'));

      final logged = await logs();
      expect(logged.single.recordId, 's1');
      expect(logged.single.action, 'upsert');
      expect(logged.single.timestamp, greaterThan(0));
    });

    test('addStyles inserts every style and logs one upsert each', () async {
      await repo.addStyles([
        style(id: 's1'),
        style(id: 's2'),
        style(id: 's3'),
      ]);

      expect(await repo.watchAllStyles().first, hasLength(3));
      expect((await logs()).map((l) => l.recordId), containsAll(['s1', 's2', 's3']));
    });

    test('addStyles mints ids for the styles that have none', () async {
      await repo.addStyles([style(), style()]);

      final stored = await db.select(db.styles).get();
      expect(stored, hasLength(2));
      expect(stored.map((s) => s.id).toSet(), hasLength(2));
    });

    test('addStyles stamps modifiedAt on every row', () async {
      final before = DateTime.now().millisecondsSinceEpoch;

      await repo.addStyles([style(id: 's1'), style(id: 's2')]);

      final stored = await db.select(db.styles).get();
      expect(stored.every((s) => s.modifiedAt >= before), isTrue);
    });
  });

  group('updateStyle', () {
    test('overwrites name, icon and colour', () async {
      await repo.addStyle(style(id: 's1'));

      await repo.updateStyle(
        style(id: 's1', name: 'Rent', iconName: 'home', colorHex: '#00FF00'),
      );

      final read = await repo.getStyleById('s1');
      expect(read!.name, 'Rent');
      expect(read.iconName, 'home');
      expect(read.colorHex, '#00FF00');
    });

    test('refreshes modifiedAt so the edit wins the next sync', () async {
      await repo.addStyle(style(id: 's1'));
      await db
          .update(db.styles)
          .write(const StylesCompanion(modifiedAt: Value(1)));
      final before = DateTime.now().millisecondsSinceEpoch;

      await repo.updateStyle(style(id: 's1', name: 'Rent'));

      expect((await rowFor('s1'))!.modifiedAt, greaterThanOrEqualTo(before));
    });

    test('logs an upsert for the edited style', () async {
      await repo.addStyle(style(id: 's1'));
      await db.delete(db.syncLog).go();

      await repo.updateStyle(style(id: 's1', name: 'Rent'));

      expect((await logs()).single.action, 'upsert');
    });

    test('CHARACTERIZATION: updating an id that does not exist writes a '
        'sync_log row for a record that is not there', () async {
      // BUG. `StylesDao.updateStyle` calls `_logChange` unconditionally,
      // ignoring the bool returned by `replace`. The peer then asks for a
      // record the sender does not have, so every failed edit costs one
      // pointless round trip and, for the file-sync engine, one entry that can
      // never be resolved. `CurrencyDesignationsDao.updateDesignation` does
      // this correctly - it only logs `if (result)`.
      await repo.updateStyle(style(id: 'ghost', name: 'Rent'));

      expect(await repo.watchAllStyles().first, isEmpty);
      expect((await logs()).single.recordId, 'ghost');
    });
  });

  group('deleteStyle', () {
    test('marks the row deleted instead of removing it, so the delete can '
        'sync', () async {
      await repo.addStyle(style(id: 's1'));

      await repo.deleteStyle('s1');

      expect((await rowFor('s1'))!.isDeleted, isTrue);
    });

    test('bumps modifiedAt so the tombstone beats an older live copy', () async {
      await repo.addStyle(style(id: 's1'));
      await db
          .update(db.styles)
          .write(const StylesCompanion(modifiedAt: Value(1)));
      final before = DateTime.now().millisecondsSinceEpoch;

      await repo.deleteStyle('s1');

      expect((await rowFor('s1'))!.modifiedAt, greaterThanOrEqualTo(before));
    });

    test('logs a delete action, not an upsert', () async {
      await repo.addStyle(style(id: 's1'));
      await db.delete(db.syncLog).go();

      await repo.deleteStyle('s1');

      expect((await logs()).single.action, 'delete');
    });

    test('deleting an id that does not exist logs nothing', () async {
      await repo.deleteStyle('ghost');

      expect(await logs(), isEmpty);
    });
  });
}
