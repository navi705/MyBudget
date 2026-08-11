import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/theme/app_theme.dart';
import 'package:my_budget_client/data/repositories/local_db/local_theme_repository.dart';
import 'package:my_budget_client/domain/entities/custom_theme.dart';

/// Custom themes are soft-deleted, synced, and have an "exactly one active"
/// rule that `getActiveTheme` reads back with `getSingleOrNull` - so a second
/// active row does not just look wrong, it throws. Those are the invariants
/// pinned here, plus the colour <-> hex round-trip.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LocalThemeRepository repo;

  setUpAll(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalThemeRepository(db);
  });

  tearDownAll(() async => db.close());

  setUp(() async {
    await db.delete(db.customThemes).go();
    await db.delete(db.syncLog).go();
  });

  Future<List<SyncLogData>> logs() =>
      (db.select(db.syncLog)
            ..where((l) => l.changedTableName.equals('custom_themes')))
          .get();

  Future<DbCustomTheme?> rowFor(String id) =>
      (db.select(db.customThemes)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  CustomTheme theme({
    String id = 't1',
    String name = 'Midnight',
    bool isActive = false,
    bool isPreset = false,
    String? backgroundImagePath,
  }) => CustomTheme(
    id: id,
    name: name,
    primaryColor: const Color(0xFF112233),
    secondaryColor: const Color(0xFF445566),
    surfaceColor: const Color(0xFF778899),
    backgroundColor: const Color(0xFFAABBCC),
    backgroundImagePath: backgroundImagePath,
    backgroundImageOpacity: 0.42,
    backgroundImageBlur: 3.5,
    windowEffectType: WindowEffectType.mica,
    effectOpacity: 0.75,
    surfaceOpacity: 0.25,
    themeMode: ThemeMode.dark,
    isPreset: isPreset,
    isActive: isActive,
  );

  group('saveTheme', () {
    test('a theme round-trips every one of its fields', () async {
      await repo.saveTheme(theme(backgroundImagePath: 'C:/wall.png'));

      final read = (await repo.getAllThemes()).single;

      expect(read.id, 't1');
      expect(read.name, 'Midnight');
      expect(read.primaryColor, const Color(0xFF112233));
      expect(read.secondaryColor, const Color(0xFF445566));
      expect(read.surfaceColor, const Color(0xFF778899));
      expect(read.backgroundColor, const Color(0xFFAABBCC));
      expect(read.backgroundImagePath, 'C:/wall.png');
      expect(read.backgroundImageOpacity, 0.42);
      expect(read.backgroundImageBlur, 3.5);
      expect(read.windowEffectType, WindowEffectType.mica);
      expect(read.effectOpacity, 0.75);
      expect(read.surfaceOpacity, 0.25);
      expect(read.themeMode, ThemeMode.dark);
      expect(read.isPreset, isFalse);
      expect(read.isActive, isFalse);
    });

    test('a theme with no background image round-trips a null path, not an '
        'empty string', () async {
      await repo.saveTheme(theme());

      expect((await repo.getAllThemes()).single.backgroundImagePath, isNull);
    });

    test('saving the same id twice replaces the theme instead of failing or '
        'duplicating it', () async {
      // The theme editor saves on every change, so this path runs constantly.
      await repo.saveTheme(theme(name: 'First'));
      await repo.saveTheme(theme(name: 'Second'));

      final all = await repo.getAllThemes();
      expect(all, hasLength(1));
      expect(all.single.name, 'Second');
    });

    test('stamps modifiedAt so the saved theme wins the next sync', () async {
      final before = DateTime.now().millisecondsSinceEpoch;

      await repo.saveTheme(theme());

      expect((await rowFor('t1'))!.modifiedAt, greaterThanOrEqualTo(before));
    });

    test('logs an upsert against the custom_themes table', () async {
      await repo.saveTheme(theme());

      final logged = await logs();
      expect(logged.single.recordId, 't1');
      expect(logged.single.action, 'upsert');
      expect(logged.single.timestamp, greaterThan(0));
    });

    test('saving a theme keeps its active flag', () async {
      await repo.saveTheme(theme(isActive: true));

      expect((await repo.getActiveTheme())!.id, 't1');
    });
  });

  group('reading', () {
    test('getAllThemes returns every live theme', () async {
      await repo.saveTheme(theme(id: 't1'));
      await repo.saveTheme(theme(id: 't2'));

      expect(await repo.getAllThemes(), hasLength(2));
    });

    test('a soft-deleted theme is not returned by getAllThemes', () async {
      await repo.saveTheme(theme(id: 't1'));
      await repo.saveTheme(theme(id: 't2'));

      await repo.deleteTheme('t1');

      expect((await repo.getAllThemes()).single.id, 't2');
    });

    test('getActiveTheme is null when no theme is active', () async {
      await repo.saveTheme(theme(id: 't1'));

      expect(await repo.getActiveTheme(), isNull);
    });

    test('a soft-deleted theme is never reported as the active one', () async {
      // Without the isDeleted filter the app would keep painting itself with a
      // theme the user deleted.
      await repo.saveTheme(theme(id: 't1', isActive: true));

      await repo.deleteTheme('t1');

      expect(await repo.getActiveTheme(), isNull);
    });

    test('getAllThemes is empty when nothing is stored', () async {
      expect(await repo.getAllThemes(), isEmpty);
    });
  });

  group('setActiveTheme', () {
    test('activates the requested theme', () async {
      await repo.saveTheme(theme(id: 't1'));

      await repo.setActiveTheme('t1');

      expect((await repo.getActiveTheme())!.id, 't1');
    });

    test('deactivates the theme that was active before, so only one stays '
        'active', () async {
      // getActiveTheme uses getSingleOrNull: two active rows make it throw, so
      // this is the invariant that keeps the app from failing to start.
      await repo.saveTheme(theme(id: 't1', isActive: true));
      await repo.saveTheme(theme(id: 't2'));

      await repo.setActiveTheme('t2');

      final active = await repo.getActiveTheme();
      expect(active!.id, 't2');
      expect((await rowFor('t1'))!.isActive, isFalse);
    });

    test('logs an upsert for the theme that lost active as well as the one '
        'that gained it', () async {
      // A peer told only about the newly active theme would end up with two
      // active rows and hit the getSingleOrNull crash above.
      await repo.saveTheme(theme(id: 't1', isActive: true));
      await repo.saveTheme(theme(id: 't2'));
      await db.delete(db.syncLog).go();

      await repo.setActiveTheme('t2');

      final ids = (await logs()).map((l) => l.recordId).toSet();
      expect(ids, containsAll(['t1', 't2']));
    });

    test('bumps modifiedAt on both the deactivated and the activated '
        'theme', () async {
      await repo.saveTheme(theme(id: 't1', isActive: true));
      await repo.saveTheme(theme(id: 't2'));
      await db
          .update(db.customThemes)
          .write(const CustomThemesCompanion(modifiedAt: Value(1)));
      final before = DateTime.now().millisecondsSinceEpoch;

      await repo.setActiveTheme('t2');

      expect((await rowFor('t1'))!.modifiedAt, greaterThanOrEqualTo(before));
      expect((await rowFor('t2'))!.modifiedAt, greaterThanOrEqualTo(before));
    });

    test('activating the already active theme leaves it active', () async {
      await repo.saveTheme(theme(id: 't1', isActive: true));

      await repo.setActiveTheme('t1');

      expect((await repo.getActiveTheme())!.id, 't1');
    });

    test('CHARACTERIZATION: setActiveTheme with an unknown id leaves the app '
        'with no active theme at all', () async {
      // BUG. `CustomThemesDao.setActiveTheme` clears `isActive` on every row
      // first and only then tries to set it on [id]; when that id does not
      // exist the update matches nothing and the user is left themeless (the
      // app falls back to the default theme) with no error reported. It also
      // logs an upsert for the missing id. Correct behaviour: check the row
      // exists first and abort the transaction if it does not.
      await repo.saveTheme(theme(id: 't1', isActive: true));

      await repo.setActiveTheme('ghost');

      expect(await repo.getActiveTheme(), isNull);
    });

    test('CHARACTERIZATION: a soft-deleted theme can still be made '
        'active', () async {
      // BUG. `setActiveTheme` does not filter `isDeleted`, so the row is
      // flagged active while every read path hides it: getActiveTheme returns
      // null and the app silently drops back to the default theme, but the
      // deleted row now holds the active flag, so activating a real theme is
      // the only way out. Correct behaviour: refuse to activate a deleted row.
      await repo.saveTheme(theme(id: 't1'));
      await repo.deleteTheme('t1');

      await repo.setActiveTheme('t1');

      expect((await rowFor('t1'))!.isActive, isTrue);
      expect(await repo.getActiveTheme(), isNull);
    });
  });

  group('deleteTheme', () {
    test('marks the row deleted instead of removing it, so the delete can '
        'sync', () async {
      await repo.saveTheme(theme(id: 't1'));

      await repo.deleteTheme('t1');

      final row = await rowFor('t1');
      expect(row, isNotNull);
      expect(row!.isDeleted, isTrue);
    });

    test('bumps modifiedAt so the tombstone beats an older live copy', () async {
      await repo.saveTheme(theme(id: 't1'));
      await db
          .update(db.customThemes)
          .write(const CustomThemesCompanion(modifiedAt: Value(1)));
      final before = DateTime.now().millisecondsSinceEpoch;

      await repo.deleteTheme('t1');

      expect((await rowFor('t1'))!.modifiedAt, greaterThanOrEqualTo(before));
    });

    test('logs a delete action, not an upsert', () async {
      await repo.saveTheme(theme(id: 't1'));
      await db.delete(db.syncLog).go();

      await repo.deleteTheme('t1');

      expect((await logs()).single.action, 'delete');
    });

    test('deleting an id that does not exist logs nothing', () async {
      await repo.deleteTheme('ghost');

      expect(await logs(), isEmpty);
    });

    test('deleting one theme leaves the others alone', () async {
      await repo.saveTheme(theme(id: 't1'));
      await repo.saveTheme(theme(id: 't2'));

      await repo.deleteTheme('t1');

      expect((await repo.getAllThemes()).single.id, 't2');
    });
  });
}
