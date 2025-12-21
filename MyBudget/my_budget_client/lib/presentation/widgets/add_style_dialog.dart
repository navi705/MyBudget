import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/get.dart';
import 'package:my_budget_client/domain/entities/icon_type.dart';
import 'package:my_budget_client/domain/entities/style.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

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

  Map<String, List<String>> _materialIconCategories = {};
  List<String> _customIconPaths = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadMaterialIcons();
    _loadCustomIcons();
  }

  Future<void> _loadMaterialIcons() async {
    final data = await rootBundle.loadString('lib/icons/material_icons.json');
    final Map<String, dynamic> iconData = json.decode(data);
    final Map<String, List<String>> categories = {};
    iconData.forEach((key, value) {
      categories[key] = List<String>.from(value);
    });
    setState(() {
      _materialIconCategories = categories;
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
      final isSvg = image.name.toLowerCase().endsWith('.svg');
      final appDir = await getApplicationDocumentsDirectory();
      final iconsDir = Directory(p.join(appDir.path, 'icons'));
      if (!await iconsDir.exists()) {
        await iconsDir.create(recursive: true);
      }
      final newIconPath = p.join(iconsDir.path, image.name);
      final imageBytes = await image.readAsBytes();
      await File(newIconPath).writeAsBytes(imageBytes);

      // Only create thumbnails for non-SVG images
      if (!isSvg) {
        final originalImage = img.decodeImage(imageBytes);
        if (originalImage != null) {
          final thumbnailDir = Directory(p.join(iconsDir.path, '.thumbnails'));
          if (!await thumbnailDir.exists()) {
            await thumbnailDir.create(recursive: true);
          }
          final thumbnailPath = p.join(thumbnailDir.path, image.name);
          final thumbnail = img.copyResize(originalImage, width: 120);
          await File(thumbnailPath).writeAsBytes(img.encodePng(thumbnail));
        }
      }

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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Style'),
      content: SizedBox(
        width: double.maxFinite,
        child: DefaultTabController(
          length: 2,
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
                  ExpansionTile(
                    title: Row(
                      children: [
                        Container(
                          width: 80,
                          height: 20,
                          decoration: BoxDecoration(
                            color: _selectedColor,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text('Color'),
                      ],
                    ),
                    children: [
                      ColorPicker(
                        color: _selectedColor,
                        onColorChanged: (color) {
                          setState(() {
                            _selectedColor = color;
                          });
                        },
                        pickersEnabled: const {
                          ColorPickerType.wheel: true,
                          ColorPickerType.primary: false,
                          ColorPickerType.accent: false
                        },
                        wheelDiameter: 300,
                        width: 44,
                        height: 44,
                        borderRadius: 22,
                        heading: Text(
                          'Select color',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        subheading: Text(
                          'Select color shade',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const TabBar(
                    tabs: [
                      Tab(text: 'Material Icons'),
                      Tab(text: 'Custom Icons'),
                    ],
                  ),
                  SizedBox(
                    height: 400,
                    child: TabBarView(
                      children: [
                        _buildMaterialIconList(),
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
        ElevatedButton(onPressed: _onSave, child: const Text('Save')),
      ],
    );
  }

  Widget _buildMaterialIconList() {
    final categories = _materialIconCategories.keys.toList();
    if (categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final icons = _materialIconCategories[category]!;
        return ExpansionTile(
          title: Text(category),
          initiallyExpanded: index == 0,
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 50, // CHANGED: Reduced from 60 to 50
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: icons.length,
              itemBuilder: (context, iconIndex) {
                final iconName = icons[iconIndex];
                return _buildIconTile(
                  iconIdentifier: iconName,
                  iconWidget: Icon(
                    SymbolsGet.get(iconName, SymbolStyle.outlined),
                  ),
                  iconType: IconType.material,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCustomIconGrid() {
    final filteredIcons = _customIconPaths
        .where((path) => !path.toLowerCase().endsWith('.json'))
        .toList();
    return Stack(
      children: [
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 50, // CHANGED: Reduced from 60 to 50
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: filteredIcons.length,
          itemBuilder: (context, index) {
            final iconPath = filteredIcons[index];
            final isAsset = iconPath.startsWith('lib/icons/');
            final isSvg = iconPath.toLowerCase().endsWith('.svg');

            Widget imageWidget;
            if (isAsset) {
              imageWidget =
                  isSvg ? SvgPicture.asset(iconPath) : Image.asset(iconPath);
            } else {
              if (isSvg) {
                imageWidget = SvgPicture.file(File(iconPath));
              } else {
                // Construct path to thumbnail for bitmap images
                final dir = p.dirname(iconPath);
                final filename = p.basename(iconPath);
                final displayPath = p.join(dir, '.thumbnails', filename);
                imageWidget = Image.file(File(displayPath));
              }
            }

            return _buildIconTile(
              iconIdentifier: iconPath,
              iconWidget: imageWidget,
              iconType: IconType.custom,
            );
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: _addNewIcon,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildIconTile({
    required String iconIdentifier,
    required Widget iconWidget,
    required IconType iconType,
  }) {
    final bool isSelected = _selectedIconName == iconIdentifier;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIconName = iconIdentifier;
          _selectedIconType = iconType;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color:
                isSelected ? Theme.of(context).primaryColor : Colors.transparent,
            width: 2,
          ),
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.transparent,
        ),
        padding: const EdgeInsets.all(4), // Keep some padding so icon doesn't touch border
        // CHANGED: Added FittedBox to force icon to fill the space
        child: FittedBox(
          fit: BoxFit.contain,
          child: iconWidget,
        ),
      ),
    );
  }
}