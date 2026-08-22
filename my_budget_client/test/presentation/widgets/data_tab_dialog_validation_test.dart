// Both Data tab dialogs used to guard Save with a bare `if (parsed != null)`
// and no else: a blank or unparseable field made the button do nothing at all,
// with nothing marked and the dialog just sitting there. The inflation dialog
// also took the country as free text, which FinanceCalculator - it looks a rate
// up by exact World Bank code - could never match, so the rate was stored,
// listed, and silently never applied to a balance.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:my_budget_client/core/utils/country_codes.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/presentation/blocs/asset/asset_bloc.dart';
import 'package:my_budget_client/presentation/blocs/asset/asset_event.dart';
import 'package:my_budget_client/presentation/blocs/asset/asset_state.dart';
import 'package:my_budget_client/presentation/blocs/inflation/inflation_bloc.dart';
import 'package:my_budget_client/presentation/widgets/asset_tab.dart';
import 'package:my_budget_client/presentation/widgets/inflation_tab.dart';

import '../test_app.dart';

/// A bloc that records what the dialog dispatched.
///
/// `MockBloc` stubs `add` into a no-op, which is what makes these tests about
/// the widget - but the whole point of the country picker is *which* value
/// leaves the dialog, so `add` is overridden to keep the events.
class _RecordingInflationBloc extends MockBloc<InflationEvent, InflationState>
    implements InflationBloc {
  final events = <InflationEvent>[];

  @override
  void add(InflationEvent event) => events.add(event);
}

class _RecordingAssetBloc extends MockBloc<AssetEvent, AssetState>
    implements AssetBloc {
  final events = <AssetEvent>[];

  @override
  void add(AssetEvent event) => events.add(event);
}

/// The Add Asset dialog reads the account list before it opens; an empty one is
/// enough, the linked account is optional.
class _NoAccountsRepository extends Fake implements AccountRepository {
  @override
  Future<List<Account>> getAccounts() async => const [];
}

InflationState _inflationState() => InflationState(
  status: InflationStatus.success,
  activeDate: DateTime(2025, 3),
);

AssetState _assetState() =>
    AssetState(status: AssetStatus.success, activeDate: DateTime(2025, 3));

Future<void> _openAddDialog(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.add));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(GetIt.I.reset);

  group('inflation', () {
    late _RecordingInflationBloc bloc;

    setUp(() {
      bloc = _RecordingInflationBloc();
      whenListen(
        bloc,
        const Stream<InflationState>.empty(),
        initialState: _inflationState(),
      );
      GetIt.I.registerFactory<InflationBloc>(() => bloc);
    });

    Future<void> pumpTab(WidgetTester tester) => pumpAppWidget(
      tester,
      const InflationTab(),
      wrapInScaffold: false,
      surfaceSize: const Size(1200, 1600),
      aboveApp: (app) => wrapWithBlocs(app, settingsBloc: createSettingsBloc()),
    );

    testWidgets(
      'Add with no percent marks the field instead of doing nothing',
      (tester) async {
        await pumpTab(tester);
        await _openAddDialog(tester);

        await tester.tap(find.widgetWithText(FilledButton, 'Add'));
        await tester.pumpAndSettle();

        expect(find.text('Enter a number, for example 2.5'), findsOne);
        expect(
          find.text('Add Inflation Rate'),
          findsOne,
          reason: 'the dialog must stay open so the message can be read',
        );
        expect(
          bloc.events.whereType<AddInflationRate>(),
          isEmpty,
          reason: 'nothing may be saved while a field is unusable',
        );
      },
    );

    testWidgets('the country is saved as the World Bank code the picker gave', (
      tester,
    ) async {
      await pumpTab(tester);
      await _openAddDialog(tester);

      await tester.enterText(find.byType(TextField).first, '2.5');
      await tester.tap(find.text('Country: Global'));
      await tester.pumpAndSettle();

      // The picker searches localized names and codes alike, so the code is the
      // stable thing to type here.
      await tester.enterText(
        find.widgetWithText(TextField, 'Search Country'),
        'SRB',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'SRB'));
      await tester.pumpAndSettle();

      final name = getLocalizedCountryName('SRB', 'en');
      expect(find.text('Country: $name'), findsOne);

      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();

      final saved = bloc.events.whereType<AddInflationRate>().single.rate;
      expect(
        saved.country,
        'SRB',
        reason: 'FinanceCalculator matches on the exact code, not on a name',
      );
      expect(saved.percent, 2.5);
    });

    testWidgets('a worldwide rate is saved with no country at all', (
      tester,
    ) async {
      await pumpTab(tester);
      await _openAddDialog(tester);

      await tester.enterText(find.byType(TextField).first, '3');
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();

      final saved = bloc.events.whereType<AddInflationRate>().single.rate;
      expect(
        saved.country,
        isNull,
        reason:
            'InflationRateMapper substitutes the global sentinel at the DB '
            'boundary, so the UI must pass null rather than a made-up code',
      );
    });
  });

  group('assets', () {
    late _RecordingAssetBloc bloc;

    setUp(() {
      bloc = _RecordingAssetBloc();
      whenListen(
        bloc,
        const Stream<AssetState>.empty(),
        initialState: _assetState(),
      );
      GetIt.I.registerFactory<AssetBloc>(() => bloc);
      GetIt.I.registerSingleton<AccountRepository>(_NoAccountsRepository());
    });

    testWidgets('Add with blank fields marks every one that is missing', (
      tester,
    ) async {
      await pumpAppWidget(
        tester,
        const AssetTab(),
        wrapInScaffold: false,
        surfaceSize: const Size(1200, 1600),
        aboveApp: (app) =>
            wrapWithBlocs(app, settingsBloc: createSettingsBloc()),
      );
      await _openAddDialog(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();

      expect(find.text('Give the asset a name'), findsOne);
      expect(find.text('Give the asset an ID, for example AAPL'), findsOne);
      expect(find.text('Enter a number, for example 150.25'), findsOne);
      expect(
        bloc.events.whereType<AddAssetData>(),
        isEmpty,
        reason: 'nothing may be saved while a field is unusable',
      );
    });
  });
}
