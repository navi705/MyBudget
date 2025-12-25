import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/core/utils/icon_utils.dart';
import 'package:my_budget_client/domain/entities/icon_type.dart';
import 'package:my_budget_client/domain/entities/style.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';
import 'package:my_budget_client/presentation/widgets/icon_picker_dialog.dart';

class EditStyleScreen extends StatefulWidget {
  final String styleId;

  const EditStyleScreen({super.key, required this.styleId});

  @override
  State<EditStyleScreen> createState() => _EditStyleScreenState();
}

class _EditStyleScreenState extends State<EditStyleScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  
  late String _selectedIconName;
  late IconType _selectedIconType;
  late Color _selectedColor;

  Style? _initialStyle;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();

    final stylesState = context.read<StylesBloc>().state;
    if (stylesState is StylesLoadSuccess) {
      try {
        _initialStyle = stylesState.styles.firstWhere(
          (style) => style.id == widget.styleId,
        );
        _nameController.text = _initialStyle!.name;
        _selectedIconName = _initialStyle!.iconName;
        _selectedIconType = _initialStyle!.iconType;
        _selectedColor = _getColorFromHex(_initialStyle!.colorHex);
      } catch (e) {
        // If the style is not found (e.g., deleted), _initialStyle remains null
        _initialStyle = null;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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
      final updatedStyle = Style(
        id: _initialStyle!.id,
        name: _nameController.text,
        iconName: _selectedIconName,
        colorHex: '#${_selectedColor.hex}',
        iconType: _selectedIconType,
      );
      context.read<StylesBloc>().add(UpdateStyle(updatedStyle));
      context.pop();
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
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                ),
                onTap: () async {
                  final newColor = await showColorPickerDialog(
                    context,
                    _selectedColor,
                    pickersEnabled: const {
                      ColorPickerType.wheel: true,
                      ColorPickerType.primary: false,
                      ColorPickerType.accent: false
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
                      colorHex: '#FFFFFF', // Color is ignored by the util
                      iconType: _selectedIconType,
                    ),
                  ),
                ),
                onTap: _showIconPicker,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _onSave,
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50)),
                child: const Text('Save Changes'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
