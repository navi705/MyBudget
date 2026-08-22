import 'package:flutter/material.dart';

/// An [Icon] that swaps glyphs with the reading direction.
///
/// Sixteen chevrons and arrows across this app are hardcoded to the LTR glyph,
/// so in `ar` and `ur` — where the whole layout mirrors — "previous period"
/// draws an arrow pointing at the *next* period. `Icon(matchTextDirection:)`
/// only helps for the handful of Material glyphs that ship a mirrored variant;
/// `chevron_left` is not one of them, so the pair has to be chosen explicitly.
///
/// The house pattern is `Directionality.of(context) == TextDirection.rtl`, as
/// used by the rail toggle in `adaptive_scaffold.dart`. This widget is that one
/// line, named, so the six call sites in the filter bars and pickers cannot
/// drift apart from each other.
class DirectionalIcon extends StatelessWidget {
  /// The glyph to draw when text runs left-to-right.
  final IconData ltr;

  /// The glyph to draw when text runs right-to-left.
  final IconData rtl;

  final Color? color;
  final double? size;

  const DirectionalIcon({
    super.key,
    required this.ltr,
    required this.rtl,
    this.color,
    this.size,
  });

  /// Chevron pointing at the *earlier* item: left in LTR, right in RTL.
  const DirectionalIcon.previous({super.key, this.color, this.size})
    : ltr = Icons.chevron_left,
      rtl = Icons.chevron_right;

  /// Chevron pointing at the *later* item: right in LTR, left in RTL.
  const DirectionalIcon.next({super.key, this.color, this.size})
    : ltr = Icons.chevron_right,
      rtl = Icons.chevron_left;

  /// The slimmer `arrow_back_ios` / `arrow_forward_ios` pair the generic filter
  /// bar uses for period navigation, mirrored the same way.
  const DirectionalIcon.previousArrow({super.key, this.color, this.size})
    : ltr = Icons.arrow_back_ios,
      rtl = Icons.arrow_forward_ios;

  const DirectionalIcon.nextArrow({super.key, this.color, this.size})
    : ltr = Icons.arrow_forward_ios,
      rtl = Icons.arrow_back_ios;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Icon(isRtl ? rtl : ltr, color: color, size: size);
  }
}
