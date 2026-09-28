import 'package:android_tile_launcher/model/tile.dart';

/// A [Tile] with the column and row the packer chose for it. Both are 0-based
/// grid cells, not pixels; the UI multiplies by its own cell size.
class PlacedTile {
  const PlacedTile({
    required this.tile,
    required this.column,
    required this.row,
    this._span,
  });

  final Tile tile;
  final int column;
  final int row;
  final int? _span;

  /// How many columns the tile takes where it was placed; the default
  /// four-column footprint when the placement did not say.
  int get span => _span ?? tile.size.columns;
}

/// Packs an ordered list of tiles into rows of [columns], skyline-style: each
/// tile goes in the leftmost gap that lets it sit highest (closest to the
/// top), so mixed sizes still leave no unnecessary empty rows below a
/// shorter neighbour. Pure and order-stable — the same list always packs the
/// same way.
List<PlacedTile> packTiles(List<Tile> tiles, {int columns = 4}) {
  final List<int> nextFreeRow = List<int>.filled(columns, 0);
  final List<PlacedTile> placed = <PlacedTile>[];

  for (final Tile tile in tiles) {
    final int span = tile.size.spanIn(columns);
    assert(span <= columns, 'a tile cannot be wider than the grid');

    int bestColumn = 0;
    int bestTop = _tallestOf(nextFreeRow, 0, span);
    for (int start = 1; start <= columns - span; start++) {
      final int top = _tallestOf(nextFreeRow, start, span);
      if (top < bestTop) {
        bestTop = top;
        bestColumn = start;
      }
    }

    placed.add(
      PlacedTile(tile: tile, column: bestColumn, row: bestTop, span: span),
    );
    for (int c = bestColumn; c < bestColumn + span; c++) {
      nextFreeRow[c] = bestTop + tile.size.rows;
    }
  }
  return placed;
}

/// The row height of the grid a packed layout needs, so the UI knows how tall
/// to make its scrollable area.
int totalRows(List<PlacedTile> placed) {
  int max = 0;
  for (final PlacedTile p in placed) {
    final int bottom = p.row + p.tile.size.rows;
    if (bottom > max) max = bottom;
  }
  return max;
}

int _tallestOf(List<int> nextFreeRow, int start, int span) {
  int tallest = 0;
  for (int c = start; c < start + span; c++) {
    if (nextFreeRow[c] > tallest) tallest = nextFreeRow[c];
  }
  return tallest;
}
