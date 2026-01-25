import 'package:flutter/material.dart';
import '../../core/utils/country_codes.dart';

class CountryPickerDialog extends StatefulWidget {
  final Map<String, String> allCountries;
  final String? selectedCountryCode;

  const CountryPickerDialog({
    super.key,
    required this.allCountries,
    this.selectedCountryCode,
  });

  @override
  State<CountryPickerDialog> createState() => _CountryPickerDialogState();
}

class _CountryPickerDialogState extends State<CountryPickerDialog> {
  late TextEditingController _searchController;
  late List<MapEntry<String, String>> _localizedCountries;
  late List<MapEntry<String, String>> _filteredCountries;
  String? _currentLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).toString();
    if (_currentLocale != locale) {
      _currentLocale = locale;
      _updateLocalizedCountries();
    }
  }

  void _updateLocalizedCountries() {
    _localizedCountries = widget.allCountries.values.map((code) {
      final name = getLocalizedCountryName(code, _currentLocale ?? 'en');
      return MapEntry(name, code);
    }).toList();

    // Initial sort by localized name
    _localizedCountries.sort((a, b) => a.key.compareTo(b.key));
    _onSearchChanged();
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);
    // Note: Items will be populated in didChangeDependencies
    _filteredCountries = [];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCountries = _localizedCountries.where((e) {
        return e.key.toLowerCase().contains(query) ||
            e.value.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return AlertDialog(
      title: const Text('Select Country'),
      content: SizedBox(
        width: double.maxFinite,
        height: screenHeight * 0.7,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Country',
                prefixIcon: Icon(Icons.search),
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
                itemCount: _filteredCountries.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final country = _filteredCountries[index];
                  final isSelected =
                      country.value == widget.selectedCountryCode;

                  return ListTile(
                    title: Text(country.key),
                    subtitle: Text(country.value),
                    selected: isSelected,
                    trailing: isSelected
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () {
                      Navigator.of(context).pop(country.value);
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
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
