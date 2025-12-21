import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/get.dart';
import 'package:my_budget_client/domain/entities/icon_type.dart';
import 'package:my_budget_client/domain/entities/style.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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

  List<String> _materialIconNames = [];
  List<String> _customIconPaths = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadMaterialIcons();
    _loadCustomIcons();
  }

  Future<void> _loadMaterialIcons() async {
    final data =
        await rootBundle.loadString('MyBudget/docs/planning/material_icons.json');
    final Map<String, dynamic> iconData = json.decode(data);
    final List<String> iconNames = [];
    iconData.forEach((key, value) {
      iconNames.addAll(List<String>.from(value));
    });
    setState(() {
      _materialIconNames = iconNames;
    });
  }

  Future<void> _loadCustomIcons() async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);
    final imagePaths = manifestMap.keys
        .where((String key) => key.startsWith('lib/icons/'))
        .toList();

    final appDir = await getApplicationDocumentsDirectory();
    final iconsDir = Directory(p.join(appDir.path, 'icons'));
    if (await iconsDir.exists()) {
      final userIcons = await iconsDir.list().map((file) => file.path).toList();
      imagePaths.addAll(userIcons);
    }

    setState(() {
      _customIconPaths = imagePaths;
    });
  }

  Future<void> _addNewIcon() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final iconsDir = Directory(p.join(appDir.path, 'icons'));
      if (!await iconsDir.exists()) {
        await iconsDir.create();
      }
      final newIconPath = p.join(iconsDir.path, image.name);
      final file = File(newIconPath);
      await file.writeAsBytes(await image.readAsBytes());
      setState(() {
        _customIconPaths.add(newIconPath);
      });
    }
  }

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
        colorHex: '#${_selectedColor.value.toRadixString(16).substring(2)}',
        iconType: _selectedIconType,
      );
      context.read<StylesBloc>().add(AddStyle(newStyle));
      Navigator.of(context).pop();
    }
  }

  Future<void> _showColorPicker() async {
    final color = await showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: ColorPicker(
          color: _selectedColor,
          onColorChanged: (color) {
            setState(() {
              _selectedColor = color;
            });
          },
          pickersEnabled: const {
            ColorPickerType.wheel: true,
            ColorPickerType.accent: false,
            ColorPickerType.primary: false,
            ColorPickerType.bw: false,
            ColorPickerType.custom: false,
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_selectedColor),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (color != null) {
      setState(() {
        _selectedColor = color;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Style'),
      content: DefaultTabController(
        length: 2,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: SizedBox(
              width: double.maxFinite,
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
                  const Text('Color',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ListTile(
                    title: const Text('Change Color'),
                    trailing: CircleAvatar(
                      backgroundColor: _selectedColor,
                    ),
                    onTap: _showColorPicker,
                  ),
                  const SizedBox(height: 16),
                  const TabBar(
                    tabs: [
                      Tab(text: 'Material Icons'),
                      Tab(text: 'Custom Icons'),
                    ],
                  ),
                  SizedBox(
                    height: 200,
                    child: TabBarView(
                      children: [
                        _buildMaterialIconGrid(),
                        _buildCustomIconGrid(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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

  Widget _buildMaterialIconGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 60,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _materialIconNames.length,
      itemBuilder: (context, index) {
        final iconName = _materialIconNames[index];
        return ChoiceChip(
          label: Icon(SymbolsGet.get(iconName, SymbolStyle.outlined)),
          selected: _selectedIconName == iconName,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _selectedIconName = iconName;
                _selectedIconType = IconType.material;
              });
            }
          },
        );
      },
    );
  }

  Widget _buildCustomIconGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 60,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _customIconPaths.length + 1,
      itemBuilder: (context, index) {
        if (index == _customIconPaths.length) {
          return IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNewIcon,
          );
        }
        final iconPath = _customIconPaths[index];
        final isAsset = iconPath.startsWith('lib/icons/');
        return ChoiceChip(
          label: isAsset
              ? Image.asset(iconPath)
              : Image.file(File(iconPath)),
          selected: _selectedIconName == iconPath,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _selectedIconName = iconPath;
                _selectedIconType = IconType.custom;
              });
            }
          },
        );
      },
    );
  }
}
