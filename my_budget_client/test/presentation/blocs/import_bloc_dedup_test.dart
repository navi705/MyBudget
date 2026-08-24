// Importing a statement must not quietly throw rows away.
//
// The same file can be picked twice - two exports of one month overlap, or the
// user simply selects the file again - so the import drops rows it has already
// read. Which rows count as "already read" was decided by date, amount, from
// and to alone, and that is not what makes a transaction distinct: two fares of
// the same price on the same day differ only in their note, and 100 USD and
// 100 EUR spent the same day differ only in their currency. Both pairs
// collapsed into one row, and the import reported success while the money went
// missing.
//
// The flow is stopped at the first mapping step - the accounts repository knows
// no account named in the file - because everything under test has already
// happened by then: parsing, deduplication and the records landing in state.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_budget_client/core/utils/import_file_data.dart';
import 'package:my_budget_client/core/utils/import_utils.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/presentation/blocs/import/import_bloc.dart';

const _header =
    'ДАТА,ТИП,СО СЧЁТА,НА СЧЁТ / НА КАТЕГОРИЮ,СУММА,ВАЛЮТА,'
    'СУММА 2,ВАЛЮТА 2,МЕТКИ,ЗАМЕТКИ';

/// A OneMoney export, written the way a spreadsheet writes one.
ImportFileData _file(List<String> rows, {String name = 'onemoney.csv'}) =>
    ImportFileData(
      name: name,
      bytes: Uint8List.fromList(
        utf8.encode('$_header\r\n${rows.map((r) => '$r\r\n').join()}'),
      ),
    );

/// One expense row, with only the fields a test varies spelled out.
String _row({
  String date = '15.03.2025',
  String from = 'Кошелёк',
  String to = 'Продукты',
  String amount = '-12.5',
  String currency = 'EUR',
  String notes = '',
}) => '$date,Расход,$from,$to,$amount,$currency,,,,$notes';

/// No account matches the file, so the import stops and asks - which is where
/// the parsed records can be read.
class _FakeAccountRepository extends Fake implements AccountRepository {
  @override
  Future<List<Account>> getAccounts() async => const [];
}

class _FakeCategoryRepository extends Fake implements CategoryRepository {}

class _FakeTransactionRepository extends Fake
    implements TransactionRepository {}

class _FakeCurrencyRepository extends Fake implements CurrencyRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The date column is parsed with a locale-pinned DateFormat.
  setUpAll(() async => initializeDateFormatting());

  late ImportBloc bloc;

  setUp(() {
    bloc = ImportBloc(
      accountRepository: _FakeAccountRepository(),
      categoryRepository: _FakeCategoryRepository(),
      transactionRepository: _FakeTransactionRepository(),
      currencyRepository: _FakeCurrencyRepository(),
    );
  });

  tearDown(() => bloc.close());

  /// Feeds the files in and hands back the rows the import decided to keep.
  Future<List<OneMoneyRecord>> importedRecords(List<ImportFileData> files) {
    final done = bloc.stream.firstWhere(
      (s) => s.step == ImportStep.mappingAccounts && s.parsedRecords.isNotEmpty,
    );
    bloc.add(StartImportProcess(files));
    return done.then((s) => s.parsedRecords);
  }

  test('two identical rows in one file are two transactions', () async {
    // The same fare twice in a day, or the same coffee: the file says it
    // happened twice, so it happened twice.
    final records = await importedRecords([
      _file([_row(amount: '-2'), _row(amount: '-2')]),
    ]);

    expect(records, hasLength(2));
  });

  test('the same file picked twice imports each row once', () async {
    final rows = [
      _row(amount: '-2', notes: 'Автобус'),
      _row(amount: '-12.5', notes: 'Хлеб'),
    ];
    final records = await importedRecords([
      _file(rows),
      _file(rows, name: 'onemoney (1).csv'),
    ]);

    expect(records, hasLength(2));
    expect(records.map((r) => r.notes), ['Автобус', 'Хлеб']);
  });

  test('a row repeated within a file survives the file being picked twice', () {
    // Two of one row and one of another, in both copies of the file: the
    // overlap collapses, the genuine repeat does not.
    final rows = [
      _row(amount: '-2'),
      _row(amount: '-2'),
      _row(amount: '-12.5'),
    ];

    return importedRecords([
      _file(rows),
      _file(rows, name: 'onemoney (1).csv'),
    ]).then((records) {
      expect(records, hasLength(3));
      expect(records.where((r) => r.amount == -2), hasLength(2));
    });
  });

  test('rows that differ only in their note are both kept', () async {
    final records = await importedRecords([
      _file([_row(notes: 'Хлеб'), _row(notes: 'Молоко')]),
    ]);

    expect(records.map((r) => r.notes), ['Хлеб', 'Молоко']);
  });

  test('rows that differ only in their currency are both kept', () async {
    // 100 spent in two currencies on one day is two different amounts of
    // money, however alike the two lines look.
    final records = await importedRecords([
      _file([
        _row(amount: '-100', currency: 'EUR'),
        _row(amount: '-100', currency: 'USD'),
      ]),
    ]);

    expect(records.map((r) => r.currency), ['EUR', 'USD']);
  });

  test('rows that differ only in their category are both kept', () async {
    final records = await importedRecords([
      _file([_row(to: 'Продукты'), _row(to: 'Транспорт')]),
    ]);

    expect(records.map((r) => r.to), ['Продукты', 'Транспорт']);
  });

  test('the rows arrive in the order the statement lists them', () async {
    // An import that reorders rows is an import the user cannot check against
    // the file it came from.
    final records = await importedRecords([
      _file([
        _row(date: '15.03.2025', notes: 'первая'),
        _row(date: '01.03.2025', notes: 'вторая'),
        _row(date: '20.03.2025', notes: 'третья'),
      ]),
    ]);

    expect(records.map((r) => r.notes), ['первая', 'вторая', 'третья']);
  });
}
