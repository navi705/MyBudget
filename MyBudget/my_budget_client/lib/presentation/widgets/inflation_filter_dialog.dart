import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/domain/repositories/inflation_repository.dart';
import 'package:my_budget_client/presentation/blocs/inflation/inflation_bloc.dart';
import 'package:my_budget_client/presentation/widgets/multi_select_dialog.dart';

void showInflationFilterDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return BlocProvider.value(
        value: BlocProvider.of<InflationBloc>(context),
        child: const InflationFilterDialog(),
      );
    },
  );
}

class InflationFilterDialog extends StatefulWidget {
  const InflationFilterDialog({super.key});

  @override
  State<InflationFilterDialog> createState() => _InflationFilterDialogState();
}

class _InflationFilterDialogState extends State<InflationFilterDialog> {
  late List<String> _selectedCountries;
  late List<int> _selectedPresets;

  List<String> _availableCountries = [];
  List<int> _availablePresets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final state = context.read<InflationBloc>().state;
    _selectedCountries = List.from(state.countryFilters ?? []);
    _selectedPresets = List.from(state.presetFilters ?? []);
    _loadAvailableFilters();
  }

  Future<void> _loadAvailableFilters() async {
    try {
      final repository = context.read<InflationRepository>();
      final countries = await repository.getAvailableCountries();
      final presets = await repository.getAvailablePresets();

      if (mounted) {
        setState(() {
          _availableCountries = countries;
          _availablePresets = presets;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle error cleanly, maybe just show empty lists
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    context.read<InflationBloc>().add(
      ChangeInflationFilters(
        countries: _selectedCountries.isEmpty ? null : _selectedCountries,
        presets: _selectedPresets.isEmpty ? null : _selectedPresets,
      ),
    );
    Navigator.of(context).pop();
  }

  void _clearFilters() {
    setState(() {
      _selectedCountries = [];
      _selectedPresets = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Inflation Filters'),
      content: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('Countries'),
                    subtitle: Text(
                      _selectedCountries.isEmpty
                          ? 'All'
                          : '${_selectedCountries.length} selected',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      final results = await showDialog<List<String>>(
                        context: context,
                        builder: (context) => MultiSelectDialog<String, String>(
                          items: _availableCountries,
                          selectedIds: _selectedCountries,
                          itemBuilder: (item) => Text(item),
                          idGetter: (item) => item,
                          stringGetter: (item) => item,
                        ),
                      );
                      if (results != null) {
                        setState(() {
                          _selectedCountries = results;
                        });
                      }
                    },
                  ),
                  const Divider(),
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
                        setState(() {
                          _selectedPresets = results;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(onPressed: _clearFilters, child: const Text('Clear')),
        TextButton(onPressed: _applyFilters, child: const Text('Apply')),
      ],
    );
  }
}
