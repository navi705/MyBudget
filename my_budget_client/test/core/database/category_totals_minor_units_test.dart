import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart'
    hide Transaction;

/// Category totals added up in integer minor units instead of REAL.
///
/// The screen's numbers are money, and money in this schema is a hybrid: fiat
/// rows carry exact minor units alongside the double, non-fiat rows carry only
/// the double. The aggregate summed the double for everything, so a category
/// with a few hundred ordinary purchases in it came back a hair off the sum of
/// its own transactions - and, worse, off by a DIFFERENT hair than its parent,
/// because the parent adds up a different set of rows in a different order.
///
/// So the rows that can be exact are now summed as integers and divided once,
/// and only what genuinely cannot be exact - foreign currency, crypto - stays
/// in floating point.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  late String designationId;
  late String accountTypeId;

  var counter = 0;

  Future<void> account(String id, String currency) => db
      .into(db.accounts)
      .insert(
        AccountsCompanion.insert(
          id: Value(id),
          name: id,
          balance: 0,
          currencyCode: currency,
          currencyDesignationId: designationId,
          accountTypeId: accountTypeId,
          creationDate: Value(DateTime(2020, 1, 1)),
        ),
      );

  Future<void> category(String id) => db
      .into(db.categories)
      .insert(CategoriesCompanion.insert(id: Value(id), name: id));

  Future<void> tx(
    String account,
    String category,
    String currency,
    double amount, {
    int? amountMinor,
    double fee = 0.0,
    int? feeMinor,
  }) => db
      .into(db.transactions)
      .insert(
        TransactionsCompanion.insert(
          id: Value('mu_tx_${counter++}'),
          description: category,
          amount: amount,
          amountMinor: Value(amountMinor),
          fee: Value(fee),
          feeMinor: Value(feeMinor),
          date: DateTime(2024, 5, 5),
          accountId: account,
          categoryId: category,
          currencyCode: currency,
        ),
      );

  setUpAll(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    designationId = (await db.select(db.currencyDesignations).get()).first.id;
    accountTypeId = (await db.select(db.accountTypes).get()).first.id;

    await account('mu_eur', 'EUR');
    await account('mu_jpy', 'JPY');
    await account('mu_kwd', 'KWD');
    await account('mu_btc', 'BTC');

    for (final c in [
      'mu_many',
      'mu_fee',
      'mu_fee_legacy',
      'mu_legacy',
      'mu_jpy_cat',
      'mu_kwd_cat',
      'mu_btc_cat',
    ]) {
      await category(c);
    }

    // A thousand ten-cent purchases. Ten cents is not representable in binary,
    // so a REAL accumulator lands near -100 and not on it.
    await db.batch((b) {
      for (var i = 0; i < 1000; i++) {
        b.insert(
          db.transactions,
          TransactionsCompanion.insert(
            id: Value('mu_many_$i'),
            description: 'mu_many',
            amount: -0.10,
            amountMinor: const Value(-10),
            date: DateTime(2024, 5, 5),
            accountId: 'mu_eur',
            categoryId: 'mu_many',
            currencyCode: 'EUR',
          ),
        );
      }
    });

    // Fee with its own minor units: stays on the exact path.
    await tx('mu_eur', 'mu_fee', 'EUR', 100.0, amountMinor: 10000,
        fee: 0.03, feeMinor: 3);
    // Fee WITHOUT minor units - a row written before the column existed. Must
    // fall to the double branch rather than lose the commission.
    await tx('mu_eur', 'mu_fee_legacy', 'EUR', 100.0, amountMinor: 10000,
        fee: 0.03);
    // No minor units at all: the same fallback, for the amount itself.
    await tx('mu_eur', 'mu_legacy', 'EUR', -12.34);

    await tx('mu_jpy', 'mu_jpy_cat', 'JPY', 500.0, amountMinor: 500);
    await tx('mu_kwd', 'mu_kwd_cat', 'KWD', -1.234, amountMinor: -1234);
    await tx('mu_btc', 'mu_btc_cat', 'BTC', -0.5);
  });

  tearDownAll(() async => db.close());

  Future<Map<String, double>> totals(String main) => db.transactionsDao
      .getCategoryTotalsInMainCurrency(mainCurrencyCode: main);

  test('a thousand ten-cent rows come back exact, not near-exact', () async {
    // What the old REAL accumulator was doing, for the record:
    var drifting = 0.0;
    for (var i = 0; i < 1000; i++) {
      drifting -= 0.10;
    }
    expect(drifting, isNot(-100.0));

    expect((await totals('EUR'))['mu_many'], -100.0);
  });

  test('an exact fee is subtracted in minor units', () async {
    expect((await totals('EUR'))['mu_fee'], 99.97);
  });

  test('a fee with no minor units still counts, via the double branch', () async {
    expect((await totals('EUR'))['mu_fee_legacy'], closeTo(99.97, 0.0001));
  });

  test('a row with no minor units at all still counts', () async {
    expect((await totals('EUR'))['mu_legacy'], closeTo(-12.34, 0.0001));
  });

  test('a zero-decimal main currency scales by 1', () async {
    // Divided by a hardwired 100 this would read 5 yen.
    expect((await totals('JPY'))['mu_jpy_cat'], 500.0);
  });

  test('a three-decimal main currency scales by 1000', () async {
    expect((await totals('KWD'))['mu_kwd_cat'], -1.234);
  });

  test('a non-fiat main currency falls to the double branch', () async {
    // BTC rows carry no amountMinor, so nothing here can be exact - and the
    // total must still be right.
    expect((await totals('BTC'))['mu_btc_cat'], closeTo(-0.5, 1e-9));
  });

  test('a category with no exact rows is not zeroed by the exact half', () async {
    // The exact aggregate is COALESCEd to 0 for these; the double half carries
    // the whole answer, and the two must add rather than one masking the other.
    final t = await totals('EUR');
    expect(t['mu_legacy'], isNot(0.0));
    expect(t['mu_btc_cat'], isNot(0.0));
  });
}
