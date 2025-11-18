// ignore_for_file: avoid_redundant_argument_values

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';

import 'accounts_bloc_test.mocks.dart';

@GenerateMocks([AccountRepository])
void main() {
  late MockAccountRepository mockAccountRepository;
  late AccountsBloc accountsBloc;

  final testAccount = Account(
    id: 1,
    name: 'Test Account',
    balance: 1000,
    currencyId: 1,
  );
  final List<Account> testAccounts = [testAccount];

  setUp(() {
    mockAccountRepository = MockAccountRepository();
    accountsBloc = AccountsBloc(accountRepository: mockAccountRepository);
  });

  tearDown(() {
    accountsBloc.close();
  });

  group('AccountsBloc', () {
    test('initial state is AccountsInitial', () {
      expect(accountsBloc.state, equals(AccountsInitial()));
    });

    group('LoadAccounts', () {
      blocTest<AccountsBloc, AccountsState>(
        'emits [AccountsLoadInProgress, AccountsLoadSuccess] when account stream emits data.',
        setUp: () {
          when(mockAccountRepository.watchAccounts())
              .thenAnswer((_) => Stream.value(testAccounts));
        },
        build: () => accountsBloc,
        act: (bloc) => bloc.add(LoadAccounts()),
        expect: () => [
          AccountsLoadInProgress(),
          isA<AccountsLoadSuccess>()
              .having((s) => s.accounts, 'accounts', testAccounts),
        ],
        verify: (_) {
          verify(mockAccountRepository.watchAccounts()).called(1);
        },
      );

      blocTest<AccountsBloc, AccountsState>(
        'emits [AccountsLoadInProgress, AccountsLoadFailure] when account stream throws error.',
        setUp: () {
          when(mockAccountRepository.watchAccounts())
              .thenAnswer((_) => Stream.error(Exception('Failed to load')));
        },
        build: () => accountsBloc,
        act: (bloc) => bloc.add(LoadAccounts()),
        expect: () => [
          AccountsLoadInProgress(),
          AccountsLoadFailure(),
        ],
        verify: (_) {
          verify(mockAccountRepository.watchAccounts()).called(1);
        },
      );
    });

    group('AddAccount', () {
      blocTest<AccountsBloc, AccountsState>(
        'calls AccountRepository.addAccount',
        setUp: () {
          when(mockAccountRepository.addAccount(any))
              .thenAnswer((_) async {});
        },
        build: () => accountsBloc,
        act: (bloc) => bloc.add(AddAccount(testAccount)),
        verify: (_) {
          verify(mockAccountRepository.addAccount(testAccount)).called(1);
        },
      );
    });

    group('DeleteAccount and UndoDeleteAccount', () {
      // Simulate that the bloc is already loaded with one account
      final initialState =
          AccountsLoadSuccess(accounts: testAccounts);

      blocTest<AccountsBloc, AccountsState>(
        'deletes account and holds it for undo',
        setUp: () {
          when(mockAccountRepository.deleteAccount(any))
              .thenAnswer((_) async {});
        },
        build: () => accountsBloc,
        seed: () => initialState,
        act: (bloc) => bloc.add(DeleteAccount(testAccount.id!)),
        expect: () => [
          isA<AccountsLoadSuccess>()
              .having(
                (s) => s.recentlyDeletedAccount,
                'recentlyDeletedAccount',
                testAccount,
              )
              .having((s) => s.accounts, 'accounts', testAccounts),
        ],
        verify: (_) {
          verify(mockAccountRepository.deleteAccount(testAccount.id!))
              .called(1);
        },
      );

      blocTest<AccountsBloc, AccountsState>(
        'restores account when UndoDeleteAccount is added',
        setUp: () {
          when(mockAccountRepository.restoreAccount(any))
              .thenAnswer((_) async {});
        },
        build: () => accountsBloc,
        // Seed the state as if an account was just deleted
        seed: () => AccountsLoadSuccess(
          accounts: const [], // The list would be empty after deletion
          recentlyDeletedAccount: testAccount,
        ),
        act: (bloc) => bloc.add(UndoDeleteAccount()),
        expect: () => [
          // The state after undoing: the account is no longer in 'recentlyDeletedAccount'
          isA<AccountsLoadSuccess>().having(
            (s) => s.recentlyDeletedAccount,
            'recentlyDeletedAccount',
            isNull,
          ),
        ],
        verify: (_) {
          verify(mockAccountRepository.restoreAccount(testAccount)).called(1);
        },
      );
    });
  });
}
