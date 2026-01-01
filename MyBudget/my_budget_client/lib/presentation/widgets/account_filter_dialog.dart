import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/domain/entities/account_type.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/presentation/blocs/categories/categories_bloc.dart' hide FiltersChanged;
import 'package:my_budget_client/presentation/blocs/currency/currency_bloc.dart';
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';
import 'package:my_budget_client/presentation/widgets/multi_select_dialog.dart';

void showAccountFilterDialog(
    BuildContext context, AccountFilters currentFilters) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return MultiBlocProvider(
        providers: [
          BlocProvider.value(
            value: BlocProvider.of<AccountsBloc>(context),
          ),
          BlocProvider.value(
            value: BlocProvider.of<SettingsBloc>(context),
          ),
          BlocProvider.value(
            value: BlocProvider.of<CategoriesBloc>(context),
          ),
          BlocProvider.value(
            value: BlocProvider.of<CurrencyBloc>(context),
          ),
        ],
        child: AccountFilterDialog(currentFilters: currentFilters),
      );
    },
  );
}

class AccountFilterDialog extends StatefulWidget {
  final AccountFilters currentFilters;

  const AccountFilterDialog({super.key, required this.currentFilters});

  @override
  State<AccountFilterDialog> createState() => _AccountFilterDialogState();
}

class _AccountFilterDialogState extends State<AccountFilterDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _amountFromController;
  late TextEditingController _amountToController;
  late DateTime? _creationDate;
  late List<String> _selectedCurrencyIds;
  late List<String> _selectedAccountTypeIds;
  late bool _persistFilters;

  @override
  void initState() {
    super.initState();
    final settingsBloc = context.read<SettingsBloc>();
    _persistFilters =
        settingsBloc.state.settings['persist_account_filters'] == 'true';

    AccountFilters filters;
    if (_persistFilters) {
      final settings = settingsBloc.state.settings;
      filters = AccountFilters(
        sort: Sort.descending, // Default sort
        name: settings['account_filter_name'],
        description: settings['account_filter_description'],
        amountFrom:
            double.tryParse(settings['account_filter_amount_from'] ?? ''),
        amountTo: double.tryParse(settings['account_filter_amount_to'] ?? ''),
        date: DateTime.tryParse(settings['account_filter_account_date'] ?? ''),
        currenciesIds:
            (settings['account_selected_currencies'] ?? '')
                .split(',')
                .where((id) => id.isNotEmpty)
                .toList(),
        accountTypeIds:
            (settings['account_filter_account_type_id'] ?? '')
                .split(',')
                .where((id) => id.isNotEmpty)
                .toList(),
      );
    } else {
      filters = widget.currentFilters;
    }

    _nameController = TextEditingController(text: filters.name);
    _descriptionController = TextEditingController(text: filters.description);
    _amountFromController =
        TextEditingController(text: filters.amountFrom?.toString());
    _amountToController =
        TextEditingController(text: filters.amountTo?.toString());
    _creationDate = filters.date;
    _selectedCurrencyIds = List<String>.from(filters.currenciesIds ?? []);
    _selectedAccountTypeIds = List<String>.from(filters.accountTypeIds ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _amountFromController.dispose();
    _amountToController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final settingsBloc = context.read<SettingsBloc>();
    settingsBloc.add(
        UpdateSetting('persist_account_filters', _persistFilters.toString()));

    final newFilters = AccountFilters(
      sort: widget.currentFilters.sort,
      name: _nameController.text.isNotEmpty ? _nameController.text : null,
      description: _descriptionController.text.isNotEmpty
          ? _descriptionController.text
          : null,
      amountFrom: _amountFromController.text.isNotEmpty
          ? double.tryParse(_amountFromController.text)
          : null,
      amountTo: _amountToController.text.isNotEmpty
          ? double.tryParse(_amountToController.text)
          : null,
      date: _creationDate,
      currenciesIds: _selectedCurrencyIds,
      accountTypeIds: _selectedAccountTypeIds,
    );

    if (_persistFilters) {
      settingsBloc
          .add(UpdateSetting('account_filter_name', newFilters.name ?? ''));
      settingsBloc.add(UpdateSetting(
          'account_filter_description', newFilters.description ?? ''));
      settingsBloc.add(UpdateSetting('account_filter_amount_from',
          newFilters.amountFrom?.toString() ?? ''));
      settingsBloc.add(UpdateSetting(
          'account_filter_amount_to', newFilters.amountTo?.toString() ?? ''));
      settingsBloc.add(UpdateSetting('account_filter_account_date',
          newFilters.date?.toIso8601String() ?? ''));
      settingsBloc.add(UpdateSetting('account_selected_currencies',
          newFilters.currenciesIds?.join(',') ?? ''));
      settingsBloc.add(UpdateSetting('account_filter_account_type_id',
          newFilters.accountTypeIds?.join(',') ?? ''));
    } else {
      _clearFilterSettings();
    }

    context.read<AccountsBloc>().add(FiltersChanged(newFilters));
    Navigator.of(context).pop();
  }

  void _clearFilters() {
    _clearFilterSettings();
    context
        .read<AccountsBloc>()
        .add(const FiltersChanged(AccountFilters(sort: Sort.descending)));
    Navigator.of(context).pop();
  }

  void _clearFilterSettings() {
    final settingsBloc = context.read<SettingsBloc>();
    settingsBloc.add(const UpdateSetting('account_filter_name', ''));
    settingsBloc.add(const UpdateSetting('account_filter_description', ''));
    settingsBloc.add(const UpdateSetting('account_filter_amount_from', ''));
    settingsBloc.add(const UpdateSetting('account_filter_amount_to', ''));
    settingsBloc.add(const UpdateSetting('account_filter_account_date', ''));
    settingsBloc.add(const UpdateSetting('account_selected_currencies', ''));
    settingsBloc.add(const UpdateSetting('account_filter_account_type_id', ''));
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _creationDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _creationDate) {
      setState(() {
        _creationDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mainCurrencyCode =
        context.watch<SettingsBloc>().state.settings['main_currency_code'] ??
            'EUR';
    return AlertDialog(
      title: const Text('Account Filters'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Persist Filters'),
                Switch(
                  value: _persistFilters,
                  onChanged: (value) {
                    setState(() {
                      _persistFilters = value;
                    });
                  },
                ),
              ],
            ),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Search by name...',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Search description...',
              ),
            ),
            // const SizedBox(height: 16),
            // TextFormField(
            //   controller: _amountFromController,
            //   decoration:
            //       InputDecoration(labelText: 'Balance From ($mainCurrencyCode)'),
            //   keyboardType:
            //       const TextInputType.numberWithOptions(decimal: true),
            // ),
            const SizedBox(height: 16),
            // TextFormField(
            //   controller: _amountToController,
            //   decoration:
            //       InputDecoration(labelText: 'Balance To ($mainCurrencyCode)'),
            //   keyboardType:
            //       const TextInputType.numberWithOptions(decimal: true),
            // ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Date create: ${_creationDate != null ? DateFormat.yMd().format(_creationDate!) : 'Any'}',
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
                ),
                if (_creationDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _creationDate = null;
                      });
                    },
                  )
              ],
            ),
            const SizedBox(height: 16),
            BlocBuilder<AccountsBloc, AccountsState>(
              builder: (context, state) {
                if (state is AccountsLoadSuccess) {
                  return ListTile(
                    title: const Text('Account Types'),
                    subtitle: Text('${_selectedAccountTypeIds.length} selected'),
                    onTap: () async {
                      final List<String>? result = await showDialog(
                        context: context,
                        builder: (_) => MultiSelectDialog<AccountType>(
                          items: state.accountTypes,
                          selectedIds: _selectedAccountTypeIds,
                          itemBuilder: (item) => Text(item.name),
                          idGetter: (item) => item.id,
                          stringGetter: (item) => item.name,
                        ),
                      );

                      if (result != null) {
                        setState(() {
                          _selectedAccountTypeIds = result;
                        });
                      }
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 16),
            BlocBuilder<CurrencyBloc, CurrencyState>(
              builder: (context, state) {
                if (state is CurrencyLoadSuccess) {
                  return ListTile(
                    title: const Text('Currencies'),
                    subtitle: Text('${_selectedCurrencyIds.length} selected'),
                    onTap: () async {
                      final List<String>? result = await showDialog(
                        context: context,
                        builder: (_) => MultiSelectDialog<Currency>(
                          items: state.currencies,
                          selectedIds: _selectedCurrencyIds,
                          itemBuilder: (item) => Text(item.code),
                          idGetter: (item) => item.code,
                          stringGetter: (item) => '${item.name} ${item.code}',
                        ),
                      );

                      if (result != null) {
                        setState(() {
                          _selectedCurrencyIds = result;
                        });
                      }
                    },
                  );
                }
                return const CircularProgressIndicator();
              },
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _clearFilters,
          child: const Text('Clear'),
        ),
        TextButton(
          onPressed: _applyFilters,
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
