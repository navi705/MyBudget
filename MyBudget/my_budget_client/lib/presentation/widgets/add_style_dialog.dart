import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:my_budget_client/core/utils/icon_utils.dart';
import 'package:my_budget_client/domain/entities/icon_type.dart';
import 'package:my_budget_client/domain/entities/style.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';
import 'package:my_budget_client/presentation/widgets/icon_picker_dialog.dart';

class AddStyleDialog extends StatefulWidget {
  const AddStyleDialog({super.key});

  @override
  State<AddStyleDialog> createState() => _AddStyleDialogState();
}

class _AddStyleDialogState extends State<AddStyleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String _selectedIconName = 'wallet';
  Color _selectedColor = const Color(0xFF4CAF50);
  IconType _selectedIconType = IconType.material;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      final newStyle = Style(
        name: _nameController.text,
        iconName: _selectedIconName,
        colorHex: '#${_selectedColor.hex}',
        iconType: _selectedIconType,
      );
      context.read<StylesBloc>().add(AddStyle(newStyle));
      Navigator.of(context).pop();
    }
  }

  Future<void> _showIconPicker() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => IconPickerDialog(
        initialIconName: _selectedIconName,
        initialIconType: _selectedIconType,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedIconName = result['name'];
        _selectedIconType = result['type'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Style'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Style Name'),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Please enter a name'
                      : null,
                ),
                const SizedBox(height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Color'),
                  subtitle: Text(_selectedColor.hex.toUpperCase()),
                  trailing: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  onTap: () async {
                    final newColor = await showColorPickerDialog(
                      context,
                      _selectedColor,
                      pickersEnabled: const {
                        ColorPickerType.wheel: true,
                        ColorPickerType.primary: false,
                        ColorPickerType.accent: false,
                      },
                    );
                    setState(() {
                      _selectedColor = newColor;
                    });
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Icon'),
                  subtitle: Text(_selectedIconName),
                  trailing: SizedBox(
                    width: 40,
                    height: 40,
                    child: IconUtils.getIconWidget(
                      Style(
                        id: 'preview',
                        name: 'preview',
                        iconName: _selectedIconName,
                        colorHex: '#FFFFFF', // Ignored by util
                        iconType: _selectedIconType,
                      ),
                    ),
                  ),
                  onTap: _showIconPicker,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.tonal(onPressed: _onSave, child: const Text('Save')),
      ],
    );
  }
}
