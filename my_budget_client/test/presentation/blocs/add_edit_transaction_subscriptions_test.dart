import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/domain/repositories/asset_repository.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/presentation/blocs/add_edit_transaction/add_edit_transaction_bloc.dart';
import 'package:my_budget_client/domain/entities/settings.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';

import 'add_edit_transaction_subscriptions_test.mocks.dart';

@GenerateMocks([
  AccountRepository,
  CategoryRepository,
  TransactionRepository,
  CurrencyRepository,
  SettingsRepository,
  AssetRepository,
])
void main() {
  late MockAccountRepository mockAccountRepository;
  late MockCategoryRepository mockCategoryRepository;
  late MockTransactionRepository mockTransactionRepository;
  late MockCurrencyRepository mockCurrencyRepository;
  late MockSettingsRepository mockSettingsRepository;
  late MockAssetRepository mockAssetRepository;

  setUp(() {
    mockAccountRepository = MockAccountRepository();
    mockCategoryRepository = MockCategoryRepository();
    mockTransactionRepository = MockTransactionRepository();
    mockCurrencyRepository = MockCurrencyRepository();
    mockSettingsRepository = MockSettingsRepository();
    mockAssetRepository = MockAssetRepository();

    // Default Stubs
    when(mockAccountRepository.getAccounts()).thenAnswer((_) async => []);
    when(mockCategoryRepository.getCategories()).thenAnswer((_) async => []);
    when(mockCurrencyRepository.getCurrencies()).thenAnswer((_) async => []);
    when(mockSettingsRepository.getSetting(any)).thenAnswer((_) async => null);
    when(
      mockAccountRepository.watchAccounts(),
    ).thenAnswer((_) => Stream.value([]));
    when(
      mockCategoryRepository.watchCategories(),
    ).thenAnswer((_) => Stream.value([]));
    when(
      mockCurrencyRepository.getLatestExchangeRates(any),
    ).thenAnswer((_) async => []);
  });

  group('AddEditTransactionBloc Subscriptions', () {
    final account1 = Account(
      id: '1',
      name: 'Test Account',
      balance: 100,
      currencyCode: 'EUR',
      currencyDesignationId: '1',
      accountTypeId: '1',
      creationDate: DateTime.now(),
    );

    final category1 = Category(
      id: '1',
      name: 'Test Category',
      type: CategoryType.expense,
    );

    final updatedAccounts = [account1];
    final updatedCategories = [category1];

    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'updates accounts when account repository stream emits new data',
      setUp: () {
        final controller = StreamController<List<Account>>();
        when(
          mockAccountRepository.watchAccounts(),
        ).thenAnswer((_) => controller.stream);

        // Emit initial empty list then updated list
        controller.add([]);
        Future.delayed(Duration(milliseconds: 10), () {
          controller.add(updatedAccounts);
        });
      },
      build: () => AddEditTransactionBloc(
        accountRepository: mockAccountRepository,
        categoryRepository: mockCategoryRepository,
        transactionRepository: mockTransactionRepository,
        currencyRepository: mockCurrencyRepository,
        settingsRepository: mockSettingsRepository,
        assetRepository: mockAssetRepository,
      ),
      act: (bloc) => bloc.add(const AddEditTransactionLoad()),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<AddEditTransactionState>().having(
          (s) => s.status,
          'status',
          AddEditTransactionStatus.loading,
        ),
        // Initial success from getAccounts() returning []
        isA<AddEditTransactionState>().having(
          (s) => s.status,
          'status',
          AddEditTransactionStatus.success,
        ),
        // We expect an update with the accounts from stream
        isA<AddEditTransactionState>().having(
          (s) => s.accounts,
          'accounts',
          isNotEmpty,
        ),
      ],
      verify: (_) {
        verify(mockAccountRepository.watchAccounts()).called(1);
      },
    );

    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'updates categories when category repository stream emits new data',
      setUp: () {
        final controller = StreamController<List<Category>>();
        when(
          mockCategoryRepository.watchCategories(),
        ).thenAnswer((_) => controller.stream);

        controller.add([]);
        Future.delayed(Duration(milliseconds: 10), () {
          controller.add(updatedCategories);
        });
      },
      build: () => AddEditTransactionBloc(
        accountRepository: mockAccountRepository,
        categoryRepository: mockCategoryRepository,
        transactionRepository: mockTransactionRepository,
        currencyRepository: mockCurrencyRepository,
        settingsRepository: mockSettingsRepository,
        assetRepository: mockAssetRepository,
      ),
      act: (bloc) => bloc.add(const AddEditTransactionLoad()),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<AddEditTransactionState>().having(
          (s) => s.status,
          'status',
          AddEditTransactionStatus.loading,
        ),
        isA<AddEditTransactionState>().having(
          (s) => s.status,
          'status',
          AddEditTransactionStatus.success,
        ),
        isA<AddEditTransactionState>().having(
          (s) => s.categories,
          'categories',
          isNotEmpty,
        ),
      ],
      verify: (_) {
        verify(mockCategoryRepository.watchCategories()).called(1);
      },
    );
  });
}
