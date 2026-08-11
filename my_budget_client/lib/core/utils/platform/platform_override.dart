/// Host platform identity, expressed without `dart:io` so that both the io and
/// the web variant of `AppPlatform` can share it.
enum AppPlatformKind { android, iOS, linux, macOS, windows, fuchsia, web }

/// Test-only override for every `AppPlatform.isX` flag.
///
/// `AppPlatform` is resolved through a conditional import: the io variant reads
/// `dart:io`'s `Platform.isAndroid` and friends, the web variant answers `false`
/// to all of them. Neither can be moved from a test, so a widget that gates a
/// feature on `AppPlatform.isAndroid` was only ever exercisable on whichever OS
/// happened to run the suite — the other side of the gate was untestable.
///
/// Setting this to a non-null value makes every flag answer from it instead:
/// exactly one flag is true and the rest are false. Set it back to `null` in a
/// `tearDown` so the value never leaks into the next test.
///
/// ```dart
/// setUp(() => debugAppPlatformOverride = AppPlatformKind.android);
/// tearDown(() => debugAppPlatformOverride = null);
/// ```
///
/// Production code must never assign this: it is `null` in a released build,
/// which leaves the real platform lookup in place.
AppPlatformKind? debugAppPlatformOverride;
