part of 'theme_bloc.dart';

class ThemeState extends Equatable {
  final Color themeColor;
  final ThemeMode themeMode;
  final WindowEffectType windowEffect;
  final double windowOpacity;
  final bool isLoaded;

  const ThemeState({
    this.themeColor = const Color(0xFF2196F3),
    this.themeMode = ThemeMode.system,
    this.windowEffect = WindowEffectType.none,
    this.windowOpacity = 0.8,
    this.isLoaded = false,
  });

  ThemeState copyWith({
    Color? themeColor,
    ThemeMode? themeMode,
    WindowEffectType? windowEffect,
    double? windowOpacity,
    bool? isLoaded,
  }) {
    return ThemeState(
      themeColor: themeColor ?? this.themeColor,
      themeMode: themeMode ?? this.themeMode,
      windowEffect: windowEffect ?? this.windowEffect,
      windowOpacity: windowOpacity ?? this.windowOpacity,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  @override
  List<Object?> get props => [
    themeColor,
    themeMode,
    windowEffect,
    windowOpacity,
    isLoaded,
  ];
}
