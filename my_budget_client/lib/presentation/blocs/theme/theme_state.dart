part of 'theme_bloc.dart';

class ThemeState extends Equatable {
  final CustomTheme? activeTheme;
  final List<CustomTheme> presets;
  final bool isLoaded;

  /// Why the last attempt to read the saved theme failed, or null when it
  /// worked.
  ///
  /// The load used to have nowhere to report a failure, so a database that
  /// could not answer left `isLoaded` false forever and the whole app sat on a
  /// spinner. [activeTheme] is still filled in when this is set - with a
  /// built-in preset - because the app has to stay usable while the user's own
  /// theme is unreadable.
  final String? loadError;

  const ThemeState({
    this.activeTheme,
    this.presets = const [],
    this.isLoaded = false,
    this.loadError,
  });

  ThemeState copyWith({
    CustomTheme? activeTheme,
    List<CustomTheme>? presets,
    bool? isLoaded,
    String? loadError,
    bool clearLoadError = false,
  }) {
    return ThemeState(
      // Deliberately no `clearActiveTheme`: both the app shell and the theme
      // settings screen render a permanent spinner while this is null, so a
      // state with no active theme is a dead app. Every handler resolves a
      // replacement instead of clearing it.
      activeTheme: activeTheme ?? this.activeTheme,
      presets: presets ?? this.presets,
      isLoaded: isLoaded ?? this.isLoaded,
      loadError: clearLoadError ? null : (loadError ?? this.loadError),
    );
  }

  @override
  List<Object?> get props => [activeTheme, presets, isLoaded, loadError];
}
