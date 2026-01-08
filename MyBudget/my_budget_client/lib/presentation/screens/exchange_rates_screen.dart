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
            onPressed: () => _showAddExchangeRateDialog(context),
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
        return _ExchangeRateListItem(rate: rate);
      },
    );
  }

  void _showAddExchangeRateDialog(BuildContext context) {
    final bloc = context.read<ExchangeRatesBloc>();
    final fromController = TextEditingController(text: 'EUR');
    final toController = TextEditingController();
    final rateController = TextEditingController();
    final presetController = TextEditingController(text: '1');
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Exchange Rate'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fromController,
                decoration: const InputDecoration(
                  labelText: 'From Currency (e.g. EUR)',
                ),
              ),
              TextField(
                controller: toController,
                decoration: const InputDecoration(
                  labelText: 'To Currency (e.g. USD)',
                ),
              ),
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
                      decoration: const InputDecoration(labelText: 'Preset ID'),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton.tonal(
              onPressed: () {
                final rate = double.tryParse(rateController.text);
                final preset = int.tryParse(presetController.text) ?? 1;
                if (fromController.text.isNotEmpty &&
                    toController.text.isNotEmpty &&
                    rate != null) {
                  bloc.add(
                    AddExchangeRate(
                      ExchangeRateDomain(
                        fromCurrencyCode: fromController.text.toUpperCase(),
                        toCurrencyCode: toController.text.toUpperCase(),
                        rate: rate,
                        date: selectedDate,
                        preset: preset,
                      ),
                    ),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExchangeRateListItem extends StatefulWidget {
  final ExchangeRateDomain rate;

  const _ExchangeRateListItem({required this.rate});

  @override
  State<_ExchangeRateListItem> createState() => _ExchangeRateListItemState();
}

class _ExchangeRateListItemState extends State<_ExchangeRateListItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Card(
        elevation: _isHovering ? 4.0 : 2.0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: _isHovering
              ? BorderSide(color: Theme.of(context).primaryColor, width: 2.0)
              : BorderSide.none,
        ),
        color: _isHovering ? Colors.grey.withValues(alpha: 0.1) : null,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20.0,
            vertical: 10.0,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: const Icon(Icons.currency_exchange, color: Colors.white),
          ),
          title: Text(
            '${widget.rate.fromCurrencyCode} ➔ ${widget.rate.toCurrencyCode}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Text(
            DateFormat('dd.MM.yyyy').format(widget.rate.date),
            style: const TextStyle(fontSize: 14),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                widget.rate.rate.toStringAsFixed(4),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              Text(
                'Preset: ${widget.rate.preset}',
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

    // Using a more compact layout to fit Currencies.
    // Row: [Nav Left] [Date] [Nav Right] [Sort] | [From] [To]
    final centerWidget = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: onSurface),
            onPressed: () => _navigate(bloc, -1),
          ),
          InkWell(
            onTap: () => _showCustomCalendar(context),
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 12.0,
                horizontal: 8.0,
              ),
              alignment: Alignment.center,
              child: Text(
                _formatDate(context),
                style: TextStyle(color: onSurface, fontSize: 16),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: onSurface),
            onPressed: () => _navigate(bloc, 1),
          ),
          const SizedBox(width: 8),
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
          const SizedBox(width: 16),
          // Currency Filters
          _buildCurrencyDropdown(
            context,
            'From',
            state.fromCurrencyFilter,
            state.currencies,
            (val) => bloc.add(
              ChangeExchangeRatesFilters(
                date: state
                    .activeDate, // Keeping activeDate in sync if needed by legacy
                fromCurrency: val,
                toCurrency: state.toCurrencyFilter,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildCurrencyDropdown(
            context,
            'To',
            state.toCurrencyFilter,
            state.currencies,
            (val) => bloc.add(
              ChangeExchangeRatesFilters(
                date: state.activeDate,
                fromCurrency: state.fromCurrencyFilter,
                toCurrency: val,
              ),
            ),
          ),
        ],
      ),
    );

    return GenericFilterAppBar(
      centerWidget: centerWidget,
      totalCountText: 'Total: ${state.totalCount}',
    );
  }

  Widget _buildCurrencyDropdown(
    BuildContext context,
    String hint,
    String? value,
    List<Currency> currencies,
    ValueChanged<String?> onChanged,
  ) {
    // Reusing the simple dropdown style from before but smaller logic
    return SizedBox(
      width: 100, // Fixed width to fit
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: hint,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 0,
          ),
          border: const OutlineInputBorder(),
        ),
        items: currencies.map((c) {
          return DropdownMenuItem(
            value: c.code,
            child: Text(
              c.code,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
