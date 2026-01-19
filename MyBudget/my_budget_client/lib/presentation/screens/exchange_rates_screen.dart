import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/core/di/injection_container.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/presentation/blocs/exchange_rates/exchange_rates_bloc.dart';
import 'package:my_budget_client/presentation/widgets/generic/generic_filter_app_bar.dart';
import 'package:my_budget_client/presentation/widgets/calendar_step_picker.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/presentation/widgets/multi_select_dialog.dart';

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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExchangeRatesBloc, ExchangeRatesState>(
      builder: (context, state) {
        final body = _buildBody(context, state);
        return Scaffold(
          appBar: _buildAppBar(context, state),
          body: body,
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddEditExchangeRateDialog(context),
            child: const Icon(Icons.add),
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
    if (state.status == ExchangeRatesStatus.failure) {
      return Center(child: Text('Error: ${state.error}'));
    }
    if (state.exchangeRates.isEmpty &&
        state.status == ExchangeRatesStatus.success) {
      return const Center(child: Text('No exchange rates found.'));
    }

    return ListView.builder(
      controller: _scrollController,
      itemExtent: 88.0,
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
          onSecondaryTapUp: (details) =>
              _showContextMenu(context, details, rate, state),
          onTap: () =>
              _showAddEditExchangeRateDialog(context, existingRate: rate),
        );
      },
    );
  }

  void _showContextMenu(
    BuildContext context,
    TapUpDetails details,
    ExchangeRateDomain rate,
    ExchangeRatesState state,
  ) {
    final bloc = context.read<ExchangeRatesBloc>();
    final isSelected = state.selectedExchangeRates.contains(rate);

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu(
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
          child: Text(isSelected ? 'Deselect' : 'Select'),
        ),
        const PopupMenuItem(value: 'select_all', child: Text('Select All')),
        if (state.selectedExchangeRates.isNotEmpty)
          const PopupMenuItem(
            value: 'deselect_all',
            child: Text('Deselect All'),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'change_preset',
          child: Text('Change Preset'),
        ),
        const PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    ).then((value) {
      if (!mounted) return;
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
        // Small delay to let selection update propagate if needed, though bloc is async.
        // For better UX, we might just pass the list directly if we had immediate state,
        // but here we rely on the bloc state.
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) _showBulkPresetUpdate(context, bloc);
        });
      } else if (value == 'delete') {
        if (!isSelected) {
          if (!state.isSelectionModeActive) {
            bloc.add(const ToggleSelectionMode(true));
          }
          bloc.add(ToggleExchangeRateSelection(rate));
        }
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            // We need to get the latest count, but state here is stale from the closure.
            // We can read the bloc's current state.
            final currentCount = bloc.state.selectedExchangeRates.length;
            _showDeleteConfirmation(context, bloc, currentCount);
          }
        });
      }
    });
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
                : 'Select Currency';

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
              existingRate == null ? 'Add Exchange Rate' : 'Edit Exchange Rate',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildCurrencySelector(
                    'From Currency',
                    fromCurrency,
                    (val) => setState(() => fromCurrency = val!),
                  ),
                  const SizedBox(height: 8),
                  buildCurrencySelector(
                    'To Currency',
                    toCurrency,
                    (val) => setState(() => toCurrency = val),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: rateController,
                          decoration: const InputDecoration(labelText: 'Rate'),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: presetController,
                          decoration: const InputDecoration(
                            labelText: 'Preset ID',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text(
                      'Date: ${DateFormat('dd.MM.yyyy').format(selectedDate)}',
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
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton.tonal(
                onPressed: () {
                  final rate = double.tryParse(rateController.text);
                  final preset = int.tryParse(presetController.text) ?? 1;
                  if (fromCurrency.isNotEmpty &&
                      toCurrency != null &&
                      rate != null) {
                    bloc.add(
                      AddExchangeRate(
                        ExchangeRateDomain(
                          fromCurrencyCode: fromCurrency,
                          toCurrencyCode: toCurrency!,
                          rate: rate,
                          date: selectedDate,
                          preset: preset,
                        ),
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save'),
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
  final void Function(TapUpDetails)? onSecondaryTapUp;
  final VoidCallback? onTap;

  const _ExchangeRateListItem({
    required this.rate,
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
                  child: Text(
                    rate.toCurrencyCode,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
          title: Text(
            '${rate.fromCurrencyCode} ➔ ${rate.toCurrencyCode}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Text(
            DateFormat('dd.MM.yyyy').format(rate.date),
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
                'Preset: ${rate.preset}',
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

  void _showCustomCalendar(BuildContext context) {
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

  String _formatDate(BuildContext context) {
    if (state.filterMode == FilterMode.range) {
      if (state.activeDateRange == null) return 'Select Range';
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

  void _navigate(ExchangeRatesBloc bloc, int i) {
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

    final centerWidget = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.tune, color: onSurface),
          tooltip: 'Filter',
          onPressed: () => _showFilterDialog(context),
        ),
        IconButton(
          icon: Icon(Icons.chevron_left, color: onSurface),
          onPressed: () => _navigate(bloc, -1),
        ),
        InkWell(
          onTap: () => _showCustomCalendar(context),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            alignment: Alignment.center,
            child: Text(
              _formatDate(context),
              style: TextStyle(color: onSurface, fontSize: 18),
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.chevron_right, color: onSurface),
          onPressed: () => _navigate(bloc, 1),
        ),
        const SizedBox(width: 24),
        RotatedBox(
          quarterTurns: state.sort == Sort.ascending ? 2 : 0,
          child: IconButton(
            icon: Icon(Icons.sort, color: onSurface),
            tooltip: 'Sort',
            onPressed: () {
              final newSort = state.sort == Sort.ascending
                  ? Sort.descending
                  : Sort.ascending;
              bloc.add(ChangeExchangeRatesSort(newSort));
            },
          ),
        ),
      ],
    );

    return GenericFilterAppBar(
      centerWidget: centerWidget,
      totalCountText: 'Total: ${state.totalCount}',
    );
  }

  void _showFilterDialog(BuildContext context) {
    final repository = context.read<CurrencyRepository>();
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<ExchangeRatesBloc>(),
        child: _ExchangeRatesFilterDialog(state: state, repository: repository),
      ),
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
    print('UI: ExchangeRatesFilterDialog initState');
    _fromCurrency = widget.state.fromCurrencyFilter;
    _toCurrency = widget.state.toCurrencyFilter;
    _selectedPresets = List.from(widget.state.presetFilters);
    _loadPresets();
  }

  Future<void> _loadPresets() async {
    try {
      print('UI: _loadPresets called');
      final repo = widget.repository;
      final presets = await repo.getAvailablePresets();
      if (mounted) {
        setState(() {
          _availablePresets = presets;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      print('UI: Error loading presets: $e\n$stack');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Exchange Rates'),
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
                  'From Currency',
                  _fromCurrency,
                  widget.state.currencies,
                  (val) => setState(() => _fromCurrency = val),
                ),
                const SizedBox(height: 16),
                _buildCurrencySelector(
                  context,
                  'To Currency',
                  _toCurrency,
                  widget.state.currencies,
                  (val) => setState(() => _toCurrency = val),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Presets'),
                  subtitle: Text(
                    _selectedPresets.isEmpty
                        ? 'All'
                        : '${_selectedPresets.length} selected',
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
          child: const Text('Clear'),
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
          child: const Text('Apply'),
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
        : 'All';

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
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: onClearSelection,
      ),
      title: Text('$selectionCount selected'),
      actions: [
        IconButton(
          icon: Icon(
            isAllSelected ? Icons.deselect_outlined : Icons.select_all_outlined,
          ),
          onPressed: onSelectAll,
          tooltip: isAllSelected ? 'Deselect All' : 'Select All',
        ),
        if (selectionCount > 0) ...[
          IconButton(
            icon: const Icon(Icons.drive_file_rename_outline),
            onPressed: onChangePreset,
            tooltip: 'Change Preset',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: onDelete,
            tooltip: 'Delete',
          ),
        ],
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

void _showDeleteConfirmation(
  BuildContext context,
  ExchangeRatesBloc bloc,
  int count,
) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Exchange Rates'),
      content: Text('Are you sure you want to delete $count exchange rates?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            bloc.add(const DeleteSelectedExchangeRates());
            Navigator.pop(context);
          },
          child: const Text('Delete'),
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
      title: const Text('Update Preset'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Enter the new preset ID for the selected items:'),
          const SizedBox(height: 16),
          TextField(
            controller: presetController,
            decoration: const InputDecoration(
              labelText: 'Preset ID',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final newPreset = int.tryParse(presetController.text);
            if (newPreset != null) {
              bloc.add(UpdateSelectedExchangeRatesPreset(newPreset));
              Navigator.pop(context);
            }
          },
          child: const Text('Update'),
        ),
      ],
    ),
  );
}
