import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart' as db;
import 'package:my_budget_client/core/mappers/category_mapper.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';

void main() {
  db.Category rowFromCompanion(db.CategoriesCompanion c) => db.Category(
    id: c.id.value,
    name: c.name.value,
    parentId: c.parentId.value,
    styleId: c.styleId.value,
    type: c.type.value,
    modifiedAt: 0,
    isDeleted: false,
  );

  test('round trip preserves every field for a populated category', () {
    final original = Category(
      id: 'cat1',
      name: 'Groceries',
      parentId: 'food',
      styleId: 'style1',
      type: CategoryType.expense,
    );

    final roundTripped = rowFromCompanion(original.toCompanion()).toDomain();

    expect(roundTripped.id, original.id);
    expect(roundTripped.name, original.name);
    expect(roundTripped.parentId, original.parentId);
    expect(roundTripped.styleId, original.styleId);
    expect(roundTripped.type, original.type);
  });

  test('round trip preserves null parentId/styleId and default income type', () {
    final original = Category(id: 'cat2', name: 'Salary', type: CategoryType.income);

    final roundTripped = rowFromCompanion(original.toCompanion()).toDomain();

    expect(roundTripped.parentId, isNull);
    expect(roundTripped.styleId, isNull);
    expect(roundTripped.type, CategoryType.income);
  });

  test(
    'toCompanion generates a fresh random id on every call when domain.id is null '
    '(unlike AccountMapper/StyleMapper, which leave id absent for the DB/caller to assign)',
    () {
      final unsaved = Category(name: 'New Category');

      final firstId = unsaved.toCompanion().id.value;
      final secondId = unsaved.toCompanion().id.value;

      expect(firstId, isNotNull);
      expect(secondId, isNotNull);
      expect(
        firstId,
        isNot(secondId),
        reason:
            'CategoryMapper.toCompanion() calls Uuid().v4() inline instead of '
            'leaving id absent, so two toCompanion() calls on the same unsaved '
            'Category silently produce two different row ids.',
      );
    },
  );
}
