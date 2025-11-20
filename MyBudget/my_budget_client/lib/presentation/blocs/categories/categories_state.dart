part of 'categories_bloc.dart';

abstract class CategoriesState extends Equatable {
  const CategoriesState();

  @override
  List<Object> get props => [];
}

class CategoriesInitial extends CategoriesState {}

class CategoriesLoadInProgress extends CategoriesState {}

class CategoriesLoadSuccess extends CategoriesState {
  final List<Category> categories;
  final Map<int, double> categoryTotals;

  const CategoriesLoadSuccess({
    this.categories = const [],
    this.categoryTotals = const {},
  });

  @override
  List<Object> get props => [categories, categoryTotals];
}

class CategoriesLoadFailure extends CategoriesState {}
