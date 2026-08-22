import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';

class DashboardCurrencySelector extends StatefulWidget {
  final String selectedCurrency;
  final List<String> availableCurrencies;
  final Function(String) onCurrencyChanged;

  const DashboardCurrencySelector({
    super.key,
    required this.selectedCurrency,
    required this.availableCurrencies,
    required this.onCurrencyChanged,
  });

  @override
  State<DashboardCurrencySelector> createState() =>
      _DashboardCurrencySelectorState();
}

class _DashboardCurrencySelectorState extends State<DashboardCurrencySelector> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => showDashboardCurrencyPicker(
          context,
          selectedCurrency: widget.selectedCurrency,
          availableCurrencies: widget.availableCurrencies,
          onSelected: widget.onCurrencyChanged,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered
                ? colorScheme.surfaceContainerHighest
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isHovered
                  ? colorScheme.onSurface.withValues(alpha: 0.1)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.selectedCurrency,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens the dashboard's currency picker.
///
/// Top level rather than a method on the selector's state because the
/// `dashboard_currency` hot key has to open the very same sheet, and the
/// `ScreenShortcuts` that runs it lives up in dashboard_screen.dart, several
/// widgets above this one. One implementation, called from the tap and from the
/// key, instead of two that can drift apart.
void showDashboardCurrencyPicker(
  BuildContext context, {
  required String selectedCurrency,
  required List<String> availableCurrencies,
  required ValueChanged<String> onSelected,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _CurrencyPickerDialog(
      availableCurrencies: availableCurrencies,
      onSelected: onSelected,
      currentCurrency: selectedCurrency,
    ),
  );
}

class _CurrencyPickerDialog extends StatefulWidget {
  final List<String> availableCurrencies;
  final String currentCurrency;
  final Function(String) onSelected;

  const _CurrencyPickerDialog({
    required this.availableCurrencies,
    required this.currentCurrency,
    required this.onSelected,
  });

  @override
  State<_CurrencyPickerDialog> createState() => _CurrencyPickerDialogState();
}

class _CurrencyPickerDialogState extends State<_CurrencyPickerDialog> {
  late List<String> _filteredCurrencies;
  final TextEditingController _searchController = TextEditingController();
  List<String> _favorites = const [];

  @override
  void initState() {
    super.initState();
    _filteredCurrencies = _ordered(widget.availableCurrencies);
    _loadFavorites();
  }

  /// The stars set in the currency picker apply here too: this sheet is the
  /// same question asked from the dashboard, and a currency that sits at the
  /// top of one list and in the middle of the other is two lists.
  Future<void> _loadFavorites() async {
    CurrencyRepository repository;
    try {
      repository = RepositoryProvider.of<CurrencyRepository>(context);
    } on FlutterError {
      // No repository above this sheet - a widget test pumping the dashboard
      // in isolation. The list stays in the order it arrived in.
      return;
    }
    final favorites = await repository.getFavoriteCurrencyCodes();
    if (!mounted) return;
    setState(() {
      _favorites = favorites;
      _filteredCurrencies = _ordered(_filteredCurrencies);
    });
  }

  List<String> _ordered(List<String> currencies) {
    final favorites = _favorites.toSet();
    return [
      ...currencies.where(favorites.contains),
      ...currencies.where((c) => !favorites.contains(c)),
    ];
  }

  void _filter(String query) {
    setState(() {
      _filteredCurrencies = _ordered(
        widget.availableCurrencies
            .where((c) => c.toLowerCase().contains(query.toLowerCase()))
            .toList(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: context.l10n.dshSearchCurrency,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: _filter,
                ),
              ),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: _filteredCurrencies.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final currency = _filteredCurrencies[index];
                    final isSelected = currency == widget.currentCurrency;
                    return _CurrencyListItem(
                      currency: currency,
                      isSelected: isSelected,
                      isFavorite: _favorites.contains(currency),
                      onTap: () {
                        widget.onSelected(currency);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CurrencyListItem extends StatefulWidget {
  final String currency;
  final bool isSelected;
  final bool isFavorite;
  final VoidCallback onTap;

  const _CurrencyListItem({
    required this.currency,
    required this.isSelected,
    required this.isFavorite,
    required this.onTap,
  });

  @override
  State<_CurrencyListItem> createState() => _CurrencyListItemState();
}

class _CurrencyListItemState extends State<_CurrencyListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? colorScheme.primary.withValues(alpha: 0.15)
              : _isHovered
              ? colorScheme.onSurface.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          onTap: widget.onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            widget.currency,
            style: TextStyle(
              fontWeight: widget.isSelected
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: widget.isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurface,
            ),
          ),
          leading: widget.isFavorite
              ? Icon(Icons.star, size: 18, color: colorScheme.primary)
              : null,
          trailing: widget.isSelected
              ? Icon(Icons.check, color: colorScheme.primary)
              : null,
        ),
      ),
    );
  }
}
