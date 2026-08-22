// Where the account row puts its "change" figure.
//
// This used to be the only `Theme.of(context).platform` gate in the
// presentation layer — mobile stacked the figure onto a second line, desktop
// kept it inline — and these tests pinned it that way. The gate is gone: it
// made a 360dp desktop window and a 360dp Android phone lay the same row out
// differently for a reason no user could see, and the decision is really about
// width, so `account_list_item.dart` now measures the value column against
// `_kInlineChangeMinWidth`.
//
// The invariant flipped, so the tests flipped with it. What is pinned now is
// the rule itself: narrow stacks, wide stays inline, and the platform makes no
// difference at a fixed width. Still worth pinning precisely because it is
// invisible — nothing fails if it regresses, the number just silently moves.
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

/// Narrow enough that the value column cannot hold the change figure inline:
/// the Android reference width the renders used.
const Size _narrow = Size(360, 800);

/// Room to spare — the desktop case.
const Size _wide = Size(900, 800);

Future<void> _pumpItem(
  WidgetTester tester, {
  TargetPlatform? platform,
  Locale locale = const Locale('en'),
  Size surface = _wide,
}) async {
  await pumpAppWidget(
    tester,
    AccountListItem(account: _account, prevBalance: 1000),
    platform: platform,
    locale: locale,
    surfaceSize: surface,
    aboveApp: (app) => wrapWithBlocs(
      app,
      currencyBloc: createCurrencyBloc(),
      stylesBloc: createStylesBloc(),
    ),
  );
  // MaterialApp lerps between themes, and ThemeData.lerp keeps the *old*
  // platform until the halfway point — so re-pumping with a different platform
  // inside one test needs the animation settled before the row is read.
  await tester.pumpAndSettle();
}

/// The balance row's span. It hung off a `SelectableText` until that was
/// found to be eating the row's own tap and long press.
TextSpan _balanceSpan(WidgetTester tester) =>
    tester
            .widgetList<Text>(find.byType(Text))
            .firstWhere((text) => text.textSpan != null)
            .textSpan!
        as TextSpan;

/// Flattened text of the balance row, separators included.
String _balanceRowText(WidgetTester tester) =>
    _balanceSpan(tester).toPlainText();

void main() {
  group('AccountListItem change separator', () {
    testWidgets('breaks the line when the value column is narrow', (
      tester,
    ) async {
      await _pumpItem(
        tester,
        platform: TargetPlatform.android,
        surface: _narrow,
      );

      expect(_balanceRowText(tester), contains('\n'));
    });

    testWidgets('stays on one line when there is room for it', (tester) async {
      await _pumpItem(tester, platform: TargetPlatform.windows);

      expect(_balanceRowText(tester), isNot(contains('\n')));
    });

    // The regression the width rule was written to kill. A 360dp window is
    // 360dp wide whether it is a phone or a desktop window dragged narrow, and
    // a 900dp one is roomy on either; before the rule, identical pixels laid
    // out differently across a platform check no user can see.
    for (final platform in TargetPlatform.values) {
      testWidgets('follows width, not platform, on $platform', (tester) async {
        await _pumpItem(tester, platform: platform, surface: _narrow);
        expect(
          _balanceRowText(tester),
          contains('\n'),
          reason: 'did not stack at ${_narrow.width}dp on $platform',
        );

        await _pumpItem(tester, platform: platform, surface: _wide);
        expect(
          _balanceRowText(tester),
          isNot(contains('\n')),
          reason: 'stacked at ${_wide.width}dp on $platform',
        );
      });
    }

    testWidgets('shows the same figures on both sides of the rule', (
      tester,
    ) async {
      final l10n = await loadL10n();

      await _pumpItem(tester, surface: _narrow);
      final stacked = _balanceRowText(tester);

      await _pumpItem(tester, surface: _wide);
      final inline = _balanceRowText(tester);

      expect(stacked.replaceAll('\n', ' '), inline);
      for (final text in [stacked, inline]) {
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
        surfaceSize: _wide,
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

        expect(tester.takeException(), isNull, reason: 'threw on $platform');
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
        surfaceSize: _narrow,
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
  // =========================================================================
  // The row exists to be tapped: a tap opens the account, a long press starts
  // a selection. The figures were `SelectableText`, which wins both gestures
  // against the `ListTile` behind it - and they cover most of the card, so the
  // majority of it answered neither.
  group('the whole card answers a tap', () {
    Future<(int, int)> tapAndHold(
      WidgetTester tester,
      Finder Function(WidgetTester) target,
    ) async {
      var taps = 0;
      var longPresses = 0;
      await pumpAppWidget(
        tester,
        AccountListItem(
          account: _account,
          prevBalance: 1000,
          onTap: () => taps++,
          onLongPress: () => longPresses++,
        ),
        surfaceSize: _wide,
        aboveApp: (app) => wrapWithBlocs(
          app,
          currencyBloc: createCurrencyBloc(),
          stylesBloc: createStylesBloc(),
        ),
      );
      await tester.pumpAndSettle();

      final finder = target(tester);
      await tester.tap(finder, warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.longPress(finder, warnIfMissed: false);
      await tester.pumpAndSettle();
      return (taps, longPresses);
    }

    testWidgets('on the balance figure', (tester) async {
      // The span itself, not the label beside it: the label was always plain
      // text and always let the gesture through.
      expect(
        await tapAndHold(
          tester,
          (tester) => find.byWidget(
            tester
                .widgetList<Text>(find.byType(Text))
                .firstWhere((text) => text.textSpan != null),
          ),
        ),
        (1, 1),
      );
    });

    testWidgets('and on the account name', (tester) async {
      expect(await tapAndHold(tester, (_) => find.text(_account.name)), (1, 1));
    });
  });
}
