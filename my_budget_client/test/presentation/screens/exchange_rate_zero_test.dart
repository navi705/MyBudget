// A rate of zero, typed straight into the exchange-rate dialog.
//
// The save button only checked `rate != null`, so '0' parsed, stored and then
// converted every amount through that pair to nothing. The import path has
// always refused a rate that is not a positive finite number; this is the same
// rule on the one screen where a rate is entered by hand.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/di/injection_container.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
import 'package:my_budget_client/presentation/blocs/exchange_rates/exchange_rates_bloc.dart';
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';
import 'package:my_budget_client/presentation/screens/exchange_rates_screen.dart';

import '../test_app.dart';

class _RecordingExchangeRatesBloc extends MockExchangeRatesBloc {
  final events = <ExchangeRatesEvent>[];

  @override
  void add(ExchangeRatesEvent event) => events.add(event);
}

class _FakeCurrencyRepository extends Fake implements CurrencyRepository {
  @override
  Future<List<int>> getAvailablePresets() async => const [];
}

final _rate = ExchangeRateDomain(
  fromCurrencyCode: 'EUR',
  toCurrencyCode: 'USD',
  rate: 1.1,
  date: DateTime(2024, 3, 15),
  preset: 1,
);

/// Opens the screen on one existing rate and taps it, which is the edit branch
/// of the dialog - the one where both currencies are already filled in, so the
/// rate is the only thing standing between the button and a write.
Future<_RecordingExchangeRatesBloc> _openRateDialog(
  WidgetTester tester,
) async {
  setSurfaceSize(tester, const Size(900, 900));

  final bloc = _RecordingExchangeRatesBloc();
  whenListen(
    bloc,
    const Stream<ExchangeRatesState>.empty(),
    initialState: ExchangeRatesState(
      status: ExchangeRatesStatus.success,
      activeDate: DateTime(2024, 3, 15),
      exchangeRates: [_rate],
      hasReachedMax: true,
    ),
  );

  if (sl.isRegistered<ExchangeRatesBloc>()) {
    sl.unregister<ExchangeRatesBloc>();
  }
  sl.registerFactory<ExchangeRatesBloc>(() => bloc);
  addTearDown(() => sl.unregister<ExchangeRatesBloc>());

  await tester.pumpWidget(
    RepositoryProvider<CurrencyRepository>.value(
      value: _FakeCurrencyRepository(),
      child: wrapWithBlocs(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ExchangeRatesScreen(),
        ),
        settingsBloc: createSettingsBloc(state: const SettingsState()),
        currencyBloc: createCurrencyBloc(),
        stylesBloc: createStylesBloc(),
      ),
    ),
  );
  await tester.pumpAndSettle();

  // By the row rather than by its text: the rate is rendered through
  // `RateFormatter`, so what it reads as is a formatting decision this test
  // has no business pinning.
  await tester.tap(find.byType(ListTile).first);
  await tester.pumpAndSettle();

  return bloc;
}

/// The rate field is the first of the dialog's two text fields; the second is
/// the preset id.
Finder get _rateField => find.byType(TextField).first;

Future<void> _save(WidgetTester tester, String rate) async {
  final l10n = await loadL10n();
  await tester.enterText(_rateField, rate);
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, l10n.saveButton));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a rate of zero is refused and reported on the field', (
    tester,
  ) async {
    final l10n = await loadL10n();
    final bloc = await _openRateDialog(tester);

    await _save(tester, '0');

    expect(bloc.events.whereType<UpdateExchangeRate>(), isEmpty);
    expect(
      find.text(l10n.formValidationPleaseEnterValidNumber),
      findsOneWidget,
    );
  });

  testWidgets('the dialog stays open on a refused rate', (tester) async {
    // Popping would leave the user looking at the unchanged list with no way
    // to tell whether anything happened.
    await _openRateDialog(tester);

    await _save(tester, '0');

    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('an empty rate field is refused the same way', (tester) async {
    final bloc = await _openRateDialog(tester);

    await _save(tester, '');

    expect(bloc.events.whereType<UpdateExchangeRate>(), isEmpty);
  });

  testWidgets('an ordinary rate still saves', (tester) async {
    // The guard has to remove the bad values, not the dialog.
    final bloc = await _openRateDialog(tester);

    await _save(tester, '1.25');

    final updates = bloc.events.whereType<UpdateExchangeRate>().toList();
    expect(updates, hasLength(1));
    expect(updates.single.updatedExchangeRate.rate, 1.25);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
