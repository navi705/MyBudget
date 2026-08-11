import 'package:flutter/material.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
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
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(l10n.fltSelectCurrenciesLabel),
      content: SizedBox(
        width: double.maxFinite,
        height: screenHeight * 0.7,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
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
          child: Text(l10n.pckClearAll),
          onPressed: () {
            setState(() {
              _tempSelectedCurrencies.clear();
            });
          },
        ),
        TextButton(
          child: Text(l10n.cancelButton),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: Text(l10n.okButton),
          onPressed: () {
            Navigator.of(context).pop(_tempSelectedCurrencies);
          },
        ),
      ],
    );
  }
}
