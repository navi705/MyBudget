import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart'
    hide Transaction;

/// The rows the accounts screen used to fetch and immediately throw away.
///
/// `calculatePeriodStats` skips every transfer and every row on an asset
/// account before it looks at anything else, but the fetch behind it had no way
/// to say so: the positive `accountId` filter can only name what to keep, and
/// naming "everything except the asset accounts" means listing every other
/// account - a list that grows as the person adds accounts. So the period fetch
/// shipped those rows across drift's isolate port, one serialization each, for
/// the calculator to drop.
///
/// These tests pin the two exclusion filters that let the drop happen in SQL,
/// and - the part that actually matters - that they drop nothing else.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  const eur = 'EUR';

  setUpAll(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());

    final designationId = (await db.select(db.currencyDesignations).get())
        .first
        .id;
    final accountTypeId = (await db.select(db.accountTypes).get()).first.id;

    Future<void> account(String id) => db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: Value(id),
            name: id,
            balance: 0,
            currencyCode: eur,
            currencyDesignationId: designationId,
            accountTypeId: accountTypeId,
            creationDate: Value(DateTime(2020, 1, 1)),
          ),
        );

    await account('ex_cash');
    await account('ex_bank');
    await account('ex_asset');

    Future<void> category(String id) => db
        .into(db.categories)
        .insert(CategoriesCompanion.insert(id: Value(id), name: id));

    await category('ex_food');
    await category('ex_salary');
    await category('ex_transfer');

    var counter = 0;
    Future<void> tx(String account, String category, double amount) => db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: Value('ex_tx_${counter++}'),
            description: '$account/$category',
            amount: amount,
            date: DateTime(2024, 5, 5),
            accountId: account,
            categoryId: category,
            currencyCode: eur,
          ),
        );

    await tx('ex_cash', 'ex_food', -10.0);
    await tx('ex_cash', 'ex_transfer', -20.0);
    await tx('ex_bank', 'ex_salary', 30.0);
    await tx('ex_bank', 'ex_transfer', -40.0);
    await tx('ex_asset', 'ex_food', -50.0);
    // An asset-account row that is ALSO a transfer, so a filter that OR-ed the
    // two exclusions instead of AND-ing the survivors would still pass.
    await tx('ex_asset', 'ex_transfer', -60.0);
  });

  tearDownAll(() async => db.close());

  Future<Set<String>> descriptions({
    List<String>? excludeAccountId,
    List<String>? excludeCategoryId,
    List<String>? accountId,
  }) async {
    final rows = await db.transactionsDao.getTransactionsWithFilters(
      accountId: accountId,
      excludeAccountId: excludeAccountId,
      excludeCategoryId: excludeCategoryId,
    );
    return rows.map((r) => r.description).toSet();
  }

  test('no exclusions returns everything', () async {
    expect(await descriptions(), hasLength(6));
  });

  test('an excluded account drops its rows and nothing else', () async {
    expect(await descriptions(excludeAccountId: ['ex_asset']), {
      'ex_cash/ex_food',
      'ex_cash/ex_transfer',
      'ex_bank/ex_salary',
      'ex_bank/ex_transfer',
    });
  });

  test('an excluded category drops its rows across all accounts', () async {
    expect(await descriptions(excludeCategoryId: ['ex_transfer']), {
      'ex_cash/ex_food',
      'ex_bank/ex_salary',
      'ex_asset/ex_food',
    });
  });

  test('both exclusions together leave only what the stats read', () async {
    // Exactly the set `calculatePeriodStats` would still be holding after its
    // own two `continue`s.
    expect(
      await descriptions(
        excludeAccountId: ['ex_asset'],
        excludeCategoryId: ['ex_transfer'],
      ),
      {'ex_cash/ex_food', 'ex_bank/ex_salary'},
    );
  });

  test('exclusions compose with the positive account filter', () async {
    expect(
      await descriptions(
        accountId: ['ex_cash', 'ex_bank'],
        excludeCategoryId: ['ex_transfer'],
      ),
      {'ex_cash/ex_food', 'ex_bank/ex_salary'},
    );
  });

  test('an empty exclusion list excludes nothing', () async {
    // The bloc passes the list it built without checking it: an account set
    // with no asset accounts in it hands over `[]`, and that must not be read
    // as `NOT IN ()`.
    expect(
      await descriptions(excludeAccountId: const [], excludeCategoryId: const []),
      hasLength(6),
    );
  });

  test('excluding an id that matches nothing is a no-op', () async {
    expect(
      await descriptions(excludeAccountId: ['ex_nonexistent']),
      hasLength(6),
    );
  });
}
