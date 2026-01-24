import 'dart:io';
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
                  backgroundImage = FileImage(File(theme.backgroundImagePath!));
                }
              }

              return MaterialApp.router(
                key: ValueKey(
                  'app_locale_${settingsState.locale?.languageCode ?? 'system'}',
                ),
                title: 'MyBudget',
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
                  return supportedLocales.first;
                },
                routerConfig: router,
                debugShowCheckedModeBanner: false,
                builder: (context, child) {
                  // Calculate the full screen height (screen + keyboard) to keep background static
                  final mediaQuery = MediaQuery.of(context);
                  final fullHeight =
                      mediaQuery.size.height + mediaQuery.viewInsets.bottom;

                  return Container(
                    color: theme.backgroundColor.withValues(
                      alpha: theme.effectOpacity,
                    ),
                    child: Stack(
                      children: [
                        // Optimized Background Layer
                        // We use OverflowBox to force the background to stay at full device height
                        // even when the keyboard pushes the view up. This allows RepaintBoundary
                        // to actually cache the raster, as the child size doesn't change.
                        Positioned.fill(
                          child: RepaintBoundary(
                            child: OverflowBox(
                              minHeight: fullHeight,
                              maxHeight: fullHeight,
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
