import 'dart:convert';
import 'package:my_budget_client/core/utils/platform/io_helper.dart';
import 'package:my_budget_client/core/utils/platform/icon_helper.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
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
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final imagePaths = manifest
        .listAssets()
        .where((String key) => key.startsWith('lib/icons/'))
        .toList();

    final appDir = await getApplicationDocumentsDirectory();
    final iconsDirPath = p.join(appDir.path, 'icons');
    if (await IoHelper.exists(iconsDirPath)) {
      final userIcons = await IoHelper.listFiles(iconsDirPath);
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
      final filePath = result.files.single.path!;
      final fileName = p.basename(filePath);
      final isSvg = fileName.toLowerCase().endsWith('.svg');
      final appDir = await getApplicationDocumentsDirectory();
      // Using Directory directly here might be unsafe if web needs special directory handling,
      // but path_provider and Directory are sometimes abstractable.
      // However, to be strictly safe and avoid dart:io File mixups:

      final iconsDirPath = p.join(appDir.path, 'icons');
      if (!await IoHelper.exists(iconsDirPath)) {
        // IoHelper doesn't have createDirectory but has createParent.
        // We can use createParent on a dummy child.
        await IoHelper.createParent(p.join(iconsDirPath, 'dummy'));
      }

      final newIconPath = p.join(iconsDirPath, fileName);
      final imageBytes = await IoHelper.readAsBytes(filePath);
      await IoHelper.writeAsBytes(newIconPath, imageBytes);

      if (!isSvg) {
        final originalImage = img.decodeImage(imageBytes);
        if (originalImage != null) {
          final thumbnailDirPath = p.join(iconsDirPath, '.thumbnails');
          if (!await IoHelper.exists(thumbnailDirPath)) {
            await IoHelper.createParent(p.join(thumbnailDirPath, 'dummy'));
          }
          final thumbnailPath = p.join(thumbnailDirPath, fileName);
          final thumbnail = img.copyResize(originalImage, width: 120);
          await IoHelper.writeAsBytes(thumbnailPath, img.encodePng(thumbnail));
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
      title: Text(context.l10n.pckSelectIcon),
      content: SizedBox(
        width: double.maxFinite,
        child: DefaultTabController(
          length: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TabBar(
                tabs: [
                  Tab(text: context.l10n.pckMaterialIcons),
                  Tab(text: context.l10n.pckCustomIcons),
                ],
              ),
              // Expanded instead of a screen-height fraction: AlertDialog already
              // bounds its content to the space left after the title, the actions
              // and the keyboard insets, so half the *screen* height regularly
              // exceeds what the dialog actually has. TabBarView cannot
              // shrink-wrap, so it needs a bounded height and Expanded gives it
              // exactly the height the dialog can spare.
              Expanded(
                child: TabBarView(
                  children: [_buildMaterialIconList(), _buildCustomIconGrid()],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancelButton),
        ),
        FilledButton.tonal(
          onPressed: () {
            Navigator.of(
              context,
            ).pop({'name': _selectedIconName, 'type': _selectedIconType});
          },
          child: Text(context.l10n.selectButton),
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
              imageWidget = isSvg
                  ? SvgPicture.asset(
                      iconPath,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    )
                  : Image.asset(iconPath, color: Colors.white);
            } else {
              if (isSvg) {
                imageWidget = IconPlatformHelper.buildSvgFromFile(
                  iconPath,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                );
              } else {
                final dir = p.dirname(iconPath);
                final filename = p.basename(iconPath);
                final displayPath = p.join(dir, '.thumbnails', filename);
                imageWidget = IconPlatformHelper.buildImageFromFile(
                  displayPath,
                  color: Colors.white,
                );
              }
            }

            return _buildIconTile(
              iconIdentifier: iconPath,
              iconWidget: imageWidget,
              iconType: IconType.custom,
            );
          },
        ),
        // Directional so the FAB lands in the trailing corner of the grid for
        // RTL locales (ar/ur) instead of on top of the first icons.
        PositionedDirectional(
          bottom: 16,
          end: 16,
          child: FloatingActionButton(
            onPressed: _addNewIcon,
            tooltip: context.l10n.addNewIconLabel,
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
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 3,
          ),
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
        padding: const EdgeInsets.all(4),
        child: FittedBox(fit: BoxFit.contain, child: iconWidget),
      ),
    );
  }
}
