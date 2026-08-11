import 'package:flutter/material.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
import 'package:my_budget_client/domain/entities/currency.dart';

class CurrencyPickerDialog extends StatefulWidget {
  final List<Currency> allCurrencies;
  final String? selectedCurrencyCode;

  const CurrencyPickerDialog({
    super.key,
    required this.allCurrencies,
    this.selectedCurrencyCode,
  });

  @override
  State<CurrencyPickerDialog> createState() => _CurrencyPickerDialogState();
}

class _CurrencyPickerDialogState extends State<CurrencyPickerDialog> {
  late TextEditingController _searchController;
  late List<Currency> _filteredCurrencies;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredCurrencies = widget.allCurrencies;
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
      title: Text(context.l10n.selectCurrencyTitle),
      content: SizedBox(
        width: double.maxFinite,
        height: screenHeight * 0.7,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: context.l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 8.0,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: _filteredCurrencies.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final currency = _filteredCurrencies[index];
                  final isSelected =
                      currency.code == widget.selectedCurrencyCode;

                  return ListTile(
                    title: Text('${currency.name} (${currency.code})'),
                    selected: isSelected,
                    trailing: isSelected
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () {
                      Navigator.of(context).pop(currency.code);
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
          child: Text(context.l10n.cancelButton),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
