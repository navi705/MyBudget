// The change-type dialog on a state that carries no account types.
//
// The dialog pre-selects the first type before it is built, and read it with a
// bare `.first`. An account list can arrive before the types do - the load
// emits them as separate fields, and a pull can empty the table - and the menu
// item then threw `StateError: No element` out of the tap handler instead of
// simply having nothing to offer.
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

import '../test_app.dart';

const _changeTypeKey = LogicalKeyboardKey.keyT;

final Map<String, String> _hotkeys = {
  'accounts_selection_change_type': '${_changeTypeKey.keyId}',
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

AccountsState _loaded(List<AccountType> accountTypes) => AccountsLoadSuccess(
  accounts: [_checking],
  accountTypes: accountTypes,
  hasReachedMax: true,
  totalCount: 1,
  exchangeRates: const [],
  activeDate: DateTime(2024, 1, 1),
  isSelectionModeActive: true,
  selectedAccountIds: const {'a1'},
);

/// `MockBloc.add` keeps no history, and the dialog that never opens must be
/// shown to send nothing either.
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
  testWidgets('changing the type of a selection with no types loaded does not '
      'throw', (tester) async {
    final l10n = await loadL10n();
    final bloc = await _pumpAccounts(tester, _loaded(const []));

    await tester.sendKeyEvent(_changeTypeKey);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(l10n.changeAccountTypeTitle), findsNothing);
    expect(
      bloc.events.whereType<UpdateAccountTypeForMultipleAccounts>(),
      isEmpty,
      reason: 'there is no type to change the accounts to',
    );
  });

  testWidgets('the dialog still opens once a type is loaded', (tester) async {
    // The guard has to remove the crash, not the feature.
    final l10n = await loadL10n();
    await _pumpAccounts(tester, _loaded(const [_cash]));

    await tester.sendKeyEvent(_changeTypeKey);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(l10n.changeAccountTypeTitle), findsOneWidget);
  });
}
