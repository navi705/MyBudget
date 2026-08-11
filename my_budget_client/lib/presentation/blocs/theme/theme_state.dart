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

  /// Why the last theme the user asked to select, save, edit or delete did not
  /// take, or null when nothing has failed since.
  ///
  /// Separate from [loadError]: that one describes the theme the app is
  /// painting with, this one describes an action the user just took. Every
  /// write handler used to let a repository failure escape as an unhandled
  /// bloc error, so tapping a preset that could not be stored looked exactly
  /// like tapping one that could - the tile just did not move.
  final String? actionError;

  const ThemeState({
    this.activeTheme,
    this.presets = const [],
    this.isLoaded = false,
    this.loadError,
    this.actionError,
  });

  ThemeState copyWith({
    CustomTheme? activeTheme,
    List<CustomTheme>? presets,
    bool? isLoaded,
    String? loadError,
    bool clearLoadError = false,
    String? actionError,
    bool clearActionError = false,
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
      actionError: clearActionError ? null : (actionError ?? this.actionError),
    );
  }

  @override
  List<Object?> get props => [
    activeTheme,
    presets,
    isLoaded,
    loadError,
    actionError,
  ];
}
