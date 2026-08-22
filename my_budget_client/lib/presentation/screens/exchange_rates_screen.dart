import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/core/utils/date_display.dart';
import 'package:my_budget_client/core/di/injection_container.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/currency_designation.dart';
import 'package:my_budget_client/presentation/blocs/exchange_rates/exchange_rates_bloc.dart';
import 'package:my_budget_client/presentation/widgets/generic/generic_filter_app_bar.dart';
import 'package:my_budget_client/presentation/widgets/calendar_step_picker.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/presentation/widgets/multi_select_dialog.dart';
import 'package:my_budget_client/presentation/widgets/multi_level_tooltip.dart';
import 'package:my_budget_client/presentation/widgets/screen_shortcuts.dart';

class ExchangeRatesScreen extends StatelessWidget {
  final bool isStandalone;
  const ExchangeRatesScreen({super.key, this.isStandalone = true});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<ExchangeRatesBloc>()..add(const LoadExchangeRates()),
      child: _ExchangeRatesView(isStandalone: isStandalone),
    );
  }
}

class _ExchangeRatesView extends StatefulWidget {
  final bool isStandalone;
  const _ExchangeRatesView({this.isStandalone = true});

  @override
  State<_ExchangeRatesView> createState() => _ExchangeRatesViewState();
}

class _ExchangeRatesViewState extends State<_ExchangeRatesView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<ExchangeRatesBloc>().add(const LoadExchangeRates());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  void _showEmptyAreaContextMenu(BuildContext context, Offset position) async {
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
          value: 'add_rate',
          child: Row(
            children: [
              const Icon(Icons.add),
              const SizedBox(width: 8),
              Flexible(child: Text(context.l10n.exchAddExchangeRate)),
            ],
          ),
        ),
      ],
    );

    if (!context.mounted || value == null) return;

    if (value == 'add_rate') {
      _showAddEditExchangeRateDialog(context);
    }
  }

  void _navigate(ExchangeRatesBloc bloc, ExchangeRatesState state, int i) {
    if (state.filterMode == FilterMode.range) return;

    DateTime newDate = state.activeDate;
    if (state.dateStep == DateStep.day) {
      newDate = newDate.add(Duration(days: i));
    } else if (state.dateStep == DateStep.month) {
      newDate = DateTime(newDate.year, newDate.month + i, newDate.day);
    } else if (state.dateStep == DateStep.year) {
      newDate = DateTime(newDate.year + i, newDate.month, newDate.day);
    }
    bloc.add(ChangeExchangeRatesActiveDate(newDate));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ExchangeRatesBloc, ExchangeRatesState>(
      // A failed add/edit/delete used to close its dialog over an unchanged
      // list and say nothing. The body can only report a failure while the
      // list is empty, so anything else has to come through here.
      listenWhen: (previous, current) =>
          current.error != null &&
          current.error != previous.error &&
          current.exchangeRates.isNotEmpty,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(context.l10n.importErrorLabel('${state.error}')),
            ),
          );
      },
      builder: (context, state) {
        final body = _buildBody(context, state);
        final bloc = context.read<ExchangeRatesBloc>();

        return ScreenShortcuts(
          actions: {
            'add_action': () => _showAddEditExchangeRateDialog(context),
            'prev_period': () => _navigate(bloc, state, -1),
            'next_period': () => _navigate(bloc, state, 1),
            // The date, sort and filter controls of the app bar. Their ids are
            // screen-agnostic, like prev_period and add_action above: every
            // screen carries the same three buttons, and only the focused
            // screen's ScreenShortcuts sees the key event.
            'pick_date': () => _showExchangeRatesCalendar(context, state),
            'sort_order': () => _toggleExchangeRatesSort(bloc, state),
            'filter_action': () =>
                _showExchangeRatesFilterDialog(context, state),
            // Selection actions only while the selection bar is on screen.
            // Without the guard, "close" would fire a state change nothing
            // asked for and "select all" would fill a selection the user
            // cannot see, let alone clear.
            'exchange_rates_selection_close': () {
              if (state.isSelectionModeActive) {
                bloc.add(const ToggleSelectionMode(false));
              }
            },
            'exchange_rates_selection_all': () {
              if (state.isSelectionModeActive) {
                bloc.add(const SelectAllExchangeRates());
              }
            },
            'exchange_rates_selection_delete': () {
              if (state.isSelectionModeActive &&
                  state.selectedExchangeRates.isNotEmpty) {
                _showDeleteConfirmation(
                  context,
                  bloc,
                  state.selectedExchangeRates.length,
                );
              }
            },
            'exchange_rates_selection_change_preset': () {
              if (state.isSelectionModeActive &&
                  state.selectedExchangeRates.isNotEmpty) {
                _showBulkPresetUpdate(context, bloc);
              }
            },
          },
          child: Scaffold(
            appBar: _buildAppBar(context, state),
            body: body,
            floatingActionButton: MultiLevelTooltip(
              message: context.l10n.exchAddExchangeRate,
              actionId: 'add_action',
              description: context.l10n.exchAddRateDescription,
              child: FloatingActionButton(
                onPressed: () => _showAddEditExchangeRateDialog(context),
                child: const Icon(Icons.add),
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ExchangeRatesState state,
  ) {
    if (state.isSelectionModeActive) {
      // Capture the bloc here to pass it to the dialogs
      final bloc = context.read<ExchangeRatesBloc>();
      return _SelectionAppBar(
        selectionCount: state.selectedExchangeRates.length,
        totalCount: state.exchangeRates.length,
        onClearSelection: () {
          if (state.selectedExchangeRates.isNotEmpty) {
            bloc.add(const ClearSelection());
          } else {
            bloc.add(const ToggleSelectionMode(false));
          }
        },
        onSelectAll: () {
          final isAllSelected =
              state.selectedExchangeRates.length ==
                  state.exchangeRates.length &&
              state.exchangeRates.isNotEmpty;
          if (isAllSelected) {
            bloc.add(const ClearSelection());
          } else {
            bloc.add(const SelectAllExchangeRates());
          }
        },
        onDelete: () => _showDeleteConfirmation(
          context,
          bloc,
          state.selectedExchangeRates.length,
        ),
        onChangePreset: () => _showBulkPresetUpdate(context, bloc),
      );
    }
    return _ExchangeRatesDateAppBar(state: state);
  }

  Widget _buildBody(BuildContext context, ExchangeRatesState state) {
    if (state.status == ExchangeRatesStatus.loading &&
        state.exchangeRates.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    // Only take the whole screen when there is nothing else to show: a failed
    // edit must not hide the rates the user still has.
    if (state.status == ExchangeRatesStatus.failure &&
        state.exchangeRates.isEmpty) {
      return Center(
        child: Text(context.l10n.importErrorLabel('${state.error}')),
      );
    }
    if (state.exchangeRates.isEmpty &&
        state.status == ExchangeRatesStatus.success) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onSecondaryTapUp: (details) =>
            _showEmptyAreaContextMenu(context, details.globalPosition),
        onLongPressStart: (details) =>
            _showEmptyAreaContextMenu(context, details.globalPosition),
        child: Center(child: Text(context.l10n.exchNoRatesFound)),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapUp: (details) =>
          _showEmptyAreaContextMenu(context, details.globalPosition),
      onLongPressStart: (details) =>
          _showEmptyAreaContextMenu(context, details.globalPosition),
      // No itemExtent: 88dp left the ListTile only 72dp after the card margins,
      // which its title + subtitle outgrow once the system font scale passes
      // ~1.4. Letting the rows measure themselves costs a little scroll-extent
      // precision but never clips the text.
      child: ListView.builder(
        controller: _scrollController,
        itemCount: state.hasReachedMax
            ? state.exchangeRates.length
            : state.exchangeRates.length + 1,
        itemBuilder: (context, index) {
          if (index >= state.exchangeRates.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          final rate = state.exchangeRates[index];
          final isSelected = state.selectedExchangeRates.contains(rate);
          return _ExchangeRateListItem(
            rate: rate,
            isSelected: isSelected,
            isSelectionMode: state.isSelectionModeActive,
            designations: state.designations,
            onSecondaryTapUp: (details) =>
                _showContextMenu(context, details, rate, state),
            onTap: () =>
                _showAddEditExchangeRateDialog(context, existingRate: rate),
          );
        },
      ),
    );
  }

  Future<void> _showContextMenu(
    BuildContext context,
    TapUpDetails details,
    ExchangeRateDomain rate,
    ExchangeRatesState state,
  ) async {
    final bloc = context.read<ExchangeRatesBloc>();
    final isSelected = state.selectedExchangeRates.contains(rate);

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    final value = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTRB(
          details.globalPosition.dx,
          details.globalPosition.dy,
          details.globalPosition.dx,
          details.globalPosition.dy,
        ),
        Offset.zero & overlay.size,
      ),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem(
          value: 'select',
          child: Text(
            isSelected
                ? context.l10n.contextMenuDeselect
                : context.l10n.selectButton,
          ),
        ),
        PopupMenuItem(
          value: 'select_all',
          child: Text(context.l10n.selectAllButton),
        ),
        if (state.selectedExchangeRates.isNotEmpty)
          PopupMenuItem(
            value: 'deselect_all',
            child: Text(context.l10n.deselectAllButton),
          ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'change_preset',
          child: Text(context.l10n.exchChangePreset),
        ),
        PopupMenuItem(value: 'delete', child: Text(context.l10n.deleteButton)),
      ],
    );

    if (!mounted || value == null) return;

    if (value == 'select') {
      if (!state.isSelectionModeActive) {
        bloc.add(const ToggleSelectionMode(true));
      }
      bloc.add(ToggleExchangeRateSelection(rate));
    } else if (value == 'select_all') {
      if (!state.isSelectionModeActive) {
        bloc.add(const ToggleSelectionMode(true));
      }
      bloc.add(const SelectAllExchangeRates());
    } else if (value == 'deselect_all') {
      bloc.add(const ClearSelection());
    } else if (value == 'change_preset') {
      // If not selected, select it first for the action
      if (!isSelected) {
        if (!state.isSelectionModeActive) {
          bloc.add(const ToggleSelectionMode(true));
        }
        bloc.add(ToggleExchangeRateSelection(rate));
      }
      // Small delay to let selection update propagate if needed
      await Future.delayed(const Duration(milliseconds: 50));
      if (context.mounted) _showBulkPresetUpdate(context, bloc);
    } else if (value == 'delete') {
      if (!isSelected) {
        if (!state.isSelectionModeActive) {
          bloc.add(const ToggleSelectionMode(true));
        }
        bloc.add(ToggleExchangeRateSelection(rate));
      }
      await Future.delayed(const Duration(milliseconds: 50));
      if (context.mounted) {
        // We need to get the latest count, but state here is stale from the closure.
        // We can read the bloc's current state.
        final currentCount = bloc.state.selectedExchangeRates.length;
        _showDeleteConfirmation(context, bloc, currentCount);
      }
    }
  }

  void _showAddEditExchangeRateDialog(
    BuildContext context, {
    ExchangeRateDomain? existingRate,
  }) {
    final bloc = context.read<ExchangeRatesBloc>();
    final currencies = bloc.state.currencies;

    String fromCurrency = existingRate?.fromCurrencyCode ?? 'EUR';
    String? toCurrency = existingRate?.toCurrencyCode;
    final rateController = TextEditingController(
      text: existingRate != null ? existingRate.rate.toString() : '',
    );
    final presetController = TextEditingController(
      text: existingRate != null ? existingRate.preset.toString() : '1',
    );
    DateTime selectedDate = existingRate?.date ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          Widget buildCurrencySelector(
            String label,
            String? selectedCode,
            ValueChanged<String?> onChanged,
          ) {
            final selectedCurrency = selectedCode != null
                ? currencies.where((c) => c.code == selectedCode).firstOrNull
                : null;

            final displayText = selectedCurrency != null
                ? '${selectedCurrency.name} (${selectedCurrency.code})'
                : context.l10n.selectCurrencyTitle;

            return ListTile(
              title: Text(label),
              subtitle: Text(displayText),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                final results = await showDialog<List<String>>(
                  context: context,
                  builder: (context) => MultiSelectDialog<Currency, String>(
                    items: currencies,
                    selectedIds: selectedCode != null ? [selectedCode] : [],
                    itemBuilder: (c) => Text('${c.name} (${c.code})'),
                    idGetter: (c) => c.code,
                    stringGetter: (c) => '${c.name} ${c.code}',
                    isSingleSelect: true,
                  ),
                );
                if (results != null && results.isNotEmpty) {
                  onChanged(results.first);
                }
              },
            );
          }

          return AlertDialog(
            title: Text(
              existingRate == null
                  ? context.l10n.exchAddExchangeRate
                  : context.l10n.exchEditExchangeRate,
            ),
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 250),
                child: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      buildCurrencySelector(
                        context.l10n.exchFromCurrency,
                        fromCurrency,
                        (val) => setState(() => fromCurrency = val!),
                      ),
                      const SizedBox(height: 8),
                      buildCurrencySelector(
                        context.l10n.exchToCurrency,
                        toCurrency,
                        (val) => setState(() => toCurrency = val),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: rateController,
                              decoration: InputDecoration(
                                labelText: context.l10n.exchRate,
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: presetController,
                              decoration: InputDecoration(
                                labelText: context.l10n.exchPresetIdLabel,
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        title: Text(
                          context.l10n.importDateLabel(
                            DateDisplay.short(context, selectedDate),
                          ),
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) setState(() => selectedDate = date);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.l10n.cancelButton),
              ),
              FilledButton.tonal(
                onPressed: () {
                  final rate = double.tryParse(rateController.text);
                  final preset = int.tryParse(presetController.text) ?? 1;
                  if (fromCurrency.isNotEmpty &&
                      toCurrency != null &&
                      rate != null) {
                    final newRate = ExchangeRateDomain(
                      fromCurrencyCode: fromCurrency,
                      toCurrencyCode: toCurrency!,
                      rate: rate,
                      date: selectedDate,
                      preset: preset,
                    );
                    if (existingRate == null) {
                      bloc.add(AddExchangeRate(newRate));
                    } else {
                      // Editing an existing rate: delete the original row and
                      // insert the new one so changing from/to/date/preset does
                      // not create a duplicate.
                      bloc.add(
                        UpdateExchangeRate(
                          originalExchangeRate: existingRate,
                          updatedExchangeRate: newRate,
                        ),
                      );
                    }
                    Navigator.pop(context);
                  }
                },
                child: Text(context.l10n.saveButton),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ExchangeRateListItem extends StatelessWidget {
  final ExchangeRateDomain rate;
  final bool isSelected;
  final bool isSelectionMode;
  final List<CurrencyDesignation> designations;
  final void Function(TapUpDetails)? onSecondaryTapUp;
  final VoidCallback? onTap;

  const _ExchangeRateListItem({
    required this.rate,
    required this.designations,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.onSecondaryTapUp,
    this.onTap,
  });

  void _handleTap(BuildContext context) {
    if (isSelectionMode) {
      context.read<ExchangeRatesBloc>().add(ToggleExchangeRateSelection(rate));
    } else {
      onTap?.call();
    }
  }

  void _handleLongPress(BuildContext context) {
    if (!isSelectionMode) {
      context.read<ExchangeRatesBloc>().add(const ToggleSelectionMode(true));
      context.read<ExchangeRatesBloc>().add(ToggleExchangeRateSelection(rate));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = theme.highlightColor;

    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      color: isSelected ? selectedColor : null,
      child: GestureDetector(
        onSecondaryTapUp: onSecondaryTapUp,
        child: ListTile(
          onTap: () => _handleTap(context),
          onLongPress: () => _handleLongPress(context),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20.0,
            vertical: 10.0,
          ),
          leading: isSelectionMode
              ? Checkbox(
                  value: isSelected,
                  onChanged: (value) => _handleTap(context),
                )
              : CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        designations
                                .where(
                                  (d) => d.currencyCode == rate.toCurrencyCode,
                                )
                                .firstOrNull
                                ?.value ??
                            rate.toCurrencyCode,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
          title: Text(
            '${rate.fromCurrencyCode} ➔ ${rate.toCurrencyCode}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Text(
            DateDisplay.short(context, rate.date),
            style: const TextStyle(fontSize: 14),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                rate.rate.toStringAsFixed(4),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              Text(
                context.l10n.exchPresetValue(rate.preset),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExchangeRatesDateAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final ExchangeRatesState state;

  const _ExchangeRatesDateAppBar({required this.state});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight * 1.5);

  String _formatDate(BuildContext context) {
    if (state.filterMode == FilterMode.range) {
      if (state.activeDateRange == null) return context.l10n.exchSelectRange;
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

  void _navigateInAppBar(BuildContext context, ExchangeRatesBloc bloc, int i) {
    if (state.filterMode == FilterMode.range) return;

    DateTime newDate = state.activeDate;
    if (state.dateStep == DateStep.day) {
      newDate = newDate.add(Duration(days: i));
    } else if (state.dateStep == DateStep.month) {
      newDate = DateTime(newDate.year, newDate.month + i, newDate.day);
    } else if (state.dateStep == DateStep.year) {
      newDate = DateTime(newDate.year + i, newDate.month, newDate.day);
    }
    bloc.add(ChangeExchangeRatesActiveDate(newDate));
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ExchangeRatesBloc>();
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final isMobile = MediaQuery.of(context).size.width < 600;

    final centerWidget = Row(
      mainAxisAlignment: isMobile
          ? MainAxisAlignment.spaceBetween
          : MainAxisAlignment.center,
      mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
      children: [
        MultiLevelTooltip(
          message: context.l10n.previousPeriodTooltip,
          actionId: 'prev_period',
          description: context.l10n.exchPreviousPeriodDescription,
          child: IconButton(
            icon: Icon(Icons.chevron_left, color: onSurface),
            onPressed: () => _navigateInAppBar(context, bloc, -1),
          ),
        ),
        if (isMobile)
          MultiLevelTooltip(
            message: context.l10n.filterTooltip,
            actionId: 'filter_action',
            description: context.l10n.exchFilterDescription,
            child: IconButton(
              icon: Icon(Icons.tune, color: onSurface),
              onPressed: () => _showExchangeRatesFilterDialog(context, state),
            ),
          )
        else if (!isMobile) ...[
          MultiLevelTooltip(
            message: context.l10n.filterTooltip,
            actionId: 'filter_action',
            description: context.l10n.exchFilterDescription,
            child: IconButton(
              icon: Icon(Icons.tune, color: onSurface),
              onPressed: () => _showExchangeRatesFilterDialog(context, state),
            ),
          ),
        ],
        if (!isMobile) const SizedBox(width: 8),
        Expanded(
          flex: isMobile ? 1 : 0,
          child: MultiLevelTooltip(
            message: context.l10n.selectDateTooltip,
            actionId: 'pick_date',
            description: context.l10n.exchSelectDateDescription,
            child: InkWell(
              onTap: () => _showExchangeRatesCalendar(context, state),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                alignment: Alignment.center,
                child: Text(
                  _formatDate(context),
                  // The four icon buttons eat most of the app bar on a phone, so
                  // a range like "01.08.2026 - 31.08.2026" would wrap to several
                  // lines inside a fixed kToolbarHeight box without this clamp.
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
            description: context.l10n.exchSortOrderDescription,
            child: RotatedBox(
              quarterTurns: state.sort == Sort.ascending ? 2 : 0,
              child: IconButton(
                icon: Icon(Icons.sort, color: onSurface),
                onPressed: () => _toggleExchangeRatesSort(bloc, state),
              ),
            ),
          )
        else if (!isMobile) ...[
          const SizedBox(width: 8),
        ],
        if (!isMobile) ...[
          const SizedBox(width: 8),
          MultiLevelTooltip(
            message: context.l10n.sortOrderTooltip,
            actionId: 'sort_order',
            description: context.l10n.exchSortOrderDescription,
            child: RotatedBox(
              quarterTurns: state.sort == Sort.ascending ? 2 : 0,
              child: IconButton(
                icon: Icon(Icons.sort, color: onSurface),
                onPressed: () => _toggleExchangeRatesSort(bloc, state),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        MultiLevelTooltip(
          message: context.l10n.nextPeriodTooltip,
          actionId: 'next_period',
          description: context.l10n.exchNextPeriodDescription,
          child: IconButton(
            icon: Icon(Icons.chevron_right, color: onSurface),
            onPressed: () => _navigateInAppBar(context, bloc, 1),
          ),
        ),
      ],
    );

    return GenericFilterAppBar(
      centerWidget: centerWidget,
      totalCountText: context.l10n.totalCountLabel(state.totalCount),
    );
  }
}

class _ExchangeRatesFilterDialog extends StatefulWidget {
  final ExchangeRatesState state;
  final CurrencyRepository repository;
  const _ExchangeRatesFilterDialog({
    required this.state,
    required this.repository,
  });

  @override
  State<_ExchangeRatesFilterDialog> createState() =>
      _ExchangeRatesFilterDialogState();
}

class _ExchangeRatesFilterDialogState
    extends State<_ExchangeRatesFilterDialog> {
  String? _fromCurrency;
  String? _toCurrency;
  List<int> _selectedPresets = [];
  List<int> _availablePresets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    debugPrint('UI: ExchangeRatesFilterDialog initState');
    _fromCurrency = widget.state.fromCurrencyFilter;
    _toCurrency = widget.state.toCurrencyFilter;
    _selectedPresets = List.from(widget.state.presetFilters);
    _loadPresets();
  }

  Future<void> _loadPresets() async {
    try {
      debugPrint('UI: _loadPresets called');
      final repo = widget.repository;
      final presets = await repo.getAvailablePresets();
      if (mounted) {
        setState(() {
          _availablePresets = presets;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      debugPrint('UI: Error loading presets: $e\n$stack');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.exchFilterExchangeRates),
      content: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCurrencySelector(
                  context,
                  context.l10n.exchFromCurrency,
                  _fromCurrency,
                  widget.state.currencies,
                  (val) => setState(() => _fromCurrency = val),
                ),
                const SizedBox(height: 16),
                _buildCurrencySelector(
                  context,
                  context.l10n.exchToCurrency,
                  _toCurrency,
                  widget.state.currencies,
                  (val) => setState(() => _toCurrency = val),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(context.l10n.presetsLabel),
                  subtitle: Text(
                    _selectedPresets.isEmpty
                        ? context.l10n.allLabel
                        : context.l10n.selectedCountLabel(
                            _selectedPresets.length,
                          ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    final results = await showDialog<List<int>>(
                      context: context,
                      builder: (context) => MultiSelectDialog<int, int>(
                        items: _availablePresets,
                        selectedIds: _selectedPresets,
                        itemBuilder: (item) => Text(item.toString()),
                        idGetter: (item) => item,
                        stringGetter: (item) => item.toString(),
                      ),
                    );
                    if (results != null) {
                      setState(() => _selectedPresets = results);
                    }
                  },
                ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _fromCurrency = null;
              _toCurrency = null;
              _selectedPresets = [];
            });
          },
          child: Text(context.l10n.clearButton),
        ),
        FilledButton(
          onPressed: () {
            context.read<ExchangeRatesBloc>().add(
              ChangeExchangeRatesFilters(
                fromCurrency: _fromCurrency,
                toCurrency: _toCurrency,
                presets: _selectedPresets.isEmpty ? null : _selectedPresets,
              ),
            );
            Navigator.pop(context);
          },
          child: Text(context.l10n.applyButton),
        ),
      ],
    );
  }

  Widget _buildCurrencySelector(
    BuildContext context,
    String label,
    String? selectedCode,
    List<Currency> currencies,
    ValueChanged<String?> onChanged,
  ) {
    final selectedCurrency = selectedCode != null
        ? currencies.where((c) => c.code == selectedCode).firstOrNull
        : null;

    final displayText = selectedCurrency != null
        ? '${selectedCurrency.name} (${selectedCurrency.code})'
        : context.l10n.allLabel;

    return ListTile(
      title: Text(label),
      subtitle: Text(displayText),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () async {
        final results = await showDialog<List<String>>(
          context: context,
          builder: (context) => MultiSelectDialog<Currency, String>(
            items: currencies,
            selectedIds: selectedCode != null ? [selectedCode] : [],
            itemBuilder: (c) => Text('${c.name} (${c.code})'),
            idGetter: (c) => c.code,
            stringGetter: (c) => '${c.name} ${c.code}',
            isSingleSelect: true,
          ),
        );
        if (results != null) {
          onChanged(results.isNotEmpty ? results.first : null);
        }
      },
    );
  }
}

class _SelectionAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int selectionCount;
  final int totalCount;
  final VoidCallback onClearSelection;
  final VoidCallback onSelectAll;
  final VoidCallback onDelete;
  final VoidCallback onChangePreset;

  const _SelectionAppBar({
    required this.selectionCount,
    required this.totalCount,
    required this.onClearSelection,
    required this.onSelectAll,
    required this.onDelete,
    required this.onChangePreset,
  });

  @override
  Widget build(BuildContext context) {
    final isAllSelected = selectionCount == totalCount && totalCount > 0;

    return AppBar(
      leading: MultiLevelTooltip(
        message: context.l10n.closeSelectionTooltip,
        actionId: 'exchange_rates_selection_close',
        description: context.l10n.exchExitSelectionDescription,
        child: IconButton(
          icon: const Icon(Icons.close),
          onPressed: onClearSelection,
        ),
      ),
      title: Text(context.l10n.selectedCountLabel(selectionCount)),
      actions: [
        MultiLevelTooltip(
          message: isAllSelected
              ? context.l10n.deselectAllButton
              : context.l10n.selectAllButton,
          actionId: 'exchange_rates_selection_all',
          description: isAllSelected
              ? context.l10n.exchDeselectAllDescription
              : context.l10n.exchSelectAllDescription,
          child: IconButton(
            icon: Icon(
              isAllSelected
                  ? Icons.deselect_outlined
                  : Icons.select_all_outlined,
            ),
            onPressed: onSelectAll,
          ),
        ),
        if (selectionCount > 0) ...[
          MultiLevelTooltip(
            message: context.l10n.exchChangePreset,
            actionId: 'exchange_rates_selection_change_preset',
            description: context.l10n.exchChangePresetDescription,
            child: IconButton(
              icon: const Icon(Icons.drive_file_rename_outline),
              onPressed: onChangePreset,
            ),
          ),
          MultiLevelTooltip(
            message: context.l10n.deleteSelectedButton,
            actionId: 'exchange_rates_selection_delete',
            description: context.l10n.exchDeleteSelectedDescription,
            child: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: onDelete,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// The date picker, the filter dialog and the sort toggle are driven from the
// date app bar, but the Hot Keys screen offers all three as bindable actions
// and the ScreenShortcuts that has to run them sits two classes above it.
// Hoisting the bodies to the top level - where this file already keeps the
// dialogs shared between the list and the selection bar - lets the button and
// the hotkey call one implementation instead of two that can drift apart.
void _showExchangeRatesCalendar(
  BuildContext context,
  ExchangeRatesState state,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      return BlocProvider.value(
        value: context.read<ExchangeRatesBloc>(),
        child: CalendarStepPicker(
          initialDate: state.activeDate,
          initialRange: state.activeDateRange,
          initialStep: state.dateStep,
          initialFilterMode: state.filterMode,
          rangeOptionVisibility: PickerVisibility.visible,
          onApply: (date, range, step, mode) {
            final bloc = context.read<ExchangeRatesBloc>();
            if (state.filterMode != mode) {
              bloc.add(ChangeExchangeRatesFilterMode(mode));
            }
            if (state.dateStep != step) {
              bloc.add(ChangeExchangeRatesDateStep(step));
            }
            if (mode == FilterMode.range && range != null) {
              bloc.add(ChangeExchangeRatesActiveDateRange(range));
            } else {
              bloc.add(ChangeExchangeRatesActiveDate(date));
            }
          },
        ),
      );
    },
  );
}

void _showExchangeRatesFilterDialog(
  BuildContext context,
  ExchangeRatesState state,
) {
  final repository = context.read<CurrencyRepository>();
  showDialog(
    context: context,
    builder: (_) => BlocProvider.value(
      value: context.read<ExchangeRatesBloc>(),
      child: _ExchangeRatesFilterDialog(state: state, repository: repository),
    ),
  );
}

void _toggleExchangeRatesSort(
  ExchangeRatesBloc bloc,
  ExchangeRatesState state,
) {
  bloc.add(
    ChangeExchangeRatesSort(
      state.sort == Sort.ascending ? Sort.descending : Sort.ascending,
    ),
  );
}

void _showDeleteConfirmation(
  BuildContext context,
  ExchangeRatesBloc bloc,
  int count,
) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.l10n.exchDeleteExchangeRatesTitle),
      content: Text(context.l10n.exchDeleteConfirmMessage(count)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.cancelButton),
        ),
        FilledButton(
          onPressed: () {
            bloc.add(const DeleteSelectedExchangeRates());
            Navigator.pop(context);
          },
          child: Text(context.l10n.deleteButton),
        ),
      ],
    ),
  );
}

void _showBulkPresetUpdate(BuildContext context, ExchangeRatesBloc bloc) {
  final presetController = TextEditingController(text: '1');
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.l10n.exchUpdatePresetTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.l10n.exchUpdatePresetMessage),
          const SizedBox(height: 16),
          TextField(
            controller: presetController,
            decoration: InputDecoration(
              labelText: context.l10n.exchPresetIdLabel,
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.cancelButton),
        ),
        FilledButton(
          onPressed: () {
            final newPreset = int.tryParse(presetController.text);
            if (newPreset != null) {
              bloc.add(UpdateSelectedExchangeRatesPreset(newPreset));
              Navigator.pop(context);
            }
          },
          child: Text(context.l10n.updateButton),
        ),
      ],
    ),
  );
}
