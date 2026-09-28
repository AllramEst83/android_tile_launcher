import 'package:android_tile_launcher/model/settings.dart';
import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/model/tile_layout.dart';
import 'package:android_tile_launcher/services/tile_services.dart';
import 'package:android_tile_launcher/ui/settings_scope.dart';
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
/// less the gaps between [columns], divided evenly, and every tile is a whole
/// number of square cells plus the [gap]s between them. Shared by [TileGrid]
/// and the grid editor's canvas so both size tiles identically.
List<TileRect> layoutTiles(
  List<PlacedTile> placed, {
  required double maxWidth,
  int columns = TileMetrics.columns,
  double gap = TileMetrics.gutter,
}) {
  final double cell = _cellSize(maxWidth, columns, gap);
  return [
    for (final PlacedTile p in placed)
      TileRect(
        tile: p.tile,
        left: p.column * (cell + gap),
        top: p.row * (cell + gap),
        width: p.span * cell + (p.span - 1) * gap,
        height: p.tile.size.rows * cell + (p.tile.size.rows - 1) * gap,
      ),
  ];
}

/// The total height a packed layout needs at [maxWidth].
double gridHeight(
  List<PlacedTile> placed, {
  required double maxWidth,
  int columns = TileMetrics.columns,
  double gap = TileMetrics.gutter,
}) {
  final int rows = totalRows(placed);
  if (rows == 0) return 0;
  final double cell = _cellSize(maxWidth, columns, gap);
  return rows * cell + (rows - 1) * gap;
}

double _cellSize(double maxWidth, int columns, double gap) =>
    (maxWidth - (columns - 1) * gap) / columns;

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
    required this.services,
    required this.onLaunch,
    this.onLongPress,
  });

  final List<PlacedTile> placed;
  final String Function(Tile tile) labelFor;
  final TileServices services;
  final ValueChanged<String> onLaunch;
  final ValueChanged<String>? onLongPress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final LauncherSettings settings = SettingsScope.of(context);
        final List<TileRect> rects = layoutTiles(
          placed,
          maxWidth: constraints.maxWidth,
          columns: settings.columns,
          gap: settings.gap.pixels,
        );
        return SizedBox(
          height: gridHeight(
            placed,
            maxWidth: constraints.maxWidth,
            columns: settings.columns,
            gap: settings.gap.pixels,
          ),
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
                    content: tileContent(
                      r.tile,
                      labelFor: labelFor,
                      services: services,
                    ),
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
