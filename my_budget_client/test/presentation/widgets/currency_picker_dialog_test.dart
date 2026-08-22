// The currency picker used to be a flat alphabetical run of every currency the
// app knows. Picking the one currency a person actually uses meant scrolling
// past dozens of them or typing a search, on every screen that asks. These
// tests pin the two shortcuts that replaced that: the codes the user starred,
// and the codes they already keep money in.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
import 'package:my_budget_client/presentation/widgets/currency_picker_dialog.dart';

import '../test_app.dart';

Currency _currency(String code, String name) => Currency(
  name: name,
  code: code,
  languageCode: 'en',
  type: TypeCurrency.currency,
);

final _eur = _currency('EUR', 'Euro');
final _usd = _currency('USD', 'US Dollar');
final _jpy = _currency('JPY', 'Japanese Yen');
final _gbp = _currency('GBP', 'British Pound');
final _all = [_eur, _gbp, _jpy, _usd];

class _FakeCurrencyRepository extends Fake implements CurrencyRepository {
  _FakeCurrencyRepository({List<String>? favorites, Map<String, int>? usage})
    : favorites = [...?favorites],
      usage = usage ?? const {};

  final List<String> favorites;
  final Map<String, int> usage;
  final List<(String, bool)> writes = [];

  @override
  Future<List<String>> getFavoriteCurrencyCodes() async => List.of(favorites);

  @override
  Future<Map<String, int>> getCurrencyUsageCounts() async => usage;

  @override
  Future<void> setFavoriteCurrency(
    String code, {
    required bool favorite,
  }) async {
    writes.add((code, favorite));
    if (favorite) {
      favorites.add(code);
    } else {
      favorites.remove(code);
    }
  }
}

/// Opens the picker the way every call site does.
///
/// [picked] collects whatever the dialog pops; the value lands there after the
/// dialog is dismissed, which is later than this function returns.
Future<void> _open(
  WidgetTester tester, {
  CurrencyRepository? repository,
  String? selectedCurrencyCode,
  List<Currency>? currencies,
  List<Currency?>? picked,
}) async {
  await pumpAppWidget(
    tester,
    Builder(
      builder: (context) => ElevatedButton(
        onPressed: () async {
          final result = await showDialog<Currency>(
            context: context,
            builder: (_) => CurrencyPickerDialog(
              allCurrencies: currencies ?? _all,
              selectedCurrencyCode: selectedCurrencyCode,
              repository: repository,
            ),
          );
          picked?.add(result);
        },
        child: const Text('open'),
      ),
    ),
    surfaceSize: const Size(800, 1000),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

String _label(Currency c) => '${c.name} (${c.code})';

/// Where the first row for [currency] sits vertically.
double _firstY(WidgetTester tester, Currency currency) =>
    tester.getTopLeft(find.text(_label(currency)).first).dy;

void main() {
  late AppLocalizations l10n;

  setUpAll(() async => l10n = await loadL10n());

  testWidgets('with nothing starred or used it is the plain list', (
    tester,
  ) async {
    await _open(tester, repository: _FakeCurrencyRepository());

    // No section is worth a heading when there is nothing to put under it.
    expect(find.text(l10n.favoriteCurrenciesHeader), findsNothing);
    expect(find.text(l10n.frequentCurrenciesHeader), findsNothing);
    expect(find.text(l10n.allCurrenciesHeader), findsNothing);
    for (final currency in _all) {
      expect(find.text(_label(currency)), findsOneWidget);
    }
  });

  testWidgets('starred currencies sit above everything else', (tester) async {
    await _open(
      tester,
      repository: _FakeCurrencyRepository(
        favorites: ['JPY'],
        usage: const {'EUR': 12},
      ),
    );

    expect(_firstY(tester, _jpy), lessThan(_firstY(tester, _eur)));
    expect(
      tester.getTopLeft(find.text(l10n.favoriteCurrenciesHeader)).dy,
      lessThan(tester.getTopLeft(find.text(l10n.frequentCurrenciesHeader)).dy),
    );
  });

  testWidgets('the most used currency leads the frequently-used section', (
    tester,
  ) async {
    await _open(
      tester,
      repository: _FakeCurrencyRepository(usage: const {'EUR': 2, 'USD': 9}),
    );

    expect(_firstY(tester, _usd), lessThan(_firstY(tester, _eur)));
    // A currency the user has never touched is not lifted out of the list at
    // all - it appears once, under "All currencies".
    expect(find.text(_label(_jpy)), findsOneWidget);
  });

  testWidgets('a lifted currency still appears in the full list', (
    tester,
  ) async {
    await _open(
      tester,
      repository: _FakeCurrencyRepository(
        favorites: ['EUR'],
        usage: const {'USD': 4},
      ),
    );

    // Twice: once in its shortcut section, once where the user last saw it.
    // A shortcut that moves a row is not a shortcut.
    expect(find.text(_label(_eur)), findsNWidgets(2));
    expect(find.text(_label(_usd)), findsNWidgets(2));
    expect(find.text(l10n.allCurrenciesHeader), findsOneWidget);
  });

  testWidgets('the star writes through and moves the currency to the top', (
    tester,
  ) async {
    final repository = _FakeCurrencyRepository(usage: const {'EUR': 3});
    await _open(tester, repository: repository);

    // The Yen is at the bottom of the alphabetical list and is starred there.
    final row = find.ancestor(
      of: find.text(_label(_jpy)),
      matching: find.byType(ListTile),
    );
    await tester.tap(
      find.descendant(of: row, matching: find.byIcon(Icons.star_border)).first,
    );
    await tester.pumpAndSettle();

    expect(repository.writes, [('JPY', true)]);
    expect(find.text(l10n.favoriteCurrenciesHeader), findsOneWidget);
    expect(_firstY(tester, _jpy), lessThan(_firstY(tester, _eur)));
  });

  testWidgets('tapping the star again takes it back off', (tester) async {
    final repository = _FakeCurrencyRepository(favorites: ['JPY']);
    await _open(tester, repository: repository);

    final row = find.ancestor(
      of: find.text(_label(_jpy)),
      matching: find.byType(ListTile),
    );
    await tester.tap(
      find.descendant(of: row, matching: find.byIcon(Icons.star)).first,
    );
    await tester.pumpAndSettle();

    expect(repository.writes, [('JPY', false)]);
    expect(find.text(l10n.favoriteCurrenciesHeader), findsNothing);
  });

  testWidgets('a search keeps the starred matches on top', (tester) async {
    // Both currencies match "o"; one of them is starred and must not be sunk
    // back into alphabetical order by the filter.
    await _open(
      tester,
      repository: _FakeCurrencyRepository(favorites: ['USD']),
    );

    await tester.enterText(find.byType(TextField), 'o');
    await tester.pumpAndSettle();

    expect(find.text(_label(_usd)), findsNWidgets(2));
    expect(find.text(_label(_jpy)), findsNothing);
    expect(_firstY(tester, _usd), lessThan(_firstY(tester, _gbp)));
  });

  testWidgets('a search matching nothing empties the list', (tester) async {
    await _open(
      tester,
      repository: _FakeCurrencyRepository(favorites: ['USD']),
    );

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();

    // Including the heading: a "Favorites" heading over nothing reads as the
    // stars having been lost.
    expect(find.text(l10n.favoriteCurrenciesHeader), findsNothing);
    for (final currency in _all) {
      expect(find.text(_label(currency)), findsNothing);
    }
  });

  testWidgets('a tapped row comes back to the caller', (tester) async {
    final picked = <Currency?>[];
    await _open(tester, repository: _FakeCurrencyRepository(), picked: picked);

    await tester.tap(find.text(_label(_gbp)));
    await tester.pumpAndSettle();

    expect(find.byType(CurrencyPickerDialog), findsNothing);
    // The whole entity, not the code: five of the six call sites want the
    // name or the designation that goes with it.
    expect(picked, [_gbp]);
  });

  testWidgets('cancelling comes back with nothing', (tester) async {
    final picked = <Currency?>[];
    await _open(tester, repository: _FakeCurrencyRepository(), picked: picked);

    await tester.tap(find.text(l10n.cancelButton));
    await tester.pumpAndSettle();

    expect(picked, [null]);
  });

  testWidgets('the current choice carries a check mark', (tester) async {
    await _open(
      tester,
      repository: _FakeCurrencyRepository(),
      selectedCurrencyCode: 'GBP',
    );

    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('it takes the repository from the tree when given none', (
    tester,
  ) async {
    final repository = _FakeCurrencyRepository(favorites: ['JPY']);
    await pumpAppWidget(
      tester,
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () =>
              showCurrencyPicker(context: context, currencies: _all),
          child: const Text('open'),
        ),
      ),
      surfaceSize: const Size(800, 1000),
      // Above the app: a dialog is a sibling route of `home`, so a provider
      // wrapped around the button itself would be invisible to it.
      aboveApp: (app) => RepositoryProvider<CurrencyRepository>.value(
        value: repository,
        child: app,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text(l10n.favoriteCurrenciesHeader), findsOneWidget);
  });

  testWidgets('with no repository anywhere it still opens, without stars', (
    tester,
  ) async {
    // A widget test pumping one screen in isolation, and the shape any future
    // caller gets wrong. A picker that cannot read the stars is still a picker.
    await _open(tester);

    expect(find.byIcon(Icons.star_border), findsNothing);
    expect(find.text(l10n.favoriteCurrenciesHeader), findsNothing);
    expect(find.text(_label(_eur)), findsOneWidget);
  });
}
