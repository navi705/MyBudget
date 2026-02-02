import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:material_symbols_icons/get.dart';
import 'package:my_budget_client/domain/entities/icon_type.dart';
import 'package:my_budget_client/domain/entities/style.dart';
import 'package:path/path.dart' as p;
import 'package:my_budget_client/core/utils/platform/icon_helper.dart';

class IconUtils {
  static Widget getIconWidget(Style icon, {double? size}) {
    if (icon.iconType == IconType.material) {
      return Icon(
        SymbolsGet.get(icon.iconName, SymbolStyle.outlined),
        color: Colors.white,
        size: size,
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
                width: size,
                height: size,
              )
            : Image.asset(
                iconPath,
                color: Colors.white,
                width: size,
                height: size,
              );
      } else {
        if (isSvg) {
          return IconPlatformHelper.buildSvgFromFile(
            iconPath,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            width: size,
            height: size,
          );
        } else {
          // Construct path to thumbnail for bitmap images
          final dir = p.dirname(iconPath);
          final filename = p.basename(iconPath);
          final displayPath = p.join(dir, '.thumbnails', filename);
          return IconPlatformHelper.buildImageFromFile(
            displayPath,
            color: Colors.white,
            width: size,
            height: size,
          );
        }
      }
    }
    return Icon(
      Icons.error,
      color: Colors.white,
      size: size,
    ); // Default error icon
  }

  static Color getColorFromHex(String? hexColor) {
    hexColor = (hexColor ?? '#808080').replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    if (hexColor.length == 8) {
      try {
        return Color(int.parse("0x$hexColor"));
      } catch (_) {
        return Colors.grey;
      }
    }
    return Colors.grey;
  }
}
