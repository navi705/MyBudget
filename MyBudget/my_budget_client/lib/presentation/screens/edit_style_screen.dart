import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/domain/entities/account_style.dart';
import 'package:my_budget_client/presentation/blocs/account_styles/account_styles_bloc.dart';

class EditStyleScreen extends StatefulWidget {
  final String styleId;

  const EditStyleScreen({super.key, required this.styleId});

  @override
  State<EditStyleScreen> createState() => _EditStyleScreenState();
}

class _EditStyleScreenState extends State<EditStyleScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  String? _selectedIconName;
  String? _selectedColorHex;

  AccountStyle? _initialStyle;

  final List<String> _iconNames = ['wallet', 'savings', 'credit_card', 'account_balance'];
  final List<String> _colorHexes = ['#4CAF50', '#2196F3', '#F44336', '#FFC107', '#9C27B0', '#E91E63'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();

    final stylesState = context.read<AccountStylesBloc>().state;
    if (stylesState is AccountStylesLoadSuccess) {
      try {
        _initialStyle = stylesState.styles.firstWhere(
          (style) => style.id.toString() == widget.styleId,
        );
        _nameController.text = _initialStyle!.name;
        _selectedIconName = _initialStyle!.iconName;
        _selectedColorHex = _initialStyle!.colorHex;
      } catch (e) {
        _initialStyle = null;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'wallet': return Icons.account_balance_wallet;
      case 'savings': return Icons.savings;
      case 'credit_card': return Icons.credit_card;
      default: return Icons.account_balance;
    }
  }

  Color _getColorFromHex(String? hexColor) {
    hexColor = (hexColor ?? '#4CAF50').replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    return Color(int.parse("0x$hexColor"));
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      final updatedStyle = AccountStyle(
        id: _initialStyle!.id,
        name: _nameController.text,
        iconName: _selectedIconName!,
        colorHex: _selectedColorHex!,
      );
      context.read<AccountStylesBloc>().add(UpdateAccountStyle(updatedStyle));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initialStyle == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Style not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit: ${_initialStyle!.name}'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Style Name'),
                validator: (value) => (value == null || value.isEmpty) ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 24),
              const Text('Icon', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                children: _iconNames.map((iconName) {
                  return ChoiceChip(
                    label: Icon(_getIconData(iconName)),
                    selected: _selectedIconName == iconName,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedIconName = iconName);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Color', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                children: _colorHexes.map((colorHex) {
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColorHex = colorHex),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: _getColorFromHex(colorHex),
                      child: _selectedColorHex == colorHex ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _onSave,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text('Save Changes'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
