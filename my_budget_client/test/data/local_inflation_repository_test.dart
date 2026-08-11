import 'dart:io';

import 'package:drift/drift.dart'
    show BooleanExpressionOperators, InsertMode, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/data/repositories/local_db/local_inflation_repository.dart';
import 'package:my_budget_client/domain/entities/inflation_rate.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// `inflation_rates` has no `isDeleted` column: rows are hard-deleted, so there
/// is no soft-delete surface here. What is worth pinning instead is the
/// composite primary key `(date, country, preset)` — where a worldwide rate is
/// stored under [globalInflationCountry] and surfaces as a null country above
/// the mapper — the paging/filter arguments the inflation screen passes
/// straight through, and the sync bookkeeping on every write path.
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

  /// Seeds a row without going through `addInflationRate`, so that the reading
  /// and filtering groups do not depend on the write path they are not
  /// exercising. A null [country] is left absent so the column default is what
  /// decides where a worldwide rate lands.
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
          country: country == null ? const Value.absent() : Value(country),
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
                t.country.equals(country ?? globalInflationCountry) &
                t.preset.equals(preset),
          ))
          .getSingleOrNull();

  group('reading', () {
    test('getInflationRates returns every stored rate', () async {
      await seed(date: DateTime(2024, 1, 1), country: 'US');
      await seed(date: DateTime(2024, 2, 1), country: 'DE');
      await seed(date: DateTime(2024, 3, 1)); // worldwide

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

    test('a rate with no country round-trips as null, not as the stored '
        'sentinel', () async {
      // The UI distinguishes "global inflation" from a country row by the null.
      // If the sentinel leaked through the mapper the worldwide series would
      // show up as a country named 'global' in the country filter.
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
      await seed(date: DateTime(2024, 5, 10), preset: 1, percent: 5); // worldwide
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

    test('the worldwide series is addressable through the country filter by '
        'its sentinel', () async {
      final countryRates = await repo.getInflationRatesFiltered(
        countries: ['US', 'DE'],
      );
      expect(countryRates.map((r) => r.country), everyElement(isNotNull));

      final worldwide = await repo.getInflationRatesFiltered(
        countries: [globalInflationCountry],
      );
      expect(worldwide.single.date, DateTime(2024, 5, 10));
      expect(worldwide.single.country, isNull);
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

    test('getAvailableCountries omits the worldwide series rather than '
        'listing its sentinel', () async {
      await seed(date: DateTime(2024, 1, 1)); // worldwide
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
    test('addInflationRate stores the rate and queues it for sync', () async {
      await repo.addInflationRate(
        domainRate(date: DateTime(2024, 8, 1), country: 'US'),
      );

      expect(await rowFor(DateTime(2024, 8, 1), 'US', 1), isNotNull);

      final log = (await logsFor('inflation_rates')).single;
      expect(log.action, 'upsert');
      expect(log.recordId, '2024-08-01_US_1');
      expect(log.timestamp, greaterThan(0));
      expect(log.exported, isFalse);
    });

    test('a worldwide rate is queued for sync under its sentinel', () async {
      await repo.addInflationRate(domainRate(date: DateTime(2024, 8, 3)));

      expect(
        (await logsFor('inflation_rates')).single.recordId,
        '2024-08-03_global_1',
      );
    });

    test('addInflationRate stamps modifiedAt so the write wins the next '
        'sync', () async {
      // Last-write-wins sync compares this field, and a rate left at 0 loses
      // to any remote copy.
      final before = DateTime.now().millisecondsSinceEpoch;
      await repo.addInflationRate(
        domainRate(date: DateTime(2024, 8, 2), country: 'US'),
      );

      final row = await rowFor(DateTime(2024, 8, 2), 'US', 1);
      expect(row!.modifiedAt, greaterThanOrEqualTo(before));
    });

    test('re-adding a rate with the same date, country and preset replaces '
        'the old percent instead of duplicating it', () async {
      await repo.addInflationRate(
        domainRate(date: DateTime(2024, 9, 1), country: 'US', percent: 1.0),
      );
      await repo.addInflationRate(
        domainRate(date: DateTime(2024, 9, 1), country: 'US', percent: 2.0),
      );

      final all = await repo.getInflationRates();
      expect(all, hasLength(1));
      expect(all.single.percent, 2.0);
    });

    test('re-adding a worldwide rate replaces it instead of duplicating '
        'it', () async {
      // The sentinel exists for exactly this: SQLite does not enforce
      // uniqueness across NULLs in a rowid table's PRIMARY KEY, so a nullable
      // country let a re-fetch of the worldwide series grow the table forever.
      await repo.addInflationRate(
        domainRate(date: DateTime(2024, 10, 1), percent: 1.0),
      );
      await repo.addInflationRate(
        domainRate(date: DateTime(2024, 10, 1), percent: 2.0),
      );

      final all = await repo.getInflationRates();
      expect(all, hasLength(1));
      expect(all.single.percent, 2.0);
      expect(all.single.country, isNull);
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

    test('updateInflationRate edits the worldwide rate', () async {
      // `replace` builds its WHERE clause from the primary key, which a
      // nullable country cannot express.
      await seed(date: DateTime(2024, 11, 3), percent: 1.0);

      await repo.updateInflationRate(
        domainRate(date: DateTime(2024, 11, 3), percent: 8.0),
      );

      final rate = (await repo.getInflationRates()).single;
      expect(rate.percent, 8.0);
      expect(rate.country, isNull);
    });

    test('updateInflationRate writes a sync_log row', () async {
      // Without it an edited rate never reaches the other devices: they keep
      // the old percent until something else re-fetches the whole series.
      await seed(date: DateTime(2024, 11, 4), country: 'US', preset: 1);

      await repo.updateInflationRate(
        domainRate(date: DateTime(2024, 11, 4), country: 'US', percent: 6),
      );

      final log = (await logsFor('inflation_rates')).single;
      expect(log.action, 'upsert');
      expect(log.recordId, '2024-11-04_US_1');
      expect(log.timestamp, greaterThan(0));
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

    test('deleteInflationRate can address the worldwide rate by passing a null '
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
      expect(await logsFor('inflation_rates'), isEmpty);
    });

    test('deleteInflationRate writes a sync_log row', () async {
      // Without it a deleted rate is resurrected on the next sync from any
      // device that still has it.
      await seed(date: DateTime(2024, 12, 4), country: 'US', preset: 1);

      await repo.deleteInflationRate(DateTime(2024, 12, 4), 'US', 1);

      final log = (await logsFor('inflation_rates')).single;
      expect(log.action, 'delete');
      expect(log.recordId, '2024-12-04_US_1');
      expect(log.timestamp, greaterThan(0));
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
      expect(await logsFor('inflation_rates'), isEmpty);
    });

    test('deleteInflationRates writes one sync_log row per rate', () async {
      // Same reason as the single delete: a bulk clear from the inflation
      // screen would otherwise stay local and come back on the next sync.
      await seed(date: DateTime(2025, 3, 1), country: 'US', preset: 1);
      await seed(date: DateTime(2025, 3, 2), preset: 1);
      final all = await repo.getInflationRates();

      await repo.deleteInflationRates(all);

      final logs = await logsFor('inflation_rates');
      expect(logs, hasLength(2));
      expect(logs.every((l) => l.action == 'delete'), isTrue);
      expect(
        logs.map((l) => l.recordId),
        containsAll(['2025-03-01_US_1', '2025-03-02_global_1']),
      );
    });
  });

  group('the v9 -> v10 migration onto the global sentinel', () {
    // Same approach as test/core/database/schema_migrations_test.dart: this
    // repo has no `test/drift_schemas/` fixtures and no `drift_dev schema
    // dump` setup, so the v9 database is hand-built with plain
    // `package:sqlite3` in a real temp file (two connections have to see the
    // same database) and then handed to `AppDatabase`, which observes
    // `PRAGMA user_version` < `schemaVersion` and runs the real `onUpgrade`.
    // v9 == the current schema with a nullable `inflation_rates.country`.
    const createV9Sql = '''
      CREATE TABLE "languages" ("language" TEXT NOT NULL, "language_code" TEXT NOT NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, PRIMARY KEY ("language_code"));
      CREATE TABLE "currencies" ("name" TEXT NOT NULL UNIQUE, "code" TEXT NOT NULL, "language_code" TEXT NOT NULL REFERENCES languages (language_code), "type" INTEGER NOT NULL DEFAULT 6, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, PRIMARY KEY ("code"));
      CREATE TABLE "currency_designations" ("id" TEXT NOT NULL, "value" TEXT NOT NULL, "currency_code" TEXT NOT NULL REFERENCES currencies (code), "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "account_types" ("id" TEXT NOT NULL, "name" TEXT NOT NULL UNIQUE, "language_code" TEXT NOT NULL REFERENCES languages (language_code), "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "styles" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "icon_name" TEXT NOT NULL, "color_hex" TEXT NOT NULL, "icon_type" INTEGER NOT NULL DEFAULT 0, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "categories" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "parent_id" TEXT NULL REFERENCES categories (id), "style_id" TEXT NULL REFERENCES styles (id), "type" INTEGER NOT NULL DEFAULT 0, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "accounts" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "description" TEXT NULL, "balance" REAL NOT NULL, "currency_code" TEXT NOT NULL REFERENCES currencies (code), "currency_designation_id" TEXT NOT NULL REFERENCES currency_designations (id), "style_id" TEXT NULL REFERENCES styles (id), "account_type_id" TEXT NOT NULL REFERENCES account_types (id), "creation_date" INTEGER NOT NULL, "country" TEXT NULL, "asset_id" TEXT NULL, "asset_quantity" REAL NOT NULL DEFAULT 0.0, "fee_structure" TEXT NULL, "balance_minor" INTEGER NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "transactions" ("id" TEXT NOT NULL, "description" TEXT NOT NULL, "amount" REAL NOT NULL, "date" INTEGER NOT NULL, "account_id" TEXT NOT NULL REFERENCES accounts (id), "category_id" TEXT NOT NULL REFERENCES categories (id), "currency_code" TEXT NOT NULL REFERENCES currencies (code), "exchange_rate" REAL NULL, "exchange_rate_preset" INTEGER NULL, "fee" REAL NOT NULL DEFAULT 0.0, "linked_transaction_id" TEXT NULL, "amount_minor" INTEGER NULL, "fee_minor" INTEGER NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "exchange_rates" ("from_currency_code" TEXT NOT NULL REFERENCES currencies (code), "to_currency_code" TEXT NOT NULL REFERENCES currencies (code), "rate" REAL NOT NULL, "preset" INTEGER NOT NULL, "date" INTEGER NOT NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "source_id" TEXT NULL, PRIMARY KEY ("from_currency_code", "to_currency_code", "date", "preset"));
      CREATE TABLE "inflation_rates" ("date" INTEGER NOT NULL, "percent" REAL NOT NULL, "country" TEXT NULL, "preset" INTEGER NOT NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "source_id" TEXT NULL, PRIMARY KEY ("date", "country", "preset"));
      CREATE TABLE "asset_entries" ("id" TEXT NOT NULL, "asset_id" TEXT NOT NULL, "name" TEXT NOT NULL, "date" INTEGER NOT NULL, "value" REAL NOT NULL, "quantity" REAL NOT NULL DEFAULT 1.0, "asset_type" TEXT NULL, "description" TEXT NULL, "currency_code" TEXT NOT NULL REFERENCES currencies (code), "account_id" TEXT NULL REFERENCES accounts (id), "source" TEXT NOT NULL, "preset" INTEGER NOT NULL DEFAULT 1, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "source_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "settings" ("key" TEXT NOT NULL, "value" TEXT NOT NULL, "device" TEXT NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, PRIMARY KEY ("key"));
      CREATE TABLE "custom_themes" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "primary_color_hex" TEXT NOT NULL, "secondary_color_hex" TEXT NOT NULL, "surface_color_hex" TEXT NOT NULL, "background_color_hex" TEXT NOT NULL, "background_image_path" TEXT NULL, "background_image_opacity" REAL NOT NULL DEFAULT 1.0, "background_image_blur" REAL NOT NULL DEFAULT 0.0, "window_effect_type" INTEGER NOT NULL, "effect_opacity" REAL NOT NULL DEFAULT 1.0, "surface_opacity" REAL NOT NULL DEFAULT 1.0, "theme_mode" INTEGER NOT NULL, "is_preset" INTEGER NOT NULL DEFAULT 0, "is_active" INTEGER NOT NULL DEFAULT 0, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "sync_log" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "changed_table_name" TEXT NOT NULL, "record_id" TEXT NOT NULL, "action" TEXT NOT NULL, "timestamp" INTEGER NOT NULL, "exported" INTEGER NOT NULL DEFAULT 0);
      CREATE TABLE "conflict_history" ("id" TEXT NOT NULL, "changed_table_name" TEXT NOT NULL, "record_id" TEXT NOT NULL, "rejected_data" TEXT NOT NULL, "rejected_at" INTEGER NOT NULL, "rejected_device" TEXT NULL, PRIMARY KEY ("id"));
      CREATE TABLE "custom_data_sources" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "url" TEXT NOT NULL, "data_type" INTEGER NOT NULL, "enabled" INTEGER NOT NULL DEFAULT 1, "auto_fetch" INTEGER NOT NULL DEFAULT 0, "last_fetch_at" INTEGER NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "api_settings_table" ("id" TEXT NOT NULL, "enabled" INTEGER NOT NULL DEFAULT 1, "auto_fetch" INTEGER NOT NULL DEFAULT 0, "last_fetch_at" INTEGER NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, PRIMARY KEY ("id"));
      CREATE TABLE "api_fetch_statuses" ("id" TEXT NOT NULL, "attempts" INTEGER NOT NULL DEFAULT 0, "last_attempt" INTEGER NULL, "status" TEXT NOT NULL DEFAULT 'pending', PRIMARY KEY ("id"));
      CREATE TABLE "sms_presets" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "sender_filter" TEXT NOT NULL, "is_built_in" INTEGER NOT NULL DEFAULT 0, "is_enabled" INTEGER NOT NULL DEFAULT 1, "default_account_id" TEXT NULL, "default_category_id" TEXT NULL, "rules_json" TEXT NOT NULL, "modified_at" INTEGER NOT NULL DEFAULT 0, "device_id" TEXT NULL, "is_deleted" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
      CREATE TABLE "sync_processed_files" ("file_name" TEXT NOT NULL, "processed_at" INTEGER NOT NULL, "device_id" TEXT NOT NULL, PRIMARY KEY ("file_name"));
    ''';

    // `date` is stored the way drift stores a DateTimeColumn: unix seconds.
    const januarySeconds = 1704067200; // 2024-01-01T00:00:00Z
    const februarySeconds = 1706745600; // 2024-02-01T00:00:00Z
    final january = DateTime.fromMillisecondsSinceEpoch(januarySeconds * 1000);

    // Three worldwide rows for the same month - the pile-up a nullable country
    // allowed - plus a country row for that month that must survive untouched.
    const seedSql = '''
      INSERT INTO inflation_rates (date, percent, country, preset, modified_at) VALUES ($januarySeconds, 1.0, NULL, 1, 100);
      INSERT INTO inflation_rates (date, percent, country, preset, modified_at) VALUES ($januarySeconds, 2.0, NULL, 1, 300);
      INSERT INTO inflation_rates (date, percent, country, preset, modified_at) VALUES ($januarySeconds, 3.0, NULL, 1, 200);
      INSERT INTO inflation_rates (date, percent, country, preset, modified_at) VALUES ($januarySeconds, 9.0, 'US', 1, 50);
      INSERT INTO inflation_rates (date, percent, country, preset, modified_at) VALUES ($februarySeconds, 4.0, NULL, 2, 10);
    ''';

    late Directory tempDir;
    late AppDatabase migrated;
    late LocalInflationRepository migratedRepo;

    setUpAll(() async {
      tempDir = Directory.systemTemp.createTempSync('mybudget_inflation_v10');
      final file = File('${tempDir.path}/v9.sqlite');
      final raw = sqlite3.sqlite3.open(file.path);
      raw.execute(createV9Sql);
      raw.execute(seedSql);
      raw.execute('PRAGMA user_version = 9;');
      raw.dispose();

      migrated = AppDatabase.forTesting(NativeDatabase(file));
      migratedRepo = LocalInflationRepository(migrated.inflationRatesDao);
      // Force the migration to run by touching the db.
      await migrated.customSelect('SELECT 1').get();
    });

    tearDownAll(() async {
      await migrated.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('completes v9->v10 and lands on schemaVersion 10', () async {
      final versionRow = await migrated
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(versionRow.data['user_version'], 10);
    });

    test('country ends up NOT NULL with the global default', () async {
      final columns = await migrated
          .customSelect("PRAGMA table_info('inflation_rates')")
          .get();
      final country = columns.firstWhere(
        (r) => r.data['name'] == 'country',
      );

      expect(country.data['notnull'], 1);
      expect(country.data['dflt_value'], "'global'");
      expect(country.data['pk'], isNot(0)); // still part of the primary key
    });

    test('rows that were only distinct by NULL-ness collapse to the newest '
        'modified_at', () async {
      final worldwide = await migratedRepo.getInflationRatesFiltered(
        countries: [globalInflationCountry],
        dateFrom: january,
        dateTo: january,
      );

      expect(worldwide, hasLength(1));
      expect(worldwide.single.percent, 2.0);
    });

    test('a migrated worldwide rate reads back with no country, and the '
        'country row beside it is untouched', () async {
      final rates = await migratedRepo.getInflationRates();

      expect(rates, hasLength(3));
      expect(rates.where((r) => r.country == null), hasLength(2));
      expect(rates.singleWhere((r) => r.country == 'US').percent, 9.0);
    });

    test('a worldwide month can no longer be inserted twice after the '
        'migration', () async {
      await migratedRepo.addInflationRate(
        InflationRateDomain(date: january, preset: 1, percent: 7.0),
      );

      final worldwide = await migratedRepo.getInflationRatesFiltered(
        countries: [globalInflationCountry],
        dateFrom: january,
        dateTo: january,
      );
      expect(worldwide, hasLength(1));
      expect(worldwide.single.percent, 7.0);
    });
  });
}
