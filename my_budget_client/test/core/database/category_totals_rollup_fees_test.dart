import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart'
    hide Transaction;

/// What a category total is made of: the transactions filed under everything
/// below it, and the commissions those transactions cost.
///
/// Both were missing. `GROUP BY t.category_id` rolled nothing up, so a parent
/// that exists purely to group its children showed 0.00 while its children
/// held real money; and `fee`/`fee_minor` were never added to anything, so a
/// category disagreed with what the account actually moved by the sum of its
/// commissions.
///
/// The tree here is three deep on purpose - a rollup that only climbs one
/// level passes a two-level fixture.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  const eur = 'EUR';

  setUpAll(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());

    await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: const Value('rf_acc'),
            name: 'Acc',
            balance: 0,
            currencyCode: eur,
            currencyDesignationId: (await db
                .select(db.currencyDesignations)
                .get()).first.id,
            accountTypeId: (await db.select(db.accountTypes).get()).first.id,
            creationDate: Value(DateTime(2020, 1, 1)),
          ),
        );

    Future<void> category(String id, {String? parent}) => db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: Value(id),
            name: id,
            parentId: Value(parent),
          ),
        );

    // root
    //  |- mid            <- has money of its own as well as children
    //  |   |- leaf
    //  |   \- leaf_gone  <- soft deleted
    //  \- sibling
    // orphan             <- no parent at all
    await category('rf_root');
    await category('rf_mid', parent: 'rf_root');
    await category('rf_leaf', parent: 'rf_mid');
    await category('rf_leaf_gone', parent: 'rf_mid');
    await category('rf_sibling', parent: 'rf_root');
    await category('rf_orphan');
    await category('rf_fee_only');

    await (db.update(db.categories)
          ..where((c) => c.id.equals('rf_leaf_gone')))
        .write(const CategoriesCompanion(isDeleted: Value(true)));

    var counter = 0;
    Future<void> tx(
      String category,
      double amount, {
      double fee = 0.0,
      bool deleted = false,
    }) => db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: Value('rf_tx_${counter++}'),
            description: category,
            amount: amount,
            fee: Value(fee),
            date: DateTime(2024, 5, 5),
            accountId: 'rf_acc',
            categoryId: category,
            currencyCode: eur,
            isDeleted: Value(deleted),
          ),
        );

    await tx('rf_leaf', -100.0);
    await tx('rf_leaf_gone', -7.0);
    await tx('rf_mid', -20.0);
    await tx('rf_sibling', -5.0);
    await tx('rf_root', -1.0);
    await tx('rf_orphan', -50.0);
    // Income with a commission, so the sign handling is pinned in both
    // directions rather than only on expenses.
    await tx('rf_fee_only', 100.0, fee: 3.0);
    // Soft deleted: must not reach any level of the tree.
    await tx('rf_sibling', -1000.0, deleted: true);
  });

  tearDownAll(() async => db.close());

  Future<Map<String, double>> totals() => db.transactionsDao
      .getCategoryTotalsInMainCurrency(mainCurrencyCode: eur);

  test('a leaf still reports only its own transactions', () async {
    expect((await totals())['rf_leaf'], closeTo(-100.0, 0.0001));
  });

  test('a parent adds its children to what is pinned directly to it', () async {
    // mid: own -20, leaf -100, leaf_gone -7.
    expect((await totals())['rf_mid'], closeTo(-127.0, 0.0001));
  });

  test('the rollup climbs more than one level', () async {
    // root: own -1, mid subtree -127, sibling -5.
    expect((await totals())['rf_root'], closeTo(-133.0, 0.0001));
  });

  test('a category with no parent is unaffected', () async {
    expect((await totals())['rf_orphan'], closeTo(-50.0, 0.0001));
  });

  test('a soft deleted child still rolls up into its live parent', () async {
    // The money left the account. Skipping it because the label it was filed
    // under is gone would make the parent disagree with the account.
    final result = await totals();
    expect(result['rf_leaf_gone'], closeTo(-7.0, 0.0001));
    expect(result['rf_mid'], closeTo(-127.0, 0.0001));
  });

  test('a soft deleted transaction reaches no level of the tree', () async {
    final result = await totals();
    expect(result['rf_sibling'], closeTo(-5.0, 0.0001));
    expect(result['rf_root'], closeTo(-133.0, 0.0001));
  });

  test('a fee is taken off an income rather than added to it', () async {
    // 100 earned, 3 paid to earn it.
    expect((await totals())['rf_fee_only'], closeTo(97.0, 0.0001));
  });

  test('a fee deepens an expense', () async {
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: const Value('rf_tx_fee_expense'),
            description: 'fee expense',
            amount: -40.0,
            fee: const Value(2.0),
            date: DateTime(2024, 5, 6),
            accountId: 'rf_acc',
            categoryId: 'rf_orphan',
            currencyCode: eur,
          ),
        );

    // -50 already there, then -40 with a 2 commission.
    expect((await totals())['rf_orphan'], closeTo(-92.0, 0.0001));

    await (db.delete(db.transactions)
          ..where((t) => t.id.equals('rf_tx_fee_expense')))
        .go();
  });
}
