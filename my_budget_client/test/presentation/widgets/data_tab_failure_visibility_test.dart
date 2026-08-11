// Both Data tabs reported a failed add/edit/delete only through a branch gated
// on their list being empty - which, for anyone who already has data, it never
// is. The dialogs pop as soon as they dispatch, so the user was left looking at
// an unchanged list with no indication that the write had failed at all.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/domain/entities/asset_data.dart';
import 'package:my_budget_client/domain/entities/inflation_rate.dart';
import 'package:my_budget_client/presentation/blocs/asset/asset_bloc.dart';
import 'package:my_budget_client/presentation/blocs/asset/asset_event.dart';
import 'package:my_budget_client/presentation/blocs/asset/asset_state.dart';
import 'package:my_budget_client/presentation/blocs/inflation/inflation_bloc.dart';
import 'package:my_budget_client/presentation/widgets/asset_view.dart';
import 'package:my_budget_client/presentation/widgets/inflation_view.dart';

import '../test_app.dart';

class _MockAssetBloc extends MockBloc<AssetEvent, AssetState>
    implements AssetBloc {}

class _MockInflationBloc extends MockBloc<InflationEvent, InflationState>
    implements InflationBloc {}

final _asset = AssetDataDomain(
  id: 'a1',
  assetId: 'BTC',
  name: 'Bitcoin',
  date: DateTime(2025, 3),
  value: 100,
  source: 'manual',
);

final _rate = InflationRateDomain(
  date: DateTime(2025, 3),
  percent: 2.5,
  country: 'SRB',
  preset: 1,
);

void main() {
  testWidgets('a failed asset write is reported over a populated list', (
    tester,
  ) async {
    final loaded = AssetState(
      status: AssetStatus.success,
      assetData: [_asset],
      activeDate: DateTime(2025, 3),
    );
    final bloc = _MockAssetBloc();
    whenListen(
      bloc,
      Stream<AssetState>.value(
        loaded.copyWith(
          status: AssetStatus.failure,
          errorMessage: 'disk is full',
        ),
      ),
      initialState: loaded,
    );
    addTearDown(bloc.close);

    await pumpAppWidget(
      tester,
      BlocProvider<AssetBloc>.value(
        value: bloc,
        child: AssetView(onEdit: (_) {}),
      ),
    );
    await tester.pump();

    expect(find.widgetWithText(SnackBar, 'Error: disk is full'), findsOne);
    expect(
      find.text('Bitcoin'),
      findsOne,
      reason: 'the failure must not take the list away',
    );
  });

  testWidgets('a failed inflation write is reported over a populated list', (
    tester,
  ) async {
    final l10n = await loadL10n();
    final loaded = InflationState(
      status: InflationStatus.success,
      rates: [_rate],
      activeDate: DateTime(2025, 3),
    );
    final bloc = _MockInflationBloc();
    whenListen(
      bloc,
      Stream<InflationState>.value(
        loaded.copyWith(
          status: InflationStatus.failure,
          errorMessage: 'disk is full',
        ),
      ),
      initialState: loaded,
    );
    addTearDown(bloc.close);

    await pumpAppWidget(
      tester,
      BlocProvider<InflationBloc>.value(
        value: bloc,
        child: InflationView(onEdit: (_) {}),
      ),
    );
    await tester.pump();

    expect(
      find.widgetWithText(SnackBar, l10n.inflationError('disk is full')),
      findsOne,
    );
  });

  group('the message does not outlive the failure', () {
    test('a successful asset load clears it', () {
      final failed = AssetState(
        status: AssetStatus.failure,
        errorMessage: 'disk is full',
        activeDate: DateTime(2025, 3),
      );

      expect(
        failed.copyWith(forceNullErrorMessage: true).errorMessage,
        isNull,
        reason: 'a stale message would be reported again as if it were new',
      );
    });

    test('a successful inflation load clears it', () {
      final failed = InflationState(
        status: InflationStatus.failure,
        errorMessage: 'disk is full',
        activeDate: DateTime(2025, 3),
      );

      expect(failed.copyWith(forceNullErrorMessage: true).errorMessage, isNull);
    });
  });
}
