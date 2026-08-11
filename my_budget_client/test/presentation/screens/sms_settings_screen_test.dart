// SmsSettingsScreen is the one screen that is deliberately unavailable off
// Android. Two things have to hold: the notice is shown instead of the feature,
// and the screen does not reach for `SmsBloc` — that bloc is only provided on
// Android, so touching it would turn a graceful notice into a
// ProviderNotFoundException on every other platform.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/utils/platform/platform_utils.dart';
import 'package:my_budget_client/presentation/blocs/sms/sms_bloc.dart';
import 'package:my_budget_client/presentation/screens/sms_settings_screen.dart';

import '../test_app.dart';

void main() {
  tearDown(() => debugAppPlatformOverride = null);

  group('SmsSettingsScreen off Android', () {
    for (final platform in [
      AppPlatformKind.iOS,
      AppPlatformKind.windows,
      AppPlatformKind.linux,
      AppPlatformKind.macOS,
      AppPlatformKind.web,
    ]) {
      testWidgets('shows the unsupported notice on $platform', (tester) async {
        debugAppPlatformOverride = platform;
        final l10n = await loadL10n();

        // No SmsBloc on purpose: this is the provider set off Android.
        await pumpAppWidget(
          tester,
          const SmsSettingsScreen(),
          wrapInScaffold: false,
        );

        expect(tester.takeException(), isNull);
        expect(find.text(l10n.smsOnlyAndroid), findsOneWidget);
        // The feature's own affordances must be gone, not merely disabled.
        expect(find.byIcon(Icons.download), findsNothing);
        expect(find.byType(FloatingActionButton), findsNothing);
      });
    }
  });

  group('SmsSettingsScreen on Android', () {
    testWidgets('shows the feature rather than the notice', (tester) async {
      debugAppPlatformOverride = AppPlatformKind.android;
      final l10n = await loadL10n();

      await pumpAppWidget(
        tester,
        const SmsSettingsScreen(),
        wrapInScaffold: false,
        aboveApp: (app) => wrapWithBlocs(app, smsBloc: createSmsBloc()),
      );

      expect(find.text(l10n.smsOnlyAndroid), findsNothing);
      expect(find.byIcon(Icons.download), findsOneWidget);
    });

    testWidgets('reuses the SmsBloc from above instead of building one', (
      tester,
    ) async {
      // A second instance would open a second listenForSms() subscription and
      // double-handle every incoming message.
      debugAppPlatformOverride = AppPlatformKind.android;
      final bloc = createSmsBloc();

      await pumpAppWidget(
        tester,
        const SmsSettingsScreen(),
        wrapInScaffold: false,
        aboveApp: (app) => wrapWithBlocs(app, smsBloc: bloc),
      );

      final inner = tester.element(find.byType(Scaffold)).read<SmsBloc>();
      expect(identical(inner, bloc), isTrue);
    });

    testWidgets('builds right-to-left in Arabic', (tester) async {
      debugAppPlatformOverride = AppPlatformKind.android;

      await pumpAppWidget(
        tester,
        const SmsSettingsScreen(),
        locale: const Locale('ar'),
        wrapInScaffold: false,
        aboveApp: (app) => wrapWithBlocs(app, smsBloc: createSmsBloc()),
      );

      expect(tester.takeException(), isNull);
      expect(
        Directionality.of(tester.element(find.byType(SmsSettingsScreen))),
        TextDirection.rtl,
      );
    });
  });
}
