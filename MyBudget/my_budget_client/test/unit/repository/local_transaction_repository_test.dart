import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:my_budget_client/core/database/app_database.dart' as db;
import 'package:my_budget_client/core/mappers/transaction_mapper.dart';
import 'package:my_budget_client/data/repositories/local_db/local_transaction_repository.dart';


import 'local_transaction_repository_test.mocks.dart';

@GenerateMocks([db.AppDatabase, db.TransactionsDao, db.AccountsDao])
void main() {
  late MockAppDatabase mockAppDatabase;
  late MockTransactionsDao mockTransactionsDao;
  late MockAccountsDao mockAccountsDao;
  late LocalTransactionRepository repository;

  setUp(() {
    mockAppDatabase = MockAppDatabase();
    mockTransactionsDao = MockTransactionsDao();
    mockAccountsDao = MockAccountsDao();

    when(mockAppDatabase.transactionsDao).thenReturn(mockTransactionsDao);
    when(mockAppDatabase.accountsDao).thenReturn(mockAccountsDao);

    repository = LocalTransactionRepository(mockAppDatabase);
  });

  group('updateTransaction', () {
    final tOldDbTransaction = db.Transaction(
      id: 1,
      description: 'Old grocery shopping',
      amount: 50.0,
      date: DateTime.now(),
      accountId: 1,
      categoryId: 1,
      currencyId: 1,
    );

    final tOldDomainTransaction = tOldDbTransaction.toDomain();

    final tOldAccount = db.Account(
      id: 1,
      name: 'Checking',
      balance: 1000.0,
      currencyId: 1,
      currencyDesignationId: 1,
      accountTypeId: 1,
    );

    final tSecondAccount = db.Account(
      id: 2,
      name: 'Savings',
      balance: 5000.0,
      currencyId: 1,
      currencyDesignationId: 1,
      accountTypeId: 2,
    );

    // This setup function handles the common mock setups for the tests.
    void setupMocksForUpdate({
      required db.Transaction oldTransaction,
      required db.Account oldAccount,
      db.Account? newAccount, 
    }) {
      when(mockTransactionsDao.getTransactionById(oldTransaction.id))
          .thenAnswer((_) async => oldTransaction);
      
      when(mockAccountsDao.getAccountById(oldTransaction.accountId))
          .thenAnswer((_) async => oldAccount);

      if (newAccount != null) {
        when(mockAccountsDao.getAccountById(newAccount.id))
            .thenAnswer((_) async => newAccount);
      }

      when(mockTransactionsDao.updateTransaction(any)).thenAnswer((_) async => true);
      when(mockAccountsDao.updateAccount(any)).thenAnswer((_) async => true);
    }

    test(
        'should only update balance with the difference when accountId is the same',
        () async {
      // Arrange
      setupMocksForUpdate(oldTransaction: tOldDbTransaction, oldAccount: tOldAccount);
      
      final tNewDomainTransaction = tOldDomainTransaction.copyWith(amount: 75.0);
      const amountDifference = 25.0;
      final expectedNewBalance = tOldAccount.balance + amountDifference;

      // Act
      await repository.updateTransaction(tNewDomainTransaction);

      // Assert
      verify(mockTransactionsDao.getTransactionById(tOldDomainTransaction.id!));
      
      verify(mockTransactionsDao.updateTransaction(
        tNewDomainTransaction.toCompanion(),
      )).called(1);

      final verification = verify(mockAccountsDao.updateAccount(captureAny));
      verification.called(1);
      
      final capturedCompanion = verification.captured.first as db.AccountsCompanion;
      expect(capturedCompanion.id.value, tOldAccount.id);
      expect(capturedCompanion.balance.value, expectedNewBalance);
    });

    test(
        'should revert old account and apply to new account when accountId changes',
        () async {
      // Arrange
      setupMocksForUpdate(
        oldTransaction: tOldDbTransaction,
        oldAccount: tOldAccount,
        newAccount: tSecondAccount,
      );

      final tNewDomainTransaction = tOldDomainTransaction.copyWith(
        accountId: 2,
        amount: 100.0,
      );

      final expectedOldAccountBalance = tOldAccount.balance - tOldDbTransaction.amount;
      final expectedNewAccountBalance = tSecondAccount.balance + tNewDomainTransaction.amount;

      // Act
      await repository.updateTransaction(tNewDomainTransaction);

      // Assert
      verify(mockTransactionsDao.getTransactionById(tOldDomainTransaction.id!));
      verify(mockTransactionsDao.updateTransaction(tNewDomainTransaction.toCompanion()));

      final verification = verify(mockAccountsDao.updateAccount(captureAny));
      verification.called(2);

      final companions = verification.captured.cast<db.AccountsCompanion>();
      final oldAccountCompanion = companions.firstWhere((c) => c.id.value == tOldAccount.id);
      final newAccountCompanion = companions.firstWhere((c) => c.id.value == tSecondAccount.id);

      expect(oldAccountCompanion.balance.value, expectedOldAccountBalance);
      expect(newAccountCompanion.balance.value, expectedNewAccountBalance);
    });

    test('should do nothing if the transaction to update is not found', () async {
      // Arrange
      final tNonExistentTransaction = tOldDomainTransaction.copyWith(id: 999);
      when(mockTransactionsDao.getTransactionById(tNonExistentTransaction.id!))
          .thenAnswer((_) async => null);

      // Act
      await repository.updateTransaction(tNonExistentTransaction);

      // Assert
      verify(mockTransactionsDao.getTransactionById(tNonExistentTransaction.id!));
      verifyNever(mockTransactionsDao.updateTransaction(any));
      verifyNever(mockAccountsDao.updateAccount(any));
    });

    test('should handle negative transaction amounts correctly', () async {
      // Arrange
      setupMocksForUpdate(oldTransaction: tOldDbTransaction, oldAccount: tOldAccount);
      
      // From 50.0 to -20.0, a difference of -70.0
      final tNewDomainTransaction = tOldDomainTransaction.copyWith(amount: -20.0);
      final amountDifference = -70.0;
      final expectedNewBalance = tOldAccount.balance + amountDifference;

      // Act
      await repository.updateTransaction(tNewDomainTransaction);

      // Assert
      final verification = verify(mockAccountsDao.updateAccount(captureAny));
      verification.called(1);
      
      final capturedCompanion = verification.captured.first as db.AccountsCompanion;
      expect(capturedCompanion.balance.value, expectedNewBalance);
    });

    test('should not crash if an account is not found during balance update', () async {
        // Arrange
        final tNewDomainTransaction = tOldDomainTransaction.copyWith(amount: 100.0);
        
        when(mockTransactionsDao.getTransactionById(tOldDomainTransaction.id!))
            .thenAnswer((_) async => tOldDbTransaction); // Old transaction exists
        when(mockAccountsDao.getAccountById(tOldDomainTransaction.accountId))
            .thenAnswer((_) async => tOldAccount); // Old account exists

        // Explicitly stub updateTransaction for this test
        when(mockTransactionsDao.updateTransaction(any)).thenAnswer((_) async => true);

        // This time, mock getAccountById for the new account to return null
        when(mockAccountsDao.getAccountById(tNewDomainTransaction.accountId))
            .thenAnswer((_) async => null);
        
        // Act & Assert
        expect(() async => await repository.updateTransaction(tNewDomainTransaction), returnsNormally);
        
        // Verify that we attempted to get the transaction and new account, but no update to account balance was performed.
        verify(mockTransactionsDao.getTransactionById(tOldDomainTransaction.id!));
        verify(mockAccountsDao.getAccountById(tNewDomainTransaction.accountId));
        verifyNever(mockAccountsDao.updateAccount(any));
    });
  });
}
