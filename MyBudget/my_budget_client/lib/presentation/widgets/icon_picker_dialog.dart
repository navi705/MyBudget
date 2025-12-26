import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:material_symbols_icons/get.dart';
import 'package:my_budget_client/domain/entities/icon_type.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';

class IconPickerDialog extends StatefulWidget {
  final String initialIconName;
  final IconType initialIconType;

  const IconPickerDialog({
    super.key,
    required this.initialIconName,
    required this.initialIconType,
  });

  @override
  State<IconPickerDialog> createState() => _IconPickerDialogState();
}

class _IconPickerDialogState extends State<IconPickerDialog> {
  late String _selectedIconName;
  late IconType _selectedIconType;

  Map<String, List<String>> _materialIconCategories = {};
  List<String> _customIconPaths = [];

  @override
  void initState() {
    super.initState();
    _selectedIconName = widget.initialIconName;
    _selectedIconType = widget.initialIconType;
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
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'svg'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final fileName = p.basename(file.path);
      final isSvg = fileName.toLowerCase().endsWith('.svg');
      final appDir = await getApplicationDocumentsDirectory();
      final iconsDir = Directory(p.join(appDir.path, 'icons'));
      if (!await iconsDir.exists()) {
        await iconsDir.create(recursive: true);
      }
      final newIconPath = p.join(iconsDir.path, fileName);
      final imageBytes = await file.readAsBytes();
      await File(newIconPath).writeAsBytes(imageBytes);

      if (!isSvg) {
        final originalImage = img.decodeImage(imageBytes);
        if (originalImage != null) {
          final thumbnailDir = Directory(p.join(iconsDir.path, '.thumbnails'));
          if (!await thumbnailDir.exists()) {
            await thumbnailDir.create(recursive: true);
          }
          final thumbnailPath = p.join(thumbnailDir.path, fileName);
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
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Icon'),
      content: SizedBox(
        width: double.maxFinite,
        child: DefaultTabController(
          length: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop({
              'name': _selectedIconName,
              'type': _selectedIconType,
            });
          },
          child: const Text('Select'),
        ),
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
                maxCrossAxisExtent: 50,
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
            maxCrossAxisExtent: 50,
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
                  isSvg ? SvgPicture.asset(iconPath, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)) : Image.asset(iconPath, color: Colors.white);
            } else {
              if (isSvg) {
                imageWidget = SvgPicture.file(File(iconPath), colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn));
              } else {
                final dir = p.dirname(iconPath);
                final filename = p.basename(iconPath);
                final displayPath = p.join(dir, '.thumbnails', filename);
                imageWidget = Image.file(File(displayPath), color: Colors.white);
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
        padding: const EdgeInsets.all(4),
        child: FittedBox(
          fit: BoxFit.contain,
          child: iconWidget,
        ),
      ),
    );
  }
}
