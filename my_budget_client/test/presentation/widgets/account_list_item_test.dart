// The only `Theme.of(context).platform` gate in the presentation layer.
//
// It is purely typographic — mobile puts the "change" figure on its own line,
// desktop keeps it inline — so the test asserts that both branches carry the
// same information and differ only in the separator. A gate like this is worth
// pinning precisely because it is invisible: nothing fails if it flips, the
// number just silently moves.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/presentation/widgets/account_list_item.dart';

import '../test_app.dart';

final _account = Account(
  id: 'a1',
  name: 'Checking',
  balance: 1500,
  currencyCode: 'EUR',
  currencyDesignationId: 'd1',
  accountTypeId: 't1',
  creationDate: DateTime(2024, 1, 1),
);

Future<void> _pumpItem(
  WidgetTester tester, {
  TargetPlatform? platform,
  Locale locale = const Locale('en'),
}) async {
  await pumpAppWidget(
    tester,
    AccountListItem(account: _account, prevBalance: 1000),
    platform: platform,
    locale: locale,
    surfaceSize: const Size(500, 900),
    aboveApp: (app) => wrapWithBlocs(
      app,
      currencyBloc: createCurrencyBloc(),
      stylesBloc: createStylesBloc(),
    ),
  );
  // MaterialApp lerps between themes, and ThemeData.lerp keeps the *old*
  // platform until the halfway point — so re-pumping with a different platform
  // inside one test needs the animation settled before the gate is read.
  await tester.pumpAndSettle();
}

/// Flattened text of the balance row, separators included.
String _balanceRowText(WidgetTester tester) => tester
    .widget<SelectableText>(find.byType(SelectableText).first)
    .textSpan!
    .toPlainText();

void main() {
  group('AccountListItem change separator', () {
    testWidgets('breaks the line on Android', (tester) async {
      await _pumpItem(tester, platform: TargetPlatform.android);

      expect(_balanceRowText(tester), contains('\n'));
    });

    testWidgets('breaks the line on iOS', (tester) async {
      await _pumpItem(tester, platform: TargetPlatform.iOS);

      expect(_balanceRowText(tester), contains('\n'));
    });

    for (final platform in [
      TargetPlatform.windows,
      TargetPlatform.linux,
      TargetPlatform.macOS,
    ]) {
      testWidgets('stays on one line on $platform', (tester) async {
        await _pumpItem(tester, platform: platform);

        expect(_balanceRowText(tester), isNot(contains('\n')));
      });
    }

    testWidgets('shows the same figures on both sides of the gate', (
      tester,
    ) async {
      final l10n = await loadL10n();

      await _pumpItem(tester, platform: TargetPlatform.android);
      final mobile = _balanceRowText(tester);

      await _pumpItem(tester, platform: TargetPlatform.windows);
      final desktop = _balanceRowText(tester);

      expect(mobile.replaceAll('\n', ' '), desktop);
      for (final text in [mobile, desktop]) {
        expect(text, contains(l10n.metricChange));
        expect(text, contains('+50.00%'));
      }
    });

    testWidgets('omits the change entirely when there is no previous value', (
      tester,
    ) async {
      final l10n = await loadL10n();

      await pumpAppWidget(
        tester,
        AccountListItem(account: _account),
        platform: TargetPlatform.android,
        surfaceSize: const Size(500, 900),
        aboveApp: (app) => wrapWithBlocs(
          app,
          currencyBloc: createCurrencyBloc(),
          stylesBloc: createStylesBloc(),
        ),
      );
      await tester.pump();

      expect(_balanceRowText(tester), isNot(contains(l10n.metricChange)));
    });
  });

  group('AccountListItem rendering', () {
    testWidgets('renders on every platform without overflowing', (
      tester,
    ) async {
      for (final platform in TargetPlatform.values) {
        await _pumpItem(tester, platform: platform);

        expect(
          tester.takeException(),
          isNull,
          reason: 'threw on $platform',
        );
        expect(find.text(_account.name), findsOneWidget);
      }
    });

    testWidgets('renders right-to-left in Arabic', (tester) async {
      await _pumpItem(
        tester,
        platform: TargetPlatform.android,
        locale: const Locale('ar'),
      );

      expect(tester.takeException(), isNull);
      expect(
        Directionality.of(tester.element(find.byType(AccountListItem))),
        TextDirection.rtl,
      );
    });

    testWidgets('renders right-to-left in Urdu on a narrow surface', (
      tester,
    ) async {
      await pumpAppWidget(
        tester,
        AccountListItem(account: _account, prevBalance: 1000),
        platform: TargetPlatform.android,
        locale: const Locale('ur'),
        surfaceSize: const Size(360, 800),
        aboveApp: (app) => wrapWithBlocs(
          app,
          currencyBloc: createCurrencyBloc(),
          stylesBloc: createStylesBloc(),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
