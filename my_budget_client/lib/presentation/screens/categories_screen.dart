import 'package:flutter/material.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
import 'package:my_budget_client/core/utils/dialog_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/presentation/widgets/budget_icon.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';
import 'package:collection/collection.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
// Both bloc libraries export ToggleSelectionMode, ClearSelection,
// ActiveDateChanged and DatePeriodNavigated, and every use of those names on
// this screen belongs to the categories bloc.
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart'
    show AccountsBloc, AccountsLoadSuccess, AccountsState;
import 'package:my_budget_client/presentation/blocs/categories/categories_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency/currency_bloc.dart'
    show CurrencyBloc;
import 'package:my_budget_client/presentation/widgets/add_account_dialog.dart';
import 'package:my_budget_client/presentation/widgets/category_grid.dart';
import 'package:my_budget_client/presentation/widgets/category_list_item.dart';
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/category_with_total.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';
import 'package:my_budget_client/presentation/widgets/delete_category_dialog.dart';
import 'package:my_budget_client/presentation/widgets/generic/generic_filter_app_bar.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/core/theme/pane_layout.dart';
import 'package:my_budget_client/presentation/widgets/account_list_item.dart'
    show kContentMaxWidth, kFabScrollBottomInset;

import 'package:my_budget_client/presentation/widgets/calendar_step_picker.dart';
import 'package:my_budget_client/presentation/widgets/category_filter_dialog.dart';
import 'package:my_budget_client/presentation/widgets/single_select_dialog.dart';
import 'package:my_budget_client/presentation/widgets/icon_selection_dialog.dart';
import 'package:my_budget_client/presentation/widgets/multi_level_tooltip.dart';
import 'package:my_budget_client/presentation/widgets/screen_shortcuts.dart';

/// Settings key holding which of the two category views is on screen.
///
/// It lives in settings rather than in screen state because the choice is a
/// preference, not a step in a task: reopening the app and finding the list
/// back would undo it every time.
const String kCategoriesViewModeSetting = 'categories_view_mode';

/// The grid is opt-in; anything other than `grid` (including nothing saved
/// yet) means the list every existing user already has.
bool categoriesGridViewEnabled(SettingsState state) =>
    state.settings[kCategoriesViewModeSetting] == 'grid';

class CategoriesScreen extends StatefulWidget {
  final bool isStandalone;
  const CategoriesScreen({super.key, this.isStandalone = true});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<CategoriesBloc>().add(LoadCategories());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<CategoriesBloc>().add(LoadMoreCategories());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  /// The original one-row-per-category view.
  Widget _buildCategoryList(
    BuildContext context, {
    required CategoriesBloc bloc,
    required CategoriesLoadSuccess successState,
    required List<CategoryWithTotal> filteredCategories,
    required List<CategoryWithTotal> topLevelCategories,
  }) {
    return ListView.builder(
      controller: _scrollController,
      // Room for the FAB that floats over this list: 56dp of button, its 16dp
      // margin, and 16dp so the last row reads as a row rather than as
      // something half-hidden.
      padding: const EdgeInsets.only(bottom: kFabScrollBottomInset),
      itemCount: successState.hasReachedMax
          ? topLevelCategories.length
          : topLevelCategories.length + 1,
      itemBuilder: (context, index) {
        if (index >= topLevelCategories.length) {
          return const Center(child: CircularProgressIndicator());
        }
        final categoryWithTotal = topLevelCategories[index];
        final category = categoryWithTotal.category;
        final isSelected = successState.selectedCategoryIds.contains(
          category.id,
        );

        return CategoryListItem(
          key: ValueKey(category.id),
          categoryWithTotal: categoryWithTotal,
          allCategoriesWithTotals: filteredCategories,
          isSelected: isSelected,
          onTap: (tappedCategory) {
            if (successState.isSelectionModeActive) {
              bloc.add(ToggleCategorySelection(tappedCategory.id!));
            } else {
              _navigateToAddTransaction(context, tappedCategory);
            }
          },
          onLongPressStart: (details) {
            if (successState.isSelectionModeActive) {
              bloc.add(ToggleCategorySelection(category.id!));
            } else {
              _showContextMenu(
                context,
                details.globalPosition,
                category,
                successState,
              );
            }
          },
          onSecondaryTapUp: (details) {
            _showContextMenu(
              context,
              details.globalPosition,
              category,
              successState,
            );
          },
          mainCurrencyCode: successState.mainCurrencyCode,
          currencyDesignations: successState.currencyDesignations,
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(
    BuildContext context,
    CategoriesBloc bloc,
    List<String> categoryIds, {
    VoidCallback? onConfirm,
  }) {
    final l10n = context.l10n;
    DialogUtils.showAppDialog(
      context: context,
      resizeToAvoidBottomInset: false,
      child: AlertDialog(
        title: Text(l10n.deleteCategoriesConfirmationTitle(categoryIds.length)),
        content: Text(l10n.deleteCategoriesConfirmationMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () {
              if (onConfirm != null) {
                onConfirm();
              } else {
                bloc.add(DeleteMultipleCategories(categoryIds));
              }
              Navigator.of(context, rootNavigator: true).pop();
            },
            child: Text(l10n.deleteButton),
          ),
        ],
      ),
    );
  }

  void _showChangeCategoryTypeDialog(
    BuildContext context,
    CategoriesBloc bloc,
    List<String> categoryIds,
  ) {
    final l10n = context.l10n;
    CategoryType? selectedType = CategoryType.expense;
    DialogUtils.showAppDialog(
      context: context,
      resizeToAvoidBottomInset: false,
      child: StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(l10n.changeCategoryTypeDialogTitle),
            content: DropdownButton<CategoryType>(
              value: selectedType,
              onChanged: (newValue) {
                setState(() {
                  selectedType = newValue;
                });
              },
              items: CategoryType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.toString().split('.').last),
                    ),
                  )
                  .toList(),
            ),
            actions: [
              TextButton(
                child: Text(l10n.cancelButton),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: Text(l10n.categoriesChangeButton),
                onPressed: () {
                  if (selectedType != null) {
                    bloc.add(
                      UpdateCategoryTypeForMultipleCategories(
                        categoryIds,
                        selectedType!,
                      ),
                    );
                  }
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      ),
    );
  }

  /// True once the accounts have actually loaded and there are none.
  ///
  /// Every other [AccountsState] reports no accounts while the load is still
  /// running, so treating that as "no accounts" everywhere would refuse the
  /// first taps of a normal launch.
  ///
  /// The unfiltered count, not `state.accounts`: that list is the accounts
  /// screen's page after its type/currency/name filter, and the form's account
  /// picker is fed from the whole table. Reading it refused the form whenever a
  /// filter left the accounts grid empty.
  static bool _hasNoAccounts(AccountsState state) =>
      state is AccountsLoadSuccess && state.unfilteredAccountCount == 0;

  /// Says which prerequisite is missing and offers to create it.
  ///
  /// The alternative is what this screen used to do: push a form whose required
  /// Account picker reads the same empty list, so it can be opened but never
  /// saved and Back is the only exit.
  void _refuseWithoutAccount(BuildContext context) {
    final l10n = context.l10n;

    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.addAccountBeforeTransactionDescription),
          action: SnackBarAction(
            label: l10n.accountsAddTooltip,
            // The SnackBar outlives the row that was tapped, so the screen's own
            // context is what opens the dialog.
            onPressed: () {
              if (!mounted) return;
              _showAddAccountDialog(this.context);
            },
          ),
        ),
      );
  }

  /// Account creation, on the root navigator: the dialog is a sibling of this
  /// screen rather than a descendant, so it has to be handed the blocs itself.
  void _showAddAccountDialog(BuildContext context) {
    DialogUtils.showAppDialog(
      context: context,
      resizeToAvoidBottomInset: false,
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<AccountsBloc>()),
          BlocProvider.value(value: context.read<CurrencyBloc>()),
          BlocProvider.value(value: context.read<StylesBloc>()),
        ],
        child: const AddAccountDialog(),
      ),
    );
  }

  void _navigateToAddTransaction(BuildContext context, Category category) {
    // The category is the one that was tapped, but a transaction also needs an
    // account and nothing seeds one.
    if (_hasNoAccounts(context.read<AccountsBloc>().state)) {
      _refuseWithoutAccount(context);
      return;
    }

    final state = context.read<CategoriesBloc>().state;
    DateTime date = DateTime.now();
    String currencyCode = 'EUR';

    if (state is CategoriesLoadSuccess) {
      date = state.activeDate;
      currencyCode = state.mainCurrencyCode;
    }

    final transaction = Transaction(
      id: '',
      description: '',
      amount: 0,
      date: date,
      accountId: '',
      categoryId: category.id!,
      currencyCode: currencyCode,
    );

    context.push(
      AppRoutes.addEditTransaction,
      extra: {'transaction': transaction},
    );
  }

  void _showContextMenu(
    BuildContext context,
    Offset position,
    Category category,
    CategoriesLoadSuccess state,
  ) async {
    final bloc = context.read<CategoriesBloc>();
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final isSelected = state.selectedCategoryIds.contains(category.id);

    final l10n = context.l10n;
    final value = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
        Offset.zero & overlay.size,
      ),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem(
          value: 'add_transaction',
          child: Text(l10n.contextMenuAddTransaction),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'select',
          child: Text(
            isSelected ? l10n.contextMenuDeselect : l10n.contextMenuSelect,
          ),
        ),
        PopupMenuItem(
          value: 'select_all',
          child: Text(l10n.contextMenuSelectAll),
        ),
        if (state.selectedCategoryIds.isNotEmpty)
          PopupMenuItem(
            value: 'deselect_all',
            child: Text(l10n.contextMenuDeselectAll),
          ),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'edit', child: Text(l10n.contextMenuEdit)),
        PopupMenuItem(value: 'delete', child: Text(l10n.contextMenuDelete)),
        PopupMenuItem(
          value: 'change_type',
          child: Text(l10n.contextMenuChangeType),
        ),
      ],
    );

    if (!context.mounted || value == null) return;
    final selectedIds = state.selectedCategoryIds.toList();

    if (value == 'add_transaction') {
      _navigateToAddTransaction(context, category);
    } else if (value == 'select') {
      if (!state.isSelectionModeActive) {
        bloc.add(const ToggleSelectionMode(true));
      }
      bloc.add(ToggleCategorySelection(category.id!));
    } else if (value == 'select_all') {
      if (!state.isSelectionModeActive) {
        bloc.add(const ToggleSelectionMode(true));
      }
      bloc.add(SelectAllCategories());
    } else if (value == 'deselect_all') {
      bloc.add(ClearSelection());
    } else if (value == 'edit') {
      _showAddEditCategoryDialog(
        context,
        category: category,
        allCategories: state.allCategories,
      );
    } else if (value == 'delete') {
      if (isSelected && state.selectedCategoryIds.length > 1) {
        _showDeleteConfirmationDialog(context, bloc, selectedIds);
      } else {
        _showDeleteConfirmationDialog(context, bloc, [
          category.id!,
        ], onConfirm: () => bloc.add(DeleteCategory(category.id!)));
      }
    } else if (value == 'change_type') {
      _showChangeCategoryTypeDialog(
        context,
        bloc,
        isSelected ? selectedIds : [category.id!],
      );
    }
  }

  void _showEmptyAreaContextMenu(BuildContext context, Offset position) async {
    final state = context.read<CategoriesBloc>().state;
    if (state is! CategoriesLoadSuccess) return;

    final l10n = context.l10n;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final value = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
        Offset.zero & overlay.size,
      ),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem(
          value: 'add_category',
          child: Row(
            children: [
              const Icon(Icons.add),
              const SizedBox(width: 8),
              Flexible(child: Text(l10n.addCategoryDescription)),
            ],
          ),
        ),
      ],
    );

    if (!context.mounted || value == null) return;

    if (value == 'add_category') {
      _showAddEditCategoryDialog(context, allCategories: state.allCategories);
    }
  }

  /// The loaded list an app bar action may act on, or null while the screen
  /// shows nothing but the spinner or the load-failure message.
  ///
  /// Read from the bloc at press time rather than captured, because a hotkey
  /// callback outlives the build that registered it: the list it acts on has to
  /// be the one the user is looking at now, not the one that happened to be
  /// current when the callback was created.
  /// `CategoryDeletionConfirmationNeeded` is unwrapped rather than rejected,
  /// the way `build` unwraps it to paint the app bars: while the delete dialog
  /// is up - or after it is cancelled, which dispatches nothing and leaves the
  /// bloc in that state - every button is still on screen, and a guard that
  /// dropped them there would make them dead to the eye.
  static CategoriesLoadSuccess? _loadedState(BuildContext context) {
    final state = context.read<CategoriesBloc>().state;
    final success = state is CategoryDeletionConfirmationNeeded
        ? state.lastSuccessState
        : state;
    return success is CategoriesLoadSuccess ? success : null;
  }

  /// The state a selection action may act on, or null when the selection app
  /// bar that carries its button is not on screen.
  static CategoriesLoadSuccess? _activeSelection(BuildContext context) {
    final state = _loadedState(context);
    return state != null && state.isSelectionModeActive ? state : null;
  }

  /// Runs [body] on the loaded list, for the date app bar's view controls.
  ///
  /// They are not selection actions and take no selection guard - the date
  /// picker, the sort toggle and the filter dialog are offered whether or not
  /// anything is selected. What they do need is the state itself: the date to
  /// open the calendar on, the sort to flip, the filters to seed the dialog.
  /// None of that exists before the first load, and the hot keys screen offers
  /// the three ids unconditionally, so the binding is live over the spinner too.
  void _runViewAction(
    BuildContext context,
    void Function(CategoriesLoadSuccess state) body,
  ) {
    final state = _loadedState(context);
    if (state != null) body(state);
  }

  // The four methods below are the bodies of the selection app bar's buttons,
  // shared with the hotkeys of the same name so the two can never drift apart.
  //
  // Each opens with the selection guard, which is free for the buttons - they
  // only exist while the selection app bar is up - and load-bearing for the
  // keys, because the hot keys screen offers these ids unconditionally and the
  // binding therefore stays live over the plain date app bar and the loading
  // spinner, where none of the buttons is on screen.

  /// Leaves selection mode.
  void _closeSelection(BuildContext context) {
    if (_activeSelection(context) == null) return;
    context.read<CategoriesBloc>().add(const ToggleSelectionMode(false));
  }

  /// Selects every category, or clears the selection once it already holds all
  /// of them - the same condition the button swaps its icon on.
  void _toggleSelectAll(BuildContext context) {
    final state = _activeSelection(context);
    if (state == null) return;
    final allCount = state.categoriesWithTotals.length;
    final isAllSelected =
        state.selectedCategoryIds.length == allCount && allCount > 0;
    context.read<CategoriesBloc>().add(
      isAllSelected ? ClearSelection() : SelectAllCategories(),
    );
  }

  /// Asks about deleting the whole selection.
  ///
  /// The empty-selection check is not an extra restriction: the app bar hides
  /// this button at `selectedCount == 0`, and a confirmation offering to delete
  /// nothing is what the key would otherwise open.
  void _deleteSelection(BuildContext context) {
    final state = _activeSelection(context);
    if (state == null || state.selectedCategoryIds.isEmpty) return;
    _showDeleteConfirmationDialog(
      context,
      context.read<CategoriesBloc>(),
      state.selectedCategoryIds.toList(),
    );
  }

  /// Retypes the whole selection; hidden alongside delete while nothing is
  /// selected.
  void _changeSelectionType(BuildContext context) {
    final state = _activeSelection(context);
    if (state == null || state.selectedCategoryIds.isEmpty) return;
    _showChangeCategoryTypeDialog(
      context,
      context.read<CategoriesBloc>(),
      state.selectedCategoryIds.toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<CategoriesBloc>();
    return MultiBlocListener(
      listeners: [
        BlocListener<CategoriesBloc, CategoriesState>(
          listener: (context, state) {
            if (state is CategoryDeletionConfirmationNeeded) {
              DialogUtils.showAppDialog(
                context: context,
                resizeToAvoidBottomInset: false,
                child: BlocProvider.value(
                  value: context.read<CategoriesBloc>(),
                  child: DeleteCategoryDialog(
                    categoryToDelete: state.categoryToDelete,
                    allCategories: state.allCategories,
                  ),
                ),
              );
            }
          },
        ),
        BlocListener<CategoriesBloc, CategoriesState>(
          listenWhen: (previous, current) {
            final prevError = previous is CategoriesLoadSuccess
                ? previous.error
                : null;
            final currError = current is CategoriesLoadSuccess
                ? current.error
                : null;
            return prevError != currError && currError != null;
          },
          listener: (context, state) {
            // A bulk operation can fail after deleting or updating part of the
            // selection, so the list stays on screen and only the message is
            // new - a full-screen failure would hide categories that are still
            // there.
            final error = state is CategoriesLoadSuccess ? state.error : null;
            if (error == null) return;
            ScaffoldMessenger.of(context)
              ..removeCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(l10n.importErrorLabel(error))),
              );
          },
        ),
        BlocListener<CategoriesBloc, CategoriesState>(
          listenWhen: (previous, current) {
            final prevDelete = previous is CategoriesLoadSuccess
                ? previous.recentlyDeletedCategory
                : null;
            final currDelete = current is CategoriesLoadSuccess
                ? current.recentlyDeletedCategory
                : null;
            return prevDelete != currDelete && currDelete != null;
          },
          listener: (context, state) {
            final recentlyDeleted = state is CategoriesLoadSuccess
                ? state.recentlyDeletedCategory
                : null;
            if (recentlyDeleted != null) {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              scaffoldMessenger.removeCurrentSnackBar();

              scaffoldMessenger
                  .showSnackBar(
                    SnackBar(
                      showCloseIcon: true,
                      closeIconColor: Colors.white,
                      duration: const Duration(seconds: 4),
                      content: Text(
                        l10n.itemDeletedMessage(recentlyDeleted.name),
                      ),
                      action: SnackBarAction(
                        label: l10n.undoButton,
                        onPressed: () {
                          context.read<CategoriesBloc>().add(
                            const UndoDeleteCategory(),
                          );
                        },
                      ),
                    ),
                  )
                  .closed
                  .then((reason) {
                    if (context.mounted &&
                        reason != SnackBarClosedReason.action) {
                      context.read<CategoriesBloc>().add(
                        const ClearRecentlyDeletedCategory(),
                      );
                    }
                  });
            }
          },
        ),
      ],
      child: ScreenShortcuts(
        actions: {
          'add_action': () {
            final state = context.read<CategoriesBloc>().state;
            CategoriesLoadSuccess? successState;
            if (state is CategoriesLoadSuccess) {
              successState = state;
            } else if (state is CategoryDeletionConfirmationNeeded) {
              successState = state.lastSuccessState;
            }
            if (successState != null) {
              _showAddEditCategoryDialog(
                context,
                allCategories: successState.allCategories,
              );
            }
          },
          'prev_period': () =>
              context.read<CategoriesBloc>().add(const DatePeriodNavigated(-1)),
          'next_period': () =>
              context.read<CategoriesBloc>().add(const DatePeriodNavigated(1)),
          // The selection app bar's four buttons, reached by key. Without these
          // entries ScreenShortcuts builds no binding at all for the ids, so
          // the key the hot keys screen let the user pick did nothing.
          'categories_selection_close': () => _closeSelection(context),
          'categories_selection_all': () => _toggleSelectAll(context),
          'categories_selection_delete': () => _deleteSelection(context),
          'categories_selection_change_type': () =>
              _changeSelectionType(context),
          // The date app bar's own three controls. Their ids are
          // screen-agnostic, like prev_period and add_action above: every list
          // screen carries the same three buttons, and only the focused
          // screen's ScreenShortcuts sees the key event.
          'pick_date': () => _runViewAction(
            context,
            (state) => _showCategoriesCalendar(context, state),
          ),
          'sort_order': () => _runViewAction(
            context,
            (state) =>
                _toggleCategoriesSort(context.read<CategoriesBloc>(), state),
          ),
          'filter_action': () => _runViewAction(
            context,
            (state) => showCategoryFilterDialog(context, state.filters),
          ),
        },
        child: Scaffold(
          appBar: widget.isStandalone
              ? PreferredSize(
                  // The pane, not the window: the rail takes ~73dp off the
                  // left, so the two disagree across the whole 600-742dp band
                  // and this bar sized itself for the layout it was not
                  // building.
                  preferredSize: Size.fromHeight(
                    context.isCompactPane
                        ? kToolbarHeight * 1.8
                        : kToolbarHeight,
                  ),
                  child: BlocBuilder<CategoriesBloc, CategoriesState>(
                    builder: (context, state) {
                      CategoriesLoadSuccess? successState;
                      if (state is CategoriesLoadSuccess) {
                        successState = state;
                      } else if (state is CategoryDeletionConfirmationNeeded) {
                        successState = state.lastSuccessState;
                      }

                      if (successState != null) {
                        if (successState.isSelectionModeActive) {
                          return _SelectionAppBar(
                            state: successState,
                            onClose: () => _closeSelection(context),
                            onSelectAll: () => _toggleSelectAll(context),
                            onDelete: () => _deleteSelection(context),
                            onChangeType: () => _changeSelectionType(context),
                          );
                        }
                        return _CategoriesDateAppBar(state: successState);
                      }
                      return AppBar(
                        title: Text(context.l10n.categoriesAppBarTitle),
                      );
                    },
                  ),
                )
              : null,
          body: BlocBuilder<CategoriesBloc, CategoriesState>(
            builder: (context, state) {
              if (state is CategoriesLoadInProgress) {
                return const Center(child: CircularProgressIndicator());
              }

              final successState = state is CategoriesLoadSuccess
                  ? state
                  : (state is CategoryDeletionConfirmationNeeded
                        ? state.lastSuccessState
                        : null);

              if (successState != null) {
                if (successState.categoriesWithTotals.isEmpty) {
                  return Center(child: Text(context.l10n.noCategoriesCreated));
                }

                final filteredCategories = successState.filters.type == null
                    ? successState.categoriesWithTotals
                    : successState.categoriesWithTotals
                          .where(
                            (c) => c.category.type == successState.filters.type,
                          )
                          .toList();

                final topLevelCategories = filteredCategories
                    .where((c) => c.category.parentId == null)
                    .toList();

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onSecondaryTapUp: (details) => _showEmptyAreaContextMenu(
                    context,
                    details.globalPosition,
                  ),
                  onLongPressStart: (details) => _showEmptyAreaContextMenu(
                    context,
                    details.globalPosition,
                  ),
                  // The GestureDetector stays full-bleed so a right-click in
                  // the desktop margin still opens the empty-area menu; only
                  // the content column is capped, centred, the same way
                  // settings_screen.dart does it.
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: kContentMaxWidth,
                      ),
                      child: BlocBuilder<SettingsBloc, SettingsState>(
                        buildWhen: (previous, current) =>
                            categoriesGridViewEnabled(previous) !=
                            categoriesGridViewEnabled(current),
                        builder: (context, settingsState) {
                          if (categoriesGridViewEnabled(settingsState)) {
                            return CategoryGrid(
                              topLevelCategories: topLevelCategories,
                              allCategoriesWithTotals: filteredCategories,
                              selectedCategoryIds: successState
                                  .selectedCategoryIds
                                  .toSet(),
                              mainCurrencyCode: successState.mainCurrencyCode,
                              currencyDesignations:
                                  successState.currencyDesignations,
                              controller: _scrollController,
                              isLoadingMore: !successState.hasReachedMax,
                              // Same FAB clearance as the list below.
                              padding: const EdgeInsets.only(
                                left: 12,
                                right: 12,
                                bottom: kFabScrollBottomInset,
                              ),
                              onTap: (tappedCategory) {
                                if (successState.isSelectionModeActive) {
                                  bloc.add(
                                    ToggleCategorySelection(tappedCategory.id!),
                                  );
                                } else {
                                  _navigateToAddTransaction(
                                    context,
                                    tappedCategory,
                                  );
                                }
                              },
                              onContextMenu: (category, position) =>
                                  _showContextMenu(
                                    context,
                                    position,
                                    category,
                                    successState,
                                  ),
                            );
                          }
                          return _buildCategoryList(
                            context,
                            bloc: bloc,
                            successState: successState,
                            filteredCategories: filteredCategories,
                            topLevelCategories: topLevelCategories,
                          );
                        },
                      ),
                    ),
                  ),
                );
              }
              return Center(child: Text(context.l10n.accountsLoadFailure));
            },
          ),
          floatingActionButton: BlocBuilder<CategoriesBloc, CategoriesState>(
            builder: (context, state) {
              CategoriesLoadSuccess? successState;
              if (state is CategoriesLoadSuccess) {
                successState = state;
              } else if (state is CategoryDeletionConfirmationNeeded) {
                successState = state.lastSuccessState;
              }

              if (successState != null && successState.isSelectionModeActive) {
                return const SizedBox.shrink();
              }
              return MultiLevelTooltip(
                message: l10n.addCategoryTooltip,
                actionId: 'add_action',
                description: l10n.addCategoryDescription,
                child: FloatingActionButton(
                  onPressed: () {
                    final state = context.read<CategoriesBloc>().state;
                    CategoriesLoadSuccess? successState;
                    if (state is CategoriesLoadSuccess) {
                      successState = state;
                    } else if (state is CategoryDeletionConfirmationNeeded) {
                      successState = state.lastSuccessState;
                    }
                    if (successState != null) {
                      _showAddEditCategoryDialog(
                        context,
                        allCategories: successState.allCategories,
                      );
                    }
                  },
                  child: const Icon(Icons.add),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showAddEditCategoryDialog(
    BuildContext context, {
    Category? category,
    required List<Category> allCategories,
  }) {
    DialogUtils.showAppDialog(
      context: context,
      resizeToAvoidBottomInset: false,
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: BlocProvider.of<CategoriesBloc>(context)),
          BlocProvider.value(value: BlocProvider.of<StylesBloc>(context)),
        ],
        child: AddEditCategoryDialog(
          category: category,
          allCategories: allCategories,
        ),
      ),
    );
  }
}

class _CategoriesDateAppBar extends StatelessWidget {
  final CategoriesLoadSuccess state;

  const _CategoriesDateAppBar({required this.state});

  String _formatDate(BuildContext context, CategoriesLoadSuccess state) {
    if (state.filterMode == FilterMode.range) {
      if (state.activeDateRange == null) return context.l10n.selectDateTooltip;
      final start = MaterialLocalizations.of(
        context,
      ).formatShortDate(state.activeDateRange!.start);
      final end = MaterialLocalizations.of(
        context,
      ).formatShortDate(state.activeDateRange!.end);
      return '$start - $end';
    }

    switch (state.dateStep) {
      case DateStep.day:
        return MaterialLocalizations.of(
          context,
        ).formatShortDate(state.activeDate);
      case DateStep.month:
        return MaterialLocalizations.of(
          context,
        ).formatMonthYear(state.activeDate);
      case DateStep.year:
        return state.activeDate.year.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CategoriesBloc>();
    final l10n = context.l10n;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    // The pane the bar is drawn into, not the whole window: the desktop branch
    // of this Row is unbounded and overflows the moment the two disagree.
    final isMobile = context.isCompactPane;
    // Chevrons are direction, not decoration: "previous" points at the start
    // edge, which is the right-hand one under RTL. Same glyph-swap the rail's
    // collapse button uses (adaptive_scaffold.dart).
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    final centerWidget = Row(
      mainAxisAlignment: isMobile
          ? MainAxisAlignment.spaceBetween
          : MainAxisAlignment.center,
      mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
      children: [
        MultiLevelTooltip(
          message: context.l10n.previousPeriodTooltip,
          actionId: 'prev_period',
          description: context.l10n.previousPeriodDescription,
          child: IconButton(
            icon: Icon(
              isRtl ? Icons.chevron_right : Icons.chevron_left,
              color: onSurface,
            ),
            onPressed: () => bloc.add(const DatePeriodNavigated(-1)),
          ),
        ),
        if (isMobile)
          MultiLevelTooltip(
            message: context.l10n.filterTooltip,
            actionId: 'filter_action',
            description: context.l10n.filterCategoriesDescription,
            child: IconButton(
              icon: Icon(Icons.tune, color: onSurface),
              onPressed: () => showCategoryFilterDialog(context, state.filters),
            ),
          )
        else if (!isMobile) ...[
          MultiLevelTooltip(
            message: l10n.filterTooltip,
            actionId: 'filter_action',
            description: l10n.filterCategoriesDescription,
            child: IconButton(
              icon: Icon(Icons.tune, color: onSurface),
              onPressed: () => showCategoryFilterDialog(context, state.filters),
            ),
          ),
        ],
        if (!isMobile) const SizedBox(width: 8),
        Expanded(
          flex: isMobile ? 1 : 0,
          child: MultiLevelTooltip(
            message: l10n.selectDateTooltip,
            actionId: 'pick_date',
            description: context.l10n.selectDateDescription,
            child: InkWell(
              onTap: () => _showCategoriesCalendar(context, state),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                alignment: Alignment.center,
                child: Text(
                  _formatDate(context, state),
                  style: TextStyle(
                    color: onSurface,
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: isMobile ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (isMobile)
          MultiLevelTooltip(
            message: context.l10n.sortOrderTooltip,
            actionId: 'sort_order',
            description: context.l10n.sortOrderDescription,
            child: RotatedBox(
              quarterTurns: state.filters.sort == Sort.ascending ? 2 : 0,
              child: IconButton(
                icon: Icon(Icons.sort, color: onSurface),
                onPressed: () => _toggleCategoriesSort(bloc, state),
              ),
            ),
          )
        else if (!isMobile) ...[
          const SizedBox(width: 8),
        ],
        if (!isMobile) ...[
          const SizedBox(width: 8),
          MultiLevelTooltip(
            message: l10n.sortOrderTooltip,
            actionId: 'sort_order',
            description: l10n.sortOrderDescription,
            child: RotatedBox(
              quarterTurns: state.filters.sort == Sort.ascending ? 2 : 0,
              child: IconButton(
                icon: Icon(Icons.sort, color: onSurface),
                onPressed: () => _toggleCategoriesSort(bloc, state),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        MultiLevelTooltip(
          message: l10n.nextPeriodTooltip,
          actionId: 'next_period',
          description: l10n.nextPeriodDescription,
          child: IconButton(
            icon: Icon(
              isRtl ? Icons.chevron_left : Icons.chevron_right,
              color: onSurface,
            ),
            onPressed: () => bloc.add(const DatePeriodNavigated(1)),
          ),
        ),
      ],
    );

    return GenericFilterAppBar(
      centerWidget: centerWidget,
      totalCountText: l10n.totalCountLabel(
        state.categoriesWithTotals.length.toString(),
      ),
      actions: const [_ViewModeToggle()],
    );
  }
}

/// Switches the categories screen between the list and the picker grid.
class _ViewModeToggle extends StatelessWidget {
  const _ViewModeToggle();

  /// Key for the toggle, so a test can drive it without depending on which of
  /// the two icons is currently showing.
  static const ValueKey<String> toggleKey = ValueKey<String>(
    'categories-view-mode-toggle',
  );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (previous, current) =>
          categoriesGridViewEnabled(previous) !=
          categoriesGridViewEnabled(current),
      builder: (context, settingsState) {
        final isGrid = categoriesGridViewEnabled(settingsState);
        return IconButton(
          key: toggleKey,
          // The icon shows what tapping gets you, not what you are looking at.
          icon: Icon(
            isGrid ? Icons.view_list : Icons.grid_view,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          tooltip: isGrid
              ? context.l10n.categoriesListViewTooltip
              : context.l10n.categoriesGridViewTooltip,
          onPressed: () => context.read<SettingsBloc>().add(
            UpdateSetting(kCategoriesViewModeSetting, isGrid ? 'list' : 'grid'),
          ),
        );
      },
    );
  }
}

class _SelectionAppBar extends StatelessWidget {
  final CategoriesLoadSuccess state;

  /// Every button's body lives on the screen state, because the hotkey of the
  /// same name has to run that identical body.
  final VoidCallback onClose;
  final VoidCallback onSelectAll;
  final VoidCallback onDelete;
  final VoidCallback onChangeType;

  const _SelectionAppBar({
    required this.state,
    required this.onClose,
    required this.onSelectAll,
    required this.onDelete,
    required this.onChangeType,
  });

  @override
  Widget build(BuildContext context) {
    final selectedCount = state.selectedCategoryIds.length;
    final allCount = state.categoriesWithTotals.length;
    final isAllSelected = selectedCount == allCount && allCount > 0;

    final l10n = context.l10n;
    return AppBar(
      leading: MultiLevelTooltip(
        message: l10n.closeSelectionTooltip,
        actionId: 'categories_selection_close',
        description: l10n.exitSelectionDescription,
        child: IconButton(icon: const Icon(Icons.close), onPressed: onClose),
      ),
      title: Text(l10n.selectedCountLabel(selectedCount.toString())),
      actions: [
        MultiLevelTooltip(
          message: isAllSelected
              ? l10n.contextMenuDeselectAll
              : l10n.contextMenuSelectAll,
          actionId: 'categories_selection_all',
          description: isAllSelected
              ? l10n.contextMenuDeselectAll
              : l10n.contextMenuSelectAll,
          child: IconButton(
            icon: Icon(
              isAllSelected
                  ? Icons.deselect_outlined
                  : Icons.select_all_outlined,
            ),
            onPressed: onSelectAll,
          ),
        ),
        if (selectedCount > 0) ...[
          MultiLevelTooltip(
            message: l10n.contextMenuDelete,
            actionId: 'categories_selection_delete',
            description: l10n.deleteCategoriesConfirmationMessage,
            child: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: onDelete,
            ),
          ),
          MultiLevelTooltip(
            message: l10n.contextMenuChangeType,
            actionId: 'categories_selection_change_type',
            description: l10n.changeCategoryTypeDialogTitle,
            child: IconButton(
              icon: const Icon(Icons.drive_file_rename_outline),
              onPressed: onChangeType,
            ),
          ),
        ],
      ],
    );
  }
}

// The date picker and the sort toggle are driven from the date app bar, but the
// hot keys screen offers both as bindable actions and the ScreenShortcuts that
// has to run them sits on _CategoriesScreenState, which _CategoriesDateAppBar
// cannot reach. Hoisting the bodies to the top level lets the button and the
// key call one implementation instead of two that drift apart. The filter
// button needs no equivalent: `showCategoryFilterDialog` is already one shared
// function, and both call sites use it.
void _showCategoriesCalendar(
  BuildContext context,
  CategoriesLoadSuccess state,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      return BlocProvider.value(
        value: context.read<CategoriesBloc>(),
        child: CalendarStepPicker(
          initialDate: state.activeDate,
          initialRange: null,
          initialStep: state.dateStep,
          initialFilterMode: FilterMode.date,
          rangeOptionVisibility: PickerVisibility.hidden,
          onApply: (date, range, step, mode) {
            final bloc = context.read<CategoriesBloc>();
            if (state.dateStep != step) {
              bloc.add(DateStepChanged(step));
            }
            bloc.add(ActiveDateChanged(date));
          },
        ),
      );
    },
  );
}

void _toggleCategoriesSort(CategoriesBloc bloc, CategoriesLoadSuccess state) {
  bloc.add(
    SortChanged(
      state.filters.sort == Sort.ascending ? Sort.descending : Sort.ascending,
    ),
  );
}

class AddEditCategoryDialog extends StatefulWidget {
  final Category? category;
  final List<Category> allCategories;

  const AddEditCategoryDialog({
    super.key,
    this.category,
    required this.allCategories,
  });

  @override
  State<AddEditCategoryDialog> createState() => _AddEditCategoryDialogState();
}

class _AddEditCategoryDialogState extends State<AddEditCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  String? _selectedStyleId;
  String? _selectedParentId;
  CategoryType _selectedCategoryType = CategoryType.expense;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name);
    _selectedStyleId = widget.category?.styleId;
    _selectedParentId = widget.category?.parentId;
    _selectedCategoryType = widget.category?.type ?? CategoryType.expense;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;
      if (widget.category == null) {
        context.read<CategoriesBloc>().add(
          AddCategory(
            Category(
              name: name,
              styleId: _selectedStyleId,
              type: _selectedCategoryType,
              parentId: _selectedParentId,
            ),
          ),
        );
      } else {
        context.read<CategoriesBloc>().add(
          UpdateCategory(
            widget.category!.copyWith(
              name: name,
              styleId: _selectedStyleId,
              type: _selectedCategoryType,
              parentId: _selectedParentId,
            ),
          ),
        );
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(
        widget.category == null
            ? l10n.addCategoryTooltip
            : l10n.contextMenuEdit,
      ),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 250),
          child: SizedBox(
            width: double.maxFinite,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: l10n.categoryNameLabel,
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? l10n.formValidationPleaseEnterName
                        : null,
                  ),
                  BlocBuilder<StylesBloc, StylesState>(
                    builder: (context, state) {
                      if (state is StylesLoadSuccess) {
                        return GestureDetector(
                          onTap: () async {
                            final selectedIconId =
                                await showIconSelectionDialog(
                                  context,
                                  _selectedStyleId,
                                );
                            if (mounted && selectedIconId != null) {
                              setState(() {
                                _selectedStyleId = selectedIconId;
                              });
                            }
                          },
                          child: AbsorbPointer(
                            child: TextFormField(
                              key: Key(_selectedStyleId ?? 'no_style'),
                              initialValue:
                                  state.styles
                                      .firstWhereOrNull(
                                        (s) => s.id == _selectedStyleId,
                                      )
                                      ?.name ??
                                  l10n.selectIconSubtitle,
                              decoration: InputDecoration(
                                labelText: l10n.styleLabel,
                                prefixIcon: _selectedStyleId != null
                                    ? BlocBuilder<StylesBloc, StylesState>(
                                        builder: (context, stylesState) {
                                          if (stylesState
                                              is StylesLoadSuccess) {
                                            final style = stylesState.styles
                                                .firstWhereOrNull(
                                                  (s) =>
                                                      s.id == _selectedStyleId,
                                                );
                                            if (style != null) {
                                              return Padding(
                                                padding: const EdgeInsets.all(
                                                  8.0,
                                                ),
                                                child: BudgetIcon(
                                                  style: style,
                                                  radius: 12,
                                                ),
                                              );
                                            }
                                          }
                                          return const Icon(Icons.style);
                                        },
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  GestureDetector(
                    onTap: () async {
                      final selectedParent =
                          await showSingleSelectDialog<Category>(
                            context: context,
                            items: widget.allCategories,
                            title: l10n.parentCategoryLabel,
                            selectedItem: widget.allCategories.firstWhereOrNull(
                              (c) => c.id == _selectedParentId,
                            ),
                            itemBuilder: (category) => Row(
                              children: [
                                BlocBuilder<StylesBloc, StylesState>(
                                  builder: (context, stylesState) {
                                    if (stylesState is StylesLoadSuccess) {
                                      final style = stylesState.styles
                                          .firstWhereOrNull(
                                            (s) => s.id == category.styleId,
                                          );
                                      if (style != null) {
                                        return BudgetIcon(
                                          style: style,
                                          radius: 15,
                                        );
                                      }
                                    }
                                    return const Icon(Icons.category);
                                  },
                                ),
                                const SizedBox(width: 8),
                                Text(category.name),
                              ],
                            ),
                            stringGetter: (category) => category.name,
                          );
                      if (mounted) {
                        setState(() {
                          _selectedParentId = selectedParent?.id;
                        });
                      }
                    },
                    child: AbsorbPointer(
                      child: TextFormField(
                        key: Key(_selectedParentId ?? 'no_parent'),
                        initialValue:
                            widget.allCategories
                                .firstWhereOrNull(
                                  (c) => c.id == _selectedParentId,
                                )
                                ?.name ??
                            l10n.noneLabel,
                        decoration: InputDecoration(
                          labelText: l10n.parentCategoryLabel,
                          prefixIcon: _selectedParentId != null
                              ? BlocBuilder<StylesBloc, StylesState>(
                                  builder: (context, stylesState) {
                                    if (stylesState is StylesLoadSuccess) {
                                      final parentCategory = widget
                                          .allCategories
                                          .firstWhereOrNull(
                                            (c) => c.id == _selectedParentId,
                                          );
                                      if (parentCategory != null) {
                                        final style = stylesState.styles
                                            .firstWhereOrNull(
                                              (s) =>
                                                  s.id ==
                                                  parentCategory.styleId,
                                            );
                                        if (style != null) {
                                          return Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: BudgetIcon(
                                              style: style,
                                              radius: 12,
                                            ),
                                          );
                                        }
                                      }
                                    }
                                    return const Icon(Icons.category);
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final selectedType =
                          await showSingleSelectDialog<CategoryType>(
                            context: context,
                            items: CategoryType.values,
                            title: l10n.typeLabel,
                            selectedItem: _selectedCategoryType,
                            itemBuilder: (type) =>
                                Text(type.toString().split('.').last),
                            stringGetter: (type) =>
                                type.toString().split('.').last,
                          );
                      if (mounted && selectedType != null) {
                        setState(() {
                          _selectedCategoryType = selectedType;
                        });
                      }
                    },
                    child: AbsorbPointer(
                      child: TextFormField(
                        key: Key(_selectedCategoryType.toString()),
                        initialValue: _selectedCategoryType
                            .toString()
                            .split('.')
                            .last,
                        decoration: InputDecoration(labelText: l10n.typeLabel),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        FilledButton.tonal(onPressed: _onSave, child: Text(l10n.saveButton)),
      ],
    );
  }
}
