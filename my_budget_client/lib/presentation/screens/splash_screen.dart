import 'package:flutter/material.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';

/// A splash screen that shows initialization progress.
///
/// This is the root widget until the app itself has been built, so it carries
/// its own [MaterialApp]. That app is deliberately not pinned to a dark theme:
/// a light-theme user was getting a dark flash on every cold start, and the
/// splash is the first thing they see. It follows the platform brightness
/// instead, which is the closest a screen that runs before the stored theme has
/// been read can get to the theme the user chose.
class SplashScreen extends StatelessWidget {
  final String message;
  final double? progress;

  const SplashScreen({super.key, this.message = 'Loading...', this.progress});

  /// The brand blue the progress bar has always used, kept as the seed so the
  /// generated light and dark schemes stay recognisably this app.
  static const Color _seed = Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // The delegates are here for the text direction as much as the strings:
      // without them an Arabic device gets a left-to-right splash before the
      // real app flips it.
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _seed),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      // MaterialApp resolves this against `MediaQuery.platformBrightnessOf`.
      themeMode: ThemeMode.system,
      home: _SplashBody(message: message, progress: progress),
    );
  }
}

class _SplashBody extends StatelessWidget {
  const _SplashBody({required this.message, required this.progress});

  final String message;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);

    // The logo used to be a fixed 200x200, which with the name and the
    // progress block underneath needs ~340dp on a phone that is 360dp tall in
    // landscape - and none of it scrolled. Sizing off the available height
    // keeps the whole block on screen there while leaving the logo at its
    // full 200 anywhere with room for it, and the scroll view catches whatever
    // is left over (a large text scale, a very short window).
    final double logoSize = (size.height * 0.30).clamp(72.0, 200.0);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // App Logo/Icon
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 24),

                // App Name. The product name is a proper noun and is not
                // translated in any locale.
                Text(
                  'MyBudget',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 32),

                // Progress Indicator
                SizedBox(
                  width: 200,
                  child: Column(
                    children: [
                      LinearProgressIndicator(
                        // Null is the indeterminate case the widget already
                        // handles; two near-identical branches only gave the
                        // two states room to drift apart.
                        value: progress,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
