// Two dead ends in the Add Account dialog, both of them silent.
//
// The currency designation is looked up by currency code, so picking a currency
// with no designation row left the field looking filled and `_onSave`'s guard
// returning with nothing marked - Save was a button that did nothing. And the
// account type picker is hidden because a type is normally auto-assigned from
// the loaded list, so on a fresh install with no account types the same guard
// made the dialog permanently unsubmittable, with nothing on screen saying why.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/domain/entities/account_type.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/currency_designation.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency/currency_bloc.dart';
import 'package:my_budget_client/presentation/widgets/add_account_dialog.dart';

import '../test_app.dart';

/// Records what the dialog dispatched.
///
/// `MockBloc` stubs `add` into a no-op, which is what keeps these tests about
/// the widget - but whether Save reaches the bloc at all is the whole question
/// here, so `add` is overridden to keep the events.
class _RecordingAccountsBloc extends MockBloc<AccountsEvent, AccountsState>
    implements AccountsBloc {
  final events = <AccountsEvent>[];

  @override
  void add(AccountsEvent event) => events.add(event);
}

const _usd = Currency(
  name: 'US Dollar',
  code: 'USD',
  languageCode: 'en',
  type: TypeCurrency.currency,
);

const _usdDesignation = CurrencyDesignation(
  id: 'usd-symbol',
  value: r'$',
  currencyCode: 'USD',
);

const _cash = AccountType(id: 'cash', name: 'Cash', languageCode: 'en');

AccountsLoadSuccess _accountsState(List<AccountType> accountTypes) =>
    AccountsLoadSuccess(
      accounts: const [],
      accountTypes: accountTypes,
      hasReachedMax: true,
      totalCount: 0,
      activeDate: DateTime(2025, 3, 15),
      exchangeRates: const [],
    );

void main() {
  late _RecordingAccountsBloc accountsBloc;

  setUp(() => accountsBloc = _RecordingAccountsBloc());

  /// Opens the dialog from a route, the way it opens in the app.
  ///
  /// The blocs go above the `MaterialApp`: the dialog is a sibling of `home`
  /// under the app's Navigator and cannot see anything provided around it.
  Future<void> openDialog(
    WidgetTester tester, {
    required List<CurrencyDesignation> designations,
    required List<AccountType> accountTypes,
  }) async {
    whenListen(
      accountsBloc,
      const Stream<AccountsState>.empty(),
      initialState: _accountsState(accountTypes),
    );

    await pumpAppWidget(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => const AddAccountDialog(),
          ),
          child: const Text('open'),
        ),
      ),
      surfaceSize: const Size(900, 1400),
      aboveApp: (app) => wrapWithBlocs(
        app,
        settingsBloc: createSettingsBloc(),
        currencyBloc: createCurrencyBloc(
          state: CurrencyLoadSuccess(
            currencies: const [_usd],
            designations: designations,
          ),
        ),
        stylesBloc: createStylesBloc(),
        accountsBloc: accountsBloc,
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  /// Fills in the two free-text fields and picks the only currency on offer.
  Future<void> fillForm(WidgetTester tester, AppLocalizations l10n) async {
    await tester.enterText(
      find.ancestor(
        of: find.text(l10n.accountNameHint),
        matching: find.byType(TextFormField),
      ),
      'Wallet',
    );
    await tester.enterText(
      find.ancestor(
        of: find.text(l10n.initialBalanceHint),
        matching: find.byType(TextFormField),
      ),
      '100',
    );

    // The currency field is keyed by the selected code, so before a selection
    // it is reachable by the placeholder key and nothing else. The dialog body
    // scrolls, so the field has to be brought into view before it can be hit.
    final currencyField = find.byKey(const Key('no_currency'));
    await tester.ensureVisible(currencyField);
    await tester.pumpAndSettle();
    // The field itself is behind an AbsorbPointer - the tap is meant for the
    // GestureDetector above it, so the hit-test warning is expected. That the
    // gesture arrived is asserted below rather than assumed.
    await tester.tap(currencyField, warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text(_usd.name));
    await tester.pumpAndSettle();

    // The picker rebuilds the field under the selected code. Without this the
    // tests below could pass on a tap that never landed, with the validator
    // firing because no currency was chosen at all.
    expect(find.byKey(const Key('USD')), findsOneWidget);
  }

  Future<void> tapSave(WidgetTester tester, AppLocalizations l10n) async {
    await tester.tap(find.text(l10n.saveButton));
    await tester.pumpAndSettle();
  }

  testWidgets('a currency with no designation marks the currency field '
      'instead of leaving Save inert', (tester) async {
    final l10n = await loadL10n();
    await openDialog(
      tester,
      designations: const [], // USD exists, its designation row does not.
      accountTypes: const [_cash],
    );

    await fillForm(tester, l10n);
    await tapSave(tester, l10n);

    expect(
      find.text(l10n.formValidationPleaseSelectCurrency),
      findsOneWidget,
      reason: 'the field the guard is stopping the save on must be named',
    );
    expect(accountsBloc.events, isEmpty);
    expect(
      find.byType(AddAccountDialog),
      findsOneWidget,
      reason: 'a rejected save must leave the dialog open to be corrected',
    );
  });

  testWidgets('a currency with a designation saves and closes', (tester) async {
    final l10n = await loadL10n();
    await openDialog(
      tester,
      designations: const [_usdDesignation],
      accountTypes: const [_cash],
    );

    // Nothing to complain about: no message on screen before Save is pressed.
    expect(find.text(l10n.formValidationPleaseSelectAccountType), findsNothing);

    await fillForm(tester, l10n);
    await tapSave(tester, l10n);

    final event = accountsBloc.events.single;
    expect(event, isA<AddAccount>());
    final account = (event as AddAccount).account;
    expect(account.name, 'Wallet');
    expect(account.balance, 100);
    expect(account.currencyCode, 'USD');
    expect(account.currencyDesignationId, _usdDesignation.id);
    expect(account.accountTypeId, _cash.id);
    expect(find.byType(AddAccountDialog), findsNothing);
  });

  testWidgets('no account types to auto-assign says so on screen', (
    tester,
  ) async {
    final l10n = await loadL10n();
    await openDialog(
      tester,
      designations: const [_usdDesignation],
      accountTypes: const [],
    );

    // The picker itself stays hidden - there is nothing to pick from. What the
    // user gets instead is the reason the dialog cannot be submitted.
    expect(
      find.text(l10n.formValidationPleaseSelectAccountType),
      findsOneWidget,
    );

    await fillForm(tester, l10n);
    await tapSave(tester, l10n);

    expect(accountsBloc.events, isEmpty);
    expect(find.byType(AddAccountDialog), findsOneWidget);
    expect(
      find.text(l10n.formValidationPleaseSelectAccountType),
      findsOneWidget,
    );
  });
}
