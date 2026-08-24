import 'package:my_budget_client/core/utils/decimal_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/repositories/asset_repository.dart';
import 'package:my_budget_client/presentation/blocs/asset/asset_bloc.dart';
import 'package:my_budget_client/presentation/blocs/asset/asset_event.dart';
import 'package:my_budget_client/presentation/blocs/currency/currency_bloc.dart';
import 'package:my_budget_client/presentation/widgets/multi_select_dialog.dart';
import 'package:my_budget_client/presentation/widgets/currency_selection_dialog.dart';
import 'package:my_budget_client/core/utils/dialog_utils.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';

void showAssetFilterDialog(BuildContext context) {
  DialogUtils.showAppDialog(
    context: context,
    resizeToAvoidBottomInset: false,
    child: MultiBlocProvider(
      providers: [
        BlocProvider.value(value: BlocProvider.of<AssetBloc>(context)),
        BlocProvider.value(value: BlocProvider.of<CurrencyBloc>(context)),
      ],
      child: const AssetFilterDialog(),
    ),
  );
}

class AssetFilterDialog extends StatefulWidget {
  const AssetFilterDialog({super.key});

  @override
  State<AssetFilterDialog> createState() => _AssetFilterDialogState();
}

class _AssetFilterDialogState extends State<AssetFilterDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _minValueController;
  late TextEditingController _maxValueController;

  late List<String> _selectedAssetTypes;
  late List<String> _selectedCurrencyCodes;
  late List<String> _selectedSources;
  late List<int> _selectedPresets;

  List<String> _availableAssetTypes = [];
  List<String> _availableSources = [];
  List<int> _availablePresets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final state = context.read<AssetBloc>().state;
    _nameController = TextEditingController(text: state.nameFilter);
    _descriptionController = TextEditingController(
      text: state.descriptionFilter,
    );
    _minValueController = TextEditingController(
      text: state.minValueFilter?.toString(),
    );
    _maxValueController = TextEditingController(
      text: state.maxValueFilter?.toString(),
    );
    _selectedAssetTypes = List.from(state.assetTypeFilters ?? []);
    _selectedCurrencyCodes = List.from(state.currencyCodeFilters ?? []);
    _selectedSources = List.from(state.sourceFilters ?? []);
    _selectedPresets = List.from(state.presetFilters ?? []);

    _loadAvailableFilters();
  }

  Future<void> _loadAvailableFilters() async {
    try {
      final repository = context.read<AssetRepository>();
      final assetTypes = await repository.getAvailableAssetTypes();
      final sources = await repository.getAvailableSources();
      final presets = await repository.getAvailablePresets();

      if (mounted) {
        setState(() {
          _availableAssetTypes = assetTypes;
          _availableSources = sources;
          _availablePresets = presets;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _minValueController.dispose();
    _maxValueController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    context.read<AssetBloc>().add(
      ChangeAssetFilters(
        name: _nameController.text.isEmpty ? null : _nameController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        assetTypes: _selectedAssetTypes.isEmpty ? null : _selectedAssetTypes,
        currencyCodes: _selectedCurrencyCodes.isEmpty
            ? null
            : _selectedCurrencyCodes,
        sources: _selectedSources.isEmpty ? null : _selectedSources,
        presets: _selectedPresets.isEmpty ? null : _selectedPresets,
        minValue: _minValueController.text.isEmpty
            ? null
            : double.tryParse(_minValueController.text),
        maxValue: _maxValueController.text.isEmpty
            ? null
            : double.tryParse(_maxValueController.text),
      ),
    );
    Navigator.of(context).pop();
  }

  void _clearFilters() {
    setState(() {
      _nameController.clear();
      _descriptionController.clear();
      _minValueController.clear();
      _maxValueController.clear();
      _selectedAssetTypes = [];
      _selectedCurrencyCodes = [];
      _selectedSources = [];
      _selectedPresets = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.assetFiltersTitle),
      content: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: context.l10n.fltNameLabel,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: context.l10n.descriptionLabel,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _minValueController,
                          decoration: InputDecoration(
                            labelText: context.l10n.minValueLabel,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: signedDecimalInputFormatters,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _maxValueController,
                          decoration: InputDecoration(
                            labelText: context.l10n.maxValueLabel,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: signedDecimalInputFormatters,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text(context.l10n.assetTypesLabel),
                    subtitle: Text(
                      _selectedAssetTypes.isEmpty
                          ? context.l10n.allLabel
                          : context.l10n.selectedCountLabel(
                              _selectedAssetTypes.length.toString(),
                            ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      final results =
                          await DialogUtils.showAppDialog<List<String>>(
                            context: context,
                            resizeToAvoidBottomInset: false,
                            child: MultiSelectDialog<String, String>(
                              items: _availableAssetTypes,
                              selectedIds: _selectedAssetTypes,
                              itemBuilder: (item) => Text(item),
                              idGetter: (item) => item,
                              stringGetter: (item) => item,
                            ),
                          );
                      if (results != null) {
                        setState(() {
                          _selectedAssetTypes = results;
                        });
                      }
                    },
                  ),
                  const Divider(),
                  BlocBuilder<CurrencyBloc, CurrencyState>(
                    builder: (context, state) {
                      final currencies = state is CurrencyLoadSuccess
                          ? state.currencies
                          : <Currency>[];
                      return ListTile(
                        title: Text(context.l10n.currenciesLabel),
                        subtitle: Text(
                          _selectedCurrencyCodes.isEmpty
                              ? context.l10n.allLabel
                              : context.l10n.selectedCountLabel(
                                  _selectedCurrencyCodes.length.toString(),
                                ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          // The same picker the rest of the app asks with:
                          // starred codes first, then the ones already in use.
                          final results =
                              await DialogUtils.showAppDialog<List<Currency>>(
                                context: context,
                                resizeToAvoidBottomInset: false,
                                child: CurrencySelectionDialog(
                                  allCurrencies: currencies,
                                  selectedCurrencies: currencies
                                      .where(
                                        (c) => _selectedCurrencyCodes.contains(
                                          c.code,
                                        ),
                                      )
                                      .toList(),
                                ),
                              );
                          if (results != null) {
                            setState(() {
                              _selectedCurrencyCodes = results
                                  .map((c) => c.code)
                                  .toList();
                            });
                          }
                        },
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: Text(context.l10n.sourcesLabel),
                    subtitle: Text(
                      _selectedSources.isEmpty
                          ? context.l10n.allLabel
                          : context.l10n.selectedCountLabel(
                              _selectedSources.length.toString(),
                            ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      final results =
                          await DialogUtils.showAppDialog<List<String>>(
                            context: context,
                            resizeToAvoidBottomInset: false,
                            child: MultiSelectDialog<String, String>(
                              items: _availableSources,
                              selectedIds: _selectedSources,
                              itemBuilder: (item) => Text(item),
                              idGetter: (item) => item,
                              stringGetter: (item) => item,
                            ),
                          );
                      if (results != null) {
                        setState(() {
                          _selectedSources = results;
                        });
                      }
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: Text(context.l10n.presetsLabel),
                    subtitle: Text(
                      _selectedPresets.isEmpty
                          ? context.l10n.allLabel
                          : context.l10n.selectedCountLabel(
                              _selectedPresets.length.toString(),
                            ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      final results =
                          await DialogUtils.showAppDialog<List<int>>(
                            context: context,
                            resizeToAvoidBottomInset: false,
                            child: MultiSelectDialog<int, int>(
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
        TextButton(
          onPressed: _clearFilters,
          child: Text(context.l10n.clearButton),
        ),
        TextButton(
          onPressed: _applyFilters,
          child: Text(context.l10n.applyButton),
        ),
      ],
    );
  }
}
