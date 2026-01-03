part of 'theme_bloc.dart';

class ThemeState extends Equatable {
  final Color themeColor;
  final ThemeMode themeMode;
  final WindowEffectType windowEffect;
  final double windowOpacity;
  final String? backgroundImagePath;
  final Color secondaryColor;
  final Color surfaceColor;
  final List<String> userPresets;
  final bool isLoaded;

  const ThemeState({
    this.themeColor = const Color(0xFF2196F3),
    this.secondaryColor = const Color(0xFF9C27B0),
    this.surfaceColor = const Color(0xFF121212),
    this.themeMode = ThemeMode.system,
    this.windowEffect = WindowEffectType.none,
    this.windowOpacity = 0.8,
    this.backgroundImagePath,
    this.userPresets = const [],
    this.isLoaded = false,
  });

  ThemeState copyWith({
    Color? themeColor,
    Color? secondaryColor,
    Color? surfaceColor,
    ThemeMode? themeMode,
    WindowEffectType? windowEffect,
    double? windowOpacity,
    String? backgroundImagePath,
    List<String>? userPresets,
    bool clearBackgroundImage = false,
    bool? isLoaded,
  }) {
    return ThemeState(
      themeColor: themeColor ?? this.themeColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      themeMode: themeMode ?? this.themeMode,
      windowEffect: windowEffect ?? this.windowEffect,
      windowOpacity: windowOpacity ?? this.windowOpacity,
      backgroundImagePath: clearBackgroundImage
          ? null
          : (backgroundImagePath ?? this.backgroundImagePath),
      userPresets: userPresets ?? this.userPresets,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  @override
  List<Object?> get props => [
    themeColor,
    secondaryColor,
    surfaceColor,
    themeMode,
    windowEffect,
    windowOpacity,
    backgroundImagePath,
    userPresets,
    isLoaded,
  ];
}
