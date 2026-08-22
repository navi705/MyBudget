// A decimal typed on a comma keyboard has to reach the form as a number.
//
// `TextInputType.numberWithOptions(decimal: true)` draws whichever separator
// the DEVICE locale uses, so a phone set to Russian, German or French offers
// a comma and nothing else. Every balance and threshold field then read the
// text back through `double.parse`/`double.tryParse`, which only accept a dot:
// "1000,50" was rejected as "not a valid number" on the very keyboard the app
// asked for. The transaction amount fields already normalised the separator as
// the user typed; the account, filter, asset and rate fields did not.
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

void main() {
  late _RecordingAccountsBloc accountsBloc;

  setUp(() => accountsBloc = _RecordingAccountsBloc());

  Future<void> openDialog(WidgetTester tester) async {
    whenListen(
      accountsBloc,
      const Stream<AccountsState>.empty(),
      initialState: AccountsLoadSuccess(
        accounts: const [],
        accountTypes: const [_cash],
        hasReachedMax: true,
        totalCount: 0,
        activeDate: DateTime(2025, 3, 15),
        exchangeRates: const [],
      ),
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
          state: const CurrencyLoadSuccess(
            currencies: [_usd],
            designations: [_usdDesignation],
          ),
        ),
        stylesBloc: createStylesBloc(),
        accountsBloc: accountsBloc,
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  /// Fills the dialog the way the existing suite does, with [balance] typed
  /// into the balance field exactly as given.
  Future<void> fillForm(
    WidgetTester tester,
    AppLocalizations l10n,
    String balance,
  ) async {
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
      balance,
    );

    final currencyField = find.byKey(const Key('no_currency'));
    await tester.ensureVisible(currencyField);
    await tester.pumpAndSettle();
    await tester.tap(currencyField, warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('${_usd.name} (${_usd.code})'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('USD')), findsOneWidget);
  }

  testWidgets('a balance typed with a comma saves as that number', (
    tester,
  ) async {
    final l10n = await loadL10n();
    await openDialog(tester);

    await fillForm(tester, l10n, '1000,50');
    await tester.tap(find.text(l10n.saveButton));
    await tester.pumpAndSettle();

    expect(
      find.text(l10n.formValidationPleaseEnterValidNumber),
      findsNothing,
      reason: 'the separator the keyboard offered cannot be the invalid one',
    );
    final event = accountsBloc.events.single;
    expect(event, isA<AddAccount>());
    expect((event as AddAccount).account.balance, 1000.5);
  });

  testWidgets('a balance typed with a dot still saves as that number', (
    tester,
  ) async {
    // The normalisation has to accept the separator it was already accepting.
    final l10n = await loadL10n();
    await openDialog(tester);

    await fillForm(tester, l10n, '1000.50');
    await tester.tap(find.text(l10n.saveButton));
    await tester.pumpAndSettle();

    expect((accountsBloc.events.single as AddAccount).account.balance, 1000.5);
  });

  testWidgets('a negative balance is still typeable', (tester) async {
    // A credit card is the reason the field asks for a signed keyboard; a
    // filter that strips everything but digits and the separator would take
    // that away.
    final l10n = await loadL10n();
    await openDialog(tester);

    await fillForm(tester, l10n, '-40,25');
    await tester.tap(find.text(l10n.saveButton));
    await tester.pumpAndSettle();

    expect((accountsBloc.events.single as AddAccount).account.balance, -40.25);
  });
}
