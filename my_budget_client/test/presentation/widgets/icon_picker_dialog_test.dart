// IconPickerDialog loads its two tabs from initState: the material catalogue
// from the asset bundle, the custom icons from the documents directory.
//
// The documents directory is the interesting part. path_provider has no web
// implementation, so on web that call raises a MissingPluginException — which
// used to abort `_loadCustomIcons` before its setState and left the Custom tab
// empty forever, bundled assets included. `kIsWeb` is a compile-time constant
// and cannot be flipped in a VM test, so these tests cover the non-web branch
// and the disposal race; the web branch is verified by inspection only.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/domain/entities/icon_type.dart';
import 'package:my_budget_client/presentation/widgets/icon_picker_dialog.dart';

import '../test_app.dart';

const MethodChannel _pathProvider = MethodChannel(
  'plugins.flutter.io/path_provider',
);

/// Opens the dialog from a button, the way the app does.
Future<void> _openDialog(WidgetTester tester) async {
  await pumpAppWidget(
    tester,
    Builder(
      builder: (context) => ElevatedButton(
        onPressed: () => showDialog<Object?>(
          context: context,
          builder: (_) => const IconPickerDialog(
            initialIconName: 'wallet',
            initialIconType: IconType.material,
          ),
        ),
        child: const Text('open'),
      ),
    ),
    surfaceSize: const Size(800, 900),
  );
  await tester.tap(find.text('open'));
}

/// Bounded pumps instead of `pumpAndSettle`.
///
/// The picker never reaches a settled frame in a test host: while the material
/// catalogue is still loading a CircularProgressIndicator animates forever, and
/// once it has loaded the icon grids keep decoding. Either way the frame queue
/// stays busy, so the tests advance a fixed amount of time instead.
Future<void> _settleDialog(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  setUp(() {
    // Stands in for the plugin on hosts that answer over the method channel.
    // (The desktop implementations resolve the documents directory through FFI
    // instead, so this handler is never consulted there — which is also why
    // the disposal race below cannot be forced open on those hosts: the load
    // has already finished by the time the picker can be dismissed.)
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          _pathProvider,
          (call) async => Directory.systemTemp.createTempSync('icons').path,
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProvider, null);
  });

  testWidgets('opens with both tabs', (tester) async {
    final l10n = await loadL10n();
    await _openDialog(tester);
    await _settleDialog(tester);

    expect(find.text(l10n.pckSelectIcon), findsOneWidget);
    expect(find.text(l10n.pckMaterialIcons), findsOneWidget);
    expect(find.text(l10n.pckCustomIcons), findsOneWidget);
  });

  testWidgets('survives being dismissed while its icons are still loading', (
    tester,
  ) async {
    // Both loaders are async and both end in setState, so dismissing the
    // picker mid-load must not reach a disposed State. This is a regression
    // guard rather than a reproduction: on a host where the loaders complete
    // before the pop, it passes either way.
    await _openDialog(tester);
    await tester.pump();

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(IconPickerDialog), findsNothing);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
  });

  testWidgets('offers the add-icon button off web', (tester) async {
    await _openDialog(tester);
    await _settleDialog(tester);

    await tester.tap(find.text((await loadL10n()).pckCustomIcons));
    await _settleDialog(tester);

    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('builds right-to-left in Arabic', (tester) async {
    await pumpAppWidget(
      tester,
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showDialog<Object?>(
            context: context,
            builder: (_) => const IconPickerDialog(
              initialIconName: 'wallet',
              initialIconType: IconType.material,
            ),
          ),
          child: const Text('open'),
        ),
      ),
      locale: const Locale('ar'),
      surfaceSize: const Size(800, 900),
    );
    await tester.tap(find.text('open'));
    await _settleDialog(tester);

    expect(tester.takeException(), isNull);
    expect(
      Directionality.of(tester.element(find.byType(IconPickerDialog))),
      TextDirection.rtl,
    );
  });
}
