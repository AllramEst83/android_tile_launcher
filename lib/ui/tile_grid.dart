import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/model/tile_layout.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:android_tile_launcher/ui/tile_view.dart';
import 'package:flutter/material.dart';

/// Where one placed tile lands in pixels, for a given available width.
class TileRect {
  const TileRect({
    required this.tile,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final Tile tile;
  final double left;
  final double top;
  final double width;
  final double height;
}

/// Turns a packed layout into pixel rectangles: a cell is the available width
/// divided evenly into [TileMetrics.columns], and every tile is a whole
/// number of square cells plus the gutters between them. Shared by [TileGrid]
/// and the grid editor's canvas so both size tiles identically.
List<TileRect> layoutTiles(
  List<PlacedTile> placed, {
  required double maxWidth,
}) {
  final double cell = _cellSize(maxWidth);
  return [
    for (final PlacedTile p in placed)
      TileRect(
        tile: p.tile,
        left: p.column * (cell + TileMetrics.gutter),
        top: p.row * (cell + TileMetrics.gutter),
        width:
            p.tile.size.columns * cell +
            (p.tile.size.columns - 1) * TileMetrics.gutter,
        height:
            p.tile.size.rows * cell +
            (p.tile.size.rows - 1) * TileMetrics.gutter,
      ),
  ];
}

/// The total height a packed layout needs at [maxWidth].
double gridHeight(List<PlacedTile> placed, {required double maxWidth}) {
  final int rows = totalRows(placed);
  if (rows == 0) return 0;
  final double cell = _cellSize(maxWidth);
  return rows * cell + (rows - 1) * TileMetrics.gutter;
}

double _cellSize(double maxWidth) =>
    (maxWidth - (TileMetrics.columns - 1) * TileMetrics.gutter) /
    TileMetrics.columns;

/// Renders a layout [packTiles] already worked out. Cell size comes from the
/// available width, so every tile is a whole number of square base cells;
/// this widget only lays out what it is given, it never packs. [onLaunch]
/// only fires for a tile with a [launchTargetOf] — a system kind's tile just
/// isn't tappable outside the editor.
class TileGrid extends StatelessWidget {
  const TileGrid({
    super.key,
    required this.placed,
    required this.labelFor,
    required this.onLaunch,
    this.onLongPress,
  });

  final List<PlacedTile> placed;
  final String Function(Tile tile) labelFor;
  final ValueChanged<String> onLaunch;
  final ValueChanged<String>? onLongPress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final List<TileRect> rects = layoutTiles(
          placed,
          maxWidth: constraints.maxWidth,
        );
        return SizedBox(
          height: gridHeight(placed, maxWidth: constraints.maxWidth),
          child: Stack(
            children: <Widget>[
              for (final TileRect r in rects)
                Positioned(
                  key: ValueKey(r.tile.id),
                  left: r.left,
                  top: r.top,
                  width: r.width,
                  height: r.height,
                  child: TileView(
                    colour: r.tile.colour,
                    content: tileContent(r.tile, labelFor: labelFor),
                    onTap: switch (launchTargetOf(r.tile)) {
                      final String target => () => onLaunch(target),
                      null => null,
                    },
                    onLongPress: onLongPress == null
                        ? null
                        : () => onLongPress!(r.tile.id),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
