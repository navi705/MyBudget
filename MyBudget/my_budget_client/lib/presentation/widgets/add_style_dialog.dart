import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/domain/entities/account_style.dart';
import 'package:my_budget_client/presentation/blocs/account_styles/account_styles_bloc.dart';

class AddStyleDialog extends StatefulWidget {
  const AddStyleDialog({super.key});

  @override
  State<AddStyleDialog> createState() => _AddStyleDialogState();
}

class _AddStyleDialogState extends State<AddStyleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String _selectedIconName = 'wallet';
  String _selectedColorHex = '#4CAF50';

  final List<String> _iconNames = ['wallet', 'savings', 'credit_card', 'account_balance'];
  final List<String> _colorHexes = ['#4CAF50', '#2196F3', '#F44336', '#FFC107', '#9C27B0', '#E91E63'];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'wallet': return Icons.account_balance_wallet;
      case 'savings': return Icons.savings;
      case 'credit_card': return Icons.credit_card;
      default: return Icons.account_balance;
    }
  }

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    return Color(int.parse("0x$hexColor"));
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      final newStyle = AccountStyle(
        name: _nameController.text,
        iconName: _selectedIconName,
        colorHex: _selectedColorHex,
      );
      context.read<AccountStylesBloc>().add(AddAccountStyle(newStyle));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Style'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _onSave,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
