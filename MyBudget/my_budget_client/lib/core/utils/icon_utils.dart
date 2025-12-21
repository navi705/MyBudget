import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:material_symbols_icons/get.dart';
import 'package:my_budget_client/domain/entities/icon_type.dart';
import 'package:my_budget_client/domain/entities/style.dart';
import 'package:path/path.dart' as p;

class IconUtils {
  static Widget getIconWidget(Style icon) {
    if (icon.iconType == IconType.material) {
      return Icon(
        SymbolsGet.get(icon.iconName, SymbolStyle.outlined),
        color: Colors.white,
      );
    } else if (icon.iconType == IconType.custom) {
      final iconPath = icon.iconName;
      final isAsset = iconPath.startsWith('lib/icons/');
      final isSvg = iconPath.toLowerCase().endsWith('.svg');

      if (isAsset) {
        return isSvg
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
          return SvgPicture.file(
            File(iconPath),
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          );
        } else {
          // Construct path to thumbnail for bitmap images
          final dir = p.dirname(iconPath);
          final filename = p.basename(iconPath);
          final displayPath = p.join(dir, '.thumbnails', filename);
          return Image.file(File(displayPath), color: Colors.white);
        }
      }
    }
    return const Icon(Icons.error, color: Colors.white); // Default error icon
  }
}
