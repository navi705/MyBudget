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
    'a null domain id leaves the companion id absent, so repeated calls agree',
    () {
      // It used to call Uuid().v4() inline, so two toCompanion() calls on the
      // same unsaved Category produced two different row ids — anything that
      // built the companion twice (validate, then insert) wrote the category
      // under an id nobody else held. AccountMapper and StyleMapper leave it
      // absent and let the DB's clientDefault assign one; this one now does too.
      final unsaved = Category(name: 'New Category');

      expect(unsaved.toCompanion().id.present, isFalse);
      expect(
        unsaved.toCompanion().id,
        unsaved.toCompanion().id,
      );
    },
  );
}
