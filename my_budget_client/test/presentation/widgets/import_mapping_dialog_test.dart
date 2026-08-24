// Telling the import which account, category or currency a name in the file
// stands for.
//
// The dialog popped `(item as dynamic).id` - whatever the runtime type happens
// to call `id`. Accounts and categories have one; a currency does not, it is
// keyed by its code. So the one step that exists to say "this file's USD is
// the USD you already have" threw NoSuchMethodError on the tap, and an import
// carrying a currency the app did not know could not be finished at all.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/presentation/widgets/import_mapping_dialog.dart';

import '../test_app.dart';

const _usd = Currency(
  name: 'US Dollar',
  code: 'USD',
  languageCode: 'en',
  type: TypeCurrency.currency,
);

const _eur = Currency(
  name: 'Euro',
  code: 'EUR',
  languageCode: 'en',
  type: TypeCurrency.currency,
);

final _wallet = Account(
  id: 'a1',
  name: 'Кошелёк',
  balance: 0,
  currencyCode: 'EUR',
  currencyDesignationId: 'd1',
  accountTypeId: 't1',
  creationDate: DateTime(2024, 1, 1),
);

/// Opens the dialog the way the import screen does - as a route - and collects
/// what it pops.
Future<List<String?>> _open<T>(
  WidgetTester tester, {
  required List<T> items,
  required String Function(T) name,
  required String? Function(T) id,
}) async {
  final popped = <String?>[];

  await pumpAppWidget(
    tester,
    Builder(
      builder: (context) => ElevatedButton(
        onPressed: () async {
          popped.add(
            await showDialog<String>(
              context: context,
              builder: (_) => ImportMappingDialog<T>(
                title: 'Map it',
                items: items,
                itemNameProvider: name,
                itemIdProvider: id,
                itemBuilder: (item) => Text(name(item)),
              ),
            ),
          );
        },
        child: const Text('open'),
      ),
    ),
    surfaceSize: const Size(600, 800),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return popped;
}

void main() {
  testWidgets('picking a currency answers with its code', (tester) async {
    final popped = await _open<Currency>(
      tester,
      items: const [_usd, _eur],
      name: (c) => c.name,
      id: (c) => c.code,
    );

    await tester.tap(find.text(_eur.name));
    await tester.pumpAndSettle();

    expect(popped.single, 'EUR');
  });

  testWidgets('picking an account answers with its id', (tester) async {
    final popped = await _open<Account>(
      tester,
      items: [_wallet],
      name: (a) => a.name,
      id: (a) => a.id,
    );

    await tester.tap(find.text(_wallet.name));
    await tester.pumpAndSettle();

    expect(popped.single, _wallet.id);
  });

  testWidgets('the search narrows the list to what was typed', (tester) async {
    // The list is every currency the app knows; typing is the only way to
    // reach one that is not in the first screenful.
    await _open<Currency>(
      tester,
      items: const [_usd, _eur],
      name: (c) => c.name,
      id: (c) => c.code,
    );

    await tester.enterText(find.byType(TextField), 'euro');
    await tester.pumpAndSettle();

    expect(find.text(_eur.name), findsOneWidget);
    expect(find.text(_usd.name), findsNothing);
  });

  testWidgets('cancelling maps nothing', (tester) async {
    final l10n = await loadL10n();
    final popped = await _open<Currency>(
      tester,
      items: const [_usd],
      name: (c) => c.name,
      id: (c) => c.code,
    );

    await tester.tap(find.text(l10n.cancelButton));
    await tester.pumpAndSettle();

    expect(popped.single, isNull);
  });
}
