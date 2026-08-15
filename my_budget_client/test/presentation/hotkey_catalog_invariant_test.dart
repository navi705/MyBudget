// This test exists because the hotkey pipeline has three places that must
// agree with each other, and nothing enforced that until now:
//
//   - hot_keys_screen.dart is the CATALOG: it lists every id the Settings UI
//     offers the user to bind.
//   - ScreenShortcuts(actions: {...}) is the only thing that makes an id
//     actually FIRE. Screens pass it a Map<String, VoidCallback>.
//   - MultiLevelTooltip(actionId: ...) only DISPLAYS the bound key as a
//     badge.
//
// A whole bug class came from these three drifting apart, silently:
//
//   - An id offered by the catalog but present in no ScreenShortcuts actions
//     map is bindable in Settings and does *nothing* when the key is
//     pressed. The user picks a shortcut, it "sticks" in the UI, and it
//     never fires.
//   - An id that lives in an actions map but was never added to the catalog
//     can never be bound at all - there is no way for the user to reach it
//     from Settings, no matter how useful the action is.
//   - An id shown by a tooltip but absent from the catalog shows a
//     permanently blank/"None" badge, because there is nothing in Settings
//     for the user to bind against that id.
//
// None of this throws, logs, or shows an error. It just quietly does
// nothing, which is exactly why it needs a standing test rather than manual
// review. This test scans the lib/ sources directly (not by importing them -
// by reading the text off disk) so it stays honest about what is actually
// wired, independent of what any of the three places *claims*.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// An id found at a specific site in the source tree.
class _IdHit {
  const _IdHit(this.id, this.file, this.line);

  final String id;
  final String file;
  final int line;

  @override
  String toString() => "'$id' in $file:$line";
}

/// The result of extracting the `{ ... }` body that follows the first `{`
/// at or after [searchFrom] in [source], respecting brace nesting.
class _BraceBody {
  const _BraceBody(this.text, this.startOffset);

  /// The text strictly between the outermost matching braces.
  final String text;

  /// The absolute offset into [source] of the first character of [text].
  final int startOffset;
}

_BraceBody? _extractBalancedBraces(
  String source,
  int searchFrom,
  int searchUntilExclusive,
) {
  final braceStart = source.indexOf('{', searchFrom);
  if (braceStart == -1 || braceStart >= searchUntilExclusive) return null;

  var depth = 0;
  for (var i = braceStart; i < source.length; i++) {
    final char = source[i];
    if (char == '{') {
      depth++;
    } else if (char == '}') {
      depth--;
      if (depth == 0) {
        return _BraceBody(source.substring(braceStart + 1, i), braceStart + 1);
      }
    }
  }
  return null;
}

int _lineOf(String content, int offset) =>
    '\n'.allMatches(content.substring(0, offset)).length + 1;

/// Matches one `key: ()` entry inside a `Map<String, VoidCallback>` literal,
/// anchored to the start of a line or right after `{`/`,` so it cannot match
/// an unrelated nested `(...) => ...` deeper in a callback's body (those are
/// never preceded by a bare `key:` at that position).
///
/// The key is captured whether or not it is a plain string literal, so a
/// dynamically-built key (e.g. string interpolation) is still captured -
/// just not as a clean `[a-zA-Z0-9_]+` id - and gets reported as "dynamic"
/// rather than silently skipped.
final _mapEntryPattern = RegExp(
  r"(?:^|[{,])[ \t]*('[a-zA-Z0-9_]+'|[^\n:,{}]+?)[ \t]*:[ \t]*\(\)",
  multiLine: true,
);

final _literalIdPattern = RegExp(r"^'([a-zA-Z0-9_]+)'$");

/// `expect()` only works inside a running test, so the disk scan below
/// (which happens once, before any test body runs) reports its own hard
/// failures by throwing instead. They surface as a failure of whichever
/// `setUpAll` runs the scan.
void _require(bool condition, String message) {
  if (!condition) throw StateError(message);
}

void main() {
  // ---------------------------------------------------------------------
  // Scan phase: read lib/ off disk and extract the three id sets. This runs
  // once, in setUpAll, before any test body - the tests below only assert
  // over what was found. It is a plain function (not `expect`-based) because
  // `expect` cannot run outside a test body.
  // ---------------------------------------------------------------------

  late Set<String> catalogIds;
  late List<_IdHit> actionsIdHits;
  late Set<String> actionsIdsUnion;
  late Set<String> filesWithActionsMaps;
  late List<String> dynamicActionsEntries;
  late List<_IdHit> tooltipIdHits;
  late List<String> dynamicTooltipEntries;

  setUpAll(() {
    final libDir = Directory('lib');
    _require(
      libDir.existsSync(),
      'This test must run with the package root (my_budget_client) as the '
      "working directory, so that Directory('lib') resolves. "
      'flutter test was not run from there.',
    );

    final dartFiles =
        libDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    // Directory('lib') is relative to the package root, so every listed
    // file's path already starts with 'lib' - just normalize separators.
    String relPathOf(File f) => f.path.replaceAll('\\', '/');

    // --- 1. The catalog: every {'id': 'foo', 'label': ...} in
    //     hot_keys_screen.dart ---

    final catalogFile = File('lib/presentation/screens/hot_keys_screen.dart');
    _require(
      catalogFile.existsSync(),
      'lib/presentation/screens/hot_keys_screen.dart was not found. This '
      'test hardcodes that path as THE hotkey catalog; if it moved, update '
      'this test.',
    );
    final catalogContent = catalogFile.readAsStringSync();
    final catalogIdPattern = RegExp(r"'id':\s*'([a-zA-Z0-9_]+)'");
    catalogIds = <String>{
      for (final m in catalogIdPattern.allMatches(catalogContent)) m.group(1)!,
    };

    // --- 2. Every id fired from a ScreenShortcuts(actions: {...}) map ---

    actionsIdHits = <_IdHit>[];
    dynamicActionsEntries = <String>[];
    filesWithActionsMaps = <String>{};

    final screenShortcutsCallPattern = RegExp(r'ScreenShortcuts\(');

    for (final file in dartFiles) {
      final content = file.readAsStringSync();
      final relPath = relPathOf(file);

      final callStarts = [
        for (final m in screenShortcutsCallPattern.allMatches(content)) m.start,
      ];

      for (var i = 0; i < callStarts.length; i++) {
        final callStart = callStarts[i];
        final boundEnd = i + 1 < callStarts.length
            ? callStarts[i + 1]
            : content.length;

        final actionsKeywordIdx = content.indexOf('actions:', callStart);
        if (actionsKeywordIdx == -1 || actionsKeywordIdx >= boundEnd) continue;

        final body = _extractBalancedBraces(
          content,
          actionsKeywordIdx,
          boundEnd,
        );
        if (body == null) continue;

        filesWithActionsMaps.add(relPath);

        for (final entryMatch in _mapEntryPattern.allMatches(body.text)) {
          final rawKey = entryMatch.group(1)!.trim();
          final literalMatch = _literalIdPattern.firstMatch(rawKey);
          final absoluteOffset = body.startOffset + entryMatch.start;
          if (literalMatch != null) {
            actionsIdHits.add(
              _IdHit(
                literalMatch.group(1)!,
                relPath,
                _lineOf(content, absoluteOffset),
              ),
            );
          } else {
            dynamicActionsEntries.add(
              '$relPath:${_lineOf(content, absoluteOffset)}: key expression '
              '`$rawKey` is not a plain string literal',
            );
          }
        }
      }
    }

    actionsIdsUnion = actionsIdHits.map((h) => h.id).toSet();

    // --- 3. Every actionId: ... used on a MultiLevelTooltip ---

    tooltipIdHits = <_IdHit>[];
    dynamicTooltipEntries = <String>[];

    final tooltipCallPattern = RegExp(r'MultiLevelTooltip\(');
    final tooltipActionIdPattern = RegExp(r'actionId:\s*([^\n,]+),');

    for (final file in dartFiles) {
      final content = file.readAsStringSync();
      final relPath = relPathOf(file);

      final callStarts = [
        for (final m in tooltipCallPattern.allMatches(content)) m.start,
      ];

      for (var i = 0; i < callStarts.length; i++) {
        final callStart = callStarts[i];
        final boundEnd = i + 1 < callStarts.length
            ? callStarts[i + 1]
            : content.length;

        final bounded = content.substring(callStart, boundEnd);
        final match = tooltipActionIdPattern.firstMatch(bounded);
        if (match == null) continue;

        final rawValue = match.group(1)!.trim();
        final literalMatch = _literalIdPattern.firstMatch(rawValue);
        final absoluteOffset = callStart + match.start;
        if (literalMatch != null) {
          tooltipIdHits.add(
            _IdHit(
              literalMatch.group(1)!,
              relPath,
              _lineOf(content, absoluteOffset),
            ),
          );
        } else {
          dynamicTooltipEntries.add(
            '$relPath:${_lineOf(content, absoluteOffset)}: actionId '
            'expression `$rawValue` is not a plain string literal',
          );
        }
      }
    }
  });

  // --- The allowlist for requirement 2: catalog ids that are deliberately
  //     wired outside of any ScreenShortcuts actions map. Keep this list as
  //     small as reality allows - every entry below is verified, at the end
  //     of this file, to still actually be unwired, so the list can only
  //     shrink over time and never silently rot into a lie. ---

  const unwiredAllowlist = <String, String>{
    'back':
        "Wired via EscapeBackHandler (scaffold_with_escape_back.dart), "
        "which reads state.hotkeys['back'] directly and binds it with "
        "CallbackShortcuts, instead of going through a ScreenShortcuts "
        "actions map like every other action.",
  };

  // ---------------------------------------------------------------------
  // Assertions
  // ---------------------------------------------------------------------

  group('hotkey catalog invariant', () {
    test('sanity floors: the extractor actually found something, so a broken '
        'regex cannot make the invariant tests pass vacuously', () {
      expect(
        catalogIds.length,
        greaterThanOrEqualTo(40),
        reason:
            'Only found ${catalogIds.length} ids in the hot_keys_screen.dart '
            'catalog. The catalog has always had 40+ entries; either the '
            "extractor regex broke, or entries were genuinely removed - "
            'either way this needs a human look before trusting the rest '
            'of this test.',
      );

      expect(
        filesWithActionsMaps.length,
        greaterThanOrEqualTo(8),
        reason:
            'Only found actions maps in ${filesWithActionsMaps.length} '
            'files (${filesWithActionsMaps.join(', ')}). At least 8 '
            'screens/tabs are known to pass an actions map to '
            'ScreenShortcuts; if fewer were found, the extractor likely '
            "broke rather than the app having actually lost wiring.",
      );

      const mustBeFoundBothWays = [
        'pick_date',
        'sort_order',
        'filter_action',
        'add_action',
      ];
      for (final id in mustBeFoundBothWays) {
        expect(
          catalogIds,
          contains(id),
          reason:
              "'$id' is expected to be in the hot_keys_screen.dart catalog "
              "but the extractor did not find it - the catalog regex is "
              "probably broken.",
        );
        expect(
          actionsIdsUnion,
          contains(id),
          reason:
              "'$id' is expected to be fired from at least one "
              "ScreenShortcuts actions map but the extractor did not find "
              "it anywhere - the actions-map regex is probably broken.",
        );
      }
    });

    test('every id fired from a ScreenShortcuts actions map is offered by the '
        'catalog', () {
      for (final hit in actionsIdHits) {
        expect(
          catalogIds,
          contains(hit.id),
          reason:
              "ScreenShortcuts in $hit fires the action '${hit.id}', but "
              "hot_keys_screen.dart's catalog does not list that id. "
              "There is no way for a user to ever bind a key to it from "
              "Settings, no matter how useful the action is. Add "
              "'${hit.id}' to the catalog in hot_keys_screen.dart.",
        );
      }
    });

    test('every catalog id is wired to a ScreenShortcuts actions map, or is on '
        'the explicit unwired allowlist', () {
      for (final id in catalogIds) {
        final wired = actionsIdsUnion.contains(id);
        final allowlisted = unwiredAllowlist.containsKey(id);
        expect(
          wired || allowlisted,
          isTrue,
          reason:
              "hot_keys_screen.dart offers '$id' for binding in Settings, "
              "but no ScreenShortcuts actions map anywhere in lib/ fires "
              "it, and '$id' is not on the unwiredAllowlist in this test. "
              "A user who binds a key to it will see the key 'stick' in "
              "Settings and then do nothing when pressed. Either wire it "
              "into a ScreenShortcuts actions map, or - if it is "
              "deliberately handled some other way - add it to "
              "unwiredAllowlist in this test with a one-line reason.",
        );
      }
    });

    test(
      'the unwired allowlist names only ids that are still actually unwired',
      () {
        for (final entry in unwiredAllowlist.entries) {
          expect(
            actionsIdsUnion.contains(entry.key),
            isFalse,
            reason:
                "'${entry.key}' is on the unwiredAllowlist in this test "
                "(reason given: \"${entry.value}\"), but it now shows up in "
                "a ScreenShortcuts actions map (${actionsIdHits.where((h) => h.id == entry.key).join(', ')}). "
                "It is no longer unwired, so it must be removed from "
                "unwiredAllowlist - the whole point of the allowlist is "
                "that it can only shrink, never silently keep an id that "
                "got wired without anyone noticing.",
          );
        }
      },
    );

    test('every actionId shown by a MultiLevelTooltip is offered by the '
        'catalog', () {
      for (final hit in tooltipIdHits) {
        expect(
          catalogIds,
          contains(hit.id),
          reason:
              "MultiLevelTooltip in $hit displays the hotkey for "
              "'${hit.id}', but hot_keys_screen.dart's catalog does not "
              "list that id. There is nothing in Settings for the user to "
              "bind, so the tooltip's key badge will be permanently "
              "blank. Add '${hit.id}' to the catalog in "
              "hot_keys_screen.dart, or fix the actionId if it is a typo.",
        );
      }
    });

    test('dynamically-built ids are reported rather than silently dropped', () {
      // This test always passes: dynamic ids (built from a variable or
      // string interpolation instead of a plain string literal) cannot be
      // checked by the regex-based extraction above, so they are excluded
      // from the invariant checks. Rather than silently ignoring them,
      // list them here so a human can see what was NOT verified.
      if (dynamicActionsEntries.isNotEmpty) {
        // ignore: avoid_print
        print(
          'hotkey_catalog_invariant_test: dynamic (non-literal) keys in '
          'ScreenShortcuts actions maps were NOT checked against the '
          'catalog:\n${dynamicActionsEntries.map((e) => '  - $e').join('\n')}',
        );
      }
      if (dynamicTooltipEntries.isNotEmpty) {
        // ignore: avoid_print
        print(
          'hotkey_catalog_invariant_test: dynamic (non-literal) actionId '
          'values on MultiLevelTooltip were NOT checked against the '
          'catalog:\n${dynamicTooltipEntries.map((e) => '  - $e').join('\n')}',
        );
      }
      expect(true, isTrue);
    });
  });
}
