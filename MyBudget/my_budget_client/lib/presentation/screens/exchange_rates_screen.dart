import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/core/di/injection_container.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';
import 'package:my_budget_client/presentation/blocs/exchange_rates/exchange_rates_bloc.dart';
import 'package:my_budget_client/presentation/widgets/generic/generic_filter_app_bar.dart';

class ExchangeRatesScreen extends StatelessWidget {
  const ExchangeRatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<ExchangeRatesBloc>()..add(const LoadExchangeRates()),
      child: const _ExchangeRatesView(),
    );
  }
}

class _ExchangeRatesView extends StatefulWidget {
  const _ExchangeRatesView();

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
        return Scaffold(
          appBar: _buildAppBar(context, state),
          body: _buildBody(context, state),
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
    final bloc = context.read<ExchangeRatesBloc>();

    return GenericFilterAppBar(
      totalCountText: 'Total: ${state.totalCount}',
      centerWidget: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Date Filter
          TextButton.icon(
            icon: const Icon(
              Icons.calendar_today,
              size: 18,
              color: Colors.white,
            ),
            label: Text(
              state.dateFilter == null
                  ? 'All Dates'
                  : DateFormat('dd.MM.yyyy').format(state.dateFilter!),
              style: const TextStyle(color: Colors.white),
            ),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: state.dateFilter ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              bloc.add(
                ChangeExchangeRatesFilters(
                  date: date,
                  fromCurrency: state.fromCurrencyFilter,
                  toCurrency: state.toCurrencyFilter,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          // Clear Date
          if (state.dateFilter != null)
            IconButton(
              icon: const Icon(Icons.clear, size: 18, color: Colors.white),
              onPressed: () => bloc.add(
                ChangeExchangeRatesFilters(
                  date: null,
                  fromCurrency: state.fromCurrencyFilter,
                  toCurrency: state.toCurrencyFilter,
                ),
              ),
            ),
          const VerticalDivider(
            color: Colors.white24,
            indent: 12,
            endIndent: 12,
          ),
          // From Currency Filter
          _buildCurrencyDropdown(
            context,
            'From',
            state.fromCurrencyFilter,
            state.currencies,
            (val) => bloc.add(
              ChangeExchangeRatesFilters(
                date: state.dateFilter,
                fromCurrency: val,
                toCurrency: state.toCurrencyFilter,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // To Currency Filter
          _buildCurrencyDropdown(
            context,
            'To',
            state.toCurrencyFilter,
            state.currencies,
            (val) => bloc.add(
              ChangeExchangeRatesFilters(
                date: state.dateFilter,
                fromCurrency: state.fromCurrencyFilter,
                toCurrency: val,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyDropdown(
    BuildContext context,
    String hint,
    String? value,
    List<dynamic> currencies,
    Function(String?) onChanged,
  ) {
    return DropdownButton<String>(
      value: value,
      hint: Text(
        hint,
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
      dropdownColor: Theme.of(context).colorScheme.surface,
      underline: const SizedBox(),
      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      items: [
        const DropdownMenuItem<String>(value: null, child: Text('All')),
        ...currencies.map(
          (c) => DropdownMenuItem<String>(value: c.code, child: Text(c.code)),
        ),
      ],
      onChanged: onChanged,
    );
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
              TextField(
                controller: rateController,
                decoration: const InputDecoration(labelText: 'Rate'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
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
                        preset: 0,
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
          trailing: Text(
            widget.rate.rate.toStringAsFixed(4),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ),
      ),
    );
  }
}
