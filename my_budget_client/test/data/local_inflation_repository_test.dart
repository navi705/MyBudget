import 'package:drift/drift.dart'
    show BooleanExpressionOperators, InsertMode, InvalidDataException, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/data/repositories/local_db/local_inflation_repository.dart';
import 'package:my_budget_client/domain/entities/inflation_rate.dart';

/// `inflation_rates` has no `isDeleted` column: rows are hard-deleted, so there
/// is no soft-delete surface here. What is worth pinning instead is the
/// composite primary key `(date, country, preset)` with a *nullable* `country`,
/// the paging/filter arguments the inflation screen passes straight through,
/// and the sync bookkeeping (which is currently broken on the write paths).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LocalInflationRepository repo;

  setUpAll(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalInflationRepository(db.inflationRatesDao);
  });

  tearDownAll(() async => db.close());

  setUp(() async {
    await db.delete(db.inflationRates).go();
    await db.delete(db.syncLog).go();
  });

  Future<List<SyncLogData>> logsFor(String table) =>
      (db.select(db.syncLog)..where((l) => l.changedTableName.equals(table)))
          .get();

  /// Seeds a row without going through `addInflationRate`, which currently
  /// throws (see the characterization test below) and would take every other
  /// test down with it.
  Future<void> seed({
    required DateTime date,
    String? country,
    int preset = 1,
    double percent = 2.5,
    int modifiedAt = 0,
  }) => db
      .into(db.inflationRates)
      .insert(
        InflationRatesCompanion.insert(
          date: date,
          percent: percent,
          preset: preset,
          country: Value(country),
          modifiedAt: Value(modifiedAt),
        ),
        mode: InsertMode.insertOrReplace,
      );

  InflationRateDomain domainRate({
    required DateTime date,
    String? country,
    int preset = 1,
    double percent = 2.5,
  }) => InflationRateDomain(
    date: date,
    country: country,
    preset: preset,
    percent: percent,
  );

  Future<InflationRate?> rowFor(DateTime date, String? country, int preset) =>
      (db.select(db.inflationRates)..where(
            (t) =>
                t.date.equals(date) &
                (country == null
                    ? t.country.isNull()
                    : t.country.equals(country)) &
                t.preset.equals(preset),
          ))
          .getSingleOrNull();

  group('reading', () {
    test('getInflationRates returns every stored rate', () async {
      await seed(date: DateTime(2024, 1, 1), country: 'US');
      await seed(date: DateTime(2024, 2, 1), country: 'DE');
      await seed(date: DateTime(2024, 3, 1)); // global, country == null

      final all = await repo.getInflationRates();

      expect(all, hasLength(3));
      expect(all.map((r) => r.country), containsAll(<String?>['US', 'DE', null]));
    });

    test('a rate round-trips date, percent, country and preset', () async {
      await seed(
        date: DateTime(2024, 7, 15),
        country: 'BR',
        preset: 42,
        percent: -0.75,
      );

      final rate = (await repo.getInflationRates()).single;

      expect(rate.date, DateTime(2024, 7, 15));
      expect(rate.percent, -0.75);
      expect(rate.country, 'BR');
      expect(rate.preset, 42);
    });

    test('a rate with no country round-trips as null, not as an empty '
        'string', () async {
      // The UI distinguishes "global inflation" (null) from a country row. If
      // the mapper ever coerced null to '' the global series would show up as a
      // country named nothing in the country filter.
      await seed(date: DateTime(2024, 4, 4));

      expect((await repo.getInflationRates()).single.country, isNull);
    });

    test('getInflationRates returns an empty list when nothing is '
        'stored', () async {
      expect(await repo.getInflationRates(), isEmpty);
    });
  });

  group('filtering and paging', () {
    setUp(() async {
      await seed(date: DateTime(2024, 1, 10), country: 'US', preset: 1, percent: 1);
      await seed(date: DateTime(2024, 2, 10), country: 'US', preset: 2, percent: 2);
      await seed(date: DateTime(2024, 3, 10), country: 'DE', preset: 1, percent: 3);
      await seed(date: DateTime(2024, 4, 10), country: 'DE', preset: 2, percent: 4);
      await seed(date: DateTime(2024, 5, 10), preset: 1, percent: 5); // global
    });

    test('rates come back newest first by default', () async {
      final rates = await repo.getInflationRatesFiltered();

      expect(
        rates.map((r) => r.date).toList(),
        [
          DateTime(2024, 5, 10),
          DateTime(2024, 4, 10),
          DateTime(2024, 3, 10),
          DateTime(2024, 2, 10),
          DateTime(2024, 1, 10),
        ],
      );
    });

    test('sortAscending flips the order to oldest first', () async {
      final rates = await repo.getInflationRatesFiltered(sortAscending: true);

      expect(rates.first.date, DateTime(2024, 1, 10));
      expect(rates.last.date, DateTime(2024, 5, 10));
    });

    test('limit caps how many rates are returned', () async {
      expect(await repo.getInflationRatesFiltered(limit: 2), hasLength(2));
    });

    test('the default limit is 50', () async {
      // Callers rely on the default page size; dropping it to e.g. 10 would
      // silently truncate the list screen.
      for (var i = 0; i < 60; i++) {
        await seed(date: DateTime(2025, 1, 1).add(Duration(days: i)), country: 'FR');
      }

      expect(await repo.getInflationRatesFiltered(), hasLength(50));
    });

    test('offset skips over the first page without overlapping it', () async {
      final page1 = await repo.getInflationRatesFiltered(limit: 2, offset: 0);
      final page2 = await repo.getInflationRatesFiltered(limit: 2, offset: 2);

      final page1Dates = page1.map((r) => r.date).toSet();
      final page2Dates = page2.map((r) => r.date).toSet();
      expect(page1Dates.intersection(page2Dates), isEmpty);
      expect(page2.map((r) => r.date).toList(), [
        DateTime(2024, 3, 10),
        DateTime(2024, 2, 10),
      ]);
    });

    test('dateFrom is inclusive of the boundary day', () async {
      final rates = await repo.getInflationRatesFiltered(
        dateFrom: DateTime(2024, 3, 10),
      );

      expect(rates, hasLength(3));
      expect(rates.map((r) => r.date), contains(DateTime(2024, 3, 10)));
    });

    test('dateTo is inclusive of the boundary day', () async {
      final rates = await repo.getInflationRatesFiltered(
        dateTo: DateTime(2024, 3, 10),
      );

      expect(rates, hasLength(3));
      expect(rates.map((r) => r.date), contains(DateTime(2024, 3, 10)));
    });

    test('dateFrom and dateTo together select a closed window', () async {
      final rates = await repo.getInflationRatesFiltered(
        dateFrom: DateTime(2024, 2, 10),
        dateTo: DateTime(2024, 4, 10),
      );

      expect(rates.map((r) => r.percent).toList(), [4, 3, 2]);
    });

    test('countries filters to the listed countries only', () async {
      final rates = await repo.getInflationRatesFiltered(countries: ['DE']);

      expect(rates, hasLength(2));
      expect(rates.every((r) => r.country == 'DE'), isTrue);
    });

    test('a country filter cannot select the global (null-country) '
        'rate', () async {
      // `country IN (...)` is never true for NULL. Worth pinning because it
      // means the global series is only reachable with no country filter at
      // all - there is no value the caller can pass to ask for it.
      final rates = await repo.getInflationRatesFiltered(countries: ['US', 'DE']);

      expect(rates.map((r) => r.country), everyElement(isNotNull));
    });

    test('presets filters to the listed presets only', () async {
      final rates = await repo.getInflationRatesFiltered(presets: [2]);

      expect(rates, hasLength(2));
      expect(rates.every((r) => r.preset == 2), isTrue);
    });

    test('country and preset filters compose with AND', () async {
      final rates = await repo.getInflationRatesFiltered(
        countries: ['US'],
        presets: [2],
      );

      expect(rates.single.percent, 2);
    });

    test('an empty country list means no country filter, not no '
        'results', () async {
      expect(await repo.getInflationRatesFiltered(countries: []), hasLength(5));
    });

    test('an empty preset list means no preset filter, not no results', () async {
      expect(await repo.getInflationRatesFiltered(presets: []), hasLength(5));
    });

    test('null filters are ignored', () async {
      final rates = await repo.getInflationRatesFiltered(
        dateFrom: null,
        dateTo: null,
        countries: null,
        presets: null,
      );

      expect(rates, hasLength(5));
    });

    test('getInflationRatesCount counts every match, ignoring paging', () async {
      final page = await repo.getInflationRatesFiltered(limit: 2);
      final count = await repo.getInflationRatesCount();

      expect(page, hasLength(2));
      expect(count, 5);
    });

    test('getInflationRatesCount applies the same filters as the '
        'list query', () async {
      expect(
        await repo.getInflationRatesCount(
          dateFrom: DateTime(2024, 2, 10),
          dateTo: DateTime(2024, 4, 10),
          presets: [1, 2],
        ),
        3,
      );
      expect(await repo.getInflationRatesCount(countries: ['DE']), 2);
    });

    test('getInflationRatesCount is 0 when nothing matches', () async {
      expect(await repo.getInflationRatesCount(countries: ['ZZ']), 0);
    });

    test('watchInflationRatesFiltered re-emits after a rate is '
        'inserted', () async {
      final stream = repo.watchInflationRatesFiltered(limit: 50, offset: 0);
      final first = await stream.first;
      expect(first, hasLength(5));

      final next = stream.skip(1).first;
      await seed(date: DateTime(2024, 6, 10), country: 'US');

      expect(await next, hasLength(6));
    });

    test('watchInflationRatesFiltered honours the same filters as the '
        'one-shot query', () async {
      final rates = await repo
          .watchInflationRatesFiltered(
            limit: 50,
            offset: 0,
            countries: ['US'],
            sortAscending: true,
          )
          .first;

      expect(rates.map((r) => r.percent).toList(), [1, 2]);
    });
  });

  group('available countries and presets', () {
    test('getAvailableCountries returns each country once', () async {
      await seed(date: DateTime(2024, 1, 1), country: 'US');
      await seed(date: DateTime(2024, 2, 1), country: 'US', preset: 2);
      await seed(date: DateTime(2024, 3, 1), country: 'DE');

      final countries = await repo.getAvailableCountries();

      expect(countries, hasLength(2));
      expect(countries, containsAll(['US', 'DE']));
    });

    test('getAvailableCountries omits the global rate rather than '
        'listing a null country', () async {
      await seed(date: DateTime(2024, 1, 1)); // country == null
      await seed(date: DateTime(2024, 2, 1), country: 'US');

      expect(await repo.getAvailableCountries(), ['US']);
    });

    test('getAvailableCountries drops rows whose country is the empty '
        'string', () async {
      // The repository filters these out itself, so an empty option never
      // reaches the country dropdown.
      await seed(date: DateTime(2024, 1, 1), country: '');
      await seed(date: DateTime(2024, 2, 1), country: 'US');

      expect(await repo.getAvailableCountries(), ['US']);
    });

    test('getAvailablePresets returns each preset once', () async {
      await seed(date: DateTime(2024, 1, 1), country: 'US', preset: 7);
      await seed(date: DateTime(2024, 2, 1), country: 'DE', preset: 7);
      await seed(date: DateTime(2024, 3, 1), country: 'DE', preset: 9);

      final presets = await repo.getAvailablePresets();

      expect(presets, hasLength(2));
      expect(presets, containsAll([7, 9]));
    });

    test('both lists are empty when there are no rates', () async {
      expect(await repo.getAvailableCountries(), isEmpty);
      expect(await repo.getAvailablePresets(), isEmpty);
    });
  });

  group('writing', () {
    test('CHARACTERIZATION: addInflationRate stores the rate and then throws '
        'because its sync_log row is invalid', () async {
      // BUG. `InflationRatesDao._logChange` builds a `SyncLogCompanion` with
      // changedTableName/recordId/action but no `timestamp`, and `timestamp`
      // is a non-nullable column with no default, so the insert is rejected.
      // The rate insert is not inside a transaction, so the row survives while
      // the caller sees an exception: the UI reports "failed to add" for a rate
      // that is now in the table, and no sync_log row is written either.
      // Correct behaviour: `_logChange` should pass
      // `timestamp: Value(DateTime.now().millisecondsSinceEpoch)` like every
      // other DAO does, and the write plus its log should be one transaction.
      await expectLater(
        repo.addInflationRate(
          domainRate(date: DateTime(2024, 8, 1), country: 'US'),
        ),
        throwsA(isA<InvalidDataException>()),
      );

      expect(await rowFor(DateTime(2024, 8, 1), 'US', 1), isNotNull);
      expect(await logsFor('inflation_rates'), isEmpty);
    });

    test('CHARACTERIZATION: addInflationRate stamps modifiedAt before it '
        'fails', () async {
      // Pinned separately so that fixing the `_logChange` crash above does not
      // accidentally drop the modifiedAt stamp: last-write-wins sync compares
      // this field, and a rate left at 0 loses to any remote copy.
      final before = DateTime.now().millisecondsSinceEpoch;
      await repo
          .addInflationRate(domainRate(date: DateTime(2024, 8, 2), country: 'US'))
          .catchError((Object _) {});

      final row = await rowFor(DateTime(2024, 8, 2), 'US', 1);
      expect(row!.modifiedAt, greaterThanOrEqualTo(before));
    });

    test('re-adding a rate with the same date, country and preset replaces '
        'the old percent instead of duplicating it', () async {
      await repo
          .addInflationRate(
            domainRate(date: DateTime(2024, 9, 1), country: 'US', percent: 1.0),
          )
          .catchError((Object _) {});
      await repo
          .addInflationRate(
            domainRate(date: DateTime(2024, 9, 1), country: 'US', percent: 2.0),
          )
          .catchError((Object _) {});

      final all = await repo.getInflationRates();
      expect(all, hasLength(1));
      expect(all.single.percent, 2.0);
    });

    test('CHARACTERIZATION: re-adding a global rate duplicates it instead of '
        'replacing it', () async {
      // BUG (schema). The primary key is (date, country, preset) but `country`
      // is nullable, and SQLite does not enforce uniqueness across NULLs in a
      // rowid table's PRIMARY KEY. So INSERT OR REPLACE finds no conflict and
      // appends. Refreshing global inflation from the provider therefore grows
      // the table forever and the chart shows the same month several times.
      // Correct behaviour: store 'global' (as the sync record id already does)
      // instead of NULL, or add a unique index that treats NULL as a value.
      await seed(date: DateTime(2024, 10, 1), percent: 1.0);
      await seed(date: DateTime(2024, 10, 1), percent: 2.0);

      final all = await repo.getInflationRates();
      expect(all, hasLength(2));
      expect(all.map((r) => r.percent), containsAll([1.0, 2.0]));
    });

    test('updateInflationRate overwrites the percent of the matching '
        'rate', () async {
      await seed(date: DateTime(2024, 11, 1), country: 'US', preset: 1, percent: 1.0);

      await repo.updateInflationRate(
        domainRate(date: DateTime(2024, 11, 1), country: 'US', percent: 9.5),
      );

      final row = await rowFor(DateTime(2024, 11, 1), 'US', 1);
      expect(row!.percent, 9.5);
    });

    test('updateInflationRate refreshes modifiedAt so the edit wins the next '
        'sync', () async {
      await seed(
        date: DateTime(2024, 11, 2),
        country: 'US',
        preset: 1,
        modifiedAt: 1,
      );
      final before = DateTime.now().millisecondsSinceEpoch;

      await repo.updateInflationRate(
        domainRate(date: DateTime(2024, 11, 2), country: 'US', percent: 4),
      );

      final row = await rowFor(DateTime(2024, 11, 2), 'US', 1);
      expect(row!.modifiedAt, greaterThanOrEqualTo(before));
    });

    test('CHARACTERIZATION: updating a global rate throws instead of editing '
        'it', () async {
      // BUG. `updateInflationRate` uses drift's `replace`, whose WHERE clause
      // is built from the primary key. `country` is part of that key and is
      // null for a global rate, so drift refuses the statement outright with
      // "Tried to find a row with a matching primary key that has a null
      // value". In a debug/profile build the user sees the edit blow up; with
      // asserts off the generated `country = NULL` matches nothing, so the
      // edit silently reverts on the next read. Either way the row is never
      // touched. Correct behaviour: match on `country IS NULL` (or store
      // 'global' instead of NULL, as the sync record id already does).
      await seed(date: DateTime(2024, 11, 3), percent: 1.0);

      await expectLater(
        repo.updateInflationRate(
          domainRate(date: DateTime(2024, 11, 3), percent: 8.0),
        ),
        throwsA(isA<AssertionError>()),
      );

      expect((await repo.getInflationRates()).single.percent, 1.0);
    });

    test('CHARACTERIZATION: updateInflationRate writes no sync_log row', () async {
      // BUG. An edited rate never reaches the other devices: they keep the old
      // percent until something else re-fetches the whole series. Every other
      // edit path in this database appends an `upsert` row here.
      await seed(date: DateTime(2024, 11, 4), country: 'US', preset: 1);

      await repo.updateInflationRate(
        domainRate(date: DateTime(2024, 11, 4), country: 'US', percent: 6),
      );

      expect(await logsFor('inflation_rates'), isEmpty);
    });

    test('deleteInflationRate removes only the addressed rate', () async {
      await seed(date: DateTime(2024, 12, 1), country: 'US', preset: 1);
      await seed(date: DateTime(2024, 12, 1), country: 'US', preset: 2);
      await seed(date: DateTime(2024, 12, 1), country: 'DE', preset: 1);

      await repo.deleteInflationRate(DateTime(2024, 12, 1), 'US', 1);

      final left = await repo.getInflationRates();
      expect(left, hasLength(2));
      expect(await rowFor(DateTime(2024, 12, 1), 'US', 1), isNull);
    });

    test('deleteInflationRate can address the global rate by passing a null '
        'country', () async {
      await seed(date: DateTime(2024, 12, 2), preset: 1);
      await seed(date: DateTime(2024, 12, 2), country: 'US', preset: 1);

      await repo.deleteInflationRate(DateTime(2024, 12, 2), null, 1);

      expect((await repo.getInflationRates()).single.country, 'US');
    });

    test('deleting a rate that does not exist leaves the table alone', () async {
      await seed(date: DateTime(2024, 12, 3), country: 'US', preset: 1);

      await repo.deleteInflationRate(DateTime(2030, 1, 1), 'US', 1);

      expect(await repo.getInflationRates(), hasLength(1));
    });

    test('CHARACTERIZATION: deleteInflationRate writes no sync_log '
        'row', () async {
      // BUG. A deleted rate is resurrected on the next sync from any device
      // that still has it, because no `delete` row is queued for it.
      await seed(date: DateTime(2024, 12, 4), country: 'US', preset: 1);

      await repo.deleteInflationRate(DateTime(2024, 12, 4), 'US', 1);

      expect(await logsFor('inflation_rates'), isEmpty);
    });

    test('deleteInflationRates removes every rate in the list', () async {
      await seed(date: DateTime(2025, 1, 1), country: 'US', preset: 1);
      await seed(date: DateTime(2025, 1, 2), country: 'US', preset: 1);
      await seed(date: DateTime(2025, 1, 3), country: 'DE', preset: 1);

      final toDelete = (await repo.getInflationRates())
          .where((r) => r.country == 'US')
          .toList();
      await repo.deleteInflationRates(toDelete);

      expect((await repo.getInflationRates()).single.country, 'DE');
    });

    test('deleteInflationRates with an empty list is a no-op', () async {
      await seed(date: DateTime(2025, 2, 1), country: 'US', preset: 1);

      await repo.deleteInflationRates([]);

      expect(await repo.getInflationRates(), hasLength(1));
    });

    test('CHARACTERIZATION: deleteInflationRates writes no sync_log '
        'rows', () async {
      // BUG, same as the single delete: a bulk clear from the inflation screen
      // stays local and every deleted rate comes back on the next sync.
      await seed(date: DateTime(2025, 3, 1), country: 'US', preset: 1);
      final all = await repo.getInflationRates();

      await repo.deleteInflationRates(all);

      expect(await logsFor('inflation_rates'), isEmpty);
    });
  });
}
