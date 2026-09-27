import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// One tile: a flat VIC-II fill with a 2px light-top-left/dark-bottom-right
/// bevel (never a shadow or gradient), a monochrome glyph — its label's first
/// letter, since no real app icons are drawn yet (plan.md, "Not implemented")
/// — and the label itself along the bottom edge.
class TileView extends StatelessWidget {
  const TileView({
    super.key,
    required this.tile,
    required this.label,
    required this.onTap,
  });

  final Tile tile;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color fill = tile.colour.fill;
    final Color ink = tile.colour.ink;
    final Color light = Color.lerp(fill, C64.white, 0.35)!;
    final Color dark = Color.lerp(fill, C64.black, 0.35)!;
    final String glyph = label.isEmpty ? '?' : label[0].toUpperCase();

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: fill,
          border: Border(
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
          ],
        ),
      ),
    );
  }
}
