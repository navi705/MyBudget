---
score: 17
max: 40
p0: 3
p1: 3
mode: operate
method: dual-agent
target: my_budget_client/lib/presentation
timestamp: 2026-08-21T16-36-37Z
slug: my-budget-client-lib-presentation
---
Method: dual-agent (A: design review, isolated · B: detector + headless render evidence, isolated)

Target: `my_budget_client/lib/presentation` — 19 screens, 123 files, ~40k lines. Mode: Operate.
Device classes judged: phone portrait 360x780, phone landscape 780x360, tablet 834x1112,
desktop 1440x900, desktop small 620x520; plus `ar` and `ru` variants. 135 headless renders,
129 OK / 6 layout-exception.

## Heuristics (0-4, max 40)

| # | Heuristic | Score | Finding |
|---|---|---|---|
| 1 | Visibility of system status | 2 | `import_screen.dart` runs an 11-state wizard with no step indicator |
| 2 | Match with the real world | 2 | `_DateField` prints a raw ISO date in a 10-locale app |
| 3 | User control and freedom | 2 | export dialog has no Cancel (`settings_screen.dart:248`); a web reload discards an in-progress edit |
| 4 | Consistency and standards | 1 | the breakpoint is read from the pane in the shell and from the window in ten screens; `splashFactory: NoSplash` is set in the light theme only |
| 5 | Error prevention | 1 | `_confirmResetData` destroys all data behind one red button, while deleting one transaction offers Undo |
| 6 | Recognition over recall | 1 | `multi_level_tooltip.dart` labels on hover only, no `Semantics`; it is the sole label carrier for nav, FAB and filter bars |
| 7 | Flexibility and efficiency | 3 | rebindable hotkeys, mouse-drag scroll, right-click menus; but the three pickers in the transaction form are `AbsorbPointer` and skip tab order |
| 8 | Aesthetic and minimalist design | 2 | 13-row flat Settings list with no section headers; ~1270px between a row label and its own actions at 1440 |
| 9 | Error recovery | 2 | good `_ThemeLoadFailureBar`; sync and import failures surface as bare `failure` text |
| 10 | Help and documentation | 1 | help exists only as grey captions; splash strings are untranslated English |

**Total: 17/40.**

## Design specificity

Generic Material 3 with a theme picker on top. Everything derives from `ColorScheme.fromSeed`
over ten stock swatches, and the parts that carry the product's meaning ignore the theme
entirely: money is `Colors.green` / `Colors.red` hardcoded in `transaction_list.dart`,
`add_edit_transaction_screen.dart:385`, `account_list_item.dart:168`. No money type, no
positive/negative token, no numeral treatment. The product's one genuinely own idea —
`_buildUnconvertibleNotice` in `dashboard_screen.dart:112`, which refuses to state a total it
cannot back with rates — lives in exactly one widget instead of being a house rule.

## Priority issues

### P0-1. The navigation rail drops destinations off the bottom, unreachable

CONFIRMED by render: `A RenderFlex overflowed by 166 pixels on the bottom` at 780x360 and
`by 6.0 pixels` at 620x520, `NavigationRail` at `adaptive_scaffold.dart:145`, reproduced
identically in en/ar/ru. The rail needs ~446dp for its toggle plus seven destinations and sits in
no scroll view. At 780x360 (a phone in landscape) Data, Settings and Debug are simply gone — and
Settings is the only route to Hot Keys, Theme, API, SMS, Sync, Import/Export and Reset.
Fix: choose the shell by width *and* height — bottom `NavigationBar` when the pane is shorter
than ~500dp — and wrap the rail body in a scroll view so it degrades instead of truncating.

### P0-2. The software keyboard covers the fields being typed into, app-wide

`adaptive_scaffold.dart:99` and `:141` both set `resizeToAvoidBottomInset: false`, so every
screen inside the shell keeps full height when the keyboard opens.
`add_edit_transaction_screen.dart` opts back in, which proves the shell default is wrong rather
than intentional. Fix: drop both, opt out per screen where a full-bleed chart needs it.

### P0-3. Balances over 999 are displayed wrong in Arabic and Urdu

CONFIRMED visually: `1 234.56` in en renders as `234.56 1` in ar. `money_formatter.dart:39`
groups with a plain space (U+0020, bidi class WS), which terminates the number run, so the groups
lay out right-to-left under an RTL paragraph. No bidi isolation anywhere in `lib/`.
Fix: group with U+00A0, or wrap the formatted amount in LRI…PDI (U+2066…U+2069). This is a
finance app stating a wrong number to a reader — it outranks every layout issue here.

### P1-4. Icon-only controls are unlabelled for touch and for screen readers

`multi_level_tooltip.dart` fires on `MouseRegion.onEnter` only, contains no `Semantics` and no
`Tooltip`, and is the sole label carrier for nav destinations, the FAB and the filter bars. The
rail is collapsed by default, so tablet users cannot learn the navigation at all.
Fix: `Semantics(label:, hint:)` unconditionally plus a long-press `Tooltip` on the touch path;
extend the rail above ~900dp.

### P1-5. Two definitions of "mobile" disagree over a 142dp band

The shell measures `constraints.maxWidth`; ten screens measure `MediaQuery.of(context).size.width`
(`accounts_screen.dart:548,991`, `categories_screen.dart:623,852`, `transactions_screen.dart:215`,
`settings_screen.dart:55`, `filter_date.dart:58`, `asset_tab_app_bar.dart:78`,
`inflation_tab_app_bar.dart:78`, `account_filter_dialog.dart:25`). Visible in the renders: the
dashboard tab bar sits at the top at 620x520 and at the bottom at 780x360 — dragging a window
160px narrower teleports the primary tab control across the screen.
Fix: one `context.isCompactPane` backed by the pane, used everywhere.

### P1-6. Nothing constrains content width on desktop

At 1440x900: `manage_styles` puts a row's label at x=72 and its own edit/delete at x=1344/1392;
`theme_settings` puts labels at x=36 and swatches at x=1380; `accounts` and `transactions` render
full-bleed 1408px cards holding ~300px of content. `settings_screen.dart` (800) and
`add_edit_transaction_screen.dart` (600) already do it right — the pattern exists and is applied
to two screens of nineteen.

## Also confirmed

- 16 hardcoded directional icons, none `matchTextDirection`, two per file across eight files
  (`dashboard_header.dart:58,68`, `filter_date.dart:71,181`, `calendar_step_picker.dart:421,437`,
  `accounts_screen.dart:1004,1096`, `categories_screen.dart:865,951`,
  `exchange_rates_screen.dart:748,839`, `asset_tab_app_bar.dart:91,176`,
  `inflation_tab_app_bar.dart:91,176`). "Previous month" points forward in Arabic.
- `dashboard_calendar.dart` `_buildWeekdayLabels` hardcodes a Monday-start week; wrong for `ar`
  (Saturday) and `en_US` (Sunday).
- Three date patterns coexist (`dd.MM.yyyy`, `EEE, MMM d, yyyy`, raw ISO), only two locale-aware.
- Contrast: the `theme_settings` preset tile "Nordic Frost" prints white on a near-white swatch;
  unselected dashboard tab labels are mid-grey on near-black.
- The FAB overlaps the last list item on `transactions` at 1440x900 and 780x360 — no bottom
  padding reserved.
- `splash_screen.dart` forces `ThemeData.dark()` and English strings on every cold start.
- 17 of 19 screens have no `SafeArea` (static risk; not observable headless).
- Destructive protection is inverted: Undo for one transaction, a single red button for all data.
- Six dialogs sized as a fraction of screen height (0.7 / 0.85), which is 252dp in phone landscape
  and 756px on a desktop monitor.

## What is working

- `_buildUnconvertibleNotice` — the app admits when a total is incomplete. A product value
  expressed as UI.
- Desktop input is taken seriously: `PointerDeviceKind.mouse` re-added to `dragDevices`,
  right-click menus gated per platform with a long-press touch path, fully rebindable hotkeys.
- Structural RTL mirroring is sound (`main_shell_ar__1440x900` mirrors rail and panes correctly);
  `EdgeInsetsDirectional` is used ten times against two non-directional uses; no
  `Alignment.centerLeft`, no `TextAlign.left` anywhere.
- Tap targets are clean: no `iconSize` overrides, no `IconButton` constraint shrinking, nothing
  under 44dp.
- Platform gating is all behind `AppPlatform` / `kIsWeb`, never raw `Platform.is*`.

## Detector

`node .claude/skills/impeccable/scripts/detect.mjs --json my_budget_client/lib/presentation` —
exit 0, `[]`. The detector parses HTML/CSS and has no Dart front end, so the null result carries
no signal either way. All render evidence came from a throwaway `flutter_test` harness, since
removed; the repo is clean of it.

## Persona red flags

- **Phone, one hand, at a counter:** unlabelled FAB, ISO date, keyboard over the Save button,
  and rotating the phone breaks the navigation outright.
- **Arabic tablet:** balances over 999 read wrong, month arrows point the wrong way, the calendar
  is a column off, and the collapsed rail's labels need a pointer the device does not have.
- **Web at 125% scaling:** Settings rows silently missing (`AppPlatform` is all-false on web), tab
  order skips account/category/linked account, no focus ring anywhere, F5 during an edit discards
  it with no message.
