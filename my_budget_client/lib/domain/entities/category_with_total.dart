import 'package:equatable/equatable.dart';
import 'package:my_budget_client/domain/entities/category.dart';

class CategoryWithTotal extends Equatable {
  final Category category;
  final double total;

  const CategoryWithTotal({required this.category, required this.total});

  @override
  List<Object?> get props => [category, total];
}
