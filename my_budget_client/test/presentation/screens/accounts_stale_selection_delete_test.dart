// Deleting a selected account the list no longer holds.
//
// The selection is a set of ids and the list is a snapshot, and the two are
// kept apart: a sync pull that removes an account replaces the list without
// touching the selection. The single-account branch of the delete dialog then
// looked its one id up in the fresh list with a bare `firstWhere`, so a
// selection left pointing at a deleted account threw `StateError: No element`
// straight out of the tap handler.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/account_type.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/presentation/blocs/categories/categories_bloc.dart'
    show CategoriesBloc, CategoriesLoadSuccess, CategoriesState;
import 'package:my_budget_client/presentation/blocs/currency_converter/currency_converter_bloc.dart';
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';
import 'package:my_budget_client/presentation/screens/accounts_screen.dart';
import 'package:my_budget_client/presentation/widgets/delete_account_dialog.dart';

import '../test_app.dart';

const _deleteKey = LogicalKeyboardKey.keyD;

final Map<String, String> _hotkeys = {
  'accounts_selection_delete': '${_deleteKey.keyId}',
};

final _checking = Account(
  id: 'a1',
  name: 'Checking',
  balance: 100,
  currencyCode: 'EUR',
  currencyDesignationId: 'd1',
  accountTypeId: 't1',
  creationDate: DateTime(2024, 1, 1),
);

const _cash = AccountType(id: 't1', name: 'Cash', languageCode: 'en');

AccountsState _loaded(Set<String> selected) => AccountsLoadSuccess(
  accounts: [_checking],
  accountTypes: const [_cash],
  hasReachedMax: true,
  totalCount: 1,
  exchangeRates: const [],
  activeDate: DateTime(2024, 1, 1),
  isSelectionModeActive: true,
  selectedAccountIds: selected,
);

/// `MockBloc.add` keeps no history, and the delete path must be shown to send
/// nothing when its account is gone.
class _RecordingAccountsBloc extends MockAccountsBloc {
  final events = <AccountsEvent>[];

  @override
  void add(AccountsEvent event) => events.add(event);
}

CategoriesBloc _categoriesBloc() {
  final bloc = MockCategoriesBloc();
  whenListen(
    bloc,
    const Stream<CategoriesState>.empty(),
    initialState: CategoriesLoadSuccess(
      allCategories: <Category>[],
      hasReachedMax: true,
      activeDate: DateTime(2024, 1, 1),
    ),
  );
  return bloc;
}

CurrencyConverterBloc _converterBloc() {
  final bloc = MockCurrencyConverterBloc();
  whenListen(
    bloc,
    const Stream<CurrencyConverterState>.empty(),
    initialState: CurrencyConverterInitial(),
  );
  return bloc;
}

Future<_RecordingAccountsBloc> _pumpAccounts(
  WidgetTester tester,
  AccountsState state,
) async {
  setSurfaceSize(tester, const Size(900, 1200));

  final accountsBloc = _RecordingAccountsBloc();
  whenListen(
    accountsBloc,
    const Stream<AccountsState>.empty(),
    initialState: state,
  );

  final router = GoRouter(
    initialLocation: AppRoutes.accounts,
    routes: [
      GoRoute(
        path: AppRoutes.accounts,
        builder: (_, _) => const AccountsScreen(),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    wrapWithBlocs(
      MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
      settingsBloc: createSettingsBloc(state: SettingsState(hotkeys: _hotkeys)),
      currencyBloc: createCurrencyBloc(),
      stylesBloc: createStylesBloc(),
      accountsBloc: accountsBloc,
      categoriesBloc: _categoriesBloc(),
      currencyConverterBloc: _converterBloc(),
    ),
  );
  await tester.pumpAndSettle();

  return accountsBloc;
}

void main() {
  testWidgets('deleting a selection whose account is gone does not throw', (
    tester,
  ) async {
    // 'a2' was on the list when it was selected and a pull has since removed
    // it, so the selection names an account the state no longer carries.
    final bloc = await _pumpAccounts(tester, _loaded({'a2'}));

    await tester.sendKeyEvent(_deleteKey);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(DeleteAccountDialog), findsNothing);
    expect(
      bloc.events.whereType<DeleteAccountWithTransactions>(),
      isEmpty,
      reason: 'nothing may be deleted on behalf of a row that is not there',
    );
  });

  testWidgets('deleting a selection that is still on the list still opens the '
      'confirmation', (tester) async {
    // The guard has to remove the crash, not the feature.
    await _pumpAccounts(tester, _loaded({'a1'}));

    await tester.sendKeyEvent(_deleteKey);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(DeleteAccountDialog), findsOneWidget);
  });
}
