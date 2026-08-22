import 'package:my_budget_client/core/utils/platform/platform_utils.dart';
import 'package:my_budget_client/core/utils/platform/icon_helper.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
import 'package:my_budget_client/core/theme/app_theme.dart';
import 'package:my_budget_client/domain/entities/custom_theme.dart';
import 'package:my_budget_client/presentation/app_providers.dart';
import 'package:my_budget_client/presentation/blocs/theme/theme_bloc.dart';
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';
import 'package:my_budget_client/presentation/routes/app_router.dart';

import 'l10n/app_localizations.dart';

/// Scroll behaviour applied to the whole app.
///
/// Flutter's default `dragDevices` deliberately leaves out
/// [PointerDeviceKind.mouse] so that desktop users scroll with the wheel only.
/// This app is also driven by touch-first layouts that expose no scrollbars on
/// short lists, so without the mouse here a desktop or web user has content
/// they can see but cannot reach by dragging. Re-adding it costs nothing on
/// mobile, where no mouse pointer exists.
class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}

/// The Inter text themes, built once for the life of the process.
///
/// `GoogleFonts.interTextTheme()` copies and restyles fourteen text styles on
/// every call, and the shell below rebuilds on every `ThemeState` emission -
/// which is one per frame for the whole time a user drags the opacity or blur
/// slider. Neither call reads the theme or the context, so hoisting them out
/// produces the same text theme the per-build calls did. Top-level finals in
/// Dart are lazy, so nothing runs until the first frame that needs them.
final TextTheme _interLightTextTheme = GoogleFonts.interTextTheme();
final TextTheme _interDarkTextTheme = GoogleFonts.interTextTheme(
  ThemeData.dark().textTheme,
);

/// Builds the app on the platform's own text theme instead of Inter.
///
/// Inter is fetched at runtime rather than bundled, and a `flutter test`
/// process has neither the asset nor a network to fetch it from. google_fonts
/// reports that failure by rethrowing out of a future nothing awaits: a real
/// app logs it and carries on with the fallback font, but a test zone counts
/// an unhandled async error as a failed test. So every test that builds the
/// whole [App] - rather than one screen under its own `MaterialApp` - would
/// fail on the font before it could look at anything else.
///
/// Same shape and same purpose as `debugAppPlatformOverride`: it exists so a
/// test can say "not this one part", and it is never set in a shipped build.
@visibleForTesting
bool debugUsePlatformTextTheme = false;

TextTheme get _lightTextTheme => debugUsePlatformTextTheme
    ? ThemeData.light().textTheme
    : _interLightTextTheme;

TextTheme get _darkTextTheme => debugUsePlatformTextTheme
    ? ThemeData.dark().textTheme
    : _interDarkTextTheme;

/// Exactly the theme fields that [AppTheme.lightTheme] and
/// [AppTheme.darkTheme] read.
///
/// Deliberately narrower than the whole [CustomTheme]: `effectOpacity` and the
/// background-image opacity/blur never reach `ThemeData`, yet those are the
/// three the sliders change sixty times a second. Keying the cache on the whole
/// theme would regenerate two HCT palettes per frame of a drag for output that
/// cannot differ.
typedef _ThemeDataInputs = (
  Color primary,
  Color secondary,
  Color surface,
  Color background,
  double surfaceOpacity,
  WindowEffectType effect,
  bool hasBackgroundImage,
);

_ThemeDataInputs _themeDataInputsOf(CustomTheme theme) => (
  theme.primaryColor,
  theme.secondaryColor,
  theme.surfaceColor,
  theme.backgroundColor,
  theme.surfaceOpacity,
  theme.windowEffectType,
  theme.backgroundImagePath != null && theme.backgroundImagePath!.isNotEmpty,
);

/// How opaque the app's own background layer should be painted for [theme].
///
/// `effectOpacity` does not mean the same thing for a transparent window as it
/// does for a blur, and this is the consumer that never learnt the difference.
/// Windows' window alpha is parabolic - 0.0 and 1.0 both come out opaque, the
/// middle is the most see-through - so the theme screen stores the *reversed*
/// value whenever the effect is [WindowEffectType.transparent]: its "Opaque"
/// chip saves 0.0 and its "fully transparent" chip saves 0.5. Handing that
/// straight to a colour's alpha, which is what used to happen here, painted the
/// background completely see-through for the user who had just asked for it to
/// be opaque, and left it half-there for the one who asked to see through it.
///
/// Public so the mapping can be tested; there is no way to reach the shell's
/// `MaterialApp.builder` from a test without standing up the whole DI graph.
double backgroundLayerAlpha(CustomTheme theme) {
  if (theme.windowEffectType != WindowEffectType.transparent) {
    return theme.effectOpacity.clamp(0.0, 1.0);
  }

  // Both arms of the parabola describe the same amount of transparency, and a
  // value above the peak is what a theme carries when the user switched over
  // from a blur (whose slider runs the full 0..1) or synced one in.
  final stored = theme.effectOpacity > 0.5
      ? 1.0 - theme.effectOpacity
      : theme.effectOpacity.clamp(0.0, 0.5);

  // The stored value against the transparency its chip is labelled with, as
  // alpha. Interpolating between them keeps "50%" looking like half, instead of
  // whatever a straight line through the two ends happens to give.
  const stops = <(double stored, double alpha)>[
    (0.0, 1.0), // "Opaque"
    (0.1, 0.75), // "25%"
    (0.2, 0.5), // "50%"
    (0.35, 0.25), // "75%"
    (0.5, 0.0), // "Fully transparent"
  ];
  for (var i = 1; i < stops.length; i++) {
    final (previousStored, previousAlpha) = stops[i - 1];
    final (nextStored, nextAlpha) = stops[i];
    if (stored <= nextStored) {
      final t = (stored - previousStored) / (nextStored - previousStored);
      return (previousAlpha + (nextAlpha - previousAlpha) * t).clamp(0.0, 1.0);
    }
  }
  return 0.0;
}

/// Loads intl's date symbols for the locales this app ships.
///
/// `DateFormat` carries no data of its own: for anything but `en_US` it looks
/// the locale up in a table that stays empty until this runs, and throws
/// `LocaleDataException` when the entry is not there. Nothing in this app ever
/// called it. It got away with that only because
/// `GlobalMaterialLocalizations.load` fills the same table as a side effect -
/// which happens somewhere in the first frames, well after `main()`, and never
/// at all for a date formatted outside the widget tree (start-up sync, an
/// import, the database's own date keys). Awaiting it here makes the data a
/// precondition of the app rather than a coincidence of the first localization
/// load.
///
/// intl ignores the locale argument - `initializeDateFormatting` installs the
/// whole CLDR table in a single pass - so calling it once per supported locale
/// would just rebuild that (large) table ten times at start-up. The debug-only
/// check below is what actually ties the locales the app ships to the data
/// being present, so adding a locale intl has never heard of fails here rather
/// than at the first date the user looks at.
Future<void> initializeAppDateFormatting() async {
  await initializeDateFormatting();
  assert(() {
    final probe = DateTime(2000, 1, 2);
    for (final locale in AppLocalizations.supportedLocales) {
      DateFormat.yMMMMd(locale.toString()).format(probe);
    }
    return true;
  }());
}

/// Points `Intl.defaultLocale` at the locale the app is actually rendering in.
///
/// A `DateFormat` built without an explicit locale formats in
/// `Intl.defaultLocale`, and falls back to the system locale when that is
/// unset - which is why every date in this app came out in English however the
/// user had set the language. The locale here is a *setting*: it changes while
/// the app runs, so a one-shot assignment in `main()` would be stale the first
/// time someone switched language. This sits below [Localizations] instead, so
/// it sees the same locale the widgets do - including the one
/// `localeResolutionCallback` picked for a user who never chose explicitly -
/// and re-runs whenever that changes.
///
/// A caution for the next `DateFormat` added to this codebase: this makes
/// every *unqualified* `DateFormat` locale-sensitive, machine-facing ones
/// included. `bn` is the shipped locale whose CLDR data carries native digits,
/// so under Bengali `DateFormat('yyyy-MM-dd').format(...)` renders
/// `২০২৬-০৮-১২`. Anything whose output becomes a database key, a URL, a file
/// name or a cache key must name its locale explicitly.
class IntlLocaleSync extends StatelessWidget {
  const IntlLocaleSync({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Assigned during build, not from a listener: the descendants that do the
    // formatting are built after this returns, so they must see the new value
    // in the very frame the locale changes.
    Intl.defaultLocale = Localizations.localeOf(context).toString();
    return child;
  }
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppProviders(child: _AppShell());
  }
}

/// The app itself, plus the [ThemeData] it is painted with.
///
/// Stateful only to hold that derivation: see [_ThemeDataInputs].
class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  _ThemeDataInputs? _themeDataInputs;
  ThemeData? _lightThemeData;
  ThemeData? _darkThemeData;

  String? _backgroundImagePath;
  ImageProvider? _backgroundImage;

  void _deriveTheme(CustomTheme theme) {
    final inputs = _themeDataInputsOf(theme);
    if (inputs != _themeDataInputs || _lightThemeData == null) {
      _themeDataInputs = inputs;
      _lightThemeData = AppTheme.lightTheme(
        theme,
      ).copyWith(textTheme: _lightTextTheme);
      _darkThemeData = AppTheme.darkTheme(
        theme,
      ).copyWith(textTheme: _darkTextTheme);
    }

    final path = theme.backgroundImagePath;
    if (path != _backgroundImagePath) {
      _backgroundImagePath = path;
      if (path == null || path.isEmpty) {
        _backgroundImage = null;
      } else if (path.startsWith('assets/')) {
        _backgroundImage = AssetImage(path);
      } else {
        _backgroundImage = IconPlatformHelper.getImageFromFile(path);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, settingsState) {
            if (!themeState.isLoaded || themeState.activeTheme == null) {
              return const MaterialApp(
                home: Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final theme = themeState.activeTheme!;
            _deriveTheme(theme);

            final backgroundImage = _backgroundImage;

            return MaterialApp.router(
              key: ValueKey(
                'app_locale_${settingsState.locale?.languageCode ?? 'system'}',
              ),
              title: 'MyBudget',
              scrollBehavior: const _AppScrollBehavior(),
              theme: _lightThemeData,
              darkTheme: _darkThemeData,
              themeMode: theme.themeMode,
              locale: settingsState.locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              localeResolutionCallback: (locale, supportedLocales) {
                if (settingsState.locale != null) return settingsState.locale;
                if (locale != null) {
                  for (var supportedLocale in supportedLocales) {
                    if (supportedLocale.languageCode == locale.languageCode) {
                      return supportedLocale;
                    }
                  }
                }
                // Never fall back to `supportedLocales.first`: that list is
                // alphabetical, so its head is `ar` and every user with an
                // unsupported system locale would be dropped into a
                // right-to-left Arabic UI. English is the authored source
                // language and the only safe default.
                return const Locale('en');
              },
              routerConfig: router,
              debugShowCheckedModeBanner: false,
              builder: (context, child) {
                // Optimization: use a fixed large height to prevent RepaintBoundary invalidation
                // during keyboard animations. Adding viewInsets would cause a repaint every frame.
                const staticBackgroundHeight = 2000.0;

                // The app is painted with a built-in preset when the saved
                // theme could not be read, which is a difference the user has
                // no other way of noticing - and the load is dispatched once at
                // startup, so this bar carries the only retry there is.
                Widget? content = child;
                if (content != null && themeState.loadError != null) {
                  content = Positioned.fill(
                    child: Column(
                      children: [
                        const _ThemeLoadFailureBar(),
                        Expanded(child: content),
                      ],
                    ),
                  );
                }

                return IntlLocaleSync(
                  child: Container(
                    color: theme.backgroundColor.withValues(
                      alpha: backgroundLayerAlpha(theme),
                    ),
                    child: Stack(
                      children: [
                        // Optimized Background Layer
                        Positioned.fill(
                          child: RepaintBoundary(
                            child: OverflowBox(
                              minHeight: staticBackgroundHeight,
                              maxHeight: staticBackgroundHeight,
                              alignment: Alignment.topCenter,
                              child: Stack(
                                children: [
                                  if (backgroundImage != null)
                                    Positioned.fill(
                                      child: Opacity(
                                        opacity: theme.backgroundImageOpacity,
                                        child: theme.backgroundImageBlur > 0
                                            ? ImageFiltered(
                                                imageFilter: ImageFilter.blur(
                                                  sigmaX:
                                                      theme.backgroundImageBlur,
                                                  sigmaY:
                                                      theme.backgroundImageBlur,
                                                ),
                                                child: Image(
                                                  image: backgroundImage,
                                                  fit: BoxFit.cover,
                                                  gaplessPlayback: true,
                                                ),
                                              )
                                            : Image(
                                                image: backgroundImage,
                                                fit: BoxFit.cover,
                                                gaplessPlayback: true,
                                              ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (content != null) content,
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

/// Says the saved theme could not be read, and offers the retry the app never
/// had.
///
/// The theme load runs exactly once, at startup. When it threw, `isLoaded`
/// never turned true and all the user ever saw was a spinner where the app
/// should have been: no message, no button, and no amount of waiting or
/// restarting would move it. The app now paints itself with a built-in preset
/// instead, so the only thing actually missing is the user's own theme.
class _ThemeLoadFailureBar extends StatelessWidget {
  const _ThemeLoadFailureBar();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.errorContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 4, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.failedToLoadData,
                  style: TextStyle(color: colors.onErrorContainer),
                ),
              ),
              TextButton(
                onPressed: () =>
                    context.read<ThemeBloc>().add(const LoadThemeSettings()),
                child: Text(context.l10n.retryButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
