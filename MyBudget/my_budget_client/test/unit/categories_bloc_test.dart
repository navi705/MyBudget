import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/presentation/blocs/categories/categories_bloc.dart';

import 'categories_bloc_test.mocks.dart';

@GenerateMocks([CategoryRepository, TransactionRepository])
void main() {
  late MockCategoryRepository mockCategoryRepository;
  late MockTransactionRepository mockTransactionRepository;
  late CategoriesBloc categoriesBloc;

  final testCategory = Category(
    id: 1,
    name: 'Test Category',
    parentId: null,
    styleId: 1,
  );
  final List<Category> testCategories = [testCategory];

  setUp(() {
    mockCategoryRepository = MockCategoryRepository();
    mockTransactionRepository = MockTransactionRepository();
    categoriesBloc = CategoriesBloc(
      categoryRepository: mockCategoryRepository,
      transactionRepository: mockTransactionRepository,
    );
  });

  tearDown(() {
    categoriesBloc.close();
  });

  group('CategoriesBloc', () {
    test('initial state is CategoriesInitial', () {
      expect(categoriesBloc.state, equals(CategoriesInitial()));
    });

    group('LoadCategories', () {
      blocTest<CategoriesBloc, CategoriesState>(
        'emits [CategoriesLoadInProgress, CategoriesLoadSuccess] when category stream emits data.',
        setUp: () {
          when(mockCategoryRepository.watchCategories())
              .thenAnswer((_) => Stream.value(testCategories));
          when(mockTransactionRepository.watchTransactions())
              .thenAnswer((_) => Stream.value([]));
        },
        build: () => categoriesBloc,
        act: (bloc) => bloc.add(LoadCategories()),
        expect: () => [
          CategoriesLoadInProgress(),
          isA<CategoriesLoadSuccess>()
              .having((s) => s.categories, 'categories', testCategories),
        ],
        verify: (_) {
          verify(mockCategoryRepository.watchCategories()).called(1);
          verify(mockTransactionRepository.watchTransactions()).called(1);
        },
      );

      final parentCategory = Category(id: 1, name: 'Parent', parentId: null, styleId: 1);
      final childCategory = Category(id: 2, name: 'Child', parentId: 1, styleId: 1);
      final transactions = [
        Transaction(id: 1, description: 't1', amount: 50, date: DateTime.now(), accountId: 1, categoryId: 2, currencyId: 1),
      ];

      blocTest<CategoriesBloc, CategoriesState>(
        'emits CategoriesLoadSuccess with recursive totals.',
        setUp: () {
          when(mockCategoryRepository.watchCategories())
              .thenAnswer((_) => Stream.value([parentCategory, childCategory]));
          when(mockTransactionRepository.watchTransactions())
              .thenAnswer((_) => Stream.value(transactions));
        },
        build: () => categoriesBloc,
        act: (bloc) => bloc.add(LoadCategories()),
        expect: () => [
          CategoriesLoadInProgress(),
          isA<CategoriesLoadSuccess>()
              .having((s) => s.categoryTotals[1], 'parent total', 50.0),
        ],
      );
    });

    group('AddCategory', () {
      blocTest<CategoriesBloc, CategoriesState>(
        'calls CategoryRepository.addCategory',
        setUp: () {
          when(mockCategoryRepository.addCategory(any))
              .thenAnswer((_) async {});
        },
        build: () => categoriesBloc,
        act: (bloc) => bloc.add(AddCategory(testCategory)),
        verify: (_) {
          verify(mockCategoryRepository.addCategory(testCategory)).called(1);
        },
      );
    });

    group('DeleteCategory', () {
      blocTest<CategoriesBloc, CategoriesState>(
        'deletes category directly if no transactions are associated',
        setUp: () {
          when(mockTransactionRepository.getTransactionsByCategoryId(any))
              .thenAnswer((_) async => []);
          when(mockCategoryRepository.deleteCategory(any))
              .thenAnswer((_) async {});
        },
        build: () => categoriesBloc,
        act: (bloc) => bloc.add(DeleteCategory(1)),
        verify: (_) {
          verify(mockCategoryRepository.deleteCategory(1)).called(1);
        },
      );

      final transaction = Transaction(id: 1, description: 't1', amount: 10, date: DateTime.now(), accountId: 1, categoryId: 1, currencyId: 1);
      blocTest<CategoriesBloc, CategoriesState>(
        'emits CategoryDeletionConfirmationNeeded if transactions are associated',
        setUp: () {
          when(mockTransactionRepository.getTransactionsByCategoryId(any))
              .thenAnswer((_) async => [transaction]);
          when(mockCategoryRepository.getCategoryById(any))
              .thenAnswer((_) async => testCategory);
          when(mockCategoryRepository.getCategories())
              .thenAnswer((_) async => testCategories);
        },
        build: () => categoriesBloc,
        act: (bloc) => bloc.add(DeleteCategory(1)),
        expect: () => [
          isA<CategoryDeletionConfirmationNeeded>(),
        ],
      );
    });
    
    group('DeleteCategoryConfirmed', () {
      final transaction = Transaction(id: 1, description: 't1', amount: 10, date: DateTime.now(), accountId: 1, categoryId: 1, currencyId: 1);
      
      blocTest<CategoriesBloc, CategoriesState>(
        'deletes transactions and category',
        setUp: () {
          when(mockTransactionRepository.getTransactionsByCategoryId(any))
              .thenAnswer((_) async => [transaction]);
          when(mockTransactionRepository.deleteTransaction(any))
              .thenAnswer((_) async {});
          when(mockCategoryRepository.deleteCategory(any))
              .thenAnswer((_) async {});
        },
        build: () => categoriesBloc,
        act: (bloc) => bloc.add(DeleteCategoryConfirmed(categoryToDelete: testCategory, deleteTransactions: true)),
        verify: (_) {
          verify(mockTransactionRepository.deleteTransaction(1)).called(1);
          verify(mockCategoryRepository.deleteCategory(1)).called(1);
        },
      );

      blocTest<CategoriesBloc, CategoriesState>(
        're-assigns transactions and deletes category',
        setUp: () {
          when(mockTransactionRepository.getTransactionsByCategoryId(any))
              .thenAnswer((_) async => [transaction]);
          when(mockTransactionRepository.updateTransaction(any))
              .thenAnswer((_) async {});
          when(mockCategoryRepository.deleteCategory(any))
              .thenAnswer((_) async {});
        },
        build: () => categoriesBloc,
        act: (bloc) => bloc.add(DeleteCategoryConfirmed(categoryToDelete: testCategory, deleteTransactions: false, newCategoryId: 2)),
        verify: (_) {
          final updatedTransaction = transaction.copyWith(categoryId: 2);
          verify(mockTransactionRepository.updateTransaction(updatedTransaction)).called(1);
          verify(mockCategoryRepository.deleteCategory(1)).called(1);
        },
      );
    });
  });
}
