import 'package:flutter/material.dart';

class DashboardCurrencySelector extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showCurrencyPicker(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedCurrency,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CurrencyPickerDialog(
        availableCurrencies: availableCurrencies,
        onSelected: onCurrencyChanged,
        currentCurrency: selectedCurrency,
      ),
    );
  }
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

  @override
  void initState() {
    super.initState();
    _filteredCurrencies = widget.availableCurrencies;
  }

  void _filter(String query) {
    setState(() {
      _filteredCurrencies = widget.availableCurrencies
          .where((c) => c.toLowerCase().contains(query.toLowerCase()))
          .toList();
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
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search Currency',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: _filter,
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                itemCount: _filteredCurrencies.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final currency = _filteredCurrencies[index];
                  final isSelected = currency == widget.currentCurrency;
                  return ListTile(
                    title: Text(currency),
                    trailing: isSelected
                        ? Icon(
                            Icons.check,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    onTap: () {
                      widget.onSelected(currency);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
