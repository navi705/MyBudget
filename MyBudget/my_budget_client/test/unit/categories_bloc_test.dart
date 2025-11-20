import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/presentation/blocs/categories/categories_bloc.dart';

import 'categories_bloc_test.mocks.dart';

@GenerateMocks([CategoryRepository])
void main() {
  late MockCategoryRepository mockCategoryRepository;
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
    categoriesBloc = CategoriesBloc(categoryRepository: mockCategoryRepository);
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
          when(mockCategoryRepository.watchCategoryTotals())
              .thenAnswer((_) => Stream.value({1: 100.0}));
        },
        build: () => categoriesBloc,
        act: (bloc) => bloc.add(LoadCategories()),
        expect: () => [
          CategoriesLoadInProgress(),
          isA<CategoriesLoadSuccess>()
              .having((s) => s.categories, 'categories', testCategories)
              .having((s) => s.categoryTotals, 'categoryTotals', {1: 100.0}),
        ],
        verify: (_) {
          verify(mockCategoryRepository.watchCategories()).called(1);
          verify(mockCategoryRepository.watchCategoryTotals()).called(1);
        },
      );

      blocTest<CategoriesBloc, CategoriesState>(
        'emits [CategoriesLoadInProgress, CategoriesLoadFailure] when category stream throws error.',
        setUp: () {
          when(mockCategoryRepository.watchCategories())
              .thenAnswer((_) => Stream.error(Exception('Failed to load')));
          when(mockCategoryRepository.watchCategoryTotals())
              .thenAnswer((_) => Stream.error(Exception('Failed to load')));
        },
        build: () => categoriesBloc,
        act: (bloc) => bloc.add(LoadCategories()),
        expect: () => [
          CategoriesLoadInProgress(),
          CategoriesLoadFailure(),
        ],
        verify: (_) {
          verify(mockCategoryRepository.watchCategories()).called(1);
          verify(mockCategoryRepository.watchCategoryTotals()).called(1);
        },
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
  });
}
