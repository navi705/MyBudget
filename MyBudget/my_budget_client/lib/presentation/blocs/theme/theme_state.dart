part of 'theme_bloc.dart';

class ThemeState extends Equatable {
  final CustomTheme? activeTheme;
  final List<CustomTheme> presets;
  final bool isLoaded;

  const ThemeState({
    this.activeTheme,
    this.presets = const [],
    this.isLoaded = false,
  });

  ThemeState copyWith({
    CustomTheme? activeTheme,
    List<CustomTheme>? presets,
    bool? isLoaded,
  }) {
    return ThemeState(
      activeTheme: activeTheme ?? this.activeTheme,
      presets: presets ?? this.presets,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  @override
  List<Object?> get props => [activeTheme, presets, isLoaded];
}
