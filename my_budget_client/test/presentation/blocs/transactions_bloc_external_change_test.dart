// The transaction list has to notice a write it did not make itself.
//
// The screen only loads from a cold state, so a sync pull, an SMS import or a
// restore reaches the list through one table signal. The bloc swallows exactly
// one such signal after each of its own writes, because its own write handlers
// already reload the list. That suppression used to be a plain flag armed on
// dispatch: a write that ended in its catch block never caused a signal, so
// the flag stayed armed for the life of the screen and the next signal it
// swallowed belonged to a pull. The peer's transactions then stayed off the
// list until something else happened to write.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart'
    hide Transaction;
import 'package:my_budget_client/data/repositories/local_db/local_account_repository.dart';
import 'package:my_budget_client/data/repositories/local_db/local_category_repository.dart';
import 'package:my_budget_client/data/repositories/local_db/local_currency_repository.dart';
import 'package:my_budget_client/data/repositories/local_db/local_settings_repository.dart';
import 'package:my_budget_client/data/repositories/local_db/local_style_repository.dart';
import 'package:my_budget_client/data/repositories/local_db/local_transaction_repository.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';

/// A repository whose `addTransaction` fails the way a constraint or a full
/// disk does: it throws before anything reaches the database, so no table
/// signal ever follows.
class _FailingAddRepository extends LocalTransactionRepository {
  _FailingAddRepository(super.database);

  @override
  Future<void> addTransaction(Transaction transaction) async {
    throw StateError('write refused');
  }
}

/// Records the events the bloc raises so a reload caused by the table signal
/// can be told apart from one a handler raised itself.
class _RecordingBloc extends TransactionsBloc {
  _RecordingBloc({
    required super.transactionRepository,
    required super.styleRepository,
    required super.categoryRepository,
    required super.settingsRepository,
    required super.currencyRepository,
    required super.accountRepository,
    required super.ownWriteEcho,
  });

  final List<TransactionsEvent> seen = [];

  @override
  void onEvent(TransactionsEvent event) {
    seen.add(event);
    super.onEvent(event);
  }

  int get reloads => seen.whereType<InitialLoadTransactions>().length;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late String accountId;
  late String categoryId;

  setUp(() async {
    AppDatabase.seedExchangeRatesOnCreate = false;
    db = AppDatabase.forTesting(NativeDatabase.memory());

    final designationId =
        (await db.select(db.currencyDesignations).get()).first.id;
    final accountTypeId = (await db.select(db.accountTypes).get()).first.id;
    categoryId = (await db.select(db.categories).get()).first.id;
    accountId = 'acc';

    await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: const Value('acc'),
            name: 'Checking',
            balance: 0,
            currencyCode: 'EUR',
            currencyDesignationId: designationId,
            accountTypeId: accountTypeId,
            creationDate: Value(DateTime(2024)),
          ),
        );
  });

  tearDown(() => db.close());

  /// A transaction written straight to the table, which is what a pull, an
  /// import and a restore all look like from the bloc's side.
  Future<void> writeBehindTheBloc(String id) => db
      .into(db.transactions)
      .insert(
        TransactionsCompanion.insert(
          id: Value(id),
          description: id,
          amount: -10,
          date: DateTime.now(),
          accountId: accountId,
          categoryId: categoryId,
          currencyCode: 'EUR',
        ),
      );

  _RecordingBloc makeBloc({
    LocalTransactionRepository? transactions,
    Duration echo = const Duration(seconds: 3),
  }) {
    return _RecordingBloc(
      transactionRepository: transactions ?? LocalTransactionRepository(db),
      styleRepository: LocalStyleRepository(db),
      categoryRepository: LocalCategoryRepository(db),
      settingsRepository: LocalSettingsRepository(db),
      currencyRepository: LocalCurrencyRepository(db),
      accountRepository: LocalAccountRepository(db),
      ownWriteEcho: echo,
    );
  }

  /// Long enough for the listener's 500ms debounce and the load behind it.
  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 900));

  Transaction sample(String id) => Transaction(
    id: id,
    description: id,
    amount: -10,
    date: DateTime.now(),
    accountId: accountId,
    categoryId: categoryId,
    currencyCode: 'EUR',
  );

  test('a write made behind the bloc reaches the list', () async {
    final bloc = makeBloc();
    addTearDown(bloc.close);
    bloc.add(const InitialLoadTransactions());
    await settle();
    final before = bloc.reloads;

    await writeBehindTheBloc('pulled');
    await settle();

    expect(bloc.reloads, greaterThan(before));
    expect(
      bloc.state.transactions.map((t) => t.transaction.id),
      contains('pulled'),
    );
  });

  test("the bloc's own write does not reload the list twice", () async {
    // The suppression this pins is the whole reason the flag exists: the add
    // handler reloads by itself, so the signal that add causes is redundant.
    final bloc = makeBloc();
    addTearDown(bloc.close);
    bloc.add(const InitialLoadTransactions());
    await settle();
    final before = bloc.reloads;

    bloc.add(AddTransaction(sample('mine')));
    await settle();

    expect(bloc.reloads, before + 1);
    expect(
      bloc.state.transactions.map((t) => t.transaction.id),
      contains('mine'),
    );
  });

  test('a write that failed does not swallow the next external one', () async {
    // The echo is shortened so the test does not have to wait out the
    // production value; the failing write arms the suppression either way.
    final bloc = makeBloc(
      transactions: _FailingAddRepository(db),
      echo: const Duration(milliseconds: 100),
    );
    addTearDown(bloc.close);
    bloc.add(const InitialLoadTransactions());
    await settle();

    bloc.add(AddTransaction(sample('never-written')));
    await settle();
    final before = bloc.reloads;

    await writeBehindTheBloc('pulled');
    await settle();

    expect(bloc.reloads, greaterThan(before));
    expect(
      bloc.state.transactions.map((t) => t.transaction.id),
      contains('pulled'),
    );
  });
}
