import 'package:flutter/material.dart';
import 'package:my_budget_client/domain/entities/currency.dart';

class CurrencySelectionDialog extends StatefulWidget {
  final List<Currency> allCurrencies;
  final List<Currency> selectedCurrencies;

  const CurrencySelectionDialog({
    super.key,
    required this.allCurrencies,
    required this.selectedCurrencies,
  });

  @override
  State<CurrencySelectionDialog> createState() =>
      _CurrencySelectionDialogState();
}

class _CurrencySelectionDialogState extends State<CurrencySelectionDialog> {
  late TextEditingController _searchController;
  late List<Currency> _filteredCurrencies;
  late List<Currency> _tempSelectedCurrencies;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredCurrencies = widget.allCurrencies;
    _tempSelectedCurrencies = List.from(widget.selectedCurrencies);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCurrencies = widget.allCurrencies.where((c) {
        return c.name.toLowerCase().contains(query) ||
            c.code.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return AlertDialog(
      title: const Text('Select Currencies'),
      content: SizedBox(
        width: double.maxFinite,
        height: screenHeight * 0.7,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 8.0,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredCurrencies.length,
                itemBuilder: (context, index) {
                  final currency = _filteredCurrencies[index];
                  final isSelected = _tempSelectedCurrencies.any(
                    (c) => c.code == currency.code,
                  );
                  return CheckboxListTile(
                    title: Text('${currency.name} (${currency.code})'),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _tempSelectedCurrencies.add(currency);
                        } else {
                          _tempSelectedCurrencies.removeWhere(
                            (c) => c.code == currency.code,
                          );
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Clear All'),
          onPressed: () {
            setState(() {
              _tempSelectedCurrencies.clear();
            });
          },
        ),
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: const Text('OK'),
          onPressed: () {
            Navigator.of(context).pop(_tempSelectedCurrencies);
          },
        ),
      ],
    );
  }
}
