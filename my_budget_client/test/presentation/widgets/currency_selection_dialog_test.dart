// Choosing several currencies at once - the accounts filter, and the set the
// total-balance widget adds up.
//
// The single-currency picker learned to put starred codes first and used ones
// next; this dialog stayed a flat alphabetical run of every currency the app
// knows, so the same person answering the same question got a different list
// depending on which screen asked. These tests pin it to the same order, and to
// the one thing sections make possible: a currency on screen twice.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
import 'package:my_budget_client/presentation/widgets/currency_selection_dialog.dart';

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

/// Opens the dialog the way the filter screens do.
///
/// [picked] collects what the dialog pops - the list of currencies the filter
/// will be built from - which lands there after the dialog is dismissed.
Future<void> _open(
  WidgetTester tester, {
  CurrencyRepository? repository,
  List<Currency> selected = const [],
  List<List<Currency>?>? picked,
}) async {
  await pumpAppWidget(
    tester,
    Builder(
      builder: (context) => ElevatedButton(
        onPressed: () async {
          final result = await showDialog<List<Currency>>(
            context: context,
            builder: (_) => CurrencySelectionDialog(
              allCurrencies: _all,
              selectedCurrencies: selected,
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

double _firstY(WidgetTester tester, Currency currency) =>
    tester.getTopLeft(find.text(_label(currency)).first).dy;

void main() {
  late AppLocalizations l10n;

  setUpAll(() async => l10n = await loadL10n());

  testWidgets('with nothing starred or used it is the plain list', (
    tester,
  ) async {
    await _open(tester, repository: _FakeCurrencyRepository());

    expect(find.text(l10n.favoriteCurrenciesHeader), findsNothing);
    expect(find.text(l10n.frequentCurrenciesHeader), findsNothing);
    expect(find.text(l10n.allCurrenciesHeader), findsNothing);
    for (final currency in _all) {
      expect(find.text(_label(currency)), findsOneWidget);
    }
  });

  testWidgets('starred codes sit above the used ones, which sit above the '
      'rest', (tester) async {
    await _open(
      tester,
      repository: _FakeCurrencyRepository(
        favorites: ['JPY'],
        usage: {'USD': 12},
      ),
    );

    expect(_firstY(tester, _jpy), lessThan(_firstY(tester, _usd)));
    // GBP is neither starred nor used, so it only appears in the full list.
    expect(_firstY(tester, _usd), lessThan(_firstY(tester, _gbp)));
    expect(find.text(l10n.favoriteCurrenciesHeader), findsOneWidget);
    expect(find.text(l10n.frequentCurrenciesHeader), findsOneWidget);
    expect(find.text(l10n.allCurrenciesHeader), findsOneWidget);
  });

  testWidgets('the used ones are ordered by how much they were used', (
    tester,
  ) async {
    await _open(
      tester,
      repository: _FakeCurrencyRepository(usage: {'USD': 2, 'JPY': 40}),
    );

    expect(_firstY(tester, _jpy), lessThan(_firstY(tester, _usd)));
  });

  testWidgets('a currency listed twice is still selected once', (tester) async {
    // Starred, so it is in the favourites section and again in the full list.
    // Ticking one box has to tick the other, and the filter must not end up
    // holding the same currency twice - a duplicate would make an `IN` clause
    // list it twice and a chip row show it twice.
    final picked = <List<Currency>?>[];
    await _open(
      tester,
      repository: _FakeCurrencyRepository(favorites: ['EUR']),
      picked: picked,
    );

    final boxes = find.widgetWithText(CheckboxListTile, _label(_eur));
    expect(boxes, findsNWidgets(2));

    await tester.tap(boxes.first);
    await tester.pumpAndSettle();

    // Both rows show the same currency, so both show it as chosen.
    for (final box in tester.widgetList<CheckboxListTile>(boxes)) {
      expect(box.value, isTrue);
    }

    await tester.tap(find.text(l10n.okButton));
    await tester.pumpAndSettle();

    expect(picked.single, hasLength(1));
    expect(picked.single!.single.code, 'EUR');
  });

  testWidgets('unticking either row clears the selection', (tester) async {
    final picked = <List<Currency>?>[];
    await _open(
      tester,
      repository: _FakeCurrencyRepository(favorites: ['EUR']),
      selected: [_eur],
      picked: picked,
    );

    final boxes = find.widgetWithText(CheckboxListTile, _label(_eur));
    // The full-list row, not the starred one the user ticked it from.
    await tester.tap(boxes.last);
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.okButton));
    await tester.pumpAndSettle();

    expect(picked.single, isEmpty);
  });

  testWidgets('the star writes through and moves the row up', (tester) async {
    final repository = _FakeCurrencyRepository(usage: {'USD': 3});
    await _open(tester, repository: repository);

    // GBP starts at the bottom: not starred, never used.
    expect(_firstY(tester, _usd), lessThan(_firstY(tester, _gbp)));

    await tester.tap(
      find.descendant(
        of: find.widgetWithText(CheckboxListTile, _label(_gbp)),
        matching: find.byIcon(Icons.star_border),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.writes, [('GBP', true)]);
    expect(_firstY(tester, _gbp), lessThan(_firstY(tester, _usd)));
  });

  testWidgets('starring is not selecting', (tester) async {
    // The star and the checkbox are two answers to two questions, and the row
    // carries both: pinning a currency to the top must not silently add it to
    // the filter.
    final picked = <List<Currency>?>[];
    await _open(tester, repository: _FakeCurrencyRepository(), picked: picked);

    await tester.tap(
      find.descendant(
        of: find.widgetWithText(CheckboxListTile, _label(_gbp)),
        matching: find.byIcon(Icons.star_border),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.okButton));
    await tester.pumpAndSettle();

    expect(picked.single, isEmpty);
  });

  testWidgets('search still reaches every currency', (tester) async {
    await _open(
      tester,
      repository: _FakeCurrencyRepository(favorites: ['EUR']),
    );

    await tester.enterText(find.byType(TextField), 'yen');
    await tester.pumpAndSettle();

    expect(find.text(_label(_jpy)), findsOneWidget);
    expect(find.text(_label(_eur)), findsNothing);
    // Nothing starred is left showing, so the heading goes with it.
    expect(find.text(l10n.favoriteCurrenciesHeader), findsNothing);
  });

  testWidgets('with no repository above it the stars are gone, not broken', (
    tester,
  ) async {
    // A screen pumped on its own, with no RepositoryProvider: the dialog still
    // opens and still picks, it just has nowhere to save a star.
    await _open(tester);

    expect(find.byIcon(Icons.star_border), findsNothing);
    expect(find.byIcon(Icons.star), findsNothing);
    for (final currency in _all) {
      expect(find.text(_label(currency)), findsOneWidget);
    }
  });

  testWidgets('the stars come off the tree when the caller names no '
      'repository', (tester) async {
    // How the app itself opens it: the filter screens pass currencies and
    // nothing else, and the repository is the one already above the app.
    // Provided above the MaterialApp, not around the button, because the
    // dialog is a route under the app's Navigator - which is where production
    // puts it too.
    final repository = _FakeCurrencyRepository(favorites: ['GBP']);
    await pumpAppWidget(
      tester,
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showDialog<List<Currency>>(
            context: context,
            builder: (_) => CurrencySelectionDialog(
              allCurrencies: _all,
              selectedCurrencies: const [],
            ),
          ),
          child: const Text('open'),
        ),
      ),
      surfaceSize: const Size(800, 1000),
      aboveApp: (app) => RepositoryProvider<CurrencyRepository>.value(
        value: repository,
        child: app,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text(l10n.favoriteCurrenciesHeader), findsOneWidget);
    expect(_firstY(tester, _gbp), lessThan(_firstY(tester, _eur)));
  });
}
