// Which rows the import stops to ask about.
//
// Before writing anything, the import compares every row in the file against
// what the database already holds and asks the user about the ones that look
// like repeats. Two things were wrong with the comparison. It negated the
// amount of an expense a second time, so a spend already recorded as -12.50
// was compared against +12.50 and never matched - importing the same statement
// twice quietly doubled the spending. And it ignored the currency, so 100 EUR
// already recorded made a 100 USD row look like a repeat of it and the import
// stopped to ask about a row nobody had entered twice.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/core/utils/import_file_data.dart';
import 'package:my_budget_client/core/utils/import_utils.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/entities/transaction_type_filter.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/presentation/blocs/import/import_bloc.dart';

const _header =
    'ДАТА,ТИП,СО СЧЁТА,НА СЧЁТ / НА КАТЕГОРИЮ,СУММА,ВАЛЮТА,'
    'СУММА 2,ВАЛЮТА 2,МЕТКИ,ЗАМЕТКИ';

ImportFileData _file(List<String> rows) => ImportFileData(
  name: 'onemoney.csv',
  bytes: Uint8List.fromList(
    utf8.encode('$_header\r\n${rows.map((r) => '$r\r\n').join()}'),
  ),
);

final _wallet = Account(
  id: 'a1',
  name: 'Кошелёк',
  balance: 0,
  currencyCode: 'EUR',
  currencyDesignationId: 'd1',
  accountTypeId: 't1',
  creationDate: DateTime(2024, 1, 1),
);

final _groceries = Category(
  id: 'c1',
  name: 'Продукты',
  type: CategoryType.expense,
);

final _salary = Category(id: 'c2', name: 'Зарплата', type: CategoryType.income);

/// A row already in the database, written the way the app writes one: an
/// expense is negative.
Transaction _existing({
  required double amount,
  String currencyCode = 'EUR',
  DateTime? date,
}) => Transaction(
  id: 'existing-${amount.toStringAsFixed(2)}-$currencyCode',
  date: date ?? DateTime(2025, 3, 15),
  description: 'Хлеб',
  amount: amount,
  accountId: 'a1',
  categoryId: 'c1',
  currencyCode: currencyCode,
);

class _FakeAccountRepository extends Fake implements AccountRepository {
  @override
  Future<List<Account>> getAccounts() async => [_wallet];
}

class _FakeCategoryRepository extends Fake implements CategoryRepository {
  @override
  Future<List<Category>> getCategories({bool includeSystem = false}) async => [
    _groceries,
    _salary,
  ];
}

class _FakeCurrencyRepository extends Fake implements CurrencyRepository {
  @override
  Future<List<Currency>> getCurrencies() async => const [
    Currency(
      name: 'Euro',
      code: 'EUR',
      languageCode: 'en',
      type: TypeCurrency.currency,
    ),
    Currency(
      name: 'US Dollar',
      code: 'USD',
      languageCode: 'en',
      type: TypeCurrency.currency,
    ),
  ];
}

class _FakeTransactionRepository extends Fake implements TransactionRepository {
  _FakeTransactionRepository(this.existing);

  final List<Transaction> existing;

  @override
  Future<List<Transaction>> getTransactionsWithFilters({
    int limit = 10,
    int offset = 0,
    Sort sort = Sort.descending,
    TransactionFilters? filters,
  }) async => existing;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async => initializeDateFormatting());

  /// Reads the file in and hands back the rows the import wants asked about -
  /// empty when it went straight through to the writing step.
  Future<List<OneMoneyRecord>> duplicatesFound(
    ImportFileData file, {
    required List<Transaction> alreadyStored,
  }) async {
    final bloc = ImportBloc(
      accountRepository: _FakeAccountRepository(),
      categoryRepository: _FakeCategoryRepository(),
      transactionRepository: _FakeTransactionRepository(alreadyStored),
      currencyRepository: _FakeCurrencyRepository(),
    );
    addTearDown(bloc.close);

    final settled = bloc.stream.firstWhere(
      (s) =>
          s.step == ImportStep.readyToImport ||
          s.potentialDuplicates.isNotEmpty,
    );
    bloc.add(StartImportProcess([file]));
    return (await settled).potentialDuplicates;
  }

  test(
    'a spend already recorded is recognised in the file that repeats it',
    () async {
      final duplicates = await duplicatesFound(
        _file(['15.03.2025,Расход,Кошелёк,Продукты,-12.5,EUR,,,,Хлеб']),
        alreadyStored: [_existing(amount: -12.5)],
      );

      expect(
        duplicates,
        hasLength(1),
        reason:
            'importing the same statement twice must ask, not silently double '
            'the spending',
      );
    },
  );

  test('the same amount in another currency is another transaction', () async {
    final duplicates = await duplicatesFound(
      _file(['15.03.2025,Расход,Кошелёк,Продукты,-12.5,USD,,,,Хлеб']),
      alreadyStored: [_existing(amount: -12.5)],
    );

    expect(duplicates, isEmpty);
  });

  test('the same amount on another day is another transaction', () async {
    final duplicates = await duplicatesFound(
      _file(['16.03.2025,Расход,Кошелёк,Продукты,-12.5,EUR,,,,Хлеб']),
      alreadyStored: [_existing(amount: -12.5)],
    );

    expect(duplicates, isEmpty);
  });

  test('income already recorded is recognised as well', () async {
    final duplicates = await duplicatesFound(
      _file(['15.03.2025,Доход,Кошелёк,Зарплата,1000,EUR,,,,Аванс']),
      alreadyStored: [_existing(amount: 1000)],
    );

    expect(duplicates, hasLength(1));
  });

  test(
    'a file with nothing in common with the database goes straight through',
    () async {
      final duplicates = await duplicatesFound(
        _file(['15.03.2025,Расход,Кошелёк,Продукты,-3.5,EUR,,,,Кофе']),
        alreadyStored: [_existing(amount: -12.5)],
      );

      expect(duplicates, isEmpty);
    },
  );
}
