import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart' as drift;
import 'package:my_budget_client/core/mappers/style_mapper.dart';
import 'package:my_budget_client/domain/entities/icon_type.dart';
import 'package:my_budget_client/domain/entities/style.dart';

void main() {
  drift.Style rowFromCompanion(drift.StylesCompanion c) => drift.Style(
    id: c.id.value,
    name: c.name.value,
    iconName: c.iconName.value,
    colorHex: c.colorHex.value,
    iconType: c.iconType.value,
    modifiedAt: 0,
    isDeleted: false,
  );

  test('round trip preserves every field', () {
    final original = Style(
      id: 'style1',
      name: 'Groceries',
      iconName: 'cart',
      colorHex: '#FF00FF',
      iconType: IconType.material,
    );

    final roundTripped = rowFromCompanion(original.toCompanion()).toDomain();

    expect(roundTripped.id, original.id);
    expect(roundTripped.name, original.name);
    expect(roundTripped.iconName, original.iconName);
    expect(roundTripped.colorHex, original.colorHex);
    expect(roundTripped.iconType, original.iconType);
  });

  test(
    'null domain id becomes an absent companion id (insert lets the DB/caller assign one)',
    () {
      final original = Style(
        name: 'Groceries',
        iconName: 'cart',
        colorHex: '#FF00FF',
        iconType: IconType.material,
      );

      expect(original.toCompanion().id.present, isFalse);
    },
  );
}
