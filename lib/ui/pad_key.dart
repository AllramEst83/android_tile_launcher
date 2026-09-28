import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// A key or chip on the calculator's pads, in the launcher's own look: a
/// bordered label, brighter when [selected] or when it is an [accent] key.
/// A `null` [onTap] greys it. Sized by its parent (keys in a row are
/// [Expanded]); [height] is what a thumb needs.
class PadKey extends StatelessWidget {
  const PadKey({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.accent = false,
    this.height = 52,
    this.fontSize = 14,
    this.padding = EdgeInsets.zero,
  });

  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final bool accent;
  final double height;
  final double fontSize;

  /// Space inside the border either side of the label, for keys that size to
  /// their label (chips) rather than to their parent.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final Color colour = onTap == null
        ? TileColors.textDim
        : selected
        ? TileColors.highlight
        : accent
        ? TileColors.accent
        : TileColors.textBright;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: height),
        alignment: Alignment.center,
        padding: padding,
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? TileColors.highlight : TileColors.bezel,
            width: TileMetrics.bevel,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: kPixelFontFamily,
            fontSize: fontSize,
            color: colour,
          ),
        ),
      ),
    );
  }
}

/// A row of equally wide keys with a small gap between them; `null` in [keys]
/// leaves a gap where a key would be. A key given a [flex] other than 1 takes
/// that many keys' width.
class PadRow extends StatelessWidget {
  const PadRow({super.key, required this.keys});

  final List<(Widget, int)> keys;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: <Widget>[
          for (final (int i, (Widget, int) entry) in keys.indexed) ...<Widget>[
            if (i > 0) const SizedBox(width: 4),
            Expanded(flex: entry.$2, child: entry.$1),
          ],
        ],
      ),
    );
  }
}
