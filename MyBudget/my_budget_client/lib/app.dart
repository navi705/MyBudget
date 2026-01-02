import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_budget_client/core/theme/app_theme.dart';
import 'package:my_budget_client/presentation/app_providers.dart';
import 'package:my_budget_client/presentation/blocs/theme/theme_bloc.dart';
import 'package:my_budget_client/presentation/routes/app_router.dart';

import 'l10n/app_localizations.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return AppProviders(
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          final hasWindowEffect =
              Platform.isWindows && state.windowEffect != WindowEffectType.none;

          // Apply transparent theme if either window effect or background image is present
          final useTransparentTheme =
              hasWindowEffect || state.backgroundImagePath != null;

          final lightTheme = AppTheme.lightTheme(
            state.themeColor,
            hasWindowEffect: useTransparentTheme,
            windowOpacity: state.windowOpacity,
          ).copyWith(textTheme: GoogleFonts.interTextTheme());

          final darkTheme =
              AppTheme.darkTheme(
                state.themeColor,
                hasWindowEffect: useTransparentTheme,
                windowOpacity: state.windowOpacity,
              ).copyWith(
                textTheme: GoogleFonts.interTextTheme(
                  ThemeData.dark().textTheme,
                ),
              );

          return Container(
            decoration: state.backgroundImagePath != null
                ? BoxDecoration(
                    image: DecorationImage(
                      image: FileImage(File(state.backgroundImagePath!)),
                      fit: BoxFit.cover,
                    ),
                  )
                : null,
            child: MaterialApp.router(
              title: 'MyBudget',
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: state.themeMode,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: router,
              debugShowCheckedModeBanner: false,
            ),
          );
        },
      ),
    );
  }
}
