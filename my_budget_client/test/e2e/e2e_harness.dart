// Boots the whole app - real DI, real database, real router, real blocs - so a
// test can drive it the way a person does and check what actually landed in
// the database at the end.
//
// This is deliberately NOT `test/presentation/test_app.dart`. That harness
// mocks every bloc and pumps one screen under its own `MaterialApp`, which is
// exactly right for asking "does this widget render this state". It cannot
// answer "can a user, on this device, complete this flow" - the mocks are the
// part under test as soon as the question spans two screens.
//
// There is no `integration_test` package here and adding one is out of scope,
// so the whole thing runs on `flutter_test` against `NativeDatabase.memory()`.
// That buys real drift queries, real repository code and real bloc streams; it
// does not buy a real Android or Windows binary. What it can and does check is
// the layer where the platforms actually differ in this codebase: the
// `AppPlatform` gates and the width/height-driven rail-or-bar shell.
//
// Two things bite immediately and are handled here rather than in every test:
//
//   - Real database work is real async, and `tester.pump()` only advances the
//     fake clock. [settleE2e] alternates `runAsync` (which lets the actual I/O
//     run) with `pump` (which lets the frames it caused be built).
//   - `App` builds its text theme from google_fonts, which fetches Inter at
//     runtime. In a test process there is no asset and no network, and
//     google_fonts rethrows out of a future nothing awaits - reported as a
//     failed test. [bootE2eApp] sets `debugUsePlatformTextTheme`.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:my_budget_client/app.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/di/injection_container.dart' as di;
import 'package:my_budget_client/core/utils/platform/platform_utils.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';

/// The surfaces the flows below are checked on.
///
/// These are the two the user names as the pair that must stay in step, and
/// they sit on opposite sides of every layout decision the app makes: the
/// phone gets the bottom bar, the desktop window gets the rail. A regression
/// that only strands one of them is exactly the kind this file exists to
/// catch, so every parity test runs the same body against both.
class E2eDevice {
  final String name;
  final Size size;
  final AppPlatformKind platform;

  /// Whether this surface is expected to lay out with the navigation rail.
  /// Asserted rather than assumed - if the breakpoint moves, the tests that
  /// depend on which shell they are in say so instead of silently drifting.
  final bool expectsRail;

  const E2eDevice({
    required this.name,
    required this.size,
    required this.platform,
    required this.expectsRail,
  });

  /// A phone in portrait. 411x866 is the logical size of a Pixel-class device,
  /// which is what the Android build actually ships onto.
  static const androidPhone = E2eDevice(
    name: 'Android phone',
    size: Size(411, 866),
    platform: AppPlatformKind.android,
    expectsRail: false,
  );

  /// A desktop window at the size the Windows build opens at.
  static const windowsDesktop = E2eDevice(
    name: 'Windows desktop',
    size: Size(1400, 950),
    platform: AppPlatformKind.windows,
    expectsRail: true,
  );

  /// A phone laid on its side. Wide enough to pass a width-only rail check and
  /// far too short to draw one - the case that once pushed Settings, and every
  /// screen only Settings reaches, off the bottom of the rail.
  static const androidLandscape = E2eDevice(
    name: 'Android phone, landscape',
    size: Size(866, 411),
    platform: AppPlatformKind.android,
    expectsRail: false,
  );

  /// A desktop window dragged down to half width. The host is still Windows;
  /// the box is a phone's, and the shell is supposed to follow the box.
  static const windowsHalfWidth = E2eDevice(
    name: 'Windows desktop, half width',
    size: Size(560, 900),
    platform: AppPlatformKind.windows,
    expectsRail: false,
  );

  static const all = [
    androidPhone,
    windowsDesktop,
    androidLandscape,
    windowsHalfWidth,
  ];

  /// The pair the user calls out by name: the phone and the desktop window.
  static const primary = [androidPhone, windowsDesktop];

  @override
  String toString() => name;
}

/// Everything a test needs to hold onto between booting the app and tearing it
/// back down.
class E2eApp {
  final WidgetTester tester;
  final AppDatabase database;
  final AppLocalizations l10n;
  final E2eDevice device;

  E2eApp._({
    required this.tester,
    required this.database,
    required this.l10n,
    required this.device,
  });

  /// Unmounts the app, closes the database and clears every global this boot
  /// touched.
  ///
  /// The order and the settling in between both matter. Blocs cancel their
  /// drift subscriptions in `close()`, and drift finishes a cancellation on a
  /// zero-duration timer - a FAKE timer, because it is created inside the test
  /// zone. `database.close()` waits for those cancellations, and it runs
  /// inside `runAsync`, where the fake clock does not tick. Close the database
  /// without settling first and it waits on timers that nothing will ever
  /// fire, which reads as the whole test hanging until its timeout with no
  /// error to point at.
  ///
  /// So: unmount, let the cancellations land, drop the singletons, let their
  /// cancellations land too, and only then close.
  Future<void> dispose() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await settleE2e(tester, rounds: 4);
    await tester.runAsync(() => GetIt.I.reset());
    await settleE2e(tester, rounds: 4);
    await tester.runAsync(() => database.close());
    for (final name in _stubbedChannels) {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        MethodChannel(name),
        null,
      );
    }
    tester.view.reset();
    debugAppPlatformOverride = null;
    debugUsePlatformTextTheme = false;
  }
}

/// Every channel [_installChannelStubs] answers, so tearing the stubs back
/// down cannot fall out of step with putting them up.
const _stubbedChannels = <String>[
  'dev.fluttercommunity.plus/device_info',
  'plugins.flutter.io/path_provider',
  'com.mybudget.app/file_picker',
  'com.mybudget.app/sms_events',
  'flutter.baseflow.com/permissions/methods',
  'flutter_acrylic',
  'dev.fluttercommunity.plus/share',
  'plugins.flutter.io/shared_preferences',
];

/// Answers, in-process, the platform channels the app calls during startup.
///
/// A `flutter test` process has no plugins registered, and an unanswered
/// channel does not fail - it never replies at all. `getDeviceName()` is
/// called while the settings table is being seeded, on the very first
/// database touch, so the whole boot stops there and the test dies on its
/// timeout with no error to point at.
///
/// (The reason this is not caught by the existing widget tests: none of them
/// build the real `App`, and the one probe that did happened to run with the
/// platform overridden to web, where `getDeviceName` takes the `kIsWeb` branch
/// and reaches for `webBrowserInfo` instead - which resolves in-process.)
///
/// Each handler returns the least interesting thing that is still shaped like
/// a real answer, so nothing downstream has to special-case running in a test.
void _installChannelStubs(WidgetTester tester, E2eDevice device) {
  final messenger = tester.binding.defaultBinaryMessenger;

  messenger.setMockMethodCallHandler(
    const MethodChannel('dev.fluttercommunity.plus/device_info'),
    (call) async => switch (device.platform) {
      AppPlatformKind.android => <String, dynamic>{
        'model': 'e2e-android',
        'brand': 'e2e',
        'device': 'e2e',
        'id': 'e2e',
        'version': <String, dynamic>{'sdkInt': 34, 'release': '14'},
      },
      AppPlatformKind.windows => <String, dynamic>{
        'computerName': 'e2e-windows',
        'numberOfCores': 4,
        'systemMemoryInMegabytes': 8192,
      },
      _ => <String, dynamic>{'name': 'e2e-device'},
    },
  );

  // A real, writable, throwaway directory rather than a made-up path. The app
  // appends a performance log to whatever it is handed, on every frame that
  // records a sample; a path that does not exist turns into one
  // `PathNotFoundException` per frame and buries everything else in the
  // output, and a path that DOES exist and is not throwaway would collect the
  // droppings of every test run.
  final scratch = Directory.systemTemp.createTempSync('my_budget_e2e');
  addTearDown(() {
    // The app appends to the performance log without awaiting, so on Windows
    // the file can still be held open when the test ends. Failing the teardown
    // over a temp directory would turn a passing flow into a red test and hide
    // whatever the flow was actually checking; the OS reclaims it either way.
    try {
      if (scratch.existsSync()) scratch.deleteSync(recursive: true);
    } on FileSystemException {
      // Left for the OS.
    }
  });
  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (call) async => scratch.path,
  );

  // Android-only, and only reached from the import screen, but a test that
  // walks into that screen on the phone surface would otherwise hang exactly
  // the way the device-info call did.
  messenger.setMockMethodCallHandler(
    const MethodChannel('com.mybudget.app/file_picker'),
    (call) async => null,
  );

  // The SMS reader is wired up as an `EventChannel`, and `SmsBloc` subscribes
  // to it the moment DI builds it - i.e. during boot, on every surface, before
  // any test has said the word "SMS". An `EventChannel` sends `listen` down an
  // ordinary method channel, so answering that channel is enough; returning
  // null means "the stream produced nothing", which is what a device with no
  // messages would say anyway.
  messenger.setMockMethodCallHandler(
    const MethodChannel('com.mybudget.app/sms_events'),
    (call) async => null,
  );

  // ...and the same bloc immediately asks permission_handler whether it may
  // read them. Unlike an unanswered channel, this one throws
  // `MissingPluginException` out of an async gap, which flutter_test counts as
  // a test failure no matter which test it happened in. Answer "denied" (0):
  // the app then takes its no-permission path, which is the honest state for a
  // process that is not a phone.
  messenger.setMockMethodCallHandler(
    const MethodChannel('flutter.baseflow.com/permissions/methods'),
    (call) async => switch (call.method) {
      'checkPermissionStatus' || 'checkServiceStatus' => 0,
      'requestPermissions' => <int, int>{},
      _ => null,
    },
  );

  // The SMS presets live in shared_preferences, and the same boot-time
  // `_onLoadPresets` reads them. An empty store is a first run, which every
  // caller already handles.
  final prefs = <String, Object?>{};
  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/shared_preferences'),
    (call) async {
      switch (call.method) {
        case 'getAll':
          return prefs;
        case 'clear':
          prefs.clear();
          return true;
        case 'remove':
          prefs.remove(call.arguments['key'] as String);
          return true;
        default:
          if (call.method.startsWith('set')) {
            prefs[call.arguments['key'] as String] = call.arguments['value'];
            return true;
          }
          return null;
      }
    },
  );

  // Desktop-only window chrome. Not touched during boot, but the theme screen
  // reaches for it, and a hang there would look like a layout bug.
  messenger.setMockMethodCallHandler(
    const MethodChannel('flutter_acrylic'),
    (call) async => null,
  );

  messenger.setMockMethodCallHandler(
    const MethodChannel('dev.fluttercommunity.plus/share'),
    (call) async => null,
  );
}

/// Lets the app's real asynchronous work actually happen.
///
/// `pumpAndSettle` is not usable here. It advances only the fake clock, so a
/// drift query - which needs the real event loop - never completes and the
/// pump spins until it times out. Alternating a real delay with a fake-clock
/// pump lets the I/O finish and then lets the frames it triggered be built.
Future<void> settleE2e(WidgetTester tester, {int rounds = 8}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 200));
  }
}

/// Boots the app on [device] and returns once the first screen has settled.
///
/// The database is in-memory and per-boot, so tests neither see each other's
/// rows nor need to clean up.
Future<E2eApp> bootE2eApp(
  WidgetTester tester, {
  required E2eDevice device,
  Locale locale = const Locale('en'),
}) async {
  debugUsePlatformTextTheme = true;
  debugAppPlatformOverride = device.platform;
  tester.view.physicalSize = device.size;
  tester.view.devicePixelRatio = 1.0;
  _installChannelStubs(tester, device);

  // `App` formats dates during its first build, and `intl` throws on a locale
  // whose symbols were never loaded.
  await initializeAppDateFormatting();

  // A previous boot in the same file leaves its registrations behind, and the
  // database is registered here rather than by `di.init` so each test gets its
  // own.
  GetIt.I.allowReassignment = true;
  await di.init();
  final database = AppDatabase.forTesting(NativeDatabase.memory());
  GetIt.I.registerSingleton<AppDatabase>(database);

  // The first real touch of the database: creates the schema and seeds the
  // static rows (currencies, account types, categories). Doing it up front
  // means the first frame is not racing the migration.
  await GetIt.I<SettingsRepository>().initializeDefaults();

  await tester.pumpWidget(const App());
  await settleE2e(tester);

  return E2eApp._(
    tester: tester,
    database: database,
    l10n: await AppLocalizations.delegate.load(locale),
    device: device,
  );
}

/// Runs [body] once per device, as its own test.
///
/// The point of the whole file: a flow is written once and every surface has
/// to complete it. A flow that only works on one of them fails by name -
/// "... [Android phone]" - rather than never being run there at all.
void e2eTestOnEachDevice(
  String description,
  Future<void> Function(E2eApp app) body, {
  List<E2eDevice> devices = E2eDevice.primary,
  Locale locale = const Locale('en'),
  Timeout timeout = const Timeout(Duration(seconds: 120)),
}) {
  for (final device in devices) {
    testWidgets('$description [${device.name}]', (tester) async {
      final app = await bootE2eApp(tester, device: device, locale: locale);
      try {
        await body(app);
      } finally {
        await app.dispose();
      }
    }, timeout: timeout);
  }
}
