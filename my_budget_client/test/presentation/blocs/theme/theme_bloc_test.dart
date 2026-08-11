// ThemeBloc used to have no answer for a theme it could not read. The load
// handler had no try/catch, ThemeState had no error field, and the app shell
// renders nothing but a spinner until `isLoaded` turns true - so a single throw
// out of the repository (two rows carrying is_active is enough, because
// getActiveTheme is a getSingleOrNull) left the user with a permanently dead
// app, dispatched once at startup with no way to ask again.
//
// It also had exactly one slot for customisations: every preset the user tuned
// was written to the id 'custom-theme' with an insert-or-replace, so the second
// preset they touched overwrote the first one's saved look in place.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/theme/app_theme.dart';
import 'package:my_budget_client/core/theme/default_themes.dart';
import 'package:my_budget_client/domain/entities/custom_theme.dart';
import 'package:my_budget_client/domain/entities/settings.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/domain/repositories/theme_repository.dart';
import 'package:my_budget_client/presentation/blocs/theme/theme_bloc.dart';

/// An in-memory theme store, keyed by id like the real table is.
///
/// Anything the bloc is not supposed to call stays unimplemented on purpose: an
/// unexpected call should fail the test loudly rather than return a default.
class _FakeThemeRepository extends Fake implements ThemeRepository {
  _FakeThemeRepository([List<CustomTheme> seed = const []]) {
    for (final theme in seed) {
      themes[theme.id] = theme;
    }
  }

  final Map<String, CustomTheme> themes = {};

  /// Set to make the next [getAllThemes] throw, the way a duplicated
  /// `is_active` row makes the real one throw.
  Object? failure;

  int getAllThemesCalls = 0;

  @override
  Future<List<CustomTheme>> getAllThemes() async {
    getAllThemesCalls++;
    final failure = this.failure;
    if (failure != null) throw failure;
    return themes.values.toList();
  }

  @override
  Future<CustomTheme?> getActiveTheme() async {
    for (final theme in themes.values) {
      if (theme.isActive) return theme;
    }
    return null;
  }

  @override
  Future<void> saveTheme(CustomTheme theme) async {
    // The real repository is an insertOrReplace on the primary key, which is
    // the whole reason a shared id destroys another preset's customisation.
    themes[theme.id] = theme;
  }

  @override
  Future<void> setActiveTheme(String id) async {
    if (!themes.containsKey(id)) return;
    for (final entry in themes.entries) {
      themes[entry.key] = entry.value.copyWith(isActive: entry.key == id);
    }
  }

  @override
  Future<void> deleteTheme(String id) async {
    themes.remove(id);
  }
}

/// Answers "nothing stored" for every lookup the migration path makes.
class _FakeSettingsRepository extends Fake implements SettingsRepository {
  final modes = <ThemeMode>[];

  @override
  Future<Settings?> getSetting(String key) async => null;

  @override
  Future<Map<String, String>> getAllSettings() async => const {};

  @override
  Future<void> saveSetting(String key, String value) async {}

  @override
  Future<void> setThemeMode(ThemeMode themeMode, String device) async {
    modes.add(themeMode);
  }
}

/// A repository whose active-theme row is missing entirely, so the delete path
/// has to decide what the app is painted with next.
class _NoActiveThemeRepository extends _FakeThemeRepository {
  _NoActiveThemeRepository(super.seed);

  @override
  Future<CustomTheme?> getActiveTheme() async => null;
}

/// Reads fine, refuses every write - a read-only database file, a disk that
/// filled up, a row another device is holding.
class _UnwritableThemeRepository extends _FakeThemeRepository {
  _UnwritableThemeRepository(super.seed);

  final writeFailure = Exception('database is locked');

  @override
  Future<void> saveTheme(CustomTheme theme) async => throw writeFailure;

  @override
  Future<void> setActiveTheme(String id) async => throw writeFailure;

  @override
  Future<void> deleteTheme(String id) async => throw writeFailure;
}

CustomTheme _theme(
  String id, {
  String name = 'Theme',
  bool isPreset = false,
  bool isActive = false,
  Color primary = const Color(0xFF2196F3),
}) => CustomTheme(
  id: id,
  name: name,
  primaryColor: primary,
  secondaryColor: const Color(0xFF9C27B0),
  surfaceColor: const Color(0xFF252525),
  backgroundColor: const Color(0xFF121212),
  windowEffectType: WindowEffectType.none,
  themeMode: ThemeMode.dark,
  isPreset: isPreset,
  isActive: isActive,
);

void main() {
  late _FakeThemeRepository themeRepository;
  late _FakeSettingsRepository settingsRepository;

  ThemeBloc build() => ThemeBloc(
    settingsRepository: settingsRepository,
    themeRepository: themeRepository,
  );

  setUp(() {
    settingsRepository = _FakeSettingsRepository();
    themeRepository = _FakeThemeRepository();
  });

  group('load failure', () {
    final failure = Exception('Too many elements');

    blocTest<ThemeBloc, ThemeState>(
      'reports the failure and still hands the app a theme to paint with',
      build: () {
        themeRepository.failure = failure;
        return build();
      },
      act: (bloc) => bloc.add(const LoadThemeSettings()),
      // isLoaded true is what stops the shell's spinner; the error is what lets
      // it say so and offer a retry. Without both, the app is unreachable.
      expect: () => [
        isA<ThemeState>()
            .having((s) => s.isLoaded, 'isLoaded', isTrue)
            .having((s) => s.loadError, 'loadError', contains('Too many'))
            .having((s) => s.activeTheme, 'activeTheme', isNotNull)
            .having((s) => s.presets, 'presets', isNotEmpty),
      ],
    );

    blocTest<ThemeBloc, ThemeState>(
      'the failure never leaves the app on a spinner',
      build: () {
        themeRepository.failure = failure;
        return build();
      },
      act: (bloc) => bloc.add(const LoadThemeSettings()),
      verify: (bloc) {
        // The two conditions the shell and the theme screen both gate on.
        expect(bloc.state.isLoaded, isTrue);
        expect(bloc.state.activeTheme, isNotNull);
        expect(bloc.state.presets, defaultThemePresets);
      },
    );

    blocTest<ThemeBloc, ThemeState>(
      'retrying after a failure loads the real theme and clears the error',
      build: () {
        themeRepository.failure = failure;
        return build();
      },
      act: (bloc) async {
        bloc.add(const LoadThemeSettings());
        await Future<void>.delayed(Duration.zero);
        // Whatever made the read fail has been dealt with - a duplicated
        // is_active row cleaned up, the file unlocked - and the user presses
        // the bar's Retry.
        themeRepository.failure = null;
        themeRepository.themes['saved'] = _theme(
          'saved',
          name: 'Saved',
          isActive: true,
        );
        bloc.add(const LoadThemeSettings());
      },
      skip: 1,
      expect: () => [
        isA<ThemeState>()
            .having((s) => s.loadError, 'loadError', isNull)
            .having((s) => s.isLoaded, 'isLoaded', isTrue)
            .having((s) => s.activeTheme?.id, 'activeTheme', 'saved'),
      ],
      verify: (_) => expect(themeRepository.getAllThemesCalls, 2),
    );
  });

  group('customising a preset', () {
    final presetA = _theme(
      'classic-blue',
      name: 'Classic Blue',
      isPreset: true,
      isActive: true,
    );
    final presetB = _theme('midnight', name: 'Midnight', isPreset: true);

    blocTest<ThemeBloc, ThemeState>(
      'customising a second preset leaves the first preset\'s custom theme '
      'untouched',
      build: () {
        themeRepository = _FakeThemeRepository([presetA, presetB]);
        return build();
      },
      seed: () => ThemeState(
        activeTheme: presetA,
        presets: [presetA, presetB],
        isLoaded: true,
      ),
      act: (bloc) async {
        bloc.add(const UpdateThemeProperty(primaryColor: Color(0xFFFF0000)));
        await Future<void>.delayed(Duration.zero);
        // The user goes back to the picker, taps the other preset, and nudges
        // one colour on it. This is the moment that used to wipe the look they
        // had built on the first one.
        bloc.add(const SelectThemePreset('midnight'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const UpdateThemeProperty(primaryColor: Color(0xFF00FF00)));
      },
      verify: (_) {
        final customA = themeRepository.themes['custom-classic-blue'];
        final customB = themeRepository.themes['custom-midnight'];
        expect(customA, isNotNull);
        expect(customB, isNotNull);
        expect(customA!.primaryColor, const Color(0xFFFF0000));
        expect(customB!.primaryColor, const Color(0xFF00FF00));
        // Distinguishable in the picker, which renders nothing but the name.
        expect(customA.name, isNot(customB.name));
        // The presets themselves are never edited in place.
        expect(themeRepository.themes['classic-blue'], isNotNull);
        expect(
          themeRepository.themes['classic-blue']!.primaryColor,
          presetA.primaryColor,
        );
      },
    );

    blocTest<ThemeBloc, ThemeState>(
      'a second change to the same preset keeps updating its own custom theme',
      build: () {
        themeRepository = _FakeThemeRepository([presetA]);
        return build();
      },
      seed: () =>
          ThemeState(activeTheme: presetA, presets: [presetA], isLoaded: true),
      act: (bloc) async {
        bloc.add(const UpdateThemeProperty(primaryColor: Color(0xFFFF0000)));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const UpdateThemeProperty(secondaryColor: Color(0xFF0000FF)));
      },
      verify: (_) {
        // One customisation per preset, not one per edit.
        expect(themeRepository.themes.keys, [
          'classic-blue',
          'custom-classic-blue',
        ]);
        final custom = themeRepository.themes['custom-classic-blue']!;
        expect(custom.primaryColor, const Color(0xFFFF0000));
        expect(custom.secondaryColor, const Color(0xFF0000FF));
        expect(custom.isPreset, isFalse);
      },
    );
  });

  group('deleting a theme', () {
    blocTest<ThemeBloc, ThemeState>(
      'deleting the active theme with no built-in preset left does not throw',
      build: () {
        themeRepository = _FakeThemeRepository([
          _theme('mine', name: 'Mine', isActive: true),
          _theme('other', name: 'Other'),
        ]);
        return build();
      },
      // A sync that soft-deletes the built-ins leaves a picker with no
      // `isPreset` row at all; the old `firstWhere` threw StateError here
      // before anything was deleted.
      seed: () => ThemeState(
        activeTheme: _theme('mine', name: 'Mine', isActive: true),
        presets: [_theme('mine', name: 'Mine'), _theme('other', name: 'Other')],
        isLoaded: true,
      ),
      act: (bloc) => bloc.add(const DeleteThemePreset('mine')),
      errors: () => isEmpty,
      verify: (bloc) {
        expect(themeRepository.themes.containsKey('mine'), isFalse);
        expect(bloc.state.activeTheme?.id, 'other');
      },
    );

    blocTest<ThemeBloc, ThemeState>(
      'a repository with no active theme left does not keep the deleted one '
      'on screen',
      build: () {
        themeRepository = _NoActiveThemeRepository([
          _theme('mine', name: 'Mine', isActive: true),
          _theme('classic-blue', name: 'Classic Blue', isPreset: true),
        ]);
        return build();
      },
      seed: () => ThemeState(
        activeTheme: _theme('mine', name: 'Mine', isActive: true),
        presets: [
          _theme('mine', name: 'Mine'),
          _theme('classic-blue', name: 'Classic Blue', isPreset: true),
        ],
        isLoaded: true,
      ),
      act: (bloc) => bloc.add(const DeleteThemePreset('mine')),
      errors: () => isEmpty,
      verify: (bloc) {
        // copyWith reads a null as "leave it alone", so this used to stay on
        // 'mine' - a theme that no longer exists anywhere.
        expect(bloc.state.activeTheme?.id, isNot('mine'));
        expect(bloc.state.activeTheme?.id, 'classic-blue');
      },
    );

    blocTest<ThemeBloc, ThemeState>(
      'deleting the last theme of all still leaves something to paint with',
      build: () {
        themeRepository = _NoActiveThemeRepository([
          _theme('mine', name: 'Mine', isActive: true),
        ]);
        return build();
      },
      seed: () => ThemeState(
        activeTheme: _theme('mine', name: 'Mine', isActive: true),
        presets: [_theme('mine', name: 'Mine')],
        isLoaded: true,
      ),
      act: (bloc) => bloc.add(const DeleteThemePreset('mine')),
      errors: () => isEmpty,
      // Emitting no active theme is not an option: the shell and the theme
      // screen both render a permanent spinner without one.
      verify: (bloc) => expect(bloc.state.activeTheme, isNotNull),
    );
  });

  // The load path was given a fallback and a loadError, but every write handler
  // was still bare: a repository that could not answer escaped the handler as an
  // unhandled bloc error and reached no widget at all. The tile did not move,
  // the slider snapped back, and nothing said why.
  group('write failures', () {
    final mine = _theme('mine', name: 'Mine', isActive: true);
    final other = _theme('other', name: 'Other');

    ThemeState seeded() => ThemeState(
      activeTheme: mine,
      presets: [mine, other],
      isLoaded: true,
    );

    Matcher reportsFailure() => isA<ThemeState>()
        .having(
          (s) => s.actionError,
          'actionError',
          contains('database is locked'),
        )
        // The app keeps painting what it was painting: a write that failed
        // changed nothing, and blanking the theme is a dead app.
        .having((s) => s.activeTheme, 'activeTheme', isNotNull);

    blocTest<ThemeBloc, ThemeState>(
      'a preset that cannot be made active says so',
      build: () => ThemeBloc(
        settingsRepository: settingsRepository,
        themeRepository: _UnwritableThemeRepository([mine, other]),
      ),
      seed: seeded,
      act: (bloc) => bloc.add(const SelectThemePreset('other')),
      errors: () => isEmpty,
      expect: () => [reportsFailure()],
    );

    blocTest<ThemeBloc, ThemeState>(
      'a preset deleted from under the picker is reported, not thrown',
      build: () {
        // Another device removed it between this list being drawn and the tile
        // being tapped. The old `firstWhere` had no orElse.
        themeRepository = _FakeThemeRepository([mine]);
        return build();
      },
      seed: seeded,
      act: (bloc) => bloc.add(const SelectThemePreset('other')),
      errors: () => isEmpty,
      expect: () => [
        isA<ThemeState>()
            .having((s) => s.actionError, 'actionError', contains('other'))
            .having((s) => s.activeTheme?.id, 'activeTheme', 'mine'),
      ],
    );

    blocTest<ThemeBloc, ThemeState>(
      'a customisation that cannot be stored does not pass for a saved one',
      build: () => ThemeBloc(
        settingsRepository: settingsRepository,
        themeRepository: _UnwritableThemeRepository([mine, other]),
      ),
      seed: seeded,
      act: (bloc) =>
          bloc.add(const UpdateThemeProperty(primaryColor: Color(0xFFFF0000))),
      errors: () => isEmpty,
      expect: () => [reportsFailure()],
    );

    blocTest<ThemeBloc, ThemeState>(
      'a named preset that was never written is not left in the list',
      build: () => ThemeBloc(
        settingsRepository: settingsRepository,
        themeRepository: _UnwritableThemeRepository([mine, other]),
      ),
      seed: seeded,
      act: (bloc) => bloc.add(const SaveThemePreset('My look')),
      errors: () => isEmpty,
      expect: () => [reportsFailure()],
      // The dialog closes on submit, so this message is the only thing that can
      // tell the user the name they typed went nowhere.
    );

    blocTest<ThemeBloc, ThemeState>(
      'a delete that fails is reported instead of looking like a dead button',
      build: () => ThemeBloc(
        settingsRepository: settingsRepository,
        themeRepository: _UnwritableThemeRepository([mine, other]),
      ),
      seed: seeded,
      act: (bloc) => bloc.add(const DeleteThemePreset('other')),
      errors: () => isEmpty,
      expect: () => [reportsFailure()],
    );

    blocTest<ThemeBloc, ThemeState>(
      'the same failure twice is reported twice',
      build: () => ThemeBloc(
        settingsRepository: settingsRepository,
        themeRepository: _UnwritableThemeRepository([mine, other]),
      ),
      seed: seeded,
      act: (bloc) async {
        bloc.add(const SelectThemePreset('other'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const SelectThemePreset('other'));
      },
      // The retry clears the message before it runs, so the second failure is a
      // new state rather than an equal one bloc would drop - and the screen,
      // which shows a message once per occurrence, sees the null in between.
      expect: () => [
        reportsFailure(),
        isA<ThemeState>().having((s) => s.actionError, 'actionError', isNull),
        reportsFailure(),
      ],
    );
  });
}
