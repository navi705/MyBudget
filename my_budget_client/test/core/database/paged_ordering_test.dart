// Paging through a list has to show every row once.
//
// Every paginated query in the app orders by one non-unique column - accounts
// by balance, transactions by (date, amount), rates and asset entries by date -
// and stops there. Rows that tie on it therefore have no defined order between
// them, and SQLite is free to return them differently for `LIMIT 10 OFFSET 0`
// than for `LIMIT 10 OFFSET 10`: the two are separate queries, and a bounded
// sorter of a different size can break the tie a different way.
//
// Ties are not an edge case here. A calendar picker writes midnight, an import
// writes one date for a whole statement, and a person who buys the same coffee
// every morning writes the same amount - so a transactions list built from real
// data is mostly ties. When the tie falls the wrong way the second page repeats
// a row the first page already showed and silently drops another one, which on
// a transactions list means money that is in the database and nowhere on screen.
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late String designationId;
  late String accountTypeId;
  late String categoryId;

  setUp(() async {
    AppDatabase.seedExchangeRatesOnCreate = false;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.select(db.styles).get();
    designationId =
        (await db
                .customSelect('SELECT id FROM currency_designations LIMIT 1')
                .getSingle())
            .read<String>('id');
    accountTypeId =
        (await db
                .customSelect('SELECT id FROM account_types LIMIT 1')
                .getSingle())
            .read<String>('id');
    categoryId =
        (await db.customSelect('SELECT id FROM categories LIMIT 1').getSingle())
            .read<String>('id');
  });

  tearDown(() => db.close());

  /// Ids in the order paging hands them over, one page at a time, exactly the
  /// way the blocs ask for them: offset is how many rows are already on screen.
  Future<List<String>> pageThrough(
    Future<List<String>> Function(int limit, int offset) page, {
    int pageSize = 10,
  }) async {
    final seen = <String>[];
    for (var offset = 0; ; offset += pageSize) {
      final rows = await page(pageSize, offset);
      if (rows.isEmpty) break;
      seen.addAll(rows);
      if (rows.length < pageSize) break;
    }
    return seen;
  }

  void expectCoversOnce(List<String> paged, List<String> all) {
    expect(
      paged.toSet(),
      all.toSet(),
      reason: 'paging must reach every row, and only rows that exist',
    );
    expect(
      paged.length,
      all.length,
      reason:
          'a row that arrives on two pages is a row the user sees twice '
          'while another one never arrives at all',
    );
  }

  group('accounts paged by balance', () {
    test('every account arrives exactly once when balances tie', () async {
      // One balance for all of them: a fresh set of accounts opened at zero is
      // the most ordinary way to hit this.
      for (var i = 0; i < 45; i++) {
        await db.accountsDao.insertAccount(
          AccountsCompanion.insert(
            id: Value('acc-$i'),
            name: 'Account $i',
            balance: 0,
            currencyCode: 'USD',
            currencyDesignationId: designationId,
            accountTypeId: accountTypeId,
            creationDate: Value(DateTime(2024, 1, 1)),
          ),
        );
      }

      final paged = await pageThrough(
        (limit, offset) async => (await db.accountsDao.getAccountWithFilters(
          limit: limit,
          offset: offset,
        )).map((a) => a.id).toList(),
      );

      expectCoversOnce(paged, [for (var i = 0; i < 45; i++) 'acc-$i']);
    });
  });

  group('transactions paged by date and amount', () {
    setUp(() async {
      await db.accountsDao.insertAccount(
        AccountsCompanion.insert(
          id: const Value('acc-1'),
          name: 'Wallet',
          balance: 0,
          currencyCode: 'USD',
          currencyDesignationId: designationId,
          accountTypeId: accountTypeId,
          creationDate: Value(DateTime(2024, 1, 1)),
        ),
      );
    });

    test(
      'every transaction arrives exactly once when date and amount tie',
      () async {
        // The same amount on the same day, forty-five times: a statement import,
        // or a person with a habit.
        for (var i = 0; i < 45; i++) {
          await db.transactionsDao.insertTransaction(
            TransactionsCompanion.insert(
              id: Value('tx-$i'),
              description: 'Coffee $i',
              amount: -3.5,
              date: DateTime(2024, 5, 4),
              accountId: 'acc-1',
              categoryId: categoryId,
              currencyCode: 'USD',
            ),
          );
        }

        final paged = await pageThrough(
          (limit, offset) async =>
              (await db.transactionsDao.getTransactionsWithFilters(
                limit: limit,
                offset: offset,
              )).map((t) => t.id).toList(),
        );

        expectCoversOnce(paged, [for (var i = 0; i < 45; i++) 'tx-$i']);
      },
    );

    test(
      'paging is repeatable, so a page holds still while the user reads it',
      () async {
        for (var i = 0; i < 30; i++) {
          await db.transactionsDao.insertTransaction(
            TransactionsCompanion.insert(
              id: Value('tx-$i'),
              description: 'Fare $i',
              amount: -2,
              date: DateTime(2024, 5, 4),
              accountId: 'acc-1',
              categoryId: categoryId,
              currencyCode: 'USD',
            ),
          );
        }

        Future<List<String>> firstPage() async =>
            (await db.transactionsDao.getTransactionsWithFilters(
              limit: 10,
            )).map((t) => t.id).toList();

        // Same query, twice: a reload, a stream tick, a pull-to-refresh.
        expect(await firstPage(), await firstPage());
      },
    );
  });

  group('exchange rates paged by date', () {
    test('every rate arrives exactly once when dates tie', () async {
      for (var i = 0; i < 45; i++) {
        await db
            .into(db.exchangeRates)
            .insert(
              ExchangeRatesCompanion.insert(
                fromCurrencyCode: 'USD',
                toCurrencyCode: 'EUR',
                rate: 1 + i / 1000,
                date: DateTime(2024, 5, 4),
                preset: i,
              ),
            );
      }

      final paged = await pageThrough(
        (limit, offset) async =>
            (await db.exchangeRatesDao.getExchangeRatesFiltered(
              limit: limit,
              offset: offset,
            )).map((r) => '${r.preset}').toList(),
      );

      expectCoversOnce(paged, [for (var i = 0; i < 45; i++) '$i']);
    });
  });

  group('inflation rates paged by date', () {
    test('every rate arrives exactly once when dates tie', () async {
      // One month, several countries, several sources: the date is the same for
      // all of them by construction.
      const countries = ['SRB', 'USA', 'DEU'];
      for (var i = 0; i < 45; i++) {
        await db
            .into(db.inflationRates)
            .insert(
              InflationRatesCompanion.insert(
                date: DateTime(2024, 5, 1),
                percent: 1 + i / 100,
                country: Value(countries[i % countries.length]),
                preset: i,
              ),
            );
      }

      final paged = await pageThrough(
        (limit, offset) async =>
            (await db.inflationRatesDao.getInflationRatesFiltered(
              limit: limit,
              offset: offset,
            )).map((r) => '${r.country}-${r.preset}').toList(),
      );

      expectCoversOnce(paged, [
        for (var i = 0; i < 45; i++) '${countries[i % countries.length]}-$i',
      ]);
    });
  });

  group('asset entries paged by date', () {
    test('every entry arrives exactly once when dates tie', () async {
      for (var i = 0; i < 45; i++) {
        await db
            .into(db.assetEntries)
            .insert(
              AssetEntriesCompanion.insert(
                id: Value('asset-$i'),
                assetId: 'gold',
                name: 'Gold',
                date: DateTime(2024, 5, 4),
                value: 100,
                currencyCode: 'USD',
                source: 'manual',
              ),
            );
      }

      final paged = await pageThrough(
        (limit, offset) async => (await db.assetEntriesDao.getAssetData(
          limit: limit,
          offset: offset,
        )).map((e) => e.id).toList(),
      );

      expectCoversOnce(paged, [for (var i = 0; i < 45; i++) 'asset-$i']);
    });
  });
}
