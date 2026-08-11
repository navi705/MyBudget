// AccountsScreen was the last screen still writing English straight into its
// widget tree: the multi-account delete confirmation, the change-type dialog,
// every date-bar tooltip and the "Total: n" counter ignored the user's
// language. The keys for all of them already existed — they were added when the
// destructive confirmations were localised — and simply were never read.
//
// These tests pump the screen under a locale that is *not* the source language
// and assert the translated string is on screen, plus that the English one is
// not: a string that goes back to being hard-coded fails both halves at once.
import 'dart:convert';
import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/domain/entities/account_type.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency_converter/currency_converter_bloc.dart';
import 'package:my_budget_client/presentation/screens/accounts_screen.dart';
import 'package:my_budget_client/presentation/widgets/multi_level_tooltip.dart';

import '../test_app.dart';

/// Russian, because none of the strings under test survive translation into it
/// unchanged — an English literal left behind is visible as English.
const Locale _locale = Locale('ru');

const _cash = AccountType(id: 'cash', name: 'Cash', languageCode: 'en');

/// The strings for [_locale] and for English side by side.
///
/// The English half is what the assertions deny: `findsNothing` on the source
/// language is the check that actually catches a re-hardcoded literal, because
/// the widget would still render *something* and only the language would be
/// wrong.
typedef _Strings = ({AppLocalizations ru, AppLocalizations en});

/// A loaded state with no account rows.
///
/// The list is deliberately empty: an account row pulls in the whole balance
/// formatting and currency-conversion stack, and none of the strings under test
/// live on a row. Selection mode is driven by [selectedAccountIds] rather than
/// by tapping, so the selection app bar can be reached without one.
AccountsLoadSuccess _loaded({
  int totalCount = 7,
  bool isSelectionModeActive = false,
  Set<String> selectedAccountIds = const {},
  List<AccountType> accountTypes = const [_cash],
}) => AccountsLoadSuccess(
  accounts: const [],
  accountTypes: accountTypes,
  hasReachedMax: true,
  totalCount: totalCount,
  activeDate: DateTime(2026, 3, 15),
  exchangeRates: const [],
  isSelectionModeActive: isSelectionModeActive,
  selectedAccountIds: selectedAccountIds,
);

/// Pumps AccountsScreen with [state] pinned, in [_locale].
///
/// Only the three blocs the screen reads while building are provided. They sit
/// *above* the MaterialApp because the delete and change-type dialogs go onto
/// the root navigator, where they are siblings of the screen rather than its
/// descendants and cannot see providers placed around it.
Future<_Strings> _pumpAccounts(
  WidgetTester tester, {
  required AccountsLoadSuccess state,
  Size surfaceSize = const Size(900, 1200),
}) async {
  final bloc = MockAccountsBloc();
  whenListen(bloc, const Stream<AccountsState>.empty(), initialState: state);

  final converter = MockCurrencyConverterBloc();
  whenListen(
    converter,
    const Stream<CurrencyConverterState>.empty(),
    // Not a success state, so the total-balance summary stays collapsed.
    initialState: CurrencyConverterInitial(),
  );

  await pumpAppWidget(
    tester,
    const AccountsScreen(),
    locale: _locale,
    surfaceSize: surfaceSize,
    // AccountsScreen brings its own Scaffold.
    wrapInScaffold: false,
    aboveApp: (app) => wrapWithBlocs(
      app,
      settingsBloc: createSettingsBloc(),
      accountsBloc: bloc,
      currencyConverterBloc: converter,
    ),
  );
  await tester.pumpAndSettle();

  return (ru: await loadL10n(_locale), en: await loadL10n());
}

/// Holds a mouse over [finder] long enough for both tooltip levels to appear.
///
/// [MultiLevelTooltip] is not a Material `Tooltip`: it puts its own overlay up
/// after a second of hover and only widens it to the description three seconds
/// later, so neither string is in the tree until the pointer has sat still for
/// four seconds of fake time.
Future<void> _hover(WidgetTester tester, Finder finder) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: Offset.zero);
  addTearDown(() => gesture.removePointer());

  await gesture.moveTo(tester.getCenter(finder));
  await tester.pump();
  // Level 1: the short message.
  await tester.pump(const Duration(milliseconds: 1100));
  // Level 2: the long description.
  await tester.pump(const Duration(seconds: 4));
  await tester.pump();
}

/// The tooltips on screen, keyed by the action they describe.
Map<String, MultiLevelTooltip> _tooltipsByAction(WidgetTester tester) => {
  for (final tooltip in tester.widgetList<MultiLevelTooltip>(
    find.byType(MultiLevelTooltip),
  ))
    tooltip.actionId: tooltip,
};

void main() {
  group('AccountsScreen strings follow the locale', () {
    testWidgets('the account counter is translated, not concatenated', (
      tester,
    ) async {
      final l10n = await _pumpAccounts(tester, state: _loaded(totalCount: 7));

      expect(find.text(l10n.ru.totalCountLabel(7)), findsOneWidget);
      expect(find.text(l10n.en.totalCountLabel(7)), findsNothing);
      expect(find.text('Total: 7'), findsNothing);
    });

    testWidgets('the date bar carries its tooltips in the active locale', (
      tester,
    ) async {
      final l10n = await _pumpAccounts(tester, state: _loaded());

      final tooltips = _tooltipsByAction(tester);
      final expected = <String, (String, String)>{
        'prev_period': (
          l10n.ru.previousPeriodTooltip,
          l10n.ru.accountsPreviousPeriodDescription,
        ),
        'next_period': (
          l10n.ru.nextPeriodTooltip,
          l10n.ru.accountsNextPeriodDescription,
        ),
        'filter_accounts': (
          l10n.ru.filterTooltip,
          l10n.ru.accountsFilterDescription,
        ),
        'accounts_pick_date': (
          l10n.ru.selectDateTooltip,
          l10n.ru.accountsSelectDateDescription,
        ),
        'accounts_sort': (
          l10n.ru.sortOrderTooltip,
          l10n.ru.accountsSortDescription,
        ),
      };

      for (final entry in expected.entries) {
        final tooltip = tooltips[entry.key];
        expect(tooltip, isNotNull, reason: '${entry.key} is not on screen');
        expect(
          tooltip!.message,
          entry.value.$1,
          reason: '${entry.key} shows an untranslated title',
        );
        expect(
          tooltip.description,
          entry.value.$2,
          reason: '${entry.key} shows an untranslated description',
        );
      }
    });

    // The properties above are only a promise; this is the string the user
    // actually reads, rendered into the overlay the tooltip builds.
    testWidgets('a hovered sort button explains itself in the active locale', (
      tester,
    ) async {
      final l10n = await _pumpAccounts(tester, state: _loaded());

      await _hover(tester, find.byIcon(Icons.sort));

      expect(find.text(l10n.ru.sortOrderTooltip), findsOneWidget);
      expect(find.text(l10n.ru.accountsSortDescription), findsOneWidget);
      expect(find.text(l10n.en.sortOrderTooltip), findsNothing);
      expect(find.text(l10n.en.accountsSortDescription), findsNothing);
    });

    // The confirmation that destroys data. Asking a Russian reader to confirm
    // an irreversible delete in English is the worst case this whole change
    // exists to remove.
    testWidgets('the multi-account delete confirmation is translated', (
      tester,
    ) async {
      final l10n = await _pumpAccounts(
        tester,
        state: _loaded(
          isSelectionModeActive: true,
          selectedAccountIds: const {'a1', 'a2'},
        ),
      );

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      expect(find.text(l10n.ru.deleteAccountsConfirmTitle(2)), findsOneWidget);
      expect(find.text(l10n.ru.deleteAccountsConfirmMessage), findsOneWidget);
      expect(find.text(l10n.ru.cancelButton), findsOneWidget);
      expect(find.text(l10n.ru.deleteAllButton), findsOneWidget);

      expect(find.text(l10n.en.deleteAccountsConfirmTitle(2)), findsNothing);
      expect(find.text(l10n.en.deleteAccountsConfirmMessage), findsNothing);
      expect(find.text(l10n.en.cancelButton), findsNothing);
      expect(find.text(l10n.en.deleteAllButton), findsNothing);
      // The old literal was built by interpolation rather than by a
      // placeholder, so it could never have been translated at all.
      expect(find.text('Delete 2 accounts?'), findsNothing);
    });

    testWidgets('the change-account-type dialog is translated', (tester) async {
      final l10n = await _pumpAccounts(
        tester,
        state: _loaded(
          isSelectionModeActive: true,
          selectedAccountIds: const {'a1', 'a2'},
        ),
      );

      await tester.tap(find.byIcon(Icons.drive_file_rename_outline));
      await tester.pumpAndSettle();

      expect(find.text(l10n.ru.changeAccountTypeTitle), findsOneWidget);
      expect(find.text(l10n.ru.cancelButton), findsOneWidget);
      expect(find.text(l10n.ru.changeButton), findsOneWidget);

      expect(find.text(l10n.en.changeAccountTypeTitle), findsNothing);
      expect(find.text(l10n.en.cancelButton), findsNothing);
      expect(find.text(l10n.en.changeButton), findsNothing);
      // The account type itself is user data, not a translatable string.
      expect(find.text(_cash.name), findsOneWidget);
    });

    // Narrow layout swaps which branch of the date bar builds the filter and
    // sort buttons; the strings have to survive the swap.
    testWidgets('the narrow date bar keeps its translations', (tester) async {
      final l10n = await _pumpAccounts(
        tester,
        state: _loaded(),
        surfaceSize: const Size(420, 900),
      );

      final tooltips = _tooltipsByAction(tester);
      expect(tooltips['filter_accounts']?.message, l10n.ru.filterTooltip);
      expect(
        tooltips['filter_accounts']?.description,
        l10n.ru.accountsFilterDescription,
      );
      expect(tooltips['accounts_sort']?.message, l10n.ru.sortOrderTooltip);
      expect(
        tooltips['accounts_sort']?.description,
        l10n.ru.accountsSortDescription,
      );
    });
  });

  group('the keys this screen uses ship in every locale', () {
    // Every key AccountsScreen reads. A key present only in app_en.arb still
    // compiles and still renders — `flutter gen-l10n` falls back to English —
    // so the check has to be against the .arb files themselves as well as
    // against the delegates.
    final readers = <String, String Function(AppLocalizations)>{
      'accountsAddTooltip': (l) => l.accountsAddTooltip,
      'accountsAppBarTitle': (l) => l.accountsAppBarTitle,
      'accountsEmptyState': (l) => l.accountsEmptyState,
      'accountsFilterDescription': (l) => l.accountsFilterDescription,
      'accountsNextPeriodDescription': (l) => l.accountsNextPeriodDescription,
      'accountsPreviousPeriodDescription': (l) =>
          l.accountsPreviousPeriodDescription,
      'accountsSelectDateDescription': (l) => l.accountsSelectDateDescription,
      'accountsSortDescription': (l) => l.accountsSortDescription,
      'addAccountBeforeTransactionDescription': (l) =>
          l.addAccountBeforeTransactionDescription,
      'addAccountDescription': (l) => l.addAccountDescription,
      'addCategoryTooltip': (l) => l.addCategoryTooltip,
      'cancelButton': (l) => l.cancelButton,
      'changeAccountTypeTitle': (l) => l.changeAccountTypeTitle,
      'changeButton': (l) => l.changeButton,
      'closeSelectionTooltip': (l) => l.closeSelectionTooltip,
      'contextMenuAddTransaction': (l) => l.contextMenuAddTransaction,
      'contextMenuChangeType': (l) => l.contextMenuChangeType,
      'contextMenuDelete': (l) => l.contextMenuDelete,
      'contextMenuDeselect': (l) => l.contextMenuDeselect,
      'contextMenuDeselectAll': (l) => l.contextMenuDeselectAll,
      'contextMenuEdit': (l) => l.contextMenuEdit,
      'contextMenuSelect': (l) => l.contextMenuSelect,
      'contextMenuSelectAll': (l) => l.contextMenuSelectAll,
      'contextMenuTransfer': (l) => l.contextMenuTransfer,
      'deleteAccountsConfirmMessage': (l) => l.deleteAccountsConfirmMessage,
      'deleteAccountsConfirmTitle': (l) => l.deleteAccountsConfirmTitle(2),
      'deleteAllButton': (l) => l.deleteAllButton,
      'deleteTransactionsDescription': (l) => l.deleteTransactionsDescription,
      'exitSelectionDescription': (l) => l.exitSelectionDescription,
      'failedToLoadData': (l) => l.failedToLoadData,
      'filterTooltip': (l) => l.filterTooltip,
      'importErrorLabel': (l) => l.importErrorLabel('x'),
      'itemDeletedMessage': (l) => l.itemDeletedMessage('x'),
      'nextPeriodTooltip': (l) => l.nextPeriodTooltip,
      'noCategoriesCreated': (l) => l.noCategoriesCreated,
      'previousPeriodTooltip': (l) => l.previousPeriodTooltip,
      'selectDateTooltip': (l) => l.selectDateTooltip,
      'selectedCountLabel': (l) => l.selectedCountLabel(2),
      'sortOrderTooltip': (l) => l.sortOrderTooltip,
      'totalCountLabel': (l) => l.totalCountLabel(7),
      'undoButton': (l) => l.undoButton,
    };

    test('no .arb file is missing one of them', () {
      for (final locale in AppLocalizations.supportedLocales) {
        final file = File('lib/l10n/app_${locale.languageCode}.arb');
        expect(
          file.existsSync(),
          isTrue,
          reason: '${file.path} is missing for a supported locale',
        );
        final arb =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        for (final key in readers.keys) {
          expect(
            arb[key],
            isA<String>().having((s) => s.trim(), 'text', isNotEmpty),
            reason: '$key is missing from ${file.path}',
          );
        }
      }
    });

    test('every locale resolves them to a non-empty string', () async {
      for (final locale in AppLocalizations.supportedLocales) {
        final l10n = await AppLocalizations.delegate.load(locale);
        for (final entry in readers.entries) {
          expect(
            entry.value(l10n).trim(),
            isNotEmpty,
            reason: '${entry.key} is empty in $locale',
          );
        }
      }
    });

    // The ten .arb files are only interchangeable if they hold the same set of
    // message keys; a key added to English alone is a silent English fallback
    // in the other nine, which is exactly the bug this screen had.
    test('all ten locales carry the same set of keys', () {
      Set<String> keysOf(String languageCode) {
        final arb =
            jsonDecode(
                  File('lib/l10n/app_$languageCode.arb').readAsStringSync(),
                )
                as Map<String, dynamic>;
        return arb.keys.where((k) => !k.startsWith('@')).toSet();
      }

      final english = keysOf('en');
      expect(english, isNotEmpty);
      for (final locale in AppLocalizations.supportedLocales) {
        expect(
          keysOf(locale.languageCode),
          english,
          reason: '${locale.languageCode} does not match app_en.arb',
        );
      }
    });
  });
}
