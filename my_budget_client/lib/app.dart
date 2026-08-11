import 'package:my_budget_client/core/utils/platform/platform_utils.dart';
import 'package:my_budget_client/core/utils/platform/icon_helper.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_budget_client/core/theme/app_theme.dart';
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

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return AppProviders(
      child: BlocBuilder<ThemeBloc, ThemeState>(
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

              final lightThemeData = AppTheme.lightTheme(
                theme,
              ).copyWith(textTheme: GoogleFonts.interTextTheme());

              final darkThemeData = AppTheme.darkTheme(theme).copyWith(
                textTheme: GoogleFonts.interTextTheme(
                  ThemeData.dark().textTheme,
                ),
              );

              ImageProvider? backgroundImage;
              if (theme.backgroundImagePath != null &&
                  theme.backgroundImagePath!.isNotEmpty) {
                if (theme.backgroundImagePath!.startsWith('assets/')) {
                  backgroundImage = AssetImage(theme.backgroundImagePath!);
                } else {
                  backgroundImage = IconPlatformHelper.getImageFromFile(
                    theme.backgroundImagePath!,
                  );
                }
              }

              return MaterialApp.router(
                key: ValueKey(
                  'app_locale_${settingsState.locale?.languageCode ?? 'system'}',
                ),
                title: 'MyBudget',
                scrollBehavior: const _AppScrollBehavior(),
                theme: lightThemeData,
                darkTheme: darkThemeData,
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

                  return Container(
                    color: theme.backgroundColor.withValues(
                      alpha: theme.effectOpacity,
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
                        if (child != null) child,
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
