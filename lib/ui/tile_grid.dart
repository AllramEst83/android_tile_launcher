import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/model/tile_layout.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:android_tile_launcher/ui/tile_view.dart';
import 'package:flutter/material.dart';

/// Renders a layout [packTiles] already worked out. Cell size comes from the
/// available width, so every tile is a whole number of square base cells;
/// this widget only lays out what it is given, it never packs.
class TileGrid extends StatelessWidget {
  const TileGrid({
    super.key,
    required this.placed,
    required this.labelFor,
    required this.onLaunch,
  });

  final List<PlacedTile> placed;
  final String Function(Tile tile) labelFor;
  final ValueChanged<String> onLaunch;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double cell =
            (constraints.maxWidth -
                (TileMetrics.columns - 1) * TileMetrics.gutter) /
            TileMetrics.columns;
        final int rows = totalRows(placed);
        final double height = rows == 0
            ? 0
            : rows * cell + (rows - 1) * TileMetrics.gutter;

        return SizedBox(
          height: height,
          child: Stack(
            children: <Widget>[
              for (final PlacedTile p in placed)
                Positioned(
                  left: p.column * (cell + TileMetrics.gutter),
                  top: p.row * (cell + TileMetrics.gutter),
                  width:
                      p.tile.size.columns * cell +
                      (p.tile.size.columns - 1) * TileMetrics.gutter,
                  height:
                      p.tile.size.rows * cell +
                      (p.tile.size.rows - 1) * TileMetrics.gutter,
                  child: TileView(
                    key: ValueKey(p.tile.id),
                    tile: p.tile,
                    label: labelFor(p.tile),
                    onTap: () => onLaunch(p.tile.appPackage),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
