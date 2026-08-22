// Half of the presentation layer used to be hardcoded English, so a user on any
// of the other nine locales got an app that was half translated. A confirmation
// nobody can read is the one place where a missing translation costs data, so
// these pump the destructive dialogs and a Data tab empty state under
// `Locale('ru')` and assert the Russian strings - not the English ones - are on
// screen.
//
// The expected text is read from the `ru` delegate rather than pasted in, but
// each case also pins the literal Russian: an ARB file that still carried the
// English string as a placeholder would satisfy the delegate lookup and fail
// here, which is the whole point of the sweep.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/asset_data.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/presentation/blocs/asset/asset_bloc.dart';
import 'package:my_budget_client/presentation/blocs/asset/asset_event.dart';
import 'package:my_budget_client/presentation/blocs/asset/asset_state.dart';
import 'package:my_budget_client/presentation/widgets/asset_tab_app_bar.dart';
import 'package:my_budget_client/presentation/widgets/asset_view.dart';
import 'package:my_budget_client/presentation/widgets/delete_account_dialog.dart';

import '../test_app.dart';

const _ru = Locale('ru');

class _MockAssetBloc extends MockBloc<AssetEvent, AssetState>
    implements AssetBloc {}

/// `MockBloc` stubs `add` into a no-op, which is what keeps these tests about
/// the widget - but a Delete button that reads correctly and dispatches nothing
/// is exactly as broken as one nobody can read, so `add` is overridden to keep
/// the events. (The dev_dependency is mockito, so there is no `verify(() =>)`.)
class _RecordingAssetBloc extends MockBloc<AssetEvent, AssetState>
    implements AssetBloc {
  final events = <AssetEvent>[];

  @override
  void add(AssetEvent event) => events.add(event);
}

Account _account(String id, String name) => Account(
  id: id,
  name: name,
  balance: 0,
  currencyCode: 'EUR',
  currencyDesignationId: 'd1',
  accountTypeId: 't1',
  creationDate: DateTime(2025),
);

AssetDataDomain _asset(String id, String name) => AssetDataDomain(
  id: id,
  assetId: name,
  name: name,
  date: DateTime(2025, 3),
  value: 100,
  source: 'manual',
);

void main() {
  testWidgets('the account delete confirmation is readable in ru', (
    tester,
  ) async {
    final l10n = await loadL10n(_ru);
    final accountsBloc = MockAccountsBloc();
    whenListen(
      accountsBloc,
      const Stream<AccountsState>.empty(),
      initialState: AccountsInitial(),
    );
    final target = _account('a1', 'Наличные');

    await pumpAppWidget(
      tester,
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => DeleteAccountDialog(
              accountToDelete: target,
              allAccounts: [target, _account('a2', 'Карта')],
            ),
          ),
          child: const Text('open'),
        ),
      ),
      locale: _ru,
      surfaceSize: const Size(1200, 1600),
      // The dialog is a sibling of `home` under the app's Navigator, so the
      // bloc it reads has to be provided above the MaterialApp.
      aboveApp: (app) => wrapWithBlocs(app, accountsBloc: accountsBloc),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text(l10n.deleteAccountConfirmTitle('Наличные')), findsOne);
    expect(find.text('Удалить Наличные?'), findsOne);
    expect(find.text(l10n.deleteAccountMessage), findsOne);
    expect(find.text(l10n.deleteAccountReassign), findsOne);
    expect(find.text(l10n.deleteAccountDeleteAll), findsOne);
    expect(find.text(l10n.deleteAccountNewAccount), findsOne);

    // The two buttons matter most: this is the last thing between the user and
    // a destructive write.
    expect(find.widgetWithText(TextButton, 'Отмена'), findsOne);
    expect(find.widgetWithText(FilledButton, 'Удалить'), findsOne);
    expect(find.text('Cancel'), findsNothing);
    expect(find.text('Delete'), findsNothing);
  });

  testWidgets(
    'the asset delete confirmation is readable in ru and still fires',
    (tester) async {
      final l10n = await loadL10n(_ru);
      final bloc = _RecordingAssetBloc();
      final selected = {_asset('a1', 'BTC'), _asset('a2', 'ETH')};
      whenListen(
        bloc,
        const Stream<AssetState>.empty(),
        initialState: AssetState(
          status: AssetStatus.success,
          activeDate: DateTime(2025, 3),
          assetData: selected.toList(),
          selectedAssets: selected,
          isSelectionModeActive: true,
          totalCount: 2,
        ),
      );

      await pumpAppWidget(
        tester,
        BlocProvider<AssetBloc>.value(
          value: bloc,
          child: Scaffold(appBar: AssetTabAppBar(state: bloc.state)),
        ),
        locale: _ru,
        wrapInScaffold: false,
        surfaceSize: const Size(1200, 1600),
        aboveApp: (app) =>
            wrapWithBlocs(app, settingsBloc: createSettingsBloc()),
      );

      expect(find.text(l10n.selectedCountLabel(2)), findsOne);

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      expect(find.text('Удалить активы?'), findsOne);
      expect(find.text(l10n.assetDeleteConfirmTitle), findsOne);
      expect(find.text(l10n.assetDeleteConfirmMessage(2)), findsOne);
      expect(find.text('Delete Selected Assets?'), findsNothing);

      await tester.tap(find.widgetWithText(TextButton, 'Удалить'));
      await tester.pumpAndSettle();

      expect(
        bloc.events.whereType<DeleteSelectedAssets>(),
        isNotEmpty,
        reason:
            'a confirmation that reads correctly but deletes nothing is '
            'still broken',
      );
    },
  );

  testWidgets('the asset empty state is readable in ru', (tester) async {
    final l10n = await loadL10n(_ru);
    final bloc = _MockAssetBloc();
    whenListen(
      bloc,
      const Stream<AssetState>.empty(),
      initialState: AssetState(
        status: AssetStatus.success,
        activeDate: DateTime(2025, 3),
      ),
    );

    await pumpAppWidget(
      tester,
      BlocProvider<AssetBloc>.value(
        value: bloc,
        child: AssetView(onEdit: (_) {}),
      ),
      locale: _ru,
    );

    expect(find.text('Активы не найдены.'), findsOne);
    expect(find.text(l10n.assetNoAssetsFound), findsOne);
    expect(find.text('No assets found.'), findsNothing);
  });
}
