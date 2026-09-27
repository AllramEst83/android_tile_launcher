import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// One tile: a flat VIC-II fill with a 2px light-top-left/dark-bottom-right
/// bevel (never a shadow or gradient), a monochrome glyph — its label's first
/// letter, since no real app icons are drawn yet (plan.md, "Not implemented")
/// — and the label itself along the bottom edge. In the grid editor,
/// [selected] draws a bright outline instead of the bevel and [onDelete]
/// shows a small badge in the corner.
class TileView extends StatelessWidget {
  const TileView({
    super.key,
    required this.tile,
    required this.label,
    required this.onTap,
    this.onLongPress,
    this.selected = false,
    this.onDelete,
  });

  final Tile tile;
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool selected;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final Color fill = tile.colour.fill;
    final Color ink = tile.colour.ink;
    final Color light = Color.lerp(fill, C64.white, 0.35)!;
    final Color dark = Color.lerp(fill, C64.black, 0.35)!;
    final String glyph = label.isEmpty ? '?' : label[0].toUpperCase();

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: fill,
          border: selected
              ? Border.all(color: C64.white, width: TileMetrics.bevel * 2)
              : Border(
                  top: BorderSide(color: light, width: TileMetrics.bevel),
                  left: BorderSide(color: light, width: TileMetrics.bevel),
                  right: BorderSide(color: dark, width: TileMetrics.bevel),
                  bottom: BorderSide(color: dark, width: TileMetrics.bevel),
                ),
        ),
        padding: const EdgeInsets.all(TileMetrics.gutter / 2),
        child: Stack(
          children: <Widget>[
            Center(
              child: FittedBox(
                child: Text(
                  glyph,
                  style: TextStyle(fontFamily: kPixelFontFamily, color: ink),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontFamily: kPixelFontFamily,
                  fontSize: 8,
                  color: ink,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onDelete != null)
              Positioned(
                top: 0,
                right: 0,
                child: _DeleteBadge(
                  key: ValueKey('delete-${tile.id}'),
                  onTap: onDelete!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DeleteBadge extends StatelessWidget {
  const _DeleteBadge({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(2),
        color: C64.black,
        child: const Text(
          'X',
          style: TextStyle(
            fontFamily: kPixelFontFamily,
            fontSize: 8,
            color: C64.white,
          ),
        ),
      ),
    );
  }
}
