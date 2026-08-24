// What the import actually writes into the database.
//
// A OneMoney export states an expense as a negative number - that is what the
// column says and what the parser keeps - and the import negated it again on
// the way in. Every imported expense therefore arrived as a positive amount:
// groceries, rent and fuel all added money to the account they were spent
// from, and the balance the same file states at the bottom no longer matched
// anything the app could compute. Nothing on screen said so; the import
// reported the rows as imported, because they were.
//
// These drive the whole flow - parse, three mapping steps, duplicate check,
// write - because the sign is decided at the last of those and the earlier
// steps are what put the record there.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_budget_client/core/constants/app_constants.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/core/utils/import_file_data.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/account_type.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/currency_designation.dart';
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

/// Every account and category the files below name already exists, so the
/// mapping steps have nothing to ask and the flow runs to the end on its own.
final _wallet = Account(
  id: 'a1',
  name: 'Кошелёк',
  balance: 0,
  currencyCode: 'EUR',
  currencyDesignationId: 'd1',
  accountTypeId: 't1',
  creationDate: DateTime(2024, 1, 1),
);

final _savings = Account(
  id: 'a2',
  name: 'Накопления',
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
final _transferCategory = Category(
  id: 'c-transfer',
  name: AppConstants.systemTransferCategoryName,
  type: CategoryType.transfer,
);

class _FakeAccountRepository extends Fake implements AccountRepository {
  final updated = <Account>[];

  @override
  Future<List<Account>> getAccounts() async => [
    _wallet,
    _savings,
    ...created,
  ];

  @override
  Future<List<AccountType>> getAccountTypes() async => const [
    AccountType(id: 'default_cash', name: 'Cash', languageCode: 'en'),
  ];

  final created = <Account>[];

  /// The database hands the row an id on insert, and the import reads the
  /// accounts back to find it - so a fake that swallowed the insert would
  /// leave the rows for a new account looking unmapped.
  @override
  Future<void> addAccounts(List<Account> accounts) async => created.addAll(
    accounts.map(
      (a) => a.copyWith(id: 'created-${a.name.toLowerCase()}'),
    ),
  );

  @override
  Future<void> updateAccount(Account account) async => updated.add(account);
}

class _FakeCategoryRepository extends Fake implements CategoryRepository {
  @override
  Future<List<Category>> getCategories({bool includeSystem = false}) async =>
      includeSystem
      ? [_groceries, _salary, _transferCategory]
      : [_groceries, _salary];

  @override
  Future<void> addCategory(Category category) async {}

  @override
  Future<void> addCategories(List<Category> categories) async {}
}

class _FakeCurrencyRepository extends Fake implements CurrencyRepository {
  /// Currencies the import creates land here, the way they land in the
  /// database: the steps that follow read them back out of the repository.
  final List<Currency> currencies = [
    const Currency(
      name: 'Euro',
      code: 'EUR',
      languageCode: 'en',
      type: TypeCurrency.currency,
    ),
  ];

  final List<CurrencyDesignation> designations = [
    const CurrencyDesignation(id: 'd1', value: '€', currencyCode: 'EUR'),
  ];

  @override
  Future<List<Currency>> getCurrencies() async => List.of(currencies);

  @override
  Future<List<CurrencyDesignation>> getAllCurrencyDesignations() async =>
      List.of(designations);

  @override
  Future<void> addCurrency(Currency currency) async =>
      currencies.add(currency);

  @override
  Future<void> addCurrencyDesignation(
    CurrencyDesignation designation,
  ) async => designations.add(designation);
}

class _FakeTransactionRepository extends Fake implements TransactionRepository {
  final inserted = <Transaction>[];

  /// Nothing in the database yet, so nothing the import reads is a duplicate
  /// of it and the flow does not stop to ask.
  @override
  Future<List<Transaction>> getTransactionsWithFilters({
    int limit = 10,
    int offset = 0,
    Sort sort = Sort.descending,
    TransactionFilters? filters,
  }) async => const [];

  @override
  Future<void> addTransactions(List<Transaction> transactions) async =>
      inserted.addAll(transactions);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async => initializeDateFormatting());

  late ImportBloc bloc;
  late _FakeTransactionRepository transactions;
  late _FakeAccountRepository accounts;
  late _FakeCurrencyRepository currencies;

  setUp(() {
    transactions = _FakeTransactionRepository();
    accounts = _FakeAccountRepository();
    currencies = _FakeCurrencyRepository();
    bloc = ImportBloc(
      accountRepository: accounts,
      categoryRepository: _FakeCategoryRepository(),
      transactionRepository: transactions,
      currencyRepository: currencies,
    );
  });

  tearDown(() => bloc.close());

  /// Runs a file all the way in and hands back the rows written.
  Future<List<Transaction>> importFile(ImportFileData file) async {
    final ready = bloc.stream.firstWhere(
      (s) => s.step == ImportStep.readyToImport,
    );
    bloc.add(StartImportProcess([file]));
    await ready;

    final done = bloc.stream.firstWhere(
      (s) => s.step == ImportStep.complete || s.step == ImportStep.failure,
    );
    bloc.add(FinalizeImport());
    final state = await done;
    expect(
      state.step,
      ImportStep.complete,
      reason: 'the import failed: ${state.errorMessage}',
    );
    return transactions.inserted;
  }

  test(
    'an expense written negative in the file is stored as money out',
    () async {
      final written = await importFile(
        _file(['15.03.2025,Расход,Кошелёк,Продукты,-12.5,EUR,,,,Хлеб']),
      );

      expect(written.single.amount, -12.5);
      expect(written.single.accountId, _wallet.id);
      expect(written.single.categoryId, _groceries.id);
    },
  );

  test('an expense written positive is stored as money out too', () async {
    // The type column is what says which way the money went; the sign in the
    // file is one export format's convention, not the other's.
    final written = await importFile(
      _file(['15.03.2025,Расход,Кошелёк,Продукты,12.5,EUR,,,,Хлеб']),
    );

    expect(written.single.amount, -12.5);
  });

  test('income is stored as money in', () async {
    final written = await importFile(
      _file(['15.03.2025,Доход,Кошелёк,Зарплата,1000,EUR,,,,Аванс']),
    );

    expect(written.single.amount, 1000);
    expect(written.single.categoryId, _salary.id);
  });

  test('a transfer leaves one account and arrives in the other', () async {
    final written = await importFile(
      _file(['15.03.2025,Перевод,Кошелёк,Накопления,-50,EUR,,,,']),
    );

    expect(written, hasLength(2));
    final sent = written.firstWhere((t) => t.accountId == _wallet.id);
    final received = written.firstWhere((t) => t.accountId == _savings.id);
    expect(sent.amount, -50);
    expect(
      received.amount,
      50,
      reason:
          'the receiving leg of a transfer is money arriving, whatever sign '
          'the file gave the row',
    );
    // Each leg names the other, which is what makes editing or deleting one
    // of them reach the other.
    expect(sent.linkedTransactionId, received.id);
    expect(received.linkedTransactionId, sent.id);
  });

  test('a cross-currency transfer credits the second amount', () async {
    final written = await importFile(
      _file(['15.03.2025,Перевод,Кошелёк,Накопления,-50,EUR,-55,USD,,']),
    );

    final sent = written.firstWhere((t) => t.accountId == _wallet.id);
    final received = written.firstWhere((t) => t.accountId == _savings.id);
    expect(sent.amount, -50);
    expect(sent.currencyCode, 'EUR');
    expect(received.amount, 55);
    expect(received.currencyCode, 'USD');
  });

  test('a whole statement keeps the balance the file states', () async {
    // The arithmetic the user checks first: start at nothing, spend, earn,
    // and the account should hold what the three rows add up to.
    final written = await importFile(
      _file([
        '15.03.2025,Расход,Кошелёк,Продукты,-12.5,EUR,,,,Хлеб',
        '16.03.2025,Доход,Кошелёк,Зарплата,1000,EUR,,,,Аванс',
        '17.03.2025,Расход,Кошелёк,Продукты,-7.5,EUR,,,,Молоко',
      ]),
    );

    final total = written.fold<double>(0, (sum, t) => sum + t.amount);
    expect(total, 980);
  });

  test('a transfer keeps the note the row carried', () async {
    // The note is the only part of the row the user wrote themselves. Both
    // legs were described in English by the account they touched instead, so
    // the transfer a person would recognise their own words on came back as
    // 'Transfer to Накопления'.
    final written = await importFile(
      _file([
        '15.03.2025,Перевод,Кошелёк,Накопления,-50,EUR,,,,На отпуск',
      ]),
    );

    expect(written, hasLength(2));
    for (final leg in written) {
      expect(leg.description, 'На отпуск');
    }
  });

  test('a transfer with no note still says which way it went', () async {
    final written = await importFile(
      _file(['15.03.2025,Перевод,Кошелёк,Накопления,-50,EUR,,,,']),
    );

    final sent = written.firstWhere((t) => t.accountId == _wallet.id);
    final received = written.firstWhere((t) => t.accountId == _savings.id);
    expect(sent.description, contains(_savings.name));
    expect(received.description, contains(_wallet.name));
  });

  group('a currency the user chooses to create from the file', () {
    /// Runs a file whose currency the app does not know, answers the mapping
    /// step with 'create it', and hands back the rows written.
    Future<List<Transaction>> importCreatingCurrency(
      ImportFileData file,
      String fileCurrency,
    ) async {
      final asked = bloc.stream.firstWhere(
        (s) => s.unmappedCurrencies.isNotEmpty,
      );
      bloc.add(StartImportProcess([file]));
      await asked;

      final ready = bloc.stream.firstWhere(
        (s) => s.step == ImportStep.readyToImport,
      );
      bloc.add(MapCurrency(fileCurrency.toLowerCase(), 'new'));
      await ready;

      final done = bloc.stream.firstWhere(
        (s) => s.step == ImportStep.complete || s.step == ImportStep.failure,
      );
      bloc.add(FinalizeImport());
      final state = await done;
      expect(
        state.step,
        ImportStep.complete,
        reason: 'the import failed: ${state.errorMessage}',
      );
      return transactions.inserted;
    }

    test('is written under the code the file gave it', () async {
      // 'new' is the answer to the mapping question, not a currency. Read back
      // as though it were one it became the row's own code: every transaction
      // in that currency was stored under NEW, a currency nothing converts,
      // totals or displays.
      final written = await importCreatingCurrency(
        _file(['15.03.2025,Расход,Кошелёк,Продукты,-12.5,XBT,,,,Хлеб']),
        'XBT',
      );

      expect(written.single.currencyCode, 'XBT');
      expect(
        currencies.currencies.map((c) => c.code),
        contains('XBT'),
        reason: 'the code the rows are stored under has to exist',
      );
    });

    test('both legs of a transfer follow the same answer', () async {
      final written = await importCreatingCurrency(
        _file(['15.03.2025,Перевод,Кошелёк,Накопления,-50,XBT,,,,']),
        'XBT',
      );

      expect(written, hasLength(2));
      for (final leg in written) {
        expect(leg.currencyCode, 'XBT');
      }
    });

    test('an account the import creates for it is not left in a currency '
        'it never held', () async {
      // A new account is given the currency of its earliest row, looked up by
      // the code that row carries. The lookup for NEW found nothing and fell
      // through to whichever currency happened to be first in the list, so
      // the account came out in a currency none of its rows were in.
      final asked = bloc.stream.firstWhere(
        (s) => s.unmappedAccounts.isNotEmpty,
      );
      bloc.add(
        StartImportProcess([
          _file(['15.03.2025,Расход,Крипта,Продукты,-12.5,XBT,,,,Хлеб']),
        ]),
      );
      final unmappedAccounts = (await asked).unmappedAccounts;

      final askedCurrency = bloc.stream.firstWhere(
        (s) => s.unmappedCurrencies.isNotEmpty,
      );
      for (final name in unmappedAccounts) {
        bloc.add(MapAccount(name, 'new'));
      }
      await askedCurrency;

      final ready = bloc.stream.firstWhere(
        (s) => s.step == ImportStep.readyToImport,
      );
      bloc.add(const MapCurrency('xbt', 'new'));
      await ready;

      final done = bloc.stream.firstWhere(
        (s) => s.step == ImportStep.complete || s.step == ImportStep.failure,
      );
      bloc.add(FinalizeImport());
      final state = await done;
      expect(
        state.step,
        ImportStep.complete,
        reason: 'the import failed: ${state.errorMessage}',
      );

      final account = accounts.created.single;
      expect(account.currencyCode, 'XBT');
      expect(
        transactions.inserted.single.accountId,
        account.id,
        reason: 'the row that made the account is the row it must hold',
      );
    });
  });
}
